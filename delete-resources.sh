#!/bin/bash
# Script para eliminar recursos de Kubernetes

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

# Función para borrar manifiestos de Kubernetes
delete_manifest() {
  local path=$1
  local resource=$2
  local file=$3

  if [ -f "${path}${resource}${file}" ]; then
    kubectl delete -f "${path}${resource}${file}"
    echo "Borrado: ${path}${resource}${file}"
  else
    echo "Archivo no encontrado: ${path}${resource}${file}"
  fi
}

# Función para procesar todos los recursos
delete_all_resources() {
  echo "Eliminando PersistentVolumeClaims..."
  delete_manifest "${pvcpath}" "home" "${PVC_FILE}"
  
  echo "Eliminando PersistentVolumes..."
  delete_manifest "${pvpath}" "home" "${PV_FILE}"

  echo "Eliminando PersistentVolumeClaims..."
  delete_manifest "${pvcpath}" "mysql" "${PVC_FILE}"

  echo "Eliminando PersistentVolumes..."
  delete_manifest "${pvpath}" "mysql" "${PV_FILE}"

  echo "Eliminando PersistentVolumeClaims..."
  delete_manifest "${pvcpath}" "jenkins" "${PVC_FILE}"

  echo "Eliminando PersistentVolumes..."
  delete_manifest "${pvpath}" "jenkins" "${PV_FILE}"

  echo "Eliminando PersistentVolumeClaims..."
  delete_manifest "${pvcpath}" "postgres" "${PVC_FILE}"

  echo "Eliminando PersistentVolumes..."
  delete_manifest "${pvpath}" "postgres" "${PV_FILE}"

  echo "Eliminando Deployments..."
  for resource in "${resources[@]}"; do
    delete_manifest "${deploymentpath}" "${resource}" "${DEPLOYMENT_FILE}"
  done

  echo "Eliminando Services..."
  for resource in "${resources[@]}"; do
    delete_manifest "${servicepath}" "${resource}" "${SERVICE_FILE}"
  done

  # echo "Eliminando Ingress..."
  # kubectl delete -f "${ingresspath}${INGRESS_FILE}"
}

# Ejecutar la eliminación de todos los recursos
delete_all_resources
