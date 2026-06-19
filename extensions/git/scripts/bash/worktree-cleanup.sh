#!/usr/bin/env bash
# Git extension: worktree-cleanup.sh
# Removes a feature worktree directory. Idempotent.
#
# Usage: worktree-cleanup.sh --feature <name> [--delete-branch] [--force]

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source git-common.sh for get_repo_root, has_git, etc.
_common_loaded=false
if [ -f "$SCRIPT_DIR/git-common.sh" ]; then
    source "$SCRIPT_DIR/git-common.sh"
    _common_loaded=true
else
    _dir="$SCRIPT_DIR"
    while [ "$_dir" != "/" ]; do
        if [ -f "$_dir/.specify/scripts/bash/common.sh" ]; then
            source "$_dir/.specify/scripts/bash/common.sh"
            _common_loaded=true
            break
        fi
        if [ -f "$_dir/scripts/bash/common.sh" ]; then
            source "$_dir/scripts/bash/common.sh"
            _common_loaded=true
            break
        fi
        _dir="$(dirname "$_dir")"
    done
fi
if [ "$_common_loaded" != "true" ]; then
    echo "Error: Could not locate git-common.sh or common.sh" >&2
    exit 1
fi

if type get_repo_root >/dev/null 2>&1; then
    REPO_ROOT="$(get_repo_root)"
else
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
FEATURE=""
DELETE_BRANCH=false
FORCE=false

while [ $# -gt 0 ]; do
    case "$1" in
        --feature) FEATURE="$2"; shift 2 ;;
        --delete-branch) DELETE_BRANCH=true; shift ;;
        --force) FORCE=true; shift ;;
        --help|-h)
            echo "Usage: worktree-cleanup.sh --feature <name> [--delete-branch] [--force]"
            exit 0
            ;;
        *) echo "Error: Unknown arg: $1" >&2; exit 1 ;;
    esac
done

[ -n "$FEATURE" ] || { echo "Error: --feature is required" >&2; exit 1; }

# Resolve worktree base dir from config
WORKTREE_BASE_DIR=".worktrees"
_cfg="$REPO_ROOT/.specify/extensions/git/git-config.yml"
if [ -f "$_cfg" ]; then
    _val="$(grep -E '^[[:space:]]*base_dir[[:space:]]*:' "$_cfg" 2>/dev/null | tail -1 | sed -E 's/^[[:space:]]*base_dir[[:space:]]*:[[:space:]]*//; s/[[:space:]]*#.*//; s/["'"'"']//g' || true)"
    [ -n "$_val" ] && WORKTREE_BASE_DIR="$_val"
fi
WORKTREE_PATH="$REPO_ROOT/$WORKTREE_BASE_DIR/$FEATURE"
MANIFEST_FILE="$WORKTREE_PATH/git.worktree-manifest.json"

# Idempotent: if worktree does not exist, report success
if [ ! -d "$WORKTREE_PATH" ]; then
    if command -v jq >/dev/null 2>&1; then
        jq -cn --arg feature "$FEATURE" --arg path "${WORKTREE_PATH#"$REPO_ROOT/"}" '{removed:true, worktree_path:$path, already_removed:true, ok:true}'
    else
        printf '{"removed":true,"worktree_path":"%s","already_removed":true,"ok":true}\n' "${WORKTREE_PATH#"$REPO_ROOT/"}"
    fi
    exit 0
fi

# Safety: check for uncommitted changes (excluding manifest)
if [ "$FORCE" != "true" ]; then
    _manifest_name="git.worktree-manifest.json"
    _dirty="$(git -C "$WORKTREE_PATH" status --porcelain 2>/dev/null | grep -v "^?? $_manifest_name\$" | grep -v "^.. $_manifest_name\$" || true)"
    if [ -n "$_dirty" ]; then
        echo "Error: Worktree has uncommitted changes (excluding the manifest):" >&2
        echo "$_dirty" >&2
        echo "Use --force to override." >&2
        exit 1
    fi
fi

# Remove the worktree
git -C "$REPO_ROOT" worktree remove --force "$WORKTREE_PATH" 2>/dev/null || rm -rf "$WORKTREE_PATH"

# Optionally delete the feature branch
_branch_deleted=false
if [ "$DELETE_BRANCH" = "true" ]; then
    if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$FEATURE" 2>/dev/null; then
        git -C "$REPO_ROOT" branch -D "$FEATURE" 2>/dev/null && _branch_deleted=true
    fi
fi

_rel_path="${WORKTREE_PATH#"$REPO_ROOT/"}"
if command -v jq >/dev/null 2>&1; then
    jq -cn \
        --arg feature "$FEATURE" \
        --arg path "$_rel_path" \
        --argjson branch_deleted "$_branch_deleted" \
        '{removed:true, feature:$feature, worktree_path:$path, branch_deleted:$branch_deleted, ok:true}'
else
    printf '{"removed":true,"feature":"%s","worktree_path":"%s","branch_deleted":%s,"ok":true}\n' \
        "$FEATURE" "$_rel_path" "$_branch_deleted"
fi
