# Frappe Quickstart

> From zero to Frappe in 3 minutes. Zero configuration. Development only.

A simple, developer-first Docker Compose environment for Frappe/ERPNext development. Perfect for testing issues, contributing to Frappe, or trying different versions.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)](https://www.docker.com/)
[![Frappe](https://img.shields.io/badge/Frappe-v15-orange)](https://frappeframework.com/)

## Features

- **One Command Start** - `python start.py` and you're done
- **Any Frappe Version** - Test v13, v14, v15, or develop branch
- **Preset Templates** - Pre-configured for ERP, Education, Healthcare, E-commerce, CRM
- **Zero Dependencies** - Pure Python stdlib (no pip install needed)
- **Cross-Platform** - Works on Linux, macOS, and Windows
- **Development Focus** - Quick setup for issue reproduction and testing

## Quick Start

### Prerequisites

- [Python](https://www.python.org/downloads/) 3.7 or higher
- [Docker](https://docs.docker.com/get-docker/) 20.10 or higher
- [Docker Compose](https://docs.docker.com/compose/install/) 2.0 or higher
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space

### Platform-Specific Installation

<details>
<summary><b>🐧 Linux (Ubuntu/Debian)</b></summary>

**1. Install Python 3:**
```bash
# Check if Python 3 is installed
python3 --version

# If not installed:
sudo apt update
sudo apt install python3 python3-pip -y
```

**2. Install Docker:**
```bash
# Update package index
sudo apt update

# Install dependencies
sudo apt install ca-certificates curl gnupg -y

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

**3. Clone and Run:**
```bash
# Clone repository
git clone https://github.com/yourusername/frappe-quickstart.git
cd frappe-quickstart

# Start Frappe
python3 start.py
```

</details>

<details>
<summary><b>🍎 macOS</b></summary>

**1. Install Python 3:**
```bash
# Check if Python 3 is installed
python3 --version

# If not installed, install via Homebrew:
# First install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python
brew install python3
```

**2. Install Docker Desktop:**
```bash
# Option A: Download from website
# Visit: https://docs.docker.com/desktop/install/mac-install/
# Download and install Docker Desktop for Mac (Intel or Apple Silicon)

# Option B: Install via Homebrew
brew install --cask docker

# Launch Docker Desktop from Applications
# Wait for Docker to start (check menu bar icon)

# Verify installation
docker --version
docker compose version
```

**3. Configure Docker Resources:**
- Open Docker Desktop
- Go to Settings → Resources
- Set Memory to at least 8GB
- Set Disk image size to at least 20GB
- Click "Apply & Restart"

**4. Clone and Run:**
```bash
# Clone repository
git clone https://github.com/yourusername/frappe-quickstart.git
cd frappe-quickstart

# Start Frappe
python3 start.py
```

</details>

<details>
<summary><b>🪟 Windows</b></summary>

**1. Install Python 3:**
```powershell
# Option A: Download from website
# Visit: https://www.python.org/downloads/
# Download Python 3.11+ installer
# ⚠️ IMPORTANT: Check "Add Python to PATH" during installation

# Option B: Install via winget (Windows 11)
winget install Python.Python.3.11

# Verify installation (in new terminal)
python --version
```

**2. Install Docker Desktop:**
```powershell
# Option A: Download from website
# Visit: https://docs.docker.com/desktop/install/windows-install/
# Download Docker Desktop for Windows
# Run installer and follow prompts

# Option B: Install via winget
winget install Docker.DockerDesktop

# Enable WSL 2 backend during installation
# Restart computer when prompted

# Verify installation (in new terminal)
docker --version
docker compose version
```

**3. Configure Docker Resources:**
- Open Docker Desktop
- Go to Settings → Resources
- Set Memory to at least 8GB
- Set Disk image size to at least 20GB
- Click "Apply & Restart"

**4. Clone and Run:**

**Using PowerShell:**
```powershell
# Clone repository
git clone https://github.com/yourusername/frappe-quickstart.git
cd frappe-quickstart

# Start Frappe
python start.py
```

**Using WSL2 (Recommended):**
```bash
# In WSL2 terminal
git clone https://github.com/yourusername/frappe-quickstart.git
cd frappe-quickstart

# Start Frappe
python3 start.py
```

**⚠️ Windows Notes:**
- Use PowerShell or WSL2 (not Command Prompt)
- If `python` doesn't work, try `python3` or `py`
- Ensure Docker Desktop is running before starting
- On WSL2, use Linux paths and commands

</details>

<details>
<summary><b>🐧 Linux (Fedora/RHEL/CentOS)</b></summary>

**1. Install Python 3:**
```bash
# Check if Python 3 is installed
python3 --version

# If not installed:
sudo dnf install python3 python3-pip -y
```

**2. Install Docker:**
```bash
# Remove old versions
sudo dnf remove docker docker-common docker-selinux docker-engine

# Set up repository
sudo dnf install dnf-plugins-core -y
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Install Docker
sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

**3. Clone and Run:**
```bash
# Clone repository
git clone https://github.com/yourusername/frappe-quickstart.git
cd frappe-quickstart

# Start Frappe
python3 start.py
```

</details>

<details>
<summary><b>🐧 Linux (Arch/Manjaro)</b></summary>

**1. Install Python 3:**
```bash
# Check if Python 3 is installed
python --version

# If not installed:
sudo pacman -S python python-pip
```

**2. Install Docker:**
```bash
# Install Docker
sudo pacman -S docker docker-compose

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

**3. Clone and Run:**
```bash
# Clone repository
git clone https://github.com/yourusername/frappe-quickstart.git
cd frappe-quickstart

# Start Frappe
python start.py
```

</details>

---

### Quick Installation (All Platforms)

Once prerequisites are installed:

```bash
# Clone the repository
git clone https://github.com/yourusername/frappe-quickstart.git
cd frappe-quickstart

# Start Frappe (use python3 on Linux/macOS, python on Windows)
python start.py
# OR
python3 start.py
```

Access your site at `http://localhost:8080` with:
- **Username:** Administrator
- **Password:** (shown in terminal after setup)

## Usage

### Starting Different Configurations

<details>
<summary><b>🐧 Linux</b></summary>

```bash
# Default: ERPNext v15
python3 start.py

# Minimal Frappe (no apps)
python3 start.py --preset minimal

# Different Frappe versions
python3 start.py --preset erp --frappe-version version-14
python3 start.py --preset erp --frappe-version version-13
python3 start.py --preset erp --frappe-version develop

# Other presets
python3 start.py --preset crm --frappe-version version-15
python3 start.py --preset healthcare --frappe-version version-15
python3 start.py --preset education --frappe-version version-15
python3 start.py --preset ecommerce --frappe-version version-15

# Custom port
python3 start.py --preset erp --port 8081

# Skip browser opening
python3 start.py --no-browser
```

</details>

<details>
<summary><b>🍎 macOS</b></summary>

```bash
# Ensure Docker Desktop is running first!

# Default: ERPNext v15
python3 start.py

# Minimal Frappe (no apps)
python3 start.py --preset minimal

# Different Frappe versions
python3 start.py --preset erp --frappe-version version-14
python3 start.py --preset erp --frappe-version version-13
python3 start.py --preset erp --frappe-version develop

# Other presets
python3 start.py --preset crm --frappe-version version-15
python3 start.py --preset healthcare --frappe-version version-15
python3 start.py --preset education --frappe-version version-15
python3 start.py --preset ecommerce --frappe-version version-15

# Custom port
python3 start.py --preset erp --port 8081

# Skip browser opening
python3 start.py --no-browser
```

</details>

<details>
<summary><b>🪟 Windows (PowerShell)</b></summary>

```powershell
# Ensure Docker Desktop is running first!

# Default: ERPNext v15
python start.py

# Minimal Frappe (no apps)
python start.py --preset minimal

# Different Frappe versions
python start.py --preset erp --frappe-version version-14
python start.py --preset erp --frappe-version version-13
python start.py --preset erp --frappe-version develop

# Other presets
python start.py --preset crm --frappe-version version-15
python start.py --preset healthcare --frappe-version version-15
python start.py --preset education --frappe-version version-15
python start.py --preset ecommerce --frappe-version version-15

# Custom port
python start.py --preset erp --port 8081

# Skip browser opening
python start.py --no-browser
```

**Note:** If `python` doesn't work, try `python3` or `py`

</details>

<details>
<summary><b>🪟 Windows (WSL2)</b></summary>

```bash
# Default: ERPNext v15
python3 start.py

# Minimal Frappe (no apps)
python3 start.py --preset minimal

# Different Frappe versions
python3 start.py --preset erp --frappe-version version-14
python3 start.py --preset erp --frappe-version version-13
python3 start.py --preset erp --frappe-version develop

# Other presets
python3 start.py --preset crm --frappe-version version-15
python3 start.py --preset healthcare --frappe-version version-15
python3 start.py --preset education --frappe-version version-15
python3 start.py --preset ecommerce --frappe-version version-15

# Custom port
python3 start.py --preset erp --port 8081

# Skip browser opening
python3 start.py --no-browser
```

</details>

---

### Command Reference (All Platforms)

```bash
# Basic syntax
python[3] start.py [OPTIONS]

# Available options:
--preset PRESET              # Preset name (default: erp)
--frappe-version VERSION     # Frappe version (default: version-15)
--port PORT                  # HTTP port (default: auto-detect from 8080)
--no-browser                 # Don't open browser automatically
--help                       # Show help message
```

### Managing Your Environment

**Check Status:**
```bash
docker compose ps
```

**View Logs:**
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f create-site
docker compose logs -f db
```

**Shell Access:**
```bash
# Backend container
docker compose exec backend bash

# Inside container, you can use bench:
bench --help
bench migrate
bench clear-cache
bench console
```

**Run Bench Commands:**
```bash
# From host machine
docker compose exec backend bench --help
docker compose exec backend bench --site frontend migrate
docker compose exec backend bench --site frontend clear-cache
docker compose exec backend bench --site frontend backup
docker compose exec backend bench --site frontend console
docker compose exec backend bench --site frontend add-to-hosts
```

**Database Access:**
```bash
# Via backend container
docker compose exec backend bench mariadb

# Or directly
docker compose exec db mariadb -u root -p
# Password is in .env file as DB_ROOT_PASSWORD
```

**Stop/Start/Restart:**
```bash
docker compose stop      # Stop all services
docker compose start     # Start stopped services
docker compose restart   # Restart all services
```

**Clean Up:**
```bash
# Stop and remove containers
docker compose down

# Remove containers and volumes (deletes all data)
docker compose down -v
```

## Presets

Available presets in `presets/` directory:

| Preset | Description | Apps Included |
|--------|-------------|---------------|
| `minimal` | Just Frappe framework | None |
| `erp` | Full ERPNext | ERPNext |
| `crm` | Frappe CRM | Frappe CRM |
| `education` | Education suite | ERPNext, Education, HRMS |
| `ecommerce` | E-commerce suite | ERPNext, Payments |
| `healthcare` | Healthcare suite | ERPNext, Healthcare |

### Creating Custom Presets

1. Create a new JSON file in `presets/` directory:

```bash
cat > presets/custom.json << 'EOF'
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/yourorg/custom-app",
    "branch": "main"
  }
]
EOF
```

2. Use your custom preset:

```bash
python start.py --preset custom --frappe-version version-15
```

## Development Mode - Working with Apps

### Git Operations on Apps

Apps are now mounted as volumes from your host machine (`./apps/` directory), which means:
- ✅ Full git operations (commit, branch, pull, push) work inside containers
- ✅ Code changes are immediately visible (no rebuild needed)
- ✅ Use any IDE on your host to edit app code

**Apps location**: `./apps/` directory in your project root

**Available apps**:
- `./apps/frappe/` - Frappe framework
- `./apps/nano_press/` - Your custom apps (from preset)

### Making Changes to Apps

**Option 1: Edit on Host (Recommended)**
```bash
# Use your favorite IDE/editor on host
cd apps/nano_press
# Make changes to code
git add .
git commit -m "Your changes"
git push origin ui-changes
```

**Option 2: Edit in Container**
```bash
# Enter container
docker exec -it frappe_quickstart_backend bash

# Navigate to app
cd /home/frappe/frappe-bench/apps/nano_press

# Make changes and commit
git add .
git commit -m "Your changes"
git push origin ui-changes
```

### Working with Branches

```bash
# From host
cd apps/nano_press
git checkout -b new-feature
# Make changes
git add .
git commit -m "Add new feature"
git push origin new-feature
```

### Adding New Apps

To add a new app to your development environment:

1. **Clone the app to apps directory**:
```bash
cd apps
git clone https://github.com/username/new-app --branch develop
cd ..
```

2. **Install the app in the site**:
```bash
docker exec -it frappe_quickstart_backend bench --site frontend install-app new-app
```

3. **Restart services**:
```bash
docker-compose restart backend
```

### Pulling Latest Changes

```bash
# From host
cd apps/nano_press
git pull origin ui-changes

# Restart services to apply changes
docker-compose restart backend
```

### Troubleshooting Development Issues

**Problem**: Changes not reflecting
**Solution**: Restart the backend service
```bash
docker-compose restart backend
```

**Problem**: Git permission denied
**Solution**: Configure git credentials in container
```bash
docker exec -it frappe_quickstart_backend bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

**Problem**: Apps folder is empty
**Solution**: Re-run start.py - it will clone apps if they don't exist
```bash
python start.py
```

### Development Workflow Best Practices

1. **Always work on branches** - Never commit directly to main/master
2. **Use .gitconfig** - Set up your git identity once:
   ```bash
   # From host
   git config --global user.name "Your Name"
   git config --global user.email "your@email.com"
   ```
3. **Sync regularly** - Pull changes from upstream frequently
4. **Test in container** - Your changes run in the same environment as production
5. **Commit often** - Small, focused commits are easier to manage

### App Development Commands

```bash
# Enter app directory (from host)
cd apps/nano_press

# View git status
git status

# Pull latest changes
git pull

# Install app in site
docker exec -it frappe_quickstart_backend bench --site frontend install-app nano_press

# Clear cache after changes
docker exec -it frappe_quickstart_backend bench --site frontend clear-cache

# Run migrations
docker exec -it frappe_quickstart_backend bench --site frontend migrate
```

## Common Development Tasks

### Reproducing a Bug

```bash
# Start the version where bug was reported
python start.py --preset erp --frappe-version version-14

# Access shell and reproduce
docker compose exec backend bash
cd ~/frappe-bench
bench console
```

### Testing a Pull Request

```bash
# 1. Start base environment
python start.py --preset minimal --frappe-version develop

# 2. Shell into container
docker compose exec backend bash

# 3. Fetch and test PR
cd ~/frappe-bench/apps/frappe
git fetch origin pull/12345/head:pr-12345
git checkout pr-12345
bench migrate
```

### Running Tests

```bash
# Shell into backend
docker compose exec backend bash

# Run tests
cd ~/frappe-bench
bench --site frontend run-tests --app frappe
bench --site frontend run-tests --module frappe.tests.test_api
```

### Backup and Restore

**Create Backup:**
```bash
# Create backup files
docker compose exec backend bench --site frontend backup

# Copy to host
docker compose cp backend:/home/frappe/frappe-bench/sites/frontend/private/backups/. ./backups/
```

**Restore Backup:**
```bash
# Copy backup to container
docker compose cp ./backups/20240101_123456-frontend-database.sql.gz backend:/tmp/

# Restore
docker compose exec backend bench --site frontend restore /tmp/20240101_123456-frontend-database.sql.gz
```

### Updating Apps

```bash
# Shell into container
docker compose exec backend bash

# Update apps
cd ~/frappe-bench
bench update --pull
bench update --patch
bench update --build
```

### Adding New Apps

```bash
# 1. Edit apps.json to add your app
# 2. Rebuild
python start.py --preset custom --frappe-version version-15

# Or manually add after setup:
docker compose exec backend bench get-app https://github.com/frappe/hrms --branch version-15
docker compose exec backend bench --site frontend install-app hrms
```

## Architecture

### Services

The environment includes 11 Docker services:

1. **backend** - Gunicorn WSGI server (main application)
2. **frontend** - Nginx reverse proxy
3. **websocket** - Socket.IO server for real-time features
4. **db** - MariaDB 10.6 database
5. **redis-cache** - Redis for caching
6. **redis-queue** - Redis for job queues
7. **queue-long** - Background worker for long jobs
8. **queue-short** - Background worker for short jobs
9. **scheduler** - Cron-like scheduled tasks
10. **configurator** - One-time configuration setup
11. **create-site** - One-time site creation

### Volumes

Persistent data stored in Docker volumes:

- `sites` - Frappe sites, files, and configuration
- `db-data` - MariaDB database files
- `redis-cache-data` & `redis-queue-data` - Redis persistence
- `logs` - Application logs

### How It Works

1. **start.py** generates passwords and creates `.env` file
2. **Docker build** creates image with apps from preset
3. **configurator** creates `common_site_config.json`
4. **create-site** initializes Frappe site and installs apps
5. **Services start** and site becomes accessible

## Troubleshooting

### Platform-Specific Issues

<details>
<summary><b>🐧 Linux Issues</b></summary>

**Docker Permission Denied:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes (logout/login or use)
newgrp docker

# Verify
docker ps
```

**Python command not found:**
```bash
# Install Python 3
sudo apt install python3 python3-pip -y  # Ubuntu/Debian
sudo dnf install python3 python3-pip -y  # Fedora/RHEL
sudo pacman -S python python-pip         # Arch

# Use python3 command
python3 start.py
```

**Port already in use:**
```bash
# Find process using port
sudo lsof -i :8080
# or
sudo ss -lptn 'sport = :8080'

# Kill process or use different port
python3 start.py --port 8081
```

**Docker service not running:**
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Check status
sudo systemctl status docker
```

</details>

<details>
<summary><b>🍎 macOS Issues</b></summary>

**Docker Desktop not running:**
- Open Docker Desktop from Applications
- Wait for whale icon in menu bar to become steady
- Check Settings → Resources for proper allocation

**Python version conflicts:**
```bash
# Check Python version
python3 --version

# If needed, install via Homebrew
brew install python3

# Always use python3 command
python3 start.py
```

**Port already in use:**
```bash
# Find process using port
lsof -i :8080

# Kill process or use different port
python3 start.py --port 8081
```

**Slow performance on Apple Silicon (M1/M2/M3):**
- Ensure you're using ARM64 Docker images
- In Docker Desktop: Settings → General → "Use Rosetta for x86/amd64 emulation" (can help but may be slower)
- Increase Docker memory: Settings → Resources → Memory → 8GB+

**File sharing issues:**
```bash
# Ensure project directory is in allowed paths
# Docker Desktop → Settings → Resources → File Sharing
# Add /Users/your-username/... if needed
```

</details>

<details>
<summary><b>🪟 Windows Issues</b></summary>

**WSL 2 not installed:**
```powershell
# Install WSL 2
wsl --install

# Set WSL 2 as default
wsl --set-default-version 2

# Restart computer
```

**Docker Desktop won't start:**
- Enable Virtualization in BIOS/UEFI
- Ensure Hyper-V is enabled (Windows Pro/Enterprise)
- Or ensure WSL 2 is installed (Windows Home)
- Restart Docker Desktop

**Python not recognized:**
```powershell
# Check Python installation
python --version
py --version
python3 --version

# If not found, install Python and check "Add to PATH"
# Or use full path
C:\Python311\python.exe start.py
```

**Line ending issues (Git):**
```powershell
# Configure Git to not convert line endings
git config --global core.autocrlf false

# Re-clone repository
git clone https://github.com/yourusername/frappe-quickstart.git
```

**Path too long errors:**
```powershell
# Enable long paths in Windows
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f

# Or use WSL2 instead of PowerShell
```

**Docker compose command not found:**
```powershell
# Use docker compose (space, not hyphen)
docker compose version

# Not: docker-compose (old version)
```

**Performance issues on Windows:**
- Use WSL2 backend (not Hyper-V)
- Keep project files in WSL2 filesystem (not /mnt/c/)
- Increase Docker Desktop resources

</details>

---

### Common Issues (All Platforms)

**Services Won't Start:**
```bash
# Check Docker is running
docker info

# Check logs
docker compose logs

# Restart services
docker compose restart
```

**Port Already in Use:**
```bash
# Script auto-detects available ports
# Or specify custom port:
python start.py --port 8081    # Windows PowerShell
python3 start.py --port 8081   # Linux/macOS/WSL2
```

**Site Creation Failed:**
```bash
# Check create-site logs
docker compose logs create-site

# Common causes:
# - Database not ready: Wait 30s and check: docker compose logs db
# - Network issues: Check internet connection
# - Invalid apps.json: python -m json.tool apps.json
# - Out of memory: Increase Docker memory to 8GB
```

**Database Connection Errors:**
```bash
# Check database status
docker compose ps db

# View database logs
docker compose logs db

# Test connection
docker compose exec db mariadb -u root -p
# Password is in .env file as DB_ROOT_PASSWORD
```

**Out of Memory:**

**Docker Desktop (macOS/Windows):**
- Open Docker Desktop
- Settings → Resources → Memory → 8GB minimum
- Apply & Restart

**Linux:**
- Native Docker uses system memory
- Check available: `free -h`
- Close other applications

**Slow Build Times:**
- First build: 5-10 minutes (downloads images, compiles)
- Subsequent builds: 2-3 minutes (cached layers)
- Use `--frappe-version develop` for faster base images

**Cannot access localhost:8080:**
```bash
# Check if frontend is running
docker compose ps frontend

# Check port mapping
docker compose port frontend 8080

# Try 127.0.0.1 instead
# http://127.0.0.1:8080

# Check firewall settings
```

## Security

⚠️ **This is a development environment only!**

- Passwords are randomly generated per installation
- `.env` file contains sensitive data (excluded from git)
- Database and Redis not exposed to host network
- No SSL/HTTPS configured

**For production**, use [Frappe Docker Production Setup](https://github.com/frappe/frappe_docker).

## Project Structure

```
frappe-quickstart/
├── start.py              # Main setup script (pure Python)
├── docker-compose.yml    # Service definitions
├── Dockerfile            # Multi-stage build for Frappe
├── .env.example          # Configuration template
├── presets/              # App preset configurations
│   ├── minimal.json
│   ├── erp.json
│   ├── crm.json
│   ├── education.json
│   ├── ecommerce.json
│   └── healthcare.json
└── CLAUDE.md             # Development guidance
```

## Requirements

**Python Standard Library Only** - No pip install required!

The script uses only Python stdlib:
- `argparse` - Command-line parsing
- `base64` - Apps.json encoding
- `json` - Configuration handling
- `secrets` - Secure password generation
- `socket` - Port availability checking
- `subprocess` - Docker command execution
- `pathlib` - File operations
- `webbrowser` - Browser opening

## Contributing

Contributions welcome! This project is designed to be simple and maintainable.

1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

**Guidelines:**
- Keep it simple - this is a development quickstart
- No external dependencies - pure Python stdlib
- Focus on common development workflows
- Document in README and CLAUDE.md

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/frappe-quickstart/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/frappe-quickstart/discussions)
- **Frappe Forum:** [Frappe Community](https://discuss.frappe.io/)

## Credits

Built with:
- [Frappe Framework](https://frappeframework.com/)
- [ERPNext](https://erpnext.com/)
- [Docker](https://www.docker.com/)

---

**Made with ❤️ for Frappe contributors and developers**
