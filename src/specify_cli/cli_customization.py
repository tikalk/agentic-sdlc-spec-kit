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
import shutil
import typer
from pathlib import Path
from typing import Any, Optional

from rich.console import Console

# ============================================================================
# THEMING
# ============================================================================

# Tikalk orange accent color (replaces upstream cyan)
ACCENT_COLOR = "#f47721"

# Banner gradient colors for the CLI header
BANNER_COLORS = ["#ff6b35", "#ff8c42", "#f47721", "#ff5722", "white", "bright_white"]


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


# ============================================================================
# EXTENSION NAMESPACES
# ============================================================================

# Command namespaces allowed in extension commands
# Upstream only allows "speckit", fork also allows "adlc"
EXTENSION_NAMESPACES = ["speckit", "adlc"]

# Enable short alias format: {extension}.{command} (e.g., architect.init)
EXTENSION_ALIAS_PATTERN_ENABLED = True


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


# ============================================================================
# TEAM DIRECTIVES
# ============================================================================

# Directory name for team directives repository
TEAM_DIRECTIVES_DIRNAME = "team-ai-directives"


# ============================================================================
# INIT HOOKS - Tikalk-specific pre/post init callbacks
# ============================================================================

console = Console()


def _scaffold_extensions_to_project(
    source_dir: Path,
    project_dir: Path,
) -> list[str]:
    """Scaffold extension folders from source to project if missing or empty."""
    scaffolded = []

    if not source_dir.exists():
        return scaffolded

    project_dir.mkdir(parents=True, exist_ok=True)

    for ext_dir in source_dir.iterdir():
        if not ext_dir.is_dir() or ext_dir.name.startswith("."):
            continue

        proj_ext = project_dir / ext_dir.name

        if (proj_ext / "extension.yml").exists():
            continue

        if proj_ext.exists():
            for src in ext_dir.rglob("*"):
                if src.is_file():
                    dst = proj_ext / src.relative_to(ext_dir)
                    if not dst.exists():
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


def _scaffold_presets_to_project(
    source_dir: Path,
    project_dir: Path,
) -> list[str]:
    """Scaffold preset folders from source to project if missing or empty."""
    scaffolded = []

    if not source_dir.exists():
        return scaffolded

    project_dir.mkdir(parents=True, exist_ok=True)

    for preset_dir in source_dir.iterdir():
        if not preset_dir.is_dir() or preset_dir.name.startswith("."):
            continue

        proj_preset = project_dir / preset_dir.name

        if (proj_preset / "preset.yml").exists():
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


def pre_init(
    project_path: Path,
    selected_ai: str,
    team_ai_directives: str | None,
    tracker: Any = None,
) -> None:
    """Pre-init hook - team AI directives sync."""
    if not team_ai_directives:
        if tracker:
            tracker.skip("team-directives", "not specified")
        return

    from . import sync_team_ai_directives

    tracker.start("team-directives")
    try:
        status, directives_path = sync_team_ai_directives(
            team_ai_directives, project_path
        )
        if status == "cloned":
            tracker.complete("team-directives", f"cloned to {directives_path}")
        elif status == "updated":
            tracker.complete("team-directives", f"updated at {directives_path}")
        elif status == "local":
            tracker.complete("team-directives", f"local: {directives_path}")
        os.environ["SPECIFY_TEAM_DIRECTIVES"] = str(directives_path)
    except Exception as e:
        tracker.error("team-directives", str(e))
        console.print(
            f"[yellow]Warning:[/yellow] Failed to sync team AI directives: {e}"
        )


def post_init(
    project_path: Path,
    selected_ai: str,
    tracker: Any = None,
) -> None:
    """Post-init hook - bundled extensions and presets."""
    if os.environ.get("SPECKIT_SKIP_BUNDLED"):
        if tracker:
            tracker.skip("extensions", "skipped (SPECKIT_SKIP_BUNDLED)")
            tracker.skip("presets", "skipped (SPECKIT_SKIP_BUNDLED)")
        return

    _install_bundled_extensions(project_path, selected_ai, tracker)
    _install_bundled_presets(project_path, selected_ai, tracker)


