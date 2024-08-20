#!/bin/bash
# Script para automatizar el despliegue de un cluster de Kubernetes en local

# Definir la ruta de los manifiestos de Kubernetes
DEPLOYMENT_FILE="-deployment.yaml"
SERVICE_FILE="-service.yaml"
PVC_FILE="-pvc.yaml"
PV_FILE="-pv.yaml"
INGRESS_FILE="actaas-ingress.yaml"

# Definir los nombres de los recursos
resources=("geany" "jupyter" "spyder" "guacamole" "guacd" "mysql" "jenkins")

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

# Función para procesar todos los recursos (apply o delete)
process_all_resources() {
  local operation=$1
  local func=$2

  echo "${operation} PersistentVolumeClaims..."
  $func "${pvcpath}" "mysql" "${PVC_FILE}"

  echo "${operation} PersistentVolumes..."
  $func "${pvpath}" "mysql" "${PV_FILE}"

  echo "${operation} Deployments..."
  for resource in "${resources[@]}"; do
    $func "${deploymentpath}" "${resource}" "${DEPLOYMENT_FILE}"
  done

  echo "${operation} Services..."
  for resource in "${resources[@]}"; do
    $func "${servicepath}" "${resource}" "${SERVICE_FILE}"
  done

  echo "${operation} Ingress..."
  if [ "$operation" == "Aplicando" ]; then
    minikube addons enable ingress
  fi
  $func "${ingresspath}" "" "${INGRESS_FILE}"
}

# Función para procesar un recurso específico
process_single_resource() {
  local operation=$1
  local func=$2

  read -p "Ingrese el nombre del recurso: " resource
  if [[ " ${resources[@]} " =~ " ${resource} " ]]; then
    $func "${deploymentpath}" "${resource}" "${DEPLOYMENT_FILE}"
    $func "${servicepath}" "${resource}" "${SERVICE_FILE}"
  else
    echo "Recurso no válido: ${resource}"
  fi
}

# Función para mostrar el menú interactivo
show_menu() {
  echo "---------------------------------"
  echo "     Script de Kubernetes"
  echo "---------------------------------"
  echo "1. Lanzar todos los recursos"
  echo "2. Borrar todos los recursos"
  echo "3. Lanzar un recurso específico"
  echo "4. Borrar un recurso específico"
  echo "5. Salir"
  echo "---------------------------------"
  echo -n "Seleccione una opción: "
}

# Función principal que maneja la lógica del menú
main() {
  while true; do
    show_menu

    # Leer la opción del usuario
    read -r option

    case $option in
      1)
        echo "Lanzando todos los recursos..."
        process_all_resources "Aplicando" "apply_manifest"
        ;;
      2)
        echo "Borrando todos los recursos..."
        process_all_resources "Borrando" "delete_manifest"
        ;;
      3)
        echo "Lanzando un recurso específico..."
        process_single_resource "Aplicando" "apply_manifest"
        ;;
      4)
        echo "Borrando un recurso específico..."
        process_single_resource "Borrando" "delete_manifest"
        ;;
      5)
        echo "Saliendo..."
        exit 0
        ;;
      *)
        echo "Opción no válida. Por favor, elija una opción del 1 al 5."
        ;;
    esac
  done
}

# Ejecutar el programa principal
main
