---
description: "Browse, search, and install team skills from the knowledge base"
arguments: "<skill-name> (optional, install directly)"
---

Run the `team-skills` skill.

Pass `$ARGUMENTS` through to the skill. Read `{TEAM_DIRECTIVES}/.skills.json`, group skills by policy (`default`, `external`, `blocked`), and either install the named skill or present the catalog and ask which skills to install.

Output the installed skill name, destination path, and a summary of the KB policy groups.
