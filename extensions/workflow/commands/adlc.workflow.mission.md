---
description: "Assess prompt, generate a workflow YAML, and run it. No args collects a Mission Brief first. Resume with /workflow.resume, persist with /workflow.persist."
---

## Goal

Generate and run a mission-driven workflow that takes a feature from description
to converged implementation. The command assesses the prompt, decides which
optional preset phases are appropriate (brainstorm, clarify, analyze, trace),
generates a workflow YAML with the appropriate command pipeline, and runs it
through the engine. After each workflow run, checks for EDD's `next-spec.md` to
determine if spec-level correction is needed.

The full command catalog, route templates, and phase-inclusion criteria live in
`extensions/workflow/command-catalog.md` in the source repo.

## Arguments

- `spec_description` (optional): Description of what to build. When provided,
  generates and runs the workflow immediately. When omitted, derives a
  best-effort description from the feature directory name.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Flow

### 1. Discover feature directory

Read `.specify/feature.json` to get the current feature directory name (e.g.,
`003-version-info-modal`). This becomes the `workflow.id` in the generated YAML
and is used for run matching by `/workflow.resume`.

If `SPECIFY_FEATURE_DIRECTORY` env var is set, use it instead.

**Resume check.** After discovering the feature directory, check if
`.specify/extensions/workflow/.mission-state.json` already exists and has a
non-empty `completed_steps` array. If so, this is a **resume** — skip Steps 2-6
and jump directly to Step 7 (Run the workflow). The existing YAML file at
`.specify/workflow/tmp/specify-mission-<feature-name>.yml` and the existing
`.mission-state.json` (with `completed_steps` and `step_results`) are reused.
Step 7 will skip steps whose IDs are in `completed_steps` and resume from the
first incomplete step.

### 2. Mission Brief Extraction

### Automatic Extraction

If `$ARGUMENTS` is non-empty, treat the entire value as `spec_description` — no
confirmation prompt, no Mission Brief collection. Proceed directly to Step 3.

If `$ARGUMENTS` is empty or minimal, derive a best-effort `spec_description` from
the feature directory name discovered in Step 1. Do **not** ask the user for
input — proceed directly to Step 3 with the derived description.

### Behavior

- Always populate `spec_description` from what is available.
- No confirmation prompt. Proceed directly to Step 3 (Read configuration).
- Do **not** use a structured question tool or display a Mission Brief form.

### 3. Read configuration

Read `.specify/extensions/workflow/workflow-config.yml` if it exists:

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

If the config file is missing, use defaults (`max_iterations: 5`,
`max_spec_corrections: 2`, `supervision: "gated"`, `circuit_breaker: 3`) and
omit `model:` fields from the generated YAML.

**Supervision modes**:
- `gated` (default): Human gates after specify, after each implement, and a
  final sign-off before mission complete. The YAML includes `gate` steps.
- `autonomous`: No human gates during execution. The loop runs until converged
  or `max_iterations`. Requires verifiable done-criteria in the spec (refuses
  "TBD"). State is persisted as audit trail.
- `hybrid`: No gates during loop iterations, but a final sign-off is required
  before mission complete.

**Autonomous mode validation**: If `supervision` is `autonomous`, after the
`specify` step completes, verify that the spec's Success Criteria are not
"TBD" or empty. If they are, **STOP** with: "Autonomous mode requires checkable
done-criteria. The spec has placeholder Success Criteria. Run in `gated` mode,
or provide a more descriptive prompt."

### 4. Assess prompt, route, and optional phases

#### 4a. Route classification

Classify the spec description into one of three routes using LLM judgment:

| Route | Pipeline | When |
|-------|----------|------|
| `spec.*` | specify → plan → tasks → implement↺converge | New feature, greenfield, "add/create/build" |
| `change.*` | specify → implement↺converge | Modification, brownfield, "fix/update/refactor" |
| `quick.*` | implement only (no loop) | Small task, trivial, "just/quick/simple" |

The route determines which core commands appear in the generated workflow YAML.

#### 4b. Optional phase selection

After the route is chosen, assess the prompt against the criteria in
`command-catalog.md` and decide which optional phases are *candidates*. The
candidate decision is hands-off and recorded in `.mission-state.json` for
transparency. When a candidate phase is emitted into the workflow, it is wrapped
in an outer **`if` step** whose literal `condition:` is set at generation time,
and inside that `if` step a **`gate` step** asks the user whether to run the
phase. The phase only executes if the user approves.

