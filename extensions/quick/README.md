# Quick Extension - Session-Based Ad-Hoc Task Execution

A streamlined, session-based workflow for ad-hoc task execution without file artifacts. Quick compresses the full spec-driven workflow into a single command with minimal interaction.

## Overview

Quick follows the 12-factors methodology in a compact, single-command session:

```
Mission Brief → Context Discovery → Task Breakdown → Execution (with commits)
```

**No file artifacts are created** - everything happens in the conversation with your AI agent.

### Low-Friction Design

Quick uses **task-level commits** as checkpoints instead of interactive stops:
- **1 stop**: After Mission Brief (for approval)
- **Auto-commit**: After each task completes
- **Auto-proceed**: No pauses between tasks
- **Error commits**: "WIP" commit on failure before asking user

This provides rollback capability while keeping interaction minimal.

## Quick Start

```bash
/quick.implement "fix authentication bug in login flow"
```

## How It Works

### Phase 1: Mission Brief (⚠️ Stop)
Quick asks 2-3 questions to understand what you're doing:
- What needs to be done?
- What defines success?
- Any constraints?

**Approval #1**: You see the Mission Brief and confirm before proceeding.
- **⚠️ Mandatory stop**: AI waits for "yes" confirmation

### Phase 2: Context Discovery (Auto)
You provide any relevant context:
- Project files to examine
- Documentation to reference
- Technical constraints

Quick proceeds automatically after brief input.

### Phase 3: Task Breakdown (Auto)
Quick generates a concrete task checklist:
```markdown
- [ ] Add error handling to login API
- [ ] Update session token validation
- [ ] Add unit tests for auth flow
```

**No stop** - proceeds directly to execution.

### Phase 4: Extension Hooks (Optional)

If extensions are installed (e.g., TDD), Quick checks for hooks before execution:

**Before execution**: `before_implement` hooks fire (e.g., TDD's RED→GREEN→REFACTOR)

**After execution**: `after_implement` hooks fire (e.g., TDD test validation)

Hooks execute seamlessly without interrupting the quick flow. See [Hook Support](#hook-support) for details.

### Phase 5: Execution with Task-Level Commits
Quick executes tasks one at a time:
- Displays task being executed
- Makes necessary code changes
- **Auto-commits** after each task
- Proceeds to next task automatically

```bash
git commit -m "[quick] Task 1: Add error handling to login API"
```

**Error handling**: If a task fails, Quick commits the WIP state and asks what to do next.

### Phase 5: Summary
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
| Interactive Stops | 1 (Mission Brief) | Review at each stage |
| Checkpoints | Task-level commits | Review phases + commits |
| Task Complexity | Simple checklist | Detailed task breakdown with phases |
| Use Case | Ad-hoc, small tasks | Full-featured spec-driven development |

## Execution Flow

```text
/quick.implement "your task description"
  ↓
⚠️ CHECKPOINT 1: Mission Brief (2-3 questions)
  ↓
⚠️ STOP: Approval #1: "Proceed with this brief?"
  ↓
Context Discovery (brief input)
  ↓
Task Breakdown (auto-display)
  ↓
[before_implement hooks] → Optional: TDD, etc.
  ↓
Execution (auto-proceed with commits):
  Task 1 → make changes → git commit "[quick] Task 1: ..."
  Task 2 → make changes → git commit "[quick] Task 2: ..."
  Task 3 → make changes → git commit "[quick] Task 3: ..."
  ↓
[after_implement hooks] → Optional: TDD validation, etc.
  ↓
Summary
```

## Checkpoint Strategy

Quick uses **task-level commits** as checkpoints instead of interactive stops:

| Checkpoint Type | Trigger | Purpose |
|-----------------|---------|---------|
| Mission Brief | User confirmation | Ensure understanding of goal |
| Task commit | After each task | Rollback capability |
| Error commit | On failure | Save WIP state before asking |

**Benefits**:
- User can `git reset` to any task checkpoint
- Commit history shows progress
- No need to wait for user confirmation between tasks
- Error commits save state before asking what to do

## Commit Format

**Successful task**:
```
[quick] Task 1: Add error handling to login API
```

**Failed task (WIP)**:
```
[quick] Task 2: WIP - session validation fix failed
```

## Error Handling

If a task fails during execution:

```markdown
❌ Task Failed: Add error handling to login API

Error: TypeError: Cannot read property 'token' of undefined

[Committed WIP checkpoint: [quick] Task 1: WIP - login API error]

What would you like to do?
- Retry this task
- Skip and continue to next task
- Stop execution
```

Quick **commits the WIP state** before asking your decision, so you can always rollback.

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
2. **Session-only** - History is lost after conversation ends (but commits persist)
3. **Auto-proceed** - No pause between tasks (relies on commits for checkpoints)
4. **Simple task structure** - No complex phases, dependencies, or sync/async modes
5. **Manual push** - User decides when to push/merge commits

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
- 1 interactive stop only
- Simple task checklist
- Sequential execution with auto-commits
- Task-level commits as checkpoints
- Session-only workflow (commits for history)

## Hook Support

Quick now supports extension hooks, enabling seamless integration with other Spec Kit extensions:

| Hook Point | When | Example Extension |
|------------|------|-------------------|
| `before_implement` | After Task Breakdown, before first task | TDD (RED→GREEN→REFACTOR) |
| `after_implement` | After all tasks complete | TDD (test validation) |

### TDD Integration Example

When the TDD extension is installed:

```bash
/quick.implement "add JWT authentication"
  ↓
Mission Brief → Context → Task Breakdown
  ↓
[before_implement] → TDD runs RED→GREEN→REFACTOR (in-session, no files)
  ↓
Execution with commits
  ↓
[after_implement] → TDD validation offered
  ↓
Summary
```

TDD runs entirely in-session when triggered from Quick:
- Condensed planning (3 questions instead of 5)
- Language auto-detection
- Test increment generation
- RED→GREEN→REFACTOR cycles

**No file artifacts** - TDD state is tracked in the conversation, preserving Quick's philosophy.

## Related Extensions

- **architect** - Architecture decision records and documentation
- **levelup** - Context module discovery and contribution
- **tdd** - Test-Driven Development workflow (RED→GREEN→REFACTOR)

## License

MIT

## Author

Agentic SDLC Team

## Repository

https://github.com/tikalk/agentic-sdlc-spec-kit/tree/main/extensions/quick
