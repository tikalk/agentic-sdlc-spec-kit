---
description: Discover relevant context from team-ai-directives for current feature
---

## Goal

Discover relevant personas, rules, examples, and skills from team-ai-directives that apply to the current feature being specified or planned.

## Discovery Process

### Step 1: Locate Knowledge Base

Read `.specify/init-options.json` (JSON) and extract the `team_ai_directives` field.

- If present and the path exists: use it as the knowledge base root.
- If not found or path doesn't exist: output empty results and exit.

### Step 2: Load Feature Context

Read the feature description from:
- Environment variable: `${SPECIFY_FEATURE_DESCRIPTION}` (if set)
- Context file: `{REPO_ROOT}/specs/${SPECIFY_FEATURE}/context.md`
- Spec file: `{REPO_ROOT}/specs/${SPECIFY_FEATURE}/spec.md` (Mission Brief section)

Extract the feature's:
- **Domain**: What business area is this? (e.g., payments, auth, analytics)
- **Technology**: What tech stack? (e.g., Java, Python, Kubernetes, React)
- **Patterns**: What architectural patterns? (e.g., REST, event-driven, CQRS)
- **Actions**: What is the feature doing? (e.g., create, validate, sync, process)

### Step 3: Scan team-ai-directives

Read all files from `{TEAM_AI_DIRECTIVES}/context_modules/`:

1. **constitution.md** - Always include this
2. **personas/** - List all persona files
3. **rules/** - List all rule files (organized by category)
4. **examples/** - List all example files

Also read `{TEAM_AI_DIRECTIVES}/.skills.json` for skill registry.

### Step 4: Select Relevant Context

For each file, determine relevance based on:

**Personas** - Match when:
- Persona's domain matches feature domain
- Persona's role aligns with feature users

**Rules** - Match when:
- Rule technology matches feature technology stack
- Rule category aligns with feature type (security, testing, style, etc.)
- Rule applies to the patterns being used

**Examples** - Match when:
- Example domain/technology overlaps with feature
- Similar feature type or pattern demonstrated

### Step 5: Output Discovered Context

Output structured discovery results in this exact format:

```json
{
  "constitution": "/path/to/constitution.md",
  "personas": [
    {"name": "Admin User", "file": "personas/admin.md", "relevance": "high"}
  ],
  "rules": [
    {"name": "API Security", "file": "rules/security/api-security.md", "relevance": "high", "category": "security"}
  ],
  "examples": [
    {"name": "Payment Flow", "file": "examples/payment-flow.md", "relevance": "medium"}
  ],
  "search_metadata": {
    "files_searched": 42,
    "files_with_matches": 8
  }
}
```

### Step 6: Persist Team Context (Extension-Owned)

The `team-ai-directives` extension owns persistence for discovered feature context.

Canonical artifact name:

- `team-context.json`

Persistence rules:

1. If the feature directory is already known, write the discovered payload to:
   - `SPECIFY_FEATURE_DIRECTORY/team-context.json`
2. If the feature directory is not known yet, write the same payload to the staging location:
   - `.specify/discovery/team-context.json`
3. Once the feature directory exists, the `specify` workflow should move or copy the staged file to:
   - `SPECIFY_FEATURE_DIRECTORY/team-context.json`
4. During `plan`, if `SPECIFY_FEATURE_DIRECTORY/team-context.json` exists, load it first and treat it
   as the authoritative discovered team context for that feature.
5. If discovery is re-run later and the feature directory is known, overwrite the feature-scoped
   `team-context.json` with the refreshed results.

`team-context.json` is the authoritative machine-readable artifact. If a markdown summary is added
later, it should be derived from this JSON rather than treated as the source of truth.

### Step 7: Populate Feature Context

The preset commands will use this output to populate the context template with discovered directives.

When `team-context.json` exists, they should load that persisted artifact instead of relying solely
on transient command output.

## Usage

This command is automatically executed via extension hooks:
- **before_specify**: Runs before `/spec.specify` to discover context for specification
- **before_plan**: Runs before `/spec.plan` to discover context for planning

## Failure Handling

If team-ai-directives is not configured or files cannot be read:
1. Output empty results with all arrays empty
2. Include search_metadata showing 0 files searched
3. Exit successfully (code 0) - don't block the preset command
