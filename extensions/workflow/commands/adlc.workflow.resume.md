---
description: Find paused/failed run for current feature and resume it.
---

## Goal

Find the most recent paused or failed workflow run for the current feature and
resume it from where it left off. The engine restores the run state and continues
execution from the interrupted step.

## Flow

### 1. Discover feature directory

Read `.specify/feature.json` to get the current feature name (e.g.,
`003-version-info-modal`).

### 2. Check for mission state

Read `.specify/extensions/workflow/.mission-state.json` if it exists. If present,
this means a mission was in progress and was interrupted. Use the `feature` field
from the state file to match runs.

If no mission state file exists, use the feature name from step 1 directly.

### 3. Scan runs for matching workflow

Scan `.specify/workflows/runs/*/state.json`:

For each run directory:
1. Read `state.json`
2. Check if `workflow_id` matches the feature name
3. Check if `status` is `PAUSED` or `FAILED`
4. If both match, add to candidates list with the run directory's modification time

### 4. Resume or report

**If one or more candidates found:**

Pick the most recent candidate (by directory mtime). Run:

```bash
specify workflow resume <run_id>
```

After resume completes, check for `next-spec.md` in the feature directory (same
spec correction routing as `/mission` step 8). If `next-spec.md` exists and
spec corrections are under the cap, generate and run a new workflow.

**If no candidates found:**

```markdown
No paused or failed workflow run found for feature "<feature-name>".

Possible reasons:
- The last run completed successfully (use /mission to start a new one)
- No workflow has been run for this feature yet (use /mission to start one)
- The run may have been deleted

To list all runs: specify workflow list-runs
```

## Exit conditions

- Run resumed and completed → check `next-spec.md` (same as mission)
- Run resumed and still PAUSED → report: "Run <run_id> is paused at step <step_id>. Fix the issue and run /resume again."
- Run resumed and FAILED → report error, suggest fixing the issue and running /resume again
- No resumable run found → report and stop

## Examples

```
# Resume after a failed workflow run
/resume

# Resume after session restart
/resume
```
