# ---
description: Execute the knowledge loop closure workflow using the /levelup command template to generate and contribute new team knowledge assets.
scripts:
	sh: scripts/bash/levelup.sh "{ARGS}"
	ps: scripts/powershell/levelup.ps1 -Message "{ARGS}"
# ---


# /levelup Command

Use `/levelup` to formalize learnings, codify best practices, and prepare trace summaries after completing significant work (e.g., closing an issue).

## Example Usage

```
/levelup "The work for @issue-tracker ISSUE-123 is complete. Let's formalize the learnings for the team.
1. Analyze our workflow and extract the best practice for FastAPI error handling. Codify this as a new, reusable rule.
2. The description for this new asset should reference @issue-tracker ISSUE-123 as the context for why it's valuable.
3. Prepare a final Trace Summary for the original issue, explaining the key decisions and linking to the new knowledge asset we're creating.
Present the drafted pull request details and the issue comment for my final review before you execute."
```

## Agent Instructions

- Analyze the provided workflow and extract best practices.
- Codify new rules or assets as reusable knowledge.
- Reference the original issue or context in the description.
- Prepare a trace summary explaining key decisions and linking to new assets.
- Present draft pull request details and issue comments for review before execution.

## Output Format
- Drafted pull request details
- Issue comment text
- Trace summary
- Any new knowledge asset references

---
This command is intended for use by AI agents (e.g., Gemini, Claude, Copilot) to help teams capture and formalize learnings from completed work.
