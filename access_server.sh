#!/bin/bash

# ==============================================================================
# Knockd connexion script
#
# Maintainer: Mickaël Coiraton
# Version 0.1.1
# Updated: 5 February 2017
#
# This script sends port-hits sequence and checks remote ssh port state.
# This sequence is used to open or close target port through knockd daemon.
#
# Please edit the following variables at your convenience.
hostname="host.example.com"                     # IP address, hostname or fqdn.
port=22                                         # Remote port number.
open_sequence="xxxx:tcp xxxx:tcp xxxx:tcp"      # Open sequence sent to knockd.
close_sequence="xxxx:tcp xxxx:tcp xxxx:tcp"     # Close sequence sent to knockd.
# ==============================================================================


function usage(){
    echo -e "Usage:\n$0 open|close [OPTION]...\n"
    echo -e "Options:
    -d  --dest              connect to the remote server
    -p  --port              use an alternative SSH port
    -h  --help              show this help\n"
}


function check_package(){
    type -P $1 &>/dev/null || { 
        echo "Error: $0 requires the program $1... Aborting.";
        exit 10; 
    }
}


function check_host(){
    echo -n "Checking remote host availability..."
    ping -4 -c 1 $hostname > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "\nRemote host is unreachable: $hostname"
        return 1
    else
        echo "done."
        return 0
    fi
}


# ------------------------------- Main program  --------------------------------


# Check given arguments.
if [ $# -eq 0 ]; then
    echo -e "You must provide an argument among 'open' or 'close'.\n"
    usage
    exit 0
fi


# Show help if asked.
for arg in $@; do
    if [ $arg = "--help" ] || [ $arg = "-h" ]; then
        echo "This tool helps you open or close a knockd protected SSH port."
        echo -e "Please edit the internal variables to configure the remote" \
                "host parameters.\n"
        usage
        exit 0
    fi
done


# Rewite variables if provided.
for (( i = 1; i <= $#; i++ )); do
    arg=${@:$i:1}
    if [ $arg = "-d" ] || [ $arg = "--dest" ]; then
        hostname=${@:$i+1:1}
    fi
    if [ $arg = "-p" ] || [ $arg = "--port" ]; then
        port=${@:$i+1:1}
    fi
done


# Checks if packages are installed.
check_package knock
check_package nc


# Main switch case.
case $1 in
    "open")
        if check_host; then
            echo -n "Sending open knocking sequence..."
            knock -d 1000 $hostname $open_sequence

            if [ !`nc -z -w 2 $hostname $port` ]; then
                echo "port" $port "is open."
                echo -e "\nYou can now connect to the remote server."
                echo "Be sure to close this port after you've done."
                exit 0
            else
                echo -e "\nError: port" $port "is closed."
                exit 1
            fi
        fi
    ;;
    "close")
        if check_host; then
            echo -n "Sending close knocking sequence..."
            knock -d 1000 $hostname $close_sequence

            if [ !`nc -z -w 2 $hostname $port` ]; then
                echo "port" $port "is closed."
                echo -e "\nYou can safely disconnect now."
                exit 0
            else
                echo -e "\nWarning: port" $port "is still open."
                exit 1
            fi
        fi
    ;;
    *)
        usage
esac
