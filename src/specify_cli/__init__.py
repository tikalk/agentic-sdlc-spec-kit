#!/usr/bin/env python3
"""
Specify CLI - Setup tool for Specify projects

Usage:
    uvx specify-cli.py init <project-name>
    uvx specify-cli.py init .
    uvx specify-cli.py init --here

Or install globally:
    uv tool install --from specify-cli.py specify-cli
    specify init <project-name>
    specify init .
    specify init --here
"""

import json
import os
import shlex
import shutil
import ssl
import subprocess
import sys
import tempfile
import yaml
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional, Tuple

import click
import httpx
import platformdirs
import readchar
import truststore
import typer
from rich.align import Align
from rich.console import Console
from rich.live import Live
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.table import Table
from rich.text import Text
from rich.tree import Tree
from typer.core import TyperGroup

ssl_context = truststore.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
client = httpx.Client(verify=ssl_context)

# Color constants for orange theme
ACCENT_COLOR = "#f47721"
BANNER_COLORS = ["#ff6b35", "#ff8c42", "#f47721", "#ff5722", "white", "bright_white"]

TEAM_DIRECTIVES_DIRNAME = "team-ai-directives"


def _github_token(cli_token: str | None = None) -> str | None:
    """Return sanitized GitHub token (cli arg takes precedence) or None."""
    return (
        (cli_token or os.getenv("GH_TOKEN") or os.getenv("GITHUB_TOKEN") or "").strip()
    ) or None


def _github_auth_headers(cli_token: str | None = None) -> dict:
    """Return Authorization header dict only when a non-empty token exists."""
    token = _github_token(cli_token)
    return {"Authorization": f"Bearer {token}"} if token else {}


def _parse_rate_limit_headers(headers: httpx.Headers) -> dict:
    """Extract and parse GitHub rate-limit headers."""
    info = {}

    # Standard GitHub rate-limit headers
    if "X-RateLimit-Limit" in headers:
        info["limit"] = headers.get("X-RateLimit-Limit")
    if "X-RateLimit-Remaining" in headers:
        info["remaining"] = headers.get("X-RateLimit-Remaining")
    if "X-RateLimit-Reset" in headers:
        reset_epoch = int(headers.get("X-RateLimit-Reset", "0"))
        if reset_epoch:
            reset_time = datetime.fromtimestamp(reset_epoch, tz=timezone.utc)
            info["reset_epoch"] = reset_epoch
            info["reset_time"] = reset_time
            info["reset_local"] = reset_time.astimezone()

    # Retry-After header (seconds or HTTP-date)
    if "Retry-After" in headers:
        retry_after = headers.get("Retry-After")
        try:
            info["retry_after_seconds"] = int(retry_after)
        except ValueError:
            # HTTP-date format - not implemented, just store as string
            info["retry_after"] = retry_after

    return info


def _format_rate_limit_error(status_code: int, headers: httpx.Headers, url: str) -> str:
    """Format a user-friendly error message with rate-limit information."""
    rate_info = _parse_rate_limit_headers(headers)

    lines = [f"GitHub API returned status {status_code} for {url}"]
    lines.append("")

    if rate_info:
        lines.append("[bold]Rate Limit Information:[/bold]")
        if "limit" in rate_info:
            lines.append(f"  • Rate Limit: {rate_info['limit']} requests/hour")
        if "remaining" in rate_info:
            lines.append(f"  • Remaining: {rate_info['remaining']}")
        if "reset_local" in rate_info:
            reset_str = rate_info["reset_local"].strftime("%Y-%m-%d %H:%M:%S %Z")
            lines.append(f"  • Resets at: {reset_str}")
        if "retry_after_seconds" in rate_info:
            lines.append(f"  • Retry after: {rate_info['retry_after_seconds']} seconds")
        lines.append("")

    # Add troubleshooting guidance
    lines.append("[bold]Troubleshooting Tips:[/bold]")
    lines.append(
        "  • If you're on a shared CI or corporate environment, you may be rate-limited."
    )
    lines.append(
        "  • Consider using a GitHub token via --github-token or the GH_TOKEN/GITHUB_TOKEN"
    )
    lines.append("    environment variable to increase rate limits.")
    lines.append(
        "  • Authenticated requests have a limit of 5,000/hour vs 60/hour for unauthenticated."
    )

    return "\n".join(lines)


# Agent configuration with name, folder, install URL, and CLI tool requirement
AGENT_CONFIG = {
    "copilot": {
        "name": "GitHub Copilot",
        "folder": ".github/",
        "commands_subdir": "agents",
        "install_url": None,  # IDE-based, no CLI check needed
        "requires_cli": False,
    },
    "claude": {
        "name": "Claude Code",
        "folder": ".claude/",
        "commands_subdir": "commands",
        "install_url": "https://docs.anthropic.com/en/docs/claude-code/setup",
        "requires_cli": True,
    },
    "gemini": {
        "name": "Gemini CLI",
        "folder": ".gemini/",
        "commands_subdir": "commands",
        "install_url": "https://github.com/google-gemini/gemini-cli",
        "requires_cli": True,
    },
    "cursor-agent": {
        "name": "Cursor",
        "folder": ".cursor/",
        "commands_subdir": "commands",
        "install_url": None,  # IDE-based
        "requires_cli": False,
    },
    "qwen": {
        "name": "Qwen Code",
        "folder": ".qwen/",
        "commands_subdir": "commands",
        "install_url": "https://github.com/QwenLM/qwen-code",
        "requires_cli": True,
    },
    "opencode": {
        "name": "opencode",
        "folder": ".opencode/",
        "commands_subdir": "command",
        "install_url": "https://opencode.ai",
        "requires_cli": True,
    },
    "codex": {
        "name": "Codex CLI",
        "folder": ".codex/",
        "commands_subdir": "prompts",
        "install_url": "https://github.com/openai/codex",
        "requires_cli": True,
    },
    "windsurf": {
        "name": "Windsurf",
        "folder": ".windsurf/",
        "commands_subdir": "workflows",
        "install_url": None,  # IDE-based
        "requires_cli": False,
    },
    "kilocode": {
        "name": "Kilo Code",
        "folder": ".kilocode/",
        "commands_subdir": "workflows",
        "install_url": None,  # IDE-based
        "requires_cli": False,
    },
    "auggie": {
        "name": "Auggie CLI",
        "folder": ".augment/",
        "commands_subdir": "rules",
        "install_url": "https://docs.augmentcode.com/cli/setup-auggie/install-auggie-cli",
        "requires_cli": True,
    },
    "codebuddy": {
        "name": "CodeBuddy",
        "folder": ".codebuddy/",
        "commands_subdir": "commands",
        "install_url": "https://www.codebuddy.ai/cli",
        "requires_cli": True,
    },
    "qodercli": {
        "name": "Qoder CLI",
        "folder": ".qoder/",
        "commands_subdir": "commands",
        "install_url": "https://qoder.com/cli",
        "requires_cli": True,
    },
    "roo": {
        "name": "Roo Code",
        "folder": ".roo/",
        "commands_subdir": "rules",
        "install_url": None,  # IDE-based
        "requires_cli": False,
    },
    "q": {
        "name": "Amazon Q Developer CLI",
        "folder": ".amazonq/",
        "commands_subdir": "prompts",
        "install_url": "https://aws.amazon.com/developer/learning/q-developer-cli/",
        "requires_cli": True,
    },
    "amp": {
        "name": "Amp",
        "folder": ".agents/",
        "commands_subdir": "commands",
        "install_url": "https://ampcode.com/manual#install",
        "requires_cli": True,
    },
    "shai": {
        "name": "SHAI",
        "folder": ".shai/",
        "commands_subdir": "commands",
        "install_url": "https://github.com/ovh/shai",
        "requires_cli": True,
    },
    "agy": {
        "name": "Antigravity",
        "folder": ".agent/",
        "commands_subdir": "workflows",
        "install_url": None,  # IDE-based
        "requires_cli": False,
    },
    "bob": {
        "name": "IBM Bob",
        "folder": ".bob/",
        "commands_subdir": "commands",
        "install_url": None,  # IDE-based
        "requires_cli": False,
    },
    "generic": {
        "name": "Generic Agent",
        "folder": "",
        "commands_subdir": "commands",
        "install_url": None,
        "requires_cli": False,
    },
}

AGENT_CHOICES = list(AGENT_CONFIG.keys())

AGENT_SKILLS_DIR_OVERRIDES = {
    "codex": ".agents/skills",
}

DEFAULT_SKILLS_DIR = ".agents/skills"

SKILL_DESCRIPTIONS = {
    "specify": "Create or update feature specifications from natural language descriptions. Use when starting new features or refining requirements. Generates spec.md with user stories, functional requirements, and acceptance criteria following spec-driven development methodology.",
    "plan": "Generate technical implementation plans from feature specifications. Use after creating a spec to define architecture, tech stack, and implementation phases. Creates plan.md with detailed technical design.",
    "tasks": "Break down implementation plans into actionable task lists. Use after planning to create a structured task breakdown. Generates tasks.md with ordered, dependency-aware tasks.",
    "implement": "Execute all tasks from the task breakdown to build the feature. Use after task generation to systematically implement the planned solution following TDD approach where applicable.",
    "analyze": "Perform cross-artifact consistency analysis across spec.md, plan.md, and tasks.md. Use after task generation to identify gaps, duplications, and inconsistencies before implementation.",
    "clarify": "Structured clarification workflow for underspecified requirements. Use before planning to resolve ambiguities through coverage-based questioning. Records answers in spec clarifications section.",
    "constitution": "Create or update project governing principles and development guidelines. Use at project start to establish code quality, testing standards, and architectural constraints that guide all development.",
    "checklist": "Generate custom quality checklists for validating requirements completeness and clarity. Use to create unit tests for English that ensure spec quality before implementation.",
    "taskstoissues": "Convert tasks from tasks.md into GitHub issues. Use after task breakdown to track work items in GitHub project management.",
}


def _get_skills_dir(project_path: Path, selected_ai: str) -> Path:
    """Resolve the agent-specific skills directory for the given AI assistant.

    Uses ``AGENT_SKILLS_DIR_OVERRIDES`` first, then falls back to
    ``AGENT_CONFIG[agent]["folder"] + "skills"``, and finally to
    ``DEFAULT_SKILLS_DIR``.
    """
    if selected_ai in AGENT_SKILLS_DIR_OVERRIDES:
        return project_path / AGENT_SKILLS_DIR_OVERRIDES[selected_ai]

    agent_config = AGENT_CONFIG.get(selected_ai, {})
    agent_folder = agent_config.get("folder", "")
    if agent_folder:
        return project_path / agent_folder.rstrip("/") / "skills"

    return project_path / DEFAULT_SKILLS_DIR


def install_ai_skills(
    project_path: Path, selected_ai: str, tracker: "StepTracker | None" = None
) -> bool:
    """Install Prompt.MD files from templates/commands/ as agent skills.

    Skills are written to the agent-specific skills directory following the
    `agentskills.io <https://agentskills.io/specification>`_ specification.
    Installation is additive — existing files are never removed and prompt
    command files in the agent's commands directory are left untouched.

    Args:
        project_path: Target project directory.
        selected_ai: AI assistant key from ``AGENT_CONFIG``.
        tracker: Optional progress tracker.

    Returns:
        ``True`` if at least one skill was installed or all skills were
        already present (idempotent re-run), ``False`` otherwise.
    """
    agent_config = AGENT_CONFIG.get(selected_ai, {})
    agent_folder = agent_config.get("folder", "")
    commands_subdir = agent_config.get("commands_subdir", "commands")
    if agent_folder:
        templates_dir = project_path / agent_folder.rstrip("/") / commands_subdir
    else:
        templates_dir = project_path / commands_subdir

    if not templates_dir.exists() or not any(templates_dir.glob("*.md")):
        script_dir = Path(__file__).parent.parent.parent
        fallback_dir = script_dir / "templates" / "commands"
        if fallback_dir.exists() and any(fallback_dir.glob("*.md")):
            templates_dir = fallback_dir

    if not templates_dir.exists() or not any(templates_dir.glob("*.md")):
        if tracker:
            tracker.error("ai-skills", "command templates not found")
        else:
            console.print(
                "[yellow]Warning: command templates not found, skipping skills installation[/yellow]"
            )
        return False

    command_files = sorted(templates_dir.glob("*.md"))
    if not command_files:
        if tracker:
            tracker.skip("ai-skills", "no command templates found")
        else:
            console.print("[yellow]No command templates found to install[/yellow]")
        return False

    skills_dir = _get_skills_dir(project_path, selected_ai)
    skills_dir.mkdir(parents=True, exist_ok=True)

    if tracker:
        tracker.start("ai-skills")

    installed_count = 0
    skipped_count = 0
    for command_file in command_files:
        try:
            content = command_file.read_text(encoding="utf-8")

            if content.startswith("---"):
                parts = content.split("---", 2)
                if len(parts) >= 3:
                    frontmatter = yaml.safe_load(parts[1])
                    if not isinstance(frontmatter, dict):
                        frontmatter = {}
                    body = parts[2].strip()
                else:
                    console.print(
                        f"[yellow]Warning: {command_file.name} has malformed frontmatter (no closing ---), treating as plain content[/yellow]"
                    )
                    frontmatter = {}
                    body = content
            else:
                frontmatter = {}
                body = content

            command_name = command_file.stem
            if command_name.startswith("speckit."):
                command_name = command_name[len("speckit.") :]
            skill_name = f"speckit-{command_name}"

            skill_dir = skills_dir / skill_name
            skill_dir.mkdir(parents=True, exist_ok=True)

            original_desc = frontmatter.get("description", "")
            enhanced_desc = SKILL_DESCRIPTIONS.get(
                command_name,
                original_desc or f"Spec-kit workflow command: {command_name}",
            )

            source_name = command_file.name
            if source_name.startswith("speckit."):
                source_name = source_name[len("speckit.") :]

            frontmatter_data = {
                "name": skill_name,
                "description": enhanced_desc,
                "compatibility": "Requires spec-kit project structure with .specify/ directory",
                "metadata": {
                    "author": "github-spec-kit",
                    "source": f"templates/commands/{source_name}",
                },
            }
            frontmatter_text = yaml.safe_dump(frontmatter_data, sort_keys=False).strip()
            skill_content = (
                f"---\n"
                f"{frontmatter_text}\n"
                f"---\n\n"
                f"# Speckit {command_name.title()} Skill\n\n"
                f"{body}\n"
            )

            skill_file = skill_dir / "SKILL.md"
            if skill_file.exists():
                skipped_count += 1
                continue
            skill_file.write_text(skill_content, encoding="utf-8")
            installed_count += 1

        except Exception as e:
            console.print(
                f"[yellow]Warning: Failed to install skill {command_file.stem}: {e}[/yellow]"
            )
            continue

    if tracker:
        if installed_count > 0 and skipped_count > 0:
            tracker.complete(
                "ai-skills",
                f"{installed_count} new + {skipped_count} existing skills in {skills_dir.relative_to(project_path)}",
            )
        elif installed_count > 0:
            tracker.complete(
                "ai-skills",
                f"{installed_count} skills -> {skills_dir.relative_to(project_path)}",
            )
        elif skipped_count > 0:
            tracker.complete("ai-skills", f"{skipped_count} skills already present")
        else:
            tracker.error("ai-skills", "no skills installed")
    else:
        if installed_count > 0:
            console.print(
                f"[green]✓[/green] Installed {installed_count} agent skills to {skills_dir.relative_to(project_path)}/"
            )
        elif skipped_count > 0:
            console.print(
                f"[green]✓[/green] {skipped_count} agent skills already present in {skills_dir.relative_to(project_path)}/"
            )
        else:
            console.print("[yellow]No skills were installed[/yellow]")

    return installed_count > 0 or skipped_count > 0


# Issue tracker MCP configuration with name, type, URL, and metadata
ISSUE_TRACKER_CONFIG = {
    "github": {
        "name": "GitHub Issues",
        "type": "http",
        "url": "https://api.githubcopilot.com/mcp/",
        "description": "Connect to GitHub Issues for project management and issue tracking",
    },
    "jira": {
        "name": "Jira",
        "type": "sse",
        "url": "https://mcp.atlassian.com/v1/sse",
        "description": "Connect to Atlassian Jira for enterprise project management",
    },
    "linear": {
        "name": "Linear",
        "type": "sse",
        "url": "https://mcp.linear.app/sse",
        "description": "Connect to Linear for modern software project management",
    },
    "gitlab": {
        "name": "GitLab Issues",
        "type": "http",
        "url": "https://mcp.gitlab.com/",  # Placeholder - GitLab MCP server may not exist yet
        "description": "Connect to GitLab Issues for DevOps project management",
    },
}

# Git platform MCP configuration for Git operations (PRs, branches, etc.)
GIT_PLATFORM_CONFIG = {
    "github": {
        "name": "GitHub Platform",
        "type": "http",
        "url": "https://api.github.com/mcp/",
        "description": "Connect to GitHub Platform API for PR creation, branch management, and Git operations",
    },
    "gitlab": {
        "name": "GitLab Platform",
        "type": "http",
        "url": "https://gitlab.com/api/v4/mcp/",
        "description": "Connect to GitLab Platform API for merge request creation, branch management, and Git operations",
    },
}

