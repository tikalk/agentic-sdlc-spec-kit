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

Resolve ambiguities in discovered or proposed CDRs through **system-discovered assessments, recommended actions, and targeted clarification**. This is a hybrid approach: batch overview with auto-assessed gaps, recommended actions, and conditional one-question-at-a-time clarification only when needed.

**Input**: CDRs from `{REPO_ROOT}/.specify/drafts/cdr.md` with status "Discovered" or "Proposed"

**Output**: Updated CDRs with refined content and new statuses in `.specify/drafts/cdr.md`

## Role & Context

You are acting as a **Context Validator** reviewing discovered patterns. Your role involves:

- **Auto-assessing** each CDR for validity, scope, coverage, and priority from code evidence
- **Presenting** a batch overview with system-recommended actions
- **Guiding** users to quick decisions (Accept/Reject/Defer/Investigate/Split)
- **Clarifying** one question at a time only when Investigation is needed, with recommended answers
- **Validating** rule CDRs against existing rules when appropriate

---

## Execution Steps

### Phase 0: Pre-Validation

**Objective**: Validate CDR completeness before proceeding

For each pending CDR, check:

1. **Content completeness**: Does the CDR have Context, Decision, and Evidence sections?
2. **Target module validity**: Is the target module path well-formed?
3. **Evidence presence**: Does the CDR reference specific code files or snippets?

If any CDR fails pre-validation:

```markdown
## CDR Pre-Validation Issues

The following CDRs need more information before clarification:

| CDR | Issue | Required |
|-----|-------|----------|
| CDR-XXX | Missing Evidence section | Add code references |
| CDR-YYY | Empty proposed content | Add proposed directive content |

These CDRs will be skipped. Run `/levelup.specify` to add missing context.
```

Skip invalid CDRs from the clarification session. Proceed with valid CDRs only.

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

### Phase 3: System Auto-Assessment

**Objective**: Automatically assess each CDR before presenting to user

For each pending CDR, perform automated analysis:

#### Validity Assessment
Scan the codebase for evidence the pattern is still actively used:

- **Active**: Pattern found in recent code (file modifications, imports, usage)
- **Partially Active**: Pattern found but limited usage or legacy areas
- **Unknown**: Cannot determine from code scan alone
- **Deprecated**: Pattern found in comments only or marked deprecated

Method: Search for key identifiers from the CDR's proposed content (class names, function names, import paths) in the codebase.

#### Scope Assessment
Determine if the pattern is team-wide or project-specific:

- **Team-wide**: Pattern uses standard frameworks/libraries, applicable across projects
- **Tech-stack-specific**: Pattern applies to projects using the same technology
- **Project-specific**: Pattern relies on project-specific business logic or infrastructure

Method: Analyze the CDR's target module path and proposed content for technology-specific vs. generic patterns.

#### Coverage Check (if TEAM_DIRECTIVES exists)
Check against existing team directives:

- **New**: No overlap with existing directives
- **Enhancement**: Partially overlaps with existing directive (adds new angle)
- **Duplicate**: >80% overlap with existing directive

Method: Compare CDR title, target module, and key terms against existing directive filenames and content.

#### Priority Assessment
Determine impact level:

- **High**: Pattern used across many files/modules, critical to architecture
- **Medium**: Pattern used in specific areas, useful but not critical
- **Low**: Pattern is niche or nice-to-have

Method: Count file references in CDR evidence, assess architectural significance.

#### Recommended Action
Based on the four assessments above, determine a recommended action:

| Validity | Scope | Coverage | Recommended Action |
|----------|-------|----------|-------------------|
| Active | Team-wide | New | **Accept** |
| Active | Team-wide | Enhancement | **Accept** |
| Active | Tech-stack-specific | New | **Accept** |
| Active | Project-specific | New | **Reject** (project-specific) |
| Active | Any | Duplicate | **Reject** (duplicate) |
| Partially Active | Any | Any | **Investigate** |
| Unknown | Any | Any | **Investigate** |
| Deprecated | Any | Any | **Reject** (outdated) |

### Phase 4: Batch Overview with Recommendations

**Objective**: Present all pending CDRs with auto-assessed gaps and recommended actions

Show a clear overview table:

```markdown
## Pending CDRs for Clarification

**Total**: {N} CDRs to review | **Session limit**: 5 CDRs, 10 questions max

| # | CDR | Type | Target Module | Validity | Scope | Priority | Recommended |
|---|-----|------|---------------|----------|-------|----------|-------------|
| 1 | CDR-011 | Rule | rules/python/celery-task-architecture | Active | Team-wide | High | Accept |
| 2 | CDR-012 | Rule | rules/python/multi-tenant-schema | Active | Tech-stack | High | Accept |
| 3 | CDR-013 | Example | examples/django/async-viewset-websocket | Active | Team-wide | Medium | Accept |
```

### Gap Summary

| CDR | Title | Validity | Scope | Coverage | Priority | Recommended Action |
|-----|-------|----------|-------|----------|----------|-------------------|
| CDR-011 | Celery Task Architecture | Active | Team-wide | New | High | **Accept** |
| CDR-012 | Multi-Tenant Schema | Active | Tech-stack | New | High | **Accept** |
| CDR-013 | Async ViewSet + WebSocket | Active | Team-wide | New | Medium | **Accept** |

#### Gap Prioritization

- **CRITICAL**: Duplicate of existing directive, constitution violation
- **HIGH**: Scope unclear, high priority pattern
- **MEDIUM**: Content needs minor edits
- **LOW**: Minor phrasing improvements

---

**How would you like to proceed?**

- Reply with CDR numbers to process in order (e.g., "1, 2, 3")
- Reply with "all" to process all CDRs (up to 5 per session)
- Reply with specific CDR IDs (e.g., "CDR-011 CDR-013")

---

### Phase 5: Sequential Clarification

**Objective**: Process ONE CDR at a time with action picker and recommended defaults

---

#### CRITICAL: Interactive Mode Enforcement

This phase REQUIRES user input at each step. DO NOT:
- Present multiple CDRs together in a single response
- Auto-select answers or assume user preference
- Proceed to next CDR without receiving explicit input
- Ask more than one question at a time during investigation

If running non-interactively, use bulk actions (see below).

---

#### Session Limits

- Maximum **5 CDRs** per session
- Maximum **3 questions per CDR** (during investigation)
- Maximum **10 questions total** across all CDRs in session
- Show remaining count when approaching limits
- Suggest running again for remaining CDRs

#### Early Exit

User can end session early by saying:
- "stop"
- "done"
- "skip remaining"

Capture any answers already given, update those CDRs, skip remaining.

---

#### For Each CDR (Sequential):

**IMPORTANT**: Present exactly ONE CDR per interaction. Complete all actions for that CDR before moving to the next.

```markdown
## CDR-{ID}: {Title}

**Context Type**: {type}
**Target Module**: {target}
**Current Status**: {status}

### Auto-Assessment

- **Validity**: {Active/Partially Active/Unknown/Deprecated} - {brief evidence}
- **Scope**: {Team-wide/Tech-stack-specific/Project-specific}
- **Coverage**: {New/Enhancement/Duplicate}
- **Priority**: {High/Medium/Low}

### Recommended Action

**Recommended: {Action}** - {1-2 sentence reasoning based on auto-assessment}

### Choose Action

| Option | Action | Description | Follow-up? |
|--------|--------|-------------|------------|
| A | **Accept** | Approve for implementation | No |
| B | **Reject** | Decline with reason | No |
| C | **Defer** | Skip for now, keep pending | No |
| D | **Investigate** | Need clarification | YES (max 3 questions) |
| E | **Split** | Multiple concerns | YES |
| Short | Provide a different action | | |

You can reply with the option letter (e.g., "A"), accept the recommendation by saying "yes" or "recommended", or provide your own answer.

---
[WAIT FOR USER INPUT - DO NOT PROCEED WITHOUT ANSWER]
---
```

After receiving user input, process the action, then proceed to next CDR.

#### Action A: Accept (No Questions)

Directly update status to **Accepted**:

```markdown
### Decision: Accept

**Status**: {status} → **Accepted**

Added to accepted list for `/levelup.implement`
```

Update the CDR file immediately after this decision.

