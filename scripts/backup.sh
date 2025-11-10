#!/bin/bash
#
# Backup Script
# Purpose: Create comprehensive backup of Frappe site
# Usage: ./backup.sh [--site SITENAME] [--output DIR]
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Source library files
source scripts/lib/colors.sh
source scripts/lib/utils.sh

# Default values
SITE_NAME=""
OUTPUT_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --site)
            SITE_NAME="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--site SITENAME] [--output DIR]"
            echo ""
            echo "Options:"
            echo "  --site SITENAME    Site to backup (default: from .env)"
            echo "  --output DIR       Output directory (default: backups/TIMESTAMP)"
            echo "  --help, -h         Show this help"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Get compose command
COMPOSE_CMD=$(get_compose_cmd)

# Load environment
if [ -f .env ]; then
    load_env .env
fi

# Set defaults from environment
SITE_NAME=${SITE_NAME:-${SITE_NAME:-frontend}}

# Create backup directory
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR=$(create_backup_dir)
else
    mkdir -p "$OUTPUT_DIR"
fi

header "Frappe Backup"
echo ""
info "Site: ${SITE_NAME}"
info "Output: ${OUTPUT_DIR}"
echo ""
separator 60
echo ""

# Check if services are running
if ! ${COMPOSE_CMD} ps backend &>/dev/null | grep -q "Up\|running"; then
    error "Backend service is not running"
    echo ""
    info "Start services first: ./frappe-cli start"
    exit 1
fi

# Backup database
step "Backing up database..."
${COMPOSE_CMD} exec -T backend bench --site "${SITE_NAME}" backup --with-files

# Get the backup files from container
step "Retrieving backup files..."

# Find the latest backup files
LATEST_DB_BACKUP=$(${COMPOSE_CMD} exec -T backend bash -c "ls -t sites/${SITE_NAME}/private/backups/*-database.sql.gz 2>/dev/null | head -1" | tr -d '\r')
LATEST_FILES_BACKUP=$(${COMPOSE_CMD} exec -T backend bash -c "ls -t sites/${SITE_NAME}/private/backups/*-files.tar 2>/dev/null | head -1" | tr -d '\r')
LATEST_PRIVATE_FILES=$(${COMPOSE_CMD} exec -T backend bash -c "ls -t sites/${SITE_NAME}/private/backups/*-private-files.tar 2>/dev/null | head -1" | tr -d '\r')

# Copy backup files from container to host
if [ -n "$LATEST_DB_BACKUP" ]; then
    ${COMPOSE_CMD} cp "backend:${LATEST_DB_BACKUP}" "${OUTPUT_DIR}/database.sql.gz"
    success "Database backup saved"
fi

if [ -n "$LATEST_FILES_BACKUP" ]; then
    ${COMPOSE_CMD} cp "backend:${LATEST_FILES_BACKUP}" "${OUTPUT_DIR}/files.tar"
    success "Files backup saved"
fi

if [ -n "$LATEST_PRIVATE_FILES" ]; then
    ${COMPOSE_CMD} cp "backend:${LATEST_PRIVATE_FILES}" "${OUTPUT_DIR}/private-files.tar"
    success "Private files backup saved"
fi

# Backup site config
step "Backing up site configuration..."
${COMPOSE_CMD} exec -T backend cat "sites/${SITE_NAME}/site_config.json" > "${OUTPUT_DIR}/site_config.json"
success "Site config saved"

# Backup apps.json
if [ -f apps.json ]; then
    step "Backing up apps configuration..."
    cp apps.json "${OUTPUT_DIR}/apps.json"
    success "Apps config saved"
fi

# Backup .env (without passwords)
step "Backing up environment configuration..."
if [ -f .env ]; then
    cat .env | grep -v "PASSWORD" > "${OUTPUT_DIR}/env.txt"
    success "Environment config saved (passwords excluded)"
fi

# Create manifest
step "Creating backup manifest..."

# Get installed apps list
APPS_LIST=$(${COMPOSE_CMD} exec -T backend bench --site "${SITE_NAME}" list-apps 2>/dev/null | tr '\n' ',' | sed 's/,$//' || echo "unknown")

# Calculate backup size
BACKUP_SIZE=0
for file in "${OUTPUT_DIR}"/*; do
    if [ -f "$file" ]; then
        SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        BACKUP_SIZE=$((BACKUP_SIZE + SIZE))
    fi
done

# Create manifest
cat > "${OUTPUT_DIR}/manifest.json" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "site_name": "${SITE_NAME}",
  "frappe_version": "${FRAPPE_VERSION:-version-15}",
  "apps": "${APPS_LIST}",
  "size_bytes": ${BACKUP_SIZE},
  "size_human": "$(format_bytes $BACKUP_SIZE)",
  "files": {
    "database": "database.sql.gz",
    "files": "files.tar",
    "private_files": "private-files.tar",
    "site_config": "site_config.json",
    "apps_config": "apps.json",
    "env_config": "env.txt"
  }
}
EOF

success "Manifest created"

echo ""
separator 60
echo ""
success "Backup complete!"
echo ""
info "Backup location: ${OUTPUT_DIR}"
info "Backup size: $(format_bytes $BACKUP_SIZE)"
echo ""
info "Backup contents:"
ls -lh "${OUTPUT_DIR}" | tail -n +2 | awk '{print "  • " $9 " (" $5 ")"}'
echo ""
separator 60
echo ""
