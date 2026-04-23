# Team AI Directives Starter Kit

A forkable foundation for version-controlled AI agent behavior.

**Built on the [Twelve-Factor Agentic SDLC](https://github.com/tikalk/agentic-sdlc-12-factors)** — this repository implements Factor XI: Directives as Code, treating all AI instructions as version-controlled assets.

**Quick Start:** See [GETTING_STARTED.md](GETTING_STARTED.md) for a 5-minute setup guide.

## Installation

This repository can be installed in two ways:

### Option 1: As a Spec Kit Extension (Recommended)

Install via the spec-kit CLI using the `--team-ai-directives` flag:

```bash
# Initialize project with team-ai-directives
specify init <project> --team-ai-directives https://github.com/your-org/team-ai-directives.git
```

The directives are installed to `.specify/extensions/team-ai-directives/` and available to all AI agents via the extension system.

```bash
# Or from a specific release tag
specify init <project> --team-ai-directives https://github.com/your-org/team-ai-directives/archive/refs/tags/v1.1.0.zip
```

### Option 2: Fork and Clone (Legacy)

Fork this repository and clone it locally:

```bash
git clone https://github.com/your-org/team-ai-directives.git
cd team-ai-directives
```

Then reference it in your project initialization or configuration.

## Who This Is For

- Engineering teams wanting consistent AI agent behavior
- Platform teams building developer self-service with AI
- Consultancies creating reusable AI patterns across clients
- Organizations adopting the Agentic SDLC methodology

## What's Included

This repository provides the building blocks for teaching AI agents how your team works:

- **Constitution** - Core principles that govern all AI behavior
- **Personas** - Role-specific guidance (DevOps, Java, Python, Data, Platform)
- **Rules** - Domain-specific patterns (security, testing, style guides)
- **Skills** - Self-contained capabilities with trigger-based activation
- **MCP** - Model Context Protocol integration for GitHub and other tools

## Repository Layout

```text
team-ai-directives/
├── AGENTS.md                  # Instructions for AI agents on how to use this repo
├── README.md                  # This file (for humans)
├── GETTING_STARTED.md         # Quick start guide
├── CONTRIBUTING.md            # Contribution guidelines
├── CHANGELOG.md               # Version history
├── CDR.md                     # Context Directive Records (approved contributions)
├── .mcp.json                  # MCP server configuration
├── .skills.json               # Skills registry and policy
├── context_modules/           # The knowledge library
│   ├── constitution.md        # Core principles
│   ├── personas/              # Role-specific guidance
│   ├── rules/                 # Domain-specific patterns
│   │   ├── style_guides/
│   │   ├── security/
│   │   └── testing/
│   └── examples/              # Code examples and prompt templates
│       ├── testing/
│       └── prompts/
└── skills/                    # Self-contained agent capabilities
    └── {skill-name}/
        ├── SKILL.md           # Main instructions with YAML frontmatter
        ├── references/        # Supporting content
        └── scripts/           # Automation (optional)
```

## How It Works

1. **AI agents read `AGENTS.md`** for instructions on using this repo
2. **Constitution** provides foundational principles
3. **Personas** provide role-specific guidance with rule references
4. **Skills** are triggered by user requests (matched via `.skills.json`)
5. **Rules** are accessed through personas, not directly from skills

---

## MCP Configuration

This section explains what the Model Context Protocol (MCP) is, how to configure it in this repo, and how to get an AI agent to use it effectively.

### What is an MCP?

**MCP** stands for **Model Context Protocol**. Think of it as a standardized plug-in system that lets AI agents talk to external tools and services — like GitHub, Linear, or a database — without you having to write custom integration code each time.

Without MCP, an AI agent can only work with text you paste into the conversation. With MCP, the agent gains live, structured access to real systems.

### Analogy

Imagine a highly skilled contractor who can only work with the blueprints you hand them. MCP is like giving that contractor a badge that lets them walk into the building, read the plans on-site, open pull requests, and file issues — in real time.

### Key concepts

| Term | What it means |
| --- | --- |
| **MCP server** | A small process that wraps an external tool (GitHub, a database, etc.) and exposes its actions over a standard protocol |
| **MCP client** | The AI agent or IDE extension that connects to MCP servers and calls their actions |
| **`.mcp.json`** | The config file that tells your AI client which MCP servers to start and how to reach them |
| **Tool / action** | A specific capability an MCP server exposes, e.g. "create a pull request" or "list open issues" |

### How to Configure the GitHub MCP

#### Prerequisites

- A GitHub account with a [Personal Access Token (PAT)](https://github.com/settings/tokens) that has `repo` scope (or fine-grained permissions for the repos you need).
- Node.js 18+ installed (used to run MCP servers via `npx`).

#### Step 1 — Export your token

```bash
export GITHUB_TOKEN=ghp_your_token_here
```

Add this to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.) so it persists across sessions. Alternatively, use `.envrc` files with [direnv](https://direnv.net/) to automatically load project-specific environment variables.

#### Step 2 — Edit `.mcp.json`

At the root of this repo there is a `.mcp.json` file. Update it with your organization and repository:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  },
  "tools": {
    "github": {
      "type": "github",
      "tokenEnv": "GITHUB_TOKEN",
      "owner": "YOUR_ORG_OR_USERNAME",
      "repo": "YOUR_REPO_NAME",
      "baseUrl": "https://api.github.com"
    }
  }
}
```

Replace `YOUR_ORG_OR_USERNAME` and `YOUR_REPO_NAME` with your actual values.

> **GitHub Enterprise users:** Change `baseUrl` to your enterprise API endpoint, e.g. `https://github.example.com/api/v3`.

