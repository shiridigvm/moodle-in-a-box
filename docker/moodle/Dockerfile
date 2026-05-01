FROM php:8.3-apache

ARG MOODLE_VERSION=405
ARG MOODLE_BRANCH=MOODLE_405_STABLE

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
    libxml2-dev libzip-dev libicu-dev libldap2-dev \
    libpq-dev libmaxminddb-dev libsodium-dev \
    unzip git cron curl ghostscript \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd intl soap zip opcache mysqli pdo_mysql \
        exif sodium ldap \
    && pecl install redis igbinary \
    && docker-php-ext-enable redis igbinary \
    && apt-get purge -y --auto-remove && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite headers expires

WORKDIR /var/www/html

RUN git clone --branch ${MOODLE_BRANCH} --single-branch --depth 1 \
    https://github.com/moodle/moodle.git . \
    && rm -rf .git

RUN mkdir -p /var/www/moodledata \
    && chown -R www-data:www-data /var/www/moodledata /var/www/html

COPY config/moodle-config.php /var/www/html/config.php
COPY docker/moodle/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
