#!/usr/bin/env python3
"""
Tikalk/Agentic-SDLC Fork CLI Customizations

All customizations for the tikalk fork of spec-kit are isolated here to minimize
merge conflicts when syncing with upstream. This module provides:

1. THEMING - Orange accent color and banner colors
2. HELPERS - accent() and accent_style() for consistent theming
3. BUNDLED CONTENT - Extensions and presets that ship with the fork
4. TEAM DIRECTIVES - Integration with team-ai-directives repository
5. PACKAGE IDENTITY - Package names for version detection
6. EXTENSION NAMESPACES - Support for adlc.* command prefixes

When merging upstream changes, only the import block in __init__.py needs attention.
All customization logic lives here and doesn't conflict with upstream.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import urllib.error
from packaging import version
from pathlib import Path
from typing import Any

from rich.console import Console

# ============================================================================
# THEMING
# ============================================================================

# Tikalk orange accent color (replaces upstream cyan)
ACCENT_COLOR = "#f47721"

# Banner gradient colors for the CLI header
BANNER_COLORS = ["#ff6b35", "#ff8c42", "#f47721", "#ff5722", "white", "bright_white"]

# GitHub API URL for fork releases (overrides upstream)
GITHUB_API_LATEST = "https://api.github.com/repos/tikalk/agentic-sdlc-spec-kit/releases/latest"


def accent(
    text: str,
    bold: bool = False,
    italic: bool = False,
    dim: bool = False,
) -> str:
    """
    Wrap text in accent color markup with optional formatting.

    This helper provides consistent theming throughout the CLI without
    hardcoding color values everywhere.

    Args:
        text: The text to wrap with accent color
        bold: Apply bold formatting
        italic: Apply italic formatting
        dim: Apply dim formatting

    Returns:
        Rich-formatted string with accent color applied

    Examples:
        accent("Installing...")
        # -> "[#f47721]Installing...[/#f47721]"

        accent("Important", bold=True)
        # -> "[bold #f47721]Important[/]"

        accent("Note", dim=True)
        # -> "[dim #f47721]Note[/]"

        accent("Emphasis", bold=True, italic=True)
        # -> "[bold italic #f47721]Emphasis[/]"
    """
    styles = []
    if bold:
        styles.append("bold")
    if italic:
        styles.append("italic")
    if dim:
        styles.append("dim")
    styles.append(ACCENT_COLOR)

    style_str = " ".join(styles)

    # Use closing tag with style for simple cases, [/] for combined styles
    if len(styles) == 1:
        return f"[{style_str}]{text}[/{style_str}]"
    else:
        return f"[{style_str}]{text}[/]"


def accent_style() -> str:
    """
    Return the accent color for Rich style= attributes.

    Use this for style= parameters in Rich components like:
    - Panel(border_style=accent_style())
    - Tree(guide_style=accent_style())
    - Table.add_column(style=accent_style())

    Returns:
        The accent color hex code
    """
    return ACCENT_COLOR


# ACCENT_STYLE for _console.py theming (used by Rich style attributes)
# This is the string representation used by Rich, not the hex code
ACCENT_STYLE = ACCENT_COLOR


def apply_theming_patches(_console_module) -> None:
    """Apply fork theming patches to _console.py module.

    This function patches ACCENT_STYLE in _console.py to use the fork's
    accent color instead of the upstream default "cyan".

    Called from __init__.py after importing cli_customization.

    Args:
        _console_module: The specify_cli._console module instance
    """
    _console_module.ACCENT_STYLE = ACCENT_STYLE


# ============================================================================
# EXTENSION NAMESPACES
# ============================================================================

# Command namespaces allowed in extension commands
# Upstream only allows "speckit", fork also allows "adlc"
EXTENSION_NAMESPACES = ["speckit", "adlc"]

# Enable short alias format: {extension}.{command} (e.g., architect.init)
EXTENSION_ALIAS_PATTERN_ENABLED = True

# Command prefix for __SPECKIT_COMMAND_*__ placeholder resolution
# Upstream uses "speckit", fork uses "spec"
COMMAND_PREFIX = "spec"


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
            except Exception:
                continue

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


# ============================================================================
# REFERENCE EXTENSION PATH RESOLUTION
# ============================================================================



# ============================================================================
# FORK SELF CHECK - GitHub API endpoint for specify self check command
# ============================================================================

# Fork GitHub API endpoint for self check command
FORK_GITHUB_API_LATEST = "https://api.github.com/repos/tikalk/agentic-sdlc-spec-kit/releases/latest"

# Install command template for fork (used in self check output)
FORK_INSTALL_COMMAND = "uv tool install agentic-sdlc-specify-cli --force --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git@{tag}"


# ============================================================================
# SKILL OUTPUT NAME COMPUTATION - Fork-specific naming for Claude Code slash commands
# ============================================================================

# Fork-specific command namespaces that should NOT have "speckit-" prefix
FORK_COMMAND_NAMESPACES = frozenset({"adlc", "spec"})


def compute_skill_output_name(cmd_name: str, agent_config: dict, project_root: Path | None = None) -> str:
    """
    Compute the on-disk skill name for an agent with fork-specific handling.

    Commands WITH aliases use the alias form (fork-appropriate naming).
    Commands WITHOUT aliases keep upstream behavior (speckit- prefix).

    Examples:
    - "speckit.plan" -> "spec-plan" (via alias "spec.plan")
    - "adlc.levelup.init" -> "levelup-init" (via alias "levelup.init")
    - "speckit.taskstoissues" -> "speckit-taskstoissues" (no alias, upstream name)
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