| Phase | Applies to route(s) | Candidate when |
|-------|---------------------|----------------|
| `brainstorm` | `spec.*` | prompt is architectural/ambiguous ("design", "approach", "compare", "how should we", multiple viable solutions) |
| `clarify` | `spec.*` | Mission Brief success criteria are vague or constraints are missing |
| `analyze` | `spec.*` | route is `spec.*` (symmetric with the other optional phases) |
| `trace` | `spec.*` | Mission Brief mentions persistence, audit, traceability, compliance, or `--persist`/reuse intent |

> **Preset-native commands only**: each route must use commands from a single
> preset. The `change.*` route uses only `change.specify`, `change.implement`, and
> `change.converge`; the `quick.*` route uses only `quick.implement`. Do **not**
> mix `spec.*` optional phases into `change.*` or `quick.*` workflows.

> **Engine constraint**: the workflow engine has no step-level `condition:` field;
> a `condition:` key on a normal `command` step is silently ignored. Optional
> phases MUST use the `if` step primitive (`type: if`).

> **Non-interactive execution contract**: workflow steps run unattended, so each
> command must resolve its own target. Both `spec.*` and `change.*` rely on
> `.specify/feature.json` as the shared current-work pointer, which the
> corresponding `*.specify` step writes before any downstream step runs. The
> `*.implement`/`*.converge` commands run `{SCRIPT}` to auto-detect `FEATURE_DIR`
> from that pointer. `change.implement` and `change.converge` therefore keep
> `args: ""` in the generated YAML and still work. For `quick.*`, pass the full
> Mission Brief as `args` so `quick.implement` treats it as a complete brief and
> proceeds without further prompting.

### 5. Initialize mission state

Create or update `.specify/extensions/workflow/.mission-state.json`. On a fresh
mission (no existing file or empty `completed_steps`), create the full state. On
a spec-correction re-run (file exists, `completed_steps` non-empty, but
`spec_corrections` was incremented), preserve `completed_steps` and
`step_results` from the prior run — they will be reset as needed by the
spec-correction routing in Step 8.

```json
{
  "feature": "<feature-name>",
  "yaml_path": ".specify/workflow/tmp/specify-mission-<feature-name>.yml",
  "route": "<spec|change|quick>",
  "spec_description": "<original prompt>",
  "supervision": "<gated|autonomous|hybrid>",
  "circuit_breaker": <3>,
  "phases": {
    "brainstorm": <true|false>,
    "clarify": <true|false>,
    "analyze": <true|false>,
    "trace": <true|false>
  },
  "spec_corrections": 0,
  "max_spec_corrections": <from config, default 2>,
  "max_iterations": <from config, default 5>,
  "started_at": "<ISO timestamp>",
  "last_run_id": null,
  "completed_steps": [],
  "step_results": {},
  "consecutive_tasks_appended": 0
}
```

This file persists across runs and prevents infinite spec-correction loops. The
`phases` object records the hands-off optional-phase **candidate** decision so
the same flags are reused if a spec-correction re-run is triggered. The final
decision to run a phase is made by the user at the runtime `gate` step. The
`completed_steps` array and `step_results` map are populated during Step 7
execution and enable resume after interruptions.

### 6. Generate workflow YAML

Write a temporary workflow YAML file to
`.specify/workflow/tmp/specify-mission-<feature-name>.yml`. Create the parent
directory with `mkdir -p .specify/workflow/tmp` first.

The YAML uses the feature name as `workflow.id` so `/workflow.resume` can match runs.
Write the file under `.specify/workflow/tmp/` (create the directory with
`mkdir -p .specify/workflow/tmp`). Do not write to `/tmp` or any other path
outside the workspace.

Optional phases are first selected by the hands-off assessment (recorded in
`.mission-state.json.phases`), then each selected phase is wrapped in an **`if`
step** that contains a **`gate` step** asking the user whether to run it, followed
by an inner **`if` step** that executes the phase only when the user approves.
The outer `if` step's `condition:` is a gen-time literal (`true` or `false`)
copied from `.mission-state.json.phases`.

#### Supervision-mode gate injection

The `supervision` mode from `.mission-state.json` controls whether human-review
`gate` steps are injected into the pipeline:

- **`gated`** (default): Insert a `gate` step after `specify` (before the loop)
  and after each `implement` step (before `converge`). The final sign-off gate
  is handled by Step 8.
