#! /bin/bash

if [ "$#" -ne 1 ]; then
    echo "❌ Usage: $0 <user_file>"
    exit 1
fi

USER_LIST=$1

# Keycloak configuration
KEYCLOAK_URL="http://158.42.104.43:31001"
KEYCLOAK_USER="admin"
KEYCLOAK_PASSWORD="admin"
REALM="jenkins"  # Cambia esto al realm de Jenkins
CLIENT_ID="jenkins"  # Cambia esto al client ID de Jenkins
ROLE_NAME="students"  # Cambia esto al nombre del rol que deseas asignar

# Get Keycloak admin access token
echo "🔑 Obteniendo token de acceso de Keycloak..."
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$KEYCLOAK_USER" \
    -d "password=$KEYCLOAK_PASSWORD" \
    -d 'grant_type=password' \
    -d 'client_id=admin-cli' | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "❌ Error: No se pudo obtener el token de Keycloak."
  exit 1
fi
echo "✅ Token de acceso obtenido correctamente."

# Get the ID of the 'students' role
echo "🔍 Buscando el rol '$ROLE_NAME'..."
ROLE_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/roles" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[] | select(.name=="'"$ROLE_NAME"'") | .id')

if [ -z "$ROLE_ID" ]; then
  echo "❌ Error: El rol '$ROLE_NAME' no existe. Por favor, créalo en Keycloak primero."
  exit 1
fi
echo "✅ Rol '$ROLE_NAME' encontrado (ID: $ROLE_ID)."

# Add users and assign them the 'students' role
echo "👥 Procesando la lista de usuarios..."
while IFS= read -r username || [ -n "$username" ]; do
    # Create user
    echo "🛠️ Creando usuario: $username..."
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
        echo "❌ Error: No se pudo crear el usuario $username."
        continue
    fi
    echo "✅ Usuario $username creado correctamente (ID: $USER_ID)."

    # Assign the 'students' role to the user
    echo "🎓 Asignando el rol '$ROLE_NAME' al usuario $username..."
    curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users/$USER_ID/role-mappings/realm" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '[{"id":"'"$ROLE_ID"'","name":"'"$ROLE_NAME"'"}]'

    echo "✅ Usuario $username creado y asignado al rol '$ROLE_NAME'."
done < "$USER_LIST"

echo "🎉 ¡Proceso completado!"