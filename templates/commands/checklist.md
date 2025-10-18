---
description: Generate a custom checklist for the current feature based on user requirements.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
---

## Checklist Purpose: "Unit Tests for English"

**CRITICAL CONCEPT**: Checklists are **UNIT TESTS FOR REQUIREMENTS WRITING** - they validate the quality, clarity, and completeness of requirements in a given domain.

**NOT for verification/testing**:
- ❌ NOT "Verify the button clicks correctly"
- ❌ NOT "Test error handling works"
- ❌ NOT "Confirm the API returns 200"
- ❌ NOT checking if code/implementation matches the spec

**FOR requirements quality validation**:
- ✅ "Are visual hierarchy requirements defined for all card types?" (completeness)
- ✅ "Is 'prominent display' quantified with specific sizing/positioning?" (clarity)
- ✅ "Are hover state requirements consistent across all interactive elements?" (consistency)
- ✅ "Are accessibility requirements defined for keyboard navigation?" (coverage)
- ✅ "Does the spec define what happens when logo image fails to load?" (edge cases)

**Metaphor**: If your spec is code written in English, the checklist is its unit test suite. You're testing whether the requirements are well-written, complete, unambiguous, and ready for implementation - NOT whether the implementation works.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execution Steps

1. **Setup**: Run `{SCRIPT}` from repo root and parse JSON for FEATURE_DIR, AVAILABLE_DOCS, and MODE_CONFIG.
    - All file paths must be absolute.
    - For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").
    - Parse MODE_CONFIG to determine current workflow mode and enabled framework options

2. **Clarify intent (dynamic)**: Derive up to THREE initial contextual clarifying questions (no pre-baked catalog). They MUST:
   - Be generated from the user's phrasing + extracted signals from spec/plan/tasks
   - Only ask about information that materially changes checklist content
   - Be skipped individually if already unambiguous in `$ARGUMENTS`
   - Prefer precision over breadth

   Generation algorithm:
   1. Extract signals: feature domain keywords (e.g., auth, latency, UX, API), risk indicators ("critical", "must", "compliance"), stakeholder hints ("QA", "review", "security team"), and explicit deliverables ("a11y", "rollback", "contracts").
   2. Cluster signals into candidate focus areas (max 4) ranked by relevance.
   3. Identify probable audience & timing (author, reviewer, QA, release) if not explicit.
   4. Detect missing dimensions: scope breadth, depth/rigor, risk emphasis, exclusion boundaries, measurable acceptance criteria.
   5. Formulate questions chosen from these archetypes:
      - Scope refinement (e.g., "Should this include integration touchpoints with X and Y or stay limited to local module correctness?")
      - Risk prioritization (e.g., "Which of these potential risk areas should receive mandatory gating checks?")
      - Depth calibration (e.g., "Is this a lightweight pre-commit sanity list or a formal release gate?")
      - Audience framing (e.g., "Will this be used by the author only or peers during PR review?")
      - Boundary exclusion (e.g., "Should we explicitly exclude performance tuning items this round?")
      - Scenario class gap (e.g., "No recovery flows detected—are rollback / partial failure paths in scope?")

   Question formatting rules:
   - If presenting options, generate a compact table with columns: Option | Candidate | Why It Matters
   - Limit to A–E options maximum; omit table if a free-form answer is clearer
   - Never ask the user to restate what they already said
   - Avoid speculative categories (no hallucination). If uncertain, ask explicitly: "Confirm whether X belongs in scope."

   Defaults when interaction impossible:
   - Depth: Standard
   - Audience: Reviewer (PR) if code-related; Author otherwise
   - Focus: Top 2 relevance clusters

   Output the questions (label Q1/Q2/Q3). After answers: if ≥2 scenario classes (Alternate / Exception / Recovery / Non-Functional domain) remain unclear, you MAY ask up to TWO more targeted follow‑ups (Q4/Q5) with a one-line justification each (e.g., "Unresolved recovery path risk"). Do not exceed five total questions. Skip escalation if user explicitly declines more.

3. **Understand user request**: Combine `$ARGUMENTS` + clarifying answers:
   - Derive checklist theme (e.g., security, review, deploy, ux)
   - Consolidate explicit must-have items mentioned by user
   - Map focus selections to category scaffolding
   - Infer any missing context from spec/plan/tasks (do NOT hallucinate)

