#!/bin/bash

##############################################################
#### Installation of zoneminder on 22.04, 20.04 or 18.04 with LAMP ####
##############################################################
#
#----------------------------------------------------
read -p "This script installs ZoneMinder 1.37.x on Ubuntu 20.04 with LAMP (Apache Php Mariadb) installed...
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
sudo add-apt-repository ppa:iconnor/zoneminder-master
sudo apt update 

sudo apt install -y zoneminder
sudo systemctl enable zoneminder

# Secure MySQL. Do not activate VALIDATE PASSWORD COMPONENT
#mysql_secure_installation

# Remove mariadb strict mode by setting sql_mode = NO_ENGINE_SUBSTITUTION
sudo rm /etc/mysql/mariadb.conf.d/50-server.cnf

cat <<MYSQLCONF>> /etc/mysql/mariadb.conf.d/50-server.cnf
[mysql.server]
user = mysql
#basedir = /var/lib

[client]
port = 3306
socket = /var/lib/mysql/mysql.sock

[mysqld]
datadir = /var/lib/mysql
#tmpdir = /home/mysql_tmp
socket = /var/lib/mysql/mysql.sock
user = mysql
old_passwords = 0
ft_min_word_len = 3
max_connections = 800
max_allowed_packet = 32M
skip-external-locking
sql_mode="NO_ENGINE_SUBSTITUTION"

log-error = /var/log/mysqld/mysqld.log

query-cache-type = 1
query-cache-size = 32M

long_query_time = 1
#slow_query_log = 1
#slow_query_log_file = /var/log/mysqld/slow-queries.log

tmp_table_size = 128M
table_cache = 1024

join_buffer_size = 1M
key_buffer = 512M
sort_buffer_size = 6M
read_buffer_size = 4M
read_rnd_buffer_size = 16M
myisam_sort_buffer_size = 64M

max_tmp_tables = 64

thread_cache_size = 8
thread_concurrency = 8

# If using replication, uncomment log-bin below
#log-bin = mysql-bin

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[isamchk]
key_buffer = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[myisamchk]
key_buffer = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

[mysqld_safe]
#log-error = /var/log/mysqld/mysqld.log
#pid-file = /var/run/mysqld/mysqld.pid
MYSQLCONF

# Restart MySQL
mkdir /var/log/mysqld
touch /var/log/mysqld/slow-queries.log
sudo chown -R mysql:mysql /var/log/mysqld
sudo systemctl restart mariadb

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
sudo a2enmod rewrite expires headers cgi
sudo a2enconf zoneminder

# Enable and start the ZoneMinder service
sudo systemctl restart zoneminder
sudo systemctl reload apache2

#----------------------------------------------------------
# set timezone
#----------------------------------------------------------
sudo sed -i s/";date.timezone =/date.timezone = Africa\/Kigali"/g /etc/php/7.4/apache2/php.ini

# Restart the Apache2 service
sudo systemctl restart apache2

clear
#----------------------------------------------------
read -p "Install complete. Open Zoneminder/Options and set the timezone. Press enter to continue" nothing
#----------------------------------------------------

