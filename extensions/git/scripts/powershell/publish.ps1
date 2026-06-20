#!/usr/bin/env pwsh
# Git extension: publish.ps1
# Push the current branch and create a PR (GitHub) or MR (GitLab).
#
# Usage: publish.ps1 [--draft] --title "..." [--body "..."] [--target-branch "..."]
#   e.g.: publish.ps1 --title "Add login feature" --body "Closes #123"
#   e.g.: publish.ps1 --draft --title "WIP: Refactor auth"

param(
    [switch]$Draft,
    [string]$Title = "",
    [string]$Body = "",
    [string]$TargetBranch = "main"
)

$ErrorActionPreference = 'Stop'

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

# Check git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "[specify] Error: Git not found"
    exit 1
}

# Detect branch
$branch = git rev-parse --abbrev-ref HEAD
if ($branch -eq "HEAD") {
    Write-Error "[specify] Error: Not on a valid branch (detached HEAD)"
    exit 1
}

if ($branch -eq $TargetBranch) {
    Write-Error "[specify] Error: Already on target branch ($TargetBranch); switch to a feature branch first"
    exit 1
}

# Detect remote platform
$remoteUrl = git remote get-url origin 2>$null
$platform = "unknown"
if ($remoteUrl -match 'github') { $platform = "github" }
elseif ($remoteUrl -match 'gitlab') { $platform = "gitlab" }
elseif ($remoteUrl -match 'dev\.azure') { $platform = "azure" }

# Ensure title
if (-not $Title) {
    $Title = ($branch -replace '^[^/]*/', '') -replace '-', ' '
    $Title = (Get-Culture).TextInfo.ToTitleCase($Title)
    Write-Warning "[specify] No -Title provided; generated: $Title"
}

# Check for uncommitted changes
$savedEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    git diff --quiet HEAD 2>$null; $d1 = $LASTEXITCODE
    git diff --cached --quiet 2>$null; $d2 = $LASTEXITCODE
    $untracked = git ls-files --others --exclude-standard 2>$null
} finally {
    $ErrorActionPreference = $savedEAP
}

if ($d1 -ne 0 -or $d2 -ne 0 -or $untracked) {
    Write-Error "[specify] Error: Uncommitted changes found. Commit or stash before publishing."
    exit 1
}

# Push
Write-Host "[specify] Pushing branch $branch to origin..." -ForegroundColor Cyan
$pushOut = git push -u origin $branch 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Error "[specify] Error: Push failed: $pushOut"
    exit 1
}

# Create PR/MR
$prUrl = ""
switch ($platform) {
    "github" {
        if (Get-Command gh -ErrorAction SilentlyContinue) {
            $args = @('pr', 'create', '--title', $Title, '--base', $TargetBranch, '--head', $branch)
            if ($Body) { $args += @('--body', $Body) }
            if ($Draft) { $args += @('--draft') }
            $prUrl = gh @args 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) {
                Write-Error "[specify] Error: gh pr create failed: $prUrl"
                exit 1
            }
            $prUrl = $prUrl.Trim()
        } else {
            Write-Error "[specify] Error: 'gh' CLI not found. Install GitHub CLI to create PRs."
            exit 1
        }
    }
    "gitlab" {
        if (Get-Command glab -ErrorAction SilentlyContinue) {
            $args = @('mr', 'create', '--title', $Title, '--target-branch', $TargetBranch, '--source-branch', $branch)
            if ($Body) { $args += @('--description', $Body) }
            if ($Draft) { $args += @('--draft') }
            $prUrl = glab @args 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) {
                Write-Error "[specify] Error: glab mr create failed: $prUrl"
                exit 1
            }
            $prUrl = $prUrl.Trim()
        } else {
            Write-Error "[specify] Error: 'glab' CLI not found. Install GitLab CLI to create MRs."
            exit 1
        }
    }
    "azure" {
        Write-Warning "[specify] Azure DevOps not fully supported. Branch $branch has been pushed."
        exit 0
    }
    default {
        Write-Warning "[specify] Unknown platform for remote: $remoteUrl. Branch $branch has been pushed."
        exit 0
    }
}

# Output summary
Write-Host ""
Write-Host "## Publish Summary"
Write-Host "| Operation | Status |"
Write-Host "|-----------|--------|"
Write-Host "| Push | Success |"
Write-Host "| PR/MR URL | $prUrl |"
Write-Host "| Title | $Title |"
Write-Host "| Branch | $branch -> $TargetBranch |"
Write-Host "| Draft | $Draft |"
Write-Host ""

# Return URL for downstream use
$prUrl
