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

message () {
    echo -e "\n${LBLUE} ---------------------------------------"
    echo -e "\n Select setup of FreePBX / Asterisk:"
    echo -e " 1: Asterisk 16 / FreePBX 16 (Debian 10)"
    echo -e " 2: Asterisk 18 / FreePBX 16 (Debian 10)"
    echo -e "\n ---------------------------------------"
    echo -e "\n"
    read -p " Select (1,2) : ${NC}" SELECT
}

fop2msg () {
    echo -e "\n${LBLUE} ---------------------------------------"
    echo -e "\n Do you want to install FOP2 ?"
    read -p " Install FOP2 (y/n) : ${NC}" FOP2INST
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

echo -e "${LYELLOW} Starting ...${NC}"

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
    echo -e "${YELLOW} The Installation is only supported on Debian 10 / 11 systems!${NC}"
    exit 1
fi

############
#### Get parameters and choose installation option
############

enterparameters
clear             # clear screen

if [[ "$os_release" != "11" ]]; then
    while $okinput; do
        message  
        if [ "$SELECT" -ge 1 ] && [ "$SELECT" -le 2 ]; then
            okinput=false
        else
            clear
            echo -e  "\n\n${LRED} >>>>  Wrong selection ! Try again.${NC}"
            message
        fi
    done
fi

clear              # clear screen
okinput=true

while $okinput; do
    fop2msg  
    FOP2INST=${FOP2INST^^}
    if [[ "$FOP2INST" == "Y" ]] || [[ "$FOP2INST" == "N" ]]; then
        okinput=false
    else
        clear.     # clear screen
        echo -e  "\n\n${LRED} >>>>  Wrong selection ! Try again.${NC}"
        fop2msg
    fi
done

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

apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python unzip shared-mime-info
wget http://prdownloads.sourceforge.net/webadmin/webmin_2.010_all.deb
dpkg --install webmin_2.010_all.deb
rm webmin_2.010_all.deb


##############################
#  Some additional programs
##############################

apt-get install plocate -y
updatedb

echo "root:$ROOTPW" | chpasswd   # set root password -
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

read -p "check log" GOON

##############################
#  Install Asterisk 
##############################

cd /usr/src/
if [[ "$SELECT" == "1" ]]; then    # Asterisk 16 on Debian 10
    wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz
    tar xvf asterisk-16-current.tar.gz
    rm asterisk-16-current.tar.gz
    cd asterisk-16*/
else                               # Asterisk 18 on Debian 16 or Debian 11 
    wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz
    tar xvf asterisk-18-current.tar.gz
    rm asterisk-18-current.tar.gz
    cd asterisk-18*/
fi

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

sleep 15

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

echo 'Sleep now'
sleep 15
echo 'Sleep done'


###########################
#  Install FreePBX Pre-req
###########################

apt-get update
apt-get install -y mariadb-server mariadb-client

echo '[mysqld]' >> /etc/mysql/mariadb.cnf
echo 'sql_mode=NO_ENGINE_SUBSTITUTION'  >> /etc/mysql/mariadb.cnf

systemctl restart mysql

if [[ "$os_release" != "11" ]]; then        # check with Debian version is used. Node 14 only on Debian 11
    curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
else
    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
fi

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

apt-get install php7.4 php7.4-mysql php7.4-cgi php7.4-cli php7.4-common php7.4-imap php7.4-ldap \
php7.4-xml php7.4-fpm php7.4-curl php7.4-mbstring php7.4-zip php7.4-gd php7.4-xml php7.4-json \
php7.4-bcmath php7.4-sqlite php-pear -y

apt-get install libapache2-mod-php7.4 -y

pear install Console_Getopt -y

# Add the changed parameters at the end of the file
#sed -i 's/\(^upload_max_filesize = \).*/\512M/' /etc/php/7.4/apache2/php.ini
#sed -i 's/\(^upload_max_filesize = \).*/\512M/' /etc/php/7.4/cli/php.ini
#sed -i 's/\(^memory_limit = \).*/\512M/' /etc/php/7.4/apache2/php.ini 
#sed -i 's/memory_limit = 128M/memory_limit = 512M/' /etc/php/7.4/apache2/php.ini 
echo -e '\n[PHP]' >> /etc/php/7.4/apache2/php.ini
echo -e '\n[PHP]' >> /etc/php/7.4/fpm/php.ini
echo -e '\n[PHP]' >> /etc/php/7.4/cli/php.ini
echo -e '\n[PHP]' >> /etc/php/7.4/cgi/php.ini
echo 'memory_limit = 512M'  >> /etc/php/7.4/apache2/php.ini
echo 'memory_limit = 512M'  >> /etc/php/7.4/fpm/php.ini
echo 'memory_limit = 512M'  >> /etc/php/7.4/cgi/php.ini
echo 'upload_max_filesize = 512M' >> /etc/php/7.4/apache2/php.ini
echo 'upload_max_filesize = 512M' >> /etc/php/7.4/fpm/php.ini
echo 'upload_max_filesize = 512M' >> /etc/php/7.4/cli/php.ini
echo 'upload_max_filesize = 512M' >> /etc/php/7.4/cgi/php.ini

# Enable Apache Rewrite engine 
a2enmod rewrite
systemctl restart apache2

###########################
#  Install FreePBX 
###########################

systemctl stop asterisk

echo 'Sleep now'
sleep 15
echo 'Sleep done'

############ Prepare update to support node.js > 11 (only on Debian 11)
if [[ "$os_release" == "11" ]]; then
    cd /root
    wget https://raw.githubusercontent.com/FreePBX/ucp/release/17.0/node/lib/config.js
    wget https://raw.githubusercontent.com/FreePBX/ucp/release/17.0/node/lib/freepbx.js
    wget https://raw.githubusercontent.com/FreePBX/ucp/release/17.0/node/lib/server.js
fi

#######

cd /usr/src
wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-16.0-latest.tgz

tar xfz freepbx-16.0-latest.tgz
rm -f freepbx-16.0-latest.tgz

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
if [[ "$os_release" == "11" ]]; then
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
fi

sudo fwconsole reload
sudo fwconsole restart

###########################
#  Install FOP2
###########################

if [[ "$FOP2INST" == "Y" ]]; then
    cd /usr/src
    wget http://www.fop2.com/download/debian64 -O fop2.tgz
    tar zxvf fop2.tgz
    cd fop2
    make
    cp server/create_fop2_manager_user.pl .
    chmod a+x create_fop2_manager_user.pl
    ./create_fop2_manager_user.pl
    /usr/sbin/asterisk -rx "manager reload"
    /usr/local/fop2/generate_override_contexts.pl -w
    service fop2 restart
    rm /usr/src/fop2.tgz
fi

###### Install MariaDB access tool
cd /var/www/html
wget https://raw.githubusercontent.com/fdmgit/install-asterisk-freepbx/main/adminer.php
chown asterisk:asterisk adminer.php

##### Create DB user
mysql -u root -e "CREATE USER admindb@localhost IDENTIFIED BY '$DBUSERPWD';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admindb'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

mysql_secure_installation  # make MariaDB secure 

#### Clean up

if [[ "$os_release" == "11" ]]; then
    cd /root
    rm config.js
    rm freepbx.js
    rm server.js
fi

updatedb    #### update locate DB

reboot
