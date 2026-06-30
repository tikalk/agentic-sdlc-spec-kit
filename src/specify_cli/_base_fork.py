"""
Fork-specific additions to IntegrationBase.

This module adds fork-level capabilities to the integration base class.
The default implementations are conservative and return safe fallbacks
so that the rest of the codebase can call these methods unconditionally.

The primary addition is :func:`detect_native_worktree`, which integrations
can override to indicate their CLI tool already supports git worktree
operations natively (e.g., ``cursor-agent``, ``claude``) — in which case
the worktree extension can skip its own worktree scaffolding and rely on
the agent's own commands.
"""

from __future__ import annotations


def detect_native_worktree(integration_key: str) -> bool:
    """Return True if the given agent integration has native worktree support.

    Fork customization: identifies AI agents whose CLI tool exposes native
    worktree operations, so the ``git`` extension can defer to them rather
    than re-implementing worktree management.

    Default is ``False`` (no native support). Overrides below identify
    integrations whose CLI is known to handle worktrees internally.

    Args:
        integration_key: The integration's ``key`` (matches CLI tool name).

    Returns:
        True if the agent's CLI handles worktrees natively.
    """
    # Native worktree support registry — extend as new agents qualify.
    _NATIVE_WORKTREE_INTEGRATIONS: frozenset[str] = frozenset({
        # Add integrations here as their CLI tooling is verified.
        # Per-integration overrides (e.g. CursorAgentIntegration.detect_native_worktree)
        # are preferred over this registry for explicitness.
    })
    return integration_key in _NATIVE_WORKTREE_INTEGRATIONS
