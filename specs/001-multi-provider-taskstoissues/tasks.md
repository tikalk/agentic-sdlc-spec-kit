# Tasks: Multi-Provider taskstoissues with Config Template

## Phase 1: Template Restructuring (Core)

- **T-001**: Restructure `templates/commands/taskstoissues.md` into a provider-dispatched format with `[PROVIDER_DISPATCH]` header and per-provider sections
  - Add YAML frontmatter field `requires: [taskstoissues-provider.yml]`
  - Add provider resolution logic at top (env var → config file → git remote → default GitHub)
  - Comment-delimit each provider section
- **T-002**: Extract GitHub-specific logic into a `# Provider: GitHub` section identical to current behavior
  - Preserve all existing MCP tool references, dedup logic, and field mapping
- **T-003**: Add `# Provider: GitLab` section using REST API with `$GITLAB_TOKEN`
  - Read project ID from git remote or config
  - Create issues with labels, milestone mapping
  - Dedup by title search
- **T-004**: Add `# Provider: Linear` section using GraphQL API with `$LINEAR_API_KEY`
  - Map features to teams/projects
  - Create issues with priority mapping
  - Dedup via team-specific search
- **T-005**: Add `# Provider: Jira` section using REST API with `$JIRA_EMAIL`/`$JIRA_API_TOKEN`/`$JIRA_URL`
  - Mapping config for priorities, issue types (Story/Task/Epic)
  - Dedup via JQL search
- **T-006**: Write the config template at `templates/configs/taskstoissues-provider.yml`
  - Self-documenting YAML with all options commented out
  - Include examples for all four providers
  - Field mapping section per provider

## Phase 2: CLI & Scaffolding

- **T-007**: ~~Add `--issue-tracker` option to `specify init` command~~ — REMOVED: Provider selection is via config file, not CLI flag
- **T-008**: ~~Add `specify taskstoissues setup` CLI subcommand~~ — REMOVED: Config template is scaffolded during init, no separate setup command
- **T-009**: ~~Add auth providers for Linear and Jira~~ — REMOVED: Auth is handled by the agent at runtime via env vars and tool discovery
- **T-010**: ~~Update `specify check` to validate `taskstoissues-provider.yml`~~ — REMOVED: Config is self-documenting, agent validates at runtime

## Phase 3: Preset Integration

- **T-011**: Add `taskstoissues` to `agentic-sdlc` preset's command list
  - Register as `adlc.spec.taskstoissues` with alias `spec.taskstoissues`, replaces `speckit.taskstoissues`
- **T-012**: ~~Add `taskstoissues` to `agentic-change` preset's command list~~ — REMOVED: Change workflow is lightweight, no standalone plan/tasks; taskstoissues stays SDLC-only
- **T-013**: Remove the `speckit.` prefix special case for `taskstoissues` in `command_filename()` (`shared_infra.py:297-298`)
  - The `taskstoissues.md` file lives in `templates/commands/` like all other core commands
  - Prefix is determined by preset registration, not by filename logic
- **T-014**: Update preset CHANGELOG entries explaining why it was excluded before and why it's now included
## Phase 4: Testing & Documentation

- **T-015**: ~~Write unit tests for config file parsing and provider resolution~~ — N/A: No Python code parses the config; the agent reads YAML at runtime
- **T-016**: ~~Write end-to-end test with mock API for each provider~~ — DEFERRED: Post-v1, requires mock provider infrastructure
- **T-017**: Update README and docs with provider configuration guide
- **T-018**: Update QUICKSTART.md with provider configuration examples
- **T-019**: Version bump in pyproject.toml and CHANGELOG.md

## Phase 5: Integration with Community Extensions (Future)

- **T-020**: (Post-v1) Research compatibility with ashbrener's reconcile engine for auto-sync
- **T-021**: (Post-v1) Document migration path for users of community tracker extensions

## Phase 6: Convergence

- [x] T026 ~~Write unit tests for config file parsing and provider resolution logic~~ — N/A: No Python code parses config; agent reads YAML at runtime
- [x] T027 Expand GitLab/Linear/Jira provider sections in `adlc.spec.taskstoissues.md` with detailed API call instructions (project ID detection, issue creation payload, dedup query) per FR-003/FR-004/FR-005 (partial)
- [x] T028 Update README.md and QUICKSTART.md with provider configuration guide per T-017/T-018 (missing)
