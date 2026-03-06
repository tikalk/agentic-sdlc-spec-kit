# Quick Extension - Session-Based Ad-Hoc Task Execution

A streamlined, session-based workflow for ad-hoc task execution without file artifacts. Quick compresses the full spec-driven workflow into a single command with conversation-only interactions.

## Overview

Quick follows the 12-factors methodology in a compact, single-command session:

```
Mission Brief → Context Discovery → Plan Generation → Task Breakdown → Execution
```

**No file artifacts are created** - everything happens in the conversation with your AI agent.

### Enforcement Mode

Quick uses **strict enforcement checkpoints** to ensure the workflow is followed correctly:
- **7 enforcement checkpoints** (**⚠️**) with mandatory user confirmations
- **Sequential execution only** - No phase can be skipped
- **Stop-and-wait** - AI pauses at each checkpoint for user approval
- **No auto-proceed** - Every phase requires explicit user confirmation

This prevents the AI from skipping phases or defaulting to file analysis mode.

## Quick Start

```bash
/quick.implement "fix authentication bug in login flow"
```

## How It Works

### Phase 1: Mission Brief (⚠️ Enforcement Checkpoint)
Quick asks 2-3 questions to understand what you're doing:
- What needs to be done?
- What defines success?
- Any constraints?

**Approval #1**: You see the Mission Brief and confirm before proceeding.
- **⚠️ Mandatory stop**: AI waits for "yes" confirmation

### Phase 2: Context Discovery (⚠️ Enforcement Checkpoint)
You provide any relevant context:
- Project files to examine
- Documentation to reference
- Technical constraints
- Examples to follow

**⚠️ Mandatory stop**: AI waits for context confirmation before reading files.

### Phase 3: Plan Generation (Internal)
Quick mentally plans the approach based on your brief and context. This is AI internal reasoning - not displayed.

### Phase 4: Task Breakdown (⚠️ Enforcement Checkpoint)
Quick generates a concrete task checklist:
```markdown
- [ ] Add error handling to login API
- [ ] Update session token validation
- [ ] Add unit tests for auth flow
- [ ] Update documentation
```

**Approval #2**: You see the full task list and confirm before execution.
- **⚠️ Mandatory stop**: AI waits for "yes" confirmation

### Phase 5: Sequential Execution (⚠️ Enforcement Checkpoint)
Quick executes tasks one at a time:
- Displays task being executed
- Makes necessary code changes
- Shows what was done
- Confirms completion
- **⚠️ Mandatory pause**: Waits for "Next task ready?" confirmation before proceeding

**Stop on error**: If a task fails, Quick stops and asks what to do next.
- **⚠️ Mandatory wait**: Does not auto-retry or auto-skip

### Phase 6: Summary (⚠️ Enforcement Checkpoint)
Quick shows completion status:
- All tasks completed ✅
- Files modified
- Next steps (testing, review, etc.)

**⚠️ Final summary**: Only shows completion after all tasks verified.

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

## Execution Flow (With Enforcement Checkpoints)

```text
/quick.implement "your task description"
  ↓
⚠️ CHECKPOINT 1: Mission Brief (2-3 questions)
  ↓
⚠️ STOP: Approval #1: "Proceed with this brief?"
  ↓
⚠️ CHECKPOINT 2: Context Discovery (user provides context)
  ↓
⚠️ STOP: Approval context received?
  ↓
⚠️ CHECKPOINT 3: Plan Generation (AI internal planning)
  ↓
⚠️ CHECKPOINT 4: Task Breakdown (show checklist)
  ↓
⚠️ STOP: Approval #2: "Proceed with these tasks?"
  ↓
⚠️ CHECKPOINT 5: Sequential Execution (one task at a time)
  ↓
⚠️ STOP: "Next task ready?" (per task)
  ↓
⚠️ CHECKPOINT 6: Summary
  ↓
⚠️ STOP: Implementation complete
```

### Enforcement Guarantees

- **Phase 1**: Mission Brief must be collected and approved
- **Phase 2**: Context must be collected and confirmed
- **Phase 5**: Each task must complete before next task starts
- **All phases**: Require explicit user "yes" to proceed
- **No skipping**: Phases cannot be bypassed
- **No auto-proceed**: AI never moves forward without confirmation

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