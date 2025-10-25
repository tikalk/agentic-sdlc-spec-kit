#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Amendment,
    [switch]$Validate,
    [string]$KnowledgeFile
)

$ErrorActionPreference = 'Stop'

if (-not $KnowledgeFile -and -not $Amendment -and -not $Validate) {
    Write-Error "Must specify AI session context file or use -Amendment/-Validate mode"
    exit 1
}

. "$PSScriptRoot/common.ps1"

$paths = Get-FeaturePathsEnv

# Function to analyze AI session context for team-ai-directives contributions
function Analyze-TeamDirectivesContributions {
    param([string]$ContextFile)

    if (-not (Test-Path $ContextFile)) {
        Write-Error "AI session context file not found: $ContextFile"
        exit 1
    }

    $content = Get-Content $ContextFile -Raw

    # Extract different sections for analysis
    $sessionOverview = ""
    if ($content -match '(?s)## Session Overview(.*?)(?=^## )') {
        $sessionOverview = $matches[1]
    }

    $decisionPatterns = ""
    if ($content -match '(?s)## Decision Patterns(.*?)(?=^## )') {
        $decisionPatterns = $matches[1]
    }

    $executionContext = ""
    if ($content -match '(?s)## Execution Context(.*?)(?=^## )') {
        $executionContext = $matches[1]
    }

    $reusablePatterns = ""
    if ($content -match '(?s)## Reusable Patterns(.*?)(?=^## )') {
        $reusablePatterns = $matches[1]
    }

    # Analyze for different component contributions
    $constitutionScore = 0
    $rulesScore = 0
    $personasScore = 0
    $examplesScore = 0

    $constitutionKeywords = @("must", "shall", "required", "mandatory", "always", "never", "principle", "governance", "policy", "standard", "quality", "security", "testing", "documentation", "architecture", "compliance", "oversight", "review", "approval")
    $rulesKeywords = @("agent", "behavior", "interaction", "decision", "pattern", "approach", "strategy", "methodology", "tool", "execution")
    $personasKeywords = @("role", "specialization", "capability", "expertise", "persona", "assistant", "specialist", "focus")
    $examplesKeywords = @("example", "case", "study", "implementation", "usage", "reference", "demonstration", "scenario")

    # Analyze constitution relevance
    foreach ($keyword in $constitutionKeywords) {
        if ($content -match "(?i)$keyword") {
            $constitutionScore++
        }
    }

    # Analyze rules relevance
    foreach ($keyword in $rulesKeywords) {
        if (($decisionPatterns + $reusablePatterns) -match "(?i)$keyword") {
            $rulesScore++
        }
    }

    # Analyze personas relevance
    foreach ($keyword in $personasKeywords) {
        if (($sessionOverview + $executionContext) -match "(?i)$keyword") {
            $personasScore++
        }
    }

    # Analyze examples relevance
    foreach ($keyword in $examplesKeywords) {
        if (($executionContext + $reusablePatterns) -match "(?i)$keyword") {
            $examplesScore++
        }
    }

    # Check for imperative language patterns (constitution)
    if ($content -match "(?m)^[ ]*-[ ]*[A-Z][a-z]*.*(?:must|shall|should|will)") {
        $constitutionScore += 2
    }

    # Return analysis results: constitution|rules|personas|examples|content_sections
    return "$constitutionScore|$rulesScore|$personasScore|$examplesScore|$sessionOverview|$decisionPatterns|$executionContext|$reusablePatterns"
}

