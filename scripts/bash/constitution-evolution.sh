#!/usr/bin/env bash

set -e

JSON_MODE=false
AMEND_MODE=false
HISTORY_MODE=false
DIFF_MODE=false
VERSION_MODE=false

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --amend)
            AMEND_MODE=true
            ;;
        --history)
            HISTORY_MODE=true
            ;;
        --diff)
            DIFF_MODE=true
            ;;
        --version)
            VERSION_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [--json] [--amend|--history|--diff|--version] [options]"
            echo "  --json        Output results in JSON format"
            echo "  --amend       Propose or apply constitution amendment"
            echo "  --history     Show constitution amendment history"
            echo "  --diff        Show differences between constitution versions"
            echo "  --version     Manage constitution versioning"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
done

# Get script directory and load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

eval $(get_feature_paths)

CONSTITUTION_FILE="$REPO_ROOT/.specify/memory/constitution.md"
AMENDMENT_LOG="$REPO_ROOT/.specify/memory/constitution-amendments.log"

# Ensure amendment log exists
mkdir -p "$(dirname "$AMENDMENT_LOG")"
touch "$AMENDMENT_LOG"

# Function to log amendment
log_amendment() {
    local version="$1"
    local author="$2"
    local description="$3"
    local timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)

    echo "$timestamp|$version|$author|$description" >> "$AMENDMENT_LOG"
}

# Function to get current version
get_current_version() {
    if [[ ! -f "$CONSTITUTION_FILE" ]]; then
        echo "1.0.0"
        return
    fi

    local version=""
    version=$(grep "\*\*Version\*\*:" "$CONSTITUTION_FILE" | sed 's/.*Version\*\*: *\([0-9.]*\).*/\1/')

    if [[ -z "$version" ]]; then
        echo "1.0.0"
    else
        echo "$version"
    fi
}

# Function to increment version
increment_version() {
    local current_version="$1"
    local change_type="$2"  # major, minor, patch

    # Parse version components
    local major=""
    local minor=""
    local patch=""

    IFS='.' read -r major minor patch <<< "$current_version"

    case "$change_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo "ERROR: Invalid change type: $change_type" >&2
            return 1
            ;;
    esac

    echo "$major.$minor.$patch"
}

# Function to propose amendment
propose_amendment() {
    local amendment_file="$1"

    if [[ ! -f "$amendment_file" ]]; then
        echo "ERROR: Amendment file not found: $amendment_file"
        exit 1
    fi

    local amendment_content=""
    amendment_content=$(cat "$amendment_file")

    # Validate amendment format
    if ! echo "$amendment_content" | grep -q "\*\*Proposed Principle:\*\*"; then
        echo "ERROR: Amendment must include '**Proposed Principle:**' section"
        exit 1
    fi

    # Generate amendment ID
    local amendment_id=""
    amendment_id="amendment-$(date +%Y%m%d-%H%M%S)"

    # Create amendment record
    local record_file="$REPO_ROOT/.specify/memory/amendments/$amendment_id.md"

    mkdir -p "$(dirname "$record_file")"

    cat > "$record_file" << EOF
# Constitution Amendment: $amendment_id

**Status:** Proposed
**Proposed Date:** $(date +%Y-%m-%d)
**Proposed By:** $(git config user.name 2>/dev/null || echo "Unknown")

## Amendment Content

$amendment_content

## Review Status

- [ ] Technical Review
- [ ] Team Approval
- [ ] Implementation

## Comments

EOF

    echo "Amendment proposed: $amendment_id"
    echo "Review file: $record_file"

    if $JSON_MODE; then
        printf '{"status":"proposed","id":"%s","file":"%s"}\n' "$amendment_id" "$record_file"
    fi
}

# Function to apply amendment
apply_amendment() {
    local amendment_id="$1"
    local change_type="${2:-minor}"

    local record_file="$REPO_ROOT/.specify/memory/amendments/$amendment_id.md"

    if [[ ! -f "$record_file" ]]; then
        echo "ERROR: Amendment record not found: $record_file"
        exit 1
    fi

    # Check if amendment is approved
    if ! grep -q "**Status:** Approved" "$record_file"; then
        echo "ERROR: Amendment $amendment_id is not approved for application"
        exit 1
    fi

    # Get current version and increment
    local current_version=""
    current_version=$(get_current_version)

    local new_version=""
    new_version=$(increment_version "$current_version" "$change_type")

    # Extract amendment content
    local amendment_content=""
    amendment_content=$(sed -n '/^## Amendment Content/,/^## Review Status/p' "$record_file" | head -n -1 | tail -n +2)

    # Read current constitution
    local current_constitution=""
    current_constitution=$(cat "$CONSTITUTION_FILE")

    # Apply amendment (this is a simplified implementation)
    # In practice, this would need more sophisticated merging logic
    local updated_constitution="$current_constitution

## Amendment: $amendment_id

$amendment_content"

    # Update version and amendment date
    local today=$(date +%Y-%m-%d)
    updated_constitution=$(echo "$updated_constitution" | sed "s/\*\*Version\*\*:.*/**Version**: $new_version/")
    updated_constitution=$(echo "$updated_constitution" | sed "s/\*\*Last Amended\*\*:.*/**Last Amended**: $today/")

    # Write updated constitution
    echo "$updated_constitution" > "$CONSTITUTION_FILE"

    # Log amendment
    local author=""
    author=$(grep "**Proposed By:**" "$record_file" | sed 's/.*: //')
    local description=""
    description=$(grep "\*\*Proposed Principle:\*\*" "$record_file" | sed 's/.*: //' | head -1)

    log_amendment "$new_version" "$author" "Applied amendment $amendment_id: $description"

    # Update amendment status
    sed -i 's/**Status:** Approved/**Status:** Applied/' "$record_file"

    echo "Amendment applied: $amendment_id"
    echo "New version: $new_version"

    if $JSON_MODE; then
        printf '{"status":"applied","id":"%s","version":"%s"}\n' "$amendment_id" "$new_version"
    fi
}

