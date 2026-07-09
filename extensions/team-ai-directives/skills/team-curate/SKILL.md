---
type: Skill
name: team-curate
title: Team Curate
description: "Use when scanning local execution traces to identify reusable team-wide knowledge, patterns, or decisions, and propose them as new Context Directive Records (CDRs)."
tags: [governance, curation, cdr]
timestamp: 2026-07-09T00:00:00Z
id: skill-team-curate
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

Scan execution traces to identify reusable team patterns, decisions, and conventions, then propose each candidate as a Context Directive Record (CDR) draft.

## When to Use

- After a work session that produced execution traces
- When reviewing traces for recurring team patterns
- When preparing governance content for the team-ai-directives repository
- Before running `team-evolve` to review proposed CDRs

## Core Pattern

1. **Discover** — list and read `{REPO_ROOT}/traces/*.md`
2. **Dedup** — check `{TEAM_DIRECTIVES}/CDR.md` for existing entries
3. **Draft** — write CDR entries to `{REPO_ROOT}/.specify/drafts/cdr.md`
4. **Summarize** — report trace counts, proposed CDRs, duplicates skipped, and next steps

## Quick Reference

| Signal | CDR Type |
|--------|----------|
| Decision | Rule |
| Pattern | Rule |
| Persona | Persona |
| Example | Example |
| Gap | Rule |
| Inconsistency | Inconsistency |

## Common Mistakes

- Proposing project-specific configuration as team-wide rules
- Drafting duplicates of existing CDRs
- Capturing patterns without concrete trace evidence
- Writing CDRs for trivial or obvious conventions
