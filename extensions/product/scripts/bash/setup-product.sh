#!/bin/bash

# Product Extension Setup Script
# Sets up PRD and PDR files for the product extension

set -e

JSON_MODE=false
DECOMPOSE=true
ARGS=()

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --no-decompose)
            DECOMPOSE=false
            ;;
        --help|-h)
            echo "Usage: $0 [command] [--json] [--no-decompose]"
            echo ""
            echo "Commands:"
            echo "  specify    Setup for greenfield product specification"
            echo "  init       Setup for brownfield product discovery"
            echo "  implement  Setup for PRD generation"
            echo "  clarify    Setup for PDR refinement"
            echo "  analyze    Setup for consistency analysis"
            echo "  validate   Setup for plan validation"
            echo ""
            echo "Options:"
            echo "  --json           Output results in JSON format"
            echo "  --no-decompose   Disable automatic sub-system decomposition"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
done

COMMAND="${ARGS[0]:-help}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default locations
PDR_LOCATION=".specify/drafts/pdr.md"

# Resolve team-ai-directives path
TEAM_DIRECTIVES=""
if [[ -n "$SPECIFY_TEAM_DIRECTIVES" ]]; then
    if [[ -d "$SPECIFY_TEAM_DIRECTIVES" ]]; then
        TEAM_DIRECTIVES="$SPECIFY_TEAM_DIRECTIVES"
    fi
fi

if [[ -z "$TEAM_DIRECTIVES" ]]; then
    if [[ -d "$REPO_ROOT/.specify/team-ai-directives" ]]; then
        TEAM_DIRECTIVES="$REPO_ROOT/.specify/team-ai-directives"
    elif [[ -d "$REPO_ROOT/.specify/memory/team-ai-directives" ]]; then
        TEAM_DIRECTIVES="$REPO_ROOT/.specify/memory/team-ai-directives"
    fi
fi

# PRD output location - use TD if configured, else project root
if [[ -n "$TEAM_DIRECTIVES" ]]; then
    PRD_LOCATION="$TEAM_DIRECTIVES/PRD.md"
    PRD_TEAM_MODE=true
else
    PRD_LOCATION="PRD.md"
    PRD_TEAM_MODE=false
