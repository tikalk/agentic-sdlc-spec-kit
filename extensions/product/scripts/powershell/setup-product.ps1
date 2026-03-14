# Product Extension Setup Script
# Sets up PRD and PDR files for the product extension

param(
    [string]$Command = "help",
    [switch]$Json = $false,
    [switch]$NoDecompose = $false
)

$ErrorActionPreference = "Stop"

# Default locations
$PDR_LOCATION = ".specify/drafts/pdr.md"
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

function Get-RepoRoot {
    try {
        $gitDir = git rev-parse --show-toplevel 2>$null
        if ($gitDir) { return $gitDir }
    } catch {}
    return Get-Location
}

function Detect-Subsystems {
    $repoRoot = Get-RepoRoot
    $originalLocation = Get-Location
    
    try {
        Set-Location $repoRoot -ErrorAction SilentlyContinue | Out-Null
    } catch {
        return @()
    }
    
    $dirs = @()
    
    # 1. Top-level feature directories (src/, app/, features/)
    if (Test-Path "src") {
        Get-ChildItem -Path "src" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $dirname = $_.Name
            if ($dirname -notin @("utils", "common", "lib", "shared", "core")) {
                $dirs += $dirname
            }
        }
    }
    
    if (Test-Path "features") {
        Get-ChildItem -Path "features" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $dirs += $_.Name
        }
    }
    
    if (Test-Path "modules") {
        Get-ChildItem -Path "modules" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $dirs += $_.Name
        }
    }
    
    if (Test-Path "apps") {
        Get-ChildItem -Path "apps" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $dirs += $_.Name
        }
    }
    
    # 2. Check for docker-compose services
    $composeFile = $null
    if (Test-Path "docker-compose.yml") { $composeFile = "docker-compose.yml" }
    elseif (Test-Path "docker-compose.yaml") { $composeFile = "docker-compose.yaml" }
    
    if ($composeFile) {
        $content = Get-Content $composeFile -Raw
        $services = [regex]::Matches($content, '^\s*([a-zA-Z0-9_-]+):\s*$' , [System.Text.RegularExpressions.RegexOptions]::Multiline) | ForEach-Object { $_.Groups[1].Value }
        $services = $services | Where-Object { $_ -notin @("version", "services", "networks", "volumes") }
        
        foreach ($svc in $services) {
            $found = $false
            foreach ($d in $dirs) {
                if ($d.ToLower() -like "*$($svc.ToLower())*" -or $svc.ToLower() -like "*$($d.ToLower())*") {
                    $found = $true
                    break
                }
            }
            if (-not $found) {
                $dirs += $svc
            }
        }
    }
    
    # 3. Check for Node.js workspaces
    if (Test-Path "package.json") {
        try {
            $packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
            if ($packageJson.workspaces) {
                $packageJson.workspaces | ForEach-Object {
                    $dirname = [System.IO.Path]::GetFileName($_)
                    if ($dirname -ne "node_modules" -and $dirs -notcontains $dirname) {
                        $dirs += $dirname
                    }
                }
            }
        } catch {}
    }
    
    # 4. Check for Python namespace packages
    if (Test-Path "pyproject.toml") {
        Get-ChildItem -Path . -Recurse -Filter "__init__.py" -ErrorAction SilentlyContinue | 
            Where-Object { $_.FullName -notmatch "node_modules|__pycache__" } | 
            Select-Object -First 20 | ForEach-Object {
                $dirname = $_.Directory.Name
                if ($dirname -ne "." -and $dirname -ne "src" -and $dirs -notcontains $dirname) {
                    $dirs += $dirname
                }
            }
    }
    
    # 5. Check for Go modules
    if (Test-Path "go.mod" -and (Test-Path "cmd")) {
        Get-ChildItem -Path "cmd" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            if ($dirs -notcontains $_.Name) {
                $dirs += $_.Name
            }
        }
    }
    
    Set-Location $originalLocation | Out-Null
    
    return $dirs
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
**PDR Reference:** [.specify/drafts/pdr.md](.specify/drafts/pdr.md)

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

$REPO_ROOT = Get-RepoRoot

# Resolve team-ai-directives path
$teamDirectives = $null
if ($env:SPECIFY_TEAM_DIRECTIVES) {
    if (Test-Path $env:SPECIFY_TEAM_DIRECTIVES) {
        $teamDirectives = $env:SPECIFY_TEAM_DIRECTIVES
    }
}
if (-not $teamDirectives) {
    $tdPath1 = Join-Path $REPO_ROOT ".specify\team-ai-directives"
    $tdPath2 = Join-Path $REPO_ROOT ".specify\memory\team-ai-directives"
    if (Test-Path $tdPath1) {
        $teamDirectives = $tdPath1
    } elseif (Test-Path $tdPath2) {
        $teamDirectives = $tdPath2
    }
}