4. **Load feature context**: Read from FEATURE_DIR:
     - spec.md: Feature requirements and scope
     - plan.md (if exists): Technical details, dependencies
     - tasks.md (if exists): Implementation tasks
     - .mcp.json (if exists): MCP server configurations
     - .specify/config/mode.json: Current mode and enabled options

    **Context Loading Strategy**:
    - Load only necessary portions relevant to active focus areas (avoid full-file dumping)
    - Prefer summarizing long sections into concise scenario/requirement bullets
    - Use progressive disclosure: add follow-on retrieval only if gaps detected
    - If source docs are large, generate interim summary items instead of embedding raw text
     - For MCP validation: Check .mcp.json structure and server configurations

5. **Apply Mode-Aware Checklist Generation**: Use MODE_CONFIG to adapt checklist content based on enabled framework options:

     **Parse MODE_CONFIG JSON**:
     - `current_mode`: "build" or "spec" (affects default option values)
     - `options.tdd_enabled`: true/false - include TDD requirement checks
     - `options.contracts_enabled`: true/false - include API contract checks
     - `options.data_models_enabled`: true/false - include data model checks
     - `options.risk_tests_enabled`: true/false - include risk-based testing checks

     **TDD Option (if options.tdd_enabled)**:
     - Include items checking if test requirements are specified in the spec
     - Validate that acceptance criteria are testable
     - Check for test scenario coverage in requirements

     **API Contracts Option (if options.contracts_enabled)**:
     - Include items validating OpenAPI/GraphQL contract requirements
     - Check for API specification completeness and clarity
     - Validate contract versioning and compatibility requirements

     **Data Models Option (if options.data_models_enabled)**:
     - Include items checking entity and relationship specifications
     - Validate data model completeness and consistency
     - Check for data validation and constraint requirements

     **Risk-Based Testing Option (if options.risk_tests_enabled)**:
     - Include items validating risk assessment coverage
     - Check for mitigation strategy specifications
     - Validate edge case and failure scenario requirements

