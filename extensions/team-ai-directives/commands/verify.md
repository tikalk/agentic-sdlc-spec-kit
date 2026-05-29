---
description: Verify team-ai-directives installation and health check
---

## Goal

Verify that team-ai-directives is properly installed and healthy.

## Verification Checks

### Check 1: Extension Installed

1. Check `.specify/extensions/.registry` for `team-ai-directives` entry
2. Verify `.specify/extensions/team-ai-directives/extension.yml` exists
3. Extract version from extension.yml

Output: `[OK]` or `[FAIL]` with reason

### Check 2: Knowledge Base Configured

1. Read `.specify/init-options.json`
2. Verify `team_ai_directives` field exists and points to valid path
3. Check the knowledge base path exists

Output: `[OK]` or `[FAIL]` with reason

### Check 3: Context Modules exist

1. Read `.specify/init-options.json` → get knowledge base path
2. Verify:
   - `{KNOWLEDGE_BASE}/context_modules/constitution.md`
   - `{KNOWLEDGE_BASE}/context_modules/personas/`
   - `{KNOWLEDGE_BASE}/context_modules/rules/`
   - `{KNOWLEDGE_BASE}/context_modules/examples/`

Output: `[OK]` or `[FAIL]` with reason

### Check 4: Skills registry

- `{KNOWLEDGE_BASE}/.skills.json` exists and is valid JSON

Output: `[OK]` or `[FAIL]` with reason

### Check 5: CDR tracking

- `{KNOWLEDGE_BASE}/CDR.md` exists

Output: `[OK]` or `[FAIL]` with reason

### Check 6: Constitution Alignment

1. Read team constitution from `{KNOWLEDGE_BASE}/context_modules/constitution.md`
2. Locate project constitution: `{REPO_ROOT}/.specify/memory/constitution.md`
3. If project constitution exists:
   - Check if it references team-ai-directives (e.g., "Based on team-ai-directives", "Inherits from")
   - Check if team principles are present in project constitution (compare principle titles)
   - Output:
     - `[OK]` - Project constitution exists and inherits team principles
     - `[WARN]` - Project constitution exists but missing team inheritance
4. If project constitution doesn't exist:
   - `[INFO]` - Project constitution doesn't exist yet (first-time setup)

## Output

Print verification status for each check:
- `[OK]` - Check passed
- `[FAIL]` - Check failed with reason
- `[WARN]` - Check passed with warnings (non-blocking)
- `[INFO]` - Informational only

**Exit codes:**
- 0 - All checks passed (including warnings)
- 1 - One or more checks failed
