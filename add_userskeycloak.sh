#! /bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <user_file>"
    exit 1
fi

USER_LIST=$1

# Keycloak configuration
KEYCLOAK_URL="http://192.168.49.2:31001"
KEYCLOAK_USER="admin"
KEYCLOAK_PASSWORD="admin"
REALM="guacamole"
CLIENT_ID="guacamole"
GROUP_NAME="students"

# Get Keycloak admin access token
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$KEYCLOAK_USER" \
    -d "password=$KEYCLOAK_PASSWORD" \
    -d 'grant_type=password' \
    -d 'client_id=admin-cli' | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "Failed to get Keycloak token"
  exit 1
fi

# Get the ID of the 'students' group
GROUP_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/groups?search=$GROUP_NAME" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[] | select(.name=="students") | .id')

if [ -z "$GROUP_ID" ]; then
  echo "Group 'students' not found. Create the group in Keycloak first."
  exit 1
fi

# Add users and assign them to the 'students' group
while IFS= read -r username || [ -n "$username" ]; do
    # Create user
    USER_ID=$(curl -s -D - -o /dev/null -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d '{
          "username": "'"$username"'",
          "enabled": true,
          "credentials": [
            {
              "type": "password",
              "value": "password",
              "temporary": false
            }
          ]
        }' | awk '/^Location:/ {print $2}' | awk -F'/' '{print $NF}' | tr -d '\r')

    if [ -z "$USER_ID" ]; then
        echo "Failed to create user $username."
        continue
    fi

    # Add user to the 'students' group
    curl -s -X PUT "$KEYCLOAK_URL/admin/realms/$REALM/users/$USER_ID/groups/$GROUP_ID" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{}'

    echo "User $username created and added to group 'students'."
done < "$USER_LIST"