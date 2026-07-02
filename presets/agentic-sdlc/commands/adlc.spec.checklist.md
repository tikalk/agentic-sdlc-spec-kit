---
description: Generate a custom checklist for the current feature based on user requirements.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
---

## Checklist Purpose: "Unit Tests for English"

**CRITICAL CONCEPT**: Checklists validate the **quality, clarity, and completeness of requirements** — not implementation behavior.

**NOT for verification**:
- ❌ "Verify the button clicks correctly"
- ❌ "Test error handling works"
- ❌ "Confirm the API returns 200"

**FOR requirements quality**:
- ✅ "Are visual hierarchy requirements defined for all card types?" [Completeness]
- ✅ "Is 'prominent display' quantified with specific sizing?" [Clarity]
- ✅ "Are hover state requirements consistent across all interactive elements?" [Consistency]
- ✅ "Are accessibility requirements defined for keyboard navigation?" [Coverage]

**Metaphor**: If your spec is code written in English, the checklist is its unit test suite.

## MANDATORY: Pre-Execution Hooks

**STOP. Before reading User Input or doing ANY other work, execute extension hooks.**

0. Determine `{REPO_ROOT}` by running `git rev-parse --show-toplevel 2>/dev/null`. If that fails, walk up from the current directory until you find a `.git` directory or `.specify/init-options.json` and use that parent as `{REPO_ROOT}`.
1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, state `No hooks file found` and skip to User Input.
2. Read `{REPO_ROOT}/.specify/extensions.yml` and find `hooks.before_checklist`.
3. Skip any hook with `enabled: false`. Skip any hook with a non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Pre-Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}

      Wait for the result of the hook command before proceeding.
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`): Display the hook name, command, and description. Let the user decide.
5. State which hooks were executed, then proceed to User Input.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execution Steps

1. **Setup**: Run `{SCRIPT}` from repo root and parse JSON for FEATURE_DIR and AVAILABLE_DOCS list.
   - All file paths must be absolute.
   - For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### CRITICAL - Path Validation

**DO NOT write to project root or wrong feature directory**
- Parse `FEATURE_DIR` from script output
- Write checklist files ONLY to `./specs/<BRANCH>/checklists/` NOT root
- Common mistake: Writing to `./checklists/` instead of `./specs/<BRANCH>/checklists/`

2. **Clarify intent (dynamic)**: Derive up to THREE initial contextual clarifying questions. They MUST:
   - Be generated from the user's phrasing + extracted signals from spec/plan/tasks
   - Only ask about information that materially changes checklist content
   - Be skipped individually if already unambiguous in `$ARGUMENTS`

   Generation algorithm:
   1. Extract signals: feature domain keywords, risk indicators, stakeholder hints, explicit deliverables
   2. Cluster signals into candidate focus areas (max 4) ranked by relevance
   3. Identify probable audience & timing
   4. Detect missing dimensions: scope breadth, depth/rigor, risk emphasis, exclusion boundaries, measurable acceptance criteria
   5. Formulate questions from these archetypes:
      - Scope refinement (e.g., "Should this include integration touchpoints with X and Y?")
      - Risk prioritization (e.g., "Which risk areas should receive mandatory gating checks?")
      - Depth calibration (e.g., "Lightweight pre-commit sanity or formal release gate?")
      - Audience framing (e.g., "Author only or peers during PR review?")
      - Boundary exclusion (e.g., "Exclude performance tuning items this round?")
      - Scenario class gap (e.g., "Are rollback / partial failure paths in scope?")

   Question formatting:
   - If presenting options, generate a compact table: Option | Candidate | Why It Matters (max A–E)
   - Never ask the user to restate what they already said
   - Avoid speculative categories

   Defaults when interaction impossible:
   - Depth: Standard
   - Audience: Reviewer (PR) if code-related; Author otherwise
   - Focus: Top 2 relevance clusters

   Output questions (label Q1/Q2/Q3). After answers: if ≥2 scenario classes remain unclear, ask up to TWO more follow-ups (Q4/Q5) with one-line justification each. Do not exceed five total questions. Skip escalation if user declines more.

3. **Understand user request**: Combine `$ARGUMENTS` + clarifying answers:
   - Derive checklist theme (e.g., security, review, deploy, ux, mission-brief)
   - **Default domain**: If no specific domain is requested, default to `mission-brief` for oracle adequacy validation
   - Consolidate explicit must-have items mentioned by user
   - Map focus selections to category scaffolding
   - Infer any missing context from spec/plan/tasks (do NOT hallucinate)

4. **Load feature context**: Read from FEATURE_DIR:
   - spec.md: Feature requirements and scope
   - plan.md (if exists): Technical details, dependencies
   - tasks.md (if exists): Implementation tasks

   **Context Loading Strategy**:
   - Load only necessary portions relevant to active focus areas
   - Prefer summarizing long sections into concise scenario/requirement bullets
   - Use progressive disclosure: add follow-on retrieval only if gaps detected
   - If source docs are large, generate interim summary items instead of embedding raw text

5. **Generate checklist** - Create "Unit Tests for Requirements":
   - Create `FEATURE_DIR/checklists/` directory if it doesn't exist
   - Generate unique checklist filename:
     - Use short, descriptive name based on domain (e.g., `ux.md`, `api.md`, `security.md`, `mission-brief.md`)
     - Format: `[domain].md`
   - File handling behavior:
     - If file does NOT exist: Create new file and number items starting from CHK001
     - If file exists: Append new items to existing file, continuing from the last CHK ID
     - **Mission-brief exception**: If `mission-brief.md` exists, overwrite it (oracle adequacy check must reflect current spec state)
   - Never delete or replace existing checklist content - always preserve and append (except `mission-brief.md`)

   **MISSION-BRIEF DOMAIN — Oracle Adequacy Checklist**:
   When the domain is `mission-brief`, generate exactly these 6 items:

   ```markdown
   - [ ] CHK001 - Goal is specific enough to verify completion [Clarity]
   - [ ] CHK002 - Every Success Criterion has a quantified metric [Measurability]
   - [ ] CHK003 - Constraints explicitly bound the solution space [Completeness]
   - [ ] CHK004 - Every user story maps to at least one Success Criterion [Coverage]
   - [ ] CHK005 - No vague adjectives ("fast", "secure") without quantified thresholds [Clarity]
   - [ ] CHK006 - Demo Sentence is filled with an observable outcome [Completeness]
   ```

   Then evaluate the spec against each item:
   - Read `spec.md` Mission Brief section (Goal, Success Criteria, Constraints)
   - Read User Stories and Acceptance Scenarios
   - Read the Demo Sentence
   - For each item, determine PASS or FAIL
   - Compute score: `PASS count / 6`

   Append the score section:

   ```markdown
   ## Mission Brief Adequacy: {pass_count}/6 ({percentage}%)
   **Verdict**: [Ready for implementation / Needs refinement]
   **Gaps**: [list unchecked items with specific references to spec sections]
   ```

   Example:
   ```markdown
   ## Mission Brief Adequacy: 5/6 (83%)
   **Verdict**: Needs refinement
   **Gaps**: CHK002 — SC-003 "Reduce support tickets" lacks baseline or target %
   ```

   **CORE PRINCIPLE - Test the Requirements, Not the Implementation**:
   Every checklist item MUST evaluate the REQUIREMENTS THEMSELVES for:
   - **Completeness**: Are all necessary requirements present?
   - **Clarity**: Are requirements unambiguous and specific?
   - **Consistency**: Do requirements align with each other?
   - **Measurability**: Can requirements be objectively verified?
   - **Coverage**: Are all scenarios/edge cases addressed?

   **Category Structure** - Group items by requirement quality dimensions:
   - Requirement Completeness, Requirement Clarity, Requirement Consistency
   - Acceptance Criteria Quality, Scenario Coverage, Edge Case Coverage
   - Non-Functional Requirements, Dependencies & Assumptions, Ambiguities & Conflicts

   **HOW TO WRITE CHECKLIST ITEMS - "Unit Tests for English"**:

   ❌ **WRONG** (Testing implementation):
   - "Verify landing page displays 3 episode cards"
   - "Test hover states work on desktop"

   ✅ **CORRECT** (Testing requirements quality):
   - "Are the exact number and layout of featured episodes specified?" [Completeness]
   - "Is 'prominent display' quantified with specific sizing/positioning?" [Clarity]
   - "Are hover state requirements consistently defined for all interactive elements?" [Consistency]
   - "Are keyboard navigation requirements defined for all interactive UI?" [Coverage]
   - "Is the fallback behavior specified when logo image fails to load?" [Edge Cases]

   **ITEM STRUCTURE**:
   Each item should follow this pattern:
   - Question format asking about requirement quality
   - Focus on what's WRITTEN (or not written) in the spec/plan
   - Include quality dimension in brackets [Completeness/Clarity/Consistency/etc.]
   - Reference spec section `[Spec §X.Y]` when checking existing requirements
   - Use `[Gap]` marker when checking for missing requirements

   **EXAMPLES BY QUALITY DIMENSION**:

   Completeness:
   - "Are error handling requirements defined for all API failure modes? [Gap]"
   - "Are accessibility requirements specified for all interactive elements? [Completeness]"

   Clarity:
   - "Is 'fast loading' quantified with specific timing thresholds? [Clarity, Spec §NFR-2]"
   - "Are 'related episodes' selection criteria explicitly defined? [Clarity, Spec §FR-5]"

   Consistency:
   - "Do navigation requirements align across all pages? [Consistency, Spec §FR-10]"

   Coverage:
   - "Are requirements defined for zero-state scenarios (no episodes)? [Coverage, Edge Case]"
   - "Are concurrent user interaction scenarios addressed? [Coverage, Gap]"

   Measurability:
   - "Are visual hierarchy requirements measurable/testable? [Acceptance Criteria, Spec §FR-1]"

   **Scenario Classification & Coverage**:
   - Check if requirements exist for: Primary, Alternate, Exception/Error, Recovery, Non-Functional scenarios
   - For each missing scenario class: "Are [scenario type] requirements intentionally excluded or missing? [Gap]"
   - Include resilience/rollback when state mutation occurs

   **Traceability Requirements**:
   - MINIMUM: ≥80% of items MUST include at least one traceability reference
   - Each item should reference: spec section `[Spec §X.Y]`, or use markers: `[Gap]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]`
   - If no ID system exists: "Is a requirement & acceptance criteria ID scheme established? [Traceability]"

   **Surface & Resolve Issues**:
   - Ambiguities: "Is the term 'fast' quantified with specific metrics? [Ambiguity, Spec §NFR-1]"
   - Conflicts: "Do navigation requirements conflict between §FR-10 and §FR-10a? [Conflict]"
   - Assumptions: "Is the assumption of 'always available podcast API' validated? [Assumption]"
   - Dependencies: "Are external podcast API requirements documented? [Dependency, Gap]"

   **Content Consolidation**:
   - Soft cap: If raw candidate items > 40, prioritize by risk/impact
   - Merge near-duplicates checking the same requirement aspect
   - If >5 low-impact edge cases, create one item: "Are edge cases X, Y, Z addressed in requirements? [Coverage]"

   **🚫 ABSOLUTELY PROHIBITED**:
   - ❌ Any item starting with "Verify", "Test", "Confirm", "Check" + implementation behavior
   - ❌ References to code execution, user actions, system behavior
   - ❌ "Displays correctly", "works properly", "functions as expected"
   - ❌ "Click", "navigate", "render", "load", "execute"
   - ❌ Test cases, test plans, QA procedures
   - ❌ Implementation details (frameworks, APIs, algorithms)

   **✅ REQUIRED PATTERNS**:
   - ✅ "Are [requirement type] defined/specified/documented for [scenario]?"
   - ✅ "Is [vague term] quantified/clarified with specific criteria?"
   - ✅ "Are requirements consistent between [section A] and [section B]?"
   - ✅ "Can [requirement] be objectively measured/verified?"
   - ✅ "Are [edge cases/scenarios] addressed in requirements?"
   - ✅ "Does the spec define [missing aspect]?"

6. **Structure Reference**: Generate the checklist following the canonical template in `templates/checklist-template.md` for title, meta section, category headings, and ID formatting. If template is unavailable, use: H1 title, purpose/created meta lines, `##` category sections containing `- [ ] CHK### <requirement item>` lines with globally incrementing IDs starting at CHK001.

