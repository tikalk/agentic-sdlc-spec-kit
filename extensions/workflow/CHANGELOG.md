# Changelog

All notable changes to the Workflow Extension will be documented in this file.

## [2.6.1] - 2026-07-06

### Fixed

- **`/workflow.resume` delegation target**: was contradictory (3-way: mission vs
  run vs "direct user"). Now consistently delegates to `/workflow.mission` which
  handles Step 1 resume check → Step 7 (run) → Step 8 (sign-off + audit trail).
  This ensures resumed missions get sign-off gates and `mission-log.json`
  persistence.
- **`/workflow.resume` completed-mission detection**: now checks for
  `mission-log.json` in the feature directory. If found, reports "already
  completed" instead of silently falling through to engine run scanning.
- **Circuit breaker counter persisted**: `consecutive_tasks_appended` is now
  written to `.mission-state.json` after each converge step. On resume, the
  counter is restored — a mission interrupted after 2 consecutive
  `tasks_appended` resumes with the counter at 2, not 0.
- **Do-while resume IDs**: `/workflow.run` now uses iteration-prefixed IDs
  (`loop_0_implement`, `loop_1_converge`) for `completed_steps` tracking. This
  prevents resume from confusing iteration 1's `implement` with iteration 2's.
- **`/workflow.run` minimal state init**: now includes `supervision`,
  `circuit_breaker`, and `consecutive_tasks_appended` with defaults. Direct
  invocation (without mission) no longer loses safety semantics.

## [2.6.0] - 2026-07-06

### Added — Safety Layer (Loop Engineering alignment)

- **Supervision modes**: `gated` (default), `autonomous`, and `hybrid`. Controlled
  via `workflow-config.yml`. In `gated` mode, human review gates are injected
  after `specify` and after each `implement` step, plus a final sign-off gate
  before mission complete. In `autonomous` mode, no gates — the loop runs freely
  but requires verifiable done-criteria. In `hybrid` mode, spec review gate only,
  plus final sign-off.
- **Circuit breaker**: stops the do-while loop after N consecutive
  `tasks_appended` outcomes (default 3, configurable). Prevents infinite
  spinning on unsolvable issues.
- **Converge independence hint**: converge subagent is instructed to verify
  independently and try to make each requirement fail — not trust the
  implementer's context.
- **Iterations audit trail**: after each `implement` step, an entry is appended
  to `<FEATURE_DIR>/iterations.md` with files changed, summary, and test
  results.
- **Audit trail persistence**: on mission completion, `.mission-state.json` is
  moved to `<FEATURE_DIR>/mission-log.json` instead of being deleted.
- **Autonomous mode validation**: refuses to start if the spec has "TBD" or
  empty Success Criteria when running in autonomous mode.

### Changed

- **Mission Step 8**: now includes conditional sign-off gate (gated/hybrid
  modes) and audit trail persistence (all modes).
- **Mission Step 6**: YAML templates now document supervision-mode gate
  injection — autonomous form is the base template, gates are injected for
  gated/hybrid.
- **Config template**: added `supervision` and `circuit_breaker` fields.

### Fixed

- **Converge scope guard**: converge now only grades against the current
  change/feature spec. Pre-existing issues unrelated to the change scope are
  noted in the risk register but NOT appended as convergence tasks.
- **Verifiable done-criteria**: `change.specify`, `spec.specify`, and
  `quick.implement` now refuse to leave Success Criteria as "TBD" — always
  derive at least one checkable criterion from the goal.

## [2.5.0] - 2026-07-06

### Added

- **`/workflow.run` command**: new executor command that reads a workflow YAML
  and walks its `steps:` list, dispatching each step to a subagent. Manages
  `.mission-state.json` (completed_steps, step_results, iterations) for resume.
  Returns a signal (`converged`, `tasks_appended`, `spec_correction_needed`,
  `failed`) to the caller. Works with any workflow YAML, not just
  mission-generated ones.

### Changed

- **`/workflow.mission` split**: Step 7 is now a thin delegation to
  `/workflow.run` as a subagent. The entire YAML interpreter (step dispatch,
  expression resolution, context budget, next-spec.md checks) moved to
  `/workflow.run`. Step 8 now acts on the return signal from `/workflow.run`.
- **`/workflow.resume` updated**: now delegates to `/workflow.run` with the
  `yaml_path` from `.mission-state.json` instead of telling the user to re-run
  `/workflow.mission`.
- **`yaml_path` field**: added to `.mission-state.json` schema so `/workflow.resume`
  can find the YAML file.

## [2.4.2] - 2026-07-06

### Fixed

- **`$ARGUMENTS` leakage in delegation prompt**: the delegation prompt template
  used the literal `$ARGUMENTS` which the CLI replaces with the mission's own
  args. Removed all `$ARGUMENTS` references from the delegation template — the
  subagent now receives the resolved args directly.
- **Stale feature name after specify step**: after a `specify` command step
  completes, the orchestrator now re-reads `.specify/feature.json` and updates
  `.mission-state.json.feature` to match the new change directory created by
  `change.specify`.
- **Orchestrator reading command files**: the delegation instruction now
  explicitly says "do NOT read the command file yourself — the subagent handles
  everything" to prevent the orchestrator from polluting its context with
  ~700 lines of command file content.
- **Mission state never updated**: step 5 now says "**You MUST update
  `.mission-state.json` now** — before proceeding to the next step" with
  explicit write-to-disk instruction.
