# Agentic SDLC Spec Kit Improvement Plan

## Cross-Reference Analysis Summary

**Documentation Coverage:** All 12 factors from manifesto.md are addressed across the documentation suite:
- **manifesto.md**: Comprehensive 12-factor methodology with rationale
- **principles.md**: Concise factor summaries  
- **platform.md**: Technology stack and component architecture
- **playbook.md**: Detailed step-by-step implementation guide
- **workflow.md**: 4-stage process workflow
- **repository.md**: team-ai-directives governance and structure

**Implementation Gap Analysis:** Current spec-kit implements ~85-90% of documented capabilities. Key remaining gaps:
- **Runtime dual execution loop** (tasks_meta.json integration, ASYNC task dispatching, differentiated reviews)
- **Advanced workflow orchestration** (stage management, validation, progress tracking beyond basic implementation)
- **Full MCP server integration** (orchestration hub, multi-agent coordination)
- **Comprehensive evaluation frameworks** (quantitative metrics, A/B testing)
- **Guild infrastructure** (membership management, forum integration)

## Completed Items (Actually Implemented)

### CLI Orange Theme Restoration
- Centralized the orange color palette via `ACCENT_COLOR` and `BANNER_COLORS` constants in `src/specify_cli/__init__.py` (primary accent `#f47721`).
- Audited banners, prompts, and progress trackers to ensure they consume the shared constants instead of ad-hoc Rich styles.
- Updated release automation so packaged command sets inherit the refreshed palette; documented override guidance in `docs/quickstart.md`.

### Central LLM Gateway (Golden Path)
- `specify init` scaffolds `.specify/config/gateway.env`, supports `--gateway-url`/`--gateway-token`, and allows intentional suppression of warnings when no proxy is desired.
- Shared bash helpers load the config, export assistant-specific base URLs, and surface warnings when the config is absent.
- Lays groundwork for future gateway health checks.

### Context Readiness & Spec Discipline
- `/specify`, `/plan`, `/tasks`, and `/implement` now enforce `context.md` completeness with gating logic and clear readiness checks.

### Local Team Directives Reference Support
- `specify init --team-ai-directives` records local paths without cloning (the previous singular flag now aliases to this canonical option); remote URLs continue cloning into `.specify/memory`.
- Common scripts resolve `.specify/config/team_directives.path`, fall back to defaults, and warn when paths are unavailable.

### Risk-to-Test Automation
- **IMPLEMENTED**: Enhanced risk extraction in check-prerequisites.sh with standardized severity levels (Critical/High/Medium/Low).
- Created generate-risk-tests.sh script to generate targeted test tasks based on risk severity and category.
- Integrated with /tasks command via --include-risk-tests flag to append risk-based test tasks to tasks.md.
- `/implement` captures test evidence before polish tasks conclude, keeping risk mitigation actionable.

### Issue Tracker MCP Integration
- **IMPLEMENTED**: Added `--issue-tracker` argument to `specify init` command with validation for github, jira, linear, gitlab.
- Implemented MCP configuration scaffolding that creates `.mcp.json` with appropriate server URLs for each tracker type.
- Integrated team-ai-directives MCP template merging for team consistency.
- Added progress tracking for MCP configuration step in initialization flow.

### Async Agent MCP Integration
- **COMPLETED**: Implemented `--async-agent` parameter to `specify init` command following the `--issue-tracker` MCP configuration pattern
- Defined `AGENT_MCP_CONFIG` dictionary with MCP server URLs for async coding agents (Jules, Async Copilot, Async Codex)
- Implemented `configure_agent_mcp_servers()` function to create/update `.mcp.json` with agent-specific MCP endpoints
- Enabled async coding agents to natively connect to configured MCP servers for autonomous task execution and PR creation
- Added team directives MCP template merging support for agent configurations
- **Status**: ✅ WORKING - MCP configuration tested and verified with .mcp.json file generation

