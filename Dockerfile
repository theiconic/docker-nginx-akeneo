
FROM richarvey/nginx-php-fpm:php7
# Maintainer
MAINTAINER Yinka Asonibare <yinka.asonibare@theiconic.com.au>

RUN  sed -i -e 's/dl-cdn/dl-4/' /etc/apk/repositories && \
	apk --update --no-cache add \
	autoconf \
	automake \
	build-base \
	py-pexpect \
	gosu@testing \
	php7-dev \
	php7-xml \
	php7-xmlreader \
	php7-zip

RUN cd /usr/bin && \
	ln -svf php-config7 php-config && \
	ln -svf phpize7 phpize


# Install MongoDb
RUN  CWDir=$(pwd) && cd /tmp/ && \
	git clone https://github.com/mongodb/mongo-php-driver.git && \
	cd mongo-php-driver &&\
	git submodule sync && git submodule update --init && \
	phpize && \
	./configure && \
	make -s all -j 5 && \
	make install && cd ${CWDir} && rm -rf /tmp/mongo-php-driver

# Install APCu
RUN CWDir=$(pwd) && cd /tmp/ && \
    git clone https://github.com/krakjoe/apcu && \
  	cd apcu && \
  	phpize && \
  	./configure --with-php-config=`which php-config7 | head -1` && \
  	make -s -j 5 && \
  	export TEST_PHP_ARGS='-n' && \
  	make install && cd ${CWDir} && rm -rf /tmp/apcu

RUN php_ini_path=$(realpath $(php7 --ini | grep -e ".*\.ini files in" | cut -d':' -f2)) && \
	printf  "extension=apcu.so\n \
 		apc.enabled=1\n \
 		apc.shm_size=32M\n \
 		apc.ttl=7200\n \
 		apc.enable_cli=1" \
    	>> "${php_ini_path}/20-acpu.ini";


# Enable the extensions
RUN php_ini_path=$(realpath $(php7 --ini | grep -e ".*\.ini files in" | cut -d':' -f2)) && \
    for ext in mongodb ; \
    	do printf  "extension=${ext}.so\n" \
    	>> "${php_ini_path}/20-${ext}.ini"; \
    done

ADD build/scripts/start.sh /start.sh

# Ensure it's executable
RUN chmod gu+x /start.sh
