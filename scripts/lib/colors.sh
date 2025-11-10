#!/bin/bash
#
# Color Output Library
# Purpose: Provides color-coded output functions for terminal
# Usage: Source this file in your scripts
#

# Color codes - compatible with Linux, macOS, and Windows (WSL)
if [[ -t 1 ]] && command -v tput &> /dev/null && [[ $(tput colors) -ge 8 ]]; then
    # Terminal supports colors
    export COLOR_RESET="\033[0m"
    export COLOR_RED="\033[0;31m"
    export COLOR_GREEN="\033[0;32m"
    export COLOR_YELLOW="\033[0;33m"
    export COLOR_BLUE="\033[0;34m"
    export COLOR_MAGENTA="\033[0;35m"
    export COLOR_CYAN="\033[0;36m"
    export COLOR_WHITE="\033[0;37m"
    export COLOR_BOLD="\033[1m"
    export COLOR_DIM="\033[2m"
else
    # No color support
    export COLOR_RESET=""
    export COLOR_RED=""
    export COLOR_GREEN=""
    export COLOR_YELLOW=""
    export COLOR_BLUE=""
    export COLOR_MAGENTA=""
    export COLOR_CYAN=""
    export COLOR_WHITE=""
    export COLOR_BOLD=""
    export COLOR_DIM=""
fi

# Success message (green)
success() {
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} $1"
}

# Error message (red)
error() {
    echo -e "${COLOR_RED}✗${COLOR_RESET} $1" >&2
}

# Warning message (yellow)
warning() {
    echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $1"
}

# Info message (blue)
info() {
    echo -e "${COLOR_BLUE}ℹ${COLOR_RESET} $1"
}

# Step message (cyan)
step() {
    echo -e "${COLOR_CYAN}▶${COLOR_RESET} $1"
}

# Header message (bold)
header() {
    echo -e "${COLOR_BOLD}$1${COLOR_RESET}"
}

# Subheader (dim)
subheader() {
    echo -e "${COLOR_DIM}$1${COLOR_RESET}"
}

# Progress bar
# Usage: progress_bar 50 100
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))

    printf "\r["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %d%%" $percentage

    if [ $current -eq $total ]; then
        echo ""
    fi
}

# Spinner for long-running operations
# Usage: run_with_spinner "command" "Message"
spinner() {
    local pid=$1
    local message=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local temp

    while kill -0 $pid 2>/dev/null; do
        temp=${spinstr#?}
        printf "\r${COLOR_CYAN}%c${COLOR_RESET} %s" "$spinstr" "$message"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done
    printf "\r"
}

# Box drawing
print_box() {
    local message="$1"
    local length=${#message}
    local border_length=$((length + 4))

    echo -e "${COLOR_BOLD}"
    printf '╔'
    printf '═%.0s' $(seq 1 $border_length)
    printf '╗\n'
    printf "║  %s  ║\n" "$message"
    printf '╚'
    printf '═%.0s' $(seq 1 $border_length)
    printf '╝\n'
    echo -e "${COLOR_RESET}"
}

# Separator line
separator() {
    local width=${1:-60}
    printf '%*s\n' "$width" '' | tr ' ' '─'
}