6. **Generate checklist** - Create "Unit Tests for Requirements":
    - Create `FEATURE_DIR/checklists/` directory if it doesn't exist
    - Generate unique checklist filename:
      - Use short, descriptive name based on domain (e.g., `ux.md`, `api.md`, `security.md`, `mcp.md`)
      - Format: `[domain].md`
      - If file exists, append to existing file
    - Number items sequentially starting from CHK001
    - Each `/speckit.checklist` run creates a NEW file (never overwrites existing checklists)
    - For MCP validation: Include infrastructure quality checks when relevant to the checklist focus

   **CORE PRINCIPLE - Test the Requirements, Not the Implementation**:
   Every checklist item MUST evaluate the REQUIREMENTS THEMSELVES for:
   - **Completeness**: Are all necessary requirements present?
   - **Clarity**: Are requirements unambiguous and specific?
   - **Consistency**: Do requirements align with each other?
   - **Measurability**: Can requirements be objectively verified?
   - **Coverage**: Are all scenarios/edge cases addressed?
   
     **Category Structure** - Group items by requirement quality dimensions:
     - **Requirement Completeness** (Are all necessary requirements documented?)
     - **Requirement Clarity** (Are requirements specific and unambiguous?)
     - **Requirement Consistency** (Do requirements align without conflicts?)
     - **Acceptance Criteria Quality** (Are success criteria measurable?)
     - **Scenario Coverage** (Are all flows/cases addressed?)
     - **Edge Case Coverage** (Are boundary conditions defined?)
     - **Non-Functional Requirements** (Performance, Security, Accessibility, etc. - are they specified?)
     - **Dependencies & Assumptions** (Are they documented and validated?)
     - **Ambiguities & Conflicts** (What needs clarification?)
     - **MCP Configuration** (Are MCP servers properly configured for issue tracking and async delegation?)
     - **Framework Options** (Are enabled mode options properly specified in requirements?)
   
   **HOW TO WRITE CHECKLIST ITEMS - "Unit Tests for English"**:
   
   ❌ **WRONG** (Testing implementation):
   - "Verify landing page displays 3 episode cards"
   - "Test hover states work on desktop"
   - "Confirm logo click navigates home"
   
   ✅ **CORRECT** (Testing requirements quality):
   - "Are the exact number and layout of featured episodes specified?" [Completeness]
   - "Is 'prominent display' quantified with specific sizing/positioning?" [Clarity]
   - "Are hover state requirements consistent across all interactive elements?" [Consistency]
   - "Are keyboard navigation requirements defined for all interactive UI?" [Coverage]
   - "Is the fallback behavior specified when logo image fails to load?" [Edge Cases]
   - "Are loading states defined for asynchronous episode data?" [Completeness]
   - "Does the spec define visual hierarchy for competing UI elements?" [Clarity]
   
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
    - "Are mobile breakpoint requirements defined for responsive layouts? [Gap]"

    Clarity:
    - "Is 'fast loading' quantified with specific timing thresholds? [Clarity, Spec §NFR-2]"
    - "Are 'related episodes' selection criteria explicitly defined? [Clarity, Spec §FR-5]"
    - "Is 'prominent' defined with measurable visual properties? [Ambiguity, Spec §FR-4]"

    Consistency:
    - "Do navigation requirements align across all pages? [Consistency, Spec §FR-10]"
    - "Are card component requirements consistent between landing and detail pages? [Consistency]"

    Coverage:
    - "Are requirements defined for zero-state scenarios (no episodes)? [Coverage, Edge Case]"
    - "Are concurrent user interaction scenarios addressed? [Coverage, Gap]"
    - "Are requirements specified for partial data loading failures? [Coverage, Exception Flow]"

    Measurability:
    - "Are visual hierarchy requirements measurable/testable? [Acceptance Criteria, Spec §FR-1]"
    - "Can 'balanced visual weight' be objectively verified? [Measurability, Spec §FR-2]"

     Infrastructure (MCP Configuration):
     - "Is .mcp.json file present and contains valid JSON? [Completeness, Infrastructure]"
     - "Are MCP server URLs properly formatted and accessible? [Clarity, Infrastructure]"
     - "Is issue tracker MCP server configured for project tracking? [Coverage, Infrastructure]"
     - "Are async agent MCP servers configured for task delegation? [Completeness, Infrastructure]"
     - "Do MCP server configurations include required type and url fields? [Consistency, Infrastructure]"

     Framework Options (Mode-Aware):
     - "Are test requirements specified for all acceptance criteria? [Completeness, TDD]" (when TDD enabled)
     - "Are API contract specifications complete and versioned? [Completeness, Contracts]" (when contracts enabled)
     - "Are entity relationships and data models fully specified? [Completeness, Data Models]" (when data models enabled)
     - "Are risk mitigation strategies documented for critical paths? [Coverage, Risk Testing]" (when risk tests enabled)

    **Scenario Classification & Coverage** (Requirements Quality Focus):
    - Check if requirements exist for: Primary, Alternate, Exception/Error, Recovery, Non-Functional scenarios
    - For each scenario class, ask: "Are [scenario type] requirements complete, clear, and consistent?"
    - If scenario class missing: "Are [scenario type] requirements intentionally excluded or missing? [Gap]"
    - Include resilience/rollback when state mutation occurs: "Are rollback requirements defined for migration failures? [Gap]"

    **MCP Configuration Validation** (Infrastructure Quality Focus):
    - Check if `.mcp.json` file exists and is properly configured
    - Validate MCP server configurations for issue trackers and async agents
    - Ensure required fields (type, url) are present for each server
    - Verify URL formats and server types are valid
    - Check for proper integration with issue tracking systems (GitHub, Jira, etc.)
    - Validate async agent configurations for delegation support

   **Traceability Requirements**:
   - MINIMUM: ≥80% of items MUST include at least one traceability reference
   - Each item should reference: spec section `[Spec §X.Y]`, or use markers: `[Gap]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]`
   - If no ID system exists: "Is a requirement & acceptance criteria ID scheme established? [Traceability]"

    **Surface & Resolve Issues** (Requirements Quality Problems):
    Ask questions about the requirements themselves:
    - Ambiguities: "Is the term 'fast' quantified with specific metrics? [Ambiguity, Spec §NFR-1]"
    - Conflicts: "Do navigation requirements conflict between §FR-10 and §FR-10a? [Conflict]"
    - Assumptions: "Is the assumption of 'always available podcast API' validated? [Assumption]"
    - Dependencies: "Are external podcast API requirements documented? [Dependency, Gap]"
    - Missing definitions: "Is 'visual hierarchy' defined with measurable criteria? [Gap]"

    **MCP Configuration Issues** (Infrastructure Quality Problems):
    Ask questions about MCP setup quality:
    - Missing config: "Is .mcp.json file present in the project root? [Gap, Infrastructure]"
    - Invalid servers: "Do MCP server configurations have valid URLs and types? [Consistency, Infrastructure]"
    - Missing integrations: "Is issue tracker MCP configured for the project's tracking system? [Coverage, Infrastructure]"
    - Async delegation: "Are async agent MCP servers configured for task delegation? [Completeness, Infrastructure]"

    **MCP Configuration Validation Logic**:
    - When checklist focus includes infrastructure or deployment aspects, include MCP validation items
    - Check .mcp.json file existence and validity
    - Validate each MCP server configuration for required fields and proper formatting
    - Ensure issue tracker integration is configured for the project's tracking system
    - Verify async agent configurations are present for delegation support
    - Flag any MCP configuration issues that could impact development workflow

    **Content Consolidation**:
    - Soft cap: If raw candidate items > 40, prioritize by risk/impact
    - Merge near-duplicates checking the same requirement aspect
    - If >5 low-impact edge cases, create one item: "Are edge cases X, Y, Z addressed in requirements? [Coverage]"
    - For MCP items: Consolidate server validation checks into logical groupings

   **🚫 ABSOLUTELY PROHIBITED** - These make it an implementation test, not a requirements test:
   - ❌ Any item starting with "Verify", "Test", "Confirm", "Check" + implementation behavior
   - ❌ References to code execution, user actions, system behavior
   - ❌ "Displays correctly", "works properly", "functions as expected"
   - ❌ "Click", "navigate", "render", "load", "execute"
   - ❌ Test cases, test plans, QA procedures
   - ❌ Implementation details (frameworks, APIs, algorithms)
   
   **✅ REQUIRED PATTERNS** - These test requirements quality:
   - ✅ "Are [requirement type] defined/specified/documented for [scenario]?"
   - ✅ "Is [vague term] quantified/clarified with specific criteria?"
   - ✅ "Are requirements consistent between [section A] and [section B]?"
   - ✅ "Can [requirement] be objectively measured/verified?"
   - ✅ "Are [edge cases/scenarios] addressed in requirements?"
   - ✅ "Does the spec define [missing aspect]?"

