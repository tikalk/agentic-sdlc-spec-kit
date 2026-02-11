# spec-sync-post-commit.ps1 - Post-commit hook for spec-code synchronization
# This script runs after commits to process queued spec updates

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

# Get the project root
$script_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$project_root = Split-Path -Parent (Split-Path -Parent $script_dir)

# Check if spec sync is enabled (global config)
if ($env:XDG_CONFIG_HOME) {
    $config_file = Join-Path $env:XDG_CONFIG_HOME "specify" "config.json"
} elseif ($IsWindows -or $env:OS -eq 'Windows_NT') {
    $config_file = Join-Path $env:APPDATA "specify" "config.json"
} else {
    $config_file = Join-Path $HOME ".config" "specify" "config.json"
}
if (Test-Path $config_file) {
    try {
        $config = Get-Content $config_file -Raw | ConvertFrom-Json
        if (-not $config.spec_sync.enabled) {
            exit 0
        }
    } catch {
        # If config can't be read, assume disabled
        exit 0
    }
} else {
    # No config file, assume disabled
    exit 0
}

log_info "Processing spec sync queue after commit..."

# Check if there's a queue file
$queue_file = Join-Path $project_root ".specify/config/spec-sync-queue.json"
if (-not (Test-Path $queue_file)) {
    log_info "No spec sync queue found"
    exit 0
}

# For now, just log that post-commit processing would happen here
# In a full implementation, this would process queued spec updates
log_info "Spec sync post-commit processing completed (stub implementation)"

log_success "Post-commit spec sync processing completed"