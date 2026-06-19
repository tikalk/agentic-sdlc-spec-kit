#!/usr/bin/env pwsh
# Git extension: worktree-cleanup.ps1
# Removes a feature worktree directory. Idempotent.
#
# Usage: worktree-cleanup.ps1 -Feature <name> [-DeleteBranch] [-Force]

[CmdletBinding()]
param(
    [string]$Feature = "",
    [switch]$DeleteBranch,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Source git-common.ps1
$commonLoaded = $false
$localCommon = Join-Path $ScriptDir "git-common.ps1"
if (Test-Path $localCommon) {
    . $localCommon
    $commonLoaded = $true
} else {
    $current = $ScriptDir
    while ($true) {
        $candidates = @(
            (Join-Path $current ".specify/scripts/powershell/common.ps1"),
            (Join-Path $current "scripts/powershell/common.ps1")
        )
        foreach ($candidate in $candidates) {
            if (Test-Path $candidate) {
                . $candidate
                $commonLoaded = $true
                break
            }
        }
        if ($commonLoaded) { break }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }
}
if (-not $commonLoaded) {
    [Console]::Error.WriteLine("Error: Could not locate git-common.ps1 or common.ps1")
    exit 1
}

if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
    $RepoRoot = Get-RepoRoot
} else {
    try {
        $RepoRoot = git rev-parse --show-toplevel 2>$null
        if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
    } catch {
        $RepoRoot = (Get-Location).Path
    }
}
Set-Location $RepoRoot

if ([string]::IsNullOrEmpty($Feature)) {
    [Console]::Error.WriteLine("Error: -Feature is required")
    exit 1
}

# Resolve worktree base dir from config
$WorktreeBaseDir = ".worktrees"
$cfgPath = Join-Path $RepoRoot ".specify/extensions/git/git-config.yml"
if (Test-Path $cfgPath) {
    foreach ($line in Get-Content $cfgPath) {
        if ($line -match '^\s*base_dir:\s*(.+?)\s*$') {
            $WorktreeBaseDir = $Matches[1] -replace '^["'']', '' -replace '["'']$', ''
            break
        }
    }
}

$WorktreePath = Join-Path (Join-Path $RepoRoot $WorktreeBaseDir) $Feature
$ManifestFile = Join-Path $WorktreePath "git.worktree-manifest.json"

# Idempotent: if worktree does not exist, report success
if (-not (Test-Path $WorktreePath)) {
    $relPath = $WorktreePath.Substring($RepoRoot.Length) -replace '^[\\/]', ''
    $ordered = [ordered]@{
        removed = $true
        feature = $Feature
        worktree_path = $relPath
        already_removed = $true
        ok = $true
    }
    ($ordered | ConvertTo-Json -Compress)
    exit 0
}

# Safety: check for uncommitted changes (excluding manifest)
if (-not $Force) {
    $manifestName = "git.worktree-manifest.json"
    $statusLines = (& git -C $WorktreePath status --porcelain 2>$null) | Where-Object { $_ -and ($_ -notmatch "^\?\? $([regex]::Escape($manifestName))$") -and ($_ -notmatch "^.. $manifestName$") }
    if ($statusLines) {
        $msg = "Error: Worktree has uncommitted changes (excluding the manifest):`n$($statusLines -join "`n")`nUse -Force to override."
        [Console]::Error.WriteLine($msg)
        exit 1
    }
}

# Remove the worktree
git -C $RepoRoot worktree remove --force $WorktreePath 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Remove-Item -Path $WorktreePath -Recurse -Force -ErrorAction SilentlyContinue
}

# Optionally delete the feature branch
$branchDeleted = $false
if ($DeleteBranch) {
    $branchCheck = git -C $RepoRoot show-ref --verify --quiet "refs/heads/$Feature" 2>$null
    if ($LASTEXITCODE -eq 0) {
        git -C $RepoRoot branch -D $Feature 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $branchDeleted = $true }
    }
}

$relPath = $WorktreePath.Substring($RepoRoot.Length) -replace '^[\\/]', ''
$ordered = [ordered]@{
    removed = $true
    feature = $Feature
    worktree_path = $relPath
    branch_deleted = $branchDeleted
    ok = $true
}
($ordered | ConvertTo-Json -Compress)
