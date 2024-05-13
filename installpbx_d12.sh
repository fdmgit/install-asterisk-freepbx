#!/bin/bash

######################################
######################################
####   Asterisk FreePBX Install   ####
######################################
######################################

######################################
####   Functions                  ####
######################################

enterparameters () {
    echo -e "\n${LBLUE} ---------------------------------------"
    echo -e "\n Start FreePBX / Asterisk Installation:"
    echo -e "\n ---------------------------------------"
    echo -e "\n"
    read -p " Enter root password : ${NC}" ROOTPW
    read -p "${LBLUE} Enter domain name (FQDN) ${NC}: " FQDN
    echo -e "\n${LBLUE} Setup DB user 'admindb' ${NC}"
    read -p "${LBLUE} Enter DB user password : ${NC}" DBUSERPWD
}

menuset () {
    make menuselect.makeopts
    menuselect/menuselect --enable chan_ooh323 menuselect.makeopts
    menuselect/menuselect --enable format_mp3 menuselect.makeopts
    menuselect/menuselect --enable app_macro menuselect.makeopts
    menuselect/menuselect --disable cdr_pgsql menuselect.makeopts
    menuselect/menuselect --disable cdr_radius menuselect.makeopts
    menuselect/menuselect --disable cel_pgsql menuselect.makeopts
    menuselect/menuselect --disable cel_radius menuselect.makeopts
    menuselect/menuselect --enable CORE-SOUNDS-EN-WAV menuselect.makeopts
    menuselect/menuselect --enable CORE-SOUNDS-EN-ULAW menuselect.makeopts
    menuselect/menuselect --enable CORE-SOUNDS-EN-ALAW menuselect.makeopts
    menuselect/menuselect --enable CORE-SOUNDS-EN-G729 menuselect.makeopts
    menuselect/menuselect --enable CORE-SOUNDS-EN-G722 menuselect.makeopts
    menuselect/menuselect --enable MOH-OPSOUND-WAV menuselect.makeopts
    menuselect/menuselect --enable MOH-OPSOUND-ULAW menuselect.makeopts
    menuselect/menuselect --enable MOH-OPSOUND-ALAW menuselect.makeopts
    menuselect/menuselect --enable MOH-OPSOUND-GSM menuselect.makeopts
    menuselect/menuselect --enable MOH-OPSOUND-G729 menuselect.makeopts
    menuselect/menuselect --enable MOH-OPSOUND-G722 menuselect.makeopts
    menuselect/menuselect --enable EXTRA-SOUNDS-EN-WAV menuselect.makeopts
    menuselect/menuselect --enable EXTRA-SOUNDS-EN-ULAW menuselect.makeopts
    menuselect/menuselect --enable EXTRA-SOUNDS-EN-ALAW menuselect.makeopts
    menuselect/menuselect --enable EXTRA-SOUNDS-EN-GSM menuselect.makeopts
    menuselect/menuselect --enable EXTRA-SOUNDS-EN-G729 menuselect.makeopts
    menuselect/menuselect --enable EXTRA-SOUNDS-EN-G722 menuselect.makeopts
}

inst_apache_modules () {
    a2enmod rewrite
    a2enmod ssl
    a2enmod expires
    a2enmod include
    systemctl restart apache2
}

######################################
####   Var / Const Definition     ####
######################################

okinput=true

NC=$(echo -en '\001\033[0m\002')
RED=$(echo -en '\001\033[00;31m\002')
GREEN=$(echo -en '\001\033[00;32m\002')
YELLOW=$(echo -en '\001\033[00;33m\002')
BLUE=$(echo -en '\001\033[00;34m\002')
MAGENTA=$(echo -en '\001\033[00;35m\002')
PURPLE=$(echo -en '\001\033[00;35m\002')
CYAN=$(echo -en '\001\033[00;36m\002')
WHITE=$(echo -en '\001\033[01;37m\002')

LIGHTGRAY=$(echo -en '\001\033[00;37m\002')
LRED=$(echo -en '\001\033[01;31m\002')
LGREEN=$(echo -en '\001\033[01;32m\002')
LYELLOW=$(echo -en '\001\033[01;33m\002')
LBLUE=$(echo -en '\001\033[01;34m\002')
LMAGENTA=$(echo -en '\001\033[01;35m\002')
LPURPLE=$(echo -en '\001\033[01;35m\002')
LCYAN=$(echo -en '\001\033[01;36m\002')


######################################
####          S T A R T           ####
######################################

echo -e "${LYELLOW} Starting ...  (it will take some time) ${NC}"

apt-get update > /dev/null
apt-get upgrade -y > /dev/null
apt-get install lsb-release -y > /dev/null

clear             # clear screen

