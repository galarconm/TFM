#!/bin/bash

# Variables
IP_PRIVATE=$(ip route get 1 | awk '{print $7; exit}')
IP_PUBLIC=$(ip addr show ens3 | awk '/inet / {print $2}' | cut -d/ -f1)
echo "Dirección IP publica de la máquina NFS: $IP_PUBLIC"
echo "Dirección IP privada de la máquina NFS: $IP_PRIVATE"

# Modificación de PV YAML
sed -i "s/server: .*/server: $IP_PRIVATE/" k8s/persistent-volumes/mysql-pv.yaml
sed -i "s/server: .*/server: $IP_PRIVATE/" k8s/persistent-volumes/jenkins-pv.yaml
sed -i "s/server: .*/server: $IP_PRIVATE/" k8s/persistent-volumes/home-pv.yaml
sed -i "s/server: .*/server: $IP_PRIVATE/" k8s/persistent-volumes/postgres-pv.yaml

# Modificación de Keycloak Deployment YAML
sed -i "s/value: \".*\" # minikube ip/value: \"$IP_PUBLIC\" # minikube ip/" k8s/deployments/keycloak-deployment.yaml

# Modificación de guacamole Deployment YAML
sed -i "s/value: http:\/\/.*/value: http:\/\/$IP_PUBLIC:30000\/guacamole/" k8s/deployments/guacamole-deployment.yaml
sed -i "s/value: http:\/\/.*/value: http:\/\/$IP_PUBLIC:31001\/realms\/guacamole/" k8s/deployments/guacamole-deployment.yaml
sed -i "s/value: http:\/\/.*/value: http:\/\/$IP_PUBLIC:31001\/realms\/guacamole\/protocol\/openid-connect\/auth/" k8s/deployments/guacamole-deployment.yaml
sed -i "s/value: http:\/\/.*/value: http:\/\/$IP_PUBLIC:31001\/realms\/guacamole\/protocol\/openid-connect\/certs/" k8s/deployments/guacamole-deployment.yaml
sed -i "s/value: http:\/\/.*/value: http:\/\/$IP_PUBLIC:31001\/realms\/guacamole\/protocol\/openid-connect\/token/" k8s/deployments/guacamole-deployment.yaml
sed -i "s/value: http:\/\/.*/value: http:\/\/$IP_PUBLIC:31001\/realms\/guacamole\/protocol\/openid-connect\/userinfo/" k8s/deployments/guacamole-deployment.yaml
sed -i "s/value: http:\/\/.*/value: http:\/\/$IP_PUBLIC:31001\/realms\/guacamole\/protocol\/openid-connect\/logout/" k8s/deployments/guacamole-deployment.yaml

# Modificación de add_userskeycloak.sh
sed -i "s/KEYCLOAK_URL=\"http:\/\/.*/KEYCLOAK_URL=\"http:\/\/$IP_PUBLIC:31001\"/" add_userskeycloak.sh

# Modificación de create_guacamole_users.sh
sed -i "s/GUACAMOLE_URL=\"http:\/\/.*/GUACAMOLE_URL=\"http:\/\/$IP_PUBLIC:30000\/guacamole\"/" create_guacamole_users.sh

# Modificación de jenkins-keycloak-setup.sh
sed -i "s/KEYCLOAK_URL=\"http:\/\/.*/KEYCLOAK_URL=\"http:\/\/$IP_PUBLIC:31001\"/" jenkins-keycloak-setup.sh

# Modificación de realms.sh
sed -i "s/KEYCLOAK_URL=\"http:\/\/.*/KEYCLOAK_URL=\"http:\/\/$IP_PUBLIC:31001\"/" realms.sh
sed -i "s|rootUrl\": \"http:\/\/.*:30000|rootUrl\": \"http:\/\/$IP_PUBLIC:30000|" realms.sh
sed -i "s|redirectUris\": \[\"http:\/\/.*:30000|redirectUris\": \[\"http:\/\/$IP_PUBLIC:30000|" realms.sh
sed -i "s|webOrigins\": \[\"http:\/\/.*:30000|webOrigins\": \[\"http:\/\/$IP_PUBLIC:30000|" realms.sh
sed -i "s|adminUrl\": \"http:\/\/.*:30000|adminUrl\": \"http:\/\/$IP_PUBLIC:30000|" realms.sh
sed -i "s|rootUrl\": \"http:\/\/.*:31000|rootUrl\": \"http:\/\/$IP_PUBLIC:31000|" realms.sh
sed -i "s|redirectUris\": \[\"http:\/\/.*:31000|redirectUris\": \[\"http:\/\/$IP_PUBLIC:31000|" realms.sh
sed -i "s|webOrigins\": \[\"http:\/\/.*:31000|webOrigins\": \[\"http:\/\/$IP_PUBLIC:31000|" realms.sh
sed -i "s|adminUrl\": \"http:\/\/.*:31000|adminUrl\": \"http:\/\/$IP_PUBLIC:31000|" realms.sh
