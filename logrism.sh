#!/bin/bash

# Define default log directory and log categories
LOG_DIR="/var/log"
LOG_FILE=""
ERROR_KEYWORDS=("error" "failed" "critical" "panic" "exception")
CATEGORY=""
KEYWORD=""
SHOW_ERROR_LOGS=0
TAIL_LINES=50
HELP=0
INTERACTIVE=0

# Function to display help menu
show_help() {
    echo "Usage: $0 [options]
    -d <directory>    Specify log directory (default: /var/log)
                      Example: $0 -d /home/user/logs
                      Description:This option changes the default directory     where logs are searched.
                                    Use it if your logs are stored in a custom     location.                   

   
 -f <file>            Specify a log file (if you want to look into a specific log file)
                      Example: $0 -f /var/log/syslog
                      Description:Use this to inspect a specific log file lik    e 'syslog', 'auth.log', etc.
                                   Useful if you know exactly which log file y    ou want to check.   


 -c <category>        Filter logs by category (e.g., 'auth', 'syslog', 'kernel', etc.)
                      Example: $0 -c auth   
                      Description: This option filters logs by predefined cat    egories such as 'auth' for authentication logs,
                                 'kernel' for kernel messages, etc. Helps nar    row down specific system areas.  

 -e                   Show only error logs (e.g., failed, error, panic, etc.)
                      Example: $0 -e  
                      Description: Use this to display only the error-related     logs across the specified log file or category.
                                    Helpful for quickly spotting critical issues.   


 -k <keyword>         Search for specific keyword in the logs
                      Example: $0 -k "critical"
                      Description: Search the log files for any specific keyw    ord, like 'network', 'disk', or 'user'.
                                    Great for pinpointing specific issues or events.   

 -t <lines>           Show the last N lines of log (default: 50)
                      Example: $0 -t 100  
                      Description: Use this to display the last 'N' lines fro    m the log file. Increase the number if you want
                                   to see more history from the log, such as t    he last 100 lines.   

 -h                   Show this help message
                      Example: $0 -h  
                      Description: Displays this help message, explaining the     options and examples.  

  No options will start an interactive mode.
    "
    exit 0
}

# Function to find logs by category
find_category_log() {
    case "$1" in
        auth) LOG_FILE="$LOG_DIR/auth.log" ;;
        syslog) LOG_FILE="$LOG_DIR/syslog" ;;
        kernel) LOG_FILE="$LOG_DIR/kern.log" ;;
        dmesg) LOG_FILE="$LOG_DIR/dmesg" ;;
        *) echo "Unknown category. Available categories: auth, syslog, kernel, dmesg." && exit 1 ;;
    esac
}

# Function to search logs for error keywords
search_error_logs() {
    if [ -n "$LOG_FILE" ]; then
        echo "Searching for error logs in $LOG_FILE"
       # grep -iE "${ERROR_KEYWORDS[*]}" "$LOG_FILE"
       grep -iE "$(IFS='|'; echo  "${ERROR_KEYWORDS[*]}")" "$LOG_FILE"
    else
        echo "No specific log file selected for error log search!"
    fi
}

# Interactive menu for user
interactive_menu() {
    while true; do
        echo "====================="
        echo "  Log Finder - Menu  "
        echo "====================="
        echo "1) Show last N lines of logs"
        echo "2) Search logs by category"
        echo "3) Search for error logs"
        echo "4) Search for keyword in logs"
        echo "5) Change log directory"
        echo "6) Exit"
        echo "====================="
        read -p "Choose an option: " choice

        case "$choice" in
            1)
                read -p "Enter the number of lines to display: " lines
                read -p "Enter log file name (default syslog if blank): " log_file
                if [ -z "$log_file" ]; then
                    log_file="$LOG_DIR/syslog"
                fi
                tail -n "$lines" "$log_file"
                ;;
            2)
                echo "Categories: auth, syslog, kernel, dmesg"
                read -p "Enter category: " category
                find_category_log "$category"
                tail -n "$TAIL_LINES" "$LOG_FILE"
                ;;
            3)
                echo "Searching for error logs..."
                find_category_log "syslog"  # Default to syslog for error logs
                search_error_logs
                ;;
            4)
                read -p "Enter keyword to search: " keyword
                read -p "Enter log file name (default syslog if blank): " log_file
                if [ -z "$log_file" ]; then
                    log_file="$LOG_DIR/syslog"
                fi
                grep -i "$keyword" "$log_file"
                ;;
            5)
                read -p "Enter new log directory: " new_dir
                if [ -d "$new_dir" ]; then
                    LOG_DIR="$new_dir"
                    echo "Log directory changed to $LOG_DIR"
                else
                    echo "Directory does not exist!"
                fi
                ;;
            6)
                echo "Exiting..."
                break
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac
    done
}

# Parse options passed to the script
while getopts ":d:f:c:k:t:eh" opt; do
    case ${opt} in
        d ) LOG_DIR="$OPTARG" ;;
        f ) LOG_FILE="$OPTARG" ;;
        c ) CATEGORY="$OPTARG"; find_category_log "$CATEGORY" ;;
        e ) SHOW_ERROR_LOGS=1 ;;
        k ) KEYWORD="$OPTARG" ;;
        t ) TAIL_LINES="$OPTARG" ;;
        h ) HELP=1 ;;
        \? ) echo "Invalid option: -$OPTARG" && show_help ;;
    esac
done

# If help is requested
if [ $HELP -eq 1 ]; then
    show_help
fi

# If no options were passed, load the interactive menu
if [ "$OPTIND" -eq 1 ]; then
    INTERACTIVE=1
fi

# Interactive mode
if [ $INTERACTIVE -eq 1 ]; then
    interactive_menu
else
    # If log file is specified, override the category
    if [ -n "$LOG_FILE" ]; then
        echo "Using specific log file: $LOG_FILE"
    elif [ -n "$CATEGORY" ]; then
        echo "Using log file for category '$CATEGORY': $LOG_FILE"
    else
        echo "No specific log file or category specified, using default syslog."
        LOG_FILE="$LOG_DIR/syslog"
    fi

    # Display logs or search for a keyword
    if [ -n "$KEYWORD" ]; then
        echo "Searching for '$KEYWORD' in $LOG_FILE"
        grep -i "$KEYWORD" "$LOG_FILE"
    elif [ $SHOW_ERROR_LOGS -eq 1 ]; then
        search_error_logs
    else
        echo "Displaying the last $TAIL_LINES lines of $LOG_FILE"
        tail -n "$TAIL_LINES" "$LOG_FILE"
    fi
fi
