#!/bin/bash
# Script para automatizar el despliegue de un cluster de Kubernetes en local

#Configurar IP para el NFS
IP_NFS=$(ip route get 1 | awk '{print $7; exit}')
echo "Dirección IP de la máquina NFS: $IP_NFS"

#Modificación de PV YAML
sed -i "s/server: .*/server: $IP_NFS/" k8s/persistent-volumes/mysql-pv.yaml
sed -i "s/server: .*/server: $IP_NFS/" k8s/persistent-volumes/jenkins-pv.yaml
sed -i "s/server: .*/server: $IP_NFS/" k8s/persistent-volumes/home-pv.yaml


# Definir la ruta de los manifiestos de Kubernetes
DEPLOYMENT_FILE="-deployment.yaml"
SERVICE_FILE="-service.yaml"
PVC_FILE="-pvc.yaml"
PV_FILE="-pv.yaml"
INGRESS_FILE="actaas-ingress.yaml"

# Definir los nombres de los recursos
resources=("geany" "jupyter" "spyder" "guacamole" "guacd" "mysql" "jenkins" "keycloak" "postgres")

# Definir las rutas de los manifiestos
deploymentpath="k8s/deployments/"
servicepath="k8s/services/"
pvcpath="k8s/persistent-volume-claims/"
pvpath="k8s/persistent-volumes/"
ingresspath="k8s/ingress/"

# Capturar errores y limpiar en caso de falla
trap 'echo "Se ha producido un error. Saliendo..."; exit 1' ERR

# Función para aplicar manifiestos de Kubernetes
apply_manifest() {
  local path=$1
  local resource=$2
  local file=$3

  if [ -f "${path}${resource}${file}" ]; then
    kubectl apply -f "${path}${resource}${file}"
    echo "Aplicado: ${path}${resource}${file}"
  else
    echo "Archivo no encontrado: ${path}${resource}${file}"
  fi
}

# Aplicar manifiestos
echo "Aplicando PersistentVolumeClaims..."
apply_manifest "${pvcpath}" "home" "${PVC_FILE}"
apply_manifest "${pvcpath}" "mysql" "${PVC_FILE}"
apply_manifest "${pvcpath}" "postgres" "${PVC_FILE}"
apply_manifest "${pvcpath}" "jenkins" "${PVC_FILE}"

echo "Aplicando PersistentVolumes..."
apply_manifest "${pvpath}" "home" "${PV_FILE}"
apply_manifest "${pvpath}" "mysql" "${PV_FILE}"
apply_manifest "${pvpath}" "postgres" "${PV_FILE}"
apply_manifest "${pvpath}" "jenkins" "${PV_FILE}"

echo "Aplicando Deployments..."
for resource in "${resources[@]}"; do
  apply_manifest "${deploymentpath}" "${resource}" "${DEPLOYMENT_FILE}"
done

echo "Aplicando Services..."
for resource in "${resources[@]}"; do
  apply_manifest "${servicepath}" "${resource}" "${SERVICE_FILE}"
done

#echo "Aplicando Ingress..."
#apply_manifest "${ingresspath}" "" "${INGRESS_FILE}"