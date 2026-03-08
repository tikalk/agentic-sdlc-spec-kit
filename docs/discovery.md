# Context Auto-Discovery & Skills Discovery

This document describes the automatic discovery system for team directives and skills in the Agentic SDLC Spec Kit.

## Overview

The discovery system provides a **two-tier architecture**:

1. **Layer 1 (Scripts)**: Fast, deterministic baseline discovery using grep search and manifest-based lookup
2. **Layer 2 (Templates)**: AI-powered semantic enhancement in command templates

### Benefits

- **Fast Baseline**: Scripts provide quick candidate discovery without AI latency
- **Semantic Enhancement**: AI agents refine selections based on context and relevance
- **Team-Centric**: Uses team-ai-directives as primary knowledge source
- **Local-First**: Works offline with cached repository clones

## Team AI Directives Integration

### Structure

```
team-ai-directives/
├── constitutions/           # Team principles and constraints
│   └── constitution.md
├── personas/               # Role-specific guidelines
│   ├── security-expert.md
│   └── ui-designer.md
├── rules/                  # Generic rules and patterns
│   ├── api-security.md
│   ├── code-quality.md
│   └── testing-standards.md
├── skills/                 # Reusable knowledge packages
│   ├── oauth2-flows/
│   │   └── SKILL.md
│   ├── python-logging/
│   │   └── SKILL.md
│   └── react-patterns/
│       └── SKILL.md
├── examples/               # Annotated examples
│   ├── auth-flow.md
│   └── api-design.md
└── .skills.json           # Skills manifest (required/recommended/blocked)
```

### Configuration (.skills.json)

```json
{
  "version": "1.0.0",
  "source": "team-ai-directives",
  "skills": {
    "required": {
      "github:vercel-labs/agent-skills/react-best-practices": "^1.2.0",
      "local:./skills/oauth2-flows": "*"
    },
    "recommended": {
      "github:org/skills/python-patterns": "~2.0.0"
    },
    "blocked": [
      "github:unsafe/deprecated-skill"
    ]
  },
  "policy": {
    "auto_install_required": true,
    "enforce_blocked": true
  }
}
```

## Layer 1: Script-Based Discovery

### Context Auto-Discovery (`discover_directives()`)

**Function:** `scripts/bash/create-new-feature.sh` (`discover_directives()`)

**Algorithm:**

1. Extract keywords from feature description
2. Search team-ai-directives for matches in constitutions, personas, rules
3. Rank by keyword overlap and content analysis
4. Output JSON with file paths and search metadata

**JSON Output:**

```json
{
  "DISCOVERED_DIRECTIVES": {
    "candidates": {
      "constitution": "team-ai-directives/constitutions/constitution.md",
      "personas": [
        "team-ai-directives/personas/security-expert.md"
      ],
      "rules": [
        "team-ai-directives/rules/api-security.md",
        "team-ai-directives/rules/code-quality.md"
      ],
      "skills": [],
      "examples": []
    },
    "search_metadata": {
      "keywords": ["authentication", "security", "oauth"],
      "files_searched": 15,
      "files_with_matches": 5
    }
  }
}
```

**PowerShell Equivalent:** `scripts/powershell/discovery-functions.ps1` (`Discover-Directives`)

### Skills Discovery (`discover_skills()`)

**Function:** `scripts/bash/create-new-feature.sh` (`discover_skills()`)

**5-Layer Discovery Algorithm:**

| Layer | Source | Description |
|-------|--------|-------------|
| 1. Manifest | `.skills.json` | Fetch required/recommended/blocked skill definitions |
| 2. Local | `team-ai-directives/skills/` | Search for SKILL.md files in local directory |
| 3. Cache | `skills-cache/` | Check cached skills with 24h TTL refresh |
| 4. Required | Manifest URLs | Fetch remote skills from manifest URLs |
| 5. Recommended | Keywords | Semantic matching against feature description (future) |

**TTL Cache Refresh:**

- Cache marker: `skills-cache/.last_refresh` (Unix timestamp)
- Refresh cycle: 24 hours (86400 seconds)
- Automatic rebuild when timestamp expired

