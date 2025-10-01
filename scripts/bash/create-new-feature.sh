#!/usr/bin/env bash

set -e

JSON_MODE=false
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h) echo "Usage: $0 [--json] <feature_description>"; exit 0 ;;
        *) ARGS+=("$arg") ;;
    esac
done

FEATURE_DESCRIPTION="${ARGS[*]}"
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Usage: $0 [--json] <feature_description>" >&2
    exit 1
fi

TEAM_DIRECTIVES_DIRNAME="team-ai-directives"

# Function to find the repository root by searching for existing project markers
find_repo_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -d "$dir/.specify" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Resolve repository root. Prefer git information when available, but fall back
# to searching for repository markers so the workflow still functions in repositories that
# were initialised with --no-git.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    HAS_GIT=true
else
    REPO_ROOT="$(find_repo_root "$SCRIPT_DIR")"
    if [ -z "$REPO_ROOT" ]; then
        echo "Error: Could not determine repository root. Please run this script from within the repository." >&2
        exit 1
    fi
    HAS_GIT=false
fi

cd "$REPO_ROOT"

SPECS_DIR="$REPO_ROOT/specs"
mkdir -p "$SPECS_DIR"

CONSTITUTION_FILE="$REPO_ROOT/.specify/memory/constitution.md"
if [ -f "$CONSTITUTION_FILE" ]; then
    export SPECIFY_CONSTITUTION="$CONSTITUTION_FILE"
else
    CONSTITUTION_FILE=""
fi

TEAM_DIRECTIVES_DIR="$REPO_ROOT/.specify/memory/$TEAM_DIRECTIVES_DIRNAME"
if [ -d "$TEAM_DIRECTIVES_DIR" ]; then
    export SPECIFY_TEAM_DIRECTIVES="$TEAM_DIRECTIVES_DIR"
else
    TEAM_DIRECTIVES_DIR=""
fi

HIGHEST=0
if [ -d "$SPECS_DIR" ]; then
    for dir in "$SPECS_DIR"/*; do
        [ -d "$dir" ] || continue
        dirname=$(basename "$dir")
        number=$(echo "$dirname" | grep -o '^[0-9]\+' || echo "0")
        number=$((10#$number))
        if [ "$number" -gt "$HIGHEST" ]; then HIGHEST=$number; fi
    done
fi

NEXT=$((HIGHEST + 1))
FEATURE_NUM=$(printf "%03d" "$NEXT")

BRANCH_NAME=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//')
WORDS=$(echo "$BRANCH_NAME" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//')
BRANCH_NAME="${FEATURE_NUM}-${WORDS}"

if [ "$HAS_GIT" = true ]; then
    git checkout -b "$BRANCH_NAME"
else
    >&2 echo "[specify] Warning: Git repository not detected; skipped branch creation for $BRANCH_NAME"
fi

FEATURE_DIR="$SPECS_DIR/$BRANCH_NAME"
mkdir -p "$FEATURE_DIR"

TEMPLATE="$REPO_ROOT/.specify/templates/spec-template.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
if [ -f "$TEMPLATE" ]; then cp "$TEMPLATE" "$SPEC_FILE"; else touch "$SPEC_FILE"; fi

CONTEXT_TEMPLATE="$REPO_ROOT/.specify/templates/context-template.md"
CONTEXT_FILE="$FEATURE_DIR/context.md"
if [ -f "$CONTEXT_TEMPLATE" ]; then
    if command -v sed >/dev/null 2>&1; then
        sed "s/\[FEATURE NAME\]/$BRANCH_NAME/" "$CONTEXT_TEMPLATE" > "$CONTEXT_FILE"
    else
        cp "$CONTEXT_TEMPLATE" "$CONTEXT_FILE"
    fi
else
    cat <<'EOF' > "$CONTEXT_FILE"
# Feature Context

## Mission Brief
- **Issue Tracker**: [NEEDS INPUT]
- **Summary**: [NEEDS INPUT]

## Local Context
- Relevant code paths:
  - [NEEDS INPUT]
- Existing dependencies or services touched:
  - [NEEDS INPUT]

## Team Directives
- Referenced modules:
  - [NEEDS INPUT]
- Additional guardrails:
  - [NEEDS INPUT]

## External Research & References
- Links or documents:
  - [NEEDS INPUT]

## Gateway Check
- Last verified gateway endpoint: [NEEDS INPUT]
- Verification timestamp (UTC): [NEEDS INPUT]

## Open Questions
- [NEEDS INPUT]
EOF
fi

# Set the SPECIFY_FEATURE environment variable for the current session
export SPECIFY_FEATURE="$BRANCH_NAME"

if $JSON_MODE; then
    printf '{"BRANCH_NAME":"%s","SPEC_FILE":"%s","FEATURE_NUM":"%s","HAS_GIT":"%s","CONSTITUTION":"%s","TEAM_DIRECTIVES":"%s"}\n' \
        "$BRANCH_NAME" "$SPEC_FILE" "$FEATURE_NUM" "$HAS_GIT" "$CONSTITUTION_FILE" "$TEAM_DIRECTIVES_DIR"
else
    echo "BRANCH_NAME: $BRANCH_NAME"
    echo "SPEC_FILE: $SPEC_FILE"
    echo "FEATURE_NUM: $FEATURE_NUM"
    echo "HAS_GIT: $HAS_GIT"
    if [ -n "$CONSTITUTION_FILE" ]; then
        echo "CONSTITUTION: $CONSTITUTION_FILE"
    else
        echo "CONSTITUTION: (missing)"
    fi
    if [ -n "$TEAM_DIRECTIVES_DIR" ]; then
        echo "TEAM_DIRECTIVES: $TEAM_DIRECTIVES_DIR"
    else
        echo "TEAM_DIRECTIVES: (missing)"
    fi
    echo "SPECIFY_FEATURE environment variable set to: $BRANCH_NAME"
fi
