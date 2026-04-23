---
description: Verify project constitution aligns with team constitution principles
---

## Goal

Verify the project constitution (`.specify/memory/constitution.md`) inherits from or aligns with team constitution principles. Warns but does NOT block.

## Verification Process

### Step 1: Locate Files

1. **Team constitution**: `{EXTENSION_ROOT}/context_modules/constitution.md`
2. **Project constitution**: `{REPO_ROOT}/.specify/memory/constitution.md`

### Step 2: Verification Checks

Run these checks in order:

| Check | What to Verify | Fail Behavior |
|-------|---------------|--------------|
| **Inheritance marker** | Does project constitution reference team source? | Warn |
| **Principle coverage** | Are all team principles (1-12) represented? | Warn even if custom added |
| **Version sync** | Team v1.2.0 vs project version | Warn |
| **Custom overrides** | Any project-specific deviations? | Note |
| **Alignment quality** | How many principles match intent? | Info |

### Step 3: Parse Principles

For team constitution:
- Extract numbered principles 1-12
- Record names and brief descriptions

For project constitution:
- Extract all principles
- Match against team principles by name or intent

### Step 4: Output

Output as Markdown warning/note block:

```markdown
## Constitution Verification

| Check | Status | Details |
|-------|-------|---------|
| Team principles represented | ✅/⚠️ | X/12 detected |
| Version aligned | ✅/⚠️ | Team v1.2.0 vs Project vX.Y.Z |
| Sync recommended | ✅/⚠️ | Yes/No |
| Custom overrides | ℹ️ | Listed below (if any) |

### Missing Team Principles

- Principle N: **Name** - [brief description of what's missing]

### Recommendations

1. Consider adding missing principles from team constitution
2. Custom overrides are fine but should be documented
```

## Usage

Automatically executed via **after_constitution** hook (optional: true).

## Failure Handling

If verification cannot complete:
1. Output a warning notice
2. Include `**Warning**: Could not verify constitution alignment`
3. Exit successfully (code 0) - don't block