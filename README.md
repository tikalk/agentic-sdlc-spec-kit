<div align="center">
    <img src="./media/timi_small.png" alt="Agentic SDLC Spec Kit Logo" width="200" height="200"/>
    <h1>🐙 Agentic SDLC Spec Kit</h1>
    <h3><em>Build high-quality software faster.</em></h3>
</div>

<p align="center">
    <strong>An open source toolkit that allows you to focus on product scenarios and predictable outcomes instead of vibe coding every piece from scratch.</strong>
</p>

## 🎯 Project Vision

This fork combines the [Agentic SDLC 12 Factors](https://tikalk.github.io/agentic-sdlc-12-factors/) methodology with Spec-Driven Development to create a comprehensive framework for AI-assisted software development. The 12 Factors provide the strategic foundation and operational principles, while Spec-Driven Development delivers the practical implementation workflow.

### Why This Combination?

**Agentic SDLC 12 Factors** establish the philosophical and strategic principles for building software with AI coding agents, covering aspects like strategic mindset, context scaffolding, dual execution loops, and team capability.

**Spec-Driven Development** provides the concrete, actionable process for implementing these principles through structured specification, planning, task breakdown, and iterative implementation phases.

Together, they form a complete methodology that transforms how organizations approach AI-assisted development, moving from ad-hoc AI usage to systematic, high-quality software production.

### Why This Fork?

The original [github/spec-kit](https://github.com/github/spec-kit) repository focused on the core Spec-Driven Development process. This fork extends that foundation by:

- **Integrating the 12 Factors methodology** as the strategic layer above the tactical Spec-Driven process
- **Adding enterprise-grade features** like team AI directives integration
- **Enhancing tooling** with dual execution loop support (SYNC/ASYNC task classification)
- **Implementing AI session context management** through the levelup command that creates reusable knowledge packets and analyzes contributions to team directives
- **Providing team templates** and best practices for scaling AI-assisted development across teams

This fork represents the evolution from a development process to a complete organizational methodology for AI-native software development, with sophisticated knowledge management and cross-project learning capabilities.

<p align="center">
    <a href="https://github.com/tikalk/agentic-sdlc-spec-kit/actions/workflows/release.yml"><img src="https://github.com/tikalk/agentic-sdlc-spec-kit/actions/workflows/release.yml/badge.svg" alt="Release"/></a>
    <a href="https://github.com/tikalk/agentic-sdlc-spec-kit/stargazers"><img src="https://img.shields.io/github/stars/tikalk/agentic-sdlc-spec-kit?style=social" alt="GitHub stars"/></a>
    <a href="https://github.com/tikalk/agentic-sdlc-spec-kit/blob/main/LICENSE"><img src="https://img.shields.io/github/license/tikalk/agentic-sdlc-spec-kit" alt="License"/></a>
    <a href="https://github.github.io/spec-kit/"><img src="https://img.shields.io/badge/docs-GitHub_Pages-blue" alt="Documentation"/></a>
</p>

---

## Table of Contents

- [🎯 Project Vision](#-project-vision)
- [🤔 What is Spec-Driven Development?](#-what-is-spec-driven-development)
- [⚡ Get Started](#-get-started)
- [🚀 Quick Start Guide](./QUICKSTART.md) — Complete team onboarding with team-ai-directives
- [🛠️ Installation Guide (AI Assistants)](./INSTALL.md) — Guide for AI agents helping team members
- [📽️ Video Overview](#️-video-overview)
- [🧩 Community Extensions](#-community-extensions)
- [🎨 Community Presets](#-community-presets)
- [🚶 Community Walkthroughs](#-community-walkthroughs)
- [🎯 Core Features](#-core-features)
- [📦 Bundled Extensions](#-bundled-extensions)
- [🔧 Team AI Directives Integration](#-team-ai-directives-integration)
- [🛠️ Community Friends](#️-community-friends)
- [🤖 Supported AI Agents](#-supported-ai-agents)
- [🔧 Specify CLI Reference](#-specify-cli-reference)
- [🧩 Making Spec Kit Your Own: Extensions & Presets](#-making-spec-kit-your-own-extensions--presets)
- [📚 Core Philosophy](#-core-philosophy)
- [🌟 Development Phases](#-development-phases)
- [🎯 Experimental Goals](#-experimental-goals)
- [🔧 Prerequisites](#-prerequisites)
- [📖 Learn More](#-learn-more)
- [📋 Detailed Process](#-detailed-process)
- [🔍 Troubleshooting](#-troubleshooting)
- [👥 Maintainers](#-maintainers)
- [💬 Support](#-support)
- [🙏 Acknowledgements](#-acknowledgements)
- [📄 License](#-license)

## 🤔 What is Spec-Driven Development?

Spec-Driven Development **flips the script** on traditional software development. For decades, code has been king — specifications were just scaffolding we built and discarded once the "real work" of coding began. Spec-Driven Development changes this: **specifications become executable**, directly generating working implementations rather than just guiding them.

## ⚡ Get Started

> **New Team Members:** For a comprehensive onboarding guide including team-ai-directives setup, see [QUICKSTART.md](./QUICKSTART.md). AI assistants helping with setup should refer to [INSTALL.md](./INSTALL.md).

### 1. Install Specify CLI

Choose your preferred installation method:

> **Important:** The only official, maintained packages for Spec Kit are published from this GitHub repository. Any packages with the same name on PyPI are **not** affiliated with this project and are not maintained by the Spec Kit maintainers. Always install directly from GitHub as shown below.

#### Option 1: Persistent Installation (Recommended)

Install once and use everywhere. Pin a specific release tag for stability (check [Releases](https://github.com/tikalk/agentic-sdlc-spec-kit/releases) for the latest):

> [!NOTE]
> The `uv tool install` commands below require **[uv](https://docs.astral.sh/uv/)** — a fast Python package manager. If you see `command not found: uv`, [install uv first](./docs/install/uv.md). The `pipx` alternative does not require uv.

```bash
# Install a specific stable release (recommended — replace agentic-sdlc-vX.Y.Z with the latest tag)
uv tool install agentic-sdlc-specify-cli --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git@agentic-sdlc-vX.Y.Z

# Or install latest from main (may include unreleased changes)
uv tool install agentic-sdlc-specify-cli --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git
```

Then verify the correct version is installed:

```bash
specify version
```

#### Option 2: One-Time Installation

Use `uvx` to run specify without installing it permanently. This is great for trying it out:

```bash
# Run once without installing
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init my-project
```

For detailed installation options, verification, and troubleshooting, see the [Installation Guide](./docs/installation.md).

### 2. Initialize a project

```bash
specify init my-project --integration copilot
cd my-project
```

To check for updates or upgrade the installed CLI, use the self-management commands. See the [Upgrade Guide](./docs/upgrade.md) for detailed scenarios and customization options.

```bash
# Check whether a newer release is available (read-only — does not modify anything)
specify self check

# Preview what would run, without actually upgrading
specify self upgrade --dry-run

# Upgrade in place to the latest stable release (auto-detects uv tool vs pipx install)
specify self upgrade

# Or pin a specific release tag (replace X.Y.Z with your desired version)
specify self upgrade --tag agentic-sdlc-vX.Y.Z+adlcN
```

Bare `specify self upgrade` executes immediately, matching the no-prompt behavior of commands like `pip install -U` and `npm update`. For `uv tool` installs, it runs `uv tool install specify-cli --force --from <git ref>` under the hood so pinned release tags work, including dev, alpha/beta/rc, or build metadata suffixes. `uvx` (ephemeral) runs and source checkouts are detected and produce path-specific guidance instead of running an installer. Set `SPECIFY_UPGRADE_TIMEOUT_SECS` to cap how long the installer subprocess may run (default: no timeout — interrupt with `Ctrl+C` if needed).

### 3. Establish project principles

Launch your coding agent in the project directory. Most agents expose spec-kit as `/spec.*` slash commands; Codex CLI in skills mode uses `$speckit-*` instead.

Use the **`/spec.constitution`** command to create your project's governing principles and development guidelines that will guide all subsequent development.

```bash
/spec.constitution Create principles focused on code quality, testing standards, user experience consistency, and performance requirements
```

### 4. Explore approaches

For complex features, use **`/spec.brainstorm`** to explore the problem space, identify approaches, surface tradeoffs, and document architectural context before creating the specification.

```bash
/spec.brainstorm I need to add real-time collaboration to the photo albums app so multiple users can edit the same album simultaneously
```

The output is saved to `.specify/drafts/brainstorm-context.md` and automatically consumed by `/spec.specify` to seed the specification.

### 5. Create the spec

Use the **`/spec.specify`** command to describe what you want to build. Focus on the **what** and **why**, not the tech stack.

```bash
/spec.specify Build an application that can help me organize my photos in separate photo albums. Albums are grouped by date and can be re-organized by dragging and dropping on the main page. Albums are never in other nested albums. Within each album, photos are previewed in a tile-like interface.
```

### 6. Create a technical implementation plan

Use the **`/spec.plan`** command to provide your tech stack and architecture choices.

```bash
/spec.plan The application uses Vite with minimal number of libraries. Use vanilla HTML, CSS, and JavaScript as much as possible. Images are not uploaded anywhere and metadata is stored in a local SQLite database.
```

### 7. Break down into tasks

Use **`/spec.tasks`** to create an actionable task list from your implementation plan.

```bash
/spec.tasks
```

### 8. Execute implementation

Use **`/spec.implement`** to execute all tasks and build your feature according to the plan.

```bash
/spec.implement
```

### 9. Verify completeness

After implementation, use **`/spec.verify`** to run the test gate, analyze diffs, and assess feature completeness against the specification's 4 pillars (Spec Compliance, Code Quality, Test Adequacy, Risk & Evidence).

```bash
/spec.verify
```

For detailed step-by-step instructions, see our [comprehensive guide](./spec-driven.md).

## 📽️ Video Overview

Want to see Spec Kit in action? Watch our [video overview](https://www.youtube.com/watch?v=a9eR1xsfvHg&pp=0gcJCckJAYcqIYzv)!

[![Spec Kit video header](/media/spec-kit-video-header.jpg)](https://www.youtube.com/watch?v=a9eR1xsfvHg&pp=0gcJCckJAYcqIYzv)

## 🧩 Community Extensions

Community-contributed extensions add new commands, hooks, and capabilities to Spec Kit. See the full list on the [Community Extensions](https://github.github.io/spec-kit/community/extensions.html) page.

> [!NOTE]
> Community extensions are independently created and maintained by their respective authors. Maintainers only verify that catalog entries are complete and correctly formatted — they do **not review, audit, endorse, or support the extension code itself**. Review extension source code before installation and use at your own discretion.

To submit your own extension, see the [Extension Publishing Guide](extensions/EXTENSION-PUBLISHING-GUIDE.md).

## 🎨 Community Presets

Community-contributed presets customize how Spec Kit behaves — overriding templates, commands, and terminology without changing any tooling. See the full list on the [Community Presets](https://github.github.io/spec-kit/community/presets.html) page.

> [!NOTE]
> Community presets are third-party contributions and are not maintained by the Spec Kit team. Review them carefully before use, and see the docs page above for the full disclaimer.

To submit your own preset, see the [Presets Publishing Guide](presets/PUBLISHING.md).

## 🚶 Community Walkthroughs

See Spec-Driven Development in action across different scenarios with community-contributed walkthroughs; find the full list on the [Community Walkthroughs](https://github.github.io/spec-kit/community/walkthroughs.html) page.

## 🎯 Core Features

This fork provides additional features beyond the upstream Spec Kit:

- **Team AI Directives Integration** — Synchronize team-level AI instructions and context across projects
- **Feature-level Git Worktree Isolation** — Run each feature in its own worktree with isolated task branches
- **DAG-aware Task Orchestration** — Auto-generate `tasks_dag.json` for wave-based parallel/sequential task execution
- **Task-branch Workflow** — Create, merge, and list task branches via `git.task`, `git.task-merge`, and `git.task-list`
- **Dual Execution Loop** — Classify tasks as SYNC (immediate) or ASYNC (deferred) for better workflow management
- **Levelup Command** — Analyze and improve session context with reusable knowledge packets
- **Enhanced Extensions** — Built-in extensions for product thinking, architecture analysis, and TDD workflows

## 📦 Bundled Extensions

This fork includes pre-installed extensions:

| Extension | Purpose |
|-----------|---------|
| architect | Architecture impact analysis and decision guidance |
| evals | Evaluation criteria and test generation |
| levelup | Session context improvement and knowledge management |
| product | Product thinking and user story refinement |
| tdd | Test-driven development workflows |
| git | Git workflow automation with branch or worktree isolation |

## 📦 Bundled Presets

This fork includes pre-installed presets (auto-installed during `specify init`):

| Preset | Commands | Purpose |
|--------|----------|---------|
| agentic-sdlc | `/spec.*` | Full Agentic SDLC lifecycle — specify, plan, tasks, implement, verify |
| agentic-change | `/change.specify`, `/change.implement`, `/change.verify`, `/change.levelup` | Lightweight change proposal workflow with spec + tasks artifacts |
| agentic-quick | `/quick.implement`, `/quick.levelup` | Session-based ad-hoc task execution with CDR levelup |

> **Migration note:** The `quick` extension has been replaced by the `agentic-change` and `agentic-quick` bundled presets. If you have the old `quick` extension installed, run `specify extension remove quick && specify init` to migrate.

## 🔧 Team AI Directives Integration

This fork supports team-ai-directives — a foundation for version-controlled AI agent behavior. Install during project initialization:

```bash
# Install from GitHub archive (ZIP download)
specify init <project> --team-ai-directives https://github.com/your-org/team-ai-directives/archive/refs/heads/main.zip

# Or from a specific release tag
specify init <project> --team-ai-directives https://github.com/your-org/team-ai-directives/archive/refs/tags/v1.0.0.zip

# Or use a local directory
specify init <project> --team-ai-directives ~/workspace/team-ai-directives
```

Accepted sources are a local directory, a GitHub/GitLab archive URL, or a direct `.zip`/`.tar.gz` URL. Plain `.git` clone URLs are not supported.

**Private Repositories**: If your team-ai-directives repository is private, configure authentication in `~/.specify/auth.json`:

```json
{
  "providers": [
    {
      "hosts": ["github.com", "api.github.com", "raw.githubusercontent.com"],
      "provider": "github",
      "auth": "bearer",
      "token_env": "GITHUB_TOKEN"
    },
    {
      "hosts": ["gitlab.com"],
      "provider": "gitlab",
      "auth": "bearer",
      "token_env": "GITLAB_TOKEN"
    }
  ]
}
```

Then set the appropriate environment variable:

```bash
export GITHUB_TOKEN=ghp_your_token_here
# or
export GITLAB_TOKEN=glpat_your_token_here
```

The bundled `team-ai-directives` extension is installed to `.specify/extensions/team-ai-directives/`. The actual team knowledge-base path you provided is stored in `.specify/init-options.json` under `team_ai_directives` (for local directories the content stays at the original path; for archive URLs it is extracted into the CLI cache). All directives are available to AI agents via the extension system. Use the `levelup` extension to contribute back to team-ai-directives.

See [agentic-sdlc-team-ai-directives](https://github.com/tikalk/agentic-sdlc-team-ai-directives) for the full starter kit.

## 🛠️ Community Friends

Community projects that extend, visualize, or build on Spec Kit. See the full list on the [Community Friends](https://github.github.io/spec-kit/community/friends.html) page.

## 🤖 Supported AI Agents

This fork supports the following AI coding agents:

| Agent | CLI | Skills | Setup |
|-------|-----|--------|-------|
| Claude Code | `claude` | ✓ | `--ai claude --ai-skills` |
| GitHub Copilot | — | IDE | `--ai copilot` |
| Cursor | `cursor-agent` | IDE | `--ai cursor-agent` |
| Gemini CLI | `gemini` | ✓ | `--ai gemini --ai-skills` |
| opencode | `opencode` | ✓ | `--ai opencode` |
| Qwen | `qwen` | ✓ | `--ai qwen --ai-skills` |
| Codex | `codex` | ✓ | `--ai codex --ai-skills` |
| Windsurf | — | IDE | `--ai windsurf` |
| Junie | `junie` | ✓ | `--ai junie --ai-skills` |
| And more... |

## Team Skills

When you initialize with `--team-ai-directives`, required skills from your team's knowledge base are automatically installed to your agent's skills directory. To browse and install additional team skills (recommended, internal), use the `/team.skills` agent command:

```
/team.skills
```

This reads your team's `.skills.json` manifest and lets you pick which skills to install.

## 🤖 Supported AI Coding Agent Integrations

Spec Kit works with 30+ AI coding agents — both CLI tools and IDE-based assistants. See the full list with notes and usage details in the [Supported AI Coding Agent Integrations](https://github.github.io/spec-kit/reference/integrations.html) guide.

Run `specify integration list` to see all available integrations in your installed version.

## Available Slash Commands

After running `specify init`, your AI coding agent will have access to these slash commands for structured development. For integrations that support skills mode, passing `--integration <agent> --integration-options="--skills"` installs agent skills instead of slash-command prompt files.

### Core Commands

Essential commands for the Spec-Driven Development workflow:

| Command                  | Agent Skill            | Description                                                                        |
| ------------------------ | ---------------------- | ---------------------------------------------------------------------------------- |
| `/spec.constitution`  | `speckit-constitution` | Create or update project governing principles and development guidelines           |
| `/spec.brainstorm`    | `speckit-brainstorm`   | Structured exploration of approaches, tradeoffs, and architecture before specifying|
| `/spec.specify`       | `speckit-specify`      | Define what you want to build (requirements and user stories)                      |
| `/spec.plan`          | `speckit-plan`         | Create technical implementation plans with your chosen tech stack                  |
| `/spec.tasks`         | `speckit-tasks`        | Generate actionable task lists for implementation                                  |
| `/spec.taskstoissues` | `speckit-taskstoissues`| Convert generated task lists into GitHub issues for tracking and execution         |
| `/spec.implement`     | `speckit-implement`    | Execute all tasks to build the feature according to the plan                       |
| `/spec.verify`        | `speckit-verify`       | Verify feature completeness — test gate, diff analysis, and 4-pillar assessment    |

### Optional Commands

Additional commands for enhanced quality and validation:

| Command              | Agent Skill            | Description                                                                                                                          |
| -------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `/spec.clarify`   | `speckit-clarify`      | Clarify underspecified areas (recommended before `/spec.plan`; formerly `/quizme`)                                                |
| `/spec.analyze`   | `speckit-analyze`      | Cross-artifact consistency & coverage analysis (run after `/spec.tasks`, before `/spec.implement`)                             |
| `/spec.checklist` | `speckit-checklist`    | Generate custom quality checklists that validate requirements completeness, clarity, and consistency (like "unit tests for English") |
| `/spec.trace`     | `speckit-trace`        | Generate a feature-local execution trace at `specs/{branch}/trace.md` after implementation                                        |

### Change Workflow Commands

Lightweight alternative for non-feature changes affecting existing code:

| Command | Agent Skill | Description |
|---------|-------------|-------------|
| `/change.specify` | `adlc-change-specify` | Create a change proposal — mission brief → `changes/NNN-name/spec.md` (+ optional plan.md + tasks.md) |
| `/change.implement` | `adlc-change-implement` | Execute tasks from a change proposal with per-task hook dispatch |
| `/change.verify` | `adlc-change-verify` | Verify change completeness against acceptance criteria |
| `/change.levelup` | `adlc-change-levelup` | Contribute lessons from a completed change to team-ai-directives |

### Quick Workflow Commands

Session-based ad-hoc task execution (no file artifacts):

| Command | Agent Skill | Description |
|---------|-------------|-------------|
| `/quick.implement` | `adlc-quick-implement` | Session-based ad-hoc implementation with per-task hooks |
| `/quick.levelup` | `adlc-quick-levelup` | Quick-contribute a directive to team-ai-directives (CDR-based) |

## 🔧 Specify CLI Reference

For full command details, options, and examples, see the [CLI Reference](https://github.github.io/spec-kit/reference/overview.html).

## 🧩 Making Spec Kit Your Own: Extensions & Presets

Spec Kit can be tailored to your needs through two complementary systems — **extensions** and **presets** — plus project-local overrides for one-off adjustments:

| Priority | Component Type                                    | Location                         |
| -------: | ------------------------------------------------- | -------------------------------- |
|      ⬆ 1 | Project-Local Overrides                           | `.specify/templates/overrides/`  |
|        2 | Presets — Customize core & extensions             | `.specify/presets/templates/`    |
|        3 | Extensions — Add new capabilities                 | `.specify/extensions/templates/` |
|      ⬇ 4 | Spec Kit Core — Built-in SDD commands & templates | `.specify/templates/`            |

- **Templates** are resolved at **runtime** — Spec Kit walks the stack top-down and uses the first match.
- Project-local overrides (`.specify/templates/overrides/`) let you make one-off adjustments for a single project without creating a full preset.
- **Extension/preset commands** are applied at **install time** — when you run `specify extension add` or `specify preset add`, command files are written into agent directories (e.g., `.claude/commands/`).
- If multiple presets or extensions provide the same command, the highest-priority version wins. On removal, the next-highest-priority version is restored automatically.
- If no overrides or customizations exist, Spec Kit uses its core defaults.

### Extensions — Add New Capabilities

Use **extensions** when you need functionality that goes beyond Spec Kit's core. Extensions introduce new commands and templates — for example, adding domain-specific workflows that are not covered by the built-in SDD commands, integrating with external tools, or adding entirely new development phases. They expand *what Spec Kit can do*.

```bash
# Search available extensions
specify extension search

# Install an extension
specify extension add <extension-name>
```

For example, extensions could add Jira integration, post-implementation code review, V-Model test traceability, or project health diagnostics.

See the [Extensions reference](https://github.github.io/spec-kit/reference/extensions.html) for the full command guide. Browse the [community extensions](#-community-extensions) above for what's available.

### Presets — Customize Existing Workflows

Use **presets** when you want to change *how* Spec Kit works without adding new capabilities. Presets override the templates and commands that ship with the core *and* with installed extensions — for example, enforcing a compliance-oriented spec format, using domain-specific terminology, or applying organizational standards to plans and tasks. They customize the artifacts and instructions that Spec Kit and its extensions produce.

```bash
# Search available presets
specify preset search

# Install a preset
specify preset add <preset-name>
```

For example, presets could restructure spec templates to require regulatory traceability, adapt the workflow to fit the methodology you use (e.g., Agile, Kanban, Waterfall, jobs-to-be-done, or domain-driven design), add mandatory security review gates to plans, enforce test-first task ordering, or localize the entire workflow to a different language. The [pirate-speak demo](https://github.com/mnriem/spec-kit-pirate-speak-preset-demo) shows just how deep the customization can go. Multiple presets can be stacked with priority ordering.

See the [Presets reference](https://github.github.io/spec-kit/reference/presets.html) for the full command guide, including resolution order and priority stacking.

### When to Use Which

| Goal | Use |
| --- | --- |
| Add a brand-new command or workflow | Extension |
| Customize the format of specs, plans, or tasks | Preset |
| Integrate an external tool or service | Extension |
| Enforce organizational or regulatory standards | Preset |
| Ship reusable domain-specific templates | Either — presets for template overrides, extensions for templates bundled with new commands |

## 📚 Core Philosophy

Spec-Driven Development is a structured process that emphasizes:

- **Intent-driven development** where specifications define the "*what*" before the "*how*"
- **Rich specification creation** using guardrails and organizational principles
- **Multi-step refinement** rather than one-shot code generation from prompts
- **Heavy reliance** on advanced AI model capabilities for specification interpretation

## 🌟 Development Phases

| Phase                                    | Focus                    | Key Activities                                                                                                                                                     |
| ---------------------------------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **0-to-1 Development** ("Greenfield")    | Generate from scratch    | <ul><li>Start with high-level requirements</li><li>Generate specifications</li><li>Plan implementation steps</li><li>Build production-ready applications</li></ul> |
| **Creative Exploration**                 | Parallel implementations | <ul><li>Explore diverse solutions</li><li>Support multiple technology stacks & architectures</li><li>Experiment with UX patterns</li></ul>                         |
| **Iterative Enhancement** ("Brownfield") | Brownfield modernization | <ul><li>Add features iteratively</li><li>Modernize legacy systems</li><li>Adapt processes</li></ul>                                                                |

## 🎯 Experimental Goals

Our research and experimentation focus on:

### Technology independence

- Create applications using diverse technology stacks
- Validate the hypothesis that Spec-Driven Development is a process not tied to specific technologies, programming languages, or frameworks

### Enterprise constraints

- Demonstrate mission-critical application development
- Incorporate organizational constraints (cloud providers, tech stacks, engineering practices)
- Support enterprise design systems and compliance requirements

### User-centric development

- Build applications for different user cohorts and preferences
- Support various development approaches (from vibe-coding to AI-native development)

### Creative & iterative processes

- Validate the concept of parallel implementation exploration
- Provide robust iterative feature development workflows
- Extend processes to handle upgrades and modernization tasks

## 🔧 Prerequisites

- **Linux/macOS/Windows**
- [Supported](#-supported-ai-coding-agent-integrations) AI coding agent.
- [uv](https://docs.astral.sh/uv/) for package management (recommended) or [pipx](https://pypa.github.io/pipx/) for persistent installation
- [Python 3.11+](https://www.python.org/downloads/)
- [Git](https://git-scm.com/downloads)

If you encounter issues with an agent, please open an issue so we can refine the integration.

## 📖 Learn More

- **[Complete Spec-Driven Development Methodology](./spec-driven.md)** - Deep dive into the full process
- **[Detailed Walkthrough](#-detailed-process)** - Step-by-step implementation guide

---

## 📋 Detailed Process

<details>
<summary>Click to expand the detailed step-by-step walkthrough</summary>

You can use the Specify CLI to bootstrap your project, which will bring in the required artifacts in your environment. Run:

```bash
specify init <project_name>
```

Or initialize in the current directory:

```bash
specify init .
# or use the --here flag
specify init --here
# Skip confirmation when the directory already has files
specify init . --force
# or
specify init --here --force
```

![Specify CLI bootstrapping a new project in the terminal](./media/specify_cli.gif)

In an interactive terminal, you will be prompted to select the coding agent integration you are using. In non-interactive sessions, such as CI or piped runs, `specify init` defaults to GitHub Copilot unless you pass `--integration`. You can also proactively specify the integration directly in the terminal:

```bash
specify init <project_name> --integration copilot
specify init <project_name> --integration gemini
specify init <project_name> --integration codex

# Or in current directory:
specify init . --integration copilot
specify init . --integration codex --integration-options="--skills"

# or use --here flag
specify init --here --integration copilot
specify init --here --integration codex --integration-options="--skills"

# Force merge into a non-empty current directory
specify init . --force --integration copilot

# or
specify init --here --force --integration copilot
```

The CLI will check if you have Claude Code, Gemini CLI, Cursor CLI, Qwen CLI, opencode, Codex CLI, Qoder CLI, Tabnine CLI, Kiro CLI, Pi, Forge, Goose, or Mistral Vibe installed. If you do not, or you prefer to get the templates without checking for the right tools, use `--ignore-agent-tools` with your command:

```bash
specify init <project_name> --integration copilot --ignore-agent-tools
```

### **STEP 1:** Establish project principles

Go to the project folder and run your coding agent. In our example, we're using `claude`.

![Bootstrapping Claude Code environment](./media/bootstrap-claude-code.gif)

You will know that things are configured correctly if you see the `/spec.constitution`, `/spec.specify`, `/spec.plan`, `/spec.tasks`, `/spec.implement`, `/spec.brainstorm`, and `/spec.verify` commands available.

The first step should be establishing your project's governing principles using the `/spec.constitution` command. This helps ensure consistent decision-making throughout all subsequent development phases:

```text
/spec.constitution Create principles focused on code quality, testing standards, user experience consistency, and performance requirements. Include governance for how these principles should guide technical decisions and implementation choices.
```

This step creates or updates the `.specify/memory/constitution.md` file with your project's foundational guidelines that the coding agent will reference during specification, planning, and implementation phases.

### **STEP 2:** Create project specifications

With your project principles established, you can now create the functional specifications. Use the `/spec.specify` command and then provide the concrete requirements for the project you want to develop.

> [!IMPORTANT]
> Be as explicit as possible about *what* you are trying to build and *why*. **Do not focus on the tech stack at this point**.

An example prompt:

```text
Develop Taskify, a team productivity platform. It should allow users to create projects, add team members,
assign tasks, comment and move tasks between boards in Kanban style. In this initial phase for this feature,
let's call it "Create Taskify," let's have multiple users but the users will be declared ahead of time, predefined.
I want five users in two different categories, one product manager and four engineers. Let's create three
different sample projects. Let's have the standard Kanban columns for the status of each task, such as "To Do,"
"In Progress," "In Review," and "Done." There will be no login for this application as this is just the very
first testing thing to ensure that our basic features are set up. For each task in the UI for a task card,
you should be able to change the current status of the task between the different columns in the Kanban work board.
You should be able to leave an unlimited number of comments for a particular card. You should be able to, from that task
card, assign one of the valid users. When you first launch Taskify, it's going to give you a list of the five users to pick
from. There will be no password required. When you click on a user, you go into the main view, which displays the list of
projects. When you click on a project, you open the Kanban board for that project. You're going to see the columns.
You'll be able to drag and drop cards back and forth between different columns. You will see any cards that are
assigned to you, the currently logged in user, in a different color from all the other ones, so you can quickly
see yours. You can edit any comments that you make, but you can't edit comments that other people made. You can
delete any comments that you made, but you can't delete comments anybody else made.
```

After this prompt is entered, you should see Claude Code kick off the planning and spec drafting process. Claude Code will also trigger some of the built-in scripts to set up the repository.

Once this step is completed, you should have a new branch created (e.g., `001-create-taskify`), as well as a new specification in the `specs/001-create-taskify` directory.

The produced specification should contain a set of user stories and functional requirements, as defined in the template.

At this stage, your project folder contents should resemble the following:

```text
├── .specify
│   ├── memory
│   │   └── constitution.md
│   ├── scripts
│   │   └── bash
│   │       ├── check-prerequisites.sh
│   │       ├── common.sh
│   │       ├── create-new-feature.sh
│   │       ├── setup-plan.sh
│   │       └── setup-tasks.sh
│   └── templates
│       ├── plan-template.md
│       ├── spec-template.md
│       └── tasks-template.md
└── specs
    └── 001-create-taskify
        └── spec.md
```

### **STEP 2.5:** Explore approaches with /spec.brainstorm (optional, recommended for complex features)

Before creating the specification, you can explore the problem space using the **`/spec.brainstorm`** command. This is optional but recommended when:

- The problem space is complex or novel
- Multiple approaches exist with meaningful tradeoffs
- Architecture decisions need upfront exploration

```text
/spec.brainstorm I need to add real-time collaboration to the photo albums app so multiple users can edit the same album simultaneously
```

The command produces `.specify/drafts/brainstorm-context.md` with:

- **Problem statement** and key concepts
- **Approaches considered** with tradeoffs, risks, and fit analysis
- **Architecture notes** and integration points
- **Risk register** with mitigations
- **Open questions** for further research
- **Recommended direction** with rationale

This draft is automatically consumed by `/spec.specify` in the next step to seed the specification's Goal, Success Criteria, Constraints, and Risk Register sections.

### **STEP 3:** Functional specification clarification (required before planning)

With the baseline specification created, you can go ahead and clarify any of the requirements that were not captured properly within the first shot attempt.

You should run the structured clarification workflow **before** creating a technical plan to reduce rework downstream.

Preferred order:

1. Use `/spec.clarify` (structured) – sequential, coverage-based questioning that records answers in a Clarifications section.
2. Optionally follow up with ad-hoc free-form refinement if something still feels vague.

If you intentionally want to skip clarification (e.g., spike or exploratory prototype), explicitly state that so the agent doesn't block on missing clarifications.

Example free-form refinement prompt (after `/spec.clarify` if still needed):

```text
For each sample project or project that you create there should be a variable number of tasks between 5 and 15
tasks for each one randomly distributed into different states of completion. Make sure that there's at least
one task in each stage of completion.
```

You should also ask Claude Code to validate the **Review & Acceptance Checklist**, checking off the things that are validated/pass the requirements, and leave the ones that are not unchecked. The following prompt can be used:

```text
Read the review and acceptance checklist, and check off each item in the checklist if the feature spec meets the criteria. Leave it empty if it does not.
```

It's important to use the interaction with Claude Code as an opportunity to clarify and ask questions around the specification - **do not treat its first attempt as final**.

### **STEP 4:** Generate a plan

You can now be specific about the tech stack and other technical requirements. You can use the `/spec.plan` command that is built into the project template with a prompt like this:

```text
We are going to generate this using .NET Aspire, using Postgres as the database. The frontend should use
Blazor server with drag-and-drop task boards, real-time updates. There should be a REST API created with a projects API,
tasks API, and a notifications API.
```

The output of this step will include a number of implementation detail documents, with your directory tree resembling this:

```text
.
├── .specify
│   ├── memory
│   │   └── constitution.md
│   ├── scripts
│   │   └── bash
│   │       ├── check-prerequisites.sh
│   │       ├── common.sh
│   │       ├── create-new-feature.sh
│   │       ├── setup-plan.sh
│   │       └── setup-tasks.sh
│   └── templates
│       ├── CLAUDE-template.md
│       ├── plan-template.md
│       ├── spec-template.md
│       └── tasks-template.md
├── CLAUDE.md
└── specs
    └── 001-create-taskify
        ├── contracts
        │   ├── api-spec.json
        │   └── signalr-spec.md
        ├── data-model.md
        ├── plan.md
        ├── quickstart.md
        ├── research.md
        └── spec.md
```

Check the `research.md` document to ensure that the right tech stack is used, based on your instructions. You can ask Claude Code to refine it if any of the components stand out, or even have it check the locally-installed version of the platform/framework you want to use (e.g., .NET).

Additionally, you might want to ask Claude Code to research details about the chosen tech stack if it's something that is rapidly changing (e.g., .NET Aspire, JS frameworks), with a prompt like this:

```text
I want you to go through the implementation plan and implementation details, looking for areas that could
benefit from additional research as .NET Aspire is a rapidly changing library. For those areas that you identify that
require further research, I want you to update the research document with additional details about the specific
versions that we are going to be using in this Taskify application and spawn parallel research tasks to clarify
any details using research from the web.
```

During this process, you might find that Claude Code gets stuck researching the wrong thing - you can help nudge it in the right direction with a prompt like this:

```text
I think we need to break this down into a series of steps. First, identify a list of tasks
that you would need to do during implementation that you're not sure of or would benefit
from further research. Write down a list of those tasks. And then for each one of these tasks,
I want you to spin up a separate research task so that the net results is we are researching
all of those very specific tasks in parallel. What I saw you doing was it looks like you were
researching .NET Aspire in general and I don't think that's gonna do much for us in this case.
That's way too untargeted research. The research needs to help you solve a specific targeted question.
```

> [!NOTE]
> Claude Code might be over-eager and add components that you did not ask for. Ask it to clarify the rationale and the source of the change.

### **STEP 5:** Have Claude Code validate the plan

With the plan in place, you should have Claude Code run through it to make sure that there are no missing pieces. You can use a prompt like this:

```text
Now I want you to go and audit the implementation plan and the implementation detail files.
Read through it with an eye on determining whether or not there is a sequence of tasks that you need
to be doing that are obvious from reading this. Because I don't know if there's enough here. For example,
when I look at the core implementation, it would be useful to reference the appropriate places in the implementation
details where it can find the information as it walks through each step in the core implementation or in the refinement.
```

This helps refine the implementation plan and helps you avoid potential blind spots that Claude Code missed in its planning cycle. Once the initial refinement pass is complete, ask Claude Code to go through the checklist once more before you can get to the implementation.

You can also ask Claude Code (if you have the [GitHub CLI](https://docs.github.com/en/github-cli/github-cli) installed) to go ahead and create a pull request from your current branch to `main` with a detailed description, to make sure that the effort is properly tracked.

> [!NOTE]
> Before you have the agent implement it, it's also worth prompting Claude Code to cross-check the details to see if there are any over-engineered pieces (remember - it can be over-eager). If over-engineered components or decisions exist, you can ask Claude Code to resolve them. Ensure that Claude Code follows the constitution in `.specify/memory/constitution.md` as the foundational piece that it must adhere to when establishing the plan.

### **STEP 6:** Generate task breakdown with /spec.tasks

With the implementation plan validated, you can now break down the plan into specific, actionable tasks that can be executed in the correct order. Use the `/spec.tasks` command to automatically generate a detailed task breakdown from your implementation plan:

```text
/spec.tasks
```

This step creates a `tasks.md` file in your feature specification directory that contains:

- **Task breakdown organized by user story** - Each user story becomes a separate implementation phase with its own set of tasks
- **Dependency management** - Tasks are ordered to respect dependencies between components (e.g., models before services, services before endpoints)
- **Parallel execution markers** - Tasks that can run in parallel are marked with `[P]` to optimize development workflow
- **File path specifications** - Each task includes the exact file paths where implementation should occur
- **Test-driven development structure** - If tests are requested, test tasks are included and ordered to be written before implementation
- **Checkpoint validation** - Each user story phase includes checkpoints to validate independent functionality

The generated tasks.md provides a clear roadmap for the `/spec.implement` command, ensuring systematic implementation that maintains code quality and allows for incremental delivery of user stories.

### **STEP 7:** Implementation

Once ready, use the `/spec.implement` command to execute your implementation plan:

```text
/spec.implement
```

The `/spec.implement` command will:

- Validate that all prerequisites are in place (constitution, spec, plan, and tasks)
- Parse the task breakdown from `tasks.md`
- Execute tasks in the correct order, respecting dependencies and parallel execution markers
- Follow the TDD approach defined in your task plan
- Provide progress updates and handle errors appropriately

> [!IMPORTANT]
> The coding agent will execute local CLI commands (such as `dotnet`, `npm`, etc.) - make sure you have the required tools installed on your machine.

Once the implementation is complete, test the application and resolve any runtime errors that may not be visible in CLI logs (e.g., browser console errors). You can copy and paste such errors back to your coding agent for resolution.

### **STEP 8:** Verify completeness with /spec.verify

After implementation, use the **`/spec.verify`** command to run a structured verification against the specification:

```text
/spec.verify
```

The `/spec.verify` command performs:

- **Test Gate** — Runs the project's test suite. Tests must pass before assessment proceeds
- **Diff Analysis** — Categorizes changed files (spec, implementation, tests, docs)
- **4-Pillar Assessment** — Full compliance check with scored evaluation:
  1. **Spec Compliance** (0-100): Goal alignment, Success Criteria coverage, Constraint adherence, all FRs/NFRs addressed, Risk Register mitigation
  2. **Code Quality** (0-100): Structure, error handling, edge cases, consistency
  3. **Test Adequacy** (0-100): Coverage, quality, edge cases, regression risk
  4. **Risk & Evidence** (0-100): Unverified assumptions, technical debt, integration risk

The report is saved to `SPECIFY_FEATURE_DIRECTORY/verify.md` and includes an overall VERIFIED / NOT VERIFIED verdict (all pillars >= 70 to pass).

If verification fails, the report includes specific actions to address each failing pillar. Run the recommended fixes and re-verify.

</details>

---

## 🔍 Troubleshooting

### Common Issues

**Issue**: `specify` command not found after installation
- **Solution**: Ensure your shell PATH includes `~/.local/bin` (uv) or `~/.cargo/bin` (pipx). Restart your terminal or run `source ~/.bashrc` (or `~/.zshrc`).

**Issue**: Permission denied when running scripts
- **Solution**: Run `chmod +x scripts/bash/*.sh` or re-run `specify init` which auto-fixes permissions.

**Issue**: Team AI Directives authentication fails
- **Solution**: Check that `GITHUB_TOKEN` or `GITLAB_TOKEN` environment variable is set with a valid token that has access to the private repository.

**Issue**: Extension commands not appearing in agent
- **Solution**: Run `specify extension list` to verify extensions are enabled. Some agents require restarting the IDE or CLI.

For more troubleshooting, see the [FORK.md](./FORK.md) file.

## 👥 Maintainers

This fork is maintained by the **Tikal** engineering team:

- **Tikal Knowledge Center** — [tikalk.com](https://www.tikalk.com)
- **GitHub**: [@tikalk](https://github.com/tikalk)
- **Repository**: [tikalk/agentic-sdlc-spec-kit](https://github.com/tikalk/agentic-sdlc-spec-kit)

## 💬 Support

For support on this fork:
- **Issues**: [Open a GitHub issue](https://github.com/tikalk/agentic-sdlc-spec-kit/issues/new)
- **Upstream Issues**: For upstream spec-kit issues, see [github/spec-kit](https://github.com/github/spec-kit/issues)

We welcome bug reports, feature requests, and questions about using Agentic SDLC Spec Kit.

## 🙏 Acknowledgements

This project is heavily influenced by and based on the work and research of [John Lam](https://github.com/jflam) and the original [Spec Kit](https://github.com/github/spec-kit) project.

## 📄 License

This project is licensed under the terms of the MIT open source license. Please refer to the [LICENSE](./LICENSE) file for the full terms.
