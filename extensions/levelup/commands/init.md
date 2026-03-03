---
description: Scan codebase and discover Context Decision Records (CDRs) for team-ai-directives contributions
handoffs:
  - label: Resolve Ambiguities
    agent: levelup.clarify
    prompt: |
      Review CDRs discovered from brownfield codebase analysis.
      Ask questions about:
      - Pattern validity (are inferred patterns still relevant?)
      - Team scope (is this pattern team-wide or project-specific?)
      - Existing coverage (does team-ai-directives already have this?)
      - Priority (high-value vs nice-to-have patterns)
      Focus on validating assumptions, not suggesting new patterns.
    send: false
  - label: Refine from Feature Context
    agent: levelup.spec
    prompt: Refine CDRs using current feature spec context
    send: false
scripts:
  sh: scripts/bash/setup-levelup.sh --json
  ps: scripts/powershell/setup-levelup.ps1 -Json
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

**Examples of User Input**:

- `"Python FastAPI backend with PostgreSQL"` - Focus on Python patterns
- `"Focus on testing patterns"` - Narrow to testing-related CDRs
- `"--cdr-heuristic all"` - Document all patterns, not just surprising ones
- `"--focus rules"` - Only discover rule-type patterns
- Empty input: Scan entire codebase for all context types

When users provide context, use it to focus the discovery effort.

## Goal

Scan an **existing codebase** (brownfield) and discover patterns that could become contributions to team-ai-directives. Create **Context Decision Records (CDRs)** documenting discovered patterns.

**Output**:

1. **CDRs** documenting discovered context patterns in `.specify/memory/cdr.md`
2. **Summary** of discovered patterns by context type
3. **Manual handoff options** to `/levelup.clarify` or `/levelup.spec`

**Key Concept**:

This command is the "Context Archaeologist" - it uncovers implicit team AI directive patterns from code, similar to how `/architect.init` discovers architecture decisions.

### Flags

- `--cdr-heuristic HEURISTIC`: CDR generation strategy
  - `surprising` (default): Only document patterns not already in team-ai-directives
  - `all`: Document all discovered patterns
  - `minimal`: Only high-value/novel patterns

- `--focus AREA`: Focus on specific context type
  - `rules`: Only scan for coding rules
  - `personas`: Only scan for role patterns
  - `examples`: Only scan for example-worthy code
  - `constitution`: Only scan for governance patterns
  - `skills`: Only scan for skill-worthy capabilities

- `--no-decompose`: Disable automatic context type categorization

## Role & Context

You are acting as a **Context Archaeologist** uncovering implicit team AI directive patterns from code. Your role involves:

- **Scanning** codebase for coding patterns and best practices
- **Inferring** context modules that would benefit other projects
- **Documenting** discovered patterns as CDRs
- **Comparing** against existing team-ai-directives to avoid duplicates

### Brownfield Context Discovery

| Context Type | What to Look For | Example Patterns |
|--------------|------------------|------------------|
| **Rules** | Coding patterns, error handling, testing | Custom error classes, test fixtures, logging patterns |
| **Personas** | Domain expertise, specialized logic | Domain-specific validation, business rule implementations |
| **Examples** | Reusable code, prompt patterns | API implementations, test patterns, configuration |
| **Constitution** | Governance, quality standards | Code review patterns, documentation standards |
| **Skills** | Self-contained capabilities | Deployment scripts, data processing pipelines |

## Outline

1. **Environment Setup**: Resolve team-ai-directives path and initialize CDR file
2. **Load Existing Directives**: Read team-ai-directives to compare against
3. **Codebase Scan**: Analyze project for context patterns
4. **Pattern Detection**: Identify patterns by context type
5. **Deduplication**: Filter out patterns already in team-ai-directives
6. **CDR Generation**: Create CDRs for discovered patterns (status: "Discovered")
7. **Gap Analysis**: Identify areas where patterns are unclear
8. **Output**: Write CDRs to `.specify/memory/cdr.md`
9. **Summary**: Present findings with next step options

## Execution Steps

### Phase 1: Environment Setup

**Objective**: Resolve paths and initialize CDR infrastructure

#### Step 1: Resolve Team AI Directives Path

Resolve the team-ai-directives repository path in this order:

1. `SPECIFY_TEAM_DIRECTIVES` environment variable
2. `.specify/team-ai-directives` (submodule - recommended)
3. `.specify/memory/team-ai-directives` (clone - legacy)

