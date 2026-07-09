---
description: "Scan execution traces and propose new Context Directive Records (CDRs)"
arguments: "--dry-run (optional, report only)"
---

Run the `team-curate` skill.

Pass `$ARGUMENTS` through to the skill. Scan `{REPO_ROOT}/traces/*.md`, dedup against `{TEAM_DIRECTIVES}/CDR.md`, and propose new CDR drafts in `.specify/drafts/cdr.md`.

Output a summary of traces scanned, proposals created, duplicates skipped, and recommended next steps.
