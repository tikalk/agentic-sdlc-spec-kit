---
description: Convert existing tasks into actionable, dependency-ordered tracker issues (GitHub, GitLab, Linear, Jira) for the feature based on available design artifacts.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
  py: scripts/python/check_prerequisites.py --json --require-tasks --include-tasks
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before tasks-to-issues conversion)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_taskstoissues` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:spec-...` or `$spec-...`). Emitting the block alone does not run the hook.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Outline

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").
1. **IF EXISTS**: Load `/memory/constitution.md` for project principles and governance constraints.
1. From the executed script, extract the path to **tasks**.
1. Get the Git remote by running:

```bash
git config --get remote.origin.url
```

1. **Determine issue provider**: Check `.specify/taskstoissues-provider.yml` for the configured provider. If absent, fall back to GitHub.
   - Supported: `github`, `gitlab`, `linear`, `jira`
   - Provider-specific auth is read from environment variables (not config files).
1. **Discover available tools for the provider**: Before interacting with the issue tracker, explore what tools are available in this environment for the configured provider:
   - Check for MCP server tools (e.g., `github/github-mcp-server/*`, `gitlab-mcp/*`, etc.)
   - Check for CLI tools installed locally (e.g., `gh`, `glab`, `linear`, `jira`)
   - Check for relevant API tokens in environment variables (e.g., `GITHUB_TOKEN`, `GITLAB_TOKEN`, `LINEAR_API_KEY`, `JIRA_API_TOKEN`)
   - If no tools or credentials are found for the configured provider, **STOP** and inform the user what is missing.
1. **Fetch existing issues for deduplication**: Before creating anything, build the set of task IDs you are about to process from `tasks.md` (each is a `T` followed by three digits, e.g. `T001`). Then use the configured provider's API to look for issues that already cover those IDs.
   - **GitHub**: Use the MCP server's `list_issues` tool. Do not pass a `state` value, since omitting it makes the tool return both open and closed issues. Request `perPage: 100` to keep the number of calls down, and since the tool uses cursor-based pagination, request pages with the `after` parameter (using the `endCursor` from the previous response). Stop paginating as soon as every task ID has been matched, or when there are no more pages.
   - **GitLab**: Use the GitLab API (via MCP server, `glab` CLI, or direct REST API calls). Extract the project path from the git remote URL (e.g. `gitlab.com/my-org/my-project` → URL-encoded `my-org%2Fmy-project`). List issues with `per_page=100` and paginate with `page` parameter. Include both open and closed issues by not filtering on state. When creating issues, POST to `/projects/:id/issues` with `title`, `description`, and optional `labels` from task tags.
   - **Linear**: Use the Linear GraphQL API (via MCP server or direct API calls at `https://api.linear.app/graphql`). Query issues with `issues(filter: { team: { id: { eq: "$TEAM_ID" } } })` and paginate with `cursor`. Filter by team/project from config. When creating issues, use the `issueCreate` mutation with `title`, `description`, `teamId`, `projectId` (optional), and `priority` mapped from task P-levels.
   - **Jira**: Use the Jira REST API v3 (via MCP server or `jira` CLI). Extract the project key from config (`field_mapping.project_key`). Search issues using JQL: `project = "PROJ" AND summary ~ "T\\d\\d\\d"`, paginate with `startAt` and `maxResults=100`. When creating issues, POST to `/rest/api/3/issue` with `fields.project.key`, `fields.summary` (the `T001: <description>` title), `fields.issuetype.name` (from `field_mapping.issue_types.task`), and `fields.priority.name` (from `field_mapping.priority_map`).
   - For each issue title, match it against the task ID pattern `\bT\d{3}\b` (word boundaries so tokens like `ST001` or `T0010` are not matched by mistake; this also recognises titles written as `T001 ...`, `T001: ...` or `[T001] ...`) and, when it matches one of your task IDs, mark that ID as already having an issue.
1. For each task in the list, use the configured provider's API to create a new issue in the repository that is representative of the Git remote. Task lines in `tasks.md` start with a markdown checkbox, so first strip the leading `- [ ]` (and any `[P]` / `[US#]` markers) to recover the task ID and its description. Create the issue with a single canonical title of the form `T001: <description>`, with the ID written once followed by the task description (for example, the line `- [ ] T001 Create project structure` becomes the title `T001: Create project structure`).
   - **Skip** any task whose ID is already present in the set of existing issues from the previous step, and report it (for example, `T001 already has an issue, skipping`).
   - Only create issues for tasks that do not yet have a matching issue.

> [!CAUTION]
> UNDER NO CIRCUMSTANCES EVER CREATE ISSUES IN REPOSITORIES THAT DO NOT MATCH THE REMOTE URL

## Post-Execution Checks

**Check for extension hooks (after tasks-to-issues conversion)**:
Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.after_taskstoissues` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:spec-...` or `$spec-...`). Emitting the block alone does not run the hook.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently
