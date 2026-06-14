# EDD Quality Gates Reference Template

This template documents the optional `## Quality Gates` section that can be added to any feature spec. When the section is present, `edd.verify` uses it as the source of truth for grading. When absent, `edd.verify` falls back to the defaults defined in `edd-config.yml`.

## Purpose

Quality Gates define, per-feature, what "done" means. They are part of the spec — not global config — because each feature may have different quality requirements.

## Format

```markdown
## Quality Gates

| # | Gate | Threshold | Checked By |
|---|------|-----------|------------|
| 1 | All tests pass | required | Deterministic: test runner |
| 2 | Code coverage | ≥ 80% | Deterministic: coverage tool |
| 3 | Oracle adequacy | ≥ 80% | AI: `spec.checklist mission-brief` |
| 4 | No CRITICAL/HIGH findings | required | AI: `spec.analyze` |
| 5 | All Success Criteria validated | required | AI: evidence mapping in `evidence.md` |
| 6 | All Constraints validated | required | AI: evidence mapping in `evidence.md` |
| 7 | Lint passes | 0 errors | Deterministic: linter |
| 8 | Smoke tests pass | required | Deterministic: smoke test runner |
```

## Behavior

- **Present**: `edd.verify` checks every gate listed and ignores defaults.
- **Absent**: `edd.verify` uses the default gate set from `edd-config.yml`.
- **Partial**: Only the gates listed are checked; unlisted gates default to `config-template.yml` values.

## Adding Custom Gates

Teams can add project-specific gates:

```markdown
| 9 | API contract tests | required | Deterministic: `npm run test:contract` |
| 10 | Accessibility audit | 0 violations | Deterministic: `pa11y` |
```

Custom gates must include a `Checked By` column that references either a deterministic command or an AI evaluation source.
