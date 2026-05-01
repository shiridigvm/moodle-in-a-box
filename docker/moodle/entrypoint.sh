#!/bin/bash
set -euo pipefail

echo "==> Waiting for database..."
until php -r "new mysqli('${MOODLE_DATABASE_HOST}', '${MOODLE_DATABASE_USER}', '${MOODLE_DATABASE_PASSWORD}', '${MOODLE_DATABASE_NAME}');" 2>/dev/null; do
    sleep 2
done
echo "==> Database is ready."

if ! php /var/www/html/admin/cli/isinstalled.php 2>/dev/null; then
    echo "==> Installing Moodle..."
    php /var/www/html/admin/cli/install_database.php \
        --agree-license \
        --fullname="${MOODLE_FULLNAME:-TechCorp Academy}" \
        --shortname="${MOODLE_SHORTNAME:-TechCorp}" \
        --adminuser="${MOODLE_ADMIN_USER:-admin}" \
        --adminpass="${MOODLE_ADMIN_PASSWORD}" \
        --adminemail="${MOODLE_ADMIN_EMAIL:-admin@example.com}"
    echo "==> Moodle installed successfully."

    echo "==> Configuring Redis session cache..."
    php /var/www/html/admin/cli/cfg.php --name=session_handler_class --set='\core\session\redis'
    php /var/www/html/admin/cli/cfg.php --name=session_redis_host --set="${REDIS_HOST:-redis}"

    echo "==> Enabling TechCorp theme..."
    php /var/www/html/admin/cli/cfg.php --name=theme --set=techcorp || true
else
    echo "==> Moodle already installed, running upgrade check..."
    php /var/www/html/admin/cli/upgrade.php --non-interactive || true
fi

echo "==> Purging caches..."
php /var/www/html/admin/cli/purge_caches.php

chown -R www-data:www-data /var/www/moodledata

exec "$@"
