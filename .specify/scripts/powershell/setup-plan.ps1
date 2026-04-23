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
    $template = Resolve-Template -TemplateName 'plan-template-build' -RepoRoot $paths.REPO_ROOT
} else {
    $template = Resolve-Template -TemplateName 'plan-template' -RepoRoot $paths.REPO_ROOT
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
    $projectConfig = Join-Path $paths.REPO_ROOT ".specify\config.json"
    if (Test-Path $projectConfig) {
        try {
            $config = Get-Content $projectConfig -Raw | ConvertFrom-Json
            $teamDirectives = $config.team_directives.path
        } catch {}
    }
}
if (-not $teamDirectives) {
    $teamDirectives = Join-Path $paths.REPO_ROOT ".specify\memory\team-ai-directives"
}
$teamAgentsMd = ''
if (Test-Path $teamDirectives) {
    $env:SPECIFY_TEAM_DIRECTIVES = $teamDirectives
    # Check for team-level AGENTS.md
    $teamAgentsMd = Join-Path $teamDirectives 'AGENTS.md'
    if (-not (Test-Path $teamAgentsMd)) {
        $teamAgentsMd = ''
    }
} else {
    $teamDirectives = ''
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
        TEAM_AGENTS_MD = $teamAgentsMd
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
        if ($teamAgentsMd) {
            Write-Output "TEAM_AGENTS_MD: $teamAgentsMd"
        } else {
            Write-Output "TEAM_AGENTS_MD: (missing)"
        }
    } else {
        Write-Output "TEAM_DIRECTIVES: (missing)"
        Write-Output "TEAM_AGENTS_MD: (missing)"
    }
}
