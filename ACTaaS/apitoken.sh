#!/bin/bash

# Configuración
JENKINS_URL="http://192.168.49.2:31000"  # URL de tu servidor Jenkins
USERNAME="admin"                   # Nombre de usuario del administrador
PASSWORD="admin"        # Contraseña del administrador o token existente
TOKEN_NAME="MyGeneratedToken"      # Nombre del token que se generará

# Generar token usando la API REST
RESPONSE=$(curl -s -u "$USERNAME:$PASSWORD" -X POST "$JENKINS_URL/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" \
  --data-urlencode "newTokenName=$TOKEN_NAME" \
  -H "Content-Type: application/x-www-form-urlencoded")

# Extraer el token de la respuesta
TOKEN=$(echo "$RESPONSE" | jq -r '.data.tokenValue')

# Validar si el token fue generado correctamente
if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
  echo "Token generado con éxito: $TOKEN"
else
  echo "Error al generar el token. Respuesta: $RESPONSE"
fi
