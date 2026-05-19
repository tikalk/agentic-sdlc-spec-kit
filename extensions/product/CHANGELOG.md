# Changelog

All notable changes to the Product extension will be documented in this file.

## [1.5.3] - 2026-05-19

### Added

- **Business Stakeholder Sections**: 4 new section templates for business decision-makers
  - `sections/executive-summary.md` (Section 2.5): One-page business case with ROI, investment, and recommendation
  - `sections/market-opportunity.md` (Section 4.5): TAM/SAM/SOM, competitive landscape, ICP, positioning
  - `sections/investment.md` (Section 11.5): Team composition, budget estimate, risk-adjusted ROI, go/no-go criteria
  - `sections/gtm.md` (Section 12.5): Launch phases, pricing strategy, messaging, channel strategy

- **Business Outcome Metrics** (Section 6.5): Added to metrics template with efficiency, quality, and financial metrics
- **Business Risks** (Section 11.4): Added to risks template with adoption, competitive, and financial risks
- **Financial Metrics** (Section 6.6): Cost per user, ROI, payback period

### Changed

- **Self-Contained PRD Rule**: PRD.md must now be fully self-contained
  - All Mermaid diagrams embedded inline in Visual Summary (Section 1)
  - No reader-facing links to `.specify/product/sections/` or `.specify/product/visuals/`
  - Section files remain as intermediate build artifacts only
  - Cross-references use in-document anchors (e.g., `[Section 1.1](#11-feature-hierarchy)`)

- **PRD Template** (`prd-template.md`): Updated to v1.5.3
  - Visual Summary now uses inline Mermaid (no external links)
  - Added Section 2.5, 4.5, 6.5, 6.6, 11.4, 11.5, 12.5 placeholders
  - Updated validation checklist for new sections

- **Implement Command** (`commands/implement.md`): Updated DAG
  - Added 4 new section slugs to dependency graph: `executive-summary`, `market-opportunity`, `investment`, `gtm`
  - Updated compliance checklist with business section requirements
  - Added self-contained PRD generation rules to Phase 3

- **Extension Config** (`extension.yml`): v1.5.3
  - Added `self_contained: true` configuration
  - Updated state version to 1.2.0
  - Updated description with business section keywords

## [1.5.2] - 2026-05-19

### Added

- **CRITICAL COMPLIANCE CHECKLIST**: Added strict compliance requirements to `commands/implement.md`
  - MUST use templates (not generate from scratch)
  - MUST use Mermaid diagrams (ASCII art prohibited in main content)
  - MUST place Visual Summary as Section 1 (numbered)
  - MUST validate output with validation scripts
  
- **Validation Scripts**: New bash scripts in `scripts/bash/`
  - `validate-prd.sh`: Validates PRD compliance with v1.5.2 standards
    - Checks Visual Summary is Section 1
    - Detects ASCII diagrams in main content
    - Validates Mermaid syntax
    - Checks unfilled placeholders
    - Verifies PDR traceability
    - Supports `--strict` and `--warn` modes
  - `validate-pdr.sh`: Validates PDR completeness
    - Checks constitution is populated (not template)
    - Validates required sections
    - Reports inconsistency flags

- **Template Compliance Banners**: Added to all section templates
  - HTML comment banners at top of each template
  - Reminds to use Mermaid (not ASCII)
  - Notes section numbering in final PRD
  - References validation script

### Changed

- **PRD Template Restructure** (`templates/prd-template.md`):
  - Section 1: Visual Summary (now **numbered**)
  - Section 2: Document Information (**new section**)
  - Sections 3-13: Renumbered content sections
  - Added compliance banner at top
  - Added validation checklist at bottom
  
- **Hardened implement.md Command**:
  - Added CRITICAL COMPLIANCE CHECKLIST at top
  - Added STRICT ENFORCEMENT RULES section
  - Enhanced template loading instructions (MUST read template first)
  - Added ASCII to Mermaid conversion instructions
  - Added validation step to section generation workflow

### Fixed

- **ASCII Diagram Detection**: Added explicit detection and conversion instructions
  - ASCII diagrams only allowed in `<details>` blocks as fallbacks
  - Main content MUST use Mermaid
  - Added validation check for box-drawing characters

## [1.5.1] - 2026-05-19

### Fixed

- **Mermaid v10 Syntax Compliance**: Updated deprecated `graph` keyword to `flowchart` in visual templates
  - `visuals/cross-area-map.md`: `graph TB` → `flowchart TB`
  - `visuals/feature-deps.md`: `graph LR` → `flowchart LR`
  - `visuals/feature-hierarchy.md`: `graph TD` → `flowchart TD`

