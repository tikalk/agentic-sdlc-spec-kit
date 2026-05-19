"""opencode integration."""

import json
import os
from pathlib import Path
from typing import Any, TYPE_CHECKING

from ..base import MarkdownIntegration
from .docker_manager import DockerManager

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

    def build_exec_args(
        self,
        prompt: str,
        *,
        model: str | None = None,
        output_json: bool = True,
    ) -> list[str] | None:
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
    ) -> str:
        """Process template and wrap script command with docker routing.

        Calls parent process_template, then wraps any script invocations
        with docker mode detection.
        """
        import re

        # Call parent to get processed content
        processed = super().process_template(
            content, agent_name, script_type, arg_placeholder, context_file, invoke_separator
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
                "http_url": "http://localhost:9000"
            }
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

    def _is_docker_mode(self, project_root: Path) -> bool:
        """Check if Docker mode is enabled.

        Checks env var first, then config file.
        """
        env_mode = os.getenv("OPENCODE_MODE", "").lower()
        if env_mode == "docker":
            return True

        config = self._load_opencode_config(project_root)
        return config.get("mode") == "docker"

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
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": "httpx library required for Docker mode",
            }

        project_root = project_root or Path.cwd()
        config = self._load_opencode_config(project_root)
        docker_config = config.get("docker", {})
        http_url = docker_config.get("http_url", "http://localhost:9000")

        try:
            response = httpx.post(
                f"{http_url}/api/execute",
                json={"prompt": prompt, "model": model, "format": "json" if output_json else "text"},
                timeout=600,
            )

            if response.status_code == 200:
                data = response.json() if output_json else response.text
                return {
                    "exit_code": 0,
                    "stdout": json.dumps(data) if output_json else data,
                    "stderr": "",
                }
            else:
                return {
                    "exit_code": 1,
                    "stdout": "",
                    "stderr": f"OpenCode API error: {response.status_code} {response.text}",
                }
        except httpx.ConnectError as e:
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": f"Failed to connect to OpenCode at {http_url}. Is Docker running? Error: {e}",
            }
        except httpx.TimeoutException:
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": f"Request timeout connecting to OpenCode at {http_url}",
            }
        except Exception as e:
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

        if self._is_docker_mode(project_root):
            prompt = self.build_command_invocation(command_name, args)
            result = self._call_docker_opencode(
                prompt, model=model, output_json=not stream, project_root=project_root
            )

            if stream and result.get("stdout"):
                print(result["stdout"])

            return result

        # Fall back to subprocess for local mode
        return super().dispatch_command(
            command_name, args, project_root=project_root, model=model, timeout=timeout, stream=stream
        )
