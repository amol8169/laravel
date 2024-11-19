# Base image for building the application
FROM php:8.3-apache AS base
WORKDIR /var/www/html

# Install necessary system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    git \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libzip-dev \
    libonig-dev \
    libicu-dev \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install \
    pdo_mysql \
    bcmath \
    zip \
    intl \
    gd \
    opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache Rewrite and other required modules
RUN a2enmod rewrite headers deflate

# Copy Composer from official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Production stage for minimal dependencies
FROM base AS production

# Copy application code
COPY . ./

# Install production dependencies only
RUN composer install --no-dev

# Set permissions for Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Copy Apache configuration
COPY .docker/default.conf /etc/apache2/sites-available/000-default.conf

# Expose the default Apache port
EXPOSE 80

# Start Apache in the foreground
CMD ["apache2-foreground"]

# Development stage with dev dependencies
FROM base AS development

# Copy application code
COPY . ./

# Install all dependencies including dev
RUN composer install

# Set permissions for Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache
