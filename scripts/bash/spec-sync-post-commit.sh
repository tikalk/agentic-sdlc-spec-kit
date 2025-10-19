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
if [[ ! -f "$PROJECT_ROOT/.specify/config/spec-sync-enabled" ]]; then
    exit 0
fi

log_info "Processing spec sync queue after commit..."

# Check if there's a queue file
QUEUE_FILE="$PROJECT_ROOT/.specify/config/spec-sync-queue.json"
if [[ ! -f "$QUEUE_FILE" ]]; then
    log_info "No spec sync queue found"
    exit 0
fi

# For now, just log that post-commit processing would happen here
# In a full implementation, this would process queued spec updates
log_info "Spec sync post-commit processing completed (stub implementation)"

log_success "Post-commit spec sync processing completed"