#!/usr/bin/env bash
# Git extension: create-new-feature.sh
# Adapted from core scripts/bash/create-new-feature.sh for extension layout.
# Sources common.sh from the project's installed scripts, falling back to
# git-common.sh for minimal git helpers.

set -e

JSON_MODE=false
DRY_RUN=false
ALLOW_EXISTING=false
SHORT_NAME=""
BRANCH_NUMBER=""
USE_TIMESTAMP=false
ISSUE_KEY=""
ISOLATION_MODE=""
WORKTREE_FLAG=false
BRANCH_MODE_FLAG=false
BASE_BRANCH=""
ARGS=()
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --allow-existing-branch)
            ALLOW_EXISTING=true
            ;;
        --short-name)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --short-name requires a value' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --short-name requires a value' >&2
                exit 1
            fi
            SHORT_NAME="$next_arg"
            ;;
        --number)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --number requires a value' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --number requires a value' >&2
                exit 1
            fi
            BRANCH_NUMBER="$next_arg"
            if [[ ! "$BRANCH_NUMBER" =~ ^[0-9]+$ ]]; then
                echo 'Error: --number must be a non-negative integer' >&2
                exit 1
            fi
            ;;
        --timestamp)
            USE_TIMESTAMP=true
            ;;
        --issue)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --issue requires a value' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --issue requires a value' >&2
                exit 1
            fi
            ISSUE_KEY="$next_arg"
            ;;
        --worktree)
            WORKTREE_FLAG=true
            ;;
        --branch-mode)
            BRANCH_MODE_FLAG=true
            ;;
        --isolation-mode)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --isolation-mode requires a value (branch|worktree)' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --isolation-mode requires a value (branch|worktree)' >&2
                exit 1
            fi
            ISOLATION_MODE="$next_arg"
            case "$ISOLATION_MODE" in
                branch|worktree) ;;
                *) echo "Error: --isolation-mode must be 'branch' or 'worktree' (got: $ISOLATION_MODE)" >&2; exit 1 ;;
            esac
            ;;
        --base)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --base requires a value' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --base requires a value' >&2
                exit 1
            fi
            BASE_BRANCH="$next_arg"
            ;;
        --help|-h)
            echo "Usage: $0 [--json] [--dry-run] [--allow-existing-branch] [--short-name <name>] [--number N] [--timestamp] [--issue <JIRA-123>] [--worktree|--branch-mode|--isolation-mode <mode>] [--base <branch>] <feature_description>"
            echo ""
            echo "Options:"
            echo "  --json              Output in JSON format"
            echo "  --dry-run           Compute branch name without creating the branch"
            echo "  --allow-existing-branch  Switch to branch if it already exists instead of failing"
            echo "  --short-name <name> Provide a custom short name (2-4 words) for the branch"
            echo "  --number N          Specify branch number manually (overrides auto-detection)"
            echo "  --timestamp         Use timestamp prefix (YYYYMMDD-HHMMSS) instead of sequential numbering"
            echo "  --issue <JIRA-123>  Jira-style issue key used by branch_pattern templates"
            echo "  --worktree         Shortcut for --isolation-mode worktree (creates a git worktree)"
            echo "  --branch-mode      Shortcut for --isolation-mode branch (default; checkout -b in primary)"
            echo "  --isolation-mode <branch|worktree>  Override the configured isolation mode"
            echo "  --base <branch>    Base branch for worktree (defaults to current branch)"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  GIT_BRANCH_NAME     Use this exact branch name, bypassing all prefix/suffix generation"
            echo "  GIT_BRANCH_ISSUE    Jira-style issue key used by branch_pattern templates"
            echo "  SPECIFY_ISOLATION_MODE  Override the isolation mode (branch|worktree)"
            echo ""
            echo "Examples:"
            echo "  $0 'Add user authentication system' --short-name 'user-auth'"
            echo "  $0 'Implement OAuth2 integration for API' --number 5"
            echo "  $0 --timestamp --short-name 'user-auth' 'Add user authentication'"
            echo "  $0 --worktree 'Add user authentication system' --short-name 'user-auth'"
            echo "  GIT_BRANCH_NAME=my-branch $0 'feature description'"
            exit 0
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
    i=$((i + 1))
