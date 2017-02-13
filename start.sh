#!/bin/bash

MACHINE_NAME=
source .env
DOCKER_EXEC="docker exec akeneo_pim_app "

function print_msg()
{
    printf "$1\n"   
}

# This is a hack around mounting Linux volumes on docker-machines properly
# @see https://github.com/docker/machine/issues/3234#issuecomment-202596213
if [ -n "${MACHINE_NAME}" ] && [ "`uname`" == 'Linux' ]; then
    ./linux_machine.sh $MACHINE_NAME
fi

## ------------------------------------
## Bring up the infrastructure
## ---------------------------------------
print_msg "====== Staring Akeneo Service ..."
    if [ -z "${MACHINE_NAME}" ]; then
        # Ensure we are using the right docker connections
        eval $(docker-machine env "${MACHINE_NAME}")
    fi
    docker-compose up -d || exit 22
    echo "${MACHINE_NAME}"
    if [ -z "${MACHINE_NAME}" ]; then
	    WEB_APP_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' akeneo_pim_app)
	else
	    WEB_APP_IP=$(docker-machine ip "${MACHINE_NAME}")
	fi
	print_msg "Web service listening at http://${WEB_APP_IP}/"
print_msg "Done"

