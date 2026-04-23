# Detect-Language.ps1
# Detect language and test framework from project files

param(
    [string]$OutputFile = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExtDir = Split-Path -Parent $ScriptDir

if (-not $OutputFile) {
    $OutputFile = Join-Path $ExtDir "language-detected.json"
}

Write-Host "Detecting language and test framework..."

function Get-LanguageDetection {
    $language = "unknown"
    $framework = "unknown"
    $testDir = "tests/"
    $binary = ""
    $flags = "-xvs"
    
    # Check for Python
    if ((Test-Path "pyproject.toml") -or (Test-Path "setup.py") -or (Test-Path "requirements.txt")) {
        $language = "python"
        
        if (Test-Path "pyproject.toml") {
            $content = Get-Content "pyproject.toml" -Raw
            if ($content -match "pytest") {
                $framework = "pytest"
                $binary = "pytest"
            }
            else {
                $framework = "pytest"
                $binary = "pytest"
            }
        }
        
        $testDir = "tests/"
        $flags = "-xvs"
    }
    
    # Check for TypeScript/JavaScript
    if ((Test-Path "package.json") -and ($language -eq "unknown")) {
        $language = "typescript"
        $content = Get-Content "package.json" -Raw
        
        if ($content -match "vitest") {
            $framework = "vitest"
            $binary = "vitest"
            $flags = "run"
        }
        elseif ($content -match "jest") {
            $framework = "jest"
            $binary = "npx jest"
            $flags = "--passWithNoTests"
        }
        
        if (Test-Path "__tests__") {
            $testDir = "__tests__/"
        }
        else {
            $testDir = "tests/"
        }
    }
    
    # Check for Go
    if ((Test-Path "go.mod") -and ($language -eq "unknown")) {
        $language = "go"
        $framework = "testing"
        $binary = "go test"
        $flags = "-v"
        $testDir = ""
    }
    
    # Check for Rust
    if ((Test-Path "Cargo.toml") -and ($language -eq "unknown")) {
        $language = "rust"
        $framework = "cargo"
        $binary = "cargo test"
        $flags = ""
        $testDir = ""
    }
    
    # Output detected configuration
    $config = @{
        language = $language
        framework = $framework
        test_directory = $testDir
        binary = $binary
        flags = $flags
        detected_at = (Get-Date -Format "o")
    }
    
    $config | ConvertTo-Json | Set-Content $OutputFile -Encoding UTF8
    
    Write-Host "Detected: $language / $framework"
    Write-Host "Test directory: $testDir"
    Write-Host "Test command: $binary $flags"
    Write-Host ""
    Write-Host "Configuration saved to: $OutputFile"
}

Get-LanguageDetection