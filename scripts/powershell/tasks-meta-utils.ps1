#!/usr/bin/env pwsh
# Task Meta Utilities for Agentic SDLC (PowerShell)
# Handles task classification, delegation, and status tracking
#
# Usage: tasks-meta-utils.ps1 <subcommand> [args...]
#
# Subcommands:
#   init <feature_dir>
#   add-task <tasks_meta.json> <task_id> <description> <files> <mode>
#   start-task <tasks_meta.json> <task_id>
#   complete-task <tasks_meta.json> <task_id> [result_summary]
#   fail-task <tasks_meta.json> <task_id> <reason>
#   review-micro <tasks_meta.json> <task_id>
#   quality-gate <tasks_meta.json> <task_id>
#   summary <tasks_meta.json>
#   dispatch-async <task_id> <agent_type> <description> <context> <requirements> <instructions> <feature_dir>
#   check-status <task_id> [feature_dir]
#   rollback-task <tasks_meta.json> <task_id>
#   rollback-feature <feature_dir>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Subcommand,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Rest
)

$ErrorActionPreference = 'Stop'

function Write-Info  { param([string]$Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Cyan }
function Write-Warn  { param([string]$Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow }
function Write-ErrorLog { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }

# ---------------------------------------------------------------------------
# Feature-scoped async state directories
# ---------------------------------------------------------------------------

function Get-FeatureAsyncDir {
    param([string]$FeatureDir)
    return (Join-Path $FeatureDir ".async_state")
}

function Ensure-AsyncDirs {
    param([string]$FeatureDir)
    $dir = Get-FeatureAsyncDir -FeatureDir $FeatureDir
    New-Item -ItemType Directory -Path (Join-Path $dir "delegation_prompts") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir "delegation_completed") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir "delegation_errors") -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Core functions
# ---------------------------------------------------------------------------

function Initialize-TasksMeta {
    param([string]$FeatureDir)
    $tasksMetaFile = Join-Path $FeatureDir "tasks_meta.json"
    $meta = [ordered]@{
        feature = (Split-Path $FeatureDir -Leaf)
        created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        tasks = [ordered]@{}
    }
    $meta | ConvertTo-Json -Depth 5 | Set-Content -Path $tasksMetaFile -Encoding UTF8
    Ensure-AsyncDirs -FeatureDir $FeatureDir
    Write-Host "Initialized tasks_meta.json at $tasksMetaFile"
}

function Classify-TaskExecutionMode {
    param(
        [string]$Description,
        [string]$Files
    )
    $fileCount = ($Files -split '\s+').Count
    if ($Description -match '(?i)research|analyze|design|plan|review|test|investigate|explore|prototype') {
        return "ASYNC"
    }
    if ($fileCount -gt 2) {
        return "ASYNC"
    }
    return "SYNC"
}

function Add-Task {
    param(
        [string]$TasksMetaFile,
        [string]$TaskId,
        [string]$Description,
        [string]$Files,
        [string]$ExecutionMode
    )
    $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
    if (-not $meta.tasks) { $meta.tasks = [ordered]@{} }
    $meta.tasks[$TaskId] = [ordered]@{
        description    = $Description
        files          = $Files
        execution_mode = $ExecutionMode
        status         = "pending"
        agent_type     = "general"
        started_at     = $null
        completed_at   = $null
        result_summary = $null
    }
    $meta | ConvertTo-Json -Depth 10 | Set-Content -Path $TasksMetaFile -Encoding UTF8
    Write-Host "Added task $TaskId ($ExecutionMode) to $TasksMetaFile"
}

function Start-Task {
    param(
        [string]$TasksMetaFile,
        [string]$TaskId
    )
    $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
    $meta.tasks[$TaskId].status = "in_progress"
    $meta.tasks[$TaskId].started_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $meta | ConvertTo-Json -Depth 10 | Set-Content -Path $TasksMetaFile -Encoding UTF8
    Write-Host "Task $TaskId started"
}

function Complete-Task {
    param(
        [string]$TasksMetaFile,
        [string]$TaskId,
        [string]$ResultSummary = ""
    )
    $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
    $meta.tasks[$TaskId].status = "completed"
    $meta.tasks[$TaskId].completed_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $meta.tasks[$TaskId].result_summary = $ResultSummary
    $meta | ConvertTo-Json -Depth 10 | Set-Content -Path $TasksMetaFile -Encoding UTF8
    Write-Host "Task $TaskId completed"
}

function Fail-Task {
    param(
        [string]$TasksMetaFile,
        [string]$TaskId,
        [string]$Reason
    )
    $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
    $meta.tasks[$TaskId].status = "failed"
    $meta.tasks[$TaskId].completed_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $meta.tasks[$TaskId].failure_reason = $Reason
    $meta | ConvertTo-Json -Depth 10 | Set-Content -Path $TasksMetaFile -Encoding UTF8
    Write-Host "Task $TaskId failed: $Reason"
}

function Review-Micro {
    param(
        [string]$TasksMetaFile,
        [string]$TaskId
    )
    $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
    $status = $meta.tasks[$TaskId].status
    $mode = $meta.tasks[$TaskId].execution_mode

    if ($status -ne "completed") {
        Write-Warn "Task $TaskId is not completed (status: $status); micro-review skipped"
        return 1
    }
    if ($mode -ne "SYNC") {
        Write-Warn "Task $TaskId is not a SYNC task (mode: $mode); micro-review not required"
        return 0
    }

    $meta.tasks[$TaskId].micro_reviewed_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $meta.tasks[$TaskId].micro_review_passed = $true
    $meta | ConvertTo-Json -Depth 10 | Set-Content -Path $TasksMetaFile -Encoding UTF8
    Write-Host "Micro-review passed for task $TaskId"
}

function Quality-Gate {
    param(
        [string]$TasksMetaFile,
        [string]$TaskId
    )
    $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
    $status = $meta.tasks[$TaskId].status
    $mode = $meta.tasks[$TaskId].execution_mode

    if ($status -ne "completed") {
        Write-Warn "Task $TaskId is not completed (status: $status); quality gate skipped"
        return 1
    }

    $gatePassed = $true
    if ($mode -eq "SYNC") {
        $reviewed = $meta.tasks[$TaskId].micro_review_passed
        if (-not $reviewed) {
            $gatePassed = $false
            Write-Warn "Quality gate FAILED for $TaskId: SYNC task missing micro-review"
        }
    }

    $meta.tasks[$TaskId].quality_gate_passed = $gatePassed
    $meta.tasks[$TaskId].quality_gate_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $meta | ConvertTo-Json -Depth 10 | Set-Content -Path $TasksMetaFile -Encoding UTF8

    if ($gatePassed) {
        Write-Host "Quality gate passed for task $TaskId"
    } else {
        Write-Host "Quality gate failed for task $TaskId"
        return 1
    }
}

function Get-Summary {
    param([string]$TasksMetaFile)
    $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
    $total = $meta.tasks.Count
    $pending = 0
    $inProgress = 0
    $completed = 0
    $failed = 0
    $syncTotal = 0
    $asyncTotal = 0

    foreach ($key in $meta.tasks.Keys) {
        $t = $meta.tasks[$key]
        switch ($t.status) {
            "pending"     { $pending++ }
            "in_progress" { $inProgress++ }
            "completed"   { $completed++ }
            "failed"      { $failed++ }
        }
        if ($t.execution_mode -eq "SYNC") { $syncTotal++ }
        if ($t.execution_mode -eq "ASYNC") { $asyncTotal++ }
    }

    $allDone = ($pending -eq 0 -and $inProgress -eq 0 -and $failed -eq 0 -and $total -gt 0)

    [ordered]@{
        total_tasks  = $total
        pending      = $pending
        in_progress  = $inProgress
        completed    = $completed
        failed       = $failed
        sync_tasks   = $syncTotal
        async_tasks  = $asyncTotal
        all_done     = $allDone
    } | ConvertTo-Json -Compress
}

# ---------------------------------------------------------------------------
# Async delegation
# ---------------------------------------------------------------------------

function Generate-AgentContext {
    param([string]$FeatureDir)
    $context = "## Project Context`n`n"
    $files = @{
        "Feature Specification" = "spec.md"
        "Technical Plan"        = "plan.md"
        "Data Model"            = "data-model.md"
        "Research & Decisions"  = "research.md"
    }
    foreach ($label in $files.Keys) {
        $path = Join-Path $FeatureDir $files[$label]
        if (Test-Path $path) {
            $content = Get-Content $path -Raw
            $context += "### $label`n$content`n`n"
        }
    }
    $contractsDir = Join-Path $FeatureDir "contracts"
    if (Test-Path $contractsDir) {
        $context += "### API Contracts`n"
        Get-ChildItem $contractsDir -Filter "*.md" | ForEach-Object {
            $content = Get-Content $_.FullName -Raw
            $context += "#### $($_.BaseName)`n$content`n`n"
        }
    }
    return $context
}

function Dispatch-AsyncTask {
    param(
        [string]$TaskId,
        [string]$AgentType,
        [string]$TaskDescription,
        [string]$TaskContext,
        [string]$TaskRequirements,
        [string]$ExecutionInstructions,
        [string]$FeatureDir
    )
    Ensure-AsyncDirs -FeatureDir $FeatureDir
    $asyncDir = Get-FeatureAsyncDir -FeatureDir $FeatureDir
    $promptFile = Join-Path $asyncDir "delegation_prompts" "$TaskId.md"

    $agentContext = Generate-AgentContext -FeatureDir $FeatureDir
    $fullContext = "$TaskContext`n`n$agentContext"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $prompt = @"
## Task: $TaskId
**Agent Type:** $AgentType
**Description:** $TaskDescription
**Requirements:** $TaskRequirements
**Instructions:** $ExecutionInstructions
**Timestamp:** $timestamp

$fullContext
"@

    Set-Content -Path $promptFile -Value $prompt -Encoding UTF8
    Write-Host "Task $TaskId delegated successfully - prompt saved for AI assistant"
}

function Check-DelegationStatus {
    param(
        [string]$TaskId,
        [string]$FeatureDir = ""
    )
    $asyncDir = if ($FeatureDir) { Get-FeatureAsyncDir -FeatureDir $FeatureDir } else { "." }
    $promptFile = Join-Path $asyncDir "delegation_prompts" "$TaskId.md"
    if (-not (Test-Path $promptFile)) {
        Write-Output "no_job"
        return
    }
    $completionFile = Join-Path $asyncDir "delegation_completed" "$TaskId.txt"
    if (Test-Path $completionFile) {
        Write-Output "completed"
        return
    }
    $errorFile = Join-Path $asyncDir "delegation_errors" "$TaskId.txt"
    if (Test-Path $errorFile) {
        Write-Output "failed"
        return
    }
    Write-Output "running"
}

# ---------------------------------------------------------------------------
# Rollback helpers
# ---------------------------------------------------------------------------

function Rollback-Task {
    param(
        [string]$TasksMetaFile,
        [string]$TaskId
    )
    Write-Warn "Rolling back task: $TaskId"
    $meta = Get-Content $TasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
    $meta.tasks[$TaskId].status = "rolled_back"
    $meta | ConvertTo-Json -Depth 10 | Set-Content -Path $TasksMetaFile -Encoding UTF8
    $featureDir = Split-Path $TasksMetaFile -Parent
    "$((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) - Rolled back task $TaskId" | Out-File -Append -FilePath (Join-Path $featureDir "rollback.log")
    Write-Host "Task $TaskId rolled back successfully"
}

function Rollback-Feature {
    param([string]$FeatureDir)
    Write-Warn "Rolling back entire feature: $(Split-Path $FeatureDir -Leaf)"
    $tasksMetaFile = Join-Path $FeatureDir "tasks_meta.json"
    if (Test-Path $tasksMetaFile) {
        $meta = Get-Content $tasksMetaFile -Raw | ConvertFrom-Json -AsHashtable
        foreach ($key in $meta.tasks.Keys) {
            $meta.tasks[$key].status = "rolled_back"
        }
        $meta | ConvertTo-Json -Depth 10 | Set-Content -Path $tasksMetaFile -Encoding UTF8
    }
    Remove-Item (Join-Path $FeatureDir "implementation.log") -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $FeatureDir "checklists") -Recurse -ErrorAction SilentlyContinue
    "$((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) - Rolled back entire feature" | Out-File -Append -FilePath (Join-Path $FeatureDir "rollback.log")
    Write-Host "Feature $(Split-Path $FeatureDir -Leaf) implementation rolled back"
}

