"""
Core fork customizations: alias resolution, MCP config, and skill naming.

This module is the leaf tier in the fork module dependency graph:

    _core_fork.py        (THIS MODULE - constants + alias/MCP/skill)
            ^
            |
    _init_fork.py        (theming + init hooks, imports this)

This module:
- Resolves command aliases for short-form command names
- Computes skill output names for fork-specific naming
- Validates and merges MCP configs from team-ai-directives
- Reports init success based on tracker state
- Lists pre-installed extensions from catalog.json
- Defines fork-level extension constants (namespaces, alias pattern, install cmd)
"""

from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import Any

# Command prefix for __SPECKIT_COMMAND_*__ placeholder resolution
# Upstream uses "speckit", fork uses "spec"
COMMAND_PREFIX = "spec"

# Fork-specific command namespaces that should NOT have "speckit-" prefix
FORK_COMMAND_NAMESPACES = frozenset({"adlc", "spec"})

# -- Extension-level fork constants (consolidated from _extension_fork) --------

# Command namespaces allowed in extension commands
# Upstream only allows "speckit", fork also allows "adlc"
EXTENSION_NAMESPACES = ["speckit", "adlc"]

# Enable short alias format: {extension}.{command} (e.g., architect.init)
EXTENSION_ALIAS_PATTERN_ENABLED = True

# Install command template for fork (used in self check output)
FORK_INSTALL_COMMAND = "uv tool install agentic-sdlc-specify-cli --force --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git@{tag}"


def build_alias_map(project_root: Path) -> dict[str, str]:
    """Build a command name -> first alias map from installed extension/preset manifests.

    This function scans installed extensions and presets to find commands with aliases,
    creating a mapping from the full command name to its first alias.

    Examples:
        "speckit.git.commit" -> "git.commit"
        "adlc.spec.constitution" -> "spec.constitution"
        "adlc.architect.specify" -> "architect.specify"

    Args:
        project_root: Path to the project root

    Returns:
        Dictionary mapping command names to their first alias
    """
    alias_map: dict[str, str] = {}

    # Scan extensions (both copied and reference/top-level)
    extensions_dir = project_root / ".specify" / "extensions"
    scan_dirs: list[Path] = []
    if extensions_dir.is_dir():
        for ext_dir in extensions_dir.iterdir():
            if ext_dir.is_dir() and not ext_dir.name.startswith("."):
                scan_dirs.append(ext_dir)
    # Also scan reference extensions stored at top-level paths
    try:
        from specify_cli.extensions import ExtensionRegistry
        registry = ExtensionRegistry(extensions_dir)
        for _ext_id, metadata in registry.list().items():
            if metadata.get("source") == "reference" and metadata.get("path"):
                ref_path = Path(metadata["path"])
                if ref_path.is_dir() and ref_path not in scan_dirs:
                    scan_dirs.append(ref_path)
    except Exception:
        pass

    for ext_dir in scan_dirs:
        manifest_path = ext_dir / "extension.yml"
        if not manifest_path.is_file():
            continue
        try:
            import yaml
            with open(manifest_path, 'r', encoding='utf-8') as f:
                manifest = yaml.safe_load(f)
            if not isinstance(manifest, dict):
                continue
            commands = manifest.get("provides", {}).get("commands", [])
            for cmd in commands:
                if not isinstance(cmd, dict):
                    continue
                cmd_name = cmd.get("name")
                aliases = cmd.get("aliases", [])
                if cmd_name and aliases and isinstance(aliases, list):
                    alias_map[cmd_name] = aliases[0]
                    # Also map replaced command name to the same alias
                    replaces = cmd.get("replaces")
                    if replaces:
                        alias_map[replaces] = aliases[0]
        except Exception:
            continue

    # Scan presets
    presets_dir = project_root / ".specify" / "presets"
    if presets_dir.is_dir():
        for preset_dir in presets_dir.iterdir():
            if not preset_dir.is_dir():
                continue
            manifest_path = preset_dir / "preset.yml"
            if not manifest_path.is_file():
                continue
            try:
                import yaml
                with open(manifest_path, 'r', encoding='utf-8') as f:
                    manifest = yaml.safe_load(f)
            except Exception:
                continue
            if not isinstance(manifest, dict):
                continue
            provides = manifest.get("provides", {})
            templates = provides.get("templates", [])
            for tmpl in templates:
                if not isinstance(tmpl, dict):
                    continue
                if tmpl.get("type") != "command":
                    continue
                cmd_name = tmpl.get("name")
                aliases = tmpl.get("aliases", [])
                if cmd_name and aliases and isinstance(aliases, list):
                    alias_map[cmd_name] = aliases[0]
                    # Also map replaced command name to the same alias
                    # so resolve_command_alias("speckit.plan") works
                    # for the original (upstream) command name in
                    # addition to the preset name.
                    replaces = tmpl.get("replaces")
                    if replaces:
                        alias_map[replaces] = aliases[0]

    return alias_map


