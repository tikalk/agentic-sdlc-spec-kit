---
description: Discover and load team constitution principles before project constitution update
---

## Goal

Load team constitution from team-ai-directives to inherit principles BEFORE updating the project constitution. Output is auto-populated into agent context.

## Discovery Process

### Step 1: Locate Knowledge Base

Read `.specify/init-options.json` (JSON) and extract the `team_ai_directives` field.

- If present and the path exists: use it as the knowledge base root.
- If not found or path doesn't exist: output warning and exit.

### Step 2: Read Version

Read `{TEAM_AI_DIRECTIVES}/AGENTS.md` (if exists) and look for a version line, or read git tags from the knowledge base directory.

### Step 3: Read Constitution

Read `{TEAM_AI_DIRECTIVES}/context_modules/constitution.md`.

### Step 4: Output (Auto-populate Context)

Output exactly:

```markdown
## Team Constitution Principles (Loaded from team-ai-directives)

**Source**: team-ai-directives
**Version**: {version from Step 2}

{full contents of context_modules/constitution.md from Step 3}
```

## Usage

Automatically executed via **before_constitution** hook (optional: false).

## Failure Handling

If constitution files cannot be read:
1. Output a warning notice
2. Include `**Warning**: Team constitution not found in team-ai-directives`
3. Exit successfully (code 0) - don't block the preset command