# ============================================================================
# CLI IDENTITY
# ============================================================================

# CLI tagline shown in the intro banner
TAGLINE = "Agentic SDLC toolkit for Spec-Driven Development with bundled extensions and AI agent support"


# ============================================================================
# PACKAGE IDENTITY
# ============================================================================

# Package names for version detection (checked in order)
# Fork package checked first, then upstream fallback
PKG_NAMES = ("agentic-sdlc-specify-cli", "specify-cli")


def get_speckit_version() -> str:
    """Get current spec-kit version.

    Fork customization: checks all package names in PKG_NAMES to support
    the fork's package name (agentic-sdlc-specify-cli) as well as upstream.
    """
    import importlib.metadata
    # Try all known package names (fork may have different names)
    for pkg_name in PKG_NAMES:
        try:
            return importlib.metadata.version(pkg_name)
        except Exception:
            continue
    # Fallback: try reading from pyproject.toml
    try:
        import tomllib
        from pathlib import Path

        pyproject_path = Path(__file__).parent.parent.parent / "pyproject.toml"
        if pyproject_path.exists():
            with open(pyproject_path, "rb") as f:
                data = tomllib.load(f)
                return data.get("project", {}).get("version", "unknown")
    except Exception:
        pass
    return "unknown"


# ============================================================================
# TEAM DIRECTIVES
# ============================================================================

# Directory name for team directives repository
TEAM_DIRECTIVES_DIRNAME = "team-ai-directives"


# ============================================================================
# MCP CONFIGURATION - Install .mcp.json from team-ai-directives
# ============================================================================


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


# ============================================================================
# INIT HOOKS - Tikalk-specific pre/post init callbacks
# ============================================================================

console = Console()


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


def _scaffold_extensions_to_project(
    source_dir: Path,
    project_dir: Path,
    skip_extensions: list[str] | None = None,
) -> list[str]:
    """Scaffold extension folders from source to project if missing or empty.
    Only scaffolds extensions with preinstall: true in the catalog.

    Args:
        skip_extensions: List of extension names to skip during scaffolding.
    """
    import json

    scaffolded = []
    skip_extensions = skip_extensions or []

    if not source_dir.exists():
        return scaffolded

    project_dir.mkdir(parents=True, exist_ok=True)

    preinstall_extensions = set()
    catalog_path = source_dir / "catalog.json"
    if catalog_path.exists():
        try:
            with open(catalog_path) as f:
                catalog_data = json.load(f)
            extensions = catalog_data.get("extensions", {})
            preinstall_extensions = {
                ext_id
                for ext_id, ext_data in extensions.items()
                if ext_data.get("preinstall", False)
            }
        except (json.JSONDecodeError, IOError):
            pass

    for ext_dir in source_dir.iterdir():
        if not ext_dir.is_dir() or ext_dir.name.startswith("."):
            continue

        # Skip extensions in the skip list
        if ext_dir.name in skip_extensions:
            continue

        if preinstall_extensions and ext_dir.name not in preinstall_extensions:
            continue

        proj_ext = project_dir / ext_dir.name

        # Always scaffold - copy all files, overwriting existing
        if proj_ext.exists():
            for src in ext_dir.rglob("*"):
                if src.is_file():
                    dst = proj_ext / src.relative_to(ext_dir)
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src, dst)
        else:
            shutil.copytree(ext_dir, proj_ext)

        scaffolded.append(ext_dir.name)

    src_cat = source_dir / "catalog.json"
    if src_cat.exists():
        dst_cat = project_dir / "catalog.json"
        if not dst_cat.exists():
            shutil.copy2(src_cat, dst_cat)

    return scaffolded


# ============================================================================
# PRESET VERSIONING
# ============================================================================


def _read_preset_version(preset_dir: Path) -> str | None:
    """Read version from preset.yml if it exists."""
    preset_yml = preset_dir / "preset.yml"
    if not preset_yml.exists():
        return None

    from .presets import PresetManifest

    try:
        manifest = PresetManifest(preset_yml)
        return manifest.version
    except Exception:
        return None


def _scaffold_presets_to_project(
    source_dir: Path,
    project_dir: Path,
) -> list[str]:
    """Scaffold preset folders from source to project if missing or empty.
    Only scaffolds presets with preinstall: true in the catalog.
    """
    scaffolded = []

    if not source_dir.exists():
        return scaffolded

    # Read catalog to get preinstall flags
    preinstall_presets = set()
    catalog_path = source_dir / "catalog.json"
    if catalog_path.exists():
        try:
            with open(catalog_path) as f:
                catalog_data = json.load(f)
            presets = catalog_data.get("presets", {})
            preinstall_presets = {
                preset_id
                for preset_id, preset_data in presets.items()
                if preset_data.get("preinstall", False)
            }
        except (json.JSONDecodeError, IOError):
            pass

    project_dir.mkdir(parents=True, exist_ok=True)

    for preset_dir in source_dir.iterdir():
        if not preset_dir.is_dir() or preset_dir.name.startswith("."):
            continue

        # Only scaffold presets with preinstall: true
        if preinstall_presets and preset_dir.name not in preinstall_presets:
            continue

        proj_preset = project_dir / preset_dir.name

        if (proj_preset / "preset.yml").exists():
            bundled_version = _read_preset_version(preset_dir)
            installed_version = _read_preset_version(proj_preset)
            if bundled_version and installed_version:
                try:
                    if version.parse(bundled_version) <= version.parse(installed_version):
                        continue
                    # bundled > installed: upgrade needed - remove old and re-scaffold
                    shutil.rmtree(proj_preset)
                except Exception:
                    continue
            else:
                continue

        if proj_preset.exists():
            for src in preset_dir.rglob("*"):
                if src.is_file():
                    dst = proj_preset / src.relative_to(preset_dir)
                    if not dst.exists():
                        dst.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(src, dst)
        else:
            shutil.copytree(preset_dir, proj_preset)

        scaffolded.append(preset_dir.name)

    src_cat = source_dir / "catalog.json"
    if src_cat.exists():
        dst_cat = project_dir / "catalog.json"
        if not dst_cat.exists():
            shutil.copy2(src_cat, dst_cat)

    return scaffolded


