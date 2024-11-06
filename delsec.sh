#!/bin/bash

# Function to shred and delete a file securely
shred_file() {
    local file=$1
    shred -uzv "$file"
    if [ $? -eq 0 ]; then
        echo "File '$file' has been securely deleted."
    else
        echo "Failed to securely delete the file '$file'."
    fi
}

# Function to shred and delete files in a directory securely
shred_directory() {
    local dir=$1
    if [ -d "$dir" ]; then
        # Recursively go through the directory and shred files
        find "$dir" -type f -exec shred -uzv {} \;
        # Delete the directory itself
        rm -rf "$dir"
        if [ $? -eq 0 ]; then
            echo "Directory '$dir' and its contents have been securely deleted."
        else
            echo "Failed to securely delete the directory '$dir'."
        fi
    else
        echo "Directory '$dir' does not exist."
    fi
}

# Check if an argument is passed
if [ $# -lt 2 ]; then
    echo "Usage: $0 [option] [file|directory]"
    echo "Options:"
    echo "  --file      Shred and delete a file securely"
    echo "  --directory Shred and delete a directory securely"
    exit 1
fi

# Get the option and file/directory
option=$1
target=$2

# Perform actions based on the option
case $option in
    --file)
        if [ -f "$target" ]; then
            shred_file "$target"
        else
            echo "'$target' is not a valid file."
        fi
        ;;
    --directory)
        if [ -d "$target" ]; then
            shred_directory "$target"
        else
            echo "'$target' is not a valid directory."
        fi
        ;;
    *)
        echo "Invalid option. Use --file or --directory."
        exit 1
        ;;
esac
