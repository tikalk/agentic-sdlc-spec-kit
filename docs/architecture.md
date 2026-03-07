# Architecture Workflow

This guide explains how to document and maintain software architecture using the Architect extension.

## Overview

The Architect extension provides a complete workflow for managing software architecture:

- **ADRs (Architecture Decision Records)** - Document why decisions were made
- **AD.md (Architecture Description)** - Document what the system looks like

This follows the [Rozanski & Woods](https://www.viewpoints-and-perspectives.info/) methodology for comprehensive architecture documentation.

## Installation

The Architect extension is bundled and auto-installed during `specify init`. No manual installation needed.

To add it to an existing project:

```bash
specify extension add architect
```

## Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/architect.init` | Discover ADRs from existing code | Brownfield projects |
| `/architect.specify` | Create ADRs from requirements | Greenfield projects |
| `/architect.clarify` | Refine and validate ADRs | After init or specify |
| `/architect.implement` | Generate AD.md from ADRs | After ADRs are refined |
| `/architect.analyze` | Validate consistency | After any changes |

## Workflows

### Brownfield (Existing Codebase)

For projects with existing code but no architecture documentation:

```bash
# 1. Discover decisions from code
/architect.init "Python FastAPI backend with PostgreSQL"

# 2. Validate discovered ADRs
/architect.clarify

# 3. Generate Architecture Description
/architect.implement

# 4. Verify consistency
/architect.analyze
```

### Greenfield (New Project)

For new projects starting from requirements:

```bash
# 1. Create ADRs from PRD/requirements
/architect.specify "B2B SaaS platform for supply chain"

# 2. Refine decisions through questions
/architect.clarify

# 3. Generate Architecture Description
/architect.implement

# 4. Verify consistency
/architect.analyze
```

## Command Flow

```
Brownfield:   /architect.init --> /architect.clarify --> /architect.implement --> /architect.analyze
                                        ^                        |                        |
                                        +------------------------+------------------------+
                                                     (iterate on findings)

Greenfield:   /architect.specify --> /architect.clarify --> /architect.implement --> /architect.analyze
```

## Architecture Files

| File | Location | Purpose |
|------|----------|---------|
| System ADRs | `.specify/memory/adr.md` | Architecture Decision Records |
| System AD | `AD.md` (project root) | Full Architecture Description |
| Feature ADRs | `specs/{feature}/adr.md` | Feature-level decisions |
| Feature AD | `specs/{feature}/AD.md` | Feature-level architecture |
| Constitution | `.specify/memory/constitution.md` | Governance principles |

## ADR Format (MADR)

Architecture Decision Records follow the [MADR](https://adr.github.io/madr/) format:

```markdown
### ADR-001: [Decision Title]

#### Status
Proposed | Accepted | Deprecated | Superseded by ADR-XXX | Discovered

#### Date
YYYY-MM-DD

#### Context
What is the issue we're addressing?

#### Decision
What did we decide?

#### Consequences
##### Positive
- Benefits

##### Negative
- Trade-offs

#### Common Alternatives
##### Option A: [Name]
**Description**: Brief description
**Trade-offs**: Neutral comparison
```

## AD.md Structure (Rozanski & Woods)

The Architecture Description follows Rozanski & Woods with 7 viewpoints:

### Core Views (Always Generated)

1. **Context View (3.1)** - System scope and external interactions
2. **Functional View (3.2)** - Internal components and responsibilities
3. **Information View (3.3)** - Data storage and management
4. **Development View (3.5)** - Code organization and CI/CD
5. **Deployment View (3.6)** - Physical environment and infrastructure

### Optional Views

6. **Concurrency View (3.4)** - Runtime processes and threads
7. **Operational View (3.7)** - Operations and maintenance

### Perspectives

- **Security Perspective (4.1)** - Security considerations
- **Performance Perspective (4.2)** - Performance and scalability

## Using /architect.analyze

The analyze command validates consistency between ADRs and AD.md:

### Detection Passes

| Pass | What it Checks |
|------|----------------|
| A | ADR quality (completeness, clarity) |
| B | Inter-ADR consistency (conflicts, terminology) |
| C | ADR -> AD drift (decisions not in AD) |
| D | AD -> ADR drift (components without ADRs) |
| E | AD internal consistency (views align) |
| F | Staleness (placeholders, deprecated refs) |
| G | Feature-system alignment |

### Severity Levels

- **CRITICAL** - Constitution violations, security gaps
- **HIGH** - ADR-AD drift, conflicting decisions
- **MEDIUM** - Incomplete documentation, staleness
- **LOW** - Style improvements, minor gaps

### Example Output

```markdown
## Architecture Analysis Report

### Findings
| ID | Pass | Severity | Location | Summary |
|----|------|----------|----------|---------|
| C1 | ADR->AD Drift | HIGH | ADR-005 | Caching not in Info View |
| D1 | AD->ADR Drift | HIGH | AD.md:3.2 | Redis has no ADR |

### Next Actions
- Run `/architect.clarify` for ADR quality issues
- Run `/architect.implement` to sync AD.md
```

## Integration with Spec Workflow

Architecture commands work alongside specification commands via extension hooks:

```
/architect.specify --> /architect.clarify --> /architect.implement
                                                       |
                                                       v
                    /architect extension hooks (before_plan / after_plan)
                                                       |
                                                       v
/spec.specify --> /spec.plan --> /spec.tasks --> /spec.implement
```

**Architecture Workflow** (architect extension hooks):

| Hook | Timing | Purpose |
|------|--------|---------|
| **before_plan** | Before plan generation | Create feature ADRs using architect.specify/clarify/implement |
| **after_plan** | After plan generation | Validate plan alignment using architect.validate --for-plan (READ-ONLY) |
| **Activation** | adr.md exists | Hooks only fire if `.specify/memory/adr.md` present |

**Feature Architecture Generation**:

- Manual: Run `/architect.specify` → `/architect.clarify` → `/architect.implement` to create feature ADRs and AD.md
- Automatic: architect extension before_plan hook executes same commands when adr.md exists
- Validation: architect extension after_plan hook validates plan alignment with architecture (READ-ONLY via architect.validate)

## Configuration

Optional configuration in `.specify/extensions/architect/architect-config.yml`:

```yaml
adr:
  heuristic: "surprising"  # surprising | all | minimal
  location: ".specify/memory/adr.md"

views:
  default: "core"  # core | all | concurrency,operational

analysis:
  max_findings: 50
  block_on_critical: true
```

## Best Practices

1. **Start with ADRs** - Document decisions before generating AD.md
2. **Run analyze regularly** - Detect drift early
3. **Keep ADRs focused** - One decision per ADR
4. **Use neutral alternatives** - Don't bias toward rejected options
5. **Link to constitution** - Show alignment with principles

## Related

- [Quick Start Guide](quickstart.md) - Overall workflow
- [Rozanski & Woods](https://www.viewpoints-and-perspectives.info/) - Architecture methodology
- [MADR](https://adr.github.io/madr/) - ADR format specification
