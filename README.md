# Moodle-in-a-Box

Production-ready, Dockerized Moodle deployment with a custom corporate training theme, automated CI/CD, backup/restore tooling, and a documented major-version upgrade path.

Built as **TechCorp Academy** — a realistic corporate learning platform that demonstrates implementation, customization, operations, and upgrades end-to-end.

## What's Inside

| Dimension | What this repo covers |
|-----------|----------------------|
| **Implementation** | Docker Compose stack: Moodle 4.5 + MariaDB 11.4 + Redis 7 + Nginx reverse proxy + cron runner |
| **Customization** | Full Boost child theme ("TechCorp Academy") with branded login, dashboard, navigation, typography |
| **Operations** | One-command setup, backup/restore scripts, maintenance mode, Makefile for all common tasks |
| **Upgrades** | Documented 4.4 → 4.5 major-version upgrade with breaking changes, timeline, rollback procedure |
| **CI/CD** | GitHub Actions: lint, build, smoke test, upgrade-path test, manual production deploy |
| **Documentation** | Deployment guide, theme customization guide, upgrade runbook |

## Architecture

```
                     ┌─────────────────────────────────────────┐
                     │              Docker Host                │
                     │                                         │
  Internet ──────────┤  Nginx :443/:80                         │
                     │    │  (SSL termination, static cache)   │
                     │    ▼                                    │
                     │  Moodle (PHP 8.3 + Apache)              │
                     │    ├── MariaDB 11.4                     │
                     │    ├── Redis 7 (sessions + MUC)         │
                     │    └── Theme: TechCorp Academy          │
                     │                                         │
                     │  Cron (Moodle scheduled tasks, 1m)      │
                     │  Certbot (auto SSL renewal)             │
                     └─────────────────────────────────────────┘
```

## Quick Start

```bash
git clone https://github.com/YOUR_USER/moodle-in-a-box.git
cd moodle-in-a-box
make setup
```

This will:
1. Generate `.env` with secure random passwords
2. Build the Moodle Docker image
3. Start all services
4. Install Moodle with the TechCorp theme
5. Print your admin credentials

Moodle will be available at **http://localhost** after 2-5 minutes.

## Commands

```bash
make help           # Show all available commands
make up             # Start services
make down           # Stop services (data preserved)
make logs           # Follow logs
make shell          # Shell into Moodle container
make backup         # Full backup (DB + files + theme)
make restore TS=... # Restore from backup
make upgrade BRANCH=MOODLE_405_STABLE  # Major-version upgrade
make test           # Run smoke tests
make deploy         # Deploy to production with SSL
make ssl-setup DOMAIN=... EMAIL=...    # Obtain SSL certificate
```

## Project Structure

```
.
├── .github/workflows/
│   ├── ci.yml                  # Lint → Build → Smoke test → Upgrade test
│   └── deploy.yml              # Manual production deployment
├── config/
│   ├── moodle-config.php       # Moodle configuration (env-driven)
│   └── php.ini                 # PHP tuning for Moodle
├── docker/
│   ├── moodle/
│   │   ├── Dockerfile          # Moodle image (PHP 8.3, extensions, source)
│   │   └── entrypoint.sh       # Auto-install, upgrade, cache config
│   ├── nginx/
│   │   ├── nginx.conf          # Dev reverse proxy
│   │   └── nginx-prod.conf     # Production with SSL + security headers
│   └── cron/
│       └── moodle-cron.sh      # Cron runner (every 60s)
├── theme/techcorp/
│   ├── config.php              # Theme config and layouts
│   ├── version.php             # Version and dependencies
│   ├── lib.php                 # SCSS callbacks and brand colors
│   ├── scss/techcorp.scss      # Full theme stylesheet
│   ├── templates/              # Mustache templates (login, columns2)
│   └── lang/en/                # Language strings
├── scripts/
│   ├── setup.sh                # First-time setup
│   ├── backup.sh               # Backup DB + moodledata + theme
│   ├── restore.sh              # Restore from backup
│   └── upgrade.sh              # Major-version upgrade orchestration
├── tests/
│   └── smoke-test.sh           # HTTP endpoint smoke tests
├── docs/
│   ├── DEPLOYMENT.md           # Full deployment guide
│   ├── UPGRADE-4.4-to-4.5.md   # Major-version upgrade runbook
│   └── THEME-CUSTOMIZATION.md  # Theme development guide
├── docker-compose.yml          # Development stack
├── docker-compose.prod.yml     # Production overrides (SSL, certbot, logging)
├── Makefile                    # Command interface
├── .env.example                # Environment template
└── README.md
```

## TechCorp Academy Theme

A Boost child theme designed for corporate training environments:

- **Brand identity:** Navy/blue gradient navbar, Inter font family, professional card styling
- **Custom login page:** Centered card layout with branded header, no navigation chrome
- **Dashboard:** Clean block styling with subtle shadows and branded section headers
- **Progress indicators:** Gradient progress bars matching brand palette
- **Footer:** Branded footer with company tagline
- **Responsive:** Full mobile support via Boost's responsive framework

See [docs/THEME-CUSTOMIZATION.md](docs/THEME-CUSTOMIZATION.md) for customization instructions.

## CI/CD Pipeline

The GitHub Actions pipeline runs on every push and PR:

1. **Lint** — PHP syntax check on theme files, Docker Compose validation, ShellCheck on scripts
2. **Build & Smoke Test** — Builds the full stack, waits for Moodle to install, runs HTTP smoke tests
3. **Upgrade Path Test** — Installs Moodle 4.4, upgrades to 4.5, verifies the upgrade succeeds and smoke tests pass

Production deploys are triggered manually via `workflow_dispatch` with environment selection (staging/production).

## Upgrade Documentation

The [Moodle 4.4 → 4.5 upgrade runbook](docs/UPGRADE-4.4-to-4.5.md) documents:

- Pre-upgrade checklist and compatibility matrix
- Five breaking changes encountered and their fixes
- Step-by-step upgrade procedure with exact commands
- Post-upgrade verification checklist
- Rollback procedure (tested on staging)
- Timeline: **31 minutes total downtime**
- Lessons learned for future upgrades

## Production Deployment

```bash
# On your server
cp .env.example .env
# Edit .env: set DOMAIN, MOODLE_WWWROOT, strong passwords

# Get SSL certificate
make ssl-setup DOMAIN=learn.yourcompany.com EMAIL=admin@yourcompany.com

# Deploy with production config
make deploy

# Verify
make test
```

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for the complete guide, including environment variables, performance tuning, and monitoring.

## Requirements

- Docker Engine 24+ with Compose v2
- 4 GB RAM minimum (8 GB recommended)
- 20 GB disk space

## License

This project scaffolding is MIT licensed. Moodle itself is GPL v3 — see [moodle.org](https://moodle.org) for details.
