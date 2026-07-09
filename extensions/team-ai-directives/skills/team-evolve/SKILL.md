---
type: Skill
name: team-evolve
title: Team Evolve
description: "Use when applying regression-gated CDRs to the team knowledge base, implementing approved context changes, and updating local CDR status."
tags: [governance, evolution, cdr]
timestamp: 2026-07-09T00:00:00Z
id: skill-team-evolve
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

Apply regression-gated Context Definition Requests (CDRs) to the team knowledge base. Validate proposals, implement accepted CDRs as local file changes, update CDR status, and emit a results summary. This skill edits files only and does not perform Git operations.

## When to Use

- `team-curate` has produced proposed CDRs in `.specify/drafts/cdr.md`.
- A CDR must pass regression gates before it is implemented.
- A passing CDR needs to become a context module or constitution amendment.
- Local CDR status must be updated after review.

## Core Pattern

1. Load CDRs with status **Proposed** from `.specify/drafts/cdr.md`.
2. Run the regression gate: dedup, evidence, team-wide applicability, and optional evals.
3. Mark each CDR as **Accepted**, **Rejected ({reason})**, or **Blocked ({reason})**.
4. Implement accepted CDRs in the correct context module path.
5. Update implemented CDRs to **Implemented** and record the target file.
6. Output a **Team Evolve Summary**.

## Quick Reference

| Task | Action |
|---|---|
| Generate CDRs | Run `team-curate` |
| Refine a CDR | Run `levelup-clarify` |
| Build a skill | Run `levelup-skill` |

## Common Mistakes

- Running `team-evolve` before any CDRs are proposed.
- Modifying existing context modules without running configured evals.
- Treating project-specific guidance as a team-wide rule.
- Forgetting to record `cdr_ref` and the target file on implemented modules.
- Performing Git commits or creating PRs inside this skill.
