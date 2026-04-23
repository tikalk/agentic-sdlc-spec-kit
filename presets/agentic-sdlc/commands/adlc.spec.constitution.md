---
description: Create or update the project constitution with team principles, ensuring governance alignment across the project.
handoffs: 
  - label: Specify Feature
    agent: adlc.spec.specify
    prompt: Create the feature specification based on the updated constitution
    send: true
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

### Parameters

Parse the following parameters from `$ARGUMENTS`:

## Pre-Execution Hooks

**Check for extension hooks (before constitution)**:
- Check if `{REPO_ROOT}/.specify/extensions.yml` exists in the project root
- If it exists, read it and look for entries under the `hooks.before_constitution` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For hooks with conditions, skip condition evaluation (leave to HookExecutor)
- For hooks without conditions, treat as executable

**For each executable hook**:
- **Optional hook** (`optional: true`):
  ```
  ## Extension Hooks

  **Optional Pre-Hook**: {extension}
  Command: `/{command}`
  Description: {description}

  This is an optional hook. You can choose to skip it.
  ```
  Wait for the result of the hook command before proceeding to the Outline.

- **Mandatory hook** (`optional: false`):
  ```
  ## Extension Hooks

  **Mandatory Pre-Hook**: {extension}
  Command: `/{command}`
  Description: {description}

  You **MUST** execute this hook before proceeding.
  ```
  Wait for the result of the hook command before proceeding to the Outline.

## Outline

You are updating or creating the project constitution at `{REPO_ROOT}/constitution.md`. This document defines the governance principles, decision-making framework, and team conventions for the project.

Follow this execution flow:

1. **Check for existing constitution**:
   - Look for `{REPO_ROOT}/constitution.md`
   - If it exists, load it to understand current governance principles
   - If not, you'll create from template

2. **Load team constitution principles** (via pre-execution hook):
   - The `before_constitution` hook should have loaded team principles from team-ai-directives
   - Extract core principles from the hook output (look for "Team Constitution Principles" block)
   - These principles should inform your project-level governance decisions

3. **Determine update scope** (from user input or existing constitution):
   - **New constitution**: Create from `presets/agentic-sdlc/templates/constitution-template.md`
   - **Amend existing**: Update specific principles/sections as requested
   - **Full review**: Validate all principles against team constitution

4. **Draft the constitution**:
   - Replace template placeholders with project-specific values
   - Incorporate team principles where applicable
   - Ensure governance sections are complete (principles, roles, processes, escalation)

5. **Output the constitution**:
   - Write to `{REPO_ROOT}/constitution.md`
   - Confirm the file location in your response

## Post-Execution

Report the constitution status:

```markdown
## Constitution Updated

- **Location**: `{REPO_ROOT}/constitution.md`
- **Principles**: Number of core principles defined
- **Team Alignment**: How team principles were incorporated
- **Version**: Updated version number (semver: MAJOR for governance changes, MINOR for new principles, PATCH for clarifications)
```