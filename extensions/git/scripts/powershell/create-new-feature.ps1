#!/usr/bin/env pwsh
# Git extension: create-new-feature.ps1
# Adapted from core scripts/powershell/create-new-feature.ps1 for extension layout.
# Sources common.ps1 from the project's installed scripts, falling back to
# git-common.ps1 for minimal git helpers.
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$AllowExistingBranch,
    [switch]$DryRun,
    [string]$ShortName,
    [Parameter()]
    [long]$Number = 0,
    [switch]$Timestamp,
    [string]$Issue,
    [switch]$Worktree,
    [switch]$BranchMode,
    [string]$IsolationMode,
    [string]$Base,
    [switch]$Help,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$FeatureDescription
)
$ErrorActionPreference = 'Stop'

if ($Help) {
    Write-Host "Usage: ./create-new-feature.ps1 [-Json] [-DryRun] [-AllowExistingBranch] [-ShortName <name>] [-Number N] [-Timestamp] [-Issue <JIRA-123>] [-Worktree|-BranchMode|-IsolationMode <mode>] [-Base <branch>] <feature description>"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Json                 Output in JSON format"
    Write-Host "  -DryRun               Compute branch name without creating the branch"
    Write-Host "  -AllowExistingBranch  Switch to branch if it already exists instead of failing"
    Write-Host "  -ShortName <name>     Provide a custom short name (2-4 words) for the branch"
    Write-Host "  -Number N             Specify branch number manually (overrides auto-detection)"
    Write-Host "  -Timestamp            Use timestamp prefix (YYYYMMDD-HHMMSS) instead of sequential numbering"
    Write-Host "  -Issue <JIRA-123>     Jira-style issue key used by branch_pattern templates"
    Write-Host "  -Worktree             Force worktree isolation (creates a feature-level worktree under .worktrees/<feature>/)"
    Write-Host "  -BranchMode           Force branch isolation (default behavior; the new branch lives in the primary checkout)"
    Write-Host "  -IsolationMode <mode> Set isolation explicitly: 'branch' or 'worktree'"
    Write-Host "  -Base <branch>        Base branch for the new feature branch or worktree (default: current branch)"
    Write-Host "  -Help                 Show this help message"
    Write-Host ""
    Write-Host "Environment variables:"
    Write-Host "  GIT_BRANCH_NAME        Use this exact branch name, bypassing all prefix/suffix generation"
    Write-Host "  GIT_BRANCH_ISSUE       Jira-style issue key used by branch_pattern templates"
    Write-Host "  SPECIFY_ISOLATION_MODE Override isolation mode ('branch' or 'worktree')"
    Write-Host ""
    Write-Host "Isolation mode resolution (highest precedence first):"
    Write-Host "  1. -Worktree / -BranchMode (boolean shortcuts)"
    Write-Host "  2. -IsolationMode <mode>"
    Write-Host "  3. SPECIFY_ISOLATION_MODE env var"
    Write-Host "  4. .specify/extensions/git/git-config.yml 'isolation_mode:' key"
    Write-Host "  5. Default: branch"
    Write-Host ""
    exit 0
}

if (-not $FeatureDescription -or $FeatureDescription.Count -eq 0) {
    Write-Error "Usage: ./create-new-feature.ps1 [-Json] [-DryRun] [-AllowExistingBranch] [-ShortName <name>] [-Number N] [-Timestamp] <feature description>"
    exit 1
}

$featureDesc = ($FeatureDescription -join ' ').Trim()

if ([string]::IsNullOrWhiteSpace($featureDesc)) {
    Write-Error "Error: Feature description cannot be empty or contain only whitespace"
    exit 1
}

function Get-HighestNumberFromSpecs {
    param([string]$SpecsDir)

    [long]$highest = 0
    if (Test-Path $SpecsDir) {
        Get-ChildItem -Path $SpecsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d{3,})-' -and $_.Name -notmatch '^\d{8}-\d{6}-') {
                [long]$num = 0
                if ([long]::TryParse($matches[1], [ref]$num) -and $num -gt $highest) {
                    $highest = $num
                }
            }
        }
    }
    return $highest
}

