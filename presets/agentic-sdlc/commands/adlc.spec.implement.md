---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
handoffs:
  - label: Generate Feature Trace
    agent: adlc.spec.trace
    prompt: Generate a feature execution trace from the completed implementation
  - label: Assess Convergence
    agent: adlc.spec.converge
    prompt: Assess codebase against spec, plan, and tasks; if converged, run test gate and 4-pillar assessment
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## MANDATORY: Pre-Execution Hooks

**STOP. Before reading User Input or doing ANY other work, execute extension hooks.**

0. Determine `{REPO_ROOT}` by running `git rev-parse --show-toplevel 2>/dev/null`. If that fails, walk up from the current directory until you find a `.git` directory or `.specify/init-options.json` and use that parent as `{REPO_ROOT}`.
1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, state `No hooks file found` and skip to User Input.
2. Read `{REPO_ROOT}/.specify/extensions.yml` and find `hooks.before_implement`.
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

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### CRITICAL - Path Validation

**DO NOT read from wrong directory or write to project root**
- Parse `FEATURE_DIR` from script output - this is the correct path to your feature
- All required files (tasks.md, plan.md, spec.md) should be in `./specs/<BRANCH>/` NOT root
- Common mistakes:
  - Reading from `./tasks.md` instead of `./specs/<BRANCH>/tasks.md`
  - Writing implementation files to root instead of feature directory

2. **Worktree + DAG detection (conditional, off by default)**:
   - Read `.specify/extensions/git/git-config.yml` (skip silently if missing or unparseable)
   - Extract `isolation_mode` value (`branch` or `worktree`; default `branch`)
   - **If `isolation_mode: branch` (default) or config missing**: skip this entire step; proceed to step 3. Execution continues with `tasks_meta.json` and `[SYNC]/[ASYNC]` markers driving scheduling.
   - **If `isolation_mode: worktree`**:
     - Verify you are inside a feature worktree:
       - **Bash**: `bash .specify/extensions/git/scripts/bash/worktree-utils.sh is-in-worktree`
       - **PowerShell**: `.specify/extensions/git/scripts/powershell/worktree-utils.ps1 is-in-worktree`
     - Exit 0 (primary checkout): abort with message "Worktree mode requires running inside a feature worktree. Re-run this command from the WORKTREE_PATH returned by `git.feature --worktree`."
     - Exit 2 (inside a worktree): proceed
     - If `$FEATURE_DIR/tasks_dag.json` exists:
       - Read it; extract `execution_waves` (1-based; each wave is a list of 0-based task indices)
       - For each wave (in order):
         - Dispatch each task in the wave via subagent delegation
         - Wait for all tasks in the wave to complete
     - If `$FEATURE_DIR/tasks_dag.json` does NOT exist: log a warning and fall back to sequential implementation flow. `tasks_meta.json` and `[SYNC]/[ASYNC]` markers continue to drive scheduling.

3. **MANDATORY - Initialize Execution Tracking**:

   Run from repo root:
   ```bash
   bash .specify/scripts/bash/tasks-meta-utils.sh init "$FEATURE_DIR"
   ```

   **VERIFY**: Confirm `$FEATURE_DIR/tasks_meta.json` exists before proceeding. If missing, `/spec.trace` and quality gate tracking will not function.

   If `tasks_meta.json` already exists (e.g., created by `/spec.tasks`), skip this step.

4. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - Count: total items (`- [ ]` / `- [X]` / `- [x]`), completed (`- [X]` / `- [x]`), incomplete (`- [ ]`)
   - Create status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     ```

   - **PASS**: All checklists have 0 incomplete items
   - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" / "wait" / "stop", halt execution
     - If user says "yes" / "proceed" / "continue", proceed to step 5

   - **If all checklists are complete**: Display the table and automatically proceed to step 5

5. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
    - **IF EXISTS**: Read {REPO_ROOT}/.specify/memory/constitution.md for governance constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios

6. **Project Setup Verification**:
   - **REQUIRED**: Create/verify ignore files based on actual project setup

   **Detection & Creation Logic**:
   - Check if the following command succeeds to determine if the repository is a git repo (create/verify .gitignore if so):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Check if Dockerfile* exists or Docker in plan.md → create/verify .dockerignore
   - Check if .eslintrc* exists → create/verify .eslintignore
   - Check if eslint.config.* exists → ensure the config's `ignores` entries cover required patterns
   - Check if .prettierrc* exists → create/verify .prettierignore
   - Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
   - Check if terraform files (*.tf) exist → create/verify .terraformignore
   - Check if .helmignore needed (helm charts present) → create/verify .helmignore

   **If ignore file already exists**: Verify it contains essential patterns, append missing critical patterns only
   **If ignore file missing**: Create with full pattern set for detected technology

   **Common Patterns by Technology** (from plan.md tech stack):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `*.dll`, `autom4te.cache/`, `config.status`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **Tool-Specific Patterns**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

7. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements
   - **Load tasks_meta.json**: Read execution modes, delegation status, and review requirements
     - Record assigned agents and job IDs for ASYNC tasks

8. Execute implementation following execution approach:
   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together
   - **File-based coordination**: Tasks affecting the same files must run sequentially
    - **Per-task extension hooks**: For each individual task:
      - **Before task**: Check `{REPO_ROOT}/.specify/extensions.yml` for `hooks.before_task_execute` entries. Filter out disabled hooks. Execute mandatory hooks immediately; for optional hooks, skip silently to maintain flow. If no hooks registered, continue silently.
      - **Start task**: Mark task as in-progress:
        ```bash
        bash .specify/scripts/bash/tasks-meta-utils.sh start-task "$FEATURE_DIR/tasks_meta.json" "$task_id"
        ```
      - **Execute the task**
      - **Complete task** (on success): Update metadata and record summary:
        ```bash
        bash .specify/scripts/bash/tasks-meta-utils.sh complete-task "$FEATURE_DIR/tasks_meta.json" "$task_id" "<brief-result-summary>"
        ```
      - **After task**: Check `{REPO_ROOT}/.specify/extensions.yml` for `hooks.after_task_execute` entries. Same dispatch logic as before_task_execute.
      - **On task failure**: Mark task as failed first, then dispatch after_task_execute hooks:
        ```bash
        bash .specify/scripts/bash/tasks-meta-utils.sh fail-task "$FEATURE_DIR/tasks_meta.json" "$task_id" "<failure-reason>"
        ```
        Then dispatch `after_task_execute` hooks before reporting the error (allows WIP checkpoint commits if git extension is configured).
   - **Dual execution mode handling**:
     - **SYNC tasks**: Execute immediately with human oversight, require micro-review via `scripts/bash/tasks-meta-utils.sh review-micro "$FEATURE_DIR/tasks_meta.json" "$task_id"`
     - **ASYNC tasks**: Generate delegation prompts via `scripts/bash/tasks-meta-utils.sh dispatch-async "$task_id" "$agent_type" "$description" "$context" "$requirements" "$instructions" "$FEATURE_DIR"`, send to LLM agents, monitor completion via `scripts/bash/tasks-meta-utils.sh check-status "$task_id" "$FEATURE_DIR"`, apply macro-review after completion
   - **Quality gates**: Apply differentiated validation based on execution mode via `scripts/bash/tasks-meta-utils.sh quality-gate "$FEATURE_DIR/tasks_meta.json" "$task_id"`
   - **Validation checkpoints**: Verify each phase completion before proceeding

9. Implementation execution rules:
   - **Setup first**: Initialize project structure, dependencies, configuration
   - **Tests before code**: Write tests for contracts, entities, and integration scenarios
   - **Core development**: Implement models, services, CLI commands, endpoints
   - **Integration work**: Database connections, middleware, logging, external services
   - **Polish and validation**: Unit tests, performance optimization, documentation

10. Progress tracking and error handling:
    - Report progress after each completed task
    - Halt execution if any non-parallel task fails
    - For parallel tasks [P], continue with successful tasks, report failed ones
    - Provide clear error messages with context for debugging
    - Suggest next steps if implementation cannot proceed
    - **IMPORTANT** For completed tasks, make sure to mark the task off as [X] in the tasks file.
    - Per-task metadata lifecycle (`start-task` → execute → `complete-task`/`fail-task`) is handled automatically in step 8. Do NOT call `add-task` — tasks are already registered by `/spec.tasks`.

11. **MANDATORY - Verify Execution Metadata**:

    Before reporting completion:
    ```bash
    test -f "$FEATURE_DIR/tasks_meta.json" || bash .specify/scripts/bash/tasks-meta-utils.sh init "$FEATURE_DIR"
    ```

    Print final task summary:
    ```bash
    bash .specify/scripts/bash/tasks-meta-utils.sh summary "$FEATURE_DIR/tasks_meta.json"
    ```

12. Completion validation:
    - Verify all required tasks are completed
    - Check that implemented features match the original specification
    - Validate that tests pass and coverage meets requirements
    - Confirm the implementation follows the technical plan
    - Report final status with comprehensive summary of completed work

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `__SPECKIT_COMMAND_TASKS__` first to regenerate the task list.

## Post-Execution Hooks

1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_implement`.
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
