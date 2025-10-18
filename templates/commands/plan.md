---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
scripts:
    sh: scripts/bash/setup-plan.sh --json
    ps: scripts/powershell/setup-plan.ps1 -Json
agent_scripts:
    sh: scripts/bash/update-agent-context.sh __AGENT__
    ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

## Mode Detection

1. **Check Current Workflow Mode**: Determine if the user is in "build" or "spec" mode by checking the mode configuration file at `.specify/config/mode.json`. If the file doesn't exist or mode is not set, default to "spec" mode.

2. **Mode-Aware Behavior**:
   - **Build Mode**: Lightweight planning focused on core implementation approach and basic structure
   - **Spec Mode**: Full research-driven planning with comprehensive design artifacts and validation

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

## User Input

```text
$ARGUMENTS
```

**Input Processing:** The user input represents feature context or planning directives. Analyze for:
- Specific planning requirements or constraints
- Technical preferences or architectural decisions
- Timeline or resource considerations
- Quality or compliance requirements

## Execution Strategy (Mode-Aware)

**Chain of Thought Approach:**
1. **Establish Context** → Load specifications and constitutional requirements
2. **Analyze Scope** → Identify technical unknowns and research needs (mode-aware depth)
3. **Design Architecture** → Create system models and component definitions (mode-aware complexity)
4. **Validate Compliance** → Ensure constitutional alignment
5. **Generate Artifacts** → Produce implementation-ready documentation (mode-aware templates)

## Core Workflow (Mode-Aware)

### Phase 1: Planning Setup & Context Loading
**Objective:** Establish planning environment and load all required context

1. **Environment Initialization**
   - Execute: `{SCRIPT}` from repository root
   - Parse JSON output for: FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH
   - Validate all required paths exist and are accessible
   - Handle argument escaping for special characters

2. **Context Acquisition**
   - **Specification Loading:** Read FEATURE_SPEC for requirements and constraints
   - **Constitutional Loading:** Read `/memory/constitution.md` for governance rules
   - **Template Loading:** Load appropriate template based on mode
     - **Build Mode**: Use `plan-template-build.md` (lightweight structure)
     - **Spec Mode**: Use `plan-template.md` (full research-driven structure)
   - **Validation:** Ensure all context sources are available and consistent

### Phase 2: Technical Analysis & Research Planning
**Objective:** Identify technical scope and knowledge gaps requiring research

3. **Technical Context Mapping**
   - Extract technical requirements from feature specification
   - Identify technology stack and architectural patterns
   - Map integration points and external dependencies
   - **NEEDS CLARIFICATION Flag:** Mark unknowns preventing confident planning

4. **Constitutional Compliance Assessment**
   - Map feature requirements against constitution principles
   - Identify potential conflicts or additional requirements
   - Document compliance strategy and justification
   - **Gate Evaluation:** Block progression for unjustified violations

5. **Research Planning**
   - **Gap Analysis:** Convert NEEDS CLARIFICATION items to research tasks
   - **Dependency Research:** Plan investigation of critical integrations
   - **Best Practice Research:** Identify technology-specific recommendations
   - Generate research.md with prioritized investigation plan

## Detailed Phases (Mode-Aware)

### Build Mode Execution Flow
**Focus:** Lightweight planning for quick implementation and validation

1. **Core Implementation Approach**
   - Identify primary technology stack and architecture pattern
   - Define basic project structure (source directories, key components)
   - Document essential dependencies and integrations
   - Skip extensive research - use reasonable defaults and industry standards

2. **Basic Design Artifacts**
   - Create simplified data model (only essential entities)
   - Define core API contracts (main endpoints only)
   - Generate basic project structure documentation

3. **Implementation Readiness Check**
   - Validate core functionality is implementable
   - Ensure basic dependencies are identified
   - Confirm project structure supports feature scope

**Output**: plan.md with core implementation approach, basic data model, essential contracts

### Spec Mode Execution Flow
**Focus:** Comprehensive research-driven planning with full validation

#### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
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

#### Phase 1: Design & Contracts (Configurable)

**Prerequisites:** `research.md` complete

**Framework Opinions Check:**
- Check current mode and opinion settings via `/mode`
- Respect user configuration for contracts and data models

1. **Extract entities from feature spec** → `data-model.md` (if data models enabled):
    - Only generate if data models are enabled in current mode settings
    - Entity name, fields, relationships
    - Validation rules from requirements
    - State transitions if applicable

