#!/bin/bash 
   # Define user-specific configuration directory and file
   config_dir="$HOME/.autobak"
   config_file="$config_dir/autobak.conf"
   
   # Function to initialize the autobak directory and config file
  initialize() {
      if [[ ! -d $config_dir ]]; then
          mkdir -p "$config_dir"  # No sudo needed here
          echo "Initialization complete: $config_dir directory created."
      fi
      if [[ ! -f $config_file ]]; then
          touch "$config_file"  # No sudo needed here
          echo "Initialization complete: $config_file created."
      else
          echo "Configuration file already exists."
      fi
  }
  
  # Function to check if a job already exists in the config file
  job_exists() {
      local src="$1"
local dest="$2"
      local interval="$3"
  
      grep -q "source=$src" "$config_file" && \
      grep -q "destination=$dest" "$config_file" && \
      grep -q "interval=$interval" "$config_file"
  }
  
  # Function to prompt the user for job details and write to config file if no    t registered
  create_job() {
      echo "Enter source directory:"
      read -r src
      echo "Enter destination directory:"
      read -r dest
      echo "Enter interval (e.g., 5mins, 1hour, 2days, 1week):"
      read -r interval
  
      # Check if the job already exists
      if job_exists "$src" "$dest" "$interval"; then
          echo "Job already exists: $src -> $dest every $interval"
 else
          # Append the job details to the user-specific configuration file
          {
              echo "[Job]"
              echo "source=$src"
              echo "destination=$dest"
              echo "interval=$interval"
          } >> "$config_file"
          echo "Job added to config file: $src -> $dest every $interval"
      fi
  }
  
  # Function to convert human-readable interval to cron syntax
  convert_to_cron_syntax() {
      case "$1" in
          *mins) echo "*/${1%mins} * * * *" ;;
          1hour) echo "0 * * * *" ;;
          2days) echo "0 0 */2 * *" ;;
          1week) echo "0 0 * * 0" ;;
          *) echo "Invalid interval" && return 1 ;;
      esac
  }
