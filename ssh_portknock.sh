#!/bin/bash

# ============================================================================== 
# SSH knockd connection script.
#
# Author: Mickaël Coiraton
# Version 0.1.5
# Updated: 14nd October 2016
#
# This script sends port-hits sequence to knockd deamon and checks 
# remote ssh port state before connecting.
# Please edit theses variable at your convenience.
#
# IP address, hostname or fqdn.
hostname="host.example.com"     
# Remote port number to scan.     
port=22
# Sequence sent by kockd client.
sequence="4900:tcp 6566:udp 4030:udp"
# ==============================================================================


# Check variables.
if [ -z "$hostname" ] || [ -z "$sequence" ] || [ -z "$port" ]; then
    echo "You must provide the remote server information."
    echo "Please edit the variables before using this script."
    exit
fi


# Check installed packages.
type -P knock &>/dev/null || { echo "Error: ssh_portknock.sh requires the program knock... Aborting."; echo; exit 10; }
type -P nc &>/dev/null || { echo "Error: ssh_portknock.sh requires the program nc... Aborting."; echo; exit 10; }


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
