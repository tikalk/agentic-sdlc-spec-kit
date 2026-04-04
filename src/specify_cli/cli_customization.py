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

import json
import os
import shutil
from pathlib import Path
from typing import Any

from rich.console import Console

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
    from .extensions import ExtensionError, ExtensionManager
    from . import get_speckit_version

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
        manager = ExtensionManager(project_path)
        speckit_version = get_speckit_version()
        registry = manager.registry

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

            registry.add(
                ext_name,
                {
                    "version": manifest.version,
                    "source": "local",
                    "manifest_hash": manifest.get_hash(),
                    "enabled": True,
                    "priority": 10,
                    "registered_commands": {},
                    "registered_skills": {},
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
    from .presets import PresetError, PresetManager
    from . import get_speckit_version

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

            registry.add(
                preset_name,
                {
                    "version": manifest.version,
                    "source": "local",
                    "manifest_hash": manifest.get_hash(),
                    "enabled": True,
                    "priority": 10,
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