# Agent MCP configuration for async coding agents that support autonomous task execution
# These agents can receive tasks, execute them asynchronously, and create PRs
AGENT_MCP_CONFIG = {
    "jules": {
        "name": "Jules",
        "type": "http",
        "url": "https://mcp.jules.ai/",
        "description": "Connect to Jules for autonomous async task execution and PR creation",
    },
    "async-copilot": {
        "name": "Async Copilot",
        "type": "http",
        "url": "https://mcp.async-copilot.dev/",
        "description": "Connect to Async Copilot for autonomous coding task execution",
    },
    "async-codex": {
        "name": "Async Codex",
        "type": "http",
        "url": "https://mcp.async-codex.ai/",
        "description": "Connect to Async Codex for autonomous development workflows",
    },
    "agentic-sdlc-orchestrator": {
        "name": "Agentic SDLC Orchestrator",
        "type": "local",
        "description": "Run async tasks in Kubernetes pods via local orchestrator",
    },
}

SCRIPT_TYPE_CHOICES = {"sh": "POSIX Shell (bash/zsh)", "ps": "PowerShell"}

# Consolidated Configuration Management


def get_global_config_path() -> Path:
    """Get the global config path using XDG Base Directory spec.

    Platform-specific locations:
    - Linux: ~/.config/specify/config.json
    - macOS: ~/Library/Application Support/specify/config.json
    - Windows: %APPDATA%\\specify\\config.json
    """
    config_dir = Path(platformdirs.user_config_dir("specify"))
    return config_dir / "config.json"


def get_project_config_path(project_path: Optional[Path] = None) -> Path:
    """Get project-level config path (.specify/config.json).

    Args:
        project_path: Path to project root (default: current directory)

    Returns:
        Path to .specify/config.json in the specified project
    """
    if project_path is None:
        project_path = Path.cwd()
    return project_path / ".specify" / "config.json"


def get_config_path(project_path: Optional[Path] = None) -> Path:
    """Get config path with hierarchical resolution.

    Priority order:
    1. Project-level config: .specify/config.json
    2. User-level config: ~/.config/specify/config.json (backward compat)
    3. Default to project-level path (will be created on save)

    Args:
        project_path: Path to project root (default: current directory)

    Returns:
        Path to config file (project-level preferred)
    """
    project_config = get_project_config_path(project_path)
    user_config = get_global_config_path()

    # Project config takes precedence if it exists
    if project_config.exists():
        return project_config

    # Fallback to user config for backward compatibility
    if user_config.exists():
        return user_config

    # Default to project-level config (will be created on write)
    return project_config


def load_config(project_path: Optional[Path] = None) -> dict:
    """Load the global configuration file.

    Args:
        project_path: (Ignored - global config is used for all projects)

    Returns:
        Configuration dict or defaults if config doesn't exist
    """
    config_path = get_global_config_path()
    if not config_path.exists():
        return get_default_config()

    try:
        with open(config_path, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        console.print(
            f"[yellow]Warning:[/yellow] Could not load config file {config_path}: {e}"
        )
        console.print("[yellow]Using default configuration[/yellow]")
        return get_default_config()


def save_config(
    project_path: Optional[Path] = None, config: Optional[dict] = None
) -> None:
    """Save the configuration to project-level location.

    Args:
        project_path: Path to project root (default: current directory)
        config: Configuration dict to save
    """
    if config is None:
        config = {}

    config_path = get_project_config_path(project_path)

    try:
        config_path.parent.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        console.print(
            f"[red]Error:[/red] Could not create config directory {config_path.parent}: {e}"
        )
        return

    # Update last_modified timestamp
    if "project" not in config:
        config["project"] = {}
    if not isinstance(config["project"], dict):
        config["project"] = {}
    config["project"]["last_modified"] = (
        __import__("datetime").datetime.now().isoformat()
    )

    try:
        with open(config_path, "w") as f:
            json.dump(config, f, indent=2)
    except OSError as e:
        console.print(
            f"[red]Error:[/red] Could not write config file {config_path}: {e}"
        )


def get_default_config() -> dict:
    """Get the default configuration structure."""
    from datetime import datetime

    now = datetime.now().isoformat()

    return {
        "version": "1.0",
        "project": {"created": now, "last_modified": now},
        "workflow": {
            "current_mode": "spec",
            "default_mode": "spec",
        },
        "options": {
            "tdd_enabled": False,
            "contracts_enabled": False,
            "data_models_enabled": False,
            "risk_tests_enabled": False,
        },
        "mode_defaults": {
            "build": {
                "tdd_enabled": False,
                "contracts_enabled": False,
                "data_models_enabled": False,
                "risk_tests_enabled": False,
                # GSD execution characteristics
                "atomic_commits": True,
                "skip_micro_review": True,
                "minimal_documentation": True,
            },
            "spec": {
                "tdd_enabled": True,
                "contracts_enabled": True,
                "data_models_enabled": True,
                "risk_tests_enabled": True,
                # Spec mode review characteristics
                "atomic_commits": False,
                "skip_micro_review": False,
                "minimal_documentation": False,
            },
        },
        "spec_sync": {
            "enabled": False,
            "queue": {"version": "1.0", "created": now, "pending": [], "processed": []},
        },
        "team_directives": {"path": None},
        "architecture": {
            "diagram_format": "mermaid",  # Options: "mermaid" or "ascii"
            "views": "core",  # Options: "core", "all", or comma-separated list
            "adr": {
                "heuristic": "surprising",  # Options: "surprising" (default), "all", "minimal"
                "check_constitution": True,  # Always check constitution for duplicates
                "allow_overrides": True,  # Allow constitution overrides with justification
                "duplication_threshold": "strict",  # Strict: no duplicates allowed
                "max_adrs": 10,  # Maximum ADRs to generate
                "custom_rules": {  # Project-specific obvious/surprising decisions
                    "obvious": [],
                    "surprising": [],
                },
            },
            "deduplication": {
                "enabled": True,
                "scan_paths": [
                    "docs/",
                    "*.md",
                ],  # Default: docs/ dir and root .md files
                "reference_instead_of_duplicate": True,
                "auto_merge_existing": True,  # Auto-merge when existing architecture found
            },
        },
        "skills": {
            "auto_activation_threshold": 0.7,  # Minimum relevance score for auto-discovery
            "max_auto_skills": 3,  # Maximum skills to auto-inject into context
            "preserve_user_edits": True,  # Preserve user modifications in context.md
            "registry_url": "https://skills.sh/api",  # Skills registry API URL
            "evaluation_required": False,  # Require evaluation score before install
        },
    }


def get_architecture_diagram_format(project_path: Optional[Path] = None) -> str:
    """Get the configured architecture diagram format.

    Args:
        project_path: (Ignored - global config is used)

    Returns:
        Diagram format: "mermaid" or "ascii" (defaults to "mermaid")
    """
    config = load_config(project_path)

    # Ensure architecture section exists
    if "architecture" not in config:
        config["architecture"] = {"diagram_format": "mermaid"}
        save_config(project_path, config)
        return "mermaid"

    # Get diagram format with fallback to mermaid
    return config.get("architecture", {}).get("diagram_format", "mermaid")


def set_architecture_diagram_format(
    diagram_format: str, project_path: Optional[Path] = None
) -> None:
    """Set the architecture diagram format.

    Args:
        diagram_format: "mermaid" or "ascii"
        project_path: (Ignored - global config is used)
    """
    if diagram_format not in ["mermaid", "ascii"]:
        console.print(
            f"[red]Error:[/red] Invalid diagram format '{diagram_format}'. "
            f"Must be 'mermaid' or 'ascii'."
        )
        return

    config = load_config(project_path)

    # Ensure architecture section exists
    if "architecture" not in config:
        config["architecture"] = {}

    config["architecture"]["diagram_format"] = diagram_format
    save_config(project_path, config)

    console.print(
        f"[green]✓[/green] Architecture diagram format set to: {diagram_format}"
    )


def get_architecture_views(project_path: Optional[Path] = None) -> str:
    """Get the configured architecture views setting.

    Args:
        project_path: (Ignored - global config is used)

    Returns:
        Views setting: "core", "all", or comma-separated list (defaults to "core")
    """
    config = load_config(project_path)

    if "architecture" not in config:
        config["architecture"] = {"views": "core"}
        save_config(project_path, config)
        return "core"

    return config.get("architecture", {}).get("views", "core")


def get_adr_heuristic(project_path: Optional[Path] = None) -> str:
    """Get the configured ADR heuristic.

    Args:
        project_path: (Ignored - global config is used)

    Returns:
        Heuristic: "surprising", "all", or "minimal" (defaults to "surprising")
    """
    config = load_config(project_path)

    if "architecture" not in config or "adr" not in config.get("architecture", {}):
        return "surprising"

    return config.get("architecture", {}).get("adr", {}).get("heuristic", "surprising")


def get_architecture_config(project_path: Optional[Path] = None) -> dict:
    """Get the complete architecture configuration.

    Args:
        project_path: (Ignored - global config is used)

    Returns:
        Dictionary containing all architecture configuration
    """
    config = load_config(project_path)

    default_config = {
        "diagram_format": "mermaid",
        "views": "core",
        "adr": {
            "heuristic": "surprising",
            "check_constitution": True,
            "allow_overrides": True,
            "duplication_threshold": "strict",
            "max_adrs": 10,
            "custom_rules": {"obvious": [], "surprising": []},
        },
        "deduplication": {
            "enabled": True,
            "scan_paths": ["docs/", "*.md"],
            "reference_instead_of_duplicate": True,
            "auto_merge_existing": True,
        },
    }

    if "architecture" not in config:
        return default_config

    arch_config = config.get("architecture", {})

    # Merge with defaults
    result = default_config.copy()
    result.update({k: v for k, v in arch_config.items() if v is not None})

    return result


# Skills configuration helpers


def get_skills_config(project_path: Optional[Path] = None) -> dict:
    """Get skills configuration from global config.

    Args:
        project_path: (Ignored - global config is used)

    Returns:
        Skills config dict with defaults
    """
    config = load_config(project_path)

    # Return skills section with defaults
    defaults = {
        "auto_activation_threshold": 0.7,
        "max_auto_skills": 3,
        "preserve_user_edits": True,
        "registry_url": "https://skills.sh/api",
        "evaluation_required": False,
    }

    skills_config = config.get("skills", {})
    # Merge with defaults
    for key, value in defaults.items():
        if key not in skills_config:
            skills_config[key] = value

    return skills_config


def set_skills_config(key: str, value, project_path: Optional[Path] = None) -> None:
    """Set a skills configuration value.

    Args:
        key: Config key to set
        value: Value to set
        project_path: (Ignored - global config is used)
    """
    config = load_config(project_path)

    if "skills" not in config:
        config["skills"] = {}

    config["skills"][key] = value
    save_config(project_path, config)


# Workflow mode configuration


CLAUDE_LOCAL_PATH = Path.home() / ".claude" / "local" / "claude"

BANNER = """
███████╗██████╗ ███████╗ ██████╗██╗███████╗██╗   ██╗
██╔════╝██╔══██╗██╔════╝██╔════╝██║██╔════╝╚██╗ ██╔╝
███████╗██████╔╝█████╗  ██║     ██║█████╗   ╚████╔╝ 
╚════██║██╔═══╝ ██╔══╝  ██║     ██║██╔══╝    ╚██╔╝  
███████║██║     ███████╗╚██████╗██║██║        ██║   
╚══════╝╚═╝     ╚══════╝ ╚═════╝╚═╝╚═╝        ╚═╝   
"""

TAGLINE = "Agentic SDLC Spec Kit - Spec-Driven Development Toolkit"


class StepTracker:
    """Track and render hierarchical steps without emojis, similar to Claude Code tree output.
    Supports live auto-refresh via an attached refresh callback.
    """

    def __init__(self, title: str):
        self.title = title
        self.steps = []  # list of dicts: {key, label, status, detail}
        self.status_order = {
            "pending": 0,
            "running": 1,
            "done": 2,
            "error": 3,
            "skipped": 4,
        }
        self._refresh_cb = None  # callable to trigger UI refresh

    def attach_refresh(self, cb):
        self._refresh_cb = cb

    def add(self, key: str, label: str):
        if key not in [s["key"] for s in self.steps]:
            self.steps.append(
                {"key": key, "label": label, "status": "pending", "detail": ""}
            )
            self._maybe_refresh()

    def start(self, key: str, detail: str = ""):
        self._update(key, status="running", detail=detail)

    def complete(self, key: str, detail: str = ""):
        self._update(key, status="done", detail=detail)

    def error(self, key: str, detail: str = ""):
        self._update(key, status="error", detail=detail)

    def skip(self, key: str, detail: str = ""):
        self._update(key, status="skipped", detail=detail)

    def _update(self, key: str, status: str, detail: str):
        for s in self.steps:
            if s["key"] == key:
                s["status"] = status
                if detail:
                    s["detail"] = detail
                self._maybe_refresh()
                return

        self.steps.append(
            {"key": key, "label": key, "status": status, "detail": detail}
        )
        self._maybe_refresh()

    def _maybe_refresh(self):
        if self._refresh_cb:
            try:
                self._refresh_cb()
            except Exception:
                pass

    def render(self):
        tree = Tree(Text(self.title, style=ACCENT_COLOR), guide_style="grey50")
        for step in self.steps:
            label = step["label"]
            detail_text = step["detail"].strip() if step["detail"] else ""

            status = step["status"]
            if status == "done":
                symbol = "[green]●[/green]"
            elif status == "pending":
                symbol = "[green dim]○[/green dim]"
            elif status == "running":
                symbol = f"[{ACCENT_COLOR}]○[/{ACCENT_COLOR}]"
            elif status == "error":
                symbol = "[red]●[/red]"
            elif status == "skipped":
                symbol = "[yellow]○[/yellow]"
            else:
                symbol = " "

            if status == "pending":
                # Entire line light gray (pending)
                if detail_text:
                    line = (
                        f"{symbol} [bright_black]{label} ({detail_text})[/bright_black]"
                    )
                else:
                    line = f"{symbol} [bright_black]{label}[/bright_black]"
            else:
                # Label white, detail (if any) light gray in parentheses
                if detail_text:
                    line = f"{symbol} [white]{label}[/white] [bright_black]({detail_text})[/bright_black]"
                else:
                    line = f"{symbol} [white]{label}[/white]"

            tree.add(line)
        return tree


def get_key():
    """Get a single keypress in a cross-platform way using readchar."""
    key = readchar.readkey()

    if key == readchar.key.UP or key == readchar.key.CTRL_P:
        return "up"
    if key == readchar.key.DOWN or key == readchar.key.CTRL_N:
        return "down"

    if key == readchar.key.ENTER:
        return "enter"

    if key == readchar.key.ESC:
        return "escape"

    if key == readchar.key.CTRL_C:
        raise KeyboardInterrupt

    return key


def select_with_arrows(
    options: dict,
    prompt_text: str = "Select an option",
    default_key: Optional[str] = None,
) -> str:
    """
    Interactive selection using arrow keys with Rich Live display.

    Args:
        options: Dict with keys as option keys and values as descriptions
        prompt_text: Text to show above the options
        default_key: Default option key to start with

    Returns:
        Selected option key
    """
    option_keys = list(options.keys())
    if default_key and default_key in option_keys:
        selected_index = option_keys.index(default_key)
    else:
        selected_index = 0

    selected_key = None

    def create_selection_panel():
        """Create the selection panel with current selection highlighted."""
        table = Table.grid(padding=(0, 2))
        table.add_column(style=ACCENT_COLOR, justify="left", width=3)
        table.add_column(style="white", justify="left")

        for i, key in enumerate(option_keys):
            if i == selected_index:
                table.add_row(
                    "▶",
                    f"[{ACCENT_COLOR}]{key}[/{ACCENT_COLOR}] [dim]({options[key]})[/dim]",
                )
            else:
                table.add_row(
                    " ",
                    f"[{ACCENT_COLOR}]{key}[/{ACCENT_COLOR}] [dim]({options[key]})[/dim]",
                )

        table.add_row("", "")
        table.add_row(
            "", "[dim]Use ↑/↓ to navigate, Enter to select, Esc to cancel[/dim]"
        )

        return Panel(
            table,
            title=f"[bold]{prompt_text}[/bold]",
            border_style=ACCENT_COLOR,
            padding=(1, 2),
        )

    console.print()

    def run_selection_loop():
        nonlocal selected_key, selected_index
        with Live(
            create_selection_panel(),
            console=console,
            transient=True,
            auto_refresh=False,
        ) as live:
            while True:
                try:
                    key = get_key()
                    if key == "up":
                        selected_index = (selected_index - 1) % len(option_keys)
                    elif key == "down":
                        selected_index = (selected_index + 1) % len(option_keys)
                    elif key == "enter":
                        selected_key = option_keys[selected_index]
                        break
                    elif key == "escape":
                        console.print("\n[yellow]Selection cancelled[/yellow]")
                        raise typer.Exit(1)

                    live.update(create_selection_panel(), refresh=True)

                except KeyboardInterrupt:
                    console.print("\n[yellow]Selection cancelled[/yellow]")
                    raise typer.Exit(1)

    run_selection_loop()

    if selected_key is None:
        console.print("\n[red]Selection failed.[/red]")
        raise typer.Exit(1)

    return selected_key


console = Console()


class BannerGroup(TyperGroup):
    """Custom group that shows banner before help."""

    def format_help(self, ctx, formatter):
        # Show banner before help
        show_banner()
        super().format_help(ctx, formatter)


app = typer.Typer(
    name="specify",
    help="Setup tool for Specify spec-driven development projects",
    add_completion=False,
    invoke_without_command=True,
    cls=BannerGroup,
)

# ============================================================================
# Skills Package Manager Subcommand
# ============================================================================

skill_app = typer.Typer(
    name="skill",
    help="Manage agent skills - search, install, update, and evaluate skills",
    add_completion=False,
    invoke_without_command=True,
)


@skill_app.callback()
def skill_callback(ctx: typer.Context):
    """Show skills banner when no subcommand is provided."""
    if ctx.invoked_subcommand is None:
        show_skills_banner()


@skill_app.command("search")
def skill_search(
    query: str = typer.Argument(..., help="Search query for skills"),
    category: Optional[str] = typer.Option(
        None, "--category", "-c", help="Filter by category"
    ),
    min_score: Optional[int] = typer.Option(
        None, "--min-score", "-s", help="Minimum evaluation score"
    ),
    limit: int = typer.Option(20, "--limit", "-l", help="Maximum results to return"),
    json_output: bool = typer.Option(
        False, "--json", "-j", help="Output as JSON for scripting"
    ),
):
    """Search for skills in the skills.sh registry."""
    from .skills import SkillsRegistryClient

    registry = SkillsRegistryClient()
    results = registry.search(query, limit=limit, min_installs=0)

    # Filter by category if specified
    if category:
        results = [
            r
            for r in results
            if category.lower() in [c.lower() for c in (r.categories or [])]
        ]

    # Filter by score if specified (note: registry results don't have scores yet)
    if min_score:
        console.print(
            "[yellow]Note:[/yellow] Score filtering not available in registry search"
        )

    if json_output:
        import json as json_module

        output = [
            {
                "name": r.name,
                "owner": r.owner,
                "repo": r.repo,
                "description": r.description,
                "installs": r.installs,
                "categories": r.categories,
                "skill_ref": r.skill_ref,
            }
            for r in results
        ]
        console.print(json_module.dumps(output, indent=2))
    else:
        if not results:
            console.print(f"[yellow]No skills found matching '{query}'[/yellow]")
            return

        console.print(
            f"\n[bold]Found {len(results)} skills matching '{query}':[/bold]\n"
        )

        for r in results:
            console.print(
                f"[{ACCENT_COLOR}]{r.name}[/{ACCENT_COLOR}] ({r.owner}/{r.repo})"
            )
            if r.description:
                console.print(f"  {r.description}")
            if r.installs:
                console.print(f"  [dim]Installs: {r.installs:,}[/dim]")
            if r.categories:
                console.print(f"  [dim]Categories: {', '.join(r.categories)}[/dim]")
            console.print(
                f"  [cyan]Install: specify skill install {r.skill_ref}[/cyan]"
            )
            console.print()


@skill_app.command("install")
def skill_install(
    skill_ref: str = typer.Argument(
        ...,
        help="Skill reference (github:org/repo/skill, local:./path, or registry:name)",
    ),
    version: Optional[str] = typer.Option(
        None, "--version", "-v", help="Specific version to install"
    ),
    no_save: bool = typer.Option(
        False, "--no-save", help="Don't save to skills.json manifest"
    ),
    force: bool = typer.Option(
        False, "--force", "-f", help="Reinstall even if already installed"
    ),
    evaluate: bool = typer.Option(
        False, "--eval", "-e", help="Run evaluation after install"
    ),
    skip_blocked_check: bool = typer.Option(
        False, "--skip-blocked-check", help="Skip team blocked skills check"
    ),
):
    """Install a skill from various sources."""
    from .skills import SkillsManifest, SkillInstaller, SkillEvaluator
    from .skills.manifest import TeamSkillsManifest

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)

    # Check for team manifest and blocked skills enforcement
    team_manifest = None
    if not skip_blocked_check:
        config = load_config(project_path)
        team_directives_path = config.get("team_directives", {}).get("path")
        if not team_directives_path:
            default_path = project_path / ".specify" / "memory" / "team-ai-directives"
            if default_path.exists():
                team_directives_path = str(default_path)

        if team_directives_path:
            team_directives = Path(team_directives_path)
            if team_directives.exists():
                team_manifest = TeamSkillsManifest(team_directives)
                if team_manifest.exists() and team_manifest.should_enforce_blocked():
                    blocked = team_manifest.get_blocked_skills()
                    # Check if skill is blocked (partial match)
                    for blocked_skill in blocked:
                        if blocked_skill in skill_ref or skill_ref in blocked_skill:
                            console.print(
                                f"[red]✗ Skill blocked by team policy:[/red] {skill_ref}\n"
                                f"  Blocked pattern: {blocked_skill}\n"
                                f"  Use --skip-blocked-check to override (not recommended)"
                            )
                            raise typer.Exit(1)

    installer = SkillInstaller(manifest, team_manifest)

    console.print(f"[{ACCENT_COLOR}]Installing skill:[/{ACCENT_COLOR}] {skill_ref}")

    success, message = installer.install(
        skill_ref, version=version, save=not no_save, force=force
    )

    if success:
        console.print(f"[green]✓[/green] {message}")

        if evaluate:
            console.print(f"\n[{ACCENT_COLOR}]Running evaluation...[/{ACCENT_COLOR}]")
            # Find the installed skill directory
            skills_dir = manifest.skills_dir
            for skill_dir in skills_dir.iterdir():
                if skill_dir.is_dir():
                    evaluator = SkillEvaluator()
                    result = evaluator.evaluate_review(skill_dir)
                    console.print(
                        f"\nReview Score: {result.total_score}/{result.max_score} ({result.rating})"
                    )
                    break
    else:
        console.print(f"[red]✗[/red] {message}")
        raise typer.Exit(1)


