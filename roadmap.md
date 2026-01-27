# 📊 **Agentic SDLC Spec Kit - Structured Roadmap**

## ✅ **COMPLETED ITEMS** (Fully Implemented & Verified)

### **CLI Infrastructure & Theming**

- ✅ **Orange Theme Restoration**: Centralized `ACCENT_COLOR` and `BANNER_COLORS` constants in CLI
- ✅ **Team Directives Integration**: Local path support and remote cloning for team-ai-directives
- ✅ **Context Readiness Enforcement**: `/specify`, `/plan`, `/tasks`, `/implement` validate `context.md` completeness

### **MCP Server Integration**

- ✅ **Issue Tracker MCP**: `--issue-tracker` parameter supporting github/jira/linear/gitlab with `.mcp.json` configuration
- ✅ **Async Agent MCP**: `--async-agent` parameter for jules/async-copilot/async-codex with MCP server setup
- ✅ **Git Platform MCP**: `--git-platform` parameter supporting github/gitlab with `.mcp.json` configuration for PR/merge request operations
- ✅ **Team Directives MCP Merging**: Template inheritance for consistent MCP configurations

### **Constitution Management System** *(80% Complete)*

- ✅ **Automated Constitution Assembly**: Team constitution inheritance with validation
- ⚠️ **Constitution Evolution Tracking**: Basic implementation exists but limited functionality
- ✅ **Project Artifact Scanning**: Constitution enhancement suggestions from codebase analysis
- ⚠️ **Validation Framework**: Basic structure exists but limited quality/compliance checking
- ✅ **Levelup Integration**: Constitution evolution through feature learnings

### **Workflow Modes Feature** - **COMPLETED**

- ✅ **Mode Switching Command**: `/mode` command to set build/spec workflow modes and framework options (spec mode is default)
- ✅ **Consolidated Configuration**: Unified `.specify/config/mode.json` with `options` section replacing separate `opinions.json`
- ✅ **Framework Options**: Configurable TDD, contracts, data models, and risk-based testing via `/mode` command
- ✅ **Mode State Persistence**: Store current mode, options, and history in single config file
- ✅ **Mode-Aware Commands**: `/specify`, `/clarify`, `/plan`, `/implement`, `/analyze` commands adapted for mode-aware behavior
- ✅ **Mode Validation**: Commands validate mode compatibility and provide guidance
- ✅ **Complexity Reduction**: Allow users to choose workflow complexity level (spec-driven vs lightweight)
- ✅ **Auto-Detection**: `/analyze` automatically detects pre vs post-implementation context
- ✅ **Documentation**: Mode functionality documented in README.md and quickstart.md
- ✅ **12-Factors Integration**: Workflow modes documented in methodology documentation

- ✅ **Checklist Integration**: `/checklist` command adapts validation based on enabled framework options

### **AI Session Context Management** *(100% Complete)* - **HIGH PRIORITY** - Knowledge management and team learning

- ✅ **Levelup Command Implementation**: `/levelup` command creates reusable AI session context packets
- ✅ **MCP Integration for Git Operations**: Uses Git platform MCP servers for PR/merge request operations
- ✅ **Team Directives Analysis**: Analyzes session context for contributions to rules, constitution, personas, and examples
- ✅ **Reusable Knowledge Packets**: Creates context packets for cross-project AI agent learning
- ✅ **Comprehensive Issue Summaries**: Generates detailed session summaries for issue tracker comments

### **Spec-Code Synchronization** *(100% Complete)* - **MEDIUM PRIORITY** - Documentation automation

- ✅ **Git Hook Integration**: `--spec-sync` option installs pre-commit/post-commit/pre-push hooks
- ✅ **Automatic Change Detection**: Detects code changes and queues documentation updates
- ✅ **Non-blocking Updates**: Background automation that preserves developer workflow
- ✅ **Mode-aware Batch Review**: Queued updates reviewed at natural breakpoints

### **Basic Local Parallel Execution ([P] Markers)**

- ✅ **Task Generation**: `/tasks` creates tasks with [P] markers for parallelizable tasks
- ✅ **Parallel Execution**: `/implement` recognizes [P] markers and executes concurrently
- ✅ **File-based Coordination**: Tasks affecting same files run sequentially
- ✅ **User Story Organization**: Parallel execution within story phases

