---
description: Identify underspecified areas in the current feature spec by asking up to 5 highly targeted clarification questions and encoding answers back into the spec.
handoffs: 
  - label: Build Technical Plan
    agent: adlc.spec.plan
    prompt: Create a plan for the spec. I am building with...
scripts:
   sh: scripts/bash/check-prerequisites.sh --json --paths-only
   ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
   py: scripts/python/check_prerequisites.py --json --paths-only
---

## MANDATORY: Pre-Execution Hooks

**STOP. Before reading User Input or doing ANY other work, execute extension hooks.**

0. Determine `{REPO_ROOT}` by running `git rev-parse --show-toplevel 2>/dev/null`. If that fails, walk up from the current directory until you find a `.git` directory or `.specify/init-options.json` and use that parent as `{REPO_ROOT}`.
1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, state `No hooks file found` and skip to User Input.
   If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally.
2. Read `{REPO_ROOT}/.specify/extensions.yml` and find `hooks.before_clarify`.
3. Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default. Skip any hook with a non-empty `condition` and leave condition evaluation to the HookExecutor implementation.
4. For each remaining hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Pre-Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}

      Wait for the result of the hook command before proceeding.
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:spec-...` or `$spec-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`):
      ```
      ## Extension Hooks

      **Optional Hook**: {extension}
      Command: `/{command}`
      Description: {description}

      Prompt: {prompt}
      To execute: `/{command}`
      ```
      Let the user decide whether to execute the optional hook.
5. State which hooks were executed, then proceed to User Input.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Goal: Detect and reduce ambiguity or missing decision points in the active feature specification and record the clarifications directly in the spec file.

Note: This clarification workflow is expected to run (and be completed) BEFORE invoking `__SPECKIT_COMMAND_PLAN__`. If the user explicitly states they are skipping clarification (e.g., exploratory spike), you may proceed, but must warn that downstream rework risk increases.

## Mission Brief Validation

Before proceeding with clarification, validate that the spec has a complete and confirmed Mission Brief.

**Mission Brief Fields** (in spec header):
- **Goal**: One-sentence objective - core purpose
- **Success Criteria**: 2-3 measurable outcomes
- **Constraints**: Key constraints - technical/business/regulatory

### Validation Logic

1. Parse spec header for Goal, Success Criteria, Constraints fields
2. Check if any field is missing or contains placeholder text (e.g., `[one-sentence objective - core purpose]`)

### Required Behavior

**If any Mission Brief field is missing or contains placeholder text:**

1. **Block** and prompt user to provide it before proceeding:
   - Output the Mission Brief prompt template and wait for user input
   - Do NOT proceed until Mission Brief is complete
2. When user provides content, update the spec.md header with the provided values.
3. Proceed to the confirmation step below.

**If all Mission Brief fields are populated:**

1. Display the current Mission Brief:

   ```markdown
   ## Mission Brief

   **Goal**: {goal}

   **Success Criteria**:
   - {criterion 1}
   - {criterion 2}

   **Constraints**:
   - {constraint 1}
   ```

2. Ask for confirmation:

   ```
   **Proceed with this Mission Brief?** (yes / no / adjust)
   ```

3. **STOP HERE** - Wait for explicit response.

   - **yes**: Proceed to clarification questions.
   - **adjust**: Ask what needs changing, update the Mission Brief fields in the spec header, re-display, ask again.
   - **no**: Stop. Do not proceed to clarification. Recommend re-running `__SPECKIT_COMMAND_SPECIFY__` or revising the feature description.

4. **Do NOT proceed to clarification until Mission Brief is confirmed with "yes".**

### Mission Brief Prompt Template

When Mission Brief is missing or incomplete, display:

```
## Mission Brief Required

Before proceeding with clarification, the spec needs a Mission Brief:

**Goal**: [One-sentence objective - what do you want to achieve?]

**Success Criteria**: [2-3 measurable outcomes]
- Example: "Users can log in within 5 seconds"
- Example: "95% of searches return results in under 1 second"

**Constraints**: [Key constraints]
- Examples: "Must work offline", "Budget < $X", "No external APIs"

