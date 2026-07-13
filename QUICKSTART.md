# Agentic SDLC: Quick Start Guide

Welcome to the team! This guide will get you up and running with our Agentic Software Development Lifecycle (SDLC) workflow using the Spec Kit and Team AI Directives.

## Overview

We follow **Spec-Driven Development (SDD)** — a methodology where specifications drive implementation. Instead of writing code directly from prompts, we create structured specifications first, then generate implementation plans, and finally execute tasks systematically.

**Key Benefits:**
- Clear, shared understanding before coding begins
- Traceability from requirements to implementation
- Consistent quality through structured workflows
- Captured team knowledge for reuse

---

## Table of Contents

1. [Prerequisites & Installation](#1-prerequisites--installation)
2. [Project Initialization](#2-project-initialization)
3. [Project Constitution (One-Time)](#3-project-constitution-one-time)
4. [Daily Workflow](#4-daily-workflow)
5. [Feature Development](#5-feature-development)
6. [Team Knowledge Capture](#6-team-knowledge-capture)
7. [Quick Reference](#7-quick-reference)

---

## 1. Prerequisites & Installation

### Install Required Tools

**uv** (Python package manager):
```bash
pip install uv
```

**Agentic SDLC Specify CLI**:
```bash
uv tool install agentic-sdlc-specify-cli --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git
```

Verify installation:
```bash
specify version
```

### Supported AI Coding Agents

Our workflow supports multiple AI agents. Choose your preferred tool:

| Agent | IDE/CLI | Setup |
|-------|---------|-------|
| **GitHub Copilot** | VS Code / IDE | Built-in |
| **Cursor** | Cursor IDE | `--ai cursor-agent` |
| **Claude Code** | CLI | `--ai claude` |
| **Windsurf** | Windsurf IDE | `--ai windsurf` |
| **Codex** | CLI | `--ai codex --ai-skills` |

> **Note:** During initialization, you'll be prompted to select your AI agent. The Spec Kit will configure the appropriate templates and commands for your choice.

---

## 2. Project Initialization

### For New Projects

Initialize a new project with team AI directives:

```bash
# Create and enter project directory
mkdir my-project
cd my-project

# Initialize with team-ai-directives
specify init . --team-ai-directives <DIRECTIVES_URL>
```

### For Existing Projects

Initialize in an existing codebase:

```bash
cd existing-project

# Force init in non-empty directory
specify init . --force --team-ai-directives <DIRECTIVES_URL>
```

### Private Repository Access

If your team-ai-directives repository is private, configure authentication:

**1. Create `~/.specify/auth.json`:**

```bash
mkdir -p ~/.specify
cat > ~/.specify/auth.json << 'EOF'
{
  "providers": [
    {
      "hosts": ["github.com", "api.github.com", "raw.githubusercontent.com"],
      "provider": "github",
      "auth": "bearer",
      "token_env": "GITHUB_TOKEN"
    }
  ]
}
EOF
```

**2. Set your token:**

```bash
# Generate token at https://github.com/settings/tokens
export GITHUB_TOKEN=$(gh auth token)
echo $GITHUB_TOKEN
```

**For GitLab:** Replace the provider with:
```json
{
  "hosts": ["gitlab.com"],
  "provider": "gitlab",
  "auth": "bearer",
  "token_env": "GITLAB_TOKEN"
}
```
And use `export GITLAB_TOKEN=your_token_here`

### Available Team AI Directives

Ask your team lead for the correct directives URL. Common formats:

```bash
# From a release tag (recommended for stability)
specify init . --team-ai-directives https://github.com/YOUR_ORG/team-ai-directives/archive/refs/tags/v1.0.0.zip

# From main branch (latest, may change)
specify init . --team-ai-directives https://github.com/YOUR_ORG/team-ai-directives/archive/refs/heads/main.zip

# From a local directory (for development)
specify init . --team-ai-directives ~/workspace/team-ai-directives
```

Accepted sources are a local directory, a GitHub/GitLab archive URL, or a direct `.zip`/`.tar.gz` URL. Plain `.git` clone URLs are not supported.

---

## 3. Project Constitution (One-Time)

The **Constitution** defines your project's core principles, standards, and guidelines. Create it once per project.

### Create Constitution

Open your AI assistant in the IDE and run:

```
/spec.constitution
```

Or with specific focus areas:

```
/spec.constitution Create principles focused on code quality, testing standards, API design consistency, and security requirements
```

### Verify Constitution

Check that the file was created at:
```
.specify/memory/constitution.md
```

The constitution guides all subsequent development decisions in the project.

---

## 4. Daily Workflow

For quick tasks or experiments, use the **Mission Brief** workflow:

### Create Mission Brief

```
/quick.implement "<Your task description>"
```

Example:
```
/quick.implement "Create a utility function to parse ISO dates with timezone handling"
```

### Review and Approve

The Mission Brief provides:
- Quick specification
- Implementation approach
- Verification criteria

Review the generated brief and proceed with implementation.

---

## 5. Feature Development

For full features, follow the complete SDD workflow:

### Step 1: Create Specification

Define what you want to build (focus on **what** and **why**, not **how**):

```
/spec.specify "<Feature description>"
```

Example:
```
/spec.specify "Build a user authentication system with email/password login, password reset, and session management"
```

This creates:
- Feature branch
- `specs/[feature]/spec.md` with structured requirements
- User stories and acceptance criteria

### Step 2: Clarify Ambiguities

Debug the specification to identify and resolve misunderstandings:

```
/spec.clarify
```

Review the output and address any `[NEEDS CLARIFICATION]` markers.

### Step 3: Create Implementation Plan

Provide your tech stack and architecture choices:

```
/spec.plan "<Technical approach>"
```

Example:
```
/spec.plan "Use JWT for session management, bcrypt for password hashing, PostgreSQL for user storage. Implement in Python with FastAPI."
```

This generates:
- `specs/[feature]/plan.md` — Technical implementation plan
- `specs/[feature]/data-model.md` — Data schemas
- `specs/[feature]/contracts/` — API contracts
- `specs/[feature]/research.md` — Technical research

### Step 4: Generate Tasks

Convert the plan into executable tasks:

```
/spec.tasks
```

This creates `specs/[feature]/tasks.md` with:
- Numbered tasks with checkboxes
- Parallel execution markers `[P]`
- Dependencies between tasks

In worktree mode, task generation also produces `specs/[feature]/tasks_dag.json` for wave-based execution.

### Step 5: Implement

Execute all tasks:

```
/spec.implement
```

In branch mode, this uses the existing `[SYNC]`/`[ASYNC]` sequential flow. In worktree mode, it reads `tasks_dag.json` to run tasks in waves with isolated task branches (`git.task`, `git.task-merge`).

Or implement a specific task:

```
/spec.implement "Task 3: Create user database schema"
```

### Step 6: Validate

Verify your implementation against the specification:

```
/spec.analyze
```

This checks for consistency between your implementation and the original spec.

---

## 6. Team Knowledge Capture

When you make significant architectural decisions or solve complex problems, capture that knowledge for the team.

### Extract Core Decisions

```
/levelup.specify "<Decision or pattern description>"
```

Example:
```
/levelup.specify "We decided to use repository pattern with dependency injection for database access to enable easier testing"
```

### Clarify and Refine

```
/levelup.clarify
```

### Build Reusable Skill

Define a name for the skill:

```
/levelup.skills <skill-name>
```

Example:
```
/levelup.skills repository-pattern
```

### Create Pull Request

Package the skill and open a PR to the team-ai-directives repository:

```
/levelup.implement
```

---

## 7. Quick Reference

### Essential Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/spec.constitution` | Create project principles | Once per project |
| `/quick.implement` | Quick task/experiment | Daily workflow |
| `/spec.specify` | Create feature specification | Feature development |
| `/spec.clarify` | Debug specification | After spec creation |
| `/spec.plan` | Create implementation plan | After spec is clear |
| `/spec.tasks` | Generate task list | After plan is ready |
| `/spec.taskstoissues` | Convert tasks to tracker issues (GitHub, GitLab, Linear, Jira) | After tasks are ready |
| `/spec.implement` | Execute implementation | During development |
| `/spec.converge` | Assess codebase against spec; if converged, run test gate and 4-pillar assessment | After implementation |
| `/spec.analyze` | Validate implementation | After implementation |
| `/levelup.specify` | Capture team knowledge | After significant decisions |
| `/change.specify` | Create lightweight change proposal | Non-feature code changes |
| `/change.implement` | Execute change proposal tasks | After change spec creation |
| `/change.converge` | Assess change scope and verify completeness | After change implementation |
| `/change.levelup` | Levelup from a completed change | After change completion |

### File Structure

```
.specify/
├── memory/
│   └── constitution.md          # Project principles
├── scripts/
│   └── bash/
│       ├── common.sh
│       ├── create-new-feature.sh
│       └── setup-tasks.sh
├── templates/
│   ├── plan-template.md
│   ├── spec-template.md
│   └── tasks-template.md
├── taskstoissues-provider.yml  # Issue tracker config (uncomment your provider)
└── extensions/
    └── team-ai-directives/      # Team AI directives
        ├── context_modules/
        │   ├── constitution.md  # Team principles
        │   ├── personas/        # Role definitions
        │   └── rules/           # Domain rules
        └── skills/              # Reusable skills
specs/
└── [feature-branch]/
    ├── spec.md                  # Feature specification
    ├── plan.md                  # Implementation plan
    ├── tasks.md                 # Task list
    ├── data-model.md            # Data schemas
    ├── research.md              # Technical research
    ├── contracts/               # API contracts
    └── quickstart.md            # Validation guide
changes/
└── [NNN-name]/
    ├── spec.md                  # Change proposal spec
    ├── plan.md                  # Technical approach (optional)
    └── tasks.md                 # Implementation tasks
```

### Team AI Directives Integration

Your project includes the bundled `team-ai-directives` extension installed at `.specify/extensions/team-ai-directives/`. The actual team knowledge-base path you provided during init is stored in `.specify/init-options.json` under `team_ai_directives`. If you supplied a local directory, the knowledge-base content remains at that original path. These provide:

- **Constitution** — Team-wide principles
- **Personas** — Role-specific guidance (DevOps, Java, Python, etc.)
- **Rules** — Domain-specific patterns and standards
- **Skills** — Reusable capabilities

Available commands from team-ai-directives:

```bash
# Verify extension installation
specify run adlc.team-ai-directives.verify

# Auto-discover relevant context
specify run adlc.team-ai-directives.discover

# Browse and install team skills
specify run adlc.team-ai-directives.skills
```

When discovery is used as part of the spec workflow, the extension-owned persisted artifact
lives at:

- `specs/<feature>/team-context.md`

If discovery runs before the feature directory exists, the workflow stages the payload at:

- `.specify/drafts/team-context.md`

### Getting Help

1. **Check project documentation**: Look for `AGENTS.md` and `README.md` in your project
2. **Review team-ai-directives**: Explore `.specify/extensions/team-ai-directives/`
3. **Consult team lead**: For organization-specific questions
4. **Spec Kit documentation**: Visit [Agentic SDLC Spec Kit](https://github.com/tikalk/agentic-sdlc-spec-kit)

---

## Next Steps

1. ✅ Install tools (uv, specify CLI)
2. ✅ Initialize your project with team-ai-directives
3. ✅ Create project constitution
4. ✅ Try the `/quick.implement` workflow on a small task
5. ✅ Develop your first feature using the full SDD workflow

**Welcome to the team! 🚀**

For detailed methodology, see [Spec-Driven Development](./spec-driven.md).
