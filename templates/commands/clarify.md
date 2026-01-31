---
description: Identify underspecified areas in the current feature spec by asking up to 5 highly targeted clarification questions and encoding answers back into the spec.
handoffs: 
  - label: Build Technical Plan
    agent: speckit.plan
    prompt: Create a plan for the spec. I am building with...
scripts:
   sh: scripts/bash/check-prerequisites.sh --json --paths-only
   ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Mode Detection

1. **Check Current Workflow Mode**: Determine if the user is in "build" or "spec" mode by checking the mode configuration file at `.specify/config/config.json` under `workflow.current_mode`. If the file doesn't exist or mode is not set, default to "spec" mode.

2. **Mode-Aware Behavior**:
   - **Build Mode**: Minimal clarification - focus only on critical blockers, limit to 1-2 questions maximum
   - **Spec Mode**: Full clarification workflow - comprehensive ambiguity detection and resolution

## Outline

Goal: Detect and reduce ambiguity or missing decision points in the active feature specification. Validate spec against project constitution and architecture (three-pillar validation). Record clarifications directly in the spec file.

Note: This clarification workflow is expected to run (and be completed) BEFORE invoking `/speckit.plan`. If the user explicitly states they are skipping clarification (e.g., exploratory spike), you may proceed, but must warn that downstream rework risk increases.

## Three-Pillar Validation

This command validates the spec across three pillars:

1. **Specification Completeness** (existing) - Functional scope, data model, UX, non-functionals, constraints
2. **Constitution Alignment** (NEW) - Compliance with team principles, patterns, and governance
3. **Architecture Alignment** (NEW) - Fit within system boundaries, component patterns, and diagram consistency

**Load Order**:

- Parse JSON from `{SCRIPT}` to get paths including `CONSTITUTION`, `ARCHITECTURE`, and existence flags
- If `CONSTITUTION_EXISTS: true`, load constitution rules and validate spec against them
- If `ARCHITECTURE_EXISTS: true`, load architecture views/diagrams and validate spec alignment
- If both missing, fall back to spec-only validation (current behavior)

**Priority Order** (highest impact first):

1. Architecture boundary violations (blocks system design)
2. Constitution constraint violations (blocks governance)
3. Diagram-text inconsistencies (architecture quality)
4. Missing architecture integration points (scalability/operational impact)
5. Spec completeness gaps (lowest priority)

**Question Limit**:

- No architecture present: max 5 questions (build: 2, spec: 5)
- Architecture present: max 10 questions (build: 2, spec: 10) - expanded capacity

**Auto-Fix Capability**:
When detecting diagram-text inconsistency, automatically:

- Suggest specific diagram update
- Regenerate diagram block with corrections
- Record change in clarifications section
- Skip asking question if auto-fix covers it

Execution steps:

1. Run `{SCRIPT}` from repo root **once** (combined `--json --paths-only` mode / `-Json -PathsOnly`). Parse minimal JSON payload fields:
   - `FEATURE_DIR`
   - `FEATURE_SPEC`
   - (Optionally capture `IMPL_PLAN`, `TASKS` for future chained flows.)
   - If JSON parsing fails, abort and instruct user to re-run `/speckit.specify` or verify feature branch environment.
   - For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. Load governance and architecture documents (if available):

   **Constitution Loading** (if `CONSTITUTION_EXISTS: true`):
   - Load constitution from path provided in JSON
   - Extract principles, constraints, and patterns using `CONSTITUTION_RULES`
   - Prepare for cross-validation with spec

   **Architecture Loading** (if `ARCHITECTURE_EXISTS: true`):
   - Load architecture.md from path provided in JSON
   - Extract 7 viewpoints using `ARCHITECTURE_VIEWS`
   - Extract diagrams using `ARCHITECTURE_DIAGRAMS`
   - Identify components, entities, and integration points
   - Prepare for alignment validation

   **Graceful Degradation**:
   - If constitution missing: Skip constitution validation
   - If architecture missing: Skip architecture validation
   - If both missing: Proceed with spec-only validation (current behavior)