```bash
TEAM_DIRECTIVES="${SPECIFY_TEAM_DIRECTIVES:-}"
if [[ -z "$TEAM_DIRECTIVES" ]]; then
    if [[ -d ".specify/team-ai-directives" ]]; then
        TEAM_DIRECTIVES=".specify/team-ai-directives"
    elif [[ -d ".specify/memory/team-ai-directives" ]]; then
        TEAM_DIRECTIVES=".specify/memory/team-ai-directives"
    fi
fi
```

If no team-ai-directives found, **STOP** and instruct user:

```
Team AI directives repository not found.
Run: specify init --team-ai-directives <path-or-url>
```

#### Step 2: Initialize CDR File

Run `{SCRIPT}` to set up the CDR infrastructure:

- Creates `.specify/memory/cdr.md` if not exists (using CDR template)
- Returns JSON with `CDR_FILE`, `TEAM_DIRECTIVES`, `REPO_ROOT`

If CDR file already exists, load current CDRs and continue (append new discoveries).

### Phase 2: Load Existing Directives

**Objective**: Load team-ai-directives to compare against and avoid duplicates

#### Step 1: Load Constitution

Read `{TEAM_DIRECTIVES}/context_modules/constitution.md` for team principles.

#### Step 2: Load Existing Rules

Scan `{TEAM_DIRECTIVES}/context_modules/rules/` directory:

```bash
find "$TEAM_DIRECTIVES/context_modules/rules" -name "*.md" -type f
```

Build a list of existing rule topics/patterns.

#### Step 3: Load Existing Personas

Scan `{TEAM_DIRECTIVES}/context_modules/personas/` directory.

#### Step 4: Load Existing Examples

Scan `{TEAM_DIRECTIVES}/context_modules/examples/` directory.

#### Step 5: Load Existing Skills

Scan `{TEAM_DIRECTIVES}/skills/` directory and read `.skills.json` if exists.

### Phase 3: Codebase Scan

**Objective**: Analyze the codebase for context patterns

#### Step 1: Technology Detection

Identify the project's technology stack:

| File/Pattern | Technology |
|--------------|------------|
| `package.json` | Node.js/JavaScript |
| `requirements.txt`, `pyproject.toml` | Python |
| `go.mod` | Go |
| `pom.xml`, `build.gradle` | Java |
| `Cargo.toml` | Rust |
| `Dockerfile`, `docker-compose.yml` | Containerization |
| `.github/workflows/` | GitHub Actions |
| `terraform/`, `*.tf` | Infrastructure as Code |

#### Step 2: Code Pattern Scan

For each detected technology, scan for patterns:

**Python Patterns**:
- Custom exception classes → Potential rule: error handling
- Pytest fixtures → Potential example: testing patterns
- Pydantic models → Potential rule: validation patterns
- Logging configuration → Potential rule: observability

**JavaScript/TypeScript Patterns**:
- Custom hooks → Potential example: React patterns
- Error boundaries → Potential rule: error handling
- Test utilities → Potential example: testing
- API clients → Potential example: integration patterns

**Infrastructure Patterns**:
- Deployment scripts → Potential skill
- CI/CD workflows → Potential rule: automation
- Docker configurations → Potential example: containerization

#### Step 3: Documentation Scan

Scan for documented patterns:

- `README.md` - Project conventions
- `CONTRIBUTING.md` - Contribution guidelines
- `docs/` - Architecture decisions, patterns
- Code comments with `TODO`, `FIXME`, `NOTE` - Potential improvements

### Phase 4: Pattern Detection

**Objective**: Categorize discovered patterns by context type

#### Context Type Classification

For each discovered pattern, classify:

| Pattern Characteristic | Likely Context Type |
|------------------------|---------------------|
| Coding convention, "always do X" | **Rule** |
| Role-specific expertise, "as a X" | **Persona** |
| Working code snippet, reusable | **Example** |
| Fundamental principle, governance | **Constitution** |
| Self-contained capability, workflow | **Skill** |

#### Heuristic Application

Apply the `--cdr-heuristic` setting:

**`surprising` (default)**:
- Only patterns NOT found in existing team-ai-directives
- Skip obvious/common patterns for the technology
- Focus on project-specific innovations

**`all`**:
- Document every pattern found
- Useful for comprehensive audit

**`minimal`**:
- Only high-value patterns
- Patterns with clear evidence of success
- Skip uncertain or minor patterns

