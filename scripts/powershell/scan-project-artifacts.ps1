#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Suggestions
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"

$paths = Get-FeaturePathsEnv

# Function to scan for testing patterns
function Get-TestingPatterns {
    param([string]$RepoRoot)

    $testPatterns = @(
        "test_*.py", "*Test.java", "*.spec.js", "*.test.js", "*_test.go",
        "spec/**/*.rb", "test/**/*.rs", "__tests__/**/*.js"
    )

    $testFilesCount = 0
    $testFrameworksFound = @()

    # Count test files
    foreach ($pattern in $testPatterns) {
        try {
            $files = Get-ChildItem -Path $RepoRoot -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
            $testFilesCount += $files.Count
        } catch {
            # Ignore errors for patterns that don't match
        }
    }

    # Detect testing frameworks
    $packageJsonFiles = Get-ChildItem -Path $RepoRoot -Filter "package.json" -Recurse -File -ErrorAction SilentlyContinue
    foreach ($file in $packageJsonFiles) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match '"jest"') {
            $testFrameworksFound += "Jest"
        }
    }

    $pytestFiles = Get-ChildItem -Path $RepoRoot -Include "pytest.ini", "setup.cfg" -Recurse -File -ErrorAction SilentlyContinue
    foreach ($file in $pytestFiles) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match "pytest") {
            $testFrameworksFound += "pytest"
        }
    }

    $cargoFiles = Get-ChildItem -Path $RepoRoot -Filter "Cargo.toml" -Recurse -File -ErrorAction SilentlyContinue
    foreach ($file in $cargoFiles) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match "testing") {
            $testFrameworksFound += "Rust testing"
        }
    }

    $goFiles = Get-ChildItem -Path $RepoRoot -Filter "*.go" -Recurse -File -ErrorAction SilentlyContinue
    foreach ($file in $goFiles) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match "testing") {
            $testFrameworksFound += "Go testing"
        }
    }

    return "$testFilesCount|$($testFrameworksFound -join ' ')"
}

# Function to scan for security patterns
function Get-SecurityPatterns {
    param([string]$RepoRoot)

    $securityIndicators = 0
    $authPatterns = 0
    $inputValidation = 0

    $codeFiles = Get-ChildItem -Path $RepoRoot -Include "*.py", "*.js", "*.java", "*.go", "*.rs" -Recurse -File -ErrorAction SilentlyContinue

    foreach ($file in $codeFiles) {
        $content = Get-Content $file.FullName -Raw

        # Check for authentication patterns
        if ($content -match "(?i)jwt|oauth|bearer|token") {
            $authPatterns++
            break
        }
    }

    foreach ($file in $codeFiles) {
        $content = Get-Content $file.FullName -Raw

        # Check for input validation
        if ($content -match "(?i)sanitize|validate|escape") {
            $inputValidation++
            break
        }
    }

    # Check for security-related files
    $securityFiles = Get-ChildItem -Path $RepoRoot -Include "*security*", "*auth*", "*crypto*" -Recurse -File -ErrorAction SilentlyContinue
    if ($securityFiles.Count -gt 0) {
        $securityIndicators++
    }

    return "$authPatterns|$inputValidation|$securityIndicators"
}

# Function to scan for documentation patterns
function Get-DocumentationPatterns {
    param([string]$RepoRoot)

    $readmeCount = 0
    $apiDocs = 0
    $inlineComments = 0

    # Count README files
    $readmeFiles = Get-ChildItem -Path $RepoRoot -Filter "readme*" -Recurse -File -ErrorAction SilentlyContinue
    $readmeCount = $readmeFiles.Count

    # Check for API documentation
    $docsDirs = Get-ChildItem -Path $RepoRoot -Include "*api*", "*docs*" -Recurse -Directory -ErrorAction SilentlyContinue
    if ($docsDirs.Count -gt 0) {
        $apiDocs = 1
    }

    # Sample code files for comment analysis
    $codeFiles = Get-ChildItem -Path $RepoRoot -Include "*.py", "*.js", "*.java", "*.go", "*.rs" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 10

    $totalLines = 0
    $commentLines = 0

    foreach ($file in $codeFiles) {
        $content = Get-Content $file.FullName -Raw
        $lines = $content -split "`n"
        $totalLines += $lines.Count

        $extension = [System.IO.Path]::GetExtension($file.Name)

        switch ($extension) {
            ".py" {
                $comments = $lines | Where-Object { $_ -match "^[ ]*#" }
                $commentLines += $comments.Count
            }
            ".js" {
                $comments = $lines | Where-Object { $_ -match "^[ ]*//" -or $_ -match "/\*" }
                $commentLines += $comments.Count
            }
            ".java" {
                $comments = $lines | Where-Object { $_ -match "^[ ]*//" -or $_ -match "/\*" }
                $commentLines += $comments.Count
            }
            ".go" {
                $comments = $lines | Where-Object { $_ -match "^[ ]*//" }
                $commentLines += $comments.Count
            }
            ".rs" {
                $comments = $lines | Where-Object { $_ -match "^[ ]*//" -or $_ -match "/\*" }
                $commentLines += $comments.Count
            }
        }
    }

    if ($totalLines -gt 0) {
        $inlineComments = [math]::Round(($commentLines * 100) / $totalLines)
    }

    return "$readmeCount|$apiDocs|$inlineComments"
}

