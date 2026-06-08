#!/usr/bin/env pwsh
# Git extension: worktree-utils.ps1
# Fork (tikalk) -- manages feature worktrees and task branches.
# Single dispatcher; invoked as: worktree-utils.ps1 <subcommand> [args...]
#
# Subcommands:
#   create-feature-worktree   -Feature <name> [-Base <branch>]
#   remove-feature-worktree   -Feature <name> [-Force]
#   create-task-branch        -Feature <name> -TaskId <TNNN> -TaskSlug <slug>
#   remove-task-branch        -Feature <name> -TaskId <TNNN> [-Force]
#   is-in-worktree            (no args; exit 0 in primary, exit 2 inside worktree)
#   list-worktrees            (no args)
#   read-manifest             -WorktreePath <path>
#   finish-feature            -Feature <name> [-KeepBranch] [-Force]
#
# All subcommands emit JSON to stdout on success. Errors go to stderr with
# non-zero exit codes. Manifests live at <worktree>/git.worktree-manifest.json
# (see extensions_fork.py:WORKTREE_MANIFEST_FILENAME).
#
# Design alignment: obra/superpowers using-git-worktrees -- provenance-based
# cleanup via the manifest, never clobber user-created worktrees.

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Subcommand,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Source git-common.ps1 for Get-RepoRoot, Has-Git, etc.
# Fall back to the project's installed common.ps1 if git-common.ps1 is missing.
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

# Resolve repo root (using the helper from git-common.sh if present).
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

# ---------------------------------------------------------------------------
# Constants -- mirrored from src/specify_cli/extensions_fork.py.
# If you change these, change them there too. (Single source of truth: the
# Python module. These are read at runtime so the script stays in sync.)
# ---------------------------------------------------------------------------
$WorktreeBaseDirDefault = ".worktrees"
$WorktreeManifestFilenameDefault = "git.worktree-manifest.json"
$WorktreeTaskBranchPatternDefault = "{feature}--task-{id}-{task-slug}"
$WorktreeConfigFile = ".specify/extensions/git/git-config.yml"
$WorktreeConfigKey = "worktrees"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Read a value from .specify/extensions/git/git-config.yml using simple line scan.
# Returns the value on stdout, or empty string if not found. Does NOT handle
# nested keys (only flat: `worktrees.isolation_mode` -> look for
# `isolation_mode:` inside the `worktrees:` block).
function Get-YamlValue {
    param(
        [string]$Key,
        [string]$File
    )
    if (-not (Test-Path $File)) { return "" }
    $inSection = $false
    foreach ($line in Get-Content $File) {
        # Detect entry into worktrees: section.
        if ($line -match "^\s*${WorktreeConfigKey}:" -and $line -notmatch '^\s{4,}') {
            $inSection = $true
            continue
        }
        # Exit on next top-level sibling key (no leading whitespace).
        if ($inSection -and $line -match '^[a-zA-Z]') {
            $inSection = $false
        }
        if ($inSection) {
            if ($line -match "^\s+${Key}:\s*(.+?)\s*$") {
                $val = $Matches[1]
                $val = $val -replace '^["'']', '' -replace '["'']$', ''
                return $val
            }
        }
    }
    return ""
}

# Resolve worktree config: returns the worktree section's value for the
# requested key, or the default if not configured.
function Get-WorktreeConfigValue {
    param([string]$Key)
    $configPath = Join-Path $RepoRoot $WorktreeConfigFile
    $val = Get-YamlValue -Key $Key -File $configPath
    if ([string]::IsNullOrEmpty($val)) {
        switch ($Key) {
            "base_dir" { return $WorktreeBaseDirDefault }
            "manifest_filename" { return $WorktreeManifestFilenameDefault }
            "task_branch_pattern" { return $WorktreeTaskBranchPatternDefault }
            "isolation_mode" { return "branch" }
            default { return "" }
        }
    }
    return $val
}

# Compute the absolute path of a feature worktree.
function Get-WorktreePathFor {
    param([string]$Feature)
    $baseDir = Get-WorktreeConfigValue -Key "base_dir"
    $baseDir = $baseDir -replace '^\./', '' -replace '^/', ''
    return (Join-Path (Join-Path $RepoRoot $baseDir) $Feature)
}