- **`/workflow.resume` ignores agent-orchestrated missions**: resume now
  checks for `.mission-state.json` with non-empty `completed_steps` first. If
  found, it directs the user to run `/workflow.mission` (which auto-resumes).
  Falls back to engine run scanning only for the terminal execution path.

## [2.4.1] - 2026-07-06

### Added

- **Resume support**: Step 1 now checks for an existing `.mission-state.json`
  with a non-empty `completed_steps` array. If found, the agent skips Steps 2-6
  and jumps directly to Step 7, resuming from the first incomplete step. The
  YAML file and state are reused.
- **Tracking fields in state schema**: `completed_steps: []` and
  `step_results: {}` are now part of the Step 5 schema. They are populated
  during Step 7 execution and enable resume after interruptions.

## [2.4.0] - 2026-07-06

### Changed

- **`adlc.workflow.mission` execution model**: Step 7 is now a **generic YAML
  interpreter**. It reads the workflow YAML generated in Step 6 and walks its
  `steps:` list, dispatching each step by `type:` (`command`, `if`, `gate`,
  `do-while`, `shell`, `prompt`, `switch`, `fan-out`, `fan-in`). The YAML is
  the single source of truth — Step 7 contains no route-specific prose. Adding
  routes or phases only changes the YAML templates in Step 6.

### Fixed

- **Orchestrator no longer reads command files**: the v2.3.0 orchestrator read
  the target command's `.md` file in the orchestrator's context (~600 lines)
  before delegating. v2.4.0 delegates the reading to the subagent — the
  orchestrator only reads the YAML.
- **Delegation prompts no longer leak implementation details**: v2.3.0's
  delegation prompts told the subagent what to search for and where. v2.4.0's
  delegation prompt is generic — the subagent reads the command file and
  figures out the details itself.
- **YAML is now the execution driver**: v2.3.0 generated the YAML but executed
  from route-specific numbered lists in prose. v2.4.0 executes from the YAML —
  the same artifact works in both the agent path and the terminal engine path.

## [2.3.0] - 2026-07-05

### Changed

- **`adlc.workflow.mission` execution model**: the command now acts as a **fleet
  orchestrator** and delegates each pipeline step to a subagent using the host
  agent's native subagent/task dispatch (Task tool in opencode / Claude Code,
  `@mention` in Copilot, etc.). The orchestrator manages state and gates; each
  subagent reads the target command's `.md` file, executes its instructions
  inline with its own tools, and returns a compact summary. This replaces the
  per-step `specify workflow run` approach that spawned nested processes and
  hit bash timeouts.

### Fixed

- **User Input handling**: replaced the Mission Brief collection step (which led
  agents to use a structured question tool that users dismissed) with an
  **Automatic Extraction** pattern. If `$ARGUMENTS` is non-empty, it is used as
  `spec_description` directly. If empty or minimal, a best-effort description is
  derived from the feature directory name. No confirmation prompt, no question
  tool — the command proceeds directly to route assessment.
- **Cross-agent command dispatch**: `/workflow.mission` no longer depends on a
  non-existent slash-command dispatch tool or on `specify workflow run` per
  step. It now works with any Spec Kit-supported agent by relying on the
  platform's own subagent delegation primitive.
- **Context budget**: the orchestrator keeps only a 1-2 sentence summary per
  step and discards the full subagent response, making long missions feasible
  without context exhaustion.

## [2.2.1] - 2026-07-05

### Fixed

- **`adlc.workflow.mission` command invocation**: pipeline steps are now invoked
  using the same `EXECUTE_COMMAND:` block pattern that the `agentic-sdlc` preset
  hooks use. Each step emits a structured `## Mission Step:` block with
  `EXECUTE_COMMAND: <command>`, then actually invokes that command as a native
  slash command in its own turn and waits for completion before advancing.
  This replaces the vague "dispatch `/spec.X`" wording that caused agents to
  read the command `.md` files and execute their instructions inline, losing
  per-turn boundaries, bypassing command hooks, and getting lost in command
  internals.

## [2.2.0] - 2026-07-04

### Fixed

- Generated mission workflow YAML is now written to `.specify/workflow/tmp/`
  instead of `/tmp`, avoiding `external_directory` permission requests during
  automated runs.
- The `change.*` route no longer injects `spec.clarify` or `spec.trace`
  (commands that belong to the `agentic-sdlc` preset). It now emits only the
  native `agentic-change` pipeline
  (`change.specify` → `change.implement`↺`change.converge`).
- Slash-command references: `/mission`, `/resume`, and `/persist` examples now
  use their canonical aliases `/workflow.mission`, `/workflow.resume`, and
  `/workflow.persist`.
- Quoted the `description:` frontmatter values in `adlc.workflow.mission.md`,
  `adlc.workflow.resume.md`, and `adlc.workflow.persist.md` so opencode installs
  them with non-empty descriptions.

### Changed

- User-gated optional phases: brainstorm, clarify, analyze, and trace are now
  auto-selected as candidates (recorded in `.mission-state.json.phases`), then
  each emitted phase presents a `gate` step at runtime so the operator can
  confirm or skip it before the phase's `command` step executes.

### Added

- Agent-dispatched execution model: `/workflow.mission` runs the generated
  pipeline as slash commands, one step per turn, instead of executing the whole
  workflow synchronously inside a single `specify workflow run` Bash invocation.