### Added

- **New Mermaid Diagrams in Section Templates**:
  - `sections/overview.md`: Architecture flowchart with 5-layer system diagram (Frontend → Gateway → Backend → Data → External)
  - `sections/personas.md`: User journey diagram (`journey` type) showing touchpoints across Discovery, Onboarding, Core Usage, Retention
  - `sections/requirements.md`: Dependency flowchart with layer-based organization (Foundation → Business → Growth)
  - `sections/roadmap.md`: Gantt chart with milestone markers and ASCII fallback in `<details>` block

- **Enhanced Command Logic** (`commands/implement.md`):
  - **Step 2.8**: Mandatory visual diagram generation with 7 substeps
    - Directory structure creation (feature-hierarchy, feature-deps, cross-area-map, user-flows, state-machine)
    - Node ID sanitization rules (remove special chars, replace spaces with underscores, prefix with PDR ID)
    - Edge styling conventions (hard deps `-->`, soft deps `-.->`, future `-.->|planned|`)
    - Mermaid syntax validation checklist
    - ASCII fallback generation for complex diagrams
  - **Step 3.2.5**: Visual Summary section generation for PRD embed
    - Embeds all 4 diagram types inline in PRD
    - Navigation links to full visual files
    - References from other PRD sections

## [1.5.0] - 2026-05-18

### Added

- **Multi-Agent Feature-Area Analysis**: Complete refactor of `/product.init` with three-phase pipeline
  - **Discovery Agent** (Phase 5): Comprehensive scanning (directory + docs + pricing)
  - **Pattern Agent** (Phase 6): Classifies signals, scores reusability (0.0-1.0), checks team-directives
  - **Synthesis Agent** (Phase 7): Cross-feature-area analysis generating final PDRs
  
- **Cross-Feature-Area Pattern Detection**:
  - Detects patterns appearing in ≥2 feature-areas
  - Comprehensive detection from 3 sources: directory, documentation, pricing tiers
  - Cross-area metadata in all PDRs
  
- **Inconsistency Flagging**:
  - Automatic detection of conflicts across feature-areas
  - Flags embedded in PDRs (not separate records)
  - Flags for clarify resolution
  
- **State Management & Resumability**:
  - State persisted to `.specify/product/state.json`
  - Resume interrupted scans with `--resume` flag
  - Per-feature-area checkpoint tracking
  
- **Mandatory Requirements Checkpoint in Implement**:
  - Execution pauses after Requirements section
  - User approval required before continuing
  - Requirements is the cornerstone (shapes NFRs, Out-of-Scope, Risks, Roadmap)
  
- **Enhanced Pre-Flight Validation**:
  - Verify PDRs are Accepted before implement
  - Check clarify completion
  - Hard enforcement (can bypass with `--force`)
  
- **Placeholder Validation**:
  - Mandatory checking for unfilled placeholders
  - Critical placeholders block completion
  
- **Phase Gate Verification**:
  - 7-point verification checklist before marking complete
  - Verify all section files exist on disk
  - Validate PRD.md content

### Added (Mermaid Diagram Support)

- **Comprehensive Mermaid Diagram Suite** (8 diagram types):
  - `visuals/feature-hierarchy.md`: Product structure tree diagram
  - `visuals/feature-deps.md`: Requirement dependencies with status indicators
  - `visuals/cross-area-map.md`: Inter-feature-area interactions
  - `visuals/roadmap-timeline.md`: Gantt chart with milestone tracking
  - `visuals/impact-map.md`: Decision impact mind map
  - `sections/user-flows.md`: Persona journey flowcharts
  - `sections/state-machine.md`: Feature state diagrams
  - Inline decision flow diagram in PDR template

- **Visual Summary Integration**:
  - New "Visual Summary" section in PRD with quick navigation
  - Cross-references from PRD sections to visual diagrams
  - Auto-generated during implement phase

- **Prompt-Based MCP/CLI Integration**:
  - `/product.roadmap --sync` pulls from GitHub/GitLab/Jira/Linear
  - Agent detects available tools (MCP preferred, CLI fallback)
  - Warning on failure (non-blocking)
  - Updates roadmap-timeline.md automatically

- **Diagram Quality Validation**:
  - Pass H in analyze command (warning only)
  - Checks Mermaid syntax, consistency, cross-references
  - Non-blocking but flagged for attention

### Changed

- `/product.init`: Complete rewrite with multi-agent architecture
  - Sequential execution per feature-area
  - Comprehensive detection (3 sources)
  - State-based resumability
  - Cross-area metadata in PDRs
  - Discovery visualization phase added
  
