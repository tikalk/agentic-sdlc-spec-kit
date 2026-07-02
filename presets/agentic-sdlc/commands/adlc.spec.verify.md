---
description: Loop-ready verification — converge gap-finder, test gate, diff analysis, and 4-pillar compliance assessment with loop-back directive
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -IncludeTasks
---

## MANDATORY: Pre-Execution Hooks

**STOP. Before reading User Input or doing ANY other work, execute extension hooks.**

0. Determine `{REPO_ROOT}` by running `git rev-parse --show-toplevel 2>/dev/null`. If that fails, walk up from the current directory until you find a `.git` directory or `.specify/init-options.json` and use that parent as `{REPO_ROOT}`.
1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, state `No hooks file found` and skip to User Input.
2. Read `{REPO_ROOT}/.specify/extensions.yml` and find `hooks.before_verify`.
3. Skip any hook with `enabled: false`. Skip any hook with a non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Pre-Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}

      Wait for the result of the hook command before proceeding.
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`): Display the hook name, command, and description. Let the user decide.
5. State which hooks were executed, then proceed to User Input.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Prerequisites

This command requires a feature directory with implementation artifacts. Run `/spec.implement` first if you haven't already.

If no `SPECIFY_FEATURE_DIRECTORY` is set, read `.specify/feature.json` to discover the current feature directory.

Run `{SCRIPT}` once from repo root and parse JSON for FEATURE_DIR and AVAILABLE_DOCS. Abort with a clear error if the feature directory doesn't exist or is missing required artifacts (spec.md, plan.md, tasks.md).

## Convergence Gap-Finder

**Run `/spec.converge` to identify any remaining work before proceeding to verification.**

1. Check if `tasks.md` already has convergence phase headers. If it does, read the latest convergence result.
2. Invoke `/spec.converge` (or the user runs it manually).
3. Evaluate the converge outcome:
   - **`converged`**: No remaining gaps. Proceed to Test Gate.
   - **`tasks_appended`**: Gaps remain. Output the convergence findings summary, then issue a loop-back directive:

     > **Gap detected**: `/spec.converge` found {N} items of remaining work. Run `/spec.implement` to complete the convergence tasks, then run `/spec.verify` again once converged.

     **STOP assessment here.** Do NOT proceed to Test Gate or 4-Pillar Assessment until the loop completes and converge reports `converged`.

This step ensures verification always runs against a converged baseline.

## Test Gate

**Tests MUST pass before assessment.** Run the project's test suite:

1. Detect available test runners (search for `package.json` scripts, `pytest.ini`, `Cargo.toml`, `Makefile`, etc.)
2. Run tests once:
   - If tests pass → proceed to Diff Analysis
   - If tests fail → output test failure details, recommend fixes, and STOP. Do NOT continue assessment until the user confirms tests pass.

If `SPECIFY_FEATURE_DIRECTORY` is not set and no feature.json exists, skip Test Gate (not in a feature context).

## Diff Analysis

Read `git diff` to understand what changed:

1. Run `git diff HEAD --name-only` (or `git diff --name-only` if no commits yet) to identify changed files
2. Categorize changes:
   - **Spec-related files** under `SPECIFY_FEATURE_DIRECTORY/`
   - **Implementation files** (source code, configs)
   - **Test files**
   - **Documentation files**

## 4-Pillar Assessment

Assess the feature against four pillars. For each, produce a score (0-100), evidence, and specific findings.

### Pillar 1: Spec Compliance

Compare implementation against the full spec contract in `SPECIFY_FEATURE_DIRECTORY/spec.md`:

- **Goal alignment** — Does the implementation achieve the spec Goal?
- **Success Criteria coverage** — Are all SC items met?
- **Constraint adherence** — Are all Constraints respected?
- **Functional Requirements** — Are all FR items addressed? (cite each: ✅ FR-NNN or ❌ FR-NNN)
- **Non-Functional Requirements** — Are NFR items addressed?
- **Risk Register items** — Are documented risks mitigated?

Read the spec in full. For each FR and SC, trace to evidence in the implementation (files, test output, config). Flag any that are partially or fully unmet.

### Pillar 2: Code Quality

Assess implementation quality:

- **Structure** — Is the code well-organized? Follows project conventions?
- **Error handling** — Are error paths handled gracefully?
- **Edge cases** — Are edge cases from the spec addressed?
- **Consistency** — Consistent patterns, naming, and style?

### Pillar 3: Test Adequacy

Assess test coverage:

- **Coverage** — Are all FRs and SCs covered by tests?
- **Quality** — Are tests meaningful (not just pass-through)?
- **Edge cases** — Are edge cases tested?
- **Regression risk** — Are there untested paths that could break?

### Pillar 4: Risk & Evidence

Assess remaining risk:

- **Unverified assumptions** — What assumptions remain untested?
- **Technical debt** — What shortcuts or TODOs exist?
- **Integration risk** — Are integration points verified?
- **Evidence quality** — Is the evidence for each claim credible (test output, logs, manual verification)?

## Output

Write to `SPECIFY_FEATURE_DIRECTORY/verify.md`:

```markdown
# Verification Report: [Feature Name]

