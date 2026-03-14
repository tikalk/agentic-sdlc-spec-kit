# LevelUp Extension

Discover and contribute context modules (rules, personas, examples, skills) to team-ai-directives using Context Directive Records (CDRs).

## Overview

The LevelUp extension helps brownfield projects analyze their codebase and contribute reusable context modules back to the team's shared AI directives repository. It introduces **Context Directive Records (CDRs)** - similar to Architecture Decision Records (ADRs) - for tracking what, why, and how context is being contributed.

## Commands

| Command | Purpose |
|---------|---------|
| `/levelup.init` | Scan codebase and discover CDRs (like `/architect.init`) |
| `/levelup.clarify` | Resolve ambiguities in discovered CDRs (like `/architect.clarify`) |
| `/levelup.specify` | Refine CDRs using current feature spec context |
| `/levelup.skills` | Build a single skill from accepted CDRs |
| `/levelup.implement` | Compile accepted CDRs into a PR to team-ai-directives |
| `/levelup.trace` | Generate and validate AI session execution traces |

## Quick Start

### 1. Generate Session Trace (Optional but Recommended)

After implementing a feature, generate a trace to document the session:

```bash
/levelup.trace
```

This creates `specs/{BRANCH}/trace.md` with execution summary.

### 2. Initialize CDR Discovery

Scan your codebase for patterns that could become team-wide directives:

```bash
/levelup.init
```

This creates proposed CDRs in `{PROJECT}/.specify/drafts/cdr.md` with status "Discovered" or "Proposed".

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

## Context Directive Records (CDRs)

CDRs are stored in markdown format:

- **Local**: `{PROJECT}/.specify/drafts/cdr.md` - Working copy during discovery/clarification
- **Approved**: `{TEAM_DIRECTIVES}/CDR.md` - Approved contributions tracked in team-ai-directives

CDRs define:

- **Target Module**: Where the contribution goes in team-ai-directives
- **Context Type**: Rule, Persona, Example, or Skill
- **Status**: Discovered → Proposed → Accepted | Rejected

### CDR Status Values

| Status | Description |
|--------|-------------|
| **Discovered** | Inferred from codebase during brownfield analysis |
| **Proposed** | Suggested for review, awaiting validation |
| **Accepted** | Approved for implementation |
| **Rejected** | Not approved (reason documented in CDR) |

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
  # CDR file location (local project)
  location: ".specify/drafts/cdr.md"

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
(Discover CDRs)  ───▶  (Resolve Ambiguities) ───▶ (Build Skills)  ───▶ (Create PR)
     │                      │                      │                      │
     │    [handoff]         │    [handoff]         │                      │
     └──▶ levelup.specify ◀────┘                      │                      │
           (Refine from                             │                      │
            feature context)                        │                      │
                                                     │                      │
                    ┌───────────────────────────────┘                      │
                    │                                                      │
                    ▼                                                      │
             levelup.trace ◀───────────────────────────────────────────────┘
             (Generate Trace)
                    │
                    │ [handoff]
                    ▼
             levelup.specify
             (Extract CDRs with
              trace enrichment)
```
levelup.init          levelup.clarify        levelup.skills        levelup.implement
(Discover CDRs)  ───▶  (Resolve Ambiguities) ───▶ (Build Skills)  ───▶  (Create PR)
     │                      │                      │                      │
     │    [handoff]         │    [handoff]         │                      │
     └──▶ levelup.specify ◀────┘                      │                      │
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