- **`autonomous`**: No gates during execution. The loop runs freely.
- **`hybrid`**: No gates during loop iterations, but the `specify` review gate
  IS included. The final sign-off gate is handled by Step 8.

When emitting gate steps, wrap the downstream steps in an `if` step that checks
the gate's choice:

```yaml
- id: spec_gate
  type: gate
  message: "Spec created. Review spec.md and tasks.md before implementation?"
  options: ["proceed", "revise", "abort"]
- id: spec_branch
  type: if
  condition: "{{ steps.spec_gate.output.choice == 'proceed' }}"
  then:
    # ... downstream steps (loop, etc.) go here
```

If the user chooses `abort`, the mission stops. If `revise`, re-run the
`specify` step. If `proceed`, continue to the next step.

For the implement→converge gate inside the do-while loop (gated mode only):

```yaml
steps:
  - id: implement
    command: change.implement
    ...
  - id: impl_gate
    type: gate
    message: "Implementation complete. Run convergence assessment?"
    options: ["proceed", "revise", "abort"]
  - id: impl_branch
    type: if
    condition: "{{ steps.impl_gate.output.choice == 'proceed' }}"
    then:
      - id: converge
        command: change.converge
        ...
```

The YAML templates below show the **autonomous** form (no gates). When
`supervision` is `gated` or `hybrid`, inject the gates as shown above.

#### spec.* route

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
            model: "<strong>"
            input:
              args: "{{ inputs.spec }}"
  - id: specify
    command: spec.specify
    integration: "{{ inputs.integration }}"
    model: "<strong>"
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
    model: "<strong>"
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
        model: "<strong>"
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

#### change.* route

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
    model: "<strong>"
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
        model: "<strong>"
        input:
          args: ""
      - id: converge
        command: change.converge
        integration: "{{ inputs.integration }}"
        input:
          args: ""
```

#### quick.* route

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
    model: "<strong>"
    input:
      args: "{{ inputs.spec }}"
```

#### Model field handling

- If config has `models.strong`: add `model: "<strong>"` to `spec.specify`,
  `spec.plan`, `spec.implement`, `spec.brainstorm`, and `change.specify`/`change.implement` steps
- If config has `models.fast`: add `model: "<fast>"` to `spec.tasks`,
  `spec.converge`, `spec.clarify`, `spec.analyze`, and `spec.trace` steps
  (or set as workflow-level `model:` default)
- If no config: omit all `model:` fields — engine uses integration default

### 7. Run the workflow

Delegate execution to `/workflow.run` as a subagent. Pass the YAML path generated
in Step 6 as the argument.

1. Emit:

   ```markdown
   ## Mission: delegating to /workflow.run

   **YAML**: `<yaml-path>`
   ```

2. Delegate to a subagent:

   ```markdown
   You are being invoked by the `/workflow.mission` command.

   Execute `/workflow.run` with the following argument:

   <yaml-path>

   1. Read the command file for `/workflow.run` in your integration's commands
      directory.
   2. Execute the command's instructions: read the YAML, walk its steps, manage
      `.mission-state.json`, and return one of: `converged`,
      `tasks_appended`, `spec_correction_needed`, or `failed`.
   3. Return the signal and a concise summary to the orchestrator.
   ```

3. Wait for the subagent to finish.
4. Based on the return signal, proceed to Step 8.

#### Alternative path: user-runnable YAML (terminal execution)

If the user prefers to run the workflow outside this agent session, print:

```bash
specify workflow run .specify/workflow/tmp/specify-mission-<feature-name>.yml --input spec="<spec_description>"
```

When run in a real terminal, the engine creates a normal run under
`.specify/workflows/runs/<run_id>/`, writes a `PAUSED`/`FAILED` state on
interruption, and prints a `run_id`. Capture that `run_id` and update
`.mission-state.json` with `last_run_id`.

### 8. Spec correction routing and completion (based on /workflow.run return signal)

After `/workflow.run` returns, check its signal:

**If signal is `spec_correction_needed`:**

1. Read `.mission-state.json`.
2. If `spec_corrections >= max_spec_corrections`:
   - **STOP**: "Spec repeatedly fails EDD evaluation ({{ spec_corrections }}/{{ max_spec_corrections }}). Human review of spec required."
   - Do NOT delete `next-spec.md` — the user needs it for manual review.
   - Keep `.mission-state.json` for inspection.
   - Report and stop.
