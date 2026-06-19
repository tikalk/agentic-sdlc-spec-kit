#!/usr/bin/env bash
# Git extension: publish.sh
# Push the current branch and create a PR (GitHub) or MR (GitLab).
#
# Usage: publish.sh [--draft] --title "..." [--body "..."] [--target-branch "..."]
#   e.g.: publish.sh --title "Add login feature" --body "Closes #123"
#   e.g.: publish.sh --draft --title "WIP: Refactor auth"

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./git-common.sh
. "$SCRIPT_DIR/git-common.sh"

# --- Parse arguments ---
DRAFT=false
TITLE=""
BODY=""
TARGET_BRANCH="main"

while [ $# -gt 0 ]; do
    case "$1" in
        --draft)
            DRAFT=true
            shift
            ;;
        --title)
            shift
            TITLE="$1"
            shift
            ;;
        --body)
            shift
            BODY="$1"
            shift
            ;;
        --target-branch)
            shift
            TARGET_BRANCH="$1"
            shift
            ;;
        --source-branch)
            shift
            # Source branch is auto-detected; ignore explicit override
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# --- Detect project root ---
REPO_ROOT=$(get_repo_root)
cd "$REPO_ROOT"

# --- Check git ---
if ! has_git "$REPO_ROOT"; then
    echo "[specify] Error: Not a Git repository" >&2
    exit 1
fi

# --- Detect branch ---
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "HEAD" ]; then
    echo "[specify] Error: Not on a valid branch (detached HEAD)" >&2
    exit 1
fi

if [ "$BRANCH" = "$TARGET_BRANCH" ]; then
    echo "[specify] Error: Already on target branch ($TARGET_BRANCH); switch to a feature branch first" >&2
    exit 1
fi

# --- Detect remote platform ---
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
PLATFORM="unknown"
if echo "$REMOTE_URL" | grep -qi "github"; then
    PLATFORM="github"
elif echo "$REMOTE_URL" | grep -qi "gitlab"; then
    PLATFORM="gitlab"
elif echo "$REMOTE_URL" | grep -qi "dev.azure"; then
    PLATFORM="azure"
fi

# --- Ensure title ---
if [ -z "$TITLE" ]; then
    # Generate from branch name
    TITLE=$(echo "$BRANCH" | sed 's/^[^/]*\/\(.*\)$/\1/' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
    echo "[specify] No --title provided; generated: $TITLE" >&2
fi

# --- Check for uncommitted changes ---
if ! git diff --quiet HEAD 2>/dev/null || ! git diff --cached --quiet 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
    echo "[specify] Warning: Uncommitted changes found. Commit or stash before publishing." >&2
    exit 1
fi

# --- Check for unpushed commits ---
UNPUSHED=$(git log --oneline "origin/$BRANCH..$BRANCH" 2>/dev/null || true)
if [ -z "$UNPUSHED" ] && ! git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
    # Branch doesn't exist on remote yet — that's fine, we'll push it
    :
fi

# --- Push ---
echo "[specify] Pushing branch $BRANCH to origin..." >&2
PUSH_OUT=$(git push -u origin "$BRANCH" 2>&1) || {
    echo "[specify] Error: Push failed: $PUSH_OUT" >&2
    exit 1
}

# --- Create PR/MR ---
PR_URL=""
case "$PLATFORM" in
    github)
        if command -v gh &> /dev/null; then
            ARGS=(pr create --title "$TITLE" --base "$TARGET_BRANCH" --head "$BRANCH")
            [ -n "$BODY" ] && ARGS+=(--body "$BODY")
            $DRAFT && ARGS+=(--draft)
            PR_URL=$(gh "${ARGS[@]}" 2>&1) || {
                echo "[specify] Error: gh pr create failed: $PR_URL" >&2
                exit 1
            }
        else
            echo "[specify] Error: 'gh' CLI not found. Install GitHub CLI to create PRs." >&2
            exit 1
        fi
        ;;
    gitlab)
        if command -v glab &> /dev/null; then
            ARGS=(mr create --title "$TITLE" --target-branch "$TARGET_BRANCH" --source-branch "$BRANCH")
            [ -n "$BODY" ] && ARGS+=(--description "$BODY")
            $DRAFT && ARGS+=(--draft)
            PR_URL=$(glab "${ARGS[@]}" 2>&1) || {
                echo "[specify] Error: glab mr create failed: $PR_URL" >&2
                exit 1
            }
        else
            echo "[specify] Error: 'glab' CLI not found. Install GitLab CLI to create MRs." >&2
            exit 1
        fi
        ;;
    azure)
        echo "[specify] Warning: Azure DevOps not fully supported. PR creation skipped." >&2
        echo "[specify] Branch $BRANCH has been pushed." >&2
        exit 0
        ;;
    *)
        echo "[specify] Unknown platform for remote: $REMOTE_URL" >&2
        echo "[specify] Branch $BRANCH has been pushed. Create PR/MR manually." >&2
        exit 0
        ;;
esac

# --- Output summary ---
echo ""
echo "## Publish Summary"
echo "| Operation | Status |"
echo "|-----------|--------|"
echo "| Push | Success |"
echo "| PR/MR URL | $PR_URL |"
echo "| Title | $TITLE |"
echo "| Branch | $BRANCH → $TARGET_BRANCH |"
echo "| Draft | $DRAFT |"
echo ""
