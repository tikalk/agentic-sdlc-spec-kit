"""Fork-specific bundled-asset helpers.

Leaf fork module: imports only from ._assets (clean upstream) and stdlib+yaml.
Keeps _assets.py free of fork divergence so it merges cleanly with upstream.

Contents:
- _locate_bundled_preset(): upstream locator + Tikalk bundled_presets/ fallback
- get_bundled_extension_version()/_path() (relocated from adlc4)
- get_bundled_preset_version()/_path()
"""
from __future__ import annotations

import re
from pathlib import Path

from ._assets import (
    _locate_bundled_extension,
    _locate_bundled_preset as _upstream_locate_bundled_preset,
)


# ---------------------------------------------------------------------------
# _locate_bundled_preset – fork wrapper
# ---------------------------------------------------------------------------


def _locate_bundled_preset(preset_id: str) -> Path | None:
    """Return the path to a bundled preset, or None.

    Wraps the upstream locator, then falls back to the Tikalk fork
    ``bundled_presets/`` directory used in wheel / uv-tool installs.
    """
    result = _upstream_locate_bundled_preset(preset_id)
    if result is not None:
        return result

    # Wheel / uv tool install: Tikalk fork presets land in bundled_presets/
    if not re.match(r"^[a-z0-9-]+$", preset_id):
        return None
    candidate = Path(__file__).parent / "bundled_presets" / preset_id
    if (candidate / "preset.yml").is_file():
        return candidate

    return None


# ---------------------------------------------------------------------------
# Bundled extension helpers
# ---------------------------------------------------------------------------


def get_bundled_extension_version(extension_id: str) -> str | None:
    """Get version of bundled extension from CLI wheel or source checkout.

    Args:
        extension_id: Extension identifier (e.g., "architect")

    Returns:
        Version string if extension is bundled, None otherwise
    """
    bundled_path = _locate_bundled_extension(extension_id)
    if not bundled_path:
        return None

    ext_yml = bundled_path / "extension.yml"
    if not ext_yml.is_file():
        return None

    try:
        import yaml
        with open(ext_yml, encoding="utf-8") as f:
            data = yaml.safe_load(f)
        return data.get("extension", {}).get("version")
    except Exception:
        return None


def get_bundled_extension_path(extension_id: str) -> Path | None:
    """Get filesystem path to bundled extension in CLI wheel or source checkout.

    Args:
        extension_id: Extension identifier (e.g., "architect")

    Returns:
        Path to bundled extension directory, None if not found
    """
    return _locate_bundled_extension(extension_id)


# ---------------------------------------------------------------------------
# Bundled preset helpers
# ---------------------------------------------------------------------------


def get_bundled_preset_version(preset_id: str) -> str | None:
    """Get version of bundled preset from CLI wheel or source checkout.

    Args:
        preset_id: Preset identifier (e.g., "agentic-sdlc")

    Returns:
        Version string if preset is bundled, None otherwise
    """
    bundled_path = _locate_bundled_preset(preset_id)
    if not bundled_path:
        return None

    preset_yml = bundled_path / "preset.yml"
    if not preset_yml.is_file():
        return None

    try:
        import yaml
        with open(preset_yml, encoding="utf-8") as f:
            data = yaml.safe_load(f)
        return data.get("preset", {}).get("version")
    except Exception:
        return None


def get_bundled_preset_path(preset_id: str) -> Path | None:
    """Get filesystem path to bundled preset in CLI wheel or source checkout.

    Args:
        preset_id: Preset identifier (e.g., "agentic-sdlc")

    Returns:
        Path to bundled preset directory, None if not found
    """
    return _locate_bundled_preset(preset_id)
