# 📊 **Agentic SDLC Spec Kit - Structured Roadmap**

## ✅ **COMPLETED ITEMS** (Fully Implemented & Verified)

### **CLI Infrastructure & Theming**

- ✅ **Orange Theme Restoration**: Centralized `ACCENT_COLOR` and `BANNER_COLORS` constants in CLI
- ✅ **Team Directives Integration**: Local path support and remote cloning for team-ai-directives
- ✅ **Context Readiness Enforcement**: `/specify`, `/plan`, `/tasks`, `/implement` validate `context.md` completeness

### **Constitution Management System** *(80% Complete)*

- ✅ **Automated Constitution Assembly**: Team constitution inheritance with validation
- ⚠️ **Constitution Evolution Tracking**: Basic implementation exists but limited functionality
- ✅ **Project Artifact Scanning**: Constitution enhancement suggestions from codebase analysis
- ⚠️ **Validation Framework**: Basic structure exists but limited quality/compliance checking
- ✅ **Levelup Integration**: Constitution evolution through feature learnings

### **Framework Options Feature** - **COMPLETED**

- ✅ **Framework Options**: Configurable TDD, contracts, data models, and risk-based testing via command-line flags
- ✅ **Options State Persistence**: Framework options stored in spec.md metadata for each feature
- ✅ **Auto-Detection System**: Commands automatically detect options using `detect_workflow_config()` function
- ✅ **Auto-Detection**: `/analyze` automatically detects pre vs post-implementation context
- ✅ **Documentation**: Framework options documented in README.md and quickstart.md
- ✅ **12-Factors Integration**: Framework options documented in methodology documentation
- ✅ **Checklist Integration**: `/checklist` command adapts validation based on detected framework options

### **AI Session Context Management** *(100% Complete)* - **HIGH PRIORITY** - Knowledge management and team learning

- ✅ **Levelup Extension**: `/levelup.init`, `/levelup.clarify`, `/levelup.skills`, `/levelup.implement` commands for CDR-based team-ai-directives contributions
- ✅ **Team Directives Analysis**: Analyzes session context for contributions to rules, constitution, personas, and examples
- ✅ **Reusable Knowledge Packets**: Creates context packets for cross-project AI agent learning
- ✅ **Comprehensive Issue Summaries**: Generates detailed session summaries for issue tracker comments

### **Basic Local Parallel Execution ([P] Markers)**

- ✅ **Task Generation**: `/tasks` creates tasks with [P] markers for parallelizable tasks
- ✅ **Parallel Execution**: `/implement` recognizes [P] markers and executes concurrently
- ✅ **File-based Coordination**: Tasks affecting same files run sequentially
- ✅ **User Story Organization**: Parallel execution within story phases

### **Risk-Based Testing Framework**

- ✅ **Risk Extraction**: Standardized severity levels (Critical/High/Medium/Low) in `check-prerequisites.sh`
- ✅ **Automated Test Generation**: `generate-risk-tests.sh` creates targeted test tasks
- ✅ **Mode Integration**: Risk-based testing configurable via feature-level mode parameters (`--risk-tests` flag)
- ✅ **Test Evidence Capture**: `/implement` preserves risk mitigation validation

#### **Dual Execution Loop Infrastructure**

- ✅ **Task Classification Framework**: SYNC/ASYNC classification in templates and triage system
- ✅ **Runtime Scripts**: `implement.sh`/`implement.ps1` for actual task execution
- ✅ **Rich Context Delegation**: `dispatch_async_task()` function for ASYNC task delegation with comprehensive project context
- ✅ **Delegation Template**: `templates/delegation-template.md` for conversational AI assistant prompts
- ✅ **Context Generation**: `generate_agent_context()` provides spec, plan, research, and team constitution context
- ✅ **Delegation Utilities**: `tasks-meta-utils.sh` with enhanced prompt generation and status checking
- ✅ **Interactive Reviews**: `perform_micro_review()` and `perform_macro_review()` with user prompts
- ✅ **Differentiated Quality Gates**: SYNC (80% coverage + security) vs ASYNC (60% coverage + macro review)
- ✅ **End-to-End Testing**: `test-dual-execution-loop.sh` comprehensive workflow validation

#### **Triage Framework**

- ✅ **Decision Trees**: Comprehensive SYNC/ASYNC classification guidance
- ✅ **Training Modules**: Triage effectiveness metrics and improvement tracking
- ✅ **Audit Trails**: Rationale documentation for classification decisions
- ✅ **Template Integration**: Triage guidance in `plan.md` and `plan-template.md`

#### **12-Factor Alignment**

- ✅ **Factor I-II (Strategy)**: Strategic mindset and context scaffolding implemented via constitution and directives
- ✅ **Factor III-V (Workflow)**: Mission definition, planning, and dual execution loops fully supported
- ✅ **Factor VI-VIII (Governance)**: Great filter, quality gates, and risk-based testing implemented
- ✅ **Factor IX-XII (Team Capability)**: Traceability, tooling, directives as code, and team learning supported

### **Iterative Development Support** *(100% Complete)* - **HIGH PRIORITY** - Addresses anti-iterative critique

- ✅ **Git-Managed Documentation**: Specs stored in `specs/[feature-name]/` directories with full version control
- ✅ **Branch-Based Isolation**: Each feature has dedicated branch enabling parallel development
- ✅ **Clarify Command Iteration**: Enables iterative spec refinement with direct spec file modifications
- ✅ **Three-Pillar Validation**: `/clarify` validates specs against Constitution + Architecture + Completeness (Jan 2026)
- ✅ **Analyze Command Cross-Reference**: Performs consistency analysis with remediation suggestions
- ✅ **Post-Implementation Analysis**: Extended `/analyze` command with auto-detection for pre/post-implementation context
- ✅ **Documentation Evolution**: Specs and plans actively evolve through git commits during development
- ✅ **Rollback Integration**: Git rollback capabilities preserve documentation state consistency
- ✅ **Automated Documentation Updates**: Background, non-blocking automation that detects code changes and queues documentation updates for review at natural breakpoints (pre-commit/push), with CLI-injected git hooks and batch review behavior

#### **Workflow Stage Orchestration** *(100% Complete)* - **COMPLETED** - Workflow completeness through command-to-command guidance

- ✅ **Git-Based Rollback**: Code and documentation rollback via git commands (already working)
- ✅ **Command-to-Command Guidance**: Sequential workflow guidance through existing command outputs (specify → clarify/plan → tasks → implement)
- ✅ **CLI Workflow Overview**: Complete SDD workflow steps displayed on project initialization
- ✅ **Context-Aware Next Actions**: Commands provide context-aware guidance for next steps (e.g., /analyze auto-detects pre/post-implementation)

#### **Configurable Framework Options** *(100% Complete)* - **MEDIUM PRIORITY** - Addresses over-opinionated critique

- ✅ **Opt-in Architecture Patterns**: TDD, contracts, data models, risk-based testing become user-configurable framework options
- ✅ **Reduced Mandatory Options**: Core workflow preserved, options made optional
- ✅ **User-Driven Defaults**: Users can override mode defaults with custom settings
- ✅ **Architecture Support**: Optional architecture documentation available in all modes via `/architect` commands

---

### **Three-Pillar Spec Validation** *(100% Complete)* - **COMPLETED** - Constitution + Architecture + Spec alignment

- ✅ **Constitution Alignment**: `/clarify` validates specs against team principles, constraints, and patterns
- ✅ **Architecture Alignment**: Validates specs fit within system boundaries and architectural constraints
- ✅ **Diagram Consistency**: Auto-detects and fixes diagram-text inconsistencies in architecture.md
- ✅ **Smart Prioritization**: Questions prioritized by impact (architecture > constitution > spec gaps)
- ✅ **Expanded Question Capacity**: Increased to 10 questions when architecture present (vs. 5 normally)
- ✅ **Auto-Fix Capability**: Automatically regenerates diagrams when inconsistencies detected
- ✅ **Graceful Degradation**: Falls back to spec-only validation if constitution/architecture missing
- ✅ **Context Extraction**: Python-based extraction of rules, viewpoints, and diagrams
- ✅ **JSON Payload Enhancement**: `check-prerequisites.sh` includes constitution/architecture paths and metadata

**Implementation Details** (Jan 2026):

- Extended `scripts/bash/check-prerequisites.sh` with constitution/architecture loading (+80 lines)
- Extended `scripts/powershell/check-prerequisites.ps1` with constitution/architecture loading (+80 lines)
- Added `extract_constitution_rules()`, `extract_architecture_views()`, `extract_architecture_diagrams()` to common.sh (+180 lines)
- Added `Get-ConstitutionRules`, `Get-ArchitectureViews`, `Get-ArchitectureDiagrams` to common.ps1 (+180 lines)
- Enhanced `templates/commands/clarify.md` with three-pillar validation logic (+150 lines)
- JSON output includes: `CONSTITUTION`, `ARCHITECTURE`, existence flags, extracted rules/views/diagrams
- Full bash + PowerShell parity for cross-platform support

**Benefits**:

- Catches governance violations early (constitution compliance)
- Ensures architectural integrity (boundary/pattern validation)
- Maintains visual-text consistency (auto-fixes diagrams)
- Prioritizes highest-impact clarifications first
- Seamlessly integrates with existing `/clarify` workflow

---

## 🔄 **CURRENT PHASE** (Complete After Next Phase)

### **Enhanced Traceability Framework** *(80% Complete)* - **MEDIUM PRIORITY** - Core 12F Factor IX implementation

- ✅ **MCP Configuration Foundation**: Issue tracker integration ready (GitHub/Jira/Linear/GitLab)
- ✅ **@issue-tracker Prompt Parsing**: Template parsing implemented in `/analyze` command
- ❌ **Automatic Trace Creation**: No evidence of automatic spec-issue linking implementation
- ✅ **Smart Trace Validation**: Documented and implemented in `/analyze` command (lines 209-236)
- ⚠️ **Task-to-Issues Command**: Template exists at `templates/commands/taskstoissues.md` but only supports GitHub (multi-tracker support planned in Tier 1.5)

### **Lean Architecture Improvements** *(100% Complete)* - **COMPLETED** - 6 Architecture Enhancements

Major enhancements to the architecture system making it more flexible, intelligent, and integrated with existing documentation.

- ✅ **Lean Architecture Views**: Configurable view generation (core 5 + optional 2)
  - Default "core" views: Context, Functional, Information, Development, Deployment
  - Optional views: Concurrency, Operational (via `--views` flag)
  - `--views all`, `--views core`, `--views concurrency,operational`
  
- ✅ **Surprise-Value Heuristic**: Skip obvious ecosystem defaults, document only surprising/risky decisions
  - `--adr-heuristic surprising` (default), `all`, `minimal`
  - Configuration in `config.json`: `architecture.adr.heuristic`
  
- ✅ **Constitution Cross-Reference**: Strict checking for ADR/Constitution alignment
  - Always enabled in `/architect.clarify`
  - Detects duplicates, violations, unclear alignment
  - **Option A (Amend Constitution) as PRIMARY resolution**
  
- ✅ **ADR Template Improvements**:
  - "Common Alternatives" (not "Alternatives Considered")
  - Neutral "Trade-offs" framing (not "Rejected because")
  - "Discovered" status for reverse-engineered ADRs
  - "Constitution Alignment" section
  
- ✅ **Existing Docs Deduplication**: Scan and reference instead of duplicate
  - Scans `docs/` directory and root `*.md` files
  - References existing docs (README, AGENTS.md, CONTRIBUTING)
  - Auto-merges when existing architecture found
  
- ✅ **Risks & Gaps Analysis**: Cross-cutting analysis in `/architect.clarify`
  - Identifies operational gaps, tech debt, SPOFs, security concerns
  - Section-based gap IDs (e.g., `3.6.1`)
  - Runs BEFORE constitution cross-reference

**Files Modified**: 13 files including templates, scripts, and configuration

---

