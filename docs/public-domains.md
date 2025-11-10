# Public Domain Setup Guide

Make your local Frappe instance accessible via a public domain using labs.selfmade.ninja.

## Overview

This guide helps you configure a public subdomain (e.g., `mysite.labs.selfmade.ninja`) that forwards to your local Frappe instance.

## Prerequisites

- Running Frappe instance
- Server with public IP address
- Access to labs.selfmade.ninja administrator (for domain configuration)
- Apache or Nginx on the proxy server

## Quick Setup

### Step 1: Run the Domain Setup Wizard

```bash
./frappe-cli domain
```

The wizard will:
1. Ask for your desired subdomain
2. Collect your server's public IP
3. Confirm the port your Frappe is running on
4. Generate Apache and Nginx configurations
5. Provide setup instructions

### Step 2: Find Your Public IP

If you don't know your server's public IP:

```bash
curl ifconfig.me
```

Or visit: https://ifconfig.me

### Step 3: Review Generated Configurations

The wizard creates two configuration files in `templates/generated/`:

- `apache-<subdomain>.conf` - Apache VirtualHost configuration
- `nginx-<subdomain>.conf` - Nginx server block configuration

## Manual Setup

If you prefer to set up manually:

### For Apache

1. Create a new VirtualHost configuration:

```bash
sudo nano /etc/apache2/sites-available/mysite.conf
```

2. Add the following configuration:

```apache
<VirtualHost *:80>
    ServerName mysite.labs.selfmade.ninja

    # Proxy settings
    ProxyRequests Off
    ProxyPreserveHost On
    ProxyTimeout 300

    # WebSocket support
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/?(.*) "ws://YOUR_SERVER_IP:8080/$1" [P,L]

    # HTTP proxy
    ProxyPass / http://YOUR_SERVER_IP:8080/
    ProxyPassReverse / http://YOUR_SERVER_IP:8080/

    # Headers
    RequestHeader set X-Forwarded-Proto "http"
    RequestHeader set X-Forwarded-Host "mysite.labs.selfmade.ninja"

    # Logging
    ErrorLog ${APACHE_LOG_DIR}/mysite_error.log
    CustomLog ${APACHE_LOG_DIR}/mysite_access.log combined
</VirtualHost>
```

3. Enable required Apache modules:

```bash
sudo a2enmod proxy proxy_http proxy_wstunnel rewrite headers
```

4. Enable the site:

```bash
sudo a2ensite mysite
sudo systemctl reload apache2
```

### For Nginx

1. Create a new server block:

```bash
sudo nano /etc/nginx/sites-available/mysite
```

2. Add the following configuration:

```nginx
server {
    listen 80;
    server_name mysite.labs.selfmade.ninja;

    # Timeouts
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;

    # Main proxy location
    location / {
        proxy_pass http://YOUR_SERVER_IP:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
    }

    # WebSocket support
    location /socket.io {
        proxy_pass http://YOUR_SERVER_IP:8080/socket.io;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    # Logging
    access_log /var/log/nginx/mysite_access.log;
    error_log /var/log/nginx/mysite_error.log;
}
```

3. Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/mysite /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Update Frappe Site Configuration

After setting up the proxy, update your Frappe site configuration:

```bash
./frappe-cli shell
bench --site frontend set-config host_name '"mysite.labs.selfmade.ninja"'
exit
```

Or manually edit the site config:

```bash
docker compose exec backend nano sites/frontend/site_config.json
```

Add:
```json
{
  "host_name": "mysite.labs.selfmade.ninja"
}
```

## Enable HTTPS (Optional)

### Using Let's Encrypt

1. Install Certbot:

```bash
sudo apt install certbot python3-certbot-apache  # For Apache
# OR
sudo apt install certbot python3-certbot-nginx   # For Nginx
```

2. Obtain certificate:

