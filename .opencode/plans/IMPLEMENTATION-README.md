# Skills Package Manager Implementation

## Overview

This implementation brings Tessl's core concepts to the Agentic SDLC ecosystem:

1. **Skills as Dependencies** - Versioned, installable skill packages
2. **Two-Type Evaluation** - Review (structure) + Task (behavioral impact) evaluations  
3. **Manifest-Driven** - skills.json tracks all installed skills
4. **Registry Integration** - Search and discover evaluated skills
5. **Lifecycle Management** - Install, update, evaluate, publish workflow

## Files Created

### Concept & Architecture
- **`skills-package-manager-concept.md`** - Core concepts and architecture design
- **`skill-integration-spec.md`** - Integration with existing agentic-sdlc system

### Data Formats
- **`skills-manifest-schema.json`** - JSON Schema for skills.json validation
- **`example-skills.json`** - Example manifest showing structure

### Evaluation
- **`skill-evaluation-framework.md`** - Review and task evaluation specifications
  - Review Evaluation: 100-point structure quality checklist
  - Task Evaluation: A/B testing with behavioral metrics

### CLI Commands
- **`skill-cli-commands-spec.md`** - Full CLI specification
  - `specify skill search` - Search registry
  - `specify skill install` - Install skills
  - `specify skill update` - Update skills
  - `specify skill remove` - Remove skills
  - `specify skill list` - List installed
  - `specify skill eval` - Evaluate skills
  - `specify skill publish` - Publish to registry

### Implementation
- **`skill_manager.py`** - Complete Python implementation
  - `SkillsManifest` - Manifest management
  - `SkillInstaller` - Installation from GitHub/local
  - `SkillEvaluator` - Review evaluation engine
  - `SkillAutoDiscovery` - LLM-based skill matching
  - Typer CLI commands

### Migration
- **`migrate-external-skills.py`** - Migration script from external_skills.md

## Key Features Implemented

### 1. Skill Installation

Install skills from multiple sources:
```bash
# From GitHub
specify skill install github:vercel-labs/agent-skills/react-best-practices

# Specific version
specify skill install github:vercel-labs/agent-skills/react-best-practices@1.2.0

# From local path
specify skill install local:./my-custom-skill
```

### 2. Version Management

- Semantic versioning support
- Lockfile for reproducible installs
- Update checking with `specify skill outdated`

### 3. Evaluation Framework

**Review Evaluation (Structure Quality):**
- Frontmatter validation (20 pts)
- Content organization (30 pts)
- Self-containment (30 pts)
- Documentation quality (20 pts)

**Task Evaluation (Behavioral Impact):**
- A/B testing methodology
- Metrics: API correctness, best practices, output quality
- Integration with existing evals infrastructure

### 4. Auto-Discovery

During `/speckit.specify`:
1. Scans installed skills
2. Uses LLM to match to feature description
3. Auto-injects into context.md
4. No manual selection needed

### 5. Migration Support

One-command migration from external_skills.md:
```bash
# Preview
python migrate-external-skills.py --dry-run

# Execute
python migrate-external-skills.py
```

## Integration Points

### With Team AI Directives
- Skills reference context_modules via @rule:, @persona: syntax
- References resolved at runtime from team-ai-directives repo

### With Spec-Driven Development
- Skills auto-injected during /specify
- Context population in context.md
- Available during /plan and /implement

### With Existing Evals
- Uses `evals/` directory structure
- Leverages promptfoo integration
- Custom graders for skill evaluation

## File Structure

```
.specify/
├── skills.json              # Skill manifest
├── skills/                  # Installed skills cache
│   ├── vercel-labs--react-best-practices@1.2.0/
│   │   └── SKILL.md
│   └── local--dbt-workflow/
│       └── SKILL.md
└── skills-registry/         # Registry cache
    └── index.json
```

## Benefits Over External Skills

| Feature | External Skills (Old) | Skills Package Manager (New) |
|---------|----------------------|------------------------------|
| Versioning | None | Semantic versioning |
| Installation | Manual | Automated CLI |
| Updates | Manual tracking | `specify skill update` |
| Quality | Unknown | Review + Task scores |
| Auto-discovery | No | Yes, during /specify |
| Evaluation | None | Built-in framework |
| Registry | Static list | Searchable with filters |

## Usage Examples

### Discover and Install
```bash
# Search for React skills
specify skill search react

# Install best practices
specify skill install github:vercel-labs/agent-skills/react-best-practices

# Verify installation
specify skill list
```

### Evaluate Custom Skill
```bash
# Run review evaluation
specify skill eval ./my-skill --review

# Full evaluation with report
specify skill eval ./my-skill --full --report
```

### Update Skills
```bash
# Check for updates
specify skill outdated

# Update all
specify skill update --all
```

### Development Workflow
```bash
# 1. Create skill
mkdir my-skill && cd my-skill
cat > SKILL.md << 'SKILL'
---
name: my-skill
description: Use when building X, helps with Y
---
# My Skill
...
SKILL

# 2. Evaluate
specify skill eval . --full

# 3. Install locally
specify skill install local:./my-skill

# 4. Test in workflow
/speckit.specify "Feature using my skill"
```

## Next Steps for Full Implementation

### Phase 1: Core (Weeks 1-2)
1. Integrate skill_manager.py into specify CLI
2. Add `specify skill` subcommand
3. Create skills.json on `specify init`

### Phase 2: Registry (Weeks 3-4)
1. Build registry API client
2. Implement search functionality
3. Add caching layer

### Phase 3: Evaluation (Weeks 5-6)
1. Complete review evaluation
2. Build task evaluation harness
3. Integrate with promptfoo

### Phase 4: Integration (Weeks 7-8)
1. Auto-discovery in /specify
2. Context injection
3. Migration script testing

## References

- Tessl Skills Launch: https://tessl.io/blog/skills-are-software-and-they-need-a-lifecycle-introducing-skills-on-tessl/
- Agent Skills Format: https://agentskills.io/
- Anthropic Best Practices: https://platform.anthropic.com/docs/en/agents-and-tools/agent-skills/best-practices
- Original Tessl: https://tessl.io/

## License

Same as agentic-sdlc-spec-kit (MIT)
