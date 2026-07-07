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

function Get-SpecKitBranchTemplateConfigPath {
    param([string]$RepoRoot = (Get-RepoRoot))
    return (Join-Path $RepoRoot '.specify/extensions/git/git-config.yml')
}

# Read a top-level scalar value from git-config.yml by key name.
# Only top-level keys are read; legacy nested blocks are ignored.
function Get-SpecKitBranchTemplateScalar {
    param(
        [string]$RepoRoot,
        [string]$Key
    )
    $cfg = Get-SpecKitBranchTemplateConfigPath -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $cfg -PathType Leaf)) { return $null }

    if (Get-Command python3 -ErrorAction SilentlyContinue) {
        try {
            $value = & python3 -c @"
import sys
try:
    import yaml
except Exception:
    raise SystemExit(0)

path, key = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding='utf-8') as fh:
        data = yaml.safe_load(fh) or {}
    cur = data.get(key)
    if cur is None or isinstance(cur, (dict, list)):
        raise SystemExit(0)
    if isinstance(cur, bool):
        print('true' if cur else 'false')
    else:
        print(str(cur))
except Exception:
    raise SystemExit(0)
"@ $cfg $Key 2>$null
            if ($value) { return ($value | Out-String).Trim() }
        } catch {}
    }

    # Fallback line-based parser for top-level keys only (no leading whitespace)
    $lines = Get-Content -LiteralPath $cfg -ErrorAction SilentlyContinue
    $escapedKey = [regex]::Escape($Key)
    foreach ($line in $lines) {
        if ($line -match "^$escapedKey\s*:\s*(.+?)\s*(#.*)?$") {
            return $matches[1].Trim().Trim("'", '"')
        }
    }
    return $null
}

function Test-SpecKitBranchTemplateEnabled {
    param([string]$RepoRoot = (Get-RepoRoot))
    $template = Get-SpecKitBranchTemplateScalar -RepoRoot $RepoRoot -Key 'branch_template'
    $prefix = Get-SpecKitBranchTemplateScalar -RepoRoot $RepoRoot -Key 'branch_prefix'
    return ($template -or $prefix)
}

function Get-SpecKitIssueKeyRegex {
    return '^[A-Z][A-Z0-9]*-[0-9]+$'
}

function Normalize-SpecKitIssueKey {
    param([string]$Issue)
    return ([string]$Issue).ToUpperInvariant()
}

function Test-SpecKitIssueKey {
    param([string]$Issue)
    return ([string]$Issue) -match (Get-SpecKitIssueKeyRegex)
}

# Resolve the effective branch template.
# If branch_template is set it wins; otherwise branch_prefix expands to
# <prefix>/{number}-{slug} (preserving a trailing slash on the prefix).
function Get-SpecKitResolvedBranchTemplate {
    param([string]$RepoRoot = (Get-RepoRoot))
    $template = Get-SpecKitBranchTemplateScalar -RepoRoot $RepoRoot -Key 'branch_template'
    if ($template) { return $template }

    $prefix = Get-SpecKitBranchTemplateScalar -RepoRoot $RepoRoot -Key 'branch_prefix'
    if (-not $prefix) { return '' }
    if ($prefix.EndsWith('/')) { return "${prefix}{number}-{slug}" }
    return "$prefix/{number}-{slug}"
}

