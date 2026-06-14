# EDD Extension — Evaluation-Driven Development

Adds a verification layer to the Spec-Driven Development cycle. EDD runs deterministic checks (lint, tests, smoke) alongside AI-driven evaluation (oracle adequacy, evidence mapping, analyze findings), grades all gates, and generates a corrective prompt on failure to enable loop-driven development.

## Commands

| Command | Purpose |
|---------|---------|
| `edd.verify` | Run deterministic + AI evaluation, grade gates, write `evidence.md` + `grade.json` + `next-prompt.md` |

## Workflow

```
specify → plan → tasks → implement → edd.verify
                                     ↓
                              grade.json PASS?
                              yes → done
                              no  → next-prompt.md → loop back to specify
```

## Quality Gates

EDD evaluates the implementation against quality gates. Gates can be defined per-feature in the spec's `## Quality Gates` section, or fall back to defaults:

1. All tests pass (deterministic)
2. Code coverage ≥ 80% (deterministic)
3. Oracle adequacy score ≥ 80% (AI)
4. No CRITICAL/HIGH findings (AI)
5. All Success Criteria validated (AI)
6. All Constraints validated (AI)

## Loop Workflow

The extension ships a workflow that automates the loop:

```bash
specify workflow run extensions/edd/workflows/sdd-loop.yml \
  --input spec="Build user authentication"
```

Or install and run:

```bash
specify workflow add sdd-loop  # if published to catalog
specify workflow run sdd-loop --input spec="Build user authentication"
```

## Configuration

Create `.specify/extensions/edd/edd-config.yml` to customize thresholds and check selection.

## Files Produced

| File | Purpose |
|------|---------|
| `FEATURE_DIR/evidence.md` | Human-readable verification dossier |
| `FEATURE_DIR/.eval/grade.json` | Machine-readable PASS/FAIL verdict |
| `FEATURE_DIR/next-prompt.md` | Corrective prompt for next loop iteration (FAIL only) |

## Integration

EDD hooks into `after_implement` automatically when enabled. Install the extension and the hook fires after every `spec.implement`.

```bash
specify extension install edd
```

Or, since EDD is bundled with the fork, it ships in the wheel and can be installed from the local catalog.
