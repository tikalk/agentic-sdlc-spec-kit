# Tasks: /levelup Command for Knowledge Loop Closure

**Feature Branch**: `001-generate-the-specification`
**Plan**: specs/001-generate-the-specification/plan.md

---

## Setup Tasks

- T001: Initialize and verify local clone of team-ai-directives repository (set TEAM_AI_DIRECTIVES_REPO env var)
- T002: Ensure gh CLI is installed and authenticated
- T003: Prepare scripts/levelup.sh with executable permissions

## Test Tasks [P]

- T004 [P]: Write a shell test to verify that /levelup aborts if user rejects the AI-generated drafts
- T005 [P]: Write a shell test to verify that a Markdown asset is created in the correct context_modules/ subdirectory (e.g., rules/v1/, examples/v1/, personas/v1/)
- T006 [P]: Write a shell test to verify that the PR metadata and traceability comment are generated and presented for review
- T007 [P]: Write a shell test to verify that the traceability comment is posted to the original issue tracker with correct asset path and PR link

## Core Tasks

- T008: Implement LLM call in scripts/levelup.sh to draft asset, PR metadata, and traceability comment
- T009: Implement human-in-the-loop confirmation logic in scripts/levelup.sh (halt on rejection, allow for edit/abort as clarified)
- T010: Implement logic to place the new asset in the correct context_modules/ subdirectory and version (determine type and path)
- T011: Implement git workflow in scripts/levelup.sh to create branch, commit, push, and open PR in team-ai-directives
- T012: Implement logic to post traceability comment to the original issue tracker ticket

## Integration Tasks

- T013: Integrate error handling for gh CLI and LLM failures in scripts/levelup.sh
- T014: Integrate secret management best practices in scripts/levelup.sh (avoid leaking secrets in logs/PRs)

## Polish Tasks [P]

- T015 [P]: Add documentation to scripts/levelup.sh and .github/levelup.md
- T016 [P]: Add usage examples and troubleshooting section to quickstart.md
- T017 [P]: Review and update agent configuration templates to include /levelup command

---

## Parallel Execution Guidance

- All [P] tasks can be executed in parallel (e.g., T004, T005, T006, T007, T015, T016, T017)
- Core and integration tasks must be executed sequentially due to shared file dependencies

---

## Task Agent Commands (examples)

- To run all test tasks in parallel:
  ```bash
  # Example: Run all [P] test tasks
  ./run-task.sh T004 & ./run-task.sh T005 & ./run-task.sh T006 & ./run-task.sh T007
  wait
  ```
- To execute core tasks sequentially:
  ```bash
  ./run-task.sh T008
  ./run-task.sh T009
  ./run-task.sh T010
  ./run-task.sh T011
  ./run-task.sh T012
  ```

---

## Dependency Notes

- Setup tasks (T001-T003) must be completed before any other tasks
- Test tasks [P] can be run after setup
- Core tasks (T008-T012) depend on setup and should follow TDD: implement tests first, then code
- Integration tasks (T013-T014) depend on core logic
- Polish tasks [P] can be run in parallel after core and integration tasks
