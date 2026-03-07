# Generate-RiskTests.ps1
# Parse Risk Register and generate risk-based test tasks

param(
    [string]$SpecFile = "spec.md",
    [string]$OutputFile = ""
)

Write-Host "Parsing Risk Register from: $SpecFile"

function Get-RiskTests {
    param([string]$SpecPath, [string]$OutFile)
    
    if (-not (Test-Path $SpecPath)) {
        Write-Host "Error: spec file not found: $SpecPath" -ForegroundColor Red
        return
    }
    
    # Find Risk Register section
    $content = Get-Content $SpecPath -Raw
    
    if ($content -notmatch "(?s)##.*Risk Register.*?(?=##)") {
        Write-Host "No Risk Register section found in $SpecPath" -ForegroundColor Yellow
        Write-Host "Skipping risk-based test generation."
        return
    }
    
    # Extract Risk Register content
    $riskSection = [regex]::Match($content, "(?s)##.*Risk Register.*?(?=##)").Value
    $risks = [regex]::Matches($riskSection, "-\s*RISK:\s*(.+?)(?=\n|$)")
    
    if ($risks.Count -eq 0) {
        Write-Host "No risk entries found in Risk Register" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Found $($risks.Count) risk entries:" -ForegroundColor Green
    Write-Host ""
    
    $output = @"
# Risk-Based Test Tasks
# Generated from Risk Register in $SpecPath

"@
    
    $counter = 1
    foreach ($risk in $risks) {
        $riskLine = $risk.Groups[1].Value
        
        # Parse: RISK: [name] | Severity: [High/Medium/Low] | Impact: [what] | Test: [specific test]
        if ($riskLine -match "Test:\s*([^|]+)") {
            $testDesc = $Matches[1].Trim()
            
            $output += "- [ ] TDD-R$($counter.ToString('00')) [RISK] $testDesc`n"
            Write-Host "  - TDD-R$($counter.ToString('00')) [RISK] $testDesc"
            $counter++
        }
    }
    
    if ($OutFile) {
        $output | Set-Content $OutFile -Encoding UTF8
        Write-Host ""
        Write-Host "Risk tests written to: $OutFile" -ForegroundColor Green
    }
    else {
        Write-Host ""
        Write-Host $output
    }
}

Get-RiskTests -SpecPath $SpecFile -OutFile $OutputFile