### **Risk-Based Testing Framework**

- ✅ **Risk Extraction**: Standardized severity levels (Critical/High/Medium/Low) in `check-prerequisites.sh`
- ✅ **Automated Test Generation**: `generate-risk-tests.sh` creates targeted test tasks
- ✅ **Mode Integration**: Risk-based testing configurable via `/mode --risk-tests` command
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
- ✅ **Analyze Command Cross-Reference**: Performs consistency analysis with remediation suggestions
- ✅ **Post-Implementation Analysis**: Extended `/analyze` command with auto-detection for pre/post-implementation context
- ✅ **Documentation Evolution**: Specs and plans actively evolve through git commits during development
- ✅ **Rollback Integration**: Git rollback capabilities preserve documentation state consistency
- ✅ **Automated Documentation Updates**: Background, non-blocking automation that detects code changes and queues documentation updates for review at natural breakpoints (pre-commit/push), with CLI-injected git hooks and mode-aware behavior

#### **Workflow Stage Orchestration** *(100% Complete)* - **COMPLETED** - Workflow completeness through command-to-command guidance

- ✅ **Git-Based Rollback**: Code and documentation rollback via git commands (already working)
- ✅ **Command-to-Command Guidance**: Sequential workflow guidance through existing command outputs (specify → clarify/plan → tasks → implement)
- ✅ **CLI Workflow Overview**: Complete SDD workflow steps displayed on project initialization
- ✅ **Context-Aware Next Actions**: Commands provide mode-aware guidance for next steps (e.g., /analyze auto-detects pre/post-implementation)

#### **Configurable Framework Options** *(100% Complete)* - **MEDIUM PRIORITY** - Addresses over-opinionated critique

- ✅ **Opt-in Architecture Patterns**: TDD, contracts, data models, risk-based testing become user-configurable via `/mode` command
- ✅ **Consolidated Configuration**: Unified `mode.json` with `options` section (renamed from `opinions.json`)
- ✅ **Mode-Based Preferences**: Different defaults for build vs spec modes
- ✅ **Reduced Mandatory Options**: Core workflow preserved, options made optional
- ✅ **User-Driven Defaults**: Users can override mode defaults with custom settings

---

## 🔄 **CURRENT PHASE** (Complete After Next Phase)

### **Enhanced Traceability Framework** *(60% Complete)* - **MEDIUM PRIORITY** - Core 12F Factor IX implementation

- ✅ **MCP Configuration Foundation**: Issue tracker integration ready (GitHub/Jira/Linear/GitLab)
- ⚠️ **@issue-tracker Prompt Parsing**: Referenced in templates but actual parsing logic not implemented
- ❌ **Automatic Trace Creation**: No evidence of automatic spec-issue linking implementation
- ❌ **Smart Trace Validation**: Enhanced `/analyze` claims trace detection but implementation not found
- ❌ **Task-to-Issues Command**: Template exists but actual implementation script missing

### **Architecture Description (AD) Mode** *(0% Complete)* - **HIGH PRIORITY** - Enterprise Architecture Support

- ❌ **CLI Config Update**: Add `ad` to `mode_defaults` in `src/specify_cli/__init__.py` with all options enabled by default.
- ❌ **Architecture Templates**: Create `templates/architecture-template.md` (Global V&P Context) and `templates/plan-template-ad.md` (Feature V&P Zoom-in).
- ❌ **Architect Command**: Create `templates/commands/architect.md` for generating the global `memory/architecture.md`.
- ❌ **Setup Scripts**: Create `scripts/bash/setup-architecture.sh` and `scripts/powershell/setup-architecture.ps1`.
- ❌ **Plan Script Updates**: Update `scripts/bash/setup-plan.sh` and `scripts/powershell/setup-plan.ps1` to detect `ad` mode and use the new templates.
- ❌ **Mode Documentation**: Update `templates/commands/mode.md` to include AD mode description.
- ❌ **Codebase Mapper**: Implement `/map` command to scan existing code and auto-populate `memory/architecture.md` (Context View) and `memory/tech-stack.md`. Essential for Brownfield projects (legacy code analysis and documentation).

