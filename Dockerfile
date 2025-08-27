FROM php:8.1-apache

RUN apt-get update && \
    apt-get install -y git unzip zip libzip-dev && \
    docker-php-ext-install pdo pdo_mysql

RUN a2enmod rewrite

WORKDIR /var/www/html

# Copy project sources (assumes docker-compose will mount code)
COPY . /var/www/html

# Permissions
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 755 /var/www/html

ENV APACHE_DOCUMENT_ROOT=/var/www/html/web

EXPOSE 80 8080
