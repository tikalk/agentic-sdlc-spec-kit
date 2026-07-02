# EDD Extension — Evaluation-Driven Development

EDD is a **convergence partner** for `spec.converge`: it runs deterministic checks (lint, tests, smoke) alongside AI-driven evaluation (oracle adequacy, evidence mapping), grades all quality gates, then:

1. **Appends actionable verification gaps** as tasks to `tasks.md` (implementation-level fixes)
2. **Writes `next-spec.md`** for spec-level corrections (oracle adequacy, ambiguous requirements)
3. **Fills EDD evidence sections** in converge's `verify.md`, producing a unified evidence bundle

This enables loop-driven development where both spec-level and implementation-level corrections are routed correctly.

## Commands

| Command | Purpose |
|---------|---------|
| `edd.verify` | Run deterministic + AI evaluation, grade gates, append tasks, update `verify.md`, write `evidence.md` + `loop-state.yml` + `next-spec.md` |

## Workflow

```
specify → plan → tasks → implement → converge (writes verify.md with EDD placeholders)
                                                ↓
                                         edd.verify (after_converge hook)
                                                ↓
                                         PASS? → done (verify.md fully populated)
                                         FAIL? → classify findings:
                                           • actionable → append tasks to tasks.md
                                           • spec-level → write next-spec.md
                                                ↓
                                         next-spec.md exists?
                                           yes → spec.specify → plan → tasks → implement → converge
                                           no  → implement (picks up EDD tasks) → converge
```

## Quality Gates

EDD evaluates the implementation against quality gates. Gates can be defined per-feature in the spec's `## Quality Gates` section, or fall back to defaults:

1. All tests pass (deterministic)
2. Code coverage ≥ 80% (deterministic)
3. Oracle adequacy score ≥ 80% (AI)
4. No CRITICAL/HIGH findings (AI)
5. All Success Criteria validated (AI)
6. All Constraints validated (AI)

## Finding Classification

EDD classifies each failed gate's findings into two categories:

### Actionable (→ tasks.md)

Implementation-level fixes that `spec.implement` can execute:

| Finding type | Example task |
|---|---|
| Test coverage < threshold | "Add tests for uncovered paths per FR-###" |
| Constraint unvalidated | "Validate constraint C-###: {description}" |
| CRITICAL/HIGH analyze finding | "Fix {finding} per {source-ref}" |
| Lint/test failures | "Fix {N} lint errors in {file}" |

These are appended to `tasks.md` under a `## Phase N: EDD` section, following converge's append-only contract.

### Spec-level (→ next-spec.md)

Spec-level corrections that require re-running `spec.specify`:

| Finding type | Example correction |
|---|---|
| Oracle adequacy < threshold | "Quantify SC-###, add measurable acceptance criteria" |
| Ambiguous requirement | "Clarify FR-###: {what's ambiguous}" |
| Missing success criterion | "Add SC-### for {capability}" |

## Loop Routing

The `impl-converge-loop` workflow (via the `loop` extension) automates the implement↺converge cycle. When EDD is installed, its `after_converge` hook fires after every converge step:

```bash
specify adlc.loop.run
```

When EDD signals `tasks_appended`, the loop checks for `next-spec.md`:

- **`next-spec.md` exists** → spec-level correction: route to `spec.specify` → `spec.plan` → `spec.tasks` → `spec.implement` → `spec.converge`
- **`next-spec.md` absent** → task-level correction: route to `spec.implement` (picks up EDD-appended tasks) → `spec.converge`

## Unified Evidence Bundle

Converge writes `verify.md` with placeholder sections for EDD. After EDD runs (via `after_converge` hook), it fills in:

- **EDD Evidence** — quality gate results table with PASS/FAIL per gate
- **What Was Checked (EDD)** — lint, tests, coverage, oracle adequacy, SC/constraint validation
- **What Was NOT Checked (EDD)** — incomplete gates, insufficient evidence
- **Residual Risks (EDD)** — risks from failed gates, unvalidated assumptions
- **Provenance (EDD)** — version, iteration, verdict, score

The result is a single `verify.md` that serves as the unified evidence bundle — addressing the "every accepted change should ship with a record of what was checked, what was not, and what risks remain" requirement.

## Configuration

Create `.specify/extensions/edd/edd-config.yml` to customize thresholds and check selection.

## Files Produced

| File | Purpose |
|------|---------|
| `FEATURE_DIR/verify.md` | **Updated** — EDD fills placeholder sections (unified evidence bundle) |
| `FEATURE_DIR/evidence.md` | Human-readable verification dossier (EDD's own detailed report) |
| `FEATURE_DIR/.eval/loop-state.yml` | Machine-readable state spine with iteration history |
| `FEATURE_DIR/tasks.md` | **Appended** — actionable verification tasks under `## Phase N: EDD` |
| `FEATURE_DIR/next-spec.md` | Spec-level corrections for `spec.specify` (FAIL only, spec-level issues) |

## Integration

EDD hooks into `after_converge` automatically when enabled. Install the extension and the hook fires after every `spec.converge`.

```bash
specify extension install edd
```

Or, since EDD is bundled with the fork, it ships in the wheel and can be installed from the local catalog.