@skill_app.command("update")
def skill_update(
    skill_name: Optional[str] = typer.Argument(
        None, help="Skill name to update (or all if not specified)"
    ),
    all_skills: bool = typer.Option(
        False, "--all", "-a", help="Update all installed skills"
    ),
    dry_run: bool = typer.Option(
        False, "--dry-run", "-n", help="Show what would be updated without updating"
    ),
):
    """Update installed skills to latest versions."""
    from .skills import SkillsManifest, SkillInstaller

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)
    installer = SkillInstaller(manifest)

    if not manifest.exists():
        console.print("[yellow]No skills.json found. No skills installed.[/yellow]")
        return

    if skill_name:
        # Update specific skill
        success, message, updates = installer.update(skill_name, dry_run=dry_run)
    elif all_skills:
        # Update all skills
        success, message, updates = installer.update(None, dry_run=dry_run)
    else:
        console.print(
            "[yellow]Specify a skill name or use --all to update all skills[/yellow]"
        )
        return

    if success:
        console.print(f"[green]✓[/green] {message}")
        if updates:
            for skill_id, status in updates.items():
                console.print(f"  - {skill_id}: {status}")
    else:
        console.print(f"[red]✗[/red] {message}")


@skill_app.command("remove")
def skill_remove(
    skill_name: str = typer.Argument(..., help="Skill name to remove"),
    force: bool = typer.Option(
        False, "--force", "-f", help="Remove without confirmation"
    ),
):
    """Remove an installed skill."""
    from .skills import SkillsManifest, SkillInstaller

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)

    if not manifest.exists():
        console.print("[yellow]No skills.json found. No skills installed.[/yellow]")
        return

    # Find skill by name (partial match)
    skills = manifest.list_skills()
    skill_id = None

    for sid in skills.keys():
        if skill_name in sid:
            skill_id = sid
            break

    if not skill_id:
        console.print(f"[red]Skill not found:[/red] {skill_name}")
        raise typer.Exit(1)

    if not force:
        confirm = typer.confirm(f"Remove {skill_id}?")
        if not confirm:
            console.print("Cancelled")
            return

    installer = SkillInstaller(manifest)
    success, message = installer.uninstall(skill_id)

    if success:
        console.print(f"[green]✓[/green] {message}")
    else:
        console.print(f"[red]✗[/red] {message}")


@skill_app.command("list")
def skill_list(
    outdated: bool = typer.Option(
        False, "--outdated", "-o", help="Show only outdated skills"
    ),
    json_output: bool = typer.Option(
        False, "--json", "-j", help="Output as JSON for scripting"
    ),
):
    """List installed skills."""
    from .skills import SkillsManifest

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)

    if not manifest.exists():
        console.print("[yellow]No skills.json found. No skills installed.[/yellow]")
        console.print(
            "[dim]Run 'specify skill install <skill>' to install skills[/dim]"
        )
        return

    skills = manifest.list_skills()

    if not skills:
        console.print("[yellow]No skills installed.[/yellow]")
        console.print("[dim]Run 'specify skill search <query>' to find skills[/dim]")
        return

    if json_output:
        import json as json_module

        output = {
            skill_id: {
                "version": m.version,
                "source": m.source,
                "installed_at": m.installed_at,
                "evaluation": (
                    {
                        "review_score": m.evaluation.review_score,
                        "task_score": m.evaluation.task_score,
                    }
                    if m.evaluation
                    else None
                ),
            }
            for skill_id, m in skills.items()
        }
        console.print(json_module.dumps(output, indent=2))
    else:
        console.print(f"\n[bold]Installed Skills ({len(skills)}):[/bold]\n")

        for skill_id, metadata in skills.items():
            eval_info = ""
            if metadata.evaluation:
                review = metadata.evaluation.review_score
                task = metadata.evaluation.task_score
                if review is not None or task is not None:
                    scores = []
                    if review is not None:
                        scores.append(f"Review: {review}")
                    if task is not None:
                        scores.append(f"Task: {task}")
                    eval_info = f" ({', '.join(scores)})"

            console.print(
                f"[{ACCENT_COLOR}]{skill_id}[/{ACCENT_COLOR}]@{metadata.version}"
            )
            console.print(f"  Source: {metadata.source}")
            console.print(f"  Installed: {metadata.installed_at[:10]}{eval_info}")
            console.print()


@skill_app.command("eval")
def skill_eval(
    skill_path: str = typer.Argument(
        ..., help="Path to skill directory or installed skill name"
    ),
    review: bool = typer.Option(
        False, "--review", "-r", help="Run review evaluation only"
    ),
    task: bool = typer.Option(False, "--task", "-t", help="Run task evaluation only"),
    full: bool = typer.Option(
        False, "--full", "-f", help="Run both review and task evaluations"
    ),
    report: bool = typer.Option(
        False, "--report", help="Show detailed check-by-check report"
    ),
):
    """Evaluate skill quality."""
    from .skills import SkillsManifest, SkillEvaluator

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)
    evaluator = SkillEvaluator()

    # Resolve skill path
    skill_path_obj = Path(skill_path)

    if not skill_path_obj.exists():
        # Try to find in installed skills
        if manifest.exists():
            skills_dir = manifest.skills_dir
            if skills_dir.exists():
                for skill_dir in skills_dir.iterdir():
                    if skill_dir.is_dir() and skill_path in skill_dir.name:
                        skill_path_obj = skill_dir
                        break

    if not skill_path_obj.exists():
        console.print(f"[red]Skill not found:[/red] {skill_path}")
        raise typer.Exit(1)

    console.print(
        f"\n[{ACCENT_COLOR}]Evaluating skill:[/{ACCENT_COLOR}] {skill_path_obj.name}\n"
    )

    # Run review evaluation (default if no flags)
    if review or full or (not review and not task):
        result = evaluator.evaluate_review(skill_path_obj)

        console.print(
            f"[bold]Review Score:[/bold] {result.total_score}/{result.max_score} ({result.rating})"
        )
        console.print()

        console.print("[bold]Breakdown:[/bold]")
        for category, score in result.breakdown.items():
            console.print(f"  {category}: {score} points")

        if report:
            console.print()
            console.print("[bold]Detailed Checks:[/bold]")
            for check in result.checks:
                if check.passed:
                    console.print(
                        f"  [green]✓[/green] {check.name} ({check.points}/{check.max_points})"
                    )
                else:
                    console.print(
                        f"  [red]✗[/red] {check.name} ({check.points}/{check.max_points})"
                    )
                    if check.message:
                        console.print(f"    [dim]{check.message}[/dim]")

    # Task evaluation is not yet implemented
    if task or full:
        console.print()
        console.print(
            "[yellow]Note:[/yellow] Task evaluation requires test scenarios (not yet available)"
        )


@skill_app.command("sync-team")
def skill_sync_team(
    dry_run: bool = typer.Option(
        False, "--dry-run", "-n", help="Show what would be synced without syncing"
    ),
    force: bool = typer.Option(
        False, "--force", "-f", help="Force reinstall of all team skills"
    ),
):
    """Sync with team skills manifest (install required, suggest recommended)."""
    from .skills import SkillsManifest, SkillInstaller
    from .skills.manifest import TeamSkillsManifest

    project_path = Path.cwd()
    config = load_config(project_path)

    # Find team directives path
    team_directives_path = config.get("team_directives", {}).get("path")
    if not team_directives_path:
        # Try default location
        default_path = project_path / ".specify" / "memory" / "team-ai-directives"
        if default_path.exists():
            team_directives_path = str(default_path)

    if not team_directives_path:
        console.print(
            "[yellow]No team directives configured.[/yellow]\n"
            "Run 'specify init --team-ai-directives <path-or-url>' to configure."
        )
        return

    team_directives = Path(team_directives_path)
    if not team_directives.exists():
        console.print(f"[red]Team directives not found:[/red] {team_directives}")
        return

    team_manifest = TeamSkillsManifest(team_directives)
    if not team_manifest.exists():
        console.print(
            f"[yellow]No .skills.json found in team directives.[/yellow]\n"
            f"Expected at: {team_directives / '.skills.json'}"
        )
        return

    manifest = SkillsManifest(project_path)
    installer = SkillInstaller(manifest, team_manifest)

    # Get required and recommended skills
    required = team_manifest.get_required_skills()
    recommended = team_manifest.get_recommended_skills()
    blocked = team_manifest.get_blocked_skills()

    console.print(f"\n[{ACCENT_COLOR}]Team Skills Manifest:[/{ACCENT_COLOR}]")
    console.print(f"  Required: {len(required)}")
    console.print(f"  Recommended: {len(recommended)}")
    console.print(f"  Blocked: {len(blocked)}")
    console.print()

    # Install required skills
    if required:
        console.print("[bold]Required Skills:[/bold]")
        for skill_ref, version_spec in required.items():
            current = manifest.get_skill(skill_ref)
            if current and not force:
                console.print(
                    f"  [green]✓[/green] {skill_ref}@{current.version} (already installed)"
                )
            else:
                if dry_run:
                    console.print(f"  [cyan]→[/cyan] Would install: {skill_ref}")
                else:
                    version = version_spec.lstrip("^~") if version_spec != "*" else None
                    success, message = installer.install(
                        skill_ref, version=version, force=force
                    )
                    if success:
                        console.print(f"  [green]✓[/green] {message}")
                    else:
                        console.print(f"  [red]✗[/red] {message}")

    # Show recommended skills
    if recommended:
        console.print()
        console.print("[bold]Recommended Skills (not auto-installed):[/bold]")
        for skill_ref, version_spec in recommended.items():
            current = manifest.get_skill(skill_ref)
            if current:
                console.print(
                    f"  [green]✓[/green] {skill_ref}@{current.version} (installed)"
                )
            else:
                console.print(f"  [dim]○[/dim] {skill_ref}")
                console.print(
                    f"    [cyan]Install: specify skill install {skill_ref}[/cyan]"
                )

    # Show blocked skills warning
    if blocked:
        console.print()
        console.print("[bold]Blocked Skills (will be rejected on install):[/bold]")
        for skill_id in blocked:
            console.print(f"  [red]✗[/red] {skill_id}")


@skill_app.command("check-updates")
def skill_check_updates():
    """Check for available skill updates."""
    from .skills import SkillsManifest

    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)

    if not manifest.exists():
        console.print("[yellow]No skills.json found. No skills installed.[/yellow]")
        return

    skills = manifest.list_skills()
    if not skills:
        console.print("[yellow]No skills installed.[/yellow]")
        return

    console.print(f"\n[{ACCENT_COLOR}]Checking for updates...[/{ACCENT_COLOR}]\n")

    # For now, we can't check actual versions from registry
    # Just show what's installed and note that manual check is needed
    has_updates = False
    for skill_id, metadata in skills.items():
        if metadata.source == "local":
            console.print(f"  [dim]○[/dim] {skill_id} (local - no update check)")
        else:
            # GitHub/GitLab skills could be checked against latest tag
            # For now, just show current version
            if metadata.version in ("main", "master", "*"):
                console.print(
                    f"  [yellow]?[/yellow] {skill_id}@{metadata.version} "
                    f"(tracking branch - run 'specify skill update {skill_id}' to refresh)"
                )
                has_updates = True
            else:
                console.print(f"  [green]✓[/green] {skill_id}@{metadata.version}")

    if has_updates:
        console.print()
        console.print(
            "[dim]Tip: Run 'specify skill update --all' to update all skills[/dim]"
        )
    else:
        console.print()
        console.print("[green]All skills are up to date.[/green]")