---
[WAIT FOR USER INPUT - PROCEED TO NEXT CDR]
---


#### Action B: Reject (With Reason)

Present reason picker with recommended default:

```markdown
### Decision: Reject

**Recommended: Project-specific** - {reasoning based on scope assessment}

| Option | Reason |
|--------|--------|
| A | Project-specific (not team-wide) |
| B | Deprecated/outdated pattern |
| C | Duplicate of existing directive |
| D | Out of scope for team-ai-directives |
| Short | Provide a different reason |

You can reply with the option letter, accept the recommendation by saying "yes" or "recommended", or provide your own reason.

**Status**: {status} → **Rejected**
```

Update the CDR file immediately after this decision.

---
[WAIT FOR USER INPUT - PROCEED TO NEXT CDR]
---


#### Action C: Defer (No Questions)

```markdown
### Decision: Defer

CDR kept as {status}, will appear in next clarify session.

| Option | Reason |
|--------|--------|
| A | Need more context |
| B | Waiting on team decision |
| C | Low priority |
| Short | Provide a different reason |

You can reply with the option letter or provide your own reason.
```

---
[WAIT FOR USER INPUT - PROCEED TO NEXT CDR]
---


#### Action D: Investigate (One Question at a Time)

**Only ask targeted questions** based on context type. Present ONE question at a time with recommended answers.

**Question Limit**: Maximum 3 questions per CDR, 10 total per session.

**For Rule CDRs** (conflict check):

Present questions sequentially, one at a time:

**Question 1** (if scope assessment was "Unknown" or "Partially Active"):

```markdown
### Investigate: Rule CDR - Question 1 of 3

**Recommended: Option A** - {reasoning based on code evidence}

| Option | Description |
|--------|-------------|
| A | No conflicts with existing rules |
| B | Need to check against existing rules |
| C | Known conflict exists |
| Short | Provide a different answer |

You can reply with the option letter, accept the recommendation by saying "yes" or "recommended", or provide your own answer.

---
[WAIT FOR USER INPUT]
---
```

If response is B, offer `/levelup.validate` before continuing.

**Question 2** (if scope was unclear):

```markdown
### Investigate: Rule CDR - Question 2 of 3

**Recommended: Option A** - {reasoning based on pattern analysis}

| Option | Description |
|--------|-------------|
| A | Team-wide - all projects should use this |
| B | Tech-stack-specific - for projects with same technology |
| C | Project-specific - only for this codebase |
| Short | Provide a different answer |

You can reply with the option letter, accept the recommendation by saying "yes" or "recommended", or provide your own answer.

---
[WAIT FOR USER INPUT]
---
```

**Question 3** (content accuracy):

```markdown
### Investigate: Rule CDR - Question 3 of 3

**Recommended: Option A** - {reasoning based on evidence quality}

| Option | Description |
|--------|-------------|
| A | Content is accurate and complete |
| B | Needs minor edits |
| C | Needs significant revision |
| Short | Provide a different answer |

You can reply with the option letter, accept the recommendation by saying "yes" or "recommended", or provide your own answer.

---
[WAIT FOR USER INPUT - PROCEED TO NEXT CDR AFTER INVESTIGATION COMPLETE]
---
```

**For Skill CDRs** (skill type check):

Present questions sequentially:

**Question 1** (skill type):

```markdown
### Investigate: Skill CDR - Question 1 of 3

**Recommended: Option A** - {reasoning based on CDR content}

| Option | Description |
|--------|-------------|
| A | Library & API Reference |
| B | Code Quality & Review |
| C | CI/CD & Deployment |
| D | Code Scaffolding & Templates |
| E | Other (specify) |

You can reply with the option letter, accept the recommendation by saying "yes" or "recommended", or provide your own answer.

---
[WAIT FOR USER INPUT]
---
```

**For Other CDRs** (Examples, Personas, Constitution):

Present questions sequentially:

**Question 1** (scope/validity - only if auto-assessment flagged uncertainty):