**JSON Output:**

```json
{
  "DISCOVERED_SKILLS": {
    "candidates": [
      {
        "id": "required:oauth2-flows",
        "name": "oauth2-flows",
        "source": "manifest",
        "base_relevance": 1.0
      },
      {
        "id": "required:python-logging",
        "name": "python-logging",
        "source": "local",
        "base_relevance": 0.95
      }
    ],
    "last_refresh": "2026-03-07T15:30:00Z"
  }
}
```

**PowerShell Equivalent:** `scripts/powershell/discovery-functions.ps1` (`Discover-Skills`)

## Layer 2: AI-Powered Discovery

### Template Integration

#### specify.md Template

**Location:** After initial context generation (line ~186)

**Instruction:** AI agents enhance baseline discoveries by adding human-readable explanations.

```markdown
## AI-Powered Discovery

AI agent, enhance the discovered directives and skills with concise, relevant explanations (1-2 sentences each).

### Discovered Directives (AI-Enhanced)

- **[constitution]**: [Concise explanation of key principles]
- **[personas]**: [Role-specific guidance application]
- **[rules]**: [Specific patterns to follow]
- **[skills]**: [Skill applications to this feature]
- **[examples]**: [Relevant examples to reference]

### Relevant Skills (AI-Selected)

- **[skill-name]**@version (confidence: score): [Explanation of relevance]
```

#### plan.md Template

**Location:** Context/Skills Refresh section before implementation (line ~360)

**Instruction:** AI agents revalidate selections and add technical context.

```markdown
## AI-Powered Context & Skills Refresh

Re-evaluate discovered directives and skills. Remove irrelevant items and add new discoveries.

### Revised Directives List

[AI agent updates directives based on plan context]

### Revised Skills List

[AI agent updates skills based on implementation approach]

### Confidence Scores & Justifications

- **[directive/skill-name]**: [confidence_score] - [reasoning]
```

### AI Discovery Behavior

**Conflict Resolution:**

- Script confidence > AI confidence: Keep script selection
- Script confidence < AI confidence: Update with AI selection
- Missing items only in scripts: Include (AI may have overlooked)
- Missing items only in AI: Include (script baseline may be incomplete)

**Explanation Style:**

- Concise: 1-2 sentences max
- Relevant: Tie to specific feature context
- Actionable: Provide clear guidance

**Fallback Behavior:**

- If AI fails silently: Fall back to script baseline
- If JSON output malformed: Log warning, use script baseline only

## Integration with create-new-feature.sh

### Bash Script Flow

```bash
#!/usr/bin/env bash

feature_description="Add user authentication with OAuth2"
team_directives_dir=".specify/team-ai-directives"

# 1. Discover directives
directives_json=$(discover_directives "$feature_description" "$team_directives_dir")

# 2. Discover skills
skills_json=$(discover_skills "$feature_description" "$team_directives_dir" ".specify/skills-cache")

# 3. Output combined payload
jq -n \
  --argjson directives "$directives_json" \
  --argjson skills "$skills_json" \
  '{
    DISCOVERED_DIRECTIVES: $directives.candidates,
    DISCOVERED_SKILLS: $skills.candidates,
    feature_description: env.FEATURE_DESCRIPTION
  }' <<EOF
$feature_description
EOF
```

### PowerShell Script Flow

```powershell
$featureDescription = "Add user authentication with OAuth2"
$teamDirectivesPath = ".specify/team-ai-directives"

# 1. Discover directives
$directivesJson = Discover-Directives -FeatureDescription $featureDescription -TeamDirectivesPath $teamDirectivesPath

# 2. Discover skills
$skillsJson = Discover-Skills -FeatureDescription $featureDescription -TeamDirectivesPath $teamDirectivesPath -SkillsCachePath ".specify/skills-cache"

# 3. Create payload
@{
  DISCOVERED_DIRECTIVES = $directivesJson.candidates
  DISCOVERED_SKILLS = $skillsJson.candidates
  feature_description = $featureDescription
} | ConvertTo-Json
```

