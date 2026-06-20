"""
Mistral Vibe CLI integration — skills-based agent.

Vibe uses ``.vibe/skills/speckit-<name>/SKILL.md`` layout (enforced since v2.0.0).
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from ..base import IntegrationOption, SkillsIntegration
from ..manifest import IntegrationManifest


class VibeIntegration(SkillsIntegration):
    key = "vibe"
    config = {
        "name": "Mistral Vibe",
        "folder": ".vibe/",
        "commands_subdir": "skills",
        "install_url": "https://github.com/mistralai/mistral-vibe",
        "requires_cli": True,
    }
    registrar_config = {
        "dir": ".vibe/skills",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": "/SKILL.md",
    }
    context_file = "AGENTS.md"

    @classmethod
    def options(cls) -> list[IntegrationOption]:
        return [
            IntegrationOption(
                "--skills",
                is_flag=True,
                default=True,
                help="Install as agent skills",
            ),
        ]

    def post_process_skill_content(self, content: str) -> str:
        """
        Inject shared hook guidance and Vibe-specific frontmatter flags:
        - user-invocable: allows the skill to be invoked by the user (not just other agents)
        """
        from specify_cli._core_fork import _inject_frontmatter_flag
        updated = super().post_process_skill_content(content)
        updated = _inject_frontmatter_flag(updated, "user-invocable")
        return updated

    def setup(
        self,
        project_root: Path,
        manifest: IntegrationManifest,
        parsed_options: dict[str, Any] | None = None,
        **opts: Any,
    ) -> list[Path]:
        """Install Vibe skills then inject Vibe-specific flags"""
        import click

        click.secho(
            "Warning: The .vibe/skills layout requires Mistral Vibe v2.0.0 or newer. "
            "Please ensure your installation is up to date.",
            fg="yellow",
            err=True,
        )

        return super().setup(project_root, manifest, parsed_options=parsed_options, **opts)
