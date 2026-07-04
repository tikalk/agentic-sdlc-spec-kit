# Workflow Command Catalog

Reference for `adlc.workflow.mission` command generation. Lists every command in
the three agentic presets, which phases of a mission workflow they belong to,
and the hands-off criteria that decide whether optional phases are included.

This file is a plain asset of the `workflow` extension. It is copied verbatim on
install (via `shutil.copytree`) and is **not** registered as a command, so it
must live at the extension root, not under `commands/`.

## Engine constraint used by this catalog

The workflow engine has **no step-level `condition:` field**. A `condition:`
key on a normal `command` step is silently ignored. The only supported
conditional primitive is the **`if` step** (`type: if`), which evaluates
`condition:` and executes the inline `then:` step array when true. Optional
phases therefore MUST be wrapped in an `if` step, with a gen-time literal
`condition: true` or `condition: false`.

## Preset commands

### `presets/agentic-sdlc` (greenfield / spec route)

| Command | Phase | Mission-eligible | Include when |
|---------|-------|------------------|--------------|
| `spec.brainstorm` | optional | yes | greenfield + architectural/ambiguous prompt |
| `spec.constitution` | out-of-band | no | human-run; excluded from mission |
| `spec.specify` | core | yes | always for `spec.*` route |
| `spec.clarify` | optional | yes | Mission Brief success criteria vague OR constraints missing |
| `spec.plan` | core | yes | always for `spec.*` route |
| `spec.tasks` | core | yes | always for `spec.*` route |
| `spec.analyze` | optional | yes | route is `spec.*` (both `plan` and `tasks` present) |
| `spec.checklist` | out-of-band | no | human-run quality checklist; excluded from mission |
| `spec.implement` | core | yes | always for `spec.*` route (inside do-while) |
| `spec.converge` | core | yes | always for `spec.*` route (inside do-while) |
| `spec.trace` | optional | yes | persistence/audit/traceability constraint stated |

### `presets/agentic-change` (brownfield / change route)

| Command | Phase | Mission-eligible | Include when |
|---------|-------|------------------|--------------|
| `change.specify` | core | yes | always for `change.*` route |
| `change.implement` | core | yes | always for `change.*` route (inside do-while) |
| `change.converge` | core | yes | always for `change.*` route (inside do-while) |
| `change.levelup` | extension | no | contributes to `team-ai-directives`; excluded from mission |

### `presets/agentic-quick` (trivial / quick route)

| Command | Phase | Mission-eligible | Include when |
|---------|-------|------------------|--------------|
| `quick.implement` | core | yes | always for `quick.*` route |
| `quick.levelup` | extension | no | contributes to `team-ai-directives`; excluded from mission |

### Stale / install-only commands

| Command | Status |
|---------|--------|
| `spec.verify` | Exists only as a stale install artifact in `.opencode/commands/spec.verify.md`. Not present in any preset source. **Never** include in mission workflows. |

## Phase definitions

### Core phases

Core phases are always emitted for their route. Removing them would break the
route semantics.

- `spec.*`: `specify` → `plan` → `tasks` → `implement↺converge`
- `change.*`: `change.specify` → `change.implement↺change.converge`
- `quick.*`: `quick.implement`

### Optional phases

Optional phases are gated by an `if` step whose `condition:` literal is written
at generation time based on the hands-off criteria below.

| Phase | `if.condition` = `true` when |
|-------|------------------------------|
| `brainstorm` | route is `spec.*` **and** the prompt is architectural/ambiguous. Signals: words like "design", "how should we", "approach", "compare", "tradeoff", or explicit mention of multiple viable solutions. |
| `clarify` | the Mission Brief has vague success criteria (no measurable outcomes) or missing constraints. |
| `analyze` | route is `spec.*`. This phase is effectively core for the spec route but implemented as optional for symmetry. |
| `trace` | the Mission Brief mentions persistence, audit, traceability, compliance, or `--persist`/reuse intent. |

## Route YAML templates

### `spec.*` route

```yaml
schema_version: "1.0"
workflow:
  id: "<feature-name>"
  name: "Mission: <short description>"
  version: "1.0.0"
inputs:
  spec:
    type: string
    required: true
  integration:
    type: string
    default: "auto"
steps:
  - id: brainstorm_gate
    type: if
    condition: <true|false>
    then:
      - id: brainstorm
        command: spec.brainstorm
        integration: "{{ inputs.integration }}"
        input:
          args: "{{ inputs.spec }}"
  - id: specify
    command: spec.specify
    integration: "{{ inputs.integration }}"
    input:
      args: "{{ inputs.spec }}"
  - id: clarify_gate
    type: if
    condition: <true|false>
    then:
      - id: clarify
        command: spec.clarify
        integration: "{{ inputs.integration }}"
        input:
          args: ""
  - id: plan
    command: spec.plan
    integration: "{{ inputs.integration }}"
    input:
      args: ""
  - id: tasks
    command: spec.tasks
    integration: "{{ inputs.integration }}"
    input:
      args: ""
  - id: analyze_gate
    type: if
    condition: <true|false>
    then:
      - id: analyze
        command: spec.analyze
        integration: "{{ inputs.integration }}"
        input:
          args: ""
  - id: loop
    type: do-while
    condition: "{{ steps.converge.output.stdout | contains('tasks_appended') }}"
    max_iterations: <max_iterations>
    steps:
      - id: implement
        command: spec.implement
        integration: "{{ inputs.integration }}"
        input:
          args: ""
      - id: converge
        command: spec.converge
        integration: "{{ inputs.integration }}"
        input:
          args: ""
  - id: trace_gate
    type: if
    condition: <true|false>
    then:
      - id: trace
        command: spec.trace
        integration: "{{ inputs.integration }}"
        input:
          args: ""
```

### `change.*` route

```yaml
schema_version: "1.0"
workflow:
  id: "<feature-name>"
  name: "Mission: <short description>"
  version: "1.0.0"
inputs:
  spec:
    type: string
    required: true
  integration:
    type: string
    default: "auto"
steps:
  - id: clarify_gate
    type: if
    condition: <true|false>
    then:
      - id: clarify
        command: spec.clarify
        integration: "{{ inputs.integration }}"
        input:
          args: ""
  - id: specify
    command: change.specify
    integration: "{{ inputs.integration }}"
    input:
      args: "{{ inputs.spec }}"
  - id: loop
    type: do-while
    condition: "{{ steps.converge.output.stdout | contains('tasks_appended') }}"
    max_iterations: <max_iterations>
    steps:
      - id: implement
        command: change.implement
        integration: "{{ inputs.integration }}"
        input:
          args: ""
      - id: converge
        command: change.converge
        integration: "{{ inputs.integration }}"
        input:
          args: ""
  - id: trace_gate
    type: if
    condition: <true|false>
    then:
      - id: trace
        command: spec.trace
        integration: "{{ inputs.integration }}"
        input:
          args: ""
```

### `quick.*` route

```yaml
schema_version: "1.0"
workflow:
  id: "<feature-name>"
  name: "Mission: <short description>"
  version: "1.0.0"
inputs:
  spec:
    type: string
    required: true
  integration:
    type: string
    default: "auto"
steps:
  - id: implement
    command: quick.implement
    integration: "{{ inputs.integration }}"
    input:
      args: "{{ inputs.spec }}"
```

## Notes

- The `model:` field handling described in `adlc.workflow.mission` still applies
  to any step that supports it (core and optional alike).
- The optional-phase decision is recorded in `.mission-state.json` under the
  `phases` key so it is transparent and survives restarts.
