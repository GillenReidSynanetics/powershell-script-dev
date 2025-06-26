#!/bin/bash
#
# This script gathers and displays system and Google Cloud Platform (GCP) metadata information.
#
# System Variables:
# DATE - Current date and time.
# LOAD - System load average.
# ROOT - Disk usage of the root filesystem.
# MEMORY - Memory usage percentage.
# SWAP - Swap usage percentage.
# USERS - Number of logged-in users.
# UPTIME - System uptime.
# PROCESSES - Number of running processes.
# IP - IP address of the default network interface.
#
# GCP Variables:
# PROJECT - GCP project ID.
# HOSTNAME - GCP instance hostname.
# ID - GCP instance ID.
# MACHINETYPE - GCP instance machine type.
# NAME - GCP instance name.
# ZONE - GCP instance zone.
# ENVIRONMENT - GCP instance environment attribute.
# TEMPLATE - GCP instance template attribute.
# IMAGE - GCP instance image attribute.
# PROXYENVIRONMENT - GCP instance proxy environment attribute.
# PROXYAPPLICATION - GCP instance proxy application attribute.
# PROXYPROJECT - GCP instance proxy project attribute.
# STARTUPSCRIPT - URL of the startup script for the GCP instance.
#
# The script displays:
# - Environment name using figlet.
# - Hostname and distribution information.
# - System information including load, IP address, memory usage, uptime, disk usage, swap usage, number of users, and number of processes.
# - GCP metadata information including project, hostname, ID, machine type, name, zone, environment, proxy project, proxy environment, proxy application, template, image, and startup script.
#
# Usage:
# Run the script in a bash shell to display the system and GCP metadata information.
# Initialise variables
#
# System Variables
DATE=`date`
LOAD=`cat /proc/loadavg | awk '{print $1}'`
ROOT=`df -h / | awk '/\// {print $(NF-1)}'`
MEMORY=`free -m | awk '/Mem:/ { total=$2 } /buffers\/cache/ { used=$3 } END { printf("%3.1f%%", used/total*100)}'`
if [ `free -m | awk '/Swap/' | awk '{print $2}'` -gt "0" ]; then
        SWAP=`free -m | awk '/Swap/ { printf("%3.1f%%", $3/$2*100) }'`
else SWAP=0
fi
USERS=`users | wc -w`
UPTIME=`uptime | grep -ohe 'up .*' | sed 's/,/\ hours/g' | awk '{ printf $2" "$3 }'`
PROCESSES=`ps aux | wc -l`
IP=`ifconfig $(route | grep default | awk '{ print $8 }') | grep "inet" | grep -v "inet6" | awk '{print $2}' | awk '{print $1}'`
# GCP Variables
PROJECT=$(curl -s http://metadata.google.internal/computeMetadata/v1/project/project-id -H "Metadata-Flavor: Google")
HOSTNAME=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/hostname -H "Metadata-Flavor: Google")
ID=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/id -H "Metadata-Flavor: Google")
MACHINETYPE=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/machine-type -H "Metadata-Flavor: Google" | awk -F/ '{ print $(NF) }')
NAME=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/name -H "Metadata-Flavor: Google")
ZONE=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google" | awk -F/ '{ print $(NF) }')
ENVIRONMENT=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/environment -H "Metadata-Flavor: Google")
TEMPLATE=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/template -H "Metadata-Flavor: Google")
IMAGE=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/image -H "Metadata-Flavor: Google")
PROXYENVIRONMENT=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/proxy-environment -H "Metadata-Flavor: Google")
PROXYAPPLICATION=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/proxy-application -H "Metadata-Flavor: Google")
PROXYPROJECT=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/proxy-project -H "Metadata-Flavor: Google")
STARTUPSCRIPT=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/startup-script-url -H "Metadata-Flavor: Google")

# Display environment
figlet $ENVIRONMENT