done

FEATURE_DESCRIPTION="${ARGS[*]}"
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Usage: $0 [--json] [--dry-run] [--allow-existing-branch] [--short-name <name>] [--number N] [--timestamp] [--issue <JIRA-123>] <feature_description>" >&2
    exit 1
fi

# Trim whitespace and validate description is not empty
FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Error: Feature description cannot be empty or contain only whitespace" >&2
    exit 1
fi

# Function to get highest number from specs directory
get_highest_from_specs() {
    local specs_dir="$1"
    local highest=0

    if [ -d "$specs_dir" ]; then
        for dir in "$specs_dir"/*; do
            [ -d "$dir" ] || continue
            dirname=$(basename "$dir")
            # Match sequential prefixes (>=3 digits), but skip timestamp dirs.
            if echo "$dirname" | grep -Eq '^[0-9]{3,}-' && ! echo "$dirname" | grep -Eq '^[0-9]{8}-[0-9]{6}-'; then
                number=$(echo "$dirname" | grep -Eo '^[0-9]+')
                number=$((10#$number))
                if [ "$number" -gt "$highest" ]; then
                    highest=$number
                fi
            fi
        done
    fi

    echo "$highest"
}

# Function to get highest number from git branches
get_highest_from_branches() {
    git branch -a 2>/dev/null | sed 's/^[* ]*//; s|^remotes/[^/]*/||' | _extract_highest_number
}

