---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR, AVAILABLE_DOCS, SPEC_RISKS, and PLAN_RISKS. All paths must be absolute.
2. Load and validate `context.md` from the feature directory:
   - STOP if the file is missing or contains `[NEEDS INPUT]` markers.
   - Capture mission highlights, relevant code paths, directives, and gateway status for downstream reasoning.
3. Load and analyze available design documents:
   - Always read plan.md for tech stack and libraries
   - IF EXISTS: Read data-model.md for entities
   - IF EXISTS: Read contracts/ for API endpoints
   - IF EXISTS: Read research.md for technical decisions
   - IF EXISTS: Read quickstart.md for test scenarios
   - Capture the finalized `[SYNC]`/`[ASYNC]` assignments from the plan's **Triage Overview** and apply them to generated tasks.

   Note: Not all projects have all documents. For example:
   - CLI tools might not have contracts/
   - Simple libraries might not need data-model.md
   - Generate tasks based on what's available

4. Build a consolidated Risk Register:
   - Merge SPEC_RISKS and PLAN_RISKS by `id` (Risk ID). If the same risk appears in both, prefer the richer description from plan.md for mitigation details.
   - STOP and prompt the developer if the spec declares risks but the plan lacks matching mitigation/test strategy rows.
   - For each consolidated risk, capture: `id`, `statement`, `impact`, `likelihood`, `test` (focus), and `evidence` (artefact path). Missing fields must be escalated to the developer.

5. Generate tasks following the template:
   - Use `/templates/tasks-template.md` as the base
   - Replace example tasks with actual tasks based on:
     * **Setup tasks**: Project init, dependencies, linting
     * **Test tasks [P]**: One per contract, one per integration scenario
     * **Core tasks**: One per entity, service, CLI command, endpoint
     * **Integration tasks**: DB connections, middleware, logging
     * **Polish tasks [P]**: Unit tests, performance, docs
    - For every task, append the Execution Mode tag `[SYNC]` or `[ASYNC]` as dictated by the plan. Never invent a mode—ask the developer when absent.
     - Introduce dedicated `[SYNC]` risk test tasks (prefix `TR`) for each Risk ID, referencing the exact file path to implement and the evidence artefact where `/implement` must store test output.

6. Task generation rules:
   - Each contract file → contract test task marked [P]
   - Each entity in data-model → model creation task marked [P]
   - Each endpoint → implementation task (not parallel if shared files)
   - Each user story → integration test marked [P]
   - Different files = can be parallel [P]
   - Same file = sequential (no [P])
    - Preserve the Execution Mode from the plan so downstream tooling can enforce SYNC vs ASYNC workflows.
    - Every Risk ID MUST have at least one `[SYNC]` test task with a clearly defined evidence artefact. If multiple mitigations exist, generate a task per mitigation/test.

7. Order tasks by dependencies:
   - Setup before everything
   - Tests before implementation (TDD)
   - Models before services
   - Services before endpoints
   - Core before integration
   - Everything before polish

8. Include parallel execution examples:
   - Group [P] tasks that can run together
   - Show actual Task agent commands

9. Create FEATURE_DIR/tasks.md with:
   - Correct feature name from implementation plan
   - Numbered tasks (T001, T002, etc.)
   - Clear file paths for each task
   - Dependency notes
   - Parallel execution guidance
   - Updated **Risk Evidence Log** table populated with Risk IDs and placeholder evidence entries (`TBD`) for `/implement` to update.

Context for task generation: {ARGS}

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.
