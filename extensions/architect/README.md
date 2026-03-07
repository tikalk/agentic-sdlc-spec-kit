# Architect Extension

Create and manage Architecture Decision Records (ADRs) and Architecture Descriptions (AD.md) using Rozanski & Woods methodology.

## Overview

The Architect extension provides a complete workflow for documenting and maintaining software architecture:

- **ADRs (Architecture Decision Records)** - Track why decisions were made
- **AD.md (Architecture Description)** - Document what the system looks like

## Commands

| Command | Purpose |
|---------|---------|
| `/architect.init` | Reverse-engineer ADRs from existing codebase (brownfield) |
| `/architect.specify` | Interactive PRD exploration to create ADRs (greenfield) |
| `/architect.clarify` | Refine and validate ADRs through questions |
| `/architect.implement` | Generate AD.md from ADRs (Rozanski & Woods) |
| `/architect.analyze` | Validate ADR to AD consistency and quality |
| `/architect.validate --for-plan` | Validate plan alignment with architecture (READ-ONLY) |

## Quick Start

### Brownfield (Existing Codebase)

```bash
/architect.init        # Discover ADRs from code
/architect.clarify     # Validate discovered ADRs
/architect.implement   # Generate AD.md
/architect.analyze     # Verify consistency
```

### Greenfield (New Project)

```bash
/architect.specify     # Create ADRs from PRD
/architect.clarify     # Refine ADRs
/architect.implement   # Generate AD.md
/architect.analyze     # Verify consistency
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
| System AD | `AD.md` (root) | Full Architecture Description |
| Feature ADRs | `specs/{feature}/adr.md` | Feature-level decisions |
| Feature AD | `specs/{feature}/AD.md` | Feature-level architecture |

## Installation

The architect extension is **bundled by default** during project initialization:

```bash
specify init my-project
```

For manual installation:

```bash
specify extension add architect
```

## Using /architect.analyze

The analyze command validates consistency between ADRs and AD.md:

### Detection Passes

| Pass | What it Checks |
|------|----------------|
| A | ADR quality (completeness, clarity) |
| B | Inter-ADR consistency (conflicts, terminology) |
| C | ADR to AD drift (decisions not in AD) |
| D | AD to ADR drift (components without ADRs) |
| E | AD internal consistency (views align) |
| F | Staleness (placeholders, deprecated refs) |
| G | Feature-system alignment |

### Severity Levels

- **CRITICAL** - Constitution violations, security gaps
- **HIGH** - ADR to AD drift, conflicting decisions
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
- Run /architect.clarify for ADR quality issues
- Run /architect.implement to sync AD.md
```

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

## ADR Format (MADR)

Architecture Decision Records follow the MADR format:

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

## Integration with Spec Workflow

Architecture works with specification commands via extension hooks:

```
/architect.specify --> /architect.clarify --> /architect.implement
                                                      |
                                                      v
                     architect extension hooks (before_plan / after_plan)
                                                      |
                                                      v
/spec.specify --> /spec.plan --> /spec.tasks --> /spec.implement
```

**Hooks only execute when `.specify/memory/adr.md` exists (architecture detection)**

| Hook | When it Runs | Command | Purpose |
|------|--------------|---------|---------|
| `before_plan` | Before plan generation | `adlc.architect.specify` | Create feature-level ADRs and AD.md |
| `after_plan` | After plan generation | `adlc.architect.validate` | Validate plan alignment (READ-ONLY) |

### Using /architect.validate

The validate command checks plan alignment with architecture:

- **Flags**: `--for-plan`, `--json`, `--system-only`, `--check-only [check]`
- **Returned Findings**:
  - `blocking` - Critical issues that must be fixed
  - `high_severity` - Issues that should be fixed
  - `warnings` - Recommendations
- **7 PILLAR Checks**:
  - PILLAR_1: Component ADR alignment
  - PILLAR_2: Interface contracts
  - PILLAR_3: Data model consistency
  - PILLAR_4: System context alignment
  - PILLAR_5: Functional consistency
  - PILLAR_6: Information view alignment
  - PILLAR_7: Development view alignment
- **Diagram Consistency**: System boundaries and data flows

The command is READ-ONLY and skips gracefully if no architecture exists.

## Related

- [Rozanski & Woods](https://www.viewpoints-and-perspectives.info/) - Architecture methodology
- [MADR](https://adr.github.io/madr/) - Markdown ADR format
- Issue #36 - Original feature request

## License

MIT
