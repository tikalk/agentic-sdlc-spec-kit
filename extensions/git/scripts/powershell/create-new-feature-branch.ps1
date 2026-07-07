#!/usr/bin/env pwsh
# Git extension: create-new-feature-branch.ps1
# Creates a git feature branch. The feature directory and spec file are created
# by the core create-new-feature.ps1 script.
# Merged fork features (worktree isolation, issue tokens, number padding) onto
# upstream's branch-template architecture (scope-prefix numbering).
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
    Write-Host "Usage: ./create-new-feature-branch.ps1 [-Json] [-DryRun] [-AllowExistingBranch] [-ShortName <name>] [-Number N] [-Timestamp] [-Issue <value>] [-Worktree|-BranchMode|-IsolationMode <mode>] [-Base <branch>] <feature description>"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Json                 Output in JSON format"
    Write-Host "  -DryRun               Compute branch name without creating the branch"
    Write-Host "  -AllowExistingBranch  Switch to branch if it already exists instead of failing"
    Write-Host "  -ShortName <name>     Provide a custom short name (2-4 words) for the branch"
    Write-Host "  -Number N             Specify branch number manually (overrides auto-detection)"
    Write-Host "  -Timestamp            Use timestamp prefix (YYYYMMDD-HHMMSS) instead of sequential numbering"
    Write-Host "  -Issue <value>        Issue key used by {issue} in branch_template (e.g. PROJ-123 or 1234)"
    Write-Host "  -Worktree             Force worktree isolation (creates a feature-level worktree under .worktrees/<feature>/)"
    Write-Host "  -BranchMode           Force branch isolation (default behavior; the new branch lives in the primary checkout)"
    Write-Host "  -IsolationMode <mode> Set isolation explicitly: 'branch' or 'worktree'"
    Write-Host "  -Base <branch>        Base branch for the new feature branch or worktree (default: origin/main)"
    Write-Host "  -Help                 Show this help message"
    Write-Host ""
    Write-Host "Environment variables:"
    Write-Host "  GIT_BRANCH_NAME        Use this exact branch name, bypassing all prefix/suffix generation"
    Write-Host "  GIT_BRANCH_ISSUE       Issue key fallback when -Issue is not provided"
    Write-Host "  SPECIFY_ISOLATION_MODE Override isolation mode ('branch' or 'worktree')"
    Write-Host ""
    Write-Host "Isolation mode resolution (highest precedence first):"
    Write-Host "  1. -Worktree / -BranchMode (boolean shortcuts)"
    Write-Host "  2. -IsolationMode <mode>"
    Write-Host "  3. SPECIFY_ISOLATION_MODE env var"
    Write-Host "  4. .specify/extensions/git/git-config.yml 'isolation_mode:' key"
    Write-Host "  5. Default: branch"
    Write-Host ""
    Write-Host "Configuration:"
    Write-Host "  branch_template     Optional git-config.yml template with {author}, {app}, {number}, {timestamp}, {issue}, {slug}"
    Write-Host "  branch_prefix       Optional shorthand namespace expanded before {number}-{slug}"
    Write-Host "  issue_format        jira (PROJ-123, uppercased) or numeric (1234); default jira"
    Write-Host "  number_padding      Zero-padding width for {number}; default 3"
    Write-Host ""
    exit 0
}

if (-not $FeatureDescription -or $FeatureDescription.Count -eq 0) {
    Write-Error "Usage: ./create-new-feature-branch.ps1 [-Json] [-DryRun] [-AllowExistingBranch] [-ShortName <name>] [-Number N] [-Timestamp] [-Issue <value>] [-Worktree|-BranchMode|-IsolationMode <mode>] [-Base <branch>] <feature description>"
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
    param(
        [string[]]$Names,
        [string]$ScopePrefix = ''
    )

    [long]$highest = 0
    foreach ($name in $Names) {
        if ($ScopePrefix -and -not $name.StartsWith($ScopePrefix, [System.StringComparison]::Ordinal)) {
            continue
        }
        if ($ScopePrefix) {
            $name = $name.Substring($ScopePrefix.Length)
        }
        $name = ($name -split '/')[-1]
        $hasTimestampPrefix = $name -match '^\d{8}-\d{6}-'
        $hasMalformedTimestamp = ($name -match '^\d{7}-\d{6}-') -or ($name -match '^(?:\d{7}|\d{8})-\d{6}$')
        if ($name -match '^(\d{3,})-' -and -not $hasTimestampPrefix -and -not $hasMalformedTimestamp) {
            [long]$num = 0
            if ([long]::TryParse($matches[1], [ref]$num) -and $num -gt $highest) {
                $highest = $num
            }
        }
    }
    return $highest
}

