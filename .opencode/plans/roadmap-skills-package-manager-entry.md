### **Skills Package Manager** *(0% Complete)* - **HIGH PRIORITY** - Extends Factor XI Directives as Code

**Inspired by**: Tessl Skills (https://tessl.io/) and skills.sh Registry (https://skills.sh)

**Description**: A developer-grade package manager for agent skills that treats skills as versioned software dependencies with evaluation, lifecycle management, and dual registry integration. Enables teams to curate internal skills while leveraging the public skills.sh ecosystem.

#### **Architecture Overview**

```
┌────────────────────────────────────────────┐
│         skills.sh (Discovery Only)         │
│    Community registry (46K+ skills)        │
│    API: Search, metadata, ratings          │
│    Installation: Direct GitHub download    │
└────────────────────┬───────────────────────┘
                     │ HTTPS API
┌────────────────────▼───────────────────────┐
│   team-ai-directives/skills.json          │
│   Team's curated skill manifest           │
│   - Required skills (auto-install)        │
│   - Recommended skills                    │
│   - Internal skills (./skills/)           │
│   - Blocked skills list                   │
└────────────────────┬───────────────────────┘
                     │ Sync on init/specify
┌────────────────────▼───────────────────────┐
│       .specify/skills.json                │
│   Actually installed skill packages       │
│   Versioned, lockfile, cached in          │
│   .specify/skills/                        │
└────────────────────┬───────────────────────┘
                     │ Auto-activate per feature
┌────────────────────▼───────────────────────┐
│   specs/{feature}/context.md              │
│   Auto-injected relevant skills           │
│   Top 3 by relevance score (configurable) │
└────────────────────────────────────────────┘
```

#### **Implementation Components**

##### Phase 1: Core Infrastructure
- [ ] **Skills Manifest System** (skills.json)
  - Version: "1.0.0"
  - Skills registry with metadata
  - Lockfile for reproducible installs
  - Evaluation scores tracking
  
- [ ] **Skill Installer** (Python implementation)
  - Direct GitHub installation (no npm dependency)
  - Version resolution (semver support)
  - Caching in `.specify/skills/`
  - Cross-platform support (bash/PowerShell)

- [ ] **CLI Commands**
  ```bash
  specify skill search <query>          # Search skills.sh API
  specify skill install <ref>            # Install from GitHub
  specify skill list                     # Show installed
  specify skill remove <name>            # Remove skill
  specify skill update                   # Update skills
  specify skill check-updates            # Check team updates
  specify skill sync-team                # Sync with team manifest
  specify skill eval <skill>             # Evaluate skill quality
  ```

##### Phase 2: Dual Registry Integration
- [ ] **skills.sh API Client**
  - Search endpoint: `GET /api/search?q={query}`
  - Skill metadata: ratings, installs, categories
  - No installation dependency on skills.sh CLI
  - Cache search results locally

- [ ] **Team-AI-Directives Integration**
  ```json
  // team-ai-directives/skills.json
  {
    "version": "1.0.0",
    "source": "team-ai-directives",
    "skills": {
      "required": {
        "github:vercel-labs/agent-skills/react-best-practices": "^1.2.0"
      },
      "recommended": {
        "github:vercel-labs/agent-skills/web-design-guidelines": "~1.0.0"
      },
      "internal": {
        "local:./skills/dbt-workflow": "*"
      },
      "blocked": [
        "github:unsafe-org/deprecated-skill"
      ]
    },
    "policy": {
      "auto_install_required": true,
      "enforce_blocked": true,
      "allow_project_override": true
    }
  }
  ```

- [ ] **Sync Workflow**
  - `specify init` → Auto-install team required skills
  - `specify skill sync-team` → Update to team versions
  - `specify skill check-updates` → Preview changes
  - Policy enforcement: Blocked skills rejected with clear error

##### Phase 3: Per-Feature Skill Activation
- [ ] **Auto-Discovery Engine**
  - During `/speckit.specify`: Analyze feature description
  - Calculate relevance score for each installed skill
  - Select top 3 skills above threshold (default 0.7, configurable)
  - Completely silent activation (no user prompts)

- [ ] **Context Injection**
  ```markdown
  ## specs/{feature}/context.md
  
  ## Relevant Skills (Auto-Detected)
  - react-best-practices@1.2.0 (confidence: 0.95)
  - typescript-guidelines@1.0.0 (confidence: 0.82)
  - security-rules@2.0.1 (confidence: 0.78)
  
  *These skills were automatically selected based on your feature description.*
  ```

- [ ] **User Override Support**
  - Manual edits to context.md preserved on re-run
  - Config: `preserve_user_edits: true`
  - Optional: `specify skill activate <skill>` for manual selection

##### Phase 4: Skill Evaluation Framework
- [ ] **Review Evaluation (Structure Quality)**
  - Frontmatter validation (20 pts)
  - Content organization (30 pts)
  - Self-containment check (30 pts)
  - Documentation quality (20 pts)
  - Total: 100-point scale

- [ ] **Task Evaluation (Behavioral Impact)**
  - A/B testing methodology
  - Baseline vs. skill-enhanced execution
  - Metrics: API correctness, best practices, output quality
  - Integration with existing evals infrastructure

- [ ] **Evaluation CLI**
  ```bash
  specify skill eval --review ./my-skill
  specify skill eval --task ./my-skill --scenarios ./tests/
  specify skill eval --full ./my-skill
  ```

#### **Configuration**

```json
// ~/.config/specify/config.json
{
  "skills": {
    "auto_activation_threshold": 0.7,
    "max_auto_skills": 3,
    "preserve_user_edits": true,
    "registry_url": "https://skills.sh/api",
    "evaluation_required": false
  }
}
```

#### **Benefits**

1. **Zero NPM Dependencies**: Direct GitHub installation, pure Python/bash
2. **Team Curation**: Required/recommended skills enforce team standards
3. **Auto-Activation**: Skills automatically matched to features
4. **Quality Assurance**: Built-in evaluation framework
5. **Dual Registry**: Public skills.sh + Private team skills
6. **Policy Enforcement**: Block unsafe skills, enforce versions

#### **Integration Points**

- **specify init**: Creates skills.json, installs team required skills
- **/speckit.specify**: Auto-discovers and injects relevant skills
- **/plan, /implement**: Loads activated skills from context.md
- **team-ai-directives**: Skills.json alongside .mcp.json
- **evals/**: Task evaluation scenarios and graders

#### **Files Created**

- `src/specify_cli/skills/` - Core implementation
- `scripts/bash/skill-*.sh` - Bash wrappers
- `scripts/powershell/skill-*.ps1` - PowerShell wrappers
- `templates/skills/` - Skill templates
- `.opencode/plans/` - Implementation specs (already created)

#### **References**

- Tessl Skills Launch: https://tessl.io/blog/skills-are-software-and-they-need-a-lifecycle-introducing-skills-on-tessl/
- Skills.sh Registry: https://skills.sh
- Agent Skills Format: https://agentskills.io/
- Existing Implementation: `.opencode/plans/skill-*.md`, `skill_manager.py`
