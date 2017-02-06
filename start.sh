#!/bin/bash

source .env
MACHINE_NAME="${MACHINE_NAME-machine}"
DOCKER_EXEC="docker exec akeneo_pim_app "

function print_msg()
{
    printf "$1\n"   
}


# If you wish to run this everytime you start your machines
# on a Linux machine, you could uncomment these lines
if [[ "`uname`" == 'Linux' ]]; then
    ./linux_machine.sh $MACHINE_NAME
fi

## ------------------------------------
## Bring up the infrastructure
## ---------------------------------------
print_msg "====== Staring Akeneo Service ..."
    docker-compose up -d || exit 22
    #WEB_APP_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' akeneo_pim_app)
    WEB_APP_IP=$(docker-machine ip $MACHINE_NAME)
    print_msg "Web service listening at http://${WEB_APP_IP}/"
print_msg "Done"

