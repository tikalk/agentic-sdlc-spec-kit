---
description: Assess prompt → generate workflow YAML → run. No args: collect Mission Brief first.
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
  generates and runs the workflow immediately. When omitted, collects a Mission
  Brief from the user first.

## Flow

### 1. Discover feature directory

Read `.specify/feature.json` to get the current feature directory name (e.g.,
`003-version-info-modal`). This becomes the `workflow.id` in the generated YAML
and is used for run matching by `/resume`.

If `SPECIFY_FEATURE_DIRECTORY` env var is set, use it instead.

### 2. Collect input (if no args)

If no args provided, display and collect:

```markdown
## Mission Brief

**Goal**: What do you want to build? (one sentence)
**Success Criteria**: How will you know it's done? (2-3 measurable outcomes)
**Constraints**: Any constraints? (technical, time, scope)
```

Wait for user response. Combine the three fields into a single spec description
string and use it as `spec_description`.

### 3. Read configuration

Read `.specify/extensions/workflow/workflow-config.yml` if it exists:

```yaml
workflow:
  max_iterations: 5
  max_spec_corrections: 2
  models:
    strong: "glm-5.2"
    fast: "deepseek-v4-flash-free"
```

If the config file is missing, use defaults (`max_iterations: 5`,
`max_spec_corrections: 2`) and omit `model:` fields from the generated YAML.

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
`command-catalog.md` and decide which optional phases to include. The decision is
hands-off (no user confirmation) but is recorded in `.mission-state.json` for
transparency.

| Phase | Applies to route(s) | Include when |
|-------|---------------------|--------------|
| `brainstorm` | `spec.*` | prompt is architectural/ambiguous ("design", "approach", "compare", "how should we", multiple viable solutions) |
| `clarify` | `spec.*`, `change.*` | Mission Brief success criteria are vague or constraints are missing |
| `analyze` | `spec.*` | route is `spec.*` (symmetric with the other optional phases) |
| `trace` | `spec.*`, `change.*` | Mission Brief mentions persistence, audit, traceability, compliance, or `--persist`/reuse intent |

Each selected phase is wrapped in an **`if` step** in the generated YAML. The
`if` step carries a gen-time literal `condition: true` or `condition: false`.

> **Engine constraint**: the workflow engine has no step-level `condition:` field;
> a `condition:` key on a normal `command` step is silently ignored. Optional
> phases MUST use the `if` step primitive (`type: if`).

### 5. Initialize mission state

Create or update `.specify/extensions/workflow/.mission-state.json`:

```json
{
  "feature": "<feature-name>",
  "route": "<spec|change|quick>",
  "spec_description": "<original prompt>",
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
  "last_run_id": null
}
```

This file persists across runs and prevents infinite spec-correction loops. The
`phases` object records the hands-off optional-phase decision so the same flags
are reused if a spec-correction re-run is triggered.

### 6. Generate workflow YAML

Write a temporary workflow YAML file to `/tmp/specify-mission-<feature-name>.yml`.

The YAML uses the feature name as `workflow.id` so `/resume` can match runs. It
uses the **`if` step primitive** to wrap optional phases. The `if` step's
`condition:` is a gen-time literal (`true` or `false`) copied from
`.mission-state.json.phases`.

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

- If config has `models.strong`: add `model: "<strong>"` to specify, plan,
  implement, and `spec.brainstorm` steps
- If config has `models.fast`: add `model: "<fast>"` to tasks, converge,
  `spec.clarify`, `spec.analyze`, and `spec.trace` steps
  (or set as workflow-level `model:` default)
- If no config: omit all `model:` fields — engine uses integration default

### 7. Run the workflow

```bash
specify workflow run /tmp/specify-mission-<feature-name>.yml --input spec="<spec_description>"
```

After the run completes, capture the `run_id` from the output. Update
`.mission-state.json` with `last_run_id`.

### 8. Spec correction routing (after workflow completes)

After each workflow run, check for EDD's `next-spec.md` in the feature directory:

```
$SPECIFY_FEATURE_DIRECTORY/next-spec.md
```

**If `next-spec.md` exists:**

1. Read `.mission-state.json`
2. If `spec_corrections >= max_spec_corrections`:
   - **STOP**: "Spec repeatedly fails EDD evaluation ({{ spec_corrections }}/{{ max_spec_corrections }}). Human review of spec required."
   - Do NOT delete `next-spec.md` — the user needs it for manual review
   - Keep `.mission-state.json` for inspection
   - Report and stop
3. Otherwise:
   - Delete `next-spec.md` (consume it — `spec.specify` will read the revised content)
   - Increment `spec_corrections` in `.mission-state.json`
   - Generate a new workflow YAML (same route **and same `phases` flags**; only
     `spec.specify` detects the revised spec from the consumed `next-spec.md`)
   - Run the new workflow: `specify workflow run <new-yaml> --input spec=""`
   - Update `last_run_id` in `.mission-state.json`
   - Repeat step 8

**If `next-spec.md` does NOT exist:**

The mission is complete. Report:

```markdown
## Mission Complete

- Feature: <feature-name>
- Route: <spec|change|quick>
- Phases included: brainstorm=<bool>, clarify=<bool>, analyze=<bool>, trace=<bool>
- Workflow runs: <count>
- Spec corrections: <spec_corrections>/<max_spec_corrections>
- Final run ID: <last_run_id>

To resume a failed/paused run: /resume
To persist the workflow: /persist
```

Delete `.mission-state.json` (mission is done).

## Exit conditions

- Workflow `converged` + no `next-spec.md` → **mission complete**
- Workflow `tasks_appended` after `max_iterations` + no `next-spec.md` → **mission complete** (inner loop exhausted, no spec-level issues)
- `next-spec.md` exists + `spec_corrections >= max_spec_corrections` → **stop** (human review)
- Workflow `FAILED` → **stop** (report error, suggest `/resume` after fixing)

## Safety mechanisms

- **Inner loop cap**: `max_iterations: 5` (engine-enforced, in the YAML)
- **Outer loop cap**: `max_spec_corrections: 2` (state-file-enforced, in `.mission-state.json`)
- **State persistence**: `.mission-state.json` survives context compaction and session restarts
- **Cleanup**: `.mission-state.json` is deleted on mission completion

## Examples

```
# Start a new mission with a description
/mission "add dark mode toggle to dashboard"

# Start without args — collect Mission Brief first
/mission

# After mission completes, resume a failed run
/resume

# After mission completes, persist the workflow for reuse
/persist
```
