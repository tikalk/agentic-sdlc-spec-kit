# Quick Start Guide

This guide will help you get started with Spec-Driven Development using Agentic SDLC Spec Kit.

> [!NOTE]
> All automation scripts now provide both Bash (`.sh`) and PowerShell (`.ps1`) variants. The `specify` CLI auto-selects based on OS unless you pass `--script sh|ps`.

## Stage 0: Foundation & Setup

**Goal:** Establish the foundational rules and configure the development environment so every later stage aligns with the project's architectural and security principles.  
**Note:** Run these steps in a standard terminal before opening the Intelligent IDE.  
**Alignment with 12 Factors:** This stage establishes the foundation guided by [I. Strategic Mindset](https://tikalk.github.io/agentic-sdlc-12-factors/content/strategic-mindset.html) and [II. Context Scaffolding](https://tikalk.github.io/agentic-sdlc-12-factors/content/context-scaffolding.html), positioning the developer as orchestrator and assembling necessary context for AI collaboration.

1. **Project Initialization (`/init`)**  
   **Action:** From the project root, run the Agentic SDLC Spec Kit `init` command (e.g., `specify init <project> --team-ai-directives https://github.com/your-org/team-ai-directives.git`) to configure local settings and clone the shared `team-ai-directives` modules.  
   **Purpose:** Creates the handshake that brings the repository into the managed Agentic SDLC ecosystem, wiring credentials, endpoints, and shared knowledge needed for subsequent commands.
2. **Establishing the Constitution (`/constitution`)**  
   **Action:** Within the IDE, execute `/constitution`, importing relevant modules from `team-ai-directives` and adding any project-specific principles.  
   **Purpose:** Generates `memory/constitution.md`, the immutable ruleset automatically injected into `/specify`, `/plan`, and other workflows so every response honors project standards.

**Example Command:**

```text
/constitution "Assemble the constitution for this service. Import principles from @team/context_modules/principles/stateless_services.md and @team/context_modules/principles/zero_trust_security_model.md. Add the custom principle: 'All public APIs must be versioned.'"
```

**Outcome:** The IDE is fully integrated with the Orchestration Hub, and a committed `constitution.md` anchors all future automation.

## Stage 1: Feature Specification

**Goal:** Produce a committed `spec.md` that captures the feature's intent, constraints, and acceptance criteria.
**Note:** From Stage 1 onward, all work happens inside the Intelligent IDE with the context automatically assembled by Agentic SDLC Spec Kit.  
**Alignment with 12 Factors:** This stage focuses on [III. Mission Definition](https://tikalk.github.io/agentic-sdlc-12-factors/content/mission-definition.html), translating intent into formal, version-controlled specifications.

1. **Craft the Directive (`/specify`)**  
   **Action:** Author a single, comprehensive natural-language directive that blends the issue tracker mission, personas, constraints, and any clarifications.  
   **Purpose:** Front-load human judgment so the AI can draft an accurate `spec.md` aligned with the constitution.
2. **Execute the Command**  
   **Action:** Run `/specify` in the IDE; Agentic SDLC Spec Kit loads `memory/constitution.md`, resolves `@team/...` references against the directives repo, and captures any `@issue-tracker ISSUE-###` reference in the prompt so the resulting spec links back to the originating ticket.  
   **Purpose:** Generates the structured specification artifact under `specs/<feature>/spec.md` with shared principles and traceability already in context.
3. **Review and Commit**  
   **Action:** Perform a macro-review of the generated `spec.md`, refine if needed, then commit it.  
   **Purpose:** Locks in the requirements that all later stages will honor.

**Example Command:**

```text
/specify "Generate the specification for the feature in @issue-tracker ISSUE-123. The target user is the @team/personas/data_analyst.md. The operation must be asynchronous to handle large dashboards. The PDF title must include the dashboard name and an export timestamp."
```

**Outcome:** A committed `spec.md` ready to drive planning in Stage 2.

## Stage 2: Planning & Task Management

**Goal:** Convert the committed `spec.md` into a human-approved `plan.md` and a synced task list that routes work through the issue tracker.
**Note:** `/plan` and `/tasks` run inside the IDE, reusing the constitution and the locally cloned `team-ai-directives` modules.  
**Alignment with 12 Factors:** This stage implements [IV. Structured Planning](https://tikalk.github.io/agentic-sdlc-12-factors/content/structured-planning.html) and [V. Dual Execution Loops](https://tikalk.github.io/agentic-sdlc-12-factors/content/dual-execution-loops.html), decomposing tasks and triaging them for synchronous or asynchronous execution.

1. **Generate the Plan (`/plan`)**  
   **Action:** Execute `/plan` with a directive that covers tech stack, risk considerations, testing focus, and any implementation preferences. Agentic SDLC Spec Kit loads `memory/constitution.md`, references in `team-ai-directives`, and copies the plan template before executing automation.  
   **Purpose:** Guides the AI in generating a comprehensive and strategically-sound first draft of `plan.md`—front-loading human judgment yields more robust outputs, and the AI produces technical steps with preliminary [SYNC]/[ASYNC] triage suggestions while emitting `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, and contract stubs aligned with the constitution.
2. **Macro-Review and Commit**  
   **Action:** Review the generated artifacts, adjust as needed, decide [SYNC]/[ASYNC] triage, then commit.  
   **Purpose:** Locks in an execution strategy that downstream stages must respect.
3. **Sync Tasks (`/tasks`)**  
   **Action:** Run `/tasks` to transform the validated plan into numbered tasks, ensuring each contract, test, and implementation step is represented. The command requires the committed plan artifacts and will surface gaps if prerequisites are missing.  
   **Purpose:** Creates `tasks.md` and mirrors it to the issue tracker for execution visibility.

**Outcome:** A constitution-compliant `plan.md`, supporting design artifacts, and an actionable task list synchronized with project management.

## Stage 3: Implementation

**Goal:** Execute the validated plan, honoring the `[SYNC]/[ASYNC]` execution modes and completing every task in `tasks.md`.
**Note:** Use `/implement` within the IDE; the command enforces the TDD order, dependency rules, and execution modes captured in Stages 1-2.  
**Alignment with 12 Factors:** This stage applies [VI. The Great Filter](https://tikalk.github.io/agentic-sdlc-12-factors/content/great-filter.html), [VII. Adaptive Quality Gates](https://tikalk.github.io/agentic-sdlc-12-factors/content/adaptive-quality-gates.html), and [VIII. AI-Augmented, Risk-Based Testing](https://tikalk.github.io/agentic-sdlc-12-factors/content/ai-augmented-testing.html), ensuring human judgment filters AI output with appropriate review processes and targeted testing.

1. **Execute Tasks (`/implement`)**  
    **Action:** Run `/implement` to load `plan.md`, `tasks.md`, and supporting artifacts. Follow the phase-by-phase flow, completing risk-based tests before implementation and respecting `[SYNC]/[ASYNC]` modes and `[P]` parallel markers for efficient execution.  
    **Purpose:** Produces production-ready code with targeted testing based on identified risks, marks tasks as `[X]`, and preserves the execution trace for Stage 4.
2. **Review & Validate**  
   **Action:** Ensure all `[SYNC]` tasks received micro-reviews, all `[ASYNC]` work underwent macro-review, and the test suite passes before moving on.  
   **Purpose:** Guarantees the feature matches the spec and plan with traceable quality gates.

**Outcome:** A completed feature branch with passing tests and an updated `tasks.md` documenting execution status and modes.

## Stage 4: Leveling Up

**Goal:** Capture best practices from the completed feature, create Context Decision Records (CDRs) for reusable patterns, and contribute them back to `team-ai-directives`.
**Note:** The levelup extension runs inside the IDE and relies on the locally cloned directives repository from Stage 0.  
**Alignment with 12 Factors:** This stage encompasses [IX. Traceability](https://tikalk.github.io/agentic-sdlc-12-factors/content/traceability.html), [X. Strategic Tooling](https://tikalk.github.io/agentic-sdlc-12-factors/content/strategic-tooling.html), [XI. Directives as Code](https://tikalk.github.io/agentic-sdlc-12-factors/content/directives-as-code.html), and [XII. Team Capability](https://tikalk.github.io/agentic-sdlc-12-factors/content/team-capability.html), linking artifacts, managing tools, versioning AI behavior, and systematizing learning.

1. **Extract CDRs from Feature (`/levelup.specify`)**  
   **Action:** Invoke `/levelup.specify` after completing `/implement` to extract patterns from the current feature. The command creates Context Decision Records (CDRs) in `.specify/memory/cdr.md` based on your spec, plan, tasks, and optional trace.  
   **Purpose:** Captures coding patterns, best practices, and reusable knowledge from your completed implementation.

2. **Clarify and Accept (`/levelup.clarify`)**  
   **Action:** Run `/levelup.clarify` to review discovered CDRs, answer clarifying questions about validity/scope/priority, and update CDR statuses to "Accepted" or "Rejected".  
   **Purpose:** Validates that patterns are team-wide (not project-specific) and ready for contribution.

3. **Build Skills (Optional) (`/levelup.skills`)**  
   **Action:** Run `/levelup.skills {topic}` to build a self-contained skill from accepted CDRs. Skills are created in `.specify/drafts/skills/`.  
   **Purpose:** Packages related CDRs into reusable skills that AI agents can load.

4. **Create PR (`/levelup.implement`)**  
   **Action:** Run `/levelup.implement` to compile accepted CDRs into a draft PR to team-ai-directives. The command creates a `levelup/{slug}` branch, commits context modules, and creates a PR.  
   **Purpose:** Ensures lessons learned become part of the team's shared repository with proper review.

**Example Commands:**

```text
/levelup.specify "Focus on the error handling patterns we developed"
/levelup.clarify
/levelup.skills python-error-handling
/levelup.implement
```

**Note:** For brownfield projects (scanning entire codebase without a feature context), use `/levelup.init` instead of `/levelup.specify`.

**Outcome:** CDRs documented in `.specify/memory/cdr.md`, optional skills in `.specify/drafts/skills/`, and a draft PR to team-ai-directives for team review.

## The 6-Step Process

> [!TIP]
> **Context Awareness**: Spec Kit commands automatically detect the active feature based on your current Git branch (e.g., `001-feature-name`). To switch between different specifications, simply switch Git branches.

### Step 1: Install Specify

**In your terminal**, run the `specify` CLI command to initialize your project:

> **Note:** All slash commands automatically detect framework options from the current feature's spec.md metadata.

```bash
# Create a new project directory
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <PROJECT_NAME>
# OR initialize in the current directory
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init .
```

Pick script type explicitly (optional):

```bash
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <PROJECT_NAME> --script ps  # Force PowerShell
uvx --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git specify init <PROJECT_NAME> --script sh  # Force POSIX shell
```

### Step 2: Define Your Constitution

**In your AI Agent's chat interface**, use the `/spec.constitution` slash command to establish the core rules and principles for your project. You should provide your project's specific principles as arguments.

```markdown
/spec.constitution This project follows a "Library-First" approach. All features must be implemented as standalone libraries first. We use TDD strictly. We prefer functional programming patterns.
```

### Step 3: Create the Spec

**In the chat**, use the `/spec.specify` slash command to describe what you want to build. Focus on the **what** and **why**, not the tech stack.

```markdown
/spec.specify Build an application that can help me organize my photos in separate photo albums. Albums are grouped by date and can be re-organized by dragging and dropping on the main page. Albums are never in other nested albums. Within each album, photos are previewed in a tile-like interface.
```

### Step 4: Refine the Spec

**In the chat**, use the `/spec.clarify` slash command to identify and resolve ambiguities in your specification. You can provide specific focus areas as arguments.

```bash
/spec.clarify Focus on security and performance requirements.
```

### Step 5: Create a Technical Implementation Plan

**In the chat**, use the `/spec.plan` slash command to provide your tech stack and architecture choices.

```markdown
/spec.plan The application uses Vite with minimal number of libraries. Use vanilla HTML, CSS, and JavaScript as much as possible. Images are not uploaded anywhere and metadata is stored in a local SQLite database.
```

### Step 6: Break Down and Implement

**In the chat**, use the `/spec.tasks` slash command to create an actionable task list.

```markdown
/spec.tasks
```

Optionally, validate the plan with `/spec.analyze`:

```markdown
/spec.analyze
```

Then, use the `/spec.implement` slash command to execute the plan.

```markdown
/spec.implement
```

> [!TIP]
> **Phased Implementation**: For complex projects, implement in phases to avoid overwhelming the agent's context. Start with core functionality, validate it works, then add features incrementally.

## Detailed Example: Building Taskify

Here's a complete example of building a team productivity platform:

### Step 1: Define Constitution

Initialize the project's constitution to set ground rules:

```markdown
/spec.constitution Taskify is a "Security-First" application. All user inputs must be validated. We use a microservices architecture. Code must be fully documented.
```

### Step 2: Define Requirements with `/spec.specify`

```text
Develop Taskify, a team productivity platform. It should allow users to create projects, add team members,
assign tasks, comment and move tasks between boards in Kanban style. In this initial phase for this feature,
let's call it "Create Taskify," let's have multiple users but the users will be declared ahead of time, predefined.
I want five users in two different categories, one product manager and four engineers. Let's create three
different sample projects. Let's have the standard Kanban columns for the status of each task, such as "To Do,"
"In Progress," "In Review," and "Done." There will be no login for this application as this is just the very
first testing thing to ensure that our basic features are set up.
```

### Step 3: Refine the Specification

Use the `/spec.clarify` command to interactively resolve any ambiguities in your specification. You can also provide specific details you want to ensure are included.

```bash
/spec.clarify I want to clarify the task card details. For each task in the UI for a task card, you should be able to change the current status of the task between the different columns in the Kanban work board. You should be able to leave an unlimited number of comments for a particular card. You should be able to, from that task card, assign one of the valid users.
```

You can continue to refine the spec with more details using `/spec.clarify`:

```bash
/spec.clarify When you first launch Taskify, it's going to give you a list of the five users to pick from. There will be no password required. When you click on a user, you go into the main view, which displays the list of projects. When you click on a project, you open the Kanban board for that project. You're going to see the columns. You'll be able to drag and drop cards back and forth between different columns. You will see any cards that are assigned to you, the currently logged in user, in a different color from all the other ones, so you can quickly see yours. You can edit any comments that you make, but you can't edit comments that other people made. You can delete any comments that you made, but you can't delete comments anybody else made.
```

### Step 4: Validate the Spec

Validate the specification checklist using the `/spec.checklist` command:

```bash
/spec.checklist
```

### Step 5: Generate Technical Plan with `/spec.plan`

Be specific about your tech stack and technical requirements:

```bash
/spec.plan We are going to generate this using .NET Aspire, using Postgres as the database. The frontend should use Blazor server with drag-and-drop task boards, real-time updates. There should be a REST API created with a projects API, tasks API, and a notifications API.
```

### Step 6: Define Tasks

Generate an actionable task list using the `/spec.tasks` command:

```bash
/spec.tasks
```

### Step 7: Validate and Implement

Have your AI agent audit the implementation plan using `/spec.analyze`:

```bash
/spec.analyze
```

Finally, implement the solution:

```bash
/spec.implement
```

> [!TIP]
> **Phased Implementation**: For large projects like Taskify, consider implementing in phases (e.g., Phase 1: Basic project/task structure, Phase 2: Kanban functionality, Phase 3: Comments and assignments). This prevents context saturation and allows for validation at each stage.

## Key Principles

- **Be explicit** about what you're building and why
- **Don't focus on tech stack** during specification phase
- **Iterate and refine** your specifications before implementation
- **Validate** the plan before coding begins
- **Let the AI agent handle** the implementation details

## Next Steps

- Read the [complete methodology](https://github.com/github/spec-kit/blob/main/spec-driven.md) for in-depth guidance
- Check out [more examples](https://github.com/github/spec-kit/tree/main/templates) in the repository
- Explore the [source code on GitHub](https://github.com/github/spec-kit)