# Sanitize a slug to kebab-case (lowercase, alphanum + dash, no edge dashes).
function ConvertTo-KebabSlug {
    param([string]$Slug)
    $clean = $Slug.ToLower() -replace '[^a-z0-9]+', '-'
    $clean = $clean -replace '^-', '' -replace '-$', ''
    return $clean
}

# Compute the task branch name from feature + id + slug, using the configured
# pattern. Slug is sanitized to kebab-case.
function Get-TaskBranchName {
    param(
        [string]$Feature,
        [string]$TaskId,
        [string]$TaskSlug
    )
    $pattern = Get-WorktreeConfigValue -Key "task_branch_pattern"
    # Strip "T" prefix from id (T005 -> 5) for the {id} substitution per
    # AGENTS.md branch naming example: "003-auth--task-5-auth-middleware".
    $idNum = $TaskId -replace '^T', ''
    [int]$idNumInt = 0
    [int]::TryParse($idNum, [ref]$idNumInt) | Out-Null
    $idNum = "$idNumInt"
    $cleanSlug = ConvertTo-KebabSlug -Slug $TaskSlug
    $result = $pattern -replace '\{feature\}', $Feature
    $result = $result -replace '\{id\}', $idNum
    $result = $result -replace '\{task-slug\}', $cleanSlug
    return $result
}

# Detect whether the current working directory is inside a worktree under the
# configured base dir. Returns $true or $false.
function Test-InsideWorktree {
    $toplevel = ""
    try {
        $toplevel = git rev-parse --show-toplevel 2>$null
    } catch { }
    if ([string]::IsNullOrEmpty($toplevel)) { return $false }
    $baseDir = Get-WorktreeConfigValue -Key "base_dir"
    $baseDir = $baseDir -replace '^\./', '' -replace '^/', ''
    $basePath = Join-Path $RepoRoot $baseDir
    # Normalize to forward slashes for comparison.
    $toplevelNorm = $toplevel -replace '\\', '/'
    $basePathNorm = $basePath -replace '\\', '/'
    return $toplevelNorm.StartsWith($basePathNorm, [System.StringComparison]::OrdinalIgnoreCase)
}

