#!/usr/bin/env bash

# Setup script for Team AI Directives extension
# Resolves team-ai-directives path and outputs environment info

set -e

JSON_MODE=false

# Get script directory for common.sh sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find project root by walking up from script location
_find_project_root() {
    local dir="$SCRIPT_DIR"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.specify" ] || [ -d "$dir/.git" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

PROJECT_ROOT="$(_find_project_root)" || PROJECT_ROOT="$SCRIPT_DIR"

# Load common functions - use absolute path from project root
if [[ -n "$PROJECT_ROOT" && -f "$PROJECT_ROOT/.specify/scripts/bash/common.sh" ]]; then
    source "$PROJECT_ROOT/.specify/scripts/bash/common.sh"
elif [[ -f "$SCRIPT_DIR/common.sh" ]]; then
    source "$SCRIPT_DIR/common.sh"
fi

# Get repository root
REPO_ROOT=$(get_repo_root 2>/dev/null || git rev-parse --show-toplevel 2>/dev/null || pwd)

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [--json]"
            echo "  --json    Output results in JSON format"
            echo "  --help    Show this help message"
            exit 0
            ;;
    esac
done

# Resolve team-ai-directives path using centralized function from common.sh
load_team_directives_config "$REPO_ROOT"
TEAM_DIRECTIVES="${SPECIFY_TEAM_DIRECTIVES:-}"

# Get current git branch
CURRENT_BRANCH=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi

# Output results
if $JSON_MODE; then
    printf '{"REPO_ROOT":"%s","TEAM_DIRECTIVES":"%s","BRANCH":"%s"}\n' \
        "$REPO_ROOT" "$TEAM_DIRECTIVES" "$CURRENT_BRANCH"
else
    echo "REPO_ROOT: $REPO_ROOT"
    if [[ -n "$TEAM_DIRECTIVES" ]]; then
        echo "TEAM_DIRECTIVES: $TEAM_DIRECTIVES"
    else
        echo "TEAM_DIRECTIVES: (not configured)"
    fi
    echo "BRANCH: $CURRENT_BRANCH"
fi
