# This script performs several tasks related to the Postfix mail server configuration.
# It must be run as the root user and performs the following actions:
# 1. Checks if the script is being run as the root user.
# 2. Checks if the required package(s) (defined in the PACKAGES variable) are installed.
# 3. Removes and recreates the canonical sender map file.
# 4. Removes and recreates the canonical sender map database file.
# 5. Restarts the Postfix service.
# 6. Copies the log file to a specified Google Cloud Storage bucket.
#
# Variables:
# - CANONICAL: Path to the canonical sender map file.
# - CANONICALDB: Path to the canonical sender map database file.
# - DOMAIN: Domain name used in the canonical file.
# - LOGROOT: Directory where the log file will be stored.
# - LOGNAME: Name of the log file, which includes a timestamp.
# - LOGPATH: Full path to the log file.
# - OSTICKETLOGBUCKET: Google Cloud Storage bucket where the log file will be copied.
# - PACKAGES: List of packages to check for installation.
# - ROOTONLY: Flag indicating whether only the root user should be included in the canonical file.
#
# Functions:
# - check_root: Checks if the script is being run as the root user.
# - check_install: Checks if a specified package is installed.
# - create_canonical_file: Removes and recreates the canonical sender map file.
# - create_canonicaldb_file: Removes and recreates the canonical sender map database file.
# - main: Main function that orchestrates the execution of the script.
#!/bin/bash

set -e

CANONICAL=/etc/postfix/canonical
CANONICALDB=$CANONICAL.db
DOMAIN=synanetics.com
LOGROOT=/tmp/
LOGNAME=osticket-startup-script_log_`date +%Y%m%d%H%M%S`.txt
LOGPATH=$LOGROOT$LOGNAME
OSTICKETLOGBUCKET=gs://synanetics-prod-osticket-logs
PACKAGES="postfix"
ROOTONLY=1

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

# Checks whether a package, passed a parameter 1 is installed
check_install() {
        if dpkg --get-selections | grep -q "^$1[[:space:]]*install$" >/dev/null; then
        echo -e "$1 is installed"
                exit 0
    else
        echo -e "$1 is not installed"
                exit 1
    fi
}

# Removes and recreates canonical sender map file
create_canonical_file() {
        if [ -f $CANONICAL ]; then
                rm -rf $CANONICAL
        fi
        if [ $ROOTONLY -eq 1 ]; then
                echo -e "root@`hostname --fqdn` root@`hostname`.$DOMAIN" | tee -a "$CANONICAL"
        else
                for USER in `cat /etc/passwd | grep /bin/bash | cut -d: -f1`; do
                        echo -e "$USER@`hostname --fqdn` $USER@`hostname`.$DOMAIN" | tee -a "$CANONICAL"
                done
        fi
        if [ -s $CANONICAL ]; then
                echo -e "File $CANONICAL has been created"
                exit 0
        else
                echo -e "File $CANONICAL has not been created"
                exit 1
        fi
}

# Removes and recreates canonical sender map db file
create_canonicaldb_file() {
        if [ -f $CANONICALDB ]; then
                rm -rf $CANONICALDB
        fi
        postmap $CANONICAL
        if [ -s $CANONICALDB ]; then
                echo -e "File $CANONICALDB has been created"
                exit 0
        else
                echo -e "File $CANONICALDB has not been created"
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

        # Checks whether package(s) defined in $PACKAGES are installed
        for package in $PACKAGES
        do
                echo "script-status: Checking $package is installed..." | tee -a "$LOGPATH"
                set +e
                message="$(check_install $package)"
                result=$?
                set -e
                if [ $result -eq 0 ]; then
                        echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
                else
                        echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
                        exit 1
                fi
        done

        # Removes and recreates canonical sender map file
        set +e
        message="$(create_canonical_file)"
        result=$?
        set -e
        if [ $result -eq 0 ]; then
                echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
        else
                echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
                exit 1
        fi

        # Removes and recreates canonical sender map db file
        set +e
        message="$(create_canonicaldb_file)"
        result=$?
        set -e
        if [ $result -eq 0 ]; then
                echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
        else
                echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
                exit 1
        fi

        # Restarts postfix service
        set +e
        message="$(service postfix restart)"
        result=$?
        set -e
        if [ $result -eq 0 ]; then
                echo "script-status: $message, continuing script..." | tee -a "$LOGPATH"
        else
                echo "script-status: $message, exiting script..." | tee -a "$LOGPATH"
                exit 1
        fi

        # Copies $LOGPATH to osticket bucket
        echo "script-status: Copying $LOGPATH to $OSTICKETLOGBUCKET" | tee -a "$LOGPATH"
        if ! gsutil cp $LOGPATH $OSTICKETLOGBUCKET; then
                echo "script-status: Copying $LOGPATH to $OSTICKETLOGBUCKET failed, exiting script..." | tee -a "$LOGPATH"
                exit 1
        fi

}

main & disown