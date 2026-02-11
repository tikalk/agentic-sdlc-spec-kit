# spec-sync-pre-commit.ps1 - Pre-commit hook for spec-code synchronization
# This script runs before commits to detect code changes and queue spec updates

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

log_info "Checking for code changes that may require spec updates..."

# Get list of changed files
try {
    $changed_files = git diff --cached --name-only --diff-filter=ACMRTUXB
} catch {
    log_warning "Could not get changed files from git"
    exit 0
}

if (-not $changed_files) {
    log_info "No files changed, skipping spec sync check"
    exit 0
}

# Check if any spec files or code files changed
$spec_changed = $false
$code_changed = $false

foreach ($file in $changed_files) {
    if ($file -like "specs/*.md") {
        $spec_changed = $true
    } elseif ($file -match "\.(py|js|ts|java|c|cpp|h|go|rs|php|cs|vb)$") {
        $code_changed = $true
    }
}

# If code changed but no spec updates, warn the user
if ($code_changed -and -not $spec_changed) {
    log_warning "Code changes detected but no spec files updated"
    log_warning "Consider updating relevant specs/*.md files to reflect code changes"
    log_warning "Use 'git commit --no-verify' to skip this check if intentional"
    # Don't fail the commit, just warn
}

log_success "Pre-commit spec sync check completed"