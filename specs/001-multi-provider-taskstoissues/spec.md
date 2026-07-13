# Feature Specification: Multi-Provider taskstoissues with Config Template

**Feature Branch**: `feat/multi-provider-taskstoissues`

**Created**: 2026-07-12
**Status**: Draft
**Input**: User description: "One `speckit.taskstoissues` command driven by a config template. Provider-agnostic, supports GitHub, GitLab, Linear, Jira. The config template lives at `.specify/taskstoissues-provider.yml` and the agent reads it at runtime to determine which backend to target."

**Goal**: Replace the current GitHub-hardcoded `taskstoissues` command with a single provider-agnostic version. The command is registered in the SDLC preset:
- `spec.taskstoissues` (alias of `adlc.spec.taskstoissues`)

It reads a config file to determine target backend, then branches to provider-specific issue creation instructions — all within a single template file.
**Success Criteria**: All four target providers (GitHub, GitLab, Linear, Jira) can create issues from `tasks.md`. Backward-compatible default to GitHub. No template proliferation.  
**Constraints**: Must not break existing GitHub-only users. Must not depend on new extension system features. Must work with both MCP-based and REST-based providers. Single `.md` file — no template fragments.

## Demo Sentence *(mandatory)*

**After this feature, the user can:** run `/spec.taskstoissues` in any project that has a `tasks.md` and a `.specify/taskstoissues-provider.yml` pointing to any supported tracker, and have the agent create the corresponding issues without switching commands.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - GitHub user (default, no config) (Priority: P1)

A team using the current GitHub-only workflow runs `/spec.taskstoissues` with no config file present. The command works exactly as before — creates GitHub issues in the repo, uses `github/github-mcp-server` tools, same dedup logic, same field mapping.

**Why this priority**: Backward compatibility is non-negotiable. Every existing user must keep working without any configuration change.

**Independent Test**: Run `specify init test-project --integration claude`, add `tasks.md` with 3 tasks, run `/spec.taskstoissues` with no config file present. Verify GitHub issues are created with correct titles, descriptions, labels.

**Acceptance Scenarios**:

1. **Given** a project with no `.specify/taskstoissues-provider.yml`, **When** the user runs `/spec.taskstoissues`, **Then** the command defaults to GitHub provider and behaves identically to the current implementation.
2. **Given** a project with a blank or missing config file, **When** the agent runs provider resolution, **Then** it logs "No provider config found, defaulting to GitHub" and proceeds with GitHub tools.

---

### User Story 2 - First-time config setup (Priority: P1)

A team lead new to spec-kit runs `specify init` and finds a `.specify/taskstoissues-provider.yml` template already scaffolded with commented-out examples. They uncomment their provider and field mappings. The config template is self-documenting with clear comments, valid provider values, and per-provider auth env var documentation.

**Why this priority**: The config file is the mechanism that drives provider selection — if it's unclear or error-prone, the whole feature fails.

**Independent Test**: Create `.specify/taskstoissues-provider.yml` with `provider: gitlab`, run `/spec.taskstoissues` in a GitLab-hosted project. Verify the agent selects the GitLab path and creates issues via GitLab API.

**Acceptance Scenarios**:

1. **Given** a user runs `specify init`, **When** init completes, **Then** `.specify/taskstoissues-provider.yml` exists with commented-out examples for all four providers.
2. **Given** a user creates `.specify/taskstoissues-provider.yml` by hand, **When** they open it, **Then** the file includes commented-out examples for all four providers with explanations and auth env var documentation.
3. **Given** a config file with `provider: gitlab`, **When** the command runs, **Then** the agent loads the GitLab-specific instructions section and creates issues in the configured GitLab project.

---

### User Story 3 - Multiple providers, one project (Priority: P2)

An advanced user maintains a project tracked in both GitHub Issues and Linear, switching between them by editing the config file. Or they configure both with a `primary` field and run commands for both.

**Why this priority**: Multi-provider is valuable for migrations and cross-org workflows but not essential for v1.

**Independent Test**: Configure `primary: github` and `secondary: linear` in config, run command, verify only primary is created.

**Acceptance Scenarios**:

1. **Given** a config with `primary: github` and `secondary: linear`, **When** the command runs, **Then** the agent creates GitHub issues only, and logs "Linear configured but skipped — use `--also linear` to dual-write."
2. **Given** a config with `provider: linear --also jira`, **When** the command runs, **Then** the agent creates Linear issues first, then creates corresponding Jira issues.

---

### User Story 4 - Provider-specific field mapping (Priority: P2)

A Jira user needs to map spec-kit priorities (P1, P2, P3) to Jira priority levels (Highest, High, Medium) and map feature directories to Jira epics. A GitLab user needs to map features to milestones and priorities to labels.

**Why this priority**: The whole point of multi-provider is that each backend has different semantics — the mapping must be configurable per-provider.

**Independent Test**: Configure Jira with custom priority mapping, run command, verify issues are created with correct Jira priorities.

**Acceptance Scenarios**:

1. **Given** a config file with `field_mapping.priority: { P1: Highest, P2: High, P3: Medium }`, **When** a P2 task is created in Jira, **Then** the Jira issue has priority "High".
2. **Given** a config file with `field_mapping.epic: true`, **When** a feature directory has tasks, **Then** the agent creates an Epic for the feature and Stories for the tasks.

---

### Edge Cases

- What happens when the provider field is set to an unsupported value (e.g. `provider: trello`)? Agent should print an error listing valid providers and exit.
- What happens when the provider's auth is not set up? Agent should print provider-specific setup instructions (e.g. "Set `GITLAB_TOKEN` environment variable").
- What happens when git remote doesn't match the configured provider? Agent should warn but proceed (e.g. "Provider is gitlab but remote origin is github.com — is this intentional?")
- What happens when the config file has YAML syntax errors? Agent should print the parse error and line number.
- What happens when `tasks.md` doesn't exist? Same as current behavior — prerequisite script fails before provider resolution.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Template MUST support a `[PROVIDER_DISPATCH]` section at the top that reads `.specify/taskstoissues-provider.yml` and branches to the correct provider section.
- **FR-002**: Template MUST include a **default GitHub provider section** that is identical to the current `taskstoissues.md` content, activated when no config file exists or when `provider: github` is set.
- **FR-003**: Template MUST include a **GitLab provider section** that creates issues via GitLab API using `$GITLAB_TOKEN` and the project's GitLab remote URL.
- **FR-004**: Template MUST include a **Linear provider section** that creates issues via Linear's GraphQL API using `$LINEAR_API_KEY` (or MCP if `linear/mcp-server` is available).
- **FR-005**: Template MUST include a **Jira provider section** that creates issues via Jira REST API using `$JIRA_EMAIL`/`$JIRA_API_TOKEN` and `$JIRA_URL` (or MCP if `atlassian-mcp-server` is available).
- **FR-006**: Config template at `.specify/taskstoissues-provider.yml` MUST be scaffolded into `.specify/` during `specify init` so users can discover and uncomment their provider.
- **FR-008**: Provider resolution order MUST be: (1) explicit `--provider` CLI flag, (2) `.specify/taskstoissues-provider.yml`, (3) git remote URL heuristic, (4) default to GitHub.
- **FR-009**: Each provider section MUST include dedup logic (check for existing issues before creating) appropriate to that provider's API.
- **FR-010**: Template MUST include an `after_taskstoissues` hook call that is provider-agnostic (same extension hook, regardless of which provider section ran).
- **FR-011**: The `speckit.` prefix special case in `command_filename()` (`shared_infra.py`) MUST be removed. The command file is `taskstoissues.md` — same as all other commands. The prefix is determined by the preset: `spec.` / `change.` / `adlc.spec.`.
- **FR-012**: The `agentic-sdlc` preset MUST include `taskstoissues`, registered as `adlc.spec.taskstoissues` (alias `spec.taskstoissues`, replaces `speckit.taskstoissues`).