# Extract the highest sequential feature number from a list of ref names (one per line).
_extract_highest_number() {
    local highest=0
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        if echo "$name" | grep -Eq '^[0-9]{3,}-' && ! echo "$name" | grep -Eq '^[0-9]{8}-[0-9]{6}-'; then
            number=$(echo "$name" | grep -Eo '^[0-9]+' || echo "0")
            number=$((10#$number))
            if [ "$number" -gt "$highest" ]; then
                highest=$number
            fi
        fi
    done
    echo "$highest"
}

# Function to get highest number from remote branches without fetching (side-effect-free)
get_highest_from_remote_refs() {
    local highest=0

    for remote in $(git remote 2>/dev/null); do
        local remote_highest
        remote_highest=$(GIT_TERMINAL_PROMPT=0 git ls-remote --heads "$remote" 2>/dev/null | sed 's|.*refs/heads/||' | _extract_highest_number)
        if [ "$remote_highest" -gt "$highest" ]; then
            highest=$remote_highest
        fi
    done

    echo "$highest"
}

# Function to check existing branches and return next available number.
check_existing_branches() {
    local specs_dir="$1"
    local skip_fetch="${2:-false}"

    if [ "$skip_fetch" = true ]; then
        local highest_remote=$(get_highest_from_remote_refs)
        local highest_branch=$(get_highest_from_branches)
        if [ "$highest_remote" -gt "$highest_branch" ]; then
            highest_branch=$highest_remote
        fi
    else
        git fetch --all --prune >/dev/null 2>&1 || true
        local highest_branch=$(get_highest_from_branches)
    fi

    local highest_spec=$(get_highest_from_specs "$specs_dir")

    local max_num=$highest_branch
    if [ "$highest_spec" -gt "$max_num" ]; then
        max_num=$highest_spec
    fi

    echo $((max_num + 1))
}

# Function to clean and format a branch name
clean_branch_name() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//'
}

# ---------------------------------------------------------------------------
# Source common.sh for resolve_template, json_escape, get_repo_root, has_git.
#
# Search locations in priority order:
#  1. .specify/scripts/bash/common.sh under the project root (installed project)
#  2. scripts/bash/common.sh under the project root (source checkout fallback)
#  3. git-common.sh next to this script (minimal fallback — lacks resolve_template)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find project root by walking up from the script location
_find_project_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.specify" ] || [ -d "$dir/.git" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

_common_loaded=false
_PROJECT_ROOT=$(_find_project_root "$SCRIPT_DIR") || true

if [ -n "$_PROJECT_ROOT" ] && [ -f "$_PROJECT_ROOT/.specify/scripts/bash/common.sh" ]; then
    source "$_PROJECT_ROOT/.specify/scripts/bash/common.sh"
    _common_loaded=true
elif [ -n "$_PROJECT_ROOT" ] && [ -f "$_PROJECT_ROOT/scripts/bash/common.sh" ]; then
    source "$_PROJECT_ROOT/scripts/bash/common.sh"
    _common_loaded=true
elif [ -f "$SCRIPT_DIR/git-common.sh" ]; then
    source "$SCRIPT_DIR/git-common.sh"
    _common_loaded=true
fi

if [ "$_common_loaded" != "true" ]; then
    echo "Error: Could not locate common.sh or git-common.sh. Please ensure the Specify core scripts are installed." >&2
    exit 1
fi

# Resolve repository root
if type get_repo_root >/dev/null 2>&1; then
    REPO_ROOT=$(get_repo_root)
elif git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
elif [ -n "$_PROJECT_ROOT" ]; then
    REPO_ROOT="$_PROJECT_ROOT"
else
    echo "Error: Could not determine repository root." >&2
    exit 1
fi

# Check if git is available at this repo root
if type has_git >/dev/null 2>&1; then
    if has_git "$REPO_ROOT"; then
        HAS_GIT=true
    else
        HAS_GIT=false
    fi
elif git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    HAS_GIT=true
else
    HAS_GIT=false
fi

cd "$REPO_ROOT"

SPECS_DIR="$REPO_ROOT/specs"

# Function to generate branch name with stop word filtering
generate_branch_name() {
    local description="$1"

    local stop_words="^(i|a|an|the|to|for|of|in|on|at|by|with|from|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|should|could|can|may|might|must|shall|this|that|these|those|my|your|our|their|want|need|add|get|set)$"

    local clean_name=$(echo "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g')

    local meaningful_words=()
    for word in $clean_name; do
        [ -z "$word" ] && continue
        if ! echo "$word" | grep -qiE "$stop_words"; then
            if [ ${#word} -ge 3 ]; then
                meaningful_words+=("$word")
            elif echo "$description" | grep -qw -- "${word^^}"; then
                meaningful_words+=("$word")
            fi
        fi
    done

    if [ ${#meaningful_words[@]} -gt 0 ]; then
        local max_words=3
        if [ ${#meaningful_words[@]} -eq 4 ]; then max_words=4; fi

        local result=""
        local count=0
        for word in "${meaningful_words[@]}"; do
            if [ $count -ge $max_words ]; then break; fi
            if [ -n "$result" ]; then result="$result-"; fi
            result="$result$word"
            count=$((count + 1))
        done
        echo "$result"
    else
        local cleaned=$(clean_branch_name "$description")
        echo "$cleaned" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//'
    fi
}

spec_kit_branch_pattern_template_is_valid() {
    local template="$1"
    [ -n "$template" ] || return 1
    [[ "$template" == *"{slug}"* ]] || return 1

    local number_count=0
    local timestamp_count=0
    [[ "$template" == *"{number}"* ]] && number_count=1
    [[ "$template" == *"{timestamp}"* ]] && timestamp_count=1
    [ $((number_count + timestamp_count)) -eq 1 ] || return 1
    return 0
}

spec_kit_branch_pattern_render() {
    local template="$1"
    local prefix="$2"
    local number="$3"
    local timestamp="$4"
    local issue="$5"
    local slug="$6"
    local result="$template"

    result="${result//\{prefix\}/$prefix}"
    result="${result//\{number\}/$number}"
    result="${result//\{timestamp\}/$timestamp}"
    result="${result//\{issue\}/$issue}"
    result="${result//\{slug\}/$slug}"
    printf '%s\n' "$result"
}

spec_kit_branch_pattern_first_prefix() {
    local repo_root="$1"
    while IFS= read -r prefix; do
        [ -n "$prefix" ] || continue
        printf '%s\n' "$prefix"
        return 0
    done < <(spec_kit_branch_pattern_allowed_prefixes "$repo_root" 2>/dev/null || true)
    return 1
}

spec_kit_branch_pattern_apply() {
    local repo_root="$1"
    local branch_suffix="$2"
    local feature_num="$3"
    local use_timestamp="$4"
    local issue_key="$5"

    local template number_padding prefix issue normalized_issue rendered
    template="$(spec_kit_branch_pattern_get_scalar "$repo_root" branch_pattern.template 2>/dev/null || true)"
    spec_kit_branch_pattern_template_is_valid "$template" || {
        echo "Error: Invalid branch_pattern.template. It must include {slug} and exactly one of {number} or {timestamp}." >&2
        return 1
    }

    if [[ "$template" == *"{prefix}"* ]]; then
        prefix="$(spec_kit_branch_pattern_first_prefix "$repo_root" 2>/dev/null || true)"
        if [ -z "$prefix" ]; then
            echo "Error: branch_pattern.template uses {prefix}, but branch_pattern.allowed_prefixes is empty." >&2
            return 1
        fi
    fi

    if [[ "$template" == *"{issue}"* ]]; then
        issue="$issue_key"
        [ -z "$issue" ] && issue="${GIT_BRANCH_ISSUE:-}"
        issue="$(spec_kit_normalize_issue_key "$issue")"
        if [ -z "$issue" ]; then
            echo "Error: branch_pattern.template uses {issue}; provide --issue or GIT_BRANCH_ISSUE." >&2
            return 1
        fi
        if ! spec_kit_validate_issue_key "$issue"; then
            echo "Error: Invalid Jira issue key '$issue'. Expected format like PROJ-123." >&2
            return 1
        fi
        normalized_issue="$issue"
    fi

    if [[ "$template" == *"{number}"* ]]; then
        number_padding="$(spec_kit_branch_pattern_get_scalar "$repo_root" branch_pattern.number_padding 2>/dev/null || true)"
        [[ "$number_padding" =~ ^[0-9]+$ ]] || number_padding=3
        rendered="$(spec_kit_branch_pattern_render "$template" "$prefix" "$(printf "%0${number_padding}d" "$((10#$feature_num))")" "" "$normalized_issue" "$branch_suffix")"
    else
        if [ "$use_timestamp" != true ]; then
            echo "Error: branch_pattern.template requires {timestamp}; rerun with --timestamp or change the template." >&2
            return 1
        fi
        rendered="$(spec_kit_branch_pattern_render "$template" "$prefix" "" "$feature_num" "$normalized_issue" "$branch_suffix")"
    fi

    printf '%s\n' "$rendered"
}

# Check for GIT_BRANCH_NAME env var override (exact branch name, no prefix/suffix)
if [ -n "${GIT_BRANCH_NAME:-}" ]; then
    BRANCH_NAME="$GIT_BRANCH_NAME"
    # Extract FEATURE_NUM from the branch name if it starts with a numeric prefix
    # Check timestamp pattern first (YYYYMMDD-HHMMSS-) since it also matches the simpler ^[0-9]+ pattern
    if echo "$BRANCH_NAME" | grep -Eq '^[0-9]{8}-[0-9]{6}-'; then
        FEATURE_NUM=$(echo "$BRANCH_NAME" | grep -Eo '^[0-9]{8}-[0-9]{6}')
        BRANCH_SUFFIX="${BRANCH_NAME#${FEATURE_NUM}-}"
    elif echo "$BRANCH_NAME" | grep -Eq '^[0-9]+-'; then
        FEATURE_NUM=$(echo "$BRANCH_NAME" | grep -Eo '^[0-9]+')
        BRANCH_SUFFIX="${BRANCH_NAME#${FEATURE_NUM}-}"
    else
        FEATURE_NUM="$BRANCH_NAME"
        BRANCH_SUFFIX="$BRANCH_NAME"
    fi
else
    # Generate branch name
    if [ -n "$SHORT_NAME" ]; then
        BRANCH_SUFFIX=$(clean_branch_name "$SHORT_NAME")
    else
        BRANCH_SUFFIX=$(generate_branch_name "$FEATURE_DESCRIPTION")
    fi

    # Warn if --number and --timestamp are both specified
    if [ "$USE_TIMESTAMP" = true ] && [ -n "$BRANCH_NUMBER" ]; then
        >&2 echo "[specify] Warning: --number is ignored when --timestamp is used"
        BRANCH_NUMBER=""
    fi

    # Determine branch prefix
    if [ "$USE_TIMESTAMP" = true ]; then
        FEATURE_NUM=$(date +%Y%m%d-%H%M%S)
    else
        if [ -z "$BRANCH_NUMBER" ]; then
            if [ "$DRY_RUN" = true ] && [ "$HAS_GIT" = true ]; then
                BRANCH_NUMBER=$(check_existing_branches "$SPECS_DIR" true)
            elif [ "$DRY_RUN" = true ]; then
                HIGHEST=$(get_highest_from_specs "$SPECS_DIR")
                BRANCH_NUMBER=$((HIGHEST + 1))
            elif [ "$HAS_GIT" = true ]; then
                BRANCH_NUMBER=$(check_existing_branches "$SPECS_DIR")
            else
                HIGHEST=$(get_highest_from_specs "$SPECS_DIR")
                BRANCH_NUMBER=$((HIGHEST + 1))
            fi
        fi

        FEATURE_NUM=$(printf "%03d" "$((10#$BRANCH_NUMBER))")
    fi

    if spec_kit_branch_pattern_enabled "$REPO_ROOT"; then
        BRANCH_NAME="$(spec_kit_branch_pattern_apply "$REPO_ROOT" "$BRANCH_SUFFIX" "$FEATURE_NUM" "$USE_TIMESTAMP" "$ISSUE_KEY")" || exit 1
    elif [ "$USE_TIMESTAMP" = true ]; then
        BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"
    else
        BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"
    fi
fi

# GitHub enforces a 244-byte limit on branch names
MAX_BRANCH_LENGTH=244
_byte_length() { printf '%s' "$1" | LC_ALL=C wc -c | tr -d ' '; }
BRANCH_BYTE_LEN=$(_byte_length "$BRANCH_NAME")
if [ -n "${GIT_BRANCH_NAME:-}" ] && [ "$BRANCH_BYTE_LEN" -gt $MAX_BRANCH_LENGTH ]; then
    >&2 echo "Error: GIT_BRANCH_NAME must be 244 bytes or fewer in UTF-8. Provided value is ${BRANCH_BYTE_LEN} bytes."
    exit 1
elif [ "$BRANCH_BYTE_LEN" -gt $MAX_BRANCH_LENGTH ]; then
    PREFIX_LENGTH=$(( ${#FEATURE_NUM} + 1 ))
    MAX_SUFFIX_LENGTH=$((MAX_BRANCH_LENGTH - PREFIX_LENGTH))

    TRUNCATED_SUFFIX=$(echo "$BRANCH_SUFFIX" | cut -c1-$MAX_SUFFIX_LENGTH)
    TRUNCATED_SUFFIX=$(echo "$TRUNCATED_SUFFIX" | sed 's/-$//')

    ORIGINAL_BRANCH_NAME="$BRANCH_NAME"
    BRANCH_NAME="${FEATURE_NUM}-${TRUNCATED_SUFFIX}"

    >&2 echo "[specify] Warning: Branch name exceeded GitHub's 244-byte limit"
    >&2 echo "[specify] Original: $ORIGINAL_BRANCH_NAME (${#ORIGINAL_BRANCH_NAME} bytes)"
    >&2 echo "[specify] Truncated to: $BRANCH_NAME (${#BRANCH_NAME} bytes)"
fi

# ---------------------------------------------------------------------------
# Resolve isolation mode (branch vs worktree).
#
# Precedence:
#   1. --worktree / --branch-mode (boolean shortcuts)
#   2. --isolation-mode <mode>
#   3. SPECIFY_ISOLATION_MODE env var
#   4. .specify/extensions/git/git-config.yml `isolation_mode:` key
#   5. Default: branch
# ---------------------------------------------------------------------------
_resolve_isolation_mode() {
    if [ "$WORKTREE_FLAG" = true ]; then
        echo "worktree"; return
    fi
    if [ "$BRANCH_MODE_FLAG" = true ]; then
        echo "branch"; return
    fi
    if [ -n "$ISOLATION_MODE" ]; then
        echo "$ISOLATION_MODE"; return
    fi
    if [ -n "${SPECIFY_ISOLATION_MODE:-}" ]; then
        case "${SPECIFY_ISOLATION_MODE}" in
            branch|worktree) echo "$SPECIFY_ISOLATION_MODE"; return ;;
        esac
    fi
    local cfg="$REPO_ROOT/.specify/extensions/git/git-config.yml"
    if [ -f "$cfg" ]; then
        local val
        val="$(grep -E '^[[:space:]]*isolation_mode[[:space:]]*:' "$cfg" 2>/dev/null | tail -1 | sed -E 's/^[[:space:]]*isolation_mode[[:space:]]*:[[:space:]]*//; s/[[:space:]]*#.*//; s/["'"'"']//g' || true)"
        case "$val" in
            branch|worktree) echo "$val"; return ;;
        esac
    fi
    echo "branch"
}

ISOLATION_MODE="$(_resolve_isolation_mode)"

# ---------------------------------------------------------------------------
# Worktree mode: delegate to worktree-utils.sh instead of git checkout -b.
# The agent is expected to cd into the worktree path before working.
# ---------------------------------------------------------------------------
WORKTREE_UTILS="$SCRIPT_DIR/worktree-utils.sh"

if [ "$ISOLATION_MODE" = "worktree" ] && [ "$DRY_RUN" != true ]; then
    if [ "$HAS_GIT" != true ]; then
        >&2 echo "Error: worktree mode requires a git repository."
        exit 1
    fi
    if [ ! -x "$WORKTREE_UTILS" ] && [ ! -f "$WORKTREE_UTILS" ]; then
        >&2 echo "Error: worktree-utils.sh not found at $WORKTREE_UTILS (required for --worktree mode)"
        exit 1
    fi

    wt_args=(create-feature-worktree --feature "$BRANCH_NAME")
    if [ -n "$BASE_BRANCH" ]; then
        wt_args+=(--base "$BASE_BRANCH")
    fi

    set +e
    wt_out="$(bash "$WORKTREE_UTILS" "${wt_args[@]}" 2>/dev/null)"
    wt_rc=$?
    set -e
    if [ "$wt_rc" -ne 0 ]; then
        # Re-emit stderr from the delegation for context.
        bash "$WORKTREE_UTILS" "${wt_args[@]}" >&2 || true
        exit "$wt_rc"
    fi

    WORKTREE_PATH="$(echo "$wt_out" | sed -n 's/.*"worktree_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    MANIFEST_PATH="$(echo "$wt_out" | sed -n 's/.*"manifest_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"

    if $JSON_MODE; then
        if command -v jq >/dev/null 2>&1; then
            jq -cn \
                --arg branch_name "$BRANCH_NAME" \
                --arg feature_num "$FEATURE_NUM" \
                --arg mode "worktree" \
                --arg wt_path "${WORKTREE_PATH:-}" \
                --arg mf_path "${MANIFEST_PATH:-}" \
                '{BRANCH_NAME:$branch_name, FEATURE_NUM:$feature_num, ISOLATION_MODE:$mode, WORKTREE_PATH:$wt_path, MANIFEST_PATH:$mf_path}'
        else
            printf '{"BRANCH_NAME":"%s","FEATURE_NUM":"%s","ISOLATION_MODE":"worktree","WORKTREE_PATH":"%s","MANIFEST_PATH":"%s"}\n' \
                "$BRANCH_NAME" "$FEATURE_NUM" "${WORKTREE_PATH:-}" "${MANIFEST_PATH:-}"
        fi
    else
        echo "BRANCH_NAME: $BRANCH_NAME"
        echo "FEATURE_NUM: $FEATURE_NUM"
        echo "ISOLATION_MODE: worktree"
        echo "WORKTREE_PATH: ${WORKTREE_PATH:-}"
        echo "MANIFEST_PATH: ${MANIFEST_PATH:-}"
        printf '# To persist: export SPECIFY_FEATURE=%q\n' "$BRANCH_NAME" >&2
        printf '# To work in the worktree: cd %s\n' "${WORKTREE_PATH:-}" >&2
    fi
    exit 0
fi

# ---------------------------------------------------------------------------
# Branch mode (default): existing behavior — git checkout -b in primary.
# ---------------------------------------------------------------------------

if [ "$DRY_RUN" != true ]; then
    if [ "$HAS_GIT" = true ]; then
        branch_create_error=""
        if ! branch_create_error=$(git checkout -q -b "$BRANCH_NAME" 2>&1); then
            current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
            if git branch --list "$BRANCH_NAME" | grep -q .; then
                if [ "$ALLOW_EXISTING" = true ]; then
                    if [ "$current_branch" = "$BRANCH_NAME" ]; then
                        :
                    elif ! switch_branch_error=$(git checkout -q "$BRANCH_NAME" 2>&1); then
                        >&2 echo "Error: Failed to switch to existing branch '$BRANCH_NAME'. Please resolve any local changes or conflicts and try again."
                        if [ -n "$switch_branch_error" ]; then
                            >&2 printf '%s\n' "$switch_branch_error"
                        fi
                        exit 1
                    fi
                elif [ "$USE_TIMESTAMP" = true ]; then
                    >&2 echo "Error: Branch '$BRANCH_NAME' already exists. Rerun to get a new timestamp or use a different --short-name."
                    exit 1
                else
                    >&2 echo "Error: Branch '$BRANCH_NAME' already exists. Please use a different feature name or specify a different number with --number."
                    exit 1
                fi
            else
                >&2 echo "Error: Failed to create git branch '$BRANCH_NAME'."
                if [ -n "$branch_create_error" ]; then
                    >&2 printf '%s\n' "$branch_create_error"
                else
                    >&2 echo "Please check your git configuration and try again."
                fi
                exit 1
            fi
        fi
    else
        >&2 echo "[specify] Warning: Git repository not detected; skipped branch creation for $BRANCH_NAME"
    fi

    printf '# To persist: export SPECIFY_FEATURE=%q\n' "$BRANCH_NAME" >&2
fi

if $JSON_MODE; then
    if command -v jq >/dev/null 2>&1; then
        if [ "$DRY_RUN" = true ]; then
            jq -cn \
                --arg branch_name "$BRANCH_NAME" \
                --arg feature_num "$FEATURE_NUM" \
                --arg mode "$ISOLATION_MODE" \
                '{BRANCH_NAME:$branch_name,FEATURE_NUM:$feature_num,ISOLATION_MODE:$mode,DRY_RUN:true}'
        else
            jq -cn \
                --arg branch_name "$BRANCH_NAME" \
                --arg feature_num "$FEATURE_NUM" \
                --arg mode "$ISOLATION_MODE" \
                '{BRANCH_NAME:$branch_name,FEATURE_NUM:$feature_num,ISOLATION_MODE:$mode}'
        fi
    else
        if type json_escape >/dev/null 2>&1; then
            _je_branch=$(json_escape "$BRANCH_NAME")
            _je_num=$(json_escape "$FEATURE_NUM")
        else
            _je_branch="$BRANCH_NAME"
            _je_num="$FEATURE_NUM"
        fi
        if [ "$DRY_RUN" = true ]; then
            printf '{"BRANCH_NAME":"%s","FEATURE_NUM":"%s","ISOLATION_MODE":"%s","DRY_RUN":true}\n' "$_je_branch" "$_je_num" "$ISOLATION_MODE"
        else
            printf '{"BRANCH_NAME":"%s","FEATURE_NUM":"%s","ISOLATION_MODE":"%s"}\n' "$_je_branch" "$_je_num" "$ISOLATION_MODE"
        fi
    fi
else
    echo "BRANCH_NAME: $BRANCH_NAME"
    echo "FEATURE_NUM: $FEATURE_NUM"
    echo "ISOLATION_MODE: $ISOLATION_MODE"
    if [ "$DRY_RUN" != true ]; then
        printf '# To persist in your shell: export SPECIFY_FEATURE=%q\n' "$BRANCH_NAME"
    fi
fi
