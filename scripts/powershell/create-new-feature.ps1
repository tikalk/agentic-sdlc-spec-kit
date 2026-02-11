#!/usr/bin/env pwsh
# Create a new feature
[CmdletBinding()]
param(
    [switch]$Json,
    [string]$ShortName,
    [int]$Number = 0,
    [switch]$Help,
    [string]$Mode = "spec",
    [switch]$Tdd,
    [switch]$NoTdd,
    [switch]$Contracts,
    [switch]$NoContracts,
    [switch]$DataModels,
    [switch]$NoDataModels,
    [switch]$RiskTests,
    [switch]$NoRiskTests,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FeatureDescription
)
$ErrorActionPreference = 'Stop'

# Get the global config path using XDG Base Directory spec
function Get-GlobalConfigPath {
    if ($env:XDG_CONFIG_HOME) {
        $configDir = $env:XDG_CONFIG_HOME
    } elseif ($IsWindows -or $env:OS -eq 'Windows_NT') {
        $configDir = $env:APPDATA
    } else {
        $configDir = Join-Path $HOME ".config"
    }
    return Join-Path $configDir "specify" "config.json"
}

# Show help if requested
if ($Help) {
    Write-Host "Usage: ./create-new-feature.ps1 [-Json] [-ShortName <name>] [-Number N] [-Mode <mode>] [-Tdd] [-NoTdd] [-Contracts] [-NoContracts] [-DataModels] [-NoDataModels] [-RiskTests] [-NoRiskTests] <feature description>"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Json               Output in JSON format"
    Write-Host "  -ShortName <name>   Provide a custom short name (2-4 words) for the branch"
    Write-Host "  -Number N           Specify branch number manually (overrides auto-detection)"
    Write-Host "  -Mode <mode>        Workflow mode: spec (default) or build"
    Write-Host "  -Tdd                Enable Test-Driven Development (overrides mode default)"
    Write-Host "  -NoTdd              Disable Test-Driven Development (overrides mode default)"
    Write-Host "  -Contracts          Enable smart contracts (overrides mode default)"
    Write-Host "  -NoContracts        Disable smart contracts (overrides mode default)"
    Write-Host "  -DataModels         Enable data models (overrides mode default)"
    Write-Host "  -NoDataModels       Disable data models (overrides mode default)"
    Write-Host "  -RiskTests          Enable risk tests (overrides mode default)"
    Write-Host "  -NoRiskTests        Disable risk tests (overrides mode default)"
    Write-Host "  -Help               Show this help message"
    Write-Host ""
    Write-Host "Mode-specific defaults:"
    Write-Host "  spec mode:   tdd=true, contracts=true, data_models=true, risk_tests=true"
    Write-Host "  build mode:  tdd=false, contracts=false, data_models=false, risk_tests=false"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  ./create-new-feature.ps1 'Add user authentication system' -ShortName 'user-auth'"
    Write-Host "  ./create-new-feature.ps1 'Quick API fix' -Mode build -Tdd"
    Write-Host "  ./create-new-feature.ps1 'Implement OAuth2 integration' -NoContracts"
    exit 0
}

# Check if feature description provided
if (-not $FeatureDescription -or $FeatureDescription.Count -eq 0) {
    Write-Error "Usage: ./create-new-feature.ps1 [-Json] [-ShortName <name>] <feature description>"
    exit 1
}

$featureDesc = ($FeatureDescription -join ' ').Trim()

# Resolve repository root. Prefer git information when available, but fall back
# to searching for repository markers so the workflow still functions in repositories that
# were initialized with --no-git.
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
            # Reached filesystem root without finding markers
            return $null
        }
        $current = $parent
    }
}

function Get-HighestNumberFromSpecs {
    param([string]$SpecsDir)
    
    $highest = 0
    if (Test-Path $SpecsDir) {
        Get-ChildItem -Path $SpecsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d+)') {
                $num = [int]$matches[1]
                if ($num -gt $highest) { $highest = $num }
            }
        }
    }
    return $highest
}

