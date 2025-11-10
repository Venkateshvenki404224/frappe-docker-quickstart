# Frappe Quickstart

> From zero to Frappe in 3 minutes. No configuration required.

A zero-configuration, developer-first Docker Compose environment for Frappe/ERPNext development that gets you coding in under 3 minutes with intelligent automation and beautiful UX.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)](https://www.docker.com/)
[![Frappe](https://img.shields.io/badge/Frappe-v15-orange)](https://frappeframework.com/)

## Features

- **Zero Configuration** - One command to rule them all: `./start.sh`
- **Intelligent Setup** - Auto-detects ports, generates secure passwords, handles everything
- **Beautiful CLI** - Interactive menu-driven management with color-coded output
- **Preset Templates** - Pre-configured setups for ERP, Education, Healthcare, E-commerce
- **Public Domain Support** - Easy integration with labs.selfmade.ninja
- **Cross-Platform** - Works on Linux, macOS, and Windows (WSL)
- **Complete Tooling** - Backup, restore, health checks, and more built-in
- **Production Ready** - 11 optimized services with health monitoring

## Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (version 20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 2.0+)
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/frappe-quickstart.git
cd frappe-quickstart

# Start Frappe (that's it!)
./start.sh
```

That's it! The script will:
- Check dependencies
- Find available port
- Generate secure passwords
- Build Docker images
- Start all services
- Create your site
- Open your browser

Access your site at `http://localhost:8080` with:
- **Username:** Administrator
- **Password:** (shown in terminal)

## Usage

### Interactive CLI

```bash
./frappe-cli
```

The CLI provides easy access to all operations:

```
1.  start          Start all services
2.  stop           Stop all services
3.  restart        Restart services
4.  status         Show detailed service status
5.  logs           Stream logs (all or specific service)
6.  shell          Open bash shell in backend container
7.  bench          Run bench commands directly
8.  apps           Manage apps (view/add/remove)
9.  backup         Create backup
10. restore        Restore from backup
11. domain         Setup public domain
12. update         Pull latest changes & rebuild
13. clean          Remove all data (with backup prompt)
14. config         Show configuration
15. help           Show help
```

### Direct Commands

You can also run commands directly:

```bash
./frappe-cli status         # Check service status
./frappe-cli logs           # View logs
./frappe-cli backup         # Create backup
./frappe-cli shell          # Open shell
```

## Presets

Choose from pre-configured app combinations:

### Minimal (Just Frappe)
```bash
./start.sh --preset minimal
```

### ERP (Frappe + ERPNext)
```bash
./start.sh --preset erp
```

### Education (ERP + Education + HRMS)
```bash
./start.sh --preset education
```

### E-Commerce (ERP + Payments)
```bash
./start.sh --preset ecommerce
```

### Healthcare (ERP + Healthcare)
```bash
./start.sh --preset healthcare
```

## Public Domain Setup

Make your local Frappe instance accessible via a public domain:

```bash
./frappe-cli domain
```

The wizard will:
1. Collect your desired subdomain
2. Get your server's public IP
3. Generate Apache and Nginx configurations
4. Provide step-by-step setup instructions

Your site will be available at: `<subdomain>.labs.selfmade.ninja`

See [docs/public-domains.md](docs/public-domains.md) for detailed instructions.

## Advanced Usage

### Custom Port

```bash
./start.sh --port 8081
```

### Development Mode

```bash
./start.sh --dev
```

### Running Bench Commands

```bash
# Via CLI
./frappe-cli bench --help

# Or directly
docker compose exec backend bench --help
```

### Managing Apps

Edit `apps.json` to add custom apps:

```json
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
```

Then rebuild:

```bash
./frappe-cli update
```

## Architecture

### Services

The environment includes 11 optimized Docker services:

1. **backend** - Gunicorn application server
2. **frontend** - Nginx web server
3. **websocket** - Socket.IO server for real-time features
4. **db** - MariaDB 10.6 database
5. **redis-cache** - Redis for caching
6. **redis-queue** - Redis for job queue
7. **queue-long** - Worker for long-running jobs
8. **queue-short** - Worker for short jobs
9. **scheduler** - Cron-like job scheduler
10. **configurator** - One-time setup service
11. **create-site** - Site creation service

### Volumes

Persistent data is stored in:
- `sites` - Frappe sites and files
- `db-data` - Database data
- `redis-*-data` - Redis persistence
- `logs` - Application logs

## Backup & Restore

### Create Backup

```bash
./frappe-cli backup
```

Creates a timestamped backup in `backups/` containing:
- Database dump (compressed)
- Public files
- Private files
- Site configuration
- Apps configuration
- Metadata manifest

### Restore from Backup

```bash
./frappe-cli restore
```

Select from available backups and restore completely.

## Troubleshooting

### Services Won't Start

```bash
# Check Docker daemon
docker info

# Check logs
./frappe-cli logs

# Restart services
./frappe-cli restart
```

### Port Already in Use

The script auto-detects and uses the next available port. Or specify manually:

```bash
./start.sh --port 8081
```

### Database Connection Errors

```bash
# Check database service
docker compose ps db

# View database logs
docker compose logs db
```

For more issues, see [docs/troubleshooting.md](docs/troubleshooting.md)

## Documentation

- [Quick Start Guide](docs/quickstart.md) - 60-second setup
- [Command Reference](docs/commands.md) - All CLI commands
- [Public Domains](docs/public-domains.md) - Domain setup guide
- [Troubleshooting](docs/troubleshooting.md) - Common issues

## Project Structure

```
frappe-quickstart/
├── start.sh                 # Main entry point
├── frappe-cli              # Interactive CLI tool
├── docker-compose.yml      # Service definitions
├── Dockerfile              # Multi-stage build
├── .env.example           # Configuration template
├── presets/               # App preset configurations
│   ├── minimal.json
│   ├── erp.json
│   ├── education.json
│   ├── ecommerce.json
│   └── healthcare.json
├── scripts/               # Automation scripts
│   ├── lib/              # Shared libraries
│   ├── health-check.sh   # Health monitoring
│   ├── backup.sh         # Backup utility
│   ├── restore.sh        # Restore utility
│   └── domain-setup.sh   # Domain wizard
├── templates/            # Config templates
│   ├── apache-vhost.conf
│   ├── nginx-vhost.conf
│   └── site-config.json
└── docs/                 # Documentation
    ├── quickstart.md
    ├── commands.md
    ├── public-domains.md
    └── troubleshooting.md
```

## Security

- Passwords are cryptographically random (16+ characters)
- No credentials stored in git
- `.env` file excluded from version control
- Database and Redis not exposed to host network
- Production deployment requires additional hardening

**Important:** This setup is optimized for development. For production:
1. Change all passwords
2. Use proper SSL/TLS certificates
3. Configure firewall rules
4. Enable database backups
5. Review security settings

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

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

**Made with ❤️ for the Frappe community**

**Star this repo if it helped you!**
