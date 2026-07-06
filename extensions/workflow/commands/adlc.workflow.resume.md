---
description: "Find paused/failed run for current feature and resume it."
---

## Goal

Find the most recent paused or failed workflow run for the current feature and
resume it from where it left off. This command handles two resume paths:

1. **Agent-orchestrated mission resume**: if `.mission-state.json` exists with
   non-empty `completed_steps`, the mission was run via subagent delegation and
   was interrupted. Delegate to `/workflow.mission` which will auto-detect the
   state (Step 1 resume check) and resume from the first incomplete step —
   including Step 8 sign-off and audit trail persistence.
2. **Engine run resume**: if no mission state exists, scan for PAUSED/FAILED
   engine runs and resume via `specify workflow resume`.

## Flow

### 1. Check for completed mission (mission-log.json)

Read `.specify/feature.json` to get the current feature directory. Check if
`<FEATURE_DIR>/mission-log.json` exists. If it does, the mission already
completed — report:

```markdown
Mission already completed for feature "<feature-name>".
Audit trail: <FEATURE_DIR>/mission-log.json
```

Stop.

### 2. Check for agent-orchestrated mission state

Read `.specify/extensions/workflow/.mission-state.json`. If it exists and has
a non-empty `completed_steps` array, this is an interrupted agent-orchestrated
workflow. Delegate to `/workflow.mission` as a subagent:

```markdown
You are being invoked by the `/workflow.resume` command.

Execute `/workflow.mission` with no arguments. The mission will detect the
existing `.mission-state.json` in Step 1 (resume check) and skip directly to
Step 7 (delegation to /workflow.run), which resumes from the first incomplete
step. Step 8 (sign-off gate + audit trail persistence) will run when the
pipeline completes.
```

When `/workflow.mission` returns, report its outcome to the user.

### 3. Discover feature directory (engine run path)

If no mission state was found, read `.specify/feature.json` to get the current
feature name (e.g., `003-version-info-modal`).

### 4. Scan engine runs for matching workflow

Scan `.specify/workflows/runs/*/state.json`:

For each run directory:
1. Read `state.json`
2. Check if `workflow_id` matches the feature name
3. Check if `status` is `PAUSED` or `FAILED`
4. If both match, add to candidates list with the run directory's modification time

### 5. Resume or report

**If one or more candidates found:**

Pick the most recent candidate (by directory mtime). Run:

```bash
specify workflow resume <run_id>
```

After resume completes, check for `next-spec.md` in the feature directory (same
spec correction routing as `/workflow.mission` step 8). If `next-spec.md` exists and
spec corrections are under the cap, generate and run a new workflow.

**If no candidates found:**

```markdown
No paused or failed workflow run found for feature "<feature-name>".

Possible reasons:
- The last run completed successfully (use /workflow.mission to start a new one)
- No workflow has been run for this feature yet (use /workflow.mission to start one)
- The run may have been deleted

To list all runs: specify workflow list-runs
```

## Exit conditions

- `mission-log.json` found → report "already completed", stop
- Agent-orchestrated mission state found → delegate to `/workflow.mission` (gets Step 8 sign-off + audit trail)
- Engine run resumed and completed → check `next-spec.md` (same as mission)
- Engine run resumed and still PAUSED → report: "Run <run_id> is paused at step <step_id>. Fix the issue and run /workflow.resume again."
- Engine run resumed and FAILED → report error, suggest fixing the issue and running /workflow.resume again
- No resumable run found → report and stop

## Examples

```
# Resume after a failed workflow run
/workflow.resume

# Resume after session restart
/workflow.resume
```
