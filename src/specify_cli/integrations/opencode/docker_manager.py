"""Docker container management for OpenCode."""

from __future__ import annotations

import json
import shutil
import subprocess
import time
from pathlib import Path
from typing import Any, Optional

import httpx


def ensure_opencode_docker_assets(project_root: Path) -> Path:
    """Copy packaged Dockerfile and compose file into ``.specify/`` if missing.

    Returns the absolute path to ``docker-compose.yml`` under ``.specify/``.
    """
    template_dir = Path(__file__).resolve().parent / "docker"
    specify_dir = project_root / ".specify"
    specify_dir.mkdir(parents=True, exist_ok=True)

    for name in ("Dockerfile", "docker-compose.yml"):
        src = template_dir / name
        dst = specify_dir / name
        if not dst.exists() and src.exists():
            shutil.copy(src, dst)

    return (specify_dir / "docker-compose.yml").resolve()


def _resolve_compose_file(compose_file: str | Path, project_root: Path | None) -> Path:
    p = Path(compose_file)
    if p.is_absolute():
        return p.resolve()
    base = project_root if project_root is not None else Path.cwd()
    return (base / p).resolve()


def _parse_compose_ps_json(stdout: str) -> list[dict[str, Any]]:
    """Parse ``docker compose ps --format json`` output (array or NDJSON)."""
    text = stdout.strip()
    if not text:
        return []
    try:
        data = json.loads(text)
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            return [data]
    except json.JSONDecodeError:
        pass
    services: list[dict[str, Any]] = []
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
            if isinstance(row, dict):
                services.append(row)
        except json.JSONDecodeError:
            continue
    return services


class DockerManager:
    """Manage OpenCode Docker container lifecycle."""

    def __init__(
        self,
        compose_file: str | Path = "docker-compose.yml",
        container_name: str = "opencode-dev",
        http_url: str = "http://localhost:9000",
        timeout: int = 60,
        *,
        project_root: Path | None = None,
    ):
        self.compose_file = _resolve_compose_file(compose_file, project_root)
        self.container_name = container_name
        self.http_url = http_url.rstrip("/")
        self.timeout = timeout
        self._project_root = project_root
        self._compose_prefix: list[str] | None = None

    def _compose_cmd_prefix(self) -> list[str]:
        """``docker compose -f <file>`` or legacy ``docker-compose -f <file>``."""
        if self._compose_prefix is not None:
            return self._compose_prefix
        compose_arg = str(self.compose_file)
        if shutil.which("docker"):
            probe = subprocess.run(
                ["docker", "compose", "version"],
                capture_output=True,
                text=True,
                timeout=10,
            )
            if probe.returncode == 0:
                self._compose_prefix = ["docker", "compose", "-f", compose_arg]
                return self._compose_prefix
        if shutil.which("docker-compose"):
            self._compose_prefix = ["docker-compose", "-f", compose_arg]
            return self._compose_prefix
        raise FileNotFoundError(
            "Neither 'docker compose' nor 'docker-compose' is available. Install Docker."
        )

    def _compose(self, *compose_args: str) -> list[str]:
        return [*self._compose_cmd_prefix(), *compose_args]

    def docker_up(self) -> bool:
        """Start Docker container and wait until healthy.

        Returns:
            True if successful, False otherwise
        """
        try:
            result = subprocess.run(
                self._compose("up", "-d"),
                cwd=str(self.compose_file.parent),
                capture_output=True,
                text=True,
                timeout=120,
            )
            if result.returncode != 0:
                print(f"Error starting Docker: {result.stderr}")
                return False

            return self.check_container_ready()
        except subprocess.TimeoutExpired:
            print("Timeout starting Docker container")
            return False
        except FileNotFoundError as e:
            print(str(e))
            return False

    def docker_down(self) -> bool:
        """Stop Docker container.

        Returns:
            True if successful, False otherwise
        """
        try:
            result = subprocess.run(
                self._compose("down"),
                cwd=str(self.compose_file.parent),
                capture_output=True,
                text=True,
                timeout=60,
            )
            if result.returncode != 0:
                print(f"Error stopping Docker: {result.stderr}")
                return False
            return True
        except subprocess.TimeoutExpired:
            print("Timeout stopping Docker container")
            return False
        except FileNotFoundError as e:
            print(str(e))
            return False

    def docker_status(self) -> Optional[dict]:
        """Get Docker container status.

        Returns:
            dict with container info or None if error
        """
        try:
            result = subprocess.run(
                self._compose("ps", "--format", "json"),
                cwd=str(self.compose_file.parent),
                capture_output=True,
                text=True,
                timeout=15,
            )
            if result.returncode != 0:
                return None

            services = _parse_compose_ps_json(result.stdout)
            if not services:
                return {"status": "not-running", "running": False}

            # Prefer the opencode service / configured container name
            service = None
            for row in services:
                name = row.get("Name") or row.get("Service") or ""
                if self.container_name in str(name) or row.get("Service") == "opencode":
                    service = row
                    break
            service = service or services[0]

            state = service.get("State", "unknown")
            return {
                "status": state,
                "name": service.get("Service", ""),
                "running": state == "running",
                "url": self.http_url if state == "running" else None,
            }
        except (subprocess.TimeoutExpired, FileNotFoundError):
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

        base = self.http_url.rstrip("/")
        while time.time() - start_time < timeout:
            ready = False
            for path in ("/global/health", "/health"):
                try:
                    response = httpx.get(f"{base}{path}", timeout=2)
                    if response.status_code == 200:
                        ready = True
                        break
                except Exception:
                    pass
            if ready:
                print(f"✓ OpenCode container ready at {self.http_url}")
                return True

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
                self._compose("logs", "--tail", str(lines)),
                cwd=str(self.compose_file.parent),
                capture_output=True,
                text=True,
                timeout=15,
            )
            return result.stdout if result.returncode == 0 else result.stderr
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return ""
