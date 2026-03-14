#!/usr/bin/env bash

# Setup script for LevelUp extension
# Initializes CDR file and resolves team-ai-directives path

set -e

JSON_MODE=false
DECOMPOSE=true
ARGS=()

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --no-decompose)
            DECOMPOSE=false
            ;;
        --help|-h)
            echo "Usage: $0 [--json] [--no-decompose]"
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

# Get repository root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Function to detect sub-systems from codebase structure
detect_subsystems() {
    local subsystems=""
    local count=0
    
    echo "Detecting sub-systems from codebase structure..." >&2
    
    local dirs=()
    
    # 1. Top-level feature directories (src/, app/, services/)
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
    
    if [[ -d "services" ]]; then
        for d in services/*/; do
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
    
    # Output as JSON array if JSON mode (without outer braces - will be merged into main output)
    if $JSON_MODE; then
        printf '"subsystems":['
        local first=true
        for d in "${dirs[@]}"; do
            if [[ "$first" == "true" ]]; then
                first=false
            else
                printf ','
            fi
            printf '{"id":"%s","name":"%s","detection_method":"directory","evidence":"%s/"}' "$d" "$d" "$d"
        done
        printf '],"decomposition":%s' "$DECOMPOSE"
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

# Resolve team-ai-directives path
# Priority:
# 1. SPECIFY_TEAM_DIRECTIVES environment variable
# 2. .specify/config.json team_directives.path (from specify init)
# 3. .specify/team-ai-directives (submodule - recommended)
# 4. .specify/memory/team-ai-directives (clone - legacy)

TEAM_DIRECTIVES="${SPECIFY_TEAM_DIRECTIVES:-}"

if [[ -z "$TEAM_DIRECTIVES" ]]; then
    # Try reading from config.json (written by specify init)
    CONFIG_FILE="$REPO_ROOT/.specify/config.json"
    if [[ -f "$CONFIG_FILE" ]]; then
        # Extract team_directives.path using grep/sed (no jq dependency)
        CONFIG_PATH=$(grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
        if [[ -n "$CONFIG_PATH" && -d "$CONFIG_PATH" ]]; then
            TEAM_DIRECTIVES="$CONFIG_PATH"
        fi
    fi
fi

if [[ -z "$TEAM_DIRECTIVES" ]]; then
    if [[ -d "$REPO_ROOT/.specify/team-ai-directives" ]]; then
        TEAM_DIRECTIVES="$REPO_ROOT/.specify/team-ai-directives"
    elif [[ -d "$REPO_ROOT/.specify/memory/team-ai-directives" ]]; then
        TEAM_DIRECTIVES="$REPO_ROOT/.specify/memory/team-ai-directives"
    fi
fi

# Skills drafts location
SKILLS_DRAFTS="$REPO_ROOT/.specify/drafts/skills"

# CDR file location
CDR_FILE="$REPO_ROOT/.specify/drafts/cdr.md"

# Ensure directories exist
mkdir -p "$REPO_ROOT/.specify/drafts"
mkdir -p "$SKILLS_DRAFTS"

# Get current git branch
CURRENT_BRANCH=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi

# Output results
if $JSON_MODE; then
    subsystem_data=$(detect_subsystems)
    printf '{"REPO_ROOT":"%s","TEAM_DIRECTIVES":"%s","SKILLS_DRAFTS":"%s","CDR_FILE":"%s","BRANCH":"%s",%s}\n' \
        "$REPO_ROOT" "$TEAM_DIRECTIVES" "$SKILLS_DRAFTS" "$CDR_FILE" "$CURRENT_BRANCH" "$subsystem_data"
else
    echo "REPO_ROOT: $REPO_ROOT"
    if [[ -n "$TEAM_DIRECTIVES" ]]; then
        echo "TEAM_DIRECTIVES: $TEAM_DIRECTIVES"
    else
        echo "TEAM_DIRECTIVES: (not configured)"
    fi
    echo "SKILLS_DRAFTS: $SKILLS_DRAFTS"
    echo "CDR_FILE: $CDR_FILE"
    echo "BRANCH: $CURRENT_BRANCH"
    detect_subsystems
fi