function Get-SpecKitBranchTemplateValidationMessage {
    param([string]$RepoRoot = (Get-RepoRoot))
    $template = Get-SpecKitResolvedBranchTemplate -RepoRoot $RepoRoot
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

# Validate a raw branch name against the configured branch_template.
# Token semantics mirror create-new-feature-branch.ps1:
#   {author}    -> [^/]+
#   {app}       -> [^/]+
#   {number}    -> [0-9]{padding}  (default padding 3)
#   {timestamp} -> [0-9]{8}-[0-9]{6}
#   {issue}     -> jira=[A-Z][A-Z0-9]*-[0-9]+ or numeric=[0-9]+
#   {slug}      -> [a-z0-9]+(?:-[a-z0-9]+)*
# Literal text (including "/") is matched literally.
function Test-SpecKitBranchMatchesConfiguredTemplate {
    param(
        [string]$RawBranch,
        [string]$RepoRoot = (Get-RepoRoot)
    )

    $cfg = Get-SpecKitBranchTemplateConfigPath -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $cfg -PathType Leaf)) { return $false }

    $template = Get-SpecKitBranchTemplateScalar -RepoRoot $RepoRoot -Key 'branch_template'
    $prefix = Get-SpecKitBranchTemplateScalar -RepoRoot $RepoRoot -Key 'branch_prefix'
    $paddingStr = Get-SpecKitBranchTemplateScalar -RepoRoot $RepoRoot -Key 'number_padding'
    $issueFormat = Get-SpecKitBranchTemplateScalar -RepoRoot $RepoRoot -Key 'issue_format'

    if (-not $template -and -not $prefix) { return $false }

    if ($template -and $template.Contains('{prefix}')) {
        if (-not $prefix) { return $false }
        $template = $template.Replace('{prefix}', $prefix)
    }

    if (-not $template) {
        if ($prefix.EndsWith('/')) {
            $template = "${prefix}{number}-{slug}"
        } else {
            $template = "$prefix/{number}-{slug}"
        }
    }

    [int]$padding = 3
    if ($paddingStr -and $paddingStr -match '^\d+$') {
        [int]::TryParse($paddingStr, [ref]$padding) | Out-Null
        if ($padding -lt 1) { $padding = 3 }
    }

    if (-not $issueFormat) { $issueFormat = 'jira' }
    $issueFormat = $issueFormat.ToLowerInvariant()

    $tokenMap = [ordered]@{
        '{author}' = '(?<author>[^/]+)'
        '{app}' = '(?<app>[^/]+)'
        '{number}' = "(?<number>[0-9]{$padding})"
        '{timestamp}' = '(?<timestamp>[0-9]{8}-[0-9]{6})'
        '{issue}' = '(?<issue>[A-Z][A-Z0-9]*-[0-9]+|[0-9]+)'
        '{slug}' = '(?<slug>[a-z0-9]+(?:-[a-z0-9]+)*)'
    }

    $tokenPattern = '(\{author\}|\{app\}|\{number\}|\{timestamp\}|\{issue\}|\{slug\})'
    $parts = [regex]::Split($template, $tokenPattern)
    $sb = New-Object System.Text.StringBuilder
    foreach ($part in $parts) {
        if ($tokenMap.Contains($part)) {
            [void]$sb.Append($tokenMap[$part])
        } else {
            [void]$sb.Append([regex]::Escape($part))
        }
    }
    $regexStr = '^' + $sb.ToString() + '$'

    $match = [regex]::Match($RawBranch, $regexStr)
    if (-not $match.Success) { return $false }

    if ($template.Contains('{issue}')) {
        $issueKey = $match.Groups['issue'].Value
        if ($issueFormat -eq 'numeric') {
            if ($issueKey -notmatch '^[0-9]+$') { return $false }
        } else {
            if ($issueKey -notmatch '^[A-Z][A-Z0-9]*-[0-9]+$') { return $false }
        }
    }

    return $true
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
    $featureSegment = ($Branch -split '/')[-1]

    $repoRoot = Get-RepoRoot
    if (Test-SpecKitBranchTemplateEnabled -RepoRoot $repoRoot) {
        if (Test-SpecKitBranchMatchesConfiguredTemplate -RawBranch $raw -RepoRoot $repoRoot) {
            return $true
        }
        [Console]::Error.WriteLine("ERROR: Not on a feature branch. Current branch: $raw")
        [Console]::Error.WriteLine((Get-SpecKitBranchTemplateValidationMessage -RepoRoot $repoRoot))
        return $false
    }

    # Accept sequential prefix (3+ digits), at the start or after namespace
    # segments, but exclude malformed timestamps.
    $hasMalformedTimestamp = ($featureSegment -match '^[0-9]{7}-[0-9]{6}-') -or ($featureSegment -match '^(?:\d{7}|\d{8})-\d{6}$')
    $isSequential = ($featureSegment -match '^[0-9]{3,}-') -and (-not $hasMalformedTimestamp)
    if (-not $isSequential -and $featureSegment -notmatch '^\d{8}-\d{6}-') {
        [Console]::Error.WriteLine("ERROR: Not on a feature branch. Current branch: $raw")
        [Console]::Error.WriteLine("Feature branches should be named like: 001-feature-name, 1234-feature-name, 20260319-143022-feature-name, or <prefix>/001-feature-name")
        return $false
    }
    return $true
}
