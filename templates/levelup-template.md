# Agentic SDLC Levelup Checklist (for /levelup)

Before generating or contributing a new knowledge asset, ensure:
- [ ] Analyzed recent work and extracted actionable best practices or patterns
- [ ] Drafted a knowledge asset with clear title, type, content, author, and date
- [ ] Saved the asset in the correct versioned context_modules/ subdirectory
- [ ] Created or updated traceability records (e.g., issue tracker, asset metadata)
- [ ] Prepared a draft pull request for the team-ai-directives repository
- [ ] Presented all changes for human review and confirmation before execution
- [ ] No unexplained placeholders or ambiguous requirements remain

---
description: Template for generating a new knowledge asset via the /levelup command, to be contributed to the team-ai-directives repository.
scripts:
	sh: scripts/levelup.sh
---

Given a developer has completed a feature and wants to share a new best practice, pattern, or prompt, do this:

1. Run `{SCRIPT}` from the repo root with the knowledge description as an argument. All file paths must be absolute.
2. Analyze the provided description to draft a new knowledge asset (Markdown file) with the following fields:
	 - **Title**: Short, descriptive name for the asset
	 - **Type**: rule, example, persona, or other (as appropriate)
	 - **Content**: The best practice, pattern, or prompt to be shared
	 - **Author**: Developer's name or handle
	 - **Date**: Date of asset creation
	 - **Versioned Path**: context_modules/{type}/v{N}/{title}.md
3. Present the draft asset to the developer for review and confirmation.
4. If confirmed, save the asset in the correct context_modules/ subdirectory in the team-ai-directives repository.
5. If rejected, abort or allow edits as clarified in the workflow.
6. Report the asset path and metadata for traceability.

Use absolute paths with the repository root for all file operations to avoid path issues.

*This file defines the template and standards for /levelup-generated knowledge assets, following the same conventions as other project templates.*
