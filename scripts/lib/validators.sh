#!/bin/bash
#
# Input Validation Library
# Purpose: Validation functions for user inputs
# Usage: Source this file in your scripts
#

# Validate port number
# Arguments:
#   $1 - Port number to validate
# Returns:
#   0 if valid, 1 if invalid
validate_port() {
    local port=$1

    # Check if numeric
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    # Check range (1-65535)
    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi

    return 0
}

# Validate domain name
# Arguments:
#   $1 - Domain name to validate
# Returns:
#   0 if valid, 1 if invalid
validate_domain() {
    local domain=$1

    # Basic domain validation
    if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    fi

    return 1
}

# Validate subdomain (simpler than full domain)
# Arguments:
#   $1 - Subdomain to validate
# Returns:
#   0 if valid, 1 if invalid
validate_subdomain() {
    local subdomain=$1

    # Subdomain validation (alphanumeric and hyphens, can't start/end with hyphen)
    if [[ "$subdomain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
        return 0
    fi

    return 1
}

# Validate IP address (IPv4)
# Arguments:
#   $1 - IP address to validate
# Returns:
#   0 if valid, 1 if invalid
validate_ipv4() {
    local ip=$1

    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        # Check each octet
        local IFS='.'
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if [ "$octet" -gt 255 ]; then
                return 1
            fi
        done
        return 0
    fi

    return 1
}

# Validate email address
# Arguments:
#   $1 - Email to validate
# Returns:
#   0 if valid, 1 if invalid
validate_email() {
    local email=$1

    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    fi

    return 1
}

# Validate URL
# Arguments:
#   $1 - URL to validate
# Returns:
#   0 if valid, 1 if invalid
validate_url() {
    local url=$1

    if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
        return 0
    fi

    return 1
}

# Validate Git URL
# Arguments:
#   $1 - Git URL to validate
# Returns:
#   0 if valid, 1 if invalid
validate_git_url() {
    local url=$1

    # Support both HTTPS and SSH Git URLs
    if [[ "$url" =~ ^(https?://|git@)[a-zA-Z0-9.-]+(:[0-9]+)?[:/].+\.git$ ]] || \
       [[ "$url" =~ ^(https?://|git@)[a-zA-Z0-9.-]+(:[0-9]+)?[:/].+$ ]]; then
        return 0
    fi

    return 1
}

# Validate file path exists
# Arguments:
#   $1 - File path to validate
# Returns:
#   0 if exists, 1 if not
validate_file_exists() {
    local filepath=$1

    if [ -f "$filepath" ]; then
        return 0
    fi

    return 1
}

# Validate directory exists
# Arguments:
#   $1 - Directory path to validate
# Returns:
#   0 if exists, 1 if not
validate_dir_exists() {
    local dirpath=$1

    if [ -d "$dirpath" ]; then
        return 0
    fi

    return 1
}

# Validate JSON file
# Arguments:
#   $1 - Path to JSON file
# Returns:
#   0 if valid JSON, 1 if invalid
validate_json_file() {
    local filepath=$1

    if ! validate_file_exists "$filepath"; then
        return 1
    fi

    if command -v jq &> /dev/null; then
        if jq empty "$filepath" &> /dev/null; then
            return 0
        fi
    else
        # Fallback: basic check
        if python3 -c "import json; json.load(open('$filepath'))" &> /dev/null; then
            return 0
        elif python -c "import json; json.load(open('$filepath'))" &> /dev/null; then
            return 0
        fi
    fi

    return 1
}

# Validate password strength
# Arguments:
#   $1 - Password to validate
#   $2 - Minimum length (default: 8)
# Returns:
#   0 if strong enough, 1 if weak
validate_password() {
    local password=$1
    local min_length=${2:-8}

    # Check minimum length
    if [ ${#password} -lt $min_length ]; then
        return 1
    fi

    # Check for at least one letter and one number (basic strength)
    if [[ "$password" =~ [A-Za-z] ]] && [[ "$password" =~ [0-9] ]]; then
        return 0
    fi

    return 1
}

# Validate preset name
# Arguments:
#   $1 - Preset name
# Returns:
#   0 if valid preset, 1 if invalid
validate_preset() {
    local preset=$1
    local valid_presets=("minimal" "erp" "education" "ecommerce" "healthcare" "custom")

    for valid in "${valid_presets[@]}"; do
        if [ "$preset" = "$valid" ]; then
            return 0
        fi
    done

    return 1
}

# Validate environment variable name
# Arguments:
#   $1 - Variable name
# Returns:
#   0 if valid, 1 if invalid
validate_env_var_name() {
    local varname=$1

    # Must start with letter or underscore, contain only alphanumeric and underscore
    if [[ "$varname" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        return 0
    fi

    return 1
}

# Validate disk space available
# Arguments:
#   $1 - Required space in GB
#   $2 - Path to check (default: current directory)
# Returns:
#   0 if enough space, 1 if not enough
validate_disk_space() {
    local required_gb=$1
    local path=${2:-.}

    # Get available space in GB
    local available_gb

    if command -v df &> /dev/null; then
        # Use df to check available space
        available_gb=$(df -BG "$path" | tail -1 | awk '{print $4}' | sed 's/G//')

        if [ "$available_gb" -ge "$required_gb" ]; then
            return 0
        fi
    else
        # Can't check, assume OK
        return 0
    fi

    return 1
}

# Validate Docker is installed and running
# Returns:
#   0 if valid, 1 if not installed, 2 if not running
validate_docker() {
    if ! command -v docker &> /dev/null; then
        return 1
    fi

    if ! docker info &> /dev/null; then
        return 2
    fi

    return 0
}

# Validate Docker Compose is available
# Returns:
#   0 if available, 1 if not
validate_docker_compose() {
    if docker compose version &> /dev/null; then
        return 0
    fi

    if command -v docker-compose &> /dev/null; then
        return 0
    fi

    return 1
}

# Validate semantic version format
# Arguments:
#   $1 - Version string (e.g., "1.2.3" or "v1.2.3")
# Returns:
#   0 if valid, 1 if invalid
validate_semver() {
    local version=$1

    # Remove leading 'v' if present
    version=${version#v}

    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    fi

    return 1
}

# Validate branch name
# Arguments:
#   $1 - Branch name
# Returns:
#   0 if valid, 1 if invalid
validate_branch_name() {
    local branch=$1

    # Git branch name validation
    # Cannot start with -, contain .., @{, \, space
    if [[ "$branch" =~ ^[^-].*$ ]] && \
       [[ ! "$branch" =~ \.\. ]] && \
       [[ ! "$branch" =~ @\{ ]] && \
       [[ ! "$branch" =~ \\ ]] && \
       [[ ! "$branch" =~ [[:space:]] ]]; then
        return 0
    fi

    return 1
}
