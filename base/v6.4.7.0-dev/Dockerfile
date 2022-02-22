FROM php:7.4-apache
LABEL maintainer="Rok Popov Ledinski <rok.popov.ledinski90@gmail.com>"

ENV USE_SSL=0 \
SHOPWARE_HOST="will_be_replaced" \
DB_USER=root \
DB_PASSWORD=shopware6 \
DB_HOST=mariadb \
DB_NAME=shopware6 \
DB_PORT=3306 \
APP_ENV=dev \
XDEBUG_CLIENT_HOST=localhost \
XDEBUG_CLIENT_PORT=9003 \
XDEBUG_IDEKEY="PHPSTORM" \
DEBUG_USERNAME=dev \
DEBUG_USERPASS=dev 

RUN apt-get update \
	&& apt-get install -y \
	default-mysql-client \
	libicu-dev \
	libzip-dev \
	libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \ 
	unzip \
	wget \
	nodejs \
	npm \
	cron \
	openssh-server \
	sudo

RUN docker-php-ext-configure gd --with-freetype --with-jpeg 
RUN docker-php-ext-install -j$(nproc) gd intl pdo_mysql zip

RUN pecl install xdebug-3.1.3 \
    && docker-php-ext-enable xdebug

ADD https://github.com/shopware/development/archive/refs/tags/v6.4.7.0.tar.gz /tmp/shopware6_development.tar.gz
ADD https://github.com/shopware/platform/archive/refs/tags/v6.4.7.0.tar.gz /tmp/shopware6_platform.tar.gz

COPY config/install_shopware6.sh /tmp/install_shopware6.sh
COPY config/php.ini /usr/local/etc/php/
COPY config/enable_debugging.sh /tmp/enable_debugging.sh

RUN if [ -x "$(command -v apache2-foreground)" ]; then a2enmod rewrite headers; fi

RUN chmod +x /tmp/install_shopware6.sh /tmp/enable_debugging.sh

RUN useradd -rm -d /home/$DEBUG_USERNAME -s /bin/bash -g root -G sudo -u 1000 $DEBUG_USERNAME
RUN echo "$DEBUG_USERNAME:$DEBUG_USERPASS" | chpasswd

CMD ["bash", "/tmp/install_shopware6.sh"] 

