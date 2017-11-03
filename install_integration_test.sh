#!/bin/bash

# Store the machine name
if [ -n "${MACHINE_NAME}" ]; then
	sed -i -E "s|MACHINE_NAME=(.*)|MACHINE_NAME=${MACHINE_NAME}|" .env
fi

# Use configuration for environment vars
source ./.env
if [ -z "${PIM_INTEGRATION_DB_NAME}" ] || [ -z "${PIM_INTEGRATION_DB_USER}" ]; then
	echo ""
	echo "Please set your integration environment values in '.env' file "
	echo "and try again. Thank you Sir/Lady."
	echo ""
    print_usage
	exit 1
fi

function print_msg()
{
	printf "$1\n"	
}

print_msg "Creating Integration DB..."
docker exec akeneo_pim_app /var/www/pim/app/console pim:installer:db --env=test
print_msg "Done!"

print_msg "Running the migrations..."
docker exec -i akeneo_pim_app "${WEBROOT}"/app/console doctrine:migrations:migrate --no-interaction --env=test
print_msg "Done!"
