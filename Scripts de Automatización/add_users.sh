#!/bin/bash

# Asegurarse de que el script se ejecute con exactamente un argumento
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <archivo_de_usuarios>"
    exit 1
fi

USER_FILE=$1
PASSWORD="password"

# Verificar si el archivo de usuarios existe
if [ ! -f "$USER_FILE" ]; then
    echo "El archivo $USER_FILE no existe."
    exit 1
fi

# Leer el archivo de usuarios línea por línea
while IFS= read -r USERNAME || [ -n "$USERNAME" ]; do
    # Verificar si el usuario ya existe
    if id "$USERNAME" &>/dev/null; then
        echo "El usuario $USERNAME ya existe."
    else
        # Crear el usuario con un directorio home
        useradd -m -d /home/userdata/"$USERNAME" "$USERNAME"
        if [ $? -ne 0 ]; then
            echo "Error al agregar el usuario $USERNAME. Omitiendo."
            continue
        fi

        # Establecer la contraseña para el usuario
        echo "$USERNAME:$PASSWORD" | chpasswd

        # Asegurar la propiedad adecuada del directorio home del usuario
        chown "$USERNAME":"$USERNAME" /home/userdata/"$USERNAME"

        # Establecer permisos para el directorio home del usuario
        chmod 700 /home/userdata/"$USERNAME"

        echo "Usuario $USERNAME agregado exitosamente!"
    fi
done < "$USER_FILE"