function Get-HighestNumberFromBranches {
    param([string]$ScopePrefix = '')

    try {
        $branches = git branch -a 2>$null
        if ($LASTEXITCODE -eq 0 -and $branches) {
            $cleanNames = $branches | ForEach-Object {
                $_.Trim() -replace '^[+*]?\s+', '' -replace '^remotes/[^/]+/', ''
            }
            return Get-HighestNumberFromNames -Names $cleanNames -ScopePrefix $ScopePrefix
        }
    } catch {
        Write-Verbose "Could not check Git branches: $_"
    }
    return 0
}

function Get-HighestNumberFromRemoteRefs {
    param([string]$ScopePrefix = '')

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
                    $remoteHighest = Get-HighestNumberFromNames -Names $refNames -ScopePrefix $ScopePrefix
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
        [switch]$SkipFetch,
        [string]$ScopePrefix = ''
    )

    if ($SkipFetch) {
        $highestBranch = Get-HighestNumberFromBranches -ScopePrefix $ScopePrefix
        $highestRemote = Get-HighestNumberFromRemoteRefs -ScopePrefix $ScopePrefix
        $highestBranch = [Math]::Max($highestBranch, $highestRemote)
    } else {
        try {
            git fetch --all --prune 2>$null | Out-Null
        } catch { }
        $highestBranch = Get-HighestNumberFromBranches -ScopePrefix $ScopePrefix
    }

    $highestSpec = Get-HighestNumberFromSpecs -SpecsDir $SpecsDir
    $maxNum = [Math]::Max($highestBranch, $highestSpec)
    return $maxNum + 1
}

function ConvertTo-CleanBranchName {
    param([string]$Name)
    return $Name.ToLower() -replace '[^a-z0-9]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
}

function ConvertTo-BranchToken {
    param(
        [string]$Value,
        [string]$Fallback
    )

    $cleaned = ConvertTo-CleanBranchName -Name $Value
    if ($cleaned) { return $cleaned }
    return $Fallback
}

function Get-GitAuthorToken {
    $author = ''
    if (Get-Command git -ErrorAction SilentlyContinue) {
        try { $author = (git config user.name 2>$null | Out-String).Trim() } catch {}
        if (-not $author) {
            try {
                $email = (git config user.email 2>$null | Out-String).Trim()
                if ($email) { $author = ($email -split '@')[0] }
            } catch {}
        }
    }
    if (-not $author) { $author = if ($env:USER) { $env:USER } elseif ($env:USERNAME) { $env:USERNAME } else { 'unknown' } }
    return ConvertTo-BranchToken -Value $author -Fallback 'unknown'
}

function Get-AppToken {
    return ConvertTo-BranchToken -Value (Split-Path $repoRoot -Leaf) -Fallback 'app'
}

function Read-GitConfigValue {
    param([string]$Key)

    if (-not (Test-Path -LiteralPath $configFile -PathType Leaf)) { return '' }
    $escapedKey = [regex]::Escape($Key)
    foreach ($line in Get-Content -LiteralPath $configFile) {
        # Only match top-level keys (no leading whitespace). This keeps the legacy
        # branch_pattern block from shadowing the new top-level issue_format and
        # number_padding keys.
        if ($line -match "^$escapedKey\s*:\s*(.*)$") {
            $val = ($matches[1] -replace '\s+#.*$', '').Trim()
            $val = $val -replace '^["'']', '' -replace '["'']$', ''
            return $val
        }
    }
    return ''
}

function Resolve-BranchTemplate {
    $template = Read-GitConfigValue -Key 'branch_template'
    if ($template) { return $template }

    $prefix = Read-GitConfigValue -Key 'branch_prefix'
    if (-not $prefix) { return '' }
    if ($prefix.EndsWith('/')) { return "${prefix}{number}-{slug}" }
    return "$prefix/{number}-{slug}"
}

function Get-NumberPadding {
    $padding = Read-GitConfigValue -Key 'number_padding'
    if ($padding -as [int]) { return [int]$padding }
    return 3
}

