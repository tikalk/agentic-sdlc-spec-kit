#!/usr/bin/env bash
# levelup.sh - Automate knowledge asset creation and trace summary for /levelup command

set -e

MESSAGE="$1"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ -z "$MESSAGE" ]; then
  echo "Usage: $0 \"levelup message\""
  exit 1
fi

# Example: create a new knowledge asset markdown file
ASSET_PATH="$REPO_ROOT/context_modules/rules/v1/levelup-$(date +%Y%m%d%H%M%S).md"
echo "# Levelup Knowledge Asset

$MESSAGE

---
Created: $(date)
" > "$ASSET_PATH"

echo "Created knowledge asset: $ASSET_PATH"
# TODO: Add git branch, PR, and trace summary automation
