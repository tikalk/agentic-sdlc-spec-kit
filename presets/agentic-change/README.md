# Agentic Change Workflow

A lightweight change proposal workflow modeled on OpenSpec concepts. Create structured change proposals, implement them, verify completeness, and contribute lessons back to your team.

## Installation

This preset is pre-installed when you run `specify init`. It co-exists with the `agentic-sdlc` preset.

## Commands

| Command | Description |
|---------|-------------|
| `/change.specify` | Create a change proposal — mission brief → `changes/NNN-name/spec.md` (+ optional plan.md + tasks.md) |
| `/change.implement` | Execute tasks from a change proposal — load spec + tasks, implement with per-task hook dispatch |
| `/change.converge` | Assess change scope, append remaining work; if converged, run test gate, 4-pillar assessment, write verify.md evidence bundle, set `Status: Completed` |
| `/change.levelup` | Contribute lessons from a completed change to team-ai-directives (CDR-based) |

## Workflow

```
/change.specify "Fix login redirect bug"
  → changes/003-fix-login-redirect/
    ├── spec.md     — What and why
    ├── plan.md     — Technical approach (optional, only when complexity warrants)
    └── tasks.md    — Implementation steps

/change.implement
  → Executes tasks, per-task hooks dispatch

/change.converge
  → Checks acceptance criteria, runs 4-pillar assessment, sets Status: Completed

/change.levelup
  → Extracts reusable patterns and CDRs from the completed change
```

## Design Principles

- **No git branches** — Changes are working-directory-local proposals in `changes/` directory
- **Self-contained** — Each change folder has everything needed to understand and implement it
- **Optional plan** — plan.md only created when the change has cross-cutting complexity
- **Delta-driven** — spec.md describes what's ADDED, MODIFIED, or REMOVED
- **Completable** — verify sets `Status: Completed`, enabling levelup handoff
