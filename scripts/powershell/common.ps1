#!/usr/bin/env pwsh
# Common PowerShell functions analogous to common.sh

# Get the global config path using XDG Base Directory spec
# Platform-specific locations:
# - Linux: ~/.config/specify/config.json
# - macOS: ~/Library/Application Support/specify/config.json (but we use XDG for consistency)
# - Windows: %APPDATA%\specify\config.json
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

function Get-ProjectConfigPath {
    $repoRoot = Get-RepoRoot
    return Join-Path $repoRoot ".specify" "config.json"
}

function Get-ConfigPath {
    <#
    .SYNOPSIS
    Get config path with hierarchical resolution
    Priority: 1) Project config  2) User config  3) Default to project
    #>
    $projectConfig = Get-ProjectConfigPath
    $userConfig = Get-GlobalConfigPath
    
    if (Test-Path $projectConfig) {
        return $projectConfig
    } elseif (Test-Path $userConfig) {
        return $userConfig
    } else {
        return $projectConfig
    }
}

# Get current workflow mode from config (build or spec)
# Defaults to "spec" if config doesn't exist or mode is invalid
function Get-CurrentMode {
    $configFile = Get-ConfigPath
    
    # Default to spec mode if no config exists
    if (-not (Test-Path $configFile)) {
        return 'spec'
    }
    
    try {
        $config = Get-Content $configFile -Raw | ConvertFrom-Json
        $mode = $config.workflow.current_mode
        
        # Validate mode (only build or spec allowed, treat "ad" as spec for migration)
        if ($mode -eq 'build' -or $mode -eq 'spec') {
            return $mode
        }
        return 'spec'  # Fallback for invalid values including "ad"
    }
    catch {
        return @()
    }
}

# Detect workflow mode and framework options from spec.md
# Usage: Get-WorkflowConfig -SpecFile "path/to/spec.md"
# Returns hashtable: @{mode="build|spec"; tdd=$true|$false; contracts=$true|$false; data_models=$true|$false; risk_tests=$true|$false}
function Get-WorkflowConfig {
    param(
        [string]$SpecFile = "spec.md"
    )
    
    # Source and execute the standalone script
    $scriptDir = Split-Path -Parent $PSCommandPath
    . "$scriptDir/Detect-WorkflowConfig.ps1"
    
    # Call the function
    return Get-WorkflowConfig -SpecFile $SpecFile
}


# Get a specific mode configuration value
# Usage: Get-ModeConfig "atomic_commits" → returns "true" or "false"
# Usage: Get-ModeConfig "skip_micro_review" → returns "true" or "false"
function Get-ModeConfig {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Key
    )
    
    $configFile = Get-ConfigPath
    
    # Default to false if no config exists
    if (-not (Test-Path $configFile)) {
        return 'false'
    }
    
    try {
        $config = Get-Content $configFile -Raw | ConvertFrom-Json
        $mode = Get-CurrentMode
        
        # Read mode-specific config value, default to false
        $value = $config.mode_defaults.$mode.$Key
        
        if ($null -eq $value) {
            return 'false'
        }
        
        # Convert to lowercase string for consistency with bash
        return $value.ToString().ToLower()
    }
    catch {
        return 'false'  # Fallback on any error
    }
}

# Get architecture diagram format from global config (mermaid or ascii)
# Defaults to "mermaid" if config doesn't exist or format is invalid
function Get-ArchitectureDiagramFormat {
    $configFile = Get-ConfigPath
    
    # Default to mermaid if no config exists
    if (-not (Test-Path $configFile)) {
        return 'mermaid'
    }
    
    try {
        $config = Get-Content $configFile -Raw | ConvertFrom-Json
        $format = $config.architecture.diagram_format
        
        # Validate format (only mermaid or ascii allowed)
        if ($format -eq 'mermaid' -or $format -eq 'ascii') {
            return $format
        }
        return 'mermaid'  # Fallback for invalid values
    }
    catch {
        return 'mermaid'  # Fallback on any error
    }
}