def _install_bundled_extensions(
    project_path: Path,
    selected_ai: str,
    tracker: Any = None,
) -> None:
    """Install bundled extensions with scaffolding support."""
    from .extensions import ExtensionManager

    project_extensions_dir = project_path / ".specify" / "extensions"

    search_paths = [
        (
            Path(__file__).parent.parent.parent / "extensions",
            Path(__file__).parent.parent.parent / "extensions" / "catalog.json",
        ),
        (
            Path(__file__).parent / "bundled_extensions",
            Path(__file__).parent / "bundled_extensions" / "catalog.json",
        ),
        (project_extensions_dir, project_extensions_dir / "catalog.json"),
    ]

    bundled_extensions_dir = None
    catalog_path = None

    for ext_path, cat_path in search_paths:
        if ext_path.exists():
            has_extensions = any(
                (ext_path / d / "extension.yml").exists()
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
        scaffolded = _scaffold_extensions_to_project(
            bundled_extensions_dir, project_extensions_dir
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
            if not bundled_extensions:
                bundled_extensions = [
                    ext_id
                    for ext_id in extensions.keys()
                    if (bundled_extensions_dir / ext_id / "extension.yml").exists()
                ]
        except (json.JSONDecodeError, IOError) as e:
            console.print(
                f"[yellow]Warning:[/yellow] Failed to parse catalog.json: {e}"
            )

    if not bundled_extensions:
        bundled_extensions = [
            d.name
            for d in bundled_extensions_dir.iterdir()
            if d.is_dir()
            and not d.name.startswith(".")
            and (d / "extension.yml").exists()
        ]

    if bundled_extensions:
        from .extensions import ExtensionManager

        manager = ExtensionManager(project_path)
        registry = manager.registry

        from .extensions import CommandRegistrar

        registrar = CommandRegistrar()

    installed = []
    skipped = []

    for ext_name in bundled_extensions:
        ext_dir = bundled_extensions_dir / ext_name
        if not ext_dir.exists() or not (ext_dir / "extension.yml").exists():
            skipped.append(f"{ext_name} (not found)")
            continue

        try:
            if registry.is_installed(ext_name):
                skipped.append(f"{ext_name} (existing)")
                continue

            from .extensions import ExtensionManifest

            manifest_path = ext_dir / "extension.yml"
            manifest = ExtensionManifest(manifest_path)

            registered_commands = registrar.register_commands_for_all_agents(
                manifest, ext_dir, project_path
            )

            registered_skills = manager._register_extension_skills(manifest, ext_dir)

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
) -> None:
    """Install bundled presets with scaffolding support."""
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

    bundled_presets = [
        d.name
        for d in bundled_presets_dir.iterdir()
        if d.is_dir() and not d.name.startswith(".") and (d / "preset.yml").exists()
    ]

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
            if registry.is_installed(preset_name):
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
# SKILL COMMANDS - Tikalk fork skill package manager CLI
# ============================================================================

# Import core skills modules (already exist in upstream skills/ package)
try:
    from .skills import (
        SkillsManifest,
        SkillInstaller,
        SkillEvaluator,
        SkillsRegistryClient,
    )
    from .skills.manifest import TeamSkillsManifest

    SKILLS_AVAILABLE = True
except ImportError:
    SKILLS_AVAILABLE = False


# Skill descriptions for backward compatibility
SKILL_DESCRIPTIONS = {
    "skills-shell-basics": "Essential shell/terminal skills for developers",
    "skills-git-advanced": "Advanced Git workflows and branching strategies",
    "skills-python-debugging": "Debugging techniques and tools for Python",
    "skills-docker-fundamentals": "Containerization fundamentals with Docker",
}


def _load_config(project_path: Path) -> dict:
    """Load project configuration."""
    config_path = project_path / ".specify" / "config.json"
    if config_path.exists():
        try:
            import json

            return json.loads(config_path.read_text())
        except Exception:
            return {}
    return None


def _get_skills_config() -> dict:
    """Get skills configuration from environment or defaults."""
    return {
        "auto_activation_threshold": 0.8,
        "max_auto_skills": 5,
        "preserve_user_edits": True,
        "registry_url": "https://skills.sh/api",
        "evaluation_required": False,
    }


def _set_skills_config(key: str, value) -> None:
    """Set skills configuration (placeholder - could persist to config file)."""
    pass


# Build skill_app Typer instance
skill_app = typer.Typer(
    name="skill",
    help=accent("Manage agent skills - search, install, update, and evaluate skills"),
    add_completion=False,
    invoke_without_command=True,
)


@skill_app.callback()
def skill_callback(ctx: typer.Context):
    """Show skills help when no subcommand is provided."""
    if ctx.invoked_subcommand is None:
        console.print(f"\n{accent('Agentic SDLC Skills')}\n")
        console.print("[dim]Use specify skill --help for available commands[/dim]")


@skill_app.command("search")
def skill_search(
    query: str = typer.Argument(..., help="Search query for skills"),
    category: Optional[str] = typer.Option(
        None, "--category", "-c", help="Filter by category"
    ),
    min_score: Optional[int] = typer.Option(
        None, "--min-score", "-s", help="Minimum evaluation score"
    ),
    limit: int = typer.Option(20, "--limit", "-l", help="Maximum results to return"),
    json_output: bool = typer.Option(
        False, "--json", "-j", help="Output as JSON for scripting"
    ),
):
    """Search for skills in the skills.sh registry."""
    if not SKILLS_AVAILABLE:
        console.print("[red]Skills module not available[/red]")
        raise typer.Exit(1)

    registry = SkillsRegistryClient()
    results = registry.search(query, limit=limit, min_installs=0)

    # Filter by category if specified
    if category:
        results = [
            r
            for r in results
            if category.lower() in [c.lower() for c in (r.categories or [])]
        ]

    # Filter by score if specified
    if min_score:
        console.print(
            "[yellow]Note:[/yellow] Score filtering not available in registry search"
        )

    if json_output:
        import json as json_module

        output = [
            {
                "name": r.name,
                "owner": r.owner,
                "repo": r.repo,
                "description": r.description,
                "installs": r.installs,
                "categories": r.categories,
                "skill_ref": r.skill_ref,
            }
            for r in results
        ]
        console.print(json_module.dumps(output, indent=2))
    else:
        if not results:
            console.print(f"[yellow]No skills found matching '{query}'[/yellow]")
            return

        console.print(
            f"\n[bold]Found {len(results)} skills matching '{query}':[/bold]\n"
        )

        for r in results:
            console.print(accent(r.name))
            if r.description:
                console.print(f"  {r.description}")
            if r.installs:
                console.print(f"  [dim]Installs: {r.installs:,}[/dim]")
            if r.categories:
                console.print(f"  [dim]Categories: {', '.join(r.categories)}[/dim]")
            console.print(
                f"  [cyan]Install: specify skill install {r.skill_ref}[/cyan]"
            )
            console.print()


@skill_app.command("install")
def skill_install(
    skill_ref: str = typer.Argument(
        ...,
        help="Skill reference (github:org/repo/skill, local:./path, or registry:name)",
    ),
    version: Optional[str] = typer.Option(
        None, "--version", "-v", help="Specific version to install"
    ),
    no_save: bool = typer.Option(
        False, "--no-save", help="Don't save to skills.json manifest"
    ),
    force: bool = typer.Option(
        False, "--force", "-f", help="Reinstall even if already installed"
    ),
    evaluate: bool = typer.Option(
        False, "--eval", "-e", help="Run evaluation after install"
    ),
    skip_blocked_check: bool = typer.Option(
        False, "--skip-blocked-check", help="Skip team blocked skills check"
    ),
):
    """Install a skill from various sources."""
    if not SKILLS_AVAILABLE:
        console.print("[red]Skills module not available[/red]")
        raise typer.Exit(1)

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)

    # Check for team manifest and blocked skills enforcement
    team_manifest = None
    if not skip_blocked_check:
        config = _load_config(project_path)
        team_directives_path = (
            config.get("team_directives", {}).get("path") if config else None
        )
        if not team_directives_path:
            default_path = project_path / ".specify" / "memory" / "team-ai-directives"
            if default_path.exists():
                team_directives_path = str(default_path)

        if team_directives_path:
            team_directives = Path(team_directives_path)
            if team_directives.exists():
                team_manifest = TeamSkillsManifest(team_directives)
                if team_manifest.exists() and team_manifest.should_enforce_blocked():
                    blocked = team_manifest.get_blocked_skills()
                    for blocked_skill in blocked:
                        if blocked_skill in skill_ref or skill_ref in blocked_skill:
                            console.print(
                                f"[red]✗ Skill blocked by team policy:[/red] {skill_ref}\n"
                                f"  Blocked pattern: {blocked_skill}\n"
                                f"  Use --skip-blocked-check to override (not recommended)"
                            )
                            raise typer.Exit(1)

    installer = SkillInstaller(manifest, team_manifest)

    console.print(f"{accent('Installing skill:')} {skill_ref}")

    success, message = installer.install(
        skill_ref, version=version, save=not no_save, force=force
    )

    if success:
        console.print(f"[green]✓[/green] {message}")

        if evaluate:
            console.print(f"\n{accent('Running evaluation...')}")
            skills_dir = manifest.skills_dir
            if skills_dir.exists():
                for skill_dir in skills_dir.iterdir():
                    if skill_dir.is_dir():
                        evaluator = SkillEvaluator()
                        result = evaluator.evaluate_review(skill_dir)
                        console.print(
                            f"\nReview Score: {result.total_score}/{result.max_score} ({result.rating})"
                        )
                        break
    else:
        console.print(f"[red]✗[/red] {message}")
        raise typer.Exit(1)


@skill_app.command("update")
def skill_update(
    skill_name: Optional[str] = typer.Argument(
        None, help="Skill name to update (or all if not specified)"
    ),
    all_skills: bool = typer.Option(
        False, "--all", "-a", help="Update all installed skills"
    ),
    dry_run: bool = typer.Option(
        False, "--dry-run", "-n", help="Show what would be updated without updating"
    ),
):
    """Update installed skills to latest versions."""
    if not SKILLS_AVAILABLE:
        console.print("[red]Skills module not available[/red]")
        raise typer.Exit(1)

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)
    installer = SkillInstaller(manifest)

    if not manifest.exists():
        console.print("[yellow]No skills.json found. No skills installed.[/yellow]")
        return

    if skill_name:
        success, message, updates = installer.update(skill_name, dry_run=dry_run)
    elif all_skills:
        success, message, updates = installer.update(None, dry_run=dry_run)
    else:
        console.print(
            "[yellow]Specify a skill name or use --all to update all skills[/yellow]"
        )
        return

    if success:
        console.print(f"[green]✓[/green] {message}")
        if updates:
            for skill_id, status in updates.items():
                console.print(f"  - {skill_id}: {status}")
    else:
        console.print(f"[red]✗[/red] {message}")


@skill_app.command("remove")
def skill_remove(
    skill_name: str = typer.Argument(..., help="Skill name to remove"),
    force: bool = typer.Option(
        False, "--force", "-f", help="Remove without confirmation"
    ),
):
    """Remove an installed skill."""
    if not SKILLS_AVAILABLE:
        console.print("[red]Skills module not available[/red]")
        raise typer.Exit(1)

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)

    if not manifest.exists():
        console.print("[yellow]No skills.json found. No skills installed.[/yellow]")
        return

    skills = manifest.list_skills()
    skill_id = None

    for sid in skills.keys():
        if skill_name in sid:
            skill_id = sid
            break

    if not skill_id:
        console.print(f"[red]Skill not found:[/red] {skill_name}")
        raise typer.Exit(1)

    if not force:
        confirm = typer.confirm(f"Remove {skill_id}?")
        if not confirm:
            console.print("Cancelled")
            return

    installer = SkillInstaller(manifest)
    success, message = installer.uninstall(skill_id)

    if success:
        console.print(f"[green]✓[/green] {message}")
    else:
        console.print(f"[red]✗[/red] {message}")