def _store_extension_source_url(
    project_root: Path, extension_id: str, source_url: str, target_repo: str | None = None
) -> None:
    """Store extension source URL in registry for later reference."""
    registry_path = project_root / ".specify" / "extensions" / "registry.json"
    registry = {}
    if registry_path.exists():
        try:
            registry = json.loads(registry_path.read_text())
        except json.JSONDecodeError:
            pass
    if extension_id not in registry:
        registry[extension_id] = {}
    registry[extension_id]["source_url"] = source_url
    if target_repo:
        registry[extension_id]["target_repo"] = target_repo
    registry_path.write_text(json.dumps(registry, indent=2))


def _derive_target_repo_from_url(url: str) -> str | None:
    """Derive target repository URL from archive URL.

    Converts GitHub archive URLs to repository URLs.
    """
    if "github.com" in url:
        # Handle archive URLs like: https://github.com/org/repo/archive/refs/tags/v1.0.0.zip
        if "/archive/" in url:
            parts = url.split("/archive/")[0].split("/")
            if len(parts) >= 2:
                return f"https://github.com/{parts[-2]}/{parts[-1]}"
        # Handle direct zip URLs
        elif url.endswith(".zip"):
            parts = url.replace(".zip", "").split("/")
            if len(parts) >= 2:
                return f"https://github.com/{parts[-2]}/{parts[-1]}"
    return None


def _register_bundled_catalog(project_root: Path, catalog_url: str) -> None:
    """Register bundled catalog from team-ai-directives repository.

    Failures are non-fatal (the bundled catalog is an optional enhancement),
    but we should not silently swallow exceptions during `specify init`.
    """
    try:
        import urllib.request

        req = urllib.request.Request(catalog_url)
        with urllib.request.urlopen(req, timeout=30) as response:
            catalog_data = json.loads(response.read().decode("utf-8"))

        # Save to project's catalog.bundled.json
        bundled_catalog_path = project_root / ".specify" / "extensions" / "catalog.bundled.json"
        bundled_catalog_path.write_text(json.dumps(catalog_data, indent=2))
    except Exception as e:
        # Non-fatal, but surfaced so users can diagnose failures.
        sanitized = str(e).replace("\n", " ").strip()
        console.print(
            f"[yellow]Warning:[/yellow] Failed to register bundled extension catalog: {sanitized[:200]}"
        )


def sync_team_ai_directives(
    repo_url: str, project_root: Path, *, force: bool = False
) -> tuple[str, Path]:
    """Install bundled team-ai-directives extension and resolve knowledge base path.

    The extension itself is bundled with the spec-kit CLI. The knowledge base
    (context_modules, skills, .skills.json, CDR.md) is provided by the user
    via --team-ai-directives as a local directory or ZIP URL.

    Args:
        repo_url: URL or local path to team-ai-directives knowledge base
        project_root: Project root directory
        force: If True, remove existing team-ai-directives before reinstalling.

    Returns:
        Tuple of (status, knowledge_base_path) where status is "local" or "installed"
    """
    from .extensions import ExtensionManager
    from ._assets import _locate_bundled_extension

    repo_url = (repo_url or "").strip()
    if not repo_url:
        raise ValueError("Team AI directives repository URL cannot be empty")

    # Install bundled extension from CLI package
    ext_manager = ExtensionManager(project_root)
    speckit_version = get_speckit_version()

    if force and ext_manager.registry.is_installed(TEAM_DIRECTIVES_DIRNAME):
        ext_manager.remove(TEAM_DIRECTIVES_DIRNAME)

    if not ext_manager.registry.is_installed(TEAM_DIRECTIVES_DIRNAME):
        bundled_path = _locate_bundled_extension(TEAM_DIRECTIVES_DIRNAME)
        if bundled_path and bundled_path.exists():
            ext_manager.install_from_directory(
                bundled_path, speckit_version, priority=1
            )
        else:
            raise RuntimeError(
                f"Bundled extension '{TEAM_DIRECTIVES_DIRNAME}' not found in CLI package"
            )

    # Resolve knowledge base path
    potential_path = Path(repo_url).expanduser()

    if potential_path.exists() and potential_path.is_dir():
        # Validate it's a knowledge base (not an extension)
        has_content = (
            (potential_path / "context_modules").exists()
            or (potential_path / ".skills.json").exists()
            or (potential_path / "CDR.md").exists()
        )
        if not has_content:
            raise ValueError(
                f"Invalid team-ai-directives knowledge base: {potential_path}\n"
                f"Missing expected content (context_modules/, .skills.json, or CDR.md)"
            )
        return ("local", potential_path)

    if repo_url.endswith(".zip") or "/archive/" in repo_url:
        download_dir = (
            project_root / ".specify" / "extensions" / ".cache" / "downloads"
        )
        download_dir.mkdir(parents=True, exist_ok=True)
        zip_path = download_dir / "team-ai-directives-kb.zip"

        try:
            from specify_cli.authentication.http import open_url

            try:
                with open_url(repo_url, timeout=60) as response:
                    zip_data = response.read()
            except urllib.error.HTTPError as e:
                if e.code in (401, 403):
                    raise ValueError(
                        f"Authentication failed accessing {repo_url}\n"
                        f"The repository may be private. Configure authentication "
                        f"in ~/.specify/auth.json"
                    ) from e
                elif e.code == 404:
                    raise ValueError(
                        f"Repository not found: {repo_url}\n"
                        f"Please verify the URL is correct and the repository exists."
                    ) from e
                else:
                    raise
            except urllib.error.URLError as e:
                raise ValueError(
                    f"Failed to download team-ai-directives: {e.reason}\n"
                    f"Check your network connection and the URL."
                ) from e
            zip_path.write_bytes(zip_data)

            # Validate downloaded content
            if not zip_data.startswith(b'PK'):
                content_preview = zip_data[:500].decode('utf-8', errors='replace')
                if '<html' in content_preview.lower():
                    raise ValueError(
                        f"Repository requires authentication: {repo_url}\n"
                        f"The repository may be private."
                    )
                raise ValueError(
                    f"Downloaded file is not a valid ZIP archive: {repo_url}"
                )

            import zipfile

            extract_dir = download_dir / "team-ai-directives-kb-extracted"
            if extract_dir.exists():
                shutil.rmtree(extract_dir)
            extract_dir.mkdir(parents=True, exist_ok=True)

            with zipfile.ZipFile(zip_path, 'r') as zf:
                zf.extractall(extract_dir)

            # Find the actual content directory
            kb_path = extract_dir
            entries = [e for e in kb_path.iterdir() if e.is_dir()]
            if len(entries) == 1 and not (kb_path / "context_modules").exists():
                subdir = entries[0]
                if (
                    (subdir / "context_modules").exists()
                    or (subdir / ".skills.json").exists()
                ):
                    kb_path = subdir

            return ("installed", kb_path)
        finally:
            if zip_path.exists():
                zip_path.unlink()
    else:
        raise ValueError(
            "Invalid team-ai-directives URL. Expected:\n"
            "  - Local directory path\n"
            "  - ZIP file URL (ending in .zip)\n"
            "  - GitHub/GitLab archive URL"
        )


