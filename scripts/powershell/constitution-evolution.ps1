#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Amend,
    [switch]$History,
    [switch]$Diff,
    [switch]$Version,
    [string[]]$ArgsList
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"

$paths = Get-FeaturePathsEnv

$constitutionFile = Join-Path $paths.REPO_ROOT '.specify/memory/constitution.md'
$amendmentLog = Join-Path $paths.REPO_ROOT '.specify/memory/constitution-amendments.log'

# Ensure amendment log exists
$amendmentLogDir = Split-Path $amendmentLog -Parent
if (-not (Test-Path $amendmentLogDir)) {
    New-Item -ItemType Directory -Path $amendmentLogDir -Force | Out-Null
}
if (-not (Test-Path $amendmentLog)) {
    New-Item -ItemType File -Path $amendmentLog -Force | Out-Null
}

# Function to log amendment
function Add-AmendmentLog {
    param([string]$Version, [string]$Author, [string]$Description)

    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
    "$timestamp|$Version|$Author|$Description" | Out-File -FilePath $amendmentLog -Append -Encoding UTF8
}

# Function to get current version
function Get-ConstitutionVersion {
    if (-not (Test-Path $constitutionFile)) {
        return "1.0.0"
    }

    $content = Get-Content $constitutionFile -Raw
    $versionMatch = [regex]::Match($content, '\*\*Version\*\*:\s*([0-9.]+)')

    if ($versionMatch.Success) {
        return $versionMatch.Groups[1].Value
    } else {
        return "1.0.0"
    }
}

# Function to increment version
function Step-Version {
    param([string]$CurrentVersion, [string]$ChangeType)

    $parts = $CurrentVersion -split '\.'
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]

    switch ($ChangeType) {
        "major" {
            $major++
            $minor = 0
            $patch = 0
        }
        "minor" {
            $minor++
            $patch = 0
        }
        "patch" {
            $patch++
        }
        default {
            Write-Error "Invalid change type: $ChangeType"
            return $null
        }
    }

    return "$major.$minor.$patch"
}

# Function to propose amendment
function New-AmendmentProposal {
    param([string]$AmendmentFile)

    if (-not (Test-Path $AmendmentFile)) {
        Write-Error "Amendment file not found: $AmendmentFile"
        exit 1
    }

    $amendmentContent = Get-Content $AmendmentFile -Raw

    # Validate amendment format
    if ($amendmentContent -notmatch '\*\*Proposed Principle:\*\*') {
        Write-Error "Amendment must include '**Proposed Principle:**' section"
        exit 1
    }

    # Generate amendment ID
    $amendmentId = "amendment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    # Create amendment record
    $recordFile = Join-Path $paths.REPO_ROOT ".specify/memory/amendments/$amendmentId.md"
    $recordDir = Split-Path $recordFile -Parent

    if (-not (Test-Path $recordDir)) {
        New-Item -ItemType Directory -Path $recordDir -Force | Out-Null
    }

    $author = git config user.name 2>$null
    if (-not $author) { $author = "Unknown" }

    $recordContent = @"
# Constitution Amendment: $amendmentId

**Status:** Proposed
**Proposed Date:** $(Get-Date -Format 'yyyy-MM-dd')
**Proposed By:** $author

## Amendment Content

$amendmentContent

## Review Status

- [ ] Technical Review
- [ ] Team Approval
- [ ] Implementation

## Comments

"@

    $recordContent | Out-File -FilePath $recordFile -Encoding UTF8

    Write-Host "Amendment proposed: $amendmentId" -ForegroundColor Green
    Write-Host "Review file: $recordFile" -ForegroundColor Yellow

    if ($Json) {
        @{status="proposed"; id=$amendmentId; file=$recordFile} | ConvertTo-Json -Compress
    }
}

