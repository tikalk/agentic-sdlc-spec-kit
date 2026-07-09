---
type: Skill
name: team-verify
title: Team Verify
description: "Use when performing a health check on the team-ai-directives installation, verifying config presence, and validating OKF frontmatter compatibility."
tags: [governance, verification, health-check]
timestamp: 2026-07-09T00:00:00Z
id: skill-team-verify
cdr_ref: null
created: 2026-07-09
modified: 2026-07-09
verified: 2026-07-09
age_days: 0
evidence: []
instruction_type: Generation
priority: Standard
source: team-ai-directives
user-invocable: true
---

## Overview

Run a health check on a team-ai-directives knowledge base. Confirm configuration, required context modules, registry files, CDR tracking, constitution alignment, and OKF frontmatter validity.

## When to Use

- After installing or updating the knowledge base.
- Before onboarding a new repository.
- When a generated directive appears stale or inconsistent.
- As a periodic governance hygiene step.

## Core Pattern

Execute each check and report `[OK]`, `[WARN]`, `[INFO]`, or `[FAIL]`.

1. **Knowledge Base Configured**
   - Read `.specify/init-options.json`.
   - Confirm `team_ai_directives` points to a valid path.
   - Verify the knowledge base directory exists.

2. **Context Modules Exist**
   - Locate the knowledge base path.
   - Confirm the following exist:
     - `context_modules/constitution.md`
     - `context_modules/personas/`
     - `context_modules/rules/`
     - `context_modules/examples/`

3. **Skills Registry**
   - Confirm `.skills.json` exists and parses as valid JSON.

4. **CDR Tracking**
   - Confirm `CDR.md` exists.

5. **Constitution Alignment**
   - Read `{KB}/context_modules/constitution.md`.
   - Locate `{REPO_ROOT}/.specify/memory/constitution.md`.
   - If present, verify it inherits team principles.
   - Report `[OK]`, `[WARN]`, or `[INFO]` if missing.

6. **OKF Type Field Presence**
   - Scan all `.md` files in `context_modules/` (exclude `index.md`, `log.md`).
   - Parse YAML frontmatter.
   - Confirm each file has a valid `type`: `Constitution`, `Persona`, `Rule`, `Example`, or `Skill`.

## Quick Reference

| Code | Meaning |
|------|---------|
| `[OK]` | Check passed |
| `[WARN]` | Non-blocking issue |
| `[INFO]` | Informational |
| `[FAIL]` | Blocking failure |

Exit `0` if no `[FAIL]` items remain; otherwise exit `1`.

## Common Mistakes

- Running the check outside a repository with `.specify/init-options.json`.
- Treating `[WARN]` as a failure.
- Forgetting to validate JSON syntax in `.skills.json`.
- Skipping the constitution inheritance check for existing projects.