### How the GitHub MCP Can Be Used

Once configured, the GitHub MCP gives your AI agent real-time, read/write access to GitHub. Here is a sample of what it can do:

#### Reading & discovery

- List open issues and pull requests
- Read file contents from any branch or commit
- Search for code, issues, or commits across a repository
- Fetch PR review comments and CI status checks

#### Writing & collaboration

- Create issues with labels, assignees, and milestones
- Open pull requests from a source branch to a target branch
- Post review comments on a specific PR
- Merge a pull request (when conditions are met)

#### Workflow automation

- Trigger GitHub Actions workflows via the API
- Query commit history and blame information
- Create or update files directly in a branch

This makes the agent a first-class participant in your engineering workflow rather than a passive code-suggestion tool.

### Getting an Agent to Use the GitHub MCP

The GitHub MCP is available automatically once `.mcp.json` is configured and your IDE or agent runtime is connected. You interact with it through natural language — the agent decides which MCP tool to call based on your request.

#### Example prompts and what the agent does

**Reading the current state of a repository**

> "What are the open pull requests in this repo?"

The agent calls the GitHub MCP to list open PRs and returns a summary with titles, authors, and links.

**Creating an issue**

> "Create a GitHub issue titled 'Add retry logic to the payment service'. Label it `enhancement` and assign it to @alice."

The agent calls the MCP `create_issue` action with the supplied fields and returns the new issue URL.

**Reviewing a pull request**

> "Summarize PR #42 and tell me if there are any unresolved review comments."

The agent fetches the PR diff and all review threads via the MCP, then gives you a plain-English summary.

**Automating a full feature cycle**

> "I've just finished the feature on branch `feature/retry-logic`. Open a PR against `main`, write a description based on the commit history, and request review from @bob."

The agent:
1. Reads the commit log on `feature/retry-logic` via the MCP.
2. Generates a PR description.
3. Calls `create_pull_request` with the generated title and description.
4. Requests a review from `@bob`.

**Incorporating the GitHub MCP into a directive**

You can bake GitHub MCP usage into an agent directive or skill so the agent uses it automatically without being asked each time. For example, in a skill file:

