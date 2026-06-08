#!/usr/bin/env bash
# Git-specific common functions for the git extension.
# Extracted from scripts/bash/common.sh — contains only git-specific
# branch validation and detection logic.

# Find the project root by looking for .specify directory
find_specify_root() {
    local dir="${1:-$(pwd)}"
    # Normalize to absolute path to prevent infinite loop with relative paths
    # Use -- to handle paths starting with - (e.g., -P, -L)
    dir="$(cd -- "$dir" 2>/dev/null && pwd)" || return 1
    local prev_dir=""
    while true; do
        if [ -d "$dir/.specify" ]; then
            echo "$dir"
            return 0
        fi

        # Stop if we've reached filesystem root or dirname stops changing
        if [ "$dir" = "/" ] || [ "$dir" = "$prev_dir" ]; then
            break
        fi
        prev_dir="$dir"
        dir="$(dirname "$dir")"
    done
    return 1
}

# Get repository root, prioritizing .specify directory over git
# This prevents using a parent git repo when spec-kit is initialized in a subdirectory
get_repo_root() {
    # First, look for .specify directory (spec-kit's own marker)
    local specify_root
    if specify_root=$(find_specify_root); then
        echo "$specify_root"
        return
    fi

    # Fallback to git if no .specify found
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
        return
    fi

    # Final fallback to script location for non-git repos
    local script_dir="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    (cd "$script_dir/../../.." && pwd)
}

# Check if we have git available at the repo root
has_git() {
    local repo_root="${1:-$(pwd)}"
    { [ -d "$repo_root/.git" ] || [ -f "$repo_root/.git" ]; } && \
        command -v git >/dev/null 2>&1 && \
        git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

spec_kit_branch_pattern_config_path() {
    local repo_root="${1:-$(get_repo_root)}"
    printf '%s\n' "$repo_root/.specify/extensions/git/git-config.yml"
}

spec_kit_branch_pattern_get_scalar() {
    local repo_root="$1"
    local key_path="$2"
    local cfg
    cfg="$(spec_kit_branch_pattern_config_path "$repo_root")"
    [ -f "$cfg" ] || return 1

    if command -v python3 >/dev/null 2>&1; then
        local value
        value=$(python3 - "$cfg" "$key_path" <<'PY' 2>/dev/null || true
import sys

path, key_path = sys.argv[1], sys.argv[2].split('.')
try:
    import yaml
except Exception:
    sys.exit(0)

try:
    with open(path, encoding='utf-8') as fh:
        data = yaml.safe_load(fh) or {}
    cur = data
    for key in key_path:
        if not isinstance(cur, dict) or key not in cur:
            cur = None
            break
        cur = cur[key]
    if cur is None or isinstance(cur, (dict, list)):
        sys.exit(0)
    if isinstance(cur, bool):
        print('true' if cur else 'false')
    else:
        print(str(cur))
except Exception:
    sys.exit(0)
PY
)
        if [ -n "$value" ]; then
            printf '%s\n' "$value"
            return 0
        fi
    fi

    case "$key_path" in
        branch_pattern.enabled)
            grep -E '^[[:space:]]*enabled[[:space:]]*:' "$cfg" 2>/dev/null | tail -1 | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*#.*//; s/[[:space:]]+$//'
            ;;
        branch_pattern.template)
            grep -E '^[[:space:]]*template[[:space:]]*:' "$cfg" 2>/dev/null | tail -1 | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*#.*//; s/^['"'"']|['"'"']$//g; s/[[:space:]]+$//'
            ;;
        branch_pattern.number_padding)
            grep -E '^[[:space:]]*number_padding[[:space:]]*:' "$cfg" 2>/dev/null | tail -1 | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*#.*//; s/[[:space:]]+$//'
            ;;
        branch_pattern.issue_format)
            grep -E '^[[:space:]]*issue_format[[:space:]]*:' "$cfg" 2>/dev/null | tail -1 | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*#.*//; s/^['"'"']|['"'"']$//g; s/[[:space:]]+$//'
            ;;
        *)
            return 1
            ;;
    esac
}

