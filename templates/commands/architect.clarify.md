---
description: Refine and validate system-level ADRs through targeted clarification questions
handoffs:
  - label: Generate Architecture
    agent: architect.implement
    prompt: Generate full architecture description from ADRs
    send: true
  - label: Review Architecture
    agent: spec.analyze
    prompt: Analyze architecture for consistency and completeness
    send: false
scripts:
  sh: scripts/bash/setup-architecture.sh "clarify {ARGS}"
  ps: scripts/powershell/setup-architecture.ps1 "clarify {ARGS}"
agent_scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

**Examples of User Input**:

- `"Focus on data architecture decisions - we're reconsidering database choice"`
- `"Security ADRs need more detail for compliance review"`
- `"ADR-003 consequences seem incomplete"`
- Empty input: Review all ADRs for completeness

## Goal

Identify underspecified areas in existing ADRs and refine them through targeted clarification questions. Ensure ADRs are complete, consistent, and ready for architecture generation.

## Role & Context

You are acting as an **Architecture Reviewer** ensuring ADR quality. Your role involves:

- **Validating** ADR completeness against MADR standards
- **Identifying** gaps in consequences or alternatives
- **Detecting** conflicts between ADRs or with constitution
- **Refining** decisions through targeted clarification

### ADR Quality Checklist

Each ADR should have:

- [ ] Clear context explaining the problem/opportunity
- [ ] Explicit decision statement
- [ ] Positive AND negative consequences
- [ ] At least 2 alternatives considered with rejection reasons
- [ ] Risks identified with mitigation strategies
- [ ] No conflicts with other ADRs
- [ ] Alignment with constitution principles

## Outline

1. **Load Current State**: Parse `memory/adr.md` and `memory/constitution.md`
2. **Analyze ADRs**: Check each ADR against quality checklist
3. **Identify Gaps**: List areas needing clarification
4. **Interactive Refinement**: Ask targeted questions to fill gaps
5. **Update ADRs**: Write refined ADRs back to file

## Execution Steps

### Phase 1: Context Loading

**Objective**: Establish current ADR state

1. **Run Prerequisites Script**:
   - Execute `{SCRIPT}` from repo root
   - Parse JSON for paths to memory files
   - Handle errors gracefully if files don't exist

2. **Load ADR File**:
   - Read `memory/adr.md`
   - Parse ADR index and individual ADR sections
   - Count total ADRs and identify status distribution

3. **Load Constitution**:
   - Read `memory/constitution.md` if it exists
   - Extract principles for alignment checking
   - Note governance constraints

4. **User Focus**:
   - If user specified specific ADRs or areas, narrow scope
   - Otherwise, review all ADRs

### Phase 2: ADR Analysis

**Objective**: Identify quality gaps in each ADR

#### Quality Dimensions to Check

1. **Context Completeness**:
   - Is the problem clearly stated?
   - Are the forces/drivers documented?
   - Is the decision scope clear?

2. **Decision Clarity**:
   - Is the decision actionable?
   - Are implementation implications clear?
   - Can this decision be validated/tested?

3. **Consequence Coverage**:
   - Are positive outcomes documented?
   - Are negative trade-offs acknowledged?
   - Are risks identified with mitigations?

4. **Alternatives Documentation**:
   - Are at least 2 alternatives listed?
   - Is rejection reasoning clear for each?
   - Were reasonable options considered?

5. **Cross-ADR Consistency**:
   - Do decisions conflict with other ADRs?
   - Are dependencies between ADRs documented?
   - Is terminology consistent?

6. **Constitution Alignment**:
   - Does decision comply with MUST principles?
   - Are SHOULD principles addressed?
   - Are violations explicitly justified?

### Phase 3: Gap Identification

**Objective**: Prioritize clarification needs

Generate a gap report:

```markdown
## ADR Clarification Report

### Summary
- Total ADRs: [N]
- Complete: [N]
- Needs Clarification: [N]

### Gaps by ADR

| ADR | Title | Gap Type | Severity | Priority |
|-----|-------|----------|----------|----------|
| ADR-001 | [Title] | Missing alternatives | HIGH | 1 |
| ADR-002 | [Title] | Incomplete consequences | MEDIUM | 2 |

### Cross-ADR Issues

| Issue | ADRs Affected | Description |
|-------|---------------|-------------|
| [Conflict] | ADR-001, ADR-003 | [Description of conflict] |
```