Please provide the Mission Brief fields before proceeding.
```

Execution steps:

1. Run `{SCRIPT}` from repo root **once** (combined `--json --paths-only` mode / `-Json -PathsOnly`). Parse minimal JSON payload fields:
   - `FEATURE_DIR`
   - `FEATURE_SPEC`
   - If JSON parsing fails, abort and instruct user to re-run `__SPECKIT_COMMAND_SPECIFY__` or verify feature branch environment.
   - For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **IF EXISTS**: Load `{REPO_ROOT}/.specify/memory/constitution.md` for project principles and governance constraints. Constitution MUST violations are automatically CRITICAL and must be resolved before proceeding to planning.

3. Load the current spec file. Perform a structured ambiguity & coverage scan using this taxonomy. For each category, mark status: Clear / Partial / Missing. Produce an internal coverage map used for prioritization (do not output raw map unless no questions will be asked).

   Functional Scope & Behavior:
   - Core user goals & success criteria
   - Explicit out-of-scope declarations
   - User roles / personas differentiation

   Domain & Data Model:
   - Entities, attributes, relationships
   - Identity & uniqueness rules
   - Lifecycle/state transitions
   - Data volume / scale assumptions

   Interaction & UX Flow:
   - Critical user journeys / sequences
   - Error/empty/loading states
   - Accessibility or localization notes

   Non-Functional Quality Attributes:
   - Performance (latency, throughput targets)
   - Scalability (horizontal/vertical, limits)
   - Reliability & availability (uptime, recovery expectations)
   - Observability (logging, metrics, tracing signals)
   - Security & privacy (authN/Z, data protection, threat assumptions)
   - Compliance / regulatory constraints (if any)

   Integration & External Dependencies:
   - External services/APIs and failure modes
   - Data import/export formats
   - Protocol/versioning assumptions

   Edge Cases & Failure Handling:
   - Negative scenarios
   - Rate limiting / throttling
   - Conflict resolution (e.g., concurrent edits)

   Constraints & Tradeoffs:
   - Technical constraints (language, storage, hosting)
   - Explicit tradeoffs or rejected alternatives

   Terminology & Consistency:
   - Canonical glossary terms
   - Avoided synonyms / deprecated terms

   Completion Signals:
   - Acceptance criteria testability
   - Measurable Definition of Done style indicators

   Misc / Placeholders:
   - TODO markers / unresolved decisions
   - Ambiguous adjectives ("robust", "intuitive") lacking quantification

   For each category with Partial or Missing status, add a candidate question opportunity unless:
   - Clarification would not materially change implementation or validation strategy
   - Information is better deferred to planning phase (note internally)

4. Generate (internally) a prioritized queue of candidate clarification questions (maximum 5). Do NOT output them all at once. Apply these constraints:
   - Maximum of 5 total questions across the whole session.
   - Each question must be answerable with EITHER:
      - A short multiple‑choice selection (2–5 distinct, mutually exclusive options), OR
      - A one-word / short‑phrase answer (explicitly constrain: "Answer in <=5 words").
   - Only include questions whose answers materially impact architecture, data modeling, task decomposition, test design, UX behavior, operational readiness, or compliance validation.
   - Ensure category coverage balance: attempt to cover the highest impact unresolved categories first; avoid asking two low-impact questions when a single high-impact area (e.g., security posture) is unresolved.
   - Exclude questions already answered, trivial stylistic preferences, or plan-level execution details (unless blocking correctness).
   - Favor clarifications that reduce downstream rework risk or prevent misaligned acceptance tests.
   - If more than 5 categories remain unresolved, select the top 5 by (Impact * Uncertainty) heuristic.

5. Sequential questioning loop (interactive):
   - Present EXACTLY ONE question at a time.
   - **CRITICAL**: You MUST output the actual question text BEFORE showing any options or recommendations.
   - For multiple‑choice questions:
      - **First, clearly state the question** (e.g., "**Question**: How should the CLI authenticate with the API?")
      - **Analyze all options** and determine the **most suitable option** based on:
        - Best practices for the project type
        - Common patterns in similar implementations
        - Risk reduction (security, performance, maintainability)
        - Alignment with any explicit project goals or constraints visible in the spec
      - Present your recommended option prominently at the top with clear reasoning (1-2 sentences explaining why this is the best choice): `**Recommended:** Option [X] - <reasoning>`
      - Then render all options as a Markdown table:

        | Option | Description |
        |--------|-------------|
        | A | <Option A description> |
        | B | <Option B description> |
        | C | <Option C description> (add D/E as needed up to 5) |
        | Short | Provide a different short answer (<=5 words) (Include only if free-form alternative is appropriate) |

      - After the table, add: `You can reply with the option letter (e.g., "A"), accept the recommendation by saying "yes" or "recommended", or provide your own short answer.`
   - For short‑answer style (no meaningful discrete options):
      - **First, clearly state the question**
      - Provide your **suggested answer** based on best practices and context: `**Suggested:** <your proposed answer> - <brief reasoning>`
      - Then output: `Format: Short answer (<=5 words). You can accept the suggestion by saying "yes" or "suggested", or provide your own answer.`
   - After the user answers:
      - If the user replies with "yes", "recommended", or "suggested", use your previously stated recommendation/suggestion as the answer.
      - Otherwise, validate the answer maps to one option or fits the <=5 word constraint.
      - If ambiguous, ask for a quick disambiguation (count still belongs to same question; do not advance).
      - Once satisfactory, record it in working memory (do not yet write to disk) and move to the next queued question.
   - Stop asking further questions when:
      - All critical ambiguities resolved early (remaining queued items become unnecessary), OR
      - User signals completion ("done", "good", "no more"), OR
      - You reach 5 asked questions.
   - Never reveal future queued questions in advance.
   - If no valid questions exist at start, immediately report no critical ambiguities.

6. Integration after EACH accepted answer (incremental update approach):
   - Maintain in-memory representation of the spec (loaded once at start) plus the raw file contents.
   - For the first integrated answer in this session:
      - Ensure a `## Clarifications` section exists (create it just after the highest-level contextual/overview section per the spec template if missing).
      - Under it, create (if not present) a `### Session YYYY-MM-DD` subheading for today.
   - Append a bullet line immediately after acceptance: `- Q: <question> → A: <final answer>`.
   - Then immediately apply the clarification to the most appropriate section(s):
      - Functional ambiguity → Update or add a bullet in Functional Requirements.
      - User interaction / actor distinction → Update User Stories or Actors subsection with clarified role, constraint, or scenario.
      - Data shape / entities → Update Data Model (add fields, types, relationships) preserving ordering; note added constraints succinctly.
      - Non-functional constraint → Add/modify measurable criteria in Success Criteria > Measurable Outcomes (convert vague adjective to metric or explicit target).
      - Edge case / negative flow → Add a new bullet under Edge Cases / Error Handling (or create such subsection if template provides placeholder for it).
      - Terminology conflict → Normalize term across spec; retain original only if necessary by adding `(formerly referred to as "X")` once.
   - If the clarification invalidates an earlier ambiguous statement, replace that statement instead of duplicating; leave no obsolete contradictory text.
   - Save the spec file AFTER each integration to minimize risk of context loss (atomic overwrite).
   - Preserve formatting: do not reorder unrelated sections; keep heading hierarchy intact.
   - Keep each inserted clarification minimal and testable (avoid narrative drift).

