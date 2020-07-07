#!/bin/bash

##############################################################
#### Installation of zoneminder on Ubuntu 18.04 with LAMP ####
##############################################################

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
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

#--------------------------------------------------
# Set up the timezones
#--------------------------------------------------

# set the correct timezone on ubuntu
timedatectl set-timezone Africa/Kigali
timedatectl

#--------------------------------------------------
# Install dependences
#--------------------------------------------------
# Install Apache, MySQL, and PHP
apt install -y tasksel
tasksel install lamp-server

#--------------------------------------------------
# ZoneMinder repository
#--------------------------------------------------
apt install -y software-properties-common
add-apt-repository ppa:iconnor/zoneminder-1.34
apt update
apt upgrade
apt dist-upgrade

apt install -y zoneminder

# Secure MySQL. Do not activate VALIDATE PASSWORD COMPONENT
Mysql_secure_installation

rm /etc/mysql/my.cnf
cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/my.cnf

cat >> /etc/my.cnf <<EOF
[mysqld]
default-authentication-plugin=mysql_native_password
EOF

# Restart MySQL
systemctl restart mysql

# Create the zoneminder database
sudo mysql -uroot -p < /usr/share/zoneminder/db/zm_create.sql

#-----------------------------------------------------------------
# Create user and set permissions (press Enter after each entry)
#---------------------------------------------------------------
mysql -u root -p<<MYSQL_SCRIPT
CREATE USER 'zmuser'@localhost IDENTIFIED WITH mysql_native_password BY 'zmpass';
GRANT ALL PRIVILEGES ON zm.* TO 'zmuser'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Fix permissions
chmod 740 /etc/zm/zm.conf
chown root:www-data /etc/zm/zm.conf

adduser www-data video
chown -R root:root /usr/share/zoneminder/

# Setup Apache2
a2enconf zoneminder
a2enmod rewrite
a2enmod cgi
a2enmod expires
a2enmod headers

# Enable and start the ZoneMinder service
sudo systemctl enable zoneminder
sudo systemctl start zoneminder

#----------------------------------------------------------
# set timezone
#----------------------------------------------------------
sudo sed -i s/";date.timezone =/date.timezone = Africa\/Kigali"/g /etc/php/7.2/apache2/php.ini

# Restart the Apache2 service
sudo systemctl restart apache2

echo -e "Open Zoneminder http://hostname_or_ip/zm/"