3. Load the current spec file. Perform three-pillar validation scan:

   **PILLAR 1: Specification Completeness** (existing taxonomy)

   For each category, mark status: Clear / Partial / Missing. Produce an internal coverage map used for prioritization.

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

   **PILLAR 2: Constitution Alignment** (NEW - if constitution exists)

   Validate spec against constitutional rules:

   Principle Compliance:
   - Does spec respect declared team principles?
   - Are standard architectural patterns applied?
   - Is coding philosophy consistent with constitution?

   Constraint Adherence:
   - Technical constraints: Does spec violate technology/platform restrictions?
   - Security constraints: Does spec meet required security posture?
   - Operational constraints: Does spec respect deployment/operational requirements?
   - Compliance constraints: Are regulatory requirements addressed?

   Pattern Consistency:
   - Are approved architectural patterns followed?
   - Do component designs match constitutional patterns?
   - Is error handling consistent with established patterns?

   **Flag conflicts** where spec contradicts constitution:
   - Record as HIGH PRIORITY issues (blocking governance)
   - Example: Constitution requires OAuth2, spec uses API keys
   - Example: Constitution mandates audit logging, spec doesn't mention it

   **PILLAR 3: Architecture Alignment** (NEW - if architecture exists)

   Validate spec against architectural boundaries:

   System Boundaries (Context View):
   - Does spec operate within defined external entity interactions?
   - Are new external dependencies within acceptable scope?
   - Do integration points match Context View?

   Component Alignment (Functional View):
   - Do new/modified components fit existing architecture?
   - Are component responsibilities clear and non-overlapping?
   - Do interactions follow established patterns?

   Data Model Consistency (Information View):
   - Do entities/relationships align with Information View?
   - Are data lifecycle requirements considered?
   - Do data flows match architectural design?

   Process Coordination (Concurrency View):
   - Are concurrency requirements architecturally feasible?
   - Do threading/async patterns match Concurrency View?
   - Are synchronization mechanisms appropriate?

   Code Organization (Development View):
   - Does spec respect code organization structure?
   - Are module dependencies appropriate?
   - Does testing approach align with Development View?

   Deployment Feasibility (Deployment View):
   - Can performance requirements be met with current deployment?
   - Are scalability expectations realistic?
   - Do infrastructure needs match Deployment View?

   Operational Readiness (Operational View):
   - Are monitoring/alerting requirements specified?
   - Is operational complexity acceptable?
   - Are backup/recovery needs considered?

   **Diagram Consistency Check**:
   - Compare architecture diagram content with textual descriptions
   - Detect missing components: Functional View text mentions component not in diagram
   - Detect missing entities: Information View entities missing from ER diagram
   - Detect flow mismatches: Concurrency View text/diagram inconsistencies

   **Auto-Fix Capability**:
   When diagram inconsistency detected:
   - Generate updated diagram code (mermaid or ascii based on format)
   - Insert corrected diagram in place of outdated one
   - Record in clarifications: "Auto-updated [View] diagram to include [component]"
   - Skip asking question since auto-fix resolved it

   **Flag architectural issues**:
   - Boundary violations: HIGH PRIORITY (system design impact)
   - Component misalignments: MEDIUM PRIORITY (refactoring needed)
   - Diagram inconsistencies: MEDIUM PRIORITY (auto-fixable)
   - Missing integration details: LOW PRIORITY (can defer to planning)

