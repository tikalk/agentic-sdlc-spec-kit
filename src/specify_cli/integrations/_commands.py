"""specify integration * commands — app objects and register() entry point."""
from __future__ import annotations

import typer

from .._assets import get_speckit_version  # noqa: F401 — re-exported for monkeypatching in tests

try:
    from .._init_fork import make_typer
except ImportError:
    def make_typer(*, name: str | None = None, help: str | None = None, **kwargs):
        kwargs.setdefault("add_completion", False)
        return typer.Typer(name=name, help=help, **kwargs)

# Re-export helpers used by commands/init.py and tests
from ._helpers import (  # noqa: F401
    _cli_error_detail,
    _cli_phase_label,
    _parse_integration_options,
    _write_integration_json,
)

integration_app = make_typer(
    name="integration",
    help="Manage coding agent integrations",
)

integration_catalog_app = make_typer(
    name="catalog",
    help="Manage integration catalog sources",
)
integration_app.add_typer(integration_catalog_app, name="catalog")


def register(app: typer.Typer) -> None:
    from . import _install_commands  # noqa: F401 — registers handlers via decorators
    from . import _migrate_commands  # noqa: F401
    from . import _query_commands    # noqa: F401
    from . import _scaffold_commands  # noqa: F401
    app.add_typer(integration_app, name="integration")
