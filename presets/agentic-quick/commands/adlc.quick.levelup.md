---
description: Quick-contribute a directive to team-ai-directives (LOW-FRICTION MODE)
model-invocation: true
mode: quick
scripts:
  sh: |
    for path in "$(pwd)/.specify/scripts/bash/common.sh" "$(dirname "$(pwd)")/scripts/bash/common.sh"; do
        if [[ -f "$path" ]]; then
            source "$path" 2>/dev/null && break
        fi
    done
    REPO_ROOT=$(get_repo_root 2>/dev/null || git rev-parse --show-toplevel 2>/dev/null || pwd)
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    echo "REPO_ROOT='$REPO_ROOT'"
    echo "CURRENT_BRANCH='$CURRENT_BRANCH'"
    # Resolve TEAM_DIRECTIVES
    TEAM_DIRECTIVES_RESOLVED=false
    if [[ -n "${SPECIFY_TEAM_DIRECTIVES:-}" ]]; then
        echo "TEAM_DIRECTIVES='$SPECIFY_TEAM_DIRECTIVES'"; TEAM_DIRECTIVES_RESOLVED=true
    fi
    if ! $TEAM_DIRECTIVES_RESOLVED && [[ -f "$REPO_ROOT/.specify/init-options.json" ]]; then
        TD_PATH=$(python3 -c "import json; d=json.load(open('$REPO_ROOT/.specify/init-options.json')); print(d.get('team_ai_directives',''))" 2>/dev/null)
        if [[ -n "$TD_PATH" ]]; then
            echo "TEAM_DIRECTIVES='$TD_PATH'"; TEAM_DIRECTIVES_RESOLVED=true
        fi
    fi
    if ! $TEAM_DIRECTIVES_RESOLVED && [[ -d "$REPO_ROOT/.specify/team-ai-directives" ]]; then
        echo "TEAM_DIRECTIVES='$REPO_ROOT/.specify/team-ai-directives'"; TEAM_DIRECTIVES_RESOLVED=true
    fi
    if ! $TEAM_DIRECTIVES_RESOLVED; then
        echo "TEAM_DIRECTIVES=''"
    fi
  ps: |
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $commonPath = Join-Path $scriptDir "..\..\..\scripts\powershell\common.ps1"
    if (Test-Path $commonPath) { . $commonPath }
    $repoRoot = Get-RepoRoot
    $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $currentBranch) { $currentBranch = "main" }
    "REPO_ROOT='$repoRoot'"
    "CURRENT_BRANCH='$currentBranch'"
    $tdPath = $null
    if ($env:SPECIFY_TEAM_DIRECTIVES) {
        $tdPath = $env:SPECIFY_TEAM_DIRECTIVES
    } elseif (Test-Path "$repoRoot\.specify\init-options.json") {
        $json = Get-Content "$repoRoot\.specify\init-options.json" -Raw | ConvertFrom-Json
        $tdPath = $json.team_ai_directives
    } elseif (Test-Path "$repoRoot\.specify\team-ai-directives") {
        $tdPath = "$repoRoot\.specify\team-ai-directives"
    }
    if ($tdPath) { "TEAM_DIRECTIVES='$tdPath'" } else { "TEAM_DIRECTIVES=''" }
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

**Examples of User Input**:
- `"Add a rule for SQL injection prevention"` — Contribute a new rule directive
- `"Create a persona for data engineers"` — Create a new persona directive
- `"Document error handling patterns as an example"` — Contribute an example directive
- `"Constitution principle: prefer composition over inheritance"` — Create or amend a constitution principle
- `"Build a skill for code review patterns"` — Create a skill directive (type: Skill)
- Empty input: Ask the user what they want to contribute

## Design Principles

1. **Low friction** — Exactly 1 mandatory stop (Phase 4 User Review)
2. **Verifiable phases** — Each phase has entry criteria, automated gate, and exit criteria
3. **Quality gates** — Signal Gate + Conflict Detection ensure contributions are valuable and non-duplicative
4. **Descriptor-first** — Every CDR includes a Descriptor (the search surface for `/team.discover`)
5. **Skill companion** — Auto-detect if the directive is actionable enough for a skill; offer inline