# Function to generate team-ai-directives proposals
function New-DirectivesProposals {
    param([string]$ContextFile, [string]$AnalysisResult)

    $parts = $AnalysisResult -split '\|', 8
    $constitutionScore = [int]$parts[0]
    $rulesScore = [int]$parts[1]
    $personasScore = [int]$parts[2]
    $examplesScore = [int]$parts[3]
    $sessionOverview = $parts[4]
    $decisionPatterns = $parts[5]
    $executionContext = $parts[6]
    $reusablePatterns = $parts[7]

    # Extract feature name from file path
    $featureName = [System.IO.Path]::GetFileNameWithoutExtension($ContextFile) -replace '-session$', ''

    $proposals = ""

    # Generate constitution amendment if relevant
    if ($constitutionScore -ge 3) {
        $amendmentTitle = ($sessionOverview -split "`n" | Where-Object { $_ -notmatch "^#" } | Select-Object -First 1 | ForEach-Object { $_.TrimStart('- ').Substring(0, [Math]::Min(50, $_.Length)) })
        if (-not $amendmentTitle) {
            $amendmentTitle = "Constitution Amendment from $featureName"
        }

        $proposals += "**CONSTITUTION AMENDMENT PROPOSAL**

**Proposed Principle:** $amendmentTitle

**Description:**
$($sessionOverview -replace '^#', '###')

**Rationale:** This principle was derived from AI agent session in feature '$featureName'. The approach demonstrated governance and quality considerations that should be codified.

**Evidence:** See AI session context at $ContextFile

**Impact Assessment:**
- Adds new governance requirement for AI agent sessions
- May require updates to agent behavior guidelines
- Enhances project quality and consistency
- Should be reviewed by team before adoption

---
"
    }

    # Generate rules proposal if relevant
    if ($rulesScore -ge 2) {
        $proposals += "**RULES CONTRIBUTION**

**Proposed Rule:** AI Agent Decision Pattern from $featureName

**Pattern Description:**
$($decisionPatterns -replace '^#', '###')

**When to Apply:** Use this decision pattern when facing similar challenges in $featureName-type features.

**Evidence:** See AI session context at $ContextFile

---
"
    }

    # Generate personas proposal if relevant
    if ($personasScore -ge 2) {
        $proposals += "**PERSONA DEFINITION**

**Proposed Persona:** Specialized Agent for $featureName-type Features

**Capabilities Demonstrated:**
$($executionContext -replace '^#', '###')

**Specialization:** $featureName implementation and similar complex feature development.

**Evidence:** See AI session context at $ContextFile

---
"
    }

    # Generate examples proposal if relevant
    if ($examplesScore -ge 2) {
        $proposals += "**EXAMPLE CONTRIBUTION**

**Example:** $featureName Implementation Approach

**Scenario:** Complete feature development from spec to deployment.

**Approach Used:**
$($reusablePatterns -replace '^#', '###')

**Outcome:** Successful implementation with quality gates passed.

**Evidence:** See AI session context at $ContextFile

---
"
    }

    if (-not $proposals) {
        return "No significant team-ai-directives contributions identified from this session."
    }

    return $proposals
}

    # Generate amendment proposal
    $amendmentTitle = ""

    # Try to extract a concise title from the rule
    $lines = $ruleSection -split "`n" | Where-Object { $_ -notmatch '^#' -and $_.Trim() -ne '' }
    if ($lines) {
        $firstLine = $lines[0] -replace '^[ ]*-[ ]*', ''
        $amendmentTitle = $firstLine.Substring(0, [Math]::Min(50, $firstLine.Length))
    }

    if (-not $amendmentTitle) {
        $amendmentTitle = "Amendment from $featureName"
    }

    $amendmentDescription = @"
**Proposed Principle:** $amendmentTitle

**Description:**
$($ruleSection -replace '^#', '###')

**Rationale:** This principle was derived from successful implementation of feature '$featureName'. The rule addresses $($matchedKeywords -split ' ' -join ', ') considerations identified during development.

**Evidence:** See knowledge asset at $KnowledgeFile

**Impact Assessment:**
- Adds new governance requirement
- May require updates to existing processes
- Enhances project quality/consistency
- Should be reviewed by team before adoption
"@

    return $amendmentDescription
}

# Function to validate amendment against existing constitution
function Test-Amendment {
    param([string]$Amendment)

    $constitutionFile = Join-Path $paths.REPO_ROOT '.specify/memory/constitution.md'

    if (-not (Test-Path $constitutionFile)) {
        Write-Warning "No project constitution found at $constitutionFile"
        return $true
    }

    $constitutionContent = Get-Content $constitutionFile -Raw
    $conflicts = @()

    # Extract principle names from amendment
    if ($Amendment -match '\*\*Proposed Principle:\*\* (.+)') {
        $amendmentPrinciple = $matches[1]

        # Check if similar principle already exists
        if ($constitutionContent -match "(?i)$amendmentPrinciple") {
            $conflicts += "Similar principle already exists: $amendmentPrinciple"
        }
    }

    # Check for contradictory language
    $amendmentRules = ($Amendment -split '\*\*Rationale:\*\*')[0] |
        Select-String -Pattern '(?m)^[ ]*-[ ]*[A-Z].*' -AllMatches |
        ForEach-Object { $_.Matches.Value }

    foreach ($rule in $amendmentRules) {
        $ruleWord = ($rule -split ' ' | Select-Object -Last 1)
        if ($constitutionContent -match "(?i)never.*$ruleWord" -or $constitutionContent -match "(?i)must not.*$ruleWord") {
            $conflicts += "Potential contradiction with existing rule: $rule"
        }
    }

    if ($conflicts.Count -gt 0) {
        Write-Host "VALIDATION ISSUES:" -ForegroundColor Red
        foreach ($conflict in $conflicts) {
            Write-Host "  - $conflict" -ForegroundColor Yellow
        }
        return $false
    } else {
        Write-Host "✓ Amendment validation passed - no conflicts detected" -ForegroundColor Green
        return $true
    }
}

