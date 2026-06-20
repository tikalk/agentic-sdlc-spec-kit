# Agentic Quick Workflow

Session-based ad-hoc task execution — mission brief, implement, levelup, no file artifacts.

## Installation

This preset is pre-installed when you run `specify init`. It preserves the same `/quick.implement` and `/quick.levelup` commands previously provided by the `quick` extension.

## Commands

| Command | Description |
|---------|-------------|
| `/quick.implement` | Session-based ad-hoc task execution — mission brief, per-task hooks, no artifacts |
| `/quick.levelup` | Quick-contribute a directive to team-ai-directives (CDR-based) |

## Workflow

```
/quick.implement "Fix authentication bug"
  → Mission Brief → Context → Task Breakdown → Per-Task Hook Dispatch → Complete

/quick.levelup "Logging pattern for all microservices"
  → Parse → Structure CDR → Signal Gate → User Review → Publish → PR
```

## Design Principles

- **1 stop only** — Mission Brief confirmation is the only interactive stop
- **No file artifacts** — All interaction in conversation
- **Per-task hooks** — `before_task_execute` / `after_task_execute` dispatch
- **Session-only** — No spec.md, tasks.md, or other workflow files
