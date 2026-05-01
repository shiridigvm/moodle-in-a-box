#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_BRANCH="${1:-}"
if [ -z "$TARGET_BRANCH" ]; then
    echo "Usage: $0 <moodle_branch>"
    echo "Example: $0 MOODLE_405_STABLE"
    echo
    echo "This script performs a major-version Moodle upgrade:"
    echo "  1. Creates a full backup"
    echo "  2. Enables maintenance mode"
    echo "  3. Rebuilds the Moodle container with the new branch"
    echo "  4. Runs the database upgrade"
    echo "  5. Verifies and disables maintenance mode"
    exit 1
fi

echo "============================================"
echo "  Moodle Upgrade to ${TARGET_BRANCH}"
echo "============================================"
echo

echo "==> Step 1/6: Pre-upgrade backup..."
bash "$SCRIPT_DIR/backup.sh"
echo

echo "==> Step 2/6: Enabling maintenance mode..."
docker compose exec -T moodle php /var/www/html/admin/cli/maintenance.php --enable
echo "    Maintenance mode enabled."
echo

echo "==> Step 3/6: Recording current version..."
CURRENT_VERSION=$(docker compose exec -T moodle php -r "require('/var/www/html/version.php'); echo \$release;" 2>/dev/null || echo 'unknown')
echo "    Current Moodle version: ${CURRENT_VERSION}"
echo

echo "==> Step 4/6: Rebuilding with ${TARGET_BRANCH}..."
docker compose build --no-cache --build-arg MOODLE_BRANCH="${TARGET_BRANCH}" moodle
echo "    Image rebuilt."
echo

echo "==> Step 5/6: Stopping and restarting services..."
docker compose stop moodle cron
docker compose up -d moodle

echo "    Waiting for container to be ready..."
sleep 10

echo "    Running database upgrade..."
docker compose exec -T moodle php /var/www/html/admin/cli/upgrade.php --non-interactive
echo "    Database upgrade complete."
echo

echo "==> Step 6/6: Post-upgrade verification..."
docker compose exec -T moodle php /var/www/html/admin/cli/purge_caches.php

NEW_VERSION=$(docker compose exec -T moodle php -r "require('/var/www/html/version.php'); echo \$release;" 2>/dev/null || echo 'unknown')
echo "    New Moodle version: ${NEW_VERSION}"

docker compose up -d cron

docker compose exec -T moodle php /var/www/html/admin/cli/maintenance.php --disable
echo "    Maintenance mode disabled."

echo
echo "============================================"
echo "  Upgrade Complete!"
echo "============================================"
echo "  From: ${CURRENT_VERSION}"
echo "  To:   ${NEW_VERSION}"
echo
echo "  Post-upgrade checklist:"
echo "  [ ] Verify login works"
echo "  [ ] Check course content renders correctly"
echo "  [ ] Test TechCorp theme compatibility"
echo "  [ ] Review admin notifications at /admin/index.php"
echo "  [ ] Test plugin compatibility"
echo "  [ ] Monitor error logs: make logs"
echo
echo "  If issues arise, restore from backup:"
echo "  bash scripts/restore.sh <timestamp>"
echo
