#!/usr/bin/env pwsh
# Git extension: auto-commit.ps1
# Automatically commit changes after a Spec Kit command completes.
# Checks per-command config keys in git-config.yml before committing.
#
# Usage: auto-commit.ps1 [-Mode <sync|parallel|async>] [-TaskId <TNNN>] <event_name>
#   e.g.: auto-commit.ps1 after_specify
#         auto-commit.ps1 -Mode parallel -TaskId T001 after_implement
#
# Environment variables (used when parameters are not provided):
#   SPECKIT_TASK_MODE    sync (default) | parallel | async
#                        - parallel / async prefix commit messages with [TNNN]
#                          so concurrent agents' commits can be distinguished
#                        - sync preserves the original commit message format
#   SPECKIT_TASK_ID      Task id (TNNN) used to prefix the commit subject when
#                        SPECKIT_TASK_MODE is parallel or async
#
# Precedence:  -Mode / -TaskId parameters > SPECKIT_TASK_MODE / SPECKIT_TASK_ID env > default
param(
    [string]$Mode,
    [string]$TaskId,
    [switch]$Help,
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$EventName
)
$ErrorActionPreference = 'Stop'

if ($Help) {
    Write-Host "Usage: ./auto-commit.ps1 [-Mode <sync|parallel|async>] [-TaskId <TNNN>] <event_name>"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Mode <mode>       sync (default) | parallel | async"
    Write-Host "                     parallel/async prefix commit subject with [TNNN]"
    Write-Host "  -TaskId <TNNN>     Task id used to prefix commit subject when mode is parallel/async"
    Write-Host "  -Help              Show this help message"
    Write-Host ""
    Write-Host "Environment variables (used when parameters are not provided):"
    Write-Host "  SPECKIT_TASK_MODE    Same as -Mode"
    Write-Host "  SPECKIT_TASK_ID      Same as -TaskId"
    Write-Host ""
    Write-Host "Arguments:"
    Write-Host "  <event_name>       Event that triggered the auto-commit (e.g., after_specify)"
    Write-Host ""
    exit 0
}

# Defaults: parameter > env > default
if ([string]::IsNullOrEmpty($Mode)) { $Mode = if ([string]::IsNullOrEmpty($env:SPECKIT_TASK_MODE)) { 'sync' } else { $env:SPECKIT_TASK_MODE } }
if ([string]::IsNullOrEmpty($TaskId)) { $TaskId = if ($env:SPECKIT_TASK_ID) { $env:SPECKIT_TASK_ID } else { '' } }

# Validate Mode
if ($Mode -ne 'sync' -and $Mode -ne 'parallel' -and $Mode -ne 'async') {
    throw "Error: -Mode/SPECKIT_TASK_MODE must be 'sync', 'parallel', or 'async' (got: $Mode)"
}

# Validate TaskId format (when provided)
if (-not [string]::IsNullOrEmpty($TaskId) -and $TaskId -notmatch '^T[0-9]+$') {
    [Console]::Error.WriteLine("[specify] Warning: -TaskId '$TaskId' is not a valid TNNN id; ignoring")
    $TaskId = ''
}

function Find-ProjectRoot {
    param([string]$StartDir)
    $current = Resolve-Path $StartDir
    while ($true) {
        foreach ($marker in @('.specify', '.git')) {
            if (Test-Path (Join-Path $current $marker)) {
                return $current
            }
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) { return $null }
        $current = $parent
    }
}

$repoRoot = Find-ProjectRoot -StartDir $PSScriptRoot
if (-not $repoRoot) { $repoRoot = Get-Location }
Set-Location $repoRoot

# Check if git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Warning "[specify] Warning: Git not found; skipped auto-commit"
    exit 0
}

# Temporarily relax ErrorActionPreference so git stderr warnings
# (e.g. CRLF notices on Windows) do not become terminating errors.
$savedEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    $isRepo = $LASTEXITCODE -eq 0
} finally {
    $ErrorActionPreference = $savedEAP
}
if (-not $isRepo) {
    Write-Warning "[specify] Warning: Not a Git repository; skipped auto-commit"
    exit 0
}

