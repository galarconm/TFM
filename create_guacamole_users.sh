#!/bin/bash

# Este script crea usuarios en Guacamole usando la API (para el manejo de contraseñas) y los agrega al grupo "students" usando consultas directas a MySQL.

# Verificar si se pasa un archivo como argumento
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <archivo_de_usuarios>"
    exit 1
fi

USER_LIST=$1

# Configuración
GUACAMOLE_URL="http://192.168.49.2:30000/guacamole"
GUAC_ADMIN_USER="guacadmin"
GUAC_ADMIN_PASSWORD="guacadmin"
DATA_SOURCE="mysql"
PASSWORD="password"
GROUP_NAME="students"

# Configuración de MySQL
MYSQL_LABEL="app=mysql-dep-pod"
MYSQL_USER="root"
MYSQL_PASSWORD="root_password"
MYSQL_DATABASE="guacamole_db"

# Obtener el nombre del pod de MySQL
MYSQL_POD=$(kubectl get pods -l "$MYSQL_LABEL" -o jsonpath='{.items[0].metadata.name}')
if [ -z "$MYSQL_POD" ]; then
    echo "Error: No se encontró ningún pod de MySQL con la etiqueta $MYSQL_LABEL"
    mysql_exec "INSERT INTO guacamole_entity (name, type) VALUES ('$GROUP_NAME', 'USER_GROUP');"
fi

# Función para ejecutar comandos MySQL a través de kubectl
mysql_exec() {
    kubectl exec "$MYSQL_POD" -- bash -c "mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -D $MYSQL_DATABASE -sse \"$1\""
}

# Obtener un token de autenticación
TOKEN=$(curl -s -X POST -d "username=$GUAC_ADMIN_USER&password=$GUAC_ADMIN_PASSWORD" "$GUACAMOLE_URL/api/tokens")
TOKEN=$(echo "$TOKEN" | jq -r '.authToken')

if [ -z "$TOKEN" ]; then
    echo "Error al autenticar con Guacamole"
    exit 1
fi

echo "Token obtenido: $TOKEN"

# Verificar si el grupo "students" existe
GROUP_EXISTS=$(mysql_exec "SELECT COUNT(*) FROM guacamole_entity WHERE name='$GROUP_NAME' AND type='USER_GROUP';")
if [ "$GROUP_EXISTS" -eq 0 ]; then
    echo "Error: El grupo $GROUP_NAME no existe."
    exit 1
fi

# Obtener los IDs de entidad y grupo de usuario del grupo
GROUP_ENTITY_ID=$(mysql_exec "SELECT entity_id FROM guacamole_entity WHERE name='$GROUP_NAME' AND type='USER_GROUP';")
GROUP_USER_ID=$(mysql_exec "SELECT user_group_id FROM guacamole_user_group WHERE entity_id=$GROUP_ENTITY_ID;")

# Insertar en guacamole_user_group si falta
if [ -z "$GROUP_USER_ID" ]; then
    echo "Insertando el grupo $GROUP_NAME en guacamole_user_group."
    kubectl exec "$MYSQL_POD" -- bash -c "mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -D $MYSQL_DATABASE -e \
        \"INSERT INTO guacamole_user_group (entity_id) VALUES ($GROUP_ENTITY_ID);\""
    GROUP_USER_ID=$(mysql_exec "SELECT user_group_id FROM guacamole_user_group WHERE entity_id=$GROUP_ENTITY_ID;")
fi

# Procesar cada usuario en la lista
while IFS= read -r username || [ -n "$username" ]; do
    [ -z "$username" ] && continue  # Omitir líneas vacías

    echo "🔄 Procesando usuario: $username"

    # Crear usuario usando la API de Guacamole
    echo "Creando usuario: $username"
    CREATE_USER_RESPONSE=$(curl -s -X POST "$GUACAMOLE_URL/api/session/data/$DATA_SOURCE/users?token=$TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
              "username": "'$username'",
              "password": "'$PASSWORD'",
              "attributes": {
                "disabled": "",
                "expired": "",
                "access-window-start": "",
                "access-window-end": "",
                "valid-from": "",
                "valid-until": "",
                "timezone": ""
              }
            }')

    if [[ "$CREATE_USER_RESPONSE" == *"error"* ]]; then
        echo "❌ Error al crear el usuario $username: $CREATE_USER_RESPONSE"
        continue
    else
        echo "✅ Usuario $username creado."
    fi

    # Obtener entity_id del usuario desde la base de datos
    USER_ENTITY_ID=$(mysql_exec "SELECT entity_id FROM guacamole_entity WHERE name='$username' AND type='USER';")

    if [ -z "$USER_ENTITY_ID" ]; then
        echo "❌ Error al obtener entity_id para el usuario $username."
        continue
    fi

    # Agregar usuario al grupo "students" si no es ya miembro
    USER_IN_GROUP=$(mysql_exec "SELECT COUNT(*) FROM guacamole_user_group_member WHERE user_group_id=$GROUP_USER_ID AND member_entity_id=$USER_ENTITY_ID;")
    if [ "$USER_IN_GROUP" -eq 0 ]; then
        mysql_exec "INSERT INTO guacamole_user_group_member (user_group_id, member_entity_id) VALUES ($GROUP_USER_ID, $USER_ENTITY_ID);"
        echo "👥 Usuario $username agregado al grupo $GROUP_NAME."
    else
        echo "👥 El usuario $username ya está en el grupo $GROUP_NAME."
    fi

done < "$USER_LIST"

echo "✅ Importación masiva de usuarios completada."