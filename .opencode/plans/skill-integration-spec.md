# Skill Package Manager Integration Specification

## Integration with Existing System

### 1. Team AI Directives Integration

Skills can reference context modules from team-ai-directives:

**During Skill Installation:**
1. Parse skill's SKILL.md for references
2. Check if references exist in team-ai-directives
3. Store reference metadata in skills.json
4. Do NOT copy content (skills remain self-contained)

**Reference Format:**
```markdown
## References
- Team Constitution: @constitution.md
- Security Rules: @rules/security/prevent_sql_injection.md
```

**Resolution at Runtime:**
- When skill is loaded, resolve references
- Check team-ai-directives repository
- Inject referenced content into context

### 2. External Skills Registry Migration

Migrate from `external_skills.md` to versioned skills:

**Migration Script:**
```bash
# One-time migration
specify skill migrate-from-external

# This will:
# 1. Parse external_skills.md
# 2. Install each skill with version
# 3. Generate skills.json
# 4. Keep external_skills.md for reference
```

**Backward Compatibility:**
- External skills still work during /speckit.specify
- Skills from skills.json take precedence
- Deprecation warning when using external_skills.md

### 3. Spec-Driven Development Integration

**Auto-Discovery in /speckit.specify:**

Modified workflow:
1. User describes feature
2. System scans skills.json for installed skills
3. Uses LLM to match feature to relevant skills
4. Auto-injects skill names into context.md
5. No user interaction required (silent injection)

**Context Injection:**
```markdown
## Relevant Skills
Based on your feature description, these skills may be helpful:

- react-best-practices: Component patterns and performance
- typescript-guidelines: Type safety best practices

Reference them with: @skill:react-best-practices
```

**Skill Loading:**
- Agent can reference skill: `@skill:react-best-practices`
- System loads SKILL.md content
- Provides context for implementation

### 4. Context System Integration

**context.md Structure:**
```markdown
# Feature Context

## Relevant Skills (Auto-Detected)
- react-best-practices@1.2.0
- security-rules@2.0.1

## Team Directives
- Constitution: @constitution.md
- Rules: @rules/security/*

## Architecture
- See: @architecture.md
```

**Auto-Population:**
- `/speckit.specify` detects skills
- Injects into context.md under "Relevant Skills"
- Updates on each run based on feature description

### 5. Evaluation Integration with Existing Evals

**Reuse Existing Infrastructure:**
- Use `evals/` directory for test scenarios
- Leverage promptfoo integration
- Use custom graders from `evals/graders/`

**Evaluation Scenarios:**
```
evals/
├── skill-scenarios/          # Skill test scenarios
│   ├── react-best-practices/
│   │   ├── scenario-01.yaml
│   │   └── scenario-02.yaml
│   └── security-rules/
│       └── scenario-01.yaml
└── graders/
    └── skill_grader.py       # Skill-specific graders
```

### 6. CLI Integration

**Add to specify CLI:**
```python
# In src/specify_cli/__init__.py

@app.command()
def skill(
    ctx: typer.Context,
    command: str = typer.Argument(..., help="Command: search, install, update, remove, list, eval, publish"),
    args: List[str] = typer.Argument(None)
):
    """Manage agent skills"""
    # Delegate to skill manager
    pass
```

**Subcommand Structure:**
```bash
specify skill search    # Search registry
specify skill install   # Install skill
specify skill update    # Update skill
specify skill remove    # Remove skill
specify skill list      # List installed
specify skill eval      # Evaluate skill
specify skill publish   # Publish skill
```

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1-2)

1. **Create skill manager module**
   - `src/specify_cli/skills/` package
   - Manifest loading/saving
   - Skill installation logic

2. **Implement basic commands**
   - `skill install`
   - `skill list`
   - `skill remove`

3. **Create skills.json on init**
   - Update `specify init` to create empty skills.json

### Phase 2: Registry Integration (Week 3-4)

1. **Registry client**
   - Search functionality
   - Skill metadata fetching
   - Caching layer

2. **Implement search command**
   - Query registry
   - Display results with scores

3. **Update command**
   - Check for updates
   - Version resolution

### Phase 3: Evaluation Framework (Week 5-6)

1. **Review evaluation**
   - Implement checklist validation
   - Generate review scores

2. **Task evaluation**
   - Scenario-based testing
   - Comparison framework
   - Grader integration

3. **eval command**
   - Run evaluations
   - Generate reports

### Phase 4: Integration (Week 7-8)

1. **Auto-discovery**
   - Skill matching during /specify
   - Context injection

2. **External skills migration**
   - Migration script
   - Backward compatibility

3. **Documentation**
   - User guide
   - Developer guide

## Configuration

**Global Config** (`~/.config/specify/config.json`):
```json
{
  "skills": {
    "registry_url": "https://registry.agentic-sdlc.io",
    "auto_update": false,
    "evaluation_required": false,
    "default_categories": ["frontend", "backend", "devops"]
  }
}
```

**Project Config** (`.specify/skills.json`):
- Automatically managed
- Tracks installed skills
- Stores evaluation results

## Security Considerations

1. **Skill Verification**
   - Check integrity hashes
   - Verify signatures (future)
   - Sandboxed execution

2. **Registry Trust**
   - Official registry vetted
   - Community registry warnings
   - Private registry support

3. **Local Skills**
   - Path validation
   - No directory traversal
   - Symlink handling

## Migration from External Skills

**Script:** `scripts/migrate-external-skills.py`

```python
#!/usr/bin/env python3
"""Migrate from external_skills.md to skills.json"""

def migrate():
    # Parse external_skills.md
    # Extract skill URLs
    # Install each skill
    # Generate skills.json
    # Create backup
    pass

if __name__ == "__main__":
    migrate()
```

**Usage:**
```bash
# Preview migration
specify skill migrate-from-external --dry-run

# Execute migration
specify skill migrate-from-external

# Show migration report
specify skill migrate-from-external --report
```

## Testing Strategy

1. **Unit Tests**
   - Manifest parsing
   - Skill installation
   - Version resolution

2. **Integration Tests**
   - End-to-end install flow
   - Registry communication
   - Context injection

3. **Evaluation Tests**
   - Review scoring
   - Task evaluation
   - Report generation

## Success Metrics

- Skills can be installed/uninstalled in <5 seconds
- Search returns results in <2 seconds
- Evaluation completes in <30 seconds
- 90%+ skill match accuracy during auto-discovery
- Zero breaking changes to existing workflows