```markdown
## Instructions

1. Before writing any code, search for related open issues using the GitHub MCP.
2. After completing a task, create a GitHub issue summarizing what was done and any follow-up items.
3. If the user asks you to "ship it", open a pull request against `main` with a generated description.
```

### Working with Multiple Repos

The MCP is not limited to one repo. The `owner` and `repo` fields in `.mcp.json` set a **default context hint** for the agent — they are not an API-level restriction. Every GitHub MCP tool (`get_file_contents`, `search_code`, `create_issue`, etc.) accepts `owner` and `repo` as parameters on each individual call. As long as your `GITHUB_TOKEN` has access to a repository, the agent can read from and write to it.

One GitHub MCP server instance handles all repos the token can reach. You do not need a separate MCP server entry per repository.

#### Token permissions

When working across multiple repos:

- A **classic PAT** with `repo` scope works across all repos the account can access.
- A **fine-grained PAT** must explicitly list each repo it is allowed to access — scope it to only the repos your agent needs.
- For organization repos, ensure the token has been granted SSO authorization if your org enforces SAML SSO.

---

## Personas

Personas define the role, expertise, preferences, and rule references that shape how an AI agent behaves for a given engineering context. Loading a persona tells the agent _who_ it is for this session — its values, collaboration style, and which domain-specific rules to apply.

### How Personas Work

When an agent begins a session, it loads context in this order:

1. **Constitution** (`context_modules/constitution.md`) — non-negotiable team principles applied to every interaction.
2. **Persona** (`context_modules/personas/*.md`) — role-specific defaults, rules, and collaboration style.
3. **Skills** (`skills/*/SKILL.md`) — on-demand capabilities triggered by the user's request.

A persona sits between the universal constitution and the task-specific skill. It tells the agent:
- What domain knowledge to prioritize
- Which rule files are relevant to its role
- How to collaborate (communication style, review preferences, workflow assumptions)
- Agent-specific guidance (e.g., always propose infra changes as code)

Personas are **passive by default** — they don't activate automatically unless your tooling or prompt instructs the agent to load one. You attach a persona to an agent through your IDE settings, a system prompt, or a prompt prefix.

### Persona Folder Structure

All personas live in `context_modules/personas/`:

```
context_modules/personas/
├── cloud_native_platform_architect.md
├── data_analyst.md
├── devops_engineer.md
├── senior_java_developer.md
└── senior_python_developer.md
```

Each persona is a single Markdown file. There is no sub-folder nesting — one file per role.

### Persona File Anatomy

A well-formed persona file contains some or all of the following sections:

#### `# Persona: <Name>` (required)

The heading names the persona. Agents use this as the persona identifier.

```markdown
# Persona: DevOps Engineer
```

#### `## Summary` (required)

Describes the persona's **motivation**, **pain points**, and **success criteria**. This is the first context an agent reads to understand its role.

```markdown
## Summary
- **Motivation**: Enable reliable, scalable, and secure software delivery through automation, IaC, and observability.
- **Pain Points**: Manual deployments, configuration drift, lack of visibility.
- **Success Criteria**: Fully automated CI/CD pipelines, declarative infrastructure, secure secret management.
```

#### `## Rule References` (recommended)

Links the persona to domain-specific rule files using the `@rule:<path>` syntax. Agents resolve these paths relative to `context_modules/rules/`.

```markdown
## Rule References
- CI/CD Pipelines: @rule:devops/github_actions.md
- Secrets Management: @rule:devops/external_secrets_operator.md, @rule:devops/secrets_management_dry.md
- Testing: @rule:testing/python_testing.md
```

#### `## Collaboration Preferences` (recommended)

Describes how the persona prefers to work: communication style, review expectations, workflow assumptions, and advocacy positions.

