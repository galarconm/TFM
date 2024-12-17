#!/bin/bash

# Ensure the script is run with exactly one argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <user_file>"
    exit 1
fi

USER_FILE=$1
PASSWORD="password"

# Check if the user file exists
if [ ! -f "$USER_FILE" ]; then
    echo "File $USER_FILE does not exist."
    exit 1
fi

# Read the user file line by line
while IFS= read -r USERNAME || [ -n "$USERNAME" ]; do
    # Check if the user already exists
    if id "$USERNAME" &>/dev/null; then
        echo "User $USERNAME already exists."
    else
        # Create the user with a home directory
        useradd -m -d /home/userdata/"$USERNAME" "$USERNAME"
        if [ $? -ne 0 ]; then
            echo "Failed to add user $USERNAME. Skipping."
            continue
        fi

        # Set the password for the user
        echo "$USERNAME:$PASSWORD" | chpasswd

        # Ensure proper ownership of the user's home directory
        chown "$USERNAME":"$USERNAME" /home/userdata/"$USERNAME"

        # Set permissions for the user's home directory
        chmod 700 /home/userdata/"$USERNAME"

        echo "User $USERNAME added successfully!"
    fi
done < "$USER_FILE"
