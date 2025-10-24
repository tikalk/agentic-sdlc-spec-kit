---
description: Capture learnings from a completed feature and draft a knowledge asset plus traceability summary, with constitution enhancement analysis.
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

1. Run `{SCRIPT}` from the repo root and parse JSON for `FEATURE_DIR`, `BRANCH`, `SPEC_FILE`, `PLAN_FILE`, `TASKS_FILE`, `RESEARCH_FILE`, `QUICKSTART_FILE`, `KNOWLEDGE_ROOT`, and `KNOWLEDGE_DRAFTS`. All file paths must be absolute.
   - If any of `SPEC_FILE`, `PLAN_FILE`, or `TASKS_FILE` are missing, STOP and instruct the developer to complete Stages 1-3 before leveling up.
   - Before proceeding, analyze `TASKS_FILE` and confirm **all tasks are marked `[X]`** and no execution status indicates `[IN PROGRESS]`, `[BLOCKED]`, or other incomplete markers. If any tasks remain open or unchecked, STOP and instruct the developer to finish `/implement` first.
    - If `KNOWLEDGE_ROOT` or `KNOWLEDGE_DRAFTS` are empty, STOP and direct the developer to rerun `specify init --team-ai-directive ...` so the shared directives repository is cloned locally.

2. Load the implementation artifacts:
    - Read `SPEC_FILE` (feature intent and acceptance criteria).
    - Read `PLAN_FILE` (execution strategy and triage decisions).
    - Read `TASKS_FILE` (completed task log, including `[SYNC]/[ASYNC]` execution modes and `[X]` markers).
    - **Read tasks_meta.json**: Load dual execution metadata, review status, MCP job tracking, and quality gate results.
    - IF EXISTS: Read `RESEARCH_FILE` (supporting decisions) and `QUICKSTART_FILE` (validation scenarios).
    - Synthesize the key decisions, risks addressed, and noteworthy implementation patterns from these artifacts.
    - **Perform macro-review**: Run `scripts/bash/tasks-meta-utils.sh review-macro "$FEATURE_DIR/tasks_meta.json"` to complete the dual execution loop.

3. Draft the knowledge asset:
    - Determine a slug such as `{BRANCH}-levelup` and create a new markdown file under `KNOWLEDGE_DRAFTS/{slug}.md`.
    - Capture:
      - **Summary** of the feature and why the learning matters.
      - **Reusable rule or best practice** distilled from the implementation.
      - **Evidence links** back to repository files/commits and the originating issue (if available from user input).
      - **Adoption guidance** (when to apply, prerequisites, caveats).
      - Ensure the asset is self-contained, written in clear, prescriptive language, and references the feature branch/issue ID where relevant.
      - Generate a review checklist capturing:
        - Tasks completed and any issues found during review
        - Test coverage and quality metrics
        - Documentation completeness
      - Embed this checklist in the asset for compliance with Stage 3 documentation.

4. Analyze for constitution enhancement:
    - Run `{CONSTITUTION_SCRIPT} --json "{KNOWLEDGE_DRAFTS}/{slug}.md"` to analyze the drafted knowledge asset for constitution relevance.
    - Parse the JSON result for `relevance_score` and `matched_keywords`.
    - If relevance_score >= 3, run `{CONSTITUTION_SCRIPT} --amendment "{KNOWLEDGE_DRAFTS}/{slug}.md"` to generate an amendment proposal.
    - Constitution-level rules include: governance policies, quality standards, security requirements, testing mandates, documentation policies, or architectural principles.
    - The amendment proposal should include: proposed principle name, description, rationale (linking back to the feature), and impact assessment.

5. Prepare review materials for the team:
    - Generate a draft pull request description targeting the `team-ai-directives` repository. Include:
      - Purpose of the new asset.
      - Summary of analysis performed.
      - Checklist of validations (spec, plan, tasks reviewed).
      - If constitution amendment proposed: include the amendment details and rationale.
    - Generate a draft "Trace Summary" comment for the originating issue tracker entry (`$ARGUMENTS` may specify the issue ID). Summaries should:
      - Highlight key decisions.
      - Link to the new knowledge asset file (relative path within the directives repo).
      - Mention any follow-up actions.
      - If constitution amendment proposed: note the potential impact on project governance.

6. Present results for human approval:
    - Output the path of the generated knowledge asset and its full content.
    - If constitution amendment proposed: display the amendment proposal.
    - Provide the draft pull request description and issue comment text.
    - Ask the developer to confirm whether to proceed with publishing (Y/N). If "N", stop after summarizing the manual next steps (create branch, commit, open PR, comment).

7. On developer approval, execute the publishing workflow automatically (mirroring the Stage 4 process):
    - Verify the working tree at `KNOWLEDGE_ROOT` is clean. If not, report the pending changes and abort.
    - Create a new branch `levelup/{slug}` in `KNOWLEDGE_ROOT` (reuse if already created in this session).
    - Move/copy the asset from `KNOWLEDGE_DRAFTS/{slug}.md` into a permanent path (e.g., `knowledge/{slug}.md`) inside `KNOWLEDGE_ROOT`.
    - If constitution amendment was proposed and approved: create/update a constitution amendment file in the team directives.
    - Run `git add` for the new/updated files and commit with a message like `Add level-up asset for {BRANCH}`.
    - If the repository has a configured `origin` remote and the `gh` CLI is available:
        - Push the branch: `git push -u origin levelup/{slug}`
        - Create a pull request via `gh pr create` populated with the drafted description (fall back to printing the command if `gh` is unavailable).
    - If an issue identifier was provided, attempt to post the trace comment via `gh issue comment`; otherwise, print the comment text for manual posting.
    - Report the exact commands executed and surface any failures so the developer can intervene manually.

8. Summarize final status, including:
    - Knowledge asset path and commit SHA (if created).
    - Constitution amendment status (if applicable).
    - Pull request URL or instructions for manual creation.
    - Issue tracker comment status or manual instructions.