```markdown
## Collaboration Preferences
- Prefers infrastructure changes reviewed through pull requests with clear descriptions
- Values declarative configurations over imperative scripts
- Expects "everything as code" — infrastructure, configs, and pipelines in version control
```

#### `## Tool Context` (optional)

Lists the tooling ecosystem this persona operates in. Helps agents make appropriate technology choices without asking the user every time.

```markdown
## Tool Context
- CI: GitHub Actions, GitLab CI
- CD/GitOps: ArgoCD, Flux
- IaC: Terraform, Crossplane
- Secrets: HashiCorp Vault, AWS Secrets Manager
```

#### `## Guidance for Agents` (optional)

Explicit behavioral instructions for agents taking actions on behalf of this persona.

```markdown
## Guidance for Agents
- Always propose infrastructure changes as code, never manual operations
- When working with secrets, always use secret management services — never hardcode or commit secrets
- Always consider disaster recovery, backup strategies, and rollback procedures
```

### Built-In Personas

| File | Persona | Primary Domain |
|---|---|---|
| `senior_python_developer.md` | Senior Python Developer | Python, PEP 8, testing, CI/CD |
| `senior_java_developer.md` | Senior Java Developer | Java, Spring Boot, JUnit 5, Google Style |
| `devops_engineer.md` | DevOps Engineer | CI/CD, Helm, IaC, secrets management, GitOps |
| `cloud_native_platform_architect.md` | Cloud-Native Platform Architect | Kubernetes, Crossplane, ArgoCD, platform engineering |
| `data_analyst.md` | Data Analyst | SQL, dashboards, reproducible reporting, large datasets |

Each built-in persona is self-contained and production-ready. Fork and adjust them to match your team's specific tooling and standards.

### Creating a Custom Persona

1. Create a new file in `context_modules/personas/`:

   ```bash
   touch context_modules/personas/my_role.md
   ```

2. Add the following template and fill it in:

   ```markdown
   # Persona: My Role

   ## Summary
   - **Motivation**: [What drives this role]
   - **Pain Points**: [What slows them down]
   - **Success Criteria**: [What good looks like]

   ## Rule References
   - [Domain]: @rule:[domain]/[rule-file].md

   ## Collaboration Preferences
   - [How this persona prefers to work]

   ## Tool Context
   - [Tools and platforms this persona uses]

   ## Guidance for Agents
   - [Behavioral instructions for autonomous actions]
   ```

3. Reference any applicable rule files from `context_modules/rules/`. Browse the available rules:

   ```
   context_modules/rules/
   ├── devops/
   ├── framework/
   ├── orchestration/
   ├── security/
   ├── style-guides/
   └── testing/
   ```

4. Attach the persona in your agent configuration.

### Using Personas

#### Option A: IDE Custom Instructions (GitHub Copilot)

In VS Code with GitHub Copilot, add the persona content directly to a `.github/copilot-instructions.md` file or reference it in your workspace settings:

```json
// .vscode/settings.json
{
  "github.copilot.chat.codeGeneration.instructions": [
    { "file": "context_modules/personas/devops_engineer.md" }
  ]
}
```

#### Option B: System Prompt Prefix

Prepend the persona content to your agent's system prompt:

```
[Load persona: context_modules/personas/devops_engineer.md]

User request: ...
```

#### Option C: Prompt Reference at Session Start

Tell the agent explicitly which persona to adopt at the start of a conversation:

```
You are acting as the DevOps Engineer persona defined in
context_modules/personas/devops_engineer.md. Load that file
and apply it to all responses in this session.
```

### Personas vs. Skills

| | Persona | Skill |
|---|---|---|
| **Purpose** | Defines _who_ the agent is | Defines _what_ the agent can do |
| **Scope** | Entire session | Triggered per task |
| **Location** | `context_modules/personas/` | `skills/*/SKILL.md` |
| **Activation** | Loaded at session start | Loaded on-demand by trigger phrases |
| **Registered in `.skills.json`?** | No | Yes |
| **Contains rules?** | References rules via `@rule:` | May embed rules inline |

