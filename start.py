#!/usr/bin/env python3

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
    RESET = '\033[0m'
    BOLD = '\033[1m'
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'

    @staticmethod
    def disable():
        Colors.RESET = Colors.BOLD = Colors.RED = ''
        Colors.GREEN = Colors.YELLOW = Colors.BLUE = Colors.CYAN = ''


if not sys.stdout.isatty():
    Colors.disable()


def print_header(text: str):
    print(f"\n{Colors.BOLD}{Colors.CYAN}═══ {text} ═══{Colors.RESET}")


def print_step(text: str):
    print(f"{Colors.BLUE}▶{Colors.RESET} {text}")


def print_success(text: str):
    print(f"{Colors.GREEN}✓{Colors.RESET} {text}")


def print_error(text: str):
    print(f"{Colors.RED}✗{Colors.RESET} {text}", file=sys.stderr)


def print_info(text: str):
    print(f"{Colors.CYAN}ℹ{Colors.RESET} {text}")


def print_warning(text: str):
    print(f"{Colors.YELLOW}⚠{Colors.RESET} {text}")


def generate_password(length: int = 16) -> str:
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))


def find_available_port(start_port: int = 8080, max_tries: int = 100) -> int:
    for port in range(start_port, start_port + max_tries):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.bind(('', port))
                return port
        except OSError:
            continue

    raise RuntimeError(f"No available port found in range {start_port}-{start_port + max_tries}")


def check_dependencies() -> bool:
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
    presets_dir = Path('presets')
    if not presets_dir.exists():
        return []

    return [p.stem for p in presets_dir.glob('*.json')]


def load_preset(preset_name: str) -> List[Dict[str, str]]:
    preset_path = Path('presets') / f'{preset_name}.json'

    if not preset_path.exists():
        available = ', '.join(get_available_presets())
        raise FileNotFoundError(
            f"Preset '{preset_name}' not found.\n"
            f"Available presets: {available}"
        )

    with preset_path.open() as f:
        apps = json.load(f)

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
    app_names = []
    for app in apps:
        url = app.get('url', '')
        app_name = url.rstrip('/').split('/')[-1].replace('.git', '')
        if app_name:
            app_names.append(app_name)

    install_apps = ','.join(app_names) if app_names else ''

    env_content = f"""FRAPPE_VERSION={frappe_version}
SITE_NAME=frontend

ADMIN_PASSWORD={admin_password}
DB_ROOT_PASSWORD={db_password}
MYSQL_ROOT_PASSWORD={db_password}
MARIADB_ROOT_PASSWORD={db_password}

PORT={port}

PROJECT_NAME=frappe_quickstart
IMAGE_NAME=frappe_quickstart:latest

PRESET={preset}

INSTALL_APPS={install_apps}
"""

    Path('.env').write_text(env_content)


