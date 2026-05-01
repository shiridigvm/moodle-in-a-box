#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_NAME="moodle_backup_${TIMESTAMP}"

source "$PROJECT_DIR/.env"

echo "==> Creating backup: ${BACKUP_NAME}"
mkdir -p "$BACKUP_DIR"

echo "==> Dumping database..."
docker compose exec -T db mysqldump \
    -u"${DB_USER}" -p"${DB_PASSWORD}" \
    --single-transaction --quick --lock-tables=false \
    "${DB_NAME}" > "${BACKUP_DIR}/${BACKUP_NAME}_db.sql"
echo "    Database dump: ${BACKUP_DIR}/${BACKUP_NAME}_db.sql"

echo "==> Backing up moodledata..."
docker compose exec -T moodle tar czf - -C /var/www moodledata \
    > "${BACKUP_DIR}/${BACKUP_NAME}_data.tar.gz"
echo "    Data archive: ${BACKUP_DIR}/${BACKUP_NAME}_data.tar.gz"

echo "==> Backing up theme..."
tar czf "${BACKUP_DIR}/${BACKUP_NAME}_theme.tar.gz" -C "$PROJECT_DIR" theme/
echo "    Theme archive: ${BACKUP_DIR}/${BACKUP_NAME}_theme.tar.gz"

echo "==> Creating manifest..."
cat > "${BACKUP_DIR}/${BACKUP_NAME}_manifest.json" <<EOF
{
    "timestamp": "${TIMESTAMP}",
    "moodle_version": "$(docker compose exec -T moodle php -r "require('/var/www/html/version.php'); echo \$release;" 2>/dev/null || echo 'unknown')",
    "database": "${BACKUP_NAME}_db.sql",
    "data": "${BACKUP_NAME}_data.tar.gz",
    "theme": "${BACKUP_NAME}_theme.tar.gz"
}
EOF

TOTAL_SIZE=$(du -sh "${BACKUP_DIR}/${BACKUP_NAME}"* | tail -1 | cut -f1)
echo
echo "==> Backup complete!"
echo "    Location: ${BACKUP_DIR}/"
echo "    Files:"
ls -lh "${BACKUP_DIR}/${BACKUP_NAME}"*

OLD_BACKUPS=$(find "$BACKUP_DIR" -name "moodle_backup_*_manifest.json" -mtime +30 | wc -l | tr -d ' ')
if [ "$OLD_BACKUPS" -gt "0" ]; then
    echo
    echo "    NOTE: ${OLD_BACKUPS} backups are older than 30 days."
    echo "    Run: find ${BACKUP_DIR} -name 'moodle_backup_*' -mtime +30 -delete"
fi