# Display hostname and distribution
echo
printf "Welcome to %s running %s\n" "$(hostname)" "$(cat /etc/system-release)"
echo

# Display system information
echo "System information as of: $date"
echo
printf "System Load:\t%s\tIP Address:\t%s\n" $LOAD $IP
printf "Memory Usage:\t%s\tSystem Uptime:\t%s\n" $MEMORY "$UPTIME"
printf "Usage On /:\t%s\tSwap Usage:\t%s\n" $ROOT $SWAP
printf "Local Users:\t%s\tProcesses:\t%s\n" $USERS $PROCESSES
echo

# Display GCP metadata
echo "GCP information"
echo
if [[ $PROJECT != "" ]] && [[ ${PROJECT:2:3} != DOC ]]; then
         printf "Project:\t\t%s\n" $PROJECT
else printf "Print:\t\t%s\n" "None Set"
fi
if [[ $HOSTNAME != "" ]] && [[ ${HOSTNAME:2:3} != DOC ]]; then
         printf "Hostname:\t\t%s\n" $HOSTNAME
else printf "Hostname:\t\t%s\n" "None Set"
fi
if [[ $ID != "" ]] && [[ ${ID:2:3} != DOC ]]; then
         printf "Id:\t\t\t%s\n" $ID
else printf "Id:\t\t\t%s\n" "None Set"
fi
if [[ $MACHINETYPE != "" ]] && [[ ${MACHINETYPE:2:3} != DOC ]]; then
         printf "Machine Type:\t\t%s\n" $MACHINETYPE
else printf "Machine Type:\t\t%s\n" "None Set"
fi
if [[ $NAME != "" ]] && [[ ${NAME:2:3} != DOC ]]; then
         printf "Name:\t\t\t%s\n" $NAME
else printf "Name:\t\t\t%s\n" "None Set"
fi
if [[ $ZONE != "" ]] && [[ ${ZONE:2:3} != DOC ]]; then
         printf "Zone:\t\t\t%s\n" $ZONE
else printf "Zone:\t\t\t%s\n" "None Set"
fi
if [[ $ENVIRONMENT != "" ]] && [[ ${ENVIRONMENT:2:3} != DOC ]]; then
         printf "Environment:\t\t%s\n" $ENVIRONMENT
else printf "Environment:\t\t%s\n" "None Set"
fi

if [[ $PROXYPROJECT != "" ]] && [[ ${PROXYPROJECT:2:3} != DOC ]]; then
         printf "Proxy Project:\t%s\n" $PROXYPROJECT
else printf "Proxy Project:\t%s\n" "None Set"
fi

if [[ $PROXYENVIRONMENT != "" ]] && [[ ${PROXYENVIRONMENT:2:3} != DOC ]]; then
         printf "Proxy Environment:\t%s\n" $PROXYENVIRONMENT
else printf "Proxy Environment:\t%s\n" "None Set"
fi

if [[ $PROXYAPPLICATION != "" ]] && [[ ${PROXYAPPLICATION:2:3} != DOC ]]; then
         printf "Proxy Application:\t%s\n" $PROXYAPPLICATION
else printf "Proxy Application:\t%s\n" "None Set"
fi

if [[ $TEMPLATE != "" ]]&& [[ ${TEMPLATE:2:3} != DOC ]]; then
         printf "Template:\t\t%s\n" $TEMPLATE
else printf "Template:\t\t%s\n" "None Set"
fi

if [[ $IMAGE != "" ]] && [[ ${IMAGE:2:3} != DOC ]]; then
         printf "Image:\t\t\t%s\n" $IMAGE
else printf "Image:\t\t\t%s\n" "None Set"
fi

if [[ $STARTUPSCRIPT != "" ]] && [[ ${STARTUPSCRIPT:2:3} != DOC ]]; then
         printf "Startup Script:\t\t%s\n" $STARTUPSCRIPT
else printf "Startup Script:\t\t%s\n" "None Set"
fi
echo