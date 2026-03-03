#!/usr/bin/env bash

# Setup script for LevelUp extension
# Initializes CDR file and resolves team-ai-directives path

set -e

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

# Get repository root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Resolve team-ai-directives path
# Priority:
# 1. SPECIFY_TEAM_DIRECTIVES environment variable
# 2. .specify/team-ai-directives (submodule - recommended)
# 3. .specify/memory/team-ai-directives (clone - legacy)

TEAM_DIRECTIVES="${SPECIFY_TEAM_DIRECTIVES:-}"

if [[ -z "$TEAM_DIRECTIVES" ]]; then
    if [[ -d "$REPO_ROOT/.specify/team-ai-directives" ]]; then
        TEAM_DIRECTIVES="$REPO_ROOT/.specify/team-ai-directives"
    elif [[ -d "$REPO_ROOT/.specify/memory/team-ai-directives" ]]; then
        TEAM_DIRECTIVES="$REPO_ROOT/.specify/memory/team-ai-directives"
    fi
fi

# CDR file location
CDR_FILE="$REPO_ROOT/.specify/memory/cdr.md"
CDR_DIR="$(dirname "$CDR_FILE")"

# Skills drafts location
SKILLS_DRAFTS="$REPO_ROOT/.specify/drafts/skills"

# Ensure directories exist
mkdir -p "$CDR_DIR"
mkdir -p "$SKILLS_DRAFTS"

# Initialize CDR file if it doesn't exist
if [[ ! -f "$CDR_FILE" ]]; then
    cat > "$CDR_FILE" << 'EOF'
# Context Decision Records

Context Decision Records (CDRs) track decisions about contributing context modules (rules, personas, examples, skills) to team-ai-directives.

## CDR Index

| ID | Target Module | Context Type | Status | Date | Source |
|----|---------------|--------------|--------|------|--------|

---

<!-- CDRs will be appended below -->
EOF
fi

# Get current git branch
CURRENT_BRANCH=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi

# Check if team directives exists
TEAM_DIRECTIVES_EXISTS="false"
if [[ -n "$TEAM_DIRECTIVES" && -d "$TEAM_DIRECTIVES" ]]; then
    TEAM_DIRECTIVES_EXISTS="true"
fi

# Output results
if $JSON_MODE; then
    printf '{"REPO_ROOT":"%s","CDR_FILE":"%s","TEAM_DIRECTIVES":"%s","TEAM_DIRECTIVES_EXISTS":%s,"SKILLS_DRAFTS":"%s","BRANCH":"%s"}\n' \
        "$REPO_ROOT" "$CDR_FILE" "$TEAM_DIRECTIVES" "$TEAM_DIRECTIVES_EXISTS" "$SKILLS_DRAFTS" "$CURRENT_BRANCH"
else
    echo "REPO_ROOT: $REPO_ROOT"
    echo "CDR_FILE: $CDR_FILE"
    if [[ -n "$TEAM_DIRECTIVES" ]]; then
        echo "TEAM_DIRECTIVES: $TEAM_DIRECTIVES"
        echo "TEAM_DIRECTIVES_EXISTS: $TEAM_DIRECTIVES_EXISTS"
    else
        echo "TEAM_DIRECTIVES: (not configured)"
        echo "TEAM_DIRECTIVES_EXISTS: false"
    fi
    echo "SKILLS_DRAFTS: $SKILLS_DRAFTS"
    echo "BRANCH: $CURRENT_BRANCH"
fi
