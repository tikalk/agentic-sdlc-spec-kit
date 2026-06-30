# AGENTS.md

## About Agentic SDLC Spec Kit and Specify

**Agentic SDLC Spec Kit** is a comprehensive toolkit for implementing Spec-Driven Development (SDD) - a methodology that emphasizes creating clear specifications before implementation. The toolkit includes templates, scripts, and workflows that guide development teams through a structured approach to building software.

**Specify CLI** is the command-line interface that bootstraps projects with the Agentic SDLC Spec Kit framework. It sets up the necessary directory structures, templates, and AI agent integrations to support the Spec-Driven Development workflow.

The toolkit supports multiple AI coding assistants, allowing teams to use their preferred tools while maintaining consistent project structure and development practices.

---

## General practices

### Python

```text
src/specify_cli/integrations/
├── __init__.py            # INTEGRATION_REGISTRY + _register_builtins()
├── base.py                # IntegrationBase, MarkdownIntegration, TomlIntegration, YamlIntegration, SkillsIntegration
├── manifest.py            # IntegrationManifest (file tracking)
├── claude/                # Example: SkillsIntegration subclass
│   └── __init__.py        #   ClaudeIntegration class
├── gemini/                # Example: TomlIntegration subclass
│   └── __init__.py
├── windsurf/              # Example: MarkdownIntegration subclass
│   └── __init__.py
├── copilot/               # Example: IntegrationBase subclass (custom setup)
│   └── __init__.py
└── ...                    # One subpackage per supported agent
```

The registry is the **single source of truth for Python integration metadata**. Supported agents, their directories, formats, capabilities, and context files are derived from the integration classes for the Python integration layer.

- Any changes to `__init__.py` for the Specify CLI require a version rev in `pyproject.toml` and addition to `CHANGELOG.md`.

## Adding New Agent Support

This section explains how to add support for new AI agents/assistants to the Specify CLI. Use this guide as a reference when integrating new AI tools into the Spec-Driven Development workflow.

### Overview

Specify supports multiple AI agents by generating agent-specific command files and directory structures when initializing projects. Each agent has its own conventions for:

- **Command file formats** (Markdown, TOML, etc.)
- **Directory structures** (`.claude/commands/`, `.windsurf/workflows/`, etc.)
- **Command invocation patterns** (slash commands, CLI tools, etc.)
- **Argument passing conventions** (`$ARGUMENTS`, `{{args}}`, etc.)

### Current Supported Agents

| Agent                      | Directory              | Format   | CLI Tool        | Description                 |
| -------------------------- | ---------------------- | -------- | --------------- | --------------------------- |
| **Claude Code**            | `.claude/commands/`    | Markdown | `claude`        | Anthropic's Claude Code CLI |
| **Gemini CLI**             | `.gemini/commands/`    | TOML     | `gemini`        | Google's Gemini CLI         |
| **GitHub Copilot**         | `.github/agents/`      | Markdown | N/A (IDE-based) | GitHub Copilot in VS Code   |
| **Cursor**                 | `.cursor/commands/`    | Markdown | N/A (IDE-based) | Cursor IDE (`--ai cursor-agent`) |
| **Qwen Code**              | `.qwen/commands/`      | Markdown | `qwen`          | Alibaba's Qwen Code CLI     |
| **opencode**               | `.opencode/command/`   | Markdown | `opencode`      | opencode CLI                |
| **Codex CLI**              | `.agents/skills/`      | Markdown | `codex`         | Codex CLI (`--ai codex --ai-skills`) |
| **Windsurf**               | `.windsurf/workflows/` | Markdown | N/A (IDE-based) | Windsurf IDE workflows      |
| **Junie**                  | `.junie/commands/`     | Markdown | `junie`         | Junie by JetBrains          |
| **Kilo Code**              | `.kilocode/workflows/` | Markdown | N/A (IDE-based) | Kilo Code IDE               |
| **Auggie CLI**             | `.augment/commands/`   | Markdown | `auggie`        | Auggie CLI                  |
| **Roo Code**               | `.roo/commands/`       | Markdown | N/A (IDE-based) | Roo Code IDE                |
| **CodeBuddy CLI**          | `.codebuddy/commands/` | Markdown | `codebuddy`     | CodeBuddy CLI               |
| **Qoder CLI**              | `.qoder/commands/`     | Markdown | `qodercli`      | Qoder CLI                   |
| **Kiro CLI**               | `.kiro/prompts/`       | Markdown | `kiro-cli`      | Kiro CLI                    |
| **Amp**                    | `.agents/commands/`    | Markdown | `amp`           | Amp CLI                     |
| **SHAI**                   | `.shai/commands/`      | Markdown | `shai`          | SHAI CLI                    |
| **Tabnine CLI**            | `.tabnine/agent/commands/` | TOML | `tabnine`       | Tabnine CLI                 |
| **Kimi Code**              | `.kimi/skills/`        | Markdown | `kimi`          | Kimi Code CLI (Moonshot AI) |
| **Pi Coding Agent**        | `.pi/prompts/`         | Markdown | `pi`            | Pi terminal coding agent    |
| **iFlow CLI**              | `.iflow/commands/`     | Markdown | `iflow`         | iFlow CLI (iflow-ai)        |
| **Forge**                  | `.forge/commands/`     | Markdown | `forge`         | Forge CLI (forgecode.dev)   |
| **IBM Bob**                | `.bob/commands/`       | Markdown | N/A (IDE-based) | IBM Bob IDE                 |
| **Trae**                   | `.trae/rules/`         | Markdown | N/A (IDE-based) | Trae IDE                    |
| **Antigravity**            | `.agent/commands/`     | Markdown | N/A (IDE-based) | Antigravity IDE (`--ai agy --ai-skills`) |
| **Mistral Vibe**           | `.vibe/prompts/`       | Markdown | `vibe`          | Mistral Vibe CLI            |
| **Generic**                | User-specified via `--ai-commands-dir` | Markdown | N/A | Bring your own agent        |