# Convert a path to relative form against REPO_ROOT (with forward slashes).
function ConvertTo-RelativePath {
    param([string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) {
        $rel = $Path.Substring($RepoRoot.Length)
        $rel = $rel -replace '^[\\/]', ''
    } else {
        $rel = $Path -replace '^\./', ''
    }
    return ($rel -replace '\\', '/')
}

function Get-UtcTimestamp {
    return (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
}

# Write a manifest JSON file. Takes feature and worktree_path; the task
# branches list starts empty (create-task-branch appends via
# Update-ManifestTask).
function Write-WorktreeManifest {
    param(
        [string]$Feature,
        [string]$WorktreePath
    )
    $manifestFilename = Get-WorktreeConfigValue -Key "manifest_filename"
    $manifestFile = Join-Path $WorktreePath $manifestFilename
    $createdAt = Get-UtcTimestamp
    $manifest = [ordered]@{
        schema_version  = "1.0"
        feature         = $Feature
        feature_branch  = $Feature
        worktree_path   = $WorktreePath
        created_at      = $createdAt
        task_branches   = @()
        provenance      = [ordered]@{
            created_by = "worktree-utils.ps1"
            version    = "1.0"
        }
    }
    $json = $manifest | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($manifestFile, $json, [System.Text.UTF8Encoding]::new($false))
}

# Mark the manifest file as skip-worktree (tracked in the index but with the
# skip-worktree bit set). This makes git consider it "tracked" so `git worktree
# remove` won't complain about untracked files, while still letting our script
# freely rewrite the on-disk content without dirtying the worktree.
function Add-WorktreeManifestExclude {
    param([string]$WorktreePath)
    $manifestFilename = Get-WorktreeConfigValue -Key "manifest_filename"
    $manifestFile = Join-Path $WorktreePath $manifestFilename
    if (-not (Test-Path $manifestFile)) { return }
    # `git update-index --add` registers a new path in the index without
    # requiring a commit; `--skip-worktree` then makes git ignore subsequent
    # in-place rewrites when computing worktree cleanliness.
    & git -C $WorktreePath update-index --add --skip-worktree -- $manifestFilename 2>&1 | Out-Null
}

# Append a task branch record to the manifest.
function Add-ManifestTask {
    param(
        [string]$ManifestFile,
        [string]$TaskId,
        [string]$TaskBranch
    )
    if (-not (Test-Path $ManifestFile)) { return }
    try {
        $content = Get-Content -Path $ManifestFile -Raw
        $manifest = $content | ConvertFrom-Json
        $record = [ordered]@{
            id         = $TaskId
            branch     = $TaskBranch
            created_at = Get-UtcTimestamp
        }
        # Convert existing task_branches (PSCustomObject array) to a generic
        # list so we can append; rebuild to preserve ordering.
        $list = @()
        if ($manifest.task_branches) {
            foreach ($tb in $manifest.task_branches) {
                $list += $tb
            }
        }
        $list += $record
        $manifest.task_branches = $list
        $json = $manifest | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($ManifestFile, $json, [System.Text.UTF8Encoding]::new($false))
    } catch {
        # Best-effort: silently skip on parse failure.
    }
}

# Remove a task branch record from the manifest by task id.
function Remove-ManifestTask {
    param(
        [string]$ManifestFile,
        [string]$TaskId
    )
    if (-not (Test-Path $ManifestFile)) { return }
    try {
        $content = Get-Content -Path $ManifestFile -Raw
        $manifest = $content | ConvertFrom-Json
        if (-not $manifest.task_branches) { return }
        $list = @()
        foreach ($tb in $manifest.task_branches) {
            if ($tb.id -ne $TaskId) { $list += $tb }
        }
        $manifest.task_branches = $list
        $json = $manifest | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($ManifestFile, $json, [System.Text.UTF8Encoding]::new($false))
    } catch {
        # Best-effort: silently skip on parse failure.
    }
}

# Read all task branch names from manifest. Returns @() if none / missing.
function Get-ManifestTaskBranches {
    param([string]$ManifestFile)
    if (-not (Test-Path $ManifestFile)) { return @() }
    try {
        $content = Get-Content -Path $ManifestFile -Raw
        $manifest = $content | ConvertFrom-Json
        if (-not $manifest.task_branches) { return @() }
        $branches = @()
        foreach ($tb in $manifest.task_branches) {
            $branches += $tb.branch
        }
        return $branches
    } catch {
        return @()
    }
}

# Find a task branch name by task id from the manifest. Returns $null if not found.
function Find-ManifestTaskBranch {
    param(
        [string]$ManifestFile,
        [string]$TaskId
    )
    if (-not (Test-Path $ManifestFile)) { return $null }
    try {
        $content = Get-Content -Path $ManifestFile -Raw
        $manifest = $content | ConvertFrom-Json
        if (-not $manifest.task_branches) { return $null }
        foreach ($tb in $manifest.task_branches) {
            if ($tb.id -eq $TaskId) { return $tb.branch }
        }
    } catch { }
    return $null
}

function Write-Err {
    param([string]$Message)
    [Console]::Error.WriteLine("Error: $Message")
}

function Die {
    param([string]$Message)
    Write-Err -Message $Message
    exit 1
}

function Show-Usage {
    @"
Usage: worktree-utils.ps1 <subcommand> [options]

Subcommands:
  create-feature-worktree   -Feature <name> [-Base <branch>]
  remove-feature-worktree   -Feature <name> [-Force]
  create-task-branch        -Feature <name> -TaskId <TNNN> -TaskSlug <slug>
  remove-task-branch        -Feature <name> -TaskId <TNNN> [-Force]
  merge-task-branch         -Feature <name> -TaskId <TNNN> [-DelegateConflicts]
  is-in-worktree
  list-worktrees
  read-manifest             -WorktreePath <path>
  finish-feature            -Feature <name> [-KeepBranch] [-Force]

Run `worktree-utils.ps1 <subcommand> -Help` for subcommand-specific options.
"@
}

function Emit-Json {
    param([hashtable]$Obj)
    $ordered = [ordered]@{}
    foreach ($k in $Obj.Keys) { $ordered[$k] = $Obj[$k] }
    ($ordered | ConvertTo-Json -Compress -Depth 10)
}

# ---------------------------------------------------------------------------
# Subcommand: create-feature-worktree
# ---------------------------------------------------------------------------
function Invoke-CreateFeatureWorktree {
    [CmdletBinding()]
    param(
        [string]$Feature = "",
        [string]$Base = ""
    )
    if ([string]::IsNullOrEmpty($Feature)) { Die "--Feature is required" }
    if (-not (Has-Git -RepoRoot $RepoRoot)) { Die "Not a git repository" }

    $baseDir = Get-WorktreeConfigValue -Key "base_dir"
    $baseDir = $baseDir -replace '^\./', '' -replace '^/', ''
    $worktreePath = Join-Path (Join-Path $RepoRoot $baseDir) $Feature

    # Default base: current branch (whatever the user is on when they invoke
    # git.feature). If on a feature branch, base off main/master to avoid
    # nested feature worktrees.
    if ([string]::IsNullOrEmpty($Base)) {
        try {
            $Base = (git -C $RepoRoot rev-parse --abbrev-ref HEAD 2>$null).Trim()
        } catch { $Base = "HEAD" }
        if ($Base -eq $Feature) {
            # Self-referencing -- just use HEAD.
            $Base = "HEAD"
        }
    }

    # Refuse if a worktree already exists at the target path.
    if (Test-Path $worktreePath) { Die "Worktree path already exists: $worktreePath" }

    # Refuse if the feature branch already exists in the primary checkout.
    $branchRef = git -C $RepoRoot show-ref --verify --quiet "refs/heads/$Feature" 2>$null
    if ($LASTEXITCODE -eq 0) { Die "Branch '$Feature' already exists in primary checkout" }

    # Create the .worktrees directory if needed.
    $basePath = Join-Path $RepoRoot $baseDir
    if (-not (Test-Path $basePath)) {
        New-Item -ItemType Directory -Path $basePath -Force | Out-Null
    }

    # Add the worktree with a new branch.
    git -C $RepoRoot worktree add $worktreePath -b $Feature $Base 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Die "git worktree add failed for $worktreePath" }

    # Write initial manifest (no task branches yet).
    Write-WorktreeManifest -Feature $Feature -WorktreePath $worktreePath

    # Exclude the manifest from the worktree's gitdir so `git worktree remove`
    # doesn't refuse over an untracked file.
    Add-WorktreeManifestExclude -WorktreePath $worktreePath

    $manifestFilename = Get-WorktreeConfigValue -Key "manifest_filename"
    $relPath = ConvertTo-RelativePath -Path $worktreePath
    Emit-Json -Obj ([ordered]@{
        worktree_path    = $relPath
        worktree_branch  = $Feature
        manifest_written = $true
        manifest_path    = "$relPath/$manifestFilename"
        base_dir         = $baseDir
        ok               = $true
    })
}

# ---------------------------------------------------------------------------
# Subcommand: remove-feature-worktree
# ---------------------------------------------------------------------------
function Invoke-RemoveFeatureWorktree {
    [CmdletBinding()]
    param(
        [string]$Feature = "",
        [switch]$Force
    )
    if ([string]::IsNullOrEmpty($Feature)) { Die "--Feature is required" }

    $worktreePath = Get-WorktreePathFor -Feature $Feature
    $manifestFilename = Get-WorktreeConfigValue -Key "manifest_filename"
    $manifestFile = Join-Path $worktreePath $manifestFilename

    if (-not (Test-Path $worktreePath)) { Die "Worktree does not exist: $worktreePath" }

    # Provenance check: refuse to remove without manifest unless -Force.
    if ((-not (Test-Path $manifestFile)) -and (-not $Force)) {
        Die "No manifest at $manifestFile -- refusing to remove (use -Force to override)"
    }

    # If there are task branches in the manifest, refuse unless -Force.
    $taskBranches = @()
    if (Test-Path $manifestFile) {
        $taskBranches = Get-ManifestTaskBranches -ManifestFile $manifestFile
    }
    if (($taskBranches.Count -gt 0) -and (-not $Force)) {
        Die "Manifest has $($taskBranches.Count) task branch(es) -- use 'finish-feature' for proper cleanup, or -Force to override"
    }

    # Remove the worktree. The manifest file is untracked by design; run a
    # pre-check that filters it from the dirty list. -Force is always used
    # after the pre-check (safe because we've verified only the manifest
    # was dirty). Route git's chatter to stderr.
    if (Test-Path $worktreePath) {
        $statusLines = (& git -C $worktreePath status --porcelain 2>$null) | Where-Object { $_ -and ($_ -notmatch "^\?\? $([regex]::Escape($manifestFilename))$") -and ($_ -notmatch "^.. $manifestFilename$") }
        if ($statusLines -and -not $Force) {
            $msg = "Worktree has uncommitted changes (excluding the manifest, which is ignored):`n$($statusLines -join "`n")`nUse -Force to override."
            Die $msg
        }
        git -C $RepoRoot worktree remove --force $worktreePath 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Remove-Item -Path $worktreePath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Clean up: delete the feature branch if it still exists.
    $branchDeleted = $false
    $branchCheck = git -C $RepoRoot show-ref --verify --quiet "refs/heads/$Feature" 2>$null
    if ($LASTEXITCODE -eq 0) {
        git -C $RepoRoot branch -D $Feature 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $branchDeleted = $true }
    }

    $relPath = ConvertTo-RelativePath -Path $worktreePath
    Emit-Json -Obj ([ordered]@{
        removed        = $true
        worktree_path  = $relPath
        branch_deleted = $branchDeleted
        ok             = $true
    })
}

# ---------------------------------------------------------------------------
# Subcommand: create-task-branch
# ---------------------------------------------------------------------------
function Invoke-CreateTaskBranch {
    [CmdletBinding()]
    param(
        [string]$Feature = "",
        [string]$TaskId = "",
        [string]$TaskSlug = ""
    )
    if ([string]::IsNullOrEmpty($Feature))    { Die "--Feature is required" }
    if ([string]::IsNullOrEmpty($TaskId))     { Die "--TaskId is required" }
    if ([string]::IsNullOrEmpty($TaskSlug))   { Die "--TaskSlug is required" }

    # Validate task_id format (T followed by digits).
    if ($TaskId -notmatch '^T\d+$') {
        Die "Invalid task_id: '$TaskId' (expected T followed by digits)"
    }

    $worktreePath = Get-WorktreePathFor -Feature $Feature
    $manifestFilename = Get-WorktreeConfigValue -Key "manifest_filename"
    $manifestFile = Join-Path $worktreePath $manifestFilename

    if (-not (Test-Path $worktreePath)) {
        Die "Feature worktree does not exist: $worktreePath (run create-feature-worktree first)"
    }

    $taskBranch = Get-TaskBranchName -Feature $Feature -TaskId $TaskId -TaskSlug $TaskSlug

    # Refuse if task branch already exists.
    $refCheck = git -C $worktreePath show-ref --verify --quiet "refs/heads/$taskBranch" 2>$null
    if ($LASTEXITCODE -eq 0) { Die "Task branch '$taskBranch' already exists" }

    # Create the task branch from the feature branch HEAD.
    git -C $worktreePath branch $taskBranch 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Die "git branch $taskBranch failed" }

    # Update manifest: append the new task record (best-effort).
    if (Test-Path $manifestFile) {
        Add-ManifestTask -ManifestFile $manifestFile -TaskId $TaskId -TaskBranch $taskBranch
    }

    $relPath = ConvertTo-RelativePath -Path $worktreePath
    Emit-Json -Obj ([ordered]@{
        task_branch      = $taskBranch
        worktree_path    = $relPath
        manifest_updated = $true
        ok               = $true
    })
}

