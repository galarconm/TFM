#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <user_file>"
    exit 1
fi

USER_FILE=$1

# Define the label selectors for each deployment
LABELS=("app=geany-dep-pod" "app=spyder-dep-pod" "app=jupyter-dep-pod")

for LABEL in "${LABELS[@]}"; do
    PODS=$(kubectl get pods -l "$LABEL" -o jsonpath='{.items[*].metadata.name}')
    for POD in $PODS; do
        kubectl cp add_users.sh "$POD:/usr/local/bin/add_users.sh"
        echo "Copying $USER_FILE to $POD pod..."
        kubectl cp "$USER_FILE" "$POD:/usr/local/bin/$USER_FILE"
        echo "Adding users to $POD pod..."
        kubectl exec "$POD" -- /usr/local/bin/add_users.sh /usr/local/bin/"$USER_FILE"
    done
done

#summary: The script copies the add_users.sh script and the user file to each pod with
#the label app=geany-dep-pod, app=spyder-dep-pod, or app=jupyter-dep-pod. 
#It then executes the add_users.sh script with the user file as an argument in each pod. 
#This allows users to be added to multiple pods at once.