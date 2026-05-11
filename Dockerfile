FROM php:8.2-apache-bullseye

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libpq-dev \
        libzip-dev \
        unzip \
        wget \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd intl pdo_pgsql pgsql zip \
    && wget -O /tmp/ioncube.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar -xzf /tmp/ioncube.tar.gz -C /tmp \
    && PHP_EXT_DIR="$(php -r 'echo ini_get("extension_dir");')" \
    && cp /tmp/ioncube/ioncube_loader_lin_8.2.so "$PHP_EXT_DIR/" \
    && echo "zend_extension=ioncube_loader_lin_8.2.so" > /usr/local/etc/php/conf.d/00-ioncube.ini \
    && rm -rf /tmp/ioncube /tmp/ioncube.tar.gz /var/lib/apt/lists/*

COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY docker/php/erapor.ini /usr/local/etc/php/conf.d/erapor.ini

RUN a2enmod rewrite headers

WORKDIR /var/www/html
