---
description: Full autonomous SDLC cycle — with args: spec→plan→tasks→loop.run; without args: resume loop.run on existing artifacts
---

## Goal

Full autonomous SDLC cycle: when called with a spec description, run spec, plan,
and tasks to generate artifacts, then run the implement↺converge loop until
convergence or max iterations. When called without args, resume iteration on
existing artifacts.

## Design philosophy

The human controls direction (args), the loop automates execution (implement↺converge).
Unlike a scheduled prompt that fires blindly, this loop has engine-native do-while
iteration, convergence-based exit (not arbitrary count), and automated triage
(spec-level vs task-level correction via next-spec.md routing).

## Arguments

- `spec_description` (optional): Description of what to build. When provided,
  regenerates spec/plan/tasks. When omitted, resumes `loop.run` on existing artifacts.

## Flow

1. Verify `SPECIFY_FEATURE_DIRECTORY` is set and exists. If not, read `.specify/feature.json`
   to discover the current feature directory.

2. **If args provided:**
   - Run `spec.specify` — pass the spec_description as args
   - Run `spec.plan`
   - Run `spec.tasks`

   **If no args:**
   - Verify `spec.md`, `plan.md`, and `tasks.md` all exist in the feature directory.
   - If any is missing → **hard error**: "spec_description argument required —
     no existing spec/plan/tasks found. Provide a description to generate artifacts."

3. Run `loop.run` (delegates to `impl-converge-loop` workflow)

4. **Loop routing** (max 2 spec-level corrections): If the loop reports `tasks_appended`,
   check for `next-spec.md` in the feature directory:
   - If `next-spec.md` exists AND spec corrections < 2 → spec-level correction: re-run
     `spec.specify` (feeding next-spec.md as input) → `spec.plan` → `spec.tasks` → `loop.run`.
     Increment spec correction counter.
   - If `next-spec.md` exists AND spec corrections ≥ 2 → **stop**: "Spec repeatedly fails
     EDD evaluation. Human review of spec required."
   - If `next-spec.md` does not exist → task-level correction only: re-run `loop.run`
     (implement will pick up the EDD-appended tasks)

5. Report: loop iterations, convergence result, whether spec-level corrections were applied

## Exit conditions

- `converged` → loop stops, feature is fully verified
- `tasks_appended` + no `next-spec.md` → loop continues (task-level fix)
- `tasks_appended` + `next-spec.md` → spec correction route (max 2)
- `max_iterations: 5` → inner loop hard stop regardless of condition
- `max spec corrections: 2` → outer routing hard stop, human review required

## Examples

```
# First time — create everything fresh
loop.goal "add dark mode toggle"

# Loop went wrong — resume iteration on existing artifacts
loop.goal

# New requirements — regenerate spec with updated description
loop.goal "add dark mode + system theme detection"
```
