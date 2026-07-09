---
description: "Verify team-ai-directives installation and health"
arguments: "(none)"
---

Run the `team-verify` skill.

Check that `team_ai_directives` is configured in `.specify/init-options.json`, that the knowledge base path exists, and that required files (`context_modules/constitution.md`, `context_modules/personas/`, `context_modules/rules/`, `context_modules/examples/`, `.skills.json`, `CDR.md`) are present. Validate OKF frontmatter on context modules.

Report each check as `[OK]`, `[WARN]`, `[INFO]`, or `[FAIL]`. Exit with a non-zero status if any check returns `[FAIL]`.