7. Validation (performed after EACH write plus final pass):
   - Clarifications session contains exactly one bullet per accepted answer (no duplicates).
   - Total asked (accepted) questions ≤ 5.
   - Updated sections contain no lingering vague placeholders the new answer was meant to resolve.
   - No contradictory earlier statement remains (scan for now-invalid alternative choices removed).
   - Markdown structure valid; only allowed new headings: `## Clarifications`, `### Session YYYY-MM-DD`.
   - Terminology consistency: same canonical term used across all updated sections.

8. Write the updated spec back to `FEATURE_SPEC`.

9. **Spec Quality Checklist re-validation (IF EXISTS)**:
   - If `FEATURE_DIR/checklists/requirements.md` exists, re-validate the spec against it:
     1. Identify all GitHub task-list checkbox lines (`- [ ]`, `- [x]`, `- [X]`, case-insensitive, tolerant of nested whitespace, outside code fences).
     2. Record a before-snapshot of each checkbox marker state and its item text.
     3. Re-evaluate each checklist item against the updated spec.
     4. Toggle `[ ]` ↔ `[x]` only when the state actually changes; preserve existing case to avoid cosmetic diffs.
     5. Save the checklist file, modifying only checkbox markers whose state changed.
     6. Compute three lists: Newly passing, Regressions, Still unchecked.
     7. Record the before/after pass counts (e.g., "12/16 → 15/16").
   - If `requirements.md` does not exist, skip this step silently.

10. Report completion:
   - Number of questions asked & answered.
   - Path to updated spec.
   - Sections touched (list names).
   - Coverage summary table listing each taxonomy category with Status: Resolved (was Partial/Missing and addressed), Deferred (exceeds question quota or better suited for planning), Clear (already sufficient), Outstanding (still Partial/Missing but low impact).
    - **Mission Brief Status**: Complete / Required (if still needed)
    - **Spec quality checklist status**: If `requirements.md` was re-validated, show the before/after pass counts (e.g., "12/16 → 15/16") and list any items that changed state — both newly checked (regressions are rare here) and any still unchecked. If any items remain unchecked, list them as areas needing attention.
    - If any Outstanding or Deferred remain, recommend whether to proceed to `__SPECKIT_COMMAND_PLAN__` or run `__SPECKIT_COMMAND_CLARIFY__` again later post-plan.
    - Suggested next command.

Behavior rules:

- If no meaningful ambiguities found (or all potential questions would be low-impact), respond: "No critical ambiguities detected worth formal clarification." and suggest proceeding.
- If spec file missing, instruct user to run `__SPECKIT_COMMAND_SPECIFY__` first (do not create a new spec here).
- Never exceed 5 total asked questions (clarification retries for a single question do not count as new questions).
- Avoid speculative tech stack questions unless the absence blocks functional clarity.
- Respect user early termination signals ("stop", "done", "proceed").
- If no questions asked due to full coverage, output a compact coverage summary (all categories Clear) then suggest advancing.
- If quota reached with unresolved high-impact categories remaining, explicitly flag them under Deferred with rationale.

Context for prioritization: {ARGS}

## Done When

- [ ] Spec ambiguities identified and integrated into `FEATURE_SPEC`
- [ ] Spec quality checklist re-validated (if `requirements.md` exists)
- [ ] Extension hooks dispatched or skipped according to the rules above
- [ ] Completion reported to user with questions asked, sections touched, and checklist status


## Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_clarify`.
3. Skip hooks with `enabled: false` or non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:spec-...` or `$spec-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`):
      ```
      ## Extension Hooks

      **Optional Hook**: {extension}
      Command: `/{command}`
      Description: {description}

      Prompt: {prompt}
      To execute: `/{command}`
      ```
      Let the user decide whether to execute the optional hook.
5. If no hooks registered, skip silently.