@skill_app.command("config")
def skill_config(
    key: Optional[str] = typer.Argument(None, help="Config key to get/set"),
    value: Optional[str] = typer.Argument(None, help="Value to set"),
):
    """View or modify skills configuration."""
    skills_config = get_skills_config()

    if key is None:
        # Show all config
        console.print(f"\n[{ACCENT_COLOR}]Skills Configuration:[/{ACCENT_COLOR}]\n")
        for k, v in skills_config.items():
            console.print(f"  {k}: {v}")
        console.print()
        console.print("[dim]Set with: specify skill config <key> <value>[/dim]")
        return

    if value is None:
        # Show specific key
        if key in skills_config:
            console.print(f"{key}: {skills_config[key]}")
        else:
            console.print(f"[red]Unknown config key:[/red] {key}")
            console.print(
                f"[dim]Available keys: {', '.join(skills_config.keys())}[/dim]"
            )
        return

    # Set value
    valid_keys = {
        "auto_activation_threshold": float,
        "max_auto_skills": int,
        "preserve_user_edits": lambda x: x.lower() in ("true", "1", "yes"),
        "registry_url": str,
        "evaluation_required": lambda x: x.lower() in ("true", "1", "yes"),
    }

    if key not in valid_keys:
        console.print(f"[red]Unknown config key:[/red] {key}")
        console.print(f"[dim]Available keys: {', '.join(valid_keys.keys())}[/dim]")
        return

    try:
        converter = valid_keys[key]
        converted_value = converter(value)
        set_skills_config(key, converted_value)
        console.print(f"[green]✓[/green] Set {key} = {converted_value}")
    except (ValueError, TypeError) as e:
        console.print(f"[red]Invalid value:[/red] {e}")


# Register skill subapp with main app
app.add_typer(skill_app, name="skill")


def show_banner():
    """Display the ASCII art banner."""
    banner_lines = BANNER.strip().split("\n")
    colors = BANNER_COLORS

    styled_banner = Text()
    for i, line in enumerate(banner_lines):
        color = colors[i % len(colors)]
        styled_banner.append(line + "\n", style=color)

    console.print(Align.center(styled_banner))
    console.print(Align.center(Text(TAGLINE, style=f"italic {ACCENT_COLOR}")))
    console.print()


def show_skills_banner():
    """Display the Skills Package Manager banner with key features."""
    skills_info = Panel(
        "[bold]Skills Package Manager[/bold]\n"
        "[dim]Auto-discover and inject relevant agent skills based on feature descriptions[/dim]\n\n"
        "[bold green]Key Features:[/bold green]\n"
        "  [cyan]Auto-Discovery[/cyan] - Automatically matched skills to features (60% description, 40% content)\n"
        "  [cyan]Dual Registry[/cyan] - Search skills.sh registry + install from GitHub/local paths\n"
        "  [cyan]Team Curation[/cyan] - Required/recommended/blocked skills via team-ai-directives\n"
        "  [cyan]Quality Evaluation[/cyan] - Built-in 100-point review scoring framework\n"
        "  [cyan]Zero Dependencies[/cyan] - Direct GitHub installation, no npm required\n\n"
        "[bold]Available Commands:[/bold]\n"
        "  [yellow]specify skill search <query>[/yellow]     Search public skills registry\n"
        "  [yellow]specify skill install <ref>[/yellow]      Install from GitHub/GitLab\n"
        "  [yellow]specify skill list[/yellow]              Show installed skills\n"
        "  [yellow]specify skill eval <path>[/yellow]       Evaluate skill quality\n"
        "  [yellow]specify skill sync-team[/yellow]         Sync with team manifest\n\n"
        "[dim]Learn more: https://github.com/tikalk/agentic-sdlc-spec-kit[/dim]",
        border_style=ACCENT_COLOR,
        padding=(1, 2),
        title="[bold]Skill-Powered Development[/bold]",
    )
    console.print(skills_info)
    console.print()


@app.callback()
def callback(ctx: typer.Context):
    """Show banner when no subcommand is provided."""
    if (
        ctx.invoked_subcommand is None
        and "--help" not in sys.argv
        and "-h" not in sys.argv
    ):
        show_banner()
        console.print(
            Align.center("[dim]Run 'specify --help' for usage information[/dim]")
        )
        console.print()


def run_command(
    cmd: list[str],
    check_return: bool = True,
    capture: bool = False,
    shell: bool = False,
) -> Optional[str]:
    """Run a shell command and optionally capture output."""
    try:
        if capture:
            result = subprocess.run(
                cmd, check=check_return, capture_output=True, text=True, shell=shell
            )
            return result.stdout.strip()
        else:
            subprocess.run(cmd, check=check_return, shell=shell)
            return None
    except subprocess.CalledProcessError as e:
        if check_return:
            console.print(f"[red]Error running command:[/red] {' '.join(cmd)}")
            console.print(f"[red]Exit code:[/red] {e.returncode}")
            if hasattr(e, "stderr") and e.stderr:
                console.print(f"[red]Error output:[/red] {e.stderr}")
            raise
        return None


def check_tool(tool: str, tracker: Optional[StepTracker] = None) -> bool:
    """Check if a tool is installed. Optionally update tracker.

    Args:
        tool: Name of the tool to check
        tracker: Optional StepTracker to update with results

    Returns:
        True if tool is found, False otherwise
    """
    # Special handling for Claude CLI after `claude migrate-installer`
    # See: https://github.com/github/spec-kit/issues/123
    # The migrate-installer command REMOVES the original executable from PATH
    # and creates an alias at ~/.claude/local/claude instead
    # This path should be prioritized over other claude executables in PATH
    if tool == "claude":
        if CLAUDE_LOCAL_PATH.exists() and CLAUDE_LOCAL_PATH.is_file():
            if tracker:
                tracker.complete(tool, "available")
            return True

    found = shutil.which(tool) is not None

    if tracker:
        if found:
            tracker.complete(tool, "available")
        else:
            tracker.error(tool, "not found")

    return found


def _run_git_command(
    args: list[str], cwd: Path | None = None, *, env: dict[str, str] | None = None
) -> subprocess.CompletedProcess:
    """Run a git command with optional working directory and environment overrides."""
    cmd = ["git"]
    if cwd is not None:
        cmd.extend(["-C", str(cwd)])
    cmd.extend(args)
    return subprocess.run(cmd, check=True, capture_output=True, text=True, env=env)


def sync_team_ai_directives(
    repo_url: str, project_root: Path, *, skip_tls: bool = False
) -> tuple[str, Path]:
    """Clone or update the team-ai-directives repository.

    When repo_url points to a local directory, return it without cloning.
    Returns a tuple of (status, resolved_path).
    """
    repo_url = (repo_url or "").strip()
    if not repo_url:
        raise ValueError("Team AI directives repository URL cannot be empty")

    potential_path = Path(repo_url).expanduser()
    if potential_path.exists() and potential_path.is_dir():
        return ("local", potential_path.resolve())

    memory_root = project_root / ".specify" / "memory"
    memory_root.mkdir(parents=True, exist_ok=True)
    destination = memory_root / TEAM_DIRECTIVES_DIRNAME

    git_env = os.environ.copy()
    if skip_tls:
        git_env["GIT_SSL_NO_VERIFY"] = "1"

    try:
        if destination.exists() and any(destination.iterdir()):
            _run_git_command(
                ["rev-parse", "--is-inside-work-tree"], cwd=destination, env=git_env
            )
            try:
                existing_remote = _run_git_command(
                    [
                        "config",
                        "--get",
                        "remote.origin.url",
                    ],
                    cwd=destination,
                    env=git_env,
                ).stdout.strip()
            except subprocess.CalledProcessError:
                existing_remote = ""

            if existing_remote and existing_remote != repo_url:
                _run_git_command(
                    ["remote", "set-url", "origin", repo_url],
                    cwd=destination,
                    env=git_env,
                )

            _run_git_command(["pull", "--ff-only"], cwd=destination, env=git_env)
            return ("updated", destination)

        if destination.exists() and not any(destination.iterdir()):
            shutil.rmtree(destination)

        memory_root.mkdir(parents=True, exist_ok=True)
        _run_git_command(["clone", repo_url, str(destination)], env=git_env)
        return ("cloned", destination)
    except subprocess.CalledProcessError as exc:
        message = exc.stderr.strip() if exc.stderr else str(exc)
        raise RuntimeError(f"Git operation failed: {message}") from exc


def configure_mcp_servers(
    project_path: Path, issue_tracker: str, team_directives_path: Path | None = None
) -> None:
    """Configure MCP servers for issue tracker integration.

    Creates or updates .mcp.json in the project root with the appropriate
    MCP server configuration for the selected issue tracker.
    """
    import json

    mcp_file = project_path / ".mcp.json"
    mcp_servers = {}

    # Load existing .mcp.json if it exists
    if mcp_file.exists():
        try:
            with open(mcp_file, "r") as f:
                data = json.load(f)
                mcp_servers = data.get("mcpServers", {})
        except (json.JSONDecodeError, IOError):
            # If file is corrupted, start fresh
            pass

    # Load team directives template if available
    if team_directives_path:
        template_file = team_directives_path / ".mcp.json"
        if template_file.exists():
            try:
                with open(template_file, "r") as f:
                    template_data = json.load(f)
                    template_servers = template_data.get("mcpServers", {})
                    # Merge template servers (template takes precedence for conflicts)
                    for name, config in template_servers.items():
                        mcp_servers[name] = config
            except (json.JSONDecodeError, IOError):
                # Skip template if corrupted
                pass

    # Get issue tracker configuration
    tracker_config = ISSUE_TRACKER_CONFIG.get(issue_tracker)
    if not tracker_config:
        raise ValueError(f"Unknown issue tracker: {issue_tracker}")

    # Add issue tracker server
    server_name = f"issue-tracker-{issue_tracker}"
    if server_name not in mcp_servers:
        mcp_servers[server_name] = {
            "type": tracker_config["type"],
            "url": tracker_config["url"],
        }

    # Write updated configuration
    mcp_data = {"mcpServers": mcp_servers}
    with open(mcp_file, "w") as f:
        json.dump(mcp_data, f, indent=2)


def configure_agent_mcp_servers(
    project_path: Path, agent: str, team_directives_path: Path | None = None
) -> None:
    """Configure MCP servers for AI agent integration.

    Creates or updates .mcp.json in the project root with the appropriate
    MCP server configuration for the selected AI coding agent.
    """
    import json

    mcp_file = project_path / ".mcp.json"
    mcp_servers = {}

    # Load existing .mcp.json if it exists
    if mcp_file.exists():
        try:
            with open(mcp_file, "r") as f:
                data = json.load(f)
                mcp_servers = data.get("mcpServers", {})
        except (json.JSONDecodeError, IOError):
            # If file is corrupted, start fresh
            pass

    # Load team directives template if available
    if team_directives_path:
        template_file = team_directives_path / ".mcp.json"
        if template_file.exists():
            try:
                with open(template_file, "r") as f:
                    template_data = json.load(f)
                    template_servers = template_data.get("mcpServers", {})
                    # Merge template servers (template takes precedence for conflicts)
                    for name, config in template_servers.items():
                        mcp_servers[name] = config
            except (json.JSONDecodeError, IOError):
                # Skip template if corrupted
                pass

    # Get agent configuration
    agent_config = AGENT_MCP_CONFIG.get(agent)
    if not agent_config:
        raise ValueError(f"Unknown agent: {agent}")

    # Add agent server
    server_name = f"agent-{agent}"
    if server_name not in mcp_servers:
        mcp_servers[server_name] = {
            "type": agent_config["type"],
            "url": agent_config["url"],
        }

    # Write updated configuration
    mcp_data = {"mcpServers": mcp_servers}
    with open(mcp_file, "w") as f:
        json.dump(mcp_data, f, indent=2)


def configure_git_platform_mcp_servers(
    project_path: Path, git_platform: str, team_directives_path: Path | None = None
) -> None:
    """Configure MCP servers for Git platform integration.

    Creates or updates .mcp.json in the project root with the appropriate
    MCP server configuration for the selected Git platform (GitHub/GitLab).
    """
    import json

    mcp_file = project_path / ".mcp.json"
    mcp_servers = {}

    # Load existing .mcp.json if it exists
    if mcp_file.exists():
        try:
            with open(mcp_file, "r") as f:
                data = json.load(f)
                mcp_servers = data.get("mcpServers", {})
        except json.JSONDecodeError:
            # Reset if corrupted
            mcp_servers = {}

    # Load template from team directives if available
    if team_directives_path:
        template_file = team_directives_path / ".mcp.json"
        if template_file.exists():
            try:
                with open(template_file, "r") as f:
                    template_data = json.load(f)
                    template_servers = template_data.get("mcpServers", {})
                    # Merge template servers (don't overwrite existing ones)
                    for name, config in template_servers.items():
                        if name not in mcp_servers:
                            mcp_servers[name] = config
            except json.JSONDecodeError:
                # Skip template if corrupted
                pass

    # Get Git platform configuration
    platform_config = GIT_PLATFORM_CONFIG.get(git_platform)
    if not platform_config:
        raise ValueError(f"Unknown Git platform: {git_platform}")

    # Add Git platform server
    server_name = f"git-platform-{git_platform}"
    if server_name not in mcp_servers:
        mcp_servers[server_name] = {
            "type": platform_config["type"],
            "url": platform_config["url"],
        }

    # Write updated configuration
    mcp_data = {"mcpServers": mcp_servers}
    with open(mcp_file, "w") as f:
        json.dump(mcp_data, f, indent=2)


def is_git_repo(path: Optional[Path] = None) -> bool:
    """Check if the specified path is inside a git repository."""
    if path is None:
        path = Path.cwd()

    if not path.is_dir():
        return False

    try:
        # Use git command to check if inside a work tree
        subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            check=True,
            capture_output=True,
            cwd=path,
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def init_git_repo(
    project_path: Path, quiet: bool = False
) -> Tuple[bool, Optional[str]]:
    """Initialize a git repository in the specified path.

    Args:
        project_path: Path to initialize git repository in
        quiet: if True suppress console output (tracker handles status)

    Returns:
        Tuple of (success: bool, error_message: Optional[str])
    """
    original_cwd = Path.cwd()
    try:
        os.chdir(project_path)
        if not quiet:
            console.print("[{ACCENT_COLOR}]Initializing git repository...[/cyan]")
        subprocess.run(["git", "init"], check=True, capture_output=True, text=True)
        subprocess.run(["git", "add", "."], check=True, capture_output=True, text=True)
        subprocess.run(
            ["git", "commit", "-m", "Initial commit from Specify template"],
            check=True,
            capture_output=True,
            text=True,
        )
        if not quiet:
            console.print("[green]✓[/green] Git repository initialized")
        return True, None

    except subprocess.CalledProcessError as e:
        error_msg = f"Command: {' '.join(e.cmd)}\nExit code: {e.returncode}"
        if e.stderr:
            error_msg += f"\nError: {e.stderr.strip()}"
        elif e.stdout:
            error_msg += f"\nOutput: {e.stdout.strip()}"

        if not quiet:
            console.print(f"[red]Error initializing git repository:[/red] {e}")
        return False, error_msg
    finally:
        os.chdir(original_cwd)


def handle_vscode_settings(
    sub_item, dest_file, rel_path, verbose=False, tracker=None
) -> None:
    """Handle merging or copying of .vscode/settings.json files."""

    def log(message, color="green"):
        if verbose and not tracker:
            console.print(f"[{color}]{message}[/] {rel_path}")

    try:
        with open(sub_item, "r", encoding="utf-8") as f:
            new_settings = json.load(f)

        if dest_file.exists():
            merged = merge_json_files(
                dest_file, new_settings, verbose=verbose and not tracker
            )
            with open(dest_file, "w", encoding="utf-8") as f:
                json.dump(merged, f, indent=4)
                f.write("\n")
            log("Merged:", "green")
        else:
            shutil.copy2(sub_item, dest_file)
            log("Copied (no existing settings.json):", "blue")

    except Exception as e:
        log(f"Warning: Could not merge, copying instead: {e}", "yellow")
        shutil.copy2(sub_item, dest_file)