def get_team_directives_path(project_path: Path) -> Path | None:
    """Get team-ai-directives path from init-options or fallback to extensions dir.

    Checks init-options.json first for external/override path, then falls back
    to the standard .specify/extensions/team-ai-directives location.

    Returns None if neither location exists.
    """
    # Import here to avoid circular imports
    from specify_cli import load_init_options

    init_opts = load_init_options(project_path)
    if "team_ai_directives" in init_opts:
        path = Path(init_opts["team_ai_directives"])
        if path.exists():
            return path
    # Fallback to installed extension
    fallback = project_path / ".specify" / "extensions" / TEAM_DIRECTIVES_DIRNAME
    return fallback if fallback.exists() else None


# ----------------------------------------------------------------------------
# Reference Extension Update Helpers
# ----------------------------------------------------------------------------



def pre_init(
    project_path: Path,
    selected_ai: str,
    team_ai_directives: str | None,
    tracker: Any = None,
) -> None:
    """Pre-init hook - team AI directives sync."""
    if tracker:
        tracker.add("team-directives", "Team AI Directives setup")

    if not team_ai_directives:
        if tracker:
            tracker.skip("team-directives", "not specified")
            tracker.skip("team-mcp", "no team-ai-directives")
            tracker.skip("team-skills", "no team-ai-directives")
        return

    tracker.start("team-directives")
    directives_path: Path | None = None

    try:
        # Install bundled extension and resolve knowledge base path
        status, directives_path = sync_team_ai_directives(
            team_ai_directives, project_path, force=True
        )
        tracker.complete("team-directives", f"{status}: {directives_path}")

        # Install MCP config from knowledge base
        if directives_path and (directives_path / ".mcp.json").exists():
            if tracker:
                tracker.start("team-mcp")
            try:
                success, messages, resolved, unresolved = install_mcp_config(
                    directives_path, project_path
                )

                # Parse messages to extract useful info
                installed_servers = []
                merged_servers = []

                for msg in messages:
                    if msg.startswith("    - mcpServers:"):
                        server_name = msg.replace("    - mcpServers: ", "").strip()
                        merged_servers.append(server_name)
                    elif msg.startswith("    - tools:"):
                        tool_name = msg.replace("    - tools: ", "").strip()
                        merged_servers.append(tool_name)

                # Read the config to get server names
                try:
                    mcp_path = project_path / ".mcp.json"
                    if mcp_path.exists():
                        mcp_config = json.loads(mcp_path.read_text())
                        all_servers = list(mcp_config.get("mcpServers", {}).keys())
                        all_tools = list(mcp_config.get("tools", {}).keys())

                        # Determine which servers need env vars
                        for server_name in all_servers + all_tools:
                            if server_name not in merged_servers:
                                installed_servers.append(server_name)
                except Exception:
                    pass

                # Build user-friendly tracker status
                total_items = len(installed_servers) + len(merged_servers)
                status_parts = []

                if total_items > 0:
                    status_parts.append(
                        f"{total_items} server{'s' if total_items > 1 else ''}"
                    )

                if unresolved:
                    status_parts.append(
                        f"{len(unresolved)} need{'s' if len(unresolved) == 1 else ''} setup"
                    )

                if merged_servers:
                    status_parts.append(f"{len(merged_servers)} merged")

                status_msg = ", ".join(status_parts) if status_parts else "installed"

                if success:
                    if tracker:
                        tracker.complete("team-mcp", status_msg)

                    # Print explanatory console output
                    if installed_servers:
                        console.print(
                            f"[dim]  Installed: {', '.join(installed_servers)}[/dim]"
                        )
                    if merged_servers:
                        console.print(
                            f"[dim]  Merged with existing: {', '.join(merged_servers)}[/dim]"
                        )

                    # Show env var hints
                    if unresolved:
                        for var in unresolved[:3]:  # Show first 3
                            console.print(f"[dim]  Needs env var: ${var}[/dim]")
                        if len(unresolved) > 3:
                            console.print(
                                f"[dim]  ... and {len(unresolved) - 3} more[/dim]"
                            )
                        console.print(
                            f"[yellow]  Hint:[/yellow] Set with: export {unresolved[0]}=\"your-value\""
                        )
                else:
                    if tracker:
                        tracker.skip("team-mcp", "validation failed - see warnings")
                # Print all messages
                for msg in messages:
                    console.print(f"[dim]{msg}[/dim]")
            except Exception as e:
                if tracker:
                    tracker.skip("team-mcp", f"skipped: {str(e)[:40]}")
                console.print(
                    f"[yellow]Warning:[/yellow] MCP config installation failed: {e}"
                )
        else:
            # Skip team-mcp step if no .mcp.json
            if tracker:
                tracker.skip("team-mcp", "no .mcp.json found")

        # Install skills from knowledge base
        if directives_path and selected_ai:
            try:
                if tracker:
                    tracker.start("team-skills")
                installed = _install_skills_from_path(
                    team_directives_path=directives_path,
                    project_path=project_path,
                    selected_ai=selected_ai,
                    force=False,
                )
                if installed:
                    if tracker:
                        tracker.complete("team-skills", f"{len(installed)} skills")
                    console.print("[dim]Installed team-ai-directives skills[/dim]")
                else:
                    if tracker:
                        tracker.skip("team-skills", "no required skills found")
            except Exception as e:
                console.print(
                    f"[yellow]Warning:[/yellow] Failed to install skills: {e}"
                )
                if tracker:
                    tracker.error("team-skills", str(e))

    except Exception as e:
        tracker.error("team-directives", str(e))
        console.print(
            f"[yellow]Warning:[/yellow] Failed to sync team AI directives: {e}"
        )
        return

    # Persist to init-options.json separately - failures here are critical
    if directives_path:
        from . import load_init_options, save_init_options

        init_opts = load_init_options(project_path)
        init_opts["team_ai_directives"] = str(directives_path)
        save_init_options(project_path, init_opts)


