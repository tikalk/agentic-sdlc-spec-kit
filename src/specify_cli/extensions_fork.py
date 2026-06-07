"""
Fork-specific constants and schemas for the ``extensions/`` layer.

This module is the single source of truth for worktree-related
configuration shapes and defaults used across the fork.

The git extension's worktree feature (see ``extensions/git/scripts/bash/``)
reads these constants when:
- Validating ``config-template.yml`` against :data:`WORKTREE_CONFIG_SCHEMA`
- Choosing the default isolation mode when not specified by the user
- Writing/reading the worktree manifest in feature worktree roots
"""

from __future__ import annotations

# Default isolation mode when none is specified in user config.
# "branch" = feature branch in the primary checkout (legacy behavior).
# "worktree" = dedicated git worktree per feature (obra-aligned).
WORKTREE_DEFAULT_ISOLATION_MODE = "branch"

# Valid isolation modes. The worktree feature accepts either; new projects
# default to ``WORKTREE_DEFAULT_ISOLATION_MODE`` and may be overridden
# per-project via .specify/extensions/git/config.yml.
WORKTREE_VALID_ISOLATION_MODES: frozenset[str] = frozenset({"branch", "worktree"})

# Manifest filename written at the root of each feature worktree.
# Records the feature branch, list of task branches, and provenance so
# ``git.feature --finish`` can clean up only manifested worktrees.
WORKTREE_MANIFEST_FILENAME = "git.worktree-manifest.json"

# Path (relative to project root) under which feature worktrees are placed.
# Default: ``.worktrees/`` at project root.
WORKTREE_BASE_DIR = ".worktrees"

# Branch naming pattern for task branches inside a feature worktree.
# Substituted fields: {feature} (feature branch slug), {id} (task number),
# {task-slug} (kebab-cased task title).
WORKTREE_TASK_BRANCH_PATTERN = "{feature}--task-{id}-{task-slug}"

# Top-level key in user config under which worktree settings live.
WORKTREE_CONFIG_KEY = "worktrees"

# Schema describing the worktree section of config.yml. Each entry is
# (key, default, validator-description). Used by config validation and
# for documentation generation. Empty defaults are filled in by the
# extension's bash config-lint pass; this constant is the contract.
WORKTREE_CONFIG_SCHEMA: dict[str, dict[str, object]] = {
    "isolation_mode": {
        "type": "string",
        "enum": sorted(WORKTREE_VALID_ISOLATION_MODES),
        "default": WORKTREE_DEFAULT_ISOLATION_MODE,
        "description": (
            "How the git extension isolates feature work. "
            "'branch' uses the primary checkout; 'worktree' uses a dedicated git worktree per feature."
        ),
    },
    "base_dir": {
        "type": "string",
        "default": WORKTREE_BASE_DIR,
        "description": "Directory (relative to project root) under which feature worktrees are created.",
    },
    "manifest_filename": {
        "type": "string",
        "default": WORKTREE_MANIFEST_FILENAME,
        "description": "Filename for the per-feature worktree manifest.",
    },
    "task_branch_pattern": {
        "type": "string",
        "default": WORKTREE_TASK_BRANCH_PATTERN,
        "description": "Pattern for naming task branches inside a feature worktree.",
    },
}
