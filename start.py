#!/usr/bin/env python3
"""
Frappe Quickstart - Zero Configuration Docker Setup
Purpose: Automated setup and launch of Frappe Docker environment for development
Usage: python start.py [--preset <name>] [--frappe-version <version>] [--port <number>]
"""

import argparse
import base64
import json
import secrets
import socket
import string
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional, Dict, List


class Colors:
    """ANSI color codes for terminal output"""
    RESET = '\033[0m'
    BOLD = '\033[1m'
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'

    @staticmethod
    def disable():
        """Disable colors (for non-TTY environments)"""
        Colors.RESET = Colors.BOLD = Colors.RED = ''
        Colors.GREEN = Colors.YELLOW = Colors.BLUE = Colors.CYAN = ''


# Disable colors if not a TTY
if not sys.stdout.isatty():
    Colors.disable()


def print_header(text: str):
    """Print a bold header"""
    print(f"\n{Colors.BOLD}{Colors.CYAN}═══ {text} ═══{Colors.RESET}")


def print_step(text: str):
    """Print a step message"""
    print(f"{Colors.BLUE}▶{Colors.RESET} {text}")


def print_success(text: str):
    """Print a success message"""
    print(f"{Colors.GREEN}✓{Colors.RESET} {text}")


def print_error(text: str):
    """Print an error message"""
    print(f"{Colors.RED}✗{Colors.RESET} {text}", file=sys.stderr)


def print_info(text: str):
    """Print an info message"""
    print(f"{Colors.CYAN}ℹ{Colors.RESET} {text}")


def print_warning(text: str):
    """Print a warning message"""
    print(f"{Colors.YELLOW}⚠{Colors.RESET} {text}")


def generate_password(length: int = 16) -> str:
    """
    Generate a secure random password

    Args:
        length: Password length (default: 16)

    Returns:
        Randomly generated password string
    """
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))


def find_available_port(start_port: int = 8080, max_tries: int = 100) -> int:
    """
    Find an available port starting from start_port

    Args:
        start_port: Port to start checking from (default: 8080)
        max_tries: Maximum number of ports to try (default: 100)

    Returns:
        First available port number

    Raises:
        RuntimeError: If no available port found within range
    """
    for port in range(start_port, start_port + max_tries):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.bind(('', port))
                return port
        except OSError:
            continue

    raise RuntimeError(f"No available port found in range {start_port}-{start_port + max_tries}")


def check_dependencies() -> bool:
    """
    Check if required dependencies are installed

    Returns:
        True if all dependencies are available, False otherwise
    """
    dependencies = {
        'docker': ['docker', '--version'],
        'docker compose': ['docker', 'compose', 'version']
    }

    all_available = True

    for name, command in dependencies.items():
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                # Extract version info
                version = result.stdout.split('\n')[0] if result.stdout else 'installed'
                print_success(f"{name} found ({version})")
            else:
                print_error(f"{name} check failed")
                all_available = False
        except (subprocess.TimeoutExpired, FileNotFoundError):
            print_error(f"{name} not found")
            all_available = False

    return all_available


def get_available_presets() -> List[str]:
    """
    Get list of available preset names

    Returns:
        List of preset names (without .json extension)
    """
    presets_dir = Path('presets')
    if not presets_dir.exists():
        return []

    return [p.stem for p in presets_dir.glob('*.json')]


def load_preset(preset_name: str) -> List[Dict[str, str]]:
    """
    Load apps from preset file

    Args:
        preset_name: Name of the preset (without .json extension)

    Returns:
        List of app dictionaries with 'url' and 'branch' keys

    Raises:
        FileNotFoundError: If preset file doesn't exist
        json.JSONDecodeError: If preset file is invalid JSON
    """
    preset_path = Path('presets') / f'{preset_name}.json'

    if not preset_path.exists():
        available = ', '.join(get_available_presets())
        raise FileNotFoundError(
            f"Preset '{preset_name}' not found.\n"
            f"Available presets: {available}"
        )

    with preset_path.open() as f:
        apps = json.load(f)

    # Validate format
    if not isinstance(apps, list):
        raise ValueError(f"Preset file must contain a JSON array, got {type(apps).__name__}")

    return apps


