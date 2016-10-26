#!/bin/bash

# ============================================================================== 
# SSH knockd connection script.
#
# Maintainer: Mickaël Coiraton
# Version 0.1.6
# Updated: 26th October 2016
#
# This script sends port-hits sequence to knockd deamon and checks 
# remote ssh port state before connecting.
#
# Please edit the following variables at your convenience.
hostname="host.example.com"             # IP address, hostname or fqdn.
port=22                                 # Remote port number.
sequence="xxxx:tcp xxxx:udp xxxx:udp"   # Sequence sent by portkock client.
# ==============================================================================


function usage(){
    echo -e "Usage:\n$0 [OPTION]...\n"
    echo -e "Options:
    -d  --dest              connect to the remote server
    -p  --port              use an alternative SSH port
    -h  --help              show this help\n"
}


function check_package(){
    type -P $1 &>/dev/null || { 
        echo "Error: ssh_portknock.sh requires the program $1... Aborting.";
        exit 10; 
    }
}


# ------------------------------- Main program  --------------------------------


# Show help if asked.
for arg in $@; do
    if [ $arg = "--help" ] || [ $arg = "-h" ]; then
        echo "This tool lets you connect through a knockd protected SSH port."
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


# Check variables.
if [ -z "$hostname" ] || [ -z "$sequence" ] || [ -z "$port" ]; then
    echo "You must provide the remote server information."
    echo "Please edit the internal variables before using this script."
    exit 0
fi


# Check installed packages.
check_package knock
check_package nc


# Check remote host availability.
echo -n "Checking host availability..."
ping -c 1 $hostname > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "\nRemote host is unreachable: $hostname"
    exit 1
else
    echo "done."
fi


# Send knocking sequence and check port state.
echo -n "Sending knocking sequence..."
knock -d 1000 $hostname $sequence
echo "done."

echo -n "Scanning $port port state..."
nc -z -w 2 $hostname $port


# Initiate ssh session.
if [ $? -eq 0 ]; then
    echo "server port is open."
    echo -e "Starting ssh session...\n"
    ssh -p $port $hostname
    exit 0
else
    echo -e "\nError:" $port "server port is closed."
    exit 2
fi