### **Optional Architecture Support** *(100% Complete)* - **COMPLETED** - Enterprise Architecture Features

Architecture support is now available in all workflow modes as optional commands. The `/architect` and `/constitution` commands work silently in any mode, with no warnings if files are missing.

- ✅ **Architecture Templates**: Complete Rozanski & Woods 7 viewpoints + 2 perspectives (Security, Performance & Scalability)
- ✅ **Architect Command**: `/architect` with init/map/update/review actions fully implemented
- ✅ **Setup Scripts**: Both bash and PowerShell implementations complete
- ✅ **Brownfield Support**: `/architect map` detects technologies and populates `architecture.md` Section C directly
- ✅ **Mode Integration**: Architecture commands available in both build and spec modes
- ✅ **Silent Operation**: No errors or warnings when architecture.md missing
- ✅ **Constitution Support**: Optional project principles via `/constitution` command
- ✅ **Single Source of Truth**: `architecture.md` Section C contains tech stack (no separate files)
- ✅ **Mermaid Diagram Support**: Auto-generates professional diagrams for all 7 viewpoints (Jan 2026)

### **Architecture Command Restructuring** *(100% Complete)* - **COMPLETED** - ArcKit-aligned governance workflow

**Context**: Based on ArcKit (arckit.org) concepts and workshop discussions (Feb 2026), restructure the current `/spec.architect` command into a new `architect` command prefix with sub-commands that support interactive exploration before documentation.

**Key Insight**: The current architect command jumps too quickly to generating architecture - there should be a discussion/exploration phase first where users can explore possible solutions, weigh trade-offs, and make decisions before committing to formal documentation.

#### **Two-Level Architecture System**

| Level | Location | ADR File | Architecture Description | Commands |
|-------|----------|----------|--------------------------|----------|
| **System** | Main branch | `memory/adr.md` | `AD.md` (root) | `architect.*` |
| **Feature** | Feature branch | `specs/{feature}/adr.md` | `specs/{feature}/AD.md` | `spec.plan --architecture` |

**Note**: `AD.md` (Architecture Description) is placed at root level similar to `README.md` to emphasize its importance. It contains all 7 Rozanski & Woods viewpoints (Context, Functional, Information, Concurrency, Development, Deployment, Operational) plus 2 perspectives (Security, Performance & Scalability).

#### **New Command Structure**

| Command | Purpose | Input | Output |
|---------|---------|-------|--------|
| `architect.specify` | Interactive PRD exploration, create system ADRs | PRD (inline) + constitution | `memory/adr.md` |
| `architect.clarify` | Resolve ambiguities in system ADRs | `memory/adr.md` + constitution | Updated `memory/adr.md` |
| `architect.init` | Brownfield: reverse-engineer from codebase + PRD | Codebase + PRD (if found) | `memory/adr.md` |
| `architect.implement` | Generate full Rozanski & Woods architecture | `memory/adr.md` | `AD.md` (root) - all 7 viewpoints + 2 perspectives |
| `spec.plan` (enhanced) | Generate feature architecture when `--architecture` flag or `architecture=true` | spec.md + system adr.md | `specs/{feature}/AD.md` + `specs/{feature}/adr.md` |
| `spec.analyze` (enhanced) | Cross-validate features against AD.md | All artifacts | Analysis report |

#### **ADR Format (MADR)**

All ADRs follow Markdown Architecture Decision Record format:

- **Context**: Issue/problem requiring decision
- **Decision**: What was decided
- **Consequences**: Positive, Negative, Risks
- **Alternatives Considered**: Options evaluated with rejection reasons

#### **Feature Architecture Inheritance**

Feature-level ADRs are auto-validated against system-level ADRs:

- Conflicts flagged as VIOLATION requiring resolution
- Aligned decisions noted with "Aligns with ADR-XXX"
- New patterns create feature-specific ADRs

#### **Implementation Phases**

- ✅ **Phase 1**: `architect.specify` - Core innovation (interactive PRD → ADRs)
- ✅ **Phase 2**: `architect.clarify` - ADR refinement workflow
- ✅ **Phase 3**: `architect.init` - Brownfield support
- ✅ **Phase 4**: `architect.implement` - Full architecture generation
- ✅ **Phase 5**: `spec.plan` enhancement - Add `--architecture` flag and feature-level output
- ✅ **Phase 6**: `spec.specify` enhancement - Add `architecture` to Framework Options
- ✅ **Phase 7**: `spec.analyze` enhancement - Architecture cross-reference validation
- ✅ **Phase 8**: Migration & cleanup - Old `/spec.architect` command removed

#### **Files Created** (Feb 2026)

| File | Purpose | Status |
|------|---------|--------|
| `templates/commands/architect.specify.md` | Interactive ADR creation command | ✅ Created |
| `templates/commands/architect.clarify.md` | ADR refinement command | ✅ Created |
| `templates/commands/architect.init.md` | Brownfield initialization command | ✅ Created |
| `templates/commands/architect.implement.md` | Architecture document generation | ✅ Created |
| `templates/adr-template.md` | MADR format template | ✅ Created |
| `templates/AD-template.md` | Full Architecture Description (7 viewpoints + 2 perspectives) | ✅ Created |
| `templates/feature-AD-template.md` | Feature-level Architecture Description | ✅ Created |

#### **Migration Path**

| Old Command | New Command | Notes |
|-------------|-------------|-------|
| `/spec.architect init` | `/architect.specify` | Now interactive with PRD input |
| `/spec.architect map` | `/architect.init` | Brownfield unchanged |
| `/spec.architect update` | `/architect.clarify` | Now follows clarify pattern |
| `/spec.architect review` | `/spec.analyze` | Merged into analyze |

| Old File | New File | Notes |
|----------|----------|-------|
| `memory/architecture.md` | `AD.md` (root) + `memory/adr.md` | Split into ADRs and full Architecture Description |
| `templates/commands/architect.md` | `templates/commands/architect.*.md` | Split into 4 focused commands |

**Note**: The old `/spec.architect` command has been removed. Use the new `architect.*` commands instead.

#### **Configuration**

Feature-level architecture controlled via:

1. **Command line flag**: `/spec.plan --architecture`
2. **Framework Options in spec.md**: `architecture=true`
3. **Global config**: `~/.config/specify/config.json` → `options.architecture`

**Default**: `architecture=false` in plan mode (opt-in feature)

#### **Implementation Details** (Feb 2026)

- Created 4 new command templates (`architect.specify.md`, `architect.clarify.md`, `architect.init.md`, `architect.implement.md`)
- Created 3 new document templates (`adr-template.md`, `AD-template.md`, `feature-AD-template.md`)
- Enhanced `spec.plan.md` with `--architecture` flag and feature-level architecture generation
- Enhanced `spec.specify.md` with `architecture` Framework Option
- Enhanced `spec.analyze.md` with architecture cross-validation (Section K)
- MADR format follows Markdown Architecture Decision Record standard
- Feature ADRs auto-validate against system ADRs with VIOLATION/Alignment markers

**Benefits**:

- Interactive exploration before committing to architectural decisions
- Two-level architecture (system + feature) for governance at appropriate granularity
- ADRs capture rationale and alternatives, not just final decisions
- Feature architecture inherits from and validates against system architecture
- Cross-validation in `/spec.analyze` catches architectural drift early

**References**:

- ArcKit: <https://arckit.org/> (Enterprise Architecture Governance Toolkit)
- Discussion: AI:T:L AaC Workshop (Feb 2026) - Lior Kanfi, Yanai Franchi
- Rozanski & Woods: "Software Systems Architecture" methodology (7 viewpoints + 2 perspectives)

---

### **Mermaid Diagram Auto-Generation** *(100% Complete)* - **COMPLETED** - Visual architecture documentation

- ✅ **Automatic Diagram Generation**: Auto-generates Mermaid diagrams for all 7 architecture viewpoints
- ✅ **ASCII Fallback**: Maintains ASCII support for universal compatibility
- ✅ **User Configuration**: Global config option (`~/.config/specify/config.json`) to choose mermaid/ascii
- ✅ **Lightweight Validation**: Syntax validation with automatic ASCII fallback on failure
- ✅ **Full Coverage**: Context, Functional, Information, Concurrency, Development, Deployment, Operational views
- ✅ **Format Switching**: Easy switching between mermaid and ascii via config change + `/architect update`
- ✅ **Integration**: Built into `/architect init` and `/architect update` commands
- ✅ **Cross-Platform**: Full bash + PowerShell parity

**Implementation Details** (Jan 2026):

- Created `scripts/bash/mermaid-generator.sh` with 7 view-specific generators (+~300 lines)
- Created `scripts/bash/ascii-generator.sh` with 7 ASCII fallback generators (+~300 lines)
- Created PowerShell equivalents: `Mermaid-Generator.ps1` and `ASCII-Generator.ps1` (+~300 lines each)
- Added `get_architecture_diagram_format()` and `validate_mermaid_syntax()` to common.sh/ps1 (+~60 lines)
- Extended `setup-architecture.sh/ps1` with diagram generation integration (+~50 lines)
- Updated `templates/architecture-template.md` with Mermaid examples (replaced placeholders)
- Extended `templates/commands/architect.md` with diagram documentation (+~100 lines)
- Added architecture config to `src/specify_cli/__init__.py` (+~50 lines)

**Configuration**:

```json
{
  "architecture": {
    "diagram_format": "mermaid"  // or "ascii"
  }
}
```

**Benefits**:

- Professional visual diagrams render in GitHub/GitLab markdown
- Universal ASCII fallback works everywhere including terminals
- User choice via simple config option
- Automatic generation saves manual diagramming time
- Consistent diagram style across all viewpoints
- Version-controlled diagrams alongside architecture text

**Note**: Schema generation and drift detection features are documented in the Future Phase section as nice-to-have enhancements with no current implementation plans.

---

#### **Strategic Tooling Improvements** *(85% Complete)* - **MEDIUM PRIORITY**

- ❌ **Tool Selection Guidance**: Claims implementation but no actual guidance logic found
- ✅ **Global Configuration Support**: All configuration now stored globally in `~/.config/specify/config.json` (XDG compliant). Single shared configuration across all projects. Linux: `$XDG_CONFIG_HOME/specify/config.json`, macOS: `~/Library/Application Support/specify/config.json`, Windows: `%APPDATA%\specify\config.json`.
- ✅ **CLI Config Refactor**: Updated `src/specify_cli/__init__.py` to use `platformdirs` for XDG-compliant global path resolution.
- ✅ **Script Config Resolution**: Updated `common.sh` and `common.ps1` with `get_global_config_path()` / `Get-GlobalConfigPath` helper functions.
- ✅ **Config Consolidation**: Successfully implemented as single unified configuration file to reduce complexity and improve maintainability
- ✅ **Atomic Commits Config**: Config structure exists with defaults in `__init__.py` (lines 458, 468), available in both build and spec modes
- ✅ **Execution Logic**: Implemented in `scripts/bash/tasks-meta-utils.sh` (lines 192-208) - injects atomic commits constraint into delegation prompts when enabled

**NOTE**: User settings like `config.json` should remain user-specific and not tracked in git. However, team governance files like `.specify/constitution.md` should be version-controlled. Consider relocating constitution.md to a more appropriate location that clearly distinguishes it from user-specific configuration.

#### **Build Mode Migration** *(100% Complete)* - **COMPLETED** - Removed build mode from core specs

- ✅ **Core Command Refactoring**: Removed build mode from `templates/commands/specify.md`, `clarify.md`, `implement.md`, and `analyze.md`
- ✅ **Script Simplification**: Updated `scripts/bash/create-new-feature.sh` and `implement.sh` to remove build mode logic
- ✅ **Auto-Detection Removal**: Removed `detect_workflow_config()` based build mode detection from all scripts
- ✅ **Documentation Updates**: Updated README.md and docs/quickstart.md to remove per-spec mode architecture sections
- ✅ **Framework Options Only**: Core commands now support framework options (--tdd, --contracts, etc.) without build mode
- ✅ **Spec-Only Core**: Core commands exclusively handle spec mode with comprehensive validation

