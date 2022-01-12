FROM php:7.4-apache
LABEL maintainer="Rok Popov Ledinski <me@rpl.com>"

ENV TZ=Europe/Amsterdam \
SHOPWARE_HOST="<will be defined>" \
DB_USER=shopware6 \
DB_PASSWORD=shopware6 \
DB_HOST="<will be defined>" \
DB_NAME=shopware \
APP_URL=http://localhost:8000 \
APP_EN=dev \
SW_LANGUAGE=en_US \
SW_CURRENCY=EUR 

RUN apt-get update \
	&& apt-get install -y \
	default-mysql-client \
	libicu-dev \
	libzip-dev \
	libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \ 
	unzip \
	wget 

RUN docker-php-ext-configure gd --with-freetype --with-jpeg 
RUN docker-php-ext-install -j$(nproc) gd intl pdo_mysql zip

ADD https://github.com/shopware/development/archive/refs/tags/v6.4.7.0.tar.gz shopware6_development.tar.gz
ADD https://github.com/shopware/platform/archive/refs/tags/v6.4.7.0.tar.gz shopware6_platform.tar.gz

COPY config/install_shopware6.sh install_shopware6.sh

RUN chmod +x install_shopware6.sh