### Dual Execution Loop Infrastructure (Immediate Next Steps)
- **COMPLETED**: Updated `/tasks`, `/implement`, and `/levelup` command templates to support [SYNC]/[ASYNC] classification alongside existing [P] markers
- **COMPLETED**: Designed comprehensive `tasks_meta.json` structure for tracking execution metadata, agent assignments, reviewer checkpoints, worktree aliases, and PR links
- **NEXT**: Implement `tasks_meta.json` creation and updates in `/tasks` command
- **NEXT**: Update `/implement` command to dispatch `[ASYNC]` tasks via configured MCP agents while logging job IDs
- **FOLLOWING**: Implement micro-review enforcement for `[SYNC]` tasks and macro-review sign-off for `[ASYNC]` tasks
- **TARGET**: Enable differentiated quality gates between local parallel execution ([P]/[SYNC]) and remote async delegation ([ASYNC])

### Constitution Management System
- **IMPLEMENTED**: Complete constitution assembly, validation, and evolution tracking system
- Automated team constitution inheritance with principle extraction and mapping
- Comprehensive validation system checking structure, quality, compliance, and conflicts
- Amendment proposal and approval workflow with version management
- Project artifact scanning for constitution enhancement suggestions
- Levelup integration for constitution evolution through feature learnings
- Standardized command templates with modern prompt engineering practices

### Basic Local Parallel Task Execution ([P] Markers)
- **IMPLEMENTED**: `/tasks` command generates tasks with [P] markers for parallelizable tasks within user stories
- `/implement` command recognizes [P] markers and executes parallel tasks concurrently
- File-based coordination ensures tasks affecting same files run sequentially
- Different files can run in parallel within the same user story phase
- Tasks organized by user story (US1, US2, US3...) with parallel execution within each story
- **Status**: ✅ WORKING - Foundation for local parallel execution established

### Team Directives Layout Awareness
- **NOT IMPLEMENTED**: No structural scans of team-ai-directives repositories in CLI code.

### Knowledge Evals & Guild Feedback Loop (Basic)
- **NOT IMPLEMENTED**: No evaluation manifests or guild-log.md handling in levelup scripts.

### Basic Local Parallel Execution ([P] Tasks)
- **IMPLEMENTED**: `/tasks` generates tasks with [P] markers for parallelizable tasks within user stories
- `/implement` recognizes [P] markers and executes parallel tasks concurrently (file-based coordination)
- Tasks affecting same files run sequentially; different files can run in parallel
- **Status**: ✅ WORKING - Basic local parallelism implemented via task markers

### Async Execution Infrastructure
- **NOT IMPLEMENTED**: No `manage-tasks.sh` script for task metadata management.
- No `tasks_meta.json` tracking, git worktree provisioning, or async dispatching.
- **Clarification**: Proposed async infrastructure is for remote agent delegation, distinct from existing local parallel execution

## Prioritized Improvement Roadmap (Based on principles.md Order)

### HIGH PRIORITY - Foundational Principles (II, IV, V, VI, VII, VIII)

#### Constitution Assembly Process (Factor II: Context Scaffolding)
- ✅ **COMPLETED**: Team Constitution Inheritance System - Automated constitution assembly from team-ai-directives imports with inheritance validation and update notifications
- ✅ **COMPLETED**: Project-specific principle overlay system - Implemented via artifact scanning and project context enhancement in constitution assembly
- ✅ **COMPLETED**: Constitution validation against imported foundational directives - Created comprehensive validation system with compliance checking
- ✅ **COMPLETED**: Constitution evolution tracking with amendment history - Implemented amendment proposal, approval, and version management system
- ✅ **COMPLETED**: Command Template Context Engineering Compliance - Standardized constitution.md and plan.md templates with modern prompt engineering best practices
- Integrate context engineering patterns (Write, Select, Compress, Isolate) to optimize AI agent context windows and prevent hallucinations, poisoning, distraction, confusion, and clash
- Incorporate actionable tips for AI-assisted coding: include error logs, design docs, database schemas, and PR feedback in context management
- Use modern tools like Cursor and Cline for automatic context optimization in the SDLC workflow

#### Triage Skill Development Framework (Factor IV: Structured Planning)
- Add explicit triage guidance and decision frameworks in plan templates
- Implement triage training modules and decision trees for [SYNC] vs [ASYNC] selection
- Create triage audit trails and rationale documentation
- Develop triage effectiveness metrics and improvement tracking

