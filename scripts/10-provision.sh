#!/bin/bash

#
# Reload Supervisor
# --------------------------------------

if [ -z "$WEBROOT" ] && [ -d /var/www/pim/ ]; then
	WEBROOT=/var/www/pim/
fi

if [ -d "${WEBROOT}" ]; then
	if [ $(which composer > /dev/null 2>&1; echo $? ) -eq 0  ]; then
		composer install -o
	fi

	# Set the default parameters
	params_file="${WEBROOT}/app/config/parameters.yml"
	if [ -f "${params_file}" ]; then
		sed -i -E "s#database_host: (.*)#database_host: ${PIM_DB_HOST}#" "${params_file}"
		sed -i -E "s#database_port: (.*)#database_port: ${PIM_DB_PORT}#" "${params_file}"
		sed -i -E "s#database_name: (.*)#database_name: ${PIM_DB_NAME}#" "${params_file}"
		sed -i -E "s#database_user: (.*)#database_user: ${PIM_DB_USER}#" "${params_file}"
		sed -i -E "s#database_password: (.*)#database_password: ${PIM_DB_PASSWORD}#" "${params_file}"
	fi

	# Set the timezone
	php_ini_file=$(realpath $(php7 --ini | grep -e ".*\Loaded Config" | cut -d':' -f2))

	if [ -z "$PIM_TIMEZONE" ]; then
		PIM_TIMEZONE="Australia/Sydney"
	fi

	sed -i -E "s|^;date\.timezone =$|date\.timezone = ${PIM_TIMEZONE}|g" "${php_ini_file}"
	sed -i -E "s|^date\.timezone =$|date\.timezone = ${PIM_TIMEZONE}|g" "${php_ini_file}"

	php "${WEBROOT}"/app/console cache:clear --env=dev
	# Only provision env if requested
	if [ ! -z "${PIM_PROVISION}" ]; then
		php "${WEBROOT}"/app/console pim:install --env=dev
	fi

	# Make cache writeable
	chmod 777 -R "${WEBROOT}/app/cache"
	chmod 777 -R "${WEBROOT}/app/logs"
fi

supervisorctl restart nginx php-fpm7

echo "Done"
