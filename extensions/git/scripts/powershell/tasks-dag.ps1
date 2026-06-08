#!/usr/bin/env pwsh
# Git extension: tasks-dag.ps1
# Fork (tikalk) -- parses tasks.md into a DAG, classifies parallel eligibility,
# and reports coalescable runs. Emits tasks_dag.json alongside tasks.md.
# Single dispatcher; invoked as: tasks-dag.ps1 <subcommand> [args...]
#
# Subcommands:
#   generate     -TasksMd <path> [-Dag <path>] [-Feature <name>]
#   validate     -Dag <path>
#   show         -Dag <path>
#   classify     -TaskId <TNNN> -TasksMd <path>
#   coalesce     -TasksMd <path> [-Dag <path>]
#
# All subcommands emit JSON to stdout on success. Errors go to stderr with
# non-zero exit codes. DAG schema version: 1.0
#
# The output DAG is the source of truth for `git.task-merge` (Phase 0 of
# implement.md reads this file) and the [P] classification lives here, not in
# tasks.md (which is a human-readable checklist).
#
# PowerShell parity of tasks-dag.sh. The DAG analyzer is git-agnostic; the
# only git dependency is Get-RepoRoot (loaded best-effort from git-common.ps1).
#
# NOTE: PowerShell [CmdletBinding()] requires single-dash parameter names
# (e.g. -TasksMd, not --tasks-md). The bash version uses --tasks-md; this
# PS1 uses -TasksMd. The bash version's --help inside subcommand bodies is
# not present here -- use `tasks-dag.ps1 help` to print the main usage.
# For per-subcommand usage, refer to the header above or the bash equivalent.

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Subcommand,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Source git-common.ps1 for Get-RepoRoot, etc. Best-effort: DAG analysis
# is git-agnostic, so missing common.ps1 is not fatal.
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
# Optional: not failing if common is missing -- DAG analyzer is git-agnostic.

# Resolve repo root (using the helper if present).
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
# Constants -- mirrored from tasks-dag.sh. Single source of truth is the
# bash file; the PS1 must stay in sync.
# ---------------------------------------------------------------------------
$DagSchemaVersion = "1.0"
$DagDefaultFilename = "tasks_dag.json"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Err { param([string]$Msg) [Console]::Error.WriteLine("Error: $Msg") }
function Die { param([string]$Msg) Write-Err $Msg; exit 1 }

function Show-Usage {
    @"
Usage: tasks-dag.ps1 <subcommand> [args...]

Subcommands:
  generate     --tasks-md <path> [--dag <path>] [--feature <name>]
  validate     --dag <path>
  show         --dag <path>
  classify     --task-id <TNNN> --tasks-md <path>
  coalesce     --tasks-md <path> [--dag <path>]
"@
}

# Strip markdown checkbox, ID, [P] marker, [Story] label from a task line.
# Writes a single line: id|story|is_parallel|description
# Returns $true on match, $false otherwise.
function Parse-TaskLine {
    param([string]$Line)

    # Pattern: - [ ] TNNN [P] [SYNC|ASYNC] [USn] Description
    if ($Line -notmatch '^\-\s+\[[ x]\]\s+(T\d+)\s+(.+)$') {
        return $null
    }
    $id = $Matches[1]
    $rest = $Matches[2]
    $isParallel = 0
    $story = ""
    $execMode = ""
    $desc = $rest

    # [P] marker
    if ($rest -match '^\[P\]\s+(.+)$') {
        $isParallel = 1
        $rest = $Matches[1]
    }
    # [SYNC] or [ASYNC] marker
    if ($rest -match '^\[(SYNC|ASYNC)\]\s+(.+)$') {
        $execMode = $Matches[1]
        $rest = $Matches[2]
    }
    # [USn] story label
    if ($rest -match '^\[(US\d+)\]\s+(.+)$') {
        $story = $Matches[1]
        $rest = $Matches[2]
    }
    $desc = $rest.TrimEnd()
    return "$id|$story|$isParallel|$execMode|$desc"
}

# Extract file paths from a task description.
# Looks for patterns like "in path/to/file.ext", "to path/to/file.ext",
# and bare paths ending in known extensions.
# Returns an array of unique file paths.
function Extract-Files {
    param([string]$Desc)
    if ([string]::IsNullOrEmpty($Desc)) { return @() }
    $pattern = '[a-zA-Z0-9_./-]+\.(py|sh|ps1|js|ts|tsx|jsx|go|rs|java|rb|php|c|cpp|h|hpp|cs|swift|kt|mjs|cjs)'
    $matches = [regex]::Matches($Desc, $pattern)
    $files = @()
    $seen = @{}
    foreach ($m in $matches) {
        $f = $m.Value
        if (-not $seen.ContainsKey($f)) {
            $seen[$f] = $true
            $files += $f
        }
    }
    return $files
}

# Determine execution mode (SYNC/ASYNC).
# If explicit_mode is non-empty, trust it. Otherwise fall back to heuristics.
function Get-ExecutionMode {
    param(
        [string]$ExplicitMode,
        [string]$Desc,
        [string[]]$Files
    )
    if (-not [string]::IsNullOrEmpty($ExplicitMode)) {
        return $ExplicitMode
    }
    if ($Desc -match '(?i)research|analyze|design|plan|review|test|investigate|explore|prototype') {
        return "ASYNC"
    }
    if ($Files.Count -gt 2) {
        return "ASYNC"
    }
    return "SYNC"
}

# Compute the "phase" of a task. A phase is a section in tasks.md starting
# with "## Phase N: ..." or "## Phase N+1: ...". Returns $null if the
# line is not a phase heading.
function Get-PhaseFromLine {
    param([string]$Line)
    if ($Line -match '^\#\#\s+(Phase\s+\d+[^\s]*)(.*)$') {
        $name = $Matches[1]
        $rest = $Matches[2]
        return ($name + $rest).TrimEnd()
    }
    return $null
}

# Convert an array of arrays (waves) to a JSON string with the same compact
# representation as the bash script. Uses ConvertTo-Json with -Compress.
function ConvertTo-WavesJson {
    param([object[]]$Waves)
    $arr = @()
    foreach ($w in $Waves) {
        $arr += ,@($w)
    }
    return (ConvertTo-Json -InputObject $arr -Compress -Depth 5)
}

# Convert a list of task records (id|story|par|desc|files) to a JSON array
# of task objects matching the DAG schema. Wave lookup table is used to
# set execution_wave per task.
function ConvertTo-TasksJson {
    param(
        [string[]]$TaskRecords,
        [hashtable]$WaveLookup
    )
    $tasks = @()
    foreach ($rec in $TaskRecords) {
        $parts = $rec -split '\|', 5
        if ($parts.Count -lt 5) { continue }
        $id, $story, $par, $execMode, $desc = $parts
        $files = Extract-Files -Desc $desc
        $mode = Get-ExecutionMode -ExplicitMode $execMode -Desc $desc -Files $files
        $waveIndex = 0
        if ($WaveLookup.ContainsKey($id)) {
            $waveIndex = $WaveLookup[$id]
        }
        $deps = @()
        # For simplicity, deps are computed by reading the DAG after build.
        # Here we leave depends_on as [] -- the DAG assembly step (cmd_generate)
        # post-processes to set intra-wave dependencies.
        $taskObj = [ordered]@{
            id             = $id
            description    = $desc
            story          = if ([string]::IsNullOrEmpty($story)) { $null } else { $story }
            is_parallel    = [int]$par
            files          = $files
            execution_mode = $mode
            execution_wave = $waveIndex
            depends_on     = $deps
        }
        $tasks += $taskObj
    }
    return (ConvertTo-Json -InputObject $tasks -Compress -Depth 8)
}