# Validate Mermaid diagram syntax (lightweight regex validation)
# Returns $true if valid, $false if invalid
# Args: MermaidCode - Mermaid code string
function Test-MermaidSyntax {
    param(
        [Parameter(Mandatory=$true)]
        [string]$MermaidCode
    )
    
    # Check if empty
    if ([string]::IsNullOrWhiteSpace($MermaidCode)) {
        return $false
    }
    
    # Check for basic Mermaid diagram types
    if ($MermaidCode -notmatch '^(graph|flowchart|sequenceDiagram|classDiagram|stateDiagram|erDiagram|gantt|pie|journey|gitGraph|mindmap|timeline)') {
        return $false
    }
    
    # Check for balanced brackets/parentheses (simplified)
    $openBrackets = ([regex]::Matches($MermaidCode, '\[')).Count
    $closeBrackets = ([regex]::Matches($MermaidCode, '\]')).Count
    $openParens = ([regex]::Matches($MermaidCode, '\(')).Count
    $closeParens = ([regex]::Matches($MermaidCode, '\)')).Count
    
    if ($openBrackets -ne $closeBrackets -or $openParens -ne $closeParens) {
        return $false
    }
    
    # Basic syntax passed
    return $true
}

function Get-RepoRoot {
    try {
        $result = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    } catch {
        # Git command failed
    }
    
    # Fall back to script location for non-git repos
    return (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
}

function Get-CurrentBranch {
    # First check if SPECIFY_FEATURE environment variable is set
    if ($env:SPECIFY_FEATURE) {
        return $env:SPECIFY_FEATURE
    }
    
    # Then check git if available
    try {
        $result = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    } catch {
        # Git command failed
    }
    
    # For non-git repos, try to find the latest feature directory
    $repoRoot = Get-RepoRoot
    $specsDir = Join-Path $repoRoot "specs"
    
    if (Test-Path $specsDir) {
        $latestFeature = ""
        $highest = 0
        
        Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d{3})-') {
                $num = [int]$matches[1]
                if ($num -gt $highest) {
                    $highest = $num
                    $latestFeature = $_.Name
                }
            }
        }
        
        if ($latestFeature) {
            return $latestFeature
        }
    }
    
    # Final fallback
    return "main"
}

