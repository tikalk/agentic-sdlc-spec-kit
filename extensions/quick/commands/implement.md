---
description: Session-based ad-hoc task execution without file artifacts (Mission Brief → Context Discovery → Plan Generation → Task Breakdown → Execution)
scripts:
  sh: |
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    echo "REPO_ROOT='$REPO_ROOT'"
    echo "CURRENT_BRANCH='$CURRENT_BRANCH'"
  ps: |
    $repoRoot = git rev-parse --show-toplevel 2>$null | Select-Object -First 1
    if (-not $repoRoot) { $repoRoot = Get-Location }
    $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null | Select-Object -First 1
    if (-not $currentBranch) { $currentBranch = "main" }
    "REPO_ROOT='$repoRoot'"
    "CURRENT_BRANCH='$currentBranch'"
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Execute a **session-based, ad-hoc task workflow** without creating any file artifacts. All interactions happen in conversation, following the 12-factors methodology:
1. Mission Brief → 2. Context Discovery → 3. Plan Generation → 4. Task Breakdown → 5. Execution

**No file artifacts are created** (no PLAN.md, TASKS.md, CONTEXT.md, MISSION_BRIEF.md).

## Phase 1: Environment & Initialization

Run `{SCRIPT}` from repository root and parse output for REPO_ROOT and CURRENT_BRANCH. All paths must be absolute.

**IMPORTANT**: Run this script only ONCE. Use the output to get REPO_ROOT and CURRENT_BRANCH.

## Phase 2: Mission Brief

### Step 1: Gather Mission Brief Information

Ask the user 2-3 clarifying questions to build a Mission Brief:

```markdown
## Mission Brief Questions

1. **What needs to be done?**
   - Ask for the primary task/feature/fix being implemented
   
2. **What defines success?**
   - Ask for success criteria: How do we know this is done?
   
3. **Any constraints?** (optional - only ask if relevant)
   - Time constraints, priority, dependencies, limitations, etc.
```

Ask these questions one at a time if needed to keep the conversation compact.

### Step 2: Display Mission Brief for Approval #1

After collecting the information, display the Mission Brief in this format:

```markdown
## Mission Brief

**Goal**: {summary what needs to be done}

**Success Criteria**:
- {success criterion 1}
- {success criterion 2}
- {success criterion 3}

**Constraints**:
- {constraint 1}
- {constraint 2}
```

**Ask the user**: "Proceed with this Mission Brief? (yes/no)"

If user says "no", ask what needs to be adjusted. Re-display and ask again.

If user says "yes", proceed to Phase 3.

## Phase 3: Context Discovery

Ask the user for relevant context to help with planning:

```markdown
## Context Discovery

Please provide any relevant context:

- **Project files**: Specific files or directories to examine?
- **Documentation**: Any existing specs, docs, or notes?
- **Technical constraints**: Any technical limitations or preferences?
- **Examples**: Similar implementations to reference?
```

Wait for user input. User may provide:
- File paths to read (`src/auth/login.ts`, `docs/api.md`, etc.)
- General context explanations
- URLs or references
- "N/A" or "none" if not needed

**NOTE**: Do NOT create any context files. Context stays in conversation/memory.

## Phase 4: Plan Generation

Based on the Mission Brief + Context, generate a **mental plan** (not written down) for the implementation:

- Identify key components affected
- Determine technical approach
- Identify dependencies or risks
- Plan execution strategy

**This happens in your internal reasoning** - do NOT display or document the plan. This is just your internal preparation for task breakdown.

## Phase 5: Task Breakdown

Based on your mental plan, generate and display a **simple task checklist**:

```markdown
## Task Breakdown

- [ ] {Task 1 description}
- [ ] {Task 2 description}
- [ ] {Task 3 description}
- [ ] {Task 4 description}
- [ ] {Task 5 description}
```

**Guidelines**:
- Keep tasks concrete and actionable
- Each task should be completable in one conversation turn
- Organize logically (setup → core → polish)
- Aim for 3-8 tasks total (keep it compact)
- Use clear, specific descriptions

## Phase 6: Approval #2

**Display the task list** and ask the user:

```markdown
## Ready to Execute

Here are the tasks I will execute:

{Your task list from Phase 5}

**Proceed with these tasks?** (yes/no)
```

If user says "no", ask what changes are needed and regenerate the task list. Ask again.

If user says "yes", proceed to Phase 7.

## Phase 7: Sequential Execution

Execute tasks **one at a time**, in order.

### For Each Task:

#### Display Task Start
```markdown
---
## Task {N}/{Total}: {task description}
```

#### Execute Task
- Read files if needed
- Make necessary changes using Write/Edit tools
- If reading files is needed, understand their content first

#### Verify After Each Task
Display what was changed/created:

```markdown
✅ **Completed**: {brief summary of what was done}

Changes made:
- {file 1}: {change summary}
- {file 2}: {change summary}
```

#### Move to Next Task
Proceed to the next task in the checklist.

### Error Handling

**If a task fails**:
1. **STOP** immediately
2. Display error message with context:
   ```markdown
   ❌ **Task Failed**: {task description}
   
   Error: {error message}
   
   What would you like to do?
   - Retry this task
   - Skip and continue to next task
   - Stop execution
   ```
3. Wait for user decision
4. Act accordingly

**Do NOT proceed automatically** on error. Always ask user what to do.

### Task Completion Tracking

After each task is verified, **mark it as complete** in the displayed checklist (not in a file):

```markdown
- [x] {Task 1 description}
- [ ] {Task 2 description}
- [ ] {Task 3 description}
```

Re-display the checklist so user can see progress (in-memory only).

## Phase 8: Summary

After all tasks complete (or execution stops):

### Success Case
```markdown
## Quick Implementation Complete ✅

**All tasks completed successfully**:

- [x] {Task 1 description}
- [x] {Task 2 description}
- [x] {Task 3 description}

**Files modified**: {count files changed}

**Next steps**: {optional suggestions like testing, review, etc.}
```

### Partial Completion or Failure
```markdown
## Quick Implementation Summary

**Completed tasks**:
- [x] {Task 1 description}
- [x] {Task 2 description}

**Failed tasks**:
- [ ] {Task 3 description} → {error reason}

**Recommendation**: {what to do next}
```

## Key Constraints

1. **NO FILE ARTIFACTS**: Do NOT create PLAN.md, TASKS.md, CONTEXT.md, MISSION_BRIEF.md, or any other workflow files
2. **SESSION-ONLY**: All interactions happen in conversation/memory
3. **NO AUTO-COMMIT**: Do not run git commands for commits (user decides)
4. **STOP ON ERROR**: Halt execution and ask user what to do on failure
5. **SEQUENTIAL ONLY**: Execute one task at a time, no parallel execution
6. **MARK PROGRESS**: Display checklist updates in conversation (not files)
7. **MINIMAL ARTIFACTS**: Only create/update code/project files as needed

## Output Notes

- All file modifications are done in the actual codebase
- No workflow/documentation files are created
- User manages git commits manually
- Execution history is conversation-based only