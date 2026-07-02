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
2. Run `specify workflow run impl-converge-loop`
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
