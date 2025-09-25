# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] [TYPE] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[TYPE]**: **MUST BE EITHER** `[SYNC]` for interactive, pair-programming tasks; or `[ASYNC]` for delegated, autonomous agent tasks.
- Include exact file paths in descriptions

## Task Types
- **[SYNC]**: Synchronous tasks, requiring real-time human-AI collaboration (e.g., complex problem-solving, ambiguous requirements).
- **[ASYNC]**: Asynchronous tasks, suitable for delegation to autonomous agents (e.g., well-defined, repetitive work, generating boilerplate).

## Path Conventions
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 3.1: Setup
- [ ] T001 [ASYNC] Create project structure per implementation plan
- [ ] T002 [ASYNC] Initialize [language] project with [framework] dependencies
- [ ] T003 [P] [ASYNC] Configure linting and formatting tools

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T004 [P] [ASYNC] Contract test POST /api/users in tests/contract/test_users_post.py
- [ ] T005 [P] [ASYNC] Contract test GET /api/users/{id} in tests/contract/test_users_get.py
- [ ] T006 [P] [SYNC] Integration test user registration in tests/integration/test_registration.py
- [ ] T007 [P] [SYNC] Integration test auth flow in tests/integration/test_auth.py

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T008 [P] [ASYNC] User model in src/models/user.py
- [ ] T009 [P] [ASYNC] UserService CRUD in src/services/user_service.py
- [ ] T010 [P] [ASYNC] CLI --create-user in src/cli/user_commands.py
- [ ] T011 [SYNC] POST /api/users endpoint
- [ ] T012 [SYNC] GET /api/users/{id} endpoint
- [ ] T013 [ASYNC] Input validation
- [ ] T014 [ASYNC] Error handling and logging

## Phase 3.4: Integration
- [ ] T015 [SYNC] Connect UserService to DB
- [ ] T016 [SYNC] Auth middleware
- [ ] T017 [ASYNC] Request/response logging
- [ ] T018 [ASYNC] CORS and security headers

## Phase 3.5: Polish
- [ ] T019 [P] [ASYNC] Unit tests for validation in tests/unit/test_validation.py
- [ ] T020 [SYNC] Performance tests (<200ms)
- [ ] T021 [P] [ASYNC] Update docs/api.md
- [ ] T022 [ASYNC] Remove duplication
- [ ] T023 [SYNC] Run manual-testing.md

## Dependencies
- Tests (T004-T007) before implementation (T008-T014)
- T008 blocks T009, T015
- T016 blocks T018
- Implementation before polish (T019-T023)

## Parallel Example
```bash
# Launch T004-T007 together (example for SYNC tasks):
# Task: "Contract test POST /api/users in tests/contract/test_users_post.py"
# Task: "Contract test GET /api/users/{id} in tests/contract/test_users_get.py"
# Task: "Integration test registration in tests/integration/test_registration.py"
# Task: "Integration test auth in tests/integration/test_auth.py"
```

## Agent Integration for [ASYNC] Tasks
For tasks tagged as `[ASYNC]`, the following CLI command can be used to invoke an autonomous agent. The agent will execute the task and store its results (e.g., PR links, trace summaries) in a dedicated `.agentic/` directory within the feature's specification directory.

```bash
# Example for invoking an ASYNC task (e.g., T001)
mcp-cli execute-async-task --agent <agent_type> --task-id T001 --feature-dir {FEATURE_DIR}
```
Replace `<agent_type>` with the specific agent to use (e.g., `claude`, `gemini`, `opencode`). The `mcp-cli` command will be responsible for:
1. Reading the task details from `{FEATURE_DIR}/tasks.md`.
2. Invoking the specified autonomous agent with the task description and relevant context.
3. Storing agent results (PRs, trace summaries) in `{FEATURE_DIR}/.agentic/`.

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → Tests → Models → Services → Endpoints → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task