# ---------------------------------------------------------------------------
# Subcommand: generate
# ---------------------------------------------------------------------------
function Invoke-Generate {
    [CmdletBinding()]
    param(
        [string]$TasksMd = "",
        [string]$Dag = "",
        [string]$Feature = ""
    )
    if ([string]::IsNullOrEmpty($TasksMd)) {
        Die "-TasksMd is required. Usage: tasks-dag.ps1 generate -TasksMd <path> [-Dag <path>] [-Feature <name>]"
    }
    if (-not (Test-Path $TasksMd)) { Die "Tasks file not found: $TasksMd" }

    if ([string]::IsNullOrEmpty($Dag)) {
        $tasksDir = Split-Path -Parent (Resolve-Path $TasksMd)
        $Dag = Join-Path $tasksDir $DagDefaultFilename
    }

    if ([string]::IsNullOrEmpty($Feature)) {
        $Feature = Split-Path -Leaf (Split-Path -Parent $TasksMd)
    }

    # Parse tasks.md into records: id|story|par|exec_mode|desc
    $taskRecords = @()
    foreach ($line in Get-Content $TasksMd) {
        $parsed = Parse-TaskLine -Line $line
        if ($null -ne $parsed) {
            $taskRecords += $parsed
        }
    }

    if ($taskRecords.Count -eq 0) {
        Write-Err "No tasks found in $TasksMd"
        exit 1
    }

    # Compute waves: walk through tasks and group by [P]+same story+no overlap.
    $waves = New-Object System.Collections.Generic.List[object]
    $curWaveIds = New-Object System.Collections.Generic.List[string]
    $curWaveFiles = @()
    $curWaveStory = ""
    $waveLookup = @{}
    $waveIdsLists = @()

    foreach ($rec in $taskRecords) {
        $parts = $rec -split '\|', 5
        $id, $story, $par, $execMode, $desc = $parts
        $files = Extract-Files -Desc $desc

        # Decide whether this task joins the current wave.
        $canJoin = $false
        if ($curWaveIds.Count -gt 0 -and $par -eq "1" -and $story -eq $curWaveStory) {
            # Check file overlap.
            $overlap = $false
            if ($files.Count -gt 0 -and $curWaveFiles.Count -gt 0) {
                foreach ($f in $files) {
                    if ($curWaveFiles -contains $f) {
                        $overlap = $true
                        break
                    }
                }
            }
            if (-not $overlap) {
                $canJoin = $true
            }
        }

        if ($canJoin) {
            $curWaveIds.Add($id) | Out-Null
            if ($files.Count -gt 0) {
                $curWaveFiles += $files
            }
        } else {
            # Commit the current wave (if any).
            if ($curWaveIds.Count -gt 0) {
                $waves.Add(@($curWaveIds.ToArray())) | Out-Null
                $waveIdsLists += ,@($curWaveIds.ToArray())
            }
            # Start a new wave.
            $curWaveIds = New-Object System.Collections.Generic.List[string]
            $curWaveIds.Add($id) | Out-Null
            $curWaveFiles = @()
            if ($files.Count -gt 0) {
                $curWaveFiles = @($files)
            }
            $curWaveStory = $story
        }
    }

    # Commit the last wave.
    if ($curWaveIds.Count -gt 0) {
        $waves.Add(@($curWaveIds.ToArray())) | Out-Null
        $waveIdsLists += ,@($curWaveIds.ToArray())
    }

    # Build wave lookup: id -> wave_index (0-based).
    for ($w = 0; $w -lt $waveIdsLists.Count; $w++) {
        foreach ($id in $waveIdsLists[$w]) {
            $waveLookup[$id] = $w
        }
    }

    # Compute dependencies: each task depends on the last task of every
    # prior wave. Within a wave, [P] tasks don't depend on each other;
    # non-P tasks in a wave depend on the prior task in the same wave.
    $depLookup = @{}
    $waveBoundaries = @{}
    $cumIndex = 0
    foreach ($w in 0..($waveIdsLists.Count - 1)) {
        $waveBoundaries[$w] = $cumIndex
        $cumIndex += $waveIdsLists[$w].Count
    }

    # Build per-task deps.
    for ($i = 0; $i -lt $taskRecords.Count; $i++) {
        $rec = $taskRecords[$i]
        $parts = $rec -split '\|', 4
        $id, $story, $par, $desc = $parts
        $w = $waveLookup[$id]
        $deps = @()
        if ($w -gt 0) {
            # Depends on the last task of the prior wave.
            $priorWave = $waveIdsLists[$w - 1]
            $deps += $priorWave[-1]
        } else {
            # Wave 0: depends on the prior non-P task in the same wave, if any.
            $idxInWave = $waveIdsLists[$w].IndexOf($id)
            for ($j = $idxInWave - 1; $j -ge 0; $j--) {
                $priorId = $waveIdsLists[$w][$j]
                $priorRec = $taskRecords | Where-Object { $_.Split('|')[0] -eq $priorId } | Select-Object -First 1
                if ($priorRec) {
                    $priorParts = $priorRec -split '\|', 4
                    if ($priorParts[2] -eq "0") {
                        $deps += $priorId
                        break
                    }
                }
            }
        }
        $depLookup[$id] = $deps
    }

    # Build tasks JSON.
    $tasksJsonParts = @()
    $storySet = @{}
    $parallelCount = 0
    foreach ($rec in $taskRecords) {
        $parts = $rec -split '\|', 4
        $id, $story, $par, $desc = $parts
        $files = Extract-Files -Desc $desc
        $mode = Get-ExecutionMode -Desc $desc -Files $files
        $waveIndex = $waveLookup[$id]
        $deps = $depLookup[$id]
        if ($par -eq "1") { $parallelCount++ }
        if (-not [string]::IsNullOrEmpty($story)) { $storySet[$story] = $true }

        $taskObj = [ordered]@{
            id             = $id
            description    = $desc
            story          = if ([string]::IsNullOrEmpty($story)) { $null } else { $story }
            is_parallel    = [int]$par
            files          = $files
            execution_mode = $mode
            execution_wave = $waveIndex
            depends_on     = $deps
        }
        $tasksJsonParts += (ConvertTo-Json -InputObject $taskObj -Compress -Depth 8)
    }
    $tasksJson = "[" + ($tasksJsonParts -join ",") + "]"
    $wavesJson = ConvertTo-WavesJson -Waves $waves.ToArray()

    $statsObj = [ordered]@{
        total_tasks    = $taskRecords.Count
        parallel_tasks = $parallelCount
        stories        = $storySet.Count
        total_waves    = $waves.Count
    }
    $statsJson = ConvertTo-Json -InputObject $statsObj -Compress -Depth 5

    $createdAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $sourcePath = (Resolve-Path $TasksMd).Path

    $dagObj = [ordered]@{
        schema_version = $DagSchemaVersion
        feature        = $Feature
        source         = $sourcePath
        generated_at   = $createdAt
        tasks          = (ConvertFrom-Json $tasksJson)
        execution_waves = (ConvertFrom-Json $wavesJson)
        stats          = (ConvertFrom-Json $statsJson)
    }

    # Write DAG file.
    $dagPretty = ConvertTo-Json -InputObject $dagObj -Depth 10
    [System.IO.File]::WriteAllText($Dag, $dagPretty, [System.Text.UTF8Encoding]::new($false))

    # Emit summary JSON to stdout.
    $summaryObj = [ordered]@{
        dag_written    = $true
        dag_path       = $Dag
        feature        = $Feature
        total_tasks    = $taskRecords.Count
        parallel_tasks = $parallelCount
        total_waves    = $waves.Count
        stories        = $storySet.Count
        ok             = $true
    }
    Write-Output (ConvertTo-Json -InputObject $summaryObj -Compress)
}