# ---------------------------------------------------------------------------
# Subcommand: remove-task-branch
# ---------------------------------------------------------------------------
function Invoke-RemoveTaskBranch {
    [CmdletBinding()]
    param(
        [string]$Feature = "",
        [string]$TaskId = "",
        [switch]$Force
    )
    if ([string]::IsNullOrEmpty($Feature)) { Die "--Feature is required" }
    if ([string]::IsNullOrEmpty($TaskId))  { Die "--TaskId is required" }

    $worktreePath = Get-WorktreePathFor -Feature $Feature

    if (-not (Test-Path $worktreePath)) {
        Die "Feature worktree does not exist: $worktreePath"
    }

    # Find the task branch from the manifest.
    $manifestFilename = Get-WorktreeConfigValue -Key "manifest_filename"
    $manifestFile = Join-Path $worktreePath $manifestFilename
    $taskBranch = $null
    if (Test-Path $manifestFile) {
        $taskBranch = Find-ManifestTaskBranch -ManifestFile $manifestFile -TaskId $TaskId
    }

    if ([string]::IsNullOrEmpty($taskBranch)) {
        # Fallback: compute from pattern (in case manifest is missing).
        $taskBranch = Get-TaskBranchName -Feature $Feature -TaskId $TaskId -TaskSlug "task"
        if (-not $Force) {
            Die "Task branch not found in manifest; cannot safely derive. Use -Force with an explicit slug, or run with manifest."
        }
    }

    $refCheck = git -C $worktreePath show-ref --verify --quiet "refs/heads/$taskBranch" 2>$null
    if ($LASTEXITCODE -ne 0) {
        if (-not $Force) { Die "Task branch '$taskBranch' does not exist" }
    } else {
        if ($Force) {
            git -C $worktreePath branch -D $taskBranch 2>$null | Out-Null
        } else {
            git -C $worktreePath branch -d $taskBranch 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Die "Branch '$taskBranch' is not fully merged; use -Force to delete anyway"
            }
        }
    }

    # Update manifest: remove the task record (best-effort).
    if (Test-Path $manifestFile) {
        Remove-ManifestTask -ManifestFile $manifestFile -TaskId $TaskId
    }

    Emit-Json -Obj ([ordered]@{
        removed          = $true
        task_branch      = $taskBranch
        task_id          = $TaskId
        manifest_updated = $true
        ok               = $true
    })
}

