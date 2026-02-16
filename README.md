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
- **Adding enterprise-grade features** like team AI directives, MCP server integration, and gateway configuration
- **Enhancing tooling** with advanced CLI options, async agent support, comprehensive issue tracker integration, and spec-code synchronization
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

- [🤔 What is Spec-Driven Development?](#-what-is-spec-driven-development)
- [⚡ Get Started](#-get-started)
- [🤖 Supported AI Agents](#-supported-ai-agents)
- [🔧 Specify CLI Reference](#-specify-cli-reference)
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

### 1. Install Specify CLI

Choose your preferred installation method:

#### Option 1: Persistent Installation (Recommended)

Install once and use everywhere:

```bash
uv tool install agentic-sdlc-specify-cli --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git
```

Then use the tool directly:

```bash
# Create new project
specify init <PROJECT_NAME>

# Or initialize in existing project
specify init . --ai claude
# or
specify init --here --ai claude

# Check installed tools
specify check
```

To upgrade Specify, see the [Upgrade Guide](./docs/upgrade.md) for detailed instructions. Quick upgrade:

```bash
uv tool install agentic-sdlc-specify-cli --force --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git
```

#### Option 2: One-time Usage

Run directly without installing:

```bash
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <PROJECT_NAME>
```

**Benefits of persistent installation:**

- Tool stays installed and available in PATH
- No need to create shell aliases
- Better tool management with `uv tool list`, `uv tool upgrade`, `uv tool uninstall`
- Cleaner shell configuration

### 2. Initialize Your Project

The `specify init` command supports comprehensive configuration options:

#### Basic Usage

```bash
# Initialize a new project
specify init my-project

# Initialize in current directory
specify init .

# Initialize in current directory (alternative syntax)
specify init --here
```

#### AI Agent Configuration

```bash
# Specify AI agent during initialization
specify init my-project --ai claude
specify init my-project --ai copilot
specify init my-project --ai gemini
specify init my-project --ai cursor-agent
specify init my-project --ai qwen
specify init my-project --ai opencode
specify init my-project --ai codex
specify init my-project --ai windsurf
specify init my-project --ai kilocode
specify init my-project --ai auggie
specify init my-project --ai codebuddy
specify init my-project --ai roo
specify init my-project --ai q
```

#### Script Type Selection

```bash
# Auto-detect script type (default: ps on Windows, sh on others)
specify init my-project

# Force PowerShell scripts
specify init my-project --script ps

# Force POSIX shell scripts
specify init my-project --script sh
```

#### Team AI Directives Integration

```bash
# Use local team-ai-directives directory
specify init my-project --team-ai-directives ~/workspace/team-ai-directives

# Clone from remote repository
specify init my-project --team-ai-directives https://github.com/your-org/team-ai-directives.git

# Example: Use the official Agentic SDLC team-ai-directives template
specify init my-project --team-ai-directives https://github.com/tikalk/agentic-sdlc-team-ai-directives.git
```

#### Issue Tracker Integration

```bash
# Enable GitHub Issues integration
specify init my-project --issue-tracker github

# Enable Jira integration
specify init my-project --issue-tracker jira

# Enable Linear integration
specify init my-project --issue-tracker linear

# Enable GitLab integration
specify init my-project --issue-tracker gitlab
```

#### Async Agent Support

```bash
# Enable Jules for autonomous task execution
specify init my-project --async-agent jules

# Enable Async Copilot
specify init my-project --async-agent async-copilot

# Enable Async Codex
specify init my-project --async-agent async-codex
```

#### Git Platform MCP Configuration

```bash
# Enable GitHub platform MCP for PR operations
specify init my-project --git-platform github

# Enable GitLab platform MCP for merge request operations
specify init my-project --git-platform gitlab
```

#### Advanced Options

```bash
# Skip agent tool checks
specify init my-project --ignore-agent-tools

# Skip git repository initialization
specify init my-project --no-git

# Force overwrite existing files
specify init my-project --here --force

# Skip TLS verification (not recommended)
specify init my-project --skip-tls

# Show debug output
specify init my-project --debug

# Use custom GitHub token
specify init my-project --github-token $GITHUB_TOKEN

# Enable automatic spec-code synchronization
specify init my-project --spec-sync
specify init my-project --ai claude --spec-sync
```

### Per-Spec Workflow Mode Architecture

Specify implements a **per-spec mode architecture** where each feature can operate in different modes simultaneously, providing maximum flexibility for mixed-mode workflows. The mode is configured at the specification level and applies to all downstream commands.

#### Available Modes

- **`spec` mode (default)**: Full structured specification with comprehensive requirements, research, and validation
- **`build` mode**: Lightweight, conversational approach focused on quick validation and exploration

#### Mode Configuration

Modes are configured per-feature when creating the specification:

```bash
# Create feature with specific mode
/spec.specify --mode=build "Quick API fix"
/spec.specify --mode=spec "Comprehensive user authentication"

# Override framework options per feature
/spec.specify --mode=build --tdd "Critical feature with tests"
/spec.specify --mode=spec --no-contracts "Feature without API contracts"

# Mode-specific defaults automatically applied
# Build mode: tdd=false, contracts=false, data_models=false, risk_tests=false
# Spec mode: tdd=true, contracts=true, data_models=true, risk_tests=true
```

#### Framework Options

Fine-grained control over development approach:

```bash
# Test-Driven Development
--tdd / --no-tdd

# Smart Contracts (API specifications)
--contracts / --no-contracts

# Data Models (entity relationships)
--data-models / --no-data-models

# Risk-Based Testing
--risk-tests / --no-risk-tests
```

#### Mode Detection and Auto-Detection

The mode is stored in the `spec.md` file metadata and automatically detected by downstream commands:

- **`/spec.plan`**, **`/spec.tasks`**, **`/spec.implement`**, **`/spec.clarify`**, **`/spec.analyze`**, **`/spec.checklist`**: Auto-detect mode and framework options from the current feature's spec.md
- **`/architect.*`**: Mode-agnostic (system-level architecture should not be constrained by feature-level modes)

#### When to Use Each Mode

**Use `build` mode for:**

- Individual development and rapid prototyping
- Quick wins and simple features  
- Senior engineers who prefer autonomy
- Situations requiring fast iteration

**Use `spec` mode for:**

- Team collaboration and complex systems
- Production features requiring comprehensive validation
- Situations where thorough documentation is critical
- Projects with multiple stakeholders

#### Mixed-Mode Workflows

The per-spec architecture enables advanced workflows:

```bash
# Create multiple features with different modes in same project
/spec.specify --mode=build "Quick prototype feature"
/spec.specify --mode=spec "Production authentication system"
/spec.specify --mode=build "Bug fix"

# Each feature operates independently with its configured mode
/spec.plan    # Auto-detects mode from current feature's spec.md
/spec.tasks   # Respects framework options from spec.md
/spec.implement # Adapts validation based on detected mode
/spec.analyze # Auto-detects pre vs post-implementation context based on project state
```

#### Complete Example

```bash
specify init my-project \
  --ai claude \
  --script sh \
  --team-ai-directives https://github.com/your-org/team-ai-directives.git \
  --issue-tracker github \
  --async-agent jules
```

### Optional Architecture Support

The toolkit includes comprehensive architecture documentation support that works with both build and spec modes. Architecture commands are optional and can be used at any time, regardless of workflow mode.

#### Two-Level Architecture System

| Level | Location | ADR File | Architecture Description | Commands |
|-------|----------|----------|--------------------------|----------|
| **System** | Main branch | `memory/adr.md` | `AD.md` (root) | `architect.*` |
| **Feature** | Feature branch | `specs/{feature}/adr.md` | `specs/{feature}/AD.md` | `spec.plan --architecture` |

#### Architecture Workflow

```bash
# Interactive PRD exploration to create system-level ADRs (greenfield)
/architect.specify "B2B SaaS platform for real-time supply chain management"

# Reverse-engineer architecture from existing codebase (brownfield)
/architect.init "Django monolith with PostgreSQL, React frontend, deployed on AWS ECS"

# Refine and clarify ADRs through targeted questions
/architect.clarify

# Generate full Architecture Description from ADRs
/architect.implement

# Then proceed with normal workflow
/spec.specify "Feature within this architecture"

# Or generate feature-level architecture during planning
/spec.plan --architecture
```

#### Architecture Commands

| Command | Description |
|---------|-------------|
| `architect.specify` | Interactive PRD exploration to create system-level ADRs |
| `architect.clarify` | Refine ADRs through targeted clarification questions |
| `architect.init` | Reverse-engineer architecture from existing codebase (brownfield) |
| `architect.implement` | Generate full Architecture Description (AD.md) from ADRs |

**Feature Architecture**: Use `/spec.plan --architecture` or set `architecture=true` in spec.md Framework Options to generate feature-level architecture (`specs/{feature}/AD.md` and `specs/{feature}/adr.md`).

#### Architecture Configuration Options

The architecture commands support additional configuration options for fine-tuned control:

**Views Selection** (`--views`):

- `core` (default) - Generate the essential 5 views: Context, Functional, Information, Development, Deployment
- `all` - Include all 7 views including Concurrency and Operational
- `concurrency,operational` - Custom selection (comma-separated), always includes core views

```bash
# Default core views
/architect.init "E-commerce platform"

# All views including concurrency and operational
/architect.init --views all "High-throughput trading system"

# Custom selection
/architect.init --views concurrency "Real-time data processing pipeline"
```

**ADR Generation Heuristic** (`--adr-heuristic`):

- `surprising` (default) - Only document decisions that deviate from obvious ecosystem defaults
- `all` - Document every architectural decision
- `minimal` - Document only high-risk or non-obvious decisions

```bash
# Skip documenting obvious choices (PostgreSQL for relational data, React for SPA)
/architect.specify --adr-heuristic surprising "Standard web application"

# Document every decision
/architect.specify --adr-heuristic all "Complex multi-tenant system"

# Minimal documentation
/architect.specify --adr-heuristic minimal "Internal tool with simple requirements"
```

#### Rozanski & Woods Viewpoints

The `architect.*` commands generate documentation covering:

1. **Context View** - System scope and external interactions
2. **Functional View** - Functional elements and responsibilities
3. **Information View** - Data storage, management, and flow
4. **Concurrency View** - Runtime processes and coordination
5. **Development View** - Code organization and CI/CD
6. **Deployment View** - Physical infrastructure and environments
7. **Operational View** - Operations, monitoring, and support

Plus cross-cutting **Perspectives**: Security, Performance & Scalability

### 2. Establish project principles

Launch your AI assistant in the project directory. The `/spec.*` commands are available in the assistant.

Use the **`/spec.constitution`** command to create your project's governing principles and development guidelines that will guide all subsequent development.

```bash
/spec.constitution Create principles focused on code quality, testing standards, user experience consistency, and performance requirements
```

### 3. Create the spec

Use the **`/spec.specify`** command to describe what you want to build. Focus on the **what** and **why**, not the tech stack.

```bash
/spec.specify Build an application that can help me organize my photos in separate photo albums. Albums are grouped by date and can be re-organized by dragging and dropping on the main page. Albums are never in other nested albums. Within each album, photos are previewed in a tile-like interface.
```

### 4. Create a technical implementation plan

Use the **`/spec.plan`** command to provide your tech stack and architecture choices.

```bash
/spec.plan The application uses Vite with minimal number of libraries. Use vanilla HTML, CSS, and JavaScript as much as possible. Images are not uploaded anywhere and metadata is stored in a local SQLite database.
```

### 5. Break down into tasks

Use **`/spec.tasks`** to create an actionable task list from your implementation plan.

```bash
/spec.tasks
```

### 6. Execute implementation

Use **`/spec.implement`** to execute all tasks and build your feature according to the plan. Supports both synchronous (interactive) and asynchronous (autonomous) execution modes.

```bash
/spec.implement
```

### 7. Generate session trace (optional)

Use **`/spec.trace`** to generate comprehensive AI session execution traces capturing decisions, patterns, and outcomes.

```bash
/spec.trace
```

**Benefits**: Session traces document AI agent decision-making, execution context, quality gates, and reusable patterns. Stored in `specs/{BRANCH}/trace.md` with your feature artifacts. Optional but enriches `/spec.levelup` context packets when present.

### 8. Level up and contribute knowledge

Use **`/spec.levelup`** to capture learnings from completed work and contribute reusable knowledge back to your team's shared repository.

```bash
/spec.levelup "Document the patterns learned from this implementation for future reference"
```

For detailed step-by-step instructions, see our [comprehensive guide](./spec-driven.md).

## 🤖 Supported AI Agents

| Agent                                                                                | Support | Notes                                                                                                                                     |
| ------------------------------------------------------------------------------------ | ------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| [Qoder CLI](https://qoder.com/cli)                                                   | ✅      |                                                                                                                                           |
| [Amazon Q Developer CLI](https://aws.amazon.com/developer/learning/q-developer-cli/) | ⚠️      | Amazon Q Developer CLI [does not support](https://github.com/aws/amazon-q-developer-cli/issues/3064) custom arguments for slash commands. |
| [Amp](https://ampcode.com/)                                                          | ✅      |                                                                                                                                           |
| [Auggie CLI](https://docs.augmentcode.com/cli/overview)                              | ✅      |                                                                                                                                           |
| [Claude Code](https://www.anthropic.com/claude-code)                                 | ✅      |                                                                                                                                           |
| [CodeBuddy CLI](https://www.codebuddy.ai/cli)                                        | ✅      |                                                                                                                                           |
| [Codex CLI](https://github.com/openai/codex)                                         | ✅      |                                                                                                                                           |
| [Cursor](https://cursor.sh/)                                                         | ✅      |                                                                                                                                           |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli)                            | ✅      |                                                                                                                                           |
| [GitHub Copilot](https://code.visualstudio.com/)                                     | ✅      |                                                                                                                                           |
| [IBM Bob](https://www.ibm.com/products/bob)                                          | ✅      | IDE-based agent with slash command support                                                                                                |
| [Jules](https://jules.google.com/)                                                   | ✅      |                                                                                                                                           |
| [Kilo Code](https://github.com/Kilo-Org/kilocode)                                    | ✅      |                                                                                                                                           |
| [opencode](https://opencode.ai/)                                                     | ✅      |                                                                                                                                           |
| [Qwen Code](https://github.com/QwenLM/qwen-code)                                     | ✅      |                                                                                                                                           |
| [Roo Code](https://roocode.com/)                                                     | ✅      |                                                                                                                                           |
| [SHAI (OVHcloud)](https://github.com/ovh/shai)                                       | ✅      |                                                                                                                                           |
| [Windsurf](https://windsurf.com/)                                                    | ✅      |                                                                                                                                           |
| [Antigravity (agy)](https://agy.ai/)                                                 | ✅      |                                                                                                                                           |

## 📦 Skills Package Manager

The Specify toolkit includes a **Skills Package Manager** - a developer-grade package manager for agent skills that treats skills as versioned software dependencies. Skills enable AI agents to follow team practices, coding standards, and domain-specific guidelines.

### What Are Skills?

Skills are reusable, versioned knowledge packages that guide AI agents in making consistent technical decisions. They can cover:

- **Best Practices**: Framework patterns, testing strategies, code organization
- **Team Standards**: Coding conventions, naming patterns, architectural principles
- **Domain Knowledge**: Business logic, compliance requirements, domain patterns
- **Quality Guidelines**: Performance optimization, security hardening, accessibility standards

### Key Features

| Feature | Description |
|---------|-------------|
| **Auto-Discovery** | Skills automatically matched to features based on descriptions (60% keyword overlap, 40% content analysis) |
| **Dual Registry** | Search public [skills.sh](https://skills.sh) registry + install from GitHub, GitLab, or local paths |
| **Team Curation** | Define required skills (auto-installed), recommended skills, and blocked skills in `team-ai-directives/skills.json` |
| **Quality Evaluation** | Built-in 100-point scoring framework: frontmatter (20pts), content organization (30pts), self-containment (30pts), documentation (20pts) |
| **Zero Dependencies** | Direct GitHub installation with no npm or external tool dependencies |
| **Policy Enforcement** | Team-level policies for auto-installation, version constraints, and skill blocking |

### Available Commands

```bash
# Search the public skills registry
specify skill search "react best practices"

# Install a skill from GitHub
specify skill install github:vercel-labs/agent-skills/react-best-practices

# List all installed skills
specify skill list --json

# Evaluate skill quality
specify skill eval ./my-skill --review        # Structure quality (100-point score)
specify skill eval ./my-skill --task          # Behavioral impact via test scenarios
specify skill eval ./my-skill --full          # Complete evaluation

# Manage skills
specify skill update [name|--all]              # Update to latest versions
specify skill remove <name>                    # Uninstall a skill
specify skill sync-team                        # Sync with team manifest
specify skill check-updates                    # Check for available updates
specify skill config [key] [value]             # View/modify configuration
```

### Team Skills Manifest

Define your team's skill strategy in `team-ai-directives/skills.json`:

```json
{
  "version": "1.0.0",
  "source": "team-ai-directives",
  "skills": {
    "required": {
      "github:vercel-labs/agent-skills/react-best-practices": "^1.2.0",
      "github:your-org/internal-skills/company-patterns": "~2.0.0"
    },
    "recommended": {
      "github:vercel-labs/agent-skills/web-design-guidelines": "~1.0.0"
    },
    "internal": {
      "local:./skills/dbt-workflow": "*"
    },
    "blocked": [
      "github:unsafe-org/deprecated-skill"
    ]
  },
  "policy": {
    "auto_install_required": true,
    "enforce_blocked": true,
    "allow_project_override": true
  }
}
```

### Skill Auto-Discovery Workflow

When you run `/spec.specify`, the Skills Package Manager automatically:

1. **Analyzes** your feature description against installed skills
2. **Scores** relevance using keyword matching (60% description, 40% content)
3. **Selects** top 3 skills above threshold (default 0.7, configurable)
4. **Injects** relevant skills into `specs/{feature}/context.md`

Example auto-discovery output:

```markdown
## Relevant Skills (Auto-Detected)

- **react-best-practices**@1.2.0 (confidence: 0.95)
  - React component patterns, hooks best practices, performance optimization
  
- **typescript-guidelines**@1.0.0 (confidence: 0.82)
  - Type safety patterns, interface design, error handling
  
- **testing-strategies**@2.0.1 (confidence: 0.78)
  - Test organization, coverage targets, mocking patterns
```

### Configuration

Skills configuration is stored in `~/.config/specify/config.json`:

```json
{
  "skills": {
    "auto_activation_threshold": 0.7,
    "max_auto_skills": 3,
    "preserve_user_edits": true,
    "registry_url": "https://skills.sh/api",
    "evaluation_required": false
  }
}
```

### Integration Points

- **`specify init`** - Auto-installs team required skills during project setup
- **`/spec.specify`** - Auto-discovers and injects relevant skills per feature
- **`/spec.plan`** - References activated skills in planning
- **`/spec.implement`** - Agent applies skill guidance during implementation
- **`team-ai-directives/skills.json`** - Central skill registry alongside MCP configuration

### Benefits

1. **Consistency** - All team members follow same practices and patterns
2. **Quality** - Skills embed best practices and quality standards
3. **Speed** - Auto-discovery eliminates manual guidance searching
4. **Learning** - Skills capture team knowledge for reuse and growth
5. **Governance** - Team policies enforce standards while allowing overrides

### Learning More

- **[Skills Registry](https://skills.sh)** - Discover public skills from the community
- **[Agent Skills Format](https://agentskills.io/)** - Standard format for creating skills
- **[Roadmap Details](./roadmap.md#-skills-package-manager--100-complete---completed---extends-factor-xi-directives-as-code)** - Technical implementation details

---

## 🔧 Specify CLI Reference

The `specify` command supports the following options:

### Commands

| Command     | Description                                                    |
|-------------|----------------------------------------------------------------|
| `init`      | Initialize a new Specify project from the latest template      |
| `check`     | Check for installed tools (`git`, `claude`, `gemini`, `code`/`code-insiders`, `cursor-agent`, `windsurf`, `qwen`, `opencode`, `codex`, `shai`, `qoder`) |
| `skill`     | Manage agent skills: search, install, list, eval, update, remove, sync-team, check-updates, config |

### `specify init` Arguments & Options

| Argument/Option              | Type     | Description                                                                 |
|------------------------------|----------|-----------------------------------------------------------------------------|
| `<project-name>`             | Argument | Name for your new project directory (optional if using `--here`, or use `.` for current directory) |
| `--ai`                 | Option   | AI assistant to use: `claude`, `gemini`, `copilot`, `cursor-agent`, `qwen`, `opencode`, `codex`, `windsurf`, `kilocode`, `auggie`, `roo`, `codebuddy`, `amp`, `shai`, `q`, `agy`, `bob`, or `qoder` |
| `--script`                   | Option   | Script type: `sh` (POSIX) or `ps` (PowerShell)                              |
| `--ignore-agent-tools`       | Flag     | Skip checks for AI agent tools like Claude                                                  |
| `--no-git`                   | Flag     | Skip git repository                                         |
| `--here`                     | Flag     | Initialize project in the current directory instead of creating a new one                                            |
| `--force`                    | Flag     | Force merge/overwrite when initializing in current directory (skip confirmation)             |
| `--skip-tls`                 | Flag     | Skip SSL/TLS verification (not recommended)                                |
| `--debug`                    | Flag     | Enable detailed debug output for troubleshooting                                                        |
| `--github-token`             | Option   | GitHub token for API requests (or set GH_TOKEN/GITHUB_TOKEN env variable)      |
| `--team-ai-directives`       | Option   | Path or URL to team-ai-directives repository                               |
| `--issue-tracker`            | Option   | Issue tracker MCP: `github`, `jira`, `linear`, `gitlab`                    |
| `--async-agent`              | Option   | Async agent MCP: `jules`, `async-copilot`, `async-codex`                   |
| `--git-platform`             | Option   | Git platform MCP for PR operations: `github`, `gitlab`                     |
| `--spec-sync`                | Flag     | Enable automatic spec-code synchronization (keeps specs/*.md files updated with code changes) |

### `/spec.specify` Mode & Framework Options

| Argument/Option | Type     | Description                                                                 |
|-----------------|----------|-----------------------------------------------------------------------------|
| `--mode`        | Option   | Workflow mode: `build` (lightweight) or `spec` (comprehensive, default) |
| `--tdd/--no-tdd` | Option | Enable/disable TDD (Test-Driven Development) |
| `--contracts/--no-contracts` | Option | Enable/disable API contract generation |
| `--data-models/--no-data-models` | Option | Enable/disable data model generation |
| `--risk-tests/--no-risk-tests` | Option | Enable/disable risk-based test generation |

### `specify skill` Commands & Options

The Skills Package Manager is accessed via the `specify skill` subcommand:

| Command                          | Description                                                            |
|----------------------------------|------------------------------------------------------------------------|
| `search <query>`                 | Search the public skills.sh registry for matching skills              |
| `install <ref>`                  | Install a skill (GitHub: `github:owner/repo/skill`, GitLab: `gitlab:host/owner/repo/skill`, Local: `local:./path`) |
| `list [--outdated\|--json]`     | List installed skills with optional filtering                         |
| `eval <path> [--review\|--task\|--full\|--report]` | Evaluate skill quality: review (structure), task (behavior), full (both), or report (HTML) |
| `update [name\|--all]`           | Update specified skill or all skills to latest versions               |
| `remove <name>`                  | Uninstall a skill                                                      |
| `sync-team [--dry-run]`          | Sync installed skills with team manifest (show changes before applying with `--dry-run`) |
| `check-updates`                  | Check for available skill updates                                     |
| `config [key] [value]`           | View or modify skills configuration (e.g., `config auto_activation_threshold 0.8`) |

### Examples

#### Skills Commands

```bash
# Search for skills in the public registry
specify skill search "react best practices"
specify skill search "typescript"

# Install skills from GitHub
specify skill install github:vercel-labs/agent-skills/react-best-practices
specify skill install github:your-org/internal-skills/company-patterns

# Install local skills
specify skill install local:./skills/my-custom-skill

# List installed skills
specify skill list
specify skill list --outdated
specify skill list --json

# Evaluate skill quality
specify skill eval ./my-skill --review      # 100-point structure score
specify skill eval ./my-skill --task        # Behavioral impact testing
specify skill eval ./my-skill --full        # Complete evaluation

# Update skills
specify skill update react-best-practices
specify skill update --all

# Manage team skills
specify skill sync-team --dry-run            # Preview changes
specify skill sync-team                      # Apply changes
specify skill check-updates

# Configure skills
specify skill config auto_activation_threshold 0.8
specify skill config max_auto_skills 5

#### Project Initialization

```bash
# Basic project initialization
specify init my-project

# Initialize with specific AI assistant
specify init my-project --ai claude

# Initialize with Cursor support
specify init my-project --ai cursor-agent

# Initialize with Qoder support
specify init my-project --ai qoder

# Initialize with Windsurf support
specify init my-project --ai windsurf

# Initialize with Amp support
specify init my-project --ai amp

# Initialize with SHAI support
specify init my-project --ai shai

# Initialize with IBM Bob support
specify init my-project --ai bob

# Initialize with PowerShell scripts (Windows/cross-platform)
specify init my-project --ai copilot --script ps

# Initialize in current directory
specify init . --ai copilot
# or use the --here flag
specify init --here --ai copilot

# Force merge into current (non-empty) directory without confirmation
specify init . --force --ai copilot
# or
specify init --here --force --ai copilot

# Skip git initialization
specify init my-project --ai gemini --no-git

# Enable debug output for troubleshooting
specify init my-project --ai claude --debug

# Use GitHub token for API requests (helpful for corporate environments)
specify init my-project --ai claude --github-token ghp_your_token_here

# Initialize with team AI directives and issue tracker integration
specify init my-project --ai claude --team-ai-directives https://github.com/your-org/team-ai-directives.git --issue-tracker github

# Initialize with async agent support for autonomous task execution
specify init my-project --ai claude --async-agent jules

# Complex example: Enterprise setup with all integrations
specify init enterprise-app --ai claude --script sh --team-ai-directives https://github.com/company/team-ai-directives.git --issue-tracker jira --async-agent jules --github-token $GH_TOKEN

# Check system requirements
specify check

# Workflow mode management is per-feature during specification
/spec.specify --mode build "Quick prototype feature"      # Create feature in build mode
/spec.specify --mode spec "Complex feature"                # Create feature in spec mode (default)
/spec.specify --mode build --tdd "Feature with tests"     # Build mode with TDD enabled
```

### Available Slash Commands

After running `specify init`, your AI coding agent will have access to these slash commands for structured development:

#### Core Commands

Essential commands for the Spec-Driven Development workflow:

| Command                  | Description                                                           |
|--------------------------|-----------------------------------------------------------------------|
| `/architect.specify`  | Interactive PRD exploration to create system-level ADRs |
| `/architect.clarify`  | Refine ADRs through targeted clarification questions |
| `/architect.init`     | Reverse-engineer architecture from existing codebase (brownfield) |
| `/architect.implement`| Generate full Architecture Description (AD.md) from ADRs |
| `/spec.constitution`  | Create or update project governing principles and development guidelines |
| `/spec.specify`       | Define what you want to build (requirements and user stories)        |
| `/spec.plan`          | Create technical implementation plans with your chosen tech stack & SYNC/ASYNC triage          |
| `/spec.tasks`         | Generate actionable task lists for implementation     |
| `/spec.implement`     | Execute all tasks to build the feature according to the plan with dual execution loops (SYNC/ASYNC modes)           |
| `/spec.trace`         | Generate AI session execution traces with decisions, patterns, and evidence (optional, enriches `/levelup`) |
| `/spec.levelup`       | Capture learnings and contribute to team knowledge repository        |

#### Optional Commands

Additional commands for enhanced quality and validation:

| Command              | Description                                                                                                                          |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `/spec.clarify`   | Clarify underspecified areas (recommended before `/spec.plan`; formerly `/quizme`)                                                |
| `/spec.analyze`   | Cross-artifact consistency & coverage analysis (run after `/spec.tasks`, before `/spec.implement`)                             |
| `/spec.checklist` | Generate custom quality checklists that validate requirements completeness, clarity, and consistency (like "unit tests for English") |

### Environment Variables

| Variable          | Description                                                                                                                                                                                                                                                                                            |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `SPECIFY_FEATURE` | Override feature detection for non-Git repositories. Set to the feature directory name (e.g., `001-photo-albums`) to work on a specific feature when not using Git branches.<br/>\*\*Must be set in the context of the agent you're working with prior to using `/spec.plan` or follow-up commands. |

## 📚 Core Philosophy

Spec-Driven Development is a structured process that emphasizes:

- **Intent-driven development** where specifications define the "*what*" before the "*how*"
- **Rich specification creation** using guardrails and organizational principles
- **Multi-step refinement** rather than one-shot code generation from prompts
- **Heavy reliance** on advanced AI model capabilities for specification interpretation

### Alignment with Agentic SDLC 12 Factors

This methodology aligns with the [Agentic SDLC 12 Factors](https://tikalk.github.io/agentic-sdlc-12-factors/) framework, which provides foundational principles for building software with AI coding agents. Key alignments include:

- **Factor I: Strategic Mindset** - Intent-driven development with clear specifications
- **Factor II: Context Scaffolding** - Rich organizational principles and guardrails
- **Factor III: Mission Definition** - Structured specification creation process
- **Factor IV: Structured Planning** - Multi-step refinement with technical planning
- **Factor V: Dual Execution Loops** - SYNC/ASYNC execution modes for different development phases
- **Factor VI: The Great Filter** - Quality gates and validation checkpoints
- **Factor VII: Adaptive Quality Gates** - Flexible quality assurance based on project needs
- **Factor VIII: AI-Augmented, Risk-Based Testing** - Intelligent testing strategies
- **Factor IX: Traceability** - End-to-end artifact traceability
- **Factor X: Strategic Tooling** - Purpose-built tools for AI-assisted development
- **Factor XI: Directives as Code** - Team AI directives for consistent behavior
- **Factor XII: Team Capability** - Knowledge sharing and continuous improvement

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
- [Supported](#-supported-ai-agents) AI coding agent.
- [uv](https://docs.astral.sh/uv/) for package management
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

You will be prompted to select the AI agent you are using. You can also proactively specify it directly in the terminal:

```bash
specify init <project_name> --ai claude
specify init <project_name> --ai gemini
specify init <project_name> --ai copilot

# Or in current directory:
specify init . --ai claude
specify init . --ai codex

# or use --here flag
specify init --here --ai claude
specify init --here --ai codex

# Force merge into a non-empty current directory
specify init . --force --ai claude

# or
specify init --here --force --ai claude
```

The CLI will check if you have Claude Code, Gemini CLI, Cursor CLI, Qwen CLI, opencode, Codex CLI, Qoder CLI, or Amazon Q Developer CLI installed. If you do not, or you prefer to get the templates without checking for the right tools, use `--ignore-agent-tools` with your command:

```bash
specify init <project_name> --ai claude --ignore-agent-tools
```

### **STEP 1:** Establish project principles

Go to the project folder and run your AI agent. In our example, we're using `claude`.

![Bootstrapping Claude Code environment](./media/bootstrap-claude-code.gif)

You will know that things are configured correctly if you see the `/spec.constitution`, `/spec.specify`, `/spec.plan`, `/spec.tasks`, and `/spec.implement` commands available.

The first step should be establishing your project's governing principles using the `/spec.constitution` command. This helps ensure consistent decision-making throughout all subsequent development phases:

```text
/spec.constitution Create principles focused on code quality, testing standards, user experience consistency, and performance requirements. Include governance for how these principles should guide technical decisions and implementation choices.
```

This step creates or updates the `.specify/memory/constitution.md` file with your project's foundational guidelines that the AI agent will reference during specification, planning, and implementation phases.

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
└── .specify
    ├── memory
    │  └── constitution.md
    ├── scripts
    │  ├── check-prerequisites.sh
    │  ├── common.sh
    │  ├── create-new-feature.sh
    │  ├── setup-plan.sh
    │  └── update-claude-md.sh
    ├── specs
    │  └── 001-create-taskify
    │      └── spec.md
    └── templates
        ├── plan-template.md
        ├── spec-template.md
        └── tasks-template.md
```

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
├── CLAUDE.md
├── memory
│  └── constitution.md
├── scripts
│  ├── check-prerequisites.sh
│  ├── common.sh
│  ├── create-new-feature.sh
│  ├── setup-plan.sh
│  └── update-claude-md.sh
├── specs
│  └── 001-create-taskify
│      ├── contracts
│      │  ├── api-spec.json
│      │  └── signalr-spec.md
│      ├── data-model.md
│      ├── plan.md
│      ├── quickstart.md
│      ├── research.md
│      └── spec.md
└── templates
    ├── CLAUDE-template.md
    ├── plan-template.md
    ├── spec-template.md
    └── tasks-template.md
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
> Before you have the agent implement it, it's also worth prompting Claude Code to cross-check the details to see if there are any over-engineered pieces (remember - it can be over-eager). If over-engineered components or decisions exist, you can ask Claude Code to resolve them. Ensure that Claude Code follows the [constitution](base/memory/constitution.md) as the foundational piece that it must adhere to when establishing the plan.

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
> The AI agent will execute local CLI commands (such as `dotnet`, `npm`, etc.) - make sure you have the required tools installed on your machine.

Once the implementation is complete, test the application and resolve any runtime errors that may not be visible in CLI logs (e.g., browser console errors). You can copy and paste such errors back to your AI agent for resolution.

</details>

---

## 🔍 Troubleshooting

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

## 👥 Maintainers

### Original Repository

- Den Delimarsky ([@localden](https://github.com/localden))
- John Lam ([@jflam](https://github.com/jflam))

### Fork Maintainers (tikalk/agentic-sdlc-spec-kit)

- Lior Kanfi ([@kanfil](https://github.com/kanfil))

## 💬 Support

For support, please open a [GitHub issue](https://github.com/tikalk/agentic-sdlc-spec-kit/issues/new). We welcome bug reports, feature requests, and questions about using Spec-Driven Development.

## 🙏 Acknowledgements

This project is heavily influenced by and based on the work and research of [John Lam](https://github.com/jflam).

## 📄 License

This project is licensed under the terms of the MIT open source license. Please refer to the [LICENSE](./LICENSE) file for the full terms.