# ---------------------------------------------------------------------------
# Subcommand: validate
# ---------------------------------------------------------------------------
function Invoke-Validate {
    [CmdletBinding()]
    param([string]$Dag = "")
    if ([string]::IsNullOrEmpty($Dag)) {
        Die "-Dag is required. Usage: tasks-dag.ps1 validate -Dag <path>"
    }
    if (-not (Test-Path $Dag)) { Die "DAG file not found: $Dag" }

    $errors = @()

    # Check schema_version.
    $schema = (Get-Content $Dag -Raw | ConvertFrom-Json).schema_version
    if ([string]::IsNullOrEmpty($schema)) {
        $errors += "missing schema_version"
    } elseif ($schema -ne $DagSchemaVersion) {
        $errors += "unsupported schema_version: $schema (expected $DagSchemaVersion)"
    }

    # Check unique IDs. Use $dagData (not $dag) to avoid clobbering the
    # path param due to PowerShell's case-insensitive variable lookup.
    $dagData = Get-Content $Dag -Raw | ConvertFrom-Json
    $ids = @($dagData.tasks | ForEach-Object { $_.id })
    $dupGroups = $ids | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($dupGroups.Count -gt 0) {
        $errors += "duplicate task IDs found: $($dupGroups.Count) groups"
    }

    # Check depends_on reference valid IDs.
    $idSet = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($i in $ids) { [void]$idSet.Add($i) }
    $invalidDepsCount = 0
    foreach ($t in $dagData.tasks) {
        if ($null -ne $t.depends_on) {
            foreach ($d in $t.depends_on) {
                if (-not $idSet.Contains($d)) {
                    $invalidDepsCount++
                }
            }
        }
    }
    if ($invalidDepsCount -gt 0) {
        $errors += "depends_on references unknown IDs: $invalidDepsCount found"
    }

    # Check execution_waves is array of arrays.
    if ($null -eq $dagData.execution_waves) {
        $errors += "execution_waves must be array of arrays"
    }

    $valid = $true
    if ($errors.Count -gt 0) {
        $valid = $false
    }

    $result = [ordered]@{
        valid    = $valid
        errors   = $errors
        dag_path = $Dag
        ok       = $true
    }
    Write-Output (ConvertTo-Json -InputObject $result -Compress)
}

