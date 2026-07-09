---
description: "Re-index CDR.md, .skills.json, and AGENTS.md in the team-ai-directives knowledge base"
arguments: "--dry-run, --cdr-only, --skills-only, --agents-only"
scripts:
  sh: .specify/extensions/team-ai-directives/scripts/bash/setup-team.sh --json
  ps: .specify/extensions/team-ai-directives/scripts/powershell/setup-team.ps1 -Json
---

Run the `team-repair` skill.

Pass `$ARGUMENTS` through to the skill. Resolve `{TEAM_DIRECTIVES}` from `.specify/init-options.json`, scan `context_modules/` and `skills/` for orphans, and rebuild the requested indexes.

Use `{SCRIPT}` to read environment variables (`REPO_ROOT`, `TEAM_DIRECTIVES`, `BRANCH`) if needed.

Output a repair report listing orphans found, indexes rebuilt, and files modified.
