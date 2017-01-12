#!/bin/bash

## ------------------------------------
## Make process user
## ---------------------------------------
PIM_WEB_PROCESS_USER="${PIM_WEB_PROCESS_USER:=1000}"

function make_process_user()
{
	if [ $(id -u "${PIM_WEB_PROCESS_USER}"; echo $? ) -ne 0 ]; then
		addgroup -g "${PIM_WEB_PROCESS_USER}" alpine
    	adduser -u "${PIM_WEB_PROCESS_USER}" -G alpine alpine
	fi
}

## ------------------------------------
## Installs all project dependencies
## @param $WEBROOT
## ---------------------------------------
function composer_install()
{


	if [ $(which composer > /dev/null 2>&1; echo $? ) -eq 0  ]; then
		CWDir=$(pwd) && cd "$1"
		printf "\n    About to install vendors. Sit tight ...\n"

		# Check that we can install doctrine/mongodb-odm-bundle
		if [ $(composer show  | grep "mongo\-php\-adapter" > /dev/null 2>&1; echo $? ) -ne 0 ]; then

			xcommand="composer require --update-no-dev --no-scripts -vvv -d $1 'doctrine/mongodb-odm-bundle' "
			 # Check to see if we need to install composer
			if [ $( gosu alpine ${xcommand}; echo $?) -ne 0 ]; then
				# Current Doctrine isn't PHP7 compliant, we'll need to 
				# Install a middleware to make this backwards compatible
			 	gosu alpine composer require -d $1 alcaeus/mongo-php-adapter --ignore-platform-reqs --no-scripts 
			fi # Check that mongodb-odm-bundle can be installed safely
		else
			printf "    skipping"

		fi # Check for mongo-php-adapter exists
		
		# Install the project
		run_composer_install "$1"
		cd "${CWDir}"
		printf "\n    Done\n"
	fi

}

## ------------------------------------
## Runs composer install with Expect
## @param $WEBROOT
## ---------------------------------------
function run_composer_install()
{

	# We'll use PExpect to handle the DB setup
	cat > /tmp/composer_install.py <<-EOF
#!/usr/bin/env python
import pexpect
child = pexpect.spawn('gosu alpine composer install -o -d $1')

while True:
    try:
        child.expect('\):')
        child.sendline()
    except pexpect.EOF:
        child.sendline('exit');
        break
child.close()
EOF

	python /tmp/composer_install.py
	
}

if [ -z "$WEBROOT" ] && [ -d /var/www/pim/ ]; then
	WEBROOT=/var/www/pim/
fi

if [ -d "${WEBROOT}" ]; then

	# Set the timezone
	php_ini_file=$(realpath $(php7 --ini | grep -e ".*\Loaded Config" | cut -d':' -f2))

	if [ -z "$PIM_TIMEZONE" ]; then
		PIM_TIMEZONE="Australia/Sydney"
	fi

	sed -i -E "s|^;date\.timezone =$|date\.timezone = ${PIM_TIMEZONE}|g" "${php_ini_file}"
	sed -i -E "s|^date\.timezone =$|date\.timezone = ${PIM_TIMEZONE}|g" "${php_ini_file}"

	# Create user to run installation
	make_process_user

	composer_install "${WEBROOT}"

	# Set the default parameters
	params_file="${WEBROOT}/app/config/parameters.yml"
	if [ -f "${params_file}" ]; then
		gosu alpine sed -i -E "s#database_host: (.*)#database_host: ${PIM_DB_HOST}#" "${params_file}"
		gosu alpine sed -i -E "s#database_port: (.*)#database_port: ${PIM_DB_PORT}#" "${params_file}"
		gosu alpine sed -i -E "s#database_name: (.*)#database_name: ${PIM_DB_NAME}#" "${params_file}"
		gosu alpine sed -i -E "s#database_user: (.*)#database_user: ${PIM_DB_USER}#" "${params_file}"
		gosu alpine sed -i -E "s#database_password: (.*)#database_password: ${PIM_DB_PASSWORD}#" "${params_file}"
	fi

	gosu alpine php "${WEBROOT}"/app/console cache:clear --env=dev
	# Only provision env if requested
	if [ ! -z "${PIM_PROVISION}" ]; then
		gosu alpine php "${WEBROOT}"/app/console pim:install --env=dev --force
	fi

	# Make cache writeable
	chmod 777 -R "${WEBROOT}/app/cache"
	chmod 777 -R "${WEBROOT}/app/logs"
fi

supervisorctl restart nginx php-fpm7

echo "Done"