function Test-HasGit {
    try {
        git rev-parse --show-toplevel 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Test-FeatureBranch {
    param(
        [string]$Branch,
        [bool]$HasGit = $true
    )
    
    # For non-git repos, we can't enforce branch naming but still provide output
    if (-not $HasGit) {
        Write-Warning "[specify] Warning: Git repository not detected; skipped branch validation"
        return $true
    }
    
    if ($Branch -notmatch '^[0-9]{3}-') {
        Write-Output "ERROR: Not on a feature branch. Current branch: $Branch"
        Write-Output "Feature branches should be named like: 001-feature-name"
        return $false
    }
    return $true
}

function Get-FeatureDir {
    param([string]$RepoRoot, [string]$Branch)
    Join-Path $RepoRoot "specs/$Branch"
}

function Get-FeaturePathsEnv {
    $repoRoot = Get-RepoRoot
    $currentBranch = Get-CurrentBranch
    $hasGit = Test-HasGit
    $featureDir = Get-FeatureDir -RepoRoot $repoRoot -Branch $currentBranch
    
    # Project-level governance documents
    $memoryDir = Join-Path $repoRoot '.specify/memory'
    $constitutionFile = Join-Path $memoryDir 'constitution.md'
    $architectureFile = Join-Path $memoryDir 'architecture.md'
    
    # New architecture document structure (AD.md at root or feature level, ADR in memory/)
    $systemAdFile = Join-Path $repoRoot 'AD.md'
    $featureAdFile = Join-Path $featureDir 'AD.md'
    $adrFile = Join-Path $repoRoot '.specify/memory/adr.md'
    
    # Determine which AD file to use
    $adFile = if (Test-Path $featureAdFile) { $featureAdFile } elseif (Test-Path $systemAdFile) { $systemAdFile } else { $null }
    
    [PSCustomObject]@{
        REPO_ROOT     = $repoRoot
        CURRENT_BRANCH = $currentBranch
        HAS_GIT       = $hasGit
        FEATURE_DIR   = $featureDir
        FEATURE_SPEC  = Join-Path $featureDir 'spec.md'
        IMPL_PLAN     = Join-Path $featureDir 'plan.md'
        TASKS         = Join-Path $featureDir 'tasks.md'
        RESEARCH      = Join-Path $featureDir 'research.md'
        DATA_MODEL    = Join-Path $featureDir 'data-model.md'
        QUICKSTART    = Join-Path $featureDir 'quickstart.md'
        CONTRACTS_DIR = Join-Path $featureDir 'contracts'
        CONSTITUTION  = $constitutionFile
        ARCHITECTURE  = $architectureFile
        AD            = $adFile
        SYSTEM_AD     = $systemAdFile
        FEATURE_AD    = $featureAdFile
        ADR           = $adrFile
    }
}

function Test-FileExists {
    param([string]$Path, [string]$Description)
    if (Test-Path -Path $Path -PathType Leaf) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

function Test-DirHasFiles {
    param([string]$Path, [string]$Description)
    if ((Test-Path -Path $Path -PathType Container) -and (Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1)) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

# Extract constitution principles and constraints
# Returns array of rules
function Get-ConstitutionRules {
    param([string]$ConstitutionFile)
    
    if (-not (Test-Path $ConstitutionFile)) {
        return @()
    }
    
    try {
        $content = Get-Content $ConstitutionFile -Raw
        $rules = @()
        
        foreach ($line in $content -split "`n") {
            $trimmed = $line.Trim()
            if ($trimmed -match '^\s*-\s+\*\*(Principle|PRINCIPLE|Constraint|CONSTRAINT|Pattern|PATTERN)') {
                $type = 'principle'
                if ($trimmed -match 'Constraint|CONSTRAINT') { $type = 'constraint' }
                if ($trimmed -match 'Pattern|PATTERN') { $type = 'pattern' }
                
                $rules += @{
                    type = $type
                    text = $trimmed
                }
            }
        }
        
        return $rules
    }
    catch {
        return @()
    }
}

# Extract architecture viewpoints from architecture.md
# Returns hashtable with view names and presence status
function Get-ArchitectureViews {
    param([string]$ArchitectureFile)
    
    if (-not (Test-Path $ArchitectureFile)) {
        return @{}
    }
    
    try {
        $content = Get-Content $ArchitectureFile -Raw
        $views = @{}
        
        $viewPatterns = @{
            'context' = '###\s+3\.1\s+Context\s+View'
            'functional' = '###\s+3\.2\s+Functional\s+View'
            'information' = '###\s+3\.3\s+Information\s+View'
            'concurrency' = '###\s+3\.4\s+Concurrency\s+View'
            'development' = '###\s+3\.5\s+Development\s+View'
            'deployment' = '###\s+3\.6\s+Deployment\s+View'
            'operational' = '###\s+3\.7\s+Operational\s+View'
        }
        
        foreach ($viewName in $viewPatterns.Keys) {
            $pattern = $viewPatterns[$viewName]
            if ($content -match $pattern) {
                $views[$viewName] = @{ present = $true }
            }
            else {
                $views[$viewName] = @{ present = $false }
            }
        }
        
        return $views
    }
    catch {
        return @{}
    }
}

# Extract diagram blocks from architecture.md
# Returns array of diagrams with type and format
function Get-ArchitectureDiagrams {
    param([string]$ArchitectureFile)
    
    if (-not (Test-Path $ArchitectureFile)) {
        return @()
    }
    
    try {
        $content = Get-Content $ArchitectureFile -Raw
        $diagrams = @()
        
        # Find all code blocks (mermaid or text)
        $codeBlockPattern = '```(mermaid|text)\r?\n(.*?)\r?\n```'
        $matches = [regex]::Matches($content, $codeBlockPattern, 'Singleline')
        
        foreach ($match in $matches) {
            $diagramFormat = $match.Groups[1].Value
            $diagramContent = $match.Groups[2].Value
            
            # Find which view this diagram belongs to
            $startPos = $match.Index
            $precedingText = $content.Substring(0, $startPos)
            
            # Find the most recent view heading
            $viewName = 'unknown'
            $viewPatterns = @(
                @{ pattern = '###\s+3\.1\s+Context\s+View'; name = 'context' },
                @{ pattern = '###\s+3\.2\s+Functional\s+View'; name = 'functional' },
                @{ pattern = '###\s+3\.3\s+Information\s+View'; name = 'information' },
                @{ pattern = '###\s+3\.4\s+Concurrency\s+View'; name = 'concurrency' },
                @{ pattern = '###\s+3\.5\s+Development\s+View'; name = 'development' },
                @{ pattern = '###\s+3\.6\s+Deployment\s+View'; name = 'deployment' },
                @{ pattern = '###\s+3\.7\s+Operational\s+View'; name = 'operational' }
            )
            
            foreach ($vp in $viewPatterns) {
                $viewMatches = [regex]::Matches($precedingText, $vp.pattern, 'IgnoreCase')
                if ($viewMatches.Count -gt 0) {
                    $viewName = $vp.name
                    # Keep looking for the last (most recent) match
                }
            }
            
            $diagrams += @{
                view = $viewName
                format = $diagramFormat
                line_count = ($diagramContent -split "`n").Count
            }
        }
        
        return $diagrams
    }
    catch {
        return @()
    }
}

