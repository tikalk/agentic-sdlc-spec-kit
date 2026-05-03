# AGENTS.md

## About Agentic SDLC Spec Kit and Specify

**Agentic SDLC Spec Kit** is a comprehensive toolkit for implementing Spec-Driven Development (SDD) - a methodology that emphasizes creating clear specifications before implementation. The toolkit includes templates, scripts, and workflows that guide development teams through a structured approach to building software.

**Specify CLI** is the command-line interface that bootstraps projects with the Agentic SDLC Spec Kit framework. It sets up the necessary directory structures, templates, and AI agent integrations to support the Spec-Driven Development workflow.

The toolkit supports multiple AI coding assistants, allowing teams to use their preferred tools while maintaining consistent project structure and development practices.

---

## General practices

### Python

```
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
AGENT_CONFIG = {
    # ... existing agents ...
    "new-agent-cli": {  # Use the ACTUAL CLI tool name (what users type in terminal)
        "name": "New Agent Display Name",
        "folder": ".newagent/",  # Directory for agent files
        "commands_subdir": "commands",  # Subdirectory name for command files (default: "commands")
        "install_url": "https://example.com/install",  # URL for installation docs (or None if IDE-based)
        "requires_cli": True,  # True if CLI tool required, False for IDE-based agents
    },
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
ai_assistant: str = typer.Option(None, "--ai", help="AI assistant to use: claude, gemini, copilot, cursor-agent, qwen, opencode, codex, windsurf, kilocode, auggie, codebuddy, new-agent-cli, or kiro-cli"),
```

Also update any function docstrings, examples, and error messages that list available agents.

#### 3. Update README Documentation

Update the **Supported AI Agents** section in `README.md` to include the new agent:

- Add the new agent to the table with appropriate support level (Full/Partial)
- Include the agent's official website link
- Add any relevant notes about the agent's implementation
- Ensure the table formatting remains aligned and consistent

#### 4. Update Release Package Script

Modify `.github/workflows/scripts/create-release-packages.sh`:

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
| `context_file` | Class attribute (str or None) | Path to agent context/instructions file (e.g., `"CLAUDE.md"`, `".github/copilot-instructions.md"`) |

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

Set `context_file` on the integration class. The base integration setup creates or updates the managed Spec Kit section in that file, and uninstall removes the managed section when appropriate.

Only add custom setup logic when the agent needs non-standard behavior. Most integrations do not need wrapper scripts or separate context-update dispatch code.

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

### Standard Markdown Agents

Most agents (Bob, Claude, Windsurf, etc.) use `MarkdownIntegration`:
- Simple subclass with just `key`, `config`, `registrar_config` set
- Inherits standard processing from `MarkdownIntegration.setup()`
- No custom processing needed

Implementation: Extends `YamlIntegration` (parallel to `TomlIntegration`):
1. Processes templates through the standard placeholder pipeline
2. Extracts title and description from frontmatter
3. Renders output as Goose recipe YAML (version, title, description, author, extensions, activities, prompt)
4. Uses `yaml.safe_dump()` for header fields to ensure proper escaping
5. Sets `context_file = "AGENTS.md"` so the base setup manages the Spec Kit context section there

## Common Pitfalls

1. **Using shorthand keys instead of actual CLI tool names**: Always use the actual executable name as the AGENT_CONFIG key (e.g., `"cursor-agent"` not `"cursor"`). This prevents the need for special-case mappings throughout the codebase.
2. **Forgetting update scripts**: Both bash and PowerShell scripts must be updated when adding new agents.
3. **Incorrect `requires_cli` value**: Set to `True` only for agents that actually have CLI tools to check; set to `False` for IDE-based agents.
4. **Wrong argument format**: Use correct placeholder format for each agent type (`$ARGUMENTS` for Markdown, `{{args}}` for TOML).
5. **Directory naming**: Follow agent-specific conventions exactly (check existing agents for patterns).
6. **Help text inconsistency**: Update all user-facing text consistently (help strings, docstrings, README, error messages).

## Future Considerations

When adding new agents:

- Consider the agent's native command/workflow patterns
- Ensure compatibility with the Spec-Driven Development process
- Document any special requirements or limitations
- Update this guide with lessons learned
- Verify the actual CLI tool name before adding to AGENT_CONFIG

---

*This documentation should be updated whenever new agents are added to maintain accuracy and completeness.*

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->
