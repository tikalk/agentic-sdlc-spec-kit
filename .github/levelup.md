# /levelup Command Agent Prompt

## Purpose
The `/levelup` command enables the agent to capture new best practices, patterns, or prompts discovered during development and contribute them as version-controlled assets to the team-ai-directives repository.

## Usage
- Triggered by `/levelup "<description>"` in the CLI or agent interface.
- The agent will:
  1. Analyze the description and draft a new knowledge asset.
  2. Present the draft for human review (the "Great Filter").
  3. Upon approval, automate the Git workflow to create a branch, commit, push, and open a pull request.
  4. Post a traceability comment to the original issue tracker ticket, linking the new PR.

## Integration
- CLI entrypoint: `scripts/levelup.sh`
- Core logic: `.specify/scripts/bash/levelup.sh`
- Documented in `README.md` under Available Slash Commands.

## Example
```
/levelup "Codify the best practice for FastAPI error handling as a new rule in the team-ai-directives repo."
```

---

*This file defines the agent prompt and integration details for the /levelup command.*