A persona provides the stable identity and preferences for a session. Skills provide the domain-specific execution instructions for individual tasks. They complement each other and are both loaded alongside the constitution.

---

## Skills

Skills are self-contained, reusable AI agent capabilities. Each skill packages a domain's instructions, context, and optional automation so an AI agent can reliably apply it on demand without requiring the user to supply background knowledge each time.

### How Skills Work

When a user makes a request, an agent:

1. Reads `.skills.json` to discover available skills.
2. Matches the user's intent against each skill's `description` and trigger phrases.
3. Loads the relevant `SKILL.md` to obtain domain-specific instructions.
4. Optionally loads files from `references/` for deeper context.
5. Applies the skill while completing the task.

Skills are loaded **on-demand** — only the skills relevant to the current request are activated. Required skills defined in `.skills.json` are always available to the agent.

### Skill Folder Structure

All internal skills live under `skills/{skill-name}/`:

```
skills/
└── my-skill/
    ├── SKILL.md          # Required — primary instructions for the agent
    ├── references/       # Optional — supplementary reference documents
    │   ├── guide.md
    │   └── patterns.md
    └── scripts/          # Optional — automation scripts for the skill
        └── setup.sh
```

#### `SKILL.md`

The entry point for every skill. It uses a YAML front matter block to declare metadata, followed by Markdown instructions:

```yaml
---
name: my-skill
description: >
  Short description of the skill's purpose.
  Use when [trigger phrases that describe when to activate this skill].
---

# My Skill

## What This Skill Provides
...

## When to Use This Skill
...

## Core Patterns
...
```

The `description` field is critical — it tells the agent **when** to activate the skill. Write it in natural language and include representative phrases a user might say.

### The `.skills.json` Manifest

`.skills.json` is the single source of truth for skill discovery and policy. It defines which skills are required, recommended, internal, blocked, or available in the registry.

```json
{
  "version": "1.0.0",
  "source": "team-ai-directives",
  "description": "Team skills manifest for the Skills Package Manager.",
  "skills": {
    "required": { ... },
    "recommended": { ... },
    "internal": { ... },
    "blocked": [ ... ]
  },
  "registry": {
    "description": "Additional skills available for manual discovery.",
    "skills": { ... }
  },
  "policy": { ... }
}
```

#### Skill Categories in `.skills.json`

| Category | Meaning |
|---|---|
| `required` | Always loaded by the agent; auto-installed if `auto_install_required` is `true` |
| `recommended` | Suggested skills; surfaced to the agent but not mandatory |
| `internal` | Skills hosted locally in this repository |
| `blocked` | Skills explicitly prohibited; the agent must refuse to use them |
| `registry` | Additional skills available for on-demand discovery and installation |

#### Skill Entry Format

Each skill entry in the manifest uses a URI as its key:

- **Local skill**: `"local:./skills/my-skill"`
- **External skill**: `"github:org/repo/skill-name"`

```json
"local:./skills/my-skill": {
  "version": "*",
  "description": "Human-readable description of what the skill does.",
  "categories": ["tag1", "tag2"]
}
```

External skills add `source` and `url` fields pointing to the raw `SKILL.md`:

```json
"github:org/repo/skill-name": {
  "version": "^1.0.0",
  "description": "...",
  "categories": ["..."],
  "source": "https://github.com/org/repo",
  "url": "https://raw.githubusercontent.com/org/repo/main/skills/skill-name/SKILL.md"
}
```

### Configuring Skills

#### Adding a Local Skill

1. Create the skill folder and `SKILL.md` (see Creating a New Skill below).
2. Register the skill in `.skills.json` under the appropriate category:

```json
"skills": {
  "required": {
    "local:./skills/my-skill": {
      "version": "*",
      "description": "What my skill does.",
      "categories": ["my-category"]
    }
  }
}
```