7. **Report**: Output full path to checklist file, item count, and summarize whether the run created a new file or appended to an existing one. Summarize:
   - Focus areas selected
   - Depth level
   - Actor/timing
   - Any explicit user-specified must-have items incorporated

**Important**: Each `__SPECKIT_COMMAND_CHECKLIST__` command invocation uses a short, descriptive checklist filename and either creates a new file or appends to an existing one. This allows:

- Multiple checklists of different types (e.g., `ux.md`, `test.md`, `security.md`)
- Simple, memorable filenames that indicate checklist purpose
- Easy identification and navigation in the `checklists/` folder

To avoid clutter, use descriptive types and clean up obsolete checklists when done.

## Example Checklist Types & Sample Items

**UX Requirements Quality:** `ux.md`

- "Are visual hierarchy requirements defined with measurable criteria? [Clarity, Spec §FR-1]"
- "Is the number and positioning of UI elements explicitly specified? [Completeness, Spec §FR-1]"
- "Are interaction state requirements (hover, focus, active) consistently defined? [Consistency]"

**API Requirements Quality:** `api.md`

- "Are error response formats specified for all failure scenarios? [Completeness]"
- "Are rate limiting requirements quantified with specific thresholds? [Clarity]"
- "Are authentication requirements consistent across all endpoints? [Consistency]"

**Security Requirements Quality:** `security.md`

- "Are authentication requirements specified for all protected resources? [Coverage]"
- "Are data protection requirements defined for sensitive information? [Completeness]"
- "Is the threat model documented and requirements aligned to it? [Traceability]"

## Anti-Examples: What NOT To Do

**❌ WRONG** (tests implementation, not requirements):

```markdown
- [ ] CHK001 - Verify landing page displays 3 episode cards [Spec §FR-001]
- [ ] CHK002 - Test hover states work correctly on desktop [Spec §FR-003]
```

**✅ CORRECT** (tests requirements quality):

```markdown
- [ ] CHK001 - Are the number and layout of featured episodes explicitly specified? [Completeness, Spec §FR-001]
- [ ] CHK002 - Are hover state requirements consistently defined for all interactive elements? [Consistency, Spec §FR-003]
```

**Key Differences**:
- Wrong: Tests if the system works correctly
- Correct: Tests if the requirements are written correctly

## Post-Execution Hooks

1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_checklist`.
3. Skip hooks with `enabled: false` or non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`): Display hook info for user decision.
5. If no hooks registered, skip silently.
