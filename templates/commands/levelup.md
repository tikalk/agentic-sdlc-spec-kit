---
description: Create reusable AI session context packets and comprehensive issue summaries for team-ai-directives contributions.
scripts:
    sh: scripts/bash/prepare-levelup.sh --json
    ps: scripts/powershell/prepare-levelup.ps1 -Json
constitution_script:
    sh: scripts/bash/constitution-levelup.sh
    ps: scripts/powershell/constitution-levelup.ps1
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

**MCP Integration Requirements:**

- This command uses MCP (Model Context Protocol) tools for GitHub/GitLab operations instead of direct CLI commands
- Requires `.mcp.json` configuration with:
  - Git platform MCP server (GitHub/GitLab) for PR/merge request operations
  - Issue tracker MCP server (GitHub/Jira/Linear/GitLab) for issue comment operations
- Available MCP tools:
  - `create_pull_request` / `create_merge_request` (from Git platform MCP)
  - `add_issue_comment` (from issue tracker MCP)
  - `get_pull_request`, `update_issue`
- If MCP tools are unavailable, the command will provide drafted content for manual operations

1. Run `{SCRIPT}` from the repo root and parse JSON for `FEATURE_DIR`, `BRANCH`, `SPEC_FILE`, `PLAN_FILE`, `TASKS_FILE`, `RESEARCH_FILE`, `QUICKSTART_FILE`, `KNOWLEDGE_ROOT`, and `KNOWLEDGE_DRAFTS`. All file paths must be absolute.
     - If any of `SPEC_FILE`, `PLAN_FILE`, or `TASKS_FILE` are missing, STOP and instruct the developer to complete Stages 1-3 before leveling up.
     - Before proceeding, analyze `TASKS_FILE` and confirm **all tasks are marked `[X]`** and no execution status indicates `[IN PROGRESS]`, `[BLOCKED]`, or other incomplete markers. If any tasks remain open or unchecked, STOP and instruct the developer to finish `/implement` first.
     - If `KNOWLEDGE_ROOT` or `KNOWLEDGE_DRAFTS` are empty, STOP and direct the developer to rerun `specify init --team-ai-directive ...` so the shared directives repository is cloned locally.
     - **Check MCP configuration**: Verify `.mcp.json` exists with both Git platform MCP server (GitHub/GitLab for PR operations) and issue tracker MCP server (GitHub/Jira/Linear/GitLab for issue comments) configured. MCP tools will be used for GitHub/GitLab integration instead of direct CLI commands.

2. Load the implementation artifacts:
     - Read `SPEC_FILE` (feature intent and acceptance criteria).
     - Read `PLAN_FILE` (execution strategy and triage decisions).
     - Read `TASKS_FILE` (completed task log, including `[SYNC]/[ASYNC]` execution modes and `[X]` markers).
     - **Read tasks_meta.json**: Load dual execution metadata, review status, MCP job tracking, and quality gate results.
     - IF EXISTS: Read `RESEARCH_FILE` (supporting decisions) and `QUICKSTART_FILE` (validation scenarios).
     - Synthesize the AI agent session context: decisions made, problem-solving approaches, tool usage patterns, and execution strategies from these artifacts.
     - **Perform macro-review**: Run `scripts/bash/tasks-meta-utils.sh review-macro "$FEATURE_DIR/tasks_meta.json"` to complete the dual execution loop.

3. Create AI session context packet:
     - **IMPORTANT**: The context packet must capture the AI agent's session for reuse in other projects. Focus on session context, decision patterns, and approaches that other AI agents can learn from and apply.
     - Determine a slug such as `{BRANCH}-session` and create a new markdown file under `KNOWLEDGE_DRAFTS/{slug}.md`.
     - Capture AI session context:
       - **Session Overview**: Summary of the AI agent's approach and key decisions throughout the feature development.
       - **Decision Patterns**: How the AI agent approached problem-solving, tool selection, and execution strategies.
       - **Execution Context**: MCP job tracking, quality gates passed, and dual execution loop outcomes.
       - **Reusable Patterns**: Agent behaviors, prompts, and methodologies that proved effective.
       - **Evidence Links**: Reference to repository files/commits and the originating issue.
       - Structure the packet for easy reuse by other AI agents in similar contexts.

