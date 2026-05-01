#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================"
echo "  TechCorp Academy - Moodle-in-a-Box Setup"
echo "============================================"
echo

if [ ! -f "$PROJECT_DIR/.env" ]; then
    echo "==> Creating .env from .env.example..."
    cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"

    DB_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
    DB_ROOT_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
    ADMIN_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 20)

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/CHANGE_ME_DB_PASSWORD/$DB_PASSWORD/" "$PROJECT_DIR/.env"
        sed -i '' "s/CHANGE_ME_ROOT_PASSWORD/$DB_ROOT_PASSWORD/" "$PROJECT_DIR/.env"
        sed -i '' "s/CHANGE_ME_ADMIN_PASSWORD/$ADMIN_PASSWORD/" "$PROJECT_DIR/.env"
    else
        sed -i "s/CHANGE_ME_DB_PASSWORD/$DB_PASSWORD/" "$PROJECT_DIR/.env"
        sed -i "s/CHANGE_ME_ROOT_PASSWORD/$DB_ROOT_PASSWORD/" "$PROJECT_DIR/.env"
        sed -i "s/CHANGE_ME_ADMIN_PASSWORD/$ADMIN_PASSWORD/" "$PROJECT_DIR/.env"
    fi

    echo "    Generated secure passwords in .env"
    echo "    Admin password: $ADMIN_PASSWORD"
    echo "    (Save this — it won't be shown again)"
    echo
fi

echo "==> Creating SSL directory for nginx..."
mkdir -p "$PROJECT_DIR/docker/nginx/ssl"

echo "==> Building and starting containers..."
cd "$PROJECT_DIR"
docker compose build --no-cache
docker compose up -d

echo
echo "==> Waiting for Moodle to initialize (this takes 2-5 minutes)..."
echo "    You can watch progress with: docker compose logs -f moodle"
echo

timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker compose exec -T moodle curl -sf http://localhost:80/login/index.php > /dev/null 2>&1; then
        echo
        echo "============================================"
        echo "  TechCorp Academy is ready!"
        echo "============================================"
        echo
        echo "  URL:      http://localhost"
        echo "  Admin:    admin"
        echo "  Password: (see .env or output above)"
        echo
        echo "  Useful commands:"
        echo "    make logs     - View logs"
        echo "    make stop     - Stop services"
        echo "    make backup   - Create backup"
        echo "    make shell    - Open Moodle shell"
        echo
        exit 0
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    printf "."
done

echo
echo "WARNING: Moodle did not become ready within ${timeout}s."
echo "Check logs with: docker compose logs moodle"
exit 1
