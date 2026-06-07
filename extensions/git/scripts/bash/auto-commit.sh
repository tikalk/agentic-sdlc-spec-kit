#!/usr/bin/env bash
# Git extension: auto-commit.sh
# Automatically commit changes after a Spec Kit command completes.
# Checks per-command config keys in git-config.yml before committing.
#
# Usage: auto-commit.sh [--mode <sync|parallel|async>] [--task-id <TNNN>] <event_name>
#   e.g.: auto-commit.sh after_specify
#         auto-commit.sh --mode parallel --task-id T001 after_implement
#
# Environment variables (used when flags are not provided):
#   SPECKIT_TASK_MODE    sync (default) | parallel | async
#                        - parallel / async prefix commit messages with [TNNN]
#                          so concurrent agents' commits can be distinguished
#                        - sync preserves the original commit message format
#   SPECKIT_TASK_ID      Task id (TNNN) used to prefix the commit subject when
#                        SPECKIT_TASK_MODE is parallel or async
#
# Precedence:  --mode / --task-id flags > SPECKIT_TASK_MODE / SPECKIT_TASK_ID env > default

set -e

# ---------------------------------------------------------------------------
# Parse optional flags
# ---------------------------------------------------------------------------
TASK_MODE=""
TASK_ID=""

while [ $# -gt 0 ]; do
    case "$1" in
        --mode)
            TASK_MODE="${2:-}"
            if [ -z "$TASK_MODE" ]; then
                echo "Error: --mode requires a value (sync, parallel, async)" >&2
                exit 1
            fi
            shift 2
            ;;
        --task-id)
            TASK_ID="${2:-}"
            if [ -z "$TASK_ID" ]; then
                echo "Error: --task-id requires a value (e.g., T001)" >&2
                exit 1
            fi
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--mode <sync|parallel|async>] [--task-id <TNNN>] <event_name>"
            echo ""
            echo "Options:"
            echo "  --mode <mode>     sync (default) | parallel | async"
            echo "                    parallel/async prefix commit subject with [TNNN]"
            echo "  --task-id <TNNN>  Task id used to prefix commit subject when mode is parallel/async"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Environment variables (used when flags are not provided):"
            echo "  SPECKIT_TASK_MODE    Same as --mode"
            echo "  SPECKIT_TASK_ID      Same as --task-id"
            echo ""
            echo "Arguments:"
            echo "  <event_name>       Event that triggered the auto-commit (e.g., after_specify)"
            echo ""
            exit 0
            ;;
        --*)
            echo "Error: Unknown flag: $1" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Defaults: read env if flags not provided
: "${TASK_MODE:=${SPECKIT_TASK_MODE:-sync}}"
: "${TASK_ID:=${SPECKIT_TASK_ID:-}}"

# Validate TASK_MODE
case "$TASK_MODE" in
    sync|parallel|async) ;;
    *)
        echo "Error: --mode/SPECIFY_TASK_MODE must be 'sync', 'parallel', or 'async' (got: $TASK_MODE)" >&2
        exit 1
        ;;
esac

# Validate TASK_ID format (when provided)
if [ -n "$TASK_ID" ] && ! echo "$TASK_ID" | grep -Eq '^T[0-9]+$'; then
    echo "[specify] Warning: --task-id '$TASK_ID' is not a valid TNNN id; ignoring" >&2
    TASK_ID=""
fi

EVENT_NAME="${1:-}"
if [ -z "$EVENT_NAME" ]; then
    echo "Usage: $0 [--mode <sync|parallel|async>] [--task-id <TNNN>] <event_name>" >&2
    exit 1
fi

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_find_project_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.specify" ] || [ -d "$dir/.git" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

REPO_ROOT=$(_find_project_root "$SCRIPT_DIR") || REPO_ROOT="$(pwd)"
cd "$REPO_ROOT"

# Check if git is available
if ! command -v git >/dev/null 2>&1; then
    echo "[specify] Warning: Git not found; skipped auto-commit" >&2
    exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[specify] Warning: Not a Git repository; skipped auto-commit" >&2
    exit 0
fi

