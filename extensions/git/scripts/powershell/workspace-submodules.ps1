#!/usr/bin/env pwsh

param(
    [switch]$Json,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Source common functions
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$commonPath = Join-Path $scriptDir "git-common.ps1"
if (Test-Path $commonPath) {
    . $commonPath
}

$repoRoot = Get-RepoRoot
Set-Location $repoRoot

# Check if this is a git repo
if (-not (Has-Git)) {
    if ($Json) {
        '{"error": "Not a git repository. Workspace must be initialized with git."}'
    } else {
        Write-Error "Not a git repository. Workspace must be initialized with git."
    }
    exit 1
}

# Arrays to track results
$registeredRepos = @()
$skippedRepos = @()
$errorRepos = @()

# Function to check if a path is already a submodule
function Is-Submodule($path) {
    try {
        $submodules = git config --file .gitmodules --get-regexp "^submodule\..*\.path$" 2>$null
        return $submodules -match "^[^ ]* $path$"
    } catch {
        return $false
    }
}

# Function to get remote URL from a child repo
function Get-RemoteUrl($repoPath) {
    try {
        return git -C $repoPath remote get-url origin 2>$null
    } catch {
        return ""
    }
}

# Discover child repos at depth 1
function Discover-ChildRepos {
    $discovered = @()
    
    Get-ChildItem -Path $repoRoot -Directory | ForEach-Object {
        $basename = $_.Name
        
        # Skip common non-project directories
        $skipDirs = @('.specify', '.git', 'node_modules', '__pycache__', '.venv', 'venv', 'dist', 'build', 'target', '.idea', '.vscode')
        if ($skipDirs -contains $basename) {
            return
        }
        
        # Check if it has a .git directory or file
        $gitPath = Join-Path $_.FullName ".git"
        if ((Test-Path $gitPath -PathType Container) -or (Test-Path $gitPath -PathType Leaf)) {
            $discovered += $basename
        }
    }
    
    return $discovered
}

# Main processing
$childRepos = Discover-ChildRepos

foreach ($repoName in $childRepos) {
    $repoPath = Join-Path $repoRoot $repoName
    
    # Check if already a submodule
    if (Is-Submodule $repoName) {
        $skippedRepos += "$repoName`: already a submodule"
        continue
    }
    
    # Get remote URL
    $remoteUrl = Get-RemoteUrl $repoPath
    
    if (-not $remoteUrl) {
        $errorRepos += "$repoName`: no remote URL configured"
        continue
    }
    
    # Register as submodule
    if ($DryRun) {
        $registeredRepos += "$repoName → $remoteUrl [DRY RUN]"
    } else {
        try {
            git submodule add $remoteUrl $repoName 2>$null | Out-Null
            $registeredRepos += "$repoName → $remoteUrl"
        } catch {
            $errorRepos += "$repoName`: failed to add submodule"
        }
    }
}

# Commit changes if not dry run and we registered repos
if ((-not $DryRun) -and ($registeredRepos.Count -gt 0)) {
    $gitmodulesPath = Join-Path $repoRoot ".gitmodules"
    if (Test-Path $gitmodulesPath) {
        git add .gitmodules 2>$null | Out-Null
        # Try to commit, but don't fail if nothing to commit
        git commit -m "[Spec Kit] Register workspace submodules" 2>$null | Out-Null
    }
}

# Output results
if ($Json) {
    $registeredJson = $registeredRepos | ForEach-Object { '"' + $_ + '"' }
    $skippedJson = $skippedRepos | ForEach-Object { '"' + $_ + '"' }
    $errorsJson = $errorRepos | ForEach-Object { '"' + $_ + '"' }
    
    @"
{
  "DISCOVERED_COUNT": $($childRepos.Count),
  "REGISTERED_COUNT": $($registeredRepos.Count),
  "SKIPPED_COUNT": $($skippedRepos.Count),
  "ERROR_COUNT": $($errorRepos.Count),
  "REGISTERED_REPOS": [$($registeredJson -join ',')],
  "SKIPPED_REPOS": [$($skippedJson -join ',')],
  "ERROR_REPOS": [$($errorsJson -join ',')],
  "DRY_RUN": $(if ($DryRun) { "true" } else { "false" })
}
"@
} else {
    # Text output
    Write-Host "=========================================="
    Write-Host "Workspace Submodule Setup"
    Write-Host "=========================================="
    Write-Host ""
    
    if ($registeredRepos.Count -gt 0) {
        Write-Host "Registered ($($registeredRepos.Count)):"
        foreach ($repo in $registeredRepos) {
            Write-Host "  ✓ $repo"
        }
        Write-Host ""
    }
    
    if ($skippedRepos.Count -gt 0) {
        Write-Host "Skipped ($($skippedRepos.Count)):"
        foreach ($repo in $skippedRepos) {
            Write-Host "  - $repo"
        }
        Write-Host ""
    }
    
    if ($errorRepos.Count -gt 0) {
        Write-Host "Errors ($($errorRepos.Count)):"
        foreach ($repo in $errorRepos) {
            Write-Host "  ⚠ $repo"
        }
        Write-Host ""
    }
    
    if (($registeredRepos.Count -eq 0) -and ($skippedRepos.Count -eq 0) -and ($errorRepos.Count -eq 0)) {
        Write-Host "No child repositories found at depth 1."
        Write-Host ""
    }
    
    if ((-not $DryRun) -and ($registeredRepos.Count -gt 0)) {
        Write-Host "Next steps:"
        Write-Host "  - Team members can clone with: git clone --recursive <workspace-url>"
        Write-Host "  - Or initialize submodules: git submodule update --init"
    }
}
