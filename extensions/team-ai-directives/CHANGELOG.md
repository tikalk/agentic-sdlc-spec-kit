# Changelog

## 4.0.0 - 2026-07-09

- Repackage team-ai-directives as a bundled spec-kit extension with governance commands and skills.
- Move governance skills (`team-discover`, `team-curate`, `team-evolve`, `team-repair`, `team-skills`, `team-verify`) from the upstream KB repo into this extension.
- Remove `team.constitution` command; constitution handling is now owned by the `agent-context` extension bootstrap.
- Add handoff links between `team.discover`, `team.curate`, and `team.evolve`.
- Modernize command aliases to `team.<verb>` form.