# Function to scan for architecture patterns
function Get-ArchitecturePatterns {
    param([string]$RepoRoot)

    $layeredArchitecture = 0
    $modularStructure = 0
    $configManagement = 0

    # Check for layered architecture
    $layerDirs = Get-ChildItem -Path $RepoRoot -Include "controllers", "services", "models", "views" -Recurse -Directory -ErrorAction SilentlyContinue
    if ($layerDirs.Count -gt 0) {
        $layeredArchitecture = 1
    }

    # Check for modular structure
    $allDirs = Get-ChildItem -Path $RepoRoot -Recurse -Directory | Where-Object { $_.FullName -notlike "*\.git*" }
    if ($allDirs.Count -gt 10) {
        $modularStructure = 1
    }

    # Check for configuration management
    $configFiles = Get-ChildItem -Path $RepoRoot -Include "*.env*", "config*", "settings*" -Recurse -File -ErrorAction SilentlyContinue
    if ($configFiles.Count -gt 0) {
        $configManagement = 1
    }

    return "$layeredArchitecture|$modularStructure|$configManagement"
}

# Function to generate constitution suggestions
function New-ConstitutionSuggestions {
    param([string]$TestingData, [string]$SecurityData, [string]$DocsData, [string]$ArchData)

    $suggestions = @()

    # Parse testing data
    $testingParts = $TestingData -split '\|'
    $testFiles = [int]$testingParts[0]
    $testFrameworks = $testingParts[1]

    if ($testFiles -gt 0) {
        $suggestions += "**Testing Standards**: Project has $testFiles test files using $testFrameworks. Consider mandating test coverage requirements and framework consistency."
    }

    # Parse security data
    $securityParts = $SecurityData -split '\|'
    $authPatterns = [int]$securityParts[0]
    $inputValidation = [int]$securityParts[1]
    $securityIndicators = [int]$securityParts[2]

    if ($authPatterns -gt 0 -or $securityIndicators -gt 0) {
        $suggestions += "**Security by Default**: Project shows security practices. Consider requiring security reviews and input validation standards."
    }

    # Parse documentation data
    $docsParts = $DocsData -split '\|'
    $readmeCount = [int]$docsParts[0]
    $apiDocs = [int]$docsParts[1]
    $commentPercentage = [int]$docsParts[2]

    if ($readmeCount -gt 0) {
        $suggestions += "**Documentation Matters**: Project has $readmeCount README files. Consider mandating documentation for APIs and complex logic."
    }

    if ($commentPercentage -gt 10) {
        $suggestions += "**Code Comments**: Project shows $commentPercentage% comment density. Consider requiring meaningful comments for complex algorithms."
    }

    # Parse architecture data
    $archParts = $ArchData -split '\|'
    $layered = [int]$archParts[0]
    $modular = [int]$archParts[1]
    $config = [int]$archParts[2]

    if ($layered -gt 0) {
        $suggestions += "**Architecture Consistency**: Project uses layered architecture. Consider documenting architectural patterns and separation of concerns."
    }

    if ($modular -gt 0) {
        $suggestions += "**Modular Design**: Project shows modular organization. Consider requiring modular design principles and dependency management."
    }

    if ($config -gt 0) {
        $suggestions += "**Configuration Management**: Project uses configuration files. Consider requiring environment-specific configuration and secrets management."
    }

    # Output suggestions
    if ($suggestions.Count -gt 0) {
        Write-Host "Constitution Suggestions Based on Codebase Analysis:" -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan
        foreach ($suggestion in $suggestions) {
            Write-Host "- $suggestion" -ForegroundColor White
        }
    } else {
        Write-Host "No specific constitution suggestions generated from codebase analysis." -ForegroundColor Yellow
        Write-Host "Consider adding general development principles to your constitution." -ForegroundColor Yellow
    }
}

# Main logic
if ($Json) {
    $testing = Get-TestingPatterns -RepoRoot $paths.REPO_ROOT
    $security = Get-SecurityPatterns -RepoRoot $paths.REPO_ROOT
    $docs = Get-DocumentationPatterns -RepoRoot $paths.REPO_ROOT
    $arch = Get-ArchitecturePatterns -RepoRoot $paths.REPO_ROOT

    @{
        testing = $testing
        security = $security
        documentation = $docs
        architecture = $arch
    } | ConvertTo-Json -Compress
} else {
    Write-Host "Scanning project artifacts for constitution patterns..." -ForegroundColor Cyan
    Write-Host ""

    $testing = Get-TestingPatterns -RepoRoot $paths.REPO_ROOT
    $security = Get-SecurityPatterns -RepoRoot $paths.REPO_ROOT
    $docs = Get-DocumentationPatterns -RepoRoot $paths.REPO_ROOT
    $arch = Get-ArchitecturePatterns -RepoRoot $paths.REPO_ROOT

    Write-Host "Testing Patterns: $testing" -ForegroundColor White
    Write-Host "Security Patterns: $security" -ForegroundColor White
    Write-Host "Documentation Patterns: $docs" -ForegroundColor White
    Write-Host "Architecture Patterns: $arch" -ForegroundColor White
    Write-Host ""

    if ($Suggestions) {
        New-ConstitutionSuggestions -TestingData $testing -SecurityData $security -DocsData $docs -ArchData $arch
    }
}