# PRD output location - use TD if configured
if ($teamDirectives) {
    $PRD_LOCATION = Join-Path $teamDirectives "PRD.md"
    $prdTeamMode = $true
} else {
    $PRD_LOCATION = "PRD.md"
    $prdTeamMode = $false
}

switch ($Command.ToLower()) {
    "specify" {
        if ($Json) {
            $result = @{
                REPO_ROOT = $REPO_ROOT
                PDR_FILE = $PDR_LOCATION
                PRD_FILE = $PRD_LOCATION
                COMMAND = $Command
            }
            $result | ConvertTo-Json -Compress
        } else {
            Write-LogInfo "Setting up for product specification..."
            $pdrPath = Setup-PDR
            Write-LogInfo "Ready for PDR creation in $pdrPath"
        }
    }
    "init" {
        if ($Json) {
            $subsystems = @(Detect-Subsystems)
            $subsystemObjects = @()
            foreach ($s in $subsystems) {
                $subsystemObjects += @{
                    id = $s
                    name = $s
                    detection_method = "directory"
                    evidence = "$s/"
                }
            }
            $result = @{
                REPO_ROOT = $REPO_ROOT
                PDR_FILE = $PDR_LOCATION
                PRD_FILE = $PRD_LOCATION
                COMMAND = $Command
                subsystems = $subsystemObjects
                decomposition = -not $NoDecompose
            }
            $result | ConvertTo-Json -Compress
        } else {
            Write-LogInfo "Setting up for brownfield discovery..."
            $pdrPath = Setup-PDR
            Write-LogInfo "Ready for PDR discovery in $pdrPath"
            $subsystems = Detect-Subsystems
            if ($subsystems.Count -eq 0) {
                Write-LogInfo "No sub-systems detected."
            } else {
                Write-LogInfo "Detected $($subsystems.Count) sub-systems:"
                foreach ($s in $subsystems) {
                    Write-Host "  - $s" -ForegroundColor Cyan
                }
            }
        }
    }
    "implement" {
        if ($Json) {
            $result = @{
                REPO_ROOT = $REPO_ROOT
                PDR_FILE = $PDR_LOCATION
                PRD_FILE = $PRD_LOCATION
                COMMAND = $Command
            }
            $result | ConvertTo-Json -Compress
        } else {
            Write-LogInfo "Setting up for PRD generation..."
            $prdPath = Setup-PRD
            $pdrPath = Setup-PDR
            Write-LogInfo "Ready for PRD generation: $prdPath"
        }
    }
    "clarify" {
        if ($Json) {
            $result = @{
                REPO_ROOT = $REPO_ROOT
                PDR_FILE = $PDR_LOCATION
                PRD_FILE = $PRD_LOCATION
                COMMAND = $Command
            }
            $result | ConvertTo-Json -Compress
        } else {
            Write-LogInfo "Setting up for PDR clarification..."
            $pdrPath = Setup-PDR
            Write-LogInfo "Ready for clarification"
        }
    }
    "analyze" {
        if ($Json) {
            $result = @{
                REPO_ROOT = $REPO_ROOT
                PDR_FILE = $PDR_LOCATION
                PRD_FILE = $PRD_LOCATION
                COMMAND = $Command
            }
            $result | ConvertTo-Json -Compress
        } else {
            Write-LogInfo "Setting up for consistency analysis..."
            $prdPath = Setup-PRD
            $pdrPath = Setup-PDR
            Write-LogInfo "Ready for analysis"
        }
    }
    "validate" {
        if ($Json) {
            $result = @{
                REPO_ROOT = $REPO_ROOT
                PDR_FILE = $PDR_LOCATION
                PRD_FILE = $PRD_LOCATION
                COMMAND = $Command
            }
            $result | ConvertTo-Json -Compress
        } else {
            Write-LogInfo "Setting up for plan validation..."
            $prdPath = Setup-PRD
            $pdrPath = Setup-PDR
            Write-LogInfo "Ready for validation"
        }
    }
    default {
        Write-Host "Product Extension Setup Script" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage: .\setup-product.ps1 <command> [-Json] [-NoDecompose]" -ForegroundColor White
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor White
        Write-Host "  specify    Setup for greenfield product specification"
        Write-Host "  init       Setup for brownfield product discovery"
        Write-Host "  implement  Setup for PRD generation"
        Write-Host "  clarify    Setup for PDR refinement"
        Write-Host "  analyze    Setup for consistency analysis"
        Write-Host "  validate   Setup for plan validation"
        Write-Host ""
        Write-Host "Options:" -ForegroundColor White
        Write-Host "  -Json          Output results in JSON format"
        Write-Host "  -NoDecompose   Disable automatic sub-system decomposition"
        Write-Host "  help       Show this help message"
    }
}
