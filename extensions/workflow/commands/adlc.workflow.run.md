---
description: "Execute a workflow YAML by walking its steps list and dispatching each step to a subagent. Manages .mission-state.json for resume."
---

## Goal

Read a workflow YAML file and execute its `steps:` list sequentially, dispatching
each step to a subagent. This is the **executor** half of the mission workflow —
`/workflow.mission` generates the YAML and delegates to this command; this
command interprets the YAML and runs the pipeline.

The YAML is the **single source of truth** — this command is generic and does
not hardcode route-specific logic.

## Arguments

- `<yaml-path>` (required): Path to the workflow YAML file to execute.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding. The argument is the YAML
file path.

## Flow

### 1. Read the YAML

Read the workflow YAML file at the path given as `$ARGUMENTS`. Parse its
`steps:` list.

### 2. Load or initialize mission state

Read `.specify/extensions/workflow/.mission-state.json` if it exists. If not,
create a minimal state with defaults:

```json
{
  "spec_description": "",
  "supervision": "gated",
  "circuit_breaker": 3,
  "max_iterations": 5,
  "completed_steps": [],
  "step_results": {},
  "consecutive_tasks_appended": 0
}
```

If the state exists and `completed_steps` is non-empty, this is a **resume** —
skip steps whose IDs are already in that list.

Store the YAML path in the state as `yaml_path` for resume purposes.

### 3. Track the pipeline

Before executing, create a `todowrite` list mirroring the YAML's top-level
`steps:`. Mark steps already in `completed_steps` as `completed`. Update this
list after every step returns.

### 4. Expression resolution

Resolve `{{ }}` expressions before executing each step:

| Expression | Resolution |
|---|---|
| `{{ inputs.spec }}` | The `spec_description` from `.mission-state.json` |
| `{{ inputs.integration }}` | The string `"auto"` (or config value) |
| `{{ steps.<id>.output.choice == '<value>' }}` | Compare the user's gate choice stored from step `<id>` |
| `{{ steps.<id>.output.stdout \| contains('tasks_appended') }}` | Check whether the subagent summary from step `<id>` contains `tasks_appended` |
| `true` / `false` (literal) | Literal boolean from `.mission-state.json.phases` |

### 5. Step dispatch

For each step in the YAML's `steps:` list, read its `type:` field (default:
`command` if absent) and dispatch:

---

**`command`** (default — no `type:` field, or `type: command`)

1. Resolve `input.args` from expressions.
2. Emit:

   ```markdown
   ## Workflow Step: <id>

   **Delegating to**: `/<command>`
   **Args**: `<resolved-args>`
   ```

3. Delegate to a subagent. Pass the prompt below **verbatim** to the subagent —
   do NOT read the command file yourself, do NOT execute the instructions
   yourself. The subagent handles everything.

   If the command is a **converge** step (command ends with `.converge`), prepend
   this independence hint to the subagent prompt:

   > You are grading work that another agent produced. Do NOT assume the
   > implementation is correct — verify against the spec independently. Try to
   > make each requirement fail at the primary source (run the test, check the
   > file, grep for the reference). You are the checker, not the maker.

   Standard delegation prompt:

   ```markdown
   You are being invoked by the `/workflow.run` executor.

   Execute the command `/<command>` with the following arguments:

   <resolved-args>

   1. Read the command file for `/<command>` in your integration's commands
      directory (for example, `.opencode/commands/<command>.md`,
      `.claude/commands/<command>.md`, etc.).
   2. Execute the command's instructions inline using your available tools,
      using the arguments shown above as the user input to that command.
   3. **Do NOT follow handoffs** to other commands — return your results to the
      executor when you finish.
   4. Return a concise summary: what you did, whether it succeeded, and whether
      the output contains `tasks_appended` or `converged`.
   ```

4. Wait for the subagent to finish.
5. **You MUST update `.mission-state.json` now** — before proceeding to the next
   step. Summarize the subagent's output in 1-2 sentences. Store the summary as
   `step_results.<id>.output` and append `<id>` to `completed_steps`. Write the
   file to disk immediately. Discard the full subagent response from working
   memory.
6. If the command was a `specify` step (command ends with `.specify`), re-read
   `.specify/feature.json` and update `.mission-state.json.feature` to match the
   current feature directory — the specify step may have created a new change
   directory and updated the pointer.
7. If the command was an **implement** step (command ends with `.implement`),
   append an entry to `<FEATURE_DIR>/iterations.md` as an audit trail:

   ```markdown
   ## Iteration <N> - <date>
   - Files changed: <list from subagent summary>
   - Summary: <1-2 sentence summary>
   - Tests: <pass/fail count from subagent summary>
   ```
