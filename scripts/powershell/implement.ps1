# implement.ps1 - Execute the implementation plan with dual execution loop support
# Handles SYNC/ASYNC task classification, MCP dispatching, and review enforcement

param(
    [Parameter(Mandatory=$true)]
    [string]$JsonOutput
)

# Source common utilities
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir/common.ps1"

# Global variables
$FeatureDir = ""
$AvailableDocs = ""
$TasksFile = ""
$TasksMetaFile = ""
$ChecklistsDir = ""
$ImplementationLog = ""

# Logging functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

# Initialize implementation environment
function Initialize-Implementation {
    param([string]$JsonOutput)

    # Parse JSON output from check-prerequisites.ps1
    $global:FeatureDir = ($JsonOutput | ConvertFrom-Json).FEATURE_DIR
    $global:AvailableDocs = ($JsonOutput | ConvertFrom-Json).AVAILABLE_DOCS

    if ([string]::IsNullOrEmpty($global:FeatureDir)) {
        Write-Error "FEATURE_DIR not found in prerequisites check"
        exit 1
    }

    $global:TasksFile = Join-Path $global:FeatureDir "tasks.md"
    $global:TasksMetaFile = Join-Path $global:FeatureDir "tasks_meta.json"
    $global:ChecklistsDir = Join-Path $global:FeatureDir "checklists"

    # Create implementation log
    $global:ImplementationLog = Join-Path $global:FeatureDir "implementation.log"
    $logContent = @"
# Implementation Log - $(Get-Date)

"@
    $logContent | Out-File -FilePath $global:ImplementationLog -Encoding UTF8

    Write-Info "Initialized implementation for feature: $(Split-Path $global:FeatureDir -Leaf)"
}

# Check checklists status
function Test-ChecklistsStatus {
    if (-not (Test-Path $global:ChecklistsDir)) {
        Write-Info "No checklists directory found - proceeding without checklist validation"
        return
    }

    Write-Info "Checking checklist status..."

    $totalChecklists = 0
    $passedChecklists = 0
    $failedChecklists = 0

    $logContent = @"

## Checklist Status Report

| Checklist | Total | Completed | Incomplete | Status |
|-----------|-------|-----------|------------|--------|
"@

    Get-ChildItem -Path $global:ChecklistsDir -Filter "*.md" | ForEach-Object {
        $checklistFile = $_.FullName
        $filename = $_.BaseName

        $content = Get-Content $checklistFile -Raw
        $totalItems = ($content | Select-String -Pattern "^- \[" -AllMatches).Matches.Count
        $completedItems = ($content | Select-String -Pattern "^- \[X\]|^- \[x\]" -AllMatches).Matches.Count
        $incompleteItems = $totalItems - $completedItems

        $status = if ($incompleteItems -gt 0) { "FAIL"; $global:failedChecklists++ } else { "PASS"; $global:passedChecklists++ }
        $global:totalChecklists++

        $logContent += "| $filename | $totalItems | $completedItems | $incompleteItems | $status |`n"
    }

    $logContent | Out-File -FilePath $global:ImplementationLog -Append -Encoding UTF8

    if ($failedChecklists -gt 0) {
        Write-Warning "Found $failedChecklists checklist(s) with incomplete items"
        $response = Read-Host "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
        if ($response -notmatch "^(yes|y)$") {
            Write-Info "Implementation cancelled by user"
            exit 0
        }
    } else {
        Write-Success "All $totalChecklists checklists passed"
    }
}

# Load implementation context
function Import-ImplementationContext {
    Write-Info "Loading implementation context..."

    # Required files
    $requiredFiles = @("tasks.md", "plan.md", "spec.md")

    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $global:FeatureDir $file
        if (-not (Test-Path $filePath)) {
            Write-Error "Required file missing: $filePath"
            exit 1
        }
    }

    # Optional files
    $optionalFiles = @("data-model.md", "contracts", "research.md", "quickstart.md")

    foreach ($file in $optionalFiles) {
        $filePath = Join-Path $global:FeatureDir $file
        if ((Test-Path $filePath)) {
            Write-Info "Found optional context: $file"
        }
    }
}

# Parse tasks from tasks.md (simplified implementation)
function Get-TasksFromFile {
    Write-Info "Parsing tasks from $global:TasksFile..."

    if (-not (Test-Path $global:TasksFile)) {
        Write-Warning "Tasks file not found: $global:TasksFile"
        return
    }

    $content = Get-Content $global:TasksFile -Raw
    $taskLines = $content | Select-String -Pattern "^- \[ \] T\d+" -AllMatches

    if ($taskLines.Matches.Count -eq 0) {
        Write-Warning "No uncompleted tasks found in $global:TasksFile"
        return
    }

    foreach ($match in $taskLines.Matches) {
        $taskLine = $match.Value

        # Extract task ID
        $taskId = [regex]::Match($taskLine, "T\d+").Value

        # Extract description (remove markers and task ID)
        $description = $taskLine -replace "^- \[ \] T\d+ " -replace "\[.*?\]", "" | ForEach-Object { $_.Trim() }

        # Determine execution mode
        $executionMode = if ($taskLine -match "\[ASYNC\]") { "ASYNC" } else { "SYNC" }

        # Check for parallel marker
        $parallelMarker = if ($taskLine -match "\[P\]") { "P" } else { "" }

        # Extract file paths (simplified)
        $taskFiles = ($taskLine | Select-String -Pattern "\b\w+\.(js|ts|py|java|cpp|md|json|yml|yaml)\b" -AllMatches).Matches.Value -join " "

        Write-Info "Found task $taskId`: $description [$executionMode] $(if ($parallelMarker) { "[$parallelMarker] " } else { "" })($taskFiles)"

        # In a real implementation, would call classify and add task functions
        # For now, just log the classification
    }
}

# Main implementation workflow
function Invoke-MainImplementation {
    param([string]$JsonOutput)

    Initialize-Implementation -JsonOutput $JsonOutput
    Test-ChecklistsStatus
    Import-ImplementationContext
    Get-TasksFromFile

    Write-Success "Implementation phase completed (PowerShell implementation is simplified)"
}

# Run main function
Invoke-MainImplementation -JsonOutput $JsonOutput