function Get-IssueFormat {
    $fmt = Read-GitConfigValue -Key 'issue_format'
    if ($fmt -eq 'numeric') { return 'numeric' }
    return 'jira'
}

function Test-IssueKey {
    param(
        [string]$Key,
        [string]$Format
    )
    if ($Format -eq 'numeric') {
        return $Key -match '^[0-9]+$'
    }
    return $Key -match '^[A-Z][A-Z0-9]*-[0-9]+$'
}

function Resolve-IssueToken {
    param([string]$IssueKey)

    $fmt = Get-IssueFormat
    $candidate = if ($IssueKey) { $IssueKey } else { $env:GIT_BRANCH_ISSUE }
    $candidate = $candidate.Trim()

    if ([string]::IsNullOrWhiteSpace($candidate)) { return '' }

    if ($fmt -eq 'jira') {
        $candidate = $candidate.ToUpper()
    }

    if (-not (Test-IssueKey -Key $candidate -Format $fmt)) {
        if ($fmt -eq 'numeric') {
            throw "Invalid numeric issue key '$candidate'. Expected digits only."
        } else {
            throw "Invalid Jira issue key '$candidate'. Expected format like PROJ-123."
        }
    }
    return $candidate
}

function Get-TemplateNumberingToken {
    param([string]$Template)
    if ($Template.Contains('{number}')) { return '{number}' }
    if ($Template.Contains('{timestamp}')) { return '{timestamp}' }
    return ''
}

function Expand-BranchTemplate {
    param(
        [string]$Template,
        [string]$FeatureNum,
        [string]$BranchSuffix,
        [string]$IssueToken
    )

    $numberingToken = Get-TemplateNumberingToken -Template $Template
    $rendered = $Template.Replace('{author}', $authorToken)
    $rendered = $rendered.Replace('{app}', $appToken)
    $rendered = $rendered.Replace('{issue}', $IssueToken)
    $rendered = $rendered.Replace('{slug}', $BranchSuffix)
    if ($numberingToken -eq '{number}') {
        $rendered = $rendered.Replace('{number}', $FeatureNum)
    } elseif ($numberingToken -eq '{timestamp}') {
        $rendered = $rendered.Replace('{timestamp}', $FeatureNum)
    }
    return $rendered
}

function Assert-BranchTemplateValid {
    param(
        [string]$Template,
        [string]$IssueToken
    )

    if (-not $Template) { return }

    $featureSegment = ($Template -split '/')[-1]

    # Exactly one of {number} or {timestamp}.
    $hasNumber = $Template.Contains('{number}')
    $hasTimestamp = $Template.Contains('{timestamp}')
    if ($hasNumber -and $hasTimestamp) {
        throw "branch_template must include exactly one of {number} or {timestamp}, not both."
    }
    if (-not $hasNumber -and -not $hasTimestamp) {
        throw "branch_template must include exactly one of {number} or {timestamp}."
    }

    # {slug} must not appear before the numbering token.
    $numberingToken = Get-TemplateNumberingToken -Template $Template
    $numberIndex = $Template.IndexOf($numberingToken, [System.StringComparison]::Ordinal)
    $slugIndex = $Template.IndexOf('{slug}', [System.StringComparison]::Ordinal)
    if ($slugIndex -ge 0 -and $numberIndex -ge 0 -and $slugIndex -lt $numberIndex) {
        throw "branch_template must not place {slug} before $numberingToken; use {slug} only in the final feature segment."
    }

    # Final segment must start with the numbering token followed by '-'.
    $expectedStart = "$numberingToken-"
    if (-not $featureSegment.StartsWith($expectedStart, [System.StringComparison]::Ordinal)) {
        throw "branch_template must put $expectedStart at the start of the final path segment so generated branches remain valid feature branches."
    }

    # If {issue} is present, ensure an issue value is available.
    if ($Template.Contains('{issue}') -and [string]::IsNullOrWhiteSpace($IssueToken)) {
        throw "branch_template uses {issue}; provide -Issue or set GIT_BRANCH_ISSUE."
    }
}

function New-BranchName {
    param(
        [string]$FeatureNum,
        [string]$BranchSuffix,
        [string]$IssueToken
    )

    if ($branchTemplate) {
        return Expand-BranchTemplate -Template $branchTemplate -FeatureNum $FeatureNum -BranchSuffix $BranchSuffix -IssueToken $IssueToken
    }
    return "$FeatureNum-$BranchSuffix"
}