# ---------------------------------------------------------------------------
# Subcommand: show
# ---------------------------------------------------------------------------
function Invoke-Show {
    [CmdletBinding()]
    param([string]$Dag = "")
    if ([string]::IsNullOrEmpty($Dag)) {
        Die "-Dag is required. Usage: tasks-dag.ps1 show -Dag <path>"
    }
    if (-not (Test-Path $Dag)) { Die "DAG file not found: $Dag" }

    $dagData = Get-Content $Dag -Raw | ConvertFrom-Json
    $stats = $dagData.stats
    $feature = $dagData.feature
    $totalTasks = $stats.total_tasks
    $parallelTasks = $stats.parallel_tasks
    $storyCount = $stats.stories
    $waveCount = $stats.total_waves

    Write-Output "DAG: $Dag"
    Write-Output "  Feature:        $feature"
    Write-Output "  Total tasks:    $totalTasks"
    Write-Output "  Parallel tasks: $parallelTasks"
    Write-Output "  User stories:   $storyCount"
    Write-Output "  Wave count:     $waveCount"
    Write-Output ""
    Write-Output "Execution waves:"
    for ($w = 0; $w -lt $dagData.execution_waves.Count; $w++) {
        $wNum = $w + 1
        $ids = $dagData.execution_waves[$w] -join ", "
        Write-Output "  Wave ${wNum}: $ids"
    }
    Write-Output ""

    # Per-story task counts.
    $storyBuckets = @{}
    foreach ($t in $dagData.tasks) {
        $s = if ([string]::IsNullOrEmpty($t.story)) { "<no-story>" } else { $t.story }
        if (-not $storyBuckets.ContainsKey($s)) { $storyBuckets[$s] = 0 }
        $storyBuckets[$s]++
    }
    Write-Output "Per-story task counts:"
    foreach ($k in $storyBuckets.Keys) {
        Write-Output "  $k`: $($storyBuckets[$k]) task(s)"
    }
}

# ---------------------------------------------------------------------------
# Subcommand: classify
# ---------------------------------------------------------------------------
function Invoke-Classify {
    [CmdletBinding()]
    param(
        [string]$TaskId = "",
        [string]$TasksMd = "",
        [string]$Dag = ""
    )
    if ([string]::IsNullOrEmpty($TaskId)) {
        Die "-TaskId is required. Usage: tasks-dag.ps1 classify -TaskId <TNNN> (-TasksMd <path> | -Dag <path>)"
    }

    if ([string]::IsNullOrEmpty($TasksMd) -and -not [string]::IsNullOrEmpty($Dag)) {
        if (-not (Test-Path $Dag)) { Die "DAG file not found: $Dag" }
        try {
            $dagData = Get-Content -Raw $Dag | ConvertFrom-Json
            $TasksMd = [string]$dagData.source
        } catch {
            Die "Failed to read DAG file: $Dag"
        }
    }

    if ([string]::IsNullOrEmpty($TasksMd)) {
        Die "-TasksMd or -Dag is required. Usage: tasks-dag.ps1 classify -TaskId <TNNN> (-TasksMd <path> | -Dag <path>)"
    }
    if (-not (Test-Path $TasksMd)) { Die "Tasks file not found: $TasksMd" }

    # Find the task line.
    $targetLine = $null
    foreach ($line in Get-Content $TasksMd) {
        if ($line -match "^\-\s+\[[ x]\]\s+${TaskId}\b") {
            $targetLine = $line
            break
        }
    }
    if ($null -eq $targetLine) { Die "Task $TaskId not found in $TasksMd" }

    $parsed = Parse-TaskLine -Line $targetLine
    if ($null -eq $parsed) { Die "Failed to parse task line: $targetLine" }
    $parts = $parsed -split '\|', 4
    $id, $story, $par, $desc = $parts
    $files = Extract-Files -Desc $desc
    $execMode = Get-ExecutionMode -Desc $desc -Files $files

    # Compute the wave by replaying the same algorithm as generate.
    $wave = 0
    $curWaveStory = ""
    $curWaveFiles = @()
    $curWaveHasTask = $false
    $sawTarget = $false
    foreach ($line in Get-Content $TasksMd) {
        $p = Parse-TaskLine -Line $line
        if ($null -ne $p) {
            $pp = $p -split '\|', 4
            $tid, $tstory, $tpar, $tdesc = $pp
            $tfl = Extract-Files -Desc $tdesc

            $isTarget = ($tid -eq $TaskId)

            # Decide whether this task starts a new wave.
            $startsNewWave = $false
            if (-not $curWaveHasTask) {
                # First task: it IS wave 0; no increment needed.
                $startsNewWave = $false
            } elseif ($tpar -eq "1" -and $tstory -eq $curWaveStory) {
                # P + same story: check file overlap.
                $overlap = $false
                if ($tfl.Count -gt 0 -and $curWaveFiles.Count -gt 0) {
                    foreach ($f in $tfl) {
                        if ($curWaveFiles -contains $f) {
                            $overlap = $true
                            break
                        }
                    }
                }
                if ($overlap) { $startsNewWave = $true }
            } else {
                # Non-P, OR story change.
                $startsNewWave = $true
            }

            if ($startsNewWave) {
                $wave++
            }

            if ($isTarget) {
                $sawTarget = $true
                break
            }

            # Update current wave anchor.
            $curWaveHasTask = $true
            if ($tfl.Count -gt 0) {
                $curWaveFiles = @($curWaveFiles) + @($tfl)
            }
            $curWaveStory = $tstory
        }
    }
    if (-not $sawTarget) { Die "Task $TaskId not found in walk" }

    $result = [ordered]@{
        id             = $TaskId
        description    = $desc
        story          = if ([string]::IsNullOrEmpty($story)) { $null } else { $story }
        is_parallel    = [int]$par
        files          = $files
        execution_mode = $execMode
        execution_wave = $wave
        ok             = $true
    }
    Write-Output (ConvertTo-Json -InputObject $result -Compress)
}

