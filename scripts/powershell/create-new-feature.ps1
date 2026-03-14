#!/usr/bin/env pwsh
. "scripts/powershell/discovery-functions.ps1"`
# Create a new feature
[CmdletBinding()]
param(
    [switch]$Json,
    [string]$ShortName,
    [int]$Number = 0,
    [switch]$Help,
    [switch]$Contracts,
    [switch]$NoContracts,
    [switch]$DataModels,
    [switch]$NoDataModels,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FeatureDescription
)
$ErrorActionPreference = 'Stop'

# Set default mode
$Mode = "spec"
$ContractsVal = $true
$DataModelsVal = $true

# Handle switch parameters for contracts and data models
if ($NoContracts) {
    $ContractsVal = $false
} elseif ($Contracts) {
    $ContractsVal = $true
}

if ($NoDataModels) {
    $DataModelsVal = $false
} elseif ($DataModels) {
    $DataModelsVal = $true
}

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
    Write-Host "Usage: ./create-new-feature.ps1 [-Json] [-ShortName <name>] [-Number N] <feature description>"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Json               Output in JSON format"
    Write-Host "  -ShortName <name>   Provide a custom short name (2-4 words) for the branch"
    Write-Host "  -Number N           Specify branch number manually (overrides auto-detection)"
    Write-Host "  -Contracts          Enable service contracts (requires framework)"
    Write-Host "  -NoContracts        Disable service contracts"
    Write-Host "  -DataModels         Generate data model documentation"
    Write-Host "  -NoDataModels      Skip data model generation"
    Write-Host "  -Help               Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  ./create-new-feature.ps1 'Add user authentication system' -ShortName 'user-auth'"
    Write-Host "  ./create-new-feature.ps1 -Number 5 'Feature with specific number'"
    Write-Host "  ./create-new-feature.ps1 -Contracts -NoDataModels 'My feature' -ShortName 'my-feature'"
    exit 0
}

# Check if feature description provided
if (-not $FeatureDescription -or $FeatureDescription.Count -eq 0) {
    Write-Error "Usage: ./create-new-feature.ps1 [-Json] [-ShortName <name>] [-Number N] [-Contracts] [-NoContracts] [-DataModels] [-NoDataModels] <feature description>"
    exit 1
}

$featureDesc = ($FeatureDescription -join ' ').Trim()

# Validate description is not empty after trimming (e.g., user passed only whitespace)
if ([string]::IsNullOrWhiteSpace($featureDesc)) {
    Write-Error "Error: Feature description cannot be empty or contain only whitespace"
    exit 1
}

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
    $branchCreated = $false
    try {
        git checkout -q -b $branchName 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $branchCreated = $true
        }
    } catch {
        # Exception during git command
    }

    if (-not $branchCreated) {
        # Check if branch already exists
        $existingBranch = git branch --list $branchName 2>$null
        if ($existingBranch) {
            Write-Error "Error: Branch '$branchName' already exists. Please use a different feature name or specify a different number with -Number."
            exit 1
        } else {
            Write-Error "Error: Failed to create git branch '$branchName'. Please check your git configuration and try again."
            exit 1
        }
    }
} else {
    Write-Warning "[specify] Warning: Git repository not detected; skipped branch creation for $branchName"
}

$featureDir = Join-Path $specsDir $branchName
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null
 
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

# Use default template
$template = Resolve-Template -TemplateName 'spec-template' -RepoRoot $repoRoot
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
    
    # Replace framework options metadata
    $frameworkOptions = "  contracts=$($ContractsVal.ToString().ToLower()),`n  data_models=$($DataModelsVal.ToString().ToLower())"
    $content = $content -replace '\*\*Framework Options\*\*: tdd=true, contracts=true, data_models=true, risk_tests=true', "**Framework Options**:`n$frameworkOptions"
    
    Set-Content -Path $specFile -Value $content -NoNewline
}

# Function to populate context.md with defaults
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

# Populate context.md with defaults
$contextTemplate = Resolve-Template -TemplateName 'context-template' -RepoRoot $repoRoot
$contextFile = Join-Path $featureDir 'context.md'
if (Test-Path $contextTemplate) {
    Populate-ContextFile -ContextFile $contextFile -FeatureName $branchSuffix -FeatureDescription $featureDescription
} else {
    New-Item -ItemType File -Path $contextFile | Out-Null
}

# Set the SPECIFY_FEATURE environment variable for the current session
$env:SPECIFY_FEATURE = $branchName

# AI Discovery - Run discovery before JSON output
if ($env:SPECIFY_TEAM_DIRECTIVES) {
    $TEAM_DIRECTIVES_DIR = $env:SPECIFY_TEAM_DIRECTIVES
} else {
    $TEAM_DIRECTIVES_DIR = Join-Path $repoRoot '.specify/memory/team-ai-directives'
}
$DISCOVERED_DIRECTIVES = Discover-Directives -FeatureDescription $featureDesc -TeamDirectivesPath $TEAM_DIRECTIVES_DIR  
$DISCOVERED_SKILLS = Discover-Skills -FeatureDescription $featureDesc -TeamDirectivesPath $TEAM_DIRECTIVES_DIR -SkillsCachePath (Join-Path $repoRoot '.specify/skills')

if ($Json) {
    $obj = [PSCustomObject]@{ 
        BRANCH_NAME = $branchName
        SPEC_FILE = $specFile
        FEATURE_NUM = $featureNum
        HAS_GIT = $hasGit
        DISCOVERED_DIRECTIVES = $DISCOVERED_DIRECTIVES
        DISCOVERED_SKILLS = $DISCOVERED_SKILLS
    }
    $obj | ConvertTo-Json -Compress
} else {
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "SPEC_FILE: $specFile"
    Write-Output "FEATURE_NUM: $featureNum"
    Write-Output "HAS_GIT: $hasGit"
    Write-Output "SPECIFY_FEATURE environment variable set to: $branchName"
}

