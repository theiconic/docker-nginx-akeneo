#!/bin/bash



# Use configuration for environment vars
source ./.env

DOCKER_EXEC="docker exec akeneo_pim_app "
MACHINE_NAME="${MACHINE_NAME-machine}"

function print_msg()
{
	printf "$1\n"	
}


## ------------------------------------
## Installs all project dependencies
## @param $WEBROOT
## ---------------------------------------
function composer_install()
{

	
	printf "\n    About to install vendors. Sit tight ...\n"

	# Check that we can install doctrine/mongodb-odm-bundle
	if [ $($DOCKER_EXEC composer show  | grep "mongo\-php\-adapter" > /dev/null 2>&1; echo $? ) -ne 0 ]; then

		xcommand="composer require --update-no-dev --no-scripts -v 'doctrine/mongodb-odm-bundle' "
		 # Check to see if we need to install composer
		if [ $( $DOCKER_EXEC ${xcommand} 2> /dev/null; echo $?) -ne 0 ]; then
			# Current Doctrine isn't PHP7 compliant, we'll need to 
			# Install a middleware to make this backwards compatible
		 	$DOCKER_EXEC composer require alcaeus/mongo-php-adapter --ignore-platform-reqs --no-scripts 
		fi # Check that mongodb-odm-bundle can be installed safely
	else
		printf "    skipping\n"

	fi # Check for mongo-php-adapter exists
	
	# Install the project
	echo "     Performing PIM seup ..."
	COMPOSER_INSTALL=$(cat <<-EOF
	printf "\n\n\n\n\n" | composer install -o
EOF
)

	$DOCKER_EXEC /bin/sh -c "${COMPOSER_INSTALL}"

	printf "\n    Done\n"

}


function set_parameter()
{

CONFIG_COMMAND=$(cat <<-EOF

WEBROOT=/var/www/pim/

if [ -d "\${WEBROOT}" ]; then

	# current php ini file
	php_ini_file=\$(realpath \$(php --ini | grep -e ".*\Loaded Config" | cut -d':' -f2))

	PIM_TIMEZONE="Australia/Sydney"
	
	sed -i -E "s|^;date\.timezone =\\$|date\.timezone = \${PIM_TIMEZONE}|g" "\${php_ini_file}"
	sed -i -E "s|^date\.timezone =\\$|date\.timezone = \${PIM_TIMEZONE}|g" "\${php_ini_file}"

	# Set the default parameters
	params_file="\${WEBROOT}/app/config/parameters.yml"
	if [ -f "\${params_file}" ]; then
		sed -i -E "s#database_host: (.*)#database_host: ${PIM_DB_HOST}#" "\${params_file}"
		sed -i -E "s#database_port: (.*)#database_port: ${PIM_DB_PORT}#" "\${params_file}"
		sed -i -E "s#database_name: (.*)#database_name: ${PIM_DB_NAME}#" "\${params_file}"
		sed -i -E "s#database_user: (.*)#database_user: ${PIM_DB_USER}#" "\${params_file}"
		sed -i -E "s#database_password: (.*)#database_password: \${PIM_DB_PASSWORD}#" "\${params_file}"
	fi

fi
EOF
)
	$DOCKER_EXEC /bin/sh -c "${CONFIG_COMMAND}"
}

function provision_app()
{
	print_msg "Pre-installing empty project ..."
	composer_install
	
	# Set the project params
	print_msg "Settting project settings \"parameters.yml\" etc."
	set_parameter

	print_msg "Warming up cache"
	$DOCKER_EXEC app/console cache:clear --env=dev
	$DOCKER_EXEC app/console cache:warmup --env=dev
	
	# Only provision env if requested
	if [ ! -z "${PIM_PROVISION}" ]; then # \\$PIM_PROVISION is from .env files
		$DOCKER_EXEC app/console pim:install --env=dev --force
	fi

	# Temp. work around :)
	$DOCKER_EXEC app/console  --env=dev oro:translation:dump en_US
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
	docker-compose up -d || exit 22
	#WEB_APP_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' akeneo_pim_app)
	WEB_APP_IP=$(docker-machine ip $MACHINE_NAME)
    print_msg "\nWeb service listening at http://${WEB_APP_IP}/"
    print_msg "For convience, you could add ${WEB_APP_IP} to /etc/hosts."
    print_msg "eg. echo '${WEB_APP_IP}	akeneo.pim' >> /etc/hosts\n"
print_msg "Done"

# Provision the system
print_msg "====== Provisioning Application server"
	provision_database
	provision_app
print_msg "Done"
