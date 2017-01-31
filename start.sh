#!/bin/bash


DOCKER_EXEC="docker exec akeneo_pim_app "


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

## ------------------------------------
## Make process user
## ---------------------------------------
PIM_WEB_PROCESS_USER="${PIM_WEB_PROCESS_USER:=1000}"

function make_process_user()
{
	DOCKER_EXEC="docker exec akeneo_pim_app "
	if [ $($DOCKER_EXEC id -u alpine > /dev/null 2>&1; echo $? ) -ne 0 ]; then
		$DOCKER_EXEC addgroup -g "${PIM_WEB_PROCESS_USER}" alpine
    	$DOCKER_EXEC  adduser -D -u "${PIM_WEB_PROCESS_USER}" -G alpine alpine
	fi
}

## ------------------------------------
## Set some folder permissions to help with running
## ---------------------------------------
function set_folder_perm()
{
	# Ensure all folders are writable
	for f in "app/cache" "app/logs" "web/uploads" "web/media"; do
        TARG_PATH="/var/www/pim/$f"
        # Create the directory if none exists yet
        if [ $($DOCKER_EXEC stat "$TARG_PATH" > /dev/null 2>&1; echo $? ) -ne 0 ]; then
            echo "Pre-creating '$TARG_PATH'."
            $DOCKER_EXEC mkdir -p "$TARG_PATH"
        fi
		$DOCKER_EXEC find "$TARG_PATH" -type d -exec chmod 777 {} \;
	done
}


## ------------------------------------
## Bring up the infrastructure
## ---------------------------------------
print_msg "====== Staring Akeneo Service ..."
    export SOURCE_PATH="${WORKING_DIR}"
    docker-compose up -d || exit 22
    make_process_user
    set_folder_perm
    WEB_APP_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' akeneo_pim_app)
    print_msg "Web service listening at http://${WEB_APP_IP}/"
print_msg "Done"