3. Otherwise:
   - Delete `next-spec.md` (consume it — `spec.specify` will read the revised content).
   - Increment `spec_corrections` in `.mission-state.json`.
   - Clear `completed_steps` and `step_results` in `.mission-state.json` (fresh pipeline run).
   - Regenerate the workflow YAML using the **same route and same `phases` candidate flags**.
   - Re-delegate to `/workflow.run` with the regenerated YAML path.
   - Repeat step 8.

**If signal is `converged` or `tasks_appended`:**

The pipeline finished. Now check `supervision` mode:

- If `supervision` is `gated` or `hybrid`: **require human sign-off**.
  1. Display the audit trail from `<FEATURE_DIR>/iterations.md` (if it exists).
  2. Display: "Convergence passed. Review `verify.md` and approve completion?"
  3. Wait for user response:
     - **approve** → persist audit trail and complete (below)
     - **reject** → keep `.mission-state.json`, report: "Mission paused for
       review. Run `/workflow.resume` to continue after addressing the issues."

- If `supervision` is `autonomous`: **skip sign-off**, proceed directly to
  audit trail persistence and completion.

**Audit trail persistence** (all modes):

Instead of deleting `.mission-state.json`, move it to the feature directory as
an audit trail:

```bash
mv .specify/extensions/workflow/.mission-state.json <FEATURE_DIR>/mission-log.json
```

This gives reviewers a durable record of what the loop did — which steps ran,
how many iterations, what each step produced. "The agent forgets, the repo
doesn't."

Then report:

```markdown
## Mission Complete

- Feature: <feature-name>
- Route: <spec|change|quick>
- Supervision: <gated|autonomous|hybrid>
- Phases candidate flags: brainstorm=<bool>, clarify=<bool>, analyze=<bool>, trace=<bool>
- Signal: <converged|tasks_appended>
- Spec corrections: <spec_corrections>/<max_spec_corrections>
- Audit trail: <FEATURE_DIR>/mission-log.json
- Final run ID: <last_run_id> (only set when the terminal path was used)

To resume an interrupted workflow, run `/workflow.resume`.
To persist a workflow run for reuse, run `/workflow.persist`.
```

**If signal is `failed`:**

Report the error and stop. Keep `.mission-state.json` for inspection. The user
can re-run `/workflow.mission` or `/workflow.resume` to continue.

## Exit conditions

- `/workflow.run` returns `converged` + sign-off approved (or autonomous) → **mission complete**
- `/workflow.run` returns `tasks_appended` + sign-off approved (or autonomous) → **mission complete** (inner loop exhausted)
- `/workflow.run` returns `spec_correction_needed` + `spec_corrections >= max_spec_corrections` → **stop** (human review)
- Sign-off rejected (gated/hybrid) → **pause** (keep state, user reviews)
- `/workflow.run` returns `failed` → **stop** (report error; re-run `/workflow.mission` or `/workflow.resume`)
- Circuit breaker tripped (3 consecutive `tasks_appended`) → **stop** (human review)

## Safety mechanisms

- **Supervision modes**: `gated` (default) requires human gates; `autonomous` runs freely but requires verifiable done-criteria; `hybrid` gates only at spec review and final sign-off
- **Inner loop cap**: `max_iterations: 5` (enforced by `/workflow.run` during `do-while` evaluation)
- **Circuit breaker**: stops after N consecutive `tasks_appended` (default 3) — prevents infinite spinning
- **Outer loop cap**: `max_spec_corrections: 2` (state-file-enforced, in `.mission-state.json`)
- **Autonomous mode validation**: refuses to start if spec has "TBD" Success Criteria
- **Converge scope guard**: converge only grades against the change spec, not pre-existing issues
- **Converge independence hint**: converge subagent is instructed to verify independently, not trust the implementer's context
- **Audit trail**: `.mission-state.json` is moved to `<FEATURE_DIR>/mission-log.json` on completion — not deleted
- **Separation of concerns**: `/workflow.mission` plans and handles spec correction; `/workflow.run` executes the YAML pipeline
- **State persistence**: `.mission-state.json` survives context compaction and session restarts

## Examples

```
# Start a new mission with a description
/workflow.mission "add dark mode toggle to dashboard"

# Start without args — derive description from feature directory
/workflow.mission

# Run a workflow YAML directly (bypass mission planning)
/workflow.run .specify/workflow/tmp/specify-mission-005.yml

# Resume an interrupted workflow
/workflow.resume

# Persist a workflow run for reuse
/workflow.persist
```
