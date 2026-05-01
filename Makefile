.PHONY: help setup up down stop restart logs shell db-shell backup restore upgrade \
       build clean status ssl-setup deploy test lint

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## First-time setup: generate config, build, and start
	@chmod +x scripts/*.sh docker/cron/moodle-cron.sh
	@bash scripts/setup.sh

up: ## Start all services
	docker compose up -d

down: ## Stop and remove all containers (preserves data)
	docker compose down

stop: ## Stop all services
	docker compose stop

restart: ## Restart all services
	docker compose restart

logs: ## Follow all container logs
	docker compose logs -f

logs-moodle: ## Follow Moodle application logs
	docker compose logs -f moodle

build: ## Rebuild all images
	docker compose build --no-cache

status: ## Show container status
	docker compose ps

shell: ## Open a shell in the Moodle container
	docker compose exec moodle bash

db-shell: ## Open a MySQL shell
	docker compose exec db mysql -u$${DB_USER:-moodle} -p$${DB_PASSWORD} $${DB_NAME:-moodle}

backup: ## Create a full backup
	@bash scripts/backup.sh

restore: ## Restore from backup (usage: make restore TS=20250428_143000)
	@bash scripts/restore.sh $(TS)

upgrade: ## Upgrade Moodle (usage: make upgrade BRANCH=MOODLE_405_STABLE)
	@bash scripts/upgrade.sh $(BRANCH)

ssl-setup: ## Obtain Let's Encrypt certificate (usage: make ssl-setup DOMAIN=learn.example.com EMAIL=admin@example.com)
	docker compose run --rm certbot certonly \
		--webroot -w /var/www/certbot \
		-d $(DOMAIN) --email $(EMAIL) --agree-tos --non-interactive

deploy: ## Deploy to production with SSL
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

test: ## Run smoke tests
	@bash tests/smoke-test.sh

lint: ## Lint theme PHP files
	@find theme/ -name '*.php' -exec php -l {} \; 2>&1 | grep -v "No syntax errors"

clean: ## Remove all containers, volumes, and data (DESTRUCTIVE)
	@echo "WARNING: This will delete ALL Moodle data!"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] && \
		docker compose down -v --remove-orphans || echo "Aborted."
