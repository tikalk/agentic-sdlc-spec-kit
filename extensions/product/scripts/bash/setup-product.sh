#!/bin/bash

# Product Extension Setup Script
# Sets up PRD and PDR files for the product extension

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMAND="${1:-help}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default locations
PDR_LOCATION=".specify/memory/pdr.md"
PRD_LOCATION="PRD.md"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

setup_pdr() {
    local pdr_file="$PDR_LOCATION"
    
    if [ -f "$pdr_file" ]; then
        log_info "PDR file already exists at $pdr_file"
    else
        log_info "Creating PDR file at $pdr_file"
        mkdir -p "$(dirname "$pdr_file")"
        cat > "$pdr_file" << 'EOF'
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

EOF
        log_info "PDR file created at $pdr_file"
    fi
    
    echo "$pdr_file"
}

setup_prd() {
    local prd_file="$PRD_LOCATION"
    
    if [ -f "$prd_file" ]; then
        log_info "PRD file already exists at $prd_file"
    else
        log_info "Creating PRD file at $prd_file"
        cat > "$prd_file" << 'EOF'
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
EOF
        log_info "PRD file created at $prd_file"
    fi
    
    echo "$prd_file"
}

case "$COMMAND" in
    "specify")
        log_info "Setting up for product specification..."
        pdr_path=$(setup_pdr)
        log_info "Ready for PDR creation in $pdr_path"
        ;;
    "init")
        log_info "Setting up for brownfield discovery..."
        pdr_path=$(setup_pdr)
        log_info "Ready for PDR discovery in $pdr_path"
        ;;
    "implement")
        log_info "Setting up for PRD generation..."
        prd_path=$(setup_prd)
        pdr_path=$(setup_pdr)
        log_info "Ready for PRD generation: $prd_path"
        ;;
    "clarify"|"analyze"|"validate")
        log_info "Setting up for $COMMAND..."
        pdr_path=$(setup_pdr)
        prd_path=$(setup_prd)
        log_info "Ready for $COMMAND"
        ;;
    "help"|*)
        echo "Product Extension Setup Script"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  specify    Setup for greenfield product specification"
        echo "  init       Setup for brownfield product discovery"
        echo "  implement  Setup for PRD generation"
        echo "  clarify    Setup for PDR refinement"
        echo "  analyze    Setup for consistency analysis"
        echo "  validate   Setup for plan validation"
        echo "  help       Show this help message"
        ;;
esac