function Get-HighestNumberFromBranches {
    param()
    
    $highest = 0
    try {
        $branches = git branch -a 2>$null
        if ($LASTEXITCODE -eq 0) {
            foreach ($branch in $branches) {
                # Clean branch name: remove leading markers and remote prefixes
                $cleanBranch = $branch.Trim() -replace '^\*?\s+', '' -replace '^remotes/[^/]+/', ''
                
                # Extract feature number if branch matches pattern ###-*
                if ($cleanBranch -match '^(\d+)-') {
                    $num = [int]$matches[1]
                    if ($num -gt $highest) { $highest = $num }
                }
            }
        }
    } catch {
        # If git command fails, return 0
        Write-Verbose "Could not check Git branches: $_"
    }
    return $highest
}

function Get-NextBranchNumber {
    param(
        [string]$SpecsDir
    )

    # Fetch all remotes to get latest branch info (suppress errors if no remotes)
    try {
        git fetch --all --prune 2>$null | Out-Null
    } catch {
        # Ignore fetch errors
    }

    # Get highest number from ALL branches (not just matching short name)
    $highestBranch = Get-HighestNumberFromBranches

    # Get highest number from ALL specs (not just matching short name)
    $highestSpec = Get-HighestNumberFromSpecs -SpecsDir $SpecsDir

    # Take the maximum of both
    $maxNum = [Math]::Max($highestBranch, $highestSpec)

    # Return next number
    return $maxNum + 1
}

function ConvertTo-CleanBranchName {
    param([string]$Name)
    
    return $Name.ToLower() -replace '[^a-z0-9]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
}
$fallbackRoot = (Find-RepositoryRoot -StartDir $PSScriptRoot)
if (-not $fallbackRoot) {
    Write-Error "Error: Could not determine repository root. Please run this script from within the repository."
    exit 1
}

try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0) {
        $hasGit = $true
    } else {
        throw "Git not available"
    }
} catch {
    $repoRoot = $fallbackRoot
    $hasGit = $false
}

Set-Location $repoRoot

$specsDir = Join-Path $repoRoot 'specs'
New-Item -ItemType Directory -Path $specsDir -Force | Out-Null

# Function to generate branch name with stop word filtering and length filtering
function Get-BranchName {
    param([string]$Description)
    
    # Common stop words to filter out
    $stopWords = @(
        'i', 'a', 'an', 'the', 'to', 'for', 'of', 'in', 'on', 'at', 'by', 'with', 'from',
        'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
        'do', 'does', 'did', 'will', 'would', 'should', 'could', 'can', 'may', 'might', 'must', 'shall',
        'this', 'that', 'these', 'those', 'my', 'your', 'our', 'their',
        'want', 'need', 'add', 'get', 'set'
    )
    
    # Convert to lowercase and extract words (alphanumeric only)
    $cleanName = $Description.ToLower() -replace '[^a-z0-9\s]', ' '
    $words = $cleanName -split '\s+' | Where-Object { $_ }
    
    # Filter words: remove stop words and words shorter than 3 chars (unless they're uppercase acronyms in original)
    $meaningfulWords = @()
    foreach ($word in $words) {
        # Skip stop words
        if ($stopWords -contains $word) { continue }
        
        # Keep words that are length >= 3 OR appear as uppercase in original (likely acronyms)
        if ($word.Length -ge 3) {
            $meaningfulWords += $word
        } elseif ($Description -match "\b$($word.ToUpper())\b") {
            # Keep short words if they appear as uppercase in original (likely acronyms)
            $meaningfulWords += $word
        }
    }
    
    # If we have meaningful words, use first 3-4 of them
    if ($meaningfulWords.Count -gt 0) {
        $maxWords = if ($meaningfulWords.Count -eq 4) { 4 } else { 3 }
        $result = ($meaningfulWords | Select-Object -First $maxWords) -join '-'
        return $result
    } else {
        # Fallback to original logic if no meaningful words found
        $result = ConvertTo-CleanBranchName -Name $Description
        $fallbackWords = ($result -split '-') | Where-Object { $_ } | Select-Object -First 3
        return [string]::Join('-', $fallbackWords)
    }
}

# Generate branch name
if ($ShortName) {
    # Use provided short name, just clean it up
    $branchSuffix = ConvertTo-CleanBranchName -Name $ShortName
} else {
    # Generate from description with smart filtering
    $branchSuffix = Get-BranchName -Description $featureDesc
}

