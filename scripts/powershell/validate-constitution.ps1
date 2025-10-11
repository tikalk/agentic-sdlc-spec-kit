#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Strict,
    [switch]$Compliance,
    [string]$ConstitutionFile
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"

$paths = Get-FeaturePathsEnv

if (-not $ConstitutionFile) {
    $ConstitutionFile = Join-Path $paths.REPO_ROOT '.specify/memory/constitution.md'
}

# Validation results structure
$validationResults = @{}

# Function to add validation result
function Add-ValidationResult {
    param([string]$Category, [string]$Check, [string]$Status, [string]$Message)

    if (-not $validationResults.ContainsKey($Category)) {
        $validationResults[$Category] = @()
    }

    $validationResults[$Category] += @{
        check = $Check
        status = $Status
        message = $Message
    }
}

# Function to validate constitution file exists
function Test-ConstitutionFileExists {
    if (-not (Test-Path $ConstitutionFile)) {
        Add-ValidationResult "critical" "file_exists" "fail" "Constitution file not found at $ConstitutionFile"
        return $false
    }
    Add-ValidationResult "basic" "file_exists" "pass" "Constitution file found"
    return $true
}

# Function to validate basic structure
function Test-ConstitutionStructure {
    param([string]$Content)

    # Check for required sections
    if ($Content -notmatch '^# .* Constitution') {
        Add-ValidationResult "structure" "title" "fail" "Constitution must have a title starting with '# ... Constitution'"
        return $false
    }
    Add-ValidationResult "structure" "title" "pass" "Title format correct"

    if ($Content -notmatch '^## Core Principles') {
        Add-ValidationResult "structure" "core_principles" "fail" "Constitution must have '## Core Principles' section"
        return $false
    }
    Add-ValidationResult "structure" "core_principles" "pass" "Core Principles section present"

    if ($Content -notmatch '^##.*Governance') {
        Add-ValidationResult "structure" "governance" "fail" "Constitution must have a Governance section"
        return $false
    }
    Add-ValidationResult "structure" "governance" "pass" "Governance section present"

    return $true
}

# Function to validate principle quality
function Test-PrincipleQuality {
    param([string]$Content)

    # Extract principles
    $principles = [regex]::Matches($Content, '^### (.+)', [System.Text.RegularExpressions.RegexOptions]::Multiline) |
        ForEach-Object { $_.Groups[1].Value }

    $principleCount = $principles.Count

    foreach ($principle in $principles) {
        # Check principle name quality
        if ($principle.Length -lt 10) {
            Add-ValidationResult "quality" "principle_name_length" "warn" "Principle '$principle' name is very short"
        } elseif ($principle.Length -gt 80) {
            Add-ValidationResult "quality" "principle_name_length" "warn" "Principle '$principle' name is very long"
        } else {
            Add-ValidationResult "quality" "principle_name_length" "pass" "Principle '$principle' name length appropriate"
        }

        # Check for vague language
        if ($principle -match '(?i)should|may|might|try|consider') {
            Add-ValidationResult "quality" "principle_clarity" "warn" "Principle '$principle' contains vague language (should/may/might/try/consider)"
        } else {
            Add-ValidationResult "quality" "principle_clarity" "pass" "Principle '$principle' uses clear language"
        }
    }

    if ($principleCount -lt 3) {
        Add-ValidationResult "quality" "principle_count" "warn" "Only $principleCount principles found (recommended: 3-7)"
    } elseif ($principleCount -gt 10) {
        Add-ValidationResult "quality" "principle_count" "warn" "$principleCount principles found (consider consolidating)"
    } else {
        Add-ValidationResult "quality" "principle_count" "pass" "$principleCount principles (appropriate range)"
    }
}

