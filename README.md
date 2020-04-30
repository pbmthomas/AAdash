# AAdash

Provider level Attend Anywhere Dashboard

## About 

App.R provides an R/Shiny app that can be run locally within R ([Rstudio](https://rstudio.com/)).

Input CSV file is the raw downloaded "Consultations" CSV from the reporting section of Attend Anywhere. 

A demonstration of the latest build is available at [aadash.org](https://aadash.org).

## Getting started

The software is be available at [aadash.org](https://aadash.org).

Alternatively, you can download app.R from this page, and run it within R ([Rstudio](https://rstudio.com/)) on your computer.

## Setting up your own server

If you want to host AADash so it can be used by other individuals within your organisation without them needing to install RStudio, or use the hosted version at [aadash.org](https://aadash.org), the software can also be self-hosted. Pointers for installation on Debian-based linux systems are shown below, but additional linux experience is likely to be required.

### Self-hosting

#### Prerequisites

Dependency libraries can be installed by running the following command within the R console.

```
install.packages(c("dplyr", "DT", "ggplot2", "lubridate", "shiny", "shinyWidgets", "tidyverse"))
```

On Ubuntu linux this may fail with a message saying "installation of package ‘tidyverse’ had non-zero exit status". In this case, installing the system dependencies for tidyverse will resolve the issues.

```
sudo apt-get install libssl-dev libcurl4-openssl-dev libxml2-dev
```

Similar package installation will likely be required on other Unix systems. You should use the search command within your package manager to look for the equivalent packages on your system.

#### Running the server

The server can be run from within Rstudio desktop, or from the system console by running the command:

```
Rscript app.R
```

If you are running this on a remote server that you are accessing via SSH, the script may terminate if you lose connection to the server. To run a long-running version of the server, the easiest option is to use the GNU Screen package.

You can open a new screen session by running the command:

```
screen -S aadash
```

This will automatically enter a new terminal session, where you can start the server using `Rscript app.R`. To disconnect, you can press "Control-A", then "Control-D". To reconnect (e.g. to stop or restart the server), you type `screen -R aadash`.

#### Securing the server

You may wish to use SSL to secure the server (having a https:// web address). The easiest way to do this is by using software that runs between this application, and the end user. This software is called a reverse proxy, and the easiest reverse proxy to install is ```nginx```.

To install nginx on Ubuntu:

```
sudo apt-get install nginx
```

You now need to edit the configuration file for Nginx. 

If you are not running any other web servers on the machine, configure your Nginx server using the following instructions.:

```
sudo nano /etc/nginx/sites-enabled/default
```

You should then delete the contents of the file, and paste the configuration below, _making sure to replace example.com with your own domain_.

```
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	root /var/www/html;

	server_name example.com www.example.com;

	location / {
		proxy_pass http://127.0.0.1:8888;
                proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection "upgrade";
	}
}
```

Press "Control-O" and then "Control-X" to exit the text editor. Then, to restart Nginx, run the following:

```
sudo service nginx restart
```

Now follow the [CertBot](https://certbot.eff.org/instructions) instructions to configure a certificate for SSL.

