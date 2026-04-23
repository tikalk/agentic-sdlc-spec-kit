# Getting Started

A 5-minute guide to setting up your team AI directives.

---

## Table of Contents

1. [Fork, Clone & Customize](#1-fork-clone--customize)
2. [Configure MCP](#2-configure-mcp)
3. [Create a Skill](#3-create-a-skill)
4. [Smoke Test](#4-smoke-test)
5. [Resources](#5-resources)

---

## 1. Fork, Clone & Customize

```bash
git clone git@github.com:YOUR_ORG/team-ai-directives.git
cd team-ai-directives
```

After cloning, customize:

- `context_modules/constitution.md` — Add your team principles
- `context_modules/personas/` — Define your team roles (see [docs/personas.md](docs/personas.md))
- `skills/` — Add your [capabilities](docs/skills.md) and register them in `.skills.json`
- `.mcp.json` — Configure your MCP servers (see [docs/github_mcp.md](docs/github_mcp.md))

---

## 2. Configure MCP

MCP (Model Context Protocol) lets your AI agent connect to external tools like GitHub, Linear, or databases. See [docs/github_mcp.md](docs/github_mcp.md)

---

## 3. Create a Skill

```bash
mkdir -p skills/my-skill
```

Create `skills/my-skill/SKILL.md`:

```yaml
---
name: my-skill
description: What it does. Use when user asks to [trigger phrases].
---

# My Skill

## Instructions
[Your instructions here]
```

Register it in `.skills.json` so agents can discover and activate it.

For full details on skill folder structure, manifest configuration, external skills, and policy settings, see [docs/skills.md](docs/skills.md).

---

## 4. Smoke Test

Run the GitHub MCP smoke test:

```bash
python3 scripts/test_github_mcp.py
```

This verifies:

- `.mcp.json` has a valid `tools.github` configuration
- `GITHUB_TOKEN` is set
- The token can authenticate against `https://api.github.com/user`

Then ask your AI agent: "What skills are available?"

---

## 5. Resources

- [AGENTS.md](AGENTS.md) — How agents use this repo
- [docs/personas.md](docs/personas.md) — Personas deep-dive: structure, configuration, and usage
- [docs/skills.md](docs/skills.md) — Skills deep-dive: structure, configuration, and usage
- [docs/github_mcp.md](docs/github_mcp.md) — GitHub MCP setup and usage guide
- [.skills.json](.skills.json) — Skills registry
- [context_modules/constitution.md](context_modules/constitution.md) — Core principles
- [Model Context Protocol docs](https://modelcontextprotocol.io) — Official MCP specification
