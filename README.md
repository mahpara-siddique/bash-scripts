# Bash Scripts Collection

A collection of useful bash scripts for system administration, file management, task scheduling, log analysis, and network monitoring.

## Scripts Overview

### 1. System Information Script (system_info.sh)
A comprehensive system information gathering tool that provides detailed insights about your system.

#### Features:
- System information display
- CPU information and statistics
- Memory usage monitoring
- Disk usage reporting
- Network information
- System uptime
- Top processes monitoring
- Hardware information
- Battery status (for laptops)
- Memory consumption analysis

#### Usage:
```bash
./system_info.sh
```
Select options 1-11 from the interactive menu to view different system information.

### 2. Task Scheduler (Schedulator.sh)
A robust task scheduling system with email notifications and comprehensive logging.

#### Features:
- Schedule commands/scripts to run after specified time
- Email notification system
- Task execution logging
- Email configuration testing
- Task monitoring capabilities

#### Prerequisites:
- mailutils (or mailx)
- at
- postfix

#### Installation of Dependencies:
For Debian/Ubuntu:
```bash
sudo apt-get update
sudo apt-get install -y mailutils at postfix
sudo systemctl start atd
sudo systemctl enable atd
sudo systemctl start postfix
sudo systemctl enable postfix
```

For CentOS/RHEL:
```bash
sudo yum install -y mailx at postfix
sudo systemctl start atd
sudo systemctl enable atd
sudo systemctl start postfix
sudo systemctl enable postfix
```

#### Usage:
```bash
./Schedulator.sh
```

### 3. Secure File Deletion (delsec.sh)
A script for securely deleting files and directories using the shred command.

#### Features:
- Secure file deletion with overwriting
- Secure directory deletion
- Verification of deletion success

#### Usage:
```bash
./delsec.sh [option] [file|directory]
```

### 4. File Listing Script (renamify.sh)
A simple script to list base names of files in the root directory.

#### Usage:
```bash
./renamify.sh
```

### 5. System Update Script (gradify.sh)
A basic script to update system packages.

#### Usage:
```bash
sudo ./gradify.sh
```

### 6. File Organizer (organizer.sh)
A script that automatically organizes files into directories based on their extensions.

#### Features:
- Automatically creates directories based on file extensions
- Handles files without extensions
- Case-insensitive extension handling
- Preserves original files (creates copies)

#### Usage:
```bash
./organizer.sh [directory_path]
# or
./organizer.sh  # Will prompt for directory path
```

### 7. Log Analyzer (logrism.sh)
A comprehensive log analysis tool with multiple functionality modes.

#### Features:
- Interactive and command-line modes
- Filter logs by category (auth, syslog, kernel, dmesg)
- Search for specific error patterns
- Keyword-based log searching
- Customizable log directory
- Tail functionality for log viewing

#### Usage:
```bash
# Interactive mode
./logrism.sh

# Command-line mode
./logrism.sh -d /var/log -f syslog -c auth -e -k "error" -t 50

Options:
-d: Specify log directory
-f: Specify log file
-c: Filter by category
-e: Show only error logs
-k: Search for keyword
-t: Show last N lines
-h: Show help
```

### 8. Website Status Checker (netchk.sh)
A tool for monitoring website availability with support for bulk checking.

#### Features:
- Single website status checking
- Bulk website checking from file
- HTTPS support
- WWW subdomain handling
- Status code verification
- Output logging
- Redirect handling

#### Usage:
```bash
# Interactive mode
./netchk.sh

# Check single website
./netchk.sh https://example.com [output_file]

# Check multiple websites from file
./netchk.sh -f urls.txt [output_file]
```

## Installation

1. Clone the repository:
```bash
git clone [repository-url]
```

2. Make scripts executable:
```bash
chmod +x *.sh
```

## Requirements

- Bash shell environment
- Root/sudo access for some scripts
- Required packages as mentioned in individual script descriptions
- curl (for netchk.sh)
- Standard Unix utilities (grep, sed, awk)

## Security Considerations

- The scripts should be run with appropriate permissions
- Some scripts (like system_info.sh and gradify.sh) may require sudo privileges
- Be cautious with delsec.sh as file deletion is permanent
- Review email configurations in Schedulator.sh before deployment
- Ensure log files accessed by logrism.sh have appropriate read permissions
- Review website URLs before bulk checking with netchk.sh

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

MIT

## Authors

Mahpara Siddique 👩‍🎤
Touseef Ahmad 👨‍💻


## Acknowledgments

- Thanks to all contributors
- Inspired by common system administration needs
- Built for the open-source community

## Support

For support, please open an issue in the repository.