# Function to validate versioning
function Test-ConstitutionVersioning {
    param([string]$Content)

    # Check for version line
    if ($Content -notmatch '\*\*Version\*\*:') {
        Add-ValidationResult "versioning" "version_present" "fail" "Version information not found"
        return $false
    }
    Add-ValidationResult "versioning" "version_present" "pass" "Version information present"

    # Extract version
    $versionMatch = [regex]::Match($Content, '\*\*Version\*\*:\s*([0-9.]+)')
    if (-not $versionMatch.Success) {
        Add-ValidationResult "versioning" "version_format" "fail" "Could not parse version number"
        return $false
    }

    $version = $versionMatch.Groups[1].Value

    # Check semantic versioning format
    if ($version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
        Add-ValidationResult "versioning" "version_format" "warn" "Version '$version' does not follow semantic versioning (X.Y.Z)"
    } else {
        Add-ValidationResult "versioning" "version_format" "pass" "Version follows semantic versioning"
    }

    # Check dates
    $ratifiedMatch = [regex]::Match($Content, '\*\*Ratified\*\*:\s*([0-9-]+)')
    $amendedMatch = [regex]::Match($Content, '\*\*Last Amended\*\*:\s*([0-9-]+)')

    if (-not $ratifiedMatch.Success) {
        Add-ValidationResult "versioning" "ratified_date" "fail" "Ratification date not found"
    } elseif ($ratifiedMatch.Groups[1].Value -notmatch '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') {
        Add-ValidationResult "versioning" "ratified_date" "warn" "Ratification date '$($ratifiedMatch.Groups[1].Value)' not in YYYY-MM-DD format"
    } else {
        Add-ValidationResult "versioning" "ratified_date" "pass" "Ratification date format correct"
    }

    if (-not $amendedMatch.Success) {
        Add-ValidationResult "versioning" "amended_date" "fail" "Last amended date not found"
    } elseif ($amendedMatch.Groups[1].Value -notmatch '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') {
        Add-ValidationResult "versioning" "amended_date" "warn" "Last amended date '$($amendedMatch.Groups[1].Value)' not in YYYY-MM-DD format"
    } else {
        Add-ValidationResult "versioning" "amended_date" "pass" "Last amended date format correct"
    }

    return $true
}

# Function to validate team compliance
function Test-TeamCompliance {
    param([string]$Content)

    # Load team constitution
    $teamConstitution = ""
    $teamDirectives = Get-TeamDirectivesPath

    if ($teamDirectives -and (Test-Path $teamDirectives)) {
        $constitutionPath = Join-Path $teamDirectives "constitution.md"
        if (-not (Test-Path $constitutionPath)) {
            $constitutionPath = Join-Path $teamDirectives "context_modules/constitution.md"
        }

        if (Test-Path $constitutionPath) {
            $teamConstitution = Get-Content $constitutionPath -Raw
        }
    }

    if (-not $teamConstitution) {
        Add-ValidationResult "compliance" "team_constitution" "warn" "Team constitution not found - cannot validate compliance"
        return $true
    }

    Add-ValidationResult "compliance" "team_constitution" "pass" "Team constitution found"

    # Extract team principles
    $teamPrinciples = [regex]::Matches($teamConstitution, '^\d+\. \*\*(.+?)\*\*', [System.Text.RegularExpressions.RegexOptions]::Multiline) |
        ForEach-Object { $_.Groups[1].Value }

    # Check each team principle is represented
    $missingPrinciples = @()
    foreach ($principle in $teamPrinciples) {
        if ($principle -and $Content -notmatch [regex]::Escape($principle)) {
            $missingPrinciples += $principle
        }
    }

    if ($missingPrinciples.Count -gt 0) {
        Add-ValidationResult "compliance" "team_principles" "fail" "Missing team principles: $($missingPrinciples -join ', ')"
        return $false
    } else {
        Add-ValidationResult "compliance" "team_principles" "pass" "All team principles represented"
        return $true
    }
}