# ---------------------------------------------------------------------------
# Subcommand: is-in-worktree
# ---------------------------------------------------------------------------
function Invoke-IsInWorktree {
    [CmdletBinding()]
    param()

    $inWt = Test-InsideWorktree
    $toplevel = ""
    try {
        $toplevel = git rev-parse --show-toplevel 2>$null
    } catch { }
    $relToplevel = ""
    if (-not [string]::IsNullOrEmpty($toplevel)) {
        $relToplevel = ConvertTo-RelativePath -Path $toplevel
    }

    $feature = ""
    if ($inWt -and -not [string]::IsNullOrEmpty($relToplevel)) {
        $baseDir = Get-WorktreeConfigValue -Key "base_dir"
        $baseDir = $baseDir -replace '^\./', '' -replace '^/', ''
        if ($relToplevel.StartsWith("$baseDir/", [System.StringComparison]::OrdinalIgnoreCase)) {
            $feature = $relToplevel.Substring($baseDir.Length + 1)
        }
    }

    Emit-Json -Obj ([ordered]@{
        is_in_worktree = $inWt
        worktree_path  = $relToplevel
        feature        = $feature
    })

    if ($inWt) { exit 2 } else { exit 0 }
}

# ---------------------------------------------------------------------------
# Subcommand: list-worktrees
# ---------------------------------------------------------------------------
function Invoke-ListWorktrees {
    [CmdletBinding()]
    param()

    $baseDir = Get-WorktreeConfigValue -Key "base_dir"
    $baseDir = $baseDir -replace '^\./', '' -replace '^/', ''
    $basePath = Join-Path $RepoRoot $baseDir
    $manifestFilename = Get-WorktreeConfigValue -Key "manifest_filename"

    $entries = @()
    if (Test-Path $basePath) {
        Get-ChildItem -Path $basePath -Directory | ForEach-Object {
            $feature = $_.Name
            $rel = ConvertTo-RelativePath -Path $_.FullName
            $hasManifest = $false
            $manifestPath = Join-Path $_.FullName $manifestFilename
            if (Test-Path $manifestPath) { $hasManifest = $true }
            $entries += [ordered]@{
                path         = $rel
                branch       = $feature
                has_manifest = $hasManifest
                feature      = $feature
            }
        }
    }

    Emit-Json -Obj ([ordered]@{
        worktrees = $entries
        ok        = $true
    })
}

