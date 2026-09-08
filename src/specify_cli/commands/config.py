"""Project configuration commands for settings persisted by ``specify init``."""

from __future__ import annotations

import json
from typing import Any

import typer
from rich.table import Table
from rich.text import Text

from .._console import console
from .._core_fork import install_mcp_config
from .._init_options import load_init_options, save_init_options
from ..extensions import ExtensionManager
from ..extensions._commands import extension_app

try:
    from .._init_fork import _install_skills_from_path, sync_team_ai_directives
except ImportError:
    _install_skills_from_path = None
    sync_team_ai_directives = None

try:
    from .._init_fork import make_typer
except ImportError:

    def make_typer(*, name: str | None = None, help: str | None = None, **kwargs):
        kwargs.setdefault("add_completion", False)
        return typer.Typer(name=name, help=help, **kwargs)


config_app = make_typer(
    name="config",
    help="View and manage project configuration",
)
config_app.add_typer(extension_app, name="extension")


_INIT_OPTION_KEYS = {
    "ai": "ai",
    "ai-skills": "ai_skills",
    "feature-numbering": "feature_numbering",
    "here": "here",
    "integration": "integration",
    "script": "script",
    "speckit-version": "speckit_version",
    "team-ai-directives": "team_ai_directives",
}
_FEATURE_NUMBERING = {"sequential", "timestamp"}


def _require_specify_project():
    from .. import _require_specify_project as require_project

    return require_project()


def _canonical_key(key: str) -> str | None:
    return _INIT_OPTION_KEYS.get(key.replace("_", "-").lower())


def _display_value(value: Any) -> str:
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False)
    return str(value)


def _print_extensions(project_root) -> None:
    installed = ExtensionManager(project_root).list_installed()
    if not installed:
        console.print("\nNo extensions installed.")
        return

    table = Table(title="Extensions")
    table.add_column("ID")
    table.add_column("Status")
    table.add_column("Priority", justify="right")
    table.add_column("Config")
    for extension in installed:
        extension_id = extension["id"]
        table.add_row(
            extension_id,
            "enabled" if extension["enabled"] else "disabled",
            str(extension["priority"]),
            f".specify/extensions/{extension_id}/",
        )
    console.print()
    console.print(table)


@config_app.command("list")
def config_list(
    as_json: bool = typer.Option(False, "--json", help="Print machine-readable JSON"),
) -> None:
    """List initialization settings and installed extensions."""
    project_root = _require_specify_project()
    options = load_init_options(project_root)
    extensions = ExtensionManager(project_root).list_installed()

    if as_json:
        console.print_json(
            json.dumps({"init": options, "extensions": extensions}, ensure_ascii=False)
        )
        return

    table = Table(title="Initialization Settings")
    table.add_column("Key")
    table.add_column("Value")
    for display_key, stored_key in _INIT_OPTION_KEYS.items():
        if stored_key in options:
            table.add_row(display_key, Text(_display_value(options[stored_key])))
    console.print(table)
    _print_extensions(project_root)


@config_app.command("get")
def config_get(key: str = typer.Argument(help="Configuration key")) -> None:
    """Show one persisted initialization setting."""
    stored_key = _canonical_key(key)
    if stored_key is None:
        raise typer.BadParameter(f"Unknown configuration key: {key}")

    options = load_init_options(_require_specify_project())
    if stored_key not in options:
        console.print(f"{key.replace('_', '-')} is not set")
        raise typer.Exit(1)
    console.print(_display_value(options[stored_key]), markup=False)


@config_app.command("set")
def config_set(
    key: str = typer.Argument(help="Configuration key"),
    value: str = typer.Argument(help="New value"),
) -> None:
    """Change a supported initialization setting."""
    normalized_key = key.replace("_", "-").lower()
    project_root = _require_specify_project()
    options = load_init_options(project_root)

    if normalized_key == "script":
        raise typer.BadParameter(
            "script is managed by specify integration upgrade <key> --script <type>"
        )
    elif normalized_key == "feature-numbering":
        normalized_value = value.lower()
        if normalized_value not in _FEATURE_NUMBERING:
            raise typer.BadParameter(
                "feature-numbering must be one of: sequential, timestamp"
            )
        options["feature_numbering"] = normalized_value
    elif normalized_key in {"ai", "integration"}:
        raise typer.BadParameter(
            f"{normalized_key} is managed by specify integration use {value}"
        )
    elif normalized_key == "ai-skills":
        raise typer.BadParameter(
            "ai-skills is managed by specify integration upgrade <key> --integration-options. "
            "Options depend on the integration; see specify integration upgrade --help."
        )
    elif normalized_key in {"here", "speckit-version"}:
        raise typer.BadParameter(f"{normalized_key} is read-only")
    elif normalized_key == "team-ai-directives":
        if sync_team_ai_directives is None or _install_skills_from_path is None:
            raise typer.BadParameter("team-ai-directives is only available in this fork")
        selected_ai = options.get("ai")
        if not isinstance(selected_ai, str) or not selected_ai:
            raise typer.BadParameter(
                "team-ai-directives requires an active integration; run specify integration use <key> first"
            )
        phase = "synchronization"
        try:
            _, directives_path = sync_team_ai_directives(value, project_root, force=False)
            if (directives_path / ".mcp.json").exists():
                phase = "MCP configuration"
                mcp_installed, mcp_messages, _, _ = install_mcp_config(
                    directives_path, project_root
                )
                if not mcp_installed:
                    raise RuntimeError(
                        "\n".join(mcp_messages)
                        or "Failed to install MCP configuration"
                    )
            phase = "skill installation"
            _install_skills_from_path(
                team_directives_path=directives_path,
                project_path=project_root,
                selected_ai=selected_ai,
                force=False,
            )
        except Exception as exc:
            console.print(f"Team AI directives {phase} failed: {exc}", markup=False)
            console.print(
                "Partial extension or skills files may remain. Inspect and repair incomplete "
                "skill files first: existing skills are skipped on retry. Fix the cause and retry the same "
                "config set team-ai-directives command. The saved source was not changed."
            )
            raise typer.Exit(1) from None
        options["team_ai_directives"] = str(directives_path.resolve())
    else:
        raise typer.BadParameter(f"Unknown configuration key: {key}")

    save_init_options(project_root, options)
    console.print(f"Updated {normalized_key}")


@config_app.command("unset")
def config_unset(key: str = typer.Argument(help="Configuration key")) -> None:
    """Remove a supported initialization setting."""
    normalized_key = key.replace("_", "-").lower()
    if normalized_key != "team-ai-directives":
        raise typer.BadParameter("Only team-ai-directives can be unset")

    project_root = _require_specify_project()
    options = load_init_options(project_root)
    removed = ExtensionManager(project_root).remove("team-ai-directives")
    had_source = "team_ai_directives" in options
    if had_source:
        options.pop("team_ai_directives")
        save_init_options(project_root, options)
    if removed:
        console.print("Removed team-ai-directives extension and configuration.")
    elif had_source:
        console.print("Cleared team-ai-directives saved source; the extension was not installed.")
    else:
        console.print("Nothing to unset: no team-ai-directives extension or saved source.")
    if removed or had_source:
        console.print("Copied team skills remain for manual review in the active agent skills directory.")


def register(app: typer.Typer) -> None:
    """Attach the configuration command group to the root Typer app."""
    app.add_typer(config_app, name="config")
