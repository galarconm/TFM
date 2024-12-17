#! /bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <user_file>"
    exit 1
fi

USER_LIST=$1

# Configuration
MYSQL_LABEL="app=mysql-dep-pod"
MYSQL_USER="root"
MYSQL_PASSWORD="root_password"
MYSQL_DATABASE="guacamole_db"
PASSWORD="password"
GROUP_NAME="students"

# Get the name of the first pod associated with the MySQL deployment
MYSQL_POD=$(kubectl get pods -l "$MYSQL_LABEL" -o jsonpath='{.items[0].metadata.name}')

# Check if the MYSQL_POD variable is empty
if [ -z "$MYSQL_POD" ]; then
    echo "Error: No MySQL pod found with the label $MYSQL_LABEL"
    exit 1
fi

# Check if the students group exists
GROUP_EXISTS=$(kubectl exec -i $MYSQL_POD -- mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -D $MYSQL_DATABASE -sse "SELECT COUNT(*) FROM guacamole_entity WHERE name='$GROUP_NAME' AND type='USER_GROUP';")
if [ "$GROUP_EXISTS" -eq 0 ]; then
    echo "Error: Group $GROUP_NAME does not exist."
    exit 1
fi

# Get the entity_id of the students group
GROUP_ENTITY_ID=$(kubectl exec -i $MYSQL_POD -- mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -D $MYSQL_DATABASE -sse "SELECT entity_id FROM guacamole_entity WHERE name='$GROUP_NAME' AND type='USER_GROUP';")

# Get the user_group_id of the students group
GROUP_USER_ID=$(kubectl exec -i $MYSQL_POD -- mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -D $MYSQL_DATABASE -sse "SELECT user_group_id FROM guacamole_user_group WHERE entity_id=$GROUP_ENTITY_ID;")

# Verify the group exists in guacamole_user_group
GROUP_USER_EXISTS=$(kubectl exec -i $MYSQL_POD -- mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -D $MYSQL_DATABASE -sse "SELECT COUNT(*) FROM guacamole_user_group WHERE entity_id=$GROUP_ENTITY_ID;")
if [ "$GROUP_USER_EXISTS" -eq 0 ]; then
    echo "Inserting group $GROUP_NAME into guacamole_user_group."
    kubectl exec -i $MYSQL_POD -- mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "INSERT INTO guacamole_user_group (entity_id) VALUES ($GROUP_ENTITY_ID);"
fi

# Loop through usernames and insert into the MySQL database
while IFS= read -r username || [ -n "$username" ]; do
    # Add user to students group
    USER_ID=$(kubectl exec -i $MYSQL_POD -- mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -D $MYSQL_DATABASE -sse "SELECT entity_id FROM guacamole_entity WHERE name='$username' AND type='USER';")
    SQL_GROUP="INSERT INTO guacamole_user_group_member (user_group_id, member_entity_id) VALUES ($GROUP_USER_ID, $USER_ID);"
    echo "Executing: $SQL_GROUP"
    kubectl exec -i $MYSQL_POD -- mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "$SQL_GROUP"
    if [ $? -ne 0 ]; then
        echo "Failed to add user $username to group $GROUP_NAME."
    else
        echo "Added user $username to group $GROUP_NAME."
    fi
done < "$USER_LIST"

echo "Finished adding users to group $GROUP_NAME."