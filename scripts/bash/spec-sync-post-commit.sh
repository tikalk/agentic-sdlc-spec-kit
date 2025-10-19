#!/bin/bash
# spec-sync-post-commit.sh - Post-commit hook for spec-code synchronization
# This script runs after commits to process queued spec updates

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

# Check if spec sync is enabled
CONFIG_FILE="$PROJECT_ROOT/.specify/config/config.json"
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

log_info "Processing spec sync queue after commit..."

# Check if spec sync is enabled and there's a config file
if [[ ! -f "$CONFIG_FILE" ]] || ! command -v jq >/dev/null 2>&1; then
    log_info "No spec sync config found"
    exit 0
fi

# Check if spec sync is enabled
SPEC_SYNC_ENABLED=$(jq -r '.spec_sync.enabled // false' "$CONFIG_FILE" 2>/dev/null)
if [[ "$SPEC_SYNC_ENABLED" != "true" ]]; then
    exit 0
fi

# For now, just log that post-commit processing would happen here
# In a full implementation, this would process queued spec updates
log_info "Spec sync post-commit processing completed (stub implementation)"

log_success "Post-commit spec sync processing completed"