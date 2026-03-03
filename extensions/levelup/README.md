# LevelUp Extension

Discover and contribute context modules (rules, personas, examples, skills) to team-ai-directives using Context Decision Records (CDRs).

## Overview

The LevelUp extension helps brownfield projects analyze their codebase and contribute reusable context modules back to the team's shared AI directives repository. It introduces **Context Decision Records (CDRs)** - similar to Architecture Decision Records (ADRs) - for tracking what, why, and how context is being contributed.

## Commands

| Command | Purpose |
|---------|---------|
| `/levelup.init` | Scan codebase and discover CDRs (like `/architect.init`) |
| `/levelup.clarify` | Resolve ambiguities in discovered CDRs (like `/architect.clarify`) |
| `/levelup.spec` | Refine CDRs using current feature spec context |
| `/levelup.skills` | Build a single skill from accepted CDRs |
| `/levelup.implement` | Compile accepted CDRs into a PR to team-ai-directives |

## Quick Start

### 1. Initialize CDR Discovery

Scan your codebase for patterns that could become team-wide directives:

```bash
/levelup.init
```

This creates CDRs in `.specify/memory/cdr.md` with status "Discovered".

### 2. Clarify and Accept CDRs

Review discovered CDRs and resolve ambiguities:

```bash
/levelup.clarify
```

This validates patterns and updates CDR statuses to "Accepted" or "Rejected".

### 3. Build Skills (Optional)

Build a skill from accepted CDRs:

```bash
/levelup.skills python-error-handling
```

This creates a skill in `.specify/drafts/skills/`.

### 4. Create PR

Compile accepted CDRs into a PR to team-ai-directives:

```bash
/levelup.implement
```

This creates a draft PR with all accepted contributions.

## Context Decision Records (CDRs)

CDRs are stored in `.specify/memory/cdr.md` and track:

- **Target Module**: Where the contribution goes in team-ai-directives
- **Context Type**: Rule, Persona, Example, Constitution Amendment, or Skill
- **Status**: Discovered → Proposed → Accepted/Rejected → Implemented
- **Evidence**: Links to code, commits, and discussions

### CDR Status Values

| Status | Description |
|--------|-------------|
| **Discovered** | Inferred from codebase during brownfield analysis |
| **Proposed** | Suggested for review, awaiting validation |
| **Accepted** | Approved for implementation |
| **Rejected** | Not accepted (reason documented) |
| **Implemented** | PR created to team-ai-directives |

## Configuration

### Team AI Directives Path

The extension resolves the team-ai-directives path in this order:

1. `SPECIFY_TEAM_DIRECTIVES` environment variable
2. `.specify/team-ai-directives` (submodule - recommended)
3. `.specify/memory/team-ai-directives` (clone - legacy)

### Extension Config

Optional configuration in `.specify/extensions/levelup/levelup-config.yml`:

```yaml
cdr:
  heuristic: "surprising"  # surprising | all | minimal
  location: ".specify/memory/cdr.md"

skills:
  drafts_location: ".specify/drafts/skills"

discovery:
  rules: true
  personas: true
  examples: true
  constitution: true
  skills: true

pull_request:
  draft: true
  branch_prefix: "levelup/"
  target_branch: "main"
```

## Command Flow

```
levelup.init          levelup.clarify        levelup.skills        levelup.implement
(Discover CDRs)  ───▶  (Resolve Ambiguities) ───▶ (Build Skills)  ───▶  (Create PR)
     │                      │                      │                      │
     │    [handoff]         │    [handoff]         │                      │
     └──▶ levelup.spec ◀────┘                      │                      │
          (Refine from                             │                      │
           feature context)                        │                      │
```

## Related Issues

- [#56](https://github.com/tikalk/agentic-sdlc-spec-kit/issues/56) - Feature request for this extension
- [#49](https://github.com/tikalk/agentic-sdlc-spec-kit/issues/49) - Skills discovery (format compatibility)
- [#53](https://github.com/tikalk/agentic-sdlc-spec-kit/issues/53) - Git submodule for team-ai-directives
- [#36](https://github.com/tikalk/agentic-sdlc-spec-kit/issues/36) - Convert architect commands to extension (pattern reference)

## License

MIT
