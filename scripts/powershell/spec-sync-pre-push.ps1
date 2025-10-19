# spec-sync-pre-push.ps1 - Pre-push hook for spec-code synchronization
# This script runs before pushes to ensure spec updates are processed

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

# Check if spec sync is enabled
$enabled_file = Join-Path $project_root ".specify/config/spec-sync-enabled"
if (-not (Test-Path $enabled_file)) {
    exit 0
}

log_info "Checking spec sync status before push..."

# Check if there are any pending spec updates in the queue
$config_file = Join-Path $project_root ".specify/config/config.json"
if (Test-Path $config_file) {
    try {
        $config = Get-Content $config_file -Raw | ConvertFrom-Json
        $pending_count = $config.spec_sync.queue.pending.Count
        if ($pending_count -gt 0) {
            log_warning "Pending spec updates detected in queue ($pending_count items)"
            log_warning "Consider processing spec updates before pushing"
            log_warning "Use 'git push --no-verify' to skip this check if intentional"
            # Don't fail the push, just warn
        }
    } catch {
        # Ignore config parsing errors
    }
}

log_success "Pre-push spec sync check completed"