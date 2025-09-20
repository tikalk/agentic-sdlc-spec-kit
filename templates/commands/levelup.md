
---
description: Execute the knowledge loop closure workflow using the /levelup command template to generate and contribute new team knowledge assets.
scripts:
	sh: scripts/levelup.sh
	core: .specify/scripts/bash/levelup.sh
---

Given a developer has completed a feature and wants to share a new best practice, pattern, or prompt, do this:

1. Run `{SCRIPT}` from the repo root with the knowledge description as an argument. All future file paths must be absolute.
2. Analyze the provided description to draft a new knowledge asset (Markdown file), pull request metadata, and traceability comment.
3. Present all drafts to the developer for explicit review and confirmation (the "Great Filter").
4. If confirmed, automate the following:
	 - Create a new branch in the local clone of the team-ai-directives repository
	 - Add the asset to the correct context_modules/ subdirectory (e.g., rules/v1/, examples/v1/, personas/v1/)
	 - Commit and push the branch
	 - Open a pull request with the drafted metadata
	 - Post a traceability comment to the original issue tracker ticket, linking the new PR and asset
5. If the developer rejects the drafts, abort or allow edits as clarified in the workflow.
6. Handle all errors (authentication, repo access, etc.) with clear messages.
7. Report results with branch name, file paths, and generated artifacts.

Use absolute paths with the repository root for all file operations to avoid path issues.

*This file defines the template and intent for the /levelup command in the agentic-sdlc-spec-kit, following the same standards as other command templates.*
