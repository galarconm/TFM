#!/bin/bash
# Script para desplegar recursos de Kubernetes


#ejecutar el script ip_nfs.sh
#./ip_nfs.sh
./ip_nfs.sh

# Definir la ruta de los manifiestos de Kubernetes
DEPLOYMENT_FILE="-deployment.yaml"
SERVICE_FILE="-service.yaml"
PVC_FILE="-pvc.yaml"
PV_FILE="-pv.yaml"
INGRESS_FILE="actaas-ingress.yaml"

# Definir los nombres de los recursos
resources=("geany" "jupyter" "spyder" "guacamole" "guacd" "mysql" "jenkins" "postgres" "keycloak")

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
    echo "Desplegado: ${path}${resource}${file}"
  else
    echo "Archivo no encontrado: ${path}${resource}${file}"
  fi
}

# Función para procesar todos los recursos
deploy_all_resources() {
  echo "Desplegando PersistentVolumeClaims..."
  apply_manifest "${pvcpath}" "home" "${PVC_FILE}"
  
  echo "Desplegando PersistentVolumes..."
  apply_manifest "${pvpath}" "home" "${PV_FILE}"

  echo "Desplegando PersistentVolumeClaims..."
  apply_manifest "${pvcpath}" "mysql" "${PVC_FILE}"

  echo "Desplegando PersistentVolumes..."
  apply_manifest "${pvpath}" "mysql" "${PV_FILE}"

  echo "Desplegando PersistentVolumeClaims..."
  apply_manifest "${pvcpath}" "jenkins" "${PVC_FILE}"

  echo "Desplegando PersistentVolumes..."
  apply_manifest "${pvpath}" "jenkins" "${PV_FILE}"

  echo "Desplegando PersistentVolumeClaims..."
  apply_manifest "${pvcpath}" "postgres" "${PVC_FILE}"

  echo "Desplegando PersistentVolumes..."
  apply_manifest "${pvpath}" "postgres" "${PV_FILE}"

  echo "Desplegando Deployments..."
  for resource in "${resources[@]}"; do
    apply_manifest "${deploymentpath}" "${resource}" "${DEPLOYMENT_FILE}"
  done

  echo "Desplegando Services..."
  for resource in "${resources[@]}"; do
    apply_manifest "${servicepath}" "${resource}" "${SERVICE_FILE}"
  done

  # echo "Desplegando Ingress..."
  # minikube addons enable ingress
  # apply_manifest "${ingresspath}" "" "${INGRESS_FILE}"
}

# Ejecutar el despliegue de todos los recursos
deploy_all_resources
