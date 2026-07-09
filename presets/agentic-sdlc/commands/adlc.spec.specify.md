---
description: Create or update the feature specification from a natural language feature description.
handoffs: 
  - label: Build Technical Plan
    agent: adlc.spec.plan
    prompt: Create a plan for the spec. I am building with...
  - label: Clarify Spec Requirements
    agent: adlc.spec.clarify
    prompt: Clarify specification requirements
    send: true
  - label: Validate Mission Brief Adequacy
    agent: adlc.spec.checklist
    prompt: Run /spec.checklist mission-brief to validate oracle adequacy before planning
    send: true
scripts:
  sh: scripts/bash/create-new-feature.sh "{ARGS}"
  ps: scripts/powershell/create-new-feature.ps1 "{ARGS}"
---

## Phase A: Discovery Hooks (Read-Only)

**Execute ONLY read-only discovery hooks.**

0. Determine `{REPO_ROOT}` by running `git rev-parse --show-toplevel 2>/dev/null`. If that fails, walk up from the current directory until you find a `.git` directory or `.specify/init-options.json` and use that parent as `{REPO_ROOT}`.
1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, state `No hooks file found` and skip to Mission Brief Extraction.
2. Read `{REPO_ROOT}/.specify/extensions.yml` and find `hooks.before_specify`.
3. Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default. Skip any hook with a non-empty `condition` and leave condition evaluation to the HookExecutor implementation.
4. **Classify each hook by mutation risk** (inspect the `{command}` name):
   - **Read-only / discovery hooks** (safe to run before Phase B):
     - `agent-context.update` (read-only refresh)
     - Any command whose name contains `discover`, `verify`, `validate` (when used for read-only context gathering)
   - **Mutating hooks** (MUST be deferred until after discovery hooks):
     - `git.feature` — creates branches/worktrees
     - `git.commit` — creates commits
     - `git.initialize` — initializes repositories
     - Any hook that modifies filesystem, Git state, or creates resources
5. For each **read-only** hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Pre-Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}

      Wait for the result of the hook command before proceeding.
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:spec-...` or `$spec-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`):
      ```
      ## Extension Hooks

      **Optional Hook**: {extension}
      Command: `/{command}`
      Description: {description}

      Prompt: {prompt}
      To execute: `/{command}`
      ```
      Let the user decide whether to execute the optional hook.
6. For each **mutating** hook: do NOT execute yet. Note it for Phase B.
7. State which discovery hooks were executed, then proceed to Mission Brief Extraction.


## Mission Brief Extraction

### Brainstorm Draft Detection

Before extracting from user input, check if `.specify/drafts/brainstorm-context.md` exists:

1. If it exists, read it in full to extract Goal, Success Criteria, Constraints, and Risk Register items.
2. Use the **Recommended Direction** section as the primary signal for Goal and approach.
3. Use the **Risk Register** to pre-populate the spec's Risk Register section.
4. Use the **Architecture Notes** and **Key Concepts** to seed the spec context.
5. Use the **Problem Statement** to inform the spec's Goal.
6. The draft content takes **priority** over automatic extraction from $ARGUMENTS for overlapping fields.
7. Note in the output: `Brainstorm context consumed from .specify/drafts/brainstorm-context.md`

### Automatic Extraction

If user input ($ARGUMENTS) is substantial (10+ words) and no brainstorm draft was consumed, extract Goal, Success Criteria, and Constraints from it and populate them directly into the spec header fields.

If minimal (< 10 words) or empty (and no brainstorm draft), derive a best-effort Goal from the generated short name. **Always derive at least one checkable Success Criterion** from the goal — never leave it as a template placeholder. For example, if the goal is "add dark mode toggle", the criterion is "toggling dark mode persists across page reloads" or "dark mode CSS class is applied to the root element". Leave Constraints as placeholders only if truly unknown.

### Behavior
- Always populate what you can from the available input.
- **Never leave Success Criteria as "TBD" or template placeholders** — derive a checkable criterion from the goal.
- Brainstorm draft content takes precedence over auto-extraction from $ARGUMENTS.
- No confirmation prompt. Approval is deferred to `__SPECKIT_COMMAND_CLARIFY__`.
- Proceed directly to Phase B after extraction.

---

## Phase B: Mutating Hooks

1. Before executing any deferred `git.feature` hook, inspect `.specify/extensions/git/git-config.yml`:
   - If `branch_template` is configured and contains `{issue}`, resolve an issue key before running the hook.
   - Resolution order:
     1. Use explicit `GIT_BRANCH_ISSUE` if already provided.
      2. Otherwise extract an issue key from the user request or the extracted Mission Brief.
     3. If no issue key is available, STOP and ask the user for it before executing `git.feature`.
   - The issue key MUST match the configured `issue_format`:
     - `jira`: `PROJ-123`
     - `numeric`: `1234`
   - Pass the value through to the hook using `GIT_BRANCH_ISSUE`, or `--issue` / `-Issue` if you invoke the script directly.
2. For each **mutating** hook noted in Phase A:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Pre-Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}

      Wait for the result of the hook command before proceeding.
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:spec-...` or `$spec-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`):
      ```
      ## Extension Hooks

      **Optional Hook**: {extension}
      Command: `/{command}`
      Description: {description}

      Prompt: {prompt}
      To execute: `/{command}`
      ```
      Let the user decide whether to execute the optional hook.