os_id=$(lsb_release -i)
os_release=$(lsb_release -r)
os_codename=$(lsb_release -c)
os_sig=${os_id:16}" "${os_release:9}" ("${os_codename:10}")"

### Adapt OS info
os_id=${os_id:16}
os_release=${os_release:9}


### Check if the correct OS is used
if [[ "$os_id" != "Debian" ]]; then
    echo -e "${YELLOW} The Installation is only supported on Debian 12 systems!${NC}"
    exit 1
fi

############
#### Get parameters and choose installation option
############

enterparameters
clear             # clear screen

okinput=true


###########################
#  Set Swap Space
###########################

cd /root
swapon --show > swapon.out       ## check if swap exists
FILESIZE=$(stat -c%s swapon.out)

if [[ "$FILESIZE" == "0" ]]; then      ## swap space does not exist
   fallocate -l 1G /swapfile
   chmod 600 /swapfile
   mkswap /swapfile
   swapon /swapfile
   echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
fi

rm swapon.out

###########################
#  Set Time Zone
###########################

cd /root
timedatectl set-timezone Europe/Zurich
apt-get install sntp -y
apt-get install ntpdate -y
sntp -c 0.pool.ntp.org

###########################
#  Install Webmin
###########################

apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions unzip shared-mime-info
curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
sh setup-repos.sh
apt-get install webmin --install-recommends -y


##############################
#  Some additional programs
##############################

apt-get install plocate -y
updatedb

echo -e "root:$ROOTPW" | chpasswd   # set root password -
hostnamectl set-hostname $FQDN   # set hostname


##############################
#  Install pre-requisites
##############################

apt-get -y install git vim curl wget libnewt-dev libssl-dev libncurses5-dev subversion libsqlite3-dev build-essential libjansson-dev libxml2-dev uuid-dev
apt-get -y install bison flex sqlite3 pkg-config automake libtool autoconf unixodbc-dev uuid sox mpg123 linux-headers-`uname -r`
apt-get -y install libasound2-dev libogg-dev libvorbis-dev libicu-dev libcurl4-openssl-dev libical-dev libneon27-dev libsrtp2-dev
apt-get -y install libspandsp-dev libtool-bin python-dev unixodbc dirmngr
apt-get -y install apt-transport-https lsb-release ca-certificates gcc g++ make
apt-get -y install lame ffmpeg odbc-mariadb libicu-dev
echo "postfix postfix/mailname string $FQDN" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get -y install postfix

##############################
#  Install Asterisk 
##############################

cd /usr/src/

wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz
tar xvf asterisk-20-current.tar.gz
rm asterisk-20-current.tar.gz
cd asterisk-20*/


contrib/scripts/get_mp3_source.sh
contrib/scripts/install_prereq install
./configure --with-pjproject-bundled --with-jansson-bundled
#make menuselect

menuset    # configure Asterisk modules

make
make install
make progdocs
make samples
make config
ldconfig

sleep 10

cd /root
groupadd asterisk 
useradd -r -d /var/lib/asterisk -g asterisk asterisk 
usermod -aG audio,dialout asterisk 
chown -R asterisk.asterisk /etc/asterisk 
chown -R asterisk.asterisk /var/lib/asterisk
chown -R asterisk.asterisk /var/log/asterisk
chown -R asterisk.asterisk /var/spool/asterisk 
chown -R asterisk.asterisk /usr/lib/asterisk

sed -i 's/#AST_USER="asterisk"/AST_USER="asterisk"/'  /etc/default/asterisk
sed -i 's/#AST_GROUP="asterisk"/AST_GROUP="asterisk"/'  /etc/default/asterisk

sed -i 's/\;runuser = asterisk /runuser = asterisk/'  /etc/asterisk/asterisk.conf
sed -i 's/\;rungroup = asterisk/rungroup = asterisk/'  /etc/asterisk/asterisk.conf

systemctl start asterisk
#systemctl enable asterisk

sleep 10

###########################
#  Install FreePBX Pre-req
###########################

apt-get update
apt-get install -y mariadb-server mariadb-client

echo -e "[mysqld]" >> /etc/mysql/mariadb.cnf
echo -e "sql_mode=NO_ENGINE_SUBSTITUTION"  >> /etc/mysql/mariadb.cnf

systemctl restart mysql

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash - 

apt-get install -y nodejs

apt-get install -y apache2

# change Apache user to asterisk and turn on AllowOverride option
cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Remove default index.html page
rm -f /var/www/html/index.html

echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
wget -qO - https://packages.sury.org/php/apt.gpg | sudo apt-key add -

echo "deb https://packages.sury.org/apache2/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-apache2.list
wget -qO - https://packages.sury.org/apache2/apt.gpg | sudo apt-key add -

apt-get update

