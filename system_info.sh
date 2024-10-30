#!/bin/bash

print_heading() {
    echo "================="
    echo "__ $1 __"
    echo "================"
}

# Function to calculate the total number of cores
cal_total_number_of_cpus() {
    local socket=$1
    local cores=$2
    local thread_per_core=$3

    # Formula to calculate number of logical CPUs
    echo $((socket * cores * thread_per_core))
}

# Display menu for user to choose
show_menu() {
    print_heading "System Information Menu"
    echo "1. Show System Information"
    echo "2. Show CPU Information"
    echo "3. Show Memory Usage"
    echo "4. Show Disk Usage"
    echo "5. Show Network Information"
    echo "6. Show Uptime"
    echo "7. Show Top Processes"
    echo "8. Hardware Information"
    echo "9. Battery Information"
    echo "10. Top Memory Processes"
    echo "11. Exit"
    echo "================"
    read -p "Enter your choice [1-11]: " choice
}

# Function to provide the basic system Information
system_information() {
    print_heading 'System Information'
    echo "Hostname: $(hostname)"
    echo "Operating System: $(uname -o)"
    echo "Kernel Version: $(uname -r)"
    echo "Architecture: $(uname -m)"
}

# Function to display CPU information
cpu_info() {
    print_heading 'CPU Information'

    architecture=$(lscpu | grep 'Architecture' | awk '{print $2}')
    model_name=$(lscpu | grep 'Model name' | awk -F: '{print $2}' | sed 's/^ *//')
    number_of_cores=$(lscpu | grep -m 1 'Core(s) per socket' | awk '{print $4}')
    number_of_threads=$(lscpu | grep -m 1 'Thread(s) per core:' | awk '{print $4}')
    number_of_sockets=$(lscpu | grep -m 1 'Socket(s)' | awk '{print $2}')
    frequency=$(lscpu | grep 'MHz' | awk '{print $3}')

    total_cpus=$(cal_total_number_of_cpus "$number_of_sockets" "$number_of_cores" "$number_of_threads")

    echo "Number of Sockets: $number_of_sockets"
    echo "CPU Architecture: $architecture"
    echo "Processor Model: $model_name"
    echo "Total Number of CPU(s): $total_cpus"
    echo "Processor Frequency: $frequency MHz"
}

# Function to display memory usage
memory_info() {
    print_heading 'Memory Usage'
    free -h
}

# Function to display disk usage
disk_info() {
    print_heading 'Disk Usage'
    df -h
}

# Function to display network information
network_info() {
    print_heading 'Network Information'
    ip a
}

# Function to display system uptime
uptime_info() {
    print_heading 'System Uptime'
    uptime
}

# Function to display top processes
process_info() {
    print_heading 'Top Processes'
    top -b -n 1 | head -n 15
}

# Function to display hardware information
hardware_info() {
    print_heading 'Hardware Information'
    sudo dmidecode -t memory
    sudo dmidecode -t baseboard
}

# Function to display battery status (for laptops)
battery_info() {
    print_heading 'Battery Information'
    upower -i $(upower -e | grep BAT)
}

# Function to display top memory consuming processes
top_memory_processes() {
    print_heading 'Top Memory Consuming Processes'
    ps aux --sort=-%mem | head -n 10
}

# Main loop
while true; do
    show_menu
    case $choice in
        1) system_information ;;
        2) cpu_info ;;
        3) memory_info ;;
        4) disk_info ;;
        5) network_info ;;
        6) uptime_info ;;
        7) process_info ;;
        8) hardware_info ;;
        9) battery_info ;;
        10) top_memory_processes ;;
        11) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid choice, please try again!" ;;
    esac
    echo ""
done