# Main logic
if ($Validate) {
    if (-not $KnowledgeFile) {
        Write-Error "Must specify directives contributions file for validation"
        exit 1
    }

    $contributionsContent = Get-Content $KnowledgeFile -Raw
    if (Test-Amendment -Amendment $contributionsContent) {
        if ($Json) {
            @{status="valid"; file=$KnowledgeFile} | ConvertTo-Json -Compress
        } else {
            Write-Host "Directives contributions validation successful" -ForegroundColor Green
        }
    } else {
        if ($Json) {
            @{status="invalid"; file=$KnowledgeFile} | ConvertTo-Json -Compress
        } else {
            Write-Host "Directives contributions validation failed" -ForegroundColor Red
        }
        exit 1
    }
    exit 0
}

if ($Amendment) {
    if (-not $KnowledgeFile) {
        Write-Error "Must specify AI session context file for directives proposals"
        exit 1
    }

    $analysis = Analyze-TeamDirectivesContributions -ContextFile $KnowledgeFile
    $proposals = New-DirectivesProposals -ContextFile $KnowledgeFile -AnalysisResult $analysis

    if ($proposals -notmatch "^No significant team-ai-directives") {
        if ($Json) {
            @{status="proposed"; file=$KnowledgeFile; proposals=$proposals} | ConvertTo-Json
        } else {
            Write-Host "Team-AI-Directives Contribution Proposals:" -ForegroundColor Cyan
            Write-Host "==========================================" -ForegroundColor Cyan
            Write-Host $proposals
            Write-Host ""
            Write-Host "To apply this amendment, run:" -ForegroundColor Yellow
            Write-Host "  constitution-amend --file amendment.md"
        }
    } else {
        if ($Json) {
            @{status="not_constitution_level"; file=$KnowledgeFile} | ConvertTo-Json -Compress
        } else {
            Write-Host $proposal -ForegroundColor Yellow
        }
    }
    exit 0
}

# Default: analyze mode
$analysis = Analyze-TeamDirectivesContributions -ContextFile $KnowledgeFile

$parts = $analysis -split '\|', 4
$constitutionScore = [int]$parts[0]
$rulesScore = [int]$parts[1]
$personasScore = [int]$parts[2]
$examplesScore = [int]$parts[3]

if ($Json) {
    @{
        file = $KnowledgeFile
        constitution_score = $constitutionScore
        rules_score = $rulesScore
        personas_score = $personasScore
        examples_score = $examplesScore
    } | ConvertTo-Json -Compress
} else {
    Write-Host "Team-AI-Directives Contribution Analysis for: $KnowledgeFile" -ForegroundColor Cyan
    Write-Host "Constitution Score: $constitutionScore/10" -ForegroundColor White
    Write-Host "Rules Score: $rulesScore/5" -ForegroundColor White
    Write-Host "Personas Score: $personasScore/5" -ForegroundColor White
    Write-Host "Examples Score: $examplesScore/5" -ForegroundColor White
    Write-Host ""

    $hasContributions = $false
    if ($constitutionScore -ge 3) {
        Write-Host "✓ Constitution contribution potential detected" -ForegroundColor Green
        $hasContributions = $true
    }
    if ($rulesScore -ge 2) {
        Write-Host "✓ Rules contribution potential detected" -ForegroundColor Green
        $hasContributions = $true
    }
    if ($personasScore -ge 2) {
        Write-Host "✓ Personas contribution potential detected" -ForegroundColor Green
        $hasContributions = $true
    }
    if ($examplesScore -ge 2) {
        Write-Host "✓ Examples contribution potential detected" -ForegroundColor Green
        $hasContributions = $true
    }

    if ($hasContributions) {
        Write-Host "Run with -Amendment to generate contribution proposals" -ForegroundColor Yellow
    } else {
        Write-Host "ℹ No significant team-ai-directives contributions identified" -ForegroundColor Yellow
    }
}