#!/bin/bash

##############################################################
#### Installation of zoneminder on Ubuntu 22.04 with LAMP ####
##############################################################
#
#
# Set to "True" to install certbot and have ssl enabled, "False" to use http
ENABLE_SSL="True"
# Set the website name
WEBSITE_NAME="example.com"
# Provide Email to register ssl certificate
ADMIN_EMAIL="vms@example.com"
##
#
clear
read -p "This script installs ZoneMinder 1.36.x on Ubuntu 22.04, 20.04 or 18.04 with LAMP (MySQL or Mariadb) installed...
Press Enter to continue or Ctrl + c to quit" nothing
clear

#----------------------------------------------------
# Disable password authentication
#----------------------------------------------------
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service sshd restart

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============== Update Server ======================="
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
clear
#--------------------------------------------------
# Set up the timezones
#--------------------------------------------------

# set the correct timezone on ubuntu
sudo timedatectl set-timezone Africa/Kigali
timedatectl
clear
# Install Apache, MySQL, and PHP
sudo apt install -y apache2 php mysql-server php-mysql libapache2-mod-php 
sudo systemctl enable --now apache2 mysql

#--------------------------------------------------
# ZoneMinder repository
#--------------------------------------------------
read -p "Next we will add the PPA repository, install and configure the system to run Zoneminder. 
Press enter to continue" nothing
apt install -y software-properties-common
clear
sudo add-apt-repository ppa:iconnor/zoneminder-1.36
sudo apt update && sudo apt upgrade

sudo apt install -y zoneminder
sudo systemctl enable zoneminder

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
sudo systemctl reload apache2

#----------------------------------------------------------
# set timezone
#----------------------------------------------------------
sudo sed -i s/";date.timezone =/date.timezone = Africa\/Kigali"/g /etc/php/8.1/apache2/php.ini

# Restart the Apache2 service
sudo systemctl restart apache2

if [ $ENABLE_SSL = "True" ] && [ $ADMIN_EMAIL != "vms@example.com" ]  && [ $WEBSITE_NAME != "example.com" ];then
  sudo apt install snapd -y
  sudo apt-get remove certbot
  
  sudo snap install core
  sudo snap refresh core
  sudo snap install --classic certbot
  sudo ln -s /snap/bin/certbot /usr/bin/certbot
  sudo certbot --apache -d $WEBSITE_NAME --noninteractive --agree-tos --email $ADMIN_EMAIL --redirect
  sudo systemctl reload apache2
  
  echo "\n============ SSL/HTTPS is enabled! ========================"
else
  echo "\n==== SSL/HTTPS isn't enabled due to choice of the user or because of a misconfiguration! ======"
fi

clear
read -p "Install complete. Open Zoneminder/Options and set the timezone. Press enter to continue" nothing

