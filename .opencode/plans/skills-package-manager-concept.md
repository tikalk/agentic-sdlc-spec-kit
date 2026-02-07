# Skills Package Manager for Agentic SDLC

## Overview

A developer-grade package manager for agent skills, inspired by Tessl's approach. This system treats skills as versioned software dependencies with evaluation, lifecycle management, and registry integration.

## Core Concepts (from Tessl)

### 1. Skills as Dependencies
- Skills are installable packages, not just markdown files
- Versioned and tracked in a manifest file
- Dependencies between skills are resolved automatically
- Updates can be managed like any software dependency

### 2. Two Types of Evaluations

#### Review Evaluations
- Test skill structure against best practices
- Check for proper frontmatter, organization, and completeness
- Validate against Anthropic's agent skill best practices
- Score skills on quality metrics

#### Task Evaluations  
- Test skill's actual impact on agent behavior
- Run agents with/without skill and compare results
- Measure effectiveness across different models
- Quantify improvement in API usage, error rates, etc.

### 3. Manifest-Driven Installation
```json
{
  "skills": {
    "github:vercel-labs/agent-skills/react-best-practices": "^1.2.0",
    "github:myorg/internal-security-rules": "2.0.1",
    "local:./custom-skills/dbt-workflow": "*"
  }
}
```

### 4. Registry Integration
- Central registry of evaluated skills
- Search and discovery via CLI
- Quality scores and reviews visible before installation
- Community and private registry support

## Implementation Architecture

### Components

1. **Skill Manifest** (`.specify/skills.json`)
   - Records installed skills with versions
   - Tracks dependencies
   - Stores evaluation results

2. **Skill Installation CLI** (`specify skill install`)
   - Install from GitHub URLs
   - Install from local paths
   - Resolve dependencies
   - Handle versioning

3. **Skill Registry Client** (`specify skill search`)
   - Search public registry
   - Query by category, quality score, tags
   - Show evaluation results

4. **Skill Evaluation Framework** (`specify skill eval`)
   - Review evaluation (structure quality)
   - Task evaluation (behavioral impact)
   - Generate evaluation reports

5. **Skill Lifecycle Commands**
   - `specify skill install` - Install a skill
   - `specify skill update` - Update to latest version
   - `specify skill remove` - Remove a skill
   - `specify skill list` - List installed skills
   - `specify skill eval` - Evaluate skill quality
   - `specify skill publish` - Publish to registry

### Integration with Existing System

The skills package manager integrates with the existing:
- **Team AI Directives** - Skills can reference directives
- **External Skills Registry** - Fetches from URLs during install
- **Spec-Driven Development** - Skills auto-injected during /specify workflow
- **Context System** - Skills populate context.md automatically

## Workflow

### 1. Discover Skills
```bash
# Search public registry
specify skill search react

# Shows results with quality scores:
# react-best-practices (vercel-labs) - Score: 94/100
#   Review: 95/100 | Task: 93/100
#   Categories: Performance, SSR, Hooks
```

### 2. Install Skills
```bash
# Install from registry
specify skill install github:vercel-labs/agent-skills/react-best-practices

# Install specific version
specify skill install github:vercel-labs/agent-skills/react-best-practices@1.2.0

# Install from local path
specify skill install local:./my-custom-skill
```

### 3. Skills Auto-Discovery in Workflow
During `/speckit.specify`, the system:
1. Scans installed skills
2. Uses LLM to match skills to feature description
3. Auto-injects relevant skills into context.md
4. No manual selection needed (silent context injection)

### 4. Update Skills
```bash
# Check for updates
specify skill outdated

# Update all skills
specify skill update

# Update specific skill
specify skill update react-best-practices
```

### 5. Evaluate Custom Skills
```bash
# Run review evaluation
specify skill eval --review ./my-skill

# Run task evaluation (requires test scenarios)
specify skill eval --task ./my-skill --scenarios ./test-scenarios/

# Full evaluation
specify skill eval --full ./my-skill
```

## File Structure

```
.specify/
├── skills.json              # Skill manifest (like tessl.json)
├── skills/                  # Installed skills cache
│   ├── vercel-labs--react-best-practices@1.2.0/
│   │   └── SKILL.md
│   ├── myorg--security-rules@2.0.1/
│   │   └── SKILL.md
│   └── local--dbt-workflow/
│       └── SKILL.md
└── skills-registry/         # Local registry cache
    └── index.json
```

## Skill Manifest Format

```json
{
  "version": "1.0.0",
  "skills": {
    "github:vercel-labs/agent-skills/react-best-practices": {
      "version": "1.2.0",
      "installed_at": "2026-02-07T10:00:00Z",
      "source": "registry",
      "evaluation": {
        "review_score": 95,
        "task_score": 93,
        "last_evaluated": "2026-02-07T10:00:00Z"
      }
    },
    "local:./custom-skills/dbt-workflow": {
      "version": "*",
      "installed_at": "2026-02-07T10:00:00Z",
      "source": "local"
    }
  },
  "lockfile": {
    "github:vercel-labs/agent-skills/react-best-practices": {
      "resolved": "https://github.com/vercel-labs/agent-skills/tree/v1.2.0/skills/react-best-practices",
      "integrity": "sha256:abc123..."
    }
  }
}
```

## Evaluation Framework

### Review Evaluation (Structure Quality)

Checks:
- [ ] YAML frontmatter present and valid
- [ ] Required fields (name, description)
- [ ] Description includes trigger keywords
- [ ] Content under 500 lines (progressive disclosure)
- [ ] Proper markdown structure
- [ ] References are valid paths
- [ ] Self-contained (no external dependencies)

Scoring: 0-100 based on best practice compliance

### Task Evaluation (Behavioral Impact)

Process:
1. Define test scenarios (task descriptions)
2. Run agent WITHOUT skill - record baseline
3. Run agent WITH skill - record results
4. Compare outputs using grader functions
5. Calculate improvement metrics:
   - Accuracy improvement
   - API usage correctness
   - Error reduction
   - Best practice adherence

Scoring: 0-100 based on measured improvement

## Benefits

1. **Version Control**: Skills versioned like code dependencies
2. **Quality Assurance**: Evaluated before use
3. **Discoverability**: Searchable registry
4. **Auto-Integration**: Skills auto-injected into workflow
5. **Lifecycle Management**: Install, update, remove with confidence
6. **Team Consistency**: Shared skill configurations
7. **Progressive Disclosure**: Skills load efficiently

## Migration Path

From existing external_skills.md:
1. Parse external skill URLs
2. Install as versioned skills
3. Generate skills.json manifest
4. Maintain backward compatibility

## Future Enhancements

- [ ] Private registry support
- [ ] Skill dependency graphs
- [ ] Automated skill updates (like Dependabot)
- [ ] Team skill profiles
- [ ] Usage analytics
- [ ] Skill marketplace

## References

- Tessl Skills Launch: https://tessl.io/blog/skills-are-software-and-they-need-a-lifecycle-introducing-skills-on-tessl/
- Agent Skills Format: https://agentskills.io/
- Anthropic Best Practices: https://platform.anthropic.com/docs/en/agents-and-tools/agent-skills/best-practices
