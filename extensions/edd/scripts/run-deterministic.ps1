# EDD Deterministic Checks — PowerShell Runner
# Runs lint, tests, and smoke checks, writes structured JSON.
# Usage: run-deterministic.ps1 [-FeatureDir <dir>] [-Config <file>]

param(
    [string]$FeatureDir = ".",
    [string]$Config = ".specify/extensions/edd/edd-config.yml"
)

$ErrorActionPreference = "Stop"
$outFile = Join-Path $FeatureDir ".eval" "deterministic.json"
# Resolve to absolute before Push-Location changes CWD
$outFile = [System.IO.Path]::GetFullPath($outFile)
New-Item -ItemType Directory -Force -Path (Split-Path $outFile) | Out-Null

# ─── LINT ─────────────────────────────────────────────────────────────────────
function Run-Lint {
    $cmd = $null
    if (Test-Path "pyproject.toml" -and (Get-Command ruff -ErrorAction SilentlyContinue)) {
        $cmd = "ruff check ."
    } elseif (Test-Path "package.json" -and (Get-Command npm -ErrorAction SilentlyContinue)) {
        $pkg = Get-Content "package.json" -Raw
        if ($pkg -match '"lint"') {
            $cmd = "npm run lint"
        } elseif (Get-Command eslint -ErrorAction SilentlyContinue) {
            $cmd = "eslint ."
        }
    } elseif (Test-Path "go.mod" -and (Get-Command golangci-lint -ErrorAction SilentlyContinue)) {
        $cmd = "golangci-lint run ./..."
    } elseif (Test-Path "Cargo.toml" -and (Get-Command cargo -ErrorAction SilentlyContinue)) {
        $cmd = "cargo clippy -- -D warnings"
    }

    if (-not $cmd) {
        return '{"passed": null, "errors": null, "warnings": null, "detail": "No linter detected"}'
    }

    $out = Invoke-Expression $cmd 2>&1 -ErrorAction SilentlyContinue
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        return '{"passed": true, "errors": 0, "warnings": 0, "detail": "Lint clean"}'
    } else {
        $errors = ([regex]::Matches($out, "error", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
        $warnings = ([regex]::Matches($out, "warning", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
        if ($errors -eq 0) { $errors = 1 }
        return "{`"passed`": false, `"errors`": $errors, `"warnings`": $warnings, `"detail`": `"Lint failed`"}"
    }
}

# ─── TESTS ────────────────────────────────────────────────────────────────────
function Run-Tests {
    $cmd = $null
    $coverage = "null"
    if (Test-Path "pyproject.toml" -and (Get-Command pytest -ErrorAction SilentlyContinue)) {
        $cmd = "pytest -x --tb=short --cov"
        $coverage = "0"
    } elseif (Test-Path "package.json" -and (Get-Command npm -ErrorAction SilentlyContinue)) {
        $pkg = Get-Content "package.json" -Raw
        if ($pkg -match '"test"') {
            $cmd = "npm test"
        } elseif (Get-Command jest -ErrorAction SilentlyContinue) {
            $cmd = "jest --bail"
        }
    } elseif (Test-Path "go.mod" -and (Get-Command go -ErrorAction SilentlyContinue)) {
        $cmd = "go test ./..."
        $coverage = "0"
    } elseif (Test-Path "Cargo.toml" -and (Get-Command cargo -ErrorAction SilentlyContinue)) {
        $cmd = "cargo test"
    }

    if (-not $cmd) {
        return '{"passed": null, "pass_count": null, "fail_count": null, "coverage": null, "detail": "No test runner detected"}'
    }

    $out = Invoke-Expression $cmd 2>&1 -ErrorAction SilentlyContinue
    $exitCode = $LASTEXITCODE

    $passCount = if ($out -match '(\d+) passed') { [int]$matches[1] } else { 0 }
    $failCount = if ($out -match '(\d+) failed') { [int]$matches[1] } else { 0 }

    if ($coverage -eq "0") {
        $covMatch = [regex]::Match($out, '(\d+)%')
        $coverage = if ($covMatch.Success) { $covMatch.Groups[1].Value } else { "null" }
    }

    if ($exitCode -eq 0) {
        return "{`"passed`": true, `"pass_count`": $passCount, `"fail_count`": 0, `"coverage`": $coverage, `"detail`": `"All tests pass`"}"
    } else {
        if ($failCount -eq 0) { $failCount = 1 }
        return "{`"passed`": false, `"pass_count`": $passCount, `"fail_count`": $failCount, `"coverage`": $coverage, `"detail`": `"Some tests failed`"}"
    }
}

# ─── SMOKE ────────────────────────────────────────────────────────────────────
function Run-Smoke {
    $cmd = $null
    if (Test-Path "package.json") {
        $pkg = Get-Content "package.json" -Raw
        if ($pkg -match '"smoke"') {
            $cmd = "npm run smoke"
        }
    } elseif (Test-Path "Makefile") {
        $mk = Get-Content "Makefile" -Raw
        if ($mk -match '^smoke') {
            $cmd = "make smoke"
        }
    }

    if (-not $cmd) {
        return '{"passed": null, "scenarios": null, "detail": "No smoke tests detected"}'
    }

    $out = Invoke-Expression $cmd 2>&1 -ErrorAction SilentlyContinue
    $exitCode = $LASTEXITCODE

    $scenarios = if ($out -match '(\d+) (scenario|test)') { [int]$matches[1] } else { 0 }

    if ($exitCode -eq 0) {
        return "{`"passed`": true, `"scenarios`": $scenarios, `"detail`": `"Smoke tests pass`"}"
    } else {
        return "{`"passed`": false, `"scenarios`": $scenarios, `"detail`": `"Smoke tests failed`"}"
    }
}

# ─── MAIN ─────────────────────────────────────────────────────────────────────
Push-Location $FeatureDir

try {
    $lint = Run-Lint
    $tests = Run-Tests
    $smoke = Run-Smoke

    $result = "{
  `"lint`": $lint,
  `"tests`": $tests,
  `"smoke`": $smoke
}"

    $result | Set-Content $outFile
    Write-Output $result
} finally {
    Pop-Location
}
