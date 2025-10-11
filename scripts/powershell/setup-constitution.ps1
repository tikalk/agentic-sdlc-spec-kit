# Setup project constitution with team inheritance
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Validate
)

$ErrorActionPreference = 'Stop'

# Import common functions (assuming they exist)
# . "$PSScriptRoot\common.ps1"

# Get repository root
function Get-RepositoryRoot {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        try {
            $gitRoot = & git rev-parse --show-toplevel 2>$null
            if ($gitRoot) { return $gitRoot }
        } catch { }
    }

    # Fallback: search for repository markers
    $currentDir = Get-Location
    while ($currentDir -and (Test-Path $currentDir)) {
        if ((Test-Path "$currentDir\.git") -or (Test-Path "$currentDir\.specify")) {
            return $currentDir
        }
        $currentDir = Split-Path $currentDir -Parent
    }

    throw "Could not determine repository root"
}

# Get team directives path
function Get-TeamDirectivesPath {
    $repoRoot = Get-RepositoryRoot
    $configFile = Join-Path $repoRoot ".specify\config\team_directives.path"

    if (Test-Path $configFile) {
        $path = Get-Content $configFile -Raw -ErrorAction SilentlyContinue
        if ($path -and (Test-Path $path.Trim())) {
            return $path.Trim()
        }
    }

    # Fallback to default location
    $defaultDir = Join-Path $repoRoot ".specify\memory\team-ai-directives"
    if (Test-Path $defaultDir) {
        return $defaultDir
    }

    return $null
}

# Load team constitution
function Get-TeamConstitution {
    $teamDirectives = Get-TeamDirectivesPath

    if ($teamDirectives -and (Test-Path $teamDirectives)) {
        # Try direct constitution.md
        $constitutionFile = Join-Path $teamDirectives "constitution.md"
        if (Test-Path $constitutionFile) {
            return Get-Content $constitutionFile -Raw
        }

        # Try context_modules/constitution.md
        $constitutionFile = Join-Path $teamDirectives "context_modules\constitution.md"
        if (Test-Path $constitutionFile) {
            return Get-Content $constitutionFile -Raw
        }
    }

    # Default constitution if none found
    return @"
# Project Constitution

## Core Principles

### Principle 1: Quality First
All code must meet quality standards and include appropriate testing.

### Principle 2: Documentation Required
Clear documentation must accompany all significant changes.

### Principle 3: Security by Default
Security considerations must be addressed for all features.

## Governance

**Version**: 1.0.0 | **Ratified**: $(Get-Date -Format 'yyyy-MM-dd') | **Last Amended**: $(Get-Date -Format 'yyyy-MM-dd')

*This constitution was auto-generated from team defaults. Customize as needed for your project.*
"@
}

# Enhance constitution with project context
function Add-ProjectContext {
    param([string]$Constitution)

    $repoRoot = Get-RepositoryRoot
    $projectName = Split-Path $repoRoot -Leaf

    # Add project header if not present
    if ($Constitution -notmatch "^# $projectName Constitution") {
        $inheritanceDate = Get-Date -Format 'yyyy-MM-dd'
        $Constitution = "# $projectName Constitution

*Inherited from team constitution on $inheritanceDate*

$Constitution"
    }

    return $Constitution
}

