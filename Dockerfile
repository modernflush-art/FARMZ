FROM php:8.1-apache

RUN apt-get update && \
    apt-get install -y git unzip zip libzip-dev && \
    docker-php-ext-install pdo pdo_mysql pdo_pgsql

RUN a2enmod rewrite

# Configure Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

WORKDIR /var/www/html

# Copy project sources
COPY . /var/www/html

# Set document root for Drupal
ENV APACHE_DOCUMENT_ROOT=/var/www/html/web

# Update Apache configuration
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Permissions
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 755 /var/www/html

EXPOSE 80
