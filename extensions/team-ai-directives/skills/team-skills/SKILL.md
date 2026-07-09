---
type: Skill
name: team-skills
title: Team Skills
description: "Use when browsing available team skills in the knowledge base and installing selected capabilities to the current agent's skills directory."
tags: [governance, skills, installation]
timestamp: 2026-07-09T00:00:00Z
id: skill-team-skills
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

Browse the team-ai-directives knowledge base and install selected skills into the current agent's skills directory. The skill reads the team configuration, presents available capabilities grouped by policy, and copies the chosen SKILL.md files.

## When to Use

Use this skill when the user asks to browse team skills, install a team capability, or add a skill from the team AI directives repository.

## Core Pattern

1. Read `.specify/init-options.json` and extract `team_ai_directives`. If missing, stop and tell the user to run `specify init --team-ai-directives <path-or-url>`.
2. Read `{TEAM_DIRECTIVES}/.skills.json`.
3. Parse the manifest and group entries by policy:
   - `default` — installed automatically during project init
   - `external` — available on demand from the team KB
   - `blocked` — never install
4. Present skills grouped by policy. For each skill show its key, description, tags, and whether it is already installed in the agent's skills directory.
5. If the user supplied a skill name, install it directly. Otherwise ask which skills to install.
6. Copy `{TEAM_DIRECTIVES}/skills/{name}/SKILL.md` to the agent's skills directory (for example `.claude/skills/{name}/SKILL.md`). Use the agent's folder from `.specify/integration.json`. Do not rename the skill or add a `team-` prefix.
7. Confirm the installed skill name, destination path, and source.

## Quick Reference

| Policy | Install behavior |
|---|---|
| `default` | Already installed during init; may be reinstalled if requested |
| `external` | Install on demand from `{TEAM_DIRECTIVES}/skills/{name}/SKILL.md` |
| `blocked` | Never install |

## Common Mistakes

- Prefixing installed skills with `team-`. The KB name is final; copy it unchanged.
- Installing blocked skills.
- Guessing the team path instead of reading `.specify/init-options.json`.
