---
description: Resolve ambiguities in discovered/proposed CDRs through quick decisions and targeted clarification
handoffs:
  - label: Refine from Feature Context
    agent: adlc.levelup.specify
    prompt: Add context from current feature spec to CDRs
    send: false
  - label: Build Skills
    agent: adlc.levelup.skills
    prompt: Build skills from accepted CDRs
    send: false
  - label: Create PR
    agent: adlc.levelup.implement
    prompt: Compile accepted CDRs to team-ai-directives PR
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

- `"CDR-001 CDR-003"` - Focus on specific CDRs
- `"rules"` - Clarify only rule-type CDRs
- `"all"` - Clarify all pending CDRs
- Empty input: Clarify all CDRs with status "Discovered" or "Proposed"

## Goal

Resolve ambiguities in discovered or proposed CDRs through **quick decisions and targeted clarification**. This is the hybrid approach: batch overview, action picker, and conditional questions only when needed.

**Input**: CDRs from `{REPO_ROOT}/.specify/drafts/cdr.md` with status "Discovered" or "Proposed"

**Output**: Updated CDRs with refined content and new statuses in `.specify/drafts/cdr.md`

## Role & Context

You are acting as a **Context Validator** reviewing discovered patterns. Your role involves:

- **Presenting** a clear overview of all pending CDRs
- **Guiding** users to quick decisions (Accept/Reject/Defer/Investigate/Split)
- **Clarifying** only when needed (Investigate triggers follow-up questions)
- **Validating** rule CDRs against existing rules when appropriate

---

## Execution Steps

### Phase 1: Environment Setup

**Objective**: Initialize CDR infrastructure and resolve paths

Run `{SCRIPT}` from repository root and parse JSON output:

```json
{
  "REPO_ROOT": "/path/to/project",
  "TEAM_DIRECTIVES": "/path/to/team-ai-directives",
  "SKILLS_DRAFTS": "/path/to/project/.specify/drafts/skills",
  "BRANCH": "current-branch"
}
```

### Phase 2: Load Pending CDRs

**Objective**: Load CDRs that need clarification

Read `{REPO_ROOT}/.specify/drafts/cdr.md` and filter:

- **Include**: Status = "Discovered" or "Proposed"
- **Skip**: Status = "Accepted", "Rejected", "Deprecated"

If user specified specific module IDs, filter to those.

### Phase 3: CDR Batch Overview

**Objective**: Present all pending CDRs in a summary table

Show a clear table with key info:

```markdown
## Pending CDRs for Clarification

**Total**: {N} CDRs to review

| # | CDR | Type | Target Module | Source |
|---|-----|------|---------------|--------|
| 1 | CDR-001 | Rule | rules/python/error-handling | Discovered |
| 2 | CDR-002 | Skill | skills/validation | Proposed |
| 3 | CDR-003 | Example | examples/api/clients | Discovered |
```

### Phase 4: Quick Decision Loop

**Objective**: Process each CDR with action picker

For each pending CDR, present the **5 Action Options**:

```markdown
## CDR-{ID}: {Title}

**Context Type**: {type}
**Target Module**: {target}
**Current Status**: {status}

### Choose Action

| # | Action | Description | Follow-up? |
|---|--------|-------------|------------|
| 1 | **Accept** | Approve for implementation | No |
| 2 | **Reject** | Decline with reason | No |
| 3 | **Defer** | Skip for now, keep pending | No |
| 4 | **Investigate** | Need clarification | YES |
| 5 | **Split** | Multiple concerns | YES |

**Your choice** (1-5): _
```

#### Action 1: Accept (No Questions)

Directly update status to **Accepted**:

```markdown
### Decision: Accept

**Status**: Discovered → **Accepted**

Added to accepted list for `/levelup.implement`
```

#### Action 2: Reject (No Questions)

Reject with a reason picker:

```markdown
### Decision: Reject

**Select Reason**:
- [ ] Project-specific (not team-wide)
- [ ] Deprecated/outdated pattern
- [ ] Duplicate of existing directive
- [ ] Out of scope for team-ai-directives
- [ ] Other: {specify}

**Status**: {status} → **Rejected**
```

#### Action 3: Defer (No Questions)

Skip this CDR, keep it pending:

```markdown
### Decision: Defer

CDR kept as {status}, will appear in next clarify session.

**Reason** (optional):
- [ ] Need more context
- [ ] Waiting on team decision
- [ ] Low priority
- [ ] Other: {specify}
```

#### Action 4: Investigate (Follow-up Questions)

**Only ask targeted questions** based on context type:

**For Rule CDRs** (conflict check):

```markdown
### Investigate: Rule CDR

1. **Does this rule conflict with existing rules or constitution?**
   - [ ] No conflicts detected → Skip to question 3
   - [ ] Need to check → Offer `/levelup.validate`

2. **If conflict found, what's the severity?**
   - [ ] CRITICAL - Direct contradiction (must vs never)
   - [ ] ERROR - Logical impossibility
   - [ ] WARNING - Exception conflict
   - [ ] INFO - Scope overlap

3. **What needs clarification?**
   - [ ] Scope (team-wide vs project-specific)
   - [ ] Priority (high vs low impact)
   - [ ] Content (accuracy/completeness)
   - [ ] All of the above
```

**For Skill CDRs** (skill type check):

