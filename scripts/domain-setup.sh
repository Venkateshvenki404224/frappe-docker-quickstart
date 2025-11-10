#!/bin/bash
#
# Domain Setup Script
# Purpose: Wizard for setting up public domain (labs.selfmade.ninja)
# Usage: ./domain-setup.sh
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Source library files
source scripts/lib/colors.sh
source scripts/lib/utils.sh
source scripts/lib/validators.sh

# Create templates/generated directory if it doesn't exist
mkdir -p templates/generated

header "Public Domain Setup Wizard"
echo ""
subheader "Setup labs.selfmade.ninja subdomain for your Frappe site"
echo ""
separator 60
echo ""

# Load environment
if [ -f .env ]; then
    load_env .env
fi

SITE_NAME=${SITE_NAME:-frontend}
PORT=${PORT:-8080}

# Step 1: Get subdomain
step "Step 1: Choose your subdomain"
echo ""
info "Your site will be available at: <subdomain>.labs.selfmade.ninja"
echo ""

while true; do
    SUBDOMAIN=$(read_with_default "Enter desired subdomain" "my-frappe")

    if validate_subdomain "$SUBDOMAIN"; then
        success "Valid subdomain: ${SUBDOMAIN}"
        break
    else
        error "Invalid subdomain. Use only letters, numbers, and hyphens."
    fi
done

echo ""

# Step 2: Get server IP
step "Step 2: Provide your server's public IP"
echo ""
info "This is the IP address of the machine running Docker"
info "Find it with: curl ifconfig.me"
echo ""

while true; do
    SERVER_IP=$(read_with_default "Enter server public IP" "$(curl -s ifconfig.me 2>/dev/null || echo '0.0.0.0')")

    if validate_ipv4 "$SERVER_IP"; then
        success "Valid IP: ${SERVER_IP}"
        break
    else
        error "Invalid IP address format"
    fi
done

echo ""

# Step 3: Confirm port
step "Step 3: Confirm port"
echo ""
info "Your Frappe site is running on port: ${PORT}"
echo ""

CONFIRMED_PORT=$(read_with_default "Confirm port" "$PORT")

if ! validate_port "$CONFIRMED_PORT"; then
    error "Invalid port number"
    exit 1
fi

PORT=$CONFIRMED_PORT

echo ""
separator 60
echo ""

# Step 4: Generate configurations
step "Generating configuration files..."
echo ""

FULL_DOMAIN="${SUBDOMAIN}.labs.selfmade.ninja"

# Generate Apache configuration
info "Generating Apache VirtualHost configuration..."

