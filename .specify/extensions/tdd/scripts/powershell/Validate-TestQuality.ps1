# Validate-TestQuality.ps1
# Validate test quality based on TDD principles

param(
    [Parameter(Position=0)]
    [string]$TestPath = "tests",
    
    [string]$OutputFile = ""
)

Write-Host "Analyzing test quality in: $TestPath" -ForegroundColor Cyan
Write-Host "Based on TDD best practices:" -ForegroundColor Cyan
Write-Host "- Vertical slicing: ONE test → ONE implementation" -ForegroundColor Gray
Write-Host "- Public interface testing, not implementation details" -ForegroundColor Gray
Write-Host "- Test WHAT (behavior), not HOW (implementation)" -ForegroundColor Gray
Write-Host ""

function Get-TestFiles {
    param([string]$Path)
    
    if (Test-Path $Path -PathType Leaf) {
        return @((Get-Item $Path))
    }
    
    Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match "^test_.*\.py$|^.*_test\.py$|^.*\.test\.ts$|^.*\.spec\.ts$|^.*_test\.go$|^.*_test\.rs$" -and
        $_.FullName -notmatch "node_modules|\.venv|__pycache__|\.git|dist|build"
    }
}

function Test-FileQuality {
    param([System.IO.FileInfo]$File)
    
    $score = 0
    
    if (-not (Test-Path $File.FullName)) {
        return 0
    }
    
    Write-Host "Analyzing: $($File.Name)" -ForegroundColor Yellow
    
    $content = Get-Content $File.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return 0 }
    
    # ========================================
    # POSITIVE PATTERNS
    # ========================================
    
    # +10: Public interface tests
    if ($content -match "def test_|func Test|describe\(|it\(|test\(") {
        $score += 10
    }
    
    # +10: Behavior-focused assertions
    if ($content -match "assertEqual|assertEquals|assert.*==|expect.*toBe|should.*equal") {
        $score += 10
    }
    
    # +5: Descriptive test names
    if ($content -match "def test_[a-z_]+|it\(['`"]") {
        $score += 5
    }
    
    # +10: ONE BEHAVIOR PER TEST
    $assertionCount = ([regex]::Matches($content, "assert |expect |should |t\.Errorf")).Count
    if ($assertionCount -le 3 -and $assertionCount -gt 0) {
        $score += 10
    }
    
    # +10: EDGE CASE TESTS
    if ($content -match "empty|nil|zero|null|none|boundary|edge|limit|max|min|negative") {
        $score += 10
    }
    
    # +10: TEST ISOLATION
    if ($content -notmatch "global |@beforeClass|setUpClass|conftest") {
        $score += 10
    }
    
    # +5: AAA PATTERN
    if ($content -match "# Arrange|# Act|# Assert|// Arrange|// Act|// Assert") {
        $score += 5
    }
    
    # +5: ERROR/HAPPY PATH COVERAGE
    if ($content -match "raises|throws|toThrow|Error|error|exception") {
        $score += 5
    }
    
    # ========================================
    # ANTI-PATTERNS (TDD
    # ========================================
    
    # -15: Excessive mocking (TDD: mocks test imagined behavior)
    $mockCnt = ([regex]::Matches($content, "Mock|mock|MockObject|when\(|thenReturn|doReturn")).Count
    if ($mockCnt -gt 3) {
        $score -= 15
    }
    
    # -15: Tests implementation details (TDD)
    if ($content -match "private|_internal|__private") {
        $score -= 15
    }
    
    # -15: DB query tests (TDD: bypass interface)
    if ($content -match "db\.query|SELECT.*FROM|executeQuery|sql.*select") {
        $score -= 15
    }
    
    # -15: Call count verification (TDD: verify HOW not WHAT)
    if ($content -match "assertCalled|toHaveBeenCalled|toHaveBeenCalledTimes|assert_called") {
        $score -= 15
    }
    
    # -15: File system checks (TDD: bypass interface)
    if ($content -match "exists\(|isfile\(|readFile\(|writeFile\(|new File\(.*\)") {
        $score -= 15
    }
    
    # -10: Brittle tests
    if ($assertionCount -gt 10) {
        $score -= 10
    }
    
    # -10: Missing assertions
    $lineCount = ($content -split "`n").Count
    $assertLines = ([regex]::Matches($content, "assert |expect |should |t\.Error")).Count
    if ($lineCount -gt 20 -and $assertLines -lt 2) {
        $score -= 10
    }
    
    # Ensure score doesn't go below 0
    if ($score -lt 0) { $score = 0 }
    
    Write-Host "  Score: $score/100" -ForegroundColor $(if ($score -ge 70) { "Green" } elseif ($score -ge 50) { "Yellow" } else { "Red" })
    
    return $score
}