#### **Context Intelligence & Optimization** *(0% Complete)* - **MEDIUM PRIORITY** - Smart context management and compliance validation

- ❌ **Directives Scanner**: Create `scripts/bash/scan-directives.sh` (and ps1) to list all available assets in `team-ai-directives` as JSON.
- ❌ **Silent Context Injection**: Update `/spec.specify` to run the scanner and *silently* populate `context.md` with relevant Directives based on the user prompt (no user interaction required).
- ❌ **Compliance Gate**: Update `/spec.clarify` to validate the generated Spec against the Directives in `context.md` and pause ONLY if contradictions are found.

#### **Workflow Utilities** *(0% Complete)* - **MEDIUM PRIORITY** - Specialized workflow commands for focused development

- ❌ **Systematic Debugging**: Implement `/debug` command with a "Scientific Method" workflow (Symptoms -> Hypothesis -> Test) that runs in a persistent session.
- ❌ **Idea Backlog**: Implement `/todo` command to capture out-of-context ideas to a separate list without derailing the current active task.

#### **Persistent Issue ID Storage Enhancement** *(0% Complete)* - **HIGH PRIORITY** - Issue-tracker-first workflow improvement

- ❌ **Add --issue Parameter to Specify**: Implement `--issue ISSUE-ID` parameter for specify command to fetch issue data from configured tracker
- ❌ **Store Issue Context Persistently**: Save issue ID, tracker type, and metadata in context.md for automatic propagation
- ❌ **Automatic Issue Propagation**: Subsequent commands (/clarify, /plan, /tasks, /analyze, /levelup.spec) automatically use stored issue context
- ❌ **Dynamic MCP Tool Resolution**: Use declarative tools pattern with configuration-driven tool selection based on detected issue tracker
- ❌ **Multi-Tracker Support**: Support GitHub/Jira/Linear/GitLab issue formats with appropriate MCP tool routing

#### **Session Trace Command (/levelup.trace)** *(100% Complete)* - **HIGH PRIORITY** - AI session documentation and learning

- ✅ **Trace Generation Scripts**: Created bash and PowerShell scripts to generate traces from tasks_meta.json and feature artifacts
- ✅ **Trace Validation Scripts**: Implemented validation for section completeness, coverage percentage, and quality gate statistics
- ✅ **Command Template**: Created `/levelup.trace` command as part of LevelUp extension with generation and validation workflows
- ✅ **Trace Template**: Defined 5-section trace structure (Session Overview, Decision Patterns, Execution Context, Reusable Patterns, Evidence Links)
- ✅ **Levelup Integration**: Modified `/levelup.spec` to consume trace.md if exists (optional enrichment)
- ✅ **Mode Support**: Works in both build and spec modes with appropriate trace depth
- ✅ **Storage Location**: Traces stored in specs/{BRANCH}/trace.md with feature artifacts
- ✅ **Overwrite Behavior**: Re-running `/levelup.trace` overwrites previous trace (single latest version)
- ✅ **Extension Migration**: Moved trace command to LevelUp extension for better integration with team learning workflow

**Purpose**: Generate comprehensive AI session execution traces for knowledge sharing, pattern identification, and learning. Traces capture decision-making patterns, execution outcomes, quality gate results, and evidence links. Optional but enriches `/levelup.spec` CDR extraction when present.

**Workflow**: `/implement` → `/levelup.trace` (generate session trace) → `/levelup.spec` (consume trace for CDR extraction)

#### **Levelup Command Migration** *(100% Complete)* - **COMPLETED** - Removed build mode paths

- ✅ **Unified Levelup Path**: Levelup extension requires spec.md, plan.md, and tasks.md (spec-only workflow)
- ✅ **Script Updates**: Removed prepare-levelup.sh/ps1 WORKFLOW_MODE detection
- ✅ **Template Simplification**: Updated `levelup.md` template to remove build mode conditional logic

#### **Build Mode Artifact Removal** *(100% Complete)* - **COMPLETED** - Cleanup completed

- ✅ **Build Template Removal**: Removed `spec-template-build.md` and `plan-template-build.md`
- ✅ **Mode Documentation**: Removed `templates/commands/mode.md` command
- ✅ **Unified Workflow**: Single spec-only workflow with framework options

#### **Tier 1 (CRITICAL): Async Task Context Delivery & Remote Agent Integration** *(0% Complete)* - **CRITICAL PRIORITY** - Unblocks full async workflow

Consolidates: Former "Async Task Context Delivery Architecture" + "Multi-Tracker Task-to-Issues Extension" + context purity enforcement from Claude Code article insights

**Purpose**: Enable remote async agents (async-copilot, async-codex, jules) to receive complete spec contexts and support multi-tracker issue creation for enhanced traceability.

##### Tier 1.1 - Artifact Context Packaging

- ❌ **Spec Context Bundling**: Create `scripts/bash/package-spec-context.sh` to bundle spec.md + plan.md + research.md + context.md as unified delivery unit
- ❌ **Payload Strategy Selection**: Support embedded payload for specs < 150K tokens; URL references for larger repos
- ❌ **Git Metadata Inclusion**: Include repo URL, branch, commit SHA in package for remote context
- ❌ **PowerShell Equivalent**: Implement `scripts/powershell/Package-SpecContext.ps1` with cross-platform parity

##### Tier 1.2 - Remote MCP Task Submission Protocol

- ❌ **Standard MCP Tools**: Define `submit_async_task`, `check_task_status`, `get_task_result` tools in MCP schema
- ❌ **Agent Type Support**: Implement endpoints for async-copilot, async-codex, jules, and custom agents
- ❌ **Endpoint Registration**: Extend `.mcp.json` configuration to register remote agent endpoints per type
- ❌ **Model Parameter Passthrough**: Allow `--model` parameter to flow through to remote agent execution (e.g., `--model opus` on `/implement` passes to async agent)
- ❌ **Agent Selection Logic**: Route tasks to appropriate agent based on `/tasks` metadata (ASYNC tag + agent type)

##### Tier 1.3 - Repository Context Provision

- ❌ **Git Credential Handling**: Support SSH keys, personal tokens, git-credential-helper for remote auth
- ❌ **Branch Context**: Pass feature branch reference so remote agents work with correct isolated specs
- ❌ **Commit History**: Include recent commit history and related issue references in context metadata
- ❌ **Authentication Testing**: Validate credentials before submitting tasks to prevent failures

##### Tier 1.4 - Webhook/Callback Integration

- ❌ **Webhook Listener**: Implement listener for async agent completion events (status, output, error info)
- ❌ **Result Storage**: Store completion status + output path in `tasks_meta.json` (keyed by job_id from remote agent)
- ❌ **Integration Checking**: During `/implement` execution, check for completed async tasks and retrieve results
- ❌ **Error Handling**: Detect failures and escalate ASYNC tasks to SYNC with user notification

##### Tier 1.5 - Multi-Tracker Issue Creation (Consolidated from Multi-Tracker Task-to-Issues)

- ⚠️ **Extended `/taskstoissues`**: Template exists at `templates/commands/taskstoissues.md` but currently only supports GitHub. Needs extension for Jira, Linear, GitLab.
- ❌ **URL Validation**: Handle different URL formats (GitHub SSH/HTTPS, Jira REST, Linear API, GitLab REST)
- ❌ **Task-to-Issue Linking**: Establish bidirectional links between tasks.md and created issues for traceability

##### Tier 1.6 - Context Purity Enforcement (From Claude Code article insights)

- ❌ **Full Artifact Delivery**: Remote agents receive complete spec.md/plan.md/research.md (not summaries)
- ❌ **Compression Thresholds**: Only compress when artifacts exceed 150K tokens (configurable in config.json)
- ❌ **Attention Mechanism Preservation**: Ensure agents can perform pair-wise reasoning across context via full document loading
- ❌ **Token Cost Visibility**: Log context size and token costs in delegation prompts for transparency

---

#### **Tier 2 (HIGH): Sub-Agent Coordination Framework** *(0% Complete)* - **HIGH PRIORITY** - Intelligent local & remote task orchestration

Consolidates: Sub-agent spawning logic from dual execution loop + background observability + failure escalation + agent type selection guidance

**Purpose**: Unified framework for spawning, coordinating, and monitoring local sub-agents (Explore, Plan, general-purpose) and remote async agents with context-aware selection.

##### Tier 2.1 - Sub-Agent Type Selection Matrix

- ❌ **Explore Agent Documentation**: Create decision guidance for read-only codebase search (Glob, Grep, Read, bash read-only only)
  - ✓ When: Finding files, searching keywords, understanding architecture
  - ✗ Don't: Use for modification tasks, complex reasoning
  - Context: Fresh slate (no conversation history) - faster + focused
  - Model override: Support `--model sonnet` for deeper analysis
- ❌ **Plan Agent Documentation**: Design/implementation planning with full tools
  - ✓ When: Complex multi-file implementations, architecture decisions
  - ✗ Don't: Simple CRUD operations, straightforward fixes
  - Context: Full inheritance (pair-wise reasoning enabled)
  - Model override: Support `--model opus` for critical planning
- ❌ **General-Purpose Agent Documentation**: Complex multi-step task execution
  - ✓ When: Tasks requiring tool sequencing, decision-making
  - ✗ Don't: Single-tool operations, trivial tasks
  - Context: Full inheritance
  - Model override: User-configurable per task
- ❌ **Integration with Task Tool**: Embed selection guidance in Task tool schema (system prompt injection)
- ❌ **Model Parameter Support**: Document model override capability for each agent type

##### Tier 2.2 - Context Inheritance Rules

- ❌ **Context Inheritance Matrix**: Document which agents inherit vs start fresh
  - Explore: Fresh slate (enables fast codebase search without prior context bloat)
  - Plan/General-purpose: Full context inheritance (enables pair-wise attention relationships)
- ❌ **Main Agent Reading Pattern**: Document guidance that main agent should read relevant files itself (not rely on agent summaries) for better reasoning (from Claude Code article)
- ❌ **Team Directive Integration**: Store preferred context inheritance per organization in `team-ai-directives`
- ❌ **Configuration Option**: Allow per-project override of inheritance rules

##### Tier 2.3 - "When NOT to Spawn" Guidelines (Reduces context bloat)

- ❌ **Anti-Pattern Documentation**:
  - ❌ Don't spawn Explore if file paths already known → use Read tool directly
  - ❌ Don't spawn if task < 3 steps → execute directly with tools
  - ❌ Don't spawn for simple CRUD → handle inline
  - ❌ Don't spawn multiple agents serially → coordinate with parallel spawning
- ❌ **Negative Guidance in Task Tool**: Inject anti-patterns into system prompt to prevent unnecessary spawns
- ❌ **Token Cost Awareness**: Log when direct execution used instead of spawn (context saved)

##### Tier 2.4 - Background Agent Observability

- ❌ **Background Task Spawning**: Support `run_in_background: true` in Task tool for long-running processes
- ❌ **Monitoring Hooks**: Log output from background tasks (process execution, test runs, compilations)
- ❌ **Result Retrieval**: Implement `TaskOutput` tool for retrieving background task results
- ❌ **Error Tracking**: Surface background task failures with clear error context
- ❌ **Use Case Documentation**: Guide when background spawning is appropriate (e.g., watching test output)

##### Tier 2.5 - Parallel Sub-Agent Coordination (Enhances existing [P] markers)

- ❌ **[P] Marker Enhancement**: Ensure [P] markers in tasks.md are recognized for parallel spawning
- ❌ **File-Based Sequencing**: Maintain rule that tasks touching same files run sequentially despite [P]
- ❌ **Phase-Based Execution**: Ensure phases (setup → tests → core → integration → polish) complete in order
- ❌ **Parallel Spawn Coordination**: Manage multiple simultaneous sub-agents without context window flooding
- ❌ **Integration Testing**: Verify [P] parallelization works with both Tier 1 remote tasks and local Explore agents

