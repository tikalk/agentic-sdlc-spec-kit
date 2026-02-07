# Skill CLI Commands Specification

## Command Structure

```bash
specify skill <command> [options] [arguments]
```

## Commands

### 1. skill search

Search for skills in the registry.

```bash
specify skill search [query] [options]
```

**Options:**
- `--category <cat>` - Filter by category
- `--min-score <n>` - Minimum evaluation score
- `--source <source>` - Filter by source (github, gitlab, registry)
- `--limit <n>` - Limit results (default: 20)
- `--json` - Output as JSON

**Examples:**
```bash
# Search for React skills
specify skill search react

# Search with filters
specify skill search security --category devops --min-score 85

# JSON output for scripting
specify skill search python --json
```

**Output:**
```
Found 3 skills matching "react":

react-best-practices (vercel-labs)
  Score: 94/100 (Review: 95, Task: 93)
  Categories: frontend, performance, hooks
  Install: specify skill install github:vercel-labs/agent-skills/react-best-practices

react-native-guidelines (vercel-labs)  
  Score: 91/100 (Review: 92, Task: 90)
  Categories: mobile, react-native
  Install: specify skill install github:vercel-labs/agent-skills/react-native-guidelines
```

### 2. skill install

Install a skill from various sources.

```bash
specify skill install <skill-ref> [options]
```

**Skill Reference Formats:**
- `github:org/repo/skill-name` - GitHub repository
- `github:org/repo/skill-name@version` - Specific version
- `gitlab:org/repo/skill-name` - GitLab repository
- `local:./path/to/skill` - Local path
- `registry:skill-name` - Registry reference

**Options:**
- `--version <ver>` - Specific version to install
- `--save` - Save to skills.json (default: true)
- `--no-save` - Don't save to manifest
- `--force` - Reinstall even if already present
- `--eval` - Run evaluation after install

**Examples:**
```bash
# Install from GitHub
specify skill install github:vercel-labs/agent-skills/react-best-practices

# Install specific version
specify skill install github:vercel-labs/agent-skills/react-best-practices@1.2.0

# Install from local path
specify skill install local:./custom-skills/dbt-workflow

# Install without saving to manifest
specify skill install github:org/skill --no-save
```

**Process:**
1. Parse skill reference
2. Fetch skill from source
3. Validate skill structure
4. Copy to `.specify/skills/`
5. Update skills.json
6. Run evaluation (if --eval)

### 3. skill update

Update installed skills.

```bash
specify skill update [skill-name] [options]
```

**Options:**
- `--all` - Update all skills
- `--dry-run` - Show what would be updated
- `--force` - Update even if evaluation score decreases

**Examples:**
```bash
# Check for outdated skills
specify skill outdated

# Update specific skill
specify skill update react-best-practices

# Update all skills
specify skill update --all

# Preview updates
specify skill update --all --dry-run
```

### 4. skill remove

Remove an installed skill.

```bash
specify skill remove <skill-name> [options]
```

**Options:**
- `--force` - Remove without confirmation
- `--keep-files` - Remove from manifest but keep files

**Examples:**
```bash
# Remove skill
specify skill remove react-best-practices

# Force remove
specify skill remove react-best-practices --force
```

### 5. skill list

List installed skills.

```bash
specify skill list [options]
```

**Options:**
- `--outdated` - Show only outdated skills
- `--json` - Output as JSON
- `--tree` - Show dependency tree

**Examples:**
```bash
# List all skills
specify skill list

# Show outdated
specify skill list --outdated

# JSON output
specify skill list --json
```

**Output:**
```
Installed Skills (3):

react-best-practices@1.2.0
  Source: github:vercel-labs/agent-skills/react-best-practices
  Score: 94/100 ✓
  Installed: 2026-02-07

security-rules@2.0.1  
  Source: github:myorg/internal-security-rules
  Score: 88/100 ✓
  Installed: 2026-02-06

dbt-workflow@*
  Source: local:./custom-skills/dbt-workflow
  Score: N/A (local)
  Installed: 2026-02-05
```

### 6. skill eval

Evaluate skill quality.

```bash
specify skill eval <skill-path-or-name> [options]
```

**Options:**
- `--review` - Run review evaluation only
- `--task` - Run task evaluation only
- `--full` - Run both evaluations
- `--scenarios <path>` - Path to test scenarios
- `--report` - Generate report
- `--output <file>` - Output file for report

**Examples:**
```bash
# Evaluate installed skill
specify skill eval react-best-practices --full

# Evaluate local skill
specify skill eval ./my-skill --review

# Generate report
specify skill eval ./my-skill --full --report --output eval.md
```

**Output:**
```
Evaluation Results for react-best-practices:

Review Score: 95/100 ✓
  ✓ Frontmatter valid (20/20)
  ✓ Content organization (30/30)
  ✓ Self-contained (28/30)
  ✓ Documentation (17/20)

Task Score: 93/100 ✓
  API Correctness: 38/40
  Best Practices: 28/30
  Output Quality: 27/30

Overall: 94/100 ✓ (Excellent)
```

### 7. skill publish

Publish skill to registry.

```bash
specify skill publish <skill-path> [options]
```

**Options:**
- `--registry <url>` - Target registry
- `--version <ver>` - Version to publish
- `--skip-eval` - Skip evaluation (not recommended)

**Examples:**
```bash
# Publish skill
specify skill publish ./my-skill

# Publish specific version
specify skill publish ./my-skill --version 1.0.0
```

**Requirements:**
- Review Score >= 80
- Task Score >= 75
- Proper frontmatter
- No external dependencies

## Implementation Notes

### Directory Structure
```
.specify/
├── skills.json           # Manifest
├── skills/               # Installed skills cache
│   └── {source}--{name}@{version}/
│       └── SKILL.md
└── skills-registry/      # Registry cache
    └── index.json
```

### Integration Points

1. **specify init** - Initialize skills.json if not present
2. **speckit.specify** - Auto-discover and inject relevant skills
3. **Context System** - Skills populate context.md
4. **Team Directives** - Skills can reference directives

### Error Handling

All commands should handle:
- Network failures (retry with backoff)
- Invalid skill references
- Permission errors
- Malformed skill files
- Version conflicts

### Configuration

Global config in `~/.config/specify/config.json`:
```json
{
  "skills": {
    "registry_url": "https://registry.agentic-sdlc.io",
    "auto_update": false,
    "cache_ttl": 3600
  }
}
```