def merge_json_files(
    existing_path: Path, new_content: dict, verbose: bool = False
) -> dict:
    """Merge new JSON content into existing JSON file.

    Performs a deep merge where:
    - New keys are added
    - Existing keys are preserved unless overwritten by new content
    - Nested dictionaries are merged recursively
    - Lists and other values are replaced (not merged)

    Args:
        existing_path: Path to existing JSON file
        new_content: New JSON content to merge in
        verbose: Whether to print merge details

    Returns:
        Merged JSON content as dict
    """
    try:
        with open(existing_path, "r", encoding="utf-8") as f:
            existing_content = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        # If file doesn't exist or is invalid, just use new content
        return new_content

    def deep_merge(base: dict, update: dict) -> dict:
        """Recursively merge update dict into base dict."""
        result = base.copy()
        for key, value in update.items():
            if (
                key in result
                and isinstance(result[key], dict)
                and isinstance(value, dict)
            ):
                # Recursively merge nested dictionaries
                result[key] = deep_merge(result[key], value)
            else:
                # Add new key or replace existing value
                result[key] = value
        return result

    merged = deep_merge(existing_content, new_content)

    if verbose:
        console.print(f"[cyan]Merged JSON file:[/cyan] {existing_path.name}")

    return merged


def download_template_from_github(
    ai_assistant: str,
    download_dir: Path,
    *,
    script_type: str = "sh",
    verbose: bool = True,
    show_progress: bool = True,
    client: Optional[httpx.Client] = None,
    debug: bool = False,
    github_token: Optional[str] = None,
) -> Tuple[Path, dict]:
    repo_owner = "tikalk"
    repo_name = "agentic-sdlc-spec-kit"
    if client is None:
        client = httpx.Client(verify=ssl_context)

    if verbose:
        console.print(
            f"[{ACCENT_COLOR}]Fetching latest release information...[/{ACCENT_COLOR}]"
        )
    api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases/latest"

    try:
        response = client.get(
            api_url,
            timeout=30,
            follow_redirects=True,
            headers=_github_auth_headers(github_token),
        )
        status = response.status_code
        if status != 200:
            # Format detailed error message with rate-limit info
            error_msg = _format_rate_limit_error(status, response.headers, api_url)
            if debug:
                error_msg += f"\n\n[dim]Response body (truncated 500):[/dim]\n{response.text[:500]}"
            raise RuntimeError(error_msg)
        try:
            release_data = response.json()
        except ValueError as je:
            raise RuntimeError(
                f"Failed to parse release JSON: {je}\nRaw (truncated 400): {response.text[:400]}"
            )
    except Exception as e:
        console.print("[red]Error fetching release information[/red]")
        console.print(Panel(str(e), title="Fetch Error", border_style="red"))
        raise typer.Exit(1)

    assets = release_data.get("assets", [])
    pattern = f"agentic-sdlc-spec-kit-template-{ai_assistant}-{script_type}"
    matching_assets = [
        asset
        for asset in assets
        if pattern in asset["name"] and asset["name"].endswith(".zip")
    ]

    asset = matching_assets[0] if matching_assets else None

    if asset is None:
        console.print(
            f"[red]No matching release asset found[/red] for [bold]{ai_assistant}[/bold] (expected pattern: [bold]{pattern}[/bold])"
        )
        asset_names = [a.get("name", "?") for a in assets]
        console.print(
            Panel(
                "\n".join(asset_names) or "(no assets)",
                title="Available Assets",
                border_style="yellow",
            )
        )
        raise typer.Exit(1)

    download_url = asset["browser_download_url"]
    filename = asset["name"]
    file_size = asset["size"]

    if verbose:
        console.print(f"[{ACCENT_COLOR}]Found template:[/{ACCENT_COLOR}] {filename}")
        console.print(f"[{ACCENT_COLOR}]Size:[/{ACCENT_COLOR}] {file_size:,} bytes")
        console.print(
            f"[{ACCENT_COLOR}]Release:[/{ACCENT_COLOR}] {release_data['tag_name']}"
        )

    zip_path = download_dir / filename
    if verbose:
        console.print(f"[{ACCENT_COLOR}]Downloading template...[/{ACCENT_COLOR}]")

    try:
        with client.stream(
            "GET",
            download_url,
            timeout=60,
            follow_redirects=True,
            headers=_github_auth_headers(github_token),
        ) as response:
            if response.status_code != 200:
                # Handle rate-limiting on download as well
                error_msg = _format_rate_limit_error(
                    response.status_code, response.headers, download_url
                )
                if debug:
                    error_msg += f"\n\n[dim]Response body (truncated 400):[/dim]\n{response.text[:400]}"
                raise RuntimeError(error_msg)
            total_size = int(response.headers.get("content-length", 0))
            with open(zip_path, "wb") as f:
                if total_size == 0:
                    for chunk in response.iter_bytes(chunk_size=8192):
                        f.write(chunk)
                else:
                    if show_progress:
                        with Progress(
                            SpinnerColumn(),
                            TextColumn("[progress.description]{task.description}"),
                            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
                            console=console,
                        ) as progress:
                            task = progress.add_task("Downloading...", total=total_size)
                            downloaded = 0
                            for chunk in response.iter_bytes(chunk_size=8192):
                                f.write(chunk)
                                downloaded += len(chunk)
                                progress.update(task, completed=downloaded)
                    else:
                        for chunk in response.iter_bytes(chunk_size=8192):
                            f.write(chunk)
    except Exception as e:
        console.print("[red]Error downloading template[/red]")
        detail = str(e)
        if zip_path.exists():
            zip_path.unlink()
        console.print(Panel(detail, title="Download Error", border_style="red"))
        raise typer.Exit(1)
    if verbose:
        console.print(f"Downloaded: {filename}")
    metadata = {
        "filename": filename,
        "size": file_size,
        "release": release_data["tag_name"],
        "asset_url": download_url,
    }
    return zip_path, metadata


def download_and_extract_template(
    project_path: Path,
    ai_assistant: str,
    script_type: str,
    is_current_dir: bool = False,
    *,
    verbose: bool = True,
    tracker: StepTracker | None = None,
    client: Optional[httpx.Client] = None,
    debug: bool = False,
    github_token: Optional[str] = None,
) -> Path:
    """Download the latest release and extract it to create a new project.
    Returns project_path. Uses tracker if provided (with keys: fetch, download, extract, cleanup)
    """
    current_dir = Path.cwd()

    if tracker:
        tracker.start("fetch", "contacting GitHub API")
    try:
        zip_path, meta = download_template_from_github(
            ai_assistant,
            current_dir,
            script_type=script_type,
            verbose=verbose and tracker is None,
            show_progress=(tracker is None),
            client=client,
            debug=debug,
            github_token=github_token,
        )
        if tracker:
            tracker.complete(
                "fetch", f"release {meta['release']} ({meta['size']:,} bytes)"
            )
            tracker.add("download", "Download template")
            tracker.complete("download", meta["filename"])
    except Exception as e:
        if tracker:
            tracker.error("fetch", str(e))
        else:
            if verbose:
                console.print(f"[red]Error downloading template:[/red] {e}")
        raise

    if tracker:
        tracker.add("extract", "Extract template")
        tracker.start("extract")
    elif verbose:
        console.print("Extracting template...")

    try:
        if not is_current_dir:
            project_path.mkdir(parents=True)

        with zipfile.ZipFile(zip_path, "r") as zip_ref:
            zip_contents = zip_ref.namelist()
            if tracker:
                tracker.start("zip-list")
                tracker.complete("zip-list", f"{len(zip_contents)} entries")
            elif verbose:
                console.print(
                    f"[{ACCENT_COLOR}]ZIP contains {len(zip_contents)} items[/{ACCENT_COLOR}]"
                )

            if is_current_dir:
                with tempfile.TemporaryDirectory() as temp_dir:
                    temp_path = Path(temp_dir)
                    zip_ref.extractall(temp_path)

                    extracted_items = list(temp_path.iterdir())
                    if tracker:
                        tracker.start("extracted-summary")
                        tracker.complete(
                            "extracted-summary", f"temp {len(extracted_items)} items"
                        )
                    elif verbose:
                        console.print(
                            f"[{ACCENT_COLOR}]Extracted {len(extracted_items)} items to temp location[/{ACCENT_COLOR}]"
                        )

                    source_dir = temp_path
                    if len(extracted_items) == 1 and extracted_items[0].is_dir():
                        source_dir = extracted_items[0]
                        if tracker:
                            tracker.add("flatten", "Flatten nested directory")
                            tracker.complete("flatten")
                        elif verbose:
                            console.print(
                                f"[{ACCENT_COLOR}]Found nested directory structure[/{ACCENT_COLOR}]"
                            )

                    for item in source_dir.iterdir():
                        dest_path = project_path / item.name
                        if item.is_dir():
                            if dest_path.exists():
                                if verbose and not tracker:
                                    console.print(
                                        f"[yellow]Merging directory:[/yellow] {item.name}"
                                    )
                                for sub_item in item.rglob("*"):
                                    if sub_item.is_file():
                                        rel_path = sub_item.relative_to(item)
                                        dest_file = dest_path / rel_path
                                        dest_file.parent.mkdir(
                                            parents=True, exist_ok=True
                                        )
                                        # Special handling for .vscode/settings.json - merge instead of overwrite
                                        if (
                                            dest_file.name == "settings.json"
                                            and dest_file.parent.name == ".vscode"
                                        ):
                                            handle_vscode_settings(
                                                sub_item,
                                                dest_file,
                                                rel_path,
                                                verbose,
                                                tracker,
                                            )
                                        else:
                                            shutil.copy2(sub_item, dest_file)
                            else:
                                shutil.copytree(item, dest_path)
                        else:
                            if dest_path.exists() and verbose and not tracker:
                                console.print(
                                    f"[yellow]Overwriting file:[/yellow] {item.name}"
                                )
                            shutil.copy2(item, dest_path)
                    if verbose and not tracker:
                        console.print(
                            f"[{ACCENT_COLOR}]Template files merged into current directory[/{ACCENT_COLOR}]"
                        )
            else:
                zip_ref.extractall(project_path)

                extracted_items = list(project_path.iterdir())
                if tracker:
                    tracker.start("extracted-summary")
                    tracker.complete(
                        "extracted-summary", f"{len(extracted_items)} top-level items"
                    )
                elif verbose:
                    console.print(
                        f"[{ACCENT_COLOR}]Extracted {len(extracted_items)} items to {project_path}:[/{ACCENT_COLOR}]"
                    )
                    for item in extracted_items:
                        console.print(
                            f"  - {item.name} ({'dir' if item.is_dir() else 'file'})"
                        )

                if len(extracted_items) == 1 and extracted_items[0].is_dir():
                    nested_dir = extracted_items[0]
                    temp_move_dir = project_path.parent / f"{project_path.name}_temp"

                    shutil.move(str(nested_dir), str(temp_move_dir))

                    project_path.rmdir()

                    shutil.move(str(temp_move_dir), str(project_path))
                    if tracker:
                        tracker.add("flatten", "Flatten nested directory")
                        tracker.complete("flatten")
                    elif verbose:
                        console.print(
                            f"[{ACCENT_COLOR}]Flattened nested directory structure[/{ACCENT_COLOR}]"
                        )

    except Exception as e:
        if tracker:
            tracker.error("extract", str(e))
        else:
            if verbose:
                console.print(f"[red]Error extracting template:[/red] {e}")
                if debug:
                    console.print(
                        Panel(str(e), title="Extraction Error", border_style="red")
                    )

        if not is_current_dir and project_path.exists():
            shutil.rmtree(project_path)
        raise typer.Exit(1)
    else:
        if tracker:
            tracker.complete("extract")
    finally:
        if tracker:
            tracker.add("cleanup", "Remove temporary archive")

        if zip_path.exists():
            zip_path.unlink()
            if tracker:
                tracker.complete("cleanup")
            elif verbose:
                console.print(f"Cleaned up: {zip_path.name}")

    # Create project-level config in .specify directory
    if tracker:
        tracker.add("config", "Create project configuration")
        tracker.start("config")

    project_config_path = get_project_config_path(project_path)
    project_config_path.parent.mkdir(parents=True, exist_ok=True)

    # Generate default config
    default_config = get_default_config()
    save_config(project_path, default_config)

    if tracker:
        tracker.complete("config", ".specify/config.json")
    elif verbose:
        console.print(
            f"[green]✓[/green] Created project configuration: {project_config_path.relative_to(project_path)}"
        )

    return project_path


def ensure_executable_scripts(
    project_path: Path, tracker: StepTracker | None = None
) -> List[str]:
    """Ensure POSIX .sh scripts under .specify/scripts (recursively) have execute bits (no-op on Windows)."""
    if os.name == "nt":
        return []  # Windows: skip silently
    scripts_root = project_path / ".specify" / "scripts"
    if not scripts_root.is_dir():
        return []
    failures: list[str] = []
    updated = 0
    for script in scripts_root.rglob("*.sh"):
        try:
            if script.is_symlink() or not script.is_file():
                continue
            try:
                with script.open("rb") as f:
                    if f.read(2) != b"#!":
                        continue
            except Exception:
                continue
            st = script.stat()
            mode = st.st_mode
            if mode & 0o111:
                continue
            new_mode = mode
            if mode & 0o400:
                new_mode |= 0o100
            if mode & 0o040:
                new_mode |= 0o010
            if mode & 0o004:
                new_mode |= 0o001
            if not (new_mode & 0o100):
                new_mode |= 0o100
            os.chmod(script, new_mode)
            updated += 1
        except Exception as e:
            failures.append(f"{script.relative_to(scripts_root)}: {e}")
    if tracker:
        detail = f"{updated} updated" + (
            f", {len(failures)} failed" if failures else ""
        )
        tracker.add("chmod", "Set script permissions recursively")
        (tracker.error if failures else tracker.complete)("chmod", detail)
    else:
        if updated:
            console.print(
                f"[{ACCENT_COLOR}]Updated execute permissions on {updated} script(s) recursively[/{ACCENT_COLOR}]"
            )
        if failures:
            console.print("[yellow]Some scripts could not be updated:[/yellow]")
            for f in failures:
                console.print(f"  - {f}")

    return failures


def ensure_constitution_from_template(
    project_path: Path, tracker: StepTracker | None = None
) -> None:
    """Copy constitution template to memory if it doesn't exist (preserves existing constitution on reinitialization)."""
    memory_constitution = project_path / ".specify" / "memory" / "constitution.md"
    template_constitution = (
        project_path / ".specify" / "templates" / "constitution-template.md"
    )

    # If constitution already exists in memory, preserve it
    if memory_constitution.exists():
        if tracker:
            tracker.add("constitution", "Constitution setup")
            tracker.skip("constitution", "existing file preserved")
        return

    # If template doesn't exist, something went wrong with extraction
    if not template_constitution.exists():
        if tracker:
            tracker.add("constitution", "Constitution setup")
            tracker.error("constitution", "template not found")
        return

    # Copy template to memory directory
    try:
        memory_constitution.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(template_constitution, memory_constitution)
        if tracker:
            tracker.add("constitution", "Constitution setup")
            tracker.complete("constitution", "copied from template")
        else:
            console.print("[cyan]Initialized constitution from template[/cyan]")
    except Exception as e:
        if tracker:
            tracker.add("constitution", "Constitution setup")
            tracker.error("constitution", str(e))
        else:
            console.print(
                f"[yellow]Warning: Could not initialize constitution: {e}[/yellow]"
            )


def _validate_ai_assistant(value: Optional[str]) -> Optional[str]:
    """Validate the ai_assistant option value."""
    if value is None:
        return None
    # Check if value looks like a flag (starts with -)
    if value.startswith("-"):
        console.print(
            f"[red]Invalid value for --ai:[/red] '{value}'.\n"
            f"Hint: Did you forget to provide a value for --ai?"
            f"\nValid options: {', '.join(AGENT_CHOICES)}"
        )
        raise typer.Exit(1)
    # Check if value is in allowed choices (case-insensitive)
    valid_choices = [c.lower() for c in AGENT_CHOICES]
    if value.lower() not in valid_choices:
        console.print(
            f"[red]Invalid value for --ai:[/red] '{value}'.\n"
            f"Valid options: {', '.join(AGENT_CHOICES)}"
        )
        raise typer.Exit(1)
    return value


def _validate_ai_commands_dir(value: Optional[str]) -> Optional[str]:
    """Validate the ai_commands_dir option value."""
    if value is None:
        return None
    # Check if value looks like a flag (starts with -)
    if value.startswith("-"):
        console.print(
            f"[red]Invalid value for --ai-commands-dir:[/red] '{value}'.\n"
            f"Hint: Did you forget to provide a value for --ai-commands-dir?"
        )
        raise typer.Exit(1)
    return value


