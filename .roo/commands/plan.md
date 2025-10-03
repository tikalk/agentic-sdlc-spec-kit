---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Given the implementation details provided as an argument, do this:

1. Run `.specify/scripts/bash/setup-plan.sh --json` from the repo root and parse JSON for `FEATURE_SPEC`, `IMPL_PLAN`, `SPECS_DIR`, `BRANCH`, `HAS_GIT`, `CONSTITUTION`, `TEAM_DIRECTIVES`, and `CONTEXT_FILE`. All future file paths must be absolute.
   - BEFORE proceeding, inspect `FEATURE_SPEC` for a `## Clarifications` section with at least one `Session` subheading. If missing or clearly ambiguous areas remain (vague adjectives, unresolved critical choices), PAUSE and instruct the user to run `/clarify` first to reduce rework. Only continue if: (a) Clarifications exist OR (b) an explicit user override is provided (e.g., "proceed without clarification"). Do not attempt to fabricate clarifications yourself.
   - If `CONSTITUTION` is empty or the file does not exist, STOP and instruct the developer to run `/constitution` (Stage 0) before continuing—Stage 2 requires established principles.
   - If `TEAM_DIRECTIVES` is missing, warn the developer that shared directives cannot be referenced; note any prompts pointing to `@team/...` modules and request guidance.
2. Load and validate the feature context at `CONTEXT_FILE`:
   - STOP immediately if the file is missing.
   - Scan for any remaining `[NEEDS INPUT]` markers; instruct the developer to populate them before proceeding.
   - Summarize key insights (mission brief, relevant code, directives, gateway status) for later reference.

3. Read and analyze the feature specification to understand:
   - The feature requirements and user stories
   - Functional and non-functional requirements
   - Success criteria and acceptance criteria
   - Any technical constraints or dependencies mentioned

4. Read the constitution using the absolute path from `CONSTITUTION` to understand non-negotiable requirements and gates.

5. Execute the implementation plan template:
   - Load `/.specify.specify/templates/plan-template.md` (already copied to IMPL_PLAN path)
   - Set Input path to FEATURE_SPEC
   - Run the Execution Flow (main) function steps 1-9
   - The template is self-contained and executable
   - Follow error handling and gate checks as specified
   - Let the template guide artifact generation in $SPECS_DIR:
     * Phase 0 generates research.md
     * Phase 1 generates data-model.md, contracts/, quickstart.md
     * Phase 2 generates tasks.md
   - If `TEAM_DIRECTIVES` was available, resolve any referenced modules (e.g., `@team/context_modules/...`) and integrate their guidance.
   - Incorporate user-provided details from arguments into Technical Context: $ARGUMENTS
   - Populate the "Triage Overview" table with preliminary `[SYNC]`/`[ASYNC]` suggestions per major step, updating the rationale as you complete each phase.
   - Update Progress Tracking as you complete each phase

6. Verify execution completed:
   - Check Progress Tracking shows all phases complete
   - Ensure all required artifacts were generated
   - Confirm no ERROR states in execution

7. Report results with branch name, file paths, generated artifacts, and a reminder that `context.md` must remain up to date for `/tasks` and `/implement`.

Use absolute paths with the repository root for all file operations to avoid path issues.
