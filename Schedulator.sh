#!/bin/bash

# Task Scheduler with Email Notifications and Logging
# Features:
# 1. Schedule commands/scripts to run after specified time
# 2. Register and manage email addresses for notifications
# 3. Send email notifications when tasks complete
# 4. Comprehensive logging
# 5. Email testing functionality
# 6. Task monitoring

# Required packages:
# - mailutils (for mail command)
# - at (for scheduling)
# - postfix (for email sending)
# To install on Debian/Ubuntu:
# sudo apt-get update
# sudo apt-get install -y mailutils at postfix
# sudo systemctl start atd
# sudo systemctl enable atd
# sudo systemctl start postfix
# sudo systemctl enable postfix
# To install on CentOS/RHEL:
# sudo yum install -y mailx at postfix
# sudo systemctl start atd
# sudo systemctl enable atd
# sudo systemctl start postfix
# sudo systemctl enable postfix

# Configuration file paths
CONFIG_DIR="$HOME/.task_scheduler"
EMAIL_FILE="$CONFIG_DIR/registered_emails.txt"
LOG_FILE="$CONFIG_DIR/scheduler.log"
TASK_LOG="$CONFIG_DIR/task_history.log"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also print to console if it's an error
    if [ "$level" = "ERROR" ]; then
        echo "ERROR: $message" >&2
    fi
}

