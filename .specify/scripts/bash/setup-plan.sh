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
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get all paths and variables from common functions
_paths_output=$(get_feature_paths) || { echo "ERROR: Failed to resolve feature paths" >&2; exit 1; }
eval "$_paths_output"
unset _paths_output

# Check if we're on a proper feature branch (only for git repos)
check_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" || exit 1

# Resolve team directives path if provided
if [[ -n "$TEAM_DIRECTIVES" && ! -d "$TEAM_DIRECTIVES" ]]; then
    echo "ERROR: TEAM_DIRECTIVES path $TEAM_DIRECTIVES is not accessible." >&2
    exit 1
fi

# Ensure the feature directory exists
mkdir -p "$FEATURE_DIR"

# Select plan template
TEMPLATE=$(resolve_template "plan-template" "$REPO_ROOT")

if [[ -n "$TEMPLATE" && -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$IMPL_PLAN"
    echo "Copied plan template to $IMPL_PLAN"
else
    echo "Warning: Plan template not found at $TEMPLATE"
    # Create a basic plan file if template doesn't exist
    touch "$IMPL_PLAN"
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

# Resolve team directives path using centralized function
load_team_directives_config "$REPO_ROOT"
TEAM_DIRECTIVES_DIR="${SPECIFY_TEAM_DIRECTIVES:-}"
if [[ -d "$TEAM_DIRECTIVES_DIR" ]]; then
    TEAM_AGENTS_MD="$TEAM_DIRECTIVES_DIR/AGENTS.md"
    [[ ! -f "$TEAM_AGENTS_MD" ]] && TEAM_AGENTS_MD=""
else
    TEAM_DIRECTIVES_DIR=""
    TEAM_AGENTS_MD=""
fi

# Output results
if $JSON_MODE; then
    if has_jq; then
        jq -cn \
            --arg feature_spec "$FEATURE_SPEC" \
            --arg impl_plan "$IMPL_PLAN" \
            --arg specs_dir "$FEATURE_DIR" \
            --arg branch "$CURRENT_BRANCH" \
            --arg has_git "$HAS_GIT" \
            --arg constitution "$CONSTITUTION_FILE" \
            --arg team_directives "$TEAM_DIRECTIVES_DIR" \
            --arg team_agents_md "$TEAM_AGENTS_MD" \
            '{FEATURE_SPEC:$feature_spec,IMPL_PLAN:$impl_plan,SPECS_DIR:$specs_dir,BRANCH:$branch,HAS_GIT:$has_git,CONSTITUTION:$constitution,TEAM_DIRECTIVES:$team_directives,TEAM_AGENTS_MD:$team_agents_md}'
    else
        printf '{"FEATURE_SPEC":"%s","IMPL_PLAN":"%s","SPECS_DIR":"%s","BRANCH":"%s","HAS_GIT":"%s","CONSTITUTION":"%s","TEAM_DIRECTIVES":"%s","TEAM_AGENTS_MD":"%s"}\n' \
            "$(json_escape "$FEATURE_SPEC")" "$(json_escape "$IMPL_PLAN")" "$(json_escape "$FEATURE_DIR")" "$(json_escape "$CURRENT_BRANCH")" "$(json_escape "$HAS_GIT")" "$(json_escape "$CONSTITUTION_FILE")" "$(json_escape "$TEAM_DIRECTIVES_DIR")" "$(json_escape "$TEAM_AGENTS_MD")"
    fi
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
        if [[ -n "$TEAM_AGENTS_MD" ]]; then
            echo "TEAM_AGENTS_MD: $TEAM_AGENTS_MD"
        else
            echo "TEAM_AGENTS_MD: (missing)"
        fi
    else
        echo "TEAM_DIRECTIVES: (missing)"
        echo "TEAM_AGENTS_MD: (missing)"
    fi
fi



