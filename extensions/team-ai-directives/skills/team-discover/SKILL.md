---
type: Skill
name: team-discover
title: Team Discover
description: "Use when specifying or planning a new feature or change, before writing implementation plans, to discover relevant team personas, rules, examples, and skills."
tags: [governance, discovery, context-modules]
timestamp: 2026-07-09T00:00:00Z
id: skill-team-discover
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

Discover team-ai-directives modules for a feature. Surface personas, rules, examples, and skills aligned with team standards.

## When to Use

- Starting or refactoring a feature.
- Before implementation, tests, or interfaces.

## Core Pattern

1. Locate `team_ai_directives` via `.specify/init-options.json`.
2. Extract domain, technology, patterns, and actions from the feature.
3. Read `CDR.md`, falling back to `context_modules/`.
4. Match modules by descriptor, path, and type; load high-relevance bodies.
5. Output a table and persist to `team-context.md` unless `--no-write` is set.

## Quick Reference

- Artifact: `team-context.md`
- Surface: `CDR.md` index, fallback `context_modules/`
- Relevance: High / Medium / Low

## Common Mistakes

- Skipping discovery and missing team rules.
- Scanning every file instead of the CDR index.
- Writing files when `--no-write` is set.
