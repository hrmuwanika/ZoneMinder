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
sudo apt install curl apt-transport-https software-properties-common lsb-release ca-certificates gnupg2 dirmngr

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
#mysql_secure_installation

# Remove mariadb strict mode by setting sql_mode = NO_ENGINE_SUBSTITUTION
sudo rm /etc/mysql/mariadb.conf.d/50-server.cnf
cd /etc/mysql/mariadb.conf.d/
wget https://raw.githubusercontent.com/hrmuwanika/ZoneMinder/master/50-server.cnf

# create the zoneminder database
sudo mysql -uroot --password="" < /usr/share/zoneminder/db/zm_create.sql 2>/dev/null
sudo mysql -uroot --password="" -e "ALTER USER 'zmuser'@localhost IDENTIFIED BY 'zmpass';"
sudo mysql -uroot --password="" -e "GRANT ALL PRIVILEGES ON zm.* TO 'zmuser'@'localhost' WITH GRANT OPTION;"
sudo mysql -uroot --password="" -e "FLUSH PRIVILEGES;"
sudo mysqladmin -uroot --password="" reload 2>/dev/null

# Fix permissions
chmod 740 /etc/zm/zm.conf
chown root:www-data /etc/zm/zm.conf

sudo adduser www-data video
chown -R www-data:www-data /usr/share/zoneminder/

# Setup Apache2
sudo a2enmod rewrite
sudo a2enconf zoneminder
sudo systemctl restart apache2

#----------------------------------------------------------
# set timezone
#----------------------------------------------------------
sudo sed -i s/";date.timezone =/date.timezone = Africa\/Kigali"/g /etc/php/8.2/apache2/php.ini

# Restart the Apache2 service
sudo systemctl restart apache2

# Enable and start the ZoneMinder service
sudo systemctl restart zoneminder

#----------------------------------------------------
read -p "Install complete. Open Zoneminder/Options and set the timezone. Press enter to continue" nothing
#----------------------------------------------------
