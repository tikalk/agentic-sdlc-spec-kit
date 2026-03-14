---
description: Build a single skill from accepted CDRs based on user input
scripts:
  sh: scripts/bash/setup-levelup.sh --json
  ps: scripts/powershell/setup-levelup.ps1 -Json
---

## User Input

```text
$ARGUMENTS
```

**REQUIRED**: You **MUST** have user input specifying which skill to build.

**Examples of User Input**:

- `"python-error-handling"` - Build skill with this name from related CDRs
- `"CDR-005"` - Build skill specifically from CDR-005
- `"testing patterns"` - Build skill by topic, matching CDRs
- `"kubernetes deployment"` - Build skill from k8s-related CDRs

If no input provided, ask the user to specify a skill name or CDR ID.

## Goal

Build a **single skill** from accepted modules based on user input. Skills are self-contained capabilities that can be loaded by AI agents.

**Input**:
- User-specified skill name, module ID, or topic
- Accepted CDRs from `{REPO_ROOT}/.specify/drafts/cdr.md` (status "Accepted")

**Output**:
- Skill directory in `.specify/drafts/skills/{skill-name}/`
- Entry added to `.specify/drafts/skills/{skill-name}/.skills-entry.json` for `/levelup.implement`
- Ready for `/levelup.implement` to activate

## Role & Context

You are acting as a **Skill Builder** - packaging accepted CDRs into reusable skills. Your role involves:

- **Identifying** relevant CDRs for the skill
- **Structuring** skill content per team-ai-directives format
- **Writing** SKILL.md with trigger keywords
- **Organizing** references and supporting content

### Skill Structure

Skills follow the team-ai-directives format:

```
.specify/drafts/skills/{skill-name}/
├── SKILL.md           # Main skill definition (REQUIRED)
└── references/        # Supporting content (OPTIONAL)
    ├── examples/
    └── patterns/
```

### SKILL.md Format

```markdown
# {Skill Name}

{Brief description with trigger keywords for activation}

## When to Use

{Criteria for when this skill should be activated}

## Capabilities

{What this skill enables the AI agent to do}

## Instructions

{Step-by-step guidance for using this skill}

## Examples

{Usage examples}

## References

{Links to supporting content in references/}
```

## Execution Steps

### Phase 0: Environment Setup

**Objective**: Initialize CDR infrastructure and resolve paths

Run `{SCRIPT}` from repository root and parse JSON output:

```json
{
  "REPO_ROOT": "/path/to/project",
  "TEAM_DIRECTIVES": "/path/to/team-ai-directives",
  "SKILLS_DRAFTS": "/path/to/project/.specify/drafts/skills",
  "BRANCH": "current-branch"
}
```

**IMPORTANT**: Run this script only ONCE. Use the JSON output to get all paths.

Skills will be created in SKILLS_DRAFTS directory.

### Phase 1: Validate Environment

**Objective**: Ensure team-ai-directives is configured

#### Step 1: Verify Team Directives

Check if TEAM_DIRECTIVES has a value from script output.

If empty, **STOP**:
```
Team AI directives repository not configured.
Run: specify init --team-ai-directives <path-or-url>
Or set: export SPECIFY_TEAM_DIRECTIVES=/path/to/team-ai-directives
```

### Phase 2: Parse User Input

**Objective**: Determine which skill to build

Parse user input to identify:

| Input Type | Detection | Action |
|------------|-----------|--------|
| CDR ID | Matches `CDR-\d+` | Build skill from that CDR |
| Skill name | kebab-case string | Use as skill name, find matching CDRs |
| Topic | Multi-word phrase | Search CDRs by topic |

If input is ambiguous, ask for clarification.

### Phase 3: Load and Filter Modules

**Objective**: Find relevant accepted modules

#### Step 1: Load Modules

Read `{REPO_ROOT}/.specify/drafts/cdr.md` and filter CDRs:
- Status = "Accepted"
- Type = "skill" (primary) or related types

#### Step 2: Match Modules to Input

If module ID provided:
- Use that specific module
- Optionally include related modules

If skill name/topic provided:
- Search module paths and content
- Match by keywords
- Present matches for confirmation

