#!/bin/bash


# Check if we are using Docker machine
MACHINE_NAME=
PROVISION="no"
COMPOSER_TOKEN=

function print_usage()
{
    
	echo " "
	echo -e "\033[1;34m"
    echo " Akeneo PIM Service installer"
    echo " "
    echo "$0 [-m,--using-machine my-machine-name] [-p,--provision] [-t,--token <composer-token>]"
    echo " "
    echo "options:"
    echo "-m, --using-machine       docker machine name"
    echo "-p, --provision           true to force DB setup."
    echo "-t, --token               composer token"
    echo " "
    echo " examples:"
    echo ""
    echo "   $0   -m new-machine --provision"
    echo "   $0   --using-machine new-machine -p"
    echo "   $0   --using-machine new-machine -p -t 123abcd4nice1token"
    echo "   $0   --provision"
    echo "   $0   --provision --token 123abcd4nice1token"
    echo -e "\033[0m"
}

while test $# -gt 0; do
	case "$1" in
	-h|--help)
        print_usage
        exit 0
        ;;
	-t|--token)
		COMPOSER_TOKEN="$2"
		shift
		;;
	-m|--using-machine)
		MACHINE_NAME="$2"
		shift
		;;
	-p|--provision)
		PROVISION="yes"
		;;
	*)
		break
		;;
	esac
	# Move to next parameter
	shift
done

# Copy the configuration file
COPY='cp -v '
S_PLATFORM=`uname`
IS_LINUX=

if [ "${S_PLATFORM}" == 'Linux' ]; then
	COPY="${COPY} --update --backup" # Linux implementation support these flag
	IS_LINUX=1
fi

$COPY .env.dist .env
# Store the machine name
if [ -n "${MACHINE_NAME}" ]; then
	sed -i -E "s|MACHINE_NAME=(.*)|MACHINE_NAME=${MACHINE_NAME}|" .env
fi

# Linux is compatible with Boot2Docker, so let's mount correctly
if [ -n "${IS_LINUX}" ]; then
	sed -i -E "s|USER_ID=(.*)|USER_ID=$(id -u)\:$(id -g)|g" .env
fi

# Use configuration for environment vars
source ./.env
if [ -z "${PIM_DB_NAME}" ] || [ -z "${PIM_DB_USER}" ]; then
	echo ""
	echo "Please set your environment values in '.env' file "
	echo "and try again. Thank you."
	echo ""
    print_usage
	exit 1
fi

DOCKER_EXEC="docker exec akeneo_pim_app "

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

    if [ -n "${COMPOSER_TOKEN}" ]; then
        echo "Setting composer token globally"
        $DOCKER_EXEC composer config -g github-oauth.github.com "${COMPOSER_TOKEN}"
    fi

	# Check that we can install doctrine/mongodb-odm-bundle
	if [ $($DOCKER_EXEC composer show  | grep "mongo\-php\-adapter" > /dev/null 2>&1; echo $? ) -ne 0 ]; then

		xcommand="composer require --update-no-dev --no-scripts -v 'doctrine/mongodb-odm-bundle' "
		 # Check to see if we need to install composer
		if [ $( $DOCKER_EXEC ${xcommand} 2> /dev/null; echo $?) -ne 0 ]; then
			# Current Doctrine 3.0 isn't PHP7 compliant, we'll need to
			# Install a middleware to make this backwards compatible
			# See https://github.com/alcaeus/mongo-php-adapter#goal
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
		sed -i -E "s#database_password: (.*)#database_password: ${PIM_DB_PASSWORD}#" "\${params_file}"
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
	$DOCKER_EXEC app/console cache:clear --env="${RUNNING_ENV}"
	$DOCKER_EXEC app/console cache:warmup --env="${RUNNING_ENV}"
	
	# Only provision env if requested
	if [ "x${PROVISION}" == "xyes" ]; then # \\$PIM_PROVISION is from .env files
		$DOCKER_EXEC app/console pim:install --env="${RUNNING_ENV}" --force
	else
		$DOCKER_EXEC app/console pim:install --env="${RUNNING_ENV}"
	fi

	# Temp. work around :)
	$DOCKER_EXEC app/console  --env="${RUNNING_ENV}" oro:translation:dump en_US
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
		mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "${QUERIES}" # This is run on the mysql server so no port required
	print_msg "Done"
}

# Bring up the infrastructure
print_msg "====== Bringing empty service ..."
    
    # Ensure Linux paths are mounted properly
    if [ -n "${MACHINE_NAME}" ]; then
        ./prep_machine.sh "${MACHINE_NAME}"
    fi

	docker-compose up -d --force-recreate || exit 22
	
    if [ -z "${MACHINE_NAME}" ]; then
	    WEB_APP_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' akeneo_pim_app)
	else
	    WEB_APP_IP=$(docker-machine ip "${MACHINE_NAME}")
	fi
    print_msg "\nWeb service listening at http://${WEB_APP_IP}/"
    print_msg "For convience, you could add ${WEB_APP_IP} to /etc/hosts."
    print_msg "eg."
    print_msg "  echo '${WEB_APP_IP} akeneo.pim akeneo.pim.local akeneo.db akeneo.db.local akeneo.behat akeneo.behat.local' | sudo tee -a /etc/hosts"
print_msg "Done"

# Provision the system
print_msg "====== Provisioning Application server"
	provision_database
	provision_app
	if [ -n "${MACHINE_NAME}" ]; then
	    ETC_HOSTS=$(cat <<-EOF
	echo "127.0.0.1 akeneo.pim akeneo.pim.local akeneo.db akeneo.db.local akeneo.behat akeneo.behat.local" 
EOF
)
	    print_msg "Consider adding the following to the /etc/hosts in docker-machine manually:\n ${ETC_HOSTS}"
	fi
print_msg "Done"
