#!/usr/bin/env bash

set -e

JSON_MODE=false
SHORT_NAME=""
BRANCH_NUMBER=""
CONTRACTS="true"
DATA_MODELS="true"
ARGS=()
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --json) 
            JSON_MODE=true 
            ;;
        --short-name)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --short-name requires a value' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            # Check if the next argument is another option (starts with --)
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
            BRANCH_NUMBER="$next_arg"
            ;;
        --contracts)
            CONTRACTS="true"
            ;;
        --no-contracts)
            CONTRACTS="false"
            ;;
        --data-models)
            DATA_MODELS="true"
            ;;
        --no-data-models)
            DATA_MODELS="false"
            ;;
        --help|-h) 
            echo "Usage: $0 [OPTIONS] <feature_description>"
            echo ""
            echo "Options:"
            echo "  --json                  Output in JSON format"
            echo "  --short-name <name>     Provide a custom short name (2-4 words) for the branch"
            echo "  --number N              Specify branch number manually (overrides auto-detection)"
            echo "  --contracts             Enable service contracts (requires framework)"
            echo "  --no-contracts          Disable service contracts"
            echo "  --data-models           Generate data model documentation"
            echo "  --no-data-models        Skip data model generation"
            echo "  --help, -h              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 'Add user authentication system' --short-name 'user-auth'"
            echo "  $0 --number 5 'Feature with specific number'"
            echo "  $0 --contracts --no-data-models 'My feature' --short-name 'my-feature'"
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
    echo "Usage: $0 [--json] [--short-name <name>] [--number N] [--contracts] [--no-contracts] [--data-models] [--no-data-models] <feature_description>" >&2
    exit 1
fi

# Trim whitespace and validate description is not empty (e.g., user passed only whitespace)
FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | xargs)
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Error: Feature description cannot be empty or contain only whitespace" >&2
    exit 1
fi

# Function to find the repository root by searching for existing project markers
find_repo_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -d "$dir/.specify" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Function to get highest number from specs directory
get_highest_from_specs() {
    local specs_dir="$1"
    local highest=0
    
    if [ -d "$specs_dir" ]; then
        for dir in "$specs_dir"/*; do
            [ -d "$dir" ] || continue
            dirname=$(basename "$dir")
            number=$(echo "$dirname" | grep -o '^[0-9]\+' || echo "0")
            number=$((10#$number))
            if [ "$number" -gt "$highest" ]; then
                highest=$number
            fi
        done
    fi
    
    echo "$highest"
}

# Function to get highest number from git branches
get_highest_from_branches() {
    local highest=0
    
    # Get all branches (local and remote)
    branches=$(git branch -a 2>/dev/null || echo "")
    
    if [ -n "$branches" ]; then
        while IFS= read -r branch; do
            # Clean branch name: remove leading markers and remote prefixes
            clean_branch=$(echo "$branch" | sed 's/^[* ]*//; s|^remotes/[^/]*/||')
            
            # Extract feature number if branch matches pattern ###-*
            if echo "$clean_branch" | grep -q '^[0-9]\{3\}-'; then
                number=$(echo "$clean_branch" | grep -o '^[0-9]\{3\}' || echo "0")
                number=$((10#$number))
                if [ "$number" -gt "$highest" ]; then
                    highest=$number
                fi
            fi
        done <<< "$branches"
    fi
    
    echo "$highest"
}

# Function to check existing branches (local and remote) and return next available number
check_existing_branches() {
    local specs_dir="$1"

    # Fetch all remotes to get latest branch info (suppress all output)
    git fetch --all --prune >/dev/null 2>&1 || true

    # Get highest number from ALL branches (not just matching short name)
    local highest_branch=$(get_highest_from_branches)

    # Get highest number from ALL specs (not just matching short name)
    local highest_spec=$(get_highest_from_specs "$specs_dir")

    # Take the maximum of both
    local max_num=$highest_branch
    if [ "$highest_spec" -gt "$max_num" ]; then
        max_num=$highest_spec
    fi

    # Return next number
    echo $((max_num + 1))
}

# Function to clean and format a branch name
clean_branch_name() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//'
}

# Escape a string for safe embedding in a JSON value (fallback when jq is unavailable).
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\r'/\\r}"
    printf '%s' "$s"
}