---

## Phase 1: Parse & Classify

**Entry**: `$ARGUMENTS` provided by user (or empty → ask user for their directive idea)

**Objective**: Determine what type of directive is being contributed and extract key fields.

### Step 1: Classify Context Type

From the user input, determine the **Context Type**:

| Context Type | When | Example Input |
|-------------|------|---------------|
| **Rule** | A pattern, convention, or constraint for how code should be written | "SQL injection prevention patterns for all languages" |
| **Persona** | A role definition with expertise areas and communication patterns | "Data engineer persona with Python and SQL expertise" |
| **Example** | A code example demonstrating a specific pattern | "Authentication error handling in FastAPI" |
| **Constitution Creation** | A new team principle with supporting evidence | "Prefer composition over inheritance" |
| **Constitution Amendment** | A modification to an existing constitution principle | "Extend the testing principle to include property-based testing" |
| **Skill** | A repeatable instruction set for the AI agent to follow | "Code review checklist skill for pull requests" |

**Gate: Classification Confidence**
- If the input clearly matches one type → proceed
- If the input is ambiguous → present options to the user
- If no type matches → STOP, ask user to clarify their intent

### Step 2: Extract Key Fields

Extract from user input:
- **Title**: Concise directive title (e.g., "SQL Injection Prevention")
- **Target Module Path**: Determine the correct path in `context_modules/`:
  - Rules: `context_modules/rules/{domain}/{slug}.md` (e.g., `security/sql-injection-prevention.md`)
  - Personas: `context_modules/personas/{slug}.md`
  - Examples: `context_modules/examples/{category}/{slug}.md`
  - Constitution: `context_modules/constitution.md` (for amendments, append to existing file — do not replace)
- **Description**: One-sentence summary of what the directive covers
- **Rationale**: Why this directive matters (from user input)
- **Initial Evidence**: Any commits, files, or code references the user provides

**Exit**: `{type, title, target_module, description, rationale, evidence}` confirmed

---

## Phase 2: Structure CDR + Detect Skill + Generate Descriptor

**Entry**: Phase 1 complete with valid classification and extracted fields

**Objective**: Build the full CDR schema including Descriptor, and detect if a companion skill is warranted.

### Step 1: Assign CDR ID

Format: `CDR-{NNN}` (3-digit zero-padded, e.g., `CDR-001`)

Check `{TEAM_DIRECTIVES}/CDR.md` for the highest existing `CDR-{NNN}` number for the **current year**; increment from there. If CDR.md doesn't exist, start at `CDR-001`.

### Step 2: Build Full CDR Schema

Generate the complete CDR entry matching the canonical `levelup.implement` format:

```markdown
## CDR-{NNN}: {Title}

### Status
**Accepted** | Proposed | Rejected

### Dates
- **Created**: {today} (from evidence)
- **Modified**: {today} (publication date)
- **Verified**: {today} (initial verification)
- **Age**: {age_days} days

### Source
{project-name}

### Target Module
`{target_module}`

### Context Type
{type}

### Descriptor

{one-line "when to use" summary}

Derive the Descriptor from the Context and Decision sections — e.g., "SQL injection prevention patterns for all languages" or "Java Google style guide conventions for new projects".

### Signal Gate

✓ Team-wide applicable {if yes}
✓ High value (>30min saved) {if yes}
✓ Unique (no duplicate) {if yes}
✓ Concrete evidence available {if yes/fail}

### Context

{Why this pattern matters — from user input and rationale}

### Decision

{What was decided — the directive itself}

### Evidence

Structured list of commits and file paths:

```yaml
- type: commit
  value: {commit_sha}
  description: "{description}"
- type: file
  value: {file_path}
```

If no concrete evidence, use: `- type: note
  value: "User-provided rationale"`
```