function Get-HighestNumberFromNames {
    param([string[]]$Names)

    [long]$highest = 0
    foreach ($name in $Names) {
        if ($name -match '^(\d{3,})-' -and $name -notmatch '^\d{8}-\d{6}-') {
            [long]$num = 0
            if ([long]::TryParse($matches[1], [ref]$num) -and $num -gt $highest) {
                $highest = $num
            }
        }
    }
    return $highest
}

function Get-HighestNumberFromBranches {
    param()

    try {
        $branches = git branch -a 2>$null
        if ($LASTEXITCODE -eq 0 -and $branches) {
            $cleanNames = $branches | ForEach-Object {
                $_.Trim() -replace '^\*?\s+', '' -replace '^remotes/[^/]+/', ''
            }
            return Get-HighestNumberFromNames -Names $cleanNames
        }
    } catch {
        Write-Verbose "Could not check Git branches: $_"
    }
    return 0
}

function Get-HighestNumberFromRemoteRefs {
    [long]$highest = 0
    try {
        $remotes = git remote 2>$null
        if ($remotes) {
            foreach ($remote in $remotes) {
                $env:GIT_TERMINAL_PROMPT = '0'
                $refs = git ls-remote --heads $remote 2>$null
                $env:GIT_TERMINAL_PROMPT = $null
                if ($LASTEXITCODE -eq 0 -and $refs) {
                    $refNames = $refs | ForEach-Object {
                        if ($_ -match 'refs/heads/(.+)$') { $matches[1] }
                    } | Where-Object { $_ }
                    $remoteHighest = Get-HighestNumberFromNames -Names $refNames
                    if ($remoteHighest -gt $highest) { $highest = $remoteHighest }
                }
            }
        }
    } catch {
        Write-Verbose "Could not query remote refs: $_"
    }
    return $highest
}

function Get-NextBranchNumber {
    param(
        [string]$SpecsDir,
        [switch]$SkipFetch
    )

    if ($SkipFetch) {
        $highestBranch = Get-HighestNumberFromBranches
        $highestRemote = Get-HighestNumberFromRemoteRefs
        $highestBranch = [Math]::Max($highestBranch, $highestRemote)
    } else {
        try {
            git fetch --all --prune 2>$null | Out-Null
        } catch { }
        $highestBranch = Get-HighestNumberFromBranches
    }

    $highestSpec = Get-HighestNumberFromSpecs -SpecsDir $SpecsDir
    $maxNum = [Math]::Max($highestBranch, $highestSpec)
    return $maxNum + 1
}

function ConvertTo-CleanBranchName {
    param([string]$Name)
    return $Name.ToLower() -replace '[^a-z0-9]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
}

# ---------------------------------------------------------------------------
# Resolve isolation mode (branch vs worktree).
#
# Precedence (highest first):
#   1. -Worktree / -BranchMode (boolean shortcuts)
#   2. -IsolationMode <mode>
#   3. SPECIFY_ISOLATION_MODE env var
#   4. .specify/extensions/git/git-config.yml 'isolation_mode:' key
#   5. Default: branch
# ---------------------------------------------------------------------------
function Resolve-IsolationMode {
    if ($Worktree) { return 'worktree' }
    if ($BranchMode) { return 'branch' }
    if (-not [string]::IsNullOrEmpty($IsolationMode)) {
        if ($IsolationMode -ne 'branch' -and $IsolationMode -ne 'worktree') {
            throw "Error: -IsolationMode must be 'branch' or 'worktree' (got: $IsolationMode)"
        }
        return $IsolationMode
    }
    $envMode = $env:SPECIFY_ISOLATION_MODE
    if (-not [string]::IsNullOrEmpty($envMode) -and ($envMode -eq 'branch' -or $envMode -eq 'worktree')) {
        return $envMode
    }
    $cfgPath = Join-Path $repoRoot '.specify/extensions/git/git-config.yml'
    if (Test-Path $cfgPath) {
        $cfgValue = ''
        try {
            $lines = Get-Content -Path $cfgPath -ErrorAction SilentlyContinue
            foreach ($line in $lines) {
                if ($line -match '^\s*isolation_mode\s*:\s*(.+?)\s*(#.*)?$') {
                    $cfgValue = $matches[1].Trim().Trim("'", '"')
                }
            }
        } catch {}
        if ($cfgValue -eq 'branch' -or $cfgValue -eq 'worktree') {
            return $cfgValue
        }
    }
    return 'branch'
}

