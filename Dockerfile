
FROM php:7.1-fpm-alpine


LABEL "Maintainer"="Yinka Asonibare <yinka.asonibare@theiconic.com.au>"

RUN  \
	apk --update --no-cache add \
	autoconf \
	automake \
	build-base \
	bash \
	git \
	freetype-dev \
	icu-dev \
	libmcrypt-dev \
	libpng-dev \
	openssl-dev \
	python \
	zlib-dev

RUN apk update && \
  	apk add ca-certificates wget && \
  	update-ca-certificates 

ADD "./conf/php/php.ini" /usr/local/etc/php/

# Install additional packages
RUN docker-php-ext-install gd mcrypt intl pdo_mysql zip > /dev/null


# Install MongoDb and APCu through PECL
RUN for ext in apcu mongodb-beta; do printf "\n" | pecl install $ext > /dev/null ; done

# Enable other compiled extensions
RUN docker-php-ext-enable apcu mongodb

# Set APC parameters
RUN php_ini_path=$(realpath $(php --ini | grep -e ".*\.ini files in" | cut -d':' -f2)) && \
	printf  "apc.enabled=1\n \
 		apc.shm_size=32M\n \
 		apc.ttl=7200\n \
 		apc.enable_cli=1\n" \
    	>> "$(ls ${php_ini_path}/*apcu.ini)";

# Install composer
RUN wget \
	https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer \
	-O - -q | php -- --quiet && \
	chmod +x composer.phar && \
	mv composer.phar /usr/local/bin/composer
