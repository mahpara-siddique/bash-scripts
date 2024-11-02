#!/bin/bash

# renamify
echo "Welcome To Renamify"
touch "a.txt" # No need for $()
touch "b.txt" # No need for $()
touch "main.sh" # Ensure main.sh exists for demonstration

rename_files() {
    target_files=$1       # File extension, e.g., .txt
    new_name=$2           # Base name for new files
    target_directory=$3   # Directory to search for files
    echo $target_files
    echo $new_name
    echo $target_directory
    # Check if target directory exists
    if [ ! -d "$target_directory" ]; then
        echo "Error: Directory '$target_directory' does not exist."
        return 1
    fi

    # Enable nullglob to handle no matches correctly
    shopt -s nullglob
    files=("$target_directory"/*"$target_files")
    shopt -u nullglob

    # Check if any files matched
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files matching the pattern '$target_directory/*$target_files'."
        return 1
    fi

    for i in "${files[@]}"; do
        if [ -f "$i" ]; then  # Check if it's a regular file
            base_file=$(basename "$i")  # Extract just the file name without the path
            new_file="${target_directory}/${new_name}${target_files}"
            mv "$i" "$new_file"
            echo "Renaming '$base_file' to '$(basename "$new_file")'"
            ((counter++))  # Increment counter for each file
        else
            echo "Skipping '$i': Not a regular file."
        fi
    done
}

add_text_in_name() {
    target_files=$1       # File extension, e.g., .txt
    new_name=$2           # Text to be added to the new file names
    target_directory=$3   # Directory to search for files

    # Check if target directory exists
    if [ ! -d "$target_directory" ]; then
        echo "Error: Directory '$target_directory' does not exist."
        return 1
    fi

    # Enable nullglob to handle no matches correctly
    shopt -s nullglob
    files=("$target_directory"/*"$target_files")
    shopt -u nullglob

    # Check if any files matched
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files matching the pattern '$target_directory/*$target_files'."
        return 1
    fi

    for i in "${files[@]}"; do
        if [ -f "$i" ]; then  # Check if it's a regular file
            base_file=$(basename "$i")  # Extract just the file name without the path
            new_file="${target_directory}/${new_name}_${base_file}"  # Add new name before the original file name
            mv "$i" "$new_file"  # Rename the file
            echo "Renaming '$base_file' to '$(basename "$new_file")'"
        else
            echo "Skipping '$i': Not a regular file."
        fi
    done
}

# Menu for user
echo "Please choose an option:"
echo "1. Rename files"
echo "2. Add text to file names"

read -p "Enter your choice (1 or 2): " user_choice

# Handle user choice
case "$user_choice" in
    1)
        read -p "Enter file extension (e.g., .txt): " file_extension
        # Ensure the file extension starts with a dot
        if [[ "$file_extension" != .* ]]; then
            echo "Error: File extension should start with a dot (e.g., .txt)."
            exit 1
        fi
        read -p "Enter new base name (without quotes): " new_name
        # Validate new_name (no spaces, no special characters)
        if [[ -z "$new_name" ]]; then
            echo "Error: New base name cannot be empty."
            exit 1
        fi
        read -p "Enter target directory: " target_directory
        rename_files "$file_extension" "$new_name" "$target_directory"
        ;;
    2)
        read -p "Enter file extension (e.g., .txt): " file_extension
        # Ensure the file extension starts with a dot
        if [[ "$file_extension" != .* ]]; then
            echo "Error: File extension should start with a dot (e.g., .txt)."
            exit 1
        fi
        read -p "Enter text to add to file names (without quotes): " new_name
        # Validate new_name (no spaces, no special characters)
        if [[ -z "$new_name" ]]; then
            echo "Error: Text to add cannot be empty."
            exit 1
        fi
        read -p "Enter target directory: " target_directory
        add_text_in_name "$file_extension" "$new_name" "$target_directory"
        ;;
    *)
        echo "Invalid choice. Please run the script again and choose 1 or 2."
        exit 1
        ;;
esac

echo "Updated files:"