### Step-by-Step Integration Guide

Follow these steps to add a new agent (using a hypothetical new agent as an example):

#### 1. Add to AGENT_CONFIG

**IMPORTANT**: Use the actual CLI tool name as the key, not a shortened version.

Add the new agent to the `AGENT_CONFIG` dictionary in `src/specify_cli/__init__.py`. This is the **single source of truth** for all agent metadata:

```python
"""Windsurf IDE integration."""

from ..base import MarkdownIntegration


class WindsurfIntegration(MarkdownIntegration):
    key = "windsurf"
    config = {
        "name": "Windsurf",
        "folder": ".windsurf/",
        "commands_subdir": "workflows",
        "install_url": None,
        "requires_cli": False,
    }
    registrar_config = {
        "dir": ".windsurf/workflows",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": ".md",
    }
```

**Key Design Principle**: The dictionary key should match the actual executable name that users install. For example:

- ✅ Use `"cursor-agent"` because the CLI tool is literally called `cursor-agent`
- ❌ Don't use `"cursor"` as a shortcut if the tool is `cursor-agent`

This eliminates the need for special-case mappings throughout the codebase.

**Field Explanations**:

- `name`: Human-readable display name shown to users
- `folder`: Directory where agent-specific files are stored (relative to project root)
- `commands_subdir`: Subdirectory name within the agent folder where command/prompt files are stored (default: `"commands"`)
  - Most agents use `"commands"` (e.g., `.claude/commands/`)
  - Some agents use alternative names: `"agents"` (copilot), `"workflows"` (windsurf, kilocode), `"prompts"` (codex, kiro-cli, pi), `"command"` (opencode - singular)
  - This field enables `--ai-skills` to locate command templates correctly for skill generation
- `install_url`: Installation documentation URL (set to `None` for IDE-based agents)
- `requires_cli`: Whether the agent requires a CLI tool check during initialization

#### 2. Update CLI Help Text

Update the `--ai` parameter help text in the `init()` command to include the new agent:

```python
"""Gemini CLI integration."""

from ..base import TomlIntegration


class GeminiIntegration(TomlIntegration):
    key = "gemini"
    config = {
        "name": "Gemini CLI",
        "folder": ".gemini/",
        "commands_subdir": "commands",
        "install_url": "https://github.com/google-gemini/gemini-cli",
        "requires_cli": True,
    }
    registrar_config = {
        "dir": ".gemini/commands",
        "format": "toml",
        "args": "{{args}}",
        "extension": ".toml",
    }
```

Also update any function docstrings, examples, and error messages that list available agents.

#### 3. Update README Documentation

Update the **Supported AI Agents** section in `README.md` to include the new agent:

