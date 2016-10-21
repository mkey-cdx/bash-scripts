#!/bin/bash

# ============================================================================== 
# Get IP address location script
#
# Maintainer: Mickaël Coiraton
# Version 0.2.1
# Updated: 20th October 2016
# 
# This script gets the given IP location from ipinfo.io online service.
#
# ==============================================================================


# Check installed packages.
type -P curl &>/dev/null || { 
    echo "Error: getiplocation.sh requires the program curl... Aborting.";
    exit 10; 
}


# Check parameter.
if [ -z "$1" ] ; then
    echo "You must provide an IP address."
    exit 0;
fi


# Get Information from ipinfo.io
curl ipinfo.io/$1
printf '\n'
exit 0