6. **Structure Reference**: Generate the checklist following the canonical template in `templates/checklist-template.md` for title, meta section, category headings, and ID formatting. If template is unavailable, use: H1 title, purpose/created meta lines, `##` category sections containing `- [ ] CHK### <requirement item>` lines with globally incrementing IDs starting at CHK001.

7. **Report**: Output full path to created checklist, item count, and remind user that each run creates a new file. Summarize:
     - Focus areas selected
     - Depth level
     - Actor/timing
     - Any explicit user-specified must-have items incorporated
     - MCP configuration validation status (if included in checklist)
     - Framework options validation status (based on enabled mode options)

**Important**: Each `/speckit.checklist` command invocation creates a checklist file using short, descriptive names unless file already exists. This allows:

- Multiple checklists of different types (e.g., `ux.md`, `test.md`, `security.md`)
- Simple, memorable filenames that indicate checklist purpose
- Easy identification and navigation in the `checklists/` folder

To avoid clutter, use descriptive types and clean up obsolete checklists when done.

## Example Checklist Types & Sample Items

**UX Requirements Quality:** `ux.md`

Sample items (testing the requirements, NOT the implementation):
- "Are visual hierarchy requirements defined with measurable criteria? [Clarity, Spec §FR-1]"
- "Is the number and positioning of UI elements explicitly specified? [Completeness, Spec §FR-1]"
- "Are interaction state requirements (hover, focus, active) consistently defined? [Consistency]"
- "Are accessibility requirements specified for all interactive elements? [Coverage, Gap]"
- "Is fallback behavior defined when images fail to load? [Edge Case, Gap]"
- "Can 'prominent display' be objectively measured? [Measurability, Spec §FR-4]"

