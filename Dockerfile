FROM composer:latest AS builder
WORKDIR /app
COPY composer.* .
RUN composer install --no-ansi --ignore-platform-reqs

# Stage 2: PHP with Apache
FROM php:8.3-apache
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

# Enable Apache Rewrite Module
RUN a2enmod rewrite headers deflate

# Copy application code
COPY . .

# Copy Composer dependencies from the first stage
COPY --from=builder /app/vendor .

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
