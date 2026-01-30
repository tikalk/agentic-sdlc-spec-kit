#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

if ($Help) {
    Write-Output "Usage: ./prepare-levelup.ps1 [-Json] [-Help]"
    Write-Output "  -Json     Output results in JSON format"
    Write-Output "  -Help     Show this help message"
    exit 0
}

. "$PSScriptRoot/common.ps1"

$paths = Get-FeaturePathsEnv

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit $paths.HAS_GIT)) {
    exit 1
}

$knowledgeRoot = $env:SPECIFY_TEAM_DIRECTIVES
if (-not $knowledgeRoot) {
    $knowledgeRoot = Join-Path $paths.REPO_ROOT '.specify/memory/team-ai-directives'
}

$knowledgeDrafts = $null
if (Test-Path $knowledgeRoot -PathType Container) {
    $knowledgeDrafts = Join-Path $knowledgeRoot 'drafts'
    New-Item -ItemType Directory -Path $knowledgeDrafts -Force | Out-Null
} else {
    $knowledgeRoot = ''
    $knowledgeDrafts = ''
}

# Check for trace file (optional)
$traceFile = Join-Path $paths.FEATURE_DIR 'trace.md'
if (-not (Test-Path $traceFile)) {
    $traceFile = ''
}

if ($Json) {
    $result = [PSCustomObject]@{
        FEATURE_DIR      = $paths.FEATURE_DIR
        BRANCH           = $paths.CURRENT_BRANCH
        SPEC_FILE        = $paths.FEATURE_SPEC
        PLAN_FILE        = $paths.IMPL_PLAN
        TASKS_FILE       = $paths.TASKS
        RESEARCH_FILE    = $paths.RESEARCH
        QUICKSTART_FILE  = $paths.QUICKSTART
        TRACE_FILE       = $traceFile
        KNOWLEDGE_ROOT   = $knowledgeRoot
        KNOWLEDGE_DRAFTS = $knowledgeDrafts
    }
    $result | ConvertTo-Json -Compress
} else {
    Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
    Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
    Write-Output "SPEC_FILE: $($paths.FEATURE_SPEC)"
    Write-Output "PLAN_FILE: $($paths.IMPL_PLAN)"
    Write-Output "TASKS_FILE: $($paths.TASKS)"
    Write-Output "RESEARCH_FILE: $($paths.RESEARCH)"
    Write-Output "QUICKSTART_FILE: $($paths.QUICKSTART)"
    if ($traceFile) {
        Write-Output "TRACE_FILE: $traceFile"
    } else {
        Write-Output "TRACE_FILE: (missing - optional)"
    }
    if ($knowledgeRoot) {
        Write-Output "KNOWLEDGE_ROOT: $knowledgeRoot"
        Write-Output "KNOWLEDGE_DRAFTS: $knowledgeDrafts"
    } else {
        Write-Output "KNOWLEDGE_ROOT: (missing)"
        Write-Output "KNOWLEDGE_DRAFTS: (missing)"
    }
}
