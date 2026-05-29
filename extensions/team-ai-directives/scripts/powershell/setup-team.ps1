# Setup script for Team AI Directives extension
# Resolves team-ai-directives path and outputs environment info

param(
    [switch]$Json,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: setup-team.ps1 [-Json]"
    Write-Host "  -Json    Output results in JSON format"
    Write-Host "  -Help    Show this help message"
    exit 0
}

# Get script directory for common.ps1 sourcing
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Find project root by walking up from script location
function Get-ProjectRoot {
    param([string]$StartPath)
    $dir = $StartPath
    while ($dir -ne "") {
        if ((Test-Path "$dir\.specify") -or (Test-Path "$dir\.git")) {
            return $dir
        }
        $dir = Split-Path $dir -Parent
    }
    return $StartPath
}

$projectRoot = Get-ProjectRoot $scriptDir

# Load common functions - use absolute path from project root
$commonPath = "$projectRoot\.specify\scripts\powershell\common.ps1"
if (Test-Path $commonPath) {
    . $commonPath
} elseif (Test-Path "$scriptDir\common.ps1") {
    . "$scriptDir\common.ps1"
}

# Get repository root using common.ps1 function
$repoRoot = Get-RepoRoot

# Resolve team-ai-directives path using centralized function
$teamDirectives = Load-TeamDirectivesConfig

# Get current git branch
$currentBranch = ""
try {
    $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
} catch {
    $currentBranch = ""
}

# Output results
if ($Json) {
    $output = @{
        REPO_ROOT = $repoRoot
        TEAM_DIRECTIVES = if ($teamDirectives) { $teamDirectives } else { "" }
        BRANCH = $currentBranch
    }
    $output | ConvertTo-Json -Compress
} else {
    Write-Host "REPO_ROOT: $repoRoot"
    if ($teamDirectives) {
        Write-Host "TEAM_DIRECTIVES: $teamDirectives"
    } else {
        Write-Host "TEAM_DIRECTIVES: (not configured)"
    }
    Write-Host "BRANCH: $currentBranch"
}