# Function to create cron jobs based on config file
  process_config_file() {
      while IFS= read -r line || [[ -n "$line" ]]; do
          case $line in
              source=*) src="${line#source=}" ;;
              destination=*) dest="${line#destination=}" ;;
              interval=*)
                  interval="${line#interval=}"
                  cron_interval=$(convert_to_cron_syntax "$interval")
  
                  # Skip if interval is invalid
                  if [[ "$cron_interval" == "Invalid interval" ]]; then
                      echo "Skipping job with invalid interval: $interval"
                      continue
                  fi
  
                  cron_command="rsync -av --delete \"$src\" \"$dest\""
  
                  # Check if the cron job already exists
                  if crontab -l 2>/dev/null | grep -Fq "$cron_command"; then
                      echo "Cron job already registered: $cron_command"
               echo "Cron job already registered: $cron_command"
                  else
                      (crontab -l 2>/dev/null; echo "$cron_interval $cron_comm    and") | crontab -
                      echo "Cron job registered: $cron_command running at '$cr    on_interval'"
                  fi
                  ;;
          esac
      done < "$config_file"
  }
  
  # Function to list all registered jobs from the config file
  list_jobs() {
      if [[ ! -f $config_file || ! -s $config_file ]]; then
         echo "No jobs registered."
     else
         echo "Registered jobs:"
         echo "----------------"
         awk '
             BEGIN { job_number=0 }
             /^\[Job\]$/ { 
                 job_number++
     printf "Job #%d:\n", job_number
             }
             /^source=/ { 
                 source=substr($0, index($0, "=")+1)
                 printf "  Source: %s\n", source
             }
             /^destination=/ { 
                 destination=substr($0, index($0, "=")+1)
                 printf "  Destination: %s\n", destination
             }
             /^interval=/ { 
                 interval=substr($0, index($0, "=")+1)
                 printf "  Interval: %s\n\n", interval
             }
         ' "$config_file"
     fi
 }
 
 # New Feature 1: Function to remove a specific job
 remove_job() {
     if [[ ! -f $config_file || ! -s $config_file ]]; then
         echo "No jobs to remove."
         return
 fi
 
     echo "Select the job to remove by entering its number:"
     echo "---------------------------------------------"
 
     # List jobs with numbering
     awk '
         BEGIN { job_number=0 }
         /^\[Job\]$/ { 
             job_number++
             printf "Job #%d:\n", job_number
         }
         /^source=/ { 
             source=substr($0, index($0, "=")+1)
             printf "  Source: %s\n", source
         }
         /^destination=/ { 
             destination=substr($0, index($0, "=")+1)
             printf "  Destination: %s\n", destination
         }
         /^interval=/ { 
             interval=substr($0, index($0, "=")+1)
             printf "  Interval: %s\n\n", interval
      }
     ' "$config_file"
 
     # Count total number of jobs
     total_jobs=$(grep -c "^\[Job\]$" "$config_file")
 
     read -rp "Enter the job number to remove (1-$total_jobs): " job_num
 
     # Validate job number
     if ! [[ "$job_num" =~ ^[1-9][0-9]*$ ]]; then
         echo "Invalid input: Please enter a positive integer."
         return
     fi
 
     if (( job_num < 1 || job_num > total_jobs )); then
         echo "Invalid job number. Please enter a number between 1 and $total    _jobs."
         return
     fi
 
     # Extract job details with corrected awk to print the details4
     job_details=$(awk -v num="$job_num" '
         BEGIN { job_number=0; src=""; dest=""; interval="" }
job_number++
             next
         }
         job_number == num && /^source=/ { 
            src=substr($0, index($0, "=")+1)
         }
         job_number == num && /^destination=/ { 
             dest=substr($0, index($0, "=")+1)
         }
         job_number == num && /^interval=/ { 
             interval=substr($0, index($0, "=")+1)
             print src "|" dest "|" interval
             exit
         }
     ' "$config_file")
 
     # Split the job_details into src, dest, and interval using IFS
     IFS='|' read -r src dest interval <<< "$job_details"
 
     if [[ -z "$src" || -z "$dest" || -z "$interval" ]]; then
         echo "Failed to retrieve job details."
         return
     fi
 # Remove the job from the config file
     awk -v num="$job_num" '
         BEGIN { job_number=0; in_target_job=0 }
         /^\[Job\]$/ { 
            job_number++
             if (job_number == num) {
                 in_target_job=1
                 next
             } else {
                 in_target_job=0
             }
         }
         !in_target_job { print }
     ' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$con    fig_file"
 
     echo "Removed job #$job_num: $src -> $dest every $interval"
 
     # Remove corresponding cron job
    cron_command="rsync -av --delete \"$src\" \"$dest\""
                                                                 
# Use crontab -l to list cron jobs, filter out the one to remove, and up    date crontab
     crontab -l 2>/dev/null | grep -Fv "$cron_command" | crontab -
     echo "Corresponding cron job removed."
 }
 
 # New Feature 2: Instructions for Bulk Adding Entries
 # Users can manually edit the config file by following the syntax:
 # [Job]
 # source=/path/to/source
 # destination=/path/to/destination
 # interval=5mins
 # 
 # After adding multiple [Job] sections, they can run "Process All Jobs" to r    egister them.
 
 # Function to process all jobs (including newly added ones)
 process_all_jobs() {
     echo "Processing all jobs in the config file..."
     process_config_file
     echo "All jobs have been processed."
 }
 # Function to display help for bulk editing
 bulk_edit_instructions() {
     echo "To add jobs in bulk, manually edit the config file:"
     echo "Open the config file with your preferred editor, e.g., nano:"
     echo "  nano $config_file"
     echo "Add multiple job entries following the format below:"
     echo ""
     echo "[Job]"
     echo "source=/path/to/source1"
     echo "destination=/path/to/destination1"
     echo "interval=1hour"
     echo ""
     echo "[Job]"
     echo "source=/path/to/source2"
     echo "destination=/path/to/destination2"
     echo "interval=2days"
     echo ""
     echo "After saving the file, select 'Process All Jobs' from the menu to     register them."
 }
 
 # Function to display the main menu with new options
main_menu() {
     while true; do
         echo ""
         echo "Select an option:"
        echo "1) Create a new job"
         echo "2) List all registered jobs"
         echo "3) Remove a job"
        echo "4) Process all jobs (including bulk entries)"
         echo "5) Bulk Edit Instructions"
         echo "6) Exit"
         read -rp "Enter your choice: " choice
 
         case $choice in
             1)
                 create_job
                 process_config_file  # Process jobs after creating them
                 ;;
             2)
                 list_jobs  # Call the list_jobs function
                 ;;
             3)
                 remove_job  # Call the remove_job function
 ;;
             4)
                 process_all_jobs  # Process all jobs, including bulk entries
                 ;;
             5)
                 bulk_edit_instructions  # Show instructions for bulk editing
                 ;;
             6)
                 echo "Exiting."
                 exit 0
                 ;;
            *)
                 echo "Invalid option. Please try again."
                 ;;
         esac     done
 }
 
 # Main execution flow
 echo "Do you want to initialize the autobak system? (yes/no)"
 read -rp "Enter your choice: " init_response
 
 if [[ "$init_response" == "yes" ]]; then
 initialize
 else
     echo "Skipping initialization."
 fi
 
 main_menu

