# Setup script for LevelUp extension
# Initializes CDR file and resolves team-ai-directives path

param(
    [switch]$Json,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: setup-levelup.ps1 [-Json]"
    Write-Host "  -Json    Output results in JSON format"
    Write-Host "  -Help    Show this help message"
    exit 0
}

# Get repository root
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    $repoRoot = Get-Location
}

# Resolve team-ai-directives path
# Priority:
# 1. SPECIFY_TEAM_DIRECTIVES environment variable
# 2. .specify/team-ai-directives (submodule - recommended)
# 3. .specify/memory/team-ai-directives (clone - legacy)

$teamDirectives = $env:SPECIFY_TEAM_DIRECTIVES

if (-not $teamDirectives) {
    $submodulePath = Join-Path $repoRoot ".specify/team-ai-directives"
    $clonePath = Join-Path $repoRoot ".specify/memory/team-ai-directives"
    
    if (Test-Path $submodulePath) {
        $teamDirectives = $submodulePath
    } elseif (Test-Path $clonePath) {
        $teamDirectives = $clonePath
    }
}

# CDR file location
$cdrFile = Join-Path $repoRoot ".specify/memory/cdr.md"
$cdrDir = Split-Path $cdrFile -Parent

# Skills drafts location
$skillsDrafts = Join-Path $repoRoot ".specify/drafts/skills"

# Ensure directories exist
if (-not (Test-Path $cdrDir)) {
    New-Item -ItemType Directory -Path $cdrDir -Force | Out-Null
}
if (-not (Test-Path $skillsDrafts)) {
    New-Item -ItemType Directory -Path $skillsDrafts -Force | Out-Null
}

# Initialize CDR file if it doesn't exist
if (-not (Test-Path $cdrFile)) {
    $cdrTemplate = @"
# Context Decision Records

Context Decision Records (CDRs) track decisions about contributing context modules (rules, personas, examples, skills) to team-ai-directives.

## CDR Index

| ID | Target Module | Context Type | Status | Date | Source |
|----|---------------|--------------|--------|------|--------|

---

<!-- CDRs will be appended below -->
"@
    Set-Content -Path $cdrFile -Value $cdrTemplate
}

# Get current git branch
$currentBranch = ""
try {
    $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
} catch {
    $currentBranch = ""
}

# Check if team directives exists
$teamDirectivesExists = $false
if ($teamDirectives -and (Test-Path $teamDirectives)) {
    $teamDirectivesExists = $true
}

# Output results
if ($Json) {
    $output = @{
        REPO_ROOT = $repoRoot
        CDR_FILE = $cdrFile
        TEAM_DIRECTIVES = if ($teamDirectives) { $teamDirectives } else { "" }
        TEAM_DIRECTIVES_EXISTS = $teamDirectivesExists
        SKILLS_DRAFTS = $skillsDrafts
        BRANCH = $currentBranch
    }
    $output | ConvertTo-Json -Compress
} else {
    Write-Host "REPO_ROOT: $repoRoot"
    Write-Host "CDR_FILE: $cdrFile"
    if ($teamDirectives) {
        Write-Host "TEAM_DIRECTIVES: $teamDirectives"
        Write-Host "TEAM_DIRECTIVES_EXISTS: $teamDirectivesExists"
    } else {
        Write-Host "TEAM_DIRECTIVES: (not configured)"
        Write-Host "TEAM_DIRECTIVES_EXISTS: false"
    }
    Write-Host "SKILLS_DRAFTS: $skillsDrafts"
    Write-Host "BRANCH: $currentBranch"
}
