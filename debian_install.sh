#!/bin/bash

##############################################################
#### Installation of zoneminder on Debian Bulls eye ####
##############################################################

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============== Update Server ======================="
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y

apt install -y sudo nano
#--------------------------------------------------
# Set up the timezones
#--------------------------------------------------
# set the correct timezone on ubuntu
sudo timedatectl set-timezone Africa/Kigali
timedatectl

# Install Apache, MySQL, and PHP
sudo apt install -y apache2 mariadb-server php libapache2-mod-php php-mysql lsb-release gnupg2

sudo systemctl enable --now apache2 mysql

#--------------------------------------------------
# ZoneMinder repository
#--------------------------------------------------
echo "deb https://zmrepo.zoneminder.com/debian/release-1.36 "`lsb_release -c -s`"/" >> /etc/apt/sources.list.d/zoneminder.list
wget -O - https://zmrepo.zoneminder.com/debian/archive-keyring.gpg | sudo apt-key add -
sudo apt update && sudo apt upgrade

sudo apt install -y zoneminder=1.36.11-bullseye1
sudo systemctl enable zoneminder.service

# Secure MySQL. Do not activate VALIDATE PASSWORD COMPONENT
#mysql_secure_installation

rm /etc/mysql/my.cnf
cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/my.cnf

nano /etc/mysql/my.cnf
# paste at the bottom
# sql_mode = NO_ENGINE_SUBSTITUTION

# Restart MySQL
sudo systemctl restart mysql

# import the zoneminder database
sudo mysql -uroot --password="" < /usr/share/zoneminder/db/zm_create.sql
sudo mysql -uroot --password="" -e "grant lock tables,alter,drop,select,insert,update,delete,create,index,alter routine,create routine, trigger,execute on zm.* to 'zmuser'@localhost identified by 'zmpass';"

# Fix permissions
chmod 740 /etc/zm/zm.conf
chown root:www-data /etc/zm/zm.conf

sudo adduser www-data video
chown -R www-data:www-data /usr/share/zoneminder/

# Setup Apache2
sudo a2enmod rewrite expires headers
sudo a2enconf zoneminder

# Enable and start the ZoneMinder service
sudo systemctl restart zoneminder

#----------------------------------------------------------
# set timezone
#----------------------------------------------------------
sudo sed -i s/";date.timezone =/date.timezone = Africa\/Kigali"/g /etc/php/8.1/apache2/php.ini

# Restart the Apache2 service
sudo systemctl restart apache2

clear
#----------------------------------------------------
read -p "Install complete. Open Zoneminder/Options and set the timezone. Press enter to continue" nothing
#----------------------------------------------------

