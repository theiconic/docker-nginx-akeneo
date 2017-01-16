#!/bin/bash

NET_SUBNET="192.168.231"

# Use configuration for environment vars
source ./.env

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

function provision_database()
{

	QUERIES=$(cat <<-EOF
	CREATE DATABASE IF NOT EXISTS ${PIM_DB_NAME};
	GRANT ALL PRIVILEGES ON ${PIM_DB_NAME}.* TO ${PIM_DB_USER}@'%' IDENTIFIED BY '${PIM_DB_PASSWORD}';
	FLUSH PRIVILEGES;
EOF
)
	print_msg "===== Creating DB user ..."

	docker exec akeneo_pim_mysql \
		mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "${QUERIES}" \
		> /dev/null 2>&1
	print_msg "Done"
}

# Bring up the infrastructure
print_msg "====== Bringing empty service ..."
	export SOURCE_PATH="$1"
	docker-compose up -d || exit 22
	# Store the working directory
	sed -i "s|WORKING_DIR=|WORKING_DIR=$(realpath ${SOURCE_PATH})|g" ./.env

	WEB_APP_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' akeneo_pim_app)
    print_msg "\nWeb service listening at http://${WEB_APP_IP}/"
    print_msg "For convience, you could add ${WEB_APP_IP} to /etc/hosts."
    print_msg "eg. echo '${WEB_APP_IP}	akeneo.pim' >> /etc/hosts\n"
print_msg "Done"

# Provision the system
print_msg "====== Provisioning Application server"
	# Make process user
	make_process_user
	provision_database
	provision_app
print_msg "Done"
