#!/bin/bash

function init()
{
    unset USER

     # create etc dir if not exists
    if [ ! -d /etc/servertools ]; then
       mkdir /etc/servertools
    fi
                                     
    # create installed_services file if not exists
    if [ ! -f /etc/servertools/installed_services ]; then
       touch /etc/servertools/installed_services
    fi
}

#-----------------------------------------------#
# UTIL
#-----------------------------------------------#

check_root()
{
    if [ "$EUID" -ne 0 ]
    then
        echo "\e[91mMust be root to run this script. Exit.\e[39m"
        exit $E_NOTROOT
    fi
}

#-----------------------------------------------#
# INSTALL
#-----------------------------------------------#

function install_webspace()
{
    check_installed "webspace"
    local INSTALLED=$?
    if [ "$INSTALLED" == 1 ]; then
        echo -e "\e[33mWebspace already installed. Skip.\e[39m"
        return 0
    else
        echo -e "Installing webspace .."
        apt update > /dev/null 2>&1
        apt install -y apache2 php7.4 > /dev/null 2>&1
        echo "webspace" >> /etc/servertools/installed_services
        echo -e "Done."
    fi
    
}

function install_mariadb()
{
    check_installed "mariadb"
    local INSTALLED=$?
    if [ "$INSTALLED" == 1 ]; then
        echo -e "\e[33mMariadb already installed. Skip.\e[39m"
        return 0
    else
        echo -e "Installing mariadb .."
        apt update > /dev/null 2>&1
        apt install -y mariadb-server > /dev/null 2>&1
        echo "mariadb" >> /etc/servertools/installed_services
        echo -e "Done."
    fi
}

function check_installed()
{
    if [ -z "$1" ]
    then
        echo -e "\e[91m########\e[39m"
        exit
    fi

    INSTALLED_SERVICES=$(</etc/servertools/installed_services)

    for INSTALLED_SERVICE in $INSTALLED_SERVICES;
    do
        if [ "$INSTALLED_SERVICE" == "$1" ];
        then
            return 1
        fi
    done
    return 
}


#-----------------------------------------------#
# STDIN
#-----------------------------------------------#

function stdin_user()
{
    if [ -z "$USER" ]
    then
        echo -n "Username: "
        read USER
    fi
}

function stdin_pass()
{
    if [ -z "$PASS" ]
    then
        echo -n "Password: "
        read PASS
    fi
}

function stdin_port()
{
    if [ -z "$PORT" ]
    then
        echo -n "Port: "
        read PORT
    fi
}

function stdin_server_name()
{
    if [ -z "$SERVER_NAME" ]
    then
        echo -n "Servername: "
        read SERVER_NAME
    fi
}

#-----------------------------------------------#
# APACHE
#-----------------------------------------------#

function add_webspace_user()
{
    echo -e "Adding webspace user .."
    useradd -M -g www-data "$USER" > /dev/null 2>&1                     # add user with grou www-data
    groupadd "$USER"                                                    # add user group
    mkdir -p /home/"$USER"                                              # add user home dir
    chown "$USER":"$USER" /home/"$USER"                                 # set owner of home dir
    usermod -d /home/"$USER" "$USER"                                    # set permissions of home dir
    echo "$USER":"$PASS" | chpasswd                                     # set user password        
    usermod -s /bin/bash $USER                                          # set default shell to bash
    mkdir /var/www/"$USER" > /dev/null 2>&1                             # create webspace dir
    chown "$USER":www-data /var/www/"$USER" > /dev/null 2>&1            # set webspace dir owner
    find /var/www/"$USER" -type d -exec chmod 755 {} +                  # set webspace dir permissions
    find /var/www/"$USER" -type f -exec chmod 644 {} +                  # set webspace file permissions 
    echo -e "Done."
}

function add_webspace()
{
    echo -e "Adding webspace .."
    APACHE_CONF="$(<apache2-default.conf)"                              # read config template
    APACHE_CONF=${APACHE_CONF//USER/"$USER"}                            # set user name as document root (DocumentRoot /var/www/USER)
    APACHE_CONF=${APACHE_CONF//PORT/"$PORT"}                            # set port
    APACHE_CONF=${APACHE_CONF//SERVER_NAME/"$SERVER_NAME"}              # set server name
    echo "$APACHE_CONF" > /etc/apache2/sites-available/$USER.conf       # save conf to sites-available
    echo -e "\nListen $PORT\n" >> /etc/apache2/ports.conf               # append port listening
    a2ensite $USER.conf > /dev/null 2>&1                                # enable site
    systemctl reload apache2                                            # apache reload
    systemctl restart apache2                                           # apache restart
    echo -e "Done."
}

#-----------------------------------------------#
# MARIADB
#-----------------------------------------------#

function mariadb_init()
{
mysql --user=root << _EOF_
    UPDATE mysql.user SET Password=PASSWORD('blumentopf123') WHERE User='root';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    FLUSH PRIVILEGES;
_EOF_
}

function madiadb_add_user()
{
mysql --user=root <<_EOF_
    CREATE DATABASE IF NOT EXISTS $USER;
    CREATE USER '$USER'@'localhost' IDENTIFIED BY '$PASS';
    GRANT ALL PRIVILEGES ON $USER.*  TO '$USER'@'localhost';
    FLUSH PRIVILEGES;
_EOF_
}