cat > templates/generated/apache-${SUBDOMAIN}.conf << EOF
<VirtualHost *:80>
    ServerName ${FULL_DOMAIN}

    # Logging
    ErrorLog \${APACHE_LOG_DIR}/${SUBDOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${SUBDOMAIN}_access.log combined

    # Proxy settings
    ProxyRequests Off
    ProxyPreserveHost On
    ProxyTimeout 300

    # WebSocket support
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/?(.*) "ws://${SERVER_IP}:${PORT}/\$1" [P,L]

    # HTTP proxy
    ProxyPass / http://${SERVER_IP}:${PORT}/
    ProxyPassReverse / http://${SERVER_IP}:${PORT}/

    # Headers
    RequestHeader set X-Forwarded-Proto "http"
    RequestHeader set X-Forwarded-Host "${FULL_DOMAIN}"
    RequestHeader set X-Real-IP %{REMOTE_ADDR}s

    # Additional proxy headers
    <Location />
        ProxyPassReverse /
    </Location>
</VirtualHost>

# HTTPS configuration (optional - requires SSL certificate)
# <VirtualHost *:443>
#     ServerName ${FULL_DOMAIN}
#
#     SSLEngine on
#     SSLCertificateFile /etc/letsencrypt/live/${FULL_DOMAIN}/fullchain.pem
#     SSLCertificateKeyFile /etc/letsencrypt/live/${FULL_DOMAIN}/privkey.pem
#
#     ErrorLog \${APACHE_LOG_DIR}/${SUBDOMAIN}_ssl_error.log
#     CustomLog \${APACHE_LOG_DIR}/${SUBDOMAIN}_ssl_access.log combined
#
#     ProxyRequests Off
#     ProxyPreserveHost On
#     ProxyTimeout 300
#
#     RewriteEngine On
#     RewriteCond %{HTTP:Upgrade} websocket [NC]
#     RewriteCond %{HTTP:Connection} upgrade [NC]
#     RewriteRule ^/?(.*) "wss://${SERVER_IP}:${PORT}/\$1" [P,L]
#
#     ProxyPass / http://${SERVER_IP}:${PORT}/
#     ProxyPassReverse / http://${SERVER_IP}:${PORT}/
#
#     RequestHeader set X-Forwarded-Proto "https"
#     RequestHeader set X-Forwarded-Host "${FULL_DOMAIN}"
# </VirtualHost>
EOF

success "Apache configuration created: templates/generated/apache-${SUBDOMAIN}.conf"

# Generate Nginx configuration
info "Generating Nginx server block..."

cat > templates/generated/nginx-${SUBDOMAIN}.conf << EOF
server {
    listen 80;
    server_name ${FULL_DOMAIN};

    # Logging
    access_log /var/log/nginx/${SUBDOMAIN}_access.log;
    error_log /var/log/nginx/${SUBDOMAIN}_error.log;

    # Increase timeouts
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;

    # Main proxy location
    location / {
        proxy_pass http://${SERVER_IP}:${PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_redirect off;
    }

    # WebSocket support
    location /socket.io {
        proxy_pass http://${SERVER_IP}:${PORT}/socket.io;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

# HTTPS configuration (optional - requires SSL certificate)
# server {
#     listen 443 ssl http2;
#     server_name ${FULL_DOMAIN};
#
#     ssl_certificate /etc/letsencrypt/live/${FULL_DOMAIN}/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/${FULL_DOMAIN}/privkey.pem;
#
#     access_log /var/log/nginx/${SUBDOMAIN}_ssl_access.log;
#     error_log /var/log/nginx/${SUBDOMAIN}_ssl_error.log;
#
#     location / {
#         proxy_pass http://${SERVER_IP}:${PORT};
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto https;
#     }
#
#     location /socket.io {
#         proxy_pass http://${SERVER_IP}:${PORT}/socket.io;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade \$http_upgrade;
#         proxy_set_header Connection "upgrade";
#     }
# }
EOF

success "Nginx configuration created: templates/generated/nginx-${SUBDOMAIN}.conf"

echo ""
separator 60
echo ""

# Step 5: Display instructions
header "Next Steps:"
echo ""
echo "${COLOR_BOLD}1. Send configuration to labs.selfmade.ninja administrator${COLOR_RESET}"
echo ""
echo "   Apache configuration:"
echo "   ${COLOR_CYAN}templates/generated/apache-${SUBDOMAIN}.conf${COLOR_RESET}"
echo ""
echo "   OR"
echo ""
echo "   Nginx configuration:"
echo "   ${COLOR_CYAN}templates/generated/nginx-${SUBDOMAIN}.conf${COLOR_RESET}"
echo ""
separator 60
echo ""
echo "${COLOR_BOLD}2. Configuration details to provide:${COLOR_RESET}"
echo ""
echo "   ${COLOR_DIM}Subdomain:${COLOR_RESET}    ${SUBDOMAIN}"
echo "   ${COLOR_DIM}Full Domain:${COLOR_RESET}  ${FULL_DOMAIN}"
echo "   ${COLOR_DIM}Server IP:${COLOR_RESET}    ${SERVER_IP}"
echo "   ${COLOR_DIM}Port:${COLOR_RESET}         ${PORT}"
echo ""
separator 60
echo ""
echo "${COLOR_BOLD}3. Update Frappe site configuration${COLOR_RESET}"
echo ""

if prompt_yes_no "Do you want to update your site config now?" "y"; then
    echo ""
    step "Updating site configuration..."

    COMPOSE_CMD=$(get_compose_cmd)

    # Update site config to add the domain
    ${COMPOSE_CMD} exec -T backend bench --site "${SITE_NAME}" set-config host_name "\"${FULL_DOMAIN}\"" || {
        warning "Could not update site config automatically"
        info "You may need to update it manually later"
    }

    success "Site configuration updated"
fi

echo ""
separator 60
echo ""
echo "${COLOR_BOLD}4. Testing${COLOR_RESET}"
echo ""
info "After the administrator sets up the domain:"
echo ""
echo "   Test DNS:     ${COLOR_CYAN}nslookup ${FULL_DOMAIN}${COLOR_RESET}"
echo "   Test HTTP:    ${COLOR_CYAN}curl -I http://${FULL_DOMAIN}${COLOR_RESET}"
echo "   Access site:  ${COLOR_CYAN}http://${FULL_DOMAIN}${COLOR_RESET}"
echo ""
separator 60
echo ""
echo "${COLOR_BOLD}5. Optional: Enable HTTPS${COLOR_RESET}"
echo ""
info "For HTTPS support, uncomment the SSL sections in the config files"
info "and provide SSL certificates (e.g., from Let's Encrypt)"
echo ""
separator 60
echo ""
success "Domain setup wizard complete!"
echo ""
info "Configuration files saved in: ${COLOR_CYAN}templates/generated/${COLOR_RESET}"
echo ""
