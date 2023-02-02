#!/bin/bash

# Set up the variable to uppercase
declare -u hostname
# Colect the hostname from instance
hostname=`hostname`

# Sybase hosts
declare -u hosts
hosts=("hostname01" "hostname02" "hostname03" "hostname04" "hostname05" "hostname06" "hostname07" "hostname08")

# Check if hostname is in the list of hosts
if [[ ! " ${hosts[@]} " =~ " ${hostname} " ]]; then
    echo "This instance is Hana $hostname"
    
    echo "Backuping up files"
    # file backup
    cp -r /usr/lib/check_mk_agent /usr/lib/check_mk_agent_old

    echo "Checking if the temporary folder exists"
    # Check if the temporary folder exists
    if [ -d "/tmp/checkmk_new" ]; then
        rm -rf /tmp/checkmk_new
    fi

    echo "Creating the temporay folder"
    # creating the temporary folder
    mkdir /tmp/checkmk_new
    cd /tmp/checkmk_new/

    # Download and install the new version of Checkmk
    aws s3 cp s3://<s3-bucket>/check-mk-agent-2.1.0p10-78c9314511479f13.noarch.rpm /tmp/checkmk_new || { echo "Error downloading file"; exit 1; }

    echo "Updating checkmk agent"
    # Update the packet
    rpm -U check-mk-agent-2.1.0p10-78c9314511479f13.noarch.rpm

    echo y > lixo

    echo "Registring checkmk agent end confirm certificate"
    # Registering checkmk
    cmk-update-agent register -H $hostname -U <user> -P <pass> -s <ip> -i <update-server>

    cmk-agent-ctl register -H $hostname -U <user> -P <pass> -s <ip> -i <register-server> < lixo
else
    echo "This instance is Sybase: $hostname"
    ls /etc/check_mk/

    echo "Checking if the temporary folder exists!"
    # Check if the temporary folder exists
    if [ -d "/tmp/checkmk_new" ]; then
        rm -rf /tmp/checkmk_new
    fi

    echo "Creating the checkmk_new folder"
    # creating the temporary folder
    mkdir /tmp/checkmk_new
    cd /tmp/checkmk_new/
    
    #Download the sybase file and script.
    aws s3 cp s3://<s3-bucket>/check_sybase_thresholds /tmp/checkmk_new || { echo "Error downloading file"; exit 1; }
    aws s3 cp s3://<s3-bucket>/check_sybase.sh /tmp/checkmk_new || { echo "Error downloading file"; exit 1; }

    echo "Coping files to /etc/check_mk"
    #Copy files
    cp /tmp/checkmk_new/check_sybase_thresholds /etc/check_mk/
    cp /tmp/checkmk_new/check_sybase.sh /usr/lib/check_mk_agent/local/

    echo "Granting permissions to Sybase Scripting"
    #Put execute permissions
    chmod +x /usr/lib/check_mk_agent/local/check_sybase.sh

    echo "Doing Backup"
    # file backup
    cp -r /usr/lib/check_mk_agent /usr/lib/check_mk_agent_old

    # Download and install the new version of Checkmk
    aws s3 cp s3://<s3-bucket>/check-mk-agent-2.1.0p10-78c9314511479f13.noarch.rpm /tmp/checkmk_new || { echo "Error downloading file"; exit 1; }

    echo "Updating checkmk agent"
    # Update the packet
    rpm -U check-mk-agent-2.1.0p10-78c9314511479f13.noarch.rpm

    echo y > lixo

    echo "Registering agent and confirm certificate"
    # Registering checkmk
    cmk-update-agent register -H $hostname -U <user> -P <pass> -s <ip> -i <update-server>

    cmk-agent-ctl register -H $hostname -U <user> -P <pass> -s <ip> -i <register-server> < lixo

    echo "Runing de Sybase script"
    #Run script Sybase
    /usr/lib/check_mk_agent/local/check_sybase.sh 
fi