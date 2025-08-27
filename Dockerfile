FROM php:8.4-apache

# Set ServerName environment variable
ENV APACHE_SERVER_NAME=localhost

# Install system dependencies and PHP extensions required for Drupal/FarmOS
RUN apt-get update && \
    apt-get install -y \
    git \
    unzip \
    zip \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libonig-dev \
    libgd-dev \
    libwebp-dev \
    libicu-dev \
    libpq-dev \
    netcat-traditional \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    gd \
    mbstring \
    xml \
    intl \
    zip \
    opcache \
    && docker-php-ext-enable opcache

# Configure Apache ServerName globally before enabling modules
RUN echo "ServerName ${APACHE_SERVER_NAME}" >> /etc/apache2/apache2.conf

RUN a2enmod rewrite

# Configure Apache - Set ServerName in virtual host
RUN echo '<VirtualHost *:80>\n    ServerName localhost\n    DocumentRoot /var/www/html/web\n    <Directory /var/www/html/web>\n        AllowOverride All\n        Require all granted\n    </Directory>\n</VirtualHost>' > /etc/apache2/sites-available/000-default.conf && \
    a2ensite 000-default.conf

WORKDIR /var/www/html

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy composer files first for better caching
COPY composer.json composer.lock ./

# Install Composer dependencies
RUN composer install --no-dev --optimize-autoloader && \
    composer drupal:scaffold

# Copy project sources
COPY . /var/www/html

# Set document root for Drupal
ENV APACHE_DOCUMENT_ROOT=/var/www/html/web

# Update Apache configuration
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Create Drupal settings directory and set permissions
RUN mkdir -p /var/www/html/web/sites/default/files && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 775 /var/www/html/web/sites/default/files

# Create a startup script to handle Drupal installation
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