spec_kit_branch_pattern_allowed_prefixes() {
    local repo_root="$1"
    local cfg
    cfg="$(spec_kit_branch_pattern_config_path "$repo_root")"
    [ -f "$cfg" ] || return 1

    if command -v python3 >/dev/null 2>&1; then
        local values
        values=$(python3 - "$cfg" <<'PY' 2>/dev/null || true
import sys
try:
    import yaml
except Exception:
    sys.exit(0)

try:
    with open(sys.argv[1], encoding='utf-8') as fh:
        data = yaml.safe_load(fh) or {}
    vals = (((data or {}).get('branch_pattern') or {}).get('allowed_prefixes') or [])
    if isinstance(vals, list):
        for item in vals:
            if item is not None:
                print(str(item))
except Exception:
    sys.exit(0)
PY
)
        if [ -n "$values" ]; then
            printf '%s\n' "$values"
            return 0
        fi
    fi

    python3 - "$cfg" <<'PY' 2>/dev/null || true
import re
import sys

path = sys.argv[1]
in_branch_pattern = False
in_allowed_prefixes = False

with open(path, encoding='utf-8') as fh:
    for raw_line in fh:
        line = raw_line.rstrip('\n')
        if re.match(r'^\S', line):
            in_branch_pattern = False
            in_allowed_prefixes = False
        if re.match(r'^\s*branch_pattern\s*:', line):
            in_branch_pattern = True
            continue
        if not in_branch_pattern:
            continue
        if re.match(r'^\s*allowed_prefixes\s*:', line):
            in_allowed_prefixes = True
            continue
        if in_allowed_prefixes:
            match = re.match(r'^\s*-\s*(.+?)\s*(#.*)?$', line)
            if match:
                value = match.group(1).strip().strip('"\'')
                if value:
                    print(value)
                continue
            if re.match(r'^\s*[A-Za-z_]+\s*:', line):
                in_allowed_prefixes = False
PY
}

spec_kit_branch_pattern_enabled() {
    local repo_root="${1:-$(get_repo_root)}"
    local enabled
    enabled="$(spec_kit_branch_pattern_get_scalar "$repo_root" branch_pattern.enabled 2>/dev/null || true)"
    [[ "$enabled" == "true" || "$enabled" == "True" || "$enabled" == "yes" || "$enabled" == "1" ]]
}

spec_kit_issue_key_regex() {
    printf '%s\n' '^[A-Z][A-Z0-9]+-[0-9]+$'
}

spec_kit_normalize_issue_key() {
    local issue="$1"
    printf '%s\n' "$issue" | tr '[:lower:]' '[:upper:]'
}

spec_kit_validate_issue_key() {
    local issue="$1"
    [[ "$issue" =~ $(spec_kit_issue_key_regex) ]]
}

spec_kit_branch_pattern_validation_message() {
    local repo_root="${1:-$(get_repo_root)}"
    local template
    template="$(spec_kit_branch_pattern_get_scalar "$repo_root" branch_pattern.template 2>/dev/null || true)"
    if [ -n "$template" ]; then
        printf 'Feature branches should match configured template: %s\n' "$template"
    else
        printf 'Feature branches should be named like: 001-feature-name, 1234-feature-name, or 20260319-143022-feature-name\n'
    fi
}

