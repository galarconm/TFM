#!/bin/bash

ROLE_NAME='student'

cecho(){
    RED="\033[0;31m"
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    printf "${!1}${2} ${NC}\n"
}

usage() { echo "Usage: $0 [-f <students_names_file>] [-j <Jenkins_URL>] [-u <Jenkins_user>] [-p <Jenkins_password>] [-s <single_student_account>] [-a <number_of_assignments>] [-c <type>] [-n <job_name>]" 1>&2; exit 1; }

checkURL() {
    curl -ivs $JENKINS_URL > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        return 0
    fi
    return 1
}

createFolder() {
    STUDENT=$1

    # Crear la carpeta principal
    curl -s -X POST "${JENKINS_URL}/createItem?name=${STUDENT}&mode=com.cloudbees.hudson.plugins.folder.Folder&from=&json={\"name\":\"${STUDENT}\",\"mode\":\"com.cloudbees.hudson.plugins.folder.Folder\",\"from\":\"\",\"Submit\":\"OK\"}&Submit=OK" --user ${USER}:${PASS} -H "Content-Type:application/x-www-form-urlencoded"

    # Crear subcarpetas
    i="0"
    while [ $i -lt ${PRACTICES:-1} ]; do
        i=$((i + 1))
        folder_name="P${i}" # Nombre predeterminado de la carpeta
        if [ ! -z "$TYPE" ]; then
            folder_name="P${i}__${TYPE}" # Agregar tipo al nombre de la carpeta
        fi
        if [ ! -z "$JOB_NAME" ]; then
            folder_name="${JOB_NAME}_${i}" # Agregar nombre del trabajo al nombre de la carpeta
        fi
        curl -s -X POST "${JENKINS_URL}/job/${STUDENT}/createItem?name=${folder_name}&mode=com.cloudbees.hudson.plugins.folder.Folder&Submit=OK" -H "Content-Type:application/x-www-form-urlencoded" --user ${USER}:${PASS}
    done

    # Crear y asignar roles de proyecto
    curl -s --user ${USER}:${PASS} ${JENKINS_URL}/role-strategy/strategy/addRole --data "type=projectRoles&roleName=${STUDENT}_folder&pattern=${STUDENT}&permissionIds=hudson.model.Item.Read,hudson.model.Item.Discover&overwrite=true"
    curl -s --user ${USER}:${PASS} ${JENKINS_URL}/role-strategy/strategy/assignRole --data "type=projectRoles&roleName=${STUDENT}_folder&sid=${STUDENT}"
    return 0
}

readFile() {
    while IFS='' read -r STUDENT || [[ -n "$STUDENT" ]]; do
        createFolder "$STUDENT"
    done < ${FILE}
}

while getopts ":f:j:a:u:p:c:n:s:" o; do
    case "${o}" in
        f)
            FILE=${OPTARG} # Archivo con la lista de usuarios
            ;;
        j)
            if [[ $OPTARG =~ http://* ]] || [[ $OPTARG =~ https://* ]] || [[ $OPTARG =~ HTTP://* ]] || [[ $OPTARG =~ HTTPS://* ]]; then
                JENKINS_URL="${OPTARG}"
            fi 
            ;;
        u)
            USER=${OPTARG} # Usuario administrador de Jenkins
            ;;
        p)
            PASS=${OPTARG} # Contraseña del usuario administrador
            ;;
        a)
            PRACTICES=${OPTARG} # Número de prácticas
            ;;
        c)
            TYPE=${OPTARG}
            if [ "$TYPE" = "a" ] || [ "$TYPE" = "A" ]; then
                TYPE="Autonomous"
            elif [ "$TYPE" = "f" ] || [ "$TYPE" = "F" ]; then
                TYPE="Face"
            else
                TYPE=""
            fi
            ;;
        n)
            JOB_NAME=${OPTARG} # Nombre del trabajo
            ;;
        s)
            STUDENT=${OPTARG} # Nombre de un solo estudiante
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${JENKINS_URL}" ] || [ -z "${USER}" ] || [ -z "${PASS}" ]; then
    cecho "BLUE" "ERROR: Faltan parámetros, revisa el uso."
    usage
    exit 1
fi

if [ ! -f "jenkins-cli.jar" ]; then
    cecho "YELLOW" "ERROR: No se encontró el archivo jenkins-cli.jar."
    exit 1
fi

if [ -z "${FILE}" ] && [ -z "${STUDENT}" ]; then
    cecho "RED" "ERROR: Faltan parámetros, revisa el uso."
    usage
    exit 1
fi

checkURL
if [ $? -eq 1 ]; then
    cecho "RED" "ERROR: La URL $JENKINS_URL no es accesible."
    exit 1
fi

if [ -z "${FILE}" ]; then
    createFolder "$STUDENT"
else
    readFile
fi