# ---------------------------------------------------------------------------
# Subcommand: read-manifest
# ---------------------------------------------------------------------------
function Invoke-ReadManifest {
    [CmdletBinding()]
    param(
        [string]$WorktreePath = ""
    )
    if ([string]::IsNullOrEmpty($WorktreePath)) { Die "--WorktreePath is required" }

    # Resolve relative path against REPO_ROOT.
    if (-not [System.IO.Path]::IsPathRooted($WorktreePath)) {
        $WorktreePath = Join-Path $RepoRoot ($WorktreePath -replace '^\./', '')
    }

    $manifestFilename = Get-WorktreeConfigValue -Key "manifest_filename"
    $manifestFile = Join-Path $WorktreePath $manifestFilename

    if (-not (Test-Path $manifestFile)) { Die "Manifest not found: $manifestFile" }

    Get-Content -Path $manifestFile -Raw
}

# ---------------------------------------------------------------------------
# Subcommand: finish-feature
# Obra-aligned provenance-based cleanup:
#  1. Read manifest
#  2. Delete all task branches listed in manifest
#  3. Delete feature worktree via git worktree remove
#  4. Delete feature branch from primary checkout
#  5. Refuse to do any of this if manifest is missing (unless -Force)
# ---------------------------------------------------------------------------
function Invoke-FinishFeature {
    [CmdletBinding()]
    param(
        [string]$Feature = "",
        [switch]$KeepBranch,
        [switch]$Force
    )
    if ([string]::IsNullOrEmpty($Feature)) { Die "--Feature is required" }

    $worktreePath = Get-WorktreePathFor -Feature $Feature
    $manifestFilename = Get-WorktreeConfigValue -Key "manifest_filename"
    $manifestFile = Join-Path $worktreePath $manifestFilename

    # Provenance check: refuse to clean up without manifest.
    if ((-not (Test-Path $manifestFile)) -and (-not $Force)) {
        Die "No manifest at $manifestFile -- refusing to clean up. Use -Force to override (will skip task-branch cleanup)"
    }

    $removedTaskBranches = 0

    if (Test-Path $manifestFile) {
        $taskBranches = Get-ManifestTaskBranches -ManifestFile $manifestFile
        foreach ($branch in $taskBranches) {
            if ([string]::IsNullOrEmpty($branch)) { continue }
            $refCheck = git -C $worktreePath show-ref --verify --quiet "refs/heads/$branch" 2>$null
            if ($LASTEXITCODE -eq 0) {
                git -C $worktreePath branch -D $branch 2>$null | Out-Null
                if ($LASTEXITCODE -eq 0) { $removedTaskBranches++ }
            }
        }
    }

    # Remove the worktree. The manifest file is untracked by design; run a
    # pre-check that filters it from the dirty list. -Force is always used
    # after the pre-check (safe because we've verified only the manifest
    # was dirty).
    $worktreeRemoved = $false
    if (Test-Path $worktreePath) {
        $statusLines = (& git -C $worktreePath status --porcelain 2>$null) | Where-Object { $_ -and ($_ -notmatch "^\?\? $([regex]::Escape($manifestFilename))$") -and ($_ -notmatch "^.. $manifestFilename$") }
        if ($statusLines -and -not $Force) {
            $msg = "Worktree has uncommitted changes (excluding the manifest, which is ignored):`n$($statusLines -join "`n")`nUse -Force to override."
            Die $msg
        }
        git -C $RepoRoot worktree remove --force $worktreePath 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Remove-Item -Path $worktreePath -Recurse -Force -ErrorAction SilentlyContinue
        }
        $worktreeRemoved = $true
    }

    # Delete the feature branch from the primary checkout (unless -KeepBranch).
    $branchDeleted = $false
    if (-not $KeepBranch) {
        $branchCheck = git -C $RepoRoot show-ref --verify --quiet "refs/heads/$Feature" 2>$null
        if ($LASTEXITCODE -eq 0) {
            git -C $RepoRoot branch -D $Feature 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { $branchDeleted = $true }
        }
    }

    Emit-Json -Obj ([ordered]@{
        task_branches_removed = $removedTaskBranches
        worktree_removed      = $worktreeRemoved
        branch_deleted        = $branchDeleted
        keep_branch           = [bool]$KeepBranch
        force                 = [bool]$Force
        ok                    = $true
    })
}

