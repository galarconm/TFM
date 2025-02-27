#! /bin/bash

# Configuración de Keycloak
KEYCLOAK_URL="http://158.42.104.43:31001"
KEYCLOAK_USER="admin"
KEYCLOAK_PASSWORD="admin"

# Obtener token de acceso de Keycloak
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

# Crear Realm guacamole
echo "🛠️ Creando Realm 'guacamole'..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "realm": "guacamole",
        "enabled": true
    }'
echo "✅ Realm 'guacamole' creado."

# Crear Client guacamole
echo "🛠️ Creando Client 'guacamole'..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms/guacamole/clients" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "clientId": "guacamole",
        "enabled": true,
        "standardFlowEnabled": true,
        "implicitFlowEnabled": true,
        "directAccessGrantsEnabled": true,
        "rootUrl": "http://158.42.104.43:30000",
        "redirectUris": ["http://158.42.104.43:30000/*"],
        "webOrigins": ["http://158.42.104.43:30000"],
        "adminUrl": "http://158.42.104.43:30000/"
    }'
echo "✅ Client 'guacamole' creado."

# Configurar Mapper para ID de Grupo en el Realm de guacamole
echo "🛠️ Configurando Mapper para ID de Grupo en el Realm 'guacamole'..."

# Crear Client Scope 'groups'
echo "🔧 Creando Client Scope 'groups'..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms/guacamole/client-scopes" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "groups",
        "protocol": "openid-connect",
        "attributes": {
            "display.on.consent.screen": "true",
            "include.in.token.scope": "true"
        }
    }'
echo "✅ Client Scope 'groups' creado."

# Obtener ID del Client Scope 'groups'
SCOPE_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/guacamole/client-scopes" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[] | select(.name=="groups") | .id')

# Crear Mapper 'groups'
echo "🔧 Creando Mapper 'groups'..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms/guacamole/client-scopes/$SCOPE_ID/protocol-mappers/models" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "groups",
        "protocol": "openid-connect",
        "protocolMapper": "oidc-group-membership-mapper",
        "config": {
            "full.path": "false",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "groups",
            "userinfo.token.claim": "true"
        }
    }'
echo "✅ Mapper 'groups' creado."

# Asignar Client Scope 'groups' al Client 'guacamole'
echo "🔧 Asignando Client Scope 'groups' al Client 'guacamole'..."
CLIENT_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/guacamole/clients" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[] | select(.clientId=="guacamole") | .id')

curl -s -X POST "$KEYCLOAK_URL/admin/realms/guacamole/clients/$CLIENT_ID/default-client-scopes/$SCOPE_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json"
echo "✅ Client Scope 'groups' asignado al Client 'guacamole'."

# Crear Realm jenkins
echo "🛠️ Creando Realm 'jenkins'..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "realm": "jenkins",
        "enabled": true
    }'
echo "✅ Realm 'jenkins' creado."

# Crear Cliente para Jenkins
echo "🛠️ Creando Cliente 'jenkins'..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms/jenkins/clients" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "clientId": "jenkins",
        "enabled": true,
        "rootUrl": "http://158.42.104.43:31000",
        "redirectUris": ["http://158.42.104.43:31000/*"],
        "webOrigins": ["http://158.42.104.43:31000"],
        "adminUrl": "http://158.42.104.43:31000/"
    }'
echo "✅ Cliente 'jenkins' creado."

# Obtener JSON de configuración del Cliente Jenkins
echo "🔧 Generando JSON de configuración para Jenkins..."
CLIENT_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/jenkins/clients" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[] | select(.clientId=="jenkins") | .id')

CONFIG_JSON=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/jenkins/clients/$CLIENT_ID/installation/providers/keycloak-oidc-keycloak-json" \
    -H "Authorization: Bearer $TOKEN")

echo "🔑 JSON de configuración para Jenkins:"
echo "$CONFIG_JSON" | jq
echo "✅ JSON generado y copiado al portapapeles."

# Crear Roles en Keycloak
echo "🛠️ Creando Roles en Keycloak..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms/jenkins/roles" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "jenkins_admin"}'

curl -s -X POST "$KEYCLOAK_URL/admin/realms/jenkins/roles" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "jenkins_students"}'
echo "✅ Roles 'jenkins_admin' y 'jenkins_students' creados."

# Crear Usuarios y Asignar Roles
echo "🛠️ Creando Usuarios y Asignando Roles..."

# Crear usuario admin
curl -s -X POST "$KEYCLOAK_URL/admin/realms/jenkins/users" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "admin",
        "enabled": true,
        "credentials": [
            {
                "type": "password",
                "value": "admin",
                "temporary": false
            }
        ]
    }'

# Obtener ID del usuario admin
ADMIN_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/jenkins/users" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[] | select(.username=="admin") | .id')

# Obtener ID del rol jenkins_admin
ROLE_ADMIN_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/jenkins/roles" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[] | select(.name=="jenkins_admin") | .id')

# Asignar rol jenkins_admin al usuario admin
curl -s -X POST "$KEYCLOAK_URL/admin/realms/jenkins/users/$ADMIN_ID/role-mappings/realm" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '[{"id":"'"$ROLE_ADMIN_ID"'","name":"jenkins_admin"}]'

# Crear usuario estudiante
curl -s -X POST "$KEYCLOAK_URL/admin/realms/jenkins/users" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "usuario1",
        "enabled": true,
        "credentials": [
            {
                "type": "password",
                "value": "usuario1",
                "temporary": false
            }
        ]
    }'

# Obtener ID del usuario estudiante
USER_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/jenkins/users" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[] | select(.username=="usuario1") | .id')

# Obtener ID del rol jenkins_students
ROLE_STUDENTS_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/jenkins/roles" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[] | select(.name=="jenkins_students") | .id')

# Asignar rol jenkins_students al usuario estudiante
curl -s -X POST "$KEYCLOAK_URL/admin/realms/jenkins/users/$USER_ID/role-mappings/realm" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '[{"id":"'"$ROLE_STUDENTS_ID"'","name":"jenkins_students"}]'

echo "✅ Usuarios creados y roles asignados."


echo "🎉 ¡Configuración completada!"