#### **Strategic Tooling Improvements** *(60% Complete)* - **MEDIUM PRIORITY**

- ❌ **Tool Selection Guidance**: Claims implementation but no actual guidance logic found
- ✅ **Global Configuration Support**: All configuration now stored globally in `~/.config/specify/config.json` (XDG compliant). Single shared configuration across all projects. Linux: `$XDG_CONFIG_HOME/specify/config.json`, macOS: `~/Library/Application Support/specify/config.json`, Windows: `%APPDATA%\specify\config.json`.
- ✅ **CLI Config Refactor**: Updated `src/specify_cli/__init__.py` to use `platformdirs` for XDG-compliant global path resolution.
- ✅ **Script Config Resolution**: Updated `common.sh` and `common.ps1` with `get_global_config_path()` / `Get-GlobalConfigPath` helper functions.
- ✅ **Config Consolidation**: Successfully implemented as single unified configuration file to reduce complexity and improve maintainability
- ❌ **Atomic Commits Config**: Add `atomic_commits` boolean option to `config.json` (default: `false`). Externalize as global configuration available to all workflow modes (build/spec/ad) with per-mode override capability.
- ❌ **Execution Logic**: Update `scripts/bash/tasks-meta-utils.sh` and `scripts/powershell/common.ps1` to read `atomic_commits` config and inject constraint into `generate_delegation_prompt()` when enabled.

**NOTE**: User settings like `config.json` should remain user-specific and not tracked in git. However, team governance files like `.specify/constitution.md` should be version-controlled. Consider relocating constitution.md to a more appropriate location that clearly distinguishes it from user-specific configuration.

#### **Build Mode "GSD" Upgrade** *(0% Complete)* - **HIGH PRIORITY** - High-velocity execution mode

- ❌ **GSD Defaults**: Update `src/specify_cli/__init__.py` to set `atomic_commits: true` by default specifically for `build` mode (while keeping it `false` for `spec` and `ad` modes).
- ❌ **Senior Engineer Templates**: Overhaul `templates/spec-template-build.md` and `templates/plan-template-build.md` to use the "Senior Engineer" persona (brief, technical, imperative) and remove all "filler" sections (motivation, context narrative, etc.).
- ❌ **No-Verify Logic**: Update `implement` scripts (`scripts/bash/implement.sh` and `scripts/powershell/implement.ps1`) to skip the "Micro-Review" step when in `build` mode (trusted execution), relying solely on Atomic Commit verification for quality assurance.
- ❌ **Documentation**: Update `templates/commands/mode.md` to rebrand Build Mode as "GSD Mode: High velocity, atomic commits, minimal documentation."

#### **Context Intelligence & Optimization** *(0% Complete)* - **MEDIUM PRIORITY** - Smart context management and compliance validation

- ❌ **Directives Scanner**: Create `scripts/bash/scan-directives.sh` (and ps1) to list all available assets in `team-ai-directives` as JSON.
- ❌ **Silent Context Injection**: Update `/speckit.specify` to run the scanner and *silently* populate `context.md` with relevant Directives based on the user prompt (no user interaction required).
- ❌ **Compliance Gate**: Update `/speckit.clarify` to validate the generated Spec against the Directives in `context.md` and pause ONLY if contradictions are found.

#### **Workflow Utilities** *(0% Complete)* - **MEDIUM PRIORITY** - Specialized workflow commands for focused development

- ❌ **Systematic Debugging**: Implement `/debug` command with a "Scientific Method" workflow (Symptoms -> Hypothesis -> Test) that runs in a persistent session.
- ❌ **Idea Backlog**: Implement `/todo` command to capture out-of-context ideas to a separate list without derailing the current active task.

#### **Persistent Issue ID Storage Enhancement** *(0% Complete)* - **HIGH PRIORITY** - Issue-tracker-first workflow improvement