3. State which mutating hooks were executed.
4. If `git.feature` was executed and returned `BRANCH_NAME`/`FEATURE_NUM`, display:
   ```
   Branch created: {BRANCH_NAME} (Feature #{FEATURE_NUM})
   ```
---

## User Input
```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The text the user typed after `__SPECKIT_COMMAND_SPECIFY__` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `{ARGS}` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given that feature description, do this:

1. **Generate a concise short name** (2-4 words) for the feature:
   - Analyze the feature description and extract the most meaningful keywords
   - Create a 2-4 word short name that captures the essence of the feature
   - Keep it concise but descriptive enough to understand the feature at a glance
   - Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
   - Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)
   - Examples:
     - "I want to add user authentication" → "user-auth"
     - "Create a dashboard for analytics" → "analytics-dashboard"
     - "Fix payment processing timeout bug" → "fix-payment-timeout"
     - "Implement OAuth2 integration for the API" → "oauth2-api-integration"

2. **Branch creation** (already completed in Phase B if `git.feature` hook was present):

   The branch/worktree was created during Phase B mutating hooks (if applicable).
   Note the `BRANCH_NAME` and `FEATURE_NUM` values for reference, but the branch name does **not** dictate the spec directory name.

   If the user explicitly provided `GIT_BRANCH_NAME`, it was already passed through to the hook in Phase B.

3. **Create the spec feature directory**:

   Specs live under the default `specs/` directory unless the user explicitly provides `SPECIFY_FEATURE_DIRECTORY`.

   **Resolution order for `SPECIFY_FEATURE_DIRECTORY`**:
   1. If the user explicitly provided `SPECIFY_FEATURE_DIRECTORY`, use it as-is
   2. Otherwise, auto-generate it under `specs/`:
      - Check `.specify/init-options.json` for `feature_numbering` (preferred)
      - If `feature_numbering` is absent, fall back to `branch_numbering` (deprecated, migration only)
      - If `"timestamp"`: prefix is `YYYYMMDD-HHMMSS` (current timestamp)
      - If `"sequential"` or absent: prefix is `NNN` (next available 3-digit number after scanning existing directories in `specs/`)
      - Construct: `<prefix>-<short-name>` (e.g., `20260319-143022-user-auth` or `003-user-auth`)
      - Set `SPECIFY_FEATURE_DIRECTORY` to `specs/<directory-name>`
      - If `branch_numbering` was used, emit: "⚠️ `branch_numbering` in init-options.json is deprecated. Rename to `feature_numbering`."

   **Create the directory and spec file**:
   - `mkdir -p SPECIFY_FEATURE_DIRECTORY`
   - Copy `templates/spec-template.md` to `SPECIFY_FEATURE_DIRECTORY/spec.md`
   - Set `SPEC_FILE` to `SPECIFY_FEATURE_DIRECTORY/spec.md`
   - Persist the resolved path to `.specify/feature.json`:
     ```json
     {
       "feature_directory": "<resolved feature dir>"
     }
     ```
      Write the actual resolved directory path, not the literal string `SPECIFY_FEATURE_DIRECTORY`.
      This allows downstream commands (`__SPECKIT_COMMAND_PLAN__`, `__SPECKIT_COMMAND_TASKS__`, etc.) to locate the feature directory without relying on git branch name conventions.

   **IMPORTANT**:
   - You must only create one feature per `__SPECKIT_COMMAND_SPECIFY__` invocation
   - The spec directory name and the git branch name are independent
   - The spec directory and file are always created by this command, never by the hook

4. **Brainstorm draft promotion**:
   If `.specify/drafts/brainstorm-context.md` exists:
   1. Copy it to `SPECIFY_FEATURE_DIRECTORY/brainstorm-context.md`
   2. Delete the draft: `rm .specify/drafts/brainstorm-context.md`
   3. State `Brainstorm context promoted to feature directory`

5. **IF EXISTS**: Load `{REPO_ROOT}/.specify/memory/constitution.md` for project principles and governance constraints. Use these constraints when shaping scope, success criteria, and assumptions in the spec.

6. Load `templates/spec-template.md` to understand required sections.

7. Follow this execution flow:
   1. Parse user description from arguments. If empty: ERROR "No feature description provided"
   2. Extract key concepts from description: actors, actions, data, constraints
   3. For unclear aspects:
      - Make informed guesses based on context and industry standards
      - Only mark with [NEEDS CLARIFICATION: specific question] if:
        - The choice significantly impacts feature scope or user experience
        - Multiple reasonable interpretations exist with different implications
        - No reasonable default exists
      - **LIMIT: Maximum 3 [NEEDS CLARIFICATION] markers total**
      - Prioritize clarifications by impact: scope > security/privacy > user experience > technical details
   4. Fill User Scenarios & Testing section. If no clear user flow: ERROR "Cannot determine user scenarios"
   5. Generate Functional Requirements: Each requirement must be testable. Use reasonable defaults for unspecified details (document assumptions in Assumptions section).
   6. Define Success Criteria: Create measurable, technology-agnostic outcomes. Include both quantitative metrics (time, performance, volume) and qualitative measures (user satisfaction, task completion). Each criterion must be verifiable without implementation details.
   7. Identify Key Entities (if data involved)
   8. Return: SUCCESS (spec ready for planning)

7. Write the specification to SPEC_FILE using the template structure, replacing placeholders with concrete details derived from the feature description while preserving section order and headings.

   **Post-write validation**: After writing `spec.md`, re-read it and verify the
   Success Criteria section does not contain "TBD", "placeholder", or empty
   content. If it does, derive a checkable criterion from the Goal and rewrite
   the Success Criteria section before proceeding. Never leave Success Criteria
   as "TBD".

8. **Specification Quality Validation**: After writing the initial spec, validate it against quality criteria:

   a. **Create Spec Quality Checklist**: Generate a checklist file at `SPECIFY_FEATURE_DIRECTORY/checklists/requirements.md` using this structure:

      ```markdown
      # Specification Quality Checklist: [FEATURE NAME]

      **Purpose**: Validate specification completeness and quality before proceeding to planning
      **Created**: [DATE]
      **Feature**: [Link to spec.md]

      ## Content Quality
      - [ ] No implementation details (languages, frameworks, APIs)
      - [ ] Focused on user value and business needs
      - [ ] Written for non-technical stakeholders
      - [ ] All mandatory sections completed

      ## Requirement Completeness
      - [ ] No [NEEDS CLARIFICATION] markers remain
      - [ ] Requirements are testable and unambiguous
      - [ ] Success criteria are measurable
      - [ ] Success criteria are technology-agnostic (no implementation details)
      - [ ] All acceptance scenarios are defined
      - [ ] Edge cases are identified
      - [ ] Scope is clearly bounded
      - [ ] Dependencies and assumptions identified

      ## Feature Readiness
      - [ ] All functional requirements have clear acceptance criteria
      - [ ] User scenarios cover primary flows
      - [ ] Feature meets measurable outcomes defined in Success Criteria
      - [ ] No implementation details leak into specification

      ## Notes

      - Items marked incomplete require spec updates before `__SPECKIT_COMMAND_CLARIFY__` or `__SPECKIT_COMMAND_PLAN__`
      ```

   b. **Run Validation Check**: Review the spec against each checklist item. For each item, determine if it passes or fails. Document specific issues found (quote relevant spec sections).

   c. **Handle Validation Results**:
      - **If all items pass**: Mark checklist complete and proceed to step 8
      - **If items fail (excluding [NEEDS CLARIFICATION])**:
        1. List the failing items and specific issues
        2. Update the spec to address each issue
        3. Re-run validation until all items pass (max 3 iterations)
        4. If still failing after 3 iterations, document remaining issues in checklist notes and warn user
      - **If [NEEDS CLARIFICATION] markers remain**:
        1. Extract all [NEEDS CLARIFICATION: ...] markers from the spec
        2. **LIMIT CHECK**: If more than 3 markers exist, keep only the 3 most critical (by scope/security/UX impact) and make informed guesses for the rest
        3. For each clarification needed (max 3), present options to user:

           ```markdown
           ## Question [N]: [Topic]

           **Context**: [Quote relevant spec section]
           **What we need to know**: [Specific question]

           | Option | Answer | Implications |
           |--------|--------|--------------|
           | A | [First answer] | [What this means] |
           | B | [Second answer] | [What this means] |
           | C | [Third answer] | [What this means] |
           | Custom | Provide your own | [How to provide input] |

            **Your choice**: _[Wait for user response]_
            ```

            **CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
            - Use consistent spacing with pipes aligned
            - Each cell should have spaces around content: `| Content |` not `|Content|`
            - Header separator must have at least 3 dashes: `|--------|`
            - Test that the table renders correctly in markdown preview

         4. Number questions sequentially (Q1, Q2, Q3 - max 3 total)
        5. Present all questions together before waiting for responses
        6. Wait for user to respond with their choices for all questions
        7. Update the spec by replacing each [NEEDS CLARIFICATION] marker with the user's selected or provided answer
        8. Re-run validation after all clarifications are resolved

   d. **Update Checklist**: After each validation iteration, update the checklist file with current pass/fail status

9. **Report completion** to the user with:
   - `SPECIFY_FEATURE_DIRECTORY` — the feature directory path
   - `SPEC_FILE` — the spec file path
   - Checklist results summary
   - Readiness for the next phase (`__SPECKIT_COMMAND_CLARIFY__` or `__SPECKIT_COMMAND_PLAN__`)

**NOTE:** Branch creation is handled by the `before_specify` hook (git extension) during **Phase B** (mutating hooks). Spec directory and file creation are always handled by this core command, also during Phase B.

## Quick Guidelines

- Focus on **WHAT** users need and **WHY**.
- Avoid HOW to implement (no tech stack, APIs, code structure).
- Written for business stakeholders, not developers.
- DO NOT create any checklists that are embedded in the spec. That will be a separate command.

### Section Requirements

- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation

When creating this spec from a user prompt:

1. **Make informed guesses**: Use context, industry standards, and common patterns to fill gaps
2. **Document assumptions**: Record reasonable defaults in the Assumptions section
3. **Limit clarifications**: Maximum 3 [NEEDS CLARIFICATION] markers - use only for critical decisions that:
   - Significantly impact feature scope or user experience
   - Have multiple reasonable interpretations with different implications
   - Lack any reasonable default
4. **Prioritize clarifications**: scope > security/privacy > user experience > technical details
5. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
6. **Common areas needing clarification** (only if no reasonable default exists):
   - Feature scope and boundaries (include/exclude specific use cases)
   - User types and permissions (if multiple conflicting interpretations possible)
   - Security/compliance requirements (when legally/financially significant)

**Examples of reasonable defaults** (don't ask about these):

- Data retention: Industry-standard practices for the domain
- Performance targets: Standard web/mobile app expectations unless specified
- Error handling: User-friendly messages with appropriate fallbacks
- Authentication method: Standard session-based or OAuth2 for web apps
- Integration patterns: Use project-appropriate patterns (REST/GraphQL for web services, function calls for libraries, CLI args for tools, etc.)

### Success Criteria Guidelines

Success criteria must be:

1. **Measurable**: Include specific metrics (time, percentage, count, rate)
2. **Technology-agnostic**: No mention of frameworks, languages, databases, or tools
3. **User-focused**: Describe outcomes from user/business perspective, not system internals
4. **Verifiable**: Can be tested/validated without knowing implementation details

**Good examples**:

- "Users can complete checkout in under 3 minutes"
- "System supports 10,000 concurrent users"
- "95% of searches return results in under 1 second"
- "Task completion rate improves by 40%"

**Bad examples** (implementation-focused):

- "API response time is under 200ms" (too technical, use "Users see results instantly")
- "Database can handle 1000 TPS" (implementation detail, use user-facing metric)
- "React components render efficiently" (framework-specific)
- "Redis cache hit rate above 80%" (technology-specific)

## Done When

- [ ] Specification written to `SPEC_FILE` and validated against the quality checklist
- [ ] Extension hooks dispatched or skipped according to the rules above
- [ ] Completion reported to user with feature directory, spec file path, and checklist results


## Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_specify`.
3. Skip hooks with `enabled: false` or non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:spec-...` or `$spec-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`):
      ```
      ## Extension Hooks

      **Optional Hook**: {extension}
      Command: `/{command}`
      Description: {description}

      Prompt: {prompt}
      To execute: `/{command}`
      ```
      Let the user decide whether to execute the optional hook.
5. If no hooks registered, skip silently.
