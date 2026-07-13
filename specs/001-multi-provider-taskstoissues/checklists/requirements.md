# Requirements Checklist: Multi-Provider taskstoissues

## User Stories

- [ ] US-1: GitHub user (default, no config) — works without any config
- [ ] US-2: First-time config setup — `specify init` scaffolds config template, user uncomments provider
- [ ] US-3: Multiple providers in one project — config with primary/secondary
- [ ] US-4: Provider-specific field mapping — priorities, epics, labels

## Functional Requirements

- [ ] FR-001: Template has `[PROVIDER_DISPATCH]` section reading config YAML
- [ ] FR-002: Default GitHub section identical to current implementation
- [ ] FR-003: GitLab section using REST API + `$GITLAB_TOKEN`
- [ ] FR-004: Linear section using GraphQL API + `$LINEAR_API_KEY`
- [ ] FR-005: Jira section using REST API + `$JIRA_EMAIL`/`$JIRA_API_TOKEN`/`$JIRA_URL`
- [ ] FR-006: Config template scaffolded into `.specify/` during `specify init`
- [ ] FR-008: Provider resolution order (flag > config > remote > default GitHub)
- [ ] FR-009: Dedup logic per provider
- [ ] FR-010: `after_taskstoissues` hook is provider-agnostic
- [ ] FR-011: `speckit.` prefix special case removed from `command_filename()`
- [ ] FR-012: `agentic-sdlc` preset includes the command

## Non-Functional Requirements

- [ ] NFR-001: Template < 200 lines per provider section
- [ ] NFR-002: Provider resolution < 1 second
- [ ] NFR-003: Config file is self-documenting with per-provider auth env var comments
- [ ] NFR-004: Auth requirements documented in config comments

## Success Criteria

- [ ] SC-001: `specify init` + uncomment `provider: jira` + set env vars + `/spec.taskstoissues` creates Jira issues
- [ ] SC-002: All four providers work with same command, different config
- [ ] SC-003: Zero behavioral change for existing GitHub users
- [ ] SC-004: New provider = one template edit (section + dispatch branch)