def resolve_command_alias(cmd_name: str, project_root: Path | None = None) -> str:
    """Resolve a command name to its alias if one exists.

    This is the primary function to use instead of hardcoded prefix stripping.
    It looks up the command in the alias map and returns the alias if found,
    otherwise returns the command name unchanged.

    Args:
        cmd_name: The command name (e.g., "speckit.git.commit", "adlc.spec.plan")
        project_root: Optional project root for building alias map. If None,
                     uses current working directory.

    Returns:
        The alias if found, otherwise the original command name
    """
    if project_root is None:
        project_root = Path.cwd()

    alias_map = build_alias_map(project_root)
    return alias_map.get(cmd_name, cmd_name)


def normalize_hook_command_id(command_id: str, project_root: Path | None = None) -> str:
    """Normalize a hook command id to its alias form if one exists.

    For commands WITH aliases (e.g., ``speckit.git.commit`` → ``git.commit``,
    ``adlc.spec.plan`` → ``spec.plan``), returns the alias. For commands
    WITHOUT aliases, returns the original unchanged.

    Args:
        command_id: The command id stored in hook config.
        project_root: Optional project root for building alias map.

    Returns:
        The alias if found, otherwise the original command id.
    """
    resolved = resolve_command_alias(command_id, project_root)
    return resolved if resolved != command_id else command_id


def normalize_hook_config_commands(config: dict, project_root: Path | None = None) -> tuple[dict, bool]:
    """Normalize all hook command ids in an extensions.yml config dict.

    Walks the ``hooks`` section and replaces each hook's ``command`` field
    with its alias form when an alias exists.

    Args:
        config: The extensions.yml config dictionary.
        project_root: Optional project root for alias resolution.

    Returns:
        Tuple of (normalized_config, changed).
    """
    import copy

    if not isinstance(config, dict):
        return config, False

    normalized = copy.deepcopy(config)
    changed = False
    hooks = normalized.get("hooks")
    if not isinstance(hooks, dict):
        return normalized, False

    for event_name, hook_list in hooks.items():
        if not isinstance(hook_list, list):
            continue
        for hook in hook_list:
            if not isinstance(hook, dict):
                continue
            cmd = hook.get("command")
            if not isinstance(cmd, str):
                continue
            normalized_cmd = normalize_hook_command_id(cmd, project_root)
            if normalized_cmd != cmd:
                hook["command"] = normalized_cmd
                changed = True

    return normalized, changed


def normalize_stored_hook_commands(project_root: Path) -> bool:
    """Normalize all hook command ids in ``.specify/extensions.yml`` to alias form.

    Loads the project's extensions config, normalizes hook command ids, and
    writes the file back only when changes were made.

    Args:
        project_root: Path to the project root.

    Returns:
        True if changes were made and saved, False otherwise.
    """
    config_file = project_root / ".specify" / "extensions.yml"
    if not config_file.exists():
        return False

    try:
        import yaml

        config = yaml.safe_load(config_file.read_text(encoding="utf-8"))
        if not isinstance(config, dict):
            return False
    except Exception:
        return False

    normalized, changed = normalize_hook_config_commands(config, project_root)
    if changed:
        try:
            config_file.write_text(
                yaml.dump(
                    normalized,
                    default_flow_style=False,
                    sort_keys=False,
                    allow_unicode=True,
                ),
                encoding="utf-8",
            )
            return True
        except Exception:
            pass
    return False


def compute_skill_output_name(cmd_name: str, agent_config: dict, project_root: Path | None = None) -> str:
    """
    Compute the on-disk skill name for an agent with fork-specific handling.

    Commands WITH aliases use the alias form (fork-appropriate naming).
    Commands WITHOUT aliases keep upstream behavior (speckit- prefix).

    Examples:
    - "speckit.plan" -> "spec-plan" (via alias "spec.plan")
    - "adlc.levelup.init" -> "levelup-init" (via alias "levelup.init")
    - "speckit.taskstoissues" -> "spec-taskstoissues" (via alias "spec.taskstoissues")
    """
    if agent_config.get("extension") != "/SKILL.md":
        format_name = agent_config.get("format_name")
        return format_name(cmd_name) if format_name else cmd_name

    resolved = resolve_command_alias(cmd_name, project_root)

    if resolved != cmd_name:
        # Has alias - apply fork prefix logic
        from specify_cli.integrations.base import _get_command_prefix
        pfx = _get_command_prefix()
        for ns in ("speckit.", "spec.", "adlc."):
            if resolved.startswith(ns):
                return f"{pfx}-{resolved[len(ns):].replace('.', '-')}"
        return resolved.replace(".", "-")

    # No alias - keep upstream behavior
    return resolved.replace(".", "-")