# Main analysis
$testFiles = Get-TestFiles -Path $TestPath

if ($null -eq $testFiles -or $testFiles.Count -eq 0) {
    Write-Host "No test files found." -ForegroundColor Yellow
    return
}

Write-Host "Found $($testFiles.Count) test file(s):"
$testFiles | ForEach-Object { Write-Host "  - $($_.FullName)" }
Write-Host ""

$totalScore = 0

foreach ($file in $testFiles) {
    $fileScore = Test-FileQuality -File $file
    $totalScore += $fileScore
}

# Calculate overall score
$overallScore = 0
if ($testFiles.Count -gt 0) {
    $overallScore = [math]::Floor($totalScore / $testFiles.Count)
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Overall Test Quality Score" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files analyzed: $($testFiles.Count)"
Write-Host "Overall score: $overallScore/100" -ForegroundColor $(if ($overallScore -ge 70) { "Green" } elseif ($overallScore -ge 50) { "Yellow" } else { "Red" })
Write-Host ""

if ($overallScore -ge 90) {
    Write-Host "Excellent test quality!" -ForegroundColor Green
    Write-Host "- Vertical slicing compliant" -ForegroundColor Gray
    Write-Host "- Public interface testing" -ForegroundColor Gray
    Write-Host "- No implementation coupling" -ForegroundColor Gray
}
elseif ($overallScore -ge 70) {
    Write-Host "Good test quality" -ForegroundColor Green
}
elseif ($overallScore -ge 50) {
    Write-Host "Acceptable test quality" -ForegroundColor Yellow
}
else {
    Write-Host "Needs improvement" -ForegroundColor Red
    Write-Host ""
    Write-Host "Tips based on TDD + TDD best practices:" -ForegroundColor Cyan
    Write-Host "1. Write ONE test → ONE implementation (vertical slicing)"
    Write-Host "2. Test WHAT (behavior) through public interfaces"
    Write-Host "3. Test edge cases (empty, nil, zero, boundaries)"
    Write-Host "4. Avoid: mocking internals, call counts, DB queries"
    Write-Host "5. Tests should survive refactors unchanged"
}

# Write to output file if specified
if ($OutputFile) {
    $report = @"
# Test Quality Analysis Report

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Directory**: $TestPath
**Principles**: TDD best practices + TDD TDD

## Summary

| Metric | Value |
|--------|-------|
| Files Analyzed | $($testFiles.Count) |
| Overall Score | $overallScore/100 |

## Score Interpretation

- 90-100: Excellent (vertical slicing compliant, public interface testing)
- 70-89: Good
- 50-69: Acceptable
- 0-49: Needs improvement

## TDD best practices + TDD Principles

1. **ONE test → ONE implementation** (vertical slicing)
2. **Test WHAT (behavior) through public interfaces**
3. **Test edge cases** (empty, nil, zero, boundaries)
4. **Avoid mocking internals, call counts, DB queries**
5. **Tests should survive refactors unchanged**

## Anti-Patterns (severe penalties)

- Excessive mocking (-15): Tests imagined behavior, not real
- Implementation detail testing (-15): Breaks on refactors
- DB query tests (-15): Bypass public interface
- Call count verification (-15): Tests HOW, not WHAT
- File system checks (-15): Bypass interface

"@

    $report | Set-Content $OutputFile -Encoding UTF8
    Write-Host ""
    Write-Host "Report written to: $OutputFile" -ForegroundColor Green
}