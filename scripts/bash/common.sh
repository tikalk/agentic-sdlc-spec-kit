#!/usr/bin/env bash
# Common functions and variables for all scripts

# Shared constants
TEAM_DIRECTIVES_DIRNAME="team-ai-directives"

# Get the global config path using XDG Base Directory spec
# Platform-specific locations:
# - Linux: ~/.config/specify/config.json
# - macOS: ~/Library/Application Support/specify/config.json (but we use XDG for consistency)
get_global_config_path() {
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    echo "$config_home/specify/config.json"
}

# Get current workflow mode from global config (build or spec)
# Defaults to "spec" if config doesn't exist or mode is invalid
get_current_mode() {
    local config_file
    config_file=$(get_global_config_path)
    
    # Default to spec mode if no config exists
    if [[ ! -f "$config_file" ]] || ! command -v jq >/dev/null 2>&1; then
        echo "spec"
        return
    fi
    
    # Read mode from config, default to spec
    local mode
    mode=$(jq -r '.workflow.current_mode // "spec"' "$config_file" 2>/dev/null)
    
    # Validate mode (only build or spec allowed, treat "ad" as spec for migration)
    if [[ "$mode" == "build" || "$mode" == "spec" ]]; then
        echo "$mode"
    else
        echo "spec"  # Fallback for invalid values including "ad"
    fi
}

# Get a specific mode configuration value
# Usage: get_mode_config "atomic_commits" → returns "true" or "false"
# Usage: get_mode_config "skip_micro_review" → returns "true" or "false"
get_mode_config() {
    local key="$1"
    local config_file
    config_file=$(get_global_config_path)
    
    # Default to false if no config exists or jq not available
    if [[ ! -f "$config_file" ]] || ! command -v jq >/dev/null 2>&1; then
        echo "false"
        return
    fi
    
    # Get current mode
    local mode
    mode=$(get_current_mode)
    
    # Read mode-specific config value, default to false
    local value
    value=$(jq -r ".mode_defaults.${mode}.${key} // false" "$config_file" 2>/dev/null)
    
    echo "$value"
}

# Get architecture diagram format from global config (mermaid or ascii)
# Defaults to "mermaid" if config doesn't exist or format is invalid
get_architecture_diagram_format() {
    local config_file
    config_file=$(get_global_config_path)
    
    # Default to mermaid if no config exists or jq not available
    if [[ ! -f "$config_file" ]] || ! command -v jq >/dev/null 2>&1; then
        echo "mermaid"
        return
    fi
    
    # Read diagram format from config, default to mermaid
    local format
    format=$(jq -r '.architecture.diagram_format // "mermaid"' "$config_file" 2>/dev/null)
    
    # Validate format (only mermaid or ascii allowed)
    if [[ "$format" == "mermaid" || "$format" == "ascii" ]]; then
        echo "$format"
    else
        echo "mermaid"  # Fallback for invalid values
    fi
}

# Validate Mermaid diagram syntax (lightweight regex validation)
# Returns 0 if valid, 1 if invalid
# Args: $1 - Mermaid code string
validate_mermaid_syntax() {
    local mermaid_code="$1"
    
    # Check if empty
    if [[ -z "$mermaid_code" ]]; then
        return 1
    fi
    
    # Check for basic Mermaid diagram types
    if ! echo "$mermaid_code" | grep -qE '^(graph|flowchart|sequenceDiagram|classDiagram|stateDiagram|erDiagram|gantt|pie|journey|gitGraph|mindmap|timeline)'; then
        return 1
    fi
    
    # Check for balanced brackets/parentheses (simplified)
    local open_brackets=$(echo "$mermaid_code" | grep -o '\[' | wc -l)
    local close_brackets=$(echo "$mermaid_code" | grep -o '\]' | wc -l)
    local open_parens=$(echo "$mermaid_code" | grep -o '(' | wc -l)
    local close_parens=$(echo "$mermaid_code" | grep -o ')' | wc -l)
    
    if [[ $open_brackets -ne $close_brackets ]] || [[ $open_parens -ne $close_parens ]]; then
        return 1
    fi
    
    # Basic syntax passed
    return 0
}

load_team_directives_config() {
    local repo_root="$1"

    local config_file
    config_file=$(get_global_config_path)
    if [[ -f "$config_file" ]] && command -v jq >/dev/null 2>&1; then
        local path
        path=$(jq -r '.team_directives.path // empty' "$config_file" 2>/dev/null)
        if [[ -n "$path" && "$path" != "null" && -d "$path" ]]; then
            export SPECIFY_TEAM_DIRECTIVES="$path"
            return
        elif [[ -n "$path" && "$path" != "null" ]]; then
            echo "[specify] Warning: team directives path '$path' from $config_file is unavailable." >&2
        fi
    fi

    local default_dir="$repo_root/.specify/memory/$TEAM_DIRECTIVES_DIRNAME"
    if [[ -d "$default_dir" ]]; then
        export SPECIFY_TEAM_DIRECTIVES="$default_dir"
    fi
}