def create_env_file(
    port: int,
    admin_password: str,
    db_password: str,
    preset: str,
    frappe_version: str,
    apps: List[Dict[str, str]]
) -> None:
    """
    Create .env configuration file

    Args:
        port: Port number for the frontend service
        admin_password: Administrator password
        db_password: Database root password
        preset: Preset name used
        frappe_version: Frappe version/branch
        apps: List of app dictionaries (to extract app names)
    """
    # Extract app names from URLs
    app_names = []
    for app in apps:
        url = app.get('url', '')
        # Extract app name from URL (last part without .git)
        app_name = url.rstrip('/').split('/')[-1].replace('.git', '')
        if app_name:
            app_names.append(app_name)

    # Create comma-separated list for environment variable
    install_apps = ','.join(app_names) if app_names else ''

    env_content = f"""# Frappe Configuration
FRAPPE_VERSION={frappe_version}
SITE_NAME=frontend

# Security - Auto-generated by start.py
ADMIN_PASSWORD={admin_password}
DB_ROOT_PASSWORD={db_password}
MYSQL_ROOT_PASSWORD={db_password}
MARIADB_ROOT_PASSWORD={db_password}

# Network Configuration
PORT={port}

# Docker Configuration
PROJECT_NAME=frappe_quickstart
IMAGE_NAME=frappe_quickstart:latest

# Preset used
PRESET={preset}

# Apps to install (comma-separated)
INSTALL_APPS={install_apps}
"""

    Path('.env').write_text(env_content)


def build_docker_image(apps: List[Dict[str, str]], frappe_version: str) -> bool:
    """
    Build Docker image with specified apps and Frappe version

    Args:
        apps: List of app dictionaries to install
        frappe_version: Frappe version/branch to use

    Returns:
        True if build succeeded, False otherwise
    """
    # Encode apps.json to base64
    apps_json_str = json.dumps(apps, indent=2)
    apps_base64 = base64.b64encode(apps_json_str.encode()).decode()

    # Build Docker image
    build_command = [
        'docker', 'build',
        '--build-arg', f'APPS_JSON_BASE64={apps_base64}',
        '--build-arg', f'FRAPPE_BRANCH={frappe_version}',
        '-t', 'frappe_quickstart:latest',
        '-f', 'Dockerfile',
        '.'
    ]

    try:
        result = subprocess.run(build_command, check=True)
        return result.returncode == 0
    except subprocess.CalledProcessError:
        return False


def clone_apps_to_host(apps: List[Dict[str, str]], frappe_version: str) -> bool:
    """
    Clone apps to local ./apps directory for volume mounting

    Args:
        apps: List of app dictionaries with 'url' and 'branch'
        frappe_version: Frappe version/branch to clone

    Returns:
        True if successful, False otherwise
    """
    apps_dir = Path('apps')

    # Create apps directory if it doesn't exist
    if not apps_dir.exists():
        print_step("Creating apps directory...")
        apps_dir.mkdir(exist_ok=True)
        print_success("Apps directory created")

    # Clone Frappe framework first
    frappe_dir = apps_dir / 'frappe'
    if not frappe_dir.exists():
        print_step(f"Cloning Frappe framework ({frappe_version})...")
        result = subprocess.run(
            ['git', 'clone', 'https://github.com/frappe/frappe',
             '--branch', frappe_version, '--depth', '1', str(frappe_dir)],
            capture_output=True
        )
        if result.returncode == 0:
            print_success("Frappe framework cloned")
        else:
            print_error("Failed to clone Frappe framework")
            return False
    else:
        print_info("Frappe framework already exists, skipping clone")

    # Clone each custom app
    for app in apps:
        url = app.get('url', '')
        branch = app.get('branch', 'main')

        # Extract app name from URL
        app_name = url.rstrip('/').split('/')[-1].replace('.git', '')
        app_path = apps_dir / app_name

        if not app_path.exists():
            print_step(f"Cloning {app_name} ({branch})...")
            result = subprocess.run(
                ['git', 'clone', url, '--branch', branch, str(app_path)],
                capture_output=True
            )
            if result.returncode == 0:
                print_success(f"{app_name} cloned")
            else:
                print_error(f"Failed to clone {app_name}")
                return False
        else:
            print_info(f"{app_name} already exists, skipping clone")

    return True


