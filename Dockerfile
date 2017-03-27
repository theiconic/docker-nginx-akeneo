
FROM php:7.1.1-fpm-alpine


LABEL "Maintainer"="THE ICONIC ENGINEERING TEAM <engineering@theiconic.com.au>"

RUN  \
	apk --update --no-cache add \
	autoconf \
	automake \
	build-base \
	bash \
	git \
	freetype-dev \
	icu-dev \
	libjpeg-turbo-dev \
	libmcrypt-dev \
	libpng-dev \
	libxml2-dev \
	jpeg-dev \
	openssl-dev \
	procps \
	python \
	re2c \
	tzdata \
	zlib-dev

RUN apk --update --no-cache add ca-certificates wget && \
  	update-ca-certificates

# Install gd extension
RUN docker-php-ext-configure gd \
	--with-gd \
	--with-freetype-dir=/usr/include/ \
	--with-png-dir=/usr/include/ \
	--with-jpeg-dir=/usr/include/ && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  docker-php-ext-install -j${NPROC} gd

# Install additional extensions
RUN docker-php-ext-install \
	exif \
	intl \
	mcrypt \
	mysqli \
	pdo_mysql \
	posix \
	soap \
	zip

# Compile XDebug extension and make ready for usage if desired
RUN CWDir=$(pwd) && \
    cd /tmp/ && \
    git clone git://github.com/xdebug/xdebug.git && \
    cd xdebug && \
    phpize && \
    ./configure --enable-xdebug && \
    make && \
    cp ./modules/xdebug.so $(php-config --extension-dir)/xdebug.so && \
    cd ${CWDir} && rm -rf /tmp/xdebug
    # Note that this extension will not work without being enabled!!
    # Enabling will be left optional


# Install MongoDb and APCu through PECL
RUN for ext in apcu mongodb-beta; do printf "\n" | pecl install $ext; done

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
