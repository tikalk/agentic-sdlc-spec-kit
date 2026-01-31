---
description: Manage workflow modes and framework options for development complexity control
scripts:
    sh: echo "Mode management is handled by the specify CLI directly"
    ps: echo "Mode management is handled by the specify CLI directly"
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Control the complexity level of the Agentic SDLC workflow by setting workflow modes and configuring framework options.

## Operating Constraints

**Mode Management**: Workflow modes control overall development complexity (build vs spec)

**Option Management**: Framework options control which architectural patterns are enabled

**Configuration Persistence**: Settings are stored in `.specify/config/config.json` under the `workflow` and `options` sections

## Execution Steps

### 1. Parse User Input

**Command Patterns:**

- No arguments: Display current mode and option settings
- `build|spec`: Switch to specified workflow mode
- `--tdd|--no-tdd`: Enable/disable TDD
- `--contracts|--no-contracts`: Enable/disable API contracts
- `--data-models|--no-data-models`: Enable/disable data models
- `--risk-tests|--no-risk-tests`: Enable/disable risk-based test generation
- `--reset-options`: Reset options to current mode defaults
- `--info`: Show detailed information about all modes and options

### 2. Execute Operation

#### Display Current Configuration

- Show current workflow mode (build/spec)
- Display framework option settings
- Indicate which settings are defaults vs customizations

#### Switch Workflow Mode

- Change from current mode to specified mode
- Automatically reset options to new mode defaults
- Preserve mode change history

#### Configure Options

- Enable/disable individual framework options
- Persist custom settings in the `options` section of config.json
- Allow fine-grained control over development patterns

#### Reset Options

- Restore options to current mode's default settings
- Clear any custom option overrides

### 3. Show Impact

After any configuration change, display:

- How the change affects workflow stages
- Which artifacts will be generated differently
- Recommendations for the new configuration

## Output Format

### Current Configuration Display

```text
Current Workflow Configuration
Mode: spec
Description: Full specification-driven workflow with comprehensive planning and structure
Default: Yes

Framework Options
  ✅ TDD: Enabled (mode default)
  ❌ API contracts: Disabled (custom)
  ❌ Data models: Disabled (custom)
  ❌ Risk-based testing: Disabled (custom)
```

### Mode Change Confirmation

```text
Workflow mode changed!
From: build → To: spec
Framework options reset to spec mode defaults
```

### Opinion Change Confirmation

```text
TDD enabled
API contracts disabled
Data models disabled
Risk-based testing disabled
```

## Mode Descriptions

### Build Mode (GSD - Get Sh*t Done)

#### High-velocity execution for fast iteration and trusted autonomy

- **Framework options**: All disabled by default
- **Review gates**: Non-blocking post-hoc (no real-time approval checkpoints)
- **Atomic commits**: Self-contained, independently reviewable commits
- **Documentation**: Spec-only workflow (plan.md/tasks.md optional)
- **Focus**: Rapid iteration, quick wins, senior engineer autonomy
- **Artifacts**: Minimal docs, fast feedback loops, atomic git history
- **Best for**: Individual developers, lead engineers, rapid exploration

### Spec Mode

#### Comprehensive specification-driven workflow with deliberate planning

- **Framework options**: All enabled by default (TDD, contracts, data models, risk tests)
- **Review gates**: Blocking real-time approval checkpoints (micro-review)
- **Quality thresholds**: 80%/60% coverage requirements enforced
- **Documentation**: Complete workflow (spec → plan → tasks → implement)
- **Focus**: Thorough planning, team coordination, structured development
- **Artifacts**: Comprehensive docs, validated quality gates, full traceability
- **Best for**: Feature teams, complex systems, collaborative development

### Architecture Support (Available in All Modes)

Architecture documentation is optional and available in both build and spec modes:

- `/speckit.architect` commands work in any mode without warnings
- `/speckit.constitution` available for project principles
- Files loaded automatically if present, ignored if missing
- Use `/speckit.architect init` to generate comprehensive architecture description (Rozanski & Woods methodology)
- Use `/speckit.architect map` to reverse-engineer architecture from existing code (brownfield projects)
- Key artifact: `memory/architecture.md` (7 viewpoints + 2 perspectives)

## Framework Options

### TDD (Test-Driven Development)

- **Enabled**: Tests generated before implementation tasks
- **Disabled**: Tests optional, generated only when explicitly requested
- **Impact**: Affects task generation and implementation ordering

### API Contracts

- **Enabled**: OpenAPI/GraphQL contract generation during planning
- **Disabled**: Contract artifacts not automatically created
- **Impact**: Affects planning phase output and API documentation

### Data Models

- **Enabled**: Entity and relationship modeling during planning
- **Disabled**: Data model artifacts not automatically created
- **Impact**: Affects planning phase output and data architecture

### Risk-Based Testing

- **Enabled**: Generate tests specifically targeting identified risks and edge cases
- **Disabled**: Use standard test coverage without risk prioritization
- **Impact**: Affects task generation and test planning in tasks.md

## Context

{ARGS}