apt-get install php8.2 php8.2-mysql php8.2-cgi php8.2-cli php8.2-common php8.2-imap php8.2-ldap \
php8.2-xml php8.2-fpm php8.2-curl php8.2-mbstring php8.2-zip php8.2-gd php8.2-xml php8.2-json \
php8.2-bcmath php8.2-sqlite php-pear -y

apt-get install libapache2-mod-php8.2 -y

pear install Console_Getopt -y

# Add the changed parameters at the end of the file
#sed -i 's/\(^upload_max_filesize = \).*/\512M/' /etc/php/8.2/apache2/php.ini
#sed -i 's/\(^upload_max_filesize = \).*/\512M/' /etc/php/8.2/cli/php.ini
#sed -i 's/\(^memory_limit = \).*/\512M/' /etc/php/8.2/apache2/php.ini 
#sed -i 's/memory_limit = 128M/memory_limit = 512M/' /etc/php/8.2/apache2/php.ini 
echo -e '\n[PHP]' >> /etc/php/8.2/apache2/php.ini
echo -e '\n[PHP]' >> /etc/php/8.2/fpm/php.ini
echo -e '\n[PHP]' >> /etc/php/8.2/cli/php.ini
echo -e '\n[PHP]' >> /etc/php/8.2/cgi/php.ini
echo 'memory_limit = 512M'  >> /etc/php/8.2/apache2/php.ini
echo 'memory_limit = 512M'  >> /etc/php/8.2/fpm/php.ini
echo 'memory_limit = 512M'  >> /etc/php/8.2/cgi/php.ini
echo 'upload_max_filesize = 512M' >> /etc/php/8.2/apache2/php.ini
echo 'upload_max_filesize = 512M' >> /etc/php/8.2/fpm/php.ini
echo 'upload_max_filesize = 512M' >> /etc/php/8.2/cli/php.ini
echo 'upload_max_filesize = 512M' >> /etc/php/8.2/cgi/php.ini

# Install Apache2 Modules 
inst_apache_modules

###########################
#  Install FreePBX 
###########################

systemctl stop asterisk

sleep 10

cd /root
wget https://raw.githubusercontent.com/FreePBX/ucp/release/17.0/node/lib/config.js
wget https://raw.githubusercontent.com/FreePBX/ucp/release/17.0/node/lib/freepbx.js
wget https://raw.githubusercontent.com/FreePBX/ucp/release/17.0/node/lib/server.js


#######

cd /usr/src
wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-17.0-latest.tgz

tar xfz freepbx-17.0-latest.tgz
rm -f freepbx-17.0-latest.tgz

cd /usr/src/freepbx
./start_asterisk start
./install -n 

tee /etc/odbcinst.ini<<EOF
[MySQL]
Description = ODBC for MySQL (MariaDB)
Driver = /usr/lib/x86_64-linux-gnu/odbc/libmaodbc.so
FileUsage = 1
EOF

tee /etc/odbc.ini<<EOF
[MySQL-asteriskcdrdb]
Description = MySQL connection to 'asteriskcdrdb' database
Driver = MySQL
Server = localhost
Database = asteriskcdrdb
Port = 3306
Socket = /var/run/mysqld/mysqld.sock
Option = 3
EOF

tee /etc/systemd/system/freepbx.service<<EOF
[Unit]
Description=FreePBX VoIP Server
After=mariadb.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/fwconsole start -q
ExecStop=/usr/sbin/fwconsole stop -q

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable freepbx.service

fwconsole ma disablerepo commercial
fwconsole ma installall
fwconsole ma delete firewall
fwconsole ma delete sms
fwconsole ma delete xmpp

##### Install patches for Debian 11
cd /var/www/html/admin/modules/ucp/node/lib
mv config.js config.js.orig
mv freepbx.js freepbx.js.orig
mv server.js server.js.orig
cp /root/config.js .
chown asterisk:asterisk config.js
cp /root/freepbx.js .
chown asterisk:asterisk freepbx.js
cp /root/server.js .
chown asterisk:asterisk server.js
cd ../node_modules
npm install mariadb

fwconsole reload
fwconsole restart

###### Install MariaDB access tool
cd /var/www/html
wget https://raw.githubusercontent.com/fdmgit/install-asterisk-freepbx/main/adminer.php
chown asterisk:asterisk adminer.php

##### Create DB user
mysql -u root -e "CREATE USER admindb@localhost IDENTIFIED BY '$DBUSERPWD';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admindb'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

mysql_secure_installation  # make MariaDB secure 

#### Clean up patch files (only Debian 11)


###########################
#  Install Certbot
###########################

apt-get -y install snapd

export PATH=$PATH:/snap/bin

/usr/bin/snap install core
/usr/bin/snap refresh core
/usr/bin/snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

updatedb    #### update locate DB

reboot
