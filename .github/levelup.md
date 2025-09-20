---
description: "/levelup: Capture learnings and contribute them to the team-ai-directives repository."
---

# /levelup Command

The `/levelup` command enables developers to close the knowledge loop after completing a feature. Use this command to capture best practices, new patterns, or valuable prompts discovered during development, and contribute them as version-controlled assets to the central `team-ai-directives` repository.

**Purpose:**
- Analyze the developer's prompt to draft a new knowledge asset and pull request.
- Present the draft for human review and confirmation (the "Great Filter").
- Upon approval, automate the Git workflow to create a branch, commit the asset, push, and open a pull request.
- Post a traceability comment to the original issue tracker ticket, linking the new PR.

**Agent Action:**
- Execute the script at the absolute path: `/home/lior/dev/agentic-sdlc/agentic-sdlc-spec-kit/scripts/levelup.sh`, passing the user's full prompt as a single argument.
- Example:
  ```bash
  /home/lior/dev/agentic-sdlc/agentic-sdlc-spec-kit/scripts/levelup.sh "<developer's knowledge description>"
  ```
- Always use the absolute path to ensure reliability.

**Note:**
- The script will prompt for confirmation before making any changes.
- Ensure required environment variables (e.g., `TEAM_AI_DIRECTIVES_REPO`, `ISSUE_TRACKER_TICKET`) are set as needed.
