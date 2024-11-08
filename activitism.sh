#!/bin/bash

# Define log file location (in the user's home directory)
LOGFILE="$HOME/user_activity.log"

# Function to monitor real-time authentication logs
monitor_auth_log() {
    if [ -f /var/log/auth.log ]; then
        # For Ubuntu/Debian systems, capture more general SSH events
        tail -f /var/log/auth.log | grep --line-buffered -E "sshd|Failed password|session opened|session closed|authentication failure" >> $LOGFILE &
        MONITOR_PID=$!
        echo "Monitoring started. Process ID: $MONITOR_PID" >> $LOGFILE
        echo "Monitoring started. Check $LOGFILE for details."
    elif [ -f /var/log/secure ]; then
        # For CentOS/RHEL systems, capture more general SSH events
        tail -f /var/log/secure | grep --line-buffered -E "sshd|Failed password|session opened|session closed|authentication failure" >> $LOGFILE &
        MONITOR_PID=$!
        echo "Monitoring started. Process ID: $MONITOR_PID" >> $LOGFILE
        echo "Monitoring started. Check $LOGFILE for details."
    else
        echo "No auth logs found on this system!" | tee -a $LOGFILE
    fi
}

# Function to stop monitoring
stop_monitoring() {
    if [ -z "$MONITOR_PID" ]; then
        echo "No monitoring process found." | tee -a $LOGFILE
    else
        kill $MONITOR_PID
        echo "Monitoring stopped. Process ID: $MONITOR_PID" | tee -a $LOGFILE
        unset MONITOR_PID
    fi
}

# Display menu for the user
show_menu() {
    echo "Log Monitoring Menu"
    echo "1. Start monitoring authentication logs"
    echo "2. Stop monitoring authentication logs"
    echo "3. Exit"
}

# Handle user input
while true; do
    show_menu
    read -p "Please select an option: " choice
    case $choice in
        1)
            monitor_auth_log
            ;;
        2)
            stop_monitoring
            ;;
        3)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select again."
            ;;
    esac
done