##### Tier 2.6 - Sub-Agent Failure Escalation

- ❌ **Async Escalation Logic**: When remote ASYNC sub-agent fails, promote parent task to SYNC with user notification
- ❌ **Model Retry Strategy**: Support escalation with model upgrade (Haiku → Sonnet → Opus) for failed tasks
- ❌ **Rollback Mechanism**: Option to rollback failed agent's changes and retry with different approach
- ❌ **Escalation Logging**: Detailed logging of why escalation occurred (timeout, tool failure, reasoning error)
- ❌ **User Control**: Allow user to choose: retry, escalate, skip, or restart phase

---

#### **Tier 3 (MEDIUM): Model Selection Strategy per Command** *(0% Complete)* - **MEDIUM PRIORITY** - Optimize cost & performance

Consolidates: Command-level model selection + context budgeting + two-model review pattern + cost optimization guidance

**Purpose**: Systematic approach to model selection per core command, enabling cost optimization while maintaining quality gates.

##### Tier 3.1 - Core & Admin Command Model Selection Matrix

- ❌ **Core Workflow Commands**:
  - `/specify`: Default Opus → Options: Sonnet (faster but less conversational quality)
  - `/clarify`: Default Opus → Options: Sonnet (validation still works well)
  - `/plan`: Default Sonnet → Options: Opus (complexity), Haiku (exploration)
  - `/implement`: Default Sonnet → Options: Opus (analysis), Haiku (lightweight)
  - `/analyze`: Default Opus → Options: Sonnet (time-constrained)
  - `/trace`: Default Haiku → Options: Sonnet (richer traces)
  - `/levelup.spec`: Default Sonnet → Options: Opus (comprehensive CDR extraction)
- ❌ **Admin Commands**:
  - `/architect`: Default Sonnet → Options: Opus (critical systems), Haiku (exploration)
  - `/constitution`: Default Sonnet → Options: Opus (complex governance)
  - `/mode`: Haiku (config is lightweight)
  - `/checklist`: Haiku (validation is formulaic)
- ❌ **Integration**: Add `--model [opus|sonnet|haiku|gpt-5-codex]` parameter to all commands above

##### Tier 3.2 - Model-Aware Context Budgeting (Inform users of token costs)

- ❌ **Context Window Limits**: Document effective context windows per model (Opus: ~120K effective of 200K, Sonnet: ~100K of 200K, Haiku: ~80K of 200K)
- ❌ **Token Cost Calculator**: Implement utility to estimate tokens for spec.md + plan.md + tasks.md
- ❌ **Recommendation Engine**: Show "context utilization: 58% - OK" or "context: 72% - consider compaction" during execution
- ❌ **Model Downgrade Suggestions**: Auto-suggest Haiku when context > 70% for non-critical tasks
- ❌ **Transparency in Prompts**: Log context size in delegation prompts (e.g., "using Sonnet to preserve 22K tokens")

##### Tier 3.3 - Two-Model Review Strategy (From Claude Code article)

- ❌ **Review Model Configuration**: Store preferred review model in config.json (configurable: gpt-5-codex, Sonnet, etc.)
- ❌ **Quality Gate Integration**: Invoke review model for ASYNC task validation (bug-finding, style checking)
- ❌ **SYNC vs ASYNC Review**: Apply two-model review only to critical SYNC tasks (cost optimization)
- ❌ **User Override**: Support `--review-model` parameter to force specific reviewer (cross-vendor validation)
- ❌ **Review Quality Thresholds**: Document when review model is invoked (P1/P2 risk level, SYNC tasks, security code)

##### Tier 3.4 - Cost Optimization Guidance

- ❌ **Usage Documentation**: Create guide on when to use each tier:
  - Haiku: Trace generation, exploration, formatting, config updates
  - Sonnet: Execution, general-purpose tasks, balanced cost/quality
  - Opus: Complex reasoning, architecture decisions, critical paths
- ❌ **Cost Calculator**: Implement simple calculator (Opus costs ~3x Sonnet, 5x Haiku) with examples
- ❌ **Budget Tracking**: Optional logging of model usage per project/team
- ❌ **Org Policy Templates**: Provide templates for enforcing model choices per team

##### Tier 3.5 - Model Preference in Team Directives

- ❌ **Directive Format**: Define structure in `team-ai-directives` for model preferences per command
- ❌ **Fallback Hierarchy**: Implement precedence: user CLI override → project config → team directive → hardcoded default
- ❌ **Org-Wide Defaults**: Enable shared model policies across projects via team directives

##### Tier 3.6 - Command-Level --model Parameter Implementation

- ❌ **CLI Parameter Addition**: Add `--model` to all command templates (specify.md, clarify.md, plan.md, implement.md, analyze.md, architect.md, constitution.md, trace.md, levelup.md)
- ❌ **Config Validation**: Validate model choice against available models
- ❌ **Preference Persistence**: Store user's recent model choice per command for convenience
- ❌ **Documentation**: Update quickstart and command help text with model selection guidance

#### **Unified Spec Template Implementation** *(100% Complete)* - **MEDIUM PRIORITY** - Template maintenance reduction

- ✅ **Spec-Only Templates**: Removed build mode templates, unified to single spec.md template
- ✅ **Script Simplification**: Removed mode detection logic from create-new-feature.sh and create-new-feature.ps1 scripts
- ✅ **Minimal Conflict Surface**: Changes isolated to fork-specific scripts, templates remain upstream-compatible

#### **Spec Management & Cleanup** *(0% Complete)* - **MEDIUM PRIORITY**

- ❌ **Spec Deletion Command**: `/delete-spec` command to safely remove spec with all associated files (spec.md, plan.md, tasks.md, context.md, feature branches)
- ❌ **Dependency Validation**: Check for dependent artifacts before deletion
- ❌ **Archive Option**: Optional archiving instead of permanent deletion
- ❌ **Cleanup Verification**: Confirm all related files and branches are removed

---

## 🚀 **NEXT PHASE** (Deferred - Complete After Current Phase)

### **Worktrunk-Integrated Parallel Execution with Dependency-Aware Orchestration** *(0% Complete)* - **HIGH PRIORITY** - Incident.io workflow pattern enabling 5+ agents in parallel with git worktree isolation

**Purpose**: Enable safe parallel execution of SYNC/ASYNC tasks with explicit dependency tracking and phase-respecting orchestration. Validates the incident.io pattern (multiple agents, branch isolation, clean merge workflow) using Worktrunk as optional infrastructure for parallel development.

**Design Foundation** (locked design from validated patterns):

| Aspect | Decision | Validation |
|--------|----------|-----------|
| Branch Structure | Hierarchical: `feature/spec-name/task-NNN-description-[sync\|async]` | Nests task branches under spec branch from `/specify`; prevents collision |
| Dependencies | Explicit in tasks.md: `depends: [T001, T002]` | Human-writable during `/plan`; pre-merge hooks validate; enables sophisticated scheduling |
| Phase Ordering | Enforce phase boundaries; parallelize `[P]` within phase | Setup → Foundational → Stories; respects internal dependencies |
| Unmet Dependencies | Skip task with warning; don't block phase | Graceful degradation; visibility into blocking tasks |
| Worktree Isolation | Optional (Worktrunk); sequential fallback | Enables incident.io pattern; functional without worktrees |
| Worktree Paths | Full hierarchical: `repo.feature.spec-name.task-NNN-desc` | Fully qualified; prevents collision across features |

**Implementation Roadmap** (5 Phases, 10 Weeks):

#### Phase 1: Dependency Model & Parsing (Weeks 1-2)

- [ ] Update `templates/tasks-template.md` with `depends: [T001, T002]` syntax + examples
- [ ] Create `scripts/bash/parse-dependencies.sh` with DAG validation (cycles, cross-phase violations, missing refs)
- [ ] Create PowerShell equivalent: `scripts/powershell/Parse-Dependencies.ps1`
- [ ] Update `/tasks` template to emit dependency syntax
- [ ] Update `docs/triage-framework.md` with dependency declaration guidance

**Testing**: Sample tasks.md with 10+ tasks across 3 phases; verify DAG validation

#### Phase 2: Phase-Aware Orchestration (Weeks 3-4)

- [ ] Create `scripts/bash/orchestrate-tasks.sh` with phase-sequential + [P] parallelization logic
- [ ] Create PowerShell equivalent: `scripts/powershell/Orchestrate-Tasks.ps1`
- [ ] Extend `/implement` template to call orchestration logic
- [ ] Add phase-aware progress reporting ("Phase 1/3: 2/3 tasks complete")

**Testing**: Full workflow on test project with 10+ tasks; verify sequential Setup, parallel Foundational

#### Phase 3: Worktrunk Integration (Optional) (Weeks 5-6)

- [ ] Create `scripts/bash/spawn-task-worktree.sh` with worktree creation + branch hierarchy
- [ ] Create PowerShell equivalent: `scripts/powershell/Spawn-TaskWorktree.ps1`
- [ ] Generate `.config/wt.toml` template with pre-merge dependency validation hooks
- [ ] Extend `/implement` to detect Worktrunk + choose execution path
- [ ] Add `--enable-worktrunk`, `--prefer-worktrunk` (default), `--no-worktrunk` flags

**Testing**: Run with Worktrunk available and without; verify isolation and fallback

#### Phase 4: Remote Async Agent Integration (Weeks 7-8) *(Tier 1.3 + 1.4 enablement)*

- [ ] Extend `dispatch_async_task()` to include worktree branch SHA + path (if available)
- [ ] Create `scripts/bash/package-task-context.sh` bundling spec, plan, research, task spec
- [ ] Update delegation template with task dependency metadata
- [ ] Extend `tasks-meta-utils.sh` to track async task status from remote agents

**Testing**: Delegate ASYNC task with full worktree context; verify agent receives branch info

#### Phase 5: Monitoring & Documentation (Weeks 9-10)

- [ ] Create monitoring dashboard script: `scripts/bash/monitor-parallel-tasks.sh`
- [ ] Update `/implement` output to show phase progress, pending dependencies, agent status
- [ ] Create comprehensive guide: `docs/parallel-execution-guide.md`
- [ ] Create end-to-end integration test: `test-parallel-execution.sh`

**Testing**: Complete workflow with 3 phases, mixed SYNC/ASYNC, dependencies; verify monitoring

**Integration with Existing Framework**:

- **Enhances [P] Markers** (line 56-61): Existing `[P]` parallelization now coordinated via Worktrunk worktrees (incident.io pattern)
- **Orchestrates SYNC/ASYNC** (line 72-80): Dependency-aware scheduling enables safe parallel execution of mixed SYNC/ASYNC tasks
- **Prerequisite for Tier 1.3** (line 323-328): Worktree branch context becomes artifact delivery mechanism for remote async agents
- **Realizes Tier 2.5** (line 407-413): This IS the implementation of "Parallel Sub-Agent Coordination" with explicit dependencies

**Key Benefits**:

- Enables incident.io's 5+ agents in parallel without context clash (each in isolated branch + worktree)
- Pre-merge hooks enforce dependency constraints before merging
- Phase-respecting orchestration maintains logical workflow structure
- Graceful fallback without Worktrunk (sequential in-directory execution)
- Clear visibility into which tasks are blocked (waiting for dependencies)

**Success Metrics**:

- All 3 phases complete in correct order
- Multiple [P] tasks execute simultaneously (with Worktrunk)
- Pre-merge hooks prevent merging with unmet dependencies
- Dashboard shows real-time parallel task progress
- ASYNC tasks receive full worktree branch context (ready for Tier 1)

**Risks & Mitigation**:

| Risk | Mitigation |
|------|-----------|
| Dependency cycles in tasks.md | DAG validation in Phase 1 prevents cycles during parsing |
| Pre-merge hooks too strict | Customizable per project in `.config/wt.toml` |
| Worktrunk not installed | Graceful fallback to sequential in-directory execution |
| Tasks blocked on dependencies | Clear warning messages indicate which deps are waiting |
| Tier 1 integration complexity | Phase 4 provides scoped worktree context + packaging |