fi

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get repository root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Function to detect sub-systems from codebase structure
detect_subsystems() {
    local subsystems=""
    local count=0
    
    echo "Detecting sub-systems from codebase structure..." >&2
    
    local dirs=()
    
    # 1. Top-level feature directories (src/, app/, features/)
    if [[ -d "src" ]]; then
        for d in src/*/; do
            if [[ -d "$d" ]]; then
                local dirname
                dirname=$(basename "$d")
                if [[ "$dirname" != "utils" && "$dirname" != "common" && "$dirname" != "lib" && "$dirname" != "shared" && "$dirname" != "core" ]]; then
                    dirs+=("$dirname")
                fi
            fi
        done
    fi
    
    if [[ -d "features" ]]; then
        for d in features/*/; do
            if [[ -d "$d" ]]; then
                local dirname
                dirname=$(basename "$d")
                dirs+=("$dirname")
            fi
        done
    fi
    
    if [[ -d "modules" ]]; then
        for d in modules/*/; do
            if [[ -d "$d" ]]; then
                local dirname
                dirname=$(basename "$d")
                dirs+=("$dirname")
            fi
        done
    fi
    
    if [[ -d "apps" ]]; then
        for d in apps/*/; do
            if [[ -d "$d" ]]; then
                local dirname
                dirname=$(basename "$d")
                dirs+=("$dirname")
            fi
        done
    fi
    
    # 2. Check for docker-compose services (microservices indicator)
    if [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]]; then
        local compose_file="docker-compose.yml"
        [[ -f "docker-compose.yaml" ]] && compose_file="docker-compose.yaml"
        
        local services=()
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*([a-zA-Z0-9_-]+):[[:space:]]*$ ]]; then
                local svc="${BASH_REMATCH[1]}"
                if [[ "$svc" != "version" && "$svc" != "services" && "$svc" != "networks" && "$svc" != "volumes" ]]; then
                    services+=("$svc")
                fi
            fi
        done < "$compose_file"
        
        for svc in "${services[@]}"; do
            local found=false
            for d in "${dirs[@]}"; do
                if [[ "${d,,}" == *"${svc,,}"* ]] || [[ "${svc,,}" == *"${d,,}"* ]]; then
                    found=true
                    break
                fi
            done
            if [[ "$found" == "false" ]]; then
                dirs+=("$svc")
            fi
        done
    fi
    
    # 3. Check for Node.js workspaces (monorepo indicator)
    if [[ -f "package.json" ]]; then
        if grep -q '"workspaces"' package.json 2>/dev/null; then
            local pkgs
            pkgs=$(node -e "try { const p = require('./package.json'); console.log(Object.keys(p.workspaces?.packages || {}).join(' ')); } catch(e) { }" 2>/dev/null || true)
            for pkg in $pkgs; do
                local dirname
                dirname=$(basename "$pkg")
                if [[ "$dirname" != "node_modules" ]]; then
                    dirs+=("$dirname")
                fi
            done
        fi
    fi
    
    # 4. Check for Python namespace packages
    if [[ -f "pyproject.toml" ]]; then
        local pkg_dirs=()
        while IFS= read -r -d '' d; do
            pkg_dirs+=("$(basename "$d")")
        done < <(find . -maxdepth 3 -name "__init__.py" -printf '%h\n' 2>/dev/null | grep -v node_modules | grep -v __pycache__ | sort -u || true)
        
        for pdir in "${pkg_dirs[@]}"; do
            if [[ "$pdir" != "." && "$pdir" != "src" ]]; then
                dirs+=("$pdir")
            fi
        done
    fi
    
    # 5. Check for Go modules
    if [[ -f "go.mod" ]]; then
        if [[ -d "cmd" ]]; then
            for d in cmd/*/; do
                if [[ -d "$d" ]]; then
                    local dirname
                    dirname=$(basename "$d")
                    dirs+=("$dirname")
                fi
            done
        fi
    fi
    
    # Output as JSON array if JSON mode
    if $JSON_MODE; then
        printf '{"subsystems":['
        local first=true
        for d in "${dirs[@]}"; do
            if [[ "$first" == "true" ]]; then
                first=false
            else
                printf ','
            fi
            printf '{"id":"%s","name":"%s","detection_method":"directory","evidence":"%s/"}' "$d" "$d" "$d"
        done
        printf '],"decomposition":%s}' "$DECOMPOSE"
    else
        # Human-readable output
        if [[ ${#dirs[@]} -eq 0 ]]; then
            echo "No sub-systems detected." >&2
        else
            echo "Detected ${#dirs[@]} sub-systems:" >&2
            for d in "${dirs[@]}"; do
                echo "  - $d" >&2
            done
        fi
    fi
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
EOF
        log_info "PRD file created at $prd_file"
    fi
    
    echo "$prd_file"
}

case "$COMMAND" in
    "specify")
        if $JSON_MODE; then
            printf '{"REPO_ROOT":"%s","PDR_FILE":"%s","PRD_FILE":"%s","COMMAND":"%s"}' "$REPO_ROOT" "$PDR_LOCATION" "$PRD_LOCATION" "$COMMAND"
        else
            log_info "Setting up for product specification..."
            pdr_path=$(setup_pdr)
            log_info "Ready for PDR creation in $pdr_path"
        fi
        ;;
    "init")
        if $JSON_MODE; then
            subsystem_data=$(detect_subsystems)
            printf '{"REPO_ROOT":"%s","PDR_FILE":"%s","PRD_FILE":"%s","COMMAND":"%s",%s' "$REPO_ROOT" "$PDR_LOCATION" "$PRD_LOCATION" "$COMMAND" "${subsystem_data:1}"
        else
            log_info "Setting up for brownfield discovery..."
            pdr_path=$(setup_pdr)
            log_info "Ready for PDR discovery in $pdr_path"
            detect_subsystems
        fi
        ;;
    "implement")
        if $JSON_MODE; then
            printf '{"REPO_ROOT":"%s","PDR_FILE":"%s","PRD_FILE":"%s","COMMAND":"%s"}' "$REPO_ROOT" "$PDR_LOCATION" "$PRD_LOCATION" "$COMMAND"
        else
            log_info "Setting up for PRD generation..."
            prd_path=$(setup_prd)
            pdr_path=$(setup_pdr)
            log_info "Ready for PRD generation: $prd_path"
        fi
        ;;
    "clarify"|"analyze"|"validate")
        if $JSON_MODE; then
            printf '{"REPO_ROOT":"%s","PDR_FILE":"%s","PRD_FILE":"%s","COMMAND":"%s"}' "$REPO_ROOT" "$PDR_LOCATION" "$PRD_LOCATION" "$COMMAND"
        else
            log_info "Setting up for $COMMAND..."
            pdr_path=$(setup_pdr)
            prd_path=$(setup_prd)
            log_info "Ready for $COMMAND"
        fi
        ;;
    "help"|*)
        echo "Product Extension Setup Script"
        echo ""
        echo "Usage: $0 <command> [--json] [--no-decompose]"
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
