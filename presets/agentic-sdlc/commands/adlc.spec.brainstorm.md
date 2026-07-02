---
description: Structured exploration of approaches, tradeoffs, and architecture before specification creation.
handoffs:
  - label: Create Feature Specification
    agent: adlc.spec.specify
    prompt: Create a specification from the brainstorm context
    send: true
---

## MANDATORY: Pre-Execution Hooks

**STOP. Before reading User Input or doing ANY other work, execute extension hooks.**

0. Determine `{REPO_ROOT}` by running `git rev-parse --show-toplevel 2>/dev/null`. If that fails, walk up from the current directory until you find a `.git` directory or `.specify/init-options.json` and use that parent as `{REPO_ROOT}`.
1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, state `No hooks file found` and skip to User Input.
2. Read `{REPO_ROOT}/.specify/extensions.yml` and find `hooks.before_brainstorm`.
3. Skip any hook with `enabled: false`. Skip any hook with a non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Pre-Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}

      Wait for the result of the hook command before proceeding.
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`): Display the hook name, command, and description. Let the user decide.
5. State which hooks were executed, then proceed to User Input.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Explore the problem space, identify approaches, surface tradeoffs, and document architectural context before specification creation. This is a **read-only exploration** phase — no files outside `.specify/drafts/` are created or modified.

**When to use**: Before `/spec.specify`, when the problem space is complex, multiple approaches exist, or architectural decisions need exploration.

**Output**: `.specify/drafts/brainstorm-context.md` — consumed by `/spec.specify` to seed the specification.

## Execution Steps

### 1. Build Problem Understanding

Read the user input and identify:

- **Core problem** — What is the fundamental need or pain point?
- **Stakeholders** — Who is affected by this problem?
- **Success signals** — What would indicate success?
- **Constraints** — Known boundaries, limitations, or requirements

### 2. Structured Exploration

Explore the problem space using these lenses:

**a. Model of Understanding**
- What are the key concepts, entities, and relationships?
- What mental models help reason about this domain?
- What analogous problems have known solutions?

**b. Approach Identification**
- Identify 2-3 distinct approaches to solving the problem
- For each approach, note:
  - Core idea and how it works
  - Key tradeoffs (complexity, flexibility, performance, maintainability)
  - Risk factors and unknowns
  - Dependencies and prerequisites

**c. Architecture Considerations**
- What architectural patterns are relevant?
- How does this fit into the existing system?
- What integration points exist?
- What data flows are involved?

**d. Risk Assessment**
- What could go wrong?
- What assumptions are we making?
- What information is missing?
- What decisions carry the most impact?

### 3. Synthesize and Document

Create `.specify/drafts/brainstorm-context.md`:

```markdown
mkdir -p .specify/drafts
```

Write to `.specify/drafts/brainstorm-context.md` with this structure:

```markdown
# Brainstorm Context: [Short Name]

## Problem Statement

[Concise description of the problem being solved]

## Key Concepts

- **[Concept]**: [Description]
- **[Concept]**: [Description]

## Approaches Considered

### Approach A: [Name]
- **How it works**: [Brief description]
- **Tradeoffs**: [Key tradeoffs]
- **Risks**: [Risk factors]
- **Best for**: [When this approach shines]

### Approach B: [Name]
- **How it works**: [Brief description]
- **Tradeoffs**: [Key tradeoffs]
- **Risks**: [Risk factors]
- **Best for**: [When this approach shines]

## Architecture Notes

[Relevant architectural context, patterns, and integration points]

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [Risk] | H/M/L | H/M/L | [Mitigation strategy] |

## Open Questions

- [Question 1]
- [Question 2]

## Recommended Direction

[Your assessment of the best approach, with rationale]
```

### 4. User Gate

Present the brainstorm context to the user with:

```markdown
## Brainstorm Complete

The exploration is documented in `.specify/drafts/brainstorm-context.md`.

**Summary**:
- **Problem**: [Core problem]
- **Approaches**: [N] considered — recommended: [Approach name]
- **Key Risks**: [Top 1-2 risks]
- **Open Questions**: [N] unresolved

**Next step**: Run `/spec.specify <description>` to create the specification. The brainstorm context will be automatically consumed to seed the spec.

**Ready to proceed?** [Wait for user confirmation]
```

Wait for user confirmation before finishing. If the user wants to explore more, loop back to Step 2.

## Quick Guidelines

- **No implementation details** — focus on WHAT and WHY, not language/framework specifics
- **No file mutations** — only write to `.specify/drafts/brainstorm-context.md`
- **Be honest about tradeoffs** — surface real costs, don't oversell preferred approaches
- **Document assumptions** — note any assumptions that could change the recommendation
- **Think structurally** — use models, patterns, and analogies to illuminate the problem

## Post-Execution Hooks

1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_brainstorm`.
3. Skip hooks with `enabled: false` or non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`): Display hook info for user decision.
5. If no hooks registered, skip silently.