# ---------------------------------------------------------------------------
# CLI dispatcher
# ---------------------------------------------------------------------------

function Show-Usage {
    @"
Usage: tasks-meta-utils.ps1 <subcommand> [args...]

Subcommands:
  init <feature_dir>
  add-task <tasks_meta.json> <task_id> <description> <files> <mode>
  start-task <tasks_meta.json> <task_id>
  complete-task <tasks_meta.json> <task_id> [result_summary]
  fail-task <tasks_meta.json> <task_id> <reason>
  review-micro <tasks_meta.json> <task_id>
  quality-gate <tasks_meta.json> <task_id>
  summary <tasks_meta.json>
  dispatch-async <task_id> <agent_type> <description> <context> <requirements> <instructions> <feature_dir>
  check-status <task_id> [feature_dir]
  rollback-task <tasks_meta.json> <task_id>
  rollback-feature <feature_dir>
"@
}

switch ($Subcommand) {
    "init" { Initialize-TasksMeta -FeatureDir $Rest[0] }
    "add-task" { Add-Task -TasksMetaFile $Rest[0] -TaskId $Rest[1] -Description $Rest[2] -Files $Rest[3] -ExecutionMode $Rest[4] }
    "start-task" { Start-Task -TasksMetaFile $Rest[0] -TaskId $Rest[1] }
    "complete-task" { Complete-Task -TasksMetaFile $Rest[0] -TaskId $Rest[1] -ResultSummary ($Rest[2] -join " ") }
    "fail-task" { Fail-Task -TasksMetaFile $Rest[0] -TaskId $Rest[1] -Reason ($Rest[2] -join " ") }
    "review-micro" { Review-Micro -TasksMetaFile $Rest[0] -TaskId $Rest[1] }
    "quality-gate" { Quality-Gate -TasksMetaFile $Rest[0] -TaskId $Rest[1] }
    "summary" { Get-Summary -TasksMetaFile $Rest[0] }
    "dispatch-async" { Dispatch-AsyncTask -TaskId $Rest[0] -AgentType $Rest[1] -TaskDescription $Rest[2] -TaskContext $Rest[3] -TaskRequirements $Rest[4] -ExecutionInstructions $Rest[5] -FeatureDir $Rest[6] }
    "check-status" { Check-DelegationStatus -TaskId $Rest[0] -FeatureDir ($Rest[1] -join "") }
    "rollback-task" { Rollback-Task -TasksMetaFile $Rest[0] -TaskId $Rest[1] }
    "rollback-feature" { Rollback-Feature -FeatureDir $Rest[0] }
    "classify" { Classify-TaskExecutionMode -Description $Rest[0] -Files ($Rest[1] -join " ") }
    default { Show-Usage }
}
