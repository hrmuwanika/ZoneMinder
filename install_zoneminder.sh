#!/bin/bash

##############################################################
#### Installation of zoneminder on Ubuntu 18.04 with LAMP ####
##############################################################
#
#
# Set to "True" to install certbot and have ssl enabled, "False" to use http
ENABLE_SSL="True"
# Set the website name
WEBSITE_NAME="example.com"
# Provide Email to register ssl certificate
ADMIN_EMAIL="odoo@example.com"
##
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
# Install FFMPEG
#--------------------------------------------------
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:jonathonf/ffmpeg-4
sudo apt update 
sudo apt upgrade -y
sudo apt install -y ffmpeg

#--------------------------------------------------
# Install python and opencv
#--------------------------------------------------
sudo apt install -y python3-pip python3-dev python3-setuptools python3-opencv libopencv-dev
sudo python3 -m pip install --upgrade pip
sudo -H pip3 install opencv-contrib-python

# Install other dependencies
sudo apt install -y libboost-all-dev libgtk-3-dev scikit-image
sudo apt install -y build-essential cmake curl git unzip gcc
wget https://bootstrap.pypa.io/get-pip.py
sudo python3 get-pip.py
sudo apt install -y libmodule-build-perl
sudo apt install -y make
sudo apt install -y libcrypt-mysql-perl
sudo apt install -y libcrypt-eksblowfish-perl

sudo perl -MCPAN -e "install Crypt::MySQL"
sudo perl -MCPAN -e "install Config::IniFiles"
sudo perl -MCPAN -e "install Crypt::Eksblowfish::Bcrypt"
sudo perl -MCPAN -e "install Getopt::Long"

sudo apt install -y libyaml-perl
sudo perl -MCPAN -e "install Net::WebSocket::Server"

sudo apt install -y libjson-perl
sudo perl -MCPAN -e "install LWP::Protocol::https"

# Install Apache, MySQL, and PHP
sudo apt install -y tasksel
tasksel install lamp-server

#--------------------------------------------------
# ZoneMinder repository
#--------------------------------------------------
sudo add-apt-repository ppa:iconnor/zoneminder-1.36
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade

sudo apt install -y zoneminder

# Secure MySQL. Do not activate VALIDATE PASSWORD COMPONENT
#mysql_secure_installation

rm /etc/mysql/my.cnf
cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/my.cnf

cat >> /etc/my.cnf <<EOF
[mysqld]
default-authentication-plugin=mysql_native_password
EOF

# Restart MySQL
sudo systemctl restart mysql

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

sudo adduser www-data video
chown -R www-data:www-data /usr/share/zoneminder/

# Setup Apache2
sudo a2enconf zoneminder
sudo a2enmod rewrite
sudo a2enmod cgi
sudo a2enmod expires
sudo a2enmod headers

# Enable and start the ZoneMinder service
sudo systemctl enable zoneminder
sudo systemctl start zoneminder

#----------------------------------------------------------
# set timezone
#----------------------------------------------------------
sudo sed -i s/";date.timezone =/date.timezone = Africa\/Kigali"/g /etc/php/7.2/apache2/php.ini

# Restart the Apache2 service
sudo systemctl restart apache2

if [ $ENABLE_SSL = "True" ] && [ $ADMIN_EMAIL != "odoo@example.com" ]  && [ $WEBSITE_NAME != "example.com" ];then
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

echo -e "Open Zoneminder http://hostname_or_ip/zm/"