### Step 3: Generate Descriptor

Write a one-line "when to use" summary derived from the Context and Decision sections. This becomes the search surface in the CDR Index table for `/team.discover`.

Examples:
- "SQL injection prevention patterns for all languages"
- "Java Google style guide conventions for new projects"
- "Authentication error handling for REST APIs"

### Step 4: Build Context Module YAML Frontmatter

Build the YAML frontmatter for the target module file (matches `levelup.implement` format — **no** `descriptor` in frontmatter):

```yaml
---
type: {type}
id: {id}
title: "{title}"
description: "{description}"
cdr_ref: {cdr_ref}
created: {today}
modified: {today}
verified: {today}
timestamp: {today}
tags:
  - {tag}
age_days: {age_days}
evidence:
  - type: commit
    value: {commit_sha}
    description: "{description}"
  - type: file
    value: {file_path}
---
```

ID generation rule (from `team.repair`):
1. Strip the context type directory prefix (`rules/`, `personas/`, `examples/`)
2. Remove `.md` extension
3. Replace `/` with `-`
4. Prepend type prefix: `rule-`, `persona-`, `example-`
5. Example: `rules/security/sql-injection-prevention.md` → `rule-security-sql-injection-prevention`

### Step 5: Detect Skill Companion

If the Context Type is **not** Skill, evaluate whether this pattern is actionable enough for a skill:

| Criterion | Yes → Skill Candidate |
|-----------|----------------------|
| Has clear multi-step instructions? | ✓ |
| Is the pattern repeatable across projects? | ✓ |
| Can the user describe a workflow with steps? | ✓ |

**If skill candidate**: Generate a companion SKILL.md draft:

```markdown
---
name: {name}
description: {description}
source: team-ai-directives
version: 1.0.0
---

# {Name}

{Description with trigger keywords}

## When to Use
- {Condition 1}

## Steps
1. {Step 1}

## Example
{Minimal example}

## Verification
{How to verify correctness}

## Related
- CDRs: {cdr_ref list}
```

Present the skill candidate to the user during Phase 4 as an optional addition.

**Gate: CDR Completeness Check**
- All CDR schema fields populated? → proceed
- YAML frontmatter valid and parseable? → proceed
- Descriptor derived and non-empty? → proceed
- Any fail → auto-retry once with refinement; if still fails, flag for user review

**Exit**: CDR ready for validation + optional skill draft

---

## Phase 3: Signal Gate + Cross-System Validation

**Entry**: Phase 2 complete with valid CDR + optional skill draft

**Objective**: Validate the CDR against quality gates and check for conflicts with existing directives.

### Gate A: Signal Gate

Load `{TEAM_DIRECTIVES}/CDR.md` and `.skills.json`, then check all 4 criteria:

1. **Team-wide applicable** — Does this apply across multiple projects/teams, not just one?
2. **High value (>30min saved)** — Will this save measurable time or prevent significant issues?
3. **Unique (no duplicate)** — Is this distinct from existing directives in CDR.md? Check Descriptor + Target Module for overlap.
4. **Concrete evidence available** — Does the user provide specific code, commits, or file references?

**Outcomes**:
- **All 4 pass** → No flags; proceed
- **1–3 fail** → Flag as "low-signal" with warnings per criterion. Continue (not a hard stop — quick mode)
- **All 4 fail** → Flag as "very low signal". Present strong warning to user in Phase 4

### Gate B: Conflict/Overlap Detection

Load existing directives from `{TEAM_DIRECTIVES}/context_modules/` (or CDR.md if available).

Check for:
- **Duplicate target** — Does the same Target Module path already exist? → Blocked
- **Rule conflict** — Does the proposed rule contradict an existing one? (e.g., "must use tabs" vs "must use spaces") → Blocked
- **Scope overlap** — Does the proposed directive substantially overlap with an existing one? → Flagged