def destroy_environment() -> bool:
    """
    Destroy all containers and volumes

    Returns:
        True if successful, False otherwise
    """
    try:
        print_step("Stopping all services...")
        subprocess.run(
            ['docker', 'compose', 'down', '-v', '--remove-orphans'],
            check=True
        )
        print_success("Environment destroyed")
        return True
    except subprocess.CalledProcessError:
        print_error("Failed to destroy environment")
        return False


def start_docker_services(clean_start: bool = False) -> bool:
    """
    Start Docker Compose services

    Args:
        clean_start: If True, remove volumes before starting

    Returns:
        True if services started successfully, False otherwise
    """
    # Clean start - remove volumes
    if clean_start:
        print_step("Cleaning existing volumes...")
        subprocess.run(
            ['docker', 'compose', 'down', '-v', '--remove-orphans'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        print_success("Volumes cleaned")
    else:
        # Just stop existing services
        subprocess.run(
            ['docker', 'compose', 'down'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

    # Start services
    try:
        result = subprocess.run(
            ['docker', 'compose', 'up', '-d'],
            check=True
        )
        return result.returncode == 0
    except subprocess.CalledProcessError:
        return False


def wait_for_site_creation(timeout: int = 300) -> bool:
    """
    Wait for create-site container to complete successfully

    Args:
        timeout: Maximum time to wait in seconds (default: 300)

    Returns:
        True if site was created successfully, False otherwise
    """
    start_time = time.time()
    last_elapsed_shown = 0
    dots = 0

    while time.time() - start_time < timeout:
        elapsed = int(time.time() - start_time)

        # Check create-site container status
        result = subprocess.run(
            ['docker', 'compose', 'ps', '--all', '--format', 'json'],
            capture_output=True,
            text=True
        )

        if result.returncode == 0 and result.stdout.strip():
            try:
                # Parse JSON output - look for create-site container
                lines = [line for line in result.stdout.strip().split('\n') if line]
                for line in lines:
                    try:
                        status_data = json.loads(line)
                        service = status_data.get('Service', '')

                        if service == 'create-site':
                            state = status_data.get('State', '')
                            exit_code = status_data.get('ExitCode', -1)

                            # Show progress every 10 seconds with dots
                            if elapsed - last_elapsed_shown >= 10:
                                dots = (dots + 1) % 4
                                dot_str = '.' * dots
                                print(f"\r{Colors.CYAN}ℹ{Colors.RESET} Site creation in progress{dot_str}{'   '} ({elapsed}s)", end='', flush=True)
                                last_elapsed_shown = elapsed

                            # Check if completed successfully
                            if state == 'exited' and exit_code == 0:
                                print()  # New line after progress
                                return True

                            # Check if failed
                            if state == 'exited' and exit_code != 0:
                                print()  # New line after progress
                                print_error(f"Site creation failed with exit code {exit_code}")
                                print_info("View logs with: docker compose logs create-site")
                                return False

                    except json.JSONDecodeError:
                        continue

            except Exception:
                # Fallback to checking logs
                pass

        time.sleep(3)  # Check every 3 seconds instead of 5

    print()  # New line after progress
    print_error(f"Site creation timed out after {timeout} seconds")
    return False


def print_completion_message(port: int, admin_password: str, preset: str, frappe_version: str):
    """
    Print completion message with access information

    Args:
        port: Port number where Frappe is accessible
        admin_password: Administrator password
        preset: Preset name that was used
        frappe_version: Frappe version that was installed
    """
    print()
    print(f"{Colors.BOLD}{Colors.GREEN}╔══════════════════════════════════════════════════════════╗")
    print(f"║                                                          ║")
    print(f"║              Setup Complete! 🎉                          ║")
    print(f"║                                                          ║")
    print(f"╚══════════════════════════════════════════════════════════╝{Colors.RESET}")
    print()

    print(f"{Colors.BOLD}Access Information:{Colors.RESET}")
    print(f"  {Colors.CYAN}URL:{Colors.RESET}      http://localhost:{port}")
    print(f"  {Colors.CYAN}Username:{Colors.RESET} Administrator")
    print(f"  {Colors.CYAN}Password:{Colors.RESET} {Colors.BOLD}{admin_password}{Colors.RESET}")
    print()

    print(f"{Colors.BOLD}Configuration:{Colors.RESET}")
    print(f"  {Colors.CYAN}Preset:{Colors.RESET}   {preset}")
    print(f"  {Colors.CYAN}Version:{Colors.RESET}  {frappe_version}")
    print()

    print(f"{Colors.BOLD}Management Commands:{Colors.RESET}")
    print(f"  {Colors.CYAN}Status:{Colors.RESET}    docker compose ps")
    print(f"  {Colors.CYAN}Logs:{Colors.RESET}      docker compose logs -f backend")
    print(f"  {Colors.CYAN}Shell:{Colors.RESET}     docker compose exec backend bash")
    print(f"  {Colors.CYAN}Bench:{Colors.RESET}     docker compose exec backend bench --help")
    print(f"  {Colors.CYAN}Stop:{Colors.RESET}      docker compose stop")
    print()

    print(f"{Colors.YELLOW}⚠  Save your password somewhere safe!{Colors.RESET}")
    print()


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='Frappe Quickstart - Zero configuration Docker setup for development',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python start.py                                    # Start with ERPNext v15
  python start.py --preset minimal                  # Start Frappe only
  python start.py --preset erp --frappe-version v14 # ERPNext v14
  python start.py --preset crm --port 8081          # CRM on port 8081
  python start.py --destroy                         # Destroy environment

Available presets:
  minimal, erp, crm, education, ecommerce, healthcare

Management:
  python start.py --destroy         # Remove all containers and volumes
  docker compose ps                 # Check service status
  docker compose logs -f backend    # View logs
  docker compose exec backend bash  # Shell access
        """
    )

    parser.add_argument(
        '--preset',
        default='erp',
        help='Preset configuration to use (default: erp)'
    )

    parser.add_argument(
        '--frappe-version',
        default='version-15',
        help='Frappe version/branch to install (default: version-15)'
    )

    parser.add_argument(
        '--port',
        type=int,
        help='Port number to use (default: auto-detect from 8080)'
    )

    parser.add_argument(
        '--no-browser',
        action='store_true',
        help='Do not open browser after setup'
    )

    parser.add_argument(
        '--destroy',
        action='store_true',
        help='Destroy existing environment (remove all containers and volumes) and exit'
    )

    args = parser.parse_args()

    # Handle destroy command
    if args.destroy:
        print()
        print_header("Destroying Environment")
        print()
        print_warning("This will remove ALL containers and volumes!")
        print()

        try:
            response = input("Are you sure? Type 'yes' to confirm: ")
            if response.lower() != 'yes':
                print_info("Cancelled")
                sys.exit(0)
        except KeyboardInterrupt:
            print()
            print_info("Cancelled")
            sys.exit(0)

        print()
        if destroy_environment():
            print()
            print_success("Environment destroyed successfully")
            print_info("Run 'python start.py' to set up again")
            print()
            sys.exit(0)
        else:
            sys.exit(1)

    # Print header
    print()
    print(f"{Colors.BOLD}{Colors.CYAN}╔══════════════════════════════════════════════════════════╗")
    print(f"║                                                          ║")
    print(f"║           Frappe Quickstart - Setup Wizard              ║")
    print(f"║                                                          ║")
    print(f"╚══════════════════════════════════════════════════════════╝{Colors.RESET}")
    print()
    print(f"{Colors.CYAN}From zero to Frappe in 3 minutes. No configuration required.{Colors.RESET}")
    print()

    # Step 1: Check dependencies
    print_header("Checking Dependencies")
    if not check_dependencies():
        print()
        print_error("Missing required dependencies")
        print()
        print("Please install:")
        print("  • Docker: https://docs.docker.com/get-docker/")
        print("  • Docker Compose: https://docs.docker.com/compose/install/")
        print()
        sys.exit(1)

    # Step 2: Validate preset
    print()
    print_header("Validating Configuration")

    try:
        apps = load_preset(args.preset)
        print_success(f"Loaded preset '{args.preset}' with {len(apps)} app(s)")
    except (FileNotFoundError, ValueError, json.JSONDecodeError) as e:
        print()
        print_error(str(e))
        sys.exit(1)

    # Step 3: Find available port
    print()
    print_header("Configuring Network")

    if args.port:
        port = args.port
        print_info(f"Using specified port: {port}")
    else:
        try:
            port = find_available_port()
            print_success(f"Port {port} is available")
        except RuntimeError as e:
            print_error(str(e))
            sys.exit(1)

    # Step 4: Generate passwords
    print()
    print_header("Generating Credentials")

    admin_password = generate_password(16)
    db_password = generate_password(16)

    print_success("Administrator password generated")
    print_success("Database password generated")

    # Step 5: Create configuration files
    print()
    print_header("Creating Configuration")

    create_env_file(port, admin_password, db_password, args.preset, args.frappe_version, apps)
    print_success(".env file created")

    # Save apps.json
    apps_json_path = Path('apps.json')
    apps_json_path.write_text(json.dumps(apps, indent=2))
    print_success(f"apps.json created from {args.preset} preset")

    # Step 6: Clone apps to local directory
    print()
    print_header("Setting Up Apps")
    print_info("Cloning apps to local directory for development...")
    print()

    if not clone_apps_to_host(apps, args.frappe_version):
        print()
        print_error("Failed to clone apps")
        sys.exit(1)

    print()
    print_success("Apps cloned successfully")

    # Step 7: Build Docker image
    print()
    print_header("Building Docker Image")
    print_info(f"Building with Frappe {args.frappe_version}")
    print_info("This may take 5-10 minutes on first run...")
    print()

    if not build_docker_image(apps, args.frappe_version):
        print()
        print_error("Docker build failed")
        print()
        print("Common issues:")
        print("  • Network connectivity problems")
        print("  • Insufficient disk space")
        print("  • Invalid apps.json configuration")
        print()
        sys.exit(1)

    print()
    print_success("Build complete")

    # Step 7: Start services
    print()
    print_header("Starting Services")

    # Always clean start (remove volumes) to avoid conflicts with existing sites
    if not start_docker_services(clean_start=True):
        print_error("Failed to start Docker services")
        sys.exit(1)

    print_success("Services started")

    # Step 8: Wait for site creation
    print()
    print_header("Creating Site")
    print_info("This may take 2-3 minutes...")
    print()

    if not wait_for_site_creation():
        print()
        print_error("Site creation failed or timed out")
        print()
        print("Check logs with:")
        print("  docker compose logs create-site")
        print("  docker compose logs backend")
        print()
        sys.exit(1)

    print()
    print_success("Site created successfully")

    # Step 9: Open browser
    if not args.no_browser:
        print()
        print_step("Opening browser...")

        try:
            import webbrowser
            time.sleep(2)  # Give services a moment to stabilize
            webbrowser.open(f'http://localhost:{port}')
            print_success("Browser opened")
        except Exception:
            print_warning("Could not open browser automatically")
            print_info(f"Please open: http://localhost:{port}")

    # Step 10: Print completion message
    print_completion_message(port, admin_password, args.preset, args.frappe_version)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print()
        print_warning("Setup cancelled by user")
        sys.exit(130)
    except Exception as e:
        print()
        print_error(f"Unexpected error: {e}")
        sys.exit(1)
