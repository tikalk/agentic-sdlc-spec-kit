---
description: Full autonomous SDLC cycle — ensure spec/plan/tasks exist, then run the implement↺converge loop
---

## Goal

Full autonomous SDLC cycle: ensure spec, plan, and tasks exist, then run the
implement↺converge loop until convergence or max iterations.

## Flow

1. Verify `SPECIFY_FEATURE_DIRECTORY` is set and exists. If not, read `.specify/feature.json`
   to discover the current feature directory.
2. If no `spec.md` → run `specify spec.specify`
3. If no `plan.md` → run `specify spec.plan`
4. If no `tasks.md` → run `specify spec.tasks`
5. Run `specify adlc.loop.run` (delegates to `impl-converge-loop` workflow)
6. Report: what was done fresh (spec/plan/tasks created or already existed), loop iterations,
   convergence result