@skill_app.command("list")
def skill_list(
    outdated: bool = typer.Option(
        False, "--outdated", "-o", help="Show only outdated skills"
    ),
    json_output: bool = typer.Option(
        False, "--json", "-j", help="Output as JSON for scripting"
    ),
):
    """List installed skills."""
    if not SKILLS_AVAILABLE:
        console.print("[red]Skills module not available[/red]")
        raise typer.Exit(1)

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)

    if not manifest.exists():
        console.print("[yellow]No skills.json found. No skills installed.[/yellow]")
        console.print(
            "[dim]Run 'specify skill install <skill>' to install skills[/dim]"
        )
        return

    skills = manifest.list_skills()

    if not skills:
        console.print("[yellow]No skills installed.[/yellow]")
        console.print("[dim]Run 'specify skill search <query>' to find skills[/dim]")
        return

    if json_output:
        import json as json_module

        output = {
            skill_id: {
                "version": m.version,
                "source": m.source,
                "installed_at": m.installed_at,
                "evaluation": (
                    {
                        "review_score": m.evaluation.review_score,
                        "task_score": m.evaluation.task_score,
                    }
                    if m.evaluation
                    else None
                ),
            }
            for skill_id, m in skills.items()
        }
        console.print(json_module.dumps(output, indent=2))
    else:
        console.print(f"\n[bold]Installed Skills ({len(skills)}):[/bold]\n")

        for skill_id, metadata in skills.items():
            eval_info = ""
            if metadata.evaluation:
                review = metadata.evaluation.review_score
                task = metadata.evaluation.task_score
                if review is not None or task is not None:
                    scores = []
                    if review is not None:
                        scores.append(f"Review: {review}")
                    if task is not None:
                        scores.append(f"Task: {task}")
                    eval_info = f" ({', '.join(scores)})"

            console.print(f"{accent(skill_id)}@{metadata.version}")
            console.print(f"  Source: {metadata.source}")
            console.print(f"  Installed: {metadata.installed_at[:10]}{eval_info}")
            console.print()


