#!/usr/bin/env pwsh
# Verify that generated files contain current dates (not stale [DATE] placeholders)
# Usage: verify-dates.ps1 [-FeaturePath <path>]
#        verify-dates.ps1                           # Checks current feature based on branch
#        verify-dates.ps1 -FeaturePath specs/001-feature  # Checks specific feature directory

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$FeaturePath
)

$ErrorActionPreference = 'Stop'

# Resolve repository root
function Find-RepositoryRoot {
    param(
        [string]$StartDir,
        [string[]]$Markers = @('.git', '.specify')
    )
    $current = Resolve-Path $StartDir
    while ($true) {
        foreach ($marker in $Markers) {
            if (Test-Path (Join-Path $current $marker)) {
                return $current
            }
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) {
            return $null
        }
        $current = $parent
    }
}

# Determine repo root
try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Git not available"
    }
} catch {
    $repoRoot = Find-RepositoryRoot -StartDir $PSScriptRoot
    if (-not $repoRoot) {
        Write-Error "Error: Could not determine repository root."
        exit 1
    }
}

# Determine feature directory
if ($FeaturePath) {
    if ([System.IO.Path]::IsPathRooted($FeaturePath)) {
        $featureDir = $FeaturePath
    } else {
        $featureDir = Join-Path $repoRoot $FeaturePath
    }
} else {
    # Auto-detect from current branch or SPECIFY_FEATURE env var
    if ($env:SPECIFY_FEATURE) {
        $featureDir = Join-Path $repoRoot "specs/$($env:SPECIFY_FEATURE)"
    } else {
        try {
            $branch = git rev-parse --abbrev-ref HEAD 2>$null
            if ($LASTEXITCODE -eq 0 -and $branch) {
                $featureDir = Join-Path $repoRoot "specs/$branch"
            } else {
                throw "Could not determine branch"
            }
        } catch {
            Write-Error "Error: Could not determine feature directory. Please provide a path."
            exit 1
        }
    }
}

if (-not (Test-Path $featureDir -PathType Container)) {
    Write-Error "Error: Feature directory not found: $featureDir"
    exit 1
}

# Get current date in ISO format
$currentDate = Get-Date -Format "yyyy-MM-dd"
$currentYear = (Get-Date).Year

# Track issues found
$issuesFound = 0
$filesChecked = 0

Write-Host "=============================================="
Write-Host "Date Verification Report"
Write-Host "=============================================="
Write-Host "Feature Directory: $featureDir"
Write-Host "Current Date: $currentDate"
Write-Host "=============================================="
Write-Host ""

# Function to check a file for date issues
function Test-FileDate {
    param([string]$FilePath)
    
    $fileName = Split-Path $FilePath -Leaf
    
    if (-not (Test-Path $FilePath)) {
        return 0
    }
    
    $script:filesChecked++
    
    $content = Get-Content -Path $FilePath -Raw
    
    # Check for remaining [DATE] placeholders
    if ($content -match '\[DATE\]') {
        Write-Host "X FAIL: $fileName contains unresolved [DATE] placeholder" -ForegroundColor Red
        $script:issuesFound++
        return 1
    }
    
    # Check if file contains any date in ISO format
    if ($content -match '(\d{4})-(\d{2})-(\d{2})') {
        $foundDate = $Matches[0]
        $foundYear = [int]$Matches[1]
        
        # Check if date is in the future (more than current year) - likely incorrect
        if ($foundYear -gt $currentYear) {
            Write-Host "! WARN: $fileName contains future date: $foundDate" -ForegroundColor Yellow
            $script:issuesFound++
            return 1
        }
        
        # Check if date matches current date (ideal case)
        if ($foundDate -eq $currentDate) {
            Write-Host "V PASS: $fileName has current date ($foundDate)" -ForegroundColor Green
        } else {
            Write-Host "i INFO: $fileName has date: $foundDate (not today, but valid)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "i INFO: $fileName has no ISO date (may be okay depending on template)" -ForegroundColor Cyan
    }
    
    return 0
}

Write-Host "Checking files..."
Write-Host ""

# Check all relevant files
Test-FileDate -FilePath (Join-Path $featureDir "spec.md") | Out-Null
Test-FileDate -FilePath (Join-Path $featureDir "plan.md") | Out-Null
Test-FileDate -FilePath (Join-Path $featureDir "context.md") | Out-Null
Test-FileDate -FilePath (Join-Path $featureDir "tasks.md") | Out-Null
Test-FileDate -FilePath (Join-Path $featureDir "checklist.md") | Out-Null

Write-Host ""
Write-Host "=============================================="
Write-Host "Summary"
Write-Host "=============================================="
Write-Host "Files Checked: $filesChecked"
Write-Host "Issues Found: $issuesFound"

if ($issuesFound -eq 0) {
    Write-Host ""
    Write-Host "V All dates verified successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "X Found $issuesFound issue(s) that need attention." -ForegroundColor Red
    exit 1
}
