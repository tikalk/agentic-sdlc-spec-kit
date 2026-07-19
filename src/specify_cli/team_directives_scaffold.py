"""Create neutral team-ai-directives knowledge-base scaffolds."""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import date
from pathlib import Path


@dataclass(frozen=True)
class TeamDirectivesScaffoldResult:
    """Files produced by a team-ai-directives scaffold run."""

    name: str
    root: Path
    files: tuple[Path, ...]


def _manifest_content(name: str, created_at: str) -> str:
    return f"""schema_version: \"1.0\"
team_ai_directives:
  name: {json.dumps(name)}
  version: \"0.1.0\"
  owner: \"\"
  compatibility:
    speckit: \">=0.12.0\"
  created_at: \"{created_at}\"
"""


def _readme_content(name: str, directory_name: str) -> str:
    path_example = json.dumps(f"/path/to/{directory_name}")
    return f"""# {name}

This is a neutral team-ai-directives knowledge base. It contains no team
policies, personas, examples, or skills until your team adds them.

## Getting Started

1. Define team-wide principles in `context_modules/constitution.md`.
2. Add focused rules, personas, and examples under `context_modules/`.
3. Add reusable skills under `skills/` and register them in `.skills.json`.
4. Record accepted context modules in `CDR.md`.

Use this knowledge base when initializing a Spec Kit project:

```bash
specify init <project> --team-ai-directives {path_example}
```

`.mcp.json.example` is intentionally empty. Copy it to `.mcp.json` only when
the team needs shared MCP configuration, and never commit credentials.
"""


def _agents_content() -> str:
    return """# Agent Instructions

This repository stores team-owned context for AI agents. The scaffold itself
defines no behavioral policy.

## Structure

- `context_modules/constitution.md` contains team-wide principles.
- `context_modules/rules/`, `personas/`, and `examples/` contain focused context.
- `skills/` contains reusable skills registered in `.skills.json`.
- `CDR.md` indexes accepted context modules.

## Loading Order

Read the constitution first, then load only context relevant to the current
task.

## Functional Categories (Rules)

Organize rules by the technologies or concerns they govern.

## Using Skills

Treat `.skills.json` as the skill registry. The initial registry is empty.

## CDR.md

Add a Context Directive Record when the team accepts a context module.
"""


def _constitution_content(created_at: str) -> str:
    return f"""---
type: Constitution
title: Team Constitution
description: Team-wide principles governing AI agent behavior
tags: [governance, constitution]
timestamp: {created_at}T00:00:00Z
---

# Team Constitution

No team-wide principles have been defined yet.
"""


def _cdr_content(created_at: str) -> str:
    return f"""# Context Directive Records

Context Directive Records (CDRs) track decisions about contributing context
modules to team-ai-directives.

## CDR Index

| ID | Target Module | Type | Status | Created | Verified | Age | Descriptor |
|----|---------------|------|--------|---------|----------|-----|------------|

**Stats**: 0 entries | Last Updated: {created_at}
"""


def _scaffold_files(name: str, directory_name: str, created_at: str) -> dict[Path, str]:
    skills_manifest = {
        "version": "2.0.0",
        "default": [],
        "skills": {},
        "external": {},
    }
    mcp_example = {"mcpServers": {}}

    return {
        Path("manifest.yml"): _manifest_content(name, created_at),
        Path("README.md"): _readme_content(name, directory_name),
        Path("AGENTS.md"): _agents_content(),
        Path("CDR.md"): _cdr_content(created_at),
        Path(".skills.json"): json.dumps(skills_manifest, indent=2) + "\n",
        Path(".mcp.json.example"): json.dumps(mcp_example, indent=2) + "\n",
        Path("context_modules/constitution.md"): _constitution_content(created_at),
        Path("context_modules/rules/.gitkeep"): "",
        Path("context_modules/personas/.gitkeep"): "",
        Path("context_modules/examples/.gitkeep"): "",
        Path("skills/.gitkeep"): "",
    }


def scaffold_team_directives(
    target: Path,
    name: str | None = None,
    *,
    created_at: date | None = None,
) -> TeamDirectivesScaffoldResult:
    """Create a neutral, consumable team-ai-directives knowledge base."""
    root = target.expanduser().absolute()
    if root.is_symlink():
        raise ValueError(f"Refusing to scaffold into a symlink: {root}")
    if root.exists() and not root.is_dir():
        raise FileExistsError(f"Destination exists and is not a directory: {root}")
    if root.exists() and any(root.iterdir()):
        raise FileExistsError(f"Destination directory is not empty: {root}")

    scaffold_name = (name if name is not None else root.name).strip()
    if not scaffold_name:
        raise ValueError("Team directives name cannot be empty")

    created_on = (created_at or date.today()).isoformat()
    content_by_path = _scaffold_files(scaffold_name, root.name, created_on)
    created_files: list[Path] = []
    created_dirs: list[Path] = []

    try:
        if not root.exists():
            missing_roots: list[Path] = []
            parent = root
            while not parent.exists():
                missing_roots.append(parent)
                parent = parent.parent
            root.mkdir(parents=True)
            created_dirs.extend(reversed(missing_roots))

        for relative_path, content in content_by_path.items():
            destination = root / relative_path
            missing_parents: list[Path] = []
            parent = destination.parent
            while parent != root and not parent.exists():
                missing_parents.append(parent)
                parent = parent.parent
            destination.parent.mkdir(parents=True, exist_ok=True)
            created_dirs.extend(reversed(missing_parents))
            created_files.append(destination)
            destination.write_text(content, encoding="utf-8")
    except BaseException:
        for path in reversed(created_files):
            try:
                path.unlink()
            except OSError:
                pass
        for path in sorted(
            set(created_dirs), key=lambda item: len(item.parts), reverse=True
        ):
            try:
                path.rmdir()
            except OSError:
                pass
        raise

    return TeamDirectivesScaffoldResult(
        name=scaffold_name,
        root=root,
        files=tuple(root / path for path in content_by_path),
    )
