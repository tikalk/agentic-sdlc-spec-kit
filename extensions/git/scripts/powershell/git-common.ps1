#!/usr/bin/env pwsh
# Git-specific common functions for the git extension.
# Extracted from scripts/powershell/common.ps1 -- contains only git-specific
# branch validation and detection logic.

# Find the project root by looking for .specify directory
function Find-SpecifyRoot {
    param([string]$Dir = (Get-Location))
    $Dir = (Resolve-Path $Dir -ErrorAction SilentlyContinue).Path
    if (-not $Dir) { return $null }

    while ($true) {
        $specifyPath = Join-Path $Dir ".specify"
        if (Test-Path $specifyPath -PathType Container) {
            return $Dir
        }
        $parent = Split-Path $Dir -Parent
        if (-not $parent -or $parent -eq $Dir) { break }
        $Dir = $parent
    }
    return $null
}

# Get repository root, prioritizing .specify directory over git
function Get-RepoRoot {
    $specifyRoot = Find-SpecifyRoot
    if ($specifyRoot) {
        return $specifyRoot
    }

    try {
        $gitRoot = git rev-parse --show-toplevel 2>$null
        if ($gitRoot) { return $gitRoot }
    } catch { }

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $extensionDir = Split-Path -Parent $scriptDir
    $projectDir = Split-Path -Parent $extensionDir
    return $projectDir
}

# Check if we have git available at the repo root
function Has-Git {
    param([string]$RepoRoot = (Get-Location))
    try {
        $gitDir = Join-Path $RepoRoot ".git"
        if (-not (Test-Path $gitDir)) { return $false }
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $false }
        $null = git -C $RepoRoot rev-parse --is-inside-work-tree 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# Alias for compatibility
function Test-HasGit {
    param([string]$RepoRoot = (Get-Location))
    try {
        if (-not (Test-Path (Join-Path $RepoRoot '.git'))) { return $false }
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $false }
        git -C $RepoRoot rev-parse --is-inside-work-tree 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Get-SpecKitBranchPatternConfigPath {
    param([string]$RepoRoot = (Get-RepoRoot))
    return (Join-Path $RepoRoot '.specify/extensions/git/git-config.yml')
}

function Get-SpecKitBranchPatternScalar {
    param(
        [string]$RepoRoot,
        [string]$KeyPath
    )
    $cfg = Get-SpecKitBranchPatternConfigPath -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $cfg -PathType Leaf)) { return $null }

    if (Get-Command python3 -ErrorAction SilentlyContinue) {
        try {
            $value = & python3 -c @"
import sys
try:
    import yaml
except Exception:
    raise SystemExit(0)

path = sys.argv[1]
keys = sys.argv[2].split('.')
try:
    with open(path, encoding='utf-8') as fh:
        data = yaml.safe_load(fh) or {}
    cur = data
    for key in keys:
        if not isinstance(cur, dict) or key not in cur:
            cur = None
            break
        cur = cur[key]
    if cur is None or isinstance(cur, (dict, list)):
        raise SystemExit(0)
    if isinstance(cur, bool):
        print('true' if cur else 'false')
    else:
        print(str(cur))
except Exception:
    raise SystemExit(0)
"@ $cfg $KeyPath 2>$null
            if ($value) { return ($value | Out-String).Trim() }
        } catch {}
    }

    $lines = Get-Content -LiteralPath $cfg -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        switch ($KeyPath) {
            'branch_pattern.enabled' {
                if ($line -match '^[\s]*enabled\s*:\s*(.+?)\s*(#.*)?$') { return $matches[1].Trim().Trim("'", '"') }
            }
            'branch_pattern.template' {
                if ($line -match '^[\s]*template\s*:\s*(.+?)\s*(#.*)?$') { return $matches[1].Trim().Trim("'", '"') }
            }
            'branch_pattern.number_padding' {
                if ($line -match '^[\s]*number_padding\s*:\s*(.+?)\s*(#.*)?$') { return $matches[1].Trim().Trim("'", '"') }
            }
            'branch_pattern.issue_format' {
                if ($line -match '^[\s]*issue_format\s*:\s*(.+?)\s*(#.*)?$') { return $matches[1].Trim().Trim("'", '"') }
            }
        }
    }
    return $null
}

function Get-SpecKitBranchPatternAllowedPrefixes {
    param([string]$RepoRoot)
    $cfg = Get-SpecKitBranchPatternConfigPath -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $cfg -PathType Leaf)) { return @() }

    if (Get-Command python3 -ErrorAction SilentlyContinue) {
        try {
            $values = & python3 -c @"
import sys
try:
    import yaml
except Exception:
    raise SystemExit(0)

try:
    with open(sys.argv[1], encoding='utf-8') as fh:
        data = yaml.safe_load(fh) or {}
    vals = (((data or {}).get('branch_pattern') or {}).get('allowed_prefixes') or [])
    if isinstance(vals, list):
        for item in vals:
            if item is not None:
                print(str(item))
except Exception:
    raise SystemExit(0)
"@ $cfg 2>$null
            if ($values) {
                return @($values | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ })
            }
        } catch {}
    }

    $prefixes = @()
    $inBranchPattern = $false
    $inAllowedPrefixes = $false
    foreach ($line in Get-Content -LiteralPath $cfg -ErrorAction SilentlyContinue) {
        if ($line -match '^[^\s]') {
            $inBranchPattern = $false
            $inAllowedPrefixes = $false
        }
        if ($line -match '^\s*branch_pattern\s*:') {
            $inBranchPattern = $true
            continue
        }
        if (-not $inBranchPattern) { continue }
        if ($line -match '^\s*allowed_prefixes\s*:') {
            $inAllowedPrefixes = $true
            continue
        }
        if ($inAllowedPrefixes -and $line -match '^\s*-[\s]*(.+?)\s*(#.*)?$') {
            $prefixes += $matches[1].Trim().Trim("'", '"')
            continue
        }
        if ($inAllowedPrefixes -and $line -match '^\s*[A-Za-z_]+\s*:') {
            $inAllowedPrefixes = $false
        }
    }
    return $prefixes
}