# Function to apply amendment
function Apply-Amendment {
    param([string]$AmendmentId, [string]$ChangeType = "minor")

    $recordFile = Join-Path $paths.REPO_ROOT ".specify/memory/amendments/$AmendmentId.md"

    if (-not (Test-Path $recordFile)) {
        Write-Error "Amendment record not found: $recordFile"
        exit 1
    }

    # Check if amendment is approved
    $recordContent = Get-Content $recordFile -Raw
    if ($recordContent -notmatch '\*\*Status:\*\* Approved') {
        Write-Error "Amendment $AmendmentId is not approved for application"
        exit 1
    }

    # Get current version and increment
    $currentVersion = Get-ConstitutionVersion
    $newVersion = Step-Version -CurrentVersion $currentVersion -ChangeType $ChangeType

    # Extract amendment content
    $amendmentContent = ""
    if ($recordContent -match '(?s)## Amendment Content(.*?)(?=## Review Status)') {
        $amendmentContent = $matches[1].Trim()
    }

    # Read current constitution
    $currentConstitution = Get-Content $constitutionFile -Raw

    # Apply amendment
    $updatedConstitution = @"
$currentConstitution

## Amendment: $AmendmentId

$amendmentContent
"@

    # Update version and amendment date
    $today = Get-Date -Format 'yyyy-MM-dd'
    $updatedConstitution = $updatedConstitution -replace '\*\*Version\*\*:.*', "**Version**: $newVersion"
    $updatedConstitution = $updatedConstitution -replace '\*\*Last Amended\*\*:.*', "**Last Amended**: $today"

    # Write updated constitution
    $updatedConstitution | Out-File -FilePath $constitutionFile -Encoding UTF8

    # Log amendment
    $author = ($recordContent | Select-String '\*\*Proposed By:\*\* (.+)').Matches.Groups[1].Value
    $description = ($recordContent | Select-String '\*\*Proposed Principle:\*\* (.+)').Matches.Groups[1].Value

    Add-AmendmentLog -Version $newVersion -Author $author -Description "Applied amendment $AmendmentId`: $description"

    # Update amendment status
    $updatedRecord = $recordContent -replace '\*\*Status:\*\* Approved', '**Status:** Applied'
    $updatedRecord | Out-File -FilePath $recordFile -Encoding UTF8

    Write-Host "Amendment applied: $AmendmentId" -ForegroundColor Green
    Write-Host "New version: $newVersion" -ForegroundColor Green

    if ($Json) {
        @{status="applied"; id=$AmendmentId; version=$newVersion} | ConvertTo-Json -Compress
    }
}

# Function to show history
function Show-AmendmentHistory {
    if (-not (Test-Path $amendmentLog)) {
        Write-Host "No amendment history found" -ForegroundColor Yellow
        return
    }

    $entries = Get-Content $amendmentLog

    if ($Json) {
        $amendments = @()
        foreach ($entry in $entries) {
            $parts = $entry -split '\|', 4
            $amendments += @{
                timestamp = $parts[0]
                version = $parts[1]
                author = $parts[2]
                description = $parts[3]
            }
        }
        @{amendments=$amendments} | ConvertTo-Json -Depth 10
    } else {
        Write-Host "Constitution Amendment History:" -ForegroundColor Cyan
        Write-Host "================================" -ForegroundColor Cyan
        "{0,-20} {1,-10} {2,-20} {3}" -f "Date", "Version", "Author", "Description"
        Write-Host ("-" * 80) -ForegroundColor Gray

        foreach ($entry in $entries) {
            $parts = $entry -split '\|', 4
            $date = ($parts[0] -split 'T')[0]
            "{0,-20} {1,-10} {2,-20} {3}" -f $date, $parts[1], $parts[2], $parts[3]
        }
    }
}

# Function to show diff
function Show-ConstitutionDiff {
    param([string]$Version1 = "HEAD~1", [string]$Version2 = "HEAD")

    try {
        $null = git log --oneline -n 1 -- "$constitutionFile" 2>$null
    } catch {
        Write-Error "Constitution file not under git version control"
        exit 1
    }

    Write-Host "Constitution differences between $Version1 and $Version2`:" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan

    try {
        git diff "$Version1`:$constitutionFile" "$Version2`:$constitutionFile"
    } catch {
        Write-Host "Could not generate diff. Make sure both versions exist." -ForegroundColor Red
        exit 1
    }
}

