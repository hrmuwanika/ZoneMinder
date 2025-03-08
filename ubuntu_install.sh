#!/bin/bash

##############################################################
#### Installation of zoneminder on 22.04 with LAMP ####
##############################################################
#
#----------------------------------------------------
read -p "This script installs ZoneMinder 1.36.x on Ubuntu 22.04 with LAMP (Apache Php Mariadb) installed...
Press Enter to continue or Ctrl + c to quit" nothing
#----------------------------------------------------
clear

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============== Update Server ======================="
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y

#--------------------------------------------------
# Set up the timezones
#--------------------------------------------------
# set the correct timezone on ubuntu
sudo timedatectl set-timezone Africa/Kigali
timedatectl

# Install Apache PHP and other dependencies
sudo apt install -y apache2 php libapache2-mod-php php-mysql msmtp tzdata gnupg ca-certificates  

# Mariadb dependencies
sudo apt install -y curl apt-transport-https lsb-release gnupg2 dirmngr

curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
sudo bash mariadb_repo_setup --mariadb-server-version=11.2
sudo apt update && sudo apt upgrade -y

sudo apt install -y mariadb-server mariadb-client

sudo systemctl enable --now apache2 mariadb

#--------------------------------------------------
# ZoneMinder repository
#--------------------------------------------------
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:iconnor/zoneminder-1.36
sudo apt update

sudo apt install -y zoneminder
sudo systemctl enable zoneminder
sudo systemctl start zoneminder

# Secure MySQL. Do not activate VALIDATE PASSWORD COMPONENT
# mariadb-secure-installation

# Remove mariadb strict mode by setting sql_mode = NO_ENGINE_SUBSTITUTION
sed -i '/\[mysqld\]/a sql_mode = NO_ENGINE_SUBSTITUTION' /etc/mysql/mariadb.conf.d/50-server.cnf

# create the zoneminder database
sudo mariadb -uroot --password="" -e "create database zm;"
sudo mariadb -uroot --password="" -e "CREATE USER zmuser@localhost IDENTIFIED BY 'zmpass';"
sudo mariadb -uroot --password="" -e "GRANT ALL PRIVILEGES ON zm.* TO zmuser@localhost;"
sudo mariadb -uroot --password="" -e "FLUSH PRIVILEGES;"
sudo mariadb -uroot --password="" < /usr/share/zoneminder/db/zm_create.sql 2>/dev/null

# Fix permissions
chmod 740 /etc/zm/zm.conf
chown root:www-data /etc/zm/zm.conf

sudo adduser www-data video
sudo chown --recursive www-data:www-data /usr/share/zoneminder/ 
sudo a2enconf zoneminder

# Now we enable the configurations in Apache2
sudo a2enmod cgi 
sudo a2enmod rewrite

sudo a2enmod expires 
sudo a2enmod headers 

sudo systemctl enable zoneminder
sudo systemctl start zoneminder
sudo systemctl status zoneminder.service
netstat -vnatp | grep apache2

#----------------------------------------------------------
# set timezone
#----------------------------------------------------------
sudo sed -i s/";date.timezone =/date.timezone = Africa\/Kigali"/g /etc/php/8.3/apache2/php.ini

# Restart the Apache2 service
sudo systemctl restart apache2

#----------------------------------------------------
echo "Install complete." 
#----------------------------------------------------