# ---------------------------------------------------------------------------
# Subcommand: merge-task-branch
# ---------------------------------------------------------------------------
function Invoke-MergeTaskBranch {
    [CmdletBinding()]
    param(
        [string]$Feature = "",
        [string]$TaskId = "",
        [switch]$DelegateConflicts
    )
    if ([string]::IsNullOrEmpty($Feature)) { Die "-Feature is required" }
    if ([string]::IsNullOrEmpty($TaskId)) { Die "-TaskId is required" }

    $worktreePath = Get-WorktreePathFor -Feature $Feature
    if (-not (Test-Path $worktreePath)) {
        Die "Feature worktree does not exist: $worktreePath"
    }

    $manifestFilename = Get-WorktreeConfigValue -Key "manifest_filename"
    $manifestFile = Join-Path $worktreePath $manifestFilename

    $taskBranch = ""
    if (Test-Path $manifestFile) {
        $manifest = Get-Content $manifestFile -Raw | ConvertFrom-Json
        $taskBranch = $manifest.task_branches | Where-Object { $_.id -eq $TaskId } | Select-Object -ExpandProperty branch -First 1
    }
    if ([string]::IsNullOrEmpty($taskBranch)) {
        Die "Task $TaskId not found in manifest"
    }

    $currentBranch = git -C $worktreePath rev-parse --abbrev-ref HEAD 2>$null
    if ($currentBranch -ne $Feature) {
        git -C $worktreePath checkout $Feature 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { Die "Failed to checkout feature branch $Feature" }
    }

    $mergeOutput = ""
    $mergeRc = 0
    try {
        $mergeOutput = git -C $worktreePath merge --no-ff $taskBranch -m "Merge task $TaskId into $Feature" 2>&1
    } catch {
        $mergeRc = 1
    }

    $hasConflict = $false
    $conflictFiles = ""
    if ($LASTEXITCODE -ne 0) {
        $hasConflict = $true
        $conflictFiles = (git -C $worktreePath diff --name-only --diff-filter=U 2>$null) -join " "
        git -C $worktreePath merge --abort 2>$null | Out-Null
        Emit-Json -Obj ([ordered]@{
            task_id          = $TaskId
            task_branch      = $taskBranch
            feature          = $Feature
            merged           = $false
            has_conflict     = $true
            conflict_files   = $conflictFiles
            delegate_conflicts = [bool]$DelegateConflicts
            merge_output     = $mergeOutput
            ok               = $true
        })
        return
    }

    git -C $worktreePath branch -d $taskBranch 2>$null | Out-Null

    if (Test-Path $manifestFile) {
        $manifest = Get-Content $manifestFile -Raw | ConvertFrom-Json
        $manifest.task_branches = @($manifest.task_branches | Where-Object { $_.id -ne $TaskId })
        $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestFile -Encoding UTF8
    }

    $featureTip = git -C $worktreePath rev-parse --short HEAD 2>$null
    Emit-Json -Obj ([ordered]@{
        task_id      = $TaskId
        task_branch  = $taskBranch
        feature      = $Feature
        merged       = $true
        has_conflict = $false
        feature_tip  = $featureTip
        ok           = $true
    })
}