- ❌ **Add --issue Parameter to Specify**: Implement `--issue ISSUE-ID` parameter for specify command to fetch issue data from configured tracker
- ❌ **Store Issue Context Persistently**: Save issue ID, tracker type, and metadata in context.md for automatic propagation
- ❌ **Automatic Issue Propagation**: Subsequent commands (/clarify, /plan, /tasks, /analyze, /levelup) automatically use stored issue context
- ❌ **Dynamic MCP Tool Resolution**: Use declarative tools pattern with configuration-driven tool selection based on detected issue tracker
- ❌ **Multi-Tracker Support**: Support GitHub/Jira/Linear/GitLab issue formats with appropriate MCP tool routing

#### **Levelup Command Build Mode Compatibility** *(0% Complete)* - **HIGH PRIORITY** - AI session context management blocker

- ❌ **Make Levelup Mode-Aware**: Update `/levelup` command to work in both build and spec modes
- ❌ **Build Mode Levelup Path**: Adapt levelup for build mode (only requires spec.md, skip plan.md/tasks.md validation)
- ❌ **Spec Mode Levelup Path**: Maintain current comprehensive levelup for spec mode (requires all artifacts + task completion)
- ❌ **Context Packet Adaptation**: Create appropriate AI session context packets for each mode's workflow patterns
- ❌ **Test Both Mode Levelups**: Verify levelup works in build mode and maintains full functionality in spec mode

#### **Build Mode Workflow Bug Fix** *(0% Complete)* - **HIGH PRIORITY** - Critical workflow blocker

- ❌ **Fix Build Mode specify→implement Flow**: Implement command requires tasks.md but build mode skips plan/tasks phases
- ❌ **Mode-Aware Task Validation**: Skip --require-tasks in build mode to enable lightweight specify→implement workflow
- ❌ **Update implement.md Template**: Add build mode execution path that works without tasks.md
- ❌ **Fix Build Mode Checking in Analyze and Clarify**: Ensure analyze and clarify commands properly check build mode before execution
- ❌ **Test Build Mode Workflow**: Verify specify → implement works in build mode without tasks.md

#### **Async Task Context Delivery Architecture** *(0% Complete)* - **CRITICAL PRIORITY** - Makes async functionality non-functional

- ❌ **MCP Task Submission Protocol**: Define standard MCP tools for async task submission (submit_task, check_status, get_result)
- ❌ **Remote Context Delivery Mechanism**: Implement file upload, URL references, or embedded payload for spec content delivery to remote MCP servers
- ❌ **Repository Context Provision**: Provide repository URL, branch, and authentication for remote agents to access committed specs
- ❌ **Webhook/Callback Integration**: Establish completion notification and result retrieval from remote async agents
- ❌ **Agent-Specific MCP Tool Implementation**: Custom MCP tool implementations for jules, async-copilot, async-codex

#### **Multi-Tracker Task-to-Issues Extension** *(0% Complete)* - **MEDIUM PRIORITY** - Enhanced traceability

- ❌ **Extend taskstoissues Command**: Update `/taskstoissues` command to support Jira/Linear/GitLab in addition to GitHub
- ❌ **Dynamic Tracker Detection**: Add logic to detect configured issue tracker from `.mcp.json`
- ❌ **Tracker-Specific MCP Tools**: Implement tracker-specific issue creation logic for each platform
- ❌ **URL Validation Updates**: Update remote URL validation for different tracker types (Git-based vs non-Git-based)

#### **Unified Spec Template Implementation** *(100% Complete)* - **MEDIUM PRIORITY** - Template maintenance reduction

- ✅ **Mode-Aware Template Selection**: Implemented automatic template selection based on workflow mode (build vs spec)
- ✅ **Script-Based Mode Detection**: Added mode detection logic to create-new-feature.sh and create-new-feature.ps1 scripts
- ✅ **Template Selection Logic**: Build mode uses spec-template-build.md, spec mode uses spec-template.md
- ✅ **Minimal Conflict Surface**: Changes isolated to fork-specific scripts, templates remain upstream-compatible
- ✅ **Maintained Template Separation**: Analysis showed only 15-20% content overlap, separate templates remain optimal

#### **Spec Management & Cleanup** *(0% Complete)* - **MEDIUM PRIORITY**