8. After each `command` step, check for `next-spec.md` in the current feature
   directory. If it exists, **stop and return** `spec_correction_needed` to the
   caller — do not continue executing steps.

---

**`if`**

1. Evaluate `condition` (literal or expression — see table above).
2. If truthy: recursively execute the `then:` steps list.
3. If falsy and `else:` is present: recursively execute the `else:` steps list.
4. If falsy and no `else:`: skip.

---

**`gate`**

1. Display the `message` and `options` to the user as plain text.
2. Wait for the user to choose one of the `options`.
3. Store the choice as `step_results.<id>.output.choice` in `.mission-state.json`.
4. Append `<id>` to `completed_steps`.

---

**`do-while`**

1. Execute the inner `steps:` list (each step dispatched per its type). Use
   **iteration-prefixed IDs** for `completed_steps` tracking: for iteration 0,
   use `<loop_id>_0_<step_id>` (e.g., `loop_0_implement`); for iteration 1,
   `loop_1_implement`; etc. This ensures resume can distinguish iteration 1's
   `implement` from iteration 2's. The step ID in the YAML stays as-is — only
   the `completed_steps` entry is prefixed.
2. After the inner steps complete, evaluate `condition`:
   - If truthy and iteration count < `max_iterations`: repeat from step 1.
   - If falsy or iteration count >= `max_iterations`: continue to the next
     sibling step.
3. Track iteration count in `.mission-state.json` as
   `step_results.<id>.iterations`.

**Circuit breaker.** Track `consecutive_tasks_appended` count across iterations.
Read the initial value from `.mission-state.json.consecutive_tasks_appended`
(default 0). After each converge step, if the output contains `tasks_appended`,
increment the counter and write it to `.mission-state.json`. If it contains
`converged`, reset the counter to 0 and write it.

If the counter reaches N (where N is `circuit_breaker` from
`.mission-state.json`, default 3), **stop the loop immediately** and return
`failed` with:

```
Circuit breaker: N consecutive iterations appended tasks without convergence.
Human review needed — the loop is not converging.
```

This counter persists across resume — if a mission was interrupted after 2
consecutive `tasks_appended`, resume starts with the counter at 2, not 0.

---

**`shell`**

1. Run the `run:` command via `bash`.
2. Store stdout/stderr as `step_results.<id>.output` in `.mission-state.json`.
3. Append `<id>` to `completed_steps`.

---

**`prompt`**

1. Resolve the `prompt:` text from expressions.
2. Delegate to a subagent with the raw prompt (not a command name).
3. Same summarize/store/discard flow as `command`.

---

**`switch`**

1. Evaluate the `expression` field.
2. Match against `cases:` keys.
3. Recursively execute the matching case's `then:` steps.
4. If no match and `default:` exists: recursively execute `default:` steps.

---

**`fan-out`**

1. Resolve the `items:` expression to a list.
2. For each item: execute the `step:` template with `context.item` set to the
   current item. Execute sequentially unless the platform supports parallel
   subagent dispatch.
3. Collect all results into `step_results.<id>.output.results`.

---

**`fan-in`**

1. For each step ID in `wait_for:`: read its stored result from
   `step_results.<id>.output`.
2. Collect into `step_results.<id>.output.results`.

---

### 6. Context budget awareness

Long-running workflows can exhaust the model's context window. Actively manage
context:

- After every step, summarize the outcome in 1-2 sentences and discard the full
  subagent response.
- After completing 5 or more steps in this session, proactively suggest:
  "Session is getting long. You can continue, or start a fresh chat —
  `/workflow.resume` will resume from `.mission-state.json`."
- If responses become repetitive or lose earlier context, suggest a fresh chat.

### 7. Return signal

When all steps are complete (or when `next-spec.md` is found), return one of
these signals to the caller:

| Signal | Meaning |
|---|---|
| `converged` | All steps completed, no `tasks_appended` in last converge |
| `tasks_appended` | Loop exhausted `max_iterations` with `tasks_appended` still present |
| `spec_correction_needed` | `next-spec.md` found during execution — caller should handle spec correction |
| `failed` | A step failed and could not continue |

## Exit conditions

- All steps completed + no `next-spec.md` → return `converged`
- `do-while` exhausted `max_iterations` + no `next-spec.md` → return `tasks_appended`
- `do-while` circuit breaker tripped (N consecutive `tasks_appended`) → return `failed`
- `next-spec.md` found → return `spec_correction_needed`
- A step fails → return `failed`

## Examples

```
# Run a workflow YAML directly
/workflow.run .specify/workflow/tmp/specify-mission-005-remove-version-modal.yml

# Resume an interrupted workflow (state file must exist)
/workflow.run .specify/workflow/tmp/specify-mission-005-remove-version-modal.yml
```
