# scripts/powershell/levelup.ps1
# Entrypoint for the /levelup command (PowerShell)
# Usage: scripts/powershell/levelup.ps1 -Description "<knowledge description>"

param(
    [Parameter(Mandatory=$true)]
    [string]$Description
)

if (-not $Description) {
    Write-Error "Usage: scripts/powershell/levelup.ps1 -Description '<knowledge description>'"
    exit 1
}

$coreScript = ".specify/scripts/powershell/levelup.ps1"
if (-not (Test-Path $coreScript)) {
    Write-Error "Error: Core script $coreScript not found. Please implement the core logic."
    exit 2
}

# Call the core logic script with the description
& $coreScript -Description $Description
