#library(readr)
library(dplyr)
library(shiny)
library(tidyverse)
library(lubridate)
library(ggplot2)
library(DT)
library(shinyWidgets)

#Configure the port for the server to run on
options(shiny.port = 8888)

ui <- fluidPage(
    titlePanel("Attend Anywhere Provider Dashboard (beta)"),
    sidebarLayout(
        sidebarPanel(
            #Allow upload of a CSV file - must be the "consultations" output from Attend Anywhere
            fileInput("file1", "Upload your 'Consultations' CSV file",
                      accept = c(
                          "text/csv",
                          "text/comma-separated-values,text/plain",
                          ".csv")
            ),
            
            tags$hr(), #Divider line
            #Allow filtering by date
            dateRangeInput("daterange1", "Filter by date",
                           start = "2020-03-5",
                           end   = Sys.Date()),
            tags$hr(),
            #allow WR choics - using pickerInput from shinyWidgets
            pickerInput("wrChoices","Filter by waiting room", choices=NULL, options = list(`actions-box` = TRUE),multiple = T, selected=NULL),
            tags$hr(),
            #allow WR choics - using pickerInput from shinyWidgets
            pickerInput("clinChoices","Filter by clinician", choices=NULL, options = list(`actions-box` = TRUE),multiple = T, selected=NULL),
        ),
        mainPanel(
            #Use tabs to separate analyses
            tabsetPanel(type = "tabs",
                        tabPanel("Consults by date", plotOutput("consultPlot")),
                        tabPanel("Clinician leaderboard", tableOutput("leaderBoard")),
                        tabPanel("Waiting room utilization", tableOutput("wrUtilization")),
                        tabPanel("Raw data", DT::dataTableOutput("rawData"))
            )
        )
    )
)

server <- function(input, output, session) {
    
    #get the CSV into consults1() - this stores the unfiltered data
    consults1 <- eventReactive(input$file1, {
        inFile <- input$file1
        read.csv(inFile$datapath, skip=6)
    })
    
    #This next section needs tidying - it's a mess but it works. 
    output$consultPlot <- renderPlot({
        consults <- consults1()
        #filter to providers, waiting areas and clincians 
        consults_providers <- filter(consults, Participant.Type=="provider" & Waiting.Area %in% input$wrChoices & User.name %in% input$clinChoices)
        #select out a date column -
        consults_dates <- select(consults_providers,'Time.Call.Ended..local.')
        names(consults_dates)[1] <- "TimeEnded"
        consults_dates_formatted <- parse_date_time(consults_dates$TimeEnded, "dmy HMS")
        final_dates <- date(consults_dates_formatted)
        freq_by_date <- table(final_dates)
        freq_by_date <- data.frame(freq_by_date)
        all_date <- data.frame(final_dates)
        
        g <- ggplot(all_date, aes(x=final_dates)) + 
            geom_bar(fill="blue") +
            #scale_x_date(limits = as.Date(c('2020-04-01','2020-04-07')))
            scale_x_date(limits = c(input$daterange1[1]-1, input$daterange1[2]+1)) +
            xlab("Date") +
            ylab("Number of consultations") +
            labs(title = "Consultations per day")
        g
    })
    
    #clinician leaderboard
    output$leaderBoard <- renderTable({
        leaderBoardTab <- consults1()
        leaderBoardTab$Time.Call.Ended..local.<- parse_date_time(leaderBoardTab$Time.Call.Ended..local., "dmy HMS")
        leaderBoardTab <- filter(leaderBoardTab,Participant.Type=="provider",  Time.Call.Ended..local. > input$daterange1[1] & Time.Call.Ended..local. <input$daterange1[2]+1 & Waiting.Area %in% input$wrChoices & User.name %in% input$clinChoices)
        leaderBoardTab <- table(leaderBoardTab$User.name)
        leaderBoardTab <- as.data.frame(leaderBoardTab)
        leaderBoardTab <- leaderBoardTab[order(-leaderBoardTab$Freq),]
    })
    
    #waiting room utilization
    output$wrUtilization <- renderTable({
        wrUtilizationTab <- consults1()
        wrUtilizationTab$Time.Call.Ended..local.<- parse_date_time(wrUtilizationTab$Time.Call.Ended..local., "dmy HMS")
        wrUtilizationTab <- filter(wrUtilizationTab,Participant.Type=="provider",  Time.Call.Ended..local. > input$daterange1[1] & Time.Call.Ended..local. <input$daterange1[2]+1 & Waiting.Area %in% input$wrChoices & User.name %in% input$clinChoices)
        wrUtilizationTab <- table(wrUtilizationTab$Waiting.Area)
        wrUtilizationTab <- as.data.frame(wrUtilizationTab)
        wrUtilizationTab <- wrUtilizationTab[order(-wrUtilizationTab$Freq),]
    })
    
    #Show the raw data as a Data Table
    output$rawData <- DT::renderDataTable({
        consults1() 
    })
    
    #this watches for changes and updates the list of unique WR names from CSV
    observe({
        DF <- sort(as.character(unlist(consults1()[2])), decreasing = FALSE)
        updatePickerInput(
            session,
            "wrChoices",
            choices = unique(DF),
            selected = unique(DF)
        )
    })
    #this watches for changes and updates the list of unique clinician names from CSV
    observe({
        consultstemp <- filter(consults1(), Participant.Type=="provider")
        DF <- sort(as.character(unlist(consultstemp[5])), decreasing = FALSE)
        updatePickerInput(
            session,
            "clinChoices",
            choices = unique(DF),
            selected = unique(DF)
        )
    })
}  

shinyApp(ui, server)