4. Generate (internally) a prioritized queue of candidate clarification questions (mode-aware limits):

     **Build Mode Question Generation:**
     - Maximum of 2 total questions across the whole session
     - Focus ONLY on scope-defining decisions that would prevent basic functionality
     - Skip detailed technical, performance, or edge case questions
     - Prioritize: core functionality > basic UX > essential data requirements

     **Spec Mode Question Generation:**
     - Maximum of 5 questions if no architecture present
     - Maximum of 10 questions if architecture present (expanded capacity)
     - Each question must be answerable with EITHER:
        - A short multiple‑choice selection (2–5 distinct, mutually exclusive options), OR
        - A one-word / short‑phrase answer (explicitly constrain: "Answer in <=5 words")
     - Only include questions whose answers materially impact architecture, data modeling, task decomposition, test design, UX behavior, operational readiness, or compliance validation
     - **Three-Pillar Priority Order** (highest impact first):
       1. Architecture boundary violations
       2. Constitution constraint violations
       3. Diagram-text inconsistencies (auto-fixable)
       4. Missing architecture integration points
       5. Spec completeness gaps
     - Ensure pillar coverage balance: prioritize constitutional/architectural issues over spec gaps
     - Favor clarifications that reduce downstream rework risk or prevent governance violations
     - If more than 10 issues remain (when architecture present), select top 10 by priority order above

4. Sequential questioning loop (interactive, mode-aware):

     **Build Mode Questioning:**
     - Present EXACTLY ONE question at a time (maximum 2 total)
     - Keep questions extremely simple and focused on basic functionality
     - Use short-answer format when possible to minimize interaction
     - Stop after 2 questions or when core functionality is clear

     **Spec Mode Questioning:**
     - Present EXACTLY ONE question at a time
     - For multiple‑choice questions:
        - **Analyze all options** and determine the **most suitable option** based on:
           - Best practices for the project type
           - Common patterns in similar implementations
           - Risk reduction (security, performance, maintainability)
           - Alignment with any explicit project goals or constraints visible in the spec
        - Present your **recommended option prominently** at the top with clear reasoning (1-2 sentences explaining why this is the best choice)
        - Format as: `**Recommended:** Option [X] - <reasoning>`
        - Then render all options as a Markdown table:

        | Option | Description |
        |--------|-------------|
        | A | <Option A description> |
        | B | <Option B description> |
        | C | <Option C description> |
        | Short | Provide a different short answer (<=5 words) |

        - After the table, add: `You can reply with the option letter (e.g., "A"), accept the recommendation by saying "yes" or "recommended", or provide your own short answer.`
     - For short‑answer style (no meaningful discrete options):
        - Provide your **suggested answer** based on best practices and context
        - Format as: `**Suggested:** <your proposed answer> - <brief reasoning>`
        - Then output: `Format: Short answer (<=5 words). You can accept the suggestion by saying "yes" or "suggested", or provide your own answer.`
     - After the user answers:
        - If the user replies with "yes", "recommended", or "suggested", use your previously stated recommendation/suggestion as the answer
        - Otherwise, validate the answer maps to one option or fits the <=5 word constraint
        - If ambiguous, ask for a quick disambiguation (count still belongs to same question; do not advance)
        - Once satisfactory, record it in working memory (do not yet write to disk) and move to the next queued question
     - Stop asking further questions when:
        - All critical ambiguities resolved early (remaining queued items become unnecessary), OR
        - User signals completion ("done", "good", "no more"), OR
        - You reach question limit (5 without architecture, 10 with architecture)
     - Never reveal future queued questions in advance

