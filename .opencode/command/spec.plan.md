---
description: Execute the implementation planning workflow using the plan template
  to generate design artifacts.
handoffs:
- label: Create Tasks
  agent: adlc.spec.tasks
  prompt: Break the plan into tasks
  send: true
- label: Create Checklist
  agent: adlc.spec.checklist
  prompt: Create a checklist for the following domain...
scripts:
  sh: .specify/scripts/bash/setup-plan.sh --json
  ps: .specify/scripts/powershell/setup-plan.ps1 -Json
agent_scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---


<!-- Source: agentic-sdlc -->
## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

### Parameters

Parse the following parameters from `$ARGUMENTS`:

## Pre-Execution Hooks

**Check for extension hooks (before planning)**:
- Check if `{REPO_ROOT}/.specify/extensions.yml` exists in the project root
- If it exists, read it and look for entries under the `hooks.before_plan` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For hooks with conditions, skip condition evaluation (leave to HookExecutor)
- For hooks without conditions, treat as executable

**For each executable hook**:
- **Optional hook** (`optional: true`):
  ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    This is an optional hook. You can choose to skip it.
  ```
  Wait for the result of the hook command before proceeding to the Outline.

- **Mandatory hook** (`optional: false`):
  ```
    ## Extension Hooks

    **Mandatory Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    This is a mandatory hook. Waiting for completion...
  ```
  The hook MUST complete before proceeding to the next step.

- If no hooks are registered or `{REPO_ROOT}/.specify/extensions.yml` does not exist, skip silently

**Note on Architecture Integration**:
- If architect extension registered and adr.md exists, before_plan hook may create feature ADRs
- Command: `/architect.specify` or `/architect.init` (greenfield vs brownfield)
- Purpose: Generate feature-specific ADRs for architectural consistency
- Note: Architecture validation happens in after_plan hook (not at this stage)

## Role & Context

You are a **Technical Planning Architect** responsible for transforming feature specifications into executable implementation plans. Your role involves:

- **Analyzing** feature requirements and technical constraints
- **Designing** system architecture and component interactions
- **Ensuring** constitutional compliance throughout planning
- **Coordinating** research, design, and validation activities

**Key Principles:**

- Plans must be testable and implementable
- Unknowns require research before commitment
- Constitution governs all technical decisions
- Quality gates prevent premature advancement

## Input Processing

```text
$ARGUMENTS
```

**Input Processing:** The user input represents feature context or planning directives. Analyze for:

- Specific planning requirements or constraints
- Technical preferences or architectural decisions
- Timeline or resource considerations
- Quality or compliance requirements

## Outline (MANDATORY EXECUTION STEPS)

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`. Load IMPL_PLAN template (already copied by setup script).

