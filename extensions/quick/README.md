# Quick Extension - Session-Based Ad-Hoc Task Execution

A streamlined, session-based workflow for ad-hoc task execution without file artifacts. Quick compresses the full spec-driven workflow into a single command with conversation-only interactions.

## Overview

Quick follows the 12-factors methodology in a compact, single-command session:

```
Mission Brief → Context Discovery → Plan Generation → Task Breakdown → Execution
```

**No file artifacts are created** - everything happens in the conversation with your AI agent.

## Quick Start

```bash
/quick.implement "fix authentication bug in login flow"
```

## How It Works

### Phase 1: Mission Brief
Quick asks 2-3 questions to understand what you're doing:
- What needs to be done?
- What defines success?
- Any constraints?

**Approval #1**: You see the Mission Brief and confirm before proceeding.

### Phase 2: Context Discovery
You provide any relevant context:
- Project files to examine
- Documentation to reference
- Technical constraints
- Examples to follow

### Phase 3: Plan Generation (Internal)
Quick mentally plans the approach based on your brief and context. This is AI internal reasoning - not displayed.

### Phase 4: Task Breakdown
Quick generates a concrete task checklist:
```markdown
- [ ] Add error handling to login API
- [ ] Update session token validation
- [ ] Add unit tests for auth flow
- [ ] Update documentation
```

**Approval #2**: You see the full task list and confirm before execution.

### Phase 5: Sequential Execution
Quick executes tasks one at a time:
- Displays task being executed
- Makes necessary code changes
- Shows what was done
- Confirms completion

**Stop on error**: If a task fails, Quick stops and asks what to do next.

### Phase 6: Summary
Quick shows completion status:
- All tasks completed ✅
- Files modified
- Next steps (testing, review, etc.)

## When to Use Quick

### Perfect For:
- Ad-hoc bug fixes
- Small features
- Refactoring tasks
- Documentation updates
- Quick experiments

### Not For:
- Large-scale features (use full spec-driven workflow)
- Architecture changes (use `/architect` extension)
- Complex multi-phase projects (use `/spec.specify`, `/spec.plan`, `/spec.tasks`, `/spec.implement`)
- Projects requiring extensive documentation (use full workflow)

## Commands

| Command | Purpose |
|---------|---------|
| `/quick.implement` | Session-based ad-hoc task execution |

## Key Differences from Full Workflow

| Aspect | Quick | Full Workflow |
|--------|-------|---------------|
| File Artifacts | None (session-only) | spec.md, plan.md, tasks.md, etc. |
| Commands | 1 (`/quick.implement`) | 4+ commands |
| Interaction | 2 approval points | Review at each stage |
| Task Complexity | Simple checklist | Detailed task breakdown with phases |
| Use Case | Ad-hoc, small tasks | Full-featured spec-driven development |

## Execution Flow

```text
/quick.implement "your task description"
  ↓
Phase 1: Mission Brief (2-3 questions)
  ↓
Approval #1: "Proceed with this brief?"
  ↓
Phase 2: Context Discovery (user provides context)
  ↓
Phase 3: Plan Generation (AI internal planning)
  ↓
Phase 4: Task Breakdown (show checklist)
  ↓
Approval #2: "Proceed with these tasks?"
  ↓
Phase 5: Sequential Execution
  ↓
Phase 6: Summary
```

## Error Handling

If a task fails during execution:

```markdown
❌ Task Failed: Add error handling to login API

Error: TypeError: Cannot read property 'token' of undefined

What would you like to do?
- Retry this task
- Skip and continue to next task
- Stop execution
```

Quick **always stops on error** and waits for your decision.

## Examples

### Example 1: Bug Fix

```bash
/quick.implement "fix login page not redirecting after authentication"
```

**Mission Brief**:
- Goal: Fix login redirect issue
- Success: Login redirects to dashboard after successful auth
- Constraints: Must work with existing session token

**Task Breakdown**:
- [ ] Investigate login component redirect logic
- [ ] Fix redirect condition bug
- [ ] Test redirect flow
- [ ] Verify integration

### Example 2: Small Feature

```bash
/quick.implement "add dark mode toggle to settings page"
```

**Mission Brief**:
- Goal: Add dark mode toggle
- Success: Button toggles theme, persists preference
- Constraints: Use existing theme system

**Task Breakdown**:
- [ ] Add toggle UI component
- [ ] Implement theme switch logic
- [ ] Persist theme preference
- [ ] Test theme switching

## Installation

Quick is **bundled by default** in new projects:

```bash
specify init my-project
# Quick extension is automatically included
```

For manual installation:

```bash
specify extension add quick
```

## Configuration

Quick requires **no configuration** - it's designed to work out-of-the-box for session-based tasks.

## Limitations

1. **No file artifacts** - Quick doesn't save workflow state to files
2. **Session-only** - History is lost after conversation ends
3. **Sequential execution** - One task at a time, no parallel work
4. **Simple task structure** - No complex phases, dependencies, or sync/async modes
5. **Error handling required** - Must interact with user on failures

## Comparison to Full Spec-Driven Workflow

### Full Workflow (spec.md, plan.md, tasks.md, implement.md)
- Comprehensive documentation
- Multiple review checkpoints
- Complex task breakdown with phases
- Sync/async execution modes
- Atomic commits (configurable)
- File-based state management

### Quick (/quick.implement)
- No documentation files
- 2 approval points only
- Simple task checklist
- Sequential execution only
- No auto-commits
- Session-only workflow

## Related Extensions

- **architect** - Architecture decision records and documentation
- **levelup** - Context module discovery and contribution

## License

MIT

## Author

Agentic SDLC Team

## Repository

https://github.com/tikalk/agentic-sdlc-spec-kit/tree/main/extensions/quick