- Add the new agent to the table with appropriate support level (Full/Partial)
- Include the agent's official website link
- Add any relevant notes about the agent's implementation
- Ensure the table formatting remains aligned and consistent

#### 4. Update Release Package Script

class CodexIntegration(SkillsIntegration):
    key = "codex"
    config = {
        "name": "Codex CLI",
        "folder": ".agents/",
        "commands_subdir": "skills",
        "install_url": "https://github.com/openai/codex",
        "requires_cli": True,
    }
    registrar_config = {
        "dir": ".agents/skills",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": "/SKILL.md",
    }

    @classmethod
    def options(cls) -> list[IntegrationOption]:
        return [
            IntegrationOption(
                "--skills",
                is_flag=True,
                default=True,
                help="Install as agent skills (default for Codex)",
            ),
        ]
```

#### Required fields

| Field | Location | Purpose |
|---|---|---|
| `key` | Class attribute | Unique identifier; for CLI-based integrations (`requires_cli: True`), must match the CLI executable name |
| `config` | Class attribute (dict) | Agent metadata: `name`, `folder`, `commands_subdir`, `install_url`, `requires_cli` |
| `registrar_config` | Class attribute (dict) | Command output config: `dir`, `format`, `args` placeholder, file `extension` |

**Key design rule:** For CLI-based integrations (`requires_cli: True`), `key` must be the actual executable name (e.g., `"cursor-agent"` not `"cursor"`). This ensures `shutil.which(key)` works for CLI-tool checks without special-case mappings. IDE-based integrations (`requires_cli: False`) should use their canonical identifier (e.g., `"windsurf"`, `"copilot"`).

### 3. Register it

In `src/specify_cli/integrations/__init__.py`, add one import and one `_register()` call inside `_register_builtins()`. Both lists are alphabetical:

```python
def _register_builtins() -> None:
    # -- Imports (alphabetical) -------------------------------------------
    from .claude import ClaudeIntegration
    # ...
    from .newagent import NewAgentIntegration   # ← add import
    # ...

    # -- Registration (alphabetical) --------------------------------------
    _register(ClaudeIntegration())
    # ...
    _register(NewAgentIntegration())            # ← add registration
    # ...
```

### 4. Context file behavior

The Specify CLI carries **no agent-context state whatsoever**. Integration classes do **not** declare a `context_file`, and the CLI never creates, updates, removes, resolves, or migrates a context/instruction file (`CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, …). New integrations add nothing for context handling.

Managing the "Spec Kit" section in the context file is fully owned by the bundled `agent-context` extension (`extensions/agent-context/`), which is a **full opt-in**: `specify init` does not install it. A user adds/enables it through the standard extension verbs, after which the extension's own bundled scripts maintain the context section. When the extension is absent or disabled, nothing in Spec Kit touches the context file.

The extension reads its own config file at `.specify/extensions/agent-context/agent-context-config.yml`:

```yaml
# Path to the coding agent context file managed by this extension
context_file: CLAUDE.md

# Delimiters for the managed Spec Kit section
context_markers:
  start: "<!-- SPECKIT START -->"
  end: "<!-- SPECKIT END -->"
```

- The Specify CLI does **not** write this config. When `context_file` is empty, the extension's bundled scripts self-seed it by looking up the active integration's key in the extension's own `agent-context-defaults.json` map (`extensions/agent-context/scripts/bash/update-agent-context.sh` and `.ps1`). The CLI registry is never consulted — all agent→context-file knowledge lives inside the extension.
- `context_markers.{start,end}` are read solely by the extension's scripts; they default to the Spec Kit markers shown above and can be customized by editing `agent-context-config.yml` directly.

Existing projects created by older Spec Kit versions keep working: any previously written managed section or extension config is left intact and is only ever updated by the extension when run.

Only add custom setup logic when the agent needs non-standard behavior. Integrations no longer require per-agent thin wrapper scripts or shared context-update dispatcher scripts — the `agent-context` extension is fully generic.

### 5. Test it

```bash
# Install into a test project
specify init my-project --integration <key>

# Verify files were created in the commands directory configured by
# config["folder"] + config["commands_subdir"] (for example, .windsurf/workflows/)
ls -R my-project/.windsurf/workflows/

# Uninstall cleanly
cd my-project && specify integration uninstall <key>
```

**Benefits of this approach:**