# Function to show history
show_history() {
    if [[ ! -f "$AMENDMENT_LOG" ]]; then
        echo "No amendment history found"
        return
    fi

    if $JSON_MODE; then
        echo '{"amendments":['
        local first=true
        while IFS='|' read -r timestamp version author description; do
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo ','
            fi
            printf '{"timestamp":"%s","version":"%s","author":"%s","description":"%s"}' \
                "$timestamp" "$version" "$author" "$description"
        done < "$AMENDMENT_LOG"
        echo ']}'
    else
        echo "Constitution Amendment History:"
        echo "================================"
        printf "%-20s %-10s %-20s %s\n" "Date" "Version" "Author" "Description"
        echo "--------------------------------------------------------------------------------"

        while IFS='|' read -r timestamp version author description; do
            local date=""
            date=$(echo "$timestamp" | cut -d'T' -f1)
            printf "%-20s %-10s %-20s %s\n" "$date" "$version" "$author" "$description"
        done < "$AMENDMENT_LOG"
    fi
}

# Function to show diff
show_diff() {
    local version1="${1:-HEAD~1}"
    local version2="${2:-HEAD}"

    if ! git log --oneline -n 10 -- "$CONSTITUTION_FILE" > /dev/null 2>&1; then
        echo "ERROR: Constitution file not under git version control"
        exit 1
    fi

    echo "Constitution differences between $version1 and $version2:"
    echo "========================================================"

    git diff "$version1:$CONSTITUTION_FILE" "$version2:$CONSTITUTION_FILE" || {
        echo "Could not generate diff. Make sure both versions exist."
        exit 1
    }
}

# Function to manage versions
manage_version() {
    local action="$1"
    local change_type="$2"

    case "$action" in
        current)
            local version=""
            version=$(get_current_version)
            echo "Current constitution version: $version"
            ;;
        bump)
            if [[ -z "$change_type" ]]; then
                echo "ERROR: Must specify change type for version bump (major, minor, patch)"
                exit 1
            fi

            local current_version=""
            current_version=$(get_current_version)

            local new_version=""
            new_version=$(increment_version "$current_version" "$change_type")

            # Update constitution
            sed -i "s/\*\*Version\*\*:.*/**Version**: $new_version/" "$CONSTITUTION_FILE"
            sed -i "s/\*\*Last Amended\*\*:.*/**Last Amended**: $(date +%Y-%m-%d)/" "$CONSTITUTION_FILE"

            log_amendment "$new_version" "$(git config user.name 2>/dev/null || echo "System")" "Version bump: $change_type"

            echo "Version bumped from $current_version to $new_version"
            ;;
        *)
            echo "ERROR: Invalid version action: $action"
            echo "Valid actions: current, bump"
            exit 1
            ;;
    esac
}

# Main logic
if $AMEND_MODE; then
    if [[ ${#ARGS[@]} -eq 0 ]]; then
        echo "ERROR: Must specify amendment file for --amend"
        exit 1
    fi

    amendment_file="${ARGS[0]}"
    change_type="${ARGS[1]:-minor}"

    if [[ -f "$amendment_file" ]]; then
        propose_amendment "$amendment_file"
    else
        apply_amendment "$amendment_file" "$change_type"
    fi

elif $HISTORY_MODE; then
    show_history

elif $DIFF_MODE; then
    version1="${ARGS[0]}"
    version2="${ARGS[1]}"
    show_diff "$version1" "$version2"

elif $VERSION_MODE; then
    action="${ARGS[0]:-current}"
    change_type="${ARGS[1]}"
    manage_version "$action" "$change_type"

else
    # Default: show current status
    if [[ ! -f "$CONSTITUTION_FILE" ]]; then
        echo "No constitution found. Run setup-constitution.sh first."
        exit 1
    fi

    current_version=$(get_current_version)
    amendment_count=$(wc -l < "$AMENDMENT_LOG" 2>/dev/null || echo 0)

    if $JSON_MODE; then
        printf '{"version":"%s","amendments":%d,"file":"%s"}\n' \
            "$current_version" "$amendment_count" "$CONSTITUTION_FILE"
    else
        echo "Constitution Status:"
        echo "==================="
        echo "Current Version: $current_version"
        echo "Total Amendments: $amendment_count"
        echo "Constitution File: $CONSTITUTION_FILE"
        echo ""
        echo "Available commands:"
        echo "  --history          Show amendment history"
        echo "  --version current  Show current version"
        echo "  --version bump <type>  Bump version (major/minor/patch)"
        echo "  --amend <file>     Propose new amendment"
        echo "  --amend <id> <type> Apply approved amendment"
        echo "  --diff [v1] [v2]  Show constitution differences"
    fi
fi