#!/bin/bash

pkm=""

update_os() {
    echo "Running update for package manager: $pkm"
    case $pkm in
        "apt") sudo apt-get update ;;
        "dnf") sudo dnf update ;;
        "yum") sudo yum update ;;
        "pacman") sudo pacman -Syu ;;
        "zypper") sudo zypper update ;;
        "emerge") sudo emerge --sync ;;
        *) echo "Unknown package manager." ;;
    esac
}

upgrade_os() {
    echo "Running upgrade for package manager: $pkm"
    case $pkm in
        "apt") sudo apt-get upgrade ;;
        "dnf") sudo dnf upgrade ;;
        "yum") sudo yum upgrade ;;
        "pacman") sudo pacman -Syu ;;
        "zypper") sudo zypper dist-upgrade ;;
        "emerge") sudo emerge --update --deep --with-bdeps=y @world ;;
        *) echo "Unknown package manager." ;;
    esac
}

get_pkm() {
    if command -v apt-get >/dev/null 2>&1; then
        pkm="apt"
    elif command -v dnf >/dev/null 2>&1; then
        pkm="dnf"
    elif command -v yum >/dev/null 2>&1; then
        pkm="yum"
    elif command -v pacman >/dev/null 2>&1; then
        pkm="pacman"
    elif command -v zypper >/dev/null 2>&1; then
        pkm="zypper"
    elif command -v emerge >/dev/null 2>&1; then
        pkm="emerge"
    else
        echo "No known package manager found."
        exit 1  # Exit the script if no package manager is found
    fi
}

show_menu() {
    echo "Your Current Package Manager Is $pkm"
    echo "Please choose an option:"
    echo "1. Update OS"
    echo "2. Upgrade OS"
    read -p "Enter your choice (1 or 2): " user_choice

    case $user_choice in
        1) update_os ;;
        2) upgrade_os ;;
        *) echo "Invalid choice. Exiting." ;;
    esac
}

# Call get_pkm to determine the package manager once
get_pkm

# Print the current package manager for debugging
echo "Detected package manager: $pkm"

# Show the menu
show_menu

