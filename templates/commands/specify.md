---
description: Create or update the feature specification from a natural language feature description.
scripts:
  sh: scripts/bash/create-new-feature.sh --json "{ARGS}"
  ps: scripts/powershell/create-new-feature.ps1 -Json "{ARGS}"
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

The text the user typed after `/specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `{ARGS}` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given that feature description, do this:

1. Run the script `{SCRIPT}` from repo root and parse its JSON output for `BRANCH_NAME`, `SPEC_FILE`, `FEATURE_NUM`, `HAS_GIT`, `CONSTITUTION`, and `TEAM_DIRECTIVES`. All file paths must be absolute.
   - **IMPORTANT**: Run this script exactly once. Reuse the JSON it prints for all subsequent steps.
   - If `CONSTITUTION` is empty or missing, STOP and instruct the developer to run `/constitution` before proceeding—Stage 1 cannot continue without the foundational principles.
   - If `TEAM_DIRECTIVES` is missing, warn the developer that shared directives are unavailable and note that `@team/...` references will not resolve.
2. Load `templates/spec-template.md` to understand required sections. Review `templates/context-template.md` so you can highlight which fields the developer must fill before planning.
3. Extract the canonical issue identifier:
   - Scan `$ARGUMENTS` (and any referenced content) for `@issue-tracker` tokens and capture the latest `{ISSUE-ID}` reference.
   - If no issue ID is present, leave the placeholder as `[NEEDS CLARIFICATION: issue reference not provided]` and surface a warning to the developer.
   - If an issue ID is found, replace the `**Issue Tracker**` line in the template with `**Issue Tracker**: @issue-tracker {ISSUE-ID}` (preserve additional context if multiple IDs are relevant).
4. Read the constitution at `CONSTITUTION` and treat its non-negotiable principles as guardrails when drafting the specification.
5. When the directive references artifacts like `@team/context_modules/...`, resolve them to files beneath `TEAM_DIRECTIVES`. Load each referenced module to ground the specification; if a referenced file is absent, pause and ask the developer for guidance before continuing.
6. Write the specification to `SPEC_FILE` using the template structure, replacing placeholders with concrete details derived from the feature description (arguments) while preserving section order and headings. Ensure the `**Issue Tracker**` line is populated as described above.
7. Seed `context.md` in the feature directory (already created by the script) with any information you can auto-fill (issue IDs, summary snippets) and clearly call out remaining `[NEEDS INPUT]` markers the developer must resolve before running `/plan`.
8. Report completion with branch name, spec file path, linked issue ID (if any), the absolute path to `context.md`, and readiness for the next phase.

Note: The script creates and checks out the new branch and initializes the spec file before writing.
