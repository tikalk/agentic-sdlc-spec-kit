# Installation Guide

> Agentic SDLC Spec Kit implements the [Agentic SDLC 12 Factors](https://tikalk.github.io/agentic-sdlc-12-factors/) methodology for structured AI-assisted development.

## Prerequisites

- **Linux/macOS** (or Windows; PowerShell scripts now supported without WSL)
- AI coding agent: [Claude Code](https://www.anthropic.com/claude-code), [GitHub Copilot](https://code.visualstudio.com/), [Codebuddy CLI](https://www.codebuddy.ai/cli) or [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [uv](https://docs.astral.sh/uv/) for package management
- [Python 3.11+](https://www.python.org/downloads/)
- [Git](https://git-scm.com/downloads)

## Installation

> **Important:** The only official, maintained packages for Spec Kit come from the [github/spec-kit](https://github.com/github/spec-kit) GitHub repository. Any packages with the same name available on PyPI (e.g. `specify-cli` on pypi.org) are **not** affiliated with this project and are not maintained by the Spec Kit maintainers. For normal installs, use the GitHub-based commands shown below. For offline or air-gapped environments, locally built wheels created from this repository are also valid.

### Initialize a New Project

The easiest way to get started is to initialize a new project. Pin a specific release tag for stability (check [Releases](https://github.com/github/spec-kit/releases) for the latest):

```bash
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <PROJECT_NAME>
```

Or initialize in the current directory:

```bash
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init .
# or use the --here flag
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init --here
```

### Specify AI Agent

You can proactively specify your AI agent during initialization:

```bash
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <project_name> --ai claude
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <project_name> --ai gemini
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <project_name> --ai copilot
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <project_name> --ai codebuddy
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <project_name> --ai pi
```

### Specify Script Type (Shell vs PowerShell)

All automation scripts now have both Bash (`.sh`) and PowerShell (`.ps1`) variants.

Auto behavior:

- Windows default: `ps`
- Other OS default: `sh`
- Interactive mode: you'll be prompted unless you pass `--script`

Force a specific script type:

```bash
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <project_name> --script sh
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <project_name> --script ps
```

### Ignore Agent Tools Check

If you prefer to get the templates without checking for the right tools:

```bash
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <project_name> --ai claude --ignore-agent-tools
```

### Configure Team AI Directives

Connect to shared team knowledge and standards:

```bash
# Use local team-ai-directives directory
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <project_name> --team-ai-directives ~/workspace/team-ai-directives

# Install from GitHub archive (ZIP download)
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <project_name> --team-ai-directives https://github.com/your-org/team-ai-directives/archive/refs/heads/main.zip

# Or from a specific release tag
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <project_name> --team-ai-directives https://github.com/your-org/team-ai-directives/archive/refs/tags/v1.0.0.zip
```

## Verification

After installation, run the following command to confirm the correct version is installed:

```bash
specify version
```

This helps verify you are running the official Spec Kit build from GitHub, not an unrelated package with the same name.

After initialization, you should see the following commands available in your AI agent:

- `/spec.constitution` - Establish project principles and assemble constitution
- `/spec.specify` - Create specifications
- `/spec.plan` - Generate implementation plans
- `/spec.tasks` - Break down into actionable tasks
- `/spec.implement` - Execute implementation with SYNC/ASYNC dual execution loops
- `/levelup.specify` - Extract patterns from current feature and create CDRs for team knowledge
- `/levelup.init` - Discover patterns from entire codebase (brownfield)
- `/levelup.clarify` - Resolve ambiguities in discovered CDRs
- `/levelup.implement` - Compile CDRs into PR to team-ai-directives
- `/spec.analyze` - Cross-artifact consistency and alignment reports
- `/spec.checklist` - Generate quality checklists for requirements validation
- `/spec.clarify` - Structured questions to de-risk ambiguous areas

The `.specify/scripts` directory will contain both `.sh` and `.ps1` scripts for automation.

## Troubleshooting

### Enterprise / Air-Gapped Installation

If your environment blocks access to PyPI (you see 403 errors when running `uv tool install` or `pip install`), you can create a portable wheel bundle on a connected machine and transfer it to the air-gapped target.

**Step 1: Build the wheel on a connected machine (same OS and Python version as the target)**

```bash
# Clone the repository
git clone https://github.com/github/spec-kit.git
cd spec-kit

# Build the wheel
pip install build
python -m build --wheel --outdir dist/

# Download the wheel and all its runtime dependencies
pip download -d dist/ dist/specify_cli-*.whl
```

> **Important:** `pip download` resolves platform-specific wheels (e.g., PyYAML includes native extensions). You must run this step on a machine with the **same OS and Python version** as the air-gapped target. If you need to support multiple platforms, repeat this step on each target OS (Linux, macOS, Windows) and Python version.

**Step 2: Transfer the `dist/` directory to the air-gapped machine**

Copy the entire `dist/` directory (which contains the `specify-cli` wheel and all dependency wheels) to the target machine via USB, network share, or other approved transfer method.

**Step 3: Install on the air-gapped machine**

```bash
pip install --no-index --find-links=./dist specify-cli
```

**Step 4: Initialize a project (no network required)**

```bash
# Initialize a project — no GitHub access needed
specify init my-project --ai claude --offline
```

The `--offline` flag tells the CLI to use the templates, commands, and scripts bundled inside the wheel instead of downloading from GitHub.

> **Deprecation notice:** Starting with v0.6.0, `specify init` will use bundled assets by default and the `--offline` flag will be removed. The GitHub download path will be retired because bundled assets eliminate the need for network access, avoid proxy/firewall issues, and guarantee that templates always match the installed CLI version. No action will be needed — `specify init` will simply work without network access out of the box.

> **Note:** Python 3.11+ is required.

> **Windows note:** Offline scaffolding requires PowerShell 7+ (`pwsh`), not Windows PowerShell 5.x (`powershell.exe`). Install from https://aka.ms/powershell.

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