def post_init(
    project_path: Path,
    selected_ai: str,
    tracker: Any = None,
    no_git: bool = False,
    force: bool = False,
) -> None:
    """Post-init hook - bundled extensions and presets.

    Args:
        no_git: If True, skip installing the git extension (user passed --no-git).
        force: If True, re-register command files even when extension/preset
               version and hash are unchanged (used with ``--force`` reinit).
    """
    if os.environ.get("SPECKIT_SKIP_BUNDLED"):
        if tracker:
            tracker.skip("extensions", "skipped (SPECKIT_SKIP_BUNDLED)")
            tracker.skip("presets", "skipped (SPECKIT_SKIP_BUNDLED)")
        return

    _install_bundled_extensions(project_path, selected_ai, tracker, skip_git=no_git, force=force)
    _install_bundled_presets(project_path, selected_ai, tracker, force=force)

    # Resync the integration manifest — bundled presets may delete/rename
    # skill directories (e.g. speckit-plan/ -> spec-plan/) without updating
    # the integration manifest that was saved during setup().
    _resync_integration_manifest(project_path, selected_ai)


def _resync_integration_manifest(project_path: Path, selected_ai: str) -> None:
    """Re-snapshot the integration manifest after bundled content installation.

    During ``specify init``, the integration manifest is saved *before*
    ``post_init`` runs.  Bundled presets may then:

    * Delete original skill directories (via ``_cleanup_replaced_commands``)
      and create new ones with fork-aliased names (via ``_register_skills``).
    * Overwrite command files (``.agent.md``, ``.md``, ``.toml``) with
      enhanced content from the preset (via ``_register_commands``).

    This function loads the manifest, drops entries whose files no longer
    exist on disk, re-hashes files whose content changed, adds new files
    discovered in the integration directories, and re-saves.
    """
    import hashlib

    from .integrations import get_integration
    from .integrations.manifest import IntegrationManifest

    try:
        integration = get_integration(selected_ai)
    except Exception:
        return

    manifest_path = (
        project_path / ".specify" / "integrations" / f"{selected_ai}.manifest.json"
    )
    if not manifest_path.exists():
        return

    try:
        manifest = IntegrationManifest.load(selected_ai, project_path)
    except Exception:
        return

    current_files = dict(manifest.files)
    changed = False

    # 1. Drop entries whose files no longer exist on disk
    #    and re-hash entries whose content changed.
    for rel_path in list(current_files):
        abs_path = project_path / rel_path
        if not abs_path.exists():
            del current_files[rel_path]
            changed = True
        elif abs_path.is_file():
            new_hash = hashlib.sha256(abs_path.read_bytes()).hexdigest()
            if new_hash != current_files[rel_path]:
                current_files[rel_path] = new_hash
                changed = True

    # 2. Scan integration directories for new files to record.
    agent_dir = project_path / integration.config.get("folder", "")
    commands_subdir = integration.config.get("commands_subdir", "commands")
    scan_dir = agent_dir / commands_subdir

    if scan_dir.is_dir():
        for child in scan_dir.rglob("*"):
            if not child.is_file():
                continue
            try:
                rel = child.relative_to(project_path).as_posix()
            except ValueError:
                continue
            if rel not in current_files:
                current_files[rel] = hashlib.sha256(child.read_bytes()).hexdigest()
                changed = True

    if not changed:
        return

    # Rebuild and re-save the manifest
    manifest._files = current_files
    try:
        manifest.save()
    except Exception:
        pass  # best-effort; don't break init on manifest IO errors