#### Async Execution & Quality Gates (Factor V: Dual Execution Loops)
- **FOUNDATION COMPLETE**: Agent MCP integration implemented - AI assistants can now connect to configured MCP servers for remote task execution
- **TEMPLATES COMPLETE**: Updated `/tasks`, `/implement`, and `/levelup` templates to support `[SYNC]`/`[ASYNC]` classification alongside existing `[P]` markers
- **METADATA DESIGN COMPLETE**: Designed comprehensive `tasks_meta.json` structure for tracking execution metadata, agent assignments, reviewer checkpoints, and traceability
- **NEXT STEP**: Implement runtime integration of `tasks_meta.json` in `/tasks` and `/implement` commands
- Implement dual async execution modes:
  - **Local Mode (Parallel Evolution)**: `/implement` provisions per-task git worktrees (opt-in) for isolated development environments (evolves current [P] markers)
  - **Remote Mode (Async)**: `/implement` dispatches `[ASYNC]` tasks via configured MCP agents while logging job IDs
- Add lightweight registries to surface async job status, architect reviews, and implementer checkpoints in CLI dashboards
- Enforce micro-review on `[SYNC]` tasks and macro-review sign-off before marking `[ASYNC]` tasks as complete
- Add optional helpers for branch/PR generation and cleanup after merges to streamline human review loops

#### Enhanced Dual Execution Loop Guidance (Factor V: Dual Execution Loops)
- **COMPLETED**: Updated `/tasks` template with explicit criteria for marking tasks as [SYNC] vs [ASYNC]:
  - [SYNC] for: complex logic, architectural decisions, security-critical code, ambiguous requirements (requires human review)
  - [ASYNC] for: well-defined CRUD operations, repetitive tasks, clear specifications, independent components (can be delegated to remote agents)
- **NEXT STEP**: Add decision framework in plan.md template for triage guidance between local parallel ([P]) and remote async ([ASYNC]) execution modes

#### Micro-Review Enforcement for SYNC Tasks (Factor VI: The Great Filter)
- **TEMPLATES READY**: Updated `/implement` and `/levelup` templates to support micro-review enforcement for [SYNC] tasks
- **NEXT STEP**: Implement runtime micro-review confirmation in `/implement` command for each [SYNC] task before marking complete
- **NEXT STEP**: Integrate micro-review status into tasks_meta.json tracking

#### Differentiated Quality Gates (Factor VII: Adaptive Quality Gates)
- **TEMPLATES READY**: Designed separate quality gate approaches for [SYNC] vs [ASYNC] workflows
- **NEXT STEP**: Implement runtime differentiated quality gates:
  - [SYNC]: Focus on architecture review, security assessment, code quality metrics
  - [ASYNC]: Focus on automated testing, integration validation, performance benchmarks

#### Enhanced Risk-Based Testing Framework (Factor VIII: AI-Augmented Testing)
- **IMPLEMENTED**: Risk extraction with severity levels (Critical/High/Medium/Low) and automated test generation
- **NEXT STEP**: Add risk mitigation tracking in tasks_meta.json structure
- **NEXT STEP**: Implement runtime risk-to-test mapping with automated test generation suggestions

#### Workflow Stage Orchestration (Addresses workflow.md 4-stage process)
- Implement explicit 4-stage workflow management and validation (Stage 0-4 from workflow.md)
- Add stage transition controls and prerequisite checking
- Create workflow progress visualization and milestone tracking
- Develop stage-specific guidance and best practice enforcement
- Implement workflow rollback and recovery mechanisms

### MEDIUM PRIORITY - Integration & Governance (IX, X, XI, XII)



#### Traceability Enhancements (Factor IX: Traceability)
- Implement automated trace linking between:
  - Issue tracker tickets ↔ spec.md ↔ plan.md ↔ tasks.md ↔ commits/PRs (MCP configuration foundation now implemented)
  - AI interactions ↔ code changes ↔ review feedback
- Add trace validation in quality gates to ensure complete audit trails
- Implement MCP client integration for direct issue operations and status updates

#### Strategic Tooling Improvements (Factor X: Strategic Tooling)
- Add tool performance monitoring and recommendation system
- Implement cost tracking and optimization suggestions for AI usage
- Enhance gateway health checks with failover and load balancing
- Add tool selection guidance based on task complexity and type

