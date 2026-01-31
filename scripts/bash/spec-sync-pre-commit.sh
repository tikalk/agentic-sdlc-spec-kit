#!/bin/bash
# spec-sync-pre-commit.sh - Pre-commit hook for spec-code synchronization
# This script runs before commits to detect code changes and queue spec updates

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}INFO:${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}SUCCESS:${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}WARNING:${NC} $*" >&2
}

log_error() {
    echo -e "${RED}ERROR:${NC} $*" >&2
}

# Get the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Get config path with hierarchical resolution
get_config_path() {
    local project_config="$PROJECT_ROOT/.specify/config.json"
    local user_config="${XDG_CONFIG_HOME:-$HOME/.config}/specify/config.json"
    
    if [[ -f "$project_config" ]]; then
        echo "$project_config"
    elif [[ -f "$user_config" ]]; then
        echo "$user_config"
    else
        echo "$project_config"
    fi
}

# Check if spec sync is enabled
CONFIG_FILE=$(get_config_path)
if [[ ! -f "$CONFIG_FILE" ]]; then
    exit 0
fi

# Parse config to check if spec sync is enabled
if command -v jq >/dev/null 2>&1; then
    SPEC_SYNC_ENABLED=$(jq -r '.spec_sync.enabled // false' "$CONFIG_FILE" 2>/dev/null)
    if [[ "$SPEC_SYNC_ENABLED" != "true" ]]; then
        exit 0
    fi
else
    # Fallback: check if enabled is set to true in the file
    if ! grep -q '"enabled": true' "$CONFIG_FILE" 2>/dev/null; then
        exit 0
    fi
fi

log_info "Checking for code changes that may require spec updates..."

# Get list of changed files
CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB)

if [[ -z "$CHANGED_FILES" ]]; then
    log_info "No files changed, skipping spec sync check"
    exit 0
fi

# Check if any spec files or code files changed
SPEC_CHANGED=false
CODE_CHANGED=false

while IFS= read -r file; do
    if [[ "$file" =~ ^specs/.*\.md$ ]]; then
        SPEC_CHANGED=true
    elif [[ "$file" =~ \.(py|js|ts|java|c|cpp|h|go|rs|php)$ ]]; then
        CODE_CHANGED=true
    fi
done <<< "$CHANGED_FILES"

# If code changed but no spec updates, warn the user
if [[ "$CODE_CHANGED" == "true" && "$SPEC_CHANGED" == "false" ]]; then
    log_warning "Code changes detected but no spec files updated"
    log_warning "Consider updating relevant specs/*.md files to reflect code changes"
    log_warning "Use 'git commit --no-verify' to skip this check if intentional"
    # Don't fail the commit, just warn
fi

log_success "Pre-commit spec sync check completed"