```markdown
### Matching Modules for "{input}"

| Module | Path | Type | Relevance |
|--------|------|------|-----------|
| k8s_deployment | context_modules/rules/devops/k8s_deployment.md | rule | High |
| container_patterns | context_modules/rules/devops/container_patterns.md | rule | Medium |

**Selected**: CDR-005, CDR-007

Proceed with these CDRs? (Y/N or specify different CDRs)
```

### Phase 4: Generate Skill Structure

**Objective**: Create skill directory and files

#### Step 1: Create Directory

Use SKILLS_DRAFTS from script output:

```bash
mkdir -p {SKILLS_DRAFTS}/{skill-name}/references
```

#### Step 2: Generate SKILL.md

Build SKILL.md from CDR content:

```markdown
# {Skill Name}

{Description from CDR with trigger keywords}

Use this skill when: {trigger conditions}

## When to Use

- {Condition 1 from CDR context}
- {Condition 2}
- {Condition 3}

**Trigger Keywords**: {keywords for skill discovery}

## Capabilities

This skill enables AI agents to:

- {Capability 1 from CDR decision}
- {Capability 2}
- {Capability 3}

## Instructions

### Step 1: {First Step}

{Instructions from CDR proposed content}

### Step 2: {Second Step}

{More instructions}

## Examples

### Example 1: {Example Name}

{Code or usage example from CDR evidence}

### Example 2: {Another Example}

{Additional example}

## References

- [Pattern Details](references/pattern.md)
- [Examples](references/examples/)

## Source

Built from CDRs:
- CDR-{N}: {title}

---

*Skill Version: 1.0.0*
*Compatible with team-ai-directives*
```

#### Step 3: Create Reference Files

If CDRs contain substantial content, create reference files:

```
references/
├── pattern.md       # Detailed pattern description
├── examples/
│   ├── basic.md     # Basic usage example
│   └── advanced.md  # Advanced usage example
└── checklists/
    └── validation.md # Validation checklist
```

### Phase 5: Prepare Skills Manifest Entry

**Objective**: Prepare entry for `.skills.json`

Generate the entry for team-ai-directives `.skills.json`:

```json
{
  "local:./skills/{skill-name}": {
    "version": "1.0.0",
    "description": "{description with trigger keywords}",
    "categories": ["{category1}", "{category2}"]
  }
}
```

Save to `.specify/drafts/skills/{skill-name}/.skills-entry.json` for `/levelup.implement`.

### Phase 6: Validation

**Objective**: Validate skill structure

Check skill completeness:

- [ ] SKILL.md exists and has required sections
- [ ] Description includes trigger keywords
- [ ] At least one example provided
- [ ] References linked correctly (if any)
- [ ] `.skills-entry.json` generated

### Phase 7: Summary

**Objective**: Present skill for review

```markdown
## LevelUp Skills Summary

**Skill Name**: {skill-name}
**Location**: `.specify/drafts/skills/{skill-name}/`
**Source CDRs**: {list}

### Generated Files

| File | Status |
|------|--------|
| SKILL.md | Created |
| references/pattern.md | Created |
| .skills-entry.json | Created |

### SKILL.md Preview

\`\`\`markdown
{First 50 lines of SKILL.md}
\`\`\`

### Skills Manifest Entry

\`\`\`json
{.skills-entry.json content}
\`\`\`

### Next Steps

1. **Review** the generated skill in `.specify/drafts/skills/{skill-name}/`
2. **Edit** SKILL.md if needed
3. **Run** `/levelup.implement` to:
   - Move skill to team-ai-directives
   - Update `.skills.json`
   - Create PR
```

## Output Files

| File | Description |
|------|-------------|
| `.specify/drafts/skills/{skill-name}/SKILL.md` | Main skill definition |
| `.specify/drafts/skills/{skill-name}/references/` | Supporting content |
| `.specify/drafts/skills/{skill-name}/.skills-entry.json` | Entry for `.skills.json` (applied during implement) |

## Notes

- Builds ONE skill at a time - user specifies which
- Only uses CDRs with status "Accepted" from `.specify/drafts/cdr.md`
- Skills follow team-ai-directives format for compatibility
- Review generated skill before running `/levelup.implement`
- Skill can be edited manually before implementation

## Related Commands

- `/levelup.init` - Discover modules from codebase
- `/levelup.clarify` - Accept modules for skill building
- `/levelup.specify` - Enrich modules with feature context
- `/levelup.implement` - Move skill to team-ai-directives and set status to "active"