# Validate inheritance
function Test-ConstitutionInheritance {
    param([string]$TeamConstitution, [string]$ProjectConstitution)

    # Extract team principles (simple pattern match)
    $teamPrinciples = @()
    if ($TeamConstitution -match '^\d+\.\s*\*\*(.+?)\*\*') {
        $matches = [regex]::Matches($TeamConstitution, '^\d+\.\s*\*\*(.+?)\*\*', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        foreach ($match in $matches) {
            $teamPrinciples += $match.Groups[1].Value
        }
    }

    # Check if project contains team principles
    $missingPrinciples = @()
    foreach ($principle in $teamPrinciples) {
        if ($ProjectConstitution -notmatch [regex]::Escape($principle)) {
            $missingPrinciples += $principle
        }
    }

    if ($missingPrinciples.Count -gt 0) {
        Write-Warning "Project constitution may be missing some team principles: $($missingPrinciples -join ', ')"
        Write-Host "Consider ensuring all team principles are represented in your project constitution."
        return $false
    } else {
        Write-Host "✓ Inheritance validation passed - all team principles detected in project constitution"
        return $true
    }
}

# Check for team constitution updates
function Test-TeamConstitutionUpdates {
    param([string]$TeamConstitution, [string]$ProjectConstitution)

    if ($ProjectConstitution -match 'Inherited from team constitution on (\d{4}-\d{2}-\d{2})') {
        $inheritanceDate = $matches[1]

        $teamDirectives = Get-TeamDirectivesPath
        if ($teamDirectives) {
            $constitutionFile = Join-Path $teamDirectives "context_modules\constitution.md"
            if (-not (Test-Path $constitutionFile)) {
                $constitutionFile = Join-Path $teamDirectives "constitution.md"
            }

            if (Test-Path $constitutionFile) {
                $teamFileInfo = Get-Item $constitutionFile
                $inheritanceDateTime = [DateTime]::Parse($inheritanceDate)

                if ($teamFileInfo.LastWriteTime -gt $inheritanceDateTime) {
                    Write-Host "NOTICE: Team constitution has been updated since project constitution was created."
                    Write-Host "Consider reviewing the team constitution for any changes that should be reflected in your project."
                    Write-Host "Team constitution: $constitutionFile"
                }
            }
        }
    }
}

# Main logic
try {
    $repoRoot = Get-RepositoryRoot
    $constitutionFile = Join-Path $repoRoot ".specify\memory\constitution.md"

    # Ensure directory exists
    $constitutionDir = Split-Path $constitutionFile -Parent
    if (-not (Test-Path $constitutionDir)) {
        New-Item -ItemType Directory -Path $constitutionDir -Force | Out-Null
    }

    if ($Validate) {
        if (-not (Test-Path $constitutionFile)) {
            Write-Error "No constitution file found at $constitutionFile. Run without --validate to create the constitution first."
            exit 1
        }

        $teamConstitution = Get-TeamConstitution
        $projectConstitution = Get-Content $constitutionFile -Raw

        if ($Json) {
            $result = @{
                status = "validated"
                file = $constitutionFile
                team_directives = (Get-TeamDirectivesPath)
            } | ConvertTo-Json -Compress
            Write-Host $result
        } else {
            Write-Host "Validating constitution at: $constitutionFile"
            Write-Host "Team directives source: $(Get-TeamDirectivesPath)"
            Write-Host ""
            Test-ConstitutionInheritance -TeamConstitution $teamConstitution -ProjectConstitution $projectConstitution
            Write-Host ""
            Test-TeamConstitutionUpdates -TeamConstitution $teamConstitution -ProjectConstitution $projectConstitution
        }
        exit 0
    }

    if (Test-Path $constitutionFile) {
        Write-Host "Constitution file already exists at $constitutionFile"
        Write-Host "Use git to modify it directly, or remove it to recreate from team directives."

        # Check for updates
        $teamConstitution = Get-TeamConstitution
        $existingConstitution = Get-Content $constitutionFile -Raw
        Test-TeamConstitutionUpdates -TeamConstitution $teamConstitution -ProjectConstitution $existingConstitution
        Write-Host ""

        if ($Json) {
            $result = @{ status = "exists"; file = $constitutionFile } | ConvertTo-Json -Compress
            Write-Host $result
        }
        exit 0
    }

    # Create new constitution
    $teamConstitution = Get-TeamConstitution
    $projectConstitution = Add-ProjectContext -Constitution $teamConstitution

    # Validate inheritance
    if (-not $Json) {
        Test-ConstitutionInheritance -TeamConstitution $teamConstitution -ProjectConstitution $projectConstitution
        Write-Host ""
    }

    # Write constitution
    $projectConstitution | Out-File -FilePath $constitutionFile -Encoding UTF8

    # Output results
    if ($Json) {
        $result = @{
            status = "created"
            file = $constitutionFile
            team_directives = (Get-TeamDirectivesPath)
        } | ConvertTo-Json -Compress
        Write-Host $result
    } else {
        Write-Host "Constitution created at: $constitutionFile"
        Write-Host "Team directives source: $(Get-TeamDirectivesPath)"
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "1. Review and customize the constitution for your project needs"
        Write-Host "2. Commit the constitution: git add .specify/memory/constitution.md && git commit -m 'docs: initialize project constitution'"
        Write-Host "3. The constitution will be used by planning and implementation commands"
    }

} catch {
    Write-Error "Error: $_"
    exit 1
}