---
description: Generate and validate feature execution traces from implementation metadata.
scripts:
    sh: .specify/extensions/levelup/scripts/bash/generate-trace.sh --json
    ps: .specify/extensions/levelup/scripts/powershell/generate-trace.ps1 -Json
validation_script:
    sh: .specify/extensions/levelup/scripts/bash/validate-trace.sh --json
    ps: .specify/extensions/levelup/scripts/powershell/validate-trace.ps1 -Json
---

## Overview

The `/spec.trace` command generates comprehensive AI session execution traces from implementation metadata and feature artifacts. Traces include a **human-friendly Summary** (Problem -> Key Decisions -> Final Solution) followed by detailed technical sections for tool integration and learning.

**Purpose**:
- **Narrative summary** - Quick scan of what happened (Problem/Decisions/Solution)
- Document AI agent session for reusability
- Capture decision-making patterns and problem-solving approaches
- Record execution context (quality gates, reviews, MCP tracking)
- Identify reusable patterns for similar contexts
- Provide evidence trail (commits, issues, files)

**Output**: `specs/{BRANCH}/trace.md` - Stored with feature artifacts, version-controlled

**Structure**: Summary section (3-part narrative) + 5 technical sections (metadata and patterns)

**Note**: This command generates a feature-local execution artifact. Run `/levelup.specify` after trace to extract CDRs with enriched context.

## When to Use

Run `/spec.trace` after completing `/implement` to capture the full execution session:

```text
/implement -> tasks_meta.json created
     ↓
/spec.trace -> Generate session trace
     ↓
specs/{BRANCH}/trace.md created
     ↓
/levelup.specify -> Consume trace for CDR extraction (optional)
```

**Best Practices**:
- Run after all tasks complete and quality gates pass
- Generate before `/levelup.specify` for richer CDR extraction
- Re-run to update trace as understanding evolves
- Review trace for learning and knowledge transfer

## Execution Flow

### Step 1: Prerequisites Validation

1. **Execute trace generation script**: `{SCRIPT}`
2. **Parse JSON output** for paths and validation results
3. **Prerequisites checked**:
   - `spec.md` exists
   - `plan.md` exists
   - `tasks.md` exists
   - `tasks_meta.json` exists and valid JSON
   - Feature branch is active

If any prerequisite fails, **STOP** with clear error message directing user to run required commands first.

### Step 2: Trace Generation

The generation script automatically extracts:

#### Summary Section

Human-friendly 3-part narrative placed at the top:

**Problem**:
- Extracted from spec mission + all user stories
- Synthesized into 1-2 sentence goal statement

**Key Decisions** (chronologically):
- Architecture decisions (framework, design choices)
- Technology choices (libraries, tools)
- Testing strategy (TDD, risk-based)
- Process decisions (SYNC/ASYNC breakdown)
- Integration choices (APIs, external services)

**Final Solution**:
- Outcome statement with key metrics
- Quality gate pass rate
- User story completion count
- Commit reference

#### Section 1: Session Overview
- Feature title and mission
- Key architectural decisions from plan
- Implementation approach summary

#### Section 2: Decision Patterns
- Triage classification (SYNC vs ASYNC breakdown)
- Technology choices and stack
- Problem-solving approaches used

#### Section 3: Execution Context
- Quality gate statistics (passed/failed/total)
- Execution modes distribution (SYNC/ASYNC)
- Review status (micro-reviewed/macro-reviewed)
- MCP job tracking (if applicable)

#### Section 4: Reusable Patterns
- Effective methodologies (ASYNC delegation success, micro-review patterns)
- Testing approaches (TDD, risk-based testing)
- Applicable contexts for pattern reuse

#### Section 5: Evidence Links
- Implementation commits and messages
- Modified code paths
- Feature artifact locations

**Output**: Trace file at `specs/{BRANCH}/trace.md`

### Step 3: Trace Validation

1. **Execute validation script**: `{VALIDATION_SCRIPT}`
2. **Parse validation results**:
   - Section completeness (all 5 sections populated)
   - Coverage percentage (sections_valid / total_sections)
   - Quality gate pass rate
   - Warnings and recommendations

#### Validation Criteria

| Criterion | Requirement |
|-----------|-------------|
| Section existence | Each section exists and has >=5 lines |
| Coverage | All 5 sections present (80%+ coverage required) |
| Quality gates | Pass rate >=80% (warning if lower) |
| Evidence links | Include commits and issues |
| Reusable patterns | Identified |

### Step 4: Report Results

Display validation report including file path, coverage, quality gate stats, and any recommendations.

## Integration Points

- `/levelup.specify` reads `trace.md` if it exists (optional)
- `/spec.evidence` can later consume `trace.md` as a feature verification input
- Version-controlled with feature artifacts

## Error Handling

**Missing Prerequisites**:
```text
ERROR: tasks_meta.json not found
Please run /implement before generating a trace.
```

**Invalid JSON**:
```text
ERROR: tasks_meta.json is not valid JSON
Check execution metadata for corruption.
```

**Validation Failures**:
- Non-blocking: Trace still generated
- Warnings displayed with recommendations
- User can address gaps and re-run `/spec.trace`

## Important Notes

- **Storage**: Trace stored in `specs/{BRANCH}/` with other artifacts
- **Overwrite**: Previous trace replaced (single latest trace)
- **Optional**: Trace not required for workflow but enhances `/levelup.specify`
- **Version Control**: Commit `trace.md` with feature implementation

## Success Criteria

| Criterion | Target |
|-----------|--------|
| Trace file generated | `specs/{BRANCH}/trace.md` |
| Summary section | Present with Problem/Decisions/Solution |
| All sections populated | Summary + 5 technical sections (6/6) |
| Coverage | >=80% |
| Quality gate statistics | Extracted correctly |
| Evidence links | Include commits and issues |
| Validation report | Displays clearly |

## Related Commands

- `/spec.implement` - Produces the execution metadata trace relies on
- `/levelup.specify` - Extract CDRs from feature context (uses trace if available)
