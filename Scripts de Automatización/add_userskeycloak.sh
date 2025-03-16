#! /bin/bash

# Asegurarse de que el script se ejecute con exactamente un argumento
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <archivo_de_usuarios>"
    exit 1
fi

USER_LIST=$1

# Configuración de Keycloak
KEYCLOAK_URL="http://192.168.49.2:31001"
KEYCLOAK_USER="admin"
KEYCLOAK_PASSWORD="admin"
REALM="guacamole"
CLIENT_ID="guacamole"
GROUP_NAME="students"

# Obtener el token de acceso de administrador de Keycloak
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$KEYCLOAK_USER" \
    -d "password=$KEYCLOAK_PASSWORD" \
    -d 'grant_type=password' \
    -d 'client_id=admin-cli' | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "Error al obtener el token de Keycloak"
  exit 1
fi

# Obtener el ID del grupo 'students'
GROUP_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/groups?search=$GROUP_NAME" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[] | select(.name=="students") | .id')

if [ -z "$GROUP_ID" ]; then
  echo "Grupo 'students' no encontrado. Cree el grupo en Keycloak primero."
  exit 1
fi

# Agregar usuarios y asignarlos al grupo 'students'
while IFS= read -r username || [ -n "$username" ]; do
    # Crear usuario
    USER_ID=$(curl -s -D - -o /dev/null -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d '{
          "username": "'"$username"'",
          "enabled": true,
          "credentials": [
            {
              "type": "password",
              "value": "password",
              "temporary": false
            }
          ]
        }' | awk '/^Location:/ {print $2}' | awk -F'/' '{print $NF}' | tr -d '\r')

    if [ -z "$USER_ID" ]; then
        echo "Error al crear el usuario $username."
        continue
    fi

    # Agregar usuario al grupo 'students'
    curl -s -X PUT "$KEYCLOAK_URL/admin/realms/$REALM/users/$USER_ID/groups/$GROUP_ID" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{}'

    echo "Usuario $username creado y agregado al grupo 'students'."
done < "$USER_LIST"