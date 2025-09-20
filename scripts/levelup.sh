#!/usr/bin/env bash
# scripts/levelup.sh - /levelup command core logic
# Purpose: Capture developer learnings and contribute them to the team-ai-directives repository as a new directive.

set -euo pipefail

# --- Configuration ---
# Path to the local clone of the team-ai-directives repository
TEAM_AI_DIRECTIVES_REPO="${TEAM_AI_DIRECTIVES_REPO:-$HOME/team-ai-directives}"
# Issue tracker ticket (should be passed or inferred)
ISSUE_TRACKER_TICKET="${ISSUE_TRACKER_TICKET:-TIK-42}"
# Path to the LLM API key or credentials (if needed)
LLM_API_KEY="${LLM_API_KEY:-}" # Set as needed for your LLM provider

# --- Helper: Print usage ---
usage() {
  echo "Usage: $0 \"<developer prompt>\""
  exit 1
}

# --- Step 1: Parse argument ---
if [ "$#" -ne 1 ]; then
  usage
fi
DEV_PROMPT="$1"

# --- Step 2: Call LLM to draft asset, PR, and comment ---
draft_with_llm() {
  # Placeholder: Call your LLM here (e.g., via API or CLI)
  # Inputs: $DEV_PROMPT
  # Outputs: DRAFT_FILE, DRAFT_PR_TITLE, DRAFT_PR_BODY, DRAFT_ISSUE_COMMENT
  echo "[MOCK] Drafting knowledge asset and PR details with LLM..."
  DRAFT_FILE="new-directive.md"
  DRAFT_PR_TITLE="Add new directive: Example Title"
  DRAFT_PR_BODY="This PR adds a new directive based on recent learnings."
  DRAFT_ISSUE_COMMENT="A new directive has been proposed in PR: <PR_LINK>"
}

# --- Step 3: Human-in-the-loop confirmation ---
confirm_drafts() {
  echo "\n--- Drafted Knowledge Asset ---"
  cat "$DRAFT_FILE"
  echo "\n--- Drafted PR Title ---\n$DRAFT_PR_TITLE"
  echo "\n--- Drafted PR Body ---\n$DRAFT_PR_BODY"
  echo "\n--- Drafted Issue Comment ---\n$DRAFT_ISSUE_COMMENT"
  read -rp "\nProceed with creating the PR and posting the comment? [y/N]: " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted by user."
    exit 0
  fi
}

# --- Step 4: Git workflow to create PR ---
git_workflow() {
  cd "$TEAM_AI_DIRECTIVES_REPO"
  BRANCH_NAME="levelup/$(date +%Y%m%d%H%M%S)"
  git checkout -b "$BRANCH_NAME"
  cp "/tmp/$DRAFT_FILE" "$TEAM_AI_DIRECTIVES_REPO/$DRAFT_FILE"
  git add "$DRAFT_FILE"
  git commit -m "$DRAFT_PR_TITLE"
  git push -u origin "$BRANCH_NAME"
  # Create PR using gh CLI
  PR_URL=$(gh pr create --title "$DRAFT_PR_TITLE" --body "$DRAFT_PR_BODY" --base main)
  echo "Pull request created: $PR_URL"
}

# --- Step 5: Post summary comment to issue tracker ---
post_issue_comment() {
  # Placeholder: Post comment to issue tracker (e.g., GitHub issue, Jira, etc.)
  # For GitHub, you could use gh CLI:
  # gh issue comment "$ISSUE_TRACKER_TICKET" --body "${DRAFT_ISSUE_COMMENT//<PR_LINK>/$PR_URL}"
  echo "[MOCK] Posting comment to $ISSUE_TRACKER_TICKET: ${DRAFT_ISSUE_COMMENT//<PR_LINK>/$PR_URL}"
}

# --- Main execution ---
draft_with_llm
confirm_drafts
git_workflow
post_issue_comment
