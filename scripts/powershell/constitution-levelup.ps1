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
    Write-Error "Must specify knowledge asset file or use -Amendment/-Validate mode"
    exit 1
}

. "$PSScriptRoot/common.ps1"

$paths = Get-FeaturePathsEnv

# Function to analyze knowledge asset for constitution-relevant rules
function Analyze-ConstitutionRelevance {
    param([string]$KnowledgeFile)

    if (-not (Test-Path $KnowledgeFile)) {
        Write-Error "Knowledge asset file not found: $KnowledgeFile"
        exit 1
    }

    $content = Get-Content $KnowledgeFile -Raw

    # Extract the reusable rule/best practice section
    $ruleSection = ""
    if ($content -match '(?s)## Reusable rule or best practice(.*?)(?=^## )') {
        $ruleSection = $matches[1]
    } elseif ($content -match '(?s)### Reusable rule or best practice(.*?)(?=^## )') {
        $ruleSection = $matches[1]
    }

    # Keywords that indicate constitution-level significance
    $constitutionKeywords = @(
        "must", "shall", "required", "mandatory", "always", "never",
        "principle", "governance", "policy", "standard", "quality",
        "security", "testing", "documentation", "architecture",
        "compliance", "oversight", "review", "approval"
    )

    $relevanceScore = 0
    $matchedKeywords = @()

    foreach ($keyword in $constitutionKeywords) {
        if ($ruleSection -match "(?i)$keyword") {
            $relevanceScore++
            $matchedKeywords += $keyword
        }
    }

    # Check for imperative language patterns
    if ($ruleSection -match "(?m)^[ ]*-[ ]*[A-Z][a-z]*.*(?:must|shall|should|will)") {
        $relevanceScore += 2
    }

    return "$relevanceScore|$($matchedKeywords -join ' ')|$ruleSection"
}

# Function to generate constitution amendment proposal
function New-AmendmentProposal {
    param([string]$KnowledgeFile, [string]$AnalysisResult)

    $parts = $AnalysisResult -split '\|', 3
    $relevanceScore = [int]$parts[0]
    $matchedKeywords = $parts[1]
    $ruleSection = $parts[2]

    if ($relevanceScore -lt 3) {
        return "Rule does not appear constitution-level (score: $relevanceScore)"
    }

    # Extract feature name from file path
    $featureName = [System.IO.Path]::GetFileNameWithoutExtension($KnowledgeFile) -replace '-levelup$', ''

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
        Write-Error "Must specify amendment file for validation"
        exit 1
    }

    $amendmentContent = Get-Content $KnowledgeFile -Raw
    if (Test-Amendment -Amendment $amendmentContent) {
        if ($Json) {
            @{status="valid"; file=$KnowledgeFile} | ConvertTo-Json -Compress
        } else {
            Write-Host "Amendment validation successful" -ForegroundColor Green
        }
    } else {
        if ($Json) {
            @{status="invalid"; file=$KnowledgeFile} | ConvertTo-Json -Compress
        } else {
            Write-Host "Amendment validation failed" -ForegroundColor Red
        }
        exit 1
    }
    exit 0
}

if ($Amendment) {
    if (-not $KnowledgeFile) {
        Write-Error "Must specify knowledge asset file for amendment generation"
        exit 1
    }

    $analysis = Analyze-ConstitutionRelevance -KnowledgeFile $KnowledgeFile
    $proposal = New-AmendmentProposal -KnowledgeFile $KnowledgeFile -AnalysisResult $analysis

    if ($proposal -notmatch "^Rule does not appear") {
        if ($Json) {
            @{status="proposed"; file=$KnowledgeFile; proposal=$proposal} | ConvertTo-Json
        } else {
            Write-Host "Constitution Amendment Proposal:" -ForegroundColor Cyan
            Write-Host "=================================" -ForegroundColor Cyan
            Write-Host $proposal
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
$analysis = Analyze-ConstitutionRelevance -KnowledgeFile $KnowledgeFile

$parts = $analysis -split '\|', 3
$relevanceScore = [int]$parts[0]
$matchedKeywords = $parts[1]

if ($Json) {
    @{
        file = $KnowledgeFile
        relevance_score = $relevanceScore
        matched_keywords = $matchedKeywords
    } | ConvertTo-Json -Compress
} else {
    Write-Host "Constitution Relevance Analysis for: $KnowledgeFile" -ForegroundColor Cyan
    Write-Host "Relevance Score: $relevanceScore/10" -ForegroundColor White
    Write-Host "Matched Keywords: $matchedKeywords" -ForegroundColor White
    Write-Host ""

    if ($relevanceScore -ge 3) {
        Write-Host "✓ This learning appears constitution-level" -ForegroundColor Green
        Write-Host "Run with -Amendment to generate a proposal" -ForegroundColor Yellow
    } else {
        Write-Host "ℹ This learning appears project-level, not constitution-level" -ForegroundColor Yellow
    }
}