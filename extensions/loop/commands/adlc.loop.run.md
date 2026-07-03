---
description: Run the implement↺converge loop via the impl-converge-loop engine workflow
---

## Goal

Run one or more implement↺converge iterations via the `impl-converge-loop` engine workflow.

The workflow uses a native `do-while` step: always runs `implement` then `converge`,
re-evaluates the condition after each iteration.

## Flow

1. Verify `SPECIFY_FEATURE_DIRECTORY` is set and exists. If not, read `.specify/feature.json`
   to discover the current feature directory.
2. Run `specify workflow run impl-converge-loop`. If the CLI workflow fails
   (e.g., command resolution error), fall back to manual iteration:
   - Execute `__SPECKIT_COMMAND_IMPLEMENT__`
   - Execute `__SPECKIT_COMMAND_CONVERGE__`
   - If converge outputs `tasks_appended`, repeat (max 5 iterations)
   - If converge outputs `converged`, stop
3. Report: iterations completed, final outcome (`converged` or `tasks_appended` after max iterations)

## Condition

The do-while re-iterates while converge reports `tasks_appended` as its first output line.
When converge reports `converged`, the loop stops.

## Safety cap

`max_iterations: 5` — workflow stops regardless of condition after 5 passes.

## EDD integration

If the EDD extension is installed, its `after_converge` hook fires `edd.verify` after every
converge step — deep evaluation against the Mission Brief. If EDD finds issues, converge
overrides its outcome to `tasks_appended`, causing the loop to continue. This is
belt-and-suspenders: converge checks spec/plan/tasks gaps + test gate + 4-pillar quality,
while EDD adds deterministic checks + AI-driven evaluation.

## Loop routing

When EDD reports `tasks_appended`, the caller must determine the correct next step by
checking for `next-spec.md` in the feature directory:

### Spec-level correction (next-spec.md exists)

EDD found spec-level issues (oracle adequacy, ambiguous requirements, missing success
criteria). These cannot be fixed by implementing tasks — the spec itself needs correction.

Route:
1. `__SPECKIT_COMMAND_SPECIFY__` — feed `next-spec.md` as input to revise the spec
2. `__SPECKIT_COMMAND_PLAN__` — regenerate the plan against the revised spec
3. `__SPECKIT_COMMAND_TASKS__` — regenerate tasks from the revised plan
4. `__SPECKIT_COMMAND_IMPLEMENT__` — execute the revised tasks
5. `__SPECKIT_COMMAND_CONVERGE__` — re-assess (triggers EDD via after_converge hook)

### Task-level correction (next-spec.md does not exist)

EDD found implementation-level issues (test coverage gaps, unvalidated constraints,
lint failures). These are appended as tasks to `tasks.md` and can be fixed by implement.

Route:
1. `__SPECKIT_COMMAND_IMPLEMENT__` — execute the EDD-appended tasks
2. `__SPECKIT_COMMAND_CONVERGE__` — re-assess (triggers EDD via after_converge hook)

### Converged (no tasks_appended)

Both converge and EDD passed. The feature is fully verified. `verify.md` contains the
unified evidence bundle with all sections filled in by converge and EDD.