# Check for required commands
check_requirements() {
    local missing_packages=()
    
    # Check for mail command
    if ! command -v mail >/dev/null 2>&1; then
        missing_packages+=("mailutils/mailx")
    fi
    
    # Check for at command
    if ! command -v at >/dev/null 2>&1; then
        missing_packages+=("at")
    fi
    
    # Check for postfix
    if ! command -v postfix >/dev/null 2>&1; then
        missing_packages+=("postfix")
    fi
    
    if [ ${#missing_packages[@]} -ne 0 ]; then
        log "ERROR" "Missing required packages: ${missing_packages[*]}"
        echo "Please install the following packages:"
        echo "For Debian/Ubuntu:"
        echo "sudo apt-get update"
        echo "sudo apt-get install -y ${missing_packages[*]}"
        echo "For CentOS/RHEL:"
        echo "sudo yum install -y ${missing_packages[*]}"
        echo "Then start the required services:"
        echo "sudo systemctl start atd postfix"
        echo "sudo systemctl enable atd postfix"
        exit 1
    fi
}

# Create configuration directory and log files
setup_environment() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        log "INFO" "Created configuration directory: $CONFIG_DIR"
    fi
    
    for file in "$EMAIL_FILE" "$LOG_FILE" "$TASK_LOG"; do
        if [ ! -f "$file" ]; then
            touch "$file"
            log "INFO" "Created file: $file"
        fi
    done
}

# Function to validate email address
validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate time format
validate_time_format() {
    local time="$1"
    if [[ "$time" =~ ^[0-9]+[mhd]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to convert delay format from shorthand to full words
convert_delay() {
    local delay="$1"
    local number="${delay%[mhd]}"
    local unit="${delay##*[0-9]}"
    
    case "$unit" in
        m|M)
            echo "${number} minute"
            ;;
        h|H)
            echo "${number} hour"
            ;;
        d|D)
            echo "${number} day"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Function to register email
register_email() {
    echo "Enter email address to register:"
    read -r email

    if validate_email "$email"; then
        if grep -q "^$email$" "$EMAIL_FILE"; then
            log "WARNING" "Attempted to register duplicate email: $email"
            echo "Email already registered!"
        else
            echo "$email" >> "$EMAIL_FILE"
            log "INFO" "Successfully registered new email: $email"
            echo "Email registered successfully!"
        fi
    else
        log "ERROR" "Invalid email address attempted: $email"
        echo "Invalid email address!"
    fi
}

# Function to list registered emails
list_emails() {
    if [ -s "$EMAIL_FILE" ]; then
        echo "Registered emails:"
        cat "$EMAIL_FILE"
    else
        echo "No emails registered yet."
        log "INFO" "Attempted to list emails but none were registered"
    fi
}

# Function to remove email
remove_email() {
    echo "Enter email address to remove:"
    read -r email

    if grep -q "^$email$" "$EMAIL_FILE"; then
        sed -i "/^$email$/d" "$EMAIL_FILE"
        log "INFO" "Successfully removed email: $email"
        echo "Email removed successfully!"
    else
        log "WARNING" "Attempted to remove non-existent email: $email"
        echo "Email not found!"
    fi
}

# Function to send notification
send_notification() {
    local task="$1"
    local result="$2"
    local success=false
    
    if [ ! -s "$EMAIL_FILE" ]; then
        log "WARNING" "No registered emails found when attempting to send notification"
        return 1
    fi
    
    # Test email configuration
    echo "Testing email configuration..."
    postconf -n > "$CONFIG_DIR/postfix_config.log" 2>&1
    log "INFO" "Postfix configuration saved to: $CONFIG_DIR/postfix_config.log"
    
    while IFS= read -r email; do
        log "INFO" "Attempting to send email notification to: $email"
        
        # Create a more detailed email message
        local email_content="
Task Execution Notification
--------------------------
Task: $task
Status: $result
Execution Time: $(date)
Hostname: $(hostname)
System: $(uname -a)

This is an automated notification.
"
        
        # Send email without the -v option
        if echo "$email_content" | mail -s "Task Execution Notification" "$email" >> "$LOG_FILE" 2>&1; then
            log "INFO" "Successfully sent email notification to: $email"
            success=true
        else
            log "ERROR" "Failed to send email notification to: $email"
            # Log mail server status
            echo "Mail server status:" >> "$LOG_FILE"
            systemctl status postfix >> "$LOG_FILE" 2>&1
        fi
    done < "$EMAIL_FILE"
    
    if [ "$success" = false ]; then
        log "ERROR" "Failed to send any email notifications"
        echo "Email delivery failed. Please check:"
        echo "1. Is postfix running? Run: sudo systemctl status postfix"
        echo "2. Check mail logs: sudo tail -f /var/log/mail.log"
        echo "3. Check script logs: tail -f $LOG_FILE"
        return 1
    fi
}

# Function to schedule task
schedule_task() {
    echo "Enter the command/script to execute:"
    read -r command

    while true; do
        echo "Enter delay time using these formats:"
        echo "  1m  = 1 minute"
        echo "  30m = 30 minutes"
        echo "  1h  = 1 hour"
        echo "  1d  = 1 day"
        echo -n "Enter time: "
        read -r delay

        if validate_time_format "$delay"; then
            converted_delay=$(convert_delay "$delay")
            if [ -n "$converted_delay" ]; then
                break
            else
                log "ERROR" "Invalid time unit entered: $delay"
                echo "Invalid time unit! Please use m(minutes), h(hours), or d(days)"
            fi
        else
            log "ERROR" "Invalid time format entered: $delay"
            echo "Invalid time format! Please use number followed by m(minutes), h(hours), or d(days)"
            echo "Examples: 1m, 30m, 1h, 2h, 1d"
        fi
    done

    # Create a temporary script for at command
    temp_script=$(mktemp)
    log "INFO" "Created temporary script: $temp_script"
    
    cat << EOF > "$temp_script"
#!/bin/bash
CONFIG_DIR="$CONFIG_DIR"
EMAIL_FILE="$EMAIL_FILE"
LOG_FILE="$LOG_FILE"
TASK_LOG="$TASK_LOG"
$(declare -f log)
$(declare -f send_notification)

log "INFO" "Starting execution of scheduled task: $command"
result=\$($command 2>&1) || {
    log "ERROR" "Task execution failed: \$result"
}

echo "Task executed at: \$(date)" >> "\$TASK_LOG"
echo "Command: $command" >> "\$TASK_LOG"
echo "Result: \$result" >> "\$TASK_LOG"
echo "----------------------------------------" >> "\$TASK_LOG"

send_notification "$command" "\$result"
EOF

    chmod +x "$temp_script"
    log "INFO" "Attempting to schedule task: $command for delay: $converted_delay"

    # Check if at daemon is running
    if ! pgrep atd >/dev/null; then
        log "ERROR" "ATD daemon is not running"
        echo "Error: The 'at' daemon is not running. Please start it with:"
        echo "sudo systemctl start atd"
        return 1
    fi

    # Schedule the task
    at_output=$(echo "$temp_script" | at now + "$converted_delay" 2>&1)
    at_status=$?

    if [ $at_status -eq 0 ]; then
        log "INFO" "Successfully scheduled task with delay: $converted_delay"
        echo "Task scheduled successfully!"
        echo "The command '$command' will run after $converted_delay"
        echo "Current time: $(date)"
        echo "Task will run at: $(date -d "now + ${converted_delay}")"
    else
        log "ERROR" "Failed to schedule task. AT command output: $at_output"
        echo "Failed to schedule task. Error: $at_output"
    fi
}

# Function to view scheduled tasks
view_scheduled_tasks() {
    echo "Checking at daemon status..."
    if ! systemctl is-active --quiet atd; then
        echo "ERROR: at daemon (atd) is not running!"
        echo "Please start it with: sudo systemctl start atd"
        return 1
    fi

    echo "Checking scheduled tasks..."
    tasks=$(atq 2>&1)

    if [ -z "$tasks" ]; then
        echo "No scheduled tasks found. This could mean:"
        echo "1. All tasks have already executed"
        echo "2. No tasks were scheduled"
        echo ""
        echo "Recent task history (last 5 tasks):"
        if [ -f "$TASK_LOG" ]; then
            grep "Task executed at:" "$TASK_LOG" | tail -n 5
        else
            echo "No task history found"
        fi
    else
        echo "Currently scheduled tasks:"
        echo "$tasks"
        
        # Show more details about each task
        echo -e "\nDetailed task information:"
        for jobid in $(atq | awk '{print $1}'); do
            echo "Job $jobid details:"
            at -c "$jobid" | tail -n 20
            echo "------------------------"
        done
    fi
}

# Function to test email setup
test_email_setup() {
    echo "Testing email configuration..."
    
    # Check if postfix is installed and running
    if ! command -v postfix >/dev/null 2>&1; then
        echo "ERROR: postfix is not installed"
        echo "Install it with: sudo apt-get install postfix"
        return 1
    fi
    
    # Check postfix status
    if ! systemctl is-active --quiet postfix; then
        echo "ERROR: postfix is not running"
        echo "Start it with: sudo systemctl start postfix"
        return 1
    fi
    
    # Check if any emails are registered
    if [ ! -s "$EMAIL_FILE" ]; then
        echo "No emails registered. Please register an email first."
        return 1
    fi
    
    # Send test email to all registered addresses
    while IFS= read -r email; do
        echo "Sending test email to: $email"
        if echo "This is a test email from task scheduler" | mail -s "Test Email" "$email" >> "$LOG_FILE" 2>&1; then
            echo "Test email sent to $email. Please check your inbox (and spam folder)"
        else
            echo "Failed to send test email to $email"
            echo "Check logs: tail -f $LOG_FILE"
        fi
    done < "$EMAIL_FILE"
    
    echo "Please check the following for troubleshooting:"
    echo "1. Mail logs: sudo tail -f /var/log/mail.log"
    echo "2. Script logs: tail -f $LOG_FILE"
    echo "3. Postfix status: sudo systemctl status postfix"
}

# Function to view logs
view_logs() {
    echo "1. View scheduler logs"
    echo "2. View task execution history"
    read -rp "Enter your choice (1-2): " choice

    case $choice in
        1)
            if [ -s "$LOG_FILE" ]; then
                tail -n 50 "$LOG_FILE"
            else
                echo "No scheduler logs found."
            fi
            ;;
        2)
            if [ -s "$TASK_LOG" ]; then
                tail -n 50 "$TASK_LOG"
            else
                echo "No task execution history found."
            fi
            ;;
        *)
            echo "Invalid choice!"
            ;;
    esac
}

# Function to show help/menu
show_help() {
    cat << EOF
Task Scheduler Usage:
--------------------
1. Register email address
2. List registered emails
3. Remove email address
4. Schedule new task
5. View scheduled tasks
6. View logs
7. Test email setup
8. Exit

Requirements:
- mailutils/mailx (for email notifications)
- at (for task scheduling)
- postfix (for email sending)
EOF
}

# Main script execution starts here
log "INFO" "Script started"
setup_environment
check_requirements

# Main menu
while true; do
    echo
    show_help
    echo
    echo "Enter your choice (1-8):"
    read -rp "Choice: " choice

    case $choice in
        1) register_email ;;
        2) list_emails ;;
        3) remove_email ;;
        4) schedule_task ;;
        5) view_scheduled_tasks ;;
        6) view_logs ;;
        7) test_email_setup ;;
        8)
            log "INFO" "Script terminated by user"
            echo "Goodbye!"
            exit 0
            ;;
        *)
            log "WARNING" "Invalid menu choice: $choice"
            echo "Invalid choice!"
            ;;
    esac
done