# Read per-command config from git-config.yml
_config_file="$REPO_ROOT/.specify/extensions/git/git-config.yml"
_enabled=false
_commit_msg=""

if [ -f "$_config_file" ]; then
    # Parse the auto_commit section for this event.
    # Look for auto_commit.<event_name>.enabled and .message
    # Also check auto_commit.default as fallback.
    _in_auto_commit=false
    _in_event=false
    _default_enabled=false

    while IFS= read -r _line; do
        # Detect auto_commit: section
        if echo "$_line" | grep -q '^auto_commit:'; then
            _in_auto_commit=true
            _in_event=false
            continue
        fi

        # Exit auto_commit section on next top-level key
        if $_in_auto_commit && echo "$_line" | grep -Eq '^[a-z]'; then
            break
        fi

        if $_in_auto_commit; then
            # Check default key
            if echo "$_line" | grep -Eq "^[[:space:]]+default:[[:space:]]"; then
                _val=$(echo "$_line" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
                [ "$_val" = "true" ] && _default_enabled=true
            fi

            # Detect our event subsection
            if echo "$_line" | grep -Eq "^[[:space:]]+${EVENT_NAME}:"; then
                _in_event=true
                continue
            fi

            # Inside our event subsection
            if $_in_event; then
                # Exit on next sibling key (same indent level as event name)
                if echo "$_line" | grep -Eq '^[[:space:]]{2}[a-z]' && ! echo "$_line" | grep -Eq '^[[:space:]]{4}'; then
                    _in_event=false
                    continue
                fi
                if echo "$_line" | grep -Eq '[[:space:]]+enabled:'; then
                    _val=$(echo "$_line" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
                    [ "$_val" = "true" ] && _enabled=true
                    [ "$_val" = "false" ] && _enabled=false
                fi
                if echo "$_line" | grep -Eq '[[:space:]]+message:'; then
                    _commit_msg=$(echo "$_line" | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^["'\'']//' | sed 's/["'\'']*$//')
                fi
            fi
        fi
    done < "$_config_file"

    # If event-specific key not found, use default
    if [ "$_enabled" = "false" ] && [ "$_default_enabled" = "true" ]; then
        # Only use default if the event wasn't explicitly set to false
        # Check if event section existed at all
        if ! grep -q "^[[:space:]]*${EVENT_NAME}:" "$_config_file" 2>/dev/null; then
            _enabled=true
        fi
    fi
else
    # No config file — auto-commit disabled by default
    exit 0
fi

if [ "$_enabled" != "true" ]; then
    exit 0
fi

# Check if there are changes to commit
if git diff --quiet HEAD 2>/dev/null && git diff --cached --quiet 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
    echo "[specify] No changes to commit after $EVENT_NAME" >&2
    exit 0
fi

# Derive a human-readable command name from the event
# e.g., after_specify -> specify, before_plan -> plan
_command_name=$(echo "$EVENT_NAME" | sed 's/^after_//' | sed 's/^before_//')
_phase=$(echo "$EVENT_NAME" | grep -q '^before_' && echo 'before' || echo 'after')

# Use custom message if configured, otherwise default
if [ -z "$_commit_msg" ]; then
    _commit_msg="[Spec Kit] Auto-commit ${_phase} ${_command_name}"
fi

# When SPECKIT_TASK_MODE is parallel or async, prefix the subject with the
# task id so concurrent agents' commits stay distinguishable.
if [ "$TASK_MODE" != "sync" ] && [ -n "$TASK_ID" ]; then
    if ! echo "$_commit_msg" | head -1 | grep -q "^\[${TASK_ID}\]"; then
        _commit_msg="[${TASK_ID}] ${_commit_msg}"
    fi
fi

# Stage and commit
_git_out=$(git add . 2>&1) || { echo "[specify] Error: git add failed: $_git_out" >&2; exit 1; }
_git_out=$(git commit -q -m "$_commit_msg" 2>&1) || { echo "[specify] Error: git commit failed: $_git_out" >&2; exit 1; }

echo "[OK] Changes committed ${_phase} ${_command_name}" >&2
