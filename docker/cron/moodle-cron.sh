#!/bin/bash
set -euo pipefail

echo "==> Moodle cron runner started"

while true; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') Running Moodle cron..."
    su -s /bin/bash www-data -c "php /var/www/html/admin/cli/cron.php" 2>&1 || true
    sleep 60
done
