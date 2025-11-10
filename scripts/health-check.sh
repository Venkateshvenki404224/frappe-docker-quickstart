#!/bin/bash
#
# Health Check Script
# Purpose: Monitor service health and report status
# Usage: ./health-check.sh [--timeout 120] [--verbose]
#
# Exit codes:
#   0 - All services healthy
#   1 - One or more services unhealthy
#   2 - Timeout reached
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
TIMEOUT=120
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--timeout SECONDS] [--verbose]"
            echo ""
            echo "Options:"
            echo "  --timeout SECONDS   Maximum wait time (default: 120)"
            echo "  --verbose, -v       Show detailed output"
            echo "  --help, -h          Show this help"
            echo ""
            echo "Exit codes:"
            echo "  0 - All services healthy"
            echo "  1 - One or more services unhealthy"
            echo "  2 - Timeout reached"
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

PORT=${PORT:-8080}

# Check if database is healthy
check_database() {
    local timeout=${1:-30}
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if ${COMPOSE_CMD} exec -T db mysqladmin ping -h localhost --password="${MARIADB_ROOT_PASSWORD}" --silent &>/dev/null; then
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    return 1
}

# Check if Redis is healthy
check_redis() {
    local service=$1
    local timeout=${2:-30}
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if ${COMPOSE_CMD} exec -T "$service" redis-cli ping &>/dev/null | grep -q PONG; then
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    return 1
}

# Check if HTTP service is healthy
check_http() {
    local url=$1
    local timeout=${2:-30}
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if curl -sf "$url" &>/dev/null; then
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    return 1
}

# Main health check
main() {
    if [ "$VERBOSE" = true ]; then
        header "Frappe Health Check"
        echo ""
    fi

    local start_time=$(date +%s)
    local all_healthy=true

    # Check if services are running
    if [ "$VERBOSE" = true ]; then
        step "Checking if services are running..."
    fi

    if ! ${COMPOSE_CMD} ps &>/dev/null; then
        error "Docker Compose services not found"
        exit 1
    fi

    # Check database
    if [ "$VERBOSE" = true ]; then
        step "Checking database..."
    fi

    if check_database 30; then
        [ "$VERBOSE" = true ] && success "Database is healthy"
    else
        [ "$VERBOSE" = true ] && error "Database is unhealthy"
        all_healthy=false
    fi

    # Check Redis cache
    if [ "$VERBOSE" = true ]; then
        step "Checking Redis cache..."
    fi

    if check_redis "redis-cache" 30; then
        [ "$VERBOSE" = true ] && success "Redis cache is healthy"
    else
        [ "$VERBOSE" = true ] && error "Redis cache is unhealthy"
        all_healthy=false
    fi

    # Check Redis queue
    if [ "$VERBOSE" = true ]; then
        step "Checking Redis queue..."
    fi

    if check_redis "redis-queue" 30; then
        [ "$VERBOSE" = true ] && success "Redis queue is healthy"
    else
        [ "$VERBOSE" = true ] && error "Redis queue is unhealthy"
        all_healthy=false
    fi

    # Check frontend
    if [ "$VERBOSE" = true ]; then
        step "Checking frontend..."
    fi

    if check_http "http://localhost:${PORT}" 30; then
        [ "$VERBOSE" = true ] && success "Frontend is healthy"
    else
        [ "$VERBOSE" = true ] && error "Frontend is unhealthy"
        all_healthy=false
    fi

    # Check backend (via frontend proxy)
    if [ "$VERBOSE" = true ]; then
        step "Checking backend..."
    fi

    if check_http "http://localhost:${PORT}/api/method/ping" 30; then
        [ "$VERBOSE" = true ] && success "Backend is healthy"
    else
        [ "$VERBOSE" = true ] && warning "Backend API check inconclusive"
    fi

    # Calculate elapsed time
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))

    if [ "$VERBOSE" = true ]; then
        echo ""
        separator 60
        echo ""
    fi

    # Check timeout
    if [ $elapsed -ge $TIMEOUT ]; then
        error "Health check timeout reached (${elapsed}s)"
        exit 2
    fi

    # Final result
    if [ "$all_healthy" = true ]; then
        [ "$VERBOSE" = true ] && success "All services are healthy (checked in ${elapsed}s)"
        exit 0
    else
        [ "$VERBOSE" = true ] && error "Some services are unhealthy"
        exit 1
    fi
}

# Run main
main
