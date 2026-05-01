#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <backup_timestamp>"
    echo "Example: $0 20250428_143000"
    echo
    echo "Available backups:"
    ls "${PROJECT_DIR}/backups/"*_manifest.json 2>/dev/null | sed 's/.*moodle_backup_/  /;s/_manifest.json//' || echo "  (none found)"
    exit 1
fi

TIMESTAMP="$1"
BACKUP_DIR="${PROJECT_DIR}/backups"
BACKUP_PREFIX="moodle_backup_${TIMESTAMP}"

source "$PROJECT_DIR/.env"

for f in "${BACKUP_DIR}/${BACKUP_PREFIX}_db.sql" \
         "${BACKUP_DIR}/${BACKUP_PREFIX}_data.tar.gz" \
         "${BACKUP_DIR}/${BACKUP_PREFIX}_manifest.json"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: Missing backup file: $f"
        exit 1
    fi
done

echo "==> Restoring from backup: ${TIMESTAMP}"
echo
cat "${BACKUP_DIR}/${BACKUP_PREFIX}_manifest.json"
echo
read -p "Continue? (y/N) " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 0
fi

echo "==> Enabling maintenance mode..."
docker compose exec -T moodle php /var/www/html/admin/cli/maintenance.php --enable || true

echo "==> Restoring database..."
docker compose exec -T db mysql \
    -u"${DB_USER}" -p"${DB_PASSWORD}" \
    -e "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
docker compose exec -T db mysql \
    -u"${DB_USER}" -p"${DB_PASSWORD}" \
    "${DB_NAME}" < "${BACKUP_DIR}/${BACKUP_PREFIX}_db.sql"
echo "    Database restored."

echo "==> Restoring moodledata..."
docker compose exec -T moodle rm -rf /var/www/moodledata/*
cat "${BACKUP_DIR}/${BACKUP_PREFIX}_data.tar.gz" | \
    docker compose exec -T moodle tar xzf - -C /var/www
docker compose exec -T moodle chown -R www-data:www-data /var/www/moodledata
echo "    Data files restored."

if [ -f "${BACKUP_DIR}/${BACKUP_PREFIX}_theme.tar.gz" ]; then
    echo "==> Restoring theme..."
    tar xzf "${BACKUP_DIR}/${BACKUP_PREFIX}_theme.tar.gz" -C "$PROJECT_DIR"
    echo "    Theme restored."
fi

echo "==> Purging caches..."
docker compose exec -T moodle php /var/www/html/admin/cli/purge_caches.php

echo "==> Disabling maintenance mode..."
docker compose exec -T moodle php /var/www/html/admin/cli/maintenance.php --disable

echo
echo "==> Restore complete!"