@app.command()
def init(
    project_name: str = typer.Argument(
        None,
        help="Name for your new project directory (optional if using --here, or use '.' for current directory)",
    ),
    ai_assistant: str = typer.Option(
        None,
        "--ai",
        help="AI assistant to use: claude, gemini, copilot, cursor-agent, qwen, opencode, codex, windsurf, kilocode, auggie, codebuddy, amp, shai, q, agy, bob, qodercli, or generic (requires --ai-commands-dir)",
        case_sensitive=False,
        autocompletion=lambda: list(AGENT_CONFIG.keys()),
        callback=_validate_ai_assistant,
    ),
    ai_commands_dir: str = typer.Option(
        None,
        "--ai-commands-dir",
        help="Directory for agent command files (required with --ai generic, e.g. .myagent/commands/)",
        allow_from_autoenv=True,
        callback=lambda value: _validate_ai_commands_dir(value),
    ),
    script_type: str = typer.Option(
        None, "--script", help="Script type to use: sh or ps"
    ),
    ignore_agent_tools: bool = typer.Option(
        False,
        "--ignore-agent-tools",
        help="Skip checks for AI agent tools like Claude Code",
    ),
    no_git: bool = typer.Option(
        False, "--no-git", help="Skip git repository initialization"
    ),
    here: bool = typer.Option(
        False,
        "--here",
        help="Initialize project in the current directory instead of creating a new one",
    ),
    force: bool = typer.Option(
        False,
        "--force",
        help="Force merge/overwrite when using --here (skip confirmation)",
    ),
    skip_tls: bool = typer.Option(
        False, "--skip-tls", help="Skip SSL/TLS verification (not recommended)"
    ),
    debug: bool = typer.Option(
        False,
        "--debug",
        help="Show verbose diagnostic output for network and extraction failures",
    ),
    github_token: str = typer.Option(
        None,
        "--github-token",
        help="GitHub token to use for API requests (or set GH_TOKEN or GITHUB_TOKEN environment variable)",
    ),
    team_ai_directives: str = typer.Option(
        None,
        "--team-ai-directives",
        "--team-ai-directive",
        help="Clone or reference a team-ai-directives repository during setup",
    ),
    issue_tracker: Optional[str] = typer.Option(
        None,
        "--issue-tracker",
        help="Enable issue tracker MCP integration: github, jira, linear, gitlab",
    ),
    async_agent: Optional[str] = typer.Option(
        None,
        "--async-agent",
        help="Enable async coding agent MCP integration for autonomous task execution: jules, async-copilot, async-codex",
    ),
    git_platform: Optional[str] = typer.Option(
        None,
        "--git-platform",
        help="Enable Git platform MCP integration for PR operations: github, gitlab",
    ),
    spec_sync: bool = typer.Option(
        False,
        "--spec-sync",
        help="Enable automatic spec-code synchronization (keeps specs/*.md files updated with code changes)",
    ),
    ai_skills: bool = typer.Option(
        False,
        "--ai-skills",
        help="Install Prompt.MD templates as agent skills (requires --ai)",
    ),
):
    """
    Initialize a new Specify project from the latest template.

    This command will:
    1. Check that required tools are installed (git is optional)
    2. Let you choose your AI assistant
    3. Download the appropriate template from GitHub
    4. Extract the template to a new project directory or current directory
    5. Initialize a fresh git repository (if not --no-git and no existing repo)
    6. Optionally clone or reference a shared team-ai-directives repository
    7. Optionally configure MCP servers for issue tracker integration
    8. Optionally configure MCP servers for AI agent integration
    9. Capture learnings after delivery with /spec.levelup

    Examples:
        specify init my-project
        specify init my-project --ai claude
        specify init my-project --ai copilot --no-git
        specify init --ignore-agent-tools my-project
        specify init . --ai claude         # Initialize in current directory
        specify init .                     # Initialize in current directory (interactive AI selection)
        specify init --here --ai claude    # Alternative syntax for current directory
        specify init --here --ai codex
        specify init --here --ai codebuddy
        specify init --here
        specify init --here --force  # Skip confirmation when current directory not empty
        specify init my-project --team-ai-directives ~/workspace/team-ai-directives
        specify init my-project --team-ai-directives https://github.com/example/team-ai-directives.git
        specify init my-project --issue-tracker github
        specify init my-project --async-agent jules
        specify init my-project --git-platform github
        specify init my-project --spec-sync
        specify init my-project --ai claude --spec-sync --issue-tracker github --git-platform github
    """

    show_banner()

    if ai_skills and not ai_assistant:
        console.print("[red]Error:[/red] --ai-skills requires --ai to be specified")
        console.print(
            "[yellow]Usage:[/yellow] specify init <project> --ai <agent> --ai-skills"
        )
        raise typer.Exit(1)

    if project_name == ".":
        here = True
        project_name = None  # Clear project_name to use existing validation logic

    if here and project_name:
        console.print(
            "[red]Error:[/red] Cannot specify both project name and --here flag"
        )
        raise typer.Exit(1)

    if not here and not project_name:
        console.print(
            "[red]Error:[/red] Must specify either a project name, use '.' for current directory, or use --here flag"
        )
        raise typer.Exit(1)

    if here:
        project_name = Path.cwd().name
        project_path = Path.cwd()

        existing_items = list(project_path.iterdir())
        if existing_items:
            console.print(
                f"[{ACCENT_COLOR}]Warning:[/{ACCENT_COLOR}] Current directory is not empty ({len(existing_items)} items)"
            )
            console.print(
                f"[{ACCENT_COLOR}]Template files will be merged with existing content and may overwrite existing files[/{ACCENT_COLOR}]"
            )
            if force:
                console.print(
                    f"[{ACCENT_COLOR}]--force supplied: skipping confirmation and proceeding with merge[/{ACCENT_COLOR}]"
                )
            else:
                response = typer.confirm("Do you want to continue?")
                if not response:
                    console.print("[yellow]Operation cancelled[/yellow]")
                    raise typer.Exit(0)
    else:
        assert project_name is not None  # Ensured by check above
        project_path = Path(project_name).resolve()
        if project_path.exists():
            error_panel = Panel(
                f"Directory '[{ACCENT_COLOR}]{project_name}[/{ACCENT_COLOR}]' already exists\n"
                "Please choose a different project name or remove the existing directory.",
                title="[red]Directory Conflict[/red]",
                border_style="red",
                padding=(1, 2),
            )
            console.print()
            console.print(error_panel)
            raise typer.Exit(1)

    current_dir = Path.cwd()

    setup_lines = [
        f"[{ACCENT_COLOR}]Specify Project Setup[/{ACCENT_COLOR}]",
        "",
        f"{'Project':<15} [green]{project_path.name}[/green]",
        f"{'Working Path':<15} [dim]{current_dir}[/dim]",
    ]
    setup_lines = [line.replace("{ACCENT_COLOR}", ACCENT_COLOR) for line in setup_lines]

    if not here:
        setup_lines.append(f"{'Target Path':<15} [dim]{project_path}[/dim]")

    console.print(
        Panel("\n".join(setup_lines), border_style=ACCENT_COLOR, padding=(1, 2))
    )

    git_required_for_init = not no_git
    git_required_for_directives = bool(
        team_ai_directives and team_ai_directives.strip()
    )
    git_required = git_required_for_init or git_required_for_directives
    git_available = True

    should_init_git = False
    if not no_git:
        should_init_git = check_tool("git")
        if not should_init_git:
            console.print(
                "[yellow]Git not found - will skip repository initialization[/yellow]"
            )
    if git_required:
        git_available = check_tool("git")
        if not git_available:
            if git_required_for_directives:
                console.print(
                    "[red]Error:[/red] Git is required to sync team-ai-directives. Install git or omit --team-ai-directive."
                )
                raise typer.Exit(1)
    if git_available and git_required_for_init:
        should_init_git = True

    if ai_assistant:
        if ai_assistant not in AGENT_CONFIG:
            console.print(
                f"[red]Error:[/red] Invalid AI assistant '{ai_assistant}'. Choose from: {', '.join(AGENT_CONFIG.keys())}"
            )
            raise typer.Exit(1)
        selected_ai = ai_assistant
    else:
        # Create options dict for selection (agent_key: display_name)
        ai_choices = {key: config["name"] for key, config in AGENT_CONFIG.items()}
        selected_ai = select_with_arrows(
            ai_choices, "Choose your AI assistant:", "copilot"
        )

    # Validate issue tracker option
    if issue_tracker:
        if issue_tracker not in ISSUE_TRACKER_CONFIG:
            console.print(
                f"[red]Error:[/red] Invalid issue tracker '{issue_tracker}'. Choose from: {', '.join(ISSUE_TRACKER_CONFIG.keys())}"
            )
            raise typer.Exit(1)

    # Validate async agent option
    if async_agent:
        if async_agent not in AGENT_MCP_CONFIG:
            console.print(
                f"[red]Error:[/red] Invalid async agent '{async_agent}'. Choose from: {', '.join(AGENT_MCP_CONFIG.keys())}"
            )
            raise typer.Exit(1)

    if not ignore_agent_tools:
        agent_config = AGENT_CONFIG.get(selected_ai)
        if agent_config and agent_config["requires_cli"]:
            install_url = agent_config["install_url"]
            if not check_tool(selected_ai):
                error_panel = Panel(
                    f"{ACCENT_COLOR}{selected_ai}[/{ACCENT_COLOR}] not found\n"
                    f"Install from: [{ACCENT_COLOR}]{install_url}[/{ACCENT_COLOR}]\n"
                    f"{agent_config['name']} is required to continue with this project type.\n\n"
                    "Tip: Use [{ACCENT_COLOR}]--ignore-agent-tools[/{ACCENT_COLOR}] to skip this check",
                    title="[red]Agent Detection Error[/red]",
                    border_style="red",
                    padding=(1, 2),
                )
                console.print()
                console.print(error_panel)
                raise typer.Exit(1)

    if script_type:
        if script_type not in SCRIPT_TYPE_CHOICES:
            console.print(
                f"[red]Error:[/red] Invalid script type '{script_type}'. Choose from: {', '.join(SCRIPT_TYPE_CHOICES.keys())}"
            )
            raise typer.Exit(1)
        selected_script = script_type
    else:
        default_script = "ps" if os.name == "nt" else "sh"

        if sys.stdin.isatty():
            selected_script = select_with_arrows(
                SCRIPT_TYPE_CHOICES,
                "Choose script type (or press Enter)",
                default_script,
            )
        else:
            selected_script = default_script

    console.print(
        f"[{ACCENT_COLOR}]Selected AI assistant:[/{ACCENT_COLOR}] {selected_ai}"
    )
    console.print(
        f"[{ACCENT_COLOR}]Selected script type:[/{ACCENT_COLOR}] {selected_script}"
    )

    tracker = StepTracker("Initialize Specify Project")

    setattr(sys, "_specify_tracker_active", True)

    tracker.add("precheck", "Check required tools")
    tracker.complete("precheck", "ok")
    tracker.add("ai-select", "Select AI assistant")
    tracker.complete("ai-select", f"{selected_ai}")
    tracker.add("script-select", "Select script type")
    tracker.complete("script-select", selected_script)
    for key, label in [
        ("fetch", "Fetch latest release"),
        ("download", "Download template"),
        ("extract", "Extract template"),
        ("zip-list", "Archive contents"),
        ("extracted-summary", "Extraction summary"),
        ("chmod", "Ensure scripts executable"),
        ("gateway", "Configure gateway"),
        ("spec_sync", "Setup spec-code synchronization"),
        ("skills", "Initialize skills manifest"),
        ("constitution", "Constitution setup"),
        ("cleanup", "Cleanup"),
        ("directives", "Sync team directives"),
        ("git", "Initialize git repository"),
        ("final", "Finalize"),
    ]:
        tracker.add(key, label)

    resolved_team_directives: Path | None = None
    recommended_skills_info: list = []  # Store recommended skills to display after init

    # Use transient so live tree is replaced by the final static render (avoids duplicate output)
    # Track git error message outside Live context so it persists
    git_error_message = None

    with Live(
        tracker.render(), console=console, refresh_per_second=8, transient=True
    ) as live:
        tracker.attach_refresh(lambda: live.update(tracker.render()))
        try:
            verify = not skip_tls
            local_ssl_context = ssl_context if verify else False
            local_client = httpx.Client(verify=local_ssl_context)

            download_and_extract_template(
                project_path,
                selected_ai,
                selected_script,
                here,
                verbose=False,
                tracker=tracker,
                client=local_client,
                debug=debug,
                github_token=github_token,
            )

            ensure_executable_scripts(project_path, tracker=tracker)

            team_arg = team_ai_directives.strip() if team_ai_directives else ""
            if team_arg:
                tracker.start("directives", "syncing")
                try:
                    status, resolved_path = sync_team_ai_directives(
                        team_arg, project_path, skip_tls=skip_tls
                    )
                    resolved_team_directives = resolved_path
                    tracker.complete("directives", status)
                except Exception as e:
                    tracker.error("directives", str(e))
                    raise
            else:
                tracker.skip("directives", "not provided")

            # MCP configuration step
            if issue_tracker:
                tracker.start("mcp", "configuring")
                try:
                    configure_mcp_servers(
                        project_path,
                        issue_tracker,
                        resolved_team_directives if team_arg else None,
                    )
                    tracker.complete("mcp", "configured")
                except Exception as e:
                    tracker.error("mcp", str(e))
                    raise
            else:
                tracker.skip("mcp", "not requested")

            # Async Agent MCP configuration step
            if async_agent:
                tracker.start("async-agent-mcp", "configuring")
                try:
                    configure_agent_mcp_servers(
                        project_path,
                        async_agent,
                        resolved_team_directives if team_arg else None,
                    )
                    tracker.complete("async-agent-mcp", "configured")
                except Exception as e:
                    tracker.error("async-agent-mcp", str(e))
                    raise
            else:
                tracker.skip("async-agent-mcp", "not requested")

            # Git Platform MCP configuration step
            if git_platform:
                tracker.start("git-platform-mcp", "configuring")
                try:
                    configure_git_platform_mcp_servers(
                        project_path,
                        git_platform,
                        resolved_team_directives if team_arg else None,
                    )
                    tracker.complete("git-platform-mcp", "configured")
                except Exception as e:
                    tracker.error("git-platform-mcp", str(e))
                    raise
            else:
                tracker.skip("git-platform-mcp", "not requested")

            # Spec-code synchronization setup
            if spec_sync:
                tracker.start("spec_sync", "setting up spec-code synchronization")
                try:
                    # Determine script directory and command based on selected script type
                    if selected_script == "sh":
                        script_dir = "bash"
                        script_cmd = "bash"
                        script_ext = ".sh"
                    elif selected_script == "ps":
                        script_dir = "powershell"
                        script_cmd = "powershell"
                        script_ext = ".ps1"
                    else:
                        raise ValueError(f"Unsupported script type: {selected_script}")

                    # Run the spec hooks installation script directly
                    script_path = (
                        Path(__file__).parent.parent.parent
                        / "scripts"
                        / script_dir
                        / f"spec-hooks-install{script_ext}"
                    )
                    run_command(
                        [script_cmd, str(script_path)], check_return=True, capture=True
                    )
                    tracker.complete("spec_sync", "hooks installed")
                except Exception as e:
                    tracker.error("spec_sync", f"failed to install hooks: {str(e)}")
                    console.print(
                        f"[yellow]Warning:[/yellow] Spec sync setup failed: {str(e)}"
                    )
            else:
                tracker.skip("spec_sync", "not requested")

            # Skills manifest initialization
            tracker.start("skills", "initializing")
            try:
                from .skills import SkillsManifest, SkillInstaller
                from .skills.manifest import TeamSkillsManifest

                skills_manifest = SkillsManifest(project_path)
                # Create empty skills.json if it doesn't exist
                if not skills_manifest.exists():
                    skills_manifest.save()

                # Check for team skills manifest and auto-install required skills
                if resolved_team_directives:
                    team_skills_manifest = TeamSkillsManifest(resolved_team_directives)
                    if team_skills_manifest.exists():
                        if team_skills_manifest.should_auto_install_required():
                            required_skills = team_skills_manifest.get_required_skills()
                            if required_skills:
                                installer = SkillInstaller(
                                    skills_manifest, team_skills_manifest
                                )
                                for skill_ref, version_spec in required_skills.items():
                                    try:
                                        version = version_spec.lstrip(
                                            "^~"
                                        )  # Strip semver prefixes
                                        installer.install(skill_ref, version=version)
                                    except Exception:
                                        pass  # Continue even if a skill fails to install

                            # Capture recommended skills for display
                            recommended_skills = (
                                team_skills_manifest.get_recommended_skills()
                            )
                            for skill_ref, version_spec in recommended_skills.items():
                                recommended_skills_info.append(
                                    (skill_ref, version_spec)
                                )

                tracker.complete("skills", "manifest created")
            except Exception as e:
                tracker.error("skills", f"failed: {str(e)}")
                # Non-fatal - continue with project setup

            ensure_constitution_from_template(project_path, tracker=tracker)

            if not no_git:
                tracker.start("git")
                if is_git_repo(project_path):
                    tracker.complete("git", "existing repo detected")
                elif should_init_git:
                    success, error_msg = init_git_repo(project_path, quiet=True)
                    if success:
                        tracker.complete("git", "initialized")
                    else:
                        tracker.error("git", "init failed")
                        git_error_message = error_msg
                else:
                    tracker.skip("git", "git not available")
            else:
                tracker.skip("git", "--no-git flag")

            tracker.complete("final", "project ready")
        except Exception as e:
            tracker.error("final", str(e))
            console.print(
                Panel(
                    f"Initialization failed: {e}", title="Failure", border_style="red"
                )
            )
            if debug:
                _env_pairs = [
                    ("Python", sys.version.split()[0]),
                    ("Platform", sys.platform),
                    ("CWD", str(Path.cwd())),
                ]
                _label_width = max(len(k) for k, _ in _env_pairs)
                env_lines = [
                    f"{k.ljust(_label_width)} → [bright_black]{v}[/bright_black]"
                    for k, v in _env_pairs
                ]
                console.print(
                    Panel(
                        "\n".join(env_lines),
                        title="Debug Environment",
                        border_style="magenta",
                    )
                )
            if not here and project_path.exists():
                shutil.rmtree(project_path)
            raise typer.Exit(1)
        finally:
            pass

    console.print(tracker.render())
    console.print("\n[bold green]Project ready.[/bold green]")

    # Show git error details if initialization failed
    if git_error_message:
        console.print()
        git_error_panel = Panel(
            f"[yellow]Warning:[/yellow] Git repository initialization failed\n\n"
            f"{git_error_message}\n\n"
            f"[dim]You can initialize git manually later with:[/dim]\n"
            f"[cyan]cd {project_path if not here else '.'}[/cyan]\n"
            f"[cyan]git init[/cyan]\n"
            f"[cyan]git add .[/cyan]\n"
            f'[cyan]git commit -m "Initial commit"[/cyan]',
            title="[red]Git Initialization Failed[/red]",
            border_style="red",
            padding=(1, 2),
        )
        console.print(git_error_panel)

    if resolved_team_directives is None:
        default_directives = (
            project_path / ".specify" / "memory" / TEAM_DIRECTIVES_DIRNAME
        )
        if default_directives.exists():
            resolved_team_directives = default_directives

    if resolved_team_directives is not None:
        os.environ["SPECIFY_TEAM_DIRECTIVES"] = str(resolved_team_directives)
        # Save team directives path to consolidated config
        config = load_config(project_path)
        if "team_directives" not in config:
            config["team_directives"] = {}
        if not isinstance(config["team_directives"], dict):
            config["team_directives"] = {}
        config["team_directives"]["path"] = str(resolved_team_directives)
        save_config(project_path, config)

    # Agent folder security notice
    agent_config = AGENT_CONFIG.get(selected_ai)
    if agent_config:
        agent_folder = agent_config["folder"]
        security_notice = Panel(
            f"Some agents may store credentials, auth tokens, or other identifying and private artifacts in the agent folder within your project.\n"
            f"Consider adding [{ACCENT_COLOR}]{agent_folder}[/{ACCENT_COLOR}] (or parts of it) to [{ACCENT_COLOR}].gitignore[/{ACCENT_COLOR}] to prevent accidental credential leakage.",
            title=f"[{ACCENT_COLOR}]Agent Folder Security[/{ACCENT_COLOR}]",
            border_style=ACCENT_COLOR,
            padding=(1, 2),
        )
        console.print()
        console.print(security_notice)

    steps_lines = []
    if not here:
        steps_lines.append(
            f"1. Go to the project folder: [{ACCENT_COLOR}]cd {project_name}[/{ACCENT_COLOR}]"
        )
        step_num = 2
    else:
        steps_lines.append("1. You're already in the project directory!")
        step_num = 2

    # Add Codex-specific setup step if needed
    if selected_ai == "codex":
        codex_path = project_path / ".codex"
        quoted_path = shlex.quote(str(codex_path))
        if os.name == "nt":  # Windows
            cmd = f"setx CODEX_HOME {quoted_path}"
        else:  # Unix-like systems
            cmd = f"export CODEX_HOME={quoted_path}"

        steps_lines.append(
            f"{step_num}. Set [{ACCENT_COLOR}]CODEX_HOME[/{ACCENT_COLOR}] environment variable before running Codex: [{ACCENT_COLOR}]{cmd}[/{ACCENT_COLOR}]"
        )
        step_num += 1

    steps_lines.append(f"{step_num}. Start using slash commands with your AI agent:")

    steps_lines.append(
        f"   2.1 [{ACCENT_COLOR}]/architect.specify[/{ACCENT_COLOR}] - Interactive PRD exploration to create system ADRs"
    )
    steps_lines.append(
        f"   2.2 [{ACCENT_COLOR}]/architect.implement[/{ACCENT_COLOR}] - Execute architecture implementation from ADRs"
    )
    steps_lines.append(
        f"   2.3 [{ACCENT_COLOR}]/spec.constitution[/{ACCENT_COLOR}] - Establish project principles"
    )
    steps_lines.append(
        f"   2.4 [{ACCENT_COLOR}]/spec.specify[/{ACCENT_COLOR}] - Create baseline specification"
    )
    steps_lines.append(
        f"   2.5 [{ACCENT_COLOR}]/spec.plan[/{ACCENT_COLOR}] - Create implementation plan"
    )
    steps_lines.append(
        f"   2.6 [{ACCENT_COLOR}]/spec.tasks[/{ACCENT_COLOR}] - Generate actionable tasks"
    )
    steps_lines.append(
        f"   2.7 [{ACCENT_COLOR}]/spec.implement[/{ACCENT_COLOR}] - Execute implementation"
    )
    steps_lines.append(
        f"   2.8 [{ACCENT_COLOR}]/spec.levelup[/{ACCENT_COLOR}] - Capture learnings and create knowledge assets"
    )

    steps_panel = Panel(
        "\n".join(steps_lines),
        title="Next Steps",
        border_style=ACCENT_COLOR,
        padding=(1, 2),
    )
    console.print()
    console.print(steps_panel)

    enhancement_lines = [
        "Optional commands that you can use for your specs [bright_black](improve quality & confidence)[/bright_black]",
        "",
        f"○ [{ACCENT_COLOR}]/spec.clarify[/{ACCENT_COLOR}] [bright_black](optional)[/bright_black] - Ask structured questions to de-risk ambiguous areas before planning (run before [{ACCENT_COLOR}]/spec.plan[/{ACCENT_COLOR}] if used)",
        f"○ [{ACCENT_COLOR}]/spec.analyze[/{ACCENT_COLOR}] [bright_black](optional)[/bright_black] - Cross-artifact consistency & alignment report (after [{ACCENT_COLOR}]/spec.tasks[/{ACCENT_COLOR}], before [{ACCENT_COLOR}]/spec.implement[/{ACCENT_COLOR}])",
        f"○ [{ACCENT_COLOR}]/spec.checklist[/{ACCENT_COLOR}] [bright_black](optional)[/bright_black] - Generate quality checklists to validate requirements completeness, clarity, and consistency (after [{ACCENT_COLOR}]/spec.plan[/{ACCENT_COLOR}])",
    ]
    enhancements_panel = Panel(
        "\n".join(enhancement_lines),
        title="Enhancement Commands",
        border_style=ACCENT_COLOR,
        padding=(1, 2),
    )
    console.print()
    console.print(enhancements_panel)

    # Display recommended skills from team manifest if any
    if recommended_skills_info:
        skills_lines = [
            "Team-recommended skills for this project:",
            "",
        ]
        for skill_ref, version_spec in recommended_skills_info:
            skills_lines.append(
                f"○ [{ACCENT_COLOR}]{skill_ref}[/{ACCENT_COLOR}]@{version_spec}"
            )
        skills_lines.append("")
        skills_lines.append(
            "[dim]Install with: specify skill install <skill-ref>[/dim]"
        )
        skills_lines.append(
            "[dim]Or sync all team skills: specify skill sync-team[/dim]"
        )

        skills_panel = Panel(
            "\n".join(skills_lines),
            title="Recommended Skills",
            border_style=ACCENT_COLOR,
            padding=(1, 2),
        )
        console.print()
        console.print(skills_panel)

    if ai_skills and selected_ai:
        skills_ok = install_ai_skills(project_path, selected_ai, tracker=None)

        if skills_ok and not here:
            agent_cfg = AGENT_CONFIG.get(selected_ai, {})
            agent_folder = agent_cfg.get("folder", "")
            commands_subdir = agent_cfg.get("commands_subdir", "commands")
            if agent_folder:
                cmds_dir = project_path / agent_folder.rstrip("/") / commands_subdir
                if cmds_dir.exists():
                    try:
                        shutil.rmtree(cmds_dir)
                    except OSError:
                        console.print(
                            "[yellow]Warning: could not remove extracted commands directory[/yellow]"
                        )