# ---------------------------------------------------------------------------
# Subcommand: coalesce (report-only per C1)
# ---------------------------------------------------------------------------
function Invoke-Coalesce {
    [CmdletBinding()]
    param(
        [string]$TasksMd = "",
        [string]$Dag = ""
    )
    if ([string]::IsNullOrEmpty($TasksMd)) {
        Die "-TasksMd is required. Usage: tasks-dag.ps1 coalesce -TasksMd <path> [-Dag <path>]"
    }
    if (-not (Test-Path $TasksMd)) { Die "Tasks file not found: $TasksMd" }

    # Find adjacent pairs that meet the coalesce criteria:
    #   1. Same story (or both no-story)
    #   2. Both non-parallel (sequential)
    #   3. Short descriptions (< 80 chars after stripping)
    #   4. Touch the same primary file
    # Report as JSON. No rewrite per C1.

    $coalescable = @()
    $prevId = ""; $prevStory = ""; $prevPar = ""; $prevDesc = ""; $prevFile = ""
    foreach ($line in Get-Content $TasksMd) {
        $parsed = Parse-TaskLine -Line $line
        if ($null -ne $parsed) {
            $parts = $parsed -split '\|', 4
            $id, $story, $par, $desc = $parts
            $files = Extract-Files -Desc $desc
            $firstFile = if ($files.Count -gt 0) { $files[0] } else { "" }

            if (-not [string]::IsNullOrEmpty($prevId)) {
                $shortEnough = ($desc.Length -lt 80) -and ($prevDesc.Length -lt 80)
                if ($shortEnough -and ($story -eq $prevStory) `
                    -and ($par -eq "0") -and ($prevPar -eq "0") `
                    -and (-not [string]::IsNullOrEmpty($firstFile)) -and ($firstFile -eq $prevFile)) {
                    $record = [ordered]@{
                        tasks  = @($prevId, $id)
                        file   = $firstFile
                        reason = "Both non-parallel tasks in same story touch $firstFile; both descriptions < 80 chars"
                    }
                    $coalescable += $record
                }
            }
            $prevId = $id; $prevStory = $story; $prevPar = $par
            $prevDesc = $desc; $prevFile = $firstFile
        }
    }

    $result = [ordered]@{
        coalescable_count = $coalescable.Count
        pairs             = $coalescable
        tasks_md          = $TasksMd
        mode              = "report-only"
        ok                = $true
    }
    $json = ConvertTo-Json -InputObject $result -Compress -Depth 6
    [Console]::Out.WriteLine($json)
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
    "generate"   { Invoke-Subcommand "Invoke-Generate" $remaining }
    "validate"   { Invoke-Subcommand "Invoke-Validate" $remaining }
    "show"       { Invoke-Subcommand "Invoke-Show" $remaining }
    "classify"   { Invoke-Subcommand "Invoke-Classify" $remaining }
    "coalesce"   { Invoke-Subcommand "Invoke-Coalesce" $remaining }
    "help"       { Show-Usage; exit 0 }
    default {
        Write-Err "Unknown subcommand: $Subcommand"
        Show-Usage
        exit 1
    }
}
