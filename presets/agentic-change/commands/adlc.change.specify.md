---
description: Create a change proposal with specification, optional plan, and task breakdown
handoffs:
  - label: Clarify Change Requirements
    agent: adlc.spec.clarify
    prompt: Clarify specification requirements for this change proposal
    send: true
  - label: Validate Change Proposal
    agent: adlc.spec.checklist
    prompt: Validate the change specification against quality criteria
    send: true
---

## Phase A: Discovery Hooks (Read-Only)

**Execute ONLY read-only discovery hooks.**

0. Determine `{REPO_ROOT}` by running `git rev-parse --show-toplevel 2>/dev/null`. If that fails, walk up from the current directory until you find a `.git` directory or `.specify/init-options.json` and use that parent as `{REPO_ROOT}`.
1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, state `No hooks file found` and skip to Mission Brief Extraction.
2. Read `{REPO_ROOT}/.specify/extensions.yml` and find `hooks.before_specify`.
3. Skip any hook with `enabled: false`. Skip any hook with a non-empty `condition`.
4. **Classify each hook by mutation risk** (inspect the `{command}` name):
   - **Read-only / discovery hooks** (safe to run before Phase B):
     - `team-ai-directives.discover`, `team-ai-directives.constitution`
     - `agent-context.update` (read-only refresh)
     - Any command whose name contains `discover`, `verify`, `validate` (when used for read-only context gathering)
   - **Mutating hooks** (MUST be deferred until after Mission Brief):
     - `git.feature` — creates branches/worktrees
     - `git.commit` — creates commits
     - `git.initialize` — initializes repositories
     - Any hook that modifies filesystem, Git state, or creates resources
5. For each **read-only** hook:
   - **Mandatory** (`optional: false`): Execute the command file's full instructions NOW before continuing.
   - **Optional** (`optional: true`): Display the hook name, command, and description. Let the user decide.
6. For each **mutating** hook: do NOT execute yet. Note it for Phase B.
7. State which discovery hooks were executed, then proceed to Mission Brief Extraction.

---

## Mission Brief Extraction

### Automatic Extraction

If user input ($ARGUMENTS) is substantial (10+ words), extract Goal, Success Criteria, and Constraints from it directly — no confirmation prompt.

If minimal (< 10 words) or empty, derive a best-effort Goal from the change short name. Leave Success Criteria and Constraints as placeholders — they will be validated by the clarify handoff.

### Behavior
- Always populate what you can from the available input.
- No confirmation prompt. Proceed directly to Phase B.

---

## Phase B: Mutating Hooks

1. Before executing any deferred `git.feature` hook, inspect `.specify/extensions/git/git-config.yml`:
   - If `branch_pattern.enabled: true` and `branch_pattern.template` contains `{issue}`, resolve an issue key before running the hook.
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
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`): Display the hook name, command, and description. Let the user decide.
3. State which mutating hooks were executed.
4. If `git.feature` was executed and returned `BRANCH_NAME`/`FEATURE_NUM`, capture:
   - `BRANCH_NAME` and `FEATURE_NUM` from its JSON output
   - Persist to `.specify/feature.json`:
     ```json
     {
       "feature_directory": "changes/<FEATURE_NUM>-<short-name>",
       "feature_branch": "<BRANCH_NAME>",
       "feature_num": "<FEATURE_NUM>"
     }
     ```
   - Display:
     ```
     Branch created: {BRANCH_NAME} (Feature #{FEATURE_NUM})
     ```

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

---

## Change Specification

### Step 1: Generate Change Name

Create a concise 2-4 word kebab-case name from the goal (e.g., `fix-login-redirect`, `add-export-csv`).

### Step 2: Create Change Directory

**If `FEATURE_NUM` was captured from git.feature**: Use it as the NNN prefix.
**Otherwise**: Scan `changes/` directory for existing numbers and increment.

If `changes/NNN-{name}/` already exists, warn the user and prompt for a different name, removal of existing, or cancellation.

Create: `changes/{NNN}-{name}/`

### Step 3: Create Artifacts

**IF EXISTS**: Load `{REPO_ROOT}/.specify/memory/constitution.md`. If the constitution has no relevant principles for this change, note this in the risk register as a governance gap and proceed.

Create the following files in the change directory:

**spec.md** (always):
- Goal, Success Criteria, Constraints (from Mission Brief)
- Functional requirements (testable, technology-agnostic)
- Delta description: What files/modules are ADDED, MODIFIED, or REMOVED
- Risk Register: Any risks identified during scoping
- Status: Draft  (lifecycle: Draft → Active → Implemented → Verified → Complete)

**plan.md** (optional — only when complexity warrants):
Include a plan.md only if the change:
- Spans multiple modules/services
- Introduces new external dependencies
- Has security, performance, or migration complexity
- Benefits from technical decisions before coding

If created, include:
- Context and approach
- Key technical decisions with rationale
- Files to be modified
- Migration or rollback considerations

**tasks.md** (always):
Implementation checklist with numbered checkboxes:
```markdown
## Tasks

- [ ] 1. {Task description}
- [ ] 2. {Task description}
```

Tasks should be small enough to complete in one session, ordered by dependency.

### Step 4: Report

```
Change created: changes/{NNN-name}/
├── spec.md     — What and why
{├── plan.md     — Technical approach (if applicable)}
└── tasks.md    — Implementation steps

Feature context persisted: .specify/feature.json

Ready for implementation: /change.implement
```

---

## Post-Execution Hooks

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
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`): Display hook info for user decision.
     **STOP** — Wait for user decision before proceeding.
5. If no hooks registered, skip silently.
