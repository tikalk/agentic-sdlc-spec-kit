---
description: Create a change proposal with specification, optional plan, and task breakdown
handoffs:
  - label: Clarify Change Requirements
    agent: spec.clarify
    prompt: Clarify specification requirements for this change proposal
    send: true
  - label: Validate Change Proposal
    agent: spec.checklist
    prompt: Validate the change specification against quality criteria
    send: true
---

## MANDATORY: Pre-Execution Hooks

**STOP. Before reading User Input or doing ANY other work, execute extension hooks.**

1. If `.specify/extensions.yml` does not exist, state `No hooks file found` and skip to User Input.
2. Read `.specify/extensions.yml` and find `hooks.before_specify`.
3. Skip any hook with `enabled: false`. Skip any hook with a non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`): Read the command file for `{command}`. **First, read the extension's `extension.yml` manifest** and look up the `provides.commands` entry matching `{command}` to get the `file` field. Use that `file` path relative to the extension directory. If the manifest cannot be read, fall back to looking for `{command}.md` directly in the extension commands directory. Execute the command file's full instructions NOW before continuing.
   - **Optional** (`optional: true`): Display the hook name, command, and description. Let the user decide.
5. State which hooks were executed, then proceed to User Input.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

---

## Change Specification

### Step 1: Mission Brief

Collect answers to:
1. **Goal** — What needs to change?
2. **Success Criteria** — What defines completion?
3. **Constraints** — Time, priority, dependencies, tech limits?

Display:
```markdown
## Mission Brief

**Goal**: {response 1}
**Success Criteria**: {response 2}
**Constraints**: {response 3}
```

**STOP** — Wait for explicit "yes" before proceeding.

### Step 2: Generate Change Name

Create a concise 2-4 word kebab-case name from the goal (e.g., `fix-login-redirect`, `add-export-csv`).

### Step 3: Create Change Directory

Create `changes/NNN-{name}/` where `NNN` is the next available 3-digit number (scan `changes/` directory for existing numbers, increment from highest).

### Step 4: Create Artifacts

Create the following files in the change directory:

**spec.md** (always):
- Goal, Success Criteria, Constraints (from Mission Brief)
- Functional requirements (testable, technology-agnostic)
- Delta description: What files/modules are ADDED, MODIFIED, or REMOVED
- Risk Register: Any risks identified during scoping
- Status: Active

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

### Step 5: Report

```
Change created: changes/{NNN-name}/
├── spec.md     — What and why
{├── plan.md     — Technical approach (if applicable)}
└── tasks.md    — Implementation steps

Ready for implementation: /change.implement
```

---

## Post-Execution Hooks

1. If `.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_specify`.
3. Skip hooks with `enabled: false` or non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`): Read the command file for `{command}`. **First, read the extension's `extension.yml` manifest** and look up the `provides.commands` entry matching `{command}` to get the `file` field. Use that `file` path relative to the extension directory. If the manifest cannot be read, fall back to looking for `{command}.md` directly in the extension commands directory. Execute the command file's full instructions immediately.
   - **Optional** (`optional: true`): Display hook info for user decision.
5. If no hooks registered, skip silently.
