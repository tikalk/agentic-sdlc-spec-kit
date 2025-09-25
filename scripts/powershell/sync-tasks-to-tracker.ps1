# Script to parse tasks.md and output JSON for issue tracker integration.

param (
    [Parameter(Mandatory=$true)]
    [string]$TasksFile,

    [string]$OutputFile
)

if (-not (Test-Path $TasksFile)) {
    Write-Error "Error: tasks file not found at $TasksFile"
    exit 1
}

$tasks = @()

Get-Content $TasksFile | ForEach-Object {
    $line = $_
    # Regex to match task format: - [ ] T001 [P] [SYNC] Description
    if ($line -match '^- \[ \] (T\d{3}) (\[P\] )?(\[(SYNC|ASYNC)\]) (.*)$') {
        $taskId = $Matches[1]
        $isParallel = $false
        if ($Matches[2] -eq "[P] ") {
            $isParallel = $true
        }
        $taskType = $Matches[3].Trim('[]') # Remove brackets
        $description = $Matches[5].Trim()

        $taskObject = [PSCustomObject]@{
            id = $taskId
            is_parallel = $isParallel
            type = $taskType
            description = $description
        }
        $tasks += $taskObject
    }
}

$jsonOutput = $tasks | ConvertTo-Json -Depth 100 -Compress

if (-not [string]::IsNullOrEmpty($OutputFile)) {
    $jsonOutput | Set-Content $OutputFile -Encoding UTF8
    Write-Host "Tasks successfully parsed and saved to $OutputFile"
} else {
    Write-Host $jsonOutput
    Write-Host "`nTasks successfully parsed and printed to stdout."
}

exit 0