```bash
sudo certbot --apache -d mysite.labs.selfmade.ninja  # For Apache
# OR
sudo certbot --nginx -d mysite.labs.selfmade.ninja   # For Nginx
```

3. Auto-renewal is configured automatically

### Manual SSL Configuration

If you have your own certificates:

#### Apache HTTPS

```apache
<VirtualHost *:443>
    ServerName mysite.labs.selfmade.ninja

    SSLEngine on
    SSLCertificateFile /path/to/fullchain.pem
    SSLCertificateKeyFile /path/to/privkey.pem

    # Proxy settings (same as HTTP)
    ProxyRequests Off
    ProxyPreserveHost On

    # WebSocket support with WSS
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/?(.*) "wss://YOUR_SERVER_IP:8080/$1" [P,L]

    ProxyPass / http://YOUR_SERVER_IP:8080/
    ProxyPassReverse / http://YOUR_SERVER_IP:8080/

    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Forwarded-Host "mysite.labs.selfmade.ninja"
</VirtualHost>
```

#### Nginx HTTPS

```nginx
server {
    listen 443 ssl http2;
    server_name mysite.labs.selfmade.ninja;

    ssl_certificate /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    # Proxy locations (same as HTTP)
    location / {
        proxy_pass http://YOUR_SERVER_IP:8080;
        proxy_set_header X-Forwarded-Proto https;
        # ... other headers
    }

    location /socket.io {
        proxy_pass http://YOUR_SERVER_IP:8080/socket.io;
        # ... WebSocket settings
    }
}
```

## Testing

### Test DNS Resolution

```bash
nslookup mysite.labs.selfmade.ninja
```

Should return the labs.selfmade.ninja server IP.

### Test HTTP Connection

```bash
curl -I http://mysite.labs.selfmade.ninja
```

Should return HTTP 200 or 301/302 redirect.

### Test in Browser

1. Open: `http://mysite.labs.selfmade.ninja`
2. Should see Frappe login page
3. Login with your credentials
4. Test real-time features (should use WebSocket)

## Troubleshooting

### Site Not Loading

1. Check proxy server logs:
   ```bash
   sudo tail -f /var/log/apache2/mysite_error.log  # Apache
   sudo tail -f /var/log/nginx/mysite_error.log    # Nginx
   ```

2. Verify Frappe is accessible:
   ```bash
   curl http://YOUR_SERVER_IP:8080
   ```

3. Check firewall rules:
   ```bash
   sudo ufw status
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

### WebSocket Not Working

1. Ensure WebSocket modules are enabled:
   ```bash
   sudo a2enmod proxy_wstunnel  # Apache
   ```

2. Check WebSocket connection in browser console (F12)

3. Verify proxy configuration includes WebSocket support

### SSL Certificate Issues

1. Check certificate validity:
   ```bash
   sudo certbot certificates
   ```

2. Test SSL configuration:
   ```bash
   sudo apachectl configtest  # Apache
   sudo nginx -t              # Nginx
   ```

3. Renew certificate if expired:
   ```bash
   sudo certbot renew
   ```

## Security Considerations

1. **Firewall**: Only expose necessary ports (80, 443)
2. **HTTPS**: Always use HTTPS in production
3. **Rate Limiting**: Configure rate limiting on proxy server
4. **DDoS Protection**: Consider Cloudflare or similar services
5. **Authentication**: Ensure Frappe has strong authentication
6. **Updates**: Keep proxy server and Frappe updated

## Performance Optimization

### Apache

```apache
# Enable compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript
</IfModule>

# Enable caching
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
</IfModule>
```

### Nginx

```nginx
# Compression
gzip on;
gzip_vary on;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;

# Caching
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## Support

- [Frappe Forum](https://discuss.frappe.io/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Apache Proxy Guide](https://httpd.apache.org/docs/current/mod/mod_proxy.html)
- [Nginx Proxy Guide](https://nginx.org/en/docs/http/ngx_http_proxy_module.html)
