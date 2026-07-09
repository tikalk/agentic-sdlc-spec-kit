---
description: "Discover relevant team-ai-directives context for the current feature"
arguments: "--no-write (optional, skip file persistence)"
---

Run the `team-discover` skill for the current feature.

Pass `$ARGUMENTS` through to the skill. If the user wants to skip writing `team-context.md`, pass `--no-write`.

Output a relevance-ranked summary of team personas, rules, examples, and skills that apply to the feature, plus the path to `team-context.md` if written.
