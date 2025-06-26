# This script performs the following operations:
# 1. Checks if the script is being run as the root user.
# 2. Creates necessary directories if they do not exist, or clears them if they do.
# 3. Copies configuration files from Google Cloud Storage buckets to local directories.
# 4. Creates a Docker Compose file for the TPP JWT Signer service.
# 5. Copies Nginx configuration files from a Google Cloud Storage bucket to the local Nginx directory.
# 6. Copies the Message of the Day (motd) script from a Google Cloud Storage bucket to the local profile directory.
# 7. Copies Google Cloud Ops Agent configuration files from a Google Cloud Storage bucket to the local Ops Agent directory.
# 8. Restarts the Google Cloud Ops Agent service.
# 9. Pulls the TPP JWT Signer Docker image from Google Container Registry.
# 10. Starts Docker services using Docker Compose.
# 11. Restarts the Nginx service.
# 12. Copies the script log to a Google Cloud Storage bucket.
# 
# The script logs its progress and any errors to a log file in the /tmp/ directory.
# The log file is named based on the hostname, proxy environment, and the current timestamp.
# The script exits with a status code of 0 if all operations are successful, or 1 if any operation fails.
#!/bin/bash

set -e

HOSTNAME=$(hostname)
PROXYENVIRONMENT=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/proxy-environment -H "Metadata-Flavor: Google")
PROXYAPPLICATION=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/proxy-application -H "Metadata-Flavor: Google")
LOGROOT=/tmp/
LOGNAME=$HOSTNAME-yhcr-proxy-$PROXYENVIRONMENT-startup-script_log_$(date +%Y%m%d%H%M%S).txt
LOGPATH=$LOGROOT$LOGNAME
LOGBUCKET=gs://yhcr-proxy-logs/$PROXYAPPLICATION/$PROXYENVIRONMENT
DOCKERCOMPOSEDIRECTORY=/docker/compose
NGINXCONFIGBUCKET=gs://yhcr-proxy-config/$PROXYAPPLICATION/$PROXYENVIRONMENT/nginx
NGINXCONFIGDIRECTORY=/etc/nginx/conf.d
NGINXDIRECTORY=/etc/nginx
OPSAGENTCONFIGBUCKET=gs://yhcr-proxy-config/$PROXYAPPLICATION/$PROXYENVIRONMENT/ops-agent
OPSAGENTCONFIGDIRECTORY=/etc/google-cloud-ops-agent
TPPJWTSIGNERIMAGE=eu.gcr.io/management-265012/tpp-jwt-signer:tjs-v1.0.0
MOTDBUCKET=gs://yhcr-proxy-scripts/tpp/production/profile
MOTDDIRECTORY=/etc/profile.d
DOCKERCONFIGDIRECTORY=/root/.docker/
DOCKERCONFIGFILE=gs://yhcr-proxy-config/$PROXYAPPLICATION/$PROXYENVIRONMENT/docker/config.json

