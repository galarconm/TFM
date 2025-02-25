#! /bin/bash
#works fine to add users to guacamole, but do not add them to the group "students"

# Check if a file is passed as argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <user_file>"
    exit 1
fi

USER_LIST=$1

# Get token
TOKEN=$(curl -X POST -d "username=guacadmin&password=guacadmin" "http://158.42.104.43:30000/guacamole/api/tokens")

# Extract token from JSON response
TOKEN=$(echo $TOKEN | jq -r '.authToken')
echo "Token is: $TOKEN  "

# Get user name from file and create user
while IFS= read -r username || [ -n "$username" ]; do
    # Create user
    curl -X POST "http://158.42.104.43:30000/guacamole/api/session/data/mysql/users?token=$TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
           "username": "'$username'",
           "password": "password",
           "attributes": {
             "disabled": "",
             "expired": "",
             "access-window-start": "",
             "access-window-end": "",
             "valid-from": "",
             "valid-until": "",
             "timezone": ""
           }
         }'
done < $USER_LIST

