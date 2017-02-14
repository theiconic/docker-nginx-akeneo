# Akeneo PIM Docker Service
Akeneo PIM docker using Nginx and PHP 7

## Overview
This is a simple Akeneo PIM Docker image running PHP7, Nginx with PHP-FPM.

This borrows largely from two worlds [Akeneo PIM](https://docs.akeneo.com/1.6/developer_guide/installation/system_requirements/system_install_ubuntu_1604.html) and [nginx-php-fpm](https://github.com/ngineered/nginx-php-fpm). Pull requests are encouraged.

Currently this is aimed at using Akeneo in development arena, but with extensive testing, this setup should be useful in production environment as well.

First checkout Akeneo PIM repository
```
git clone https://github.com/akeneo/pim-community-standard.git preferred-directory
```

## # Running Service Clusters
It's easy as:
- Cloning this repository
```BASH
git clone https://github.com/theiconic/docker-nginx-akeneo.git
cd docker-nginx-akeneo
```
- **Setup your docker-compose** as desired. You may enable Behat service if needed
```BASH
$ > cp -v -b docker-compose.yml.dist docker-compose.yml
$ > vim docker-compose.yml # or anything to edit
```

- *If you need to create docker machine, please refer to [the creating docker-machine guide](https://docs.docker.com/machine/get-started/#/create-a-machine)* for your platform. Don't forget to create a machine if you are not using the native docker. You can create a new machine just by running the following:
```BASH
docker-machine create -d virtualbox --virtualbox-memory 2048 akeneo
```

- Set your environment parameters
```BASH
$ > cp -v -b .env.dist .env
```
Or just run ...
```BASH
$ > ./install.sh [--usring-machine my-docker-machine] [--provision] 
# This will copy the .env [if needed] and die with the following message :

  Please set your environment values in '.env' file 
  and try again. Thank you.

```
Edit your `.env` file as required
```
# Update the .env with your custom environment variables
$ > vim .env # Or whatever
```
**Sample .env file**
```BASH
# .env
WEBROOT=/var/www/pim/
SOURCE_PATH=/home/ilorin/Workspace/pim-community-standard

MYSQL_PORT=3309
MYSQL_ROOT_PASSWORD=043h

# Your docker machine name if using one
MACHINE_NAME=akeneo

# You can get this from running "id -u", "id -g". Please keep this as 1000 if not running on Linux env ;)
USER_ID=1000

# Composer cache
COMPOSER_HOME=.composer/

#-------------
# PIM configs
RUNNING_ENV=dev

PIM_DB_HOST=mysql
PIM_DB_PORT=3306
PIM_DB_NAME=akeneo_pim
PIM_DB_USER=akeneo_pim
PIM_DB_PASSWORD=

# Behat stuff (Optional)
PIM_BEHAT_DB_HOST=mysql
PIM_BEHAT_DB_PORT=~
PIM_BEHAT_DB_NAME=akeneo_behat
PIM_BEHAT_DB_USER=akeneo_behat
PIM_BEHAT_DB_PASSWORD=

```

### # Installation - automated, trust me.
- Install the project. This could take up to half an hour depending on your connection, your mileage may vary. **TODO.** improve this. Possibly due to slow composer install
```
$ > ./install.sh [--using-machine my-docker-machine] --provision --token 123abcd4nice1token

```
**Remeber to specify the necessary parameters for the `install.sh` script.**
***--using-machine*** If running docker inside a docker machine, specify your machine name, eg. `-m akeneo` or `--using-machine akeneo`

***--provision*** Generally you will always provide this parameter. equivalent is `-p`. It's set as a parameter to avoid accidentally overrwriting your DB, but Akeneo also does this check internally when installing :)

***--token*** It's recommended to specify your github oauth token to avoid hitting the GitHub API clone restrictions when pulling the Akeneo's vendor packages from github && packagist.org


- **Subsequent runs cab be done just by running**:
```
$ > ./start.sh

# This is just a wrapper for docker-compose down. Nothing fancy for now. :)
$ > ./stop.sh # To stop all services
```

***That's it!*** Remember to add the IP to your `/etc/hosts` for convenience.
```
For convience, you could add your docker-machine to /etc/hosts.
eg. 
    echo "$(docker-machine ip my-machine)	akeneo.pim akeneo.pim.local akeneo.db akeneo.db.local akeneo.behat.local akeneo.behat.local | sudo tee -a /etc/hosts
    
    Or 127.0.0.1 if not using docker machine
```
You could also edit the `/etc/hosts` on your docker machine too if have need for such :)

## # Behat Setup
Akeneo comes bundled with great BDD that runs off Behat amongst others, to harness hacking, you could enable the Behat service.

- First, create a new database and user for behat fixtures.
This assumes that your `${PIM_BEHAT_DB_HOST}` points to your mysql running container. 
```
$ > source .env
$ > mysql -uroot -p${MYSQL_ROOT_PASSWORD} -h ${PIM_BEHAT_DB_HOST}
# Inside mysql prompt
$ MySQL [(none)] > CREATE DATABASE IF NOT EXISTS <your-behat-db-name>;
$ MySQL [(none)] > GRANT ALL PRIVILEGES ON <your-behat-db-name>.* TO <your-behat-db-user>@'%' IDENTIFIED BY '<desired-password>';
$ MySQL [(none)] > FLUSH PRIVILEGES;
```
***For more information** please refer to [Akeneo Official Behat page](https://docs.akeneo.com/1.5/reference/best_practices/core/behat.html#configure-behat)*

- Then update the `.env` and `app/config/parameters_test.yml` to have same credentials you just created
For example:
```
# .env file

# Behat stuff (Optional)
PIM_BEHAT_DB_HOST=mysql-host
PIM_BEHAT_DB_PORT=3306
PIM_BEHAT_DB_NAME=pim_behat_db
PIM_BEHAT_DB_USER=pim_behat
PIM_BEHAT_DB_PASSWORD=
```

And inside `app/config/parameters_test.yml` **in your Akeneo Pim project folder**, make the following settings . If you don't have one just copy `cp app/config/parameters_test.yml.dist app/config/parameters_test.yml`.

```
# app/config/parameters_tests.yml file

parameters:
    database_driver: pdo_mysql
    database_host: mysql-host
    database_port: 3306
    database_name: pim_behat_db
    database_user: pim_behat
    database_password: null
```
- Also update your `behat.yml` **in your Akeneo Pim project folder**. If you don't have one, copy from dist as well `cp behat.yml.dist behat.yml`.
```
# behat.yml file
default:
    paths:
        features: features
    context:
        class:  Context\FeatureContext
        parameters:
            base_url: http://akeneo_pim_nginx:8081/ # <----- Configured to listen on port 8081 for Behat if using recommended setup
            timeout: 30000
            window_width: 1280
            window_height: 1024
    extensions:
        Behat\MinkExtension\Extension:
            default_session: symfony2
            show_cmd: chromium-browser %s
            selenium2:
              wd_host: "http://akeneo_pim_selenium:4444/wd/hub" <--- points to the selenium service
            base_url: http://akeneo_pim_nginx:8081/ # <------------------- Same as above
            files_path: 'features/Context/fixtures/'
        Behat\Symfony2Extension\Extension:
            kernel:
                env: behat
                debug: false
        SensioLabs\Behat\PageObjectExtension\Extension: ~

```

- Uncomment the Selenium service in your `docker-compose.yml` and restart your services `./stop.sh && ./start.sh`  or manually.
- Install the Behat setup and fixutres
```
docker exec akeneo_pim_app app/console pim:install --env=behat --force
```
### # Running the Behat
Just run:
```
docker exec akeneo_pim_app bin/behat
```
Sit back and enjoy.

*If you wish to see what your tests are doing, you may connect via VNC to `akeneo.pim:5901`. The password is `secret`*

### # Known Issues
1. In case you get an exception:
```BASH
request.CRITICAL: Uncaught PHP Exception Twig_Error_Runtime: "An exception has been thrown during the rendering of a template ("Error during translations file generation for locale "en_US"")." at /var/www/pim/src/Oro/Bundle/TranslationBundle/Resources/views/requirejs.config.js.twig line 4 {"exception":"[object] (Twig_Error_Runtime(code: 0): An exception has been thrown during the rendering of a template (\"Error during translations file generation for locale \"en_US\"\"). at /var/www/pim/src/Oro/Bundle/TranslationBundle/Resources/views/requirejs.config.js.twig:4, RuntimeException(code: 0): Error during translations file generation for locale \"en_US\" at /var/www/pim/src/Pim/Bundle/EnrichBundle/Twig/TranslationsExtension.php:70)"} []
```

You can attempt to recompile the locale assests:
```
docker exec  <docker-ID> php /var/www/pim/app/console  --env=dev oro:translation:dump en_US
```
2. If you get errors while clearing cache, 
```
[Symfony\Component\Filesystem\Exception\IOException]                                                                                                                                                                                                                
Failed to remove directory "/var/www/pim/app/cache/de~/doctrine": Symfony\Component\DependencyInjection\Definition::setFactoryClass(Doctrine\ORM\EntityManager) is deprecated since version 2.6 and will be removed in 3.0. Use Definition::setFactory() instead.. 
```
you could

```
docker exec akeneo_pim_app rm -rf /var/www/pim/app/cache/*
```
### # Using XDebug (Dev Optional)
This Docker service comes with a pre-compiled xDebug, which is not enabled by default.
To enable this extension, edit `conf/php/xdebug.ini` and modify as desired. Restart your service and xDebug should be available. But remember to **avoid using xDebug** for production environments.
There is also a handy xdebug proxy server in the `docker-composoe`; you may uncomment this and use as desired.
## # Some other useful resources
To further understand the rationale behind mounting the App (PHP-FPM) instance differently please refer to comments from:
- http://stackoverflow.com/a/36908278
- https://github.com/docker/machine/issues/3234#issuecomment-202596213

- https://gist.github.com/dschep/8f617de28157f8d35e69 \[Current hack\]

## Contributors

* Yinka Asonibare - [yinka](https://github.com/ashon-ikon)
* Marcelo Milhomem - [milhomem](https://github.com/milhomem)

## License

This Docker setup is released under the MIT License. See the license file for more details.
