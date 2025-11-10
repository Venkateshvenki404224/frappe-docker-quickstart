#!/bin/bash
#
# Utility Functions Library
# Purpose: Common utility functions used across scripts
# Usage: Source this file in your scripts
#

# Get script directory (works on Linux, macOS, and Windows WSL)
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$(cd -P "$(dirname "$source")" && pwd)"
}

# Get project root directory
get_project_root() {
    local script_dir="$(get_script_dir)"
    # Assuming scripts are in scripts/lib
    echo "$(cd "$script_dir/../.." && pwd)"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if running in WSL
is_wsl() {
    if [ -f /proc/version ] && grep -qi microsoft /proc/version; then
        return 0
    fi
    return 1
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)
            if is_wsl; then
                echo "WSL"
            else
                echo "Linux"
            fi
            ;;
        Darwin*)
            echo "macOS"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "Windows"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Generate secure random password
# Arguments:
#   $1 - Length (default: 16)
# Returns:
#   Random password string
generate_password() {
    local length=${1:-16}

    # Try different methods for cross-platform compatibility
    if command_exists openssl; then
        openssl rand -base64 32 | tr -dc 'A-Za-z0-9!@#$%^&*()_+=' | head -c "$length"
    elif [ -f /dev/urandom ]; then
        tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom | head -c "$length"
    else
        # Fallback for systems without /dev/urandom
        date +%s%N | sha256sum | base64 | head -c "$length"
    fi
    echo ""
}

# Check if port is available
# Arguments:
#   $1 - Port number
# Returns:
#   0 if available, 1 if in use
is_port_available() {
    local port=$1

    if command_exists nc; then
        ! nc -z localhost "$port" &> /dev/null
    elif command_exists netstat; then
        ! netstat -tuln 2>/dev/null | grep -q ":$port "
    elif command_exists ss; then
        ! ss -tuln 2>/dev/null | grep -q ":$port "
    else
        # Assume available if we can't check
        return 0
    fi
}

# Find available port starting from given port
# Arguments:
#   $1 - Starting port (default: 8080)
# Returns:
#   First available port number
find_available_port() {
    local port=${1:-8080}
    local max_tries=100
    local tries=0

    while [ $tries -lt $max_tries ]; do
        if is_port_available "$port"; then
            echo "$port"
            return 0
        fi
        port=$((port + 1))
        tries=$((tries + 1))
    done

    # Return default if no port found
    echo "8080"
    return 1
}

# Load environment file
# Arguments:
#   $1 - Path to .env file (default: .env)
load_env() {
    local env_file="${1:-.env}"

    if [ -f "$env_file" ]; then
        # Export variables while preserving values with spaces
        set -a
        source "$env_file"
        set +a
        return 0
    fi
    return 1
}

# Read value from .env file
# Arguments:
#   $1 - Key name
#   $2 - Default value
# Returns:
#   Value from .env or default
read_env_value() {
    local key=$1
    local default=${2:-}
    local env_file=".env"

    if [ -f "$env_file" ]; then
        local value=$(grep "^${key}=" "$env_file" | cut -d '=' -f2- | tr -d '"' | tr -d "'")
        echo "${value:-$default}"
    else
        echo "$default"
    fi
}

# Update or add value in .env file
# Arguments:
#   $1 - Key name
#   $2 - Value
update_env_value() {
    local key=$1
    local value=$2
    local env_file=".env"

    if [ -f "$env_file" ]; then
        # Use platform-appropriate sed
        if [[ "$(uname -s)" == "Darwin" ]]; then
            # macOS
            sed -i '' "s|^${key}=.*|${key}=${value}|" "$env_file"
        else
            # Linux/WSL
            sed -i "s|^${key}=.*|${key}=${value}|" "$env_file"
        fi
    fi
}

# Wait for service with timeout
# Arguments:
#   $1 - Service name/check command
#   $2 - Timeout in seconds (default: 120)
# Returns:
#   0 if service available, 1 if timeout
wait_for_service() {
    local check_cmd=$1
    local timeout=${2:-120}
    local elapsed=0
    local interval=5

    while [ $elapsed -lt $timeout ]; do
        if eval "$check_cmd" &> /dev/null; then
            return 0
        fi
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    return 1
}

# Open URL in default browser (cross-platform)
# Arguments:
#   $1 - URL to open
open_browser() {
    local url=$1

    case "$(detect_os)" in
        Linux|WSL)
            if command_exists xdg-open; then
                xdg-open "$url" &> /dev/null &
            elif command_exists wslview; then
                wslview "$url" &> /dev/null &
            fi
            ;;
        macOS)
            open "$url" &> /dev/null &
            ;;
        Windows)
            start "$url" &> /dev/null &
            ;;
    esac
}

# Check Docker installation and version
check_docker() {
    if ! command_exists docker; then
        return 1
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        return 2
    fi

    return 0
}

# Check Docker Compose installation
check_docker_compose() {
    # Check for docker compose (v2)
    if docker compose version &> /dev/null; then
        echo "docker compose"
        return 0
    fi

    # Check for docker-compose (v1)
    if command_exists docker-compose; then
        echo "docker-compose"
        return 0
    fi

    return 1
}

# Get Docker Compose command
get_compose_cmd() {
    if docker compose version &> /dev/null; then
        echo "docker compose"
    elif command_exists docker-compose; then
        echo "docker-compose"
    else
        echo "docker-compose"
    fi
}

# Prompt user for yes/no
# Arguments:
#   $1 - Prompt message
#   $2 - Default (y/n)
# Returns:
#   0 for yes, 1 for no
prompt_yes_no() {
    local message=$1
    local default=${2:-n}
    local response

    if [ "$default" = "y" ]; then
        read -p "$message [Y/n]: " response
        response=${response:-y}
    else
        read -p "$message [y/N]: " response
        response=${response:-n}
    fi

    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Read input with default value
# Arguments:
#   $1 - Prompt message
#   $2 - Default value
# Returns:
#   User input or default
read_with_default() {
    local message=$1
    local default=$2
    local input

    read -p "$message [$default]: " input
    echo "${input:-$default}"
}

# Check if running as root
is_root() {
    [ "$EUID" -eq 0 ]
}

# Get current timestamp
timestamp() {
    date +"%Y-%m-%d_%H-%M-%S"
}

# Create backup directory
create_backup_dir() {
    local backup_root="backups"
    local backup_dir="${backup_root}/$(timestamp)"

    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# Format bytes to human readable
# Arguments:
#   $1 - Bytes
# Returns:
#   Human readable size
format_bytes() {
    local bytes=$1

    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$((bytes / 1024))KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Cleanup on exit
cleanup() {
    local temp_files=("$@")
    for file in "${temp_files[@]}"; do
        [ -f "$file" ] && rm -f "$file"
    done
}

# Set trap for cleanup
set_cleanup_trap() {
    trap 'cleanup "$@"' EXIT INT TERM
}