## Usage Examples

### Example 1: New Feature with Team Directives

```bash
# Initialize project with team-ai-directives
cd my-project
specify init . --team-ai-directives https://github.com/my-org/team-ai-directives.git

# Create feature
./create-new-feature.sh --json "Add user authentication with OAuth2"
# Output includes DISCOVERED_DIRECTIVES and DISCOVERED_SKILLS JSON

# Use Claude Code to enhance discoveries
claude
```

### Example 2: Local Team Directives

```bash
# With existing local team-ai-directives
cd my-project
export TEAM_DIRECTIVES_DIR=~/workspace/team-ai-directives

# Create feature
./create-new-feature.sh "Add REST API with OpenAPI documentation"
# Scripts automatically discover from $TEAM_DIRECTIVES_DIR
```

### Example 3: Skills Discovery in Action

```bash
# .skills.json content
{
  "skills": {
    "required": {
      "github:anthropic/agent-skills/security-patterns": "^1.0.0",
      "local:./skills/api-security": "*"
    }
  }
}

# Running discovery
./create-new-feature.sh --json "Implement secure login flow"

# Output
{
  "DISCOVERED_SKILLS": {
    "candidates": [
      {
        "id": "required:security-patterns",
        "name": "security-patterns",
        "source": "manifest",
        "base_relevance": 1.0
      },
      {
        "id": "required:api-security",
        "name": "api-security",
        "source": "local",
        "base_relevance": 0.95
      }
    ]
  }
}
```

## Testing & Validation

### Unit Tests

```bash
# create-new-feature.sh --help
# Test with --json flag to verify discovery output

# Mock structure for testing
mkdir -p /tmp/test-discovery/team-ai-directives/{constitutions,personas,rules,skills,examples}

# Run discovery
./create-new-feature.sh --json "Test feature"
```

### Integration Tests

```bash
# Full workflow test
specify init test-project --ai claude
cd test-project/.specify

# Mock team-ai-directives
mkdir -p team-ai-directives/{constitutions,personas,rules}
echo "# Test Constitution" > team-ai-directives/constitutions/constitution.md

# Run feature creation
scripts/create-new-feature.sh "Test feature"
# Verify DISCOVERED_DIRECTIVES output
```

## Performance Considerations

### Cache Strategy

- **Refresh Cycle**: 24 hours reduces repeated large repository scans
- **Marker File**: `.last_refresh` timestamp for age tracking
- **Automatic Cleanup**: Stale entries replaced during refresh

### Scalability

- **Grep Search**: Fast for typical team-ai-directives (~100 files)
- **Candidate Limiting**: Max 5 skills configurable via scripts
- **URL Fetching**: Only for manifest URLs (not entire skills.sh registry)

## Troubleshooting

### Issue: No Directives/Skills Discovered

**Solution:** Verify team-ai-directives path exists and contains constitutions/rules/skills directories

```bash
ls -la ~/.specify/team-ai-directives
# Should show: constitutions/, personas/, rules/, skills/, examples/
```

### Issue: Skills Not Refreshed After Team Changes

**Solution:** Delete cache marker to force immediate refresh

```bash
rm ~/.specify/skills-cache/.last_refresh
```

### Issue: URL Fetching Fails

**Solution:** Check network connectivity and manifest URL validity

```bash
# Test URL accessibility
curl -I https://example.com/skill-url.md
# Should return 200 OK
```

## Future Enhancements

### Skills Semantic Selection (Not Implemented)

- NLP-based semantic matching against feature description
- Relevance confidence scoring algorithm
- Threshold-based filtering (configurable via config.json)
- Integration with skills.sh registry (optional, based on user preference)

### Directive Discovery Enhancement (Not Implemented)

- Constitution rule extraction for automated compliance checking
- Persona-based directive filtering (optional)
- Example-based pattern discovery from annotated examples

## References

- Issue #47: Context Auto-Discovery
- Issue #49: Skills Discovery
- Team AI Directives best practices
- Skills Package Manager documentation