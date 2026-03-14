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

# Get project-level config path (.specify/config.json)
get_project_config_path() {
    local repo_root=$(get_repo_root)
    echo "$repo_root/.specify/config.json"
}

# Get config path with hierarchical resolution
# Priority: 1) Project config  2) User config  3) Default to project
get_config_path() {
    local project_config=$(get_project_config_path)
    local user_config=$(get_global_config_path)
    
    if [[ -f "$project_config" ]]; then
        echo "$project_config"
    elif [[ -f "$user_config" ]]; then
        echo "$user_config"
    else
        # Default to project-level config
        echo "$project_config"
    fi
}

# Get architecture diagram format from config (mermaid or ascii)
# Defaults to "mermaid" if config doesn't exist or format is invalid
get_architecture_diagram_format() {
    local config_file
    config_file=$(get_config_path)
    
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
        return 1
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
    local feature_dir
    if ! feature_dir=$(find_feature_dir_by_prefix "$repo_root" "$current_branch"); then
        echo "ERROR: Failed to resolve feature directory" >&2
        return 1
    fi

    # Project-level governance documents
    local memory_dir="$repo_root/memory"
    local constitution_file="$memory_dir/constitution.md"
    # New architecture structure: AD.md at root, ADRs in memory/
    local ad_file="$repo_root/AD.md"
    local adr_file="$memory_dir/adr.md"

    # Use printf '%q' to safely quote values, preventing shell injection
    # via crafted branch names or paths containing special characters
    printf 'REPO_ROOT=%q\n' "$repo_root"
    printf 'CURRENT_BRANCH=%q\n' "$current_branch"
    printf 'HAS_GIT=%q\n' "$has_git_repo"
    printf 'FEATURE_DIR=%q\n' "$feature_dir"
    printf 'FEATURE_SPEC=%q\n' "$feature_dir/spec.md"
    printf 'IMPL_PLAN=%q\n' "$feature_dir/plan.md"
    printf 'TASKS=%q\n' "$feature_dir/tasks.md"
    printf 'RESEARCH=%q\n' "$feature_dir/research.md"
    printf 'DATA_MODEL=%q\n' "$feature_dir/data-model.md"
    printf 'QUICKSTART=%q\n' "$feature_dir/quickstart.md"
    printf 'CONTEXT=%q\n' "$feature_dir/context.md"
    printf 'CONTRACTS_DIR=%q\n' "$feature_dir/contracts"
    printf 'TEAM_DIRECTIVES=%q\n' "${SPECIFY_TEAM_DIRECTIVES:-}"
    printf 'CONSTITUTION=%q\n' "$constitution_file"
    printf 'AD=%q\n' "$ad_file"
    printf 'ADR=%q\n' "$adr_file"
}

# Check if jq is available for safe JSON construction
has_jq() {
    command -v jq >/dev/null 2>&1
}

# Escape a string for safe embedding in a JSON value (fallback when jq is unavailable).
# Handles backslash, double-quote, and control characters (newline, tab, carriage return).
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\r'/\\r}"
    printf '%s' "$s"
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
    print('[]')
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


# Resolve a template name to a file path using the priority stack:
#   1. .specify/templates/overrides/
#   2. .specify/presets/<preset-id>/templates/ (sorted by priority from .registry)
#   3. .specify/extensions/<ext-id>/templates/
#   4. .specify/templates/ (core)
resolve_template() {
    local template_name="$1"
    local repo_root="$2"
    local base="$repo_root/.specify/templates"

    # Priority 1: Project overrides
    local override="$base/overrides/${template_name}.md"
    [ -f "$override" ] && echo "$override" && return 0

    # Priority 2: Installed presets (sorted by priority from .registry)
    local presets_dir="$repo_root/.specify/presets"
    if [ -d "$presets_dir" ]; then
        local registry_file="$presets_dir/.registry"
        if [ -f "$registry_file" ] && command -v python3 >/dev/null 2>&1; then
            # Read preset IDs sorted by priority (lower number = higher precedence)
            local sorted_presets
            sorted_presets=$(SPECKIT_REGISTRY="$registry_file" python3 -c "
import json, sys, os
try:
    with open(os.environ['SPECKIT_REGISTRY']) as f:
        data = json.load(f)
    presets = data.get('presets', {})
    for pid, meta in sorted(presets.items(), key=lambda x: x[1].get('priority', 10)):
        print(pid)
except Exception:
    sys.exit(1)
" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$sorted_presets" ]; then
                while IFS= read -r preset_id; do
                    local candidate="$presets_dir/$preset_id/templates/${template_name}.md"
                    [ -f "$candidate" ] && echo "$candidate" && return 0
                done <<< "$sorted_presets"
            else
                # python3 returned empty list — fall through to directory scan
                for preset in "$presets_dir"/*/; do
                    [ -d "$preset" ] || continue
                    local candidate="$preset/templates/${template_name}.md"
                    [ -f "$candidate" ] && echo "$candidate" && return 0
                done
            fi
        else
            # Fallback: alphabetical directory order (no python3 available)
            for preset in "$presets_dir"/*/; do
                [ -d "$preset" ] || continue
                local candidate="$preset/templates/${template_name}.md"
                [ -f "$candidate" ] && echo "$candidate" && return 0
            done
        fi
    fi

    # Priority 3: Extension-provided templates
    local ext_dir="$repo_root/.specify/extensions"
    if [ -d "$ext_dir" ]; then
        for ext in "$ext_dir"/*/; do
            [ -d "$ext" ] || continue
            # Skip hidden directories (e.g. .backup, .cache)
            case "$(basename "$ext")" in .*) continue;; esac
            local candidate="$ext/templates/${template_name}.md"
            [ -f "$candidate" ] && echo "$candidate" && return 0
        done
    fi

    # Priority 4: Core templates
    local core="$base/${template_name}.md"
    [ -f "$core" ] && echo "$core" && return 0

    # Return success with empty output so callers using set -e don't abort;
    # callers check [ -n "$TEMPLATE" ] to detect "not found".
    return 0
}