spec_kit_extract_feature_identity() {
    local branch_name="$1"
    if [[ "$branch_name" =~ ^([0-9]{8}-[0-9]{6})- ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "$branch_name" =~ ^([0-9]{3,})- ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "$branch_name" =~ /([0-9]{8}-[0-9]{6})- ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "$branch_name" =~ /([0-9]{3,})- ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

spec_kit_branch_matches_configured_pattern() {
    local raw="$1"
    local repo_root="${2:-$(get_repo_root)}"
    local branch template has_prefix has_issue issue_key prefix identity rest prefixes_found=false

    branch="$(spec_kit_effective_branch_name "$raw")"
    template="$(spec_kit_branch_pattern_get_scalar "$repo_root" branch_pattern.template 2>/dev/null || true)"
    [ -n "$template" ] || return 1

    has_prefix=false
    has_issue=false
    [[ "$template" == *"{prefix}"* ]] && has_prefix=true
    [[ "$template" == *"{issue}"* ]] && has_issue=true

    if [ "$has_prefix" = true ]; then
        local prefix_line
        while IFS= read -r prefix_line; do
            [ -n "$prefix_line" ] || continue
            prefixes_found=true
            if [[ "$raw" == "$prefix_line/"* ]]; then
                prefix="$prefix_line"
                break
            fi
        done < <(spec_kit_branch_pattern_allowed_prefixes "$repo_root" 2>/dev/null || true)
        [ "$prefixes_found" = true ] || return 1
        [ -n "$prefix" ] || return 1
    fi

    identity="$(spec_kit_extract_feature_identity "$raw" 2>/dev/null || true)"
    [ -n "$identity" ] || return 1

    if [[ "$branch" == "$identity"-* ]]; then
        rest="${branch#${identity}-}"
    else
        return 1
    fi

    if [ "$has_issue" = true ]; then
        if [[ "$rest" =~ ^([A-Z][A-Z0-9]+-[0-9]+)-(.+)$ ]]; then
            issue_key="${BASH_REMATCH[1]}"
            rest="${BASH_REMATCH[2]}"
        else
            return 1
        fi
        spec_kit_validate_issue_key "$issue_key" || return 1
        [ -n "$rest" ] || return 1
    fi

    [[ "$rest" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]
}

# Strip a single optional path segment (e.g. gitflow "feat/004-name" -> "004-name").
# Only when the full name is exactly two slash-free segments; otherwise returns the raw name.
spec_kit_effective_branch_name() {
    local raw="$1"
    if [[ "$raw" =~ ^([^/]+)/([^/]+)$ ]]; then
        printf '%s\n' "${BASH_REMATCH[2]}"
    else
        printf '%s\n' "$raw"
    fi
}

# Validate that a branch name matches the expected feature branch pattern.
# Accepts sequential (###-* with >=3 digits) or timestamp (YYYYMMDD-HHMMSS-*) formats.
# Logic aligned with scripts/bash/common.sh check_feature_branch after effective-name normalization.
check_feature_branch() {
    local raw="$1"
    local has_git_repo="$2"

    # For non-git repos, we can't enforce branch naming but still provide output
    if [[ "$has_git_repo" != "true" ]]; then
        echo "[specify] Warning: Git repository not detected; skipped branch validation" >&2
        return 0
    fi

    local branch
    branch=$(spec_kit_effective_branch_name "$raw")

    local repo_root
    repo_root="$(get_repo_root 2>/dev/null || pwd)"
    if spec_kit_branch_pattern_enabled "$repo_root"; then
        if spec_kit_branch_matches_configured_pattern "$raw" "$repo_root"; then
            return 0
        fi
        echo "ERROR: Not on a feature branch. Current branch: $raw" >&2
        spec_kit_branch_pattern_validation_message "$repo_root" >&2
        return 1
    fi

    # Accept sequential prefix (3+ digits) but exclude malformed timestamps
    # Malformed: 7-or-8 digit date + 6-digit time with no trailing slug (e.g. "2026031-143022" or "20260319-143022")
    local is_sequential=false
    if [[ "$branch" =~ ^[0-9]{3,}- ]] && [[ ! "$branch" =~ ^[0-9]{7}-[0-9]{6}- ]] && [[ ! "$branch" =~ ^[0-9]{7,8}-[0-9]{6}$ ]]; then
        is_sequential=true
    fi
    if [[ "$is_sequential" != "true" ]] && [[ ! "$branch" =~ ^[0-9]{8}-[0-9]{6}- ]]; then
        echo "ERROR: Not on a feature branch. Current branch: $raw" >&2
        echo "Feature branches should be named like: 001-feature-name, 1234-feature-name, or 20260319-143022-feature-name" >&2
        return 1
    fi

    return 0
}