# Get repository root, with fallback for non-git repositories
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        # Fall back to script location for non-git repos
        local script_dir="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        (cd "$script_dir/../../.." && pwd)
    fi
}

# Get current branch, with fallback for non-git repositories
get_current_branch() {
    # First check if SPECIFY_FEATURE environment variable is set
    if [[ -n "${SPECIFY_FEATURE:-}" ]]; then
        echo "$SPECIFY_FEATURE"
        return
    fi

    # Then check git if available
    if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        git rev-parse --abbrev-ref HEAD
        return
    fi

    # For non-git repos, try to find the latest feature directory
    local repo_root=$(get_repo_root)
    local specs_dir="$repo_root/specs"

    if [[ -d "$specs_dir" ]]; then
        local latest_feature=""
        local highest=0

        for dir in "$specs_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dirname=$(basename "$dir")
                if [[ "$dirname" =~ ^([0-9]{3})- ]]; then
                    local number=${BASH_REMATCH[1]}
                    number=$((10#$number))
                    if [[ "$number" -gt "$highest" ]]; then
                        highest=$number
                        latest_feature=$dirname
                    fi
                fi
            fi
        done

        if [[ -n "$latest_feature" ]]; then
            echo "$latest_feature"
            return
        fi
    fi

    echo "main"  # Final fallback
}

# Check if we have git available
has_git() {
    git rev-parse --show-toplevel >/dev/null 2>&1
}

check_feature_branch() {
    local branch="$1"
    local has_git_repo="$2"

    # For non-git repos, we can't enforce branch naming but still provide output
    if [[ "$has_git_repo" != "true" ]]; then
        echo "[specify] Warning: Git repository not detected; skipped branch validation" >&2
        return 0
    fi

    if [[ ! "$branch" =~ ^[0-9]{3}- ]]; then
        echo "ERROR: Not on a feature branch. Current branch: $branch" >&2
        echo "Feature branches should be named like: 001-feature-name" >&2
        return 1
    fi

    return 0
}

get_feature_dir() { echo "$1/specs/$2"; }

# Find feature directory by numeric prefix instead of exact branch match
# This allows multiple branches to work on the same spec (e.g., 004-fix-bug, 004-add-feature)
find_feature_dir_by_prefix() {
    local repo_root="$1"
    local branch_name="$2"
    local specs_dir="$repo_root/specs"

    # Extract numeric prefix from branch (e.g., "004" from "004-whatever")
    if [[ ! "$branch_name" =~ ^([0-9]{3})- ]]; then
        # If branch doesn't have numeric prefix, fall back to exact match
        echo "$specs_dir/$branch_name"
        return
    fi

    local prefix="${BASH_REMATCH[1]}"

    # Search for directories in specs/ that start with this prefix
    local matches=()
    if [[ -d "$specs_dir" ]]; then
        for dir in "$specs_dir"/"$prefix"-*; do
            if [[ -d "$dir" ]]; then
                matches+=("$(basename "$dir")")
            fi
        done
    fi

    # Handle results
    if [[ ${#matches[@]} -eq 0 ]]; then
        # No match found - return the branch name path (will fail later with clear error)
        echo "$specs_dir/$branch_name"
    elif [[ ${#matches[@]} -eq 1 ]]; then
        # Exactly one match - perfect!
        echo "$specs_dir/${matches[0]}"
    else
        # Multiple matches - this shouldn't happen with proper naming convention
        echo "ERROR: Multiple spec directories found with prefix '$prefix': ${matches[*]}" >&2
        echo "Please ensure only one spec directory exists per numeric prefix." >&2
        echo "$specs_dir/$branch_name"  # Return something to avoid breaking the script
    fi
}

get_feature_paths() {
    local repo_root=$(get_repo_root)
    load_team_directives_config "$repo_root"
    local current_branch=$(get_current_branch)
    local has_git_repo="false"

    if has_git; then
        has_git_repo="true"
    fi

    # Use prefix-based lookup to support multiple branches per spec
    local feature_dir=$(find_feature_dir_by_prefix "$repo_root" "$current_branch")

    # Project-level governance documents
    local memory_dir="$repo_root/.specify/memory"
    local constitution_file="$memory_dir/constitution.md"
    local architecture_file="$memory_dir/architecture.md"
    
    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
HAS_GIT='$has_git_repo'
FEATURE_DIR='$feature_dir'
FEATURE_SPEC='$feature_dir/spec.md'
IMPL_PLAN='$feature_dir/plan.md'
TASKS='$feature_dir/tasks.md'
RESEARCH='$feature_dir/research.md'
DATA_MODEL='$feature_dir/data-model.md'
QUICKSTART='$feature_dir/quickstart.md'
CONTEXT='$feature_dir/context.md'
CONTRACTS_DIR='$feature_dir/contracts'
TEAM_DIRECTIVES='${SPECIFY_TEAM_DIRECTIVES:-}'
CONSTITUTION='$constitution_file'
ARCHITECTURE='$architecture_file'
EOF
}

check_file() { [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
check_dir() { [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"; }

# Extract constitution principles and constraints
# Returns JSON array of rules
extract_constitution_rules() {
    local constitution_file="$1"
    
    if [[ ! -f "$constitution_file" ]]; then
        echo "[]"
        return
    fi
    
    python3 - "$constitution_file" <<'PY'
import json
import sys
from pathlib import Path

constitution_file = Path(sys.argv[1])
rules = []

try:
    content = constitution_file.read_text()
    
    # Extract principles (lines starting with "- **Principle")
    for line in content.split('\n'):
        if line.strip().startswith('- **Principle') or line.strip().startswith('- **PRINCIPLE'):
            rules.append({
                'type': 'principle',
                'text': line.strip()
            })
        elif line.strip().startswith('- **Constraint') or line.strip().startswith('- **CONSTRAINT'):
            rules.append({
                'type': 'constraint',
                'text': line.strip()
            })
        elif line.strip().startswith('- **Pattern') or line.strip().startswith('- **PATTERN'):
            rules.append({
                'type': 'pattern',
                'text': line.strip()
            })
    
    print(json.dumps(rules, ensure_ascii=False))
except Exception as e:
    print('[]')
PY
}

# Extract architecture viewpoints from architecture.md
# Returns JSON with view names and component counts
extract_architecture_views() {
    local architecture_file="$1"
    
    if [[ ! -f "$architecture_file" ]]; then
        echo "{}"
        return
    fi
    
    python3 - "$architecture_file" <<'PY'
import json
import sys
from pathlib import Path
import re

architecture_file = Path(sys.argv[1])
views = {}

try:
    content = architecture_file.read_text()
    
    # Track which views are present
    view_patterns = {
        'context': r'###\s+3\.1\s+Context\s+View',
        'functional': r'###\s+3\.2\s+Functional\s+View',
        'information': r'###\s+3\.3\s+Information\s+View',
        'concurrency': r'###\s+3\.4\s+Concurrency\s+View',
        'development': r'###\s+3\.5\s+Development\s+View',
        'deployment': r'###\s+3\.6\s+Deployment\s+View',
        'operational': r'###\s+3\.7\s+Operational\s+View'
    }
    
    for view_name, pattern in view_patterns.items():
        if re.search(pattern, content, re.IGNORECASE):
            views[view_name] = {'present': True}
        else:
            views[view_name] = {'present': False}
    
    print(json.dumps(views, ensure_ascii=False))
except Exception as e:
    print('{}')
PY
}

# Extract diagram blocks from architecture.md
# Returns JSON array of diagrams with type and format
extract_architecture_diagrams() {
    local architecture_file="$1"
    
    if [[ ! -f "$architecture_file" ]]; then
        echo "[]"
        return
    fi
    
    python3 - "$architecture_file" <<'PY'
import json
import sys
from pathlib import Path
import re

architecture_file = Path(sys.argv[1])
diagrams = []

try:
    content = architecture_file.read_text()
    
    # Find all code blocks (mermaid or text)
    code_block_pattern = r'```(mermaid|text)\n(.*?)\n```'
    
    for match in re.finditer(code_block_pattern, content, re.DOTALL):
        diagram_format = match.group(1)
        diagram_content = match.group(2)
        
        # Try to determine which view this diagram belongs to by context
        start_pos = match.start()
        preceding_text = content[:start_pos]
        
        # Find the most recent view heading
        view_match = None
        for view_pattern in [
            r'###\s+3\.1\s+Context\s+View',
            r'###\s+3\.2\s+Functional\s+View',
            r'###\s+3\.3\s+Information\s+View',
            r'###\s+3\.4\s+Concurrency\s+View',
            r'###\s+3\.5\s+Development\s+View',
            r'###\s+3\.6\s+Deployment\s+View',
            r'###\s+3\.7\s+Operational\s+View'
        ]:
            matches = list(re.finditer(view_pattern, preceding_text, re.IGNORECASE))
            if matches:
                view_match = matches[-1].group()
                break
        
        view_name = 'unknown'
        if view_match:
            if 'Context' in view_match:
                view_name = 'context'
            elif 'Functional' in view_match:
                view_name = 'functional'
            elif 'Information' in view_match:
                view_name = 'information'
            elif 'Concurrency' in view_match:
                view_name = 'concurrency'
            elif 'Development' in view_match:
                view_name = 'development'
            elif 'Deployment' in view_match:
                view_name = 'deployment'
            elif 'Operational' in view_match:
                view_name = 'operational'
        
        diagrams.append({
            'view': view_name,
            'format': diagram_format,
            'line_count': len(diagram_content.split('\n'))
        })
    
    print(json.dumps(diagrams, ensure_ascii=False))
except Exception as e:
    print('[]')
PY
}