- ❌ **Spec Deletion Command**: `/delete-spec` command to safely remove spec with all associated files (spec.md, plan.md, tasks.md, context.md, feature branches)
- ❌ **Dependency Validation**: Check for dependent artifacts before deletion
- ❌ **Archive Option**: Optional archiving instead of permanent deletion
- ❌ **Cleanup Verification**: Confirm all related files and branches are removed

---

## 🚀 **NEXT PHASE** (Deferred - Complete After Current Phase)

### **Command Prefix Migration** *(0% Complete)* - **MEDIUM PRIORITY** - Fork differentiation and user experience

- ❌ **Prefix Change Implementation**: Migrate from `/speckit.*` to `/agenticsdlc.*` commands for clear fork identification
- ❌ **Documentation Updates**: Update all references in README.md, docs, and templates (100+ instances)
- ❌ **Release Script Modification**: Update `.github/workflows/scripts/create-release-packages.sh` to generate new prefix
- ❌ **Migration Support**: Dual prefix support during transition with deprecation warnings
- ❌ **User Communication**: Migration guide for existing projects and clear differentiation messaging

**Note**: Deferred to focus on fixing workflow blockers first. Breaking change can be applied after core functionality is stable.

---

## 🆕 **FUTURE PHASE** (New Items - Not Yet Started)

### **Future Enhancement Categories**

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
|**Strategic Tooling**|60%|⚠️ Partially Complete|
|**Async Context Delivery**|0%|🔄 Current Phase (CRITICAL)|
|**Build Mode Bug Fix**|0%|🔄 Current Phase|
|**Levelup Build Mode**|0%|🔄 Current Phase|
|**Persistent Issue ID**|0%|🔄 Current Phase|
|**Build Mode "GSD" Upgrade**|0%|🔄 Current Phase|
|**Architecture Description (AD) Mode**|0%|🔄 Current Phase|
|**Context Intelligence & Optimization**|0%|🔄 Current Phase|
|**Multi-Tracker Task-to-Issues**|0%|🔄 Current Phase|
|**Spec Management**|0%|🔄 Current Phase|
|**Workflow Utilities**|0%|🔄 Current Phase|
|**Command Prefix Migration**|0%|🚀 Next Phase (Deferred)|
|**Hook-Based Tool Auto-Activation**|0%|🆕 Future Phase|
|**Agent Skill Modularization**|0%|🆕 Future Phase|
|**Agent Testing Infrastructure**|0%|🆕 Future Phase|
|**GitHub Issues Enhancement**|0%|🆕 Future Phase|
|**Code Quality Automation**|0%|🆕 Future Phase|
|**Resilience & Self-Healing**|0%|🆕 Future Phase|
|**IDE Integration**|0%|🆕 Future Phase|

**Overall Implementation Status**: ~85% Complete

- **Core Workflow**: 100% Complete (constitution, dual execution, MCP integration, workflow orchestration)
- **12F Factors III-V (Workflow)**: 100% Complete - Mission definition, planning, execution, and orchestration work effectively
- **Knowledge Management**: 100% Complete (AI session context packets, team directives analysis, reusable knowledge sharing)
- **Documentation Automation**: 100% Complete (spec-code synchronization with git hooks, non-blocking updates, mode-aware batch review)
- **MCP Infrastructure**: 100% Complete (issue tracker, async agent, and git platform integrations)
- **SDD Optimization**: 100% Complete (workflow flexibility with comprehensive iterative development, enhanced UX, completed mode switching with auto-detection, and mode-aware checklist validation)
- **Complexity Solutions**: ~90% Complete (completed workflow modes with auto-detecting post-implementation analysis, iterative development, enhanced rollback, configurable options - HIGH PRIORITY response to user feedback; some automation features still need implementation)
- **Current Phase Priorities**: 1 CRITICAL (async context delivery) + 5 HIGH (workflow blockers) + 4 MEDIUM features - **PRIMARY FOCUS**
- **Next Phase Priorities**: Command prefix migration (deferred to reduce churn while fixing blockers)
- **Future Enhancements**: 0% Complete (minimal enterprise features only)
- **Deferred Features**: IDE Integration & overkill enhancements (removed to maintain focus)