# Read per-command config from git-config.yml
$configFile = Join-Path $repoRoot ".specify/extensions/git/git-config.yml"
$enabled = $false
$commitMsg = ""

if (Test-Path $configFile) {
    # Parse YAML to find auto_commit section
    $inAutoCommit = $false
    $inEvent = $false
    $defaultEnabled = $false

    foreach ($line in Get-Content $configFile) {
        # Detect auto_commit: section
        if ($line -match '^auto_commit:') {
            $inAutoCommit = $true
            $inEvent = $false
            continue
        }

        # Exit auto_commit section on next top-level key
        if ($inAutoCommit -and $line -match '^[a-z]') {
            break
        }

        if ($inAutoCommit) {
            # Check default key
            if ($line -match '^\s+default:\s*(.+)$') {
                $val = $matches[1].Trim().ToLower()
                if ($val -eq 'true') { $defaultEnabled = $true }
            }

            # Detect our event subsection
            if ($line -match "^\s+${EventName}:") {
                $inEvent = $true
                continue
            }

            # Inside our event subsection
            if ($inEvent) {
                # Exit on next sibling key (2-space indent, not 4+)
                if ($line -match '^\s{2}[a-z]' -and $line -notmatch '^\s{4}') {
                    $inEvent = $false
                    continue
                }
                if ($line -match '\s+enabled:\s*(.+)$') {
                    $val = $matches[1].Trim().ToLower()
                    if ($val -eq 'true') { $enabled = $true }
                    if ($val -eq 'false') { $enabled = $false }
                }
                if ($line -match '\s+message:\s*(.+)$') {
                    $commitMsg = $matches[1].Trim() -replace '^["'']' -replace '["'']$'
                }
            }
        }
    }

    # If event-specific key not found, use default
    if (-not $enabled -and $defaultEnabled) {
        $hasEventKey = Select-String -Path $configFile -Pattern "^\s*${EventName}:" -Quiet
        if (-not $hasEventKey) {
            $enabled = $true
        }
    }
} else {
    # No config file -- auto-commit disabled by default
    exit 0
}

if (-not $enabled) {
    exit 0
}

# Check if there are changes to commit
# Relax ErrorActionPreference so CRLF warnings on stderr do not terminate.
$savedEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    git diff --quiet HEAD 2>$null; $d1 = $LASTEXITCODE
    git diff --cached --quiet 2>$null; $d2 = $LASTEXITCODE
    $untracked = git ls-files --others --exclude-standard 2>$null
} finally {
    $ErrorActionPreference = $savedEAP
}

if ($d1 -eq 0 -and $d2 -eq 0 -and -not $untracked) {
    Write-Host "[specify] No changes to commit after $EventName" -ForegroundColor DarkGray
    exit 0
}

# Derive a human-readable command name from the event
$commandName = $EventName -replace '^after_', '' -replace '^before_', ''
$phase = if ($EventName -match '^before_') { 'before' } else { 'after' }

# Use custom message if configured, otherwise default
if (-not $commitMsg) {
    $commitMsg = "[Spec Kit] Auto-commit $phase $commandName"
}

# When SPECKIT_TASK_MODE is parallel or async, prefix the subject with the
# task id so concurrent agents' commits stay distinguishable.
if ($Mode -ne 'sync' -and -not [string]::IsNullOrEmpty($TaskId)) {
    if ($commitMsg -notmatch "^\[$([regex]::Escape($TaskId))\]") {
        $commitMsg = "[$TaskId] $commitMsg"
    }
}

# Stage and commit
# Relax ErrorActionPreference so CRLF warnings on stderr do not terminate,
# while still allowing redirected error output to be captured for diagnostics.
$savedEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $out = git add . 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "git add failed: $out" }
    $out = git commit -q -m $commitMsg 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "git commit failed: $out" }
} catch {
    Write-Warning "[specify] Error: $_"
    exit 1
} finally {
    $ErrorActionPreference = $savedEAP
}

Write-Host "[OK] Changes committed $phase $commandName"
