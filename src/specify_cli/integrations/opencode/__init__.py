"""opencode integration."""

import json
import os
import sys
from pathlib import Path
from typing import Any, TYPE_CHECKING

from ..base import MarkdownIntegration
from .docker_manager import DockerManager, ensure_opencode_docker_assets

if TYPE_CHECKING:
    from ..manifest import IntegrationManifest


class OpencodeIntegration(MarkdownIntegration):
    key = "opencode"
    config = {
        "name": "opencode",
        "folder": ".opencode/",
        "commands_subdir": "commands",
        "install_url": "https://opencode.ai",
        "requires_cli": True,
    }
    registrar_config = {
        "dir": ".opencode/commands",
        "legacy_dir": ".opencode/command",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": ".md",
    }
    context_file = "AGENTS.md"

    _DOCKER_LOG_PREFIX = "[specify][opencode-docker]"

    @classmethod
    def _docker_trace(cls, message: str) -> None:
        """Emit a visible trace line for OpenCode Docker routing (stderr, flushed)."""
        print(f"{cls._DOCKER_LOG_PREFIX} {message}", file=sys.stderr, flush=True)

    def build_exec_args(
        self,
        prompt: str,
        *,
        model: str | None = None,
        output_json: bool = True,
        project_root: Path | None = None,
    ) -> list[str] | None:
        # Check if Docker mode is enabled - if so, return synthetic args
        # to pass the CLI check in CommandStep._try_dispatch()
        check_path = project_root or Path.cwd()
        if self._is_docker_mode(check_path):
            # Return synthetic args indicating Docker mode
            # dispatch_command will route to HTTP API instead
            return [self.key, "--docker-mode", prompt]

        # Fall back to local CLI args (requires opencode to be installed)
        args = [self.key, "run"]

        message = prompt
        if prompt.startswith("/"):
            command, _, remainder = prompt[1:].partition(" ")
            if command:
                args.extend(["--command", command])
                message = remainder

        if model:
            args.extend(["-m", model])
        if output_json:
            args.extend(["--format", "json"])
        if message:
            args.append(message)
        return args

    @staticmethod
    def _wrap_script_for_docker(script_command: str) -> str:
        """Wrap bash script with docker routing logic.

        Injects a check at the beginning that routes to docker if enabled,
        otherwise runs locally.
        """
        # Escape for inline shell
        escaped = script_command.replace('"', '\\"')
        wrapper = (
            '[ "$OPENCODE_MODE" = "docker" ] || '
            '([ -f .specify/opencode.json ] && grep -q \'"mode"\\s*:\\s*"docker"\' .specify/opencode.json) && '
            'echo "Routing to OpenCode Docker..." >&2 || true; '
            f'{escaped}'
        )
        return wrapper

    def process_template(
        self,
        content: str,
        agent_name: str,
        script_type: str,
        arg_placeholder: str = "$ARGUMENTS",
        context_file: str = "",
        invoke_separator: str = ".",
        project_root: Path | None = None,
    ) -> str:
        """Process template and wrap script command with docker routing.

        Calls parent process_template, then wraps any script invocations
        with docker mode detection.
        """
        import re

        # Call parent to get processed content
        processed = super().process_template(
            content,
            agent_name,
            script_type,
            arg_placeholder,
            context_file,
            invoke_separator,
            project_root=project_root,
        )

        # Find and wrap script invocations in code blocks
        # Pattern: bash code block with a script path
        script_pattern = re.compile(
            r'(```bash\s*\n)(\.specify/scripts/\S+[^\n]*)',
            re.MULTILINE
        )

        def replace_script(match):
            opening = match.group(1)
            script = match.group(2)
            wrapped = self._wrap_script_for_docker(script)
            return opening + wrapped

        processed = script_pattern.sub(replace_script, processed)
        return processed

    def setup(
        self,
        project_root: Path,
        manifest: "IntegrationManifest",
        parsed_options: dict[str, Any] | None = None,
        **opts: Any,
    ) -> list[Path]:
        """Setup opencode integration.

        Calls parent setup() for command templates, then creates
        .specify/opencode.json with docker mode enabled.
        """
        created = super().setup(project_root, manifest, parsed_options=parsed_options, **opts)

        # Create .specify/opencode.json with docker mode config
        specify_dir = project_root / ".specify"
        specify_dir.mkdir(parents=True, exist_ok=True)

        config_path = specify_dir / "opencode.json"
        config_content = {
            "mode": "docker",
            "docker": {
                "http_url": "http://localhost:9000",
                "compose_file": "./.specify/docker-compose.yml",
                "container_name": "opencode-dev",
                "container_workspace": "/workspace",
            },
        }

        config_text = json.dumps(config_content, indent=2)
        config_path.write_text(config_text + "\n", encoding="utf-8")

        # Record in manifest if file didn't exist
        if config_path not in created:
            self.record_file_in_manifest(config_path, project_root, manifest)
            created.append(config_path)

        return created

    def _load_opencode_config(self, project_root: Path) -> dict[str, Any]:
        """Load OpenCode configuration from .specify/opencode.json.

        Returns dict with mode, docker, and remote settings.
        Defaults to local subprocess mode if no config exists.
        """
        config_path = project_root / ".specify" / "opencode.json"
        if config_path.exists():
            try:
                with open(config_path) as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError):
                pass

        return {"mode": "local"}

    @staticmethod
    def is_docker_mode_exec_args(args: list[str] | None) -> bool:
        """Check if build_exec_args returned Docker mode synthetic args.

        Used by CommandStep to detect when to skip local CLI checks.
        """
        return bool(args and "--docker-mode" in args)

    def _is_docker_mode(self, project_root: Path) -> bool:
        """Check if Docker mode is enabled.

        Checks env var first, then config file.
        """
        env_mode = os.getenv("OPENCODE_MODE", "").lower()
        if env_mode == "docker":
            return True

        config = self._load_opencode_config(project_root)
        return config.get("mode") == "docker"

    @staticmethod
    def _split_opencode_slash_prompt(prompt: str) -> tuple[str, str]:
        """Split ``/speckit.foo bar`` → (``speckit.foo``, ``bar``) for OpenCode ``POST /session/:id/command``."""
        p = prompt.strip()
        if not p:
            return "help", ""
        if p.startswith("/"):
            p = p[1:]
        head, _, tail = p.partition(" ")
        cmd = head.strip() or "help"
        return cmd, tail.strip()

    @staticmethod
    def _opencode_http_command_name(stem: str) -> str:
        """Map slash-command stem to the name OpenCode's HTTP ``/session/.../command`` expects.

        Installed markdown commands use ``/speckit.*``, while the server typically registers
        ``spec.*`` for the core Spec Kit commands. A few commands keep the ``speckit.`` prefix.
        """
        overrides: dict[str, str] = {
            "speckit.taskstoissues": "speckit.taskstoissues",
        }
        if stem in overrides:
            return overrides[stem]
        if stem.startswith("speckit."):
            return "spec." + stem[len("speckit.") :]
        return stem

    def _call_docker_opencode(
        self,
        prompt: str,
        *,
        model: str | None = None,
        output_json: bool = True,
        project_root: Path | None = None,
    ) -> dict[str, Any]:
        """Call OpenCode via Docker HTTP API.

        Returns dict with exit_code, stdout, stderr.
        """
        try:
            import httpx
        except ImportError:
            self._docker_trace("httpx is not installed; cannot call OpenCode Docker HTTP API")
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": "httpx library required for Docker mode",
            }

        project_root = (project_root or Path.cwd()).resolve()
        config = self._load_opencode_config(project_root)
        docker_config = config.get("docker", {})
        base = str(docker_config.get("http_url", "http://localhost:9000")).rstrip("/")
        workspace = str(docker_config.get("container_workspace", "/workspace"))

        cmd, arguments = self._split_opencode_slash_prompt(prompt)
        api_cmd = self._opencode_http_command_name(cmd)
        if api_cmd != cmd:
            self._docker_trace(f"command stem mapped for HTTP API: {cmd!r} -> {api_cmd!r}")
        preview = prompt if len(prompt) <= 280 else f"{prompt[:280]}…"
        self._docker_trace(
            f"OpenCode HTTP project={project_root} base={base} workspace={workspace!r}"
        )
        self._docker_trace(
            f"session API: slash={cmd!r} http_command={api_cmd!r} arguments={arguments!r} preview={preview!r}"
        )

        timeout = httpx.Timeout(600.0)
        try:
            with httpx.Client(timeout=timeout) as client:
                self._docker_trace(
                    f"POST {base}/session?directory={workspace} (create OpenCode session)"
                )
                sr = client.post(
                    f"{base}/session",
                    params={"directory": workspace},
                    json={"title": "Specify CLI"},
                )
                self._docker_trace(f"session HTTP status={sr.status_code}")
                if sr.status_code not in (200, 201):
                    return {
                        "exit_code": 1,
                        "stdout": "",
                        "stderr": f"OpenCode session create failed: {sr.status_code} {sr.text}",
                    }
                try:
                    session = sr.json()
                except json.JSONDecodeError:
                    return {
                        "exit_code": 1,
                        "stdout": "",
                        "stderr": f"OpenCode session create returned non-JSON: {sr.text[:500]}",
                    }
                sid = session.get("id")
                if not sid:
                    return {
                        "exit_code": 1,
                        "stdout": "",
                        "stderr": f"OpenCode session response missing id: {session!r}",
                    }
                self._docker_trace(
                    f"session_id={sid!r} — tail container logs during the next request "
                    f"(`docker compose -f .specify/docker-compose.yml logs -f`)"
                )

                body: dict[str, Any] = {"command": api_cmd, "arguments": arguments}
                if model:
                    body["model"] = model

                cmd_url = f"{base}/session/{sid}/command"
                self._docker_trace(
                    f"POST {cmd_url}?directory={workspace} (execute slash command on server)"
                )
                cr = client.post(cmd_url, params={"directory": workspace}, json=body)
                self._docker_trace(
                    f"command HTTP status={cr.status_code} bytes={len(cr.content)}"
                )

                if cr.status_code == 200:
                    if output_json:
                        payload = cr.json()
                        out = json.dumps(payload)
                    else:
                        out = cr.text
                    self._docker_trace("OpenCode Docker slash command finished OK (exit_code=0)")
                    return {"exit_code": 0, "stdout": out, "stderr": ""}
                self._docker_trace(
                    f"OpenCode command API error status={cr.status_code} body_snip="
                    f"{cr.text[:400]!r}"
                )
                return {
                    "exit_code": 1,
                    "stdout": "",
                    "stderr": f"OpenCode command failed: {cr.status_code} {cr.text}",
                }
        except httpx.ConnectError as e:
            self._docker_trace(f"connect_error base={base!r} detail={e!r}")
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": f"Failed to connect to OpenCode at {base}. Is Docker running? Error: {e}",
            }
        except httpx.TimeoutException:
            self._docker_trace(f"timeout base={base!r}")
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": f"Request timeout connecting to OpenCode at {base}",
            }
        except Exception as e:
            self._docker_trace(f"unexpected_error type={type(e).__name__!r} detail={e!r}")
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": f"Error calling OpenCode: {e}",
            }

    def dispatch_command(
        self,
        command_name: str,
        args: str = "",
        *,
        project_root: Path | None = None,
        model: str | None = None,
        timeout: int = 600,
        stream: bool = True,
    ) -> dict[str, Any]:
        """Dispatch command to OpenCode.

        Routes to Docker HTTP API if Docker mode is enabled,
        otherwise uses subprocess as before.
        """
        project_root = project_root or Path.cwd()

        # Shell commands (docker-up/down/status) must run locally — they manage the
        # Docker container, so they bypass the HTTP API and go straight to DockerManager.
        if command_name in ("docker-up", "docker-down", "docker-status"):
            return self.dispatch_shell_command(command_name, project_root=project_root)

        if self._is_docker_mode(project_root):
            root = project_root.resolve()
            prompt = self.build_command_invocation(command_name, args)
            self._docker_trace(
                f"Docker mode ON — dispatching speckit command={command_name!r} via HTTP "
                f"(not local opencode CLI) project={root}"
            )
            if "implement" in command_name.lower():
                self._docker_trace(
                    "implement detected — this request is proxied to the OpenCode container "
                    "(watch `docker compose logs` for session / command activity on the server)"
                )
            result = self._call_docker_opencode(
                prompt, model=model, output_json=not stream, project_root=project_root
            )

            if stream and result.get("stdout"):
                print(result["stdout"])

            if result.get("exit_code") == 0:
                self._docker_trace(
                    f"dispatch_command complete command={command_name!r} exit_code=0"
                )
            else:
                self._docker_trace(
                    f"dispatch_command complete command={command_name!r} "
                    f"exit_code={result.get('exit_code')} stderr={str(result.get('stderr', ''))[:500]!r}"
                )

            return result

        # Fall back to subprocess for local mode
        return super().dispatch_command(
            command_name, args, project_root=project_root, model=model, timeout=timeout, stream=stream
        )

    def dispatch_shell_command(
        self,
        command_name: str,
        project_root: Path | None = None,
    ) -> dict[str, Any]:
        """Dispatch a shell command to OpenCode.

        Handles special subcommands like docker-up, docker-down, docker-status.
        """
        project_root = project_root or Path.cwd()

        if command_name == "docker-up":
            return self._dispatch_docker_up(project_root)
        elif command_name == "docker-down":
            return self._dispatch_docker_down(project_root)
        elif command_name == "docker-status":
            return self._dispatch_docker_status(project_root)
        else:
            return {"exit_code": 1, "stdout": "", "stderr": f"Unknown shell command: {command_name}"}

    def _dispatch_docker_up(self, project_root: Path) -> dict[str, Any]:
        """Dispatch the docker-up shell command."""
        ensure_opencode_docker_assets(project_root)

        config_path = project_root / ".specify" / "opencode.json"
        full: dict[str, Any] = {}
        if config_path.exists():
            try:
                full = json.loads(config_path.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                full = {}

        docker_inner = dict(full.get("docker") or {})
        compose_file = docker_inner.get("compose_file", "./.specify/docker-compose.yml")
        container_name = docker_inner.get("container_name", "opencode-dev")
        http_url = docker_inner.get("http_url", "http://localhost:9000")

        manager = DockerManager(
            compose_file, container_name, http_url, project_root=project_root
        )

        try:
            result: dict[str, Any] = {"exit_code": 0, "stdout": "", "stderr": ""}
            result["stdout"] = f"Starting OpenCode Docker container at {http_url}\n"
            if manager.docker_up():
                full["mode"] = "docker"
                full["docker"] = {
                    **docker_inner,
                    "enabled": True,
                    "compose_file": compose_file,
                    "container_name": container_name,
                    "http_url": http_url,
                }
                config_path.parent.mkdir(parents=True, exist_ok=True)
                config_path.write_text(
                    json.dumps(full, indent=2) + "\n", encoding="utf-8"
                )
                result["stdout"] += f"✓ OpenCode container running at {http_url}\n"
            else:
                result["stderr"] = "Failed to start Docker container"
                result["exit_code"] = 1
            return result
        except Exception as e:
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": f"Error: {str(e)}",
            }

    def _dispatch_docker_down(self, project_root: Path) -> dict[str, Any]:
        """Dispatch the docker-down shell command."""
        config_path = project_root / ".specify" / "opencode.json"
        full: dict[str, Any] = {}
        if config_path.exists():
            try:
                full = json.loads(config_path.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                full = {}

        docker_inner = dict(full.get("docker") or {})
        compose_file = docker_inner.get("compose_file", "./.specify/docker-compose.yml")
        container_name = docker_inner.get("container_name", "opencode-dev")
        http_url = docker_inner.get("http_url", "http://localhost:9000")

        manager = DockerManager(
            compose_file, container_name, http_url, project_root=project_root
        )

        try:
            result: dict[str, Any] = {"exit_code": 0, "stdout": "", "stderr": ""}
            result["stdout"] = f"Stopping OpenCode Docker container at {http_url}\n"
            if manager.docker_down():
                full["mode"] = "local"
                docker_inner["enabled"] = False
                full["docker"] = {**docker_inner}
                config_path.parent.mkdir(parents=True, exist_ok=True)
                config_path.write_text(
                    json.dumps(full, indent=2) + "\n", encoding="utf-8"
                )
                result["stdout"] += "✓ OpenCode container stopped\n"
            else:
                result["stderr"] = "Failed to stop Docker container"
                result["exit_code"] = 1
            return result
        except Exception as e:
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": f"Error: {str(e)}",
            }

    def _dispatch_docker_status(self, project_root: Path) -> dict[str, Any]:
        """Dispatch the docker-status shell command."""
        config_path = project_root / ".specify" / "opencode.json"
        full: dict[str, Any] = {}
        if config_path.exists():
            try:
                full = json.loads(config_path.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                full = {}

        docker_inner = dict(full.get("docker") or {})
        compose_file = docker_inner.get("compose_file", "./.specify/docker-compose.yml")
        container_name = docker_inner.get("container_name", "opencode-dev")
        http_url = docker_inner.get("http_url", "http://localhost:9000")

        manager = DockerManager(
            compose_file, container_name, http_url, project_root=project_root
        )

        try:
            result: dict[str, Any] = {"exit_code": 0, "stdout": "", "stderr": ""}
            status = manager.docker_status()
            if status is None:
                result["stderr"] = "Could not retrieve Docker status"
                result["exit_code"] = 1
                return result

            if status.get("running"):
                result["stdout"] = (
                    f"✓ OpenCode container {status.get('name')} is running at {http_url}\n"
                )
            else:
                result["stdout"] = (
                    f"○ OpenCode container is not running at {http_url}\n"
                )

            logs = manager.get_container_logs(lines=10)
            if logs:
                result["stdout"] += f"\nRecent logs:\n{logs}\n"

            return result
        except Exception as e:
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": f"Error: {str(e)}",
            }
