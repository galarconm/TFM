#!/bin/bash

# This script creates users in Guacamole using the API (for password handling) and adds them to the "students" group using direct MySQL queries.

# Check if a file is passed as argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <user_file>"
    exit 1
fi

USER_LIST=$1

# Configuration
GUACAMOLE_URL="http://158.42.104.43:30000/guacamole"
GUAC_ADMIN_USER="guacadmin"
GUAC_ADMIN_PASSWORD="guacadmin"
DATA_SOURCE="mysql"
PASSWORD="password"
GROUP_NAME="students"

# MySQL Configuration
MYSQL_LABEL="app=mysql-dep-pod"
MYSQL_USER="root"
MYSQL_PASSWORD="root_password"
MYSQL_DATABASE="guacamole_db"

# Get MySQL pod name
MYSQL_POD=$(kubectl get pods -l "$MYSQL_LABEL" -o jsonpath='{.items[0].metadata.name}')
if [ -z "$MYSQL_POD" ]; then
    echo "Error: No MySQL pod found with the label $MYSQL_LABEL"
    mysql_exec "INSERT INTO guacamole_entity (name, type) VALUES ('$GROUP_NAME', 'USER_GROUP');"
fi

# Function to execute MySQL command via kubectl
mysql_exec() {
    kubectl exec "$MYSQL_POD" -- bash -c "mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -D $MYSQL_DATABASE -sse \"$1\""
}

# Get an authentication token
TOKEN=$(curl -s -X POST -d "username=$GUAC_ADMIN_USER&password=$GUAC_ADMIN_PASSWORD" "$GUACAMOLE_URL/api/tokens")
TOKEN=$(echo "$TOKEN" | jq -r '.authToken')

if [ -z "$TOKEN" ]; then
    echo "Failed to authenticate with Guacamole"
    exit 1
fi

echo "Token obtained: $TOKEN"

# Check if the "students" group exists
GROUP_EXISTS=$(mysql_exec "SELECT COUNT(*) FROM guacamole_entity WHERE name='$GROUP_NAME' AND type='USER_GROUP';")
if [ "$GROUP_EXISTS" -eq 0 ]; then
    echo "Error: Group $GROUP_NAME does not exist."
    exit 1
fi

# Get group entity and user_group IDs
GROUP_ENTITY_ID=$(mysql_exec "SELECT entity_id FROM guacamole_entity WHERE name='$GROUP_NAME' AND type='USER_GROUP';")
GROUP_USER_ID=$(mysql_exec "SELECT user_group_id FROM guacamole_user_group WHERE entity_id=$GROUP_ENTITY_ID;")

# Insert into guacamole_user_group if missing
if [ -z "$GROUP_USER_ID" ]; then
    echo "Inserting group $GROUP_NAME into guacamole_user_group."
    kubectl exec "$MYSQL_POD" -- bash -c "mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -D $MYSQL_DATABASE -e \
        \"INSERT INTO guacamole_user_group (entity_id) VALUES ($GROUP_ENTITY_ID);\""
    GROUP_USER_ID=$(mysql_exec "SELECT user_group_id FROM guacamole_user_group WHERE entity_id=$GROUP_ENTITY_ID;")
fi

# Process each user in the list
while IFS= read -r username || [ -n "$username" ]; do
    [ -z "$username" ] && continue  # Skip empty lines

    echo "🔄 Processing user: $username"

    # Create user using the Guacamole API
    echo "Creating user: $username"
    CREATE_USER_RESPONSE=$(curl -s -X POST "$GUACAMOLE_URL/api/session/data/$DATA_SOURCE/users?token=$TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
              "username": "'$username'",
              "password": "'$PASSWORD'",
              "attributes": {
                "disabled": "",
                "expired": "",
                "access-window-start": "",
                "access-window-end": "",
                "valid-from": "",
                "valid-until": "",
                "timezone": ""
              }
            }')

    if [[ "$CREATE_USER_RESPONSE" == *"error"* ]]; then
        echo "❌ Failed to create user $username: $CREATE_USER_RESPONSE"
        continue
    else
        echo "✅ Created user $username."
    fi

    # Get user entity_id from the database
    USER_ENTITY_ID=$(mysql_exec "SELECT entity_id FROM guacamole_entity WHERE name='$username' AND type='USER';")

    if [ -z "$USER_ENTITY_ID" ]; then
        echo "❌ Failed to retrieve entity_id for user $username."
        continue
    fi

    # Add user to "students" group if not already a member
    USER_IN_GROUP=$(mysql_exec "SELECT COUNT(*) FROM guacamole_user_group_member WHERE user_group_id=$GROUP_USER_ID AND member_entity_id=$USER_ENTITY_ID;")
    if [ "$USER_IN_GROUP" -eq 0 ]; then
        mysql_exec "INSERT INTO guacamole_user_group_member (user_group_id, member_entity_id) VALUES ($GROUP_USER_ID, $USER_ENTITY_ID);"
        echo "👥 Added user $username to group $GROUP_NAME."
    else
        echo "👥 User $username is already in group $GROUP_NAME."
    fi

done < "$USER_LIST"

echo "✅ Bulk user import completed."