# Worktree delegation block is inserted below, AFTER $repoRoot is resolved.

# Search locations in priority order:
#  1. .specify/scripts/powershell/common.ps1 under the project root
#  2. scripts/powershell/common.ps1 under the project root (source checkout)
#  3. git-common.ps1 next to this script (minimal fallback)
# ---------------------------------------------------------------------------
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

$projectRoot = Find-ProjectRoot -StartDir $PSScriptRoot
$commonLoaded = $false

if ($projectRoot) {
    $candidates = @(
        (Join-Path $projectRoot ".specify/scripts/powershell/common.ps1"),
        (Join-Path $projectRoot "scripts/powershell/common.ps1")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            . $candidate
            $commonLoaded = $true
            break
        }
    }
}

if (-not $commonLoaded -and (Test-Path "$PSScriptRoot/git-common.ps1")) {
    . "$PSScriptRoot/git-common.ps1"
    $commonLoaded = $true
}

if (-not $commonLoaded) {
    throw "Unable to locate common script file. Please ensure the Specify core scripts are installed."
}

# Resolve repository root
if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
    $repoRoot = Get-RepoRoot
} elseif ($projectRoot) {
    $repoRoot = $projectRoot
} else {
    throw "Could not determine repository root."
}

# Check if git is available
if (Get-Command Test-HasGit -ErrorAction SilentlyContinue) {
    # Call without parameters for compatibility with core common.ps1 (no -RepoRoot param)
    # and git-common.ps1 (has -RepoRoot param with default).
    $hasGit = Test-HasGit
} else {
    try {
        git -C $repoRoot rev-parse --is-inside-work-tree 2>$null | Out-Null
        $hasGit = ($LASTEXITCODE -eq 0)
    } catch {
        $hasGit = $false
    }
}

Set-Location $repoRoot

$specsDir = Join-Path $repoRoot 'specs'

# Resolve isolation mode now that $repoRoot is known.
$isolationMode = Resolve-IsolationMode

# ---------------------------------------------------------------------------
# Worktree mode: delegate to worktree-utils.ps1 instead of git checkout -b.
# ---------------------------------------------------------------------------
$worktreeUtils = Join-Path $PSScriptRoot 'worktree-utils.ps1'

function Invoke-WorktreeDelegation {
    param([string]$FeatureName, [string]$BaseBranch)

    $wtArgs = @('create-feature-worktree', '-Feature', $FeatureName)
    if (-not [string]::IsNullOrEmpty($BaseBranch)) {
        $wtArgs += @('-Base', $BaseBranch)
    }

    $wtExit = 0
    $wtStdout = ''
    try {
        $wtStdout = & pwsh -NoProfile -File $worktreeUtils @wtArgs 2>$null
        $wtExit = $LASTEXITCODE
    } catch {
        $wtExit = 1
    }
    if ($wtExit -ne 0) {
        & pwsh -NoProfile -File $worktreeUtils @wtArgs 2>&1 | Out-Null
        exit $wtExit
    }

    $wtJsonText = ($wtStdout -join "`n")
    $wtData = $null
    try {
        $wtData = $wtJsonText | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "Error: failed to parse worktree-utils.ps1 output as JSON. Raw: $wtJsonText"
    }
    $wtPath = if ($wtData.PSObject.Properties.Match('worktree_path').Count) { [string]$wtData.worktree_path } else { '' }
    $mfPath = if ($wtData.PSObject.Properties.Match('manifest_path').Count) { [string]$wtData.manifest_path } else { '' }
    return @{ WorktreePath = $wtPath; ManifestPath = $mfPath }
}