# Determine branch number
if ($Number -eq 0) {
    if ($hasGit) {
        # Check existing branches on remotes
        $Number = Get-NextBranchNumber -SpecsDir $specsDir
    } else {
        # Fall back to local directory check
        $Number = (Get-HighestNumberFromSpecs -SpecsDir $specsDir) + 1
    }
}

$featureNum = ('{0:000}' -f $Number)
$branchName = "$featureNum-$branchSuffix"

# GitHub enforces a 244-byte limit on branch names
# Validate and truncate if necessary
$maxBranchLength = 244
if ($branchName.Length -gt $maxBranchLength) {
    # Calculate how much we need to trim from suffix
    # Account for: feature number (3) + hyphen (1) = 4 chars
    $maxSuffixLength = $maxBranchLength - 4
    
    # Truncate suffix
    $truncatedSuffix = $branchSuffix.Substring(0, [Math]::Min($branchSuffix.Length, $maxSuffixLength))
    # Remove trailing hyphen if truncation created one
    $truncatedSuffix = $truncatedSuffix -replace '-$', ''
    
    $originalBranchName = $branchName
    $branchName = "$featureNum-$truncatedSuffix"
    
    Write-Warning "[specify] Branch name exceeded GitHub's 244-byte limit"
    Write-Warning "[specify] Original: $originalBranchName ($($originalBranchName.Length) bytes)"
    Write-Warning "[specify] Truncated to: $branchName ($($branchName.Length) bytes)"
}

if ($hasGit) {
    try {
        git checkout -b $branchName | Out-Null
    } catch {
        Write-Warning "Failed to create git branch: $branchName"
    }
} else {
    Write-Warning "[specify] Warning: Git repository not detected; skipped branch creation for $branchName"
}

$featureDir = Join-Path $specsDir $branchName
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null

# Apply mode-specific defaults and parameter overrides
$currentMode = if ($Mode -in @("spec", "build")) { $Mode } else { "spec" }

# Framework options with mode-specific defaults
if ($currentMode -eq "build") {
    # Build mode defaults: all false
    $tdd = if ($Tdd.IsPresent) { $true } elseif ($NoTdd.IsPresent) { $false } else { $false }
    $contracts = if ($Contracts.IsPresent) { $true } elseif ($NoContracts.IsPresent) { $false } else { $false }
    $dataModels = if ($DataModels.IsPresent) { $true } elseif ($NoDataModels.IsPresent) { $false } else { $false }
    $riskTests = if ($RiskTests.IsPresent) { $true } elseif ($NoRiskTests.IsPresent) { $false } else { $false }
} else {
    # Spec mode defaults: all true
    $tdd = if ($NoTdd.IsPresent) { $false } elseif ($Tdd.IsPresent) { $true } else { $true }
    $contracts = if ($NoContracts.IsPresent) { $false } elseif ($Contracts.IsPresent) { $true } else { $true }
    $dataModels = if ($NoDataModels.IsPresent) { $false } elseif ($DataModels.IsPresent) { $true } else { $true }
    $riskTests = if ($NoRiskTests.IsPresent) { $false } elseif ($RiskTests.IsPresent) { $true } else { $true }
}

# Function to replace [DATE] placeholders with current date in ISO format (YYYY-MM-DD)
function Replace-DatePlaceholders {
    param([string]$FilePath)
    
    if (Test-Path $FilePath) {
        $currentDate = Get-Date -Format "yyyy-MM-dd"
        $content = Get-Content -Path $FilePath -Raw
        $content = $content -replace '\[DATE\]', $currentDate
        Set-Content -Path $FilePath -Value $content -NoNewline
    }
}

# Select template based on mode
if ($currentMode -eq "build") {
    $template = Join-Path $repoRoot 'templates/spec-template-build.md'
} else {
    $template = Join-Path $repoRoot 'templates/spec-template.md'
}
$specFile = Join-Path $featureDir 'spec.md'
if (Test-Path $template) {
    Copy-Item $template $specFile -Force
} else {
    New-Item -ItemType File -Path $specFile | Out-Null
}

