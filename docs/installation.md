# Installation Guide

> Agentic SDLC Spec Kit implements the [Agentic SDLC 12 Factors](https://tikalk.github.io/agentic-sdlc-12-factors/) methodology for structured AI-assisted development.

## Prerequisites

- **Linux/macOS** (or Windows; PowerShell scripts now supported without WSL)
- AI coding agent: [Claude Code](https://www.anthropic.com/claude-code), [GitHub Copilot](https://code.visualstudio.com/), [Codebuddy CLI](https://www.codebuddy.ai/cli) or [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [uv](https://docs.astral.sh/uv/) for package management
- [Python 3.11+](https://www.python.org/downloads/)
- [Git](https://git-scm.com/downloads)

## Installation

### Initialize a New Project

The easiest way to get started is to initialize a new project:

```bash
uvx --from git+https://github.com/github/agentic-sdlc-agentic-sdlc-spec-kit.git specify init <PROJECT_NAME>
```

Or initialize in the current directory:

```bash
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init .
# or use the --here flag
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init --here
```

### Specify AI Agent

You can proactively specify your AI agent during initialization:

```bash
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --ai claude
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --ai gemini
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --ai copilot
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --ai codebuddy
```

### Specify Script Type (Shell vs PowerShell)

All automation scripts now have both Bash (`.sh`) and PowerShell (`.ps1`) variants.

Auto behavior:

- Windows default: `ps`
- Other OS default: `sh`
- Interactive mode: you'll be prompted unless you pass `--script`

Force a specific script type:

```bash
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --script sh
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --script ps
```

### Ignore Agent Tools Check

If you prefer to get the templates without checking for the right tools:

```bash
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --ai claude --ignore-agent-tools
```

### Configure Team AI Directives

Connect to shared team knowledge and standards:

```bash
# Use local team-ai-directives directory
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --team-ai-directives ~/workspace/team-ai-directives

# Clone from remote repository
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --team-ai-directives https://github.com/your-org/team-ai-directives.git
```

### Enable Issue Tracker Integration

Configure MCP servers for project management integration:

```bash
# GitHub Issues
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --issue-tracker github

# Jira, Linear, or GitLab
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --issue-tracker jira
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --issue-tracker linear
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --issue-tracker gitlab
```

### Enable Async Agent Support

Configure autonomous coding agents for delegated task execution:

```bash
# Jules, Async Copilot, or Async Codex
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --async-agent jules
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --async-agent async-copilot
uvx --from git+https://github.com/github/agentic-sdlc-spec-kit.git specify init <project_name> --async-agent async-codex
```

## Verification

After initialization, you should see the following commands available in your AI agent:

- `/speckit.constitution` - Establish project principles and assemble constitution
- `/speckit.specify` - Create specifications
- `/speckit.plan` - Generate implementation plans
- `/speckit.tasks` - Break down into actionable tasks
- `/speckit.implement` - Execute implementation with SYNC/ASYNC dual execution loops
- `/speckit.levelup` - Capture learnings and contribute to team knowledge
- `/speckit.analyze` - Cross-artifact consistency and alignment reports
- `/speckit.checklist` - Generate quality checklists for requirements validation
- `/speckit.clarify` - Structured questions to de-risk ambiguous areas

The `.specify/scripts` directory will contain both `.sh` and `.ps1` scripts for automation, and `.mcp.json` will be configured for issue tracker and async agent integration if specified.

## Troubleshooting

### Git Credential Manager on Linux

If you're having issues with Git authentication on Linux, you can install Git Credential Manager:

```bash
#!/usr/bin/env bash
set -e
echo "Downloading Git Credential Manager v2.6.1..."
wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.1/gcm-linux_amd64.2.6.1.deb
echo "Installing Git Credential Manager..."
sudo dpkg -i gcm-linux_amd64.2.6.1.deb
echo "Configuring Git to use GCM..."
git config --global credential.helper manager
echo "Cleaning up..."
rm gcm-linux_amd64.2.6.1.deb
```
