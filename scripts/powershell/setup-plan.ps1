#!/usr/bin/env pwsh
# Setup implementation plan for a feature

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output "Usage: ./setup-plan.ps1 [-Json] [-Help]"
    Write-Output "  -Json     Output results in JSON format"
    Write-Output "  -Help     Show this help message"
    exit 0
}

# Load common functions
. "$PSScriptRoot/common.ps1"

# Get all paths and variables from common functions
$paths = Get-FeaturePathsEnv

# Check if we're on a proper feature branch (only for git repos)
if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit $paths.HAS_GIT)) { 
    exit 1 
}

# Ensure the feature directory exists
New-Item -ItemType Directory -Path $paths.FEATURE_DIR -Force | Out-Null

# Detect current workflow mode and select appropriate plan template
$currentMode = Get-CurrentMode

if ($currentMode -eq 'build') {
    $template = Join-Path $paths.REPO_ROOT '.specify/templates/plan-template-build.md'
} else {
    $template = Join-Path $paths.REPO_ROOT '.specify/templates/plan-template.md'
}

if (Test-Path $template) { 
    Copy-Item $template $paths.IMPL_PLAN -Force
    Write-Output "Copied plan template to $($paths.IMPL_PLAN)"
} else {
    Write-Warning "Plan template not found at $template"
    # Create a basic plan file if template doesn't exist
    New-Item -ItemType File -Path $paths.IMPL_PLAN -Force | Out-Null
}

$constitutionFile = $env:SPECIFY_CONSTITUTION
if (-not $constitutionFile) {
    $constitutionFile = Join-Path $paths.REPO_ROOT '.specify/memory/constitution.md'
}
if (Test-Path $constitutionFile) {
    $env:SPECIFY_CONSTITUTION = $constitutionFile
} else {
    $constitutionFile = ''
}

$teamDirectives = $env:SPECIFY_TEAM_DIRECTIVES
if (-not $teamDirectives) {
    $teamDirectives = Join-Path $paths.REPO_ROOT '.specify/memory/team-ai-directives'
}
if (Test-Path $teamDirectives) {
    $env:SPECIFY_TEAM_DIRECTIVES = $teamDirectives
} else {
    $teamDirectives = ''
}

# Resolve architecture path (prefer env override, silent if missing)
$architectureFile = $env:SPECIFY_ARCHITECTURE
if (-not $architectureFile) {
    $architectureFile = Join-Path $paths.REPO_ROOT '.specify/memory/architecture.md'
}
if (Test-Path $architectureFile) {
    $env:SPECIFY_ARCHITECTURE = $architectureFile
} else {
    $architectureFile = ''
}

# Output results
if ($Json) {
    $result = [PSCustomObject]@{ 
        FEATURE_SPEC = $paths.FEATURE_SPEC
        IMPL_PLAN = $paths.IMPL_PLAN
        SPECS_DIR = $paths.FEATURE_DIR
        BRANCH = $paths.CURRENT_BRANCH
        HAS_GIT = $paths.HAS_GIT
        CONSTITUTION = $constitutionFile
        TEAM_DIRECTIVES = $teamDirectives
        ARCHITECTURE = $architectureFile
    }
    $result | ConvertTo-Json -Compress
} else {
    Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
    Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
    Write-Output "SPECS_DIR: $($paths.FEATURE_DIR)"
    Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
    Write-Output "HAS_GIT: $($paths.HAS_GIT)"
    if ($constitutionFile) {
        Write-Output "CONSTITUTION: $constitutionFile"
    } else {
        Write-Output "CONSTITUTION: (missing)"
    }
    if ($teamDirectives) {
        Write-Output "TEAM_DIRECTIVES: $teamDirectives"
    } else {
        Write-Output "TEAM_DIRECTIVES: (missing)"
    }
    if ($architectureFile) {
        Write-Output "ARCHITECTURE: $architectureFile"
    } else {
        Write-Output "ARCHITECTURE: (missing)"
    }
}