function Test-SpecKitBranchPatternEnabled {
    param([string]$RepoRoot = (Get-RepoRoot))
    $enabled = Get-SpecKitBranchPatternScalar -RepoRoot $RepoRoot -KeyPath 'branch_pattern.enabled'
    return $enabled -in @('true', 'True', 'yes', '1')
}

function Get-SpecKitIssueKeyRegex {
    return '^[A-Z][A-Z0-9]+-[0-9]+$'
}

function Normalize-SpecKitIssueKey {
    param([string]$Issue)
    return ([string]$Issue).ToUpperInvariant()
}

function Test-SpecKitIssueKey {
    param([string]$Issue)
    return ([string]$Issue) -match (Get-SpecKitIssueKeyRegex)
}

function Get-SpecKitBranchPatternValidationMessage {
    param([string]$RepoRoot = (Get-RepoRoot))
    $template = Get-SpecKitBranchPatternScalar -RepoRoot $RepoRoot -KeyPath 'branch_pattern.template'
    if ($template) {
        return "Feature branches should match configured template: $template"
    }
    return 'Feature branches should be named like: 001-feature-name, 1234-feature-name, or 20260319-143022-feature-name'
}

function Get-SpecKitFeatureIdentity {
    param([string]$Branch)
    if ($Branch -match '^(\d{8}-\d{6})-') { return $Matches[1] }
    if ($Branch -match '^(\d{3,})-') { return $Matches[1] }
    if ($Branch -match '/(\d{8}-\d{6})-') { return $Matches[1] }
    if ($Branch -match '/(\d{3,})-') { return $Matches[1] }
    return $null
}

function Test-SpecKitBranchMatchesConfiguredPattern {
    param(
        [string]$RawBranch,
        [string]$RepoRoot = (Get-RepoRoot)
    )

    $branch = Get-SpecKitEffectiveBranchName $RawBranch
    $template = Get-SpecKitBranchPatternScalar -RepoRoot $RepoRoot -KeyPath 'branch_pattern.template'
    if (-not $template) { return $false }

    $hasPrefix = $template.Contains('{prefix}')
    $hasIssue = $template.Contains('{issue}')

    if ($hasPrefix) {
        $allowedPrefixes = @(Get-SpecKitBranchPatternAllowedPrefixes -RepoRoot $RepoRoot)
        if ($allowedPrefixes.Count -eq 0) { return $false }
        $matchedPrefix = $allowedPrefixes | Where-Object { $RawBranch.StartsWith("$_/") } | Select-Object -First 1
        if (-not $matchedPrefix) { return $false }
    }

    $identity = Get-SpecKitFeatureIdentity $RawBranch
    if (-not $identity) { return $false }
    if (-not $branch.StartsWith("$identity-")) { return $false }
    $rest = $branch.Substring($identity.Length + 1)

    if ($hasIssue) {
        if ($rest -notmatch '^([A-Z][A-Z0-9]+-[0-9]+)-(.+)$') { return $false }
        $issueKey = $Matches[1]
        if (-not (Test-SpecKitIssueKey $issueKey)) { return $false }
        $rest = $Matches[2]
    }

    return ($rest -match '^[a-z0-9]+(-[a-z0-9]+)*$')
}

function Get-SpecKitEffectiveBranchName {
    param([string]$Branch)
    if ($Branch -match '^([^/]+)/([^/]+)$') {
        return $Matches[2]
    }
    return $Branch
}

function Test-FeatureBranch {
    param(
        [string]$Branch,
        [bool]$HasGit = $true
    )

    # For non-git repos, we can't enforce branch naming but still provide output
    if (-not $HasGit) {
        Write-Warning "[specify] Warning: Git repository not detected; skipped branch validation"
        return $true
    }

    $raw = $Branch
    $Branch = Get-SpecKitEffectiveBranchName $raw

    $repoRoot = Get-RepoRoot
    if (Test-SpecKitBranchPatternEnabled -RepoRoot $repoRoot) {
        if (Test-SpecKitBranchMatchesConfiguredPattern -RawBranch $raw -RepoRoot $repoRoot) {
            return $true
        }
        [Console]::Error.WriteLine("ERROR: Not on a feature branch. Current branch: $raw")
        [Console]::Error.WriteLine((Get-SpecKitBranchPatternValidationMessage -RepoRoot $repoRoot))
        return $false
    }

    # Accept sequential prefix (3+ digits) but exclude malformed timestamps
    # Malformed: 7-or-8 digit date + 6-digit time with no trailing slug (e.g. "2026031-143022" or "20260319-143022")
    $hasMalformedTimestamp = ($Branch -match '^[0-9]{7}-[0-9]{6}-') -or ($Branch -match '^(?:\d{7}|\d{8})-\d{6}$')
    $isSequential = ($Branch -match '^[0-9]{3,}-') -and (-not $hasMalformedTimestamp)
    if (-not $isSequential -and $Branch -notmatch '^\d{8}-\d{6}-') {
        [Console]::Error.WriteLine("ERROR: Not on a feature branch. Current branch: $raw")
        [Console]::Error.WriteLine("Feature branches should be named like: 001-feature-name, 1234-feature-name, or 20260319-143022-feature-name")
        return $false
    }
    return $true
}
