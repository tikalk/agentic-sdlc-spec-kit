---
type: Skill
name: team-repair
title: Team Repair
description: "Use when re-indexing CDR.md, .skills.json, and AGENTS.md in team-ai-directives to fix inconsistencies, detect orphaned files, or auto-repair metadata."
tags: [governance, repair, indexing]
timestamp: 2026-07-09T00:00:00Z
id: skill-team-repair
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

Repair the team-ai-directives knowledge base indexes. Detect orphan files, rebuild CDR.md and .skills.json, and restore AGENTS.md from the canonical template.

## When to Use

- CDR.md, .skills.json, or AGENTS.md appear stale or inconsistent.
- A context module or skill file lacks frontmatter or a manifest entry.
- After bulk imports, moves, or manual edits to the knowledge base.

## Core Pattern

1. Resolve `team_ai_directives` from `.specify/init-options.json`.
2. Scan `context_modules/` and `skills/` for orphan files.
3. Repair AGENTS.md from `templates/agents-template.md` if missing or corrupted.
4. Rebuild `CDR.md` from scanned context modules.
5. Rebuild `.skills.json` from scanned skills.
6. Report the actions taken.

## Quick Reference

| Flag | Effect |
|---|---|
| (default) | Repair all indexes |
| `--dry-run` | Report only, do not write |
| `--cdr-only` | Only repair CDR.md |
| `--skills-only` | Only repair .skills.json |
| `--agents-only` | Only repair AGENTS.md |

## Common Mistakes

- Running in a directory without `team_ai_directives` configured.
- Overwriting hand-edited CDR descriptors because orphans were not reviewed first.
- Forgetting `--dry-run` before a risky repair.
