# docker-nginx-akeneo
Akeneo PIM docker using Nginx

## Overview
This is a simple Akeneo PIM Docker image running PHP7, Nginx with PHP-FPM.

This borrows largely from two worlds [Akeneo PIM](https://docs.akeneo.com/1.6/developer_guide/installation/system_requirements/system_install_ubuntu_1604.html) and [nginx-php-fpm](https://github.com/ngineered/nginx-php-fpm). Pull requests are encouraged.

First checkout Akeneo PIM repository
```
git clone https://github.com/akeneo/pim-community-standard.git preferred-directory
```

## # Running Service Clusters
It's easy as:
1. Clone this repository
```BASH
git clone https://github.com/theiconic/docker-nginx-akeneo.git
cd docker-nginx-akeneo
```
2. Set your environment parameters
```
$ > cp .env.dist -v .env
```
Or just run ...
```
$ > ./install.sh # It will copy the .env [if needed] and die with the following message

Please set your environment values in '.env' file 
and try again. Thank you.

```
Edit your .env file as required
```
# Update the .env with your custom environment variables
$ > vim .env # Or whatever
```
**Sample .env file**
```
# .env
PIM_PROVISION=
MYSQL_ROOT_PASSWORD=043h
SOURCE_PATH=/home/waldorf/Workspace/Projects/pim/
# Your docker machine name if using one
MACHINE_NAME=my-machine
# You can get this from running "id -u"
USER_ID=1000:1500

# PIM configs
PIM_DB_HOST=mysql
PIM_DB_PORT=3306
PIM_DB_NAME=pim_db
PIM_DB_USER=pim_user
PIM_DB_PASSWORD=

# Behat stuff (Optional)
PIM_BEHAT_DB_HOST=mysql
PIM_BEHAT_DB_PORT=3306
PIM_BEHAT_DB_NAME=
PIM_BEHAT_DB_USER=
PIM_BEHAT_DB_PASSWORD=
```

3. Install the project. This could take up to half an hour depending on your connection. **TODO.** improve this. Possibly due to slow composer install
```
$ > ./install.sh

```
4. Subsequent runs cab be done just by running:
```
$ > ./start.sh

$ > ./stop.sh # To stop all services
```

***That's it!*** Remember to add the IP to your `/etc/hosts` for convenience.
```
For convience, you could add your docker-machine to /etc/hosts.
eg. 
    echo "$(docker-machine ip my-machine)	akeneo.pim akeneo.pim.local akeneo.db akeneo.db.local akeneo.behat.local akeneo.behat.local  >> /etc/hosts
    
    Or 127.0.0.1 if not using docker machine
```

#### Setting environment variable
***PIM_PROVISION=1*** is only necessasry for the first run. For subsequent run, this could be removed.


### Known Issues
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
