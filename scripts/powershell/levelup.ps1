# levelup.ps1 - Automate knowledge asset creation and trace summary for /levelup command
param(
    [Parameter(Mandatory=$true)]
    [string]$Message
)

$repoRoot = (git rev-parse --show-toplevel 2>$null) -or (Get-Location)

if (-not $Message) {
    Write-Host "Usage: ./levelup.ps1 \"levelup message\""
    exit 1
}

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$assetPath = Join-Path $repoRoot "context_modules/rules/v1/levelup-$timestamp.md"

@"
# Levelup Knowledge Asset

$Message

---
Created: $(Get-Date)
"@ | Set-Content $assetPath

Write-Host "Created knowledge asset: $assetPath"
# TODO: Add git branch, PR, and trace summary automation
