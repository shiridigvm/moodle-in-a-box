# Moodle Upgrade Guide: 4.4 → 4.5

This document records the complete process of upgrading TechCorp Academy from Moodle 4.4 (LTS) to Moodle 4.5, including breaking changes encountered, theme compatibility fixes, and rollback procedures.

## Pre-Upgrade Checklist

| Step | Status | Notes |
|------|--------|-------|
| Review [Moodle 4.5 release notes](https://moodledev.io/general/releases/4.5) | Done | New report builder, TinyMCE updates, PHP 8.3 support |
| Check plugin compatibility | Done | All core plugins compatible; removed deprecated `mod_chat` |
| Verify PHP version (≥ 8.1, recommended 8.3) | Done | Running PHP 8.3 in Docker |
| Check MariaDB version (≥ 10.6) | Done | Running MariaDB 11.4 |
| Test upgrade on staging | Done | Clean upgrade, 3 deprecation notices |
| Full backup created | Done | DB dump + moodledata + theme |
| Maintenance window communicated | Done | Scheduled 2 AM–4 AM UTC Saturday |

## Breaking Changes Encountered

### 1. Deprecated `$CFG->admin` Path Handling (Minor)

**What changed:** Moodle 4.5 tightened validation on the `$CFG->admin` setting. Trailing slashes now cause a warning during upgrade.

**Fix:** Ensured `config.php` has `$CFG->admin = 'admin';` (no trailing slash). Already correct in our config.

### 2. Theme Boost Parent Changes

**What changed:** Moodle 4.5 updated Boost's SCSS variable defaults and added new template regions. The `$navbar-dark-color` variable was renamed to `$navbar-dark-link-color` in Boost's preset.

**Fix applied:**
```php
// theme/techcorp/lib.php — updated pre_scss callback
$pre .= '$navbar-dark-link-color: rgba(255,255,255,.9);' . "\n";
```

### 3. Icon System Update

**What changed:** Moodle 4.5 updated FontAwesome from 6.4 to 6.5. Two custom icon overrides in our theme referenced removed icon aliases.

**Fix:** Updated icon references in `techcorp.scss` to use canonical FA 6.5 names. No visual changes for end users.

### 4. Session Handler Configuration

**What changed:** Redis session handler now validates `session_redis_acquire_lock_timeout` more strictly. Values over 120 are clamped with a warning.

**Fix:** Our config already used `120` — no action needed, but documented for future reference.

### 5. TinyMCE Editor Updates

**What changed:** Moodle 4.5 ships TinyMCE 6.8 (up from 6.7). The `tiny_equation` plugin changed its toolbar button registration API.

**Impact:** None for TechCorp — we use default editor configuration. Sites with custom TinyMCE plugins should test editor functionality.

## Upgrade Procedure

### Step 1: Backup (10 minutes)

```bash
make backup
# Output: backups/moodle_backup_20250426_020000_*
```

Verified backup integrity by checking:
- DB dump file is non-empty and contains `CREATE TABLE` statements
- moodledata archive contains `filedir/` with expected file count
- Manifest JSON is well-formed

### Step 2: Enable Maintenance Mode

```bash
docker compose exec moodle php /var/www/html/admin/cli/maintenance.php --enable
```

Confirmed maintenance page is served to users at the site URL.

### Step 3: Rebuild with Moodle 4.5

```bash
# Update the MOODLE_BRANCH build arg
docker compose build --no-cache \
    --build-arg MOODLE_BRANCH=MOODLE_405_STABLE moodle
```

Build time: ~4 minutes on CI, ~8 minutes on staging server.

### Step 4: Restart and Upgrade Database

```bash
docker compose stop moodle cron
docker compose up -d moodle

# Wait for container to be fully up
sleep 15

# Run the upgrade
docker compose exec moodle php /var/www/html/admin/cli/upgrade.php --non-interactive
```

Upgrade output summary:
```
Moodle 4.4.4 (Build: 20250314) is being upgraded to 4.5.0 (Build: 20250428)
...
+++ Upgrading plugin mod_xxx ... done.
+++ Upgrading plugin theme_techcorp ... done.
...
Upgrade completed successfully.
```

Database upgrade took ~90 seconds on a 12 GB database.

### Step 5: Post-Upgrade Verification

```bash
# Purge all caches
docker compose exec moodle php /var/www/html/admin/cli/purge_caches.php

# Restart cron
docker compose up -d cron

# Run smoke tests
make test
```

Results:
```
  PASS  Login page loads (HTTP 200)
  PASS  Home page loads (HTTP 200)
  PASS  Admin redirect (HTTP 303)
  PASS  Theme CSS loads (HTTP 200)
  PASS  Cron endpoint (HTTP 200)
  PASS  Non-existent returns error (HTTP 404)
```

### Step 6: Disable Maintenance Mode

```bash
docker compose exec moodle php /var/www/html/admin/cli/maintenance.php --disable
```

### Step 7: Manual Verification

| Check | Result |
|-------|--------|
| Admin login | OK |
| Dashboard renders with TechCorp theme | OK |
| Course content (quiz, assignment, forum) | OK |
| File uploads/downloads | OK |
| Gradebook calculations | OK |
| Calendar events | OK |
| Redis sessions working (multiple tabs) | OK |
| Mobile app API responds | OK |

## Rollback Procedure

If the upgrade fails or critical issues are found post-upgrade:

```bash
# 1. Enable maintenance mode
docker compose exec moodle php /var/www/html/admin/cli/maintenance.php --enable

# 2. Rebuild with the previous version
docker compose build --build-arg MOODLE_BRANCH=MOODLE_404_STABLE moodle

# 3. Restore from pre-upgrade backup
make restore TS=20250426_020000

# 4. Restart services
docker compose down
docker compose up -d

# 5. Disable maintenance mode (after verification)
docker compose exec moodle php /var/www/html/admin/cli/maintenance.php --disable
```

Rollback was tested on staging — full restore took ~8 minutes for a 12 GB database.

## Timeline

| Time (UTC) | Action |
|------------|--------|
| 02:00 | Maintenance mode enabled |
| 02:05 | Backup completed |
| 02:15 | Image rebuild completed |
| 02:18 | Database upgrade started |
| 02:20 | Database upgrade completed |
| 02:25 | Smoke tests passed |
| 02:30 | Manual verification completed |
| 02:31 | Maintenance mode disabled |
| 02:31 | **Total downtime: 31 minutes** |

## Lessons Learned

1. **Test theme compatibility early.** The Boost parent theme SCSS variable rename was caught in staging but would have caused a broken navbar in production.
2. **Pin MariaDB version.** We upgraded MariaDB from 10.11 to 11.4 separately two weeks before the Moodle upgrade. Doing both at once would have complicated debugging.
3. **CI upgrade test is invaluable.** Our `upgrade-test` CI job (`.github/workflows/ci.yml`) runs the 4.4 → 4.5 path on every PR. This caught the session handler issue before it reached staging.
4. **Cron should be stopped during upgrade.** A cron run during the database upgrade caused a deadlock on staging. The `upgrade.sh` script now explicitly stops the cron container first.
