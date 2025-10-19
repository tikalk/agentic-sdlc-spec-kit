# spec-hooks-install.ps1 - Install git hooks for automatic spec-code synchronization
# This script sets up pre-commit, post-commit, and pre-push hooks to detect code changes
# and queue documentation updates for specs/*.md files

param()

# Colors for output
$RED = "`e[0;31m"
$GREEN = "`e[0;32m"
$YELLOW = "`e[1;33m"
$BLUE = "`e[0;34m"
$NC = "`e[0m" # No Color

# Logging functions
function log_info {
    param([string]$message)
    Write-Host "${BLUE}INFO:${NC} $message" -ForegroundColor Blue
}

function log_success {
    param([string]$message)
    Write-Host "${GREEN}SUCCESS:${NC} $message" -ForegroundColor Green
}

function log_warning {
    param([string]$message)
    Write-Host "${YELLOW}WARNING:${NC} $message" -ForegroundColor Yellow
}

function log_error {
    param([string]$message)
    Write-Host "${RED}ERROR:${NC} $message" -ForegroundColor Red
}

# Check if we're in a git repository
function check_git_repo {
    try {
        $null = git rev-parse --git-dir 2>$null
    } catch {
        log_error "Not in a git repository. Spec sync requires git."
        exit 1
    }
}

# Create hooks directory if it doesn't exist
function ensure_hooks_dir {
    $hooks_dir = ".git/hooks"
    if (-not (Test-Path $hooks_dir)) {
        log_warning "Git hooks directory not found, creating it"
        New-Item -ItemType Directory -Path $hooks_dir -Force | Out-Null
    }
}

# Install a specific hook
function install_hook {
    param(
        [string]$hook_name,
        [string]$hook_script
    )

    $hooks_dir = ".git/hooks"
    $hook_path = Join-Path $hooks_dir $hook_name

    # Check if hook already exists
    if (Test-Path $hook_path) {
        # Check if it's already our hook
        $content = Get-Content $hook_path -Raw -ErrorAction SilentlyContinue
        if ($content -and $content.Contains("spec-sync")) {
            log_info "$hook_name hook already installed"
            return
        } else {
            log_warning "$hook_name hook already exists, backing up and replacing"
            $backup_path = "${hook_path}.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item $hook_path $backup_path
        }
    }

    # Create the hook script
    $hook_content = @"
#!/bin/bash
# $hook_name hook for spec-code synchronization
# Automatically detects code changes and queues spec updates

set -euo pipefail

# Source the spec sync utilities
SCRIPT_DIR="`$(cd "`$(dirname "`${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="`$(cd "`$SCRIPT_DIR/../.." && pwd)"

# Check if spec sync is enabled for this project
if [[ ! -f "`$PROJECT_ROOT/.specify/config/spec-sync-enabled" ]]; then
    exit 0
fi

# Run the $hook_script
if [[ -f "`$PROJECT_ROOT/scripts/powershell/$hook_script" ]]; then
    powershell -ExecutionPolicy Bypass -File "`$PROJECT_ROOT/scripts/powershell/$hook_script"
fi
"@

    $hook_content | Out-File -FilePath $hook_path -Encoding UTF8 -Force

    # Make executable (using bash since we're creating bash hooks that call PowerShell)
    & bash -c "chmod +x '$hook_path'"

    log_success "Installed $hook_name hook"
}

# Create spec sync configuration
function create_config {
    $config_dir = ".specify/config"
    New-Item -ItemType Directory -Path $config_dir -Force | Out-Null

    # Mark spec sync as enabled
    $enabled_file = Join-Path $config_dir "spec-sync-enabled"
    New-Item -ItemType File -Path $enabled_file -Force | Out-Null

    # Create initial queue file
    $queue_file = Join-Path $config_dir "spec-sync-queue.json"
    if (-not (Test-Path $queue_file)) {
        $queue_content = @"
{
    "version": "1.0",
    "created": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')",
    "queue": [],
    "processed": []
}
"@
        $queue_content | Out-File -FilePath $queue_file -Encoding UTF8 -Force
    }

    log_success "Created spec sync configuration"
}

# Main installation function
function main {
    log_info "Installing spec-code synchronization hooks..."

    check_git_repo
    ensure_hooks_dir
    create_config

    # Install the hooks
    install_hook "pre-commit" "spec-sync-pre-commit.ps1"
    install_hook "post-commit" "spec-sync-post-commit.ps1"
    install_hook "pre-push" "spec-sync-pre-push.ps1"

    log_success "Spec-code synchronization hooks installed successfully!"
    log_info "Hooks will automatically detect code changes and queue spec updates"
    log_info "Use 'git commit' or 'git push' to trigger synchronization"
}

# Run main function
main