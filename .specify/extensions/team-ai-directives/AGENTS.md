# Agent Instructions

This repository contains reusable AI agent directives.

## Installation Locations

When installed as a spec-kit extension (recommended), this repo lives at:
- `.specify/extensions/team-ai-directives/`

When cloned directly, this repo lives at the project root or configured path.

## Structure

- `context_modules/constitution.md` - Core principles (always load)
- `context_modules/personas/` - Role-specific guidance
- `context_modules/rules/` - Domain-specific patterns
- `context_modules_examples/` - Code examples and prompt templates
- `skills/` - Self-contained capabilities
- `.skills.json` - Skills registry and policy
- `CDR.md` - Context Directive Records (approved contributions)

## Loading Order

1. Constitution (foundational principles) — from `context_modules/constitution.md`
2. Relevant persona (based on task context) — from `context_modules/personas/`
3. Skill (triggered by user request) — from `skills/`

## Context Directive Records (CDR.md)

CDR.md tracks approved contributions to team-ai-directives from various projects.

### CDR Index

| ID | Target Module | Context Type | Status | Date | Source |
|----|---------------|--------------|--------|------|--------|

### Status Values

| Status | Description |
|--------|-------------|
| **Accepted** | Approved for inclusion in team-ai-directives |
| **Rejected** | Not accepted (reason documented in CDR) |

### Finding Context Modules

1. Explore `context_modules/` directories directly
2. Check `CDR.md` for approved contributions from projects

## Using Skills

Skills are in `skills/{skill-name}/`:

- `SKILL.md` - Read this first (has trigger keywords in description)
- `references/` - Supporting content (load on-demand)
- `scripts/` - Automation (if present)

To find relevant skills:

1. Check `.skills.json` for available skills
2. Match user request to skill descriptions
3. Load SKILL.md when triggered

## Using Rules

Rules are in `context_modules/rules/{domain}/`. Access them via:

1. Persona Rule References sections
2. Direct exploration of rules directory

## External Skills

`.skills.json` registry section lists external skills. Fetch via URL when needed.