4. Analyze for team-ai-directives contributions:
     - Analyze the session context for potential contributions to team-ai-directives components:
       - **Rules**: Agent behavior rules, interaction patterns, or decision-making guidelines.
       - **Constitution**: Governance principles, quality standards, or architectural guidelines.
       - **Personas**: Agent roles, capabilities, or specialization patterns.
       - **Examples**: Usage examples, case studies, or reference implementations.
     - For each relevant component, generate targeted proposals:
       - Run `{CONSTITUTION_SCRIPT} --json "{KNOWLEDGE_DRAFTS}/{slug}.md"` for constitution analysis.
       - Parse results and identify contributions to rules, personas, and examples.
       - Generate amendment proposals for constitution-level changes (relevance_score >= 3).
       - Create rule additions, persona definitions, or example entries as appropriate.

5. Prepare comprehensive AI session summary and team contributions:
     - Generate a draft pull request description targeting the `team-ai-directives` repository. Include:
       - AI session context packet purpose and contents.
       - Summary of team-ai-directives contributions (rules, constitution, personas, examples).
       - Analysis of session patterns and reusable approaches.
       - Checklist of validations performed.
     - Generate a comprehensive "AI Session Summary" comment for the originating issue tracker entry (`$ARGUMENTS` may specify the issue ID). Include:
       - Complete overview of AI agent session and approach.
       - Key decisions, challenges overcome, and patterns established.
       - Links to context packet and any team-ai-directives contributions.
       - Recommendations for future similar issues.

6. Present results for human approval:
     - Output the path of the generated AI session context packet and its full content.
     - Display any proposed team-ai-directives contributions (rules, constitution amendments, personas, examples).
     - Provide the draft pull request description and comprehensive issue comment.
     - Ask the developer to confirm whether to proceed with publishing (Y/N). If "N", stop after summarizing the manual next steps.

7. On developer approval, execute the publishing workflow automatically:
     - Verify the working tree at `KNOWLEDGE_ROOT` is clean. If not, report the pending changes and abort.
     - Create a new branch `levelup/{slug}` in `KNOWLEDGE_ROOT` (reuse if already created in this session).
     - Move/copy the context packet from `KNOWLEDGE_DRAFTS/{slug}.md` into a permanent path (e.g., `context/{slug}.md`) inside `KNOWLEDGE_ROOT`.
     - If team-ai-directives contributions were proposed and approved: create/update the relevant component files (rules, constitution, personas, examples).
     - Run `git add` for the new/updated files and commit with a message like `Add AI session context for {BRANCH}`.
     - If the repository has a configured `origin` remote:
         - Push the branch: `git push -u origin levelup/{slug}`
         - Use Git platform MCP tools to create a pull request:
           - Call `create_pull_request` (GitHub) or `create_merge_request` (GitLab) tool with title "Add AI session context for {BRANCH}", body containing the drafted description, source branch "levelup/{slug}", target branch "main"
           - If Git platform MCP tools are unavailable, provide the drafted PR description for manual creation.
     - If an issue identifier was provided, use issue tracker MCP tools to post the comprehensive session comment:
           - Call `add_issue_comment` tool with the issue ID and the drafted session summary
           - If issue tracker MCP tools are unavailable, provide the drafted comment text for manual posting.
     - Report the exact operations performed and surface any MCP tool failures so the developer can intervene manually.

8. Summarize final status, including:
     - AI session context packet path and commit SHA (if created).
     - Team-ai-directives contributions status (rules, constitution, personas, examples).
     - Pull request URL (from MCP) or instructions for manual creation.
     - Issue tracker comment status (from MCP) or manual instructions.
     - MCP tool execution status and any failures encountered.
