#!/bin/bash

NET_SUBNET="192.168.231"

# Ensure we have a folder to work with
if [ -z "$1" ]; then
	echo "Please specify Akeneo git folder"
	exit 1
fi


# Make the connection
source ./.connection.sh

function print_msg()
{
	printf "$1\n"	
}


function make_process_user()
{
	source ./.env
	PIM_WEB_PROCESS_USER= "${PIM_WEB_PROCESS_USER:=$(echo id -u)}"
	COMMANDS=$(cat <<-EOF
	if [ \$(id -u alpine > /dev/null 2>&1; echo \$? ) -ne 0 ]; then
		addgroup -g "${PIM_WEB_PROCESS_USER}" alpine
    	adduser -D -u "${PIM_WEB_PROCESS_USER}" -G alpine alpine
	fi; exit
EOF
)
	docker exec akeneo_pim_app /bin/bash -c "${COMMANDS}"

}

function provision_app()
{
	docker exec akeneo_pim_app /bin/bash /var/www/html/scripts/10-provision.sh
}

# Bring up the infrastructure
print_msg "====== Bringing empty service ..."
	export SOURCE_PATH="$1"
	docker-compose up -d || exit 22
	# Store the working directory
	sed -i "s|WORKING_DIR=|WORKING_DIR=$(realpath ${SOURCE_PATH})|g" ./.env
print_msg "Done"

# Provision the system
print_msg "====== Provisioning Application server"
	# Make process user
	make_process_user
	provision_app
print_msg "Done"