function Get-BranchScopePrefix {
    param(
        [string]$Template,
        [string]$BranchSuffix,
        [string]$IssueToken
    )

    if (-not $Template) { return '' }
    $numberIndex = $Template.IndexOf('{number}', [System.StringComparison]::Ordinal)
    $timestampIndex = $Template.IndexOf('{timestamp}', [System.StringComparison]::Ordinal)
    $slugIndex = $Template.IndexOf('{slug}', [System.StringComparison]::Ordinal)
    $indexes = @($numberIndex, $timestampIndex, $slugIndex) | Where-Object { $_ -ge 0 } | Sort-Object
    if (-not $indexes) { return '' }
    $prefix = $Template.Substring(0, $indexes[0])
    return Expand-BranchTemplate -Template $prefix -FeatureNum '' -BranchSuffix $BranchSuffix -IssueToken $IssueToken
}

function Get-FeatureNumberFromBranchName {
    param([string]$BranchName)

    $featureSegment = ($BranchName -split '/')[-1]
    if ($featureSegment -match '^(\d{8}-\d{6})-') {
        return $matches[1]
    }
    if ($featureSegment -match '^(\d+)-') {
        return $matches[1]
    }
    return $BranchName
}

function Get-Utf8ByteCount {
    param([string]$Value)
    return [System.Text.Encoding]::UTF8.GetByteCount($Value)
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
        } elseif ($Description -cmatch "\b$($word.ToUpper())\b") {
            # Case-sensitive (-cmatch) to mirror the bash twin's case-sensitive
            # whole-word acronym match: keep a short word only when its UPPERCASE
            # form appears in the original (an acronym). -match is case-insensitive
            # and would keep every short word.
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
                if ($line -match '^isolation_mode\s*:\s*(.+?)\s*(#.*)?$') {
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

# SPECIFY_INIT_DIR is resolved (and validated) by the core resolver. If only the
# minimal git-common.ps1 was loaded, or an older core common.ps1 without the
# resolver was loaded, refuse rather than silently falling back to the wrong root.
if ($env:SPECIFY_INIT_DIR -and -not (Get-Command Resolve-SpecifyInitDir -CommandType Function -ErrorAction SilentlyContinue)) {
    throw "SPECIFY_INIT_DIR requires updated Spec Kit core scripts (common.ps1 with Resolve-SpecifyInitDir), which were not found."
}

# Resolve repository root. When the core scripts are present, Get-RepoRoot
# honors SPECIFY_INIT_DIR (the explicit project override for non-interactive /
# CI use) and hard-fails on an invalid value with no silent fallback.
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
$configFile = Join-Path $repoRoot ".specify/extensions/git/git-config.yml"

$authorToken = Get-GitAuthorToken
$appToken = Get-AppToken
$branchTemplate = Resolve-BranchTemplate
$numberPadding = Get-NumberPadding
$issueFormat = Get-IssueFormat

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

# Check for GIT_BRANCH_NAME env var override (exact branch name, no prefix/suffix)
if ($env:GIT_BRANCH_NAME) {
    $branchName = $env:GIT_BRANCH_NAME
    # Check 244-byte limit (UTF-8) for override names
    $branchNameUtf8ByteCount = Get-Utf8ByteCount -Value $branchName
    if ($branchNameUtf8ByteCount -gt 244) {
        throw "GIT_BRANCH_NAME must be 244 bytes or fewer in UTF-8. Provided value is $branchNameUtf8ByteCount bytes; please supply a shorter override branch name."
    }
    $featureNum = Get-FeatureNumberFromBranchName -BranchName $branchName
} else {
    if ($ShortName) {
        $branchSuffix = ConvertTo-CleanBranchName -Name $ShortName
    } else {
        $branchSuffix = Get-BranchName -Description $featureDesc
    }

    # Resolve issue token if the template uses {issue}.
    $issueToken = ''
    if ($branchTemplate.Contains('{issue}')) {
        $issueToken = Resolve-IssueToken -IssueKey $Issue
        if ([string]::IsNullOrWhiteSpace($issueToken)) {
            throw "branch_template uses {issue}; provide -Issue or set GIT_BRANCH_ISSUE."
        }
    }

    # Validate template now that issue token is resolved.
    Assert-BranchTemplateValid -Template $branchTemplate -IssueToken $issueToken

    if ($Timestamp -and $PSBoundParameters.ContainsKey('Number')) {
        Write-Warning "[specify] Warning: -Number is ignored when -Timestamp is used"
        $Number = 0
    }

    if ($Timestamp) {
        $featureNum = Get-Date -Format 'yyyyMMdd-HHmmss'
        $branchName = New-BranchName -FeatureNum $featureNum -BranchSuffix $branchSuffix -IssueToken $issueToken
    } else {
        $branchScopePrefix = Get-BranchScopePrefix -Template $branchTemplate -BranchSuffix $branchSuffix -IssueToken $issueToken
        if (-not $PSBoundParameters.ContainsKey('Number') -or $Number -eq 0) {
            if ($DryRun -and $hasGit) {
                $Number = Get-NextBranchNumber -SpecsDir $specsDir -SkipFetch -ScopePrefix $branchScopePrefix
            } elseif ($DryRun) {
                $Number = (Get-HighestNumberFromSpecs -SpecsDir $specsDir) + 1
            } elseif ($hasGit) {
                $Number = Get-NextBranchNumber -SpecsDir $specsDir -ScopePrefix $branchScopePrefix
            } else {
                $Number = (Get-HighestNumberFromSpecs -SpecsDir $specsDir) + 1
            }
        }

        $featureNum = ('{0:D' + $numberPadding + '}' -f $Number)
        $branchName = New-BranchName -FeatureNum $featureNum -BranchSuffix $branchSuffix -IssueToken $issueToken
    }
}

$maxBranchLength = 244
if ((Get-Utf8ByteCount -Value $branchName) -gt $maxBranchLength) {
    $originalBranchName = $branchName
    $truncatedSuffix = $branchSuffix
    while ((Get-Utf8ByteCount -Value $branchName) -gt $maxBranchLength -and $truncatedSuffix.Length -gt 0) {
        $truncatedSuffix = $truncatedSuffix.Substring(0, $truncatedSuffix.Length - 1) -replace '-$', ''
        $branchName = New-BranchName -FeatureNum $featureNum -BranchSuffix $truncatedSuffix -IssueToken $issueToken
    }
    if ((Get-Utf8ByteCount -Value $branchName) -gt $maxBranchLength) {
        throw "Branch template prefix exceeds GitHub's 244-byte branch name limit."
    }

    Write-Warning "[specify] Branch name exceeded GitHub's 244-byte limit"
    Write-Warning "[specify] Original: $originalBranchName ($(Get-Utf8ByteCount -Value $originalBranchName) bytes)"
    Write-Warning "[specify] Truncated to: $branchName ($(Get-Utf8ByteCount -Value $branchName) bytes)"
}

# Resolve isolation mode now that $repoRoot is known.
$isolationMode = Resolve-IsolationMode

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
            BRANCH_NAME    = $branchName
            FEATURE_NUM    = $featureNum
            ISOLATION_MODE = 'worktree'
            WORKTREE_PATH  = $worktreePath
            MANIFEST_PATH  = $manifestPath
            cd             = "cd $worktreePath"
        }
        $obj | ConvertTo-Json -Compress
    } else {
        Write-Output "BRANCH_NAME: $branchName"
        Write-Output "FEATURE_NUM: $featureNum"
        Write-Output "ISOLATION_MODE: worktree"
        Write-Output "WORKTREE_PATH: $worktreePath"
        Write-Output "MANIFEST_PATH: $manifestPath"
        Write-Warning "# To persist: `$env:SPECIFY_FEATURE='$branchName'"
    }
    if (-not $Json) {
        Write-Output "cd $worktreePath"
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
        BRANCH_NAME    = $branchName
        FEATURE_NUM    = $featureNum
        ISOLATION_MODE = $isolationMode
    }
    # $hasGit is computed for branch-creation logic only; it is intentionally not
    # emitted so this output contract matches the bash twin: BRANCH_NAME and
    # FEATURE_NUM, plus DRY_RUN (added just below) on dry runs.
    if ($DryRun) {
        $obj | Add-Member -NotePropertyName 'DRY_RUN' -NotePropertyValue $true
    }
    $obj | ConvertTo-Json -Compress
} else {
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "FEATURE_NUM: $featureNum"
    Write-Output "ISOLATION_MODE: $isolationMode"
    if (-not $DryRun) {
        Write-Output "SPECIFY_FEATURE environment variable set to: $branchName"
    }
}