@skill_app.command("eval")
def skill_eval(
    skill_path: str = typer.Argument(
        ..., help="Path to skill directory or installed skill name"
    ),
    review: bool = typer.Option(
        False, "--review", "-r", help="Run review evaluation only"
    ),
    task: bool = typer.Option(False, "--task", "-t", help="Run task evaluation only"),
    full: bool = typer.Option(
        False, "--full", "-f", help="Run both review and task evaluations"
    ),
    report: bool = typer.Option(
        False, "--report", help="Show detailed check-by-check report"
    ),
):
    """Evaluate skill quality."""
    if not SKILLS_AVAILABLE:
        console.print("[red]Skills module not available[/red]")
        raise typer.Exit(1)

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)
    evaluator = SkillEvaluator()

    skill_path_obj = Path(skill_path)

    if not skill_path_obj.exists():
        if manifest.exists():
            skills_dir = manifest.skills_dir
            if skills_dir.exists():
                for skill_dir in skills_dir.iterdir():
                    if skill_dir.is_dir() and skill_path in skill_dir.name:
                        skill_path_obj = skill_dir
                        break

    if not skill_path_obj.exists():
        console.print(f"[red]Skill not found:[/red] {skill_path}")
        raise typer.Exit(1)

    console.print(f"\n{accent('Evaluating skill:')} {skill_path_obj.name}\n")

    # Run review evaluation (default if no flags)
    if review or full or (not review and not task):
        result = evaluator.evaluate_review(skill_path_obj)

        console.print(
            f"[bold]Review Score:[/bold] {result.total_score}/{result.max_score} ({result.rating})"
        )
        console.print()

        console.print("[bold]Breakdown:[/bold]")
        for category, score in result.breakdown.items():
            console.print(f"  {category}: {score} points")

        if report:
            console.print()
            console.print("[bold]Detailed Checks:[/bold]")
            for check in result.checks:
                if check.passed:
                    console.print(
                        f"  [green]✓[/green] {check.name} ({check.points}/{check.max_points})"
                    )
                else:
                    console.print(
                        f"  [red]✗[/red] {check.name} ({check.points}/{check.max_points})"
                    )
                    if check.message:
                        console.print(f"    [dim]{check.message}[/dim]")

    if task or full:
        console.print()
        console.print(
            "[yellow]Note:[/yellow] Task evaluation requires test scenarios (not yet available)"
        )


