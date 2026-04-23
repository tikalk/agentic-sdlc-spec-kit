"""Fork-specific test mixin for integration file inventory tests.

The tikalk fork bundles extensions, presets, and skills that aren't present in upstream.
This module provides methods to add fork-specific expected files to inventory tests.

Usage:
    # In test_integration_*.py files, add import and inherit from ForkInventoryMixin:

    from tests.integrations.test_fork_inventory import ForkInventoryMixin

    class TestAmpIntegration(ForkInventoryMixin, MarkdownIntegrationTests):
        KEY = "amp"
        ...
"""

import os
from typing import ClassVar

from specify_cli import PKG_NAMES


class ForkInventoryMixin:
    """Mixin that adds fork-specific files to expected file inventories."""

    IS_FORK: ClassVar[bool] = "agentic-sdlc" in PKG_NAMES

    def _fork_expected_files(self, script_variant: str) -> list[str]:
        """Return fork-specific expected files that aren't in upstream."""
        if not self.IS_FORK:
            return []

        files = []

        files.extend(self._fork_bundled_extension_files())
        files.extend(self._fork_bundled_preset_files())
        files.extend(self._fork_bundled_skills_files())

        return sorted(files)

    def _fork_bundled_extension_files(self) -> list[str]:
        """Files from bundled extensions (architect, evals, levelup, product, quick, tdd)."""
        ext_files = []

        for ext in ["architect", "evals", "levelup", "product", "quick", "tdd"]:
            ext_files.extend(
                [
                    f".specify/extensions/{ext}/extension.yml",
                    f".specify/extensions/{ext}/CHANGELOG.md",
                    f".specify/extensions/{ext}/README.md",
                    f".specify/extensions/{ext}/config-template.yml",
                    f".specify/extensions/{ext}/commands/analyze.md",
                    f".specify/extensions/{ext}/commands/clarify.md",
                    f".specify/extensions/{ext}/commands/implement.md",
                    f".specify/extensions/{ext}/commands/init.md",
                    f".specify/extensions/{ext}/commands/specify.md",
                    f".specify/extensions/{ext}/commands/validate.md",
                    f".specify/extensions/{ext}/commands/plan.md",
                    f".specify/extensions/{ext}/commands/tasks.md",
                    f".specify/extensions/{ext}/commands/trace.md",
                    f".specify/extensions/{ext}/commands/link.md",
                    f".specify/extensions/{ext}/commands/roadmap.md",
                    f".specify/extensions/{ext}/commands/skills.md",
                    f".specify/templates/{ext}-template.md",
                ]
            )

        ext_files.extend(
            [
                ".specify/extensions.yml",
                ".specify/extensions/.registry",
                ".specify/extensions/catalog.json",
            ]
        )

        return ext_files

    def _fork_bundled_preset_files(self) -> list[str]:
        """Files from bundled presets (agentic-sdlc, lean)."""
        return [
            ".specify/presets/.registry",
            ".specify/presets/catalog.json",
            ".specify/presets/agentic-sdlc/preset.yml",
            ".specify/presets/agentic-sdlc/commands/adlc.spec.analyze.md",
            ".specify/presets/agentic-sdlc/commands/adlc.spec.checklist.md",
            ".specify/presets/agentic-sdlc/commands/adlc.spec.clarify.md",
            ".specify/presets/agentic-sdlc/commands/adlc.spec.constitution.md",
            ".specify/presets/agentic-sdlc/commands/adlc.spec.implement.md",
            ".specify/presets/agentic-sdlc/commands/adlc.spec.plan.md",
            ".specify/presets/agentic-sdlc/commands/adlc.spec.specify.md",
            ".specify/presets/agentic-sdlc/commands/adlc.spec.tasks.md",
            ".specify/presets/agentic-sdlc/templates/checklist-template.md",
            ".specify/presets/agentic-sdlc/templates/constitution-template.md",
            ".specify/presets/agentic-sdlc/templates/delegation-template.md",
            ".specify/presets/agentic-sdlc/templates/plan-template.md",
            ".specify/presets/agentic-sdlc/templates/spec-template.md",
            ".specify/presets/agentic-sdlc/templates/tasks-template.md",
            ".specify/presets/lean/preset.yml",
            ".specify/presets/lean/commands/speckit.constitution.md",
            ".specify/presets/lean/commands/speckit.implement.md",
            ".specify/presets/lean/commands/speckit.plan.md",
            ".specify/presets/lean/commands/speckit.specify.md",
            ".specify/presets/lean/commands/speckit.tasks.md",
        ]

    def _fork_bundled_skills_files(self) -> list[str]:
        """Files from bundled skills (adlc namespace variants)."""
        commands = [
            "analyze",
            "clarify",
            "implement",
            "init",
            "specify",
            "validate",
            "plan",
            "tasks",
            "trace",
            "link",
            "roadmap",
            "checklist",
            "constitution",
            "skills",
        ]

        skill_files = []
        for cmd in commands:
            skill_files.append(f".agent/skills/adlc-architect-{cmd}/SKILL.md")
            skill_files.append(f".agent/skills/adlc-evals-{cmd}/SKILL.md")
            skill_files.append(f".agent/skills/adlc-levelup-{cmd}/SKILL.md")
            skill_files.append(f".agent/skills/adlc-product-{cmd}/SKILL.md")
            skill_files.append(f".agent/skills/adlc-spec-{cmd}/SKILL.md")
            skill_files.append(f".agent/skills/adlc-tdd-{cmd}/SKILL.md")

        skill_files.extend(
            [
                ".agent/skills/adlc-quick-implement/SKILL.md",
            ]
        )

        return skill_files


def patched_expected_files(method):
    """Decorator that patches _expected_files to include fork files."""

    def wrapper(self, script_variant: str):
        base_files = method(self, script_variant)
        if hasattr(self, "_fork_expected_files"):
            fork_files = self._fork_expected_files(script_variant)
            return sorted(set(base_files) | set(fork_files))
        return base_files

    return wrapper