# Checks whether script is being run as root user
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "Script is running as root"
        exit 0
        else
        echo -e "This script must be run as root"
        exit 1
    fi
}
# Create directory, if it doesn't exist. If directory already exists, its contents are deleted
create_directory() {
    local DIRECTORY=$1
    if [ ! -d $DIRECTORY ]; then
        mkdir -p $DIRECTORY
    else
        rm -f $DIRECTORY/*
    fi
    if [ -d $DIRECTORY ]; then
        echo -e "Directory $DIRECTORY has been created or already exists"
        exit 0
    else
        echo -e "Directory $DIRECTORY has been not been created and does not exist"
        exit 1
    fi
}

# Copies files from storage bucket
copy_bucket_files() {
	local BUCKET=$1
	local LOCAL=$2
    if gsutil cp -r $BUCKET $LOCAL; then
        echo -e "Copied config files from bucket $BUCKET"
        exit 0
    else
        echo -e "Unable to copy config files from bucket $BUCKET"
        exit 1
    fi	
}

create_docker_compose() {
    DOCKERCOMPOSE=$DOCKERCOMPOSEDIRECTORY/docker-compose.yml
    tee $DOCKERCOMPOSE > /dev/null << EOF
version: "3.9"
services:
  tpp-jwt-signer:
    image: "$TPPJWTSIGNERIMAGE"
    ports:
      - "8080:8080"
EOF
    if [ -s $DOCKERCOMPOSE ]; then
        echo -e "Created docker-compose.yml"
        exit 0
	else
	    echo -e "Unable to create docker-compose.yml"
        exit 1
    fi
}

main() {
    # Checks script is running as root
    echo "script-status: Checking script is running as root..." | tee -a "$LOGPATH"
    set +e
    message="$(check_root)"
    result=$?
    set -e
    if [ $result -eq 0 ]; then
        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
    else
        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
        exit 1
    fi

    # Checks whether Docker compose directory exists, and creates it if missing
    set +e
    message="$(create_directory $DOCKERCOMPOSEDIRECTORY)"
    result=$?
    set -e
    if [ $result -eq 0 ]; then
        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
    else
        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
        exit 1
    fi
	
	# Creates Docker compose file
    set +e
    message="$(create_docker_compose)"
    result=$?
    set -e
    if [ $result -eq 0 ]; then
        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
    else
        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
        exit 1
    fi

    # Checks whether nginx directory exists, and creates it if missing
    set +e
    message="$(create_directory $NGINXCONFIGDIRECTORY)"
    result=$?
    set -e
    if [ $result -eq 0 ]; then
        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
    else
        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
        exit 1
    fi
	
	# Copy Nginx config file from storage bucket
    set +e
    message="$(copy_bucket_files $NGINXCONFIGBUCKET/* $NGINXDIRECTORY)"
    result=$?
    set -e
    if [ $result -eq 0 ]; then
        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
    else
        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
        exit 1
    fi

    # Copy motd from storage bucket
    set +e
	message="$(copy_bucket_files $MOTDBUCKET/* $MOTDDIRECTORY)"
    result=$?
    set -e
    if [ $result -eq 0 ]; then
		chmod 755 $MOTDDIRECTORY/motd.sh
        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
    else
        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
        exit 1
    fi
	
	# Copy Google Cloud Ops Agent config from storage bucket
    set +e
	message="$(copy_bucket_files $OPSAGENTCONFIGBUCKET/* $OPSAGENTCONFIGDIRECTORY)"
    result=$?
    set -e
    if [ $result -eq 0 ]; then
        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
    else
        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
        exit 1
    fi
	
	# Restarts Google Cloud Ops Agent service
    set +e
    message="$(service google-cloud-ops-agent restart)"
    result=$?
    set -e
    if [ $result -eq 0 ]; then
        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
    else
        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
        exit 1
    fi

    # Pull TPP Signer Docker image
	set +e
    message="$(docker pull $TPPJWTSIGNERIMAGE)"
    result=$?
    set -e
    if [ $result -eq 0 ]; then
        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
    else
        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
        exit 1
    fi
		
    # Starts Docker services using docker-compose 
    set +e
	cd $DOCKERCOMPOSEDIRECTORY
    message="$(docker-compose up -d)"
    result=$?
    set -e
    if [ $result -eq 0 ]; then
        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
    else
        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
        exit 1
    fi
	
	# Restarts nginx service
    set +e
    message="$(service nginx restart)"
    result=$?
    set -e
    if [ $result -eq 0 ]; then
        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
    else
        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
        exit 1
    fi

    # Copies log to storage bucket
    echo "script-status: Copying $LOGPATH to $LOGBUCKET" | tee -a "$LOGPATH"
    if ! gsutil cp $LOGPATH $LOGBUCKET/$LOGNAME; then
        echo "script-status: Copying $LOGPATH to $LOGBUCKET failed, exiting script..." | tee -a "$LOGPATH"
        exit 1
	else 
		echo "script-status: Copying $LOGPATH to $LOGBUCKET succeeded, exiting script..."
		exit 0
    fi

}

main & disown