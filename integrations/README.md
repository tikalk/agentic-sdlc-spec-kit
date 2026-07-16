# Spec Kit Integration Catalog

The integration catalog enables discovery, versioning, and distribution of AI agent integrations for Spec Kit.

## Catalog Files

### Built-In Catalog (`catalog.json`)

Contains integrations that ship with Spec Kit. These are maintained by the core team and always installable.

### Community Catalog (`catalog.community.json`)

Community-contributed integrations. Listed for discovery only — users install from the source repositories.

## Catalog Configuration

The catalog stack is resolved in this order (first match wins):

1. **Environment variable** — `SPECKIT_INTEGRATION_CATALOG_URL` overrides all catalogs with a single URL
2. **Project config** — `.specify/integration-catalogs.yml` in the project root
3. **User config** — `~/.specify/integration-catalogs.yml` in the user home directory
4. **Built-in defaults** — `catalog.json` + `catalog.community.json`

Example `integration-catalogs.yml`:

```yaml
catalogs:
  - url: "https://example.com/my-catalog.json"
    name: "my-catalog"
    priority: 1
    install_allowed: true
```

## CLI Commands

```bash
# List built-in integrations (default)
specify integration list

# Browse full catalog (built-in + community)
specify integration list --catalog

# Install an integration
specify integration install copilot

# Upgrade the current integration (diff-aware)
specify integration upgrade

# Upgrade with force (overwrite modified files)
specify integration upgrade --force
```

## Integration Descriptor (`integration.yml`)

Each integration can include an `integration.yml` descriptor that documents its metadata, requirements, and provided commands/scripts:

```yaml
schema_version: "1.0"
integration:
  id: "my-agent"
  name: "My Agent"
  version: "1.0.0"
  description: "Integration for My Agent"
  author: "my-org"
  repository: "https://github.com/my-org/speckit-my-agent"
  license: "MIT"
requires:
  speckit_version: ">=0.6.0"
  tools:
    - name: "my-agent"
      version: ">=1.0.0"
      required: true
provides:
  commands:
    - name: "speckit.specify"
      file: "templates/speckit.specify.md"
    - name: "speckit.plan"
      file: "templates/speckit.plan.md"
  scripts:
    - update-context.sh
    - update-context.ps1
```

## Runtime Hooks

Runtime hooks wire agent-native lifecycle events (e.g. `PreToolUse`, `PostToolUse`, `Stop`) to existing slash commands. They are installed deterministically into the agent's own hook config — not as agent instructions, but as native config entries that the agent CLI executes automatically.

### Supported Integrations

| Integration | Config file | Format | Event casing | Notes |
|-------------|-------------|--------|--------------|-------|
| `claude` | `.claude/settings.json` | JSON (nested matcher-groups) | PascalCase | Most mature |
| `cursor-agent` | `.cursor/hooks.json` | JSON (flat handler arrays) | camelCase | |
| `codex` | `.codex/config.toml` | TOML (`[[hooks.*]]`) | PascalCase | Requires `/hooks` trust on first run |
| `opencode` | `.opencode/plugin/speckit-hooks.ts` + `opencode.json` | TypeScript plugin | — | Plugin auto-loaded via `plugin[]` array |

Other integrations (gemini, goose, copilot, pi, etc.) silently skip runtime hooks — no error, no files created.

### Hook Resolution (4 layers)

Hooks are resolved in this order (later layers override earlier ones):

1. **CLI flag** (`--hooks`): If `--integration-options="--hooks false"`, no hooks are installed. Default: `true`.
2. **User YAML override** (`.specify/integration-hooks.yml`): If the integration key is present, its `hooks` map **replaces** all hooks from layers 3 and 4. An empty `hooks: {}` disables hooks for that agent.
3. **Extension-declared** (`runtime_hooks:` in `extension.yml`): Collected from all installed extensions and appended.
4. **Built-in defaults** (`config["hooks"]` in the integration class): Baseline hooks shipped with the integration.

### CLI Option

Hook-capable integrations accept a `--hooks` option via `--integration-options`:

```bash
# Default: hooks enabled
specify init my-project --integration claude

# Disable hooks
specify init my-project --integration claude --integration-options="--hooks false"

# Re-enable on upgrade
specify integration upgrade claude --integration-options="--hooks true"
```

### User Override File (`.specify/integration-hooks.yml`)

Overrides built-in and extension-declared hooks per integration. For each integration key present, its `hooks` map replaces everything below it.

```yaml
version: 1
integrations:
  claude:
    hooks:
      PreToolUse:
        command: speckit.protected_paths
        matcher: "Edit|Write"
        timeout: 10
        optional: false
      PostToolUse:
        command: speckit.tdd.validate
        matcher: "Edit|Write"
        timeout: 60
        optional: true
      Stop:
        command: speckit.tdd.validate
        matcher: "*"
        timeout: 30
        optional: false

  # Explicitly disable hooks for an agent
  cursor-agent:
    hooks: {}

  # gemini not listed → keeps built-in default (empty = no hooks)
```

### Hook Entry Schema

Each hook entry maps one event to one slash command:

| Field | Required | Description |
|-------|----------|-------------|
| `command` | Yes | Slash command name (e.g. `speckit.tdd.validate`). Must have a `scripts:` frontmatter entry. |
| `matcher` | No | Tool name filter (e.g. `"Edit|Write"`). Default: `"*"`. |
| `timeout` | No | Execution timeout in seconds. Default: `60`. |
| `optional` | No | `true` = fail open on error; `false` = block on failure. Default: `false`. |

### How Hooks Are Installed

1. Specify CLI resolves the final hook set (4-layer resolution).
2. A portable bridge script is generated at `.specify/hooks/bridge.py` (stdlib-only Python, no dependencies).
3. The bridge resolves slash commands to their underlying scripts via the extension registry and command frontmatter `scripts:` parsing.
4. Hook entries are merged into the agent's native config file (non-destructive — user settings and user hooks are preserved).
5. On uninstall, only Specify-authored entries are removed; user settings are left intact.

### Codex Trust Requirement

Codex CLI uses a hash-based trust model for hooks. After installing or upgrading hooks, the user must run `/hooks` in an interactive Codex session to review and approve them. Until trusted, hooks are silently skipped. If `specify integration upgrade codex` changes the hook content, re-trust is required.

## Catalog Schema

Both catalog files follow the same JSON schema:

```json
{
  "schema_version": "1.0",
  "updated_at": "2026-04-08T00:00:00Z",
  "catalog_url": "https://...",
  "integrations": {
    "my-agent": {
      "id": "my-agent",
      "name": "My Agent",
      "version": "1.0.0",
      "description": "Integration for My Agent",
      "author": "my-org",
      "repository": "https://github.com/my-org/speckit-my-agent",
      "tags": ["cli"]
    }
  }
}
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `schema_version` | string | Must be `"1.0"` |
| `updated_at` | string | ISO 8601 timestamp |
| `integrations` | object | Map of integration ID → metadata |

### Integration Entry Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique ID (lowercase alphanumeric + hyphens) |
| `name` | string | Yes | Human-readable display name |
| `version` | string | Yes | PEP 440 version (e.g., `1.0.0`, `1.0.0a1`) |
| `description` | string | Yes | One-line description |
| `author` | string | No | Author name or organization |
| `repository` | string | No | Source repository URL |
| `tags` | array | No | Searchable tags (e.g., `["cli", "ide"]`) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add integrations to the community catalog.
