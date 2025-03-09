#!/bin/bash

##############################################################
#### Installation of zoneminder on 24.04 with LAMP ####
##############################################################
#
#----------------------------------------------------
read -p "This script installs ZoneMinder 1.36.x on Ubuntu 24.04 with LAMP (Apache Php Mariadb) installed...
Press Enter to continue or Ctrl + c to quit" nothing
#----------------------------------------------------

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "============== Update Server ======================="
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y

#--------------------------------------------------
# Set up the timezones
#--------------------------------------------------
# set the correct timezone on ubuntu
sudo timedatectl set-timezone Africa/Kigali
timedatectl

# Install Apache PHP and other dependencies
sudo apt install -y apache2 php libapache2-mod-php php-mysql ffmpeg

#----------------------------------------------------------
# set timezone
#----------------------------------------------------------
sudo sed -i s/";date.timezone =/date.timezone = Africa\/Kigali"/g /etc/php/8.3/apache2/php.ini

sudo systemctl enable apache2 
sudo systemctl start apache2

sudo apt install -y mariadb-server mariadb-client
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Secure MySQL. Do not activate VALIDATE PASSWORD COMPONENT
# mariadb-secure-installation

# Remove mariadb strict mode by setting sql_mode = NO_ENGINE_SUBSTITUTION
sed -i '/\[mysqld\]/a sql_mode = NO_ENGINE_SUBSTITUTION' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i '/\[mysqld\]/a innodb_file_per_table = ON' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i '/\[mysqld\]/a innodb_buffer_pool_size = 256M' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i '/\[mysqld\]/a innodb_log_file_size = 32M' /etc/mysql/mariadb.conf.d/50-server.cnf

# create the zoneminder database
# sudo mariadb -uroot --password="" -e "create database zm;"
# sudo mariadb -uroot --password="" -e "CREATE USER zmuser@localhost IDENTIFIED BY 'zmpass';"
# sudo mariadb -uroot --password="" -e "GRANT ALL PRIVILEGES ON zm.* TO zmuser@localhost;"
# sudo mariadb -uroot --password="" -e "FLUSH PRIVILEGES;"

#--------------------------------------------------
# ZoneMinder repository
#--------------------------------------------------
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:iconnor/zoneminder-master
sudo apt update
sudo apt install -y zoneminder

# Fix permissions
chmod 740 /etc/zm/zm.conf
chown root:www-data /etc/zm/zm.conf

sudo adduser www-data video
sudo chown --recursive www-data:www-data /usr/share/zoneminder/ 

sudo mariadb -uroot -p < /usr/share/zoneminder/db/zm_create.sql
sudo mariadb -uroot -p -e "grant lock tables,alter,drop,select,insert,update,delete,create,index,alter routine,create routine, trigger,execute,references on zm.* to 'zmuser'@localhost identified by 'zmpass';"

# Now we enable the configurations in Apache2
sudo a2enmod cgi 
sudo a2enmod rewrite
sudo a2enconf zoneminder
sudo a2enmod expires 
sudo a2enmod headers 

sudo systemctl enable zoneminder
sudo systemctl start zoneminder

sudo systemctl status zoneminder.service
netstat -vnatp | grep apache2

# Restart the Apache2 service
sudo systemctl restart apache2

#----------------------------------------------------
echo "Install complete." 
#----------------------------------------------------
