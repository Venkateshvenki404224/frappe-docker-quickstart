# Troubleshooting Guide

Common issues and solutions for Frappe Quickstart.

## Table of Contents

- [Docker Issues](#docker-issues)
- [Build Failures](#build-failures)
- [Service Issues](#service-issues)
- [Network & Port Issues](#network--port-issues)
- [Database Issues](#database-issues)
- [Performance Issues](#performance-issues)
- [WebSocket Issues](#websocket-issues)
- [Backup & Restore Issues](#backup--restore-issues)

---

## Docker Issues

### Docker Not Installed

**Symptom:** `./start.sh` says "Docker is not installed"

**Solution:**

Install Docker for your platform:

**Linux:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in
```

**macOS:**
- Download and install [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)

**Windows:**
- Download and install [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- Enable WSL2 backend

### Docker Daemon Not Running

**Symptom:** Error message "Cannot connect to the Docker daemon"

**Solution:**

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

**macOS/Windows:**
- Start Docker Desktop application

**Verify:**
```bash
docker info
```

### Permission Denied

**Symptom:** "permission denied while trying to connect to the Docker daemon socket"

**Solution:**

**Linux:**
```bash
sudo usermod -aG docker $USER
newgrp docker
# OR log out and back in
```

**Verify:**
```bash
docker ps
```

---

## Build Failures

### Image Build Failed

**Symptom:** Build stops with errors during `docker build`

**Common Causes & Solutions:**

#### 1. Network Issues

```bash
# Check internet connection
ping -c 3 github.com

# Try building again
./start.sh
```

#### 2. Disk Space Full

```bash
# Check disk space
df -h

# Clean up Docker
docker system prune -a
docker volume prune
```

#### 3. Invalid apps.json

**Check apps.json syntax:**
```bash
cat apps.json | jq .
```

**Fix:**
Ensure proper JSON format:
```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  }
]
```

#### 4. Git Repository Inaccessible

**Symptom:** Error cloning app repository

```bash
# Test repository access
git clone https://github.com/frappe/erpnext --depth 1 test
rm -rf test
```

### Slow Build

**Symptom:** Build takes > 15 minutes

**Solutions:**

1. **Check internet speed:**
   ```bash
   curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
   ```

2. **Use fewer apps:** Start with minimal preset
   ```bash
   ./start.sh --preset minimal
   ```

3. **Increase Docker resources:**
   - Docker Desktop → Settings → Resources
   - Increase CPU and Memory allocation

---

## Service Issues

### Services Won't Start

**Symptom:** Services keep restarting or fail to start

**Diagnosis:**

```bash
# Check service status
docker compose ps

# Check specific service logs
docker compose logs backend
docker compose logs db
docker compose logs frontend
```

**Common Solutions:**

#### Database Not Ready

```bash
# Wait for database
docker compose logs db | grep "ready for connections"

# Restart services
./frappe-cli restart
```

#### Configuration Errors

```bash
# Check .env file
cat .env

# Recreate .env
rm .env
./start.sh
```

### Create-Site Service Fails

**Symptom:** `create-site` container exits with error

**Diagnosis:**
```bash
docker compose logs create-site
```

**Common Issues:**

#### 1. Database Connection

```bash
# Check database is running
docker compose ps db

# Check database logs
docker compose logs db
```

#### 2. Site Already Exists

```bash
# Remove existing site
docker compose down
docker volume rm frappe_quickstart_sites
./start.sh
```

### Services Constantly Restarting

**Diagnosis:**

```bash
# Check logs
./frappe-cli logs

# Check resource usage
docker stats
```

**Solutions:**

1. **Insufficient Resources:**
   - Increase Docker memory limit to 4GB+
   - Close other applications

2. **Port Conflicts:**
   ```bash
   # Use different port
   ./start.sh --port 8081
   ```

---

## Network & Port Issues

### Port Already in Use

**Symptom:** "port is already allocated" or auto-detection fails

**Solution:**

1. **Find what's using the port:**
   ```bash
   sudo lsof -i :8080
   # OR
   sudo netstat -nlp | grep :8080
   ```

2. **Stop the conflicting service or use different port:**
   ```bash
   ./start.sh --port 8081
   ```

### Cannot Access Site

**Symptom:** Browser shows "connection refused" or timeout

**Diagnosis:**

```bash
# Check frontend service
docker compose ps frontend

# Check if port is exposed
docker compose port frontend 8080

# Test locally
curl http://localhost:8080
```

**Solutions:**

1. **Check services are running:**
   ```bash
   ./frappe-cli status
   ```

2. **Check firewall:**
   ```bash
   sudo ufw status
   sudo ufw allow 8080/tcp
   ```

3. **Try different browser or incognito mode**

4. **Clear browser cache**

---

## Database Issues

### Database Connection Failed

**Symptom:** "Could not connect to database" errors

**Diagnosis:**

```bash
# Check database service
docker compose ps db

# Check database logs
docker compose logs db

# Test connection
docker compose exec db mysql -uroot -p${MARIADB_ROOT_PASSWORD} -e "SELECT 1"
```

**Solutions:**

1. **Wait for database to initialize:**
   ```bash
   # First startup can take 30-60 seconds
   docker compose logs -f db
   ```

2. **Check passwords in .env:**
   ```bash
   grep PASSWORD .env
   ```

3. **Reset database:**
   ```bash
   docker compose down
   docker volume rm frappe_quickstart_db-data
   ./start.sh
   ```

### Database Corruption

**Symptom:** MySQL errors, data inconsistency

**Solution:**

1. **Create backup if possible:**
   ```bash
   ./frappe-cli backup
   ```

2. **Check and repair:**
   ```bash
   docker compose exec db mysqlcheck -uroot -p${MARIADB_ROOT_PASSWORD} --all-databases --repair
   ```

3. **If repair fails, restore from backup:**
   ```bash
   ./frappe-cli restore
   ```

---

## Performance Issues

### Slow Response Times

**Diagnosis:**

```bash
# Check resource usage
docker stats

# Check slow queries
docker compose exec db mysql -uroot -p${MARIADB_ROOT_PASSWORD} -e "SHOW FULL PROCESSLIST"
```

**Solutions:**

1. **Increase Docker resources:**
   - 4GB RAM minimum, 8GB recommended
   - 2+ CPU cores

2. **Check disk I/O:**
   ```bash
   iostat -x 1
   ```

3. **Optimize database:**
   ```bash
   docker compose exec backend bench --site frontend optimize-database
   ```

### High CPU Usage

**Check what's consuming:**
```bash
docker stats
```

**Solutions:**

1. **Disable scheduler temporarily:**
   ```bash
   docker compose stop scheduler
   ```

2. **Check background jobs:**
   ```bash
   docker compose exec backend bench --site frontend show-pending-jobs
   ```

3. **Clear job queue:**
   ```bash
   docker compose exec backend bench --site frontend clear-cache
   docker compose exec backend bench --site frontend clear-website-cache
   ```

---

## WebSocket Issues

### Real-time Features Not Working

**Symptom:** Live updates don't work, notifications delayed

**Diagnosis:**

```bash
# Check WebSocket service
docker compose logs websocket

# Test in browser console (F12)
# Look for WebSocket connection errors
```

**Solutions:**

1. **Check WebSocket service:**
   ```bash
   docker compose ps websocket
   docker compose logs websocket
   ```

2. **Restart WebSocket service:**
   ```bash
   docker compose restart websocket
   ```

3. **Check Redis queue:**
   ```bash
   docker compose ps redis-queue
   ```

---

## Backup & Restore Issues

### Backup Failed

**Symptom:** Backup script exits with errors

**Diagnosis:**
```bash
docker compose logs backend
```

**Solutions:**

1. **Check disk space:**
   ```bash
   df -h
   ```

2. **Ensure services are running:**
   ```bash
   ./frappe-cli status
   ```

3. **Manual backup:**
   ```bash
   docker compose exec backend bench --site frontend backup --with-files
   ```

### Restore Failed

**Common Issues:**

1. **Site name mismatch:**
   - Ensure restoring to correct site name

2. **Version mismatch:**
   - Backup from v14 won't restore to v15 directly

3. **Insufficient permissions:**
   ```bash
   docker compose exec backend chown -R frappe:frappe /home/frappe/frappe-bench/sites
   ```

---

## General Debugging

### Get Detailed Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend

# Last 100 lines
docker compose logs --tail=100

# With timestamps
docker compose logs -f --timestamps
```

### Access Container Shell

```bash
# Backend container
./frappe-cli shell

# Database container
docker compose exec db bash

# Any container
docker compose exec <service-name> bash
```

### Check Configuration

```bash
# View environment
cat .env

# View site config
docker compose exec backend cat sites/frontend/site_config.json

# View common config
docker compose exec backend cat sites/common_site_config.json
```

### Complete Reset

If all else fails:

```bash
# Stop and remove everything
docker compose down -v

# Remove generated files
rm .env apps.json

# Start fresh
./start.sh
```

---

## Getting Help

If you still have issues:

1. **Check logs:** `./frappe-cli logs > error-logs.txt`
2. **Document steps to reproduce**
3. **Note your environment:**
   ```bash
   docker --version
   docker compose version
   uname -a
   ```

4. **Ask for help:**
   - [GitHub Issues](https://github.com/yourusername/frappe-quickstart/issues)
   - [Frappe Forum](https://discuss.frappe.io/)
   - [Frappe Discord](https://discord.gg/frappe)

**Include in your report:**
- Operating system and version
- Docker and Docker Compose versions
- Exact error messages
- Logs from affected services
- Steps you've already tried