# Resolve repository root. Prefer git information when available, but fall back
# to searching for repository markers so the workflow still functions in repositories that
# were initialised with --no-git.
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    HAS_GIT=true
else
    REPO_ROOT="$(find_repo_root "$SCRIPT_DIR")"
    if [ -z "$REPO_ROOT" ]; then
        echo "Error: Could not determine repository root. Please run this script from within the repository." >&2
        exit 1
    fi
    HAS_GIT=false
fi

cd "$REPO_ROOT"

# Get the global config path using XDG Base Directory spec
get_global_config_path() {
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    echo "$config_home/specify/config.json"
}

# Get project-level config path (.specify/config.json)
get_project_config_path() {
    echo "$REPO_ROOT/.specify/config.json"
}

# Get config path with hierarchical resolution
get_config_path() {
    local project_config=$(get_project_config_path)
    local user_config=$(get_global_config_path)
    
    if [[ -f "$project_config" ]]; then
        echo "$project_config"
    elif [[ -f "$user_config" ]]; then
        echo "$user_config"
    else
        echo "$project_config"
    fi
}

SPECS_DIR="$REPO_ROOT/specs"
mkdir -p "$SPECS_DIR"

# Function to generate branch name with stop word filtering and length filtering
generate_branch_name() {
    local description="$1"
    
    # Common stop words to filter out
    local stop_words="^(i|a|an|the|to|for|of|in|on|at|by|with|from|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|should|could|can|may|might|must|shall|this|that|these|those|my|your|our|their|want|need|add|get|set)$"
    
    # Convert to lowercase and split into words
    local clean_name=$(echo "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g')
    
    # Filter words: remove stop words and words shorter than 3 chars (unless they're uppercase acronyms in original)
    local meaningful_words=()
    for word in $clean_name; do
        # Skip empty words
        [ -z "$word" ] && continue
        
        # Keep words that are NOT stop words AND (length >= 3 OR are potential acronyms)
        if ! echo "$word" | grep -qiE "$stop_words"; then
            if [ ${#word} -ge 3 ]; then
                meaningful_words+=("$word")
            elif echo "$description" | grep -q "\b${word^^}\b"; then
                # Keep short words if they appear as uppercase in original (likely acronyms)
                meaningful_words+=("$word")
            fi
        fi
    done
    
    # If we have meaningful words, use first 3-4 of them
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
        # Fallback to original logic if no meaningful words found
        local cleaned=$(clean_branch_name "$description")
        echo "$cleaned" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//'
    fi
}

# Generate branch name
if [ -n "$SHORT_NAME" ]; then
    # Use provided short name, just clean it up
    BRANCH_SUFFIX=$(clean_branch_name "$SHORT_NAME")
else
    # Generate from description with smart filtering
    BRANCH_SUFFIX=$(generate_branch_name "$FEATURE_DESCRIPTION")
fi

# Determine branch number
if [ -z "$BRANCH_NUMBER" ]; then
    if [ "$HAS_GIT" = true ]; then
        # Check existing branches on remotes
        BRANCH_NUMBER=$(check_existing_branches "$SPECS_DIR")
    else
        # Fall back to local directory check
        HIGHEST=$(get_highest_from_specs "$SPECS_DIR")
        BRANCH_NUMBER=$((HIGHEST + 1))
    fi
fi

# Force base-10 interpretation to prevent octal conversion (e.g., 010 → 8 in octal, but should be 10 in decimal)
FEATURE_NUM=$(printf "%03d" "$((10#$BRANCH_NUMBER))")
BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"

# GitHub enforces a 244-byte limit on branch names
# Validate and truncate if necessary
MAX_BRANCH_LENGTH=244
if [ ${#BRANCH_NAME} -gt $MAX_BRANCH_LENGTH ]; then
    # Calculate how much we need to trim from suffix
    # Account for: feature number (3) + hyphen (1) = 4 chars
    MAX_SUFFIX_LENGTH=$((MAX_BRANCH_LENGTH - 4))
    
    # Truncate suffix at word boundary if possible
    TRUNCATED_SUFFIX=$(echo "$BRANCH_SUFFIX" | cut -c1-$MAX_SUFFIX_LENGTH)
    # Remove trailing hyphen if truncation created one
    TRUNCATED_SUFFIX=$(echo "$TRUNCATED_SUFFIX" | sed 's/-$//')
    
    ORIGINAL_BRANCH_NAME="$BRANCH_NAME"
    BRANCH_NAME="${FEATURE_NUM}-${TRUNCATED_SUFFIX}"
    
    >&2 echo "[specify] Warning: Branch name exceeded GitHub's 244-byte limit"
    >&2 echo "[specify] Original: $ORIGINAL_BRANCH_NAME (${#ORIGINAL_BRANCH_NAME} bytes)"
    >&2 echo "[specify] Truncated to: $BRANCH_NAME (${#BRANCH_NAME} bytes)"
fi

if [ "$HAS_GIT" = true ]; then
    if ! git checkout -b "$BRANCH_NAME" 2>/dev/null; then
        # Check if branch already exists
        if git branch --list "$BRANCH_NAME" | grep -q .; then
            >&2 echo "Error: Branch '$BRANCH_NAME' already exists. Please use a different feature name or specify a different number with --number."
            exit 1
        else
            >&2 echo "Error: Failed to create git branch '$BRANCH_NAME'. Please check your git configuration and try again."
            exit 1
        fi
    fi
else
    >&2 echo "[specify] Warning: Git repository not detected; skipped branch creation for $BRANCH_NAME"
fi

FEATURE_DIR="$SPECS_DIR/$BRANCH_NAME"
mkdir -p "$FEATURE_DIR"

# Function to replace [DATE] placeholders with current date in ISO format (YYYY-MM-DD)
replace_date_placeholders() {
    local file="$1"
    local current_date=$(date +%Y-%m-%d)
    
    if [ -f "$file" ]; then
        # Use sed to replace [DATE] with current date
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS requires empty string for -i
            sed -i '' "s/\[DATE\]/${current_date}/g" "$file"
        else
            # Linux/other systems
            sed -i "s/\[DATE\]/${current_date}/g" "$file"
        fi
    fi
}

# Apply defaults for options if not explicitly set
TEMPLATE=$(resolve_template "spec-template" "$REPO_ROOT")
SPEC_FILE="$FEATURE_DIR/spec.md"
if [ -n "$TEMPLATE" ] && [ -f "$TEMPLATE" ]; then cp "$TEMPLATE" "$SPEC_FILE"; else touch "$SPEC_FILE"; fi

# Replace options metadata in spec.md
if [ -f "$SPEC_FILE" ]; then
    # Use awk to replace placeholders - simpler than complex sed
    awk -v contracts_val="$CONTRACTS" -v datamodels_val="$DATA_MODELS" '
        BEGIN { in_fw = 0 }
        /\*\*Framework Options\*\*:/ { in_fw = 1; next }
        in_fw && /^  contracts=/ { sub(/contracts=\{*\}/, "contracts=" contracts_val); }
        in_fw && /^  data_models=/ { sub(/data_models=\{*\}/, "data_models=" datamodels_val); }
        { print }
    ' "$SPEC_FILE" > "${SPEC_FILE}.tmp" && mv "${SPEC_FILE}.tmp" "$SPEC_FILE"
fi

# Replace [DATE] placeholders with current date
replace_date_placeholders "$SPEC_FILE"

CONTEXT_TEMPLATE=$(resolve_template "context-template" "$REPO_ROOT")
CONTEXT_FILE="$FEATURE_DIR/context.md"

# Function to discover team directives (Issue #47)
discover_directives() {
    local feature_description="$1"
    local team_directives_path="$2"

    if [[ ! -d "$team_directives_path" ]]; then
        cat <<'EOF'
{
    "candidates": {
        "constitution": "",
        "personas": [],
        "rules": [],
        "skills": [],
        "examples": []
    },
    "search_metadata": {
        "keywords": [],
        "files_searched": 0,
        "files_with_matches": 0
    }
}
EOF
        return
    fi

    local constitution=""
    if [[ -f "$team_directives_path/constitutions/constitution.md" ]]; then
        constitution="$team_directives_path/constitutions/constitution.md"
    elif [[ -f "$team_directives_path/constitution.md" ]]; then
        constitution="$team_directives_path/constitution.md"
    fi

    cat <<EOF
{
    "candidates": {
        "constitution": "${constitution}",
        "personas": [],
        "rules": [],
        "skills": [],
        "examples": []
    },
    "search_metadata": {
        "keywords": [],
        "files_searched": 0,
        "files_with_matches": 0
    }
}
EOF
}

# Function to discover skills (Issue #49)
discover_skills() {
    local feature_description="$1"
    local team_directives_path="$2"
    local skills_cache_path="$3"
    local max_skills="${4:-5}"
    local threshold="${5:-0.7}"

    mkdir -p "$skills_cache_path"

    local cache_marker="$skills_cache_path/.last_refresh"
    local current_timestamp=$(date +%s)
    local one_day=86400

    local need_refresh=false
    if [[ -f "$cache_marker" ]]; then
        local last_refresh=$(cat "$cache_marker")
        local age=$((current_timestamp - last_refresh))
        if [[ $age -gt $one_day ]]; then
            need_refresh=true
        fi
    else
        need_refresh=true
    fi

    if $need_refresh && [[ -d "$team_directives_path/skills" ]]; then
        echo "[specify] Refreshing skills cache (daily refresh)..." >&2
        cp -r "$team_directives_path/skills/"* "$skills_cache_path/" 2>/dev/null || true
        echo "$current_timestamp" > "$cache_marker"
    fi

    local required_skills=()
    local blocked_skills=()
    if [[ -f "$team_directives_path/.skills.json" ]]; then
        local required=$(jq -r '.skills.required // {} | keys[]' "$team_directives_path/.skills.json" 2>/dev/null)
        [[ -n "$required" ]] && while read -r skill_id; do
            local skill_url=$(jq -r ".skills.required[\"$skill_id\"].url // empty" "$team_directives_path/.skills.json" 2>/dev/null)
            if [[ -n "$skill_url" ]]; then
                local cache_dir="$skills_cache_path/$(basename "$skill_id")"
                mkdir -p "$cache_dir"
                curl -s -o "$cache_dir/SKILL.md" "$skill_url" 2>/dev/null
                if [[ -f "$cache_dir/SKILL.md" && -s "$cache_dir/SKILL.md" ]]; then
                    required_skills+=("$skill_id")
                fi
            elif [[ "$skill_id" == "local:"* ]]; then
                required_skills+=("$skill_id")
            elif [[ -d "$skills_cache_path/$skill_id" && -f "$skills_cache_path/$skill_id/SKILL.md" ]]; then
                required_skills+=("$skill_id")
            fi
        done <<< "$required"

        local recommended=$(jq -r '.skills.recommended // {} | keys[]' "$team_directives_path/.skills.json" 2>/dev/null)
        [[ -n "$recommended" ]] && while read -r skill_id; do
            local skill_url=$(jq -r ".skills.recommended[\"$skill_id\"].url // empty" "$team_directives_path/.skills.json" 2>/dev/null)
            if [[ -n "$skill_url" ]]; then
                local cache_dir="$skills_cache_path/$(basename "$skill_id")"
                mkdir -p "$cache_dir"
                curl -s -o "$cache_dir/SKILL.md" "$skill_url" 2>/dev/null
                if [[ -f "$cache_dir/SKILL.md" && -s "$cache_dir/SKILL.md" ]]; then
                    required_skills+=("$skill_id")
                fi
            elif [[ "$skill_id" == "local:"* ]]; then
                required_skills+=("$skill_id")
            elif [[ -d "$skills_cache_path/$skill_id" && -f "$skills_cache_path/$skill_id/SKILL.md" ]]; then
                required_skills+=("$skill_id")
            fi
        done <<< "$recommended"

        local blocked=$(jq -r '.skills.blocked // [] | .[]' "$team_directives_path/.skills.json" 2>/dev/null)
        [[ -n "$blocked" ]] && while read -r blocked_id; do
            blocked_skills+=("$blocked_id")
        done <<< "$blocked"
    fi

    local cached_skills=()
    if [[ -d "$skills_cache_path" ]]; then
        while IFS= read -r skill_dir; do
            [[ "$skill_dir" == "$skills_cache_path" ]] && continue
            [[ ! -d "$skill_dir" ]] && continue
            local skill_name=$(basename "$skill_dir")
            if [[ " ${required_skills[*]} " =~ " $skill_name " ]]; then
                continue
            fi
            local skill_md="$skill_dir/SKILL.md"
            if [[ ! -f "$skill_md" || ! -s "$skill_md" ]]; then
                continue
            fi
            cached_skills+=("$skill_name")
        done < <(find "$skills_cache_path" -maxdepth 1 -type d | grep -v "$skills_cache_path$")
    fi

    local candidate_list=()
    for skill_id in "${required_skills[@]}"; do
        local is_blocked=0
        for blocked_id in "${blocked_skills[@]}"; do
            [[ "$skill_id" == "$blocked_id" ]] && is_blocked=1 && break
        done
        [[ $is_blocked -eq 1 ]] && continue

        local skill_path=""
        local skill_name=""
        if [[ "$skill_id" == "local:"* ]]; then
            skill_path="$team_directives_path/${skill_id#local:}"
            skill_name=$(basename "$skill_path")
        else
            skill_path="$skills_cache_path/$skill_id"
            skill_name=$skill_id
        fi

        [[ ! -f "$skill_path/SKILL.md" || ! -s "$skill_path/SKILL.md" ]] && continue
        candidate_list+=("required:$skill_name")
    done

    for skill_name in "${cached_skills[@]}"; do
        local is_blocked=0
        for blocked_id in "${blocked_skills[@]}"; do
            [[ "$skill_name" == "$blocked_id" ]] && is_blocked=1 && break
        done
        [[ $is_blocked -eq 1 ]] && continue
        [[ " ${candidate_list[*]} " =~ " required:$skill_name " ]] && continue
        candidate_list+=("$skill_name")
    done

    local candidates_json="["
    local first=1
    for skill_id in "${candidate_list[@]:0:$max_skills}"; do
        [[ $first -eq 0 ]] && candidates_json+=","
        local skill_name="${skill_id#required:}"
        local source="${skill_id%%:*}"
        local base_relevance="1.0"
        [[ "$source" != "required" ]] && base_relevance="0.65"
        candidates_json+=$(jq -n --arg id "$skill_id" --arg name "$skill_name" --arg source "$source" --argjson base_relevance "$base_relevance" '{"id":$id,"name":$name,"source":$source,"base_relevance":$base_relevance}')
        first=0
    done
    candidates_json+="]"

    jq -n \
        --argjson candidates "$candidates_json" \
        '{
            "candidates": $candidates,
            "last_refresh": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
        }'
}

# Function to populate context.md with defaults
populate_context_file() {
    local context_file="$1"
    local feature_name="$2"
    local feature_description="$3"

    # Extract feature title (first line or first sentence)
    local feature_title=$(echo "$feature_description" | head -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    # Extract mission (first sentence, limited to reasonable length)
    local mission=$(echo "$feature_description" | grep -o '^[[:print:]]*[.!?]' | head -1 | sed 's/[.!?]$//')
    if [ -z "$mission" ]; then
        mission="$feature_description"
    fi
    # Limit mission length for readability
    if [ ${#mission} -gt 200 ]; then
        mission=$(echo "$mission" | cut -c1-200 | sed 's/[[:space:]]*$//' | sed 's/[[:space:]]*$/.../')
    fi

    # Spec mode: Comprehensive context for full specification
    # Detect code paths (basic detection based on common patterns)
    local code_paths="To be determined during planning phase"
    if echo "$feature_description" | grep -qi "api\|endpoint\|service"; then
        code_paths="api/, services/"
    elif echo "$feature_description" | grep -qi "ui\|frontend\|component"; then
        code_paths="src/components/, src/pages/"
    elif echo "$feature_description" | grep -qi "database\|data\|model"; then
        code_paths="src/models/, database/"
    fi

    # Read team directives if available
    local directives="None"
    local team_directives_file="$REPO_ROOT/.specify/memory/team-ai-directives/directives.md"
    if [ -f "$team_directives_file" ]; then
        directives="See team-ai-directives repository for applicable guidelines"
    fi

    # Set research needs
    local research="To be identified during specification and planning phases"

    # Create context.md with populated values
    cat > "$context_file" << EOF
# Feature Context

**Feature**: $feature_title
**Mission**: $mission
**Code Paths**: $code_paths
**Directives**: $directives
**Research**: $research

EOF
}

# Populate context.md with defaults
if [ -f "$CONTEXT_TEMPLATE" ]; then
    populate_context_file "$CONTEXT_FILE" "$BRANCH_SUFFIX" "$FEATURE_DESCRIPTION"
else
    touch "$CONTEXT_FILE"
fi

# Resolve team directives path
TEAM_DIRECTIVES_DIR="${SPECIFY_TEAM_DIRECTIVES:-}"
if [[ -z "$TEAM_DIRECTIVES_DIR" ]]; then
    TEAM_DIRECTIVES_DIR="$REPO_ROOT/.specify/memory/team-ai-directives"
fi

# Sync team-ai-directives if URL provided
if [[ "$TEAM_DIRECTIVES_DIR" =~ ^https?:// ]]; then
    echo "[specify] Syncing team-ai-directives from $TEAM_DIRECTIVES_DIR..." >&2
    TEMP_DIR=$(mktemp -d)
    if git clone --depth 1 "$TEAM_DIRECTIVES_DIR" "$TEMP_DIR/team-ai-directives" 2>/dev/null; then
        TARGET_DIR="$REPO_ROOT/.specify/memory/team-ai-directives"
        rm -rf "$TARGET_DIR"
        mv "$TEMP_DIR/team-ai-directives" "$TARGET_DIR"
        TEAM_DIRECTIVES_DIR="$TARGET_DIR"
        echo "[specify] Team-ai-directives synced successfully" >&2
    else
        echo "[specify] Warning: Failed to sync team-ai-directives" >&2
    fi
    rm -rf "$TEMP_DIR"
fi

# Discover directives and skills
DISCOVERED_DIRECTIVES=$(discover_directives "$FEATURE_DESCRIPTION" "$TEAM_DIRECTIVES_DIR")
DISCOVERED_SKILLS=$(discover_skills "$FEATURE_DESCRIPTION" "$TEAM_DIRECTIVES_DIR" "$REPO_ROOT/.specify/skills")

# Set the SPECIFY_FEATURE environment variable for the current session
export SPECIFY_FEATURE="$BRANCH_NAME"

# Inform the user how to persist the feature variable in their own shell
printf '# To persist: export SPECIFY_FEATURE=%q\n' "$BRANCH_NAME" >&2

if $JSON_MODE; then
    if command -v jq >/dev/null 2>&1; then
        jq -cn \
            --arg branch_name "$BRANCH_NAME" \
            --arg spec_file "$SPEC_FILE" \
            --arg feature_num "$FEATURE_NUM" \
            --argjson discovered_directives "$DISCOVERED_DIRECTIVES" \
            --argjson discovered_skills "$DISCOVERED_SKILLS" \
            '{BRANCH_NAME:$branch_name,SPEC_FILE:$spec_file,FEATURE_NUM:$feature_num,DISCOVERED_DIRECTIVES:$discovered_directives,DISCOVERED_SKILLS:$discovered_skills}'
    else
        printf '{"BRANCH_NAME":"%s","SPEC_FILE":"%s","FEATURE_NUM":"%s","DISCOVERED_DIRECTIVES":%s,"DISCOVERED_SKILLS":%s}\n' \
            "$(json_escape "$BRANCH_NAME")" "$(json_escape "$SPEC_FILE")" "$(json_escape "$FEATURE_NUM")" "$DISCOVERED_DIRECTIVES" "$DISCOVERED_SKILLS"
    fi
else
    echo "BRANCH_NAME: $BRANCH_NAME"
    echo "SPEC_FILE: $SPEC_FILE"
    echo "FEATURE_NUM: $FEATURE_NUM"
    printf '# To persist in your shell: export SPECIFY_FEATURE=%q\n' "$BRANCH_NAME"
fi