#### Gap Prioritization

- **CRITICAL**: Constitution violations, missing decision statement
- **HIGH**: No alternatives documented, missing consequences
- **MEDIUM**: Incomplete risks, unclear context
- **LOW**: Minor phrasing improvements, optional details

### Phase 4: Interactive Refinement

**Objective**: Fill gaps through targeted questions

#### Question Format

For each gap requiring clarification:

```markdown
## Clarification [N]: [ADR-XXX] - [Gap Type]

**Current State**: 
[Quote current ADR content]

**Gap Identified**: 
[Explain what's missing or unclear]

**Question**:
[Specific question to address the gap]

**Suggested Options** (if applicable):

| Option | Description |
|--------|-------------|
| A | [Option A] |
| B | [Option B] |
| C | [Custom response] |

Reply with your choice or provide additional context.
```

#### Clarification Rules

- Present **one clarification at a time**
- **Prioritize by severity** - address CRITICAL/HIGH gaps first
- **Limit to 5 clarifications** per session
- Allow user to **skip** non-critical clarifications
- **Summarize changes** after each answer
- User can say "done" to end clarification early

### Phase 5: ADR Updates

**Objective**: Write refined ADRs back to file

1. **Apply Clarifications**:
   - Update ADR sections with new content
   - Preserve structure and formatting
   - Update "Last Updated" timestamps

2. **Resolve Conflicts**:
   - If cross-ADR conflicts were found, propose resolution
   - Document decision to favor one ADR over another
   - Add cross-references between related ADRs

3. **Update Index**:
   - Refresh ADR index table if titles changed
   - Update status if applicable

4. **Write File**:
   - Atomic write to `memory/adr.md`
   - Preserve any ADRs that weren't modified

## Key Rules

### Non-Destructive Refinement

- **Never delete** existing ADRs without explicit user approval
- **Preserve original intent** when updating wording
- **Add, don't replace** consequences and alternatives
- **Mark changes** with updated timestamps

### Focused Clarification

- Ask **one question at a time**
- Make questions **specific and answerable**
- Provide **suggested options** when possible
- Respect user's time - limit to **5 clarifications**

### Constitution Authority

- Constitution violations are **always flagged**
- ADRs cannot override MUST principles without explicit justification
- Suggest constitution updates if conflict is systemic

### Quality Over Quantity

- Focus on **material gaps** that affect implementation
- Skip **cosmetic improvements** unless user requests
- **Defer minor issues** if major gaps remain

## Completion Report

After clarification ends (all gaps addressed or user signals "done"):

```markdown
## ADR Clarification Complete

**Changes Made**:
- ADR-001: Updated consequences section
- ADR-002: Added 2 alternatives
- ADR-003: Resolved conflict with ADR-001

**Remaining Gaps** (deferred):
- ADR-004: Minor context clarification (LOW)

**Cross-ADR Consistency**: ✅ Verified

**Constitution Alignment**: ✅ Compliant

**Recommended Next Steps**:
1. Review updated ADRs in `memory/adr.md`
2. Run `/architect.implement` to generate Architecture Description
3. Or run `/spec.specify` to start feature development
```

## Workflow Guidance & Transitions

### After `/architect.clarify`

Recommended next steps:

1. **Review Changes**: Verify ADR updates are accurate
2. **Run `/architect.implement`**: Generate full AD.md from refined ADRs
3. **Start Features**: Use `/spec.specify` to create feature specs

### When to Use This Command

- **After `/architect.specify`**: Refine initial ADRs before architecture generation
- **ADR Review**: Validate ADRs before major milestones
- **New Team Member**: Ensure ADRs make sense to fresh eyes
- **Conflict Resolution**: Resolve identified inconsistencies

### When NOT to Use This Command

- **No ADRs exist**: Use `/architect.specify` first to create ADRs
- **Brownfield projects**: Use `/architect.init` to reverse-engineer ADRs from code
- **Feature-level**: Feature ADRs are refined via `/spec.clarify`

## Context

{ARGS}
