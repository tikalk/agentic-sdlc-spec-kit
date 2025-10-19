#!/bin/bash
# spec-sync-pre-push.sh - Pre-push hook for spec-code synchronization
# This script runs before pushes to ensure spec updates are processed

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
if [[ ! -f "$PROJECT_ROOT/.specify/config/spec-sync-enabled" ]]; then
    exit 0
fi

log_info "Checking spec sync status before push..."

# Check if there are any pending spec updates in the queue
QUEUE_FILE="$PROJECT_ROOT/.specify/config/spec-sync-queue.json"
if [[ -f "$QUEUE_FILE" ]]; then
    # Check if queue has pending items (simplified check)
    if grep -q '"queue": \[[^]]' "$QUEUE_FILE" 2>/dev/null; then
        log_warning "Pending spec updates detected in queue"
        log_warning "Consider processing spec updates before pushing"
        log_warning "Use 'git push --no-verify' to skip this check if intentional"
        # Don't fail the push, just warn
    fi
fi

log_success "Pre-push spec sync check completed"