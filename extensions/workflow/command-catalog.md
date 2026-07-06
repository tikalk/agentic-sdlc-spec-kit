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
phases therefore MUST be wrapped in an outer `if` step, with a gen-time literal
`condition: true` or `condition: false`.

Each optional phase that is emitted also presents a **`gate` step** to the user
so the operator can confirm or skip the phase at runtime. The gate's choice is
then tested by an inner `if` step (`condition: "{{ steps.<id>_confirm.output.choice == '<phase>' }}"`)
before the phase's `command` step runs.

A workflow must use commands from **one preset only**. Do not mix `spec.*`
optional-phase commands into `change.*` or `quick.*` workflows; the
`agentic-change` and `agentic-quick` presets do not provide `brainstorm`,
`clarify`, `analyze`, or `trace` commands.

## Execution model

`/workflow.mission` is a **planner** command. It assesses the prompt, generates
a workflow YAML under `.specify/workflow/tmp/`, and delegates execution to
`/workflow.run` as a subagent. `/workflow.run` is a **generic YAML interpreter**
— it reads the YAML, walks its `steps:` list, and dispatches each step to a
subagent (for `command` steps) or handles it internally (for `if`, `gate`,
`do-while`, `shell`, `prompt`, `switch`, `fan-out`, `fan-in` steps). This avoids
trapping a long-running pipeline inside a single tool invocation that could time
out.

`/workflow.run` manages `.mission-state.json` (completed steps, step results,
circuit breaker counter, iteration count) for resume. It returns a signal
(`converged`, `tasks_appended`, `spec_correction_needed`, `failed`) to
`/workflow.mission`, which handles spec correction routing, sign-off gates
(gated/hybrid modes), and audit trail persistence.

The generated YAML is also a durable artifact: a user can run it directly in a
terminal with `specify workflow run <yaml>`, which creates a normal engine run
that `/workflow.resume` and `/workflow.persist` can operate on.

### Supervision modes

The workflow extension supports three supervision modes (configured in
`workflow-config.yml`):

- **`gated`** (default): Human review gates after `specify`, after each
  `implement`, and a final sign-off before mission complete.
- **`autonomous`**: No gates during execution. Requires verifiable done-criteria
  (refuses "TBD" Success Criteria). Circuit breaker and converge independence
  hint are still active.
- **`hybrid`**: Spec review gate and final sign-off, but no per-iteration gates.

### Safety mechanisms (all modes)

- **Circuit breaker**: stops after N consecutive `tasks_appended` (default 3)
- **Converge independence hint**: converge subagent instructed to verify independently
- **Converge scope guard**: only grades against the current change/feature spec
- **Audit trail**: `iterations.md` (per-implementation log) and `mission-log.json` (final state)
- **Verifiable done-criteria**: specify commands refuse to leave Success Criteria as "TBD"

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

The `agentic-change` preset provides no optional-phase commands. The `change.*`
route emits only the core pipeline above.

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

Optional phases are first selected as candidates by the hands-off assessment
below; the candidate decision is recorded in `.mission-state.json.phases`. When
a phase is emitted into the workflow, an outer `if` step carries a gen-time
literal `condition:` and contains a `gate` step that asks the user whether to
run the phase, followed by an inner `if` step that executes the phase only if
the user approves.

| Phase | Applies to route(s) | Candidate `if.condition` = `true` when |
|-------|---------------------|----------------------------------------|
| `brainstorm` | `spec.*` | route is `spec.*` **and** the prompt is architectural/ambiguous. Signals: words like "design", "how should we", "approach", "compare", "tradeoff", or explicit mention of multiple viable solutions. |
| `clarify` | `spec.*` | the Mission Brief has vague success criteria (no measurable outcomes) or missing constraints. |
| `analyze` | `spec.*` | route is `spec.*`. This phase is effectively core for the spec route but implemented as optional for symmetry. |
| `trace` | `spec.*` | the Mission Brief mentions persistence, audit, traceability, compliance, or `--persist`/reuse intent. |

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
      - id: brainstorm_confirm
        type: gate
        message: "The prompt looks architectural or ambiguous. Run the brainstorm phase to explore approaches and tradeoffs?"
        options: ["brainstorm", "skip"]
      - id: brainstorm_run
        type: if
        condition: "{{ steps.brainstorm_confirm.output.choice == 'brainstorm' }}"
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
      - id: clarify_confirm
        type: gate
        message: "The Mission Brief has vague success criteria or missing constraints. Run the clarify phase?"
        options: ["clarify", "skip"]
      - id: clarify_run
        type: if
        condition: "{{ steps.clarify_confirm.output.choice == 'clarify' }}"
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
      - id: analyze_confirm
        type: gate
        message: "Run the analyze phase to evaluate the plan before implementation?"
        options: ["analyze", "skip"]
      - id: analyze_run
        type: if
        condition: "{{ steps.analyze_confirm.output.choice == 'analyze' }}"
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
      - id: trace_confirm
        type: gate
        message: "The Mission Brief mentions persistence, audit, or traceability. Run the trace phase?"
        options: ["trace", "skip"]
      - id: trace_run
        type: if
        condition: "{{ steps.trace_confirm.output.choice == 'trace' }}"
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
- The optional-phase **candidate** decision is recorded in `.mission-state.json`
  under the `phases` key so it is transparent and survives restarts.
- A workflow must use commands from a single preset. The `change.*` and
  `quick.*` routes do **not** include optional phases because their presets do
  not provide them.