**References**:

- incident.io: "Shipping faster with Claude Code and Git Worktrees" (Jun 2025) - validates multi-agent + worktree pattern
- Worktrunk: [https://github.com/max-sixty/worktrunk](https://github.com/max-sixty/worktrunk) - git worktree management for parallel AI workflows
- Existing SYNC/ASYNC triage (line 72-87) + [P] markers (line 56-61) provide foundation

---

### **Command Prefix Migration** *(0% Complete)* - **MEDIUM PRIORITY** - Fork differentiation and user experience

- ❌ **Prefix Change Implementation**: Migrate from `/spec.*` to `/agenticsdlc.*` commands for clear fork identification
- ❌ **Documentation Updates**: Update all references in README.md, docs, and templates (100+ instances)
- ❌ **Release Script Modification**: Update `.github/workflows/scripts/create-release-packages.sh` to generate new prefix
- ❌ **Migration Support**: Dual prefix support during transition with deprecation warnings
- ❌ **User Communication**: Migration guide for existing projects and clear differentiation messaging

**Note**: Deferred to focus on fixing workflow blockers first. Breaking change can be applied after core functionality is stable.

---

## 🆕 **FUTURE PHASE** (New Items - Not Yet Started)

---

### **Compound Engineering Integration** *(0% Complete)* - **MEDIUM PRIORITY** - Insights from EveryInc's Compound Engineering Plugin

**Reference**: Analysis of [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) (7.5k stars, 598 forks)

**Key Insight**: Compound Engineering Plugin focuses on workflow efficiency through multi-agent parallelization and knowledge compounding, while Agentic SDLC Spec Kit focuses on structured SDLC methodology. These approaches are complementary.

#### **Swarm Mode Parallel Execution** *(0% Complete)* - **HIGH PRIORITY**

- **Description**: Implement swarm mode execution (like Compound's `/slfg`) that runs multiple sub-agents in parallel for tasks marked with `[P]` markers, dramatically accelerating development workflows
- **Key Components**:
  - Parallel agent spawning for independent tasks within phases
  - Worktree-based isolation (validates incident.io pattern with 5+ agents)
  - Coordinated execution with dependency awareness
  - Phase-respecting orchestration (Setup → Foundational → Stories)
  - **Benefits**:
    - 3-5x faster execution for parallelizable tasks
    - Validates incident.io multi-agent + worktree pattern
    - Maintains code isolation and merge safety
  - **Implementation**: Extend existing `[P]` marker system with swarm orchestration layer
- **References**: incident.io workflow pattern, Worktrunk integration

#### **Multi-Agent Review System** *(0% Complete)* - **MEDIUM PRIORITY**

- **Description**: Implement specialized reviewer agents (like Compound's 15 review agents) that perform focused code reviews:
  - `security-sentinel`: Security vulnerability detection
  - `performance-oracle`: Performance optimization suggestions  
  - `rails-reviewer`: Framework-specific best practices
  - `accessibility-guardian`: A11y compliance checking
  - `test-coverage-analyst`: Test quality validation
- **Key Components**:
  - Temperature-tuned agents (review: 0.1, planning: 0.2, creative: 0.6)
  - Parallel review execution before merge
  - Review agent selection based on code changes
  - Aggregated review reports with actionable items
  - **Benefits**:
    - Comprehensive pre-merge validation
    - Specialized expertise without context bloat
    - Consistent quality gates across team
  - **Integration**: Hook into `/spec.analyze` and pre-merge workflows

#### **Knowledge Compounding System** *(0% Complete)* - **MEDIUM PRIORITY**

- **Description**: Enhance the levelup extension with systematic knowledge capture inspired by Compound's philosophy: "Each unit of engineering work should make subsequent units easier"
- **Key Components**:
  - Pattern extraction from completed features
  - Anti-pattern documentation from failed approaches
  - Reusable solution templates for common problems
  - Team knowledge base with searchable patterns
  - Automatic skill generation from recurring patterns
  - **Workflow Enhancement**:

    ```text
    Plan → Work → Review → Compound → Repeat
    ```

  - **Benefits**:
    - Institutional knowledge preservation
    - Accelerated future development through pattern reuse
    - Reduced repeated mistakes
    - Team learning velocity increase
  - **Integration**: Extend existing `/levelup.init` and `/levelup.skills` with structured knowledge packets

#### **Browser Automation Integration** *(0% Complete)* - **LOW PRIORITY**

- **Description**: Integrate browser automation capabilities (like Compound's agent-browser CLI) for e2e testing and UI validation
- **Key Components**:
  - Automated e2e test generation from specifications
  - Visual regression testing integration
  - UI interaction recording and replay
  - Screenshot-based validation in `/spec.implement`
  - **Benefits**:
    - Automated visual validation
    - Reduced manual QA effort
    - Better spec-to-implementation alignment
  - **Implementation**: Integration with Playwright, Puppeteer, or agent-browser

#### **Cross-Platform Plugin Converter** *(0% Complete)* - **LOW PRIORITY**

- **Description**: Create plugin conversion system (like Compound's Bun/TypeScript CLI) to convert between agent formats:
  - Claude Code plugins ↔ OpenCode format
  - Claude Code plugins ↔ Codex format
  - Custom agent format support
- **Key Components**:
  - Agent format parsers and transformers
  - Tool mapping between platforms (bash/read/write/edit)
  - Temperature inference from agent names
  - MCP server conversion
  - **Benefits**:
    - Broader agent ecosystem compatibility
    - Reduced vendor lock-in
    - Easier migration between AI tools
  - **Implementation**: Python-based converter leveraging existing AGENT_CONFIG

#### **Task Delegation Templates** *(0% Complete)* - **MEDIUM PRIORITY*

- **Description**: Create rich task delegation system with specialized agent types inspired by Compound's agent ecosystem:
  - **Explore Agents**: Read-only codebase search (fresh slate, no context inheritance)
  - **Plan Agents**: Design/implementation planning (full context inheritance)
  - **Execute Agents**: Multi-step task execution with tool sequencing
  - **Review Agents**: Focused quality validation
- **Key Components**:
  - Agent type selection matrix based on task characteristics
  - Context inheritance rules per agent type
  - Model selection guidance per agent type
  - "When NOT to Spawn" guidelines to prevent context bloat
  - **Benefits**:
    - Optimized agent utilization
    - Reduced unnecessary context window usage
    - Better task-agent matching
  - **Integration**: Extend Tier 2 Sub-Agent Coordination Framework

### **Beads-Backed Task Execution Tracker** *(0% Complete)* - **MEDIUM PRIORITY** - Agent-native persistent work tracking

**Problem Statement**:

The `/tasks` command generates dependency-ordered tasks.md files, but agents lack persistent cross-session visibility into task state, dependencies, and execution progress. This leads to:

- Agents losing context about task generation decisions across sessions (inter-session amnesia)
- Inability to query ready-to-execute tasks without parsing markdown
- Lost work discovery when agents encounter issues during implementation but lack structured recording mechanism
- Suboptimal agent behavior near context limits (workarounds instead of updating task status)

Per Steve Yegge's Beads manifesto, agents naturally work better with issue trackers than markdown plans because structured dependency queries and persistent memory solve these problems.

**Solution**:
Integrate Beads (native issue tracker) with `/tasks` command as dual-output system:

- `/tasks` continues generating tasks.md (no breaking changes to current workflow)
- **NEW**: `/tasks` also populates beads issues with explicit dependencies, SYNC/ASYNC classification, and phase structure
- Agents can query beads during `/implement` for ready work: `bd ready --json --assignee me`
- Discovered work automatically recorded to beads by agents without context pressure
- Task status updates via `bd update` provide persistent progress tracking across sessions

**Scope** (Conservative Approach - Option A):

- ✅ `/tasks` generates beads issues in parallel with tasks.md (coexistence, not replacement)
- ✅ Each task becomes a beads issue with:
  - Title: Task name from tasks.md
  - Description: Task description + rationale for SYNC/ASYNC classification
  - Labels: `[SYNC]`, `[ASYNC]`, `[P]` (parallelizable), phase name (Setup, Foundational, US1, etc.)
  - Dependencies: Links between phases and dependent tasks via beads parent/child relationships
  - Status: `open` (not started), `in_progress`, `done`
- ✅ Beads database lives alongside tasks.md in `specs/[feature-name]/` directory
- ✅ Beads is native install (users install `bd` CLI separately)
- ✅ Graceful fallback: If beads unavailable, tasks.md workflow still works
- ❌ NOT replacing tasks.md as execution format (yet)
- ❌ NOT for multi-feature pattern learning
- ❌ NOT for cross-project agent coordination

**Integration Points**:

| Component | Current | Change | Impact |

|-----------|---------|--------|--------|
| `/tasks` command | Generates tasks.md only | Also calls `bd create` for each task | Dual output, no breaking changes |
| `tasks-meta-utils.sh` | Tracks task metadata in tasks_meta.json | Sync SYNC/ASYNC classification to beads issue labels | Beads becomes single source of execution mode truth |
| `/implement` command | Parses tasks.md for task list | Optional: Query `bd ready --json` for better structure (Phase 2) | Phase 1 uses tasks.md, Phase 2 uses beads |
| Task storage | `specs/[feature]/tasks.md` | Add `specs/[feature]/.beads/` directory | Beads provides query-able execution tracker |
| Agent context | Session-based (limited memory) | Can query beads for discovered issues, previous decisions | Persistent cross-session memory |

**Implementation Roadmap**:

**Phase 1: Beads Issue Generation from `/tasks`** (Weeks 1-3)

- ❌ Modify `/tasks` template to call `scripts/bash/tasks-to-beads.sh` after tasks.md generation

- ❌ Create `scripts/bash/tasks-to-beads.sh` (+ PowerShell equivalent):
  - Parse generated tasks.md
  - Extract: task ID, title, description, phase, SYNC/ASYNC classification, dependencies
  - Call `bd create` with formatted issue + labels
  - Link parent/child tasks via beads dependency relationships

  - Handle duplicate runs (update existing issues vs. create new)
- ❌ Add beads initialization to `/tasks` workflow: `bd init` if `.beads/` doesn't exist
- ❌ Document beads setup in `/tasks` help text: "Beads database available at .beads/issues.jsonl"
- ❌ Test with single feature: Generate tasks.md + beads issues, verify structure
**Phase 2: Agent Work Discovery & Status Tracking** (Weeks 4-6, deferred)
- ❌ Guide agents to use `bd create` when discovering issues during implementation
- ❌ Inject prompt guidance into `/implement` delegation template about recording work
- ❌ Enable agents to update task status: `bd update --status in_progress` as they work
- ❌ Test: Run `/implement` with beads tracking, verify discovered issues recorded
**Phase 3: Query-Based Task Fetching** (Weeks 7-9, deferred - Option B migration)
- ❌ Modify `/implement` to use `bd ready --json` instead of parsing tasks.md
- ❌ Implement task batching: agents fetch tasks in phases (Setup → Foundational → Stories)
- ❌ Enable dynamic task re-ordering based on discovered blockers (via beads dependency updates)

- ❌ This phase represents migration from Option A (coexistence) to Option B (full beads execution)
**Relationship to Async Work** (Tier 1.4 - Tier 1.6):
- Beads issues can be tagged `async-ready` during `/tasks` generation (integrates with Tier 1.5)
- Remote async agents query `bd ready --json --label async-ready` for delegatable work
- Webhook callbacks from remote agents update beads issue status (Tier 1.4)
- Full artifact context packaging (Tier 1.6) includes beads issue descriptions for agent briefing
**Success Metrics**:
- Phase 1 Complete: 100% of tasks.md tasks also exist as beads issues with correct dependencies
- Phase 1 Quality: Agents report improved context retention across `/tasks` regenerations

- Phase 2 Complete: Discovered issues automatically recorded to beads (no manual prompting)
- Phase 3 Complete: Agents prefer `bd ready --json` queries over tasks.md parsing
**Risks & Mitigation**:
- Risk: Agents delete/corrupt beads database (like markdown plans in Yegge's experience)
  - Mitigation: Beads backed by git, easy recovery; document git workflow in guide
- Risk: Tasks.md and beads get out of sync during development
  - Mitigation: Phase 1 only generates beads at `/tasks` time; `/implement` still uses tasks.md (Phase 3 solves this)
- Risk: Beads adoption overhead for users

  - Mitigation: Optional feature (graceful fallback); native beads install keeps dependencies simple

**Related Commands**:

- Complements `/trace` command (which captures session decisions) by making them queryable

- Enables future `/levelup.spec` enhancements (extract patterns from beads issue history)
- Works with existing `/implement` (Phase 1) and enhances it (Phase 2-3)
**References**:
- Beads Article: [https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a)
- Beads GitHub: [https://github.com/steveyegge/beads](https://github.com/steveyegge/beads)

**Notes**:

- Conservative scope (Option A) chosen to minimize risk: coexists with tasks.md, no breaking changes
- Full vision (Option B) available for future consideration: agents work directly from beads queries
- Implementation depends on users having `bd` CLI installed (documentation will cover setup)
- Aligns with Beads manifesto insight: agents work better with persistent, queryable issue trackers than stateless markdown

---

### **Executable Specifications** *(0% Complete)* - **NICE-TO-HAVE** - No implementation planned

**Status**: Deferred to focus on core workflow stability and high-priority items.

#### **Schema Generation** *(ThoughtWorks SDD - Executable Specifications)*

- **Description**: Auto-generate OpenAPI/JSON Schema from plan.md into `contracts/` folder to make specifications "executable" and enable automated API validation
- **Status**: ❌ Not planned for implementation
- **Rationale**:
  - Deferred to prioritize core workflow fixes (async context delivery)
  - Manual contract creation is sufficient for current use cases
  - Can be revisited after core functionality is stable and proven in production
- **Potential Value**: Would enable contract-driven development and automated API testing
- **Complexity**: Medium (requires plan.md parsing, schema generation, template integration)

#### **Spec-Code Drift Detector** *(ThoughtWorks SDD - Drift Detection)*

- **Description**: Automated detection of spec-code misalignment in `/analyze` command to catch divergences between documented requirements and actual implementation
- **Status**: ❌ Not planned for implementation
- **Rationale**:
  - Deferred to prioritize core workflow stability
  - Manual code reviews and `/analyze` command provide sufficient validation for now
  - Requires Schema Generation (above) as prerequisite
  - Can be revisited after core functionality is stable
- **Potential Value**: Would enable proactive identification of spec-code misalignment
- **Complexity**: Medium-High (requires code parsing, AST analysis, pattern matching)
- **Dependencies**: Would benefit from Schema Generation being implemented first

### **Architecture Description Command (/architect)** *(0% Complete)* - **HIGH PRIORITY** - Structural integrity for complex systems

- **Description**: Implement `/architect` command following Rozanski & Woods methodology to generate comprehensive Architecture Descriptions (ADs) that move beyond "Vibe Coding" and ensure structural integrity in complex systems (like the CNE Agent). This command focuses on global system boundaries and operational concerns, unlike feature-specific `/plan`.
- **Rozanski & Woods Viewpoints**:
  - Context View: Defines system scope and external entity interactions (Users, APIs, Cloud Providers)
  - Functional View: Details functional elements, responsibilities, and interfaces
  - Information View: Manages data storage, movement, and lifecycle
  - Concurrency View: Describes runtime processes, threading, and coordination
  - Development View: Sets constraints for developers (code organization, dependencies, CI/CD)
  - Deployment View: Defines physical environment (EKS clusters, VPCs, network interconnections)
  - Operational View: Covers operations, support, and maintenance in production
- **Architectural Perspectives (Cross-Cutting Qualities)**: Security, Performance & Scalability, Availability & Resilience, Evolution
- **BMAD Integration**: Operates at "A" (Architecture) layer, creates global context inherited by `/specify` and `/plan`
- **Traceability**: Establishes clear links from Stakeholder Concerns to Architectural Views (Factor IX implementation)
- **Output Location**: Generates artifacts in parallel `/architecture` folder separate from feature implementation specs
- **Benefits**: Transforms AI from simple coder to System Architect capable of describing complex, production-ready ecosystems
- **Implementation**: Template engine for 7 viewpoints, constraint injection into constitution.md, cross-view analysis linter in `/analyze`

### **Architecture Enhancements** *(33% Complete)* - **PARTIALLY COMPLETE** - Visual and methodology improvements

**Status**: Mermaid diagram support fully implemented (Jan 2026). C4 Model and methodology framework remain as future enhancements.

#### **Mermaid Diagram Auto-Generation** *(100% Complete)* - **COMPLETED** - Visual architecture documentation

- **Description**: Automatically generate Mermaid diagrams from architecture.md viewpoints to provide visual representation of system architecture alongside text descriptions
- **Status**: ✅ FULLY IMPLEMENTED (Jan 2026)
- **Key Components**:
  - ✅ Auto-generate Mermaid diagrams for all 7 viewpoints (Context, Functional, Information, Concurrency, Development, Deployment, Operational)
  - ✅ Support multiple diagram types: system context graphs, component diagrams, ER diagrams, sequence diagrams, dependency graphs, deployment graphs, operational flowcharts
  - ✅ ASCII fallback support for maximum compatibility
  - ✅ User-configurable diagram format via global config (`~/.config/specify/config.json`)
  - ✅ Lightweight Mermaid syntax validation with automatic ASCII fallback on failure
  - ✅ Integrated with `/architect init` and `/architect update` commands
  - ✅ Diagram examples embedded in architecture.md template
- **Benefits**:
  - ✅ Visual communication for stakeholders who prefer diagrams over text
  - ✅ Enables architecture validation through visual inspection
  - ✅ Improves architecture documentation accessibility for non-technical audiences
  - ✅ Supports standard Mermaid syntax for version control and diffing
  - ✅ Works in GitHub/GitLab markdown viewers and plain terminals
- **Implementation Details**:
  - Created `scripts/bash/mermaid-generator.sh` and `scripts/bash/ascii-generator.sh` (+ PowerShell equivalents)
  - Added `get_architecture_diagram_format()` and `validate_mermaid_syntax()` to common.sh/ps1
  - Updated `templates/architecture-template.md` with Mermaid diagram examples
  - Extended `templates/commands/architect.md` with diagram generation documentation
  - Global config defaults to `mermaid` format with easy switching to `ascii`

#### **C4 Model Template Support** *(0% Complete)* - **NICE-TO-HAVE** - Alternative architecture methodology

- **Description**: Add support for C4 Model (Context, Container, Component, Code) as an alternative to Rozanski & Woods methodology, allowing users to choose their preferred architecture documentation approach
- **Key Components**:
  - Create `templates/architecture-template-c4.md` following C4 Model structure with 4 levels (Context, Container, Component, Code)
  - Add methodology selection to `/architect init` command with `--methodology` parameter (choices: rozanski-woods, c4)
  - Store methodology preference in `.specify/config/config.json` under `architecture.methodology`
  - Update `/architect map`, `/architect update`, and `/architect review` to respect selected methodology
  - Support methodology-specific diagram generation when combined with Mermaid enhancement above
- **C4 Model Structure**:
  - **Level 1 - System Context**: Show system in context of users and other systems
  - **Level 2 - Container**: Show high-level technology choices and how containers communicate
  - **Level 3 - Component**: Show components within containers and their interactions
  - **Level 4 - Code**: Optional detailed class/component diagrams (typically generated from code)
- **Benefits**:
  - Provides scalable architecture visualization approach favored by many organizations
  - Simpler structure than Rozanski & Woods for smaller/medium systems
  - Better support for microservices and containerized architectures
  - Natural integration with Mermaid diagram generation (C4 diagrams are widely supported)
- **Implementation**:
  - Create new C4 template with appropriate sections and placeholders
  - Add methodology detection to architecture scripts
  - Update CLI to support `--methodology` parameter in init command
  - Maintain backward compatibility with existing Rozanski & Woods default
- **Status**: ❌ Not planned for immediate implementation (deferred as enhancement)
- **Rationale**: Rozanski & Woods provides comprehensive enterprise coverage; C4 Model support can be added based on user demand after core adoption

#### **Architecture Methodology Selection Framework** *(0% Complete)* - **NICE-TO-HAVE** - Extensible methodology support

- **Description**: Create extensible framework for supporting multiple architecture methodologies beyond Rozanski & Woods and C4 Model, allowing future addition of TOGAF, ADR-style, or custom methodologies
- **Key Components**:
  - Methodology registry system in configuration
  - Template discovery and validation mechanism
  - User-configurable default methodology per project
  - Methodology migration utilities (`/architect convert --from rozanski-woods --to c4`)
  - Validation rules per methodology in `/architect review`
- **Benefits**:
  - Future-proof architecture support for emerging methodologies
  - Enables teams to use organization-preferred frameworks
  - Supports methodology transitions during project lifecycle
- **Implementation**:
  - Abstract methodology-specific logic into pluggable handlers
  - Create methodology interface/contract for template authors
  - Support custom template directories for organization-specific methodologies
- **Status**: ❌ Not planned for immediate implementation (deferred as enhancement)
- **Rationale**: Single methodology (Rozanski & Woods) sufficient for now; extensibility can be added if multiple methodologies are commonly requested

**Cross-Reference**: These enhancements extend the **Optional Architecture Support** section (lines 135-148) which currently provides Rozanski & Woods templates. All enhancements maintain backward compatibility with existing architecture.md files.

### **Skills Package Manager** *(100% Complete)* - **COMPLETED** - Extends Factor XI Directives as Code

**Inspired by**: skills.sh Registry (<https://skills.sh>)

**Description**: A developer-grade package manager for agent skills that treats skills as versioned software dependencies with evaluation, lifecycle management, and dual registry integration. Enables teams to curate internal skills while leveraging the public skills.sh ecosystem.

**Implementation Status**: Fully implemented in v0.2.0 (released 2026-02-07) with 2,049 lines of Python code.

#### **Architecture Overview**

```text
┌────────────────────────────────────────────┐
│         skills.sh (Discovery Only)         │
│    Community registry (46K+ skills)        │
│    API: Search, metadata, ratings          │
│    Installation: Direct GitHub download    │
└────────────────────┬───────────────────────┘
                     │ HTTPS API
┌────────────────────▼───────────────────────┐
│   team-ai-directives/skills.json          │
│   Team's curated skill manifest           │
│   - Required skills (auto-install)        │
│   - Recommended skills                    │
│   - Internal skills (./skills/)           │
│   - Blocked skills list                   │
└────────────────────┬───────────────────────┘
                     │ Sync on init/specify
┌────────────────────▼───────────────────────┐
│       .specify/skills.json                │
│   Actually installed skill packages       │
│   Versioned, lockfile, cached in          │
│   .specify/skills/                        │
└────────────────────┬───────────────────────┘
                     │ Auto-activate per feature
┌────────────────────▼───────────────────────┐
│   specs/{feature}/context.md              │
│   Auto-injected relevant skills           │
│   Top 3 by relevance score (configurable) │
└────────────────────────────────────────────┘
```

#### **Implementation Components**

##### Phase 1: Core Infrastructure

- [ ] **Skills Manifest System** (skills.json)
  - Version: "1.0.0"
  - Skills registry with metadata
  - Lockfile for reproducible installs
  - Evaluation scores tracking
  
- [ ] **Skill Installer** (Python implementation)
  - Direct GitHub installation (no npm dependency)
  - Version resolution (semver support)
  - Caching in `.specify/skills/`
  - Cross-platform support (bash/PowerShell)

- [ ] **CLI Commands**

   ```bash
   specify skill search <query>          # Search skills.sh API
   specify skill install <ref>            # Install from GitHub
   specify skill list                     # Show installed
   specify skill remove <name>            # Remove skill
   specify skill update                   # Update skills
   specify skill check-updates            # Check team updates
   specify skill sync-team                # Sync with team manifest
   specify skill eval <skill>             # Evaluate skill quality
   ```

##### Phase 2: Dual Registry Integration

- [ ] **skills.sh API Client**
  - Search endpoint: `GET /api/search?q={query}`
  - Skill metadata: ratings, installs, categories
  - No installation dependency on skills.sh CLI
  - Cache search results locally

- [ ] **Team-AI-Directives Integration**

   ```json
   // team-ai-directives/skills.json
   {
     "version": "1.0.0",
     "source": "team-ai-directives",
     "skills": {
       "required": {
         "github:vercel-labs/agent-skills/react-best-practices": "^1.2.0"
       },
       "recommended": {
         "github:vercel-labs/agent-skills/web-design-guidelines": "~1.0.0"
       },
       "internal": {
         "local:./skills/dbt-workflow": "*"
       },
       "blocked": [
         "github:unsafe-org/deprecated-skill"
       ]
     },
     "policy": {
       "auto_install_required": true,
       "enforce_blocked": true,
       "allow_project_override": true
     }
   }
   ```

- [ ] **Sync Workflow**
  - `specify init` → Auto-install team required skills
  - `specify skill sync-team` → Update to team versions
  - `specify skill check-updates` → Preview changes
  - Policy enforcement: Blocked skills rejected with clear error

##### Phase 3: Per-Feature Skill Activation

- [ ] **Auto-Discovery Engine**
  - During `/spec.specify`: Analyze feature description
  - Calculate relevance score for each installed skill
  - Select top 3 skills above threshold (default 0.7, configurable)
  - Completely silent activation (no user prompts)

- [ ] **Context Injection**

   ```markdown
   ## specs/{feature}/context.md
   
   ## Relevant Skills (Auto-Detected)
   - react-best-practices@1.2.0 (confidence: 0.95)
   - typescript-guidelines@1.0.0 (confidence: 0.82)
   - security-rules@2.0.1 (confidence: 0.78)
   
   *These skills were automatically selected based on your feature description.*
   ```

- [ ] **User Override Support**
  - Manual edits to context.md preserved on re-run
  - Config: `preserve_user_edits: true`
  - Optional: `specify skill activate <skill>` for manual selection

##### Phase 4: Skill Evaluation Framework

- [ ] **Review Evaluation (Structure Quality)**
  - Frontmatter validation (20 pts)
  - Content organization (30 pts)
  - Self-containment check (30 pts)
  - Documentation quality (20 pts)
  - Total: 100-point scale

- [ ] **Task Evaluation (Behavioral Impact)**
  - **Approach**: Leverage existing `@agentic-sdlc-spec-kit/evals/` framework
  - Create `evals/configs/promptfooconfig-skill.js` with skill-specific test scenarios
  - A/B testing: baseline agent vs. skill-enhanced agent
  - Metrics: API correctness, best practices, output quality
  - Use custom Python graders in `evals/graders/skill_graders.py`
  - **Rationale**: Reuse existing PromptFoo + annotation tool infrastructure instead of building separate evaluation system

- [ ] **Evaluation CLI**

   ```bash
   specify skill eval --review ./my-skill
   specify skill eval --task ./my-skill --scenarios ./tests/
   specify skill eval --full ./my-skill
   ```

#### **Configuration**

```json
// ~/.config/specify/config.json
{
  "skills": {
    "auto_activation_threshold": 0.7,
    "max_auto_skills": 3,
    "preserve_user_edits": true,
    "registry_url": "https://skills.sh/api",
    "evaluation_required": false
  }
}
```

#### **Benefits**

1. **Zero NPM Dependencies**: Direct GitHub installation, pure Python/bash
2. **Team Curation**: Required/recommended skills enforce team standards
3. **Auto-Activation**: Skills automatically matched to features
4. **Quality Assurance**: Built-in evaluation framework
5. **Dual Registry**: Public skills.sh + Private team skills
6. **Policy Enforcement**: Block unsafe skills, enforce versions

#### **Integration Points**

- **specify init**: Creates skills.json, installs team required skills
- **/spec.specify**: Auto-discovers and injects relevant skills
- **/plan, /implement**: Loads activated skills from context.md
- **team-ai-directives**: Skills.json alongside .mcp.json
- **evals/**: Task evaluation scenarios and graders

#### **Files Created**

- `src/specify_cli/skills/` - Core implementation
- `scripts/bash/skill-*.sh` - Bash wrappers
- `scripts/powershell/skill-*.ps1` - PowerShell wrappers
- `templates/skills/` - Skill templates
- `.opencode/plans/` - Implementation specs (already created)

#### **References**

- Skills.sh Registry: <https://skills.sh>
- Agent Skills Format: <https://agentskills.io/>
- Existing Implementation: `.opencode/plans/skill-*.md`, `skill_manager.py`

#### **Future Enhancements**

##### **Private Registry Support** *(Not Started)* - **MEDIUM PRIORITY** - Enterprise skill hosting

**Description**: Support for self-hosted or enterprise-specific skill registries beyond public GitHub/skills.sh. Enables organizations to host proprietary internal skills in private repositories.

**Examples**:

- **Internal GitHub/GitLab Enterprise**: `github:company-internal.domain.com/org/repo/skill`
- **Nexus/Artifactory**: Self-hosted package manager for versioned skill artifacts
- **Private skills.sh instance**: Enterprise deployment of skills registry API
- **S3/Cloud storage**: Versioned skill artifacts with metadata indexing

**Current Support**:

- ✅ GitHub Enterprise (via `github:host.com/org/repo/skill`)
- ✅ GitLab self-hosted (via `gitlab:host.com/org/repo/skill`)
- ✅ Local paths (via `local:./path`)
- ❌ Private registry API (Nexus, Artifactory, custom APIs)

**Implementation Requirements**:

- Registry API client abstraction (extend `SkillsRegistryClient`)
- Authentication handling (tokens, SSH keys, credential helpers)
- Version resolution for private registries
- Enterprise skills.sh instance support
- Configuration for registry endpoints in `config.json`

**Configuration Example**:

```json
{
  "skills": {
    "registries": [
      {
        "name": "company-internal",
        "type": "nexus",
        "url": "https://nexus.company.com/repository/skills",
        "auth": {
          "type": "token",
          "env_var": "NEXUS_TOKEN"
        }
      }
    ]
  }
}
```

**Use Case**: Enterprise teams need to host proprietary skills not suitable for public GitHub or skills.sh (e.g., internal security guidelines, proprietary framework patterns).

---

### **Hook-Based Tool Auto-Activation** *(0% Complete)* - **MEDIUM PRIORITY** - Extends Factor X Strategic Tooling

- **Description**: Implement hook-based systems that automatically analyze user prompts and suggest relevant AI tools/agents based on project context, similar to Claude's UserPromptSubmit hooks. This reduces manual agent selection and ensures optimal tool usage.
- **Key Components**:
  - Prompt analysis hooks that detect context patterns (file types, project structure, task types)
  - Automatic agent/tool suggestions based on skill-rules.json style configuration
  - Integration with existing agent context files for seamless activation
- **Benefits**: Eliminates "which agent should I use?" friction, improves workflow efficiency
- **Implementation**: Add to Factor X with hook templates and activation rules, extending the current AGENTS.md framework
- **Reference**: Based on patterns from <https://github.com/diet103/claude-code-infrastructure-showcase>

### **Agent Skill Modularization** *(0% Complete)* - **LOW PRIORITY** - Extends Factor XI Directives as Code

- **Description**: Implement modular agent skill patterns where complex agent capabilities are broken into smaller, reusable skill modules that can be loaded progressively, similar to Claude's skill architecture.
- **Key Components**:
  - Skill module templates with main + resource file structure
  - Agent-specific skill activation rules
  - Version-controlled skill libraries for different agent types
- **Benefits**: Enables complex agent behaviors without hitting context limits, improves skill reusability across projects
- **Implementation**: Add to Factor XI with skill templates and modular loading patterns, extending the current agent file template system
- **Reference**: Based on patterns from <https://github.com/diet103/claude-code-infrastructure-showcase>

#### **Context Intelligence & Optimization** *(0% Complete)* - **HIGH PRIORITY** - Cost & Accuracy

- ❌ **Smart Context Windowing**: Logic to slice `spec.md` and `plan.md` based on the active User Story phase during implementation to save tokens.
- ❌ **Semantic Diffs**: `specify diff` command to summarize behavioral changes in specs rather than just line-diffs.
- ❌ **Directive Embeddings**: (Future) Local vector index for `team-ai-directives` to support large governance repositories without context flooding.
- ❌ **Build Skill from Project Patterns**: Analyze project implementation patterns (from spec.md, plan.md, tasks.md, code artifacts) and auto-generate reusable skill packages that can be contributed to team-ai-directives
  - Pattern extraction: Identify recurring implementation patterns, code structures, testing approaches from completed features
  - Skill scaffolding: Auto-generate SKILL.md with trigger keywords, references, and scripts based on detected patterns
  - Contribution workflow: Create PR-ready skill packages with proper structure for team-ai-directives submission
  - Skill templates: Provide templates for common skill types (testing patterns, code generators, validation rules)
  - Integration with `/levelup.spec`: Extract patterns from session traces and suggest CDR creation during levelup
  - Quality validation: Ensure generated skills meet team-ai-directives standards before contribution

#### **Resilience & Self-Healing** *(0% Complete)* - **MEDIUM PRIORITY** - Automation robustness

- ❌ **Triage Escalation Protocol**: Automated promotion of failing `[ASYNC]` tasks to `[SYNC]` status in `tasks_meta.json` with user notification.

**Assessment**: Not currently needed. Core workflow (dual execution loop, MCP integration) should be completed first. Existing terminal interface with agent context files provides sufficient IDE support. Consider lightweight integration only after core adoption is proven.

### **Repository Governance Automation** *(0% Complete)* - **FUTURE ENHANCEMENT** - Enterprise governance

- ❌ **Enhanced Governance**: Advanced team directive management (optional enterprise feature)

#### **Team Directives Layout Awareness**

- ❌ **Structural Repository Scans**: Automated analysis of team-ai-directives structure
- ❌ **Layout Validation**: Consistency checking across team repositories
- ❌ **Template Enforcement**: Standardized repository organization

#### **Team Directives Directory Restructuring** *(0% Complete)* - **MEDIUM PRIORITY**

- ❌ **Separate Cloning Location**: Move `--team-ai-directive` cloning from `.specify/` to dedicated `.team-directives/` directory to prevent repository mixture
- ❌ **Directory Isolation**: Maintain clean separation between project scaffolding and team governance repositories
- ❌ **Migration Support**: Provide migration utilities for existing projects with directives in `.specify/`
- ❌ **Path Resolution Updates**: Update all team directive path resolution logic to use new directory structure

#### **Referenceable Cross-Referencing System** *(0% Complete)* - **HIGH PRIORITY**

- **Description**: Implement a structured reference format (`@rule:relative_filepath`) for cross-referencing within team-ai-directives to eliminate duplication, improve navigation, and enable future tooling integration.
- **Key Components**:
  - Define reference syntax: `@rule:path/relative/to/rules/dir.md` for rules, extend to `@example:`, `@persona:` as needed
  - Update existing files to use references instead of duplicating content (start with null safety overlap)
  - Add validation in CONTRIBUTING.md or CI to enforce references and prevent broken links
  - Enable tooling integration for automatic link resolution and IDE support
- **Benefits**: Eliminates duplication across atomic/composite sections, enhances maintainability, enables scalable directive repositories, supports Factor XI Directives as Code
- **Implementation**: Establish conventions, apply to overlap fixes, integrate with governance process, build tooling support

#### **Feature-Level Mode Configuration** *(0% Complete)* - **FUTURE ENHANCEMENT**

- ❌ **Per-Feature Mode Settings**: Allow different workflow modes (build/spec) per feature instead of project-wide
- ❌ **Feature Mode Inheritance**: Default to project mode with ability to override per feature
- ❌ **Mode Compatibility Validation**: Ensure feature modes are compatible with project infrastructure
- ❌ **Mode Migration Support**: Tools to change feature modes mid-development

**Note**: Architecture support is now available in all modes, not tied to specific workflow modes.

#### **Issue Tracker Automation** *(0% Complete)* - **FUTURE ENHANCEMENT** - Separate from documentation updates

- ❌ **Automated Status Updates**: Sync documentation changes with issue status (GitHub/Jira/Linear)
- ❌ **Comment Synchronization**: Auto-post documentation updates as issue comments
- ❌ **Cross-Platform Compatibility**: Unified API for different issue trackers
- ❌ **Workflow Integration**: Optional integration with documentation automation pipeline

#### **Issue Tracker Enhancements** *(0% Complete)* - **FUTURE ENHANCEMENT**

- ❌ **Trace Visualization**: Dashboard showing spec-issue relationships
- ❌ **Lifecycle Trace Updates**: Automatic issue status updates during development lifecycle

#### **Issue Tracker Labeling** *(0% Complete)* - **FUTURE ENHANCEMENT**

- ❌ **Issue Label Application**: `apply_issue_labels()` for `async-ready` and `agent-delegatable` labels
- ❌ **Spec vs Task Complexity**: Handle original spec issues vs. generated implementation tasks
- ❌ **External Agent Integration**: Enable monitoring systems to pick up labeled issues
- ❌ **Workflow Compatibility**: Ensure compatibility with natural language delegation approach

#### **Agent-Optimized Testing Infrastructure** *(0% Complete)* - **MEDIUM PRIORITY**

- ❌ **Selective Test Execution**: Enable agents to run targeted test subsets during development (pytest integration)
- ❌ **Interactive Testing Support**: Development server startup guides and Playwright/curl integration for real-time testing
- ❌ **Enhanced Error Messages**: Rich assertion failures with contextual debugging information for agent comprehension
- ❌ **Test Suite Optimization**: Agent-friendly test organization and execution patterns

#### **GitHub Issues Integration Enhancement** *(0% Complete)* - **MEDIUM PRIORITY**

- ❌ **Direct Issue URL Processing**: Seamless integration of GitHub issue URLs into agent context
- ❌ **Issue-Driven Development**: Enhanced workflow for issue-to-spec conversion and tracking
- ❌ **Context Preservation**: Maintain issue relationships throughout development lifecycle

#### **Code Quality Automation** *(0% Complete)* - **LOW PRIORITY**

- ❌ **Agent-Driven Linting**: Automated code quality checks with agent-executable linters and formatters
- ❌ **Type Checking Integration**: Real-time type validation during agent code generation
- ❌ **Quality Gate Automation**: Pre-commit hooks for agent-generated code validation

---

## 📈 **IMPLEMENTATION STATUS SUMMARY**

|Category|Completion|Status|
|--------|----------|------|
|**CLI Infrastructure**|100%|✅ Complete|
|**MCP Integration**|100%|✅ Complete|
|**Constitution System**|80%|⚠️ Partially Complete|
|**Workflow Modes**|100%|✅ Complete|
|**AI Session Context Management**|100%|✅ Complete|
|**Spec-Code Synchronization**|100%|✅ Complete|
|**Local Parallel Execution**|100%|✅ Complete|
|**Dual Execution Loop**|100%|✅ Complete|
|**Triage Framework**|100%|✅ Complete|
|**Risk-Based Testing**|100%|✅ Complete|
|**12-Factor Alignment**|100%|✅ Complete|
|**Command Prefix Migration**|0%|🚀 Next Phase|
|**Iterative Development**|100%|✅ Complete|

|**Enhanced Traceability**|60%|⚠️ Partially Complete|
|**Strategic Tooling**|70%|⚠️ Partially Complete|
|**Session Trace Command**|100%|✅ Complete|
|**Tier 1: Async Context Delivery & Remote Integration**|0%|🔄 Current Phase (CRITICAL)|
|**Tier 2: Sub-Agent Coordination Framework**|0%|🔄 Current Phase (HIGH)|
|**Tier 3: Model Selection Strategy**|0%|🔄 Current Phase (MEDIUM)|
|**Build Mode Bug Fix**|100%|✅ Complete|
|**Levelup Build Mode**|100%|✅ Complete|
|**Persistent Issue ID**|0%|🔄 Current Phase|
|**Build Mode "GSD" Upgrade**|100%|✅ Complete|
|**Architecture Support + Mermaid Diagrams**|100%|✅ Complete|
|**Architecture Command Restructuring**|0%|🔄 Current Phase (HIGH)|
|**Three-Pillar Validation**|100%|✅ Complete|
|**Context Intelligence & Optimization**|0%|🔄 Current Phase|
|**Spec Management**|0%|🔄 Current Phase|
|**Workflow Utilities**|0%|🔄 Current Phase|
|**Command Prefix Migration**|0%|🚀 Next Phase (Deferred)|
|**Architecture Enhancements**|0%|🆕 Future Phase (Nice-to-have)|
|**Hook-Based Tool Auto-Activation**|0%|🆕 Future Phase|
|**Agent Skill Modularization**|0%|🆕 Future Phase|
|**Agent Testing Infrastructure**|0%|🆕 Future Phase|
|**GitHub Issues Enhancement**|0%|🆕 Future Phase|
|**Code Quality Automation**|0%|🆕 Future Phase|
|**Resilience & Self-Healing**|0%|🆕 Future Phase|
|**IDE Integration**|0%|🆕 Future Phase|

**Overall Implementation Status**: ~90% Complete

- **Core Workflow**: 100% Complete (constitution, dual execution, MCP integration, workflow orchestration)
- **12F Factors III-V (Workflow)**: 100% Complete - Mission definition, planning, execution, and orchestration work effectively
- **Knowledge Management**: 100% Complete (AI session context packets, team directives analysis, reusable knowledge sharing)
- **MCP Infrastructure**: 100% Complete (issue tracker, async agent, and git platform integrations)
- **SDD Optimization**: 100% Complete (workflow flexibility with comprehensive iterative development, enhanced UX, and framework option validation)
- **Complexity Solutions**: ~90% Complete (core workflow with auto-detecting post-implementation analysis, iterative development, enhanced rollback, configurable framework options - HIGH PRIORITY response to user feedback; some automation features still need implementation)
- **Current Phase Priorities**: 3 TIERED INITIATIVES (Tier 1: CRITICAL async delivery, Tier 2: HIGH sub-agent coordination, Tier 3: MEDIUM model selection) + 1 HIGH (persistent issue ID) + 3 MEDIUM features - **PRIMARY FOCUS with parallel development**
- **Next Phase Priorities**: Command prefix migration (deferred to reduce churn while fixing blockers)
- **Future Enhancements**: 0% Complete (minimal enterprise features only)
- **Deferred Features**: IDE Integration & overkill enhancements (removed to maintain focus)

**Note**: @agentic-sdlc-12-factors serves dual purposes as methodology documentation and reference implementation, providing working examples and command templates that accelerate Spec Kit development. **Core 12F workflow Factors III-V are 100% complete** - mission definition, planning, execution, and orchestration work effectively through existing commands, git infrastructure, and command-to-command guidance system. **Workflow orchestration implemented** through CLI workflow overview, context-aware next actions, and sequential command guidance - no advanced visualization or blocking validation needed. **All overkill features eliminated** - advanced monitoring, interactive tutorials, evaluation suites, and context engineering removed to maintain razor focus on essential SDD functionality. Key SDD flexibility features are implemented via `/clarify` (iterative refinement), `/analyze` (consistency validation with auto-detection and post-implementation analysis), and `/checklist` (requirements quality testing with framework option validation). **Complexity reduction prioritized** based on user feedback analysis - configurable workflow with comprehensive iterative development, **iterative development is comprehensively supported** through git-managed specs, branch isolation, clarify command modifications, and analyze cross-references, and configurable framework options make TDD/contracts/data models/risk-based testing opt-in rather than mandatory, with checklist validation ensuring enabled options are properly specified in requirements. **AI session context management is implemented** through the levelup command that creates reusable knowledge packets and analyzes contributions to team directives for cross-project learning. **Issue tracker traceability is intentionally separate** from documentation automation for modularity, reliability, and independent adoption. **Command prefix migration prioritized as CRITICAL** due to immediate user impact as a breaking change affecting fork differentiation. Rich context delegation provides superior AI assistance compared to issue labeling approaches.

**Verification Status**: Core infrastructure is well-implemented and verified, but some automation features (particularly in traceability and strategic tooling) require additional development to reach full completion. The roadmap now accurately reflects the distinction between configuration scaffolding and functional automation.

## 🎯 **PRIORITY RANKING** - Refined based on user impact and workflow blockers

**🔄 CURRENT PHASE (Primary Focus):**

1. **CRITICAL**: Tier 1 - Async Context Delivery & Remote Agent Integration (0% → 100%) - Unblocks full async workflow with remote agents + multi-tracker issue creation
2. **HIGH**: Tier 2 - Sub-Agent Coordination Framework (0% → 100%) - Intelligent local & remote task orchestration with context-aware selection
3. **MEDIUM**: Tier 3 - Model Selection Strategy per Command (0% → 100%) - Cost optimization & performance tuning across all workflow commands
4. **HIGH**: Persistent issue ID storage enhancement (0% → 100%) - Issue-tracker-first workflow improvement
5. **HIGH**: Architecture Command Restructuring (0% → 100%) - ArcKit-aligned governance with interactive ADR workflow
6. **✅ COMPLETED**: Build mode migration (100%) - Removed build mode from core commands
7. **✅ COMPLETED**: Levelup command simplification (100%) - Unified to spec-only workflow
8. **✅ COMPLETED**: Optional Architecture Support (100%) - Architecture commands work with spec mode
   - ✅ Architecture loading matches constitution pattern
   - ✅ Silent operation - no warnings when files missing
   - ⏭️  Schema generation (deferred - future enhancement)
   - ⏭️  Drift detection (deferred - future enhancement)
7. **MEDIUM**: Context Intelligence & Optimization (0% → 100%) - Directives scanner + compliance validation
8. **MEDIUM**: Multi-tracker task-to-issues extension (0% → 100%) - Enhanced traceability across platforms
9. **MEDIUM**: Spec management & cleanup (0% → 100%) - Workflow maintenance
10. **MEDIUM**: Workflow Utilities (0% → 100%) - /debug and /todo commands

**🚀 NEXT PHASE (Deferred):**

1. **MEDIUM**: Command prefix migration (0% → 100%) - Breaking change, fork differentiation (deferred to reduce churn)

**🆕 FUTURE PHASE (Complete After Current Phase):**

1. **NICE-TO-HAVE**: Additional architecture enhancements (optional)
   - ✅ Mermaid diagram auto-generation (COMPLETED Jan 2026)
   - C4 Model template support as alternative to Rozanski & Woods (deferred)
   - Architecture methodology selection framework for extensibility (deferred)
2. **MEDIUM**: Hook-based tool auto-activation (0% → future consideration)
3. **MEDIUM**: Agent-optimized testing infrastructure (0% → future consideration)
4. **MEDIUM**: GitHub issues integration enhancement (0% → future consideration)
5. **MEDIUM**: Resilience & Self-Healing (0% → future consideration)
6. **LOW**: Agent skill modularization (0% → future consideration)
7. **LOW**: Code quality automation (0% → future consideration)
8. **LOW**: Feature-level mode configuration (0% → future consideration)
9. **LOW**: IDE Integration & advanced cockpit features (0% → future consideration)