function Get-BranchName {
    param([string]$Description)

    $stopWords = @(
        'i', 'a', 'an', 'the', 'to', 'for', 'of', 'in', 'on', 'at', 'by', 'with', 'from',
        'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
        'do', 'does', 'did', 'will', 'would', 'should', 'could', 'can', 'may', 'might', 'must', 'shall',
        'this', 'that', 'these', 'those', 'my', 'your', 'our', 'their',
        'want', 'need', 'add', 'get', 'set'
    )

    $cleanName = $Description.ToLower() -replace '[^a-z0-9\s]', ' '
    $words = $cleanName -split '\s+' | Where-Object { $_ }

    $meaningfulWords = @()
    foreach ($word in $words) {
        if ($stopWords -contains $word) { continue }
        if ($word.Length -ge 3) {
            $meaningfulWords += $word
        } elseif ($Description -match "\b$($word.ToUpper())\b") {
            $meaningfulWords += $word
        }
    }

    if ($meaningfulWords.Count -gt 0) {
        $maxWords = if ($meaningfulWords.Count -eq 4) { 4 } else { 3 }
        $result = ($meaningfulWords | Select-Object -First $maxWords) -join '-'
        return $result
    } else {
        $result = ConvertTo-CleanBranchName -Name $Description
        $fallbackWords = ($result -split '-') | Where-Object { $_ } | Select-Object -First 3
        return [string]::Join('-', $fallbackWords)
    }
}

function Test-SpecKitBranchPatternTemplate {
    param([string]$Template)
    if ([string]::IsNullOrWhiteSpace($Template)) { return $false }
    if (-not $Template.Contains('{slug}')) { return $false }
    $hasNumber = $Template.Contains('{number}')
    $hasTimestamp = $Template.Contains('{timestamp}')
    return (($hasNumber -and -not $hasTimestamp) -or (-not $hasNumber -and $hasTimestamp))
}

function Get-SpecKitFirstBranchPatternPrefix {
    param([string]$RepoRoot)
    $prefixes = @(Get-SpecKitBranchPatternAllowedPrefixes -RepoRoot $RepoRoot)
    if ($prefixes.Count -gt 0) { return [string]$prefixes[0] }
    return ''
}

function Render-SpecKitBranchPattern {
    param(
        [string]$Template,
        [string]$Prefix,
        [string]$Number,
        [string]$TimestampValue,
        [string]$IssueKey,
        [string]$Slug
    )
    $result = $Template
    $result = $result.Replace('{prefix}', $Prefix)
    $result = $result.Replace('{number}', $Number)
    $result = $result.Replace('{timestamp}', $TimestampValue)
    $result = $result.Replace('{issue}', $IssueKey)
    $result = $result.Replace('{slug}', $Slug)
    return $result
}

function Get-SpecKitPatternBranchName {
    param(
        [string]$RepoRoot,
        [string]$BranchSuffix,
        [string]$FeatureNum,
        [bool]$UseTimestamp,
        [string]$IssueKey
    )

    $template = Get-SpecKitBranchPatternScalar -RepoRoot $RepoRoot -KeyPath 'branch_pattern.template'
    if (-not (Test-SpecKitBranchPatternTemplate -Template $template)) {
        throw 'Invalid branch_pattern.template. It must include {slug} and exactly one of {number} or {timestamp}.'
    }

    $prefix = ''
    if ($template.Contains('{prefix}')) {
        $prefix = Get-SpecKitFirstBranchPatternPrefix -RepoRoot $RepoRoot
        if ([string]::IsNullOrWhiteSpace($prefix)) {
            throw 'branch_pattern.template uses {prefix}, but branch_pattern.allowed_prefixes is empty.'
        }
    }

    $normalizedIssue = ''
    if ($template.Contains('{issue}')) {
        $candidateIssue = if ($IssueKey) { $IssueKey } else { $env:GIT_BRANCH_ISSUE }
        $normalizedIssue = Normalize-SpecKitIssueKey $candidateIssue
        if ([string]::IsNullOrWhiteSpace($normalizedIssue)) {
            throw 'branch_pattern.template uses {issue}; provide -Issue or GIT_BRANCH_ISSUE.'
        }
        if (-not (Test-SpecKitIssueKey $normalizedIssue)) {
            throw "Invalid Jira issue key '$normalizedIssue'. Expected format like PROJ-123."
        }
    }

    if ($template.Contains('{number}')) {
        $padding = Get-SpecKitBranchPatternScalar -RepoRoot $RepoRoot -KeyPath 'branch_pattern.number_padding'
        if (-not ($padding -as [int])) { $padding = 3 }
        $numberValue = ('{0:D' + [int]$padding + '}') -f [int64]$FeatureNum
        return Render-SpecKitBranchPattern -Template $template -Prefix $prefix -Number $numberValue -TimestampValue '' -IssueKey $normalizedIssue -Slug $BranchSuffix
    }

    if (-not $UseTimestamp) {
        throw 'branch_pattern.template requires {timestamp}; rerun with -Timestamp or change the template.'
    }
    return Render-SpecKitBranchPattern -Template $template -Prefix $prefix -Number '' -TimestampValue $FeatureNum -IssueKey $normalizedIssue -Slug $BranchSuffix
}