## Test Gate
- **Result**: PASS / FAIL
- **Details**: [Test output summary if failed]

## Diff Summary
- **Files changed**: [N]
- **Categories**: [Spec: N, Implementation: N, Tests: N, Docs: N]

## 4-Pillar Assessment

### Pillar 1: Spec Compliance
**Score**: [0-100]/100
**Evidence**: [Summary of findings]
**Unmet items**:
- ❌ FR-001: [Description] → [What's missing]
- ❌ SC-001: [Description] → [What's missing]

### Pillar 2: Code Quality
**Score**: [0-100]/100
**Strengths**: [What's good]
**Issues**: [What needs improvement]

### Pillar 3: Test Adequacy
**Score**: [0-100]/100
**Coverage**: [% estimated]
**Gaps**: [What's untested]

### Pillar 4: Risk & Evidence
**Score**: [0-100]/100
**Risks**: [Remaining risks]
**Evidence quality**: [How strong is the evidence]

## Overall Verdict

| Pillar | Score | Status |
|--------|-------|--------|
| Spec Compliance | [X] | ✅ PASS / ❌ FAIL |
| Code Quality | [X] | ✅ PASS / ❌ FAIL |
| Test Adequacy | [X] | ✅ PASS / ❌ FAIL |
| Risk & Evidence | [X] | ✅ PASS / ❌ FAIL |

**Overall**: ✅ VERIFIED / ❌ NOT VERIFIED

*Threshold: All pillars >= 70 for overall PASS.*

## Recommended Actions

[If failed, list specific actions to address each failing pillar]
```

**IMPORTANT**: If `SPECIFY_FEATURE_DIRECTORY` is not set, output the report inline instead of writing to a file.

## Quick Guidelines

- **Test gate is mandatory** — do not skip even if tests are slow
- **Evidence-basd** — every claim must cite specific files, lines, or test output
- **Honest scoring** — a 50 is better than an inflated 80 that hides real issues
- **No speculation** — if you can't verify a claim, flag it as unverifiable
- **Constructive** — always pair findings with actionable recommendations

## Operating Principles

### Constitution Authority

The project constitution (`{REPO_ROOT}/.specify/memory/constitution.md`) is **non-negotiable** within verification scope. If the implementation violates a constitution principle, it must be flagged as a spec compliance failure regardless of other scores.

### Verification vs Analysis

- **`/spec.analyze`** is read-only diagnostic — detects problems, no gate, no verdict, no file output
- **`/spec.verify`** is lifecycle gate — converge gap-finder, hard test gate, written record, structured verdict, loop-back directive on gaps

## Post-Execution Hooks

1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_verify`.
3. Skip hooks with `enabled: false` or non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`): Display hook info for user decision.
5. If no hooks registered, skip silently.
