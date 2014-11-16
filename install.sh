#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if type curl &>/dev/null
then
	echo "" &>/dev/null
else
	echo "Please install 'curl' to use downloader."
	exit
fi

if [ -f downloader.sh ]
then
	mv downloader.sh /usr/bin/downloader
else
	# todo add here
fi
chmod +x /usr/bin/downloader

echo "Usage: downloader <url> [<chunk size>]"