# This script performs the following operations:
# 1. Sets up system variables to gather system information such as date, load, root usage, memory usage, swap usage, number of users, uptime, number of processes, and IP address.
# 2. Defines a function to check if the script is running as root.
# 3. Updates and upgrades the system packages.
# 4. Installs PGAdmin4 along with its dependencies.
# 5. Configures PGAdmin4 and logs the patching information.
# 6. Removes the external IP address of the instance if it exists.
# 7. Configures the Message of the Day (MOTD) to display a welcome message and PGAdmin4 access credentials.
# 8. Displays the gathered system information.


#!/bin/bash

# System Variables for the script

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

# Function to check if the script is running as root

check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "Script is running as root"
        exit 0
    else
        echo -e "This script must be run as root"
        exit 1
    fi
}

# Initialize OS patching
apt update && apt upgrade -y

# Deployment of PGAdmin4
apt install -y curl gnupg lsb-release postgressql ufw
curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | gpg --dearmor -o /usr/share/keyrings/pgadmin-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/pgadmin-archive-keyring.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" | tee /etc/apt/sources.list.d/pgadmin4.list
apt update
apt install -y pgadmin4


# Location of PGAdmin4 configuration
touch /var/log/pgadmin4_patch.log
echo "Patched PGADMIN on $(date) - logs can be found in /var/log/pgadmin4_patch.log" >> /var/log/pgadmin4_patch.log

# Local Host Configuration

# 4. Remove external IP (if applicable)
INSTANCE_NAME=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
ZONE=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" | awk -F'/' '{print $NF}')
EXTERNAL_IP=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip" -H "Metadata-Flavor: Google")

if [ ! -z "$EXTERNAL_IP" ]; then
    gcloud compute instances delete-access-config "$INSTANCE_NAME" --zone="$ZONE"
fi

# MOTD Configuration
echo "Welcome to the PGAdmin4 Server" > /etc/motd
echo "This device is used by Synanetics LTD - Authorized use only" >> /etc/motd

# Display system information
echo "System information as of: $date"
printf "System Load:\t%s\tIP Address:\t%s\n" $LOAD $IP
printf "Memory Usage:\t%s\tSystem Uptime:\t%s\n" $MEMORY "$UPTIME"
printf "Usage On /:\t%s\tSwap Usage:\t%s\n" $ROOT $SWAP
printf "Local Users:\t%s\tProcesses:\t%s\n" $USERS $PROCESSES
# End of script