# Function to check for conflicts
function Test-ConstitutionConflicts {
    param([string]$Content)

    $conflictsFound = 0

    # Look for contradictory terms
    if ($Content -match '(?i)must.*never|never.*must|required.*forbidden|forbidden.*required') {
        Add-ValidationResult "conflicts" "contradictory_terms" "warn" "Found potentially contradictory terms (must/never, required/forbidden)"
        $conflictsFound++
    }

    # Check for duplicate principles
    $principleNames = [regex]::Matches($Content, '^### (.+)', [System.Text.RegularExpressions.RegexOptions]::Multiline) |
        ForEach-Object { $_.Groups[1].Value.ToLower() }

    $duplicates = @()
    $seen = @{}
    foreach ($name in $principleNames) {
        if ($seen.ContainsKey($name)) {
            $duplicates += $name
        } else {
            $seen[$name] = $true
        }
    }

    if ($duplicates.Count -gt 0) {
        Add-ValidationResult "conflicts" "duplicate_principles" "warn" "Duplicate principle names found: $($duplicates -join ', ')"
        $conflictsFound++
    }

    if ($conflictsFound -eq 0) {
        Add-ValidationResult "conflicts" "no_conflicts" "pass" "No obvious conflicts detected"
    }

    return $conflictsFound -eq 0
}

# Main validation logic
if (-not (Test-ConstitutionFileExists)) {
    if ($Json) {
        $validationResults | ConvertTo-Json -Depth 10
    } else {
        Write-Host "CRITICAL: Constitution file not found" -ForegroundColor Red
        exit 1
    }
}

# Read constitution content
$content = Get-Content $ConstitutionFile -Raw

# Run validations
Test-ConstitutionStructure -Content $content
Test-PrincipleQuality -Content $content
Test-ConstitutionVersioning -Content $content

if ($Compliance) {
    Test-TeamCompliance -Content $content
}

Test-ConstitutionConflicts -Content $content

# Calculate overall status
$criticalFails = ($validationResults.critical | Where-Object { $_.status -eq "fail" }).Count
$structureFails = ($validationResults.structure | Where-Object { $_.status -eq "fail" }).Count
$qualityFails = ($validationResults.quality | Where-Object { $_.status -eq "fail" }).Count
$versioningFails = ($validationResults.versioning | Where-Object { $_.status -eq "fail" }).Count
$complianceFails = ($validationResults.compliance | Where-Object { $_.status -eq "fail" }).Count

$totalFails = $criticalFails + $structureFails + $qualityFails + $versioningFails + $complianceFails

$warnings = 0
foreach ($category in $validationResults.Keys) {
    $warnings += ($validationResults[$category] | Where-Object { $_.status -eq "warn" }).Count
}

if ($totalFails -gt 0) {
    $overallStatus = "fail"
} elseif ($Strict -and $warnings -gt 0) {
    $overallStatus = "fail"
} else {
    $overallStatus = "pass"
}

$validationResults.overall = $overallStatus

# Output results
if ($Json) {
    $validationResults | ConvertTo-Json -Depth 10
} else {
    Write-Host "Constitution Validation Results for: $ConstitutionFile" -ForegroundColor Cyan
    Write-Host "Overall Status: $($overallStatus.ToUpper())" -ForegroundColor $(if ($overallStatus -eq "pass") { "Green" } else { "Red" })
    Write-Host ""

    # Display results by category
    foreach ($category in $validationResults.Keys) {
        if ($category -eq "overall") { continue }

        Write-Host "$category checks:" -ForegroundColor Yellow
        foreach ($result in $validationResults[$category]) {
            $color = switch ($result.status) {
                "pass" { "Green" }
                "fail" { "Red" }
                "warn" { "Yellow" }
            }
            Write-Host "  [$($result.status.ToUpper())] $($result.check): $($result.message)" -ForegroundColor $color
        }
        Write-Host ""
    }

    if ($overallStatus -eq "fail") {
        Write-Host "❌ Validation failed - address the issues above" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "✅ Validation passed" -ForegroundColor Green
    }
}