@app.command()
def check():
    """Check that all required tools are installed."""
    show_banner()
    console.print("[bold]Checking for installed tools...[/bold]\n")

    tracker = StepTracker("Check Available Tools")

    tracker.add("git", "Git version control")
    git_ok = check_tool("git", tracker=tracker)

    agent_results = {}
    for agent_key, agent_config in AGENT_CONFIG.items():
        agent_name = agent_config["name"]
        requires_cli = agent_config["requires_cli"]

        tracker.add(agent_key, agent_name)

        if requires_cli:
            agent_results[agent_key] = check_tool(agent_key, tracker=tracker)
        else:
            # IDE-based agent - skip CLI check and mark as optional
            tracker.skip(agent_key, "IDE-based, no CLI check")
            agent_results[agent_key] = False  # Don't count IDE agents as "found"

    # Check VS Code variants (not in agent config)
    tracker.add("code", "Visual Studio Code")
    check_tool("code", tracker=tracker)

    tracker.add("code-insiders", "Visual Studio Code Insiders")
    check_tool("code-insiders", tracker=tracker)

    console.print(tracker.render())

    console.print("\n[bold green]Specify CLI is ready to use![/bold green]")

    if not git_ok:
        console.print("[dim]Tip: Install git for repository management[/dim]")

    if not any(agent_results.values()):
        console.print("[dim]Tip: Install an AI assistant for the best experience[/dim]")


@app.command()
def version():
    """Display version and system information."""
    import platform
    import importlib.metadata

    show_banner()

    # Get CLI version from package metadata
    cli_version = "unknown"
    try:
        cli_version = importlib.metadata.version("specify-cli")
    except Exception:
        # Fallback: try reading from pyproject.toml if running from source
        try:
            import tomllib

            pyproject_path = Path(__file__).parent.parent.parent / "pyproject.toml"
            if pyproject_path.exists():
                with open(pyproject_path, "rb") as f:
                    data = tomllib.load(f)
                    cli_version = data.get("project", {}).get("version", "unknown")
        except Exception:
            pass

    # Fetch latest template release version
    repo_owner = "github"
    repo_name = "spec-kit"
    api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases/latest"

    template_version = "unknown"
    release_date = "unknown"

    try:
        response = client.get(
            api_url,
            timeout=10,
            follow_redirects=True,
            headers=_github_auth_headers(),
        )
        if response.status_code == 200:
            release_data = response.json()
            template_version = release_data.get("tag_name", "unknown")
            # Remove 'v' prefix if present
            if template_version.startswith("v"):
                template_version = template_version[1:]
            release_date = release_data.get("published_at", "unknown")
            if release_date != "unknown":
                # Format the date nicely
                try:
                    dt = datetime.fromisoformat(release_date.replace("Z", "+00:00"))
                    release_date = dt.strftime("%Y-%m-%d")
                except Exception:
                    pass
    except Exception:
        pass

    info_table = Table(show_header=False, box=None, padding=(0, 2))
    info_table.add_column("Key", style="cyan", justify="right")
    info_table.add_column("Value", style="white")

    info_table.add_row("CLI Version", cli_version)
    info_table.add_row("Template Version", template_version)
    info_table.add_row("Released", release_date)
    info_table.add_row("", "")
    info_table.add_row("Python", platform.python_version())
    info_table.add_row("Platform", platform.system())
    info_table.add_row("Architecture", platform.machine())
    info_table.add_row("OS Version", platform.version())

    panel = Panel(
        info_table,
        title="[bold cyan]Specify CLI Information[/bold cyan]",
        border_style="cyan",
        padding=(1, 2),
    )

    console.print(panel)
    console.print()


# ===== Extension Commands =====

extension_app = typer.Typer(
    name="extension",
    help="Manage spec-kit extensions",
    add_completion=False,
)
app.add_typer(extension_app, name="extension")


def get_speckit_version() -> str:
    """Get current spec-kit version."""
    import importlib.metadata

    try:
        return importlib.metadata.version("specify-cli")
    except Exception:
        # Fallback: try reading from pyproject.toml
        try:
            import tomllib

            pyproject_path = Path(__file__).parent.parent.parent / "pyproject.toml"
            if pyproject_path.exists():
                with open(pyproject_path, "rb") as f:
                    data = tomllib.load(f)
                    return data.get("project", {}).get("version", "unknown")
        except Exception:
            # Intentionally ignore any errors while reading/parsing pyproject.toml.
            # If this lookup fails for any reason, we fall back to returning "unknown" below.
            pass
    return "unknown"


@extension_app.command("list")
def extension_list(
    available: bool = typer.Option(
        False, "--available", help="Show available extensions from catalog"
    ),
    all_extensions: bool = typer.Option(
        False, "--all", help="Show both installed and available"
    ),
):
    """List installed extensions."""
    from .extensions import ExtensionManager

    project_root = Path.cwd()

    # Check if we're in a spec-kit project
    specify_dir = project_root / ".specify"
    if not specify_dir.exists():
        console.print(
            "[red]Error:[/red] Not a spec-kit project (no .specify/ directory)"
        )
        console.print("Run this command from a spec-kit project root")
        raise typer.Exit(1)

    manager = ExtensionManager(project_root)
    installed = manager.list_installed()

    if not installed and not (available or all_extensions):
        console.print("[yellow]No extensions installed.[/yellow]")
        console.print("\nInstall an extension with:")
        console.print("  specify extension add <extension-name>")
        return

    if installed:
        console.print("\n[bold cyan]Installed Extensions:[/bold cyan]\n")

        for ext in installed:
            status_icon = "✓" if ext["enabled"] else "✗"
            status_color = "green" if ext["enabled"] else "red"

            console.print(
                f"  [{status_color}]{status_icon}[/{status_color}] [bold]{ext['name']}[/bold] (v{ext['version']})"
            )
            console.print(f"     {ext['description']}")
            console.print(
                f"     Commands: {ext['command_count']} | Hooks: {ext['hook_count']} | Status: {'Enabled' if ext['enabled'] else 'Disabled'}"
            )
            console.print()

    if available or all_extensions:
        console.print("\nInstall an extension:")
        console.print("  [cyan]specify extension add <name>[/cyan]")


@extension_app.command("add")
def extension_add(
    extension: str = typer.Argument(help="Extension name or path"),
    dev: bool = typer.Option(False, "--dev", help="Install from local directory"),
    from_url: Optional[str] = typer.Option(
        None, "--from", help="Install from custom URL"
    ),
):
    """Install an extension."""
    from .extensions import (
        ExtensionManager,
        ExtensionCatalog,
        ExtensionError,
        ValidationError,
        CompatibilityError,
    )

    project_root = Path.cwd()

    # Check if we're in a spec-kit project
    specify_dir = project_root / ".specify"
    if not specify_dir.exists():
        console.print(
            "[red]Error:[/red] Not a spec-kit project (no .specify/ directory)"
        )
        console.print("Run this command from a spec-kit project root")
        raise typer.Exit(1)

    manager = ExtensionManager(project_root)
    speckit_version = get_speckit_version()

    try:
        with console.status(f"[cyan]Installing extension: {extension}[/cyan]"):
            if dev:
                # Install from local directory
                source_path = Path(extension).expanduser().resolve()
                if not source_path.exists():
                    console.print(
                        f"[red]Error:[/red] Directory not found: {source_path}"
                    )
                    raise typer.Exit(1)

                if not (source_path / "extension.yml").exists():
                    console.print(
                        f"[red]Error:[/red] No extension.yml found in {source_path}"
                    )
                    raise typer.Exit(1)

                manifest = manager.install_from_directory(source_path, speckit_version)

            elif from_url:
                # Install from URL (ZIP file)
                import urllib.request
                import urllib.error
                from urllib.parse import urlparse

                # Validate URL
                parsed = urlparse(from_url)
                is_localhost = parsed.hostname in ("localhost", "127.0.0.1", "::1")

                if parsed.scheme != "https" and not (
                    parsed.scheme == "http" and is_localhost
                ):
                    console.print("[red]Error:[/red] URL must use HTTPS for security.")
                    console.print("HTTP is only allowed for localhost URLs.")
                    raise typer.Exit(1)

                # Warn about untrusted sources
                console.print("[yellow]Warning:[/yellow] Installing from external URL.")
                console.print("Only install extensions from sources you trust.\n")
                console.print(f"Downloading from {from_url}...")

                # Download ZIP to temp location
                download_dir = (
                    project_root / ".specify" / "extensions" / ".cache" / "downloads"
                )
                download_dir.mkdir(parents=True, exist_ok=True)
                zip_path = download_dir / f"{extension}-url-download.zip"

                try:
                    with urllib.request.urlopen(from_url, timeout=60) as response:
                        zip_data = response.read()
                    zip_path.write_bytes(zip_data)

                    # Install from downloaded ZIP
                    manifest = manager.install_from_zip(zip_path, speckit_version)
                except urllib.error.URLError as e:
                    console.print(
                        f"[red]Error:[/red] Failed to download from {from_url}: {e}"
                    )
                    raise typer.Exit(1)
                finally:
                    # Clean up downloaded ZIP
                    if zip_path.exists():
                        zip_path.unlink()

            else:
                # Install from catalog
                catalog = ExtensionCatalog(project_root)

                # Check if extension exists in catalog
                ext_info = catalog.get_extension_info(extension)
                if not ext_info:
                    console.print(
                        f"[red]Error:[/red] Extension '{extension}' not found in catalog"
                    )
                    console.print("\nSearch available extensions:")
                    console.print("  specify extension search")
                    raise typer.Exit(1)

                # Download extension ZIP
                console.print(
                    f"Downloading {ext_info['name']} v{ext_info.get('version', 'unknown')}..."
                )
                zip_path = catalog.download_extension(extension)

                try:
                    # Install from downloaded ZIP
                    manifest = manager.install_from_zip(zip_path, speckit_version)
                finally:
                    # Clean up downloaded ZIP
                    if zip_path.exists():
                        zip_path.unlink()

        console.print("\n[green]✓[/green] Extension installed successfully!")
        console.print(f"\n[bold]{manifest.name}[/bold] (v{manifest.version})")
        console.print(f"  {manifest.description}")
        console.print("\n[bold cyan]Provided commands:[/bold cyan]")
        for cmd in manifest.commands:
            console.print(f"  • {cmd['name']} - {cmd.get('description', '')}")

        console.print("\n[yellow]⚠[/yellow]  Configuration may be required")
        console.print(f"   Check: .specify/extensions/{manifest.id}/")

    except ValidationError as e:
        console.print(f"\n[red]Validation Error:[/red] {e}")
        raise typer.Exit(1)
    except CompatibilityError as e:
        console.print(f"\n[red]Compatibility Error:[/red] {e}")
        raise typer.Exit(1)
    except ExtensionError as e:
        console.print(f"\n[red]Error:[/red] {e}")
        raise typer.Exit(1)