- Eliminates special-case logic scattered throughout the codebase
- Makes the code more maintainable and easier to understand
- Reduces the chance of bugs when adding new agents
- Tool checking "just works" without additional mappings

#### 7. Update Devcontainer files (Optional)

For agents that have VS Code extensions or require CLI installation, update the devcontainer configuration files:

##### VS Code Extension-based Agents

For agents available as VS Code extensions, add them to `.devcontainer/devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        // ... existing extensions ...
        // [New Agent Name]
        "[New Agent Extension ID]"
      ]
    }
  }
}
```

##### CLI-based Agents

For agents that require CLI tools, add installation commands to `.devcontainer/post-create.sh`:

```bash
#!/bin/bash

# Existing installations...

echo -e "\n🤖 Installing [New Agent Name] CLI..."
# run_command "npm install -g [agent-cli-package]@latest" # Example for node-based CLI
# or other installation instructions (must be non-interactive and compatible with Linux Debian "Trixie" or later)...
echo "✅ Done"

```

**Quick Tips:**

- **Extension-based agents**: Add to the `extensions` array in `devcontainer.json`
- **CLI-based agents**: Add installation scripts to `post-create.sh`
- **Hybrid agents**: May require both extension and CLI installation
- **Test thoroughly**: Ensure installations work in the devcontainer environment

## Agent Categories

### CLI-Based Agents

Require a command-line tool to be installed:

- **Claude Code**: `claude` CLI
- **Gemini CLI**: `gemini` CLI
- **Qwen Code**: `qwen` CLI
- **opencode**: `opencode` CLI
- **Codex CLI**: `codex` CLI (requires `--ai-skills`)
- **Junie**: `junie` CLI
- **Auggie CLI**: `auggie` CLI
- **CodeBuddy CLI**: `codebuddy` CLI
- **Qoder CLI**: `qodercli` CLI
- **Kiro CLI**: `kiro-cli` CLI
- **Amp**: `amp` CLI
- **SHAI**: `shai` CLI
- **Tabnine CLI**: `tabnine` CLI
- **Kimi Code**: `kimi` CLI
- **Mistral Vibe**: `vibe` CLI
- **Pi Coding Agent**: `pi` CLI
- **iFlow CLI**: `iflow` CLI
- **Forge**: `forge` CLI

### IDE-Based Agents

Work within integrated development environments:

- **GitHub Copilot**: Built into VS Code/compatible editors
- **Cursor**: Built into Cursor IDE (`--ai cursor-agent`)
- **Windsurf**: Built into Windsurf IDE
- **Kilo Code**: Built into Kilo Code IDE
- **Roo Code**: Built into Roo Code IDE
- **IBM Bob**: Built into IBM Bob IDE
- **Trae**: Built into Trae IDE
- **Antigravity**: Built into Antigravity IDE (`--ai agy --ai-skills`)

## Command File Formats

### Markdown Format

Used by: Claude, Cursor, GitHub Copilot, opencode, Windsurf, Junie, Kiro CLI, Amp, SHAI, IBM Bob, Kimi Code, Qwen, Pi, Codex, Auggie, CodeBuddy, Qoder, Roo Code, Kilo Code, Trae, Antigravity, Mistral Vibe, iFlow, Forge

**Standard format:**

```markdown
---
description: "Command description"
---

Command content with {SCRIPT} and $ARGUMENTS placeholders.
```

**GitHub Copilot Chat Mode format:**

```markdown
---
description: "Command description"
mode: spec.command-name
---

Command content with {SCRIPT} and $ARGUMENTS placeholders.
```

### TOML Format

Used by: Gemini, Tabnine

```toml
description = "Command description"

prompt = """
Command content with {SCRIPT} and {{args}} placeholders.
"""
```

## Directory Conventions

- **CLI agents**: Usually `.<agent-name>/commands/`
- **Singular command exception**:
  - opencode: `.opencode/command/` (singular `command`, not `commands`)
- **Nested path exception**:
  - Tabnine: `.tabnine/agent/commands/` (extra `agent/` segment)
- **Shared `.agents/` folder**:
  - Amp: `.agents/commands/` (shared folder, not `.amp/`)
  - Codex: `.agents/skills/` (shared folder; requires `--ai-skills`; invoked as `$speckit-<command>`)
- **Skills-based exceptions**:
  - Kimi Code: `.kimi/skills/` (skills, invoked as `/skill:speckit-<command>`)