```markdown
### Investigate: {Type} CDR - Question 1 of 3

**Recommended: Option A** - {reasoning based on auto-assessment}

| Option | Description |
|--------|-------------|
| A | {recommended option based on assessment} |
| B | {alternative option} |
| C | {another alternative} |
| Short | Provide a different answer |

You can reply with the option letter, accept the recommendation by saying "yes" or "recommended", or provide your own answer.

---
[WAIT FOR USER INPUT]
---
```

**IMPORTANT**: Only ask questions that the auto-assessment flagged as uncertain. If all assessments are clear, skip directly to acceptance recommendation.

---
[WAIT FOR USER INPUT - PROCEED TO NEXT CDR AFTER INVESTIGATION COMPLETE]
---

#### Action E: Split (Follow-up Questions)

```markdown
### Split: Multiple Concerns

This CDR covers multiple concerns. How to split?

**Recommended: Option A** - {reasoning based on CDR content analysis}

| Option | Description |
|--------|-------------|
| A | Split into separate CDRs (create new ones) |
| B | Keep primary concern, reject others |
| C | Merge with existing CDR (if overlap) |
| Short | Provide a different approach |

You can reply with the option letter, accept the recommendation by saying "yes" or "recommended", or provide your own answer.

---
[WAIT FOR USER INPUT]
---
```

After user chooses split approach:

```markdown
### Identify Concerns to Split

Please describe each concern that should become a separate CDR:

_{list each concern with brief description}_

---
[WAIT FOR USER INPUT - PROCEED TO NEXT CDR AFTER SPLIT COMPLETE]
---
```

### Phase 6: Update CDR File (After Each Interaction)

**Objective**: Write updates to `.specify/drafts/cdr.md` after EACH CDR interaction

Update immediately after each CDR decision (not in batch at end):

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
- **Auto-Assessment**: Validity={validity}, Scope={scope}, Coverage={coverage}, Priority={priority}
- **Recommended Action**: {recommended_action}
- **User Decision**: {user_decision}
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
**Questions Asked**: {M} / 10

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

### Remaining CDRs (Not Processed This Session)

| CDR | Title | Recommended |
|-----|-------|-------------|
| CDR-005 | ... | Accept |

Run `/levelup.clarify` again to process remaining CDRs.

### Next Steps

1. **Accepted**: Run `/levelup.implement` to create PR
2. **Needs Re-review**: Edit content, then run `/levelup.clarify` again
3. **Remaining**: Run `/levelup.clarify` to continue

### Clarifying Loop

To re-review any CDR:
```bash
/levelup.clarify CDR-{ID}
```

This allows another pass after content updates or additional investigation.
```

### Phase 8: Offer /levelup.validate (Rule CDRs)

**Objective**: Offer conflict validation when investigating rule CDRs

When a Rule CDR investigation reveals potential conflicts:

```markdown
### Conflict Check Offer

Would you like to run `/levelup.validate` to check for rule conflicts?

| Option | Description |
|--------|-------------|
| A | Yes, check now → Run `/levelup.validate` first, then continue |
| B | No, skip → Continue with manual check |

You can reply with the option letter or your preference.

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

- **Auto-assess first**: Always analyze CDRs before presenting to user
- **Recommended actions**: Provide system-recommended action for each CDR
- **Recommended answers**: Provide recommended answers for all investigation questions
- **One-at-a-time**: Present exactly ONE CDR per interaction, ONE question at a time
- **Wait for input**: Never auto-proceed without user response
- **Session limits**: Maximum 5 CDRs per session, 3 questions per CDR, 10 total questions
- **Early exit**: User can say "done" to end early
- **Immediate writes**: Update CDR file after each CDR interaction (not batch)
- **Clarifying loop**: Run `/levelup.clarify` again after content updates
- **Conflict check**: Offer `/levelup.validate` for rule CDRs
- **Skip uncertain**: Only ask questions where auto-assessment found uncertainty
- No automatic handoff - user decides next step

## Related Commands

- `/levelup.init` - Discover CDRs from codebase
- `/levelup.validate` - Check for rule conflicts (offered during clarify)
- `/levelup.specify` - Refine CDRs from feature context
- `/levelup.skills` - Build skills from accepted CDRs
- `/levelup.implement` - Create PR to team-ai-directives
- `/architect.clarify` - Similar pattern for ADR clarification