# Check for GIT_BRANCH_NAME env var override (exact branch name, no prefix/suffix)
if ($env:GIT_BRANCH_NAME) {
    $branchName = $env:GIT_BRANCH_NAME
    # Check 244-byte limit (UTF-8) for override names
    $branchNameUtf8ByteCount = [System.Text.Encoding]::UTF8.GetByteCount($branchName)
    if ($branchNameUtf8ByteCount -gt 244) {
        throw "GIT_BRANCH_NAME must be 244 bytes or fewer in UTF-8. Provided value is $branchNameUtf8ByteCount bytes; please supply a shorter override branch name."
    }
    # Extract FEATURE_NUM from the branch name if it starts with a numeric prefix
    # Check timestamp pattern first (YYYYMMDD-HHMMSS-) since it also matches the simpler ^\d+ pattern
    if ($branchName -match '^(\d{8}-\d{6})-') {
        $featureNum = $matches[1]
    } elseif ($branchName -match '^(\d+)-') {
        $featureNum = $matches[1]
    } else {
        $featureNum = $branchName
    }
} else {
    if ($ShortName) {
        $branchSuffix = ConvertTo-CleanBranchName -Name $ShortName
    } else {
        $branchSuffix = Get-BranchName -Description $featureDesc
    }

    if ($Timestamp -and $Number -ne 0) {
        Write-Warning "[specify] Warning: -Number is ignored when -Timestamp is used"
        $Number = 0
    }

    if ($Timestamp) {
        $featureNum = Get-Date -Format 'yyyyMMdd-HHmmss'
    } else {
        if ($Number -eq 0) {
            if ($DryRun -and $hasGit) {
                $Number = Get-NextBranchNumber -SpecsDir $specsDir -SkipFetch
            } elseif ($DryRun) {
                $Number = (Get-HighestNumberFromSpecs -SpecsDir $specsDir) + 1
            } elseif ($hasGit) {
                $Number = Get-NextBranchNumber -SpecsDir $specsDir
            } else {
                $Number = (Get-HighestNumberFromSpecs -SpecsDir $specsDir) + 1
            }
        }

        $featureNum = ('{0:000}' -f $Number)
    }

    if (Test-SpecKitBranchPatternEnabled -RepoRoot $repoRoot) {
        $branchName = Get-SpecKitPatternBranchName -RepoRoot $repoRoot -BranchSuffix $branchSuffix -FeatureNum $featureNum -UseTimestamp:$Timestamp -IssueKey $Issue
    } else {
        $branchName = "$featureNum-$branchSuffix"
    }
}

$maxBranchLength = 244
if ($branchName.Length -gt $maxBranchLength) {
    $prefixLength = $featureNum.Length + 1
    $maxSuffixLength = $maxBranchLength - $prefixLength

    $truncatedSuffix = $branchSuffix.Substring(0, [Math]::Min($branchSuffix.Length, $maxSuffixLength))
    $truncatedSuffix = $truncatedSuffix -replace '-$', ''

    $originalBranchName = $branchName
    $branchName = "$featureNum-$truncatedSuffix"

    Write-Warning "[specify] Branch name exceeded GitHub's 244-byte limit"
    Write-Warning "[specify] Original: $originalBranchName ($($originalBranchName.Length) bytes)"
    Write-Warning "[specify] Truncated to: $branchName ($($branchName.Length) bytes)"
}