- **Prompt-based exceptions**:
  - Kiro CLI: `.kiro/prompts/`
  - Pi: `.pi/prompts/`
  - Mistral Vibe: `.vibe/prompts/`
- **Rules-based exceptions**:
  - Trae: `.trae/rules/`
- **IDE agents**: Follow IDE-specific patterns:
  - Copilot: `.github/agents/`
  - Cursor: `.cursor/commands/`
  - Windsurf: `.windsurf/workflows/`
  - Kilo Code: `.kilocode/workflows/`
  - Roo Code: `.roo/commands/`
  - IBM Bob: `.bob/commands/`
  - Antigravity: `.agent/skills/` (`--ai-skills` required; `.agent/commands/` is deprecated)

## Argument Patterns

Different agents use different argument placeholders:

- **Markdown/prompt-based**: `$ARGUMENTS`
- **TOML-based**: `{{args}}`
- **Forge-specific**: `{{parameters}}` (uses custom parameter syntax)
- **Script placeholders**: `{SCRIPT}` (replaced with actual script path)
- **Agent placeholders**: `__AGENT__` (replaced with agent name)

## Special Processing Requirements

Some agents require custom processing beyond the standard template transformations:

### Copilot Integration

GitHub Copilot has unique requirements:

- Commands use `.agent.md` extension (not `.md`)
- Each command gets a companion `.prompt.md` file in `.github/prompts/`
- Installs `.vscode/settings.json` with prompt file recommendations
- Context file lives at `.github/copilot-instructions.md`

Implementation: Extends `IntegrationBase` with custom `setup()` method that:

1. Processes templates with `process_template()`
2. Generates companion `.prompt.md` files
3. Merges VS Code settings

**Skills mode (`--skills`):** Copilot also supports an alternative skills-based layout
via `--integration-options="--skills"`. When enabled:

- Commands are scaffolded as `speckit-<name>/SKILL.md` under `.github/skills/`
- No companion `.prompt.md` files are generated
- No `.vscode/settings.json` merge
- `post_process_skill_content()` injects a `mode: speckit.<stem>` frontmatter field
- `build_command_invocation()` returns `/speckit-<stem>` instead of bare args

The two modes are mutually exclusive — a project uses one or the other:

```bash
# Default mode: .agent.md agents + .prompt.md companions + settings merge
specify init my-project --integration copilot

# Skills mode: speckit-<name>/SKILL.md under .github/skills/
specify init my-project --integration copilot --integration-options="--skills"
```

### Forge Integration

Forge has special frontmatter and argument requirements:

- Uses `{{parameters}}` instead of `$ARGUMENTS`
- Strips `handoffs` frontmatter key (Forge-specific collaboration feature)
- Injects `name` field into frontmatter when missing

Implementation: Extends `MarkdownIntegration` with custom `setup()` method that:

1. Inherits standard template processing from `MarkdownIntegration`
2. Adds extra `$ARGUMENTS` → `{{parameters}}` replacement after template processing
3. Applies Forge-specific transformations via `_apply_forge_transformations()`
4. Strips `handoffs` frontmatter key
 5. Injects missing `name` fields

### Goose Integration

Goose is a YAML-format agent using Block's recipe system:

- Uses `.goose/recipes/` directory for YAML recipe files
- Uses `{{args}}` argument placeholder
- Produces YAML with `prompt: |` block scalar for command content

Implementation: Extends `YamlIntegration` (parallel to `TomlIntegration`):

1. Processes templates through the standard placeholder pipeline
2. Extracts title and description from frontmatter
3. Renders output as Goose recipe YAML (version, title, description, author, extensions, activities, prompt)
4. Uses `yaml.safe_dump()` for header fields to ensure proper escaping

## Branch Naming Convention

Branches follow one of two patterns depending on whether an issue exists:

```text
<type>/<number>-<short-slug>   # when an issue is created first
<type>/<short-slug>            # when no issue exists (PR-only changes)
```

When an issue exists, include its number immediately after the prefix — this is what makes branches traceable. For small or self-contained changes that go straight to a PR without a tracking issue, omit the number.

| Prefix | When to use | Example |
|---|---|---|
| `feat/` | New features | `feat/2342-workflow-cli-alignment` |
| `fix/` | Bug fixes | `fix/2653-paths-only-validation` |
| `docs/` | Documentation changes | `docs/2677-branch-naming-convention`, `docs/update-landing-stats` |
| `community/` | Community catalog additions | `community/2492-add-mde-extension` |
| `chore/` | Maintenance, tooling, CI | `chore/2366-editorconfig` |

