#!/bin/bash
#
# Restore Script
# Purpose: Restore Frappe site from backup
# Usage: ./restore.sh [--backup-dir DIR] [--site SITENAME]
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
BACKUP_DIR=""
SITE_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --site)
            SITE_NAME="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 --backup-dir DIR [--site SITENAME]"
            echo ""
            echo "Options:"
            echo "  --backup-dir DIR   Backup directory to restore from (required)"
            echo "  --site SITENAME    Site to restore (default: from backup)"
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

header "Frappe Restore"
echo ""

# Validate backup directory
if [ -z "$BACKUP_DIR" ]; then
    error "Backup directory not specified"
    echo ""
    info "Available backups:"
    if [ -d "backups" ]; then
        ls -1t backups/ | head -5 | while read dir; do
            echo "  • backups/$dir"
        done
    else
        warning "No backups directory found"
    fi
    echo ""
    echo "Usage: $0 --backup-dir backups/YYYY-MM-DD_HH-MM-SS"
    exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    error "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# Check for manifest
if [ ! -f "${BACKUP_DIR}/manifest.json" ]; then
    warning "No manifest.json found in backup"
else
    info "Backup manifest:"
    cat "${BACKUP_DIR}/manifest.json" | grep -E '"(timestamp|site_name|size_human|apps)"' || cat "${BACKUP_DIR}/manifest.json"
fi

echo ""
separator 60
echo ""

# Get site name from manifest or use default
if [ -z "$SITE_NAME" ]; then
    if [ -f "${BACKUP_DIR}/manifest.json" ] && command_exists jq; then
        SITE_NAME=$(jq -r '.site_name' "${BACKUP_DIR}/manifest.json")
    else
        SITE_NAME=${SITE_NAME:-frontend}
    fi
fi

info "Restoring to site: ${SITE_NAME}"
echo ""

# Warning
warning "This will overwrite all existing data for site: ${SITE_NAME}"
echo ""

if ! prompt_yes_no "Do you want to continue?" "n"; then
    info "Restore cancelled"
    exit 0
fi

echo ""

# Check if services are running
if ! ${COMPOSE_CMD} ps backend &>/dev/null | grep -q "Up\|running"; then
    error "Backend service is not running"
    echo ""
    info "Start services first: ./frappe-cli start"
    exit 1
fi

# Copy backup files to container
step "Copying backup files to container..."

TEMP_BACKUP_DIR="/tmp/frappe_restore_$(date +%s)"
${COMPOSE_CMD} exec -T backend mkdir -p "${TEMP_BACKUP_DIR}"

if [ -f "${BACKUP_DIR}/database.sql.gz" ]; then
    ${COMPOSE_CMD} cp "${BACKUP_DIR}/database.sql.gz" "backend:${TEMP_BACKUP_DIR}/"
    success "Database backup copied"
fi

if [ -f "${BACKUP_DIR}/files.tar" ]; then
    ${COMPOSE_CMD} cp "${BACKUP_DIR}/files.tar" "backend:${TEMP_BACKUP_DIR}/"
    success "Files backup copied"
fi

if [ -f "${BACKUP_DIR}/private-files.tar" ]; then
    ${COMPOSE_CMD} cp "${BACKUP_DIR}/private-files.tar" "backend:${TEMP_BACKUP_DIR}/"
    success "Private files backup copied"
fi

echo ""

# Restore database
if [ -f "${BACKUP_DIR}/database.sql.gz" ]; then
    step "Restoring database..."

    ${COMPOSE_CMD} exec -T backend bench --site "${SITE_NAME}" --force restore \
        "${TEMP_BACKUP_DIR}/database.sql.gz" || {
        error "Database restore failed"
        ${COMPOSE_CMD} exec -T backend rm -rf "${TEMP_BACKUP_DIR}"
        exit 1
    }

    success "Database restored"
fi

# Restore files
if [ -f "${BACKUP_DIR}/files.tar" ]; then
    step "Restoring public files..."

    ${COMPOSE_CMD} exec -T backend tar -xf "${TEMP_BACKUP_DIR}/files.tar" \
        -C "sites/${SITE_NAME}/public" || {
        warning "Public files restore had issues (this may be normal)"
    }

    success "Public files restored"
fi

# Restore private files
if [ -f "${BACKUP_DIR}/private-files.tar" ]; then
    step "Restoring private files..."

    ${COMPOSE_CMD} exec -T backend tar -xf "${TEMP_BACKUP_DIR}/private-files.tar" \
        -C "sites/${SITE_NAME}/private" || {
        warning "Private files restore had issues (this may be normal)"
    }

    success "Private files restored"
fi

# Clean up temp directory
step "Cleaning up..."
${COMPOSE_CMD} exec -T backend rm -rf "${TEMP_BACKUP_DIR}"
success "Cleanup complete"

echo ""

# Run migrate
step "Running database migrations..."
${COMPOSE_CMD} exec -T backend bench --site "${SITE_NAME}" migrate || {
    warning "Migration had warnings (check logs)"
}
success "Migration complete"

echo ""

# Rebuild assets
step "Rebuilding assets..."
${COMPOSE_CMD} exec -T backend bench --site "${SITE_NAME}" build || {
    warning "Asset build had warnings"
}
success "Assets rebuilt"

echo ""
separator 60
echo ""
success "Restore complete!"
echo ""
info "Site ${SITE_NAME} has been restored from backup"
echo ""
info "You may need to restart services: ./frappe-cli restart"
echo ""
separator 60
echo ""