**API Requirements Quality:** `api.md`

Sample items:
- "Are error response formats specified for all failure scenarios? [Completeness]"
- "Are rate limiting requirements quantified with specific thresholds? [Clarity]"
- "Are authentication requirements consistent across all endpoints? [Consistency]"
- "Are retry/timeout requirements defined for external dependencies? [Coverage, Gap]"
- "Is versioning strategy documented in requirements? [Gap]"

**Performance Requirements Quality:** `performance.md`

Sample items:
- "Are performance requirements quantified with specific metrics? [Clarity]"
- "Are performance targets defined for all critical user journeys? [Coverage]"
- "Are performance requirements under different load conditions specified? [Completeness]"
- "Can performance requirements be objectively measured? [Measurability]"
- "Are degradation requirements defined for high-load scenarios? [Edge Case, Gap]"

**Security Requirements Quality:** `security.md`

Sample items:
- "Are authentication requirements specified for all protected resources? [Coverage]"
- "Are data protection requirements defined for sensitive information? [Completeness]"
- "Is the threat model documented and requirements aligned to it? [Traceability]"
- "Are security requirements consistent with compliance obligations? [Consistency]"
- "Are security failure/breach response requirements defined? [Gap, Exception Flow]"

**MCP Configuration Quality:** `mcp.md`

Sample items:
- "Is .mcp.json file present and properly configured? [Completeness, Infrastructure]"
- "Are MCP server URLs valid and accessible? [Clarity, Infrastructure]"
- "Is issue tracker MCP server configured for the project's tracking system? [Coverage, Infrastructure]"
- "Are async agent MCP servers properly configured for delegation? [Completeness, Infrastructure]"
- "Do MCP server configurations include required type and url fields? [Consistency, Infrastructure]"
- "Are MCP server types valid (http, websocket, stdio)? [Measurability, Infrastructure]"

**Framework Options Quality:** `options.md` (when mode options are enabled)

Sample items (varies based on enabled options):
- "Are test scenarios specified for all acceptance criteria? [Completeness, TDD]" (TDD enabled)
- "Are API contract specifications complete with versioning? [Completeness, Contracts]" (contracts enabled)
- "Are entity relationships and constraints fully documented? [Completeness, Data Models]" (data models enabled)
- "Are risk assessment and mitigation strategies specified? [Coverage, Risk Testing]" (risk tests enabled)
- "Are framework option requirements consistent with project complexity level? [Consistency, Options]"

## Anti-Examples: What NOT To Do

**❌ WRONG - These test implementation, not requirements:**

```markdown
- [ ] CHK001 - Verify landing page displays 3 episode cards [Spec §FR-001]
- [ ] CHK002 - Test hover states work correctly on desktop [Spec §FR-003]
- [ ] CHK003 - Confirm logo click navigates to home page [Spec §FR-010]
- [ ] CHK004 - Check that related episodes section shows 3-5 items [Spec §FR-005]
```

**✅ CORRECT - These test requirements quality:**

```markdown
- [ ] CHK001 - Are the number and layout of featured episodes explicitly specified? [Completeness, Spec §FR-001]
- [ ] CHK002 - Are hover state requirements consistently defined for all interactive elements? [Consistency, Spec §FR-003]
- [ ] CHK003 - Are navigation requirements clear for all clickable brand elements? [Clarity, Spec §FR-010]
- [ ] CHK004 - Is the selection criteria for related episodes documented? [Gap, Spec §FR-005]
- [ ] CHK005 - Are loading state requirements defined for asynchronous episode data? [Gap]
- [ ] CHK006 - Can "visual hierarchy" requirements be objectively measured? [Measurability, Spec §FR-001]
```

**Key Differences:**
- Wrong: Tests if the system works correctly
- Correct: Tests if the requirements are written correctly
- Wrong: Verification of behavior
- Correct: Validation of requirement quality
- Wrong: "Does it do X?" 
- Correct: "Is X clearly specified?"

