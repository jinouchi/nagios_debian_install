#!/bin/bash

# install the following LAMP stack components in your system
apt install apache2 libapache2-mod-php7.0 php7.0

# install the following system dependencies and utilities required to compile and install Nagios Core from sources
apt install wget unzip zip  autoconf gcc libc6 make apache2-utils libgd-dev

# create nagios system user and group and add nagios account to the Apache www-data user
useradd nagios
usermod -a -G nagios www-data

# grab the latest version of Nagios Core stable source archive
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.3.4.tar.gz

# extract Nagios tarball and enter the extracted nagios directory
tar xzf nagios-4.3.4.tar.gz 
cd nagios-4.3.4/

# compile Nagios from sources
./configure --with-httpd-conf=/etc/apache2/sites-enabled

# build Nagios
make all

# install Nagios binary files, CGI scripts and HTML files
make install

# install Nagios daemon init and external command mode configuration files and make sure you enable nagios daemon system-wide by issuing the following commands.
make install-init
make install-commandmode
systemctl enable nagios.service


# install some Nagios sample configuration files needed by Nagios to run properly
make install-config

# install Nagios configuration file for Apacahe web server, which can be fount in /etc/apacahe2/sites-enabled/ directory
make install-webconf

# create nagiosadmin account and a password for this account necessary by Apache server to log in to Nagios web panel
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

# To allow Apache HTTP server to execute Nagios cgi scripts and to access Nagios admin panel via HTTP, first enable cgi module in Apache and then restart Apache service and start and enable Nagios daemon system-wide
a2enmod cgi
systemctl restart apache2
systemctl start nagios
systemctl enable nagios

# compile and install Nagios Plugins from sources
# prereqs
apt install libmcrypt-dev make libssl-dev bc gawk dc build-essential snmp libnet-snmp-perl gettext libldap2-dev smbclient fping libmysqlclient-dev qmail-tools libpqxx3-dev libdbi-dev 
wget https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz 
tar xfz release-2.2.1.tar.gz 
cd nagios-plugins-release-2.2.1/
./tools/setup 
./configure 
make
make install

# restart Nagios daemon in order to apply the installed plugins
systemctl restart nagios.service

# enable Apache SSL configurations and restart the Apache daemon to access Nagios admin web interface via HTTPS protocol
a2enmod ssl 
a2ensite default-ssl.conf
systemctl restart apache2

# Give the user some instructions (this could be automated with some work)
echo 'Add the following block of code after DocumentRoot statement in /etc/apache2/sites-enabled/000-default.conf:
RewriteEngine on
RewriteCond %{HTTPS} off
RewriteRule ^(.*) https://%{HTTP_HOST}/$1'

# Restart Apache daemon
systemctl restart apache2.service 

# tell user what to do
echo 'Done! Visit https://ip-address/nagios and log in with your credentials.'
