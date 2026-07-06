# Workflow Factory — Mission-Driven SDLC Automation

**Version:** 2.6.1

Generate and run mission-driven workflows that take a feature from description
to converged implementation. The workflow extension provides four commands that
work together: plan, execute, resume, and persist.

## Commands

| Command | Role | Description |
|---|---|---|
| `/workflow.mission` | Planner | Assess prompt, classify route (spec/change/quick), generate workflow YAML, delegate to `/workflow.run`, handle spec correction routing and sign-off |
| `/workflow.run` | Executor | Read a workflow YAML and walk its `steps:` list, dispatching each step to a subagent. Generic interpreter for all step types (command, if, gate, do-while, shell, prompt, switch, fan-out, fan-in) |
| `/workflow.resume` | Resume | Resume an interrupted workflow — delegates to `/workflow.mission` for agent-orchestrated missions, or `specify workflow resume` for engine runs |
| `/workflow.persist` | Persist | Make a workflow run permanent and register it in the workflow catalog |

## Architecture

```
/workflow.mission (plan: assess, classify, generate YAML, spec correction)
  └→ /workflow.run <yaml-path> (execute: walk steps, manage state)
       └→ /change.specify (subagent: do work)
       └→ /change.implement (subagent: do work)
       └→ /change.converge (subagent: verify)

/workflow.resume → /workflow.mission (resume from .mission-state.json)
```

## Supervision Modes

Configured in `.specify/extensions/workflow/workflow-config.yml`:

| Mode | Gates | Use when |
|---|---|---|
| `gated` (default) | After specify, after each implement, final sign-off | User wants to review at checkpoints |
| `autonomous` | None during execution | User walks away — requires verifiable done-criteria |
| `hybrid` | Spec review + final sign-off only | User wants to let the loop run but review before done |

## Safety Mechanisms

All modes include these guardrails (aligned with Loop Engineering and Harness
Engineering principles):

- **Circuit breaker**: stops after 3 consecutive `tasks_appended` (configurable)
- **Converge independence hint**: checker instructed to verify independently
- **Converge scope guard**: only grades against the current spec, not pre-existing issues
- **Audit trail**: `iterations.md` (per-implementation log) + `mission-log.json` (final state)
- **Verifiable done-criteria**: specify commands refuse "TBD" Success Criteria
- **State persistence**: `.mission-state.json` survives context compaction and session restarts

## Configuration

Copy `config-template.yml` to `.specify/extensions/workflow/workflow-config.yml`:

```yaml
workflow:
  max_iterations: 5
  max_spec_corrections: 2
  supervision: "gated"          # "gated" | "autonomous" | "hybrid"
  circuit_breaker: 3             # max consecutive tasks_appended before stopping
  models:
    strong: "glm-5.2"
    fast: "deepseek-v4-flash-free"
```

## Route Classification

| Route | Pipeline | When |
|---|---|---|
| `spec.*` | specify → plan → tasks → implement↺converge | New feature, greenfield |
| `change.*` | specify → implement↺converge | Modification, brownfield |
| `quick.*` | implement only (no loop) | Small task, trivial |

## Workflow YAML

The generated YAML is the single source of truth — both the agent interpreter
(`/workflow.run`) and the workflow engine (`specify workflow run`) can execute
it. See `command-catalog.md` for route templates and phase-inclusion criteria.

## Installation

```bash
specify extension add workflow
```

Or from source:

```bash
specify extension add --dev ./extensions/workflow
```

## Requirements

- Spec Kit CLI >= 0.8.5
- Any Spec Kit-supported agent (opencode, Claude Code, Copilot, Cursor, Gemini, etc.)

## License

MIT