### Phase 5: Deduplication

**Objective**: Filter out patterns already covered in team-ai-directives

For each discovered pattern:

1. Compare against loaded rules, personas, examples, skills
2. Use keyword matching and semantic similarity
3. If >80% overlap with existing directive, skip
4. If partial overlap, note for potential enhancement (not new CDR)

### Phase 6: CDR Generation

**Objective**: Create CDRs for discovered patterns

For each unique pattern, generate a CDR with:

```markdown
## CDR-{NNN}: {Pattern Title}

### Status
**Discovered**

### Date
{TODAY}

### Source
Brownfield codebase scan via /levelup.init

### Target Module
{context_modules/rules|personas|examples|skills}/{path}

### Context Type
{Rule|Persona|Example|Constitution Amendment|Skill}

### Context
{Description of the pattern and why it was discovered}

**Discovery Evidence:**
- {File path where pattern was found}
- {Code snippet or reference}

### Decision
{What context module to add to team-ai-directives}

**Proposed Content:**
```markdown
{Actual content to add}
```

### Evidence
- {Link to code file}
- {Link to test demonstrating pattern}

### Constitution Alignment
| Principle | Alignment | Notes |
|-----------|-----------|-------|
| {Principle} | Compliant | {How it aligns} |
```

Assign sequential CDR IDs starting from the highest existing ID + 1.

### Phase 7: Gap Analysis

**Objective**: Identify areas where patterns are unclear

Document gaps for `/levelup.clarify`:

- Patterns with conflicting implementations
- Patterns without clear evidence
- Potential patterns needing team input
- Areas where multiple approaches exist

### Phase 8: Output

**Objective**: Write CDRs to file and present summary

#### Step 1: Write CDRs

Append generated CDRs to `.specify/memory/cdr.md`:

- Update CDR Index table
- Add each CDR entry
- Preserve existing CDRs (don't overwrite)

#### Step 2: Create Summary

Present discovery summary:

```markdown
## LevelUp Init Summary

**Project**: {project-name}
**Scan Date**: {date}
**Team Directives**: {path}

### Discovered CDRs

| ID | Target Module | Context Type | Confidence |
|----|---------------|--------------|------------|
| CDR-001 | rules/python/error-handling | Rule | High |
| CDR-002 | examples/testing/fixtures | Example | Medium |

### Statistics

- **Total Patterns Scanned**: {N}
- **Patterns Already in Team Directives**: {N}
- **New CDRs Generated**: {N}
- **Gaps Identified**: {N}

### By Context Type

| Type | Count |
|------|-------|
| Rules | {N} |
| Personas | {N} |
| Examples | {N} |
| Constitution | {N} |
| Skills | {N} |

### Next Steps

1. Review CDRs in `.specify/memory/cdr.md`
2. Run `/levelup.clarify` to resolve ambiguities
3. Mark CDRs as "Accepted" or "Rejected"
4. Run `/levelup.implement` to create PR
```

### Phase 9: Handoff Options

Present manual handoff options (no auto-trigger):

```markdown
### Available Handoffs

**Option 1: Resolve Ambiguities**
Run `/levelup.clarify` to:
- Validate discovered patterns
- Ask clarifying questions
- Refine CDR content

**Option 2: Refine from Feature Context**
Run `/levelup.spec` to:
- Add context from current feature spec
- Link CDRs to implementation evidence

**Option 3: Build Skills**
Run `/levelup.skills {topic}` to:
- Build a skill from accepted CDRs

**Option 4: Create PR**
Run `/levelup.implement` to:
- Compile accepted CDRs into PR
- Submit to team-ai-directives
```

## Output Files

| File | Description |
|------|-------------|
| `.specify/memory/cdr.md` | Context Decision Records |

## Notes

- CDRs start with status "Discovered" - they need review before implementation
- Existing CDRs are preserved; new discoveries are appended
- The `--cdr-heuristic` flag significantly affects output volume
- Gaps are documented for follow-up with `/levelup.clarify`
- No automatic handoff - user decides next step

## Related Commands

- `/levelup.clarify` - Resolve ambiguities in discovered CDRs
- `/levelup.spec` - Refine CDRs from feature context
- `/levelup.skills` - Build skills from accepted CDRs
- `/levelup.implement` - Create PR to team-ai-directives
- `/architect.init` - Similar pattern for ADR discovery