def resolve_env_placeholders(content: str) -> tuple[str, list[str], list[str]]:
    """Replace ${VAR} with environment variable value.

    Args:
        content: The MCP config content with ${VAR} placeholders

    Returns:
        Tuple of (resolved_content, resolved_vars, unresolved_vars)
    """
    pattern = r'\$\{([^}]+)\}'
    resolved_vars = []
    unresolved_vars = []

    def replacer(match):
        var_name = match.group(1)
        env_value = os.environ.get(var_name)
        if env_value is not None:
            resolved_vars.append(var_name)
            return env_value
        else:
            unresolved_vars.append(var_name)
            return f"${{{var_name}}}"

    resolved_content = re.sub(pattern, replacer, content)
    return resolved_content, resolved_vars, unresolved_vars


def validate_mcp_config(content: str) -> tuple[bool, str]:
    """Validate JSON structure of MCP config.

    Args:
        content: The MCP config content as string

    Returns:
        Tuple of (is_valid, error_message)
    """
    try:
        config = json.loads(content)
        if not isinstance(config, dict):
            return False, "MCP config must be a JSON object"

        # Check for at least one of mcpServers or tools
        if "mcpServers" not in config and "tools" not in config:
            return False, "MCP config must contain 'mcpServers' or 'tools'"

        return True, ""
    except json.JSONDecodeError as e:
        return False, f"Invalid JSON: {e}"
    except Exception as e:
        return False, f"Validation error: {e}"


def merge_mcp_configs_report_conflicts(existing: dict, incoming: dict) -> tuple[dict, list[str]]:
    """Merge configs but report conflicts instead of overwriting.

    Args:
        existing: The existing MCP config dict
        incoming: The incoming MCP config dict from team-ai-directives

    Returns:
        Tuple of (merged_config, conflict_list)
    """
    merged = json.loads(json.dumps(existing))  # Deep copy
    conflicts = []

    # Merge mcpServers
    if "mcpServers" in incoming:
        if "mcpServers" not in merged:
            merged["mcpServers"] = {}

        for server_name, server_config in incoming["mcpServers"].items():
            if server_name in merged.get("mcpServers", {}):
                conflicts.append(f"mcpServers: {server_name}")
            else:
                merged["mcpServers"][server_name] = server_config

    # Merge tools
    if "tools" in incoming:
        if "tools" not in merged:
            merged["tools"] = {}

        for tool_name, tool_config in incoming["tools"].items():
            if tool_name in merged.get("tools", {}):
                conflicts.append(f"tools: {tool_name}")
            else:
                merged["tools"][tool_name] = tool_config

    return merged, conflicts


def install_mcp_config(team_path: Path, project_root: Path) -> tuple[bool, list[str], list[str], list[str]]:
    """Install .mcp.json from team-ai-directives to project root.

    Args:
        team_path: Path to team-ai-directives directory
        project_root: Path to project root

    Returns:
        Tuple of (success, messages, resolved_vars, unresolved_vars)
    """
    messages = []
    resolved_vars = []
    unresolved_vars = []

    team_mcp_path = team_path / ".mcp.json"
    project_mcp_path = project_root / ".mcp.json"

    if not team_mcp_path.exists():
        messages.append("ℹ No .mcp.json found in team-ai-directives")
        return True, messages, resolved_vars, unresolved_vars

    # Read team .mcp.json
    try:
        content = team_mcp_path.read_text()
    except Exception as e:
        messages.append(f"✗ Failed to read team .mcp.json: {e}")
        return False, messages, resolved_vars, unresolved_vars

    # Resolve environment placeholders
    content, resolved_vars, unresolved_vars = resolve_env_placeholders(content)

    # Validate JSON
    is_valid, error_msg = validate_mcp_config(content)
    if not is_valid:
        messages.append("✗ Invalid MCP config in team-ai-directives/.mcp.json")
        messages.append(f"  ℹ {error_msg}")
        return False, messages, resolved_vars, unresolved_vars

    # Parse the config
    try:
        team_config = json.loads(content)
    except Exception as e:
        messages.append(f"✗ Failed to parse team .mcp.json: {e}")
        return False, messages, resolved_vars, unresolved_vars

    # Check for existing project .mcp.json
    if project_mcp_path.exists():
        try:
            existing_content = project_mcp_path.read_text()
            existing_config = json.loads(existing_content)

            # Merge with conflict reporting
            merged_config, conflicts = merge_mcp_configs_report_conflicts(existing_config, team_config)

            if conflicts:
                messages.append("⚠ Conflicts detected (skipped, existing preserved):")
                for conflict in conflicts:
                    messages.append(f"    - {conflict}")

            # Write merged config
            project_mcp_path.write_text(json.dumps(merged_config, indent=2))
            messages.append("✓ Merged .mcp.json with existing config")

        except Exception as e:
            messages.append(f"✗ Failed to merge with existing .mcp.json: {e}")
            return False, messages, resolved_vars, unresolved_vars
    else:
        # Write new config
        project_mcp_path.write_text(json.dumps(team_config, indent=2))
        messages.append("✓ Installed .mcp.json")

    # Report env var resolution
    if resolved_vars:
        messages.append(f"  ℹ Resolved env vars: {', '.join(resolved_vars)}")
    if unresolved_vars:
        messages.append(f"  ⚠ Unresolved placeholders: {', '.join(f'${{{v}}}' for v in unresolved_vars)}")

    return True, messages, resolved_vars, unresolved_vars