def build_docker_image(apps: List[Dict[str, str]], frappe_version: str) -> bool:
    apps_json_str = json.dumps(apps, indent=2)
    apps_base64 = base64.b64encode(apps_json_str.encode()).decode()

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
    apps_dir = Path('apps')

    if not apps_dir.exists():
        print_step("Creating apps directory...")
        apps_dir.mkdir(exist_ok=True)
        print_success("Apps directory created")

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

    for app in apps:
        url = app.get('url', '')
        branch = app.get('branch', 'main')

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
    if clean_start:
        print_step("Cleaning existing volumes...")
        subprocess.run(
            ['docker', 'compose', 'down', '-v', '--remove-orphans'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        print_success("Volumes cleaned")
    else:
        subprocess.run(
            ['docker', 'compose', 'down'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

    try:
        result = subprocess.run(
            ['docker', 'compose', 'up', '-d'],
            check=True
        )
        return result.returncode == 0
    except subprocess.CalledProcessError:
        return False


def wait_for_site_creation(timeout: int = 300) -> bool:
    start_time = time.time()
    last_elapsed_shown = 0
    dots = 0

    while time.time() - start_time < timeout:
        elapsed = int(time.time() - start_time)

        result = subprocess.run(
            ['docker', 'compose', 'ps', '--all', '--format', 'json'],
            capture_output=True,
            text=True
        )

        if result.returncode == 0 and result.stdout.strip():
            try:
                lines = [line for line in result.stdout.strip().split('\n') if line]
                for line in lines:
                    try:
                        status_data = json.loads(line)
                        service = status_data.get('Service', '')

                        if service == 'create-site':
                            state = status_data.get('State', '')
                            exit_code = status_data.get('ExitCode', -1)

                            if elapsed - last_elapsed_shown >= 10:
                                dots = (dots + 1) % 4
                                dot_str = '.' * dots
                                print(f"\r{Colors.CYAN}ℹ{Colors.RESET} Site creation in progress{dot_str}{'   '} ({elapsed}s)", end='', flush=True)
                                last_elapsed_shown = elapsed

                            if state == 'exited' and exit_code == 0:
                                print()
                                return True

                            if state == 'exited' and exit_code != 0:
                                print()
                                print_error(f"Site creation failed with exit code {exit_code}")
                                print_info("View logs with: docker compose logs create-site")
                                return False

                    except json.JSONDecodeError:
                        continue

            except Exception:
                pass

        time.sleep(3)

    print()
    print_error(f"Site creation timed out after {timeout} seconds")
    return False


def print_completion_message(port: int, admin_password: str, preset: str, frappe_version: str):
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
    parser = argparse.ArgumentParser(
        description='Frappe Quickstart - Zero configuration Docker setup for development',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python start.py
  python start.py --preset minimal
  python start.py --preset erp --frappe-version v14
  python start.py --preset crm --port 8081
  python start.py --destroy

Available presets:
  minimal, erp, crm, education, ecommerce, healthcare

Management:
  python start.py --destroy
  docker compose ps
  docker compose logs -f backend
  docker compose exec backend bash
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

    print()
    print(f"{Colors.BOLD}{Colors.CYAN}╔══════════════════════════════════════════════════════════╗")
    print(f"║                                                          ║")
    print(f"║           Frappe Quickstart - Setup Wizard              ║")
    print(f"║                                                          ║")
    print(f"╚══════════════════════════════════════════════════════════╝{Colors.RESET}")
    print()
    print(f"{Colors.CYAN}From zero to Frappe in 3 minutes. No configuration required.{Colors.RESET}")
    print()

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

    print()
    print_header("Validating Configuration")

    try:
        apps = load_preset(args.preset)
        print_success(f"Loaded preset '{args.preset}' with {len(apps)} app(s)")
    except (FileNotFoundError, ValueError, json.JSONDecodeError) as e:
        print()
        print_error(str(e))
        sys.exit(1)

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

    print()
    print_header("Generating Credentials")

    admin_password = generate_password(16)
    db_password = generate_password(16)

    print_success("Administrator password generated")
    print_success("Database password generated")

    print()
    print_header("Creating Configuration")

    create_env_file(port, admin_password, db_password, args.preset, args.frappe_version, apps)
    print_success(".env file created")

    apps_json_path = Path('apps.json')
    apps_json_path.write_text(json.dumps(apps, indent=2))
    print_success(f"apps.json created from {args.preset} preset")

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

    print()
    print_header("Starting Services")

    if not start_docker_services(clean_start=True):
        print_error("Failed to start Docker services")
        sys.exit(1)

    print_success("Services started")

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

    if not args.no_browser:
        print()
        print_step("Opening browser...")

        try:
            import webbrowser
            time.sleep(2)
            webbrowser.open(f'http://localhost:{port}')
            print_success("Browser opened")
        except Exception:
            print_warning("Could not open browser automatically")
            print_info(f"Please open: http://localhost:{port}")

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
