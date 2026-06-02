"""Dev Container integration."""

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, TYPE_CHECKING

from ..base import MarkdownIntegration

if TYPE_CHECKING:
    from ..manifest import IntegrationManifest


class DevContainerIntegration(MarkdownIntegration):
    key = "devcontainer"
    config = {
        "name": "Dev Container",
        "folder": ".devcontainer/",
        "commands_subdir": "commands",
        "install_url": "https://code.visualstudio.com/docs/devcontainers/devcontainer-cli",
        "requires_cli": False,  # IDE-based, but can use CLI
    }
    registrar_config = {
        "dir": ".devcontainer/commands",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": ".md",
    }
    context_file = ".devcontainer/devcontainer-instructions.md"

    _DEVCONTAINER_LOG_PREFIX = "[specify][devcontainer]"

    @classmethod
    def _devcontainer_trace(cls, message: str) -> None:
        """Emit a visible trace line for Dev Container routing (stderr, flushed)."""
        print(f"{cls._DEVCONTAINER_LOG_PREFIX} {message}", file=sys.stderr, flush=True)

    def build_exec_args(
        self,
        prompt: str,
        *,
        model: str | None = None,
        output_json: bool = True,
        project_root: Path | None = None,
    ) -> list[str] | None:
        # Check if Dev Container mode is enabled - if so, return synthetic args
        # to pass the CLI check in CommandStep._try_dispatch()
        check_path = project_root or Path.cwd()
        if self._is_devcontainer_mode(check_path):
            # Return synthetic args indicating Dev Container mode
            # dispatch_command will route to devcontainer CLI instead
            return [self.key, "--devcontainer-mode", prompt]

        # No local CLI fallback for dev containers
        return None

    @staticmethod
    def _wrap_script_path_for_devcontainer(script_path_with_args: str, shell_type: str) -> str:
        """Wrap script path with devcontainer routing for AI agents.
        
        Creates a simple, clear command that AI agents can execute to run scripts
        in the dev container.
        
        Args:
            script_path_with_args: Path to the script with arguments
            shell_type: 'bash' or 'powershell'
            
        Returns:
            Direct devcontainer exec command (simple and clear for AI)
        """
        # Keep it simple: just wrap with devcontainer exec
        # AI agents will see clear, direct commands
        
        if shell_type == 'bash':
            # Simple, direct command that AI can easily understand and execute
            wrapper = f'devcontainer exec --workspace-folder . bash {script_path_with_args}'
        else:  # powershell
            wrapper = f'devcontainer exec --workspace-folder . powershell {script_path_with_args}'
        
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
        """Process command template with Dev Container-specific routing.
        
        Wraps script invocations so they execute inside the dev container
        when an AI agent (like Claude Code) runs commands via slash commands.
        """
        self._devcontainer_trace(f"Processing template for {agent_name} (script_type={script_type})")
        
        # First, apply standard Markdown processing
        content = super().process_template(
            content=content,
            agent_name=agent_name,
            script_type=script_type,
            arg_placeholder=arg_placeholder,
            context_file=context_file,
            invoke_separator=invoke_separator,
            project_root=project_root,
        )
        
        self._devcontainer_trace("Standard processing complete, applying script wrapping...")

        # After standard processing, {SCRIPT} has been replaced with actual script paths
        # Now wrap those script invocations to route through dev container
        # Pattern matches script paths in backticks: `.specify/scripts/bash/<script>.sh`
        
        import re
        
        # Match both with and without leading backslash escape
        # Patterns: `.specify/...` or `\.specify/...`
        bash_pattern = r'`(\\?\.specify/scripts/bash/[^`]+\.sh[^`]*)`'
        bash_matches = re.findall(bash_pattern, content)
        if bash_matches:
            self._devcontainer_trace(f"Found {len(bash_matches)} bash script references to wrap")
        
        # Wrap bash script paths
        content = re.sub(
            bash_pattern,
            lambda m: f'`{self._wrap_script_path_for_devcontainer(m.group(1).replace("\\", ""), "bash")}`',
            content
        )
        
        # Also match explicit bash commands if present
        content = re.sub(
            r'`bash (\\?\.specify/scripts/bash/[^`]+\.sh[^`]*)`',
            lambda m: f'`{self._wrap_script_path_for_devcontainer(m.group(1).replace("\\", ""), "bash")}`',
            content
        )
        
        # Wrap PowerShell script paths
        ps_pattern = r'`(\\?\.specify/scripts/powershell/[^`]+\.ps1[^`]*)`'
        content = re.sub(
            ps_pattern,
            lambda m: f'`{self._wrap_script_path_for_devcontainer(m.group(1).replace("\\", ""), "powershell")}`',
            content
        )
        
        # Also match explicit powershell commands if present
        content = re.sub(
            r'`powershell (\\?\.specify/scripts/powershell/[^`]+\.ps1[^`]*)`',
            lambda m: f'`{self._wrap_script_path_for_devcontainer(m.group(1).replace("\\", ""), "powershell")}`',
            content
        )
        
        # Debug: check if wrapping actually happened
        if 'devcontainer exec' in content:
            self._devcontainer_trace("✅ Script wrapping successful - devcontainer exec found in output")
            # Show a sample of what was wrapped
            import re
            sample = re.search(r'`devcontainer exec[^`]{0,80}', content)
            if sample:
                self._devcontainer_trace(f"Sample: {sample.group()[:100]}...")
        else:
            self._devcontainer_trace("⚠️  Script wrapping may have failed - no devcontainer exec in output")

        return content

    def setup(
        self,
        project_root: Path,
        manifest: "IntegrationManifest",
        parsed_options: dict[str, Any] | None = None,
        **opts: Any,
    ) -> list[Path]:
        """Set up Dev Container integration.

        Creates:
        1. .devcontainer/commands/ with devcontainer exec wrapping
        2. Command files for ALL AI agents (opencode, claude, cursor, etc.)
        3. Docker configuration (.devcontainer/devcontainer.json)
        4. Context files (AGENTS.md, devcontainer-instructions.md)
        5. .specify/devcontainer.json config
        """
        # Standard Markdown integration setup creates .devcontainer/commands/ files
        created_files = super().setup(project_root, manifest, parsed_options, **opts)

        # Create .specify/devcontainer.json configuration
        self._create_devcontainer_config(project_root)

        # Create .devcontainer/devcontainer.json Docker configuration if it doesn't exist
        force = opts.get("force", False)
        self._create_docker_config(project_root, force)

        # Create context files for AI agents
        self._create_context_file(project_root)
        self._create_agents_md_context(project_root)

        # Create wrapped command files for ALL AI agent directories
        self._setup_all_agent_commands(project_root, manifest, parsed_options, **opts)

        # Safety net: wrap any existing agent files not created by us
        self._wrap_all_agent_commands(project_root)

        return created_files

    def post_preset_install(self, project_root: Path) -> None:
        """Re-wrap agent command files after preset installation.

        Presets (like agentic-sdlc) install their own command files into
        agent directories AFTER setup() runs, overwriting our wrapped
        versions. This method re-applies the devcontainer exec wrapping
        to undo the overwrite.
        """
        self._devcontainer_trace("Re-wrapping agent files after preset installation...")
        self._wrap_all_agent_commands(project_root)
        self._create_agents_md_context(project_root)

    def _create_devcontainer_config(self, project_root: Path) -> None:
        """Create .specify/devcontainer.json configuration file."""
        specify_dir = project_root / ".specify"
        specify_dir.mkdir(parents=True, exist_ok=True)

        config_path = specify_dir / "devcontainer.json"
        config = {
            "mode": "enabled",
            "devcontainer": {
                "workspace_folder": "/workspace",
                "cli_path": "devcontainer",
            },
        }

        with open(config_path, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=2)
            f.write("\n")

        self._devcontainer_trace(f"Created {config_path}")

    def _create_docker_config(self, project_root: Path, force: bool = False) -> None:
        """Create .devcontainer/devcontainer.json Docker configuration file."""
        devcontainer_dir = project_root / ".devcontainer"
        devcontainer_dir.mkdir(parents=True, exist_ok=True)

        docker_config_path = devcontainer_dir / "devcontainer.json"
        
        # Skip if file exists and not forcing
        if docker_config_path.exists() and not force:
            self._devcontainer_trace(f"Docker config already exists at {docker_config_path}")
            return

        docker_config = {
            "name": "Specify Project",
            "image": "mcr.microsoft.com/devcontainers/python:3.11",
            "features": {
                "ghcr.io/devcontainers/features/common-utils:2": {
                    "installZsh": True,
                    "upgradePackages": True,
                },
                "ghcr.io/devcontainers/features/node:1": {
                    "version": "lts"
                },
            },
            "postCreateCommand": "pip install specify-cli",
            "remoteUser": "vscode",
        }

        with open(docker_config_path, "w", encoding="utf-8") as f:
            json.dump(docker_config, f, indent=2)
            f.write("\n")

        self._devcontainer_trace(f"Created Docker config at {docker_config_path}")

    def _create_context_file(self, project_root: Path) -> None:
        """Create .devcontainer/devcontainer-instructions.md context file."""
        devcontainer_dir = project_root / ".devcontainer"
        devcontainer_dir.mkdir(parents=True, exist_ok=True)

        context_path = devcontainer_dir / "devcontainer-instructions.md"
        
        context_content = """# Dev Container Instructions

## 🐳 This Project Uses Dev Containers

**ALL script execution happens automatically in the dev container.**

### How It Works

When you see commands like this in command files:

```bash
devcontainer exec --workspace-folder . bash .specify/scripts/bash/check-prerequisites.sh --json
```

**Just run it as shown!** The command will execute inside the Linux container automatically.

### Verification

After running commands, verify they executed in the container:

```bash
devcontainer exec --workspace-folder . bash -c 'echo "OS: $(uname -s) | User: $(whoami)"'
```

Expected output: `OS: Linux | User: vscode`

### Container Management

**Start container (if not running):**
```bash
devcontainer up --workspace-folder .
```

**Check if running:**
```bash
docker ps
```

**Get shell in container:**
```bash
devcontainer exec --workspace-folder . bash
```

### For AI Agents

When implementing features (`/spec.implement`, `/spec.plan`, etc.):

1. Command files already have `devcontainer exec` commands
2. Execute them exactly as shown
3. Container will auto-start if needed (first time: 3-5 min)
4. Subsequent runs are instant (container stays running)

**Evidence of container execution:**
- Scripts run with `devcontainer exec` 
- OS shows `Linux` (not `Darwin`)
- User shows `vscode` (not your host username)
- Python shows `3.11.x` (container version)

### More Information

- Dev Containers: https://containers.dev/
- devcontainer CLI: https://code.visualstudio.com/docs/devcontainers/devcontainer-cli

<!-- SPECKIT START -->
<!-- This section is managed by the Specify CLI -->
<!-- SPECKIT END -->
"""

        with open(context_path, "w", encoding="utf-8") as f:
            f.write(context_content)

        self._devcontainer_trace(f"Created {context_path}")

    def _setup_all_agent_commands(
        self,
        project_root: Path,
        manifest: "IntegrationManifest",
        parsed_options: dict[str, Any] | None = None,
        **opts: Any,
    ) -> None:
        """Create dev-container-wrapped command files for ALL AI agent directories.

        This means `specify init --integration devcontainer` sets up EVERY agent
        (opencode, claude, cursor, windsurf, etc.) so no matter which one the user
        opens, commands run inside the dev container automatically.
        """
        from .. import INTEGRATION_REGISTRY

        templates = self.list_command_templates()
        if not templates:
            self._devcontainer_trace("No command templates found")
            return

        project_root = Path(project_root)
        script_type = opts.get("script_type", "sh") if opts else "sh"
        total_created = 0
        total_agents = 0

        for key, integration_cls in INTEGRATION_REGISTRY.items():
            if key == self.key:
                continue

            # Get agent config
            try:
                agent_config = getattr(integration_cls, 'config', None) or {}
            except Exception:
                continue

            folder = agent_config.get("folder", "")
            subdir = agent_config.get("commands_subdir", "commands")
            if not folder:
                continue

            # Determine destination directory
            dest = (project_root / folder / subdir).resolve()
            try:
                dest.relative_to(project_root.resolve())
            except ValueError:
                continue
            dest.mkdir(parents=True, exist_ok=True)

            # Get agent-specific parameters
            registrar_config = getattr(integration_cls, 'registrar_config', {}) or {}
            arg_placeholder = registrar_config.get("args", "$ARGUMENTS") if registrar_config else "$ARGUMENTS"
            agent_context_file = getattr(integration_cls, 'context_file', "") or ""
            agent_name = agent_config.get("name", key)
            total_agents += 1

            for src_file in templates:
                raw = src_file.read_text(encoding="utf-8")
                processed = self.process_template(
                    raw, agent_name, script_type, arg_placeholder,
                    context_file=agent_context_file,
                    project_root=project_root,
                )
                dst_name = integration_cls.command_filename(src_file.stem)
                dst_file = self.write_file_and_record(
                    processed, dest / dst_name, project_root, manifest
                )
                total_created += 1

        self._devcontainer_trace(
            f"Created {total_created} command files across {total_agents} AI agent directories"
        )

        # Update context file for each agent
        for key, integration_cls in INTEGRATION_REGISTRY.items():
            if key == self.key:
                continue
            try:
                agent_config = getattr(integration_cls, 'config', None) or {}
                if not agent_config.get("folder"):
                    continue
                inst = integration_cls()
                inst.upsert_context_section(project_root)
            except Exception:
                pass

    def _wrap_all_agent_commands(self, project_root: Path) -> None:
        """Wrap script references in ALL AI agent command files with devcontainer exec.
        
        Safety net: catches any command files not created by _setup_all_agent_commands.
        """
        from .. import INTEGRATION_REGISTRY

        project_root = Path(project_root)
        wrapped_count = 0
        checked_dirs = 0
        import re

        self._devcontainer_trace("Wrapping ALL agent command files for dev container execution...")

        for key, integration_cls in INTEGRATION_REGISTRY.items():
            if key == self.key:
                continue  # Skip .devcontainer/commands/ - already processed in process_template()

            # Determine command directory for this agent
            try:
                config = getattr(integration_cls, 'config', None) or {}
            except Exception:
                continue
            folder = config.get("folder", "")
            subdir = config.get("commands_subdir", "commands")
            if not folder:
                continue
            cmd_dir = project_root / folder / subdir

            if not cmd_dir.exists():
                continue

            checked_dirs += 1

            files_found = list(cmd_dir.glob("*.md"))
            if files_found:
                self._devcontainer_trace(f"  📁 {key}: {cmd_dir.relative_to(project_root)}/ ({len(files_found)} files)")

            for cmd_file in sorted(files_found):
                content = cmd_file.read_text(encoding="utf-8")

                # Skip files that already have devcontainer exec wrapping
                if 'devcontainer exec' in content:
                    continue

                new_content = content

                # Wrap bash script references: `.specify/scripts/bash/<script>.sh <args>`
                bash_pattern = r'`(\\?\.specify/scripts/bash/[^`]+\.sh[^`]*)`'
                new_content = re.sub(
                    bash_pattern,
                    lambda m: f'`{self._wrap_script_path_for_devcontainer(m.group(1).replace("\\", ""), "bash")}`',
                    new_content
                )

                # Wrap explicit `bash .specify/scripts/...`
                new_content = re.sub(
                    r'`bash (\\?\.specify/scripts/bash/[^`]+\.sh[^`]*)`',
                    lambda m: f'`{self._wrap_script_path_for_devcontainer(m.group(1).replace("\\", ""), "bash")}`',
                    new_content
                )

                # Wrap powershell references
                ps_pattern = r'`(\\?\.specify/scripts/powershell/[^`]+\.ps1[^`]*)`'
                new_content = re.sub(
                    ps_pattern,
                    lambda m: f'`{self._wrap_script_path_for_devcontainer(m.group(1).replace("\\", ""), "powershell")}`',
                    new_content
                )

                if new_content != content:
                    cmd_file.write_text(new_content, encoding="utf-8")
                    wrapped_count += 1
                    rel_path = cmd_file.relative_to(project_root)
                    self._devcontainer_trace(f"  ✅ Wrapped: {rel_path}")

        self._devcontainer_trace(
            f"Checked {checked_dirs} agent directories, wrapped {wrapped_count} command files"
        )

    def _create_agents_md_context(self, project_root: Path) -> None:
        """Write dev container instructions to AGENTS.md so every AI agent reads them."""
        agents_path = project_root / "AGENTS.md"
        if not agents_path.exists():
            agents_path.write_text("", encoding="utf-8")

        content = agents_path.read_text(encoding="utf-8")

        devcontainer_section = """
## 🐳 Dev Container Execution

**IMPORTANT: This project uses dev containers. ALL commands must run inside the container.**

**How to run any command:**

```bash
devcontainer exec --workspace-folder . bash <command>
```

**Examples:**

| ❌ Wrong (runs on HOST) | ✅ Correct (runs in CONTAINER) |
|---|---|
| `bash .specify/scripts/bash/check-prerequisites.sh --json` | `devcontainer exec --workspace-folder . bash .specify/scripts/bash/check-prerequisites.sh --json` |

**Verification:**

```bash
devcontainer exec --workspace-folder . bash -c 'echo "OS: $(uname -s) | User: $(whoami)"'
```
Expected: `OS: Linux | User: vscode`

**Container Management:**

- Start: `devcontainer up --workspace-folder .` (first time: 3-5 min)
- Check: `docker ps`
- Shell: `devcontainer exec --workspace-folder . bash`

**Command files in this project already have devcontainer exec commands. Execute them as shown.**
<!-- SPECKIT START -->
<!-- This section is managed by Specify CLI. Do not edit manually. -->
<!-- SPECKIT END -->
"""

        # Replace existing dev container section if it exists
        import re as _re
        if _re.search(r'<!-- SPECKIT START -->.*?<!-- SPECKIT END -->', content, _re.DOTALL):
            content = _re.sub(
                r'<!-- SPECKIT START -->.*?<!-- SPECKIT END -->',
                devcontainer_section.split("<!-- SPECKIT START -->")[1].split("<!-- SPECKIT END -->")[0],
                content,
                flags=_re.DOTALL
            )
        else:
            content += devcontainer_section

        agents_path.write_text(content, encoding="utf-8")
        self._devcontainer_trace(f"Updated {agents_path} with dev container instructions")

    def _is_devcontainer_mode(self, project_root: Path) -> bool:
        """Check if Dev Container mode is enabled."""
        # Check environment variable first
        env_mode = os.getenv("DEVCONTAINER_MODE", "").lower()
        if env_mode == "enabled":
            return True

        # Check config file
        config = self._load_devcontainer_config(project_root)
        return config.get("mode") == "enabled"

    def _load_devcontainer_config(self, project_root: Path) -> dict[str, Any]:
        """Load .specify/devcontainer.json configuration."""
        config_path = project_root / ".specify" / "devcontainer.json"
        if not config_path.exists():
            return {}

        try:
            with open(config_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return {}

    def dispatch_command(
        self,
        command_name: str,
        *,
        args: str = "",
        project_root: Path,
        stream: bool = False,
    ) -> dict[str, Any]:
        """Dispatch command execution to Dev Container CLI."""
        # Check if devcontainer mode is enabled
        if not self._is_devcontainer_mode(project_root):
            self._devcontainer_trace("Dev Container mode not enabled, falling back to standard dispatch")
            return super().dispatch_command(
                command_name, args=args, project_root=project_root, stream=stream
            )

        # Execute via devcontainer CLI
        return self._call_devcontainer_exec(
            command_name=command_name,
            args=args,
            project_root=project_root,
            stream=stream,
        )

    def _is_container_running(self, project_root: Path, cli_path: str) -> bool:
        """Check if the dev container is currently running."""
        try:
            # Try a simple exec command to check if container is running
            result = subprocess.run(
                [cli_path, "exec", "--workspace-folder", str(project_root), "echo", "ping"],
                capture_output=True,
                text=True,
                timeout=5,
                check=False,
            )
            return result.returncode == 0
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return False

    def _start_container(self, project_root: Path, cli_path: str) -> bool:
        """Start the dev container in the background."""
        self._devcontainer_trace("Container not running, starting it now...")
        self._devcontainer_trace("This may take 3-5 minutes on first run (pulling image, installing deps)...")
        
        try:
            # Use `devcontainer up` to start the container
            result = subprocess.run(
                [
                    cli_path,
                    "up",
                    "--workspace-folder",
                    str(project_root),
                ],
                capture_output=True,
                text=True,
                timeout=300,  # Give it 5 minutes to start (first run needs to pull image)
                check=False,
            )
            
            if result.returncode == 0:
                self._devcontainer_trace("Container started successfully")
                return True
            else:
                self._devcontainer_trace(f"Failed to start container: {result.stderr}")
                # Print stdout too for debugging
                if result.stdout:
                    self._devcontainer_trace(f"Container startup output: {result.stdout[:500]}")
                return False
                
        except subprocess.TimeoutExpired:
            self._devcontainer_trace("Container startup timed out after 5 minutes")
            self._devcontainer_trace("Try manually: devcontainer up --workspace-folder .")
            return False
        except Exception as e:
            self._devcontainer_trace(f"Error starting container: {e}")
            return False

    def _call_devcontainer_exec(
        self,
        command_name: str,
        args: str,
        project_root: Path,
        stream: bool,
    ) -> dict[str, Any]:
        """Execute command using devcontainer exec."""
        config = self._load_devcontainer_config(project_root)
        cli_path = config.get("devcontainer", {}).get("cli_path", "devcontainer")

        # Check if container is running, start it if not
        if not self._is_container_running(project_root, cli_path):
            if not self._start_container(project_root, cli_path):
                return {
                    "exit_code": 1,
                    "stdout": "",
                    "stderr": "Failed to start dev container. Ensure Docker is running and .devcontainer/devcontainer.json is properly configured.",
                }

        # Build the command to execute
        # Dev container integration is designed for AI agents to read command files,
        # not for direct CLI invocation. For direct usage, get a shell in the container instead.
        # However, for basic commands, we can try to execute the check-prerequisites script
        # which is what most commands start with.
        
        # For now, provide a helpful error message
        return {
            "exit_code": 1,
            "stdout": "",
            "stderr": (
                f"Dev container integration is designed for AI agents (Claude Code, Cursor, etc.), "
                f"not direct CLI usage.\n\n"
                f"To use the dev container:\n\n"
                f"Option 1 - With AI Agent (Recommended):\n"
                f"  1. Open project in Claude Code/Cursor\n"
                f"  2. Run: /spec.{command_name} \"{args}\"\n"
                f"  3. AI agent will execute commands in container automatically\n\n"
                f"Option 2 - Get Shell in Container:\n"
                f"  devcontainer exec --workspace-folder {project_root} bash\n\n"
                f"Option 3 - Run Scripts Directly:\n"
                f"  devcontainer exec --workspace-folder {project_root} bash .specify/scripts/bash/check-prerequisites.sh\n\n"
                f"See: .devcontainer/commands/spec.{command_name}.md for AI agent instructions"
            ),
        }

        # Build devcontainer exec command
        exec_cmd = [
            cli_path,
            "exec",
            "--workspace-folder",
            str(project_root),
            "bash",
            "-c",
            cmd_to_exec,
        ]

        self._devcontainer_trace(f"Executing: {' '.join(exec_cmd)}")

        try:
            if stream:
                # Stream output in real-time
                process = subprocess.Popen(
                    exec_cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    cwd=project_root,
                )

                stdout_lines = []
                for line in process.stdout:
                    print(line, end="", flush=True)
                    stdout_lines.append(line)

                process.wait()
                stdout = "".join(stdout_lines)
                exit_code = process.returncode
            else:
                # Capture output
                result = subprocess.run(
                    exec_cmd,
                    cwd=project_root,
                    capture_output=True,
                    text=True,
                    check=False,
                )
                stdout = result.stdout
                exit_code = result.returncode

            return {
                "exit_code": exit_code,
                "stdout": stdout,
                "stderr": "",
            }

        except FileNotFoundError:
            error_msg = f"devcontainer CLI not found at: {cli_path}"
            self._devcontainer_trace(f"ERROR: {error_msg}")
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": error_msg,
            }
        except Exception as e:
            error_msg = f"Error executing devcontainer command: {e}"
            self._devcontainer_trace(f"ERROR: {error_msg}")
            return {
                "exit_code": 1,
                "stdout": "",
                "stderr": error_msg,
            }
