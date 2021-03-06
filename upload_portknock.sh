#!/bin/bash

# ============================================================================== 
# Rsync through knockd uploader script.
#
# Author: Mickaël Coiraton
# Version 0.1.1
# Updated: 26th October 2016
# 
# This script is a wrapper for rsync and knock commands. It lets you upload a file 
# in your remote home folder through a knockd protected port.
#
#
# Please edit the following variables at your convenience.
hostname="host.example.net"             # IP address, hostname or fqdn.
port=22                                 # Remote port number.
sequence="xxxx:tcp xxxx:udp xxxx:udp"   # Sequence sent by portkock client.
dest_folder="uploaded"                  # Destination folder (optional).
# ==============================================================================


function usage(){
    echo -e "Usage:\n$0 [OPTION]... FILE\n"
    echo -e "Options:
    -d  --dest              send file to the remote server
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


# Check given arguments.
if [ $# -eq 0 ]; then
    usage
    exit 0
fi


# Show help if asked.
for arg in $@; do
    if [ $arg = "--help" ] || [ $arg = "-h" ]; then
        echo "This tool provides a simple wrapper for rsync file through a" \
             "knockd protected port."
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
    echo "Use -h for help or edit the internal variables before using" \
         "this script."
    exit 0
fi


# Check installed packages.
check_package nc
check_package rsync


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


# Send given file to remote host.
if [ $? -eq 0 ]; then
    echo "server port is open."
    echo -e "Sending file...\n"
    rsync -avzh -e "ssh -p $port" $1 $USER@$hostname:$dest_folder
    exit 0
else
    echo -e "\nError:" $port "server port is closed."
    exit 2
fi
