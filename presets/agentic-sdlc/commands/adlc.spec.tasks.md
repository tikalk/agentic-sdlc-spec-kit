---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
handoffs: 
  - label: Analyze For Consistency
    agent: adlc.spec.analyze
    prompt: Run a project analysis for consistency
    send: true
  - label: Implement Project
    agent: adlc.spec.implement
    prompt: Start the implementation in phases
    send: true
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
---

## MANDATORY: Pre-Execution Hooks

**STOP. Before reading User Input or doing ANY other work, execute extension hooks.**

0. Determine `{REPO_ROOT}` by running `git rev-parse --show-toplevel 2>/dev/null`. If that fails, walk up from the current directory until you find a `.git` directory or `.specify/init-options.json` and use that parent as `{REPO_ROOT}`.
1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, state `No hooks file found` and skip to User Input.
2. Read `{REPO_ROOT}/.specify/extensions.yml` and find `hooks.before_tasks`.
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

## Outline

1. **Setup**: Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### CRITICAL - Path Validation

**DO NOT write to project root or wrong feature directory**
- Parse `TASKS` path from script JSON output (should be `./specs/<BRANCH>/tasks.md`)
- Write tasks.md ONLY to the `FEATURE_DIR` - never to `./tasks.md`
- Common mistakes:
  - Writing to `./tasks.md` (root) instead of `./specs/<BRANCH>/tasks.md`
  - Writing to `./specs/master/tasks.md` (wrong branch) instead of `./specs/<BRANCH>/tasks.md`
- The correct TASKS path includes your feature branch (e.g., `001-user-auth`)

### Non-Git Repository Support

If working in a non-git repository:
- Ensure `SPECIFY_FEATURE` environment variable is set
- Run: `export SPECIFY_FEATURE=001-user-auth` before this command
- Without this, tasks.md will be written to the wrong location

2. **MANDATORY - Initialize Dual Execution Loop**:

   Run from repo root:
   ```bash
   bash .specify/scripts/bash/tasks-meta-utils.sh init "$FEATURE_DIR"
   ```
   This creates `$FEATURE_DIR/tasks_meta.json` for tracking SYNC/ASYNC execution modes, LLM delegation, and review enforcement.

   **VERIFY**: Confirm `$FEATURE_DIR/tasks_meta.json` exists before proceeding to step 3. If this file is missing, `/spec.implement` quality gates and `/spec.trace` will not function.

3. **Load design documents**: Read from FEATURE_DIR:
   - **Required**: plan.md (tech stack, libraries, structure), spec.md (user stories with priorities)
   - **Optional**: data-model.md (entities), contracts/ (API endpoints), research.md (decisions), quickstart.md (test scenarios)
   - Note: Not all projects have all documents. Generate tasks based on what's available.

4. **Execute task generation workflow** (follow the template structure):
   - Load plan.md and extract tech stack, libraries, project structure
   - **Load spec.md and extract user stories with their priorities (P1, P2, P3, etc.)**
   - If data-model.md exists: Extract entities → map to user stories
   - If contracts/ exists: Each file → map endpoints to user stories
   - If research.md exists: Extract decisions → generate setup tasks
   - **If risk-based testing is enabled in mode configuration**:
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
       - **For each task**, classify and register in execution metadata:
         ```bash
         MODE=$(bash .specify/scripts/bash/tasks-meta-utils.sh classify "$task_description" "$task_files")
         bash .specify/scripts/bash/tasks-meta-utils.sh add-task "$FEATURE_DIR/tasks_meta.json" "$task_id" "$task_description" "$task_files" "$MODE"
         ```
       - If tests requested: Include tests specific to that story
     - **Tests are CONFIGURABLE**: Check current mode opinion settings - if TDD enabled, generate test tasks before implementation; if disabled, tests are optional
     - Apply task rules:
       - Different files = mark [P] for parallel within story
       - Same file = sequential (no [P])
       - If TDD enabled (`is_opinion_enabled tdd $MODE`): Tests before implementation (TDD order)
     - If TDD disabled: Tests optional, generated only if explicitly requested
       - Classify execution mode per task ([SYNC] or [ASYNC])
     - Number tasks sequentially (T001, T002...)
     - Generate dependency graph showing user story completion order
     - Create parallel execution examples per user story
     - Validate task completeness (each user story has all needed tasks, independently testable)

