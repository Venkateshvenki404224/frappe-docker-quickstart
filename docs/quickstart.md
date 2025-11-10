# Quick Start Guide

Get Frappe running in 60 seconds. No explanations, just commands.

## Prerequisites

- Docker installed
- Docker Compose installed
- 4GB RAM available
- 10GB disk space

## Basic Setup

```bash
git clone https://github.com/yourusername/frappe-quickstart.git
cd frappe-quickstart
./start.sh
```

Wait 3-5 minutes. Done.

Access: `http://localhost:8080`
- Username: `Administrator`
- Password: (shown in terminal)

## With Different Preset

```bash
./start.sh --preset minimal      # Just Frappe
./start.sh --preset erp          # Frappe + ERPNext (default)
./start.sh --preset education    # ERP + Education + HRMS
./start.sh --preset ecommerce    # ERP + Payments
./start.sh --preset healthcare   # ERP + Healthcare
```

## Custom Port

```bash
./start.sh --port 8081
```

## Common Commands

```bash
./frappe-cli                 # Interactive menu
./frappe-cli status          # Check status
./frappe-cli logs            # View logs
./frappe-cli shell           # Open shell
./frappe-cli backup          # Create backup
./frappe-cli stop            # Stop services
./frappe-cli start           # Start services
```

## Run Bench Commands

```bash
./frappe-cli shell
bench --help
bench list-apps
bench --site frontend console
```

## Stop Everything

```bash
./frappe-cli stop
```

## Clean Everything

```bash
./frappe-cli clean
```

## Restart After Reboot

```bash
./frappe-cli start
```

## Next Steps

- Read [README.md](../README.md) for detailed features
- See [commands.md](commands.md) for all CLI commands
- Check [troubleshooting.md](troubleshooting.md) if issues occur
- Setup public domain with [public-domains.md](public-domains.md)
