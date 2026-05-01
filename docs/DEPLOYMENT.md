# Deployment Guide

## Architecture Overview

```
Internet → Nginx (SSL termination, caching)
               → Moodle (PHP 8.3 + Apache)
                    → MariaDB 11.4
                    → Redis 7 (sessions + cache)
           → Certbot (auto-renewal)
           → Cron (scheduled tasks)
```

All services run as Docker containers orchestrated by Docker Compose.

## Requirements

- Docker Engine 24+ and Docker Compose v2
- 2+ CPU cores, 4 GB RAM minimum (8 GB recommended)
- 20 GB disk space (more for file-heavy courses)
- A domain name pointing to your server's IP
- Ports 80 and 443 open

## Quick Start (Local Development)

```bash
git clone https://github.com/YOUR_USER/moodle-in-a-box.git
cd moodle-in-a-box
make setup
```

This generates a `.env` with random passwords, builds all images, and starts the stack. Moodle will be available at `http://localhost` after 2-5 minutes.

## Production Deployment

### 1. Server Setup

```bash
# On your server
git clone https://github.com/YOUR_USER/moodle-in-a-box.git /opt/moodle
cd /opt/moodle

# Create and configure .env
cp .env.example .env
# Edit .env with production values:
#   DOMAIN=learn.yourcompany.com
#   MOODLE_WWWROOT=https://learn.yourcompany.com
#   Strong, unique passwords for DB_PASSWORD, DB_ROOT_PASSWORD, MOODLE_ADMIN_PASSWORD
```

### 2. SSL Certificate

```bash
# Start nginx temporarily for ACME challenge
docker compose up -d nginx

# Obtain certificate
make ssl-setup DOMAIN=learn.yourcompany.com EMAIL=admin@yourcompany.com

# Deploy with production config (includes SSL + certbot auto-renewal)
make deploy
```

### 3. Verify

```bash
make test
make status
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DB_NAME` | No | `moodle` | Database name |
| `DB_USER` | No | `moodle` | Database user |
| `DB_PASSWORD` | **Yes** | — | Database password |
| `DB_ROOT_PASSWORD` | **Yes** | — | MariaDB root password |
| `MOODLE_WWWROOT` | No | `http://localhost` | Full site URL |
| `MOODLE_ADMIN_USER` | No | `admin` | Admin username |
| `MOODLE_ADMIN_PASSWORD` | **Yes** | — | Admin password |
| `MOODLE_ADMIN_EMAIL` | No | `admin@example.com` | Admin email |
| `MOODLE_FULLNAME` | No | `TechCorp Academy` | Site full name |
| `MOODLE_SHORTNAME` | No | `TechCorp` | Site short name |
| `DOMAIN` | Prod only | — | Domain for SSL |
| `HTTP_PORT` | No | `80` | Host HTTP port |
| `HTTPS_PORT` | No | `443` | Host HTTPS port |

## Backup & Restore

```bash
# Create backup (DB + files + theme)
make backup

# List available backups
ls backups/*_manifest.json

# Restore
make restore TS=20250428_143000
```

Backups are stored in `./backups/` and include a JSON manifest with the Moodle version at time of backup.

## Monitoring

```bash
# Container status
make status

# Live logs
make logs

# Moodle-specific logs
make logs-moodle

# Redis stats
docker compose exec redis redis-cli INFO stats
```

## Updating

For minor updates within the same Moodle branch:

```bash
docker compose build --no-cache moodle
docker compose up -d moodle
docker compose exec moodle php /var/www/html/admin/cli/upgrade.php --non-interactive
docker compose exec moodle php /var/www/html/admin/cli/purge_caches.php
```

For major version upgrades, see [UPGRADE-4.4-to-4.5.md](UPGRADE-4.4-to-4.5.md).

## Performance Tuning

The default configuration handles 50-100 concurrent users. For larger deployments:

- **MariaDB:** Increase `innodb-buffer-pool-size` in `docker-compose.yml` (set to 70% of available RAM dedicated to DB)
- **PHP OPcache:** Increase `opcache.memory_consumption` in `config/php.ini`
- **Redis:** Increase `maxmemory` in the redis service command
- **Nginx:** Increase `worker_connections` and add `proxy_cache` for static assets
