# Command Reference

Complete reference for all Frappe Quickstart commands.

## Table of Contents

- [start.sh](#startsh)
- [frappe-cli](#frappe-cli)
- [Bench Commands](#bench-commands)
- [Docker Compose Commands](#docker-compose-commands)
- [Utility Scripts](#utility-scripts)

---

## start.sh

Main entry point for setting up Frappe environment.

### Usage

```bash
./start.sh [OPTIONS]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--preset <name>` | Use preset configuration | `erp` |
| `--port <number>` | Force specific port | Auto-detect from 8080 |
| `--no-browser` | Don't open browser automatically | Open browser |
| `--dev` | Use development compose file | Production mode |
| `--help, -h` | Show help message | - |

### Examples

```bash
# Default ERP setup
./start.sh

# Minimal Frappe only
./start.sh --preset minimal

# Education preset on port 8081
./start.sh --preset education --port 8081

# Development mode without browser
./start.sh --dev --no-browser
```

### Presets

| Preset | Apps Included |
|--------|---------------|
| `minimal` | Frappe only |
| `erp` | Frappe + ERPNext |
| `education` | Frappe + ERPNext + Education + HRMS |
| `ecommerce` | Frappe + ERPNext + Payments |
| `healthcare` | Frappe + ERPNext + Healthcare |

---

## frappe-cli

Interactive command-line interface for managing Frappe environment.

### Usage

```bash
# Interactive mode
./frappe-cli

# Direct command
./frappe-cli <command>
```

### Commands

#### start

Start all Docker services.

```bash
./frappe-cli start
```

**Equivalent:**
```bash
docker compose up -d
```

#### stop

Stop all services.

```bash
./frappe-cli stop
```

**Equivalent:**
```bash
docker compose stop
```

#### restart

Restart all services.

```bash
./frappe-cli restart
```

**Equivalent:**
```bash
docker compose restart
```

#### status

Show detailed status of all services.

```bash
./frappe-cli status
```

**Output:**
- Service names
- Current state (running/stopped/restarting)
- Ports
- Health status

#### logs

Stream logs from services.

```bash
# All services
./frappe-cli logs

# Specific service
./frappe-cli logs
# Then enter service name when prompted
```

**Available services:**
- `backend`
- `frontend`
- `websocket`
- `db`
- `redis-cache`
- `redis-queue`
- `queue-long`
- `queue-short`
- `scheduler`

**Equivalent:**
```bash
# All logs
docker compose logs -f

# Specific service
docker compose logs -f backend
```

**Shortcuts:**
```bash
# Last 100 lines
docker compose logs --tail=100

# With timestamps
docker compose logs -f --timestamps

# Since 1 hour ago
docker compose logs --since 1h
```

#### shell

Open bash shell in backend container.

```bash
./frappe-cli shell
```

**Once inside:**
```bash
# You're now in the backend container
bench --help
bench list-apps
bench --site frontend console

# Exit
exit
```

**Equivalent:**
```bash
docker compose exec backend bash
```

#### bench

Run bench commands directly.

```bash
./frappe-cli bench
# Enter command when prompted
```

**Example:**
```
Enter bench command: list-apps
```

**Equivalent:**
```bash
docker compose exec backend bench list-apps
```

#### apps

View installed apps.

```bash
./frappe-cli apps
```

**Output:**
- List of installed apps
- Branch/version information
- Instructions for adding/removing apps

#### backup

Create full backup of site.

```bash
./frappe-cli backup
```

**What's backed up:**
- Database (compressed SQL dump)
- Public files
- Private files
- Site configuration
- Apps configuration
- Manifest with metadata

**Output location:**
```
backups/YYYY-MM-DD_HH-MM-SS/
```

**Options:**
```bash
# Specify site
./scripts/backup.sh --site frontend

# Custom output directory
./scripts/backup.sh --output /path/to/backup
```

#### restore

Restore from backup.

```bash
./frappe-cli restore
```

**Interactive prompts:**
1. Lists available backups
2. Select backup to restore
3. Confirms action
4. Restores database, files, and configuration

**Options:**
```bash
# Specify backup directory
./scripts/restore.sh --backup-dir backups/2025-01-10_14-30-00

# Specify site
./scripts/restore.sh --backup-dir backups/2025-01-10_14-30-00 --site frontend
```

#### update

Update Frappe Quickstart and rebuild.

```bash
./frappe-cli update
```

**What it does:**
1. Pulls latest changes from git
2. Rebuilds Docker image
3. Restarts services

**Note:** This updates the Frappe Quickstart tooling, not Frappe apps themselves.

#### clean

Remove all data and containers.

```bash
./frappe-cli clean
```

**⚠️ Warning:** This is destructive!

**What it does:**
1. Offers to create backup first
2. Confirms action
3. Stops all services
4. Removes all volumes (database, files, etc.)
5. Removes generated configuration files

**Use when:**
- Starting completely fresh
- Switching major versions
- Troubleshooting persistent issues

#### domain

Setup public domain (labs.selfmade.ninja).

```bash
./frappe-cli domain
```

**Interactive wizard:**
1. Choose subdomain
2. Enter server public IP
3. Confirm port
4. Generates Apache and Nginx configs
5. Provides setup instructions

**See also:** [docs/public-domains.md](public-domains.md)

#### config

Show current configuration.

```bash
./frappe-cli config
```

**Output:**
- Environment variables from `.env`
- Passwords masked for security

#### help

Show help information.

```bash
./frappe-cli help
```

**Output:**
- Command list
- Quick tips
- Documentation links

---

## Bench Commands

Bench is Frappe's command-line utility. Access it through the CLI:

```bash
./frappe-cli shell
bench <command>
```

### Common Bench Commands

#### Site Management

```bash
# List sites
bench list-sites

# Create new site
bench new-site mysite.local

# Delete site
bench drop-site mysite.local

# Backup site
bench --site frontend backup

# Restore site
bench --site frontend restore database.sql.gz
```

#### App Management

```bash
# List installed apps
bench list-apps

# Install app to site
bench --site frontend install-app erpnext

# Uninstall app from site
bench --site frontend uninstall-app custom_app
```

#### Database

```bash
# Run migrations
bench --site frontend migrate

# Console (Python REPL)
bench --site frontend console

# MariaDB console
bench --site frontend mariadb

# Execute SQL
bench --site frontend mariadb -e "SELECT COUNT(*) FROM tabUser"
```

#### Development

```bash
# Clear cache
bench --site frontend clear-cache

# Clear website cache
bench --site frontend clear-website-cache

# Rebuild assets
bench --site frontend build

# Watch and build assets
bench --site frontend watch
```

#### Users and Permissions

```bash
# Add user
bench --site frontend add-user email@example.com

# Set user password
bench --site frontend set-password Administrator

# Add user to role
bench --site frontend add-to-role email@example.com "System Manager"
```

#### Scheduler

```bash
# Enable scheduler
bench --site frontend enable-scheduler

# Disable scheduler
bench --site frontend disable-scheduler

# Trigger event
bench --site frontend trigger-scheduler-event daily
```

#### Jobs and Queue

```bash
# Show pending jobs
bench --site frontend show-pending-jobs

# Purge pending jobs
bench --site frontend purge-jobs --event all

# Doctor (diagnostics)
bench doctor
```

---

## Docker Compose Commands

Direct Docker Compose commands for advanced usage.

### Basic Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Restart services
docker compose restart

# View status
docker compose ps

# View logs
docker compose logs -f
```

### Service-Specific Commands

```bash
# Execute command in service
docker compose exec backend <command>

# Open shell in service
docker compose exec backend bash

# Run one-off command
docker compose run --rm backend bench --help
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect frappe_quickstart_db-data

# Remove volume (⚠️ data loss)
docker volume rm frappe_quickstart_db-data
```

### Network Management

```bash
# List networks
docker network ls

# Inspect network
docker network inspect frappe_quickstart_frappe_network
```

### Resource Usage

```bash
# Show resource usage
docker stats

# Show disk usage
docker system df
```

### Cleanup

```bash
# Remove stopped containers
docker compose down

# Remove volumes too
docker compose down -v

# Clean up Docker system
docker system prune -a
```

---

## Utility Scripts

Additional scripts for specific tasks.

### Health Check

Check if all services are healthy.

```bash
./scripts/health-check.sh

# With timeout
./scripts/health-check.sh --timeout 180

# Verbose output
./scripts/health-check.sh --verbose
```

**Exit codes:**
- `0` - All services healthy
- `1` - One or more services unhealthy
- `2` - Timeout reached

### Backup Script

Create backup programmatically.

```bash
./scripts/backup.sh

# Options
./scripts/backup.sh --site frontend --output /path/to/backup
```

### Restore Script

Restore from backup programmatically.

```bash
./scripts/restore.sh --backup-dir backups/2025-01-10_14-30-00

# Options
./scripts/restore.sh --backup-dir path/to/backup --site frontend
```

### Domain Setup

Run domain setup wizard.

```bash
./scripts/domain-setup.sh
```

---

## Environment Variables

Configure Frappe via `.env` file.

### Available Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FRAPPE_VERSION` | Frappe version/branch | `version-15` |
| `SITE_NAME` | Site name | `frontend` |
| `ADMIN_PASSWORD` | Administrator password | Auto-generated |
| `DB_ROOT_PASSWORD` | Database root password | Auto-generated |
| `MYSQL_ROOT_PASSWORD` | MySQL root password | Auto-generated |
| `MARIADB_ROOT_PASSWORD` | MariaDB root password | Auto-generated |
| `PORT` | Frontend port | `8080` |
| `PROJECT_NAME` | Docker Compose project name | `frappe_quickstart` |
| `IMAGE_NAME` | Docker image name | `frappe_quickstart:latest` |
| `PRESET` | Preset used | Value from `--preset` |

### Modify Configuration

```bash
# Edit .env file
nano .env

# Restart services to apply
./frappe-cli restart
```

---

## Tips and Tricks

### Quick Access to Logs

```bash
# Follow logs for specific service
docker compose logs -f backend | grep ERROR

# Show only errors
docker compose logs backend 2>&1 | grep -i error
```

### Database Access

```bash
# MySQL console
docker compose exec db mysql -uroot -p${MARIADB_ROOT_PASSWORD}

# Execute SQL
docker compose exec db mysql -uroot -p${MARIADB_ROOT_PASSWORD} -e "SHOW DATABASES"
```

### Copy Files

```bash
# From container to host
docker compose cp backend:/home/frappe/frappe-bench/sites/frontend/site_config.json ./

# From host to container
docker compose cp myfile.txt backend:/tmp/
```

### Performance Monitoring

```bash
# Resource usage
docker stats --no-stream

# Container processes
docker compose top
```

### Update Apps

```bash
# Pull latest changes for apps
docker compose exec backend bench update --reset

# Rebuild assets
docker compose exec backend bench build
```

---

## See Also

- [Quick Start Guide](quickstart.md)
- [Troubleshooting](troubleshooting.md)
- [Public Domains Setup](public-domains.md)
- [Frappe Documentation](https://frappeframework.com/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
