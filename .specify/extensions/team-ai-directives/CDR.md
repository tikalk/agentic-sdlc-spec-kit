# Context Directive Records

Context Directive Records (CDRs) track approved contributions to team-ai-directives from various projects. CDRs document patterns, practices, and knowledge extracted from real-world implementations.

## CDR Index

| ID | Target Module | Context Type | Status | Date | Source |
|----|---------------|--------------|--------|------|--------|

---

## CDR Status Reference

| Status | Description |
|--------|-------------|
| **Accepted** | Approved for inclusion in team-ai-directives |
| **Rejected** | Not accepted (reason documented in CDR) |

## CDR Workflow

1. **Discovery**: Run `/levelup.init` in a project to discover patterns
2. **Clarification**: Run `/levelup.clarify` to validate and accept patterns
3. **Implementation**: Run `/levelup.implement` to create PR with:
   - Context modules (rules, personas, examples)
   - Skills (if applicable)
   - This CDR.md file with accepted CDRs

## CDR Format

Each CDR follows this structure:

```markdown
## CDR-{ID}: {Title}

### Status

**Accepted** | Rejected

### Date

YYYY-MM-DD

### Source

{project-name}

### Target Module

`context_modules/rules/{domain}/{file}.md`

### Context Type

Rule | Persona | Example | Constitution Amendment

### Context

Describe the problem being solved or the pattern being captured.

### Decision

State what context module will be added or modified.

### Evidence

Links to code, commits, or discussions that support this CDR.
```

---

*This file is maintained by the LevelUp workflow. CDRs are added through PRs from project contributions.*