```markdown
### Investigate: Skill CDR

1. **What's the Skill Type?** (see taxonomy)
   - [ ] Library & API Reference
   - [ ] Product Verification
   - [ ] Data Fetching & Analysis
   - [ ] Business Process Automation
   - [ ] Code Scaffolding & Templates
   - [ ] Code Quality & Review
   - [ ] CI/CD & Deployment
   - [ ] Runbooks
   - [ ] Infrastructure Operations

2. **What needs clarification?**
   - [ ] Trigger keywords
   - [ ] Priority
   - [ ] All of the above
```

**For Other CDRs** (generic):

```markdown
### Investigate: {Type} CDR

1. **What needs clarification?**
   - [ ] Scope (team-wide vs project-specific)
   - [ ] Priority (high vs low impact)
   - [ ] Coverage (new vs enhancement)
   - [ ] Content (accuracy/completeness)
   - [ ] All of the above

2. **Describe what needs work**:
   _{free text response}_
```

#### Action 5: Split (Follow-up Questions)

```markdown
### Split: Multiple Concerns

This CDR covers multiple concerns. How to split?

1. **Split Option**:
   - [ ] Split into separate CDRs (create new ones)
   - [ ] Keep one, reject others (focus on primary)
   - [ ] Merge with existing CDR (if duplicate)

2. **Identify concerns**:
   _{list each concern}_
```

### Phase 5: Process Answers & Update Status

**Objective**: Map actions to statuses and update CDRs

#### Status Determination Logic

| Action | New Status | Notes |
|--------|------------|-------|
| Accept | **Accepted** | Ready for `/levelup.implement` |
| Reject | **Rejected** | Reason documented |
| Defer | Keep as-is | Remains "Discovered" or "Proposed" |
| Investigate → No issues found | **Accepted** | After clarification |
| Investigate → Issues found | **Proposed** | Content updated, needs re-review |
| Split → Accepted parts | **Accepted** | Split content |
| Split → Rejected parts | **Rejected** | Split content |

### Phase 6: Update CDR File

**Objective**: Write all updates to `.specify/drafts/cdr.md`

1. Update status in CDR index table
2. Add clarification metadata to each CDR section
3. For "Investigate" actions, capture the clarification answers

```markdown
### CDR-{ID}: {Title}

**Status**

**Accepted** | Proposed | Rejected

### Clarification

- **Date**: {YYYY-MM-DD}
- **Action**: {Accept|Reject|Defer|Investigate|Split}
- **Clarification Answers** (if applicable):
  - {answer 1}
  - {answer 2}
```

### Phase 7: Summary

**Objective**: Present clarification results

```markdown
## LevelUp Clarify Summary

**Date**: {date}
**Total CDRs Reviewed**: {N}

### Results

| Action | Count |
|--------|-------|
| Accepted | {n} |
| Rejected | {n} |
| Deferred | {n} |
| Needs Re-review | {n} |

### Accepted (Ready for Implementation)

| CDR | Target Module | Type |
|-----|---------------|------|
| CDR-001 | rules/python/error-handling | Rule |
| CDR-002 | skills/validation | Skill |

### Rejected

| CDR | Reason |
|-----|--------|
| CDR-003 | Project-specific |

### Pending (Need Another Pass)

| CDR | Action Needed |
|-----|--------------|
| CDR-004 | Re-review after content update |

### Next Steps

1. **Accepted**: Run `/levelup.implement` to create PR
2. **Needs Re-review**: Edit content, then run `/levelup.clarify` again
3. **Investigate**: After updates, clarify loop: Run `/levelup.clarify` again

### Clarifying Loop

To re-review any CDR:
```bash
/levelup.clarify CDR-{ID}
```

This allows another pass after content updates or additional investigation.
```

### Phase 8: Offer /levelup.validate (Rule CDRs)

**Objective**: Offer conflict validation when investigating rule CDRs

After question 1 in "Investigate" for rule types:

```markdown
### Conflict Check Offer

Would you like to run `/levelup.validate` to check for rule conflicts?

- [ ] Yes, check now → Run `/levelup.validate` first, then continue
- [ ] No, skip → Continue with manual check

Note: `/levelup.validate` scans all rules for conflicts with constitution and each other.
```

### Phase 9: Handoff Options

Present manual handoff options:

```markdown
### Available Handoffs

**Option 1: Refine from Feature Context**
Run `/levelup.specify` to:
- Add evidence from current feature spec
- Link CDRs to implementation

**Option 2: Build Skills**
Run `/levelup.skills {topic}` to:
- Build a skill from accepted CDRs

**Option 3: Create PR**
Run `/levelup.implement` to:
- Compile accepted CDRs into PR
- Submit to team-ai-directives
```

---

## Output Files

| File | Description |
|------|-------------|
| `{REPO_ROOT}/.specify/drafts/cdr.md` | Updated Context Directive Records |

## Notes

- **Batch first**: Always show overview table before individual decisions
- **Quick decisions**: 5 actions replace 13 questions
- **Conditional questions**: Only ask when user chooses "Investigate" or "Split"
- **Clarifying loop**: Run `/levelup.clarify` again after content updates to re-review
- **Conflict check**: Offer `/levelup.validate` for rule CDRs
- No automatic handoff - user decides next step

## Related Commands

- `/levelup.init` - Discover CDRs from codebase
- `/levelup.validate` - Check for rule conflicts (offered during clarify)
- `/levelup.specify` - Refine CDRs from feature context
- `/levelup.skills` - Build skills from accepted CDRs
- `/levelup.implement` - Create PR to team-ai-directives
- `/architect.clarify` - Similar pattern for ADR clarification
