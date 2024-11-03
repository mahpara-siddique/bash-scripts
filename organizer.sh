#!/bin/bash

organize() {
    path=$1
    # Ensure the path ends with a slash
    [[ "$path" != */ ]] && path="$path/"

    # Loop through all items in the specified directory
    for file in "$path"*; do
        # Get the base name of the file (without the path)
        basefile=$(basename "$file")
        
        # Skip if it's a hidden file or a directory
        if [[ "$basefile" == .* || -d "$file" ]]; then
            continue
        fi

        # Check if the file has an extension
        if [[ "$basefile" == *.* ]]; then
            extension="${basefile##*.}"
            # Convert extension to lowercase to avoid case-sensitive duplicates
            extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
        else
            extension="no_extension"
        fi

        # Create the directory if it doesn't exist
        mkdir -p "$path$extension"

        # Move the file into the corresponding directory
        mv "$file" "$path$extension/"
    done

    echo "Files have been organized by extension."
}

show_menu() {
    echo "Select an option:"
    echo "1. Organize the current directory"
    echo "2. Organize a specified directory"
    read -p "Enter your choice (1 or 2): " choice

    case $choice in
        1) organize "./" ;;  # Organizes the current directory
        2) 
            read -p "Enter the path of the directory to organize: " dir_path
            if [ -d "$dir_path" ]; then
                organize "$dir_path"  # Organizes the specified directory
            else
                echo "Error: The provided path '$dir_path' is not a directory."
                exit 1
            fi
            ;;
        *) echo "Invalid choice. Exiting." ;;
    esac
}

# Show the menu
show_menu

