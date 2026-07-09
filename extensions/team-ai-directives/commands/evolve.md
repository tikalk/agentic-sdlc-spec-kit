---
description: "Apply regression-gated CDRs to the team knowledge base"
arguments: "--dry-run (optional, report only)"
---

Run the `team-evolve` skill.

Pass `$ARGUMENTS` through to the skill. Load proposed CDRs from `.specify/drafts/cdr.md`, run regression gates, implement accepted CDRs in `{TEAM_DIRECTIVES}/context_modules/`, and update CDR status.

Output a Team Evolve Summary with accepted/rejected/blocked counts and implemented file paths.
