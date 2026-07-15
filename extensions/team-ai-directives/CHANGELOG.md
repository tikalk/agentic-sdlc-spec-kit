# Changelog

## 4.2.0 - 2026-07-15

- **Register discovery hooks**: Add `hooks:` block to `extension.yml` declaring `before_specify` and `before_plan` hooks (both mandatory, `optional: false`) pointing at `adlc.team-ai-directives.discover`. This makes `register_hooks(manifest)` populate `extensions.yml` during install/update, so the spec workflow's pre-execution hook checks auto-invoke team-discover before `/spec.specify` and `/spec.plan`. Previously the `team.discover.md` command file documented these hooks but the manifest never declared them — a documentation/reality gap that left team context (personas, rules, examples, skills) undiscovered.
- **Migration**: Existing workspaces should run `specify extension update team-ai-directives` to write the new hooks to `.specify/extensions.yml`.

## 4.0.0 - 2026-07-09

- Repackage team-ai-directives as a bundled spec-kit extension with governance commands and skills.
- Move governance skills (`team-discover`, `team-curate`, `team-evolve`, `team-repair`, `team-skills`, `team-verify`) from the upstream KB repo into this extension.
- Remove `team.constitution` command; constitution handling is now owned by the `agent-context` extension bootstrap.
- Add handoff links between `team.discover`, `team.curate`, and `team.evolve`.
- Modernize command aliases to `team.<verb>` form.
