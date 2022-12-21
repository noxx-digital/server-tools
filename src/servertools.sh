#!/bin/bash
#
# ====================
#  Supported commands
# ====================
# 
# servertools <install, add> <service> 
#
# Available services: 
# ===================
#
#   webspace (TODO <apache2|nginx>)
#   mariadb
#   mssql
#   keys
#

source ./functions.sh

init

echo -e "\e[94m === servertools ===\e[39m"

check_root

if [ -z "$1" ]
then
    echo -e "\e[91mArgument <action> not provided.\e[39m"
    exit
fi

if [ -z "$2" ]
then
    echo -e "\e[91mArgument <service> not provided.\e[39m"
    exit
fi

ACTION=$1
SERVICES=${@:2}

# =================== #
# ===== INSTALL ===== #
# =================== #
if [  "$ACTION" == "install" ]
then
    for PARAMETER in $SERVICES;
    do
        # ===== MARIADB ===== #
        if [  "$PARAMETER" == "mariadb" ]
        then
            install_mariadb

        # ===== WEBSPACE ===== #
        elif [  "$PARAMETER" == "webspace" ]
        then
            install_webspace

        # ===== UNKNOW ===== #
        else
            echo -e "\e[33mUnknown <service>: $PARAMETER\e[39m"
        fi
    done

# =============== #
# ===== ADD ===== #
# =============== #
elif [  "$ACTION" == "add" ]
then
    for PARAMETER in $SERVICES;
    do
        # ===== MARIADB ===== #
        if [ "$PARAMETER" == "mariadb" ]
        then
            check_installed "mariadb"
            INSTALLED=$?
            if [ -z "$INSTALLED" ]; then
                echo -e "\e[91mService $1 not installed. Exit.\e[39m"
                exit
            fi
            stdin_user
            stdin_pass
            mariadb_init
            madiadb_add_user

        # ===== WEBSPACE ===== #
        elif [  "$PARAMETER" == "webspace" ]
        then
            check_installed "webspace"
            INSTALLED=$?
            if [ -z "$INSTALLED" ]; then
                echo -e "\e[91mService $1 not installed. Exit.\e[39m"
                exit
            fi
            stdin_user
            stdin_pass
            stdin_port
            #stdin_server_name TODO set with optional parameter
            add_webspace_user
            add_webspace
        
        # ===== UNKNOW ===== #
        else
            echo -e "\e[33mUnknown <service>: $PARAMETER\e[39m"
        fi
    done
else
    echo -e "\e[91mUnknown <action>: $ACTION\e[39m\nAvailable actions are: [install, add]\e[39m"
fi