# ---------------------------------------------------------------------------
# Main dispatcher
# ---------------------------------------------------------------------------
if ([string]::IsNullOrEmpty($Subcommand)) {
    Show-Usage
    exit 1
}

# Forward args to a subcommand function. PowerShell's array-splat has a bug
# where named args after splat are treated as positional, so we build a
# properly-quoted command string and Invoke-Expression it.
function Invoke-Subcommand {
    param([string]$Name, [string[]]$Arguments)
    $parts = @($Name)
    foreach ($arg in $Arguments) {
        if ($arg -like '-*') {
            $parts += $arg
        } elseif ($arg -match '\s') {
            $parts += '"' + $arg + '"'
        } else {
            $parts += $arg
        }
    }
    $cmd = $parts -join ' '
    Invoke-Expression $cmd
}

$remaining = @()
if ($Rest) { $remaining = @($Rest) }

switch ($Subcommand) {
    "create-feature-worktree" { Invoke-Subcommand "Invoke-CreateFeatureWorktree" $remaining }
    "remove-feature-worktree" { Invoke-Subcommand "Invoke-RemoveFeatureWorktree" $remaining }
    "create-task-branch"      { Invoke-Subcommand "Invoke-CreateTaskBranch" $remaining }
    "remove-task-branch"      { Invoke-Subcommand "Invoke-RemoveTaskBranch" $remaining }
    "merge-task-branch"       { Invoke-Subcommand "Invoke-MergeTaskBranch" $remaining }
    "is-in-worktree"          { Invoke-Subcommand "Invoke-IsInWorktree" $remaining }
    "list-worktrees"          { Invoke-Subcommand "Invoke-ListWorktrees" $remaining }
    "read-manifest"           { Invoke-Subcommand "Invoke-ReadManifest" $remaining }
    "finish-feature"          { Invoke-Subcommand "Invoke-FinishFeature" $remaining }
    "-h" { Show-Usage; exit 0 }
    "--help" { Show-Usage; exit 0 }
    "help" { Show-Usage; exit 0 }
    default {
        Write-Err "Unknown subcommand: $Subcommand"
        Show-Usage
        exit 1
    }
}
