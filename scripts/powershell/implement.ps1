#!/usr/bin/env pwsh
# implement.ps1 - Execute the implementation plan
# Usage: implement.ps1 -FeatureDir <path> [-Worktree]
#
# Branch mode (default): sequential execution of tasks from tasks.md
# Worktree mode (-Worktree): wave-based execution from tasks_dag.json

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureDir,
    [switch]$Worktree
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir/tasks-meta-utils.ps1"

function Write-Info  { param([string]$Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Cyan }
function Write-Warn  { param([string]$Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow }
function Write-ErrorLog { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }
function Write-Success { param([string]$Msg) Write-Host "[OK]    $Msg" -ForegroundColor Green }

$FeatureDir = Resolve-Path $FeatureDir | Select-Object -ExpandProperty Path
$FeatureName = Split-Path $FeatureDir -Leaf
$TasksFile = Join-Path $FeatureDir "tasks.md"
$TasksMetaFile = Join-Path $FeatureDir "tasks_meta.json"
$ DagFile = Join-Path $FeatureDir "tasks_dag.json"

# ---------------------------------------------------------------------------
# Task parsing from tasks.md
# ---------------------------------------------------------------------------

function Get-TasksFromMd {
    param([string]$TasksMd)
    if (-not (Test-Path $TasksMd)) {
        Write-ErrorLog "Tasks file not found: $TasksMd"
        exit 1
    }

    $tasks = @()
    foreach ($line in Get-Content $TasksMd) {
        if ($line -match '^\-\s+\[\s+\]\s+(T\d+)\s+(.+)$') {
            $id = $Matches[1]
            $rest = $Matches[2]
            $isParallel = ""
            $execMode = ""
            $story = ""
            $desc = $rest

            if ($rest -match '^\[P\]\s+(.+)$') {
                $isParallel = "P"
                $rest = $Matches[1]
            }
            if ($rest -match '^\[(SYNC|ASYNC)\]\s+(.+)$') {
                $execMode = $Matches[1]
                $rest = $Matches[2]
            }
            if ($rest -match '^\[(US\d+)\]\s+(.+)$') {
                $story = $Matches[1]
                $rest = $Matches[2]
            }
            $desc = $rest.TrimEnd()

            $files = @()
            $pattern = '[a-zA-Z0-9_./-]+\.(py|sh|ps1|js|ts|tsx|jsx|go|rs|java|rb|php|c|cpp|h|hpp|cs|swift|kt|mjs|cjs)'
            $fileMatches = [regex]::Matches($desc, $pattern)
            $seen = @{}
            foreach ($m in $fileMatches) {
                if (-not $seen.ContainsKey($m.Value)) {
                    $seen[$m.Value] = $true
                    $files += $m.Value
                }
            }
            $filesStr = $files -join " "

            if ([string]::IsNullOrEmpty($execMode)) {
                $execMode = Classify-TaskExecutionMode -Description $desc -Files $filesStr
            }

            $tasks += [PSCustomObject]@{
                id           = $id
                is_parallel  = $isParallel
                exec_mode    = $execMode
                story        = $story
                description  = $desc
                files        = $filesStr
            }
        }
    }
    return $tasks
}

function Mark-TaskComplete {
    param(
        [string]$TasksMd,
        [string]$TaskId
    )
    $content = Get-Content $TasksMd -Raw
    $content = $content -replace "^- \[ \] $TaskId\b", "- [X] $TaskId"
    Set-Content -Path $TasksMd -Value $content -Encoding UTF8 -NoNewline
}

# ---------------------------------------------------------------------------
# Branch mode: sequential execution
# ---------------------------------------------------------------------------

function Invoke-BranchMode {
    Write-Info "Branch mode: sequential execution"

    if (-not (Test-Path $TasksMetaFile)) {
        Initialize-TasksMeta -FeatureDir $FeatureDir
    }

    $tasks = Get-TasksFromMd -TasksMd $TasksFile
    foreach ($task in $tasks) {
        $taskId = $task.id
        $execMode = $task.exec_mode
        $desc = $task.description
        $files = $task.files

        $content = Get-Content $TasksFile -Raw
        if ($content -match "^- \[[xX]\] $taskId\b") {
            Write-Info "Task $taskId already completed, skipping"
            continue
        }

        $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
        if (-not $meta.tasks[$taskId]) {
            Add-Task -TasksMetaFile $TasksMetaFile -TaskId $taskId -Description $desc -Files $files -ExecutionMode $execMode
        }

        Write-Info "Executing task $taskId [$execMode]: $desc"
        Start-Task -TasksMetaFile $TasksMetaFile -TaskId $taskId

        $result = 0
        if ($execMode -eq "ASYNC") {
            $result = Invoke-AsyncTask -TaskId $taskId -Desc $desc -Files $files
        } else {
            $result = Invoke-SyncTask -TaskId $taskId -Desc $desc -Files $files
        }

        if ($result -eq 0) {
            Complete-Task -TasksMetaFile $TasksMetaFile -TaskId $taskId -ResultSummary "Task completed successfully"
            Mark-TaskComplete -TasksMd $TasksFile -TaskId $taskId
            Write-Success "Task $taskId completed"
        } else {
            Fail-Task -TasksMetaFile $TasksMetaFile -TaskId $taskId -Reason "Task execution failed"
            Write-ErrorLog "Task $taskId failed"
            return 1
        }

        Quality-Gate -TasksMetaFile $TasksMetaFile -TaskId $taskId
    }

    $summary = Get-Summary -TasksMetaFile $TasksMetaFile | ConvertFrom-Json
    if ($summary.all_done) {
        Write-Success "All tasks completed for feature $FeatureName"
    } else {
        Write-Warn "Some tasks remain incomplete for feature $FeatureName"
    }
    $summary | ConvertTo-Json -Compress
}

function Invoke-SyncTask {
    param(
        [string]$TaskId,
        [string]$Desc,
        [string]$Files
    )
    Write-Info "SYNC task $TaskId: executing inline"
    return 0
}

function Invoke-AsyncTask {
    param(
        [string]$TaskId,
        [string]$Desc,
        [string]$Files
    )
    Write-Info "ASYNC task $TaskId: dispatching to async agent"
    Dispatch-AsyncTask -TaskId $TaskId -AgentType "general" -TaskDescription $Desc -TaskContext "Files: $Files" -TaskRequirements "Complete per spec" -ExecutionInstructions "Execute and commit" -FeatureDir $FeatureDir

    $maxWait = 300
    $waited = 0
    while ($true) {
        $status = Check-DelegationStatus -TaskId $TaskId -FeatureDir $FeatureDir
        switch ($status) {
            "completed" {
                Write-Success "ASYNC task $TaskId completed"
                return 0
            }
            "failed" {
                Write-ErrorLog "ASYNC task $TaskId failed"
                return 1
            }
            "no_job" {
                Write-Warn "ASYNC task $TaskId has no job record"
                return 1
            }
        }
        Start-Sleep -Seconds 2
        $waited += 2
        if ($waited -ge $maxWait) {
            Write-Warn "ASYNC task $TaskId timed out after ${maxWait}s"
            return 1
        }
    }
}

# ---------------------------------------------------------------------------
# Worktree mode: wave-based execution
# ---------------------------------------------------------------------------

function Invoke-WorktreeMode {
    Write-Info "Worktree mode: wave-based execution"

    if (-not (Test-Path $DagFile)) {
        Write-Warn "DAG file not found: $DagFile. Falling back to branch mode."
        Invoke-BranchMode
        return
    }

    if (-not (Test-Path $TasksMetaFile)) {
        Initialize-TasksMeta -FeatureDir $FeatureDir
    }

    $dag = Get-Content $DagFile -Raw | ConvertFrom-Json
    foreach ($taskObj in $dag.tasks) {
        $taskId = $taskObj.id
        $desc = $taskObj.description
        $files = $taskObj.files -join " "
        $execMode = $taskObj.execution_mode

        $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
        if (-not $meta.tasks[$taskId]) {
            Add-Task -TasksMetaFile $TasksMetaFile -TaskId $taskId -Description $desc -Files $files -ExecutionMode $execMode
        }
    }

    $waveCount = $dag.execution_waves.Count
    for ($waveIdx = 0; $waveIdx -lt $waveCount; $waveIdx++) {
        $waveTasks = $dag.execution_waves[$waveIdx]
        Write-Info "Wave $($waveIdx + 1)/$waveCount: $($waveTasks -join ', ')"

        foreach ($taskId in $waveTasks) {
            $content = Get-Content $TasksFile -Raw
            if ($content -match "^- \[[xX]\] $taskId\b") {
                Write-Info "Task $taskId already completed, skipping"
                continue
            }

            Start-Task -TasksMetaFile $TasksMetaFile -TaskId $taskId

            $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
            $execMode = $meta.tasks[$taskId].execution_mode

            if ($execMode -eq "ASYNC") {
                Invoke-AsyncTask -TaskId $taskId -Desc "" -Files ""
            } else {
                Invoke-SyncTask -TaskId $taskId -Desc "" -Files ""
            }
        }

        foreach ($taskId in $waveTasks) {
            $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
            if ($meta.tasks[$taskId].status -eq "completed") {
                Mark-TaskComplete -TasksMd $TasksFile -TaskId $taskId
            }
        }
    }

    $summary = Get-Summary -TasksMetaFile $TasksMetaFile
    Write-Output $summary
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if (-not (Test-Path $TasksFile)) {
    Write-ErrorLog "Tasks file not found: $TasksFile"
    exit 1
}

Write-Info "Implementing feature: $FeatureName"
Write-Info "Tasks: $TasksFile"
Write-Info "Mode: $(if ($Worktree) { 'worktree' } else { 'branch' })"

if ($Worktree) {
    Invoke-WorktreeMode
} else {
    Invoke-BranchMode
}