- `/product.implement`: Major enhancement (~900 lines added)
  - Pre-flight validation
  - Mandatory checkpoint after Requirements
  - Placeholder validation
  - Phase gate verification
  - 7-point final checklist
  - Diagram generation steps added
  
- `/product.specify`: Consistency updates
  - Comprehensive feature-area detection
  - Early inconsistency flagging
  - Cross-area pre-analysis with alerts

- `/product.roadmap`: MCP sync support
  - `--sync` flag for external tool integration
  - Prompt-based tool detection and usage
  - Updates roadmap-timeline.md

- `/product.analyze`: Diagram validation
  - Pass H: Visual diagram quality check
  - Warning-level (non-blocking)

- `prd-template.md`: Visual enhancements
  - Visual Summary section with diagram links
  - References in Personas and Requirements sections
  - Roadmap sync instructions

- `pdr-template.md`: Decision visualization
  - Inline decision flow Mermaid diagram
  - Impact map reference
  - Cross-area metadata sections

- `requirements.md`: Checkpoint documentation
  - Reminder that this is the cornerstone section
  - Checkpoint options documented

- `extension.yml`:
  - Version bump to 1.5.0
  - Added state, subagents, cross_feature_area config
  - New tags: subagents, cross-feature-area-analysis, inconsistency-detection
  - Checkpoint configuration

### Technical Details

- **New Files**: 3 sub-agent prompt templates, 7 diagram templates
- **Modified Files**: init.md, implement.md, specify.md, roadmap.md, analyze.md, pdr-template.md, prd-template.md, requirements.md, extension.yml
- **Breaking Changes**: None (backward compatible)
- **Minimum speckit_version**: >=0.0.80 (unchanged)

## [1.1.11] - 2026-04-30

### Fixed

- **Fragile path sourcing**: Fixed bash and PowerShell scripts using fragile relative paths to source common.sh.

## [1.1.10] - 2026-04-23

### Changed

- **Removed team-ai-directives integration**: PDRs now stored only in `.specify/drafts/` and `.specify/memory/`, PRD.md now always outputs to project root

## [1.1.9] - 2026-04-19

### Fixed

- **Auto-handoff to clarify**: Changed `send: false` to `send: true` in init.md and specify.md for automatic validation of discovered PDRs

### Changed

- `/product.init` now auto-triggers `/product.clarify` to validate brownfield findings
- `/product.specify` now auto-triggers `/product.clarify` to validate greenfield decisions

## [1.1.8] - 2026-04-13

### Fixed

- **Script path resolution**: Fixed session execution failures by using fully-qualified paths in command files
  - Changed from relative `scripts/bash/setup-product.sh` to `.specify/extensions/product/scripts/bash/setup-product.sh`

## [1.1.7] - 2026-04-13

### Added

- **New command `adlc.product.link`**: Lightweight PDR linking for `before_specify` hook
  - Checks for PDRs in team-directives, memory, and drafts locations
  - **Silent exit** if no PDRs exist (eliminates noisy AI output)
  - Presents selection table if PDRs exist
  - Designed for hook use to eliminate "No PDR file found" noise

### Changed

- **`before_specify` hook**: Changed from `adlc.product.specify` to `adlc.product.link`
  - Old command was full interactive exploration (~535 lines), too noisy for hook
  - New command exits silently if no PDRs, reducing spurious AI output

## [1.1.6] - 2026-04-13

### Changed

- **Hook event names**: Renamed hooks to align with upstream template convention
  - `before_spec` → `before_specify`
  - `after_spec` → `after_specify`
  - Matches naming in `templates/commands/specify.md` and `EXTENSION-API-REFERENCE.md`

## [1.1.5] - 2026-04-11

### Fixed

- **Template path resolution**: Updated all command templates to use `{REPO_ROOT}` prefix for `.specify/` paths
- **Monorepo support**: Templates now correctly resolve paths when running from subdirectories

## [1.1.1] - 2026-04-11

### Fixed

- **.specify directory detection**: Scripts now properly search upward for `.specify` directory instead of using git root directly

## [1.1.0] - 2026-04-10

### Added

- **Multi-agent DAG orchestration** for `/product.implement` command
  - Three-phase workflow: Plan → Execute → Summarize
  - State persistence in `.specify/product/state.json` for resumability
  - Per-section outputs in `.specify/product/sections/{feature-area}/{section}.md`
  - Works with any AI agent (Claude, Copilot, Cursor, etc.)

