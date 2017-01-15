#!/bin/bash

# Ensure we have a folder to work with
source ./.env
if [ -z "${WORKING_DIR}" ] && [ -z "$1" ]; then
    echo "Please specify Akeneo git folder"
    exit 1
fi


# Make the connection
source ./.connection.sh

function print_msg()
{
    printf "$1\n"   
}


# Bring up the infrastructure
print_msg "====== Staring Akeneo Service ..."
    export SOURCE_PATH="${WORKING_DIR}"
    docker-compose up -d || exit 22
    WEB_APP_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' akeneo_pim_app)
    print_msg "Web service listening at http://${WEB_APP_IP}/"
print_msg "Done"