#### Structured Evaluation and Learning Framework (Factor XII: Team Capability)
- Enhance `/levelup` with standardized evaluation manifests including:
  - Success metrics (completion time, defect rates, user satisfaction)
  - Process effectiveness scores
  - AI tool performance ratings
  - Lesson learned categorization
- Implement quantitative evaluation framework for comparing prompt/tool effectiveness
- Add automated evaluation report generation for team retrospectives

#### IDE Integration and Cockpit Features (Addresses platform.md IDE cockpit)
- Enhance IDE integration with native command palette support
- Create visual workflow stage indicators and progress tracking
- Implement IDE-specific context injection and prompt optimization
- Add real-time collaboration features for pair programming
- Develop IDE plugin ecosystem for extended functionality

### LOW PRIORITY - Advanced Infrastructure (Addresses platform.md, repository.md advanced features)

#### MCP Server and Orchestration Hub (Addresses platform.md orchestration hub)
- Implement full MCP (Model Context Protocol) server infrastructure
- Create orchestration hub for coordinating multiple AI agents and tools
- Add agent capability negotiation and dynamic task routing
- Develop centralized orchestration dashboard for workflow monitoring
- Implement MCP-based tool chaining and context sharing

#### MCP Server Integration (Addresses platform.md MCP server)
- Implement MCP (Model Context Protocol) server for autonomous agent orchestration
- Add MCP endpoint management for async task delegation
- Create MCP-based agent discovery and capability negotiation
- Develop MCP server health monitoring and failover systems

#### Autonomous Agents Framework (Addresses platform.md autonomous agents)
- Build autonomous agent registration and discovery system
- Create agent capability profiles and specialization tracking
- Implement agent workload balancing and failover mechanisms
- Add agent performance monitoring and optimization
- Develop agent collaboration protocols for complex task decomposition

#### Comprehensive Evaluation Suite (Evals) (Factor XII: Team Capability)
- Implement versioned evaluation manifests with standardized metrics
- Add prompt effectiveness scoring and A/B testing frameworks
- Create tool performance benchmarking and comparison systems
- Develop evaluation result aggregation and trend analysis

#### Enhanced Traceability Framework (Factor IX: Traceability)
- Implement structured trace capture for all AI interactions and decisions
- Add automated trace linking between business requirements and implementation artifacts
- Create trace validation in quality gates to ensure complete audit trails
- Develop trace visualization and analysis tools for process improvement

#### Repository Governance Automation (Addresses repository.md governance)
- Automate PR creation and review workflows for team-ai-directives
- Implement governance rule validation and compliance checking
- Create automated version management for directive libraries
- Add contribution workflow optimization and review assignment
- Develop governance metrics and compliance reporting

#### AI Development Guild Infrastructure (Addresses repository.md guild)
- Build guild membership management and contribution tracking
- Create guild forum integration within the development workflow
- Implement guild-driven decision making and consensus processes
- Add guild knowledge sharing and best practice dissemination
- Develop guild performance metrics and improvement initiatives

## Notes
- **Documentation Coverage**: All 12 manifesto factors are comprehensively documented across the MD files
- **Implementation Status**: ~85-90% of core features implemented, dual execution loop infrastructure foundation complete
- **Verification**: Completed items verified against actual spec-kit codebase; constitution system, basic local parallelism ([P] markers), agent MCP integration, and dual execution templates fully implemented
- **Priority Alignment**: Focus on implementing dual execution loop runtime (tasks_meta.json integration, ASYNC task dispatching, differentiated reviews)
- **Parallel vs Async Clarification**: [P] markers = local parallel execution (✅ implemented); [SYNC]/[ASYNC] classification = remote async delegation (✅ templates ready); Agent MCP integration = AI assistant connectivity (✅ implemented); tasks_meta.json = execution tracking (✅ designed)
- **Cross-References**: All improvement suggestions are mapped to specific manifesto factors and documentation sections
- **IDE/tooling checks and workspace scaffolding remain handled by `specify_cli init`.
- Gateway, issue-tracker, and agent integrations stay optional: they activate only when configuration is provided, preserving flexibility for teams without central infrastructure.
