# Contributing to team-ai-directives

This repository is a living asset, maintained by the **AI Development Guild**.
It is treated with the same rigor as our production code—each change shapes how
our agents behave and impacts downstream automation.

## Governance Overview

All changes must be submitted via a Pull Request. The PR process requires peer
review by at least one member of the AI Development Guild. This structured
process ensures that all contributions are high-quality, align with our team's
standards, and are well-documented before becoming part of our official library,
guaranteeing downstream automation (spec-kit CLI, MCP, IDE scripts) remains
trustworthy.

## Workflow

1. **Pull Latest Directives** – Before starting work, pull the latest changes
   from the team-ai-directives repository to ensure you are using the team's
   most current standards.

2. **Fork and Branch** – create feature branches named `feature/<slug>` or
   `docs/<slug>`.

3. **Add or Update Modules** – follow the directory conventions under
   `context_modules/`. Use standardized templates from the library for common
   tasks (e.g., reference existing examples or rules).

4. **Validate** – run linting or schema checks if provided, and ensure markdown
   renders cleanly.

5. **Document Impact** – note which projects or workflows need to update their
   references.

6. **Open a Pull Request** – include:
   * Summary of changes
   * Rationale and intended benefits
   * Any migration steps (e.g., "projects can checkout the v1.0.0 tag for old
     structure, new projects should use latest").

7. **Guild Review** – at least one member of the AI Development Guild must
   approve before merge.

8. **Contribute Back via /levelup** – If you develop a highly effective new
   prompt or a "golden" example during your work, formalize it and submit back
   to this repository using the /levelup process to build the team's shared
   knowledge base.

## Guidelines

* Maintain a high signal-to-noise ratio: each directive should be actionable
  and unambiguous.
* Avoid leaking secrets or sensitive data; use anonymized examples.
* Prefer incremental git tags (v2.0.0, v3.0.0) when guidance changes materially.
* Keep examples up to date with current best practices and ensure they run or
  lint cleanly.
* Use structured references for cross-linking: `@rule:relative_path`
  (relative to rules/ directory), `@example:relative_path`, `@persona:name` to
  reduce duplication and enable tooling.
* Share learnings: After completing complex tasks, share your workflow,
  successful prompts, or challenges with the team in the AI Development Guild
  forum.

## Contributing Skills

### Skill Requirements

All new skills MUST include simple frontmatter in their SKILL.md:

```yaml
---
name: skill-name
description: One-sentence description with trigger keywords
license: MIT                   # Optional
---
```

### Skill Development Process

1. **Create Skill Directory**: Follow the structure in `AGENTS.md`
2. **Add Frontmatter**: Include simple name and description in SKILL.md
3. **Test Skill**: Ensure skill works standalone with Read/Grep/Bash tools
4. **Submit PR**: Include skill description and testing validation

### Skills Package Manager Integration

When adding or modifying skills, update `.skills.json` to control how the
Skills Package Manager handles them:

```json
{
  "skills": {
    "required": {
      "local:./skills/critical-skill": {
        "version": "*",
        "description": "One-sentence description with trigger keywords",
        "categories": ["category1", "category2"]
      }
    },
    "recommended": {
      "local:./skills/optional-skill": {
        "version": "*",
        "description": "Description for discovery",
        "categories": ["category1"]
      },
      "github:org/repo/external-skill": {
        "version": "^1.0.0",
        "description": "External skill description",
        "categories": ["frontend", "react"],
        "source": "https://github.com/org/repo",
        "url": "https://raw.githubusercontent.com/org/repo/main/..."
      }
    },
    "internal": {
      "local:./skills/internal-skill": {
        "version": "*",
        "description": "Internal team skill",
        "categories": ["internal"]
      }
    },
    "blocked": [
      {
        "id": "github:unsafe-org/deprecated-skill",
        "reason": "Security vulnerability - deprecated by maintainer"
      }
    ]
  },
  "registry": {
    "skills": {
      "github:org/repo/discoverable-skill": {
        "version": "^1.0.0",
        "description": "Available for manual installation",
        "categories": ["category1"],
        "source": "https://github.com/org/repo",
        "url": "https://raw.githubusercontent.com/org/repo/main/..."
      }
    }
  },
  "policy": {
    "auto_install_required": true,
    "enforce_blocked": true,
    "allow_project_override": true
  }
}
```

**Categories:**

* **required**: Auto-installed during `specify init` (use sparingly for
  critical skills)
* **recommended**: Suggested to users but optional (most skills should be here)
* **internal**: Local team skills in `skills/` directory (auto-discovered)
* **blocked**: Skills prevented from installation (security/compliance)
* **registry**: Additional skills available for manual discovery and installation

**Skill Metadata Fields:**

* `version`: Version specifier (`*`, `^1.0.0`, `~1.2.0`)
* `description`: One-sentence description with trigger keywords for discovery
* `categories`: Array of category tags for filtering
* `source`: Repository URL (for external skills)
* `url`: Direct SKILL.md URL for webfetch (for external skills)

**Version Specifiers:**

* `"*"` - Any version (for local/internal skills)
* `"^1.0.0"` - Compatible with 1.x.x (for external skills)
* `"~1.2.0"` - Compatible with 1.2.x (for external skills)

### Skill Validation Checklist

Before submitting a skill PR, ensure:

* [ ] SKILL.md includes simple frontmatter (name + description)
* [ ] Description includes trigger keywords for discovery
* [ ] Skill works standalone (no external dependencies at runtime)
* [ ] All file references in skill are relative paths
* [ ] Scripts (if any) use proper shebang and error handling
* [ ] For external skills: URL is accessible and skill follows simple format
* [ ] `.skills.json` updated if skill should be
      required/recommended/blocked/registry

Thank you for helping keep our shared knowledge base sharp and reliable!
