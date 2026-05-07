"""Docker container management for OpenCode."""

import subprocess
import time
import json
from pathlib import Path
from typing import Optional

import httpx


class DockerManager:
    """Manage OpenCode Docker container lifecycle."""

    def __init__(self, compose_file: str = "docker-compose.yml", container_name: str = "opencode-dev", http_url: str = "http://localhost:9000", timeout: int = 60):
        self.compose_file = Path(compose_file).resolve()
        self.container_name = container_name
        self.http_url = http_url
        self.timeout = timeout

    def docker_up(self) -> bool:
        """Start Docker container and wait until healthy.

        Returns:
            True if successful, False otherwise
        """
        try:
            result = subprocess.run(
                ["docker-compose", "-f", str(self.compose_file), "up", "-d"],
                cwd=self.compose_file.parent,
                capture_output=True,
                text=True,
                timeout=30
            )
            if result.returncode != 0:
                print(f"Error starting Docker: {result.stderr}")
                return False

            # Wait for container to be healthy
            return self.check_container_ready()
        except subprocess.TimeoutExpired:
            print("Timeout starting Docker container")
            return False
        except FileNotFoundError:
            print("docker-compose not found. Please install Docker Desktop or Docker Engine.")
            return False

    def docker_down(self) -> bool:
        """Stop Docker container.

        Returns:
            True if successful, False otherwise
        """
        try:
            result = subprocess.run(
                ["docker-compose", "-f", str(self.compose_file), "down"],
                cwd=self.compose_file.parent,
                capture_output=True,
                text=True,
                timeout=15
            )
            if result.returncode != 0:
                print(f"Error stopping Docker: {result.stderr}")
                return False
            return True
        except subprocess.TimeoutExpired:
            print("Timeout stopping Docker container")
            return False
        except FileNotFoundError:
            print("docker-compose not found")
            return False

    def docker_status(self) -> Optional[dict]:
        """Get Docker container status.

        Returns:
            dict with container info or None if error
        """
        try:
            result = subprocess.run(
                ["docker-compose", "-f", str(self.compose_file), "ps", "--format", "json"],
                cwd=self.compose_file.parent,
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode != 0:
                return None

            services = json.loads(result.stdout) if result.stdout.strip() else []
            if not services:
                return {"status": "not-running"}

            service = services[0]
            return {
                "status": service.get("State", "unknown"),
                "name": service.get("Service", ""),
                "running": service.get("State") == "running",
                "url": self.http_url if service.get("State") == "running" else None
            }
        except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
            return None

    def check_container_ready(self, timeout: Optional[int] = None) -> bool:
        """Poll HTTP endpoint until container is ready.

        Args:
            timeout: seconds to wait (defaults to self.timeout)

        Returns:
            True if container is ready, False if timeout/error
        """
        timeout = timeout or self.timeout
        start_time = time.time()

        while time.time() - start_time < timeout:
            try:
                response = httpx.get(
                    f"{self.http_url}/health",
                    timeout=2
                )
                if response.status_code == 200:
                    print(f"✓ OpenCode container ready at {self.http_url}")
                    return True
            except Exception:
                pass

            time.sleep(2)

        print(f"Timeout waiting for OpenCode container (waited {timeout}s)")
        return False

    def get_container_logs(self, lines: int = 50) -> str:
        """Get recent container logs.

        Args:
            lines: number of log lines to retrieve

        Returns:
            Log output as string
        """
        try:
            result = subprocess.run(
                ["docker-compose", "-f", str(self.compose_file), "logs", "--tail", str(lines)],
                cwd=self.compose_file.parent,
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.stdout if result.returncode == 0 else result.stderr
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return ""
