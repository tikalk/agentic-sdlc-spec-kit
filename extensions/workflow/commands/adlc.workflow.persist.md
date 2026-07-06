---
description: "Make current feature's most recent run workflow permanent and register it."
---

## Goal

Find the most recent workflow run for the current feature, copy its `workflow.yml`
from the run directory into `.specify/workflows/<id>/`, and register it in the
workflow registry. This makes the workflow reusable via `specify workflow run <id>`
without regenerating it.

## Flow

### 1. Discover feature directory

Read `.specify/feature.json` to get the current feature name (e.g.,
`003-version-info-modal`).

### 2. Find the most recent run

Scan `.specify/workflows/runs/*/state.json`:

For each run directory:
1. Read `state.json`
2. Check if `workflow_id` matches the feature name
3. Add to candidates list with the run directory's modification time

Pick the most recent candidate (by directory mtime), regardless of status
(COMPLETED, PAUSED, FAILED — any run is valid for persistence).

### 3. Read the workflow YAML

Read `runs/<run_id>/workflow.yml` — this is the exact YAML that was executed,
including any model configuration and step definitions.

### 4. Register the workflow

1. Extract `workflow.id` and `workflow.name` from the YAML
2. Create directory: `.specify/workflows/<workflow.id>/`
3. Copy `runs/<run_id>/workflow.yml` → `.specify/workflows/<workflow.id>/workflow.yml`
4. Update `.specify/workflows/workflow-registry.json`:

```json
{
  "<workflow.id>": {
    "name": "<workflow.name>",
    "version": "1.0.0",
    "source": "persisted-from-run-<run_id>",
    "installed_at": "<ISO timestamp>",
    "updated_at": "<ISO timestamp>"
  }
}
```

If an entry for `<workflow.id>` already exists, update it (overwrite the YAML
and update the registry entry).

### 5. Confirm

```markdown
## Workflow Persisted

- **ID**: <workflow.id>
- **Name**: <workflow.name>
- **Source run**: <run_id>
- **Location**: .specify/workflows/<workflow.id>/workflow.yml

Run anytime with:
  specify workflow run <workflow.id> --input spec="<description>"

Resume with:
  /workflow.resume
```

## Error handling

- No run found for feature → "No workflow run found for feature '<feature-name>'.
  Use /workflow.mission to start one."
- Run directory missing `workflow.yml` → "Run <run_id> is missing workflow.yml.
  The run may be corrupted."
- Registry update fails → report error, the copied YAML remains in place

## Examples

```
# After a mission completes, persist the workflow for reuse
/workflow.persist

# After resuming and completing a failed run, persist the final workflow
/workflow.persist
```