**Rules:**

1. Include the issue number when one exists — this is what makes branches traceable
2. Use kebab-case for the slug
3. Keep the slug short — enough to identify the work without looking up the issue

---

## Agent Disclosure for PRs, Comments, and Commits

Disclosure is **continuous**, not a one-time event. A single AI-disclosure paragraph in the PR body does **not** cover the commits and replies you add during review rounds. Each of the following must independently attest to agent authorship.

### Commits

- **Every commit you author must carry an `Assisted-by:` trailer** identifying the agent and whether it acted autonomously or under direct human supervision, for example:

  ```
  Assisted-by: GitHub Copilot (model: <name-if-known>, autonomous)
  ```

  Use `supervised` instead of `autonomous` only when a human actually authored or line-by-line reviewed the change before it was committed.
- **Never push solo-authored commits that hide agent authorship behind the operator's git identity.** If an agent generated the change, the trailer must say so even when the commit is attributed to a human account.
- Preserve any tool-generated `Co-authored-by:` trailers (e.g. Copilot Autofix) — do not strip them to make a commit look hand-written.

### Comments

- If you are an agent working on behalf of a human, **disclose your identity in your PR comment** — name the agent (and model, if applicable) and the human you are acting for (e.g., "Posted on behalf of @user by GitHub Copilot (model: &lt;name-if-known&gt;)").
- **Re-state agent identity in each review-round summary comment.** A prior PR-body disclosure does not cover later comments or commits.
- Post **one** top-level summary comment per review round listing what changed and the commit SHA. Do not reply on every individual comment.
- Reply inline only when context is needed (disagreement, deferral, non-obvious fix). Keep it to a sentence or two.
- **Never click "Resolve conversation"** — that belongs to the reviewer or PR author.
- No emoji, no celebratory framing, no checklist mirroring the reviewer's items, no restating what the reviewer wrote.
- Re-request review once per round (when all feedback is addressed), not after every intermediate push.

### Anti-patterns (do not do these)

- **Do not** reply "Done" or push a "fix" within seconds/minutes of a review event without disclosing that the response or commit was agent-generated. Speed of turnaround is not a substitute for attestation — a near-instant tested code change is itself a signal of automation and must be disclosed as such.
- **Do not** claim "reviewed, tested, and understood by me" for commits that were authored and pushed automatically in response to a review trigger. If the loop is automated, disclose it as automated.

---

## Common Pitfalls

1. **Using shorthand keys for CLI-based integrations**: For CLI-based integrations (`requires_cli: True`), the `key` must match the executable name (e.g., `"cursor-agent"` not `"cursor"`). `shutil.which(key)` is used for CLI tool checks — mismatches require special-case mappings. IDE-based integrations (`requires_cli: False`) are not subject to this constraint.
2. **Reintroducing context handling into the CLI**: The opt-in `agent-context` extension owns everything about context files — including the per-agent default mapping in `agent-context-defaults.json`. Integration classes must **not** declare a `context_file`, and no CLI code should read, write, resolve, or migrate context files. All context-file logic lives in `.specify/extensions/agent-context/` and its bundled scripts.
3. **Incorrect `requires_cli` value**: Set to `True` only for agents that have a CLI tool; set to `False` for IDE-based agents.
4. **Wrong argument format**: Use `$ARGUMENTS` for Markdown agents, `{{args}}` for TOML agents.
5. **Skipping registration**: The import and `_register()` call in `_register_builtins()` must both be added.
6. **Running tests against the wrong environment**: Always run the suite inside this working tree's own virtualenv (`uv sync --extra test` then `.venv/bin/python -m pytest`, or activate the venv first). A bare `uv run pytest` can resolve to an ambient/global interpreter whose editable `.pth` points at a *different* worktree. The failure is sneaky: test collection still imports `specify_cli` successfully, but newly-added subpackages (e.g. a fresh `specify_cli/bundler/`) resolve as a stale namespace package and raise `ModuleNotFoundError`. If a brand-new subpackage imports under `python -c` but not under pytest, suspect environment contamination, not your code.

---

*This documentation should be updated whenever new agents are added to maintain accuracy and completeness.*

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->