@skill_app.command("sync-team")
def skill_sync_team(
    dry_run: bool = typer.Option(
        False, "--dry-run", "-n", help="Show what would be synced without syncing"
    ),
    force: bool = typer.Option(
        False, "--force", "-f", help="Force reinstall of all team skills"
    ),
):
    """Sync with team skills manifest (install required, suggest recommended)."""
    if not SKILLS_AVAILABLE:
        console.print("[red]Skills module not available[/red]")
        raise typer.Exit(1)

    project_path = Path.cwd()
    config = _load_config(project_path)

    team_directives_path = (
        config.get("team_directives", {}).get("path") if config else None
    )
    if not team_directives_path:
        default_path = project_path / ".specify" / "memory" / "team-ai-directives"
        if default_path.exists():
            team_directives_path = str(default_path)

    if not team_directives_path:
        console.print(
            "[yellow]No team directives configured.[/yellow]\n"
            "Run 'specify init --team-ai-directives <path-or-url>' to configure."
        )
        return

    team_directives = Path(team_directives_path)
    if not team_directives.exists():
        console.print(f"[red]Team directives not found:[/red] {team_directives}")
        return

    team_manifest = TeamSkillsManifest(team_directives)
    if not team_manifest.exists():
        console.print(
            f"[yellow]No .skills.json found in team directives.[/yellow]\n"
            f"Expected at: {team_directives / '.skills.json'}"
        )
        return

    manifest = SkillsManifest(project_path)
    installer = SkillInstaller(manifest, team_manifest)

    required = team_manifest.get_required_skills()
    recommended = team_manifest.get_recommended_skills()
    blocked = team_manifest.get_blocked_skills()

    console.print(f"\n{accent('Team Skills Manifest:')}")
    console.print(f"  Required: {len(required)}")
    console.print(f"  Recommended: {len(recommended)}")
    console.print(f"  Blocked: {len(blocked)}")
    console.print()

    if required:
        console.print("[bold]Required Skills:[/bold]")
        for skill_ref, version_spec in required.items():
            current = manifest.get_skill(skill_ref)
            if current and not force:
                console.print(
                    f"  [green]✓[/green] {skill_ref}@{current.version} (already installed)"
                )
            else:
                if dry_run:
                    console.print(f"  [cyan]→[/cyan] Would install: {skill_ref}")
                else:
                    if isinstance(version_spec, dict):
                        version_str = version_spec.get("version", "*")
                        version = (
                            version_str.lstrip("^~") if version_str != "*" else None
                        )
                    else:
                        version = (
                            version_spec.lstrip("^~") if version_spec != "*" else None
                        )
                    success, message = installer.install(
                        skill_ref, version=version, force=force
                    )
                    if success:
                        console.print(f"  [green]✓[/green] {message}")
                    else:
                        console.print(f"  [red]✗[/red] {message}")

    if recommended:
        console.print()
        console.print("[bold]Recommended Skills (not auto-installed):[/bold]")
        for skill_ref, version_spec in recommended.items():
            current = manifest.get_skill(skill_ref)
            if current:
                console.print(
                    f"  [green]✓[/green] {skill_ref}@{current.version} (installed)"
                )
            else:
                skill_desc = ""
                if isinstance(version_spec, dict):
                    skill_desc = version_spec.get("description", "")[:50]
                console.print(f"  [dim]○[/dim] {skill_ref}")
                if skill_desc:
                    console.print(f"    [dim]{skill_desc}[/dim]")
                console.print(
                    f"    [cyan]Install: specify skill install {skill_ref}[/cyan]"
                )

    if blocked:
        console.print()
        console.print("[bold]Blocked Skills (will be rejected on install):[/bold]")
        for skill_id in blocked:
            console.print(f"  [red]✗[/red] {skill_id}")


