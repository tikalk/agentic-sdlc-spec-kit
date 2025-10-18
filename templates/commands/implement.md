---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
scripts:
  sh: scripts/bash/implement.sh "$(scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks)"
  ps: scripts/powershell/implement.ps1 "$(scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks)"
---

## Mode Detection

1. **Check Current Workflow Mode**: Determine if the user is in "build" or "spec" mode by checking the mode configuration file at `.specify/config/mode.json`. If the file doesn't exist or mode is not set, default to "spec" mode.

2. **Mode-Aware Behavior**:
   - **Build Mode**: Lightweight implementation focused on core functionality with simplified validation
   - **Spec Mode**: Full implementation with comprehensive quality gates and dual execution loop

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline (Mode-Aware)

### Build Mode Execution Flow
**Focus:** Quick implementation of core functionality

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute.

2. **Lightweight Validation**:
   - Skip detailed checklist validation
   - Focus on core functionality requirements only
   - Use basic project setup verification

3. **Core Implementation**:
   - Execute essential tasks for primary user journey
   - Skip comprehensive testing and edge cases
   - Prioritize working functionality over complete coverage

4. **Basic Quality Gates**:
   - Verify core functionality works
   - Check for critical errors
   - Ensure basic usability

### Spec Mode Execution Flow
**Focus:** Comprehensive implementation with full validation

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     * Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     * Completed items: Lines matching `- [X]` or `- [x]`
     * Incomplete items: Lines matching `- [ ]`
   - Create a status table:
     ```
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```
   - Calculate overall status:
     * **PASS**: All checklists have 0 incomplete items
     * **FAIL**: One or more checklists have incomplete items
   
   - **If any checklist is incomplete**:
     * Display the table with incomplete item counts
     * **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     * Wait for user response before continuing
     * If user says "no" or "wait" or "stop", halt execution
     * If user says "yes" or "proceed" or "continue", proceed to step 3
   
   - **If all checklists are complete**:
     * Display the table showing all checklists passed
     * Automatically proceed to step 3

3. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios

4. **Project Setup Verification**:
   - **REQUIRED**: Create/verify ignore files based on actual project setup:
   
   **Detection & Creation Logic**:
   - Check if the following command succeeds to determine if the repository is a git repo (create/verify .gitignore if so):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```
   - Check if Dockerfile* exists or Docker in plan.md → create/verify .dockerignore
   - Check if .eslintrc* or eslint.config.* exists → create/verify .eslintignore
   - Check if .prettierrc* exists → create/verify .prettierignore
   - Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
   - Check if terraform files (*.tf) exist → create/verify .terraformignore
   - Check if .helmignore needed (helm charts present) → create/verify .helmignore
   
   **If ignore file already exists**: Verify it contains essential patterns, append missing critical patterns only
   **If ignore file missing**: Create with full pattern set for detected technology
   
   **Common Patterns by Technology** (from plan.md tech stack):
   - **Node.js/JavaScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `Makefile`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`
   
   **Tool-Specific Patterns**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`

   5. Parse tasks.md structure and extract (mode-aware):
       - **Task phases**: Setup, Tests, Core, Integration, Polish
       - **Task dependencies**: Sequential vs parallel execution rules
       - **Task details**: ID, description, file paths, parallel markers [P]
       - **Execution flow**: Order and dependency requirements
        - **Load tasks_meta.json**: Read execution modes, delegation status, and review requirements
       - Record assigned agents and job IDs for ASYNC tasks

   6. Execute implementation following execution approach (mode-aware):

       **Build Mode Execution:**
       - **Simplified flow**: Focus on core tasks for primary functionality
       - **Basic coordination**: Run essential tasks sequentially, skip complex parallel execution
       - **Lightweight validation**: Basic checks for core functionality
       - **Fast iteration**: Prioritize working code over comprehensive testing

       **Spec Mode Execution (Dual Execution Loop):**
       - **Phase-by-phase execution**: Complete each phase before moving to the next
       - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together
        - **Follow TDD approach** (if enabled): Check current mode opinion settings - if TDD enabled, execute test tasks before implementation tasks
       - **File-based coordination**: Tasks affecting the same files must run sequentially
       - **Dual execution mode handling**:
         - **SYNC tasks**: Execute immediately with human oversight, require micro-review via `scripts/bash/tasks-meta-utils.sh review-micro "$FEATURE_DIR/tasks_meta.json" "$task_id"`
          - **ASYNC tasks**: Generate delegation prompts via `scripts/bash/tasks-meta-utils.sh dispatch_async_task "$task_id" "$agent_type" "$description" ...`, send to LLM agents, monitor completion, apply macro-review after completion
       - **Quality gates**: Apply differentiated validation based on execution mode via `scripts/bash/tasks-meta-utils.sh quality-gate "$FEATURE_DIR/tasks_meta.json" "$task_id"`
       - **Validation checkpoints**: Verify each phase completion before proceeding

  7. Implementation execution rules (mode-aware):

     **Build Mode Rules:**
     - **Core first**: Focus on primary user journey implementation
     - **Basic setup**: Essential project structure and dependencies only
     - **Working functionality**: Prioritize demonstrable features over comprehensive coverage
     - **Iterative approach**: Get something working, then refine

     **Spec Mode Rules:**
     - **Setup first**: Initialize project structure, dependencies, configuration
      - **Tests before code** (if TDD enabled): If TDD is enabled in current mode settings and you need to write tests for contracts, entities, and integration scenarios
     - **Core development**: Implement models, services, CLI commands, endpoints
     - **Integration work**: Database connections, middleware, logging, external services
     - **Polish and validation**: Unit tests, performance optimization, documentation

  8. Progress tracking and error handling (mode-aware):
     - Report progress after each completed task
     - **Build Mode**: Continue on minor errors, focus on core functionality
     - **Spec Mode**: Halt execution if any non-parallel task fails
     - For parallel tasks [P], continue with successful tasks, report failed ones
     - Provide clear error messages with context for debugging
     - Suggest next steps if implementation cannot proceed
     - **IMPORTANT** For completed tasks, make sure to mark the task off as [X] in the tasks file.

  9. Issue Tracker Integration (Spec Mode only):
     - If ASYNC tasks were dispatched, update issue tracker with progress
     - Apply completion labels when ASYNC tasks finish
     - Provide traceability links between tasks and issue tracker items

  10. Completion validation (mode-aware):

      **Build Mode Validation:**
      - Verify core user journey works end-to-end
      - Check for critical errors or crashes
      - Confirm basic functionality is demonstrable
      - Report working status with core features summary

      **Spec Mode Validation:**
      - Verify all required tasks are completed
      - Check that implemented features match the original specification
      - Validate that tests pass and coverage meets requirements
      - Confirm the implementation follows the technical plan
      - Report final status with comprehensive summary of completed work

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/tasks` first to regenerate the task list.

**Mode-Specific Notes:**
- **Build Mode**: Can work with simplified task lists focused on core functionality
- **Spec Mode**: Requires comprehensive task breakdown with proper triage classification

**Mode Guidance & Transitions:**
- **Build Mode**: Lightweight implementation with basic validation - ideal for quick wins
- **Spec Mode**: Full dual execution loop with comprehensive quality gates - ideal for robust delivery
- **Mode Switching**: If Build mode implementation reveals gaps, switch to Spec mode with `/mode spec` for complete coverage

