---
description: Create or update the project constitution from interactive or provided principle inputs, ensuring all dependent templates stay in sync.
handoffs: 
  - label: Build Specification
    agent: adlc.spec.specify
    prompt: Implement the feature specification based on the updated constitution. I want to build...
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

You are updating the project constitution at `{REPO_ROOT}/.specify/memory/constitution.md`. This file is a TEMPLATE containing placeholder tokens in square brackets (e.g. `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]`). Your job is to (a) collect/derive concrete values, (b) fill the template precisely, and (c) propagate any amendments across dependent artifacts.

**Note**: If `{REPO_ROOT}/.specify/memory/constitution.md` does not exist yet, it should have been initialized from `{REPO_ROOT}/.specify/templates/constitution-template.md` during project setup. If it's missing, copy the template first.

Follow this execution flow:

1. Load the existing constitution at `{REPO_ROOT}/.specify/memory/constitution.md`:
   - Identify every placeholder token of the form `[ALL_CAPS_IDENTIFIER]`
   - **IMPORTANT**: The user might require fewer or more principles than the template. Respect any specified count.

2. Collect/derive values for placeholders:
   - If user input supplies a value, use it
   - If team constitution exists, inherit principles from it (numbered list with `**Principle Name**` pattern)
   - Otherwise infer from existing repo context (README, docs, prior constitution versions)
   - For governance dates: `RATIFICATION_DATE` is the original adoption date (if unknown, ask or mark TODO), `LAST_AMENDED_DATE` is today if changes are made
   - `CONSTITUTION_VERSION` must increment according to semantic versioning:
     - MAJOR: Backward incompatible governance/principle removals or redefinitions
     - MINOR: New principle/section added or materially expanded guidance
     - PATCH: Clarifications, wording, typo fixes, non-semantic refinements

3. Draft the updated constitution content:
   - Replace every placeholder with concrete text (no bracketed tokens left)
   - Preserve heading hierarchy; remove comments once replaced
   - Ensure each Principle section has: succinct name, rules (paragraph or bullets), rationale if not obvious
   - Ensure Governance section lists amendment procedure, versioning policy, and compliance expectations

4. Consistency propagation checklist (READ-ONLY - report discrepancies, do NOT modify preset templates):
   - Review `{REPO_ROOT}/.specify/templates/plan-template.md` - check "Constitution Check" alignment
   - Review `{REPO_ROOT}/.specify/templates/spec-template.md` - check requirements alignment
   - Review `{REPO_ROOT}/.specify/templates/tasks-template.md` - check task categorization
   - Flag any runtime guidance docs (README.md, AGENTS.md) that may reference changed principles
   - Report all findings in the Sync Impact Report

5. Produce a Sync Impact Report (prepend as HTML comment at top of constitution file):
   - Version change: old → new
   - Modified principles (old title → new title if renamed)
   - Added/removed sections
   - Templates requiring updates (✅ updated / ⚠ pending)
   - Follow-up TODOs if any placeholders intentionally deferred

6. Validation before final output:
   - No remaining unexplained bracket tokens
   - Version line matches report
   - Dates in ISO format YYYY-MM-DD
   - Principles are declarative and testable

7. Write the completed constitution to `{REPO_ROOT}/.specify/memory/constitution.md` (overwrite).

8. Output final summary to the user:
   - New version and bump rationale
   - Files flagged for manual follow-up
   - Suggested commit message (e.g., `docs: amend constitution to vX.Y.Z`)

## Formatting Requirements

- Use Markdown headings exactly as in template (do not change levels)
- Keep lines under 100 characters where practical
- Single blank line between sections
- No trailing whitespace

If critical info is missing (e.g., ratification date unknown), insert `TODO(<FIELD_NAME>): explanation` and include in the Sync Impact Report.

Do not create a new template; always operate on the existing `{REPO_ROOT}/.specify/memory/constitution.md` file.