# Function to manage versions
function Invoke-VersionManagement {
    param([string]$Action, [string]$ChangeType)

    switch ($Action) {
        "current" {
            $version = Get-ConstitutionVersion
            Write-Host "Current constitution version: $version" -ForegroundColor Green
        }
        "bump" {
            if (-not $ChangeType) {
                Write-Error "Must specify change type for version bump (major, minor, patch)"
                exit 1
            }

            $currentVersion = Get-ConstitutionVersion
            $newVersion = Step-Version -CurrentVersion $currentVersion -ChangeType $ChangeType

            # Update constitution
            $content = Get-Content $constitutionFile -Raw
            $content = $content -replace '\*\*Version\*\*:.*', "**Version**: $newVersion"
            $content = $content -replace '\*\*Last Amended\*\*:.*', "**Last Amended**: $(Get-Date -Format 'yyyy-MM-dd')"
            $content | Out-File -FilePath $constitutionFile -Encoding UTF8

            $author = git config user.name 2>$null
            if (-not $author) { $author = "System" }

            Add-AmendmentLog -Version $newVersion -Author $author -Description "Version bump: $ChangeType"

            Write-Host "Version bumped from $currentVersion to $newVersion" -ForegroundColor Green
        }
        default {
            Write-Error "Invalid version action: $Action. Valid actions: current, bump"
            exit 1
        }
    }
}

# Main logic
if ($Amend) {
    if ($ArgsList.Count -eq 0) {
        Write-Error "Must specify amendment file for -Amend"
        exit 1
    }

    $amendmentFile = $ArgsList[0]
    $changeType = if ($ArgsList.Count -gt 1) { $ArgsList[1] } else { "minor" }

    if (Test-Path $amendmentFile) {
        New-AmendmentProposal -AmendmentFile $amendmentFile
    } else {
        Apply-Amendment -AmendmentId $amendmentFile -ChangeType $changeType
    }

} elseif ($History) {
    Show-AmendmentHistory

} elseif ($Diff) {
    $version1 = if ($ArgsList.Count -gt 0) { $ArgsList[0] } else { "HEAD~1" }
    $version2 = if ($ArgsList.Count -gt 1) { $ArgsList[1] } else { "HEAD" }
    Show-ConstitutionDiff -Version1 $version1 -Version2 $Version2

} elseif ($Version) {
    $action = if ($ArgsList.Count -gt 0) { $ArgsList[0] } else { "current" }
    $changeType = if ($ArgsList.Count -gt 1) { $ArgsList[1] } else { $null }
    Invoke-VersionManagement -Action $action -ChangeType $changeType

} else {
    # Default: show current status
    if (-not (Test-Path $constitutionFile)) {
        Write-Host "No constitution found. Run setup-constitution.ps1 first." -ForegroundColor Red
        exit 1
    }

    $currentVersion = Get-ConstitutionVersion
    $amendmentCount = if (Test-Path $amendmentLog) { (Get-Content $amendmentLog).Count } else { 0 }

    if ($Json) {
        @{
            version = $currentVersion
            amendments = $amendmentCount
            file = $constitutionFile
        } | ConvertTo-Json -Compress
    } else {
        Write-Host "Constitution Status:" -ForegroundColor Cyan
        Write-Host "===================" -ForegroundColor Cyan
        Write-Host "Current Version: $currentVersion" -ForegroundColor White
        Write-Host "Total Amendments: $amendmentCount" -ForegroundColor White
        Write-Host "Constitution File: $constitutionFile" -ForegroundColor White
        Write-Host ""
        Write-Host "Available commands:" -ForegroundColor Yellow
        Write-Host "  -History          Show amendment history" -ForegroundColor White
        Write-Host "  -Version current  Show current version" -ForegroundColor White
        Write-Host "  -Version bump <type>  Bump version (major/minor/patch)" -ForegroundColor White
        Write-Host "  -Amend <file>     Propose new amendment" -ForegroundColor White
        Write-Host "  -Amend <id> <type> Apply approved amendment" -ForegroundColor White
        Write-Host "  -Diff [v1] [v2]  Show constitution differences" -ForegroundColor White
    }
}