- **Section templates** extracted from prd-template.md:
  - `templates/sections/overview.md` - Overview section template
  - `templates/sections/problem.md` - Problem section template
  - `templates/sections/goals.md` - Goals/Objectives section template
  - `templates/sections/metrics.md` - Success Metrics section template
  - `templates/sections/personas.md` - Personas section template
  - `templates/sections/requirements.md` - Functional Requirements section template
  - `templates/sections/nfrs.md` - Non-Functional Requirements section template
  - `templates/sections/out-of-scope.md` - Out of Scope section template
  - `templates/sections/risks.md` - Risks & Mitigation section template
  - `templates/sections/roadmap.md` - Roadmap & Milestones section template
  - `templates/sections/pdr-summary.md` - PDR Summary section template

- **New script actions** for DAG workflow:
  - `plan-dag` - Phase 1: Generate DAG execution plan for user approval
  - `execute-dag` - Phase 2: Execute DAG to generate sections per feature-area
  - `summarize` - Phase 3: Aggregate sections into unified PRD.md

- **DAG customization rules** based on feature-area characteristics:
  - B2B Focus → Expand Personas, NFRs earlier
  - B2C Focus → Prioritize UX in Requirements
  - Platform → Technical Requirements first
  - Data-heavy → Metrics section priority
  - Marketplace → Multiple Persona branches

### Changed

- **`/product.implement`** completely rewritten with DAG orchestration
  - Feature-area detection from PDR index table
  - Dependency context passing between sections
  - Cross-feature-area conflict resolution using PDRs as source of truth
  - Unified PRD.md generation from per-section outputs

- **extension.yml** updated with DAG configuration:

  ```yaml
  dag:
    enabled: true
    base_location: ".specify/product/"
    state_location: ".specify/product/state.json"
    sections_location: ".specify/product/sections/"
    section_templates: "templates/sections/"
  ```

### Migration

- Existing projects: No action needed (DAG workflow is opt-in via `/product.implement`)
- Previous single-context generation still works if state.json doesn't exist

## [1.0.2] - 2026-04-09

### Changed

- **Removed hardcoded architect handoff**: External extension integration now via hooks only
  - Removed handoff from `product.implement` to `architect.specify` in extension.yml
  - Architect integration now configured in project-level `.specify/extensions.yml`
  - Ensures extensions are fully decoupled - architect only referenced if installed

### Migration

- Existing projects: Architect integration now requires explicit configuration in `.specify/extensions.yml`
- See README.md for hook configuration examples

## [1.0.1] - 2026-03-20

### Changed

- **PDR lifecycle alignment** with architect extension pattern
  - `extension.yml`: Added explicit `drafts_location` and `memory_location` keys
  - `extension.yml`: Added lifecycle documentation comment
  - `commands/implement.md`: Renamed "Cleanup Phase" to "Phase 6: PDR Lifecycle Management"
  - `commands/implement.md`: Added structured lifecycle steps matching architect pattern
  - `templates/pdr-template.md`: Updated integration section with 3-location model

### Migration

- Existing projects: No action needed (changes are additive/non-breaking)
- PDR files in `.specify/drafts/pdr.md` continue to work as before

## [1.0.0] - 2026-03-09

### Added

- Initial release of Product extension

#### Commands

- `adlc.product.specify` - Interactive PRD exploration for greenfield products
- `adlc.product.init` - Brownfield discovery from existing products
- `adlc.product.clarify` - Refine and validate PDRs
- `adlc.product.implement` - Generate PRD from PDRs
- `adlc.product.analyze` - Validate PDR-PRD consistency
- `adlc.product.validate` - Validate feature spec alignment with PRD

#### Templates

- `templates/pdr-template.md` - Product Decision Record template
- `templates/prd-template.md` - Product Requirements Document template (9 sections)

#### Configuration

- `config-template.yml` - Extension configuration

#### Hooks

- `before_spec` - Trigger `/product.specify` before feature specification
- `after_spec` - Trigger `/product.validate` after feature specification

#### Features

- Two-level product system (Product + Feature)
- Feature area decomposition for complex products
- PDR categories: Problem, Persona, Scope, Metric, Prioritization, Business Model, Feature, NFR
- Constitution integration for vision/strategy constraints
- PDR traceability throughout PRD
- Read-only validation commands

---

## Upgrade Notes

### From 0.x

This is the initial release. No upgrade path needed.

## Future Considerations

- Template customization per industry (SaaS, E-commerce, etc.)
- Integration with product management tools (Jira, Productboard)
- Export to common formats (Markdown, Confluence, HTML)
- PDR review workflow automation
