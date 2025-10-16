#!/usr/bin/env bash

set -e

# Parse command line arguments
JSON_MODE=false
ARGS=()

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
        *) 
            ARGS+=("$arg") 
            ;;
    esac
done

# Get script directory and load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get all paths and variables from common functions
eval $(get_feature_paths)

# Check if we're on a proper feature branch (only for git repos)
check_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" || exit 1

# Resolve team directives path if provided
if [[ -n "$TEAM_DIRECTIVES" && ! -d "$TEAM_DIRECTIVES" ]]; then
    echo "ERROR: TEAM_DIRECTIVES path $TEAM_DIRECTIVES is not accessible." >&2
    exit 1
fi

# Ensure the feature directory exists
mkdir -p "$FEATURE_DIR"

# Copy plan template if it exists
TEMPLATE="$REPO_ROOT/.specify/templates/plan-template.md"
if [[ -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$IMPL_PLAN"
    echo "Copied plan template to $IMPL_PLAN"
else
    echo "Warning: Plan template not found at $TEMPLATE"
    # Create a basic plan file if template doesn't exist
    touch "$IMPL_PLAN"
fi

CONTEXT_FILE="$FEATURE_DIR/context.md"
if [[ ! -f "$CONTEXT_FILE" ]]; then
    echo "ERROR: context.md not found in $FEATURE_DIR" >&2
    echo "Fill out the feature context before running /plan." >&2
    exit 1
fi

if grep -q "\[NEEDS INPUT\]" "$CONTEXT_FILE"; then
    echo "ERROR: context.md contains unresolved [NEEDS INPUT] markers." >&2
    echo "Please update $CONTEXT_FILE with mission, code paths, directives, research, and gateway details before proceeding." >&2
    exit 1
fi

# Resolve constitution and team directives paths (prefer env overrides)
CONSTITUTION_FILE="${SPECIFY_CONSTITUTION:-}"
if [[ -z "$CONSTITUTION_FILE" ]]; then
    CONSTITUTION_FILE="$REPO_ROOT/.specify/memory/constitution.md"
fi
if [[ -f "$CONSTITUTION_FILE" ]]; then
    export SPECIFY_CONSTITUTION="$CONSTITUTION_FILE"
else
    CONSTITUTION_FILE=""
fi

TEAM_DIRECTIVES_DIR="${TEAM_DIRECTIVES:-}"
if [[ -z "$TEAM_DIRECTIVES_DIR" ]]; then
    TEAM_DIRECTIVES_DIR="${SPECIFY_TEAM_DIRECTIVES:-}"
fi
if [[ -z "$TEAM_DIRECTIVES_DIR" ]]; then
    TEAM_DIRECTIVES_DIR="$REPO_ROOT/.specify/memory/team-ai-directives"
fi
if [[ -d "$TEAM_DIRECTIVES_DIR" ]]; then
    export SPECIFY_TEAM_DIRECTIVES="$TEAM_DIRECTIVES_DIR"
else
    TEAM_DIRECTIVES_DIR=""
fi

# Output results
if $JSON_MODE; then
    printf '{"FEATURE_SPEC":"%s","IMPL_PLAN":"%s","SPECS_DIR":"%s","BRANCH":"%s","HAS_GIT":"%s","CONSTITUTION":"%s","TEAM_DIRECTIVES":"%s","CONTEXT_FILE":"%s"}\n' \
        "$FEATURE_SPEC" "$IMPL_PLAN" "$FEATURE_DIR" "$CURRENT_BRANCH" "$HAS_GIT" "$CONSTITUTION_FILE" "$TEAM_DIRECTIVES_DIR" "$CONTEXT_FILE"
else
    echo "FEATURE_SPEC: $FEATURE_SPEC"
    echo "IMPL_PLAN: $IMPL_PLAN" 
    echo "SPECS_DIR: $FEATURE_DIR"
    echo "BRANCH: $CURRENT_BRANCH"
    echo "HAS_GIT: $HAS_GIT"
    if [[ -n "$CONSTITUTION_FILE" ]]; then
        echo "CONSTITUTION: $CONSTITUTION_FILE"
    else
        echo "CONSTITUTION: (missing)"
    fi
    if [[ -n "$TEAM_DIRECTIVES_DIR" ]]; then
        echo "TEAM_DIRECTIVES: $TEAM_DIRECTIVES_DIR"
    else
        echo "TEAM_DIRECTIVES: (missing)"
    fi
    echo "CONTEXT_FILE: $CONTEXT_FILE"
fi