# ---------------------------------------------------------------------------
# Worktree mode gate: when isolation_mode is worktree, delegate to
# worktree-utils.ps1 instead of running the existing git checkout -b flow.
# The agent is expected to cd into the worktree path before working.
# ---------------------------------------------------------------------------
if ($isolationMode -eq 'worktree' -and -not $DryRun) {
    if (-not $hasGit) {
        throw "Error: worktree mode requires a git repository."
    }
    if (-not (Test-Path $worktreeUtils)) {
        throw "Error: worktree-utils.ps1 not found at $worktreeUtils (required for -Worktree mode)"
    }
    $wtResult = Invoke-WorktreeDelegation -FeatureName $branchName -BaseBranch $Base
    $worktreePath = $wtResult.WorktreePath
    $manifestPath = $wtResult.ManifestPath

    if ($Json) {
        $obj = [ordered]@{
            BRANCH_NAME   = $branchName
            FEATURE_NUM   = $featureNum
            ISOLATION_MODE = 'worktree'
            WORKTREE_PATH = $worktreePath
            MANIFEST_PATH = $manifestPath
        }
        $obj | ConvertTo-Json -Compress
    } else {
        Write-Output "BRANCH_NAME: $branchName"
        Write-Output "FEATURE_NUM: $featureNum"
        Write-Output "ISOLATION_MODE: worktree"
        Write-Output "WORKTREE_PATH: $worktreePath"
        Write-Output "MANIFEST_PATH: $manifestPath"
        Write-Warning "# To persist: `$env:SPECIFY_FEATURE='$branchName'"
        Write-Warning "# To work in the worktree: cd $worktreePath"
    }
    exit 0
}

# ---------------------------------------------------------------------------
# Branch mode (default): existing behavior - git checkout -b in primary.
# ---------------------------------------------------------------------------

if (-not $DryRun) {
    if ($hasGit) {
        $branchCreated = $false
        $branchCreateError = ''
        try {
            $branchCreateError = git checkout -q -b $branchName 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0) {
                $branchCreated = $true
            }
        } catch {
            $branchCreateError = $_.Exception.Message
        }

        if (-not $branchCreated) {
            $currentBranch = ''
            try { $currentBranch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim() } catch {}
            $existingBranch = git branch --list $branchName 2>$null
            if ($existingBranch) {
                if ($AllowExistingBranch) {
                    if ($currentBranch -eq $branchName) {
                        # Already on the target branch
                    } else {
                        $switchBranchError = git checkout -q $branchName 2>&1 | Out-String
                        if ($LASTEXITCODE -ne 0) {
                            if ($switchBranchError) {
                                Write-Error "Error: Branch '$branchName' exists but could not be checked out.`n$($switchBranchError.Trim())"
                            } else {
                                Write-Error "Error: Branch '$branchName' exists but could not be checked out. Resolve any uncommitted changes or conflicts and try again."
                            }
                            exit 1
                        }
                    }
                } elseif ($Timestamp) {
                    Write-Error "Error: Branch '$branchName' already exists. Rerun to get a new timestamp or use a different -ShortName."
                    exit 1
                } else {
                    Write-Error "Error: Branch '$branchName' already exists. Please use a different feature name or specify a different number with -Number."
                    exit 1
                }
            } else {
                if ($branchCreateError) {
                    Write-Error "Error: Failed to create git branch '$branchName'.`n$($branchCreateError.Trim())"
                } else {
                    Write-Error "Error: Failed to create git branch '$branchName'. Please check your git configuration and try again."
                }
                exit 1
            }
        }
    } else {
        if ($Json) {
            [Console]::Error.WriteLine("[specify] Warning: Git repository not detected; skipped branch creation for $branchName")
        } else {
            Write-Warning "[specify] Warning: Git repository not detected; skipped branch creation for $branchName"
        }
    }

    $env:SPECIFY_FEATURE = $branchName
}

if ($Json) {
    $obj = [PSCustomObject]@{
        BRANCH_NAME   = $branchName
        FEATURE_NUM   = $featureNum
        HAS_GIT       = $hasGit
        ISOLATION_MODE = $isolationMode
    }
    if ($DryRun) {
        $obj | Add-Member -NotePropertyName 'DRY_RUN' -NotePropertyValue $true
    }
    $obj | ConvertTo-Json -Compress
} else {
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "FEATURE_NUM: $featureNum"
    Write-Output "HAS_GIT: $hasGit"
    Write-Output "ISOLATION_MODE: $isolationMode"
    if (-not $DryRun) {
        Write-Output "SPECIFY_FEATURE environment variable set to: $branchName"
    }
}
