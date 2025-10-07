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

## Format: `[ID] [MODE] [P?] Description`
- **[MODE]**: Execution state from the plan (`[SYNC]` or `[ASYNC]`)
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 3.1: Setup
- [ ] T001 [SYNC] Create project structure per implementation plan
- [ ] T002 [SYNC] Initialize [language] project with [framework] dependencies
- [ ] T003 [ASYNC] [P] Configure linting and formatting tools

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T004 [SYNC] [P] Contract test POST /api/users in tests/contract/test_users_post.py
- [ ] T005 [SYNC] [P] Contract test GET /api/users/{id} in tests/contract/test_users_get.py
- [ ] T006 [SYNC] [P] Integration test user registration in tests/integration/test_registration.py
- [ ] T007 [SYNC] [P] Integration test auth flow in tests/integration/test_auth.py

## Phase 3.2b: Risk-Based Tests (Spec Risk Register)
- [ ] TR01 [SYNC] Risk R1 — RBAC denies non-admin roles (tests/integration/test_admin_access.py) → Capture evidence in risk-tests/R1.log
- [ ] TR02 [SYNC] Risk R2 — Prevent data loss during retries (tests/integration/test_retry_durability.py) → Capture evidence in risk-tests/R2.log

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T008 [ASYNC] [P] User model in src/models/user.py
- [ ] T009 [ASYNC] [P] UserService CRUD in src/services/user_service.py
- [ ] T010 [ASYNC] [P] CLI --create-user in src/cli/user_commands.py
- [ ] T011 [SYNC] POST /api/users endpoint
- [ ] T012 [SYNC] GET /api/users/{id} endpoint
- [ ] T013 [SYNC] Input validation
- [ ] T014 [SYNC] Error handling and logging

## Phase 3.4: Integration
- [ ] T015 [ASYNC] Connect UserService to DB
- [ ] T016 [SYNC] Auth middleware
- [ ] T017 [ASYNC] Request/response logging
- [ ] T018 [SYNC] CORS and security headers

## Phase 3.5: Polish
- [ ] T019 [ASYNC] [P] Unit tests for validation in tests/unit/test_validation.py
- [ ] T020 [SYNC] Performance tests (<200ms)
- [ ] T021 [ASYNC] [P] Update docs/api.md
- [ ] T022 [ASYNC] Remove duplication
- [ ] T023 [SYNC] Run manual-testing.md

## Dependencies
- Tests (T004-T007) before implementation (T008-T014)
- T008 blocks T009, T015
- T016 blocks T018
- Implementation before polish (T019-T023)

## Parallel Example
```
# Launch T004-T007 together:
Task: "Contract test POST /api/users in tests/contract/test_users_post.py"
Task: "Contract test GET /api/users/{id} in tests/contract/test_users_get.py"
Task: "Integration test registration in tests/integration/test_registration.py"
Task: "Integration test auth in tests/integration/test_auth.py"
```

## Notes
- [P] tasks = different files, no dependencies
- `[SYNC]` tasks require hands-on micro-review and pairing; `[ASYNC]` tasks can be delegated but still require macro-review before commit
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts
- Risk tasks (`TRxx`) must reference the exact Risk ID and evidence location defined in plan.md.

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

5. **Risk Coverage**:
   - For each Risk ID in spec/plan, create at least one `[SYNC]` test task prefixed `TR` that references the risk, test path, and evidence artefact.
   - If multiple mitigations exist, create a task per mitigation/test.
   - Document required evidence capture in the task description (e.g., `→ Capture evidence in risk-tests/R1.log`).

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task
- [ ] Every Risk ID has at least one `[SYNC]` risk test task with evidence path

## Risk Evidence Log (maintained during /implement)
| Risk ID | Test Task ID | Evidence Artefact | Evidence Summary |
|---------|--------------|-------------------|------------------|
| R1 | TR01 | risk-tests/R1.log | TBD – populate with `/implement` test output |