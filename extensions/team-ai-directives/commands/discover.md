---
description: Discover relevant context from team-ai-directives for current feature
---

## Goal

Discover relevant personas, rules, examples, and skills from team-ai-directives that apply to the current feature being specified or planned.

## CDR Index as Search Surface

`CDR.md` in the team-ai-directives knowledge base serves as the authoritative, LLM-readable catalog of all available context modules — analogous to how `.skills.json` is the index for skills. Each Accepted CDR row in the index table provides:

- **Target Module path**: the file to load if relevant
- **Type**: rule, persona, example
- **Descriptor**: a short "when to use" summary

The discovery process reads the index first, matches against it (using descriptor + path + type keywords), and loads full file content only for the modules selected as relevant. This progressive-disclosure approach keeps context lean and avoids scanning every file on every invocation.

If `CDR.md` is missing or cannot be parsed, the command falls back to scanning `context_modules/` directly.

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

### Step 3: Load CDR Index (Primary Path)

Read `{TEAM_AI_DIRECTIVES}/CDR.md` and parse the CDR Index table into candidate records.

Extract each table row where `Status` is `Accepted`:
```json
{
  "id": "CDR-2026-001",
  "target_module": "context_modules/rules/security/sql_injection_prevention.md",
  "type": "Rule",
  "descriptor": "SQL injection prevention patterns for all languages"
}
```

Also read `{TEAM_AI_DIRECTIVES}/.skills.json` for the skill registry.

**Fallback**: If `CDR.md` is missing, unparseable, or contains no Accepted rows, read all files from `{TEAM_AI_DIRECTIVES}/context_modules/` directly (constitution.md, personas/, rules/, examples/) and use each file's name and path as the matching surface. This ensures the command works with any valid team-ai-directives knowledge base regardless of CDR maturity.

### Step 4: Match Against Index

For each candidate in the parsed CDR index, determine relevance based on:

**Personas** — Match when:
- Persona's domain (from descriptor or path) matches feature domain
- Persona's role aligns with feature users

**Rules** — Match when:
- Rule descriptor mentions matching technology
- Rule path category aligns with feature type (security, testing, style, etc.)
- Rule descriptor or path matches the patterns being used

**Examples** — Match when:
- Example descriptor/domain/technology overlaps with feature
- Similar feature type or pattern demonstrated

The **descriptor** column is the primary matching surface — it carries the condensed "when to use" summary authored during CDR publication. The **target module path** and **type** provide secondary matching signals.

**Skills**: Match from `.skills.json` using description + categories (existing behavior, unchanged).

### Step 4b: Load Selected Module Bodies

For every module selected as relevant in Step 4, read the full file content from:
`{TEAM_AI_DIRECTIVES}/{target_module}`

Include the full content in the output so the AI agent has the complete directive text without needing a second file read.

### Step 5: Output Discovered Context

Output structured discovery results in this exact format:

```json
{
  "constitution": "/path/to/constitution.md",
  "personas": [
    {"name": "Admin User", "file": "personas/admin.md", "relevance": "high", "cdr_id": "CDR-2026-003"}
  ],
  "rules": [
    {"name": "API Security", "file": "rules/security/api-security.md", "relevance": "high", "category": "security", "cdr_id": "CDR-2026-020"}
  ],
  "examples": [
    {"name": "Payment Flow", "file": "examples/payment-flow.md", "relevance": "medium", "cdr_id": "CDR-2026-001"}
  ],
  "search_metadata": {
    "files_searched": 42,
    "files_with_matches": 8
  }
}
```

The `cdr_id` field links each entry back to its CDR in `CDR.md` for traceability. When using the legacy fallback (no CDR.md), `cdr_id` is omitted.

Include the full file content inline with each entry so the agent has the complete directive text.

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
