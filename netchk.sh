#!/bin/bash

# Function to check the website status with redirection handling
check_website_status() {
    URL=$1
    # Use curl with -L to follow redirects and get the final HTTP status code
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -L "$URL")

    if [ "$RESPONSE" -eq 200 ]; then
        echo "The website $URL is UP."
        echo "The website $URL is UP." >> "$OUTPUT_FILE"
        return 0
    else
        echo "The website $URL is DOWN or not reachable. Status Code: $RESPONSE"
        echo "The website $URL is DOWN or not reachable. Status Code: $RESPONSE" >> "$OUTPUT_FILE"
        return 1
    fi
}

# Function to add www if not present, but only if it doesn't already have www
add_www_if_needed() {
    URL=$1
    # Remove protocol (http or https) for checking the domain
    DOMAIN=$(echo "$URL" | sed -e 's|http[s]\?://||')
    
    # Check if the domain starts with 'www.', if not, add 'www.'
    if [[ "$DOMAIN" != www.* ]]; then
        URL_WITH_WWW="www.$DOMAIN"
        echo "$URL_WITH_WWW"
    else
        echo "$DOMAIN"
    fi
}

# Function to process a bulk file of URLs
process_bulk_file() {
    FILE=$1
    if [ ! -f "$FILE" ]; then
        echo "File not found!"
        exit 1
    fi

    while IFS= read -r line; do
        DOMAIN_ONLY=$(echo "$line" | sed -e 's|http[s]\?://||')
        
        # First, check the non-www version
        if check_website_status "https://$DOMAIN_ONLY"; then
            # If non-www version is up, skip the www check
            continue
        fi
        
        # If non-www version is down, check the www version
        URL_WITH_WWW=$(add_www_if_needed "$line")
        check_website_status "https://$URL_WITH_WWW"
    done < "$FILE"
}

# Function to show the menu
show_menu() {
    echo "1. Check a single website"
    echo "2. Check websites from a file"
    echo "3. Exit"
    read -p "Choose an option: " option

    case $option in
        1)
            read -p "Enter website URL: " URL
            # Set the default output file for a single website check
            OUTPUT_FILE="single_output.txt"
            check_website_status "$URL"
            ;;
        2)
            read -p "Enter the file name containing the URLs: " FILE
            read -p "Enter the output file name: " OUTPUT_FILE
            process_bulk_file "$FILE"
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option! Please try again."
            show_menu
            ;;
    esac
}

# Main script starts here

# Check if no arguments were passed
if [ $# -eq 0 ]; then
    show_menu
else
    if [ "$1" == "-f" ]; then
        # Process URLs from a file if the -f option is passed
        FILE=$2
        OUTPUT_FILE=$3
        if [ -z "$OUTPUT_FILE" ]; then
            OUTPUT_FILE="output.txt"
        fi
        process_bulk_file "$FILE"
    else
        # Process a single URL from the command line argument
        URL="$1"
        OUTPUT_FILE=${2:-output.txt}  # Default output file if none provided
        check_website_status "$URL"
    fi
fi