5. **Generate tasks.md**: Use `templates/tasks-template.md` as structure, fill with:
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

5.5. **Worktree-mode DAG generation (conditional, off by default)**:
   - Read `.specify/extensions/git/git-config.yml` (skip silently if missing or unparseable)
   - Extract `isolation_mode` value (`branch` or `worktree`; default `branch`)
   - **If `isolation_mode: branch` (default) or config missing**: SKIP this step entirely (preserve upstream behavior)
   - **If `isolation_mode: worktree`**:
     - Determine feature branch name from `$FEATURE_DIR` (typically the leaf directory name, e.g., `001-user-auth`)
     - Run the shell-appropriate DAG generator:
       - **Bash**: `bash .specify/extensions/git/scripts/bash/tasks-dag.sh generate --tasks-md "$FEATURE_DIR/tasks.md" --feature "<branch_name>" --dag "$FEATURE_DIR/tasks_dag.json"`
       - **PowerShell**: `.specify/extensions/git/scripts/powershell/tasks-dag.ps1 generate -TasksMd "$FEATURE_DIR/tasks.md" -Feature "<branch_name>" -Dag "$FEATURE_DIR/tasks_dag.json"`
     - Capture the JSON output; verify `ok: true`
     - If `ok: false`, log the error to stderr but continue (DAG is informational, not blocking)
   - If `isolation_mode` is set to an unknown value: WARN and SKIP

6. **Report**: Output path to generated tasks.md and summary:
   - Total task count
   - Task count per user story
   - Parallel opportunities identified
   - Independent test criteria for each story
   - Suggested MVP scope (typically just User Story 1)
   - Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)

Context for task generation: {ARGS}

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.

## Task Generation Rules

**CRITICAL**: Tasks MUST be organized by user story to enable independent implementation and testing.

**Tests are OPTIONAL**: Only generate test tasks if explicitly requested in the feature specification or if user requests TDD approach.

### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [SYNC/ASYNC] [Story?] Description with file path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
3. **[P] marker**: Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
4. **[SYNC]/[ASYNC] marker**: REQUIRED for all tasks
   - **[SYNC]**: Requires human review (complex logic, security-critical, ambiguous requirements)
   - **[ASYNC]**: Can be delegated to async agents (well-defined CRUD, repetitive tasks, clear specs)
5. **[Story] label**: REQUIRED for user story phase tasks only
   - Format: [US1], [US2], [US3], etc. (maps to user stories from spec.md)
   - Setup phase: NO story label
   - Foundational phase: NO story label
   - User Story phases: MUST have story label
   - Polish phase: NO story label
6. **Description**: Clear action with exact file path

**Examples**:

- ✅ CORRECT: `- [ ] T005 [P] [SYNC] Implement authentication middleware in src/middleware/auth.py`
- ❌ WRONG: `- [ ] Create User model` (missing ID, SYNC/ASYNC, and Story label)

See `templates/tasks-template.md` for additional examples and full phase structure.

### Task Organization

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
   - Map each entity to the user story(ies) that need it
   - If entity serves multiple stories: Put in earliest story or Setup phase
   - Relationships → service layer tasks in appropriate story phase

4. **From Setup/Infrastructure**:
   - Shared infrastructure → Setup phase (Phase 1)
   - Foundational/blocking tasks → Foundational phase (Phase 2)
   - Story-specific setup → within that story's phase

### Phase Structure & Ordering

- **Phase 1**: Setup (project initialization)
- **Phase 2**: Foundational (blocking prerequisites - MUST complete before user stories)
- **Phase 3+**: User Stories in priority order (P1, P2, P3...)
  - Within each story: Tests (if requested) → Models → Services → Endpoints → Integration
  - Each phase should be a complete, independently testable increment
- **Final Phase**: Polish & Cross-Cutting Concerns

### [SYNC]/[ASYNC] Classification

See `templates/tasks-template.md` for detailed classification criteria and examples.

## Post-Execution Hooks

1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_tasks`.
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
