#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <archivo_de_usuarios>"
    exit 1
fi

USER_FILE=$1

# Definir los selectores de etiquetas para cada despliegue
LABELS=("app=geany-dep-pod" "app=spyder-dep-pod" "app=jupyter-dep-pod")

for LABEL in "${LABELS[@]}"; do
    PODS=$(kubectl get pods -l "$LABEL" -o jsonpath='{.items[*].metadata.name}')
    for POD in $PODS; do
        kubectl cp add_users.sh "$POD:/usr/local/bin/add_users.sh"
        echo "Copiando $USER_FILE al pod $POD..."
        kubectl cp "$USER_FILE" "$POD:/usr/local/bin/$USER_FILE"
        echo "Agregando usuarios al pod $POD..."
        kubectl exec "$POD" -- /usr/local/bin/add_users.sh /usr/local/bin/"$USER_FILE"
    done
done

# resumen: El script copia el script add_users.sh y el archivo de usuarios a cada pod con
# la etiqueta app=geany-dep-pod, app=spyder-dep-pod, o app=jupyter-dep-pod.
# Luego ejecuta el script add_users.sh con el archivo de usuarios como argumento en cada pod.
# Esto permite agregar usuarios a múltiples pods a la vez.