### Key Entities

- **taskstoissues-provider.yml**: Configuration file at `.specify/taskstoissues-provider.yml` that defines the active provider, per-provider field mappings, and provider-specific settings.
- **Provider Section**: A contiguous block of instruction text within the single `taskstoissues.md` template that is specific to one issue tracker. Gated by a "If provider == X" conditional.
- **Provider Resolution**: The logic at the top of the command template that reads config, CLI flags, and git remote to determine which provider section to execute.
- **Field Mapping**: Per-provider configuration that maps spec-kit concepts (priority, feature, task type) to tracker-specific fields (labels, components, epics, milestones).
- **Dedup Key**: How the command determines whether a task already has a corresponding issue — by title, by external ID comment, or by custom field.

### Non-Functional Requirements

- **NFR-001**: Template MUST render within the AI agent's context window for all providers (target: <200 lines raw Markdown per provider section).
- **NFR-002**: Provider resolution MUST complete in <1 second (config file parse, no network calls).
- **NFR-003**: The config file format MUST be self-documenting with per-provider auth env var comments so users can validate their setup manually.
- **NFR-004**: Each provider's auth requirements MUST be documented in the config file comments.

### Quality Attributes

- **Security**: API tokens read from environment variables, never logged or stored in config files.
- **Maintainability**: Each provider section is a self-contained block with clear section boundaries. Adding a new provider means appending a new section + updating the dispatch header. No template composition or fragment loading.
- **Usability**: Config file is self-documenting with YAML comments. The agent's tool discovery step checks for MCP servers, CLI tools, and env vars at runtime, printing actionable errors if auth is missing.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can run `specify init my-project`, uncomment `provider: jira` in the scaffolded `.specify/taskstoissues-provider.yml`, set the required env vars, and immediately run `/spec.taskstoissues` to create Jira issues from `tasks.md`.
- **SC-002**: All four providers (GitHub, GitLab, Linear, Jira) can create issues from the same `tasks.md` without any command changes — only config file changes.
- **SC-003**: Existing GitHub-only users experience zero behavioral change — no config file needed, same output, same dedup.
- **SC-004**: A new provider can be added by editing the single template file (adding a section + dispatch branch) without changing any extension system code.

## Assumptions

- Users have their provider's API token available as an environment variable before running the command.
- The git remote URL is a reasonable heuristic for default provider but users can override it.
- MCP servers for GitHub and Atlassian are the preferred integration path when available; REST fallbacks exist for agent environments without MCP.
- The template file will grow (each provider section adds ~50-80 lines) but remain within a single manageable file.
- The template file `taskstoissues.md` keeps its short name — prefixing is handled by preset registration (`adlc.spec.*`, `adlc.change.*`).

## Risk Register *(optional)*

- RISK: Template becomes too long / hard for agents to follow | Severity: Medium | Impact: Agents skip sections or misread provider branching | Test: Verify agent correctly executes GitLab path when config says GitLab — run 10 trials, expect 100% correct provider selection
- RISK: YAML config parse errors crash the command silently | Severity: High | Impact: User gets no output, doesn't know why | Test: Feed malformed YAML, verify error message with line number and suggestion
- RISK: Provider API changes break the template (e.g. Linear GraphQL schema changes) | Severity: Medium | Impact: Command stops working for that provider until template updated | Test: Run integration tests monthly that exercise each provider path
- RISK: GitLab REST API rate limits block issue creation for large projects | Severity: Low | Impact: Partial issue creation | Test: Create 50 tasks, verify rate limit handling (batch creation or pause-and-retry)
- RISK: Users put secrets in the YAML config file | Severity: High | Impact: Token leaked in version control | Test: Config template comments explicitly state "never put tokens in this file — use env vars"
