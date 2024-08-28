#!/bin/bash

# Variables
IP_NFS=$(ip route get 1 | awk '{print $7; exit}')
echo "Dirección IP de la máquina NFS: $IP_NFS"

#Modificación de PV YAML
sed -i "s/server: .*/server: $IP_NFS/" k8s/persistent-volumes/mysql-pv.yaml
sed -i "s/server: .*/server: $IP_NFS/" k8s/persistent-volumes/jenkins-pv.yaml
sed -i "s/server: .*/server: $IP_NFS/" k8s/persistent-volumes/jenkins-pv.yaml