#### Adding an External Skill

External skills are fetched from a URL at runtime. Add them to `recommended` or `registry`:

```json
"recommended": {
  "github:org/repo/skill-name": {
    "version": "^1.0.0",
    "description": "Short description with trigger phrases.",
    "categories": ["relevant", "tags"],
    "source": "https://github.com/org/repo",
    "url": "https://raw.githubusercontent.com/org/repo/main/skills/skill-name/SKILL.md"
  }
}
```

#### Blocking a Skill

To prevent an agent from using a specific skill (e.g., a deprecated or insecure external skill), add it to the `blocked` list:

```json
"blocked": [
  {
    "id": "github:unsafe-org/deprecated-skill",
    "reason": "Security vulnerability - deprecated by maintainer"
  }
]
```

### Creating a New Skill

```bash
mkdir -p skills/my-skill/references
```

Create `skills/my-skill/SKILL.md`:

```yaml
---
name: my-skill
description: >
  Describe what the skill does. Use when the user asks to [action],
  [another action], or [trigger phrase].
---

# My Skill

## What This Skill Provides

Brief overview of the domain knowledge and capabilities this skill covers.

## When to Use This Skill

- Scenario 1
- Scenario 2

## Core Patterns

### Pattern Name

**Rule**: State the rule clearly.

**Implementation**:
- Step or detail
- Step or detail

**References**: See references/guide.md
```

Then register it in `.skills.json`.

### Using Skills as an Agent

When processing a request, an agent resolves skills in this order:

1. **Constitution** — `context_modules/constitution.md` (always loaded).
2. **Persona** — relevant file from `context_modules/personas/` based on task context.
3. **Skill** — triggered by matching the user's intent to a skill description.

To activate a skill manually, tell the agent which skill to use:

> "Using the `github-actions` skill, create a reusable workflow for deploying to Kubernetes."

The agent will read `skills/github-actions/SKILL.md` and any referenced rule files before responding.

### How Personas and Skills Work Together

A persona and one or more skills are loaded at the same time. They complement rather than duplicate each other.

For example, a DevOps Engineer session might look like:

1. **Constitution** — foundational team principles always apply
2. **Persona**: `devops_engineer.md` — sets the role identity, collaboration preferences, and tool context
3. **Skill**: `github-actions` — activated when the user asks about CI/CD pipelines
4. **Skill**: `helm-charts` — activated when the user asks about packaging for Kubernetes

The persona tells the agent *who it is*. The skills tell it *how to execute* specific tasks.

### External Skills

External skills are fetched at runtime from their `url` field in `.skills.json`. They are not stored locally in this repository.

To discover registry skills, ask your AI agent:

> "What skills are available in the registry?"

The agent will read `.skills.json`, list the `registry` entries, and describe when each is useful. To use one, the agent fetches the `SKILL.md` from the provided `url`.

### Policy Settings

The `policy` section of `.skills.json` controls agent behavior:

```json
"policy": {
  "auto_install_required": true,
  "enforce_blocked": true,
  "allow_project_override": true
}
```

| Setting | Default | Description |
| --- | --- | --- |
| `auto_install_required` | `true` | Required skills are automatically loaded without user prompting |
| `enforce_blocked` | `true` | The agent refuses to use any skill in the `blocked` list |
| `allow_project_override` | `true` | Individual projects can override manifest settings locally |

---

## Versioning

Use git tags (v1.0.0, v2.0.0, etc.) to manage breaking changes. Downstream consumers can pin to specific versions.

## Customization

Fork this repository and customize:

1. **Constitution** - Add your team's principles
2. **Personas** - Define roles matching your team
3. **Rules** - Add domain-specific patterns
4. **Skills** - Create capabilities for your workflows
5. **`.mcp.json`** - Configure your MCP servers
6. **`.skills.json`** - Register your skills

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. All changes require pull request review.
