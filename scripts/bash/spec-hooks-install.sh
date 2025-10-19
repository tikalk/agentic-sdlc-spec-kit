#!/bin/bash
# spec-hooks-install.sh - Install git hooks for automatic spec-code synchronization
# This script sets up pre-commit, post-commit, and pre-push hooks to detect code changes
# and queue documentation updates for specs/*.md files

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

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository. Spec sync requires git."
        exit 1
    fi
}

# Create hooks directory if it doesn't exist
ensure_hooks_dir() {
    local hooks_dir=".git/hooks"
    if [[ ! -d "$hooks_dir" ]]; then
        log_warning "Git hooks directory not found, creating it"
        mkdir -p "$hooks_dir"
    fi
}

# Install a specific hook
install_hook() {
    local hook_name="$1"
    local hook_script="$2"
    local hooks_dir=".git/hooks"
    local hook_path="$hooks_dir/$hook_name"

    # Check if hook already exists
    if [[ -f "$hook_path" ]]; then
        # Check if it's already our hook
        if grep -q "spec-sync" "$hook_path" 2>/dev/null; then
            log_info "$hook_name hook already installed"
            return 0
        else
            log_warning "$hook_name hook already exists, backing up and replacing"
            cp "$hook_path" "${hook_path}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
    fi

    # Create the hook script
    cat > "$hook_path" << EOF
#!/bin/bash
# $hook_name hook for spec-code synchronization
# Automatically detects code changes and queues spec updates

set -euo pipefail

# Source the spec sync utilities
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="\$(cd "\$SCRIPT_DIR/../.." && pwd)"

# Check if spec sync is enabled for this project
if [[ ! -f "\$PROJECT_ROOT/.specify/config/spec-sync-enabled" ]]; then
    exit 0
fi

# Run the $hook_script
if [[ -f "\$PROJECT_ROOT/scripts/bash/$hook_script" ]]; then
    bash "\$PROJECT_ROOT/scripts/bash/$hook_script"
fi
EOF

    # Make executable
    chmod +x "$hook_path"

    log_success "Installed $hook_name hook"
}

# Create spec sync configuration
function create_config {
    local config_dir=".specify/config"
    local config_file="$config_dir/config.json"
    mkdir -p "$config_dir"

    # Check if config file exists, create if not
    if [[ ! -f "$config_file" ]]; then
        cat > "$config_file" << EOF
{
  "version": "1.0",
  "project": {
    "created": "$(date -Iseconds)",
    "last_modified": "$(date -Iseconds)"
  },
  "workflow": {
    "current_mode": "spec",
    "default_mode": "spec",
    "mode_history": []
  },
  "options": {
    "tdd_enabled": false,
    "contracts_enabled": false,
    "data_models_enabled": false,
    "risk_tests_enabled": false
  },
  "mode_defaults": {
    "build": {
      "tdd_enabled": false,
      "contracts_enabled": false,
      "data_models_enabled": false,
      "risk_tests_enabled": false
    },
    "spec": {
      "tdd_enabled": true,
      "contracts_enabled": true,
      "data_models_enabled": true,
      "risk_tests_enabled": true
    }
  },
  "spec_sync": {
    "enabled": true,
    "queue": {
      "version": "1.0",
      "created": "$(date -Iseconds)",
      "pending": [],
      "processed": []
    }
  },
  "gateway": {
    "url": null,
    "token": null,
    "suppress_warning": false
  }
}
EOF
    else
        # Update existing config to enable spec sync
        # Use jq if available, otherwise use sed for simple update
        if command -v jq >/dev/null 2>&1; then
            jq '.spec_sync.enabled = true' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
        else
            # Fallback: simple sed replacement (assumes enabled is currently false)
            sed -i 's/"enabled": false/"enabled": true/' "$config_file"
        fi
    fi

    log_success "Created/updated spec sync configuration"
}

# Main installation function
main() {
    log_info "Installing spec-code synchronization hooks..."

    check_git_repo
    ensure_hooks_dir
    create_config

    # Install the hooks
    install_hook "pre-commit" "spec-sync-pre-commit.sh"
    install_hook "post-commit" "spec-sync-post-commit.sh"
    install_hook "pre-push" "spec-sync-pre-push.sh"

    log_success "Spec-code synchronization hooks installed successfully!"
    log_info "Hooks will automatically detect code changes and queue spec updates"
    log_info "Use 'git commit' or 'git push' to trigger synchronization"
}

# Run main function
main "$@"