@skill_app.command("check-updates")
def skill_check_updates():
    """Check for available skill updates."""
    if not SKILLS_AVAILABLE:
        console.print("[red]Skills module not available[/red]")
        raise typer.Exit(1)

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)

    if not manifest.exists():
        console.print("[yellow]No skills.json found. No skills installed.[/yellow]")
        return

    skills = manifest.list_skills()
    if not skills:
        console.print("[yellow]No skills installed.[/yellow]")
        return

    console.print(f"\n{accent('Checking for updates...')}\n")

    has_updates = False
    for skill_id, metadata in skills.items():
        if metadata.source == "local":
            console.print(f"  [dim]○[/dim] {skill_id} (local - no update check)")
        else:
            if metadata.version in ("main", "master", "*"):
                console.print(
                    f"  [yellow]?[/yellow] {skill_id}@{metadata.version} "
                    f"(tracking branch - run 'specify skill update {skill_id}' to refresh)"
                )
                has_updates = True
            else:
                console.print(f"  [green]✓[/green] {skill_id}@{metadata.version}")

    if has_updates:
        console.print()
        console.print(
            "[dim]Tip: Run 'specify skill update --all' to update all skills[/dim]"
        )
    else:
        console.print()
        console.print("[green]All skills are up to date.[/green]")


@skill_app.command("config")
def skill_config(
    key: Optional[str] = typer.Argument(None, help="Config key to get/set"),
    value: Optional[str] = typer.Argument(None, help="Value to set"),
):
    """View or modify skills configuration."""
    skills_config = _get_skills_config()

    if key is None:
        console.print(f"\n{accent('Skills Configuration:')}\n")
        for k, v in skills_config.items():
            console.print(f"  {k}: {v}")
        console.print()
        console.print("[dim]Set with: specify skill config <key> <value>[/dim]")
        return

    if value is None:
        if key in skills_config:
            console.print(f"{key}: {skills_config[key]}")
        else:
            console.print(f"[red]Unknown config key:[/red] {key}")
            console.print(
                f"[dim]Available keys: {', '.join(skills_config.keys())}[/dim]"
            )
        return

    valid_keys = {
        "auto_activation_threshold": float,
        "max_auto_skills": int,
        "preserve_user_edits": lambda x: x.lower() in ("true", "1", "yes"),
        "registry_url": str,
        "evaluation_required": lambda x: x.lower() in ("true", "1", "yes"),
    }

    if key not in valid_keys:
        console.print(f"[red]Unknown config key:[/red] {key}")
        console.print(f"[dim]Available keys: {', '.join(valid_keys.keys())}[/dim]")
        return

    try:
        converter = valid_keys[key]
        converted_value = converter(value)
        _set_skills_config(key, converted_value)
        console.print(f"[green]✓[/green] Set {key} = {converted_value}")
    except (ValueError, TypeError) as e:
        console.print(f"[red]Invalid value:[/red] {e}")