def should_print_project_ready(tracker: Any) -> bool:
    """Return True if init should print the "Project ready." success message.

    We consider init "not ready" if any tracked step ended in an error state.
    This keeps the final messaging aligned with the progress view.
    """
    try:
        return not any(step.get("status") == "error" for step in getattr(tracker, "steps", []))
    except Exception:
        # Be conservative: if we can't inspect the tracker, do not claim success.
        return False


def get_preinstalled_extensions(project_path: Path) -> list[dict]:
    """Get list of pre-installed extensions from catalog.json."""
    extensions = []
    catalog_paths = [
        project_path / ".specify" / "catalog.json",
        project_path / ".specify" / "extensions" / "catalog.json",
        Path(__file__).parent / "bundled_extensions" / "catalog.json",
        Path(__file__).parent.parent.parent / "extensions" / "catalog.json",
    ]

    for catalog_path in catalog_paths:
        if catalog_path.exists():
            try:
                with open(catalog_path) as f:
                    catalog_data = json.load(f)
                for ext_id, ext_data in catalog_data.get("extensions", {}).items():
                    if ext_data.get("preinstall", False):
                        extensions.append(
                            {
                                "id": ext_id,
                                "name": ext_data.get("name", ext_id),
                                "description": ext_data.get("description", ""),
                                "commands": ext_data.get("commands", []),
                            }
                        )
                if extensions:
                    break
            except (json.JSONDecodeError, IOError):
                continue
    return extensions


# ============================================================================
# MODEL-INVOCATION FLAG INJECTION
# ============================================================================


def _inject_frontmatter_flag(content: str, key: str, value: str = "true") -> str:
    """Insert ``key: value`` before the closing ``---`` if not already present."""
    lines = content.splitlines(keepends=True)

    dash_count = 0
    for line in lines:
        stripped = line.rstrip("\n\r")
        if stripped == "---":
            dash_count += 1
            if dash_count == 2:
                break
            continue
        if dash_count == 1 and stripped.startswith(f"{key}:"):
            return content

    out: list[str] = []
    dash_count = 0
    injected = False
    for line in lines:
        stripped = line.rstrip("\n\r")
        if stripped == "---":
            dash_count += 1
            if dash_count == 2 and not injected:
                if line.endswith("\r\n"):
                    eol = "\r\n"
                elif line.endswith("\n"):
                    eol = "\n"
                else:
                    eol = ""
                out.append(f"{key}: {value}{eol}")
                injected = True
        out.append(line)
    return "".join(out)


def inject_model_invocation_flag(
    content: str, source_frontmatter: dict, agent_name: str
) -> str:
    """Inject ``disable-model-invocation: false`` when source has ``model-invocation: true``.

    Only applies to skills-based agents (extension == "/SKILL.md").
    Returns content unchanged otherwise.
    """
    if not isinstance(source_frontmatter, dict):
        return content
    if not source_frontmatter.get("model-invocation"):
        return content

    try:
        from specify_cli.integrations import INTEGRATION_REGISTRY

        integration = INTEGRATION_REGISTRY.get(agent_name)
        if integration and integration.registrar_config and integration.registrar_config.get("extension") == "/SKILL.md":
            return _inject_frontmatter_flag(content, "disable-model-invocation", "false")
    except Exception:
        pass
    return content