@extension_app.command("remove")
def extension_remove(
    extension: str = typer.Argument(help="Extension ID to remove"),
    keep_config: bool = typer.Option(
        False, "--keep-config", help="Don't remove config files"
    ),
    force: bool = typer.Option(False, "--force", help="Skip confirmation"),
):
    """Uninstall an extension."""
    from .extensions import ExtensionManager

    project_root = Path.cwd()

    # Check if we're in a spec-kit project
    specify_dir = project_root / ".specify"
    if not specify_dir.exists():
        console.print(
            "[red]Error:[/red] Not a spec-kit project (no .specify/ directory)"
        )
        console.print("Run this command from a spec-kit project root")
        raise typer.Exit(1)

    manager = ExtensionManager(project_root)

    # Check if extension is installed
    if not manager.registry.is_installed(extension):
        console.print(f"[red]Error:[/red] Extension '{extension}' is not installed")
        raise typer.Exit(1)

    # Get extension info
    ext_manifest = manager.get_extension(extension)
    if ext_manifest:
        ext_name = ext_manifest.name
        cmd_count = len(ext_manifest.commands)
    else:
        ext_name = extension
        cmd_count = 0

    # Confirm removal
    if not force:
        console.print("\n[yellow]⚠  This will remove:[/yellow]")
        console.print(f"   • {cmd_count} commands from AI agent")
        console.print(f"   • Extension directory: .specify/extensions/{extension}/")
        if not keep_config:
            console.print("   • Config files (will be backed up)")
        console.print()

        confirm = typer.confirm("Continue?")
        if not confirm:
            console.print("Cancelled")
            raise typer.Exit(0)

    # Remove extension
    success = manager.remove(extension, keep_config=keep_config)

    if success:
        console.print(f"\n[green]✓[/green] Extension '{ext_name}' removed successfully")
        if keep_config:
            console.print(
                f"\nConfig files preserved in .specify/extensions/{extension}/"
            )
        else:
            console.print(
                f"\nConfig files backed up to .specify/extensions/.backup/{extension}/"
            )
        console.print(f"\nTo reinstall: specify extension add {extension}")
    else:
        console.print("[red]Error:[/red] Failed to remove extension")
        raise typer.Exit(1)


@extension_app.command("search")
def extension_search(
    query: str = typer.Argument(None, help="Search query (optional)"),
    tag: Optional[str] = typer.Option(None, "--tag", help="Filter by tag"),
    author: Optional[str] = typer.Option(None, "--author", help="Filter by author"),
    verified: bool = typer.Option(
        False, "--verified", help="Show only verified extensions"
    ),
):
    """Search for available extensions in catalog."""
    from .extensions import ExtensionCatalog, ExtensionError

    project_root = Path.cwd()

    # Check if we're in a spec-kit project
    specify_dir = project_root / ".specify"
    if not specify_dir.exists():
        console.print(
            "[red]Error:[/red] Not a spec-kit project (no .specify/ directory)"
        )
        console.print("Run this command from a spec-kit project root")
        raise typer.Exit(1)

    catalog = ExtensionCatalog(project_root)

    try:
        console.print("🔍 Searching extension catalog...")
        results = catalog.search(
            query=query, tag=tag, author=author, verified_only=verified
        )

        if not results:
            console.print("\n[yellow]No extensions found matching criteria[/yellow]")
            if query or tag or author or verified:
                console.print("\nTry:")
                console.print("  • Broader search terms")
                console.print("  • Remove filters")
                console.print("  • specify extension search (show all)")
            raise typer.Exit(0)

        console.print(f"\n[green]Found {len(results)} extension(s):[/green]\n")

        for ext in results:
            # Extension header
            verified_badge = " [green]✓ Verified[/green]" if ext.get("verified") else ""
            console.print(
                f"[bold]{ext['name']}[/bold] (v{ext['version']}){verified_badge}"
            )
            console.print(f"  {ext['description']}")

            # Metadata
            console.print(f"\n  [dim]Author:[/dim] {ext.get('author', 'Unknown')}")
            if ext.get("tags"):
                tags_str = ", ".join(ext["tags"])
                console.print(f"  [dim]Tags:[/dim] {tags_str}")

            # Stats
            stats = []
            if ext.get("downloads") is not None:
                stats.append(f"Downloads: {ext['downloads']:,}")
            if ext.get("stars") is not None:
                stats.append(f"Stars: {ext['stars']}")
            if stats:
                console.print(f"  [dim]{' | '.join(stats)}[/dim]")

            # Links
            if ext.get("repository"):
                console.print(f"  [dim]Repository:[/dim] {ext['repository']}")

            # Install command
            console.print(
                f"\n  [cyan]Install:[/cyan] specify extension add {ext['id']}"
            )
            console.print()

    except ExtensionError as e:
        console.print(f"\n[red]Error:[/red] {e}")
        console.print(
            "\nTip: The catalog may be temporarily unavailable. Try again later."
        )
        raise typer.Exit(1)


@extension_app.command("info")
def extension_info(
    extension: str = typer.Argument(help="Extension ID or name"),
):
    """Show detailed information about an extension."""
    from .extensions import ExtensionCatalog, ExtensionManager, ExtensionError

    project_root = Path.cwd()

    # Check if we're in a spec-kit project
    specify_dir = project_root / ".specify"
    if not specify_dir.exists():
        console.print(
            "[red]Error:[/red] Not a spec-kit project (no .specify/ directory)"
        )
        console.print("Run this command from a spec-kit project root")
        raise typer.Exit(1)

    catalog = ExtensionCatalog(project_root)
    manager = ExtensionManager(project_root)

    try:
        ext_info = catalog.get_extension_info(extension)

        if not ext_info:
            console.print(
                f"[red]Error:[/red] Extension '{extension}' not found in catalog"
            )
            console.print("\nTry: specify extension search")
            raise typer.Exit(1)

        # Header
        verified_badge = (
            " [green]✓ Verified[/green]" if ext_info.get("verified") else ""
        )
        console.print(
            f"\n[bold]{ext_info['name']}[/bold] (v{ext_info['version']}){verified_badge}"
        )
        console.print(f"ID: {ext_info['id']}")
        console.print()

        # Description
        console.print(f"{ext_info['description']}")
        console.print()

        # Author and License
        console.print(f"[dim]Author:[/dim] {ext_info.get('author', 'Unknown')}")
        console.print(f"[dim]License:[/dim] {ext_info.get('license', 'Unknown')}")
        console.print()

        # Requirements
        if ext_info.get("requires"):
            console.print("[bold]Requirements:[/bold]")
            reqs = ext_info["requires"]
            if reqs.get("speckit_version"):
                console.print(f"  • Spec Kit: {reqs['speckit_version']}")
            if reqs.get("tools"):
                for tool in reqs["tools"]:
                    tool_name = tool["name"]
                    tool_version = tool.get("version", "any")
                    required = " (required)" if tool.get("required") else " (optional)"
                    console.print(f"  • {tool_name}: {tool_version}{required}")
            console.print()

        # Provides
        if ext_info.get("provides"):
            console.print("[bold]Provides:[/bold]")
            provides = ext_info["provides"]
            if provides.get("commands"):
                console.print(f"  • Commands: {provides['commands']}")
            if provides.get("hooks"):
                console.print(f"  • Hooks: {provides['hooks']}")
            console.print()

        # Tags
        if ext_info.get("tags"):
            tags_str = ", ".join(ext_info["tags"])
            console.print(f"[bold]Tags:[/bold] {tags_str}")
            console.print()

        # Statistics
        stats = []
        if ext_info.get("downloads") is not None:
            stats.append(f"Downloads: {ext_info['downloads']:,}")
        if ext_info.get("stars") is not None:
            stats.append(f"Stars: {ext_info['stars']}")
        if stats:
            console.print(f"[bold]Statistics:[/bold] {' | '.join(stats)}")
            console.print()

        # Links
        console.print("[bold]Links:[/bold]")
        if ext_info.get("repository"):
            console.print(f"  • Repository: {ext_info['repository']}")
        if ext_info.get("homepage"):
            console.print(f"  • Homepage: {ext_info['homepage']}")
        if ext_info.get("documentation"):
            console.print(f"  • Documentation: {ext_info['documentation']}")
        if ext_info.get("changelog"):
            console.print(f"  • Changelog: {ext_info['changelog']}")
        console.print()

        # Installation status and command
        is_installed = manager.registry.is_installed(ext_info["id"])
        if is_installed:
            console.print("[green]✓ Installed[/green]")
            console.print(f"\nTo remove: specify extension remove {ext_info['id']}")
        else:
            console.print("[yellow]Not installed[/yellow]")
            console.print(
                f"\n[cyan]Install:[/cyan] specify extension add {ext_info['id']}"
            )

    except ExtensionError as e:
        console.print(f"\n[red]Error:[/red] {e}")
        raise typer.Exit(1)


@extension_app.command("update")
def extension_update(
    extension: str = typer.Argument(None, help="Extension ID to update (or all)"),
):
    """Update extension(s) to latest version."""
    from .extensions import ExtensionManager, ExtensionCatalog, ExtensionError
    from packaging import version as pkg_version

    project_root = Path.cwd()

    # Check if we're in a spec-kit project
    specify_dir = project_root / ".specify"
    if not specify_dir.exists():
        console.print(
            "[red]Error:[/red] Not a spec-kit project (no .specify/ directory)"
        )
        console.print("Run this command from a spec-kit project root")
        raise typer.Exit(1)

    manager = ExtensionManager(project_root)
    catalog = ExtensionCatalog(project_root)

    try:
        # Get list of extensions to update
        if extension:
            # Update specific extension
            if not manager.registry.is_installed(extension):
                console.print(
                    f"[red]Error:[/red] Extension '{extension}' is not installed"
                )
                raise typer.Exit(1)
            extensions_to_update = [extension]
        else:
            # Update all extensions
            installed = manager.list_installed()
            extensions_to_update = [ext["id"] for ext in installed]

        if not extensions_to_update:
            console.print("[yellow]No extensions installed[/yellow]")
            raise typer.Exit(0)

        console.print("🔄 Checking for updates...\n")

        updates_available = []

        for ext_id in extensions_to_update:
            # Get installed version
            metadata = manager.registry.get(ext_id)
            if metadata is None:
                console.print(f"⚠  {ext_id}: Not found in registry (skipping)")
                continue
            installed_version = pkg_version.Version(metadata["version"])

            # Get catalog info
            ext_info = catalog.get_extension_info(ext_id)
            if not ext_info:
                console.print(f"⚠  {ext_id}: Not found in catalog (skipping)")
                continue

            catalog_version = pkg_version.Version(ext_info["version"])

            if catalog_version > installed_version:
                updates_available.append(
                    {
                        "id": ext_id,
                        "installed": str(installed_version),
                        "available": str(catalog_version),
                        "download_url": ext_info.get("download_url"),
                    }
                )
            else:
                console.print(f"✓ {ext_id}: Up to date (v{installed_version})")

        if not updates_available:
            console.print("\n[green]All extensions are up to date![/green]")
            raise typer.Exit(0)

        # Show available updates
        console.print("\n[bold]Updates available:[/bold]\n")
        for update in updates_available:
            console.print(
                f"  • {update['id']}: {update['installed']} → {update['available']}"
            )

        console.print()
        confirm = typer.confirm("Update these extensions?")
        if not confirm:
            console.print("Cancelled")
            raise typer.Exit(0)

        # Perform updates
        console.print()
        for update in updates_available:
            ext_id = update["id"]
            console.print(f"📦 Updating {ext_id}...")

            # TODO: Implement download and reinstall from URL
            # For now, just show  message
            console.print(
                "[yellow]Note:[/yellow] Automatic update not yet implemented. "
                "Please update manually:"
            )
            console.print(f"  specify extension remove {ext_id} --keep-config")
            console.print(f"  specify extension add {ext_id}")

        console.print(
            "\n[cyan]Tip:[/cyan] Automatic updates will be available in a future version"
        )

    except ExtensionError as e:
        console.print(f"\n[red]Error:[/red] {e}")
        raise typer.Exit(1)


@extension_app.command("enable")
def extension_enable(
    extension: str = typer.Argument(help="Extension ID to enable"),
):
    """Enable a disabled extension."""
    from .extensions import ExtensionManager, HookExecutor

    project_root = Path.cwd()

    # Check if we're in a spec-kit project
    specify_dir = project_root / ".specify"
    if not specify_dir.exists():
        console.print(
            "[red]Error:[/red] Not a spec-kit project (no .specify/ directory)"
        )
        console.print("Run this command from a spec-kit project root")
        raise typer.Exit(1)

    manager = ExtensionManager(project_root)
    hook_executor = HookExecutor(project_root)

    if not manager.registry.is_installed(extension):
        console.print(f"[red]Error:[/red] Extension '{extension}' is not installed")
        raise typer.Exit(1)

    # Update registry
    metadata = manager.registry.get(extension)
    if metadata is None:
        console.print(f"[red]Error:[/red] Extension '{extension}' metadata not found")
        raise typer.Exit(1)
    if metadata.get("enabled", True):
        console.print(f"[yellow]Extension '{extension}' is already enabled[/yellow]")
        raise typer.Exit(0)

    metadata["enabled"] = True
    manager.registry.add(extension, metadata)

    # Enable hooks in extensions.yml
    config = hook_executor.get_project_config()
    if "hooks" in config:
        for hook_name in config["hooks"]:
            for hook in config["hooks"][hook_name]:
                if hook.get("extension") == extension:
                    hook["enabled"] = True
        hook_executor.save_project_config(config)

    console.print(f"[green]✓[/green] Extension '{extension}' enabled")


@extension_app.command("disable")
def extension_disable(
    extension: str = typer.Argument(help="Extension ID to disable"),
):
    """Disable an extension without removing it."""
    from .extensions import ExtensionManager, HookExecutor

    project_root = Path.cwd()

    # Check if we're in a spec-kit project
    specify_dir = project_root / ".specify"
    if not specify_dir.exists():
        console.print(
            "[red]Error:[/red] Not a spec-kit project (no .specify/ directory)"
        )
        console.print("Run this command from a spec-kit project root")
        raise typer.Exit(1)

    manager = ExtensionManager(project_root)
    hook_executor = HookExecutor(project_root)

    if not manager.registry.is_installed(extension):
        console.print(f"[red]Error:[/red] Extension '{extension}' is not installed")
        raise typer.Exit(1)

    # Update registry
    metadata = manager.registry.get(extension)
    if metadata is None:
        console.print(f"[red]Error:[/red] Extension '{extension}' metadata not found")
        raise typer.Exit(1)
    if not metadata.get("enabled", True):
        console.print(f"[yellow]Extension '{extension}' is already disabled[/yellow]")
        raise typer.Exit(0)

    metadata["enabled"] = False
    manager.registry.add(extension, metadata)

    # Disable hooks in extensions.yml
    config = hook_executor.get_project_config()
    if "hooks" in config:
        for hook_name in config["hooks"]:
            for hook in config["hooks"][hook_name]:
                if hook.get("extension") == extension:
                    hook["enabled"] = False
        hook_executor.save_project_config(config)

    console.print(f"[green]✓[/green] Extension '{extension}' disabled")
    console.print("\nCommands will no longer be available. Hooks will not execute.")
    console.print(f"To re-enable: specify extension enable {extension}")


def main():
    app()


if __name__ == "__main__":
    main()