**Outcomes**:
- **No conflicts** → Proceed
- **Duplicate target or rule conflict** → **HARD STOP**: BLOCKED. Redirect user to `/levelup.clarify` with details of the conflict and suggest merging or replacing the existing directive
- **Scope overlap only** → Flag as warning, present in Phase 4 review

**Exit**: CDR passes all gates (or flagged with clear warnings)

---

## ⚠️ Phase 4: User Review (Mandatory Stop)

**Entry**: Phases 1–3 complete; CDR validated with gate results

**Objective**: Present the full CDR to the user and get explicit approval.

Present in this format:

```
╔══════════════════════════════════════════════════════════╗
║  QUICK LEVELUP — Review & Publish                       ║
╠══════════════════════════════════════════════════════════╣
║  CDR Type:  {type}                                      ║
║  Title:     {title}                                     ║
║  Target:    {TEAM_DIRECTIVES}/{target_module}            ║
║  Descriptor: {descriptor}                                ║
║──────────────────────────────────────────────────────────║
║  Signal Gate:                                            ║
║    ✓ Team-wide applicable                                ║
║    ✓ High value (>30min saved)                           ║
║    {✓/✗} Unique (no duplicate)                           ║
║    ✓ Concrete evidence                                   ║
║──────────────────────────────────────────────────────────║
║  Conflict Check: {No conflicts / OR flag description}    ║
║──────────────────────────────────────────────────────────║
║  Companion Skill: {yes — preview / no}                   ║
║──────────────────────────────────────────────────────────║
║  Options:                                                ║
║  1. Approve & Publish ✓                                   ║
║  2. Edit / refine (return to Phase 2)                    ║
║  3. Cancel ✗                                             ║
╚══════════════════════════════════════════════════════════╝

  STOP HERE — Wait for user input
```

**Gate: User Decision**
- **Approve** → Proceed to Phase 5
- **Edit** → Go back to Phase 2 with specific refinement instructions
- **Cancel** → Exit cleanly; CC the CDR draft if available for later use

**Exit**: Approved with user consent

---

## Phase 5: Publish to TD Repo

**Entry**: User approved the CDR in Phase 4

**Objective**: Create the context module file, update CDR.md, and commit to team-ai-directives.

### Step 1: Resolve TEAM_DIRECTIVES Path

From script output (`TEAM_DIRECTIVES`):
1. Clone if not present: `git clone {url} {TEAM_DIRECTIVES}` (use URL from init-options.json or env)
2. If TEAM_DIRECTIVES is empty and not configured → STOP with instructions:
   ```
   Team AI Directories not configured.
   Run: specify init --team-ai-directives <path-or-url>
   Or set: export SPECIFY_TEAM_DIRECTIVES=/path/to/team-ai-directives
   ```

### Step 2: Create Branch

```bash
cd "$TEAM_DIRECTIVES"
git checkout main
git pull origin main
git checkout -b quick.levelup/{timestamp}
```

If the git extension is installed, use `git.feature` instead: `git.feature --name quick.levelup/{timestamp} --base main`.

### Step 3: Create Context Module File

Write the target module file with YAML frontmatter + directive content:

`{TEAM_DIRECTIVES}/{target_module}`

```markdown
---
type: {type}
id: {id}
title: "{title}"
description: "{description}"
cdr_ref: {cdr_ref}
created: {today}
modified: {today}
verified: {today}
timestamp: {today}
tags:
  - {tag}
age_days: {age_days}
evidence:
  - type: commit
    value: {commit_sha}
    description: "{description}"
  - type: file
    value: {file_path}
---

> ⚠️ **Memory Verification**
> This directive is {age_days} days old. Before applying:
> - [ ] Rule is actively followed by team
> - [ ] No conflicting rules introduced

# {Title}

{Directive content from CDR Decision section}

## Source

Contributed from: {project-name}
CDR: {cdr_ref}
Date: {today}

## Evidence

{Evidence section from CDR}
```

### Step 4: Update CDR.md

Create or update `{TEAM_DIRECTIVES}/CDR.md`:

