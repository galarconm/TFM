#!/bin/bash
# Script para desplegar un clúster de Kubernetes en local

set -e  # Detener en caso de error

# Configurar IP para el NFS
IP_NFS=$(ip route get 1 | awk '{print $7; exit}')
echo "IP de la máquina NFS: $IP_NFS"

# Actualizar archivos de Persistent Volumes (PV)
for pv in mysql jenkins home postgres; do
  sed -i "s/server: .*/server: $IP_NFS/" "k8s/persistent-volumes/${pv}-pv.yaml"
done

# Modificación de Keycloak Deployment YAML
sed -i "s/value: \".*\" # minikube ip/value: \"$IP_NFS\" # minikube ip/" k8s/deployments/keycloak-deployment.yaml


echo "IPs actualizadas en los Persistent Volumes."

# Definir recursos y rutas
resources=("geany" "jupyter" "spyder" "guacamole" "guacd" "mysql" "jenkins" "keycloak" "postgres")
paths=(
  [pv]="k8s/persistent-volumes/"
  [pvc]="k8s/persistent-volume-claims/"
  [deploy]="k8s/deployments/"
  [service]="k8s/services/"
  [ingress]="k8s/ingress/"
)

# Aplicar manifiestos
apply_manifest() {
  local type=$1 resource=$2 ext=$3
  local file="${paths[$type]}${resource}${ext}.yaml"
  [[ -f "$file" ]] && kubectl apply -f "$file" && echo "Aplicado: $file"
}

# Aplicar PV y PVC
echo "Aplicando PersistentVolumes y PersistentVolumeClaims..."
for pv in home mysql postgres jenkins; do
  apply_manifest pv "$pv" "-pv"
  apply_manifest pvc "$pv" "-pvc"
done

# Aplicar Deployments y Services
echo "Aplicando Deployments y Services..."
for resource in "${resources[@]}"; do
  apply_manifest deploy "$resource" "-deployment"
  apply_manifest service "$resource" "-service"
done

echo "Despliegue completado."
