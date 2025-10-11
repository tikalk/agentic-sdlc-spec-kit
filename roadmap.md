# Agentic SDLC Spec Kit Improvement Plan

## Cross-Reference Analysis Summary

**Documentation Coverage:** All 12 factors from manifesto.md are addressed across the documentation suite:
- **manifesto.md**: Comprehensive 12-factor methodology with rationale
- **principles.md**: Concise factor summaries  
- **platform.md**: Technology stack and component architecture
- **playbook.md**: Detailed step-by-step implementation guide
- **workflow.md**: 4-stage process workflow
- **repository.md**: team-ai-directives governance and structure

**Implementation Gap Analysis:** Current spec-kit implements ~45-50% of documented capabilities (5-6/9 basic features actually implemented). Key gaps:
- **Async execution infrastructure** (worktrees, MCP dispatching, registries)
- **Advanced quality gates** (differentiated SYNC/ASYNC reviews)
- **Workflow orchestration** (stage management, validation, progress tracking)
- **MCP server integration** (orchestration hub, agent coordination)
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

### Team Directives Layout Awareness
- **NOT IMPLEMENTED**: No structural scans of team-ai-directives repositories in CLI code.

### Knowledge Evals & Guild Feedback Loop (Basic)
- **NOT IMPLEMENTED**: No evaluation manifests or guild-log.md handling in levelup scripts.

### Async Execution Infrastructure
- **NOT IMPLEMENTED**: No `manage-tasks.sh` script for task metadata management.
- No `tasks_meta.json` tracking, git worktree provisioning, or async dispatching.

## Prioritized Improvement Roadmap (Based on principles.md Order)

### HIGH PRIORITY - Foundational Principles (II, IV, V, VI, VII, VIII)

#### Constitution Assembly Process (Factor II: Context Scaffolding)
- ✅ **COMPLETED**: Team Constitution Inheritance System - Automated constitution assembly from team-ai-directives imports with inheritance validation and update notifications
- Add project-specific principle overlay system for constitution customization
- Create constitution validation against imported foundational directives
- Develop constitution evolution tracking with amendment history
- Integrate context engineering patterns (Write, Select, Compress, Isolate) to optimize AI agent context windows and prevent hallucinations, poisoning, distraction, confusion, and clash
- Incorporate actionable tips for AI-assisted coding: include error logs, design docs, database schemas, and PR feedback in context management
- Use modern tools like Cursor and Cline for automatic context optimization in the SDLC workflow
- **Command Template Context Engineering Compliance**: Standardize all command templates with modern prompt engineering best practices:
  - Add consistent tone context sections across all templates
  - Include conversation history context for multi-turn interactions
  - Standardize thinking step-by-step instructions for complex tasks
  - Add comprehensive examples sections with good/bad output patterns
  - Implement consistent output formatting guidelines
  - Add prefilled response structures where appropriate

#### Triage Skill Development Framework (Factor IV: Structured Planning)
- Add explicit triage guidance and decision frameworks in plan templates
- Implement triage training modules and decision trees for [SYNC] vs [ASYNC] selection
- Create triage audit trails and rationale documentation
- Develop triage effectiveness metrics and improvement tracking

#### Async Execution & Quality Gates (Factor V: Dual Execution Loops)
- Introduce `tasks_meta.json` to pair with `tasks.md` and track execution metadata, reviewer checkpoints, worktree aliases, and PR links
- Implement dual async execution modes:
  - **Local Mode**: `/implement` provisions per-task git worktrees (opt-in) for isolated development environments
  - **Remote Mode**: Add `specify init` arguments to integrate with async coding agents (Jules, Async Copilot, Async Codex, etc.) via MCP endpoints
- `/implement` dispatches `[ASYNC]` tasks via MCP endpoints or IDE callbacks while logging job IDs
- Add lightweight registries to surface async job status, architect reviews, and implementer checkpoints in CLI dashboards
- Enforce micro-review on `[SYNC]` tasks and macro-review sign-off before marking `[ASYNC]` tasks as complete
- Add optional helpers for branch/PR generation and cleanup after merges to streamline human review loops

#### Enhanced Dual Execution Loop Guidance (Factor V: Dual Execution Loops)
- Update `/tasks` template to provide explicit criteria for marking tasks as [SYNC] vs [ASYNC]:
  - [SYNC] for: complex logic, architectural decisions, security-critical code, ambiguous requirements
  - [ASYNC] for: well-defined CRUD operations, repetitive tasks, clear specifications, independent components
- Add decision framework in plan.md template for triage guidance

#### Micro-Review Enforcement for SYNC Tasks (Factor VI: The Great Filter)
- Enhance `/implement` to require explicit micro-review confirmation for each [SYNC] task before marking complete
- Add micro-review checklist template with criteria: correctness, architecture alignment, security, code quality
- Integrate micro-review status into tasks_meta.json tracking

#### Differentiated Quality Gates (Factor VII: Adaptive Quality Gates)
- Implement separate quality gate templates for [SYNC] vs [ASYNC] workflows:
  - [SYNC]: Focus on architecture review, security assessment, code quality metrics
  - [ASYNC]: Focus on automated testing, integration validation, performance benchmarks
- Update checklist templates to reflect workflow-appropriate quality criteria

#### Enhanced Risk-Based Testing Framework (Factor VIII: AI-Augmented Testing)
- Expand risk extraction to include severity levels (Critical/High/Medium/Low)
- Add test case templates specifically designed for each risk type
- Implement risk-to-test mapping with automated test generation suggestions
- Add risk mitigation tracking in tasks_meta.json

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
- **Implementation Status**: ~45-50% of basic features implemented (5-6/9 actually working), major gaps remain in advanced workflow orchestration
- **Verification**: Completed items verified against actual spec-kit codebase; most "completed" items were not implemented
- **Priority Alignment**: Focus on implementing core workflow orchestration features (async execution, quality gates, stage management)
- **Cross-References**: All improvement suggestions are mapped to specific manifesto factors and documentation sections
- IDE/tooling checks and workspace scaffolding remain handled by `specify_cli init`.
- Gateway and issue-tracker integrations stay optional: they activate only when configuration is provided, preserving flexibility for teams without central infrastructure.