3. **Execute plan workflow** (CREATE ALL ARTIFACTS):
   - Fill plan.md Technical Context section (mark unknowns as "NEEDS CLARIFICATION")
   - Fill plan.md Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - **Phase 0: CREATE research.md** - Resolve all NEEDS CLARIFICATION via research
   - **Phase 1: CREATE data-model.md** - Extract entities from feature spec
   - **Phase 1: CREATE contracts/** directory with API endpoint definitions (if project has external interfaces)
   - **Phase 1: CREATE quickstart.md** - Developer setup guide
   - **Phase 1: RUN agent context update** - Execute `{AGENT_SCRIPT}` to update agent-specific files
   - Re-evaluate Constitution Check post-design in plan.md

4. **Stop and report**: Command ends after Phase 1 completion. Report branch, IMPL_PLAN path, and all generated artifacts (research.md, data-model.md, contracts/, quickstart.md).

## Execution Strategy

**Chain of Thought Approach:**

1. **Establish Context** → Load specifications and constitutional requirements
2. **Analyze Scope** → Identify technical unknowns and research needs
3. **Design Architecture** → Create system models and component definitions
4. **Validate Compliance** → Ensure constitutional alignment
5. **Generate Artifacts** → Produce implementation-ready documentation

## CRITICAL - Path Validation

**DO NOT write to project root directory**
- Parse `IMPL_PLAN` from script JSON output (from `.specify/scripts/bash/setup-plan.sh --json`)
- Write ONLY to `IMPL_PLAN` path - never to `./plan.md`
- The correct path is: `./specs/<BRANCH>/plan.md` (e.g., `./specs/001-user-auth/plan.md`)
- Common mistake: Writing to `./plan.md` instead of `./specs/001-user-auth/plan.md`

**Non-Git Repository Support:**
- If working in a non-git repository, ensure `SPECIFY_FEATURE` environment variable is set (from `/spec.specify`)
- Without this, the script may fail to find the correct feature directory

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
    - Entity name, fields, relationships
    - Validation rules from requirements
    - State transitions if applicable

2. **Define interface contracts** (if project has external interfaces) → `/contracts/`:
    - Identify what interfaces the project exposes to users or other systems
    - Document the contract format appropriate for the project type
    - Examples: public APIs for libraries, command schemas for CLI tools, endpoints for web services, grammars for parsers, UI contracts for applications
    - Skip if project is purely internal (build scripts, one-off tools, etc.)

3. **Agent context update**:
    - Run `{AGENT_SCRIPT}`
    - These scripts detect which AI agent is in use
    - Update the appropriate agent-specific context file
    - Add only new technology from current plan
    - Preserve manual additions between markers

**Output**: data-model.md, /contracts/* (if external interfaces), quickstart.md, agent-specific file

## Triage Framework: [SYNC] vs [ASYNC] Task Classification

**Purpose**: Classify implementation tasks as [SYNC] (human-reviewed) or [ASYNC] (agent-delegated).

**[SYNC] - Human Execution Required:**
- Complex business logic, algorithms, state machines
- Security-critical code (auth, encryption, data protection)
- External integrations, third-party APIs
- Architectural decisions, component boundaries
- High-risk changes (schema, API contracts, breaking changes)

**[ASYNC] - Agent Delegation Suitable:**
- Well-defined CRUD operations with clear schemas
- Boilerplate code, standard library usage
- Independent components with minimal dependencies
- Standard framework/library patterns
- Testable units with comprehensive test coverage

**Triage Output in plan.md:**
Document each task with: Classification ([SYNC]/[ASYNC]), Primary Criteria, Risk Level, Rationale

## Key Rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications
- **TRIAGE REQUIREMENT**: All implementation tasks must be classified as [SYNC] or [ASYNC] with documented rationale
- Comprehensive research required before design decisions
- Full constitutional compliance validation
- Detailed triage analysis for all tasks
- Complete design artifacts and validation

**Planning Approach:**

- Comprehensive research-driven planning with full validation
- Detailed technical analysis and constitutional compliance
- Complete design artifacts and thorough triage

**Architecture Integration Note**:
- If architect extension is configured, hooks will handle feature architecture automatically
- Plan command focuses on research, data modeling, and contracts generation
- Architecture artifacts (adr.md, AD.md) are managed by architect extension hooks

### AI-Powered Context/Skills Refresh (Always Enabled)

**When feature scope changes during planning:**

1. **Re-run discovery** (same approach as /specify)
   - Extract keywords from updated plan requirements
   - AI semantic search (not grep-based)
   - Update candidates with new relevant items

2. **Merge with existing selections**
   - Keep manually selected directives and skills
   - Append newly discovered items
   - On conflicts: Keep higher confidence score, annotate the change

**Detection logic**: Use same AI semantic approach as /specify command to ensure consistency.


## Post-Execution Hooks

**Check for extension hooks (after planning)**:
- After plan is generated, check if `{REPO_ROOT}/.specify/extensions.yml` exists in the project root
- If it exists, read it and look for entries under the `hooks.after_plan` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.

**For each executable hook**:
- **Optional hook** (`optional: true`):
  ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Would you like to run this optional hook? (Y/n)
  ```

- **Mandatory hook** (`optional: false`):
  ```
    ## Extension Hooks

    **Mandatory Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Running mandatory hook...
  ```

- Wait for hook command completion
- If no hooks are registered or `{REPO_ROOT}/.specify/extensions.yml` does not exist, skip silently

**Note on Architecture Validation**:
- If architect extension registered and adr.md exists, after_plan hook may validate architecture:
  - `/architect.validate --for-plan --json` (READ-ONLY)
  - Parse JSON findings: blocking, high-severity, warnings
  - Document validation report in plan.md
  - BLOCK task generation if BLOCKING issues found
  - Continue if only MEDIUM/LOW issues