# Replace [DATE] placeholders with current date
Replace-DatePlaceholders -FilePath $specFile

# Replace metadata placeholders with actual values
if (Test-Path $specFile) {
    $content = Get-Content -Path $specFile -Raw
    
    # Replace mode metadata
    $content = $content -replace '\*\*Workflow Mode\*\*: spec', "**Workflow Mode**: $currentMode"
    
    # Replace framework options metadata
    $frameworkOptions = "tdd=$([bool]$tdd.ToString().ToLower()), contracts=$([bool]$contracts.ToString().ToLower()), data_models=$([bool]$dataModels.ToString().ToLower()), risk_tests=$([bool]$riskTests.ToString().ToLower())"
    $content = $content -replace '\*\*Framework Options\*\*: tdd=true, contracts=true, data_models=true, risk_tests=true', "**Framework Options**: $frameworkOptions"
    
    Set-Content -Path $specFile -Value $content -NoNewline
}

# Function to populate context.md with intelligent defaults (mode-aware)
function Populate-ContextFile {
    param(
        [string]$ContextFile,
        [string]$FeatureName,
        [string]$FeatureDescription,
        [string]$Mode
    )

    # Extract feature title (first line or first sentence)
    $featureTitle = ($featureDescription -split "`n")[0].Trim()

    # Extract mission (first sentence, limited to reasonable length)
    $mission = ($featureDescription -split '[.!?]')[0]
    if (-not $mission) {
        $mission = $featureDescription
    }
    # Limit mission length for readability
    if ($mission.Length -gt 200) {
        $mission = $mission.Substring(0, 200).TrimEnd() + "..."
    }

    # Mode-aware field population
    if ($Mode -eq "build") {
        # Build mode: Minimal context, focus on core functionality
        $codePaths = "To be determined during implementation"
        $directives = "None (build mode)"
        $research = "Minimal research needed for lightweight implementation"
    } else {
        # Spec mode: Comprehensive context for full specification
        # Detect code paths (basic detection based on common patterns)
        $codePaths = "To be determined during planning phase"
        if ($featureDescription -match "(?i)api|endpoint|service") {
            $codePaths = "api/, services/"
        } elseif ($featureDescription -match "(?i)ui|frontend|component") {
            $codePaths = "src/components/, src/pages/"
        } elseif ($featureDescription -match "(?i)database|data|model") {
            $codePaths = "src/models/, database/"
        }

        # Read team directives if available
        $directives = "None"
        $teamDirectivesFile = Join-Path $repoRoot '.specify/memory/team-ai-directives/directives.md'
        if (Test-Path $teamDirectivesFile) {
            $directives = "See team-ai-directives repository for applicable guidelines"
        }

        # Set research needs
        $research = "To be identified during specification and planning phases"
    }

    # Create context.md with populated values
    $contextContent = @"
# Feature Context

**Feature**: $featureTitle
**Mission**: $mission
**Code Paths**: $codePaths
**Directives**: $directives
**Research**: $research

"@

    $contextContent | Out-File -FilePath $contextFile -Encoding UTF8
}

# Populate context.md with intelligent defaults
$contextTemplate = Join-Path $repoRoot 'templates/context-template.md'
$contextFile = Join-Path $featureDir 'context.md'
if (Test-Path $contextTemplate) {
    Populate-ContextFile -ContextFile $contextFile -FeatureName $branchSuffix -FeatureDescription $featureDescription -Mode $currentMode
} else {
    New-Item -ItemType File -Path $contextFile | Out-Null
}

# Set the SPECIFY_FEATURE environment variable for the current session
$env:SPECIFY_FEATURE = $branchName

if ($Json) {
    $obj = [PSCustomObject]@{ 
        BRANCH_NAME = $branchName
        SPEC_FILE = $specFile
        FEATURE_NUM = $featureNum
        HAS_GIT = $hasGit
    }
    $obj | ConvertTo-Json -Compress
} else {
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "SPEC_FILE: $specFile"
    Write-Output "FEATURE_NUM: $featureNum"
    Write-Output "HAS_GIT: $hasGit"
    Write-Output "SPECIFY_FEATURE environment variable set to: $branchName"
}

