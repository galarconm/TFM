#!/bin/bash

USER_FILE=$1

if [ -z "$USER_FILE" ]; then
    echo "Usage: $0 <user_file>"
    exit 1
fi

if [ ! -f "$USER_FILE" ]; then
    echo "File $USER_FILE does not exist."
    exit 1
fi

while IFS= read -r USERNAME || [ -n "$USERNAME" ]; do
 
        userdel -r "$USERNAME"
        HOME_DIR="/home/userdata/$USERNAME"
        rm -rf "$HOME_DIR"
        echo "Home directory $HOME_DIR deleted successfully!"
        echo "User $USERNAME deleted successfully!"
 done < "$USER_FILE"