def _install_bundled_extensions(
    project_path: Path,
    selected_ai: str,
    tracker: Any = None,
    skip_git: bool = False,
    force: bool = False,
) -> None:
    """Install bundled extensions with scaffolding support.

    Args:
        skip_git: If True, skip installing the 'git' extension (used when --no-git is passed).
        force: If True, always re-register command files even when version/hash
               are unchanged (ensures files exist on disk after ``--force`` reinit).
    """
    if tracker:
        tracker.add("extensions", "Install bundled extensions")

    from .extensions import ExtensionManager

    project_extensions_dir = project_path / ".specify" / "extensions"

    # Search paths for bundled extensions (now unified in core_pack/extensions/)
    search_paths = [
        (
            Path(__file__).parent / "core_pack" / "extensions",
            Path(__file__).parent / "core_pack" / "extensions" / "catalog.json",
        ),
        (
            Path(__file__).parent.parent.parent / "extensions",
            Path(__file__).parent.parent.parent / "extensions" / "catalog.json",
        ),
        (project_extensions_dir, project_extensions_dir / "catalog.json"),
    ]

    bundled_extensions_dir = None
    catalog_path = None

    for ext_path, cat_path in search_paths:
        if ext_path.exists():
            has_extensions = any(
                (ext_path / d.name / "extension.yml").exists()
                for d in ext_path.iterdir()
                if d.is_dir() and not d.name.startswith(".")
            )
            if has_extensions:
                bundled_extensions_dir = ext_path
                if cat_path.exists():
                    catalog_path = cat_path
                break

    if not bundled_extensions_dir:
        if tracker:
            tracker.skip("extensions", "bundled extensions not found")
        return

    if bundled_extensions_dir != project_extensions_dir:
        # Build list of extensions to skip during scaffolding
        skip_list = ["git"] if skip_git else []
        scaffolded = _scaffold_extensions_to_project(
            bundled_extensions_dir, project_extensions_dir, skip_extensions=skip_list
        )
        if scaffolded:
            console.print(f"[dim]Scaffolded extensions: {', '.join(scaffolded)}[/dim]")

        if catalog_path and not (project_extensions_dir / "catalog.json").exists():
            shutil.copy2(catalog_path, project_extensions_dir / "catalog.json")
        catalog_path = project_extensions_dir / "catalog.json"

    bundled_extensions_dir = project_extensions_dir

    bundled_extensions = []
    if catalog_path and catalog_path.exists():
        try:
            with open(catalog_path) as f:
                catalog_data = json.load(f)
            extensions = catalog_data.get("extensions", {})
            bundled_extensions = [
                ext_id
                for ext_id, ext_data in extensions.items()
                if ext_data.get("preinstall", False)
                and (bundled_extensions_dir / ext_id / "extension.yml").exists()
            ]
        except (json.JSONDecodeError, IOError) as e:
            console.print(
                f"[yellow]Warning:[/yellow] Failed to parse catalog.json: {e}"
            )

    if bundled_extensions:
        from .extensions import ExtensionManager, HookExecutor
        from .extensions import CommandRegistrar as ExtCommandRegistrar

        manager = ExtensionManager(project_path)
        registry = manager.registry
        hook_executor = HookExecutor(project_path)
        cmd_registrar = ExtCommandRegistrar()

    installed = []
    skipped = []

    for ext_name in bundled_extensions:
        # Skip git extension if --no-git was passed
        if skip_git and ext_name == "git":
            skipped.append(f"{ext_name} (--no-git)")
            continue

        ext_dir = bundled_extensions_dir / ext_name
        if not ext_dir.exists() or not (ext_dir / "extension.yml").exists():
            skipped.append(f"{ext_name} (not found)")
            continue

        try:
            from .extensions import ExtensionManifest

            manifest_path = ext_dir / "extension.yml"
            manifest = ExtensionManifest(manifest_path)

            # Check if already installed - compare versions for update
            if not force and registry.is_installed(ext_name):
                from packaging.version import Version

                existing = registry.get(ext_name)
                existing_version = existing.get("version", "0") if existing else "0"
                existing_hash = existing.get("manifest_hash", "") if existing else ""

                try:
                    new_hash = manifest.get_hash()
                    version_changed = Version(manifest.version) > Version(
                        existing_version
                    )
                    hash_changed = new_hash != existing_hash

                    if version_changed or hash_changed:
                        # Update to newer version or manifest changed - re-register commands/skills/hooks
                        registered_commands = cmd_registrar.register_commands_for_all_agents(
                            manifest, ext_dir, project_path
                        )
                        registered_skills = manager._register_extension_skills(
                            manifest, ext_dir
                        )

                        # Register hooks (creates/updates .specify/extensions.yml)
                        hook_executor.register_hooks(manifest)

                        registry.update(
                            ext_name,
                            {
                                "version": manifest.version,
                                "manifest_hash": new_hash,
                                "registered_commands": registered_commands,
                                "registered_skills": registered_skills,
                            },
                        )
                        installed.append(ext_name)
                    else:
                        skipped.append(f"{ext_name} (existing)")
                        continue
                except Exception:
                    # Invalid version format - skip
                    skipped.append(f"{ext_name} (existing)")
                    continue

                continue

            # New installation
            registered_commands = cmd_registrar.register_commands_for_all_agents(
                manifest, ext_dir, project_path
            )

            registered_skills = manager._register_extension_skills(manifest, ext_dir)

            # Register hooks (creates/updates .specify/extensions.yml)
            hook_executor.register_hooks(manifest)

            registry.add(
                ext_name,
                {
                    "version": manifest.version,
                    "source": "local",
                    "manifest_hash": manifest.get_hash(),
                    "enabled": True,
                    "priority": 10,
                    "registered_commands": registered_commands,
                    "registered_skills": registered_skills,
                },
            )
            installed.append(ext_name)
        except Exception as e:
            skipped.append(f"{ext_name} ({str(e)[:40]})")

    if tracker:
        if installed and skipped:
            tracker.complete(
                "extensions",
                f"{', '.join(sorted(installed))} (skipped: {', '.join(skipped)})",
            )
        elif installed:
            tracker.complete("extensions", f"{', '.join(sorted(installed))}")
        elif skipped:
            tracker.skip("extensions", f"{', '.join(skipped)}")
        else:
            tracker.skip("extensions", "none available")


def _install_bundled_presets(
    project_path: Path,
    selected_ai: str,
    tracker: Any = None,
    force: bool = False,
) -> None:
    """Install bundled presets with scaffolding support.

    Args:
        force: If True, always re-register command files even when version
               is unchanged (ensures files exist on disk after ``--force`` reinit).
    """
    if tracker:
        tracker.add("presets", "Install bundled presets")

    from .presets import PresetManager

    project_presets_dir = project_path / ".specify" / "presets"

    search_paths = [
        Path(__file__).parent.parent.parent / "presets",
        Path(__file__).parent / "bundled_presets",
        project_presets_dir,
    ]

    bundled_presets_dir = None

    for preset_path in search_paths:
        if preset_path.exists():
            has_presets = any(
                (preset_path / d / "preset.yml").exists()
                for d in preset_path.iterdir()
                if d.is_dir() and not d.name.startswith(".")
            )
            if has_presets:
                bundled_presets_dir = preset_path
                break

    if not bundled_presets_dir:
        if tracker:
            tracker.skip("presets", "bundled presets not found")
        return

    if bundled_presets_dir != project_presets_dir:
        scaffolded = _scaffold_presets_to_project(
            bundled_presets_dir, project_presets_dir
        )
        if scaffolded:
            console.print(f"[dim]Scaffolded presets: {', '.join(scaffolded)}[/dim]")

    bundled_presets_dir = project_presets_dir

    # Read catalog.json to filter by preinstall flag
    catalog_path = bundled_presets_dir / "catalog.json"
    bundled_presets = []
    if catalog_path.exists():
        try:
            with open(catalog_path) as f:
                catalog_data = json.load(f)
            presets = catalog_data.get("presets", {})
            bundled_presets = [
                preset_id
                for preset_id, preset_data in presets.items()
                if preset_data.get("preinstall", False)
                and (bundled_presets_dir / preset_id / "preset.yml").exists()
            ]
        except (json.JSONDecodeError, IOError) as e:
            console.print(
                f"[yellow]Warning:[/yellow] Failed to parse presets catalog.json: {e}"
            )

    if not bundled_presets:
        if tracker:
            tracker.skip("presets", "no presets to install")
        return

    if bundled_presets:
        from .presets import PresetManager

        manager = PresetManager(project_path)
        registry = manager.registry

    installed = []
    skipped = []

    for preset_name in bundled_presets:
        preset_dir = bundled_presets_dir / preset_name
        if not preset_dir.exists() or not (preset_dir / "preset.yml").exists():
            skipped.append(f"{preset_name} (not found)")
            continue

        try:
            bundled_version = _read_preset_version(preset_dir)

            if not force and registry.is_installed(preset_name):
                reg_entry = registry.get(preset_name)
                installed_version = reg_entry.get("version") if reg_entry else None

                if bundled_version and installed_version:
                    try:
                        if version.parse(bundled_version) <= version.parse(installed_version):
                            skipped.append(f"{preset_name} (existing v{installed_version})")
                            continue
                    except Exception:
                        pass
                else:
                    skipped.append(f"{preset_name} (existing)")
                    continue

            from .presets import PresetManifest

            manifest = PresetManifest(preset_dir / "preset.yml")

            registered_commands = manager._register_commands(manifest, preset_dir)
            registered_skills = manager._register_skills(manifest, preset_dir)

            registry.add(
                preset_name,
                {
                    "version": manifest.version,
                    "source": "local",
                    "manifest_hash": manifest.get_hash(),
                    "enabled": True,
                    "priority": 10,
                    "registered_commands": registered_commands,
                    "registered_skills": registered_skills,
                },
            )
            installed.append(preset_name)
        except Exception as e:
            skipped.append(f"{preset_name} ({str(e)[:40]})")

    if tracker:
        if installed and skipped:
            tracker.complete(
                "presets",
                f"{', '.join(sorted(installed))} (skipped: {', '.join(skipped)})",
            )
        elif installed:
            tracker.complete("presets", f"{', '.join(sorted(installed))}")
        elif skipped:
            tracker.skip("presets", f"{', '.join(skipped)}")
        else:
            tracker.skip("presets", "none available")


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
# TEAM AI DIRECTIVES SKILL INSTALLATION
# ============================================================================


def _install_skills_from_path(
    team_directives_path: Path | None,
    project_path: Path,
    selected_ai: str,
    force: bool = False,
) -> list[str]:
    """Install team-ai-directives skills to agent integration directory.
    
    Reads skills from:
    - team-ai-directives (if configured): .specify/extensions/team-ai-directives/skills/
    - local skills: .specify/skills/
    
    Args:
        team_directives_path: Path to team-ai-directives extension (or None)
        project_path: Project root
        selected_ai: Agent type (claude, windsurf, etc.)
        force: Force re-install even if skill already exists
    
    Returns:
        List of installed skill names
    
    Raises:
        Exception: If skill installation fails
    """
    from .integrations import INTEGRATION_REGISTRY
    from .integrations.base import SkillsIntegration
    
    if selected_ai not in INTEGRATION_REGISTRY:
        raise ValueError(f"Unknown agent: {selected_ai}. Available: {', '.join(INTEGRATION_REGISTRY.keys())}")
    
    integration = INTEGRATION_REGISTRY[selected_ai]
    
    # Determine skills directory based on integration type:
    # - SkillsIntegration: commands ARE skills → use skills_dest() (same dir as commands)
    # - Others: skills are separate → use folder + "skills" (agentskills.io convention)
    if isinstance(integration, SkillsIntegration):
        skills_dest = integration.skills_dest(project_path)
    else:
        folder = integration.config.get("folder", "")
        skills_dest = project_path / folder / "skills"
    
    installed = []
    
    # 1. Install team-ai-directives skills (with team- prefix)
    if team_directives_path and team_directives_path.exists():
        team_skills_dir = team_directives_path / "skills"
        if team_skills_dir.exists():
            # Parse .skills.json to get required skills
            skills_json_path = team_directives_path / ".skills.json"
            required_skills = []
            if skills_json_path.exists():
                try:
                    import json
                    with open(skills_json_path) as f:
                        skills_data = json.load(f)
                    required_skills = skills_data.get("skills", {}).get("required", {})
                except Exception:
                    pass
            
            # Get list of skill directories
            for skill_dir in team_skills_dir.iterdir():
                if not skill_dir.is_dir():
                    continue
                
                skill_name = skill_dir.name
                skill_md = skill_dir / "SKILL.md"
                if not skill_md.exists():
                    continue
                
                # Check if skill is in required list (only install required)
                skill_ref = f"local:./skills/{skill_name}"
                if skill_ref not in required_skills and required_skills:
                    continue
                
                # Install with team- prefix
                target_name = f"team-{skill_name}"
                target_dir = skills_dest / target_name
                target_file = target_dir / "SKILL.md"
                
                if target_file.exists() and not force:
                    continue
                
                # Create target directory
                target_dir.mkdir(parents=True, exist_ok=True)
                
                # Copy SKILL.md with modified name field
                try:
                    content = skill_md.read_text(encoding="utf-8")
                    
                    # Update the name field in frontmatter to include team- prefix
                    # This ensures compliance with agentskills.io specification
                    # (name field must match parent directory name)
                    import re
                    
                    # Pattern to match name: value in YAML frontmatter
                    # Matches: name: skill-name or name: "skill-name" or name: 'skill-name'
                    name_pattern = r'^(name:\s*)(["\']?)([^"\'\n]+)(["\']?)$'
                    
                    lines = content.splitlines()
                    modified_lines = []
                    in_frontmatter = False
                    frontmatter_started = False
                    
                    for line in lines:
                        stripped = line.strip()
                        
                        # Track if we're in frontmatter
                        if stripped == '---':
                            if not frontmatter_started:
                                frontmatter_started = True
                                in_frontmatter = True
                            else:
                                in_frontmatter = False
                            modified_lines.append(line)
                            continue
                        
                        # Update name field while in frontmatter
                        if in_frontmatter and stripped.startswith('name:'):
                            match = re.match(name_pattern, stripped)
                            if match:
                                original_name = match.group(3).strip()
                                # Add team- prefix if not already present
                                if not original_name.startswith('team-'):
                                    new_name = f"team-{original_name}"
                                else:
                                    new_name = original_name
                                # Preserve original indentation and quotes
                                indent = line[:len(line) - len(line.lstrip())]
                                modified_lines.append(f"{indent}name: {new_name}")
                                continue
                        
                        modified_lines.append(line)
                    
                    modified_content = '\n'.join(modified_lines)
                    target_file.write_text(modified_content, encoding="utf-8")
                    installed.append(target_name)
                except Exception as e:
                    raise Exception(f"Failed to install {target_name}: {e}")
    
    # 2. Install local skills (without prefix)
    local_skills_dir = project_path / ".specify" / "skills"
    if local_skills_dir.exists():
        for skill_dir in local_skills_dir.iterdir():
            if not skill_dir.is_dir():
                continue
            
            skill_name = skill_dir.name
            skill_md = skill_dir / "SKILL.md"
            if not skill_md.exists():
                continue
            
            # Skip if it's a team-prefixed skill (already installed above)
            if skill_name.startswith("team-"):
                continue
            
            target_dir = skills_dest / skill_name
            target_file = target_dir / "SKILL.md"
            
            if target_file.exists() and not force:
                continue
            
            target_dir.mkdir(parents=True, exist_ok=True)
            
            try:
                content = skill_md.read_text(encoding="utf-8")
                target_file.write_text(content, encoding="utf-8")
                installed.append(skill_name)
            except Exception as e:
                raise Exception(f"Failed to install {skill_name}: {e}")
    
    return installed


