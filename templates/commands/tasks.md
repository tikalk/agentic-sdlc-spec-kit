---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

Check for `--include-risk-tests` flag in user input. If present, enable risk-based test generation.

## Outline

1. **Setup**: Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Initialize Dual Execution Loop**: Run `scripts/bash/tasks-meta-utils.sh init "$FEATURE_DIR"` to create tasks_meta.json structure for tracking SYNC/ASYNC execution modes, MCP job dispatching, and review enforcement.

2. **Load design documents**: Read from FEATURE_DIR:
   - **Required**: plan.md (tech stack, libraries, structure), spec.md (user stories with priorities)
   - **Optional**: data-model.md (entities), contracts/ (API endpoints), research.md (decisions), quickstart.md (test scenarios)
   - Note: Not all projects have all documents. Generate tasks based on what's available.

3. **Execute task generation workflow** (follow the template structure):
    - Load plan.md and extract tech stack, libraries, project structure
    - **Load spec.md and extract user stories with their priorities (P1, P2, P3, etc.)**
    - If data-model.md exists: Extract entities → map to user stories
    - If contracts/ exists: Each file → map endpoints to user stories
    - If research.md exists: Extract decisions → generate setup tasks
    - **If --include-risk-tests flag is present**:
      - Run `scripts/bash/generate-risk-tests.sh` with combined SPEC_RISKS and PLAN_RISKS from {SCRIPT} output
      - Parse the generated risk-based test tasks
      - Append them as a dedicated "Risk Mitigation" phase at the end of tasks.md
     - **Generate tasks ORGANIZED BY USER STORY**:
       - Setup tasks (shared infrastructure needed by all stories)
       - **Foundational tasks (prerequisites that must complete before ANY user story can start)**
       - For each user story (in priority order P1, P2, P3...):
         - Group all tasks needed to complete JUST that story
         - Include models, services, endpoints, UI components specific to that story
         - Mark which tasks are [P] parallelizable within each story
         - Classify tasks as [SYNC] (complex, requires human review) or [ASYNC] (routine, can be delegated to async agents)
         - **For each task**: Run `scripts/bash/tasks-meta-utils.sh classify "$task_description" "$task_files"` to determine execution mode and update tasks_meta.json with `scripts/bash/tasks-meta-utils.sh add-task "$FEATURE_DIR/tasks_meta.json" "$task_id" "$task_description" "$task_files" "$execution_mode"`
         - If tests requested: Include tests specific to that story
    - **Tests are OPTIONAL**: Only generate test tasks if explicitly requested in the feature spec or user asks for TDD approach
     - Apply task rules:
       - Different files = mark [P] for parallel within story
       - Same file = sequential (no [P])
       - If tests requested: Tests before implementation (TDD order)
       - Classify execution mode:
         - [SYNC] for: complex logic, architectural decisions, security-critical code, ambiguous requirements (requires human review)
         - [ASYNC] for: well-defined CRUD operations, repetitive tasks, clear specifications, independent components (can be delegated to async agents)
    - Number tasks sequentially (T001, T002...)
    - Generate dependency graph showing user story completion order
    - Create parallel execution examples per user story
    - Validate task completeness (each user story has all needed tasks, independently testable)

4. **Generate tasks.md**: Use `.specify/templates/tasks-template.md` as structure, fill with:
    - Correct feature name from plan.md
    - Phase 1: Setup tasks (project initialization)
    - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
    - Phase 3+: One phase per user story (in priority order from spec.md)
      - Each phase includes: story goal, independent test criteria, tests (if requested), implementation tasks
       - Clear [Story] labels (US1, US2, US3...) for each task
       - [P] markers for parallelizable tasks within each story
       - [SYNC]/[ASYNC] markers for execution mode classification
       - Checkpoint markers after each story phase
    - Final Phase: Polish & cross-cutting concerns
    - **If risk tests enabled**: Add "Risk Mitigation Phase" with generated risk-based test tasks
     - Numbered tasks (T001, T002...) in execution order
     - Clear file paths for each task
     - Dependencies section showing story completion order
     - Parallel execution examples per story
     - Implementation strategy section (MVP first, incremental delivery)

  5. **Apply Issue Tracker Labels**: If issue tracker MCP is configured and ASYNC tasks exist:
     - Apply `async-ready` and `agent-delegatable` labels to the associated issue
     - Update tasks_meta.json with labeling information
     - Enable automatic async agent triggering for qualifying tasks

  6. **Report**: Output path to generated tasks.md and summary:
     - Total task count
     - Task count per user story
     - Parallel opportunities identified
     - Independent test criteria for each story
     - **If risk tests enabled**: Number of risk mitigation tasks generated
     - **If issue labeling applied**: Issue ID and labels applied
     - Suggested MVP scope (typically just User Story 1)

Context for task generation: {ARGS}

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.

## Task Generation Rules

**IMPORTANT**: Tests are optional. Only generate test tasks if the user explicitly requested testing or TDD approach in the feature specification.

**CRITICAL**: Tasks MUST be organized by user story to enable independent implementation and testing.

1. **From User Stories (spec.md)** - PRIMARY ORGANIZATION:
   - Each user story (P1, P2, P3...) gets its own phase
   - Map all related components to their story:
     - Models needed for that story
     - Services needed for that story
     - Endpoints/UI needed for that story
     - If tests requested: Tests specific to that story
   - Mark story dependencies (most stories should be independent)
   
2. **From Contracts**:
   - Map each contract/endpoint → to the user story it serves
   - If tests requested: Each contract → contract test task [P] before implementation in that story's phase
   
3. **From Data Model**:
   - Map each entity → to the user story(ies) that need it
   - If entity serves multiple stories: Put in earliest story or Setup phase
   - Relationships → service layer tasks in appropriate story phase
   
4. **From Setup/Infrastructure**:
   - Shared infrastructure → Setup phase (Phase 1)
   - Foundational/blocking tasks → Foundational phase (Phase 2)
     - Examples: Database schema setup, authentication framework, core libraries, base configurations
     - These MUST complete before any user story can be implemented
   - Story-specific setup → within that story's phase

5. **Ordering**:
    - Phase 1: Setup (project initialization)
    - Phase 2: Foundational (blocking prerequisites - must complete before user stories)
    - Phase 3+: User Stories in priority order (P1, P2, P3...)
      - Within each story: Tests (if requested) → Models → Services → Endpoints → Integration
    - Final Phase: Polish & Cross-Cutting Concerns
    - Each user story phase should be a complete, independently testable increment

6. **[SYNC]/[ASYNC] Classification**:
    - **[SYNC] Tasks**: Require human review and oversight
      - Complex business logic or algorithms
      - Architectural or design decisions
      - Security-critical functionality
      - Integration with external systems
      - Ambiguous or unclear requirements
      - Tasks affecting multiple components
    - **[ASYNC] Tasks**: Can be safely delegated to async coding agents
      - Well-defined CRUD operations
      - Repetitive or boilerplate code
      - Clear, unambiguous specifications
      - Independent component implementation
      - Standard library/framework usage
      - Tasks with comprehensive test coverage