**Note**: @agentic-sdlc-12-factors serves dual purposes as methodology documentation and reference implementation, providing working examples and command templates that accelerate Spec Kit development. **Core 12F workflow Factors III-V are 100% complete** - mission definition, planning, execution, and orchestration work effectively through existing commands, git infrastructure, and command-to-command guidance system. **Workflow orchestration implemented** through CLI workflow overview, context-aware next actions, and sequential command guidance - no advanced visualization or blocking validation needed. **All overkill features eliminated** - advanced monitoring, interactive tutorials, evaluation suites, and context engineering removed to maintain razor focus on essential SDD functionality. Key SDD flexibility features are implemented via `/clarify` (iterative refinement), `/analyze` (consistency validation with auto-detection and post-implementation analysis), and `/checklist` (requirements quality testing with mode-aware framework option validation). **Complexity reduction prioritized** based on user feedback analysis - workflow modes provide user-choice flexibility (spec-driven structured mode as default vs lightweight build mode for exploration), **iterative development is comprehensively supported** through git-managed specs, branch isolation, clarify command modifications, and analyze cross-references, and configurable framework options make TDD/contracts/data models/risk-based testing opt-in rather than mandatory, with checklist validation ensuring enabled options are properly specified in requirements. **AI session context management is implemented** through the levelup command that creates reusable knowledge packets and analyzes contributions to team directives for cross-project learning. **Automated documentation updates are implemented** as non-blocking background automation with CLI-injected git hooks, queued updates at natural breakpoints, and mode-aware batch review to preserve developer workflow. **Issue tracker traceability is intentionally separate** from documentation automation for modularity, reliability, and independent adoption. **Command prefix migration prioritized as CRITICAL** due to immediate user impact as a breaking change affecting fork differentiation. Rich context delegation provides superior AI assistance compared to issue labeling approaches.

**Verification Status**: Core infrastructure is well-implemented and verified, but some automation features (particularly in traceability and strategic tooling) require additional development to reach full completion. The roadmap now accurately reflects the distinction between configuration scaffolding and functional automation.

## 🎯 **PRIORITY RANKING** - Refined based on user impact and workflow blockers

**🔄 CURRENT PHASE (Primary Focus):**

1. **CRITICAL**: Async task context delivery architecture (0% → 100%) - Makes async functionality completely non-functional
2. **HIGH**: Build mode workflow bug fix (0% → 100%) - Critical workflow blocker preventing build mode usage
3. **HIGH**: Levelup command build mode compatibility (0% → 100%) - AI session context management blocker (depends on #2)
4. **HIGH**: Persistent issue ID storage enhancement (0% → 100%) - Issue-tracker-first workflow improvement
5. **HIGH**: Build Mode "GSD" Upgrade (0% → 100%) - High-velocity execution mode (depends on #2)
6. **HIGH**: Architecture Description (AD) Mode (0% → 100%) - Enterprise Architecture Support
7. **MEDIUM**: Context Intelligence & Optimization (0% → 100%) - Directives scanner + compliance validation
8. **MEDIUM**: Multi-tracker task-to-issues extension (0% → 100%) - Enhanced traceability across platforms
9. **MEDIUM**: Spec management & cleanup (0% → 100%) - Workflow maintenance
10. **MEDIUM**: Workflow Utilities (0% → 100%) - /debug and /todo commands

**🚀 NEXT PHASE (Deferred):**

1. **MEDIUM**: Command prefix migration (0% → 100%) - Breaking change, fork differentiation (deferred to reduce churn)

**🆕 FUTURE PHASE (Complete After Current Phase):**

1. **MEDIUM**: Hook-based tool auto-activation (0% → future consideration)
2. **MEDIUM**: Agent-optimized testing infrastructure (0% → future consideration)
3. **MEDIUM**: GitHub issues integration enhancement (0% → future consideration)
4. **MEDIUM**: Resilience & Self-Healing (0% → future consideration)
5. **LOW**: Agent skill modularization (0% → future consideration)
6. **LOW**: Code quality automation (0% → future consideration)
7. **LOW**: Feature-level mode configuration (0% → future consideration)
8. **LOW**: IDE Integration & advanced cockpit features (0% → future consideration)