5. Sequential questioning loop (interactive):
    - Present EXACTLY ONE question at a time.
    - For multiple‑choice questions:
       - **Analyze all options** and determine the **most suitable option** based on:
          - Best practices for the project type
          - Common patterns in similar implementations
          - Risk reduction (security, performance, maintainability)
          - Alignment with any explicit project goals or constraints visible in the spec
       - Present your **recommended option prominently** at the top with clear reasoning (1-2 sentences explaining why this is the best choice).
       - Format as: `**Recommended:** Option [X] - <reasoning>`
       - Then render all options as a Markdown table:

       | Option | Description |
       |--------|-------------|
       | A | <Option A description> |
       | B | <Option B description> |
       | C | <Option C description> (add D/E as needed up to 5) |
       | Short | Provide a different short answer (<=5 words) (Include only if free-form alternative is appropriate) |

       - After the table, add: `You can reply with the option letter (e.g., "A"), accept the recommendation by saying "yes" or "recommended", or provide your own short answer.`
    - For short‑answer style (no meaningful discrete options):
       - Provide your **suggested answer** based on best practices and context.
       - Format as: `**Suggested:** <your proposed answer> - <brief reasoning>`
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
       - Terminology conflict → Normalize term across spec; retain original only if necessary by adding `(formerly referred to as "X")` once.
    - If the clarification invalidates an earlier ambiguous statement, replace that statement instead of duplicating; leave no obsolete contradictory text.
    - Save the spec file AFTER each integration to minimize risk of context loss (atomic overwrite).
    - Preserve formatting: do not reorder unrelated sections; keep heading hierarchy intact.
    - Keep each inserted clarification minimal and testable (avoid narrative drift).

6. Validation (performed after EACH write plus final pass):
   - Clarifications session contains exactly one bullet per accepted answer (no duplicates).
   - Total asked (accepted) questions ≤ 5.
   - Updated sections contain no lingering vague placeholders the new answer was meant to resolve.
   - No contradictory earlier statement remains (scan for now-invalid alternative choices removed).
   - Markdown structure valid; only allowed new headings: `## Clarifications`, `### Session YYYY-MM-DD`.
   - Terminology consistency: same canonical term used across all updated sections.

7. Write the updated spec back to `FEATURE_SPEC`.

8. Report completion (after questioning loop ends or early termination, mode-aware):

    **Build Mode Completion:**
    - Number of questions asked & answered (max 2)
    - Path to updated spec
    - Basic coverage summary (focus on core functionality)
    - Suggested next command: `/speckit.implement` (skip formal planning)

    **Spec Mode Completion:**
    - Number of questions asked & answered (max: 5 or 10 depending on architecture)
    - Path to updated spec
    - Sections touched (list names)
    - **Three-Pillar Validation Summary**:
      - **Spec Completeness**: Coverage summary table with Status per category
      - **Constitution Alignment**: Verified / Issues Found / Not Available (if missing)
      - **Architecture Alignment**: Verified / Issues Found / Not Available (if missing)
      - **Diagram Consistency**: List any auto-fixes applied
    - If any Outstanding or Deferred remain, recommend whether to proceed to `/speckit.plan` or run `/speckit.clarify` again later post-plan
    - Suggested next command

Behavior rules:

- If no meaningful ambiguities found across all three pillars, respond: "No critical ambiguities detected worth formal clarification. Constitution and architecture validated." and suggest proceeding.
- If spec file missing, instruct user to run `/speckit.specify` first (do not create a new spec here).
- Never exceed question limit: 5 (no architecture) or 10 (with architecture) total asked questions
- Clarification retries for a single question do not count as new questions
- Avoid speculative tech stack questions unless the absence blocks functional clarity
- Respect user early termination signals ("stop", "done", "proceed")
- If no questions asked due to full coverage across all pillars, output compact three-pillar summary then suggest advancing
- **Constitution/Architecture graceful handling**: If files missing, skip those pillars without error
- **Auto-fix diagrams silently**: When fixing diagram inconsistencies, apply update and note in clarifications (don't ask user)

1. **Mode Guidance & Transitions**:
    - **Build Mode**: Limited clarification (max 2 questions) focuses on critical blockers only
    - **Spec Mode**: Comprehensive clarification (max 5 questions) ensures thorough understanding
    - **Mode Switching**: If Build mode reveals unexpected complexity, suggest switching to Spec mode with `/speckit.mode spec`

- If quota reached with unresolved high-impact categories remaining, explicitly flag them under Deferred with rationale.

Context for prioritization: {ARGS}
