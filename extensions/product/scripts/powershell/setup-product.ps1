# Product Extension Setup Script
# Sets up PRD and PDR files for the product extension

param(
    [string]$Command = "help"
)

$ErrorActionPreference = "Stop"

# Default locations
$PDR_LOCATION = ".specify/memory/pdr.md"
$PRD_LOCATION = "PRD.md"

function Write-LogInfo {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-LogWarn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-LogError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Setup-PDR {
    $pdrFile = $PDR_LOCATION
    
    if (Test-Path $pdrFile) {
        Write-LogInfo "PDR file already exists at $pdrFile"
    } else {
        Write-LogInfo "Creating PDR file at $pdrFile"
        $pdrDir = Split-Path -Parent $pdrFile
        if ($pdrDir -and -not (Test-Path $pdrDir)) {
            New-Item -ItemType Directory -Path $pdrDir -Force | Out-Null
        }
        
        @"
# Product Decision Records

## PDR Index

| ID | Category | Decision | Status | Date | Owner |
|----|----------|----------|--------|------|-------|
| PDR-001 | [Category] | [First decision title] | Proposed | YYYY-MM-DD | [Owner] |

---

## PDR-001: [Decision Title]

### Status

**Proposed** | Accepted | Deprecated | Superseded by PDR-XXX | **Discovered** (Inferred from existing product)

### Date

YYYY-MM-DD

### Owner

[Product Manager / Team / Stakeholder]

### Category

[Problem | Persona | Scope | Metric | Prioritization | Business Model | Feature | NFR]

### Context

**Problem/Opportunity:**
[Clear description of what needs to be decided]

**Market Forces:**
- [Market factor 1]
- [Customer feedback]
- [Internal business priority]

### Decision

**Decision Statement:**
[Clear statement of what was decided]

### Consequences

#### Positive

- [User benefit]
- [Business benefit]

#### Negative

- [Trade-off]
- [Opportunity cost]

#### Risks

- [Risk with mitigation]

### Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| [Metric] | [Target] | [Method] |

### Alternatives Considered

#### Option A: [Alternative]

**Description:** [Brief description]
**Trade-offs:** [Neutral comparison]
"@ | Set-Content -Path $pdrFile -Encoding UTF8
        
        Write-LogInfo "PDR file created at $pdrFile"
    }
    
    return $pdrFile
}

function Setup-PRD {
    $prdFile = $PRD_LOCATION
    
    if (Test-Path $prdFile) {
        Write-LogInfo "PRD file already exists at $prdFile"
    } else {
        Write-LogInfo "Creating PRD file at $prdFile"
        
        @"
# Product Requirements Document: [PRODUCT_NAME]

**Version:** 1.0  
**Date:** YYYY-MM-DD  
**Author:** [Author]  
**Status:** Draft  
**PDR Reference:** [.specify/memory/pdr.md](.specify/memory/pdr.md)

---

## 1. Overview

[High-level description of the product]

## 2. The Problem

[Problem statement]

## 3. Goals/Objectives

* **Primary Goal:** [Main objective]
* **Technical Goal:** [Technical outcome]
* **Business Goal:** [Business value]

## 4. Success Metrics

* **Adoption:** [Metric and target]
* **Engagement:** [Metric and target]
* **Revenue/Value:** [Metric and target]

## 5. Personas

* **Primary Persona:** [Persona Name]
  * **Role:** [Job title]
  * **Needs:** [What they need]

## 6. Functional Requirements

| ID | Story | Priority |
|----|-------|----------|
| US-001 | [As a... I want to... So that...] | Must |

## 7. Non-Functional Requirements

* **Performance:** [Requirements]
* **Security:** [Requirements]
* **Reliability:** [Requirements]

## 8. Out of Scope

* [Explicitly excluded feature]

## 9. Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| [Risk] | [Mitigation] |

---

## Appendix

### A. References

### B. Change History
"@ | Set-Content -Path $prdFile -Encoding UTF8
        
        Write-LogInfo "PRD file created at $prdFile"
    }
    
    return $prdFile
}

switch ($Command.ToLower()) {
    "specify" {
        Write-LogInfo "Setting up for product specification..."
        $pdrPath = Setup-PDR
        Write-LogInfo "Ready for PDR creation in $pdrPath"
    }
    "init" {
        Write-LogInfo "Setting up for brownfield discovery..."
        $pdrPath = Setup-PDR
        Write-LogInfo "Ready for PDR discovery in $pdrPath"
    }
    "implement" {
        Write-LogInfo "Setting up for PRD generation..."
        $prdPath = Setup-PRD
        $pdrPath = Setup-PDR
        Write-LogInfo "Ready for PRD generation: $prdPath"
    }
    "clarify" {
        Write-LogInfo "Setting up for PDR clarification..."
        $pdrPath = Setup-PDR
        Write-LogInfo "Ready for clarification"
    }
    "analyze" {
        Write-LogInfo "Setting up for consistency analysis..."
        $prdPath = Setup-PRD
        $pdrPath = Setup-PDR
        Write-LogInfo "Ready for analysis"
    }
    "validate" {
        Write-LogInfo "Setting up for plan validation..."
        $prdPath = Setup-PRD
        $pdrPath = Setup-PDR
        Write-LogInfo "Ready for validation"
    }
    default {
        Write-Host "Product Extension Setup Script" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage: .\setup-product.ps1 <command>" -ForegroundColor White
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor White
        Write-Host "  specify    Setup for greenfield product specification"
        Write-Host "  init       Setup for brownfield product discovery"
        Write-Host "  implement  Setup for PRD generation"
        Write-Host "  clarify    Setup for PDR refinement"
        Write-Host "  analyze    Setup for consistency analysis"
        Write-Host "  validate   Setup for plan validation"
        Write-Host "  help       Show this help message"
    }
}
