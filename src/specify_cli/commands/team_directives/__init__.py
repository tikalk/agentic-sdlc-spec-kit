"""``specify team-directives`` command group."""

from __future__ import annotations

from pathlib import Path

import typer

from ..._console import console, err_console

try:
    from ..._init_fork import accent, make_typer
except ImportError:

    def accent(text: str, **_kwargs) -> str:
        return text

    def make_typer(*, name=None, help=None, **kwargs):
        kwargs.setdefault("add_completion", False)
        return typer.Typer(name=name, help=help, **kwargs)


team_directives_app = make_typer(
    name="team-directives",
    help="Create and manage team-ai-directives knowledge bases",
)


@team_directives_app.command("init")
def team_directives_init(
    path: Path = typer.Argument(
        Path("team-ai-directives"),
        help="Destination directory",
    ),
    name: str | None = typer.Option(
        None,
        "--name",
        help="Team name stored in manifest.yml (defaults to the directory name)",
    ),
):
    """Create a neutral team-ai-directives knowledge base."""
    from ...team_directives_scaffold import scaffold_team_directives

    try:
        result = scaffold_team_directives(path, name)
    except (OSError, ValueError) as exc:
        err_console.print(f"[red]Error:[/red] {exc}")
        raise typer.Exit(1)

    console.print(
        f"{accent('Created team-ai-directives scaffold:', bold=True)} {result.root}"
    )
    console.print(
        f"[dim]{len(result.files)} files created; no Git repository initialized.[/dim]"
    )
    console.print()
    console.print("[bold]Next step:[/bold]")
    console.print(f'specify init <project> --team-ai-directives "{result.root}"')


def register(app: typer.Typer) -> None:
    """Register the team-directives command group on the root app."""
    app.add_typer(team_directives_app, name="team-directives")