2. **Generate API contracts** from functional requirements (if contracts enabled):
    - Only generate if API contracts are enabled in current mode settings
    - For each user action → endpoint
    - Use standard REST/GraphQL patterns
    - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Agent context update**:
    - Run `{AGENT_SCRIPT}`
    - These scripts detect which AI agent is in use
    - Update the appropriate agent-specific context file
    - Add only new technology from current plan
    - Preserve manual additions between markers

**Output**: Conditionally generated artifacts based on mode opinion settings:
- data-model.md (if data models enabled)
- /contracts/* (if contracts enabled)
- quickstart.md, agent-specific file (always generated)

## Triage Framework: [SYNC] vs [ASYNC] Task Classification (Mode-Aware)

**Purpose**: Guide the classification of implementation tasks as [SYNC] (human-reviewed) or [ASYNC] (agent-delegated) to optimize execution efficiency and quality.

### Build Mode Triage
**Focus:** Simplified classification for lightweight execution
- Prioritize core functionality tasks as [SYNC]
- Delegate supporting tasks (boilerplate, standard patterns) as [ASYNC]
- Limit detailed triage analysis - focus on obvious complexity indicators

### Spec Mode Triage
**Focus:** Comprehensive classification with full validation

#### Triage Decision Framework

**Evaluate Each Implementation Task Against These Criteria:**

##### [SYNC] Classification (Human Execution Required)
- **Complex Business Logic**: Non-trivial algorithms, state machines, or domain-specific calculations
- **Architectural Decisions**: System design choices, component boundaries, or integration patterns
- **Security-Critical Code**: Authentication, authorization, encryption, or data protection
- **External Integrations**: Third-party APIs, legacy systems, or complex data transformations
- **Ambiguous Requirements**: Unclear specifications requiring interpretation or clarification
- **High-Risk Changes**: Database schema changes, API contract modifications, or breaking changes

##### [ASYNC] Classification (Agent Delegation Suitable)
- **Well-Defined CRUD**: Standard create/read/update/delete operations with clear schemas
- **Repetitive Tasks**: Boilerplate code, standard library usage, or template-based generation
- **Clear Specifications**: Unambiguous requirements with complete acceptance criteria
- **Independent Components**: Self-contained modules with minimal external dependencies
- **Standard Patterns**: Established frameworks, libraries, or architectural patterns
- **Testable Units**: Components with comprehensive automated test coverage

#### Triage Process

1. **Task Identification**: Break down the feature into discrete, implementable tasks
2. **Criteria Evaluation**: Assess each task against the [SYNC]/[ASYNC] criteria above
3. **Rationale Documentation**: Record the reasoning for each classification decision
4. **Risk Assessment**: Consider the impact of incorrect classification
5. **Review Checkpoint**: Validate triage decisions before task generation

#### Triage Audit Trail

**Document for Each Task:**
- Classification: [SYNC] or [ASYNC]
- Primary Criteria: Which criteria drove the classification
- Risk Level: Low/Medium/High (impact of misclassification)
- Rationale: 1-2 sentence explanation

#### Triage Effectiveness Metrics

**Track Over Time:**
- Classification Accuracy: Percentage of tasks correctly classified (measured post-implementation)
- Review Efficiency: Time spent on [SYNC] reviews vs [ASYNC] execution time
- Quality Impact: Defect rates by classification type
- Learning Opportunities: Common misclassification patterns

## Key Rules (Mode-Aware)

- Use absolute paths
- ERROR on gate failures or unresolved clarifications
- **TRIAGE REQUIREMENT**: All implementation tasks must be classified as [SYNC] or [ASYNC] with documented rationale

### Build Mode Rules
- Focus on core functionality and basic implementation approach
- Use reasonable defaults for unspecified technical details
- Skip extensive research - prioritize getting something working
- Limit triage to obvious complexity indicators

### Spec Mode Rules
- Comprehensive research required before design decisions
- Full constitutional compliance validation
- Detailed triage analysis for all tasks
- Complete design artifacts and validation

## Mode Guidance & Transitions

**Build Mode Planning:**
- Focus on core implementation approach and essential structure
- Use reasonable defaults for unspecified technical details
- Skip extensive research to prioritize getting something working
- Suitable for: Prototyping, simple features, quick validation

**Spec Mode Planning:**
- Comprehensive research-driven planning with full validation
- Detailed technical analysis and constitutional compliance
- Complete design artifacts and thorough triage
- Suitable for: Complex features, team collaboration, production systems

**Mode Transitions:**
- Build → Spec: Use `/mode spec` when feature complexity increases or comprehensive planning is needed
- Spec → Build: Use `/mode build` for rapid prototyping or when detailed planning creates overhead