**If CDR.md exists**: Append new row to the index table and add the full CDR entry at the bottom.

**If CDR.md doesn't exist**: Create new file:

```markdown
# Context Directive Records

Context Directive Records tracking approved contributions to team-ai-directives.

> **Memory Engineering**: This index tracks directive freshness. Run `/levelup.validate` to update verification timestamps.

## CDR Index

| ID | Target Module | Type | Status | Created | Verified | Age | Descriptor |
|----|---------------|------|--------|---------|----------|-----|------------|
| {cdr_ref} | {target_module} | {type} | Accepted | {today} | {today} | 0d | {descriptor} |

**Stats**: 1 CDR | Last Updated: {today}

---

{Full CDR entry from Phase 2}
```

### Step 5: Create Skill Files (if applicable)

If a skill companion was approved:
1. Create `{TEAM_DIRECTIVES}/skills/{name}/SKILL.md`
2. Create `{TEAM_DIRECTIVES}/skills/{name}/.skills-entry.json`
3. Update `{TEAM_DIRECTIVES}/.skills.json`

### Step 6: Commit

Use the git extension or raw git if extension is unavailable:

```
git.commit --message "quick.levelup: {cdr_ref} - {title}"
```

If git extension is unavailable:

```bash
cd "$TEAM_DIRECTIVES"
git add -A
git commit -m "quick.levelup: {cdr_ref} - {title}"
```

**Gate: Output Artifact Verification**

**MUST DO BEFORE PROCEEDING**:

| Check | Pass/Fail |
|-------|-----------|
| Context module file exists at expected path | ✓/✗ |
| YAML frontmatter is parseable | ✓/✗ |
| CDR.md exists with new entry appended | ✓/✗ |
| Descriptor column present in CDR.md index | ✓/✗ |
| Skill files created (if applicable) | ✓/✗ |
| Working tree is clean (committed) | ✓/✗ |

If ANY check fails → **STOP**, report which artifacts are missing, and fix before proceeding.

**Exit**: Committed branch ready for PR

---

## Phase 6: PR + Summary

**Entry**: Phase 5 committed successfully

**Objective**: Create a PR and summarize what was accomplished.

### Step 1: Push + Create PR

Use the git extension or raw git if extension is unavailable:

```
git.publish --title "quick.levelup: {cdr_ref} - {title}" --draft
```

If git extension is unavailable and MCP `create_pull_request` (GitHub) or `create_merge_request` (GitLab) is available:
1. Push the branch: `git push origin quick.levelup/{timestamp}`
2. Create a PR with:
   - Title: `quick.levelup: {cdr_ref} - {title}`
   - Body: Summary of what was contributed, including the Descriptor
   - Type: Draft (not ready for review until `/levelup.validate` ran)

If both git extension and MCP unavailable:
1. Print manual push instructions:

```bash
cd "{TEAM_DIRECTIVES}"
git push origin quick.levelup/{timestamp}
# Then create a PR at: {repo_url}/pull/new/quick.levelup/{timestamp}
```

### Step 2: Summary

```
╔══════════════════════════════════════════════════════════════╗
║  QUICK LEVELUP — Summary                                    ║
╠══════════════════════════════════════════════════════════════╣
║  ✓ CDR {cdr_ref} → {target_module}                          ║
║  ✓ Descriptor: {descriptor}                                  ║
║  ✓ CDR.md updated                                            ║
║  {✓ Skill: {name} → skills/{name}/ (if applicable)}          ║
║                                                              ║
║  Branch: quick.levelup/{timestamp}                          ║
║  {✓ PR created: {pr_url}}                                    ║
║  {→ Push + create PR at: {manual_url}}                       ║
║                                                              ║
║  Next Step: /levelup.validate                                ║
╚══════════════════════════════════════════════════════════════╝
```

**Gate: PR Creation Verification**
- MCP created PR → confirm URL is valid
- Manual mode → verify instructions are complete and actionable

**Exit**: Summary presented; handoff to `/levelup.validate`
