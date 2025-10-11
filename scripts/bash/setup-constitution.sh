#!/usr/bin/env bash

set -e

JSON_MODE=false
ARGS=()

VALIDATE_MODE=false
SCAN_MODE=false

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --validate)
            VALIDATE_MODE=true
            ;;
        --scan)
            SCAN_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [--json] [--validate] [--scan]"
            echo "  --json      Output results in JSON format"
            echo "  --validate  Validate existing constitution against team inheritance"
            echo "  --scan      Scan project artifacts and suggest constitution enhancements"
            echo "  --help      Show this help message"
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

# Get all paths and variables from common functions
eval $(get_feature_paths)

# Ensure the .specify/memory directory exists
mkdir -p "$REPO_ROOT/.specify/memory"

CONSTITUTION_FILE="$REPO_ROOT/.specify/memory/constitution.md"
TEMPLATE_FILE="$REPO_ROOT/memory/constitution.md"

# Function to load team constitution
load_team_constitution() {
    local team_constitution=""

    # Try to find team constitution in team directives
    if [[ -n "$TEAM_DIRECTIVES" && -d "$TEAM_DIRECTIVES" ]]; then
        # Look for constitution.md in team directives
        local team_const_file="$TEAM_DIRECTIVES/constitution.md"
        if [[ -f "$team_const_file" ]]; then
            team_constitution=$(cat "$team_const_file")
        else
            # Look in context_modules subdirectory
            team_const_file="$TEAM_DIRECTIVES/context_modules/constitution.md"
            if [[ -f "$team_const_file" ]]; then
                team_constitution=$(cat "$team_const_file")
            fi
        fi
    fi

    # If no team constitution found, use default template
    if [[ -z "$team_constitution" ]]; then
        team_constitution="# Project Constitution

## Core Principles

### Principle 1: Quality First
All code must meet quality standards and include appropriate testing.

### Principle 2: Documentation Required
Clear documentation must accompany all significant changes.

### Principle 3: Security by Default
Security considerations must be addressed for all features.

## Governance

**Version**: 1.0.0 | **Ratified**: $(date +%Y-%m-%d) | **Last Amended**: $(date +%Y-%m-%d)

*This constitution was auto-generated from team defaults. Customize as needed for your project.*"
    fi

    echo "$team_constitution"
}

# Function to parse team principles
parse_team_principles() {
    local team_constitution="$1"

    principles=()
    descriptions=()

    echo "DEBUG: Parsing team constitution:" >&2
    echo "$team_constitution" | head -10 >&2

    # Split team constitution into lines and parse
    in_description=false
    current_description=""

    while IFS= read -r line; do
        echo "DEBUG: Line: '$line'" >&2
        # Check for principle header: "1. **Principle Name**"
        if [[ $line =~ ^([0-9]+)\.\ \*\*(.*)\*\*\ *$ ]]; then
            echo "DEBUG: Matched principle: '${BASH_REMATCH[2]}'" >&2
            # Save previous principle if exists
            if [[ ${#principles[@]} -gt 0 && -n "$current_description" ]]; then
                descriptions[${#descriptions[@]}]="$current_description"
            fi

            # Start new principle
            principles[${#principles[@]}]="${BASH_REMATCH[2]}"
            current_description=""
            in_description=true
        elif [[ $in_description == true && -n "$line" ]]; then
            # Accumulate description lines
            if [[ -z "$current_description" ]]; then
                current_description="$line"
            else
                current_description="$current_description $line"
            fi
        fi
    done <<< "$team_constitution"

    # Save last principle description
    if [[ ${#principles[@]} -gt 0 && -n "$current_description" ]]; then
        descriptions[${#descriptions[@]}]="$current_description"
    fi
}

# Function to fill constitution template with team inheritance
fill_constitution_template() {
    local team_constitution="$1"
    local template_content="$2"
    local project_name=""

    # Try to extract project name from git or directory
    if [[ -n "$CURRENT_BRANCH" && "$CURRENT_BRANCH" != "main" ]]; then
        project_name="$CURRENT_BRANCH"
    else
        project_name=$(basename "$REPO_ROOT")
    fi

    # Parse team principles
    parse_team_principles "$team_constitution"

    # Debug: Show what was parsed
    echo "DEBUG: Found ${#principles[@]} principles" >&2
    for i in "${!principles[@]}"; do
        echo "DEBUG: Principle $((i+1)): '${principles[$i]}'" >&2
    done

    # Set template variables
    local today=$(date +%Y-%m-%d)

    # Replace placeholders in template
    filled_template="$template_content"
    filled_template="${filled_template//\[PROJECT_NAME\]/$project_name}"
    filled_template="${filled_template//\[CONSTITUTION_VERSION\]/1.0.0}"
    filled_template="${filled_template//\[RATIFICATION_DATE\]/$today}"
    filled_template="${filled_template//\[LAST_AMENDED_DATE\]/$today}"

    # Fill principle placeholders
    for i in {1..5}; do
        # Get principle name and description (arrays are 0-indexed)
        local idx=$((i-1))
        local name_value=""
        local desc_value=""

        if [[ $idx -lt ${#principles[@]} ]]; then
            name_value="${principles[$idx]}"
            desc_value="${descriptions[$idx]}"
        fi

        filled_template="${filled_template//\[PRINCIPLE_${i}_NAME\]/$name_value}"
        filled_template="${filled_template//\[PRINCIPLE_${i}_DESCRIPTION\]/$desc_value}"
    done

    # Fill section placeholders with team governance
    filled_template="${filled_template//\[SECTION_2_NAME\]/Additional Constraints}"
    filled_template="${filled_template//\[SECTION_2_CONTENT\]/All team principles must be followed. Constitution supersedes other practices.}"
    filled_template="${filled_template//\[SECTION_3_NAME\]/Development Workflow}"
    filled_template="${filled_template//\[SECTION_3_CONTENT\]/Follow team constitution principles in all development activities.}"
    filled_template="${filled_template//\[GOVERNANCE_RULES\]/All changes must comply with team constitution. Amendments require team approval.}"

    echo "$filled_template"
}

# Function to validate inheritance integrity
validate_inheritance() {
    local team_constitution="$1"
    local project_constitution="$2"

    # Extract core principles from team constitution
    local team_principles=""
    if echo "$team_constitution" | grep -q "^[0-9]\+\. \*\*.*\*\*"; then
        # Numbered list format
        team_principles=$(echo "$team_constitution" | grep "^[0-9]\+\. \*\*.*\*\*" | sed 's/^[0-9]\+\. \*\{2\}\(.*\)\*\{2\}.*/\1/')
    fi

    # Check if project constitution contains team principles
    local missing_principles=""
    for principle in $team_principles; do
        if ! echo "$project_constitution" | grep -qi "$principle"; then
            missing_principles="$missing_principles$principle, "
        fi
    done

    if [[ -n "$missing_principles" ]]; then
        echo "WARNING: Project constitution may be missing some team principles: ${missing_principles%, }"
        echo "Consider ensuring all team principles are represented in your project constitution."
    else
        echo "✓ Inheritance validation passed - all team principles detected in project constitution"
    fi
}

# Function to check for team constitution updates
check_team_updates() {
    local team_constitution="$1"
    local project_constitution="$2"

    # Check if project constitution has inheritance marker
    if echo "$project_constitution" | grep -q "Inherited from team constitution"; then
        local inheritance_date=""
        inheritance_date=$(echo "$project_constitution" | grep "Inherited from team constitution" | sed 's/.*on \([0-9-]\+\).*/\1/')

        if [[ -n "$inheritance_date" ]]; then
            # Get team constitution file modification date
            local team_file=""
            if [[ -n "$TEAM_DIRECTIVES" && -d "$TEAM_DIRECTIVES" ]]; then
                if [[ -f "$TEAM_DIRECTIVES/constitution.md" ]]; then
                    team_file="$TEAM_DIRECTIVES/constitution.md"
                elif [[ -f "$TEAM_DIRECTIVES/context_modules/constitution.md" ]]; then
                    team_file="$TEAM_DIRECTIVES/context_modules/constitution.md"
                fi
            fi

            if [[ -n "$team_file" ]]; then
                local team_mod_date=""
                team_mod_date=$(stat -c %Y "$team_file" 2>/dev/null)

                local inheritance_timestamp=""
                inheritance_timestamp=$(date -d "$inheritance_date" +%s 2>/dev/null)

                if [[ -n "$team_mod_date" && -n "$inheritance_timestamp" && "$team_mod_date" -gt "$inheritance_timestamp" ]]; then
                    echo "NOTICE: Team constitution has been updated since project constitution was created."
                    echo "Consider reviewing the team constitution for any changes that should be reflected in your project."
                    echo "Team constitution: $team_file"
                fi
            fi
        fi
    fi
}

# Scan-only mode
if $SCAN_MODE && [[ ! -f "$CONSTITUTION_FILE" ]]; then
    echo "Scanning project artifacts for constitution suggestions..."
    "$SCRIPT_DIR/scan-project-artifacts.sh" --suggestions
    exit 0
fi

# Validation-only mode
if $VALIDATE_MODE; then
    if [[ ! -f "$CONSTITUTION_FILE" ]]; then
        echo "ERROR: No constitution file found at $CONSTITUTION_FILE"
        echo "Run without --validate to create the constitution first."
        exit 1
    fi

    # Load constitutions for validation
    TEAM_CONSTITUTION=$(load_team_constitution)
    PROJECT_CONSTITUTION=$(cat "$CONSTITUTION_FILE")

    if $JSON_MODE; then
        # Basic validation result
        printf '{"status":"validated","file":"%s","team_directives":"%s"}\n' "$CONSTITUTION_FILE" "$TEAM_DIRECTIVES"
    else
        echo "Validating constitution at: $CONSTITUTION_FILE"
        echo "Team directives source: $TEAM_DIRECTIVES"
        echo ""
        validate_inheritance "$TEAM_CONSTITUTION" "$PROJECT_CONSTITUTION"
        echo ""
        check_team_updates "$TEAM_CONSTITUTION" "$PROJECT_CONSTITUTION"
    fi
    exit 0
fi

# Main logic
if [[ -f "$CONSTITUTION_FILE" ]]; then
    echo "Constitution file already exists at $CONSTITUTION_FILE"
    echo "Use git to modify it directly, or remove it to recreate from team directives."

    # Load team constitution for comparison
    TEAM_CONSTITUTION=$(load_team_constitution)
    EXISTING_CONSTITUTION=$(cat "$CONSTITUTION_FILE")

    # Check for team constitution updates
    if ! $JSON_MODE; then
        check_team_updates "$TEAM_CONSTITUTION" "$EXISTING_CONSTITUTION"
        echo ""
    fi

    if $JSON_MODE; then
        printf '{"status":"exists","file":"%s"}\n' "$CONSTITUTION_FILE"
    fi
    exit 0
fi

# Load team constitution
TEAM_CONSTITUTION=$(load_team_constitution)

# Load constitution template
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "ERROR: Constitution template not found at $TEMPLATE_FILE"
    exit 1
fi
TEMPLATE_CONTENT=$(cat "$TEMPLATE_FILE")

# Fill template with team inheritance
PROJECT_CONSTITUTION=$(fill_constitution_template "$TEAM_CONSTITUTION" "$TEMPLATE_CONTENT")

# If scan mode is enabled, enhance constitution with project insights
if $SCAN_MODE; then
    if ! $JSON_MODE; then
        echo "Enhancing constitution with project artifact analysis..."
    fi

    # Get scan suggestions
    SCAN_SUGGESTIONS=$("$SCRIPT_DIR/scan-project-artifacts.sh" --json)

    # Parse scan data and generate suggestions
    TESTING_DATA=$(echo "$SCAN_SUGGESTIONS" | jq -r '.testing')
    SECURITY_DATA=$(echo "$SCAN_SUGGESTIONS" | jq -r '.security')
    DOCS_DATA=$(echo "$SCAN_SUGGESTIONS" | jq -r '.documentation')
    ARCH_DATA=$(echo "$SCAN_SUGGESTIONS" | jq -r '.architecture')

    # Generate additional principles based on scan
    ADDITIONAL_PRINCIPLES=""

    # Parse testing data
    TEST_FILES=$(echo "$TESTING_DATA" | cut -d'|' -f1)
    TEST_FRAMEWORKS=$(echo "$TESTING_DATA" | cut -d'|' -f2)

    if [[ $TEST_FILES -gt 0 ]]; then
        ADDITIONAL_PRINCIPLES="${ADDITIONAL_PRINCIPLES}
### Tests Drive Confidence (Project Practice)
Automated testing is established with $TEST_FILES test files using $TEST_FRAMEWORKS. All features must maintain or improve test coverage. Refuse to ship when test suites fail."
    fi

    # Parse security data
    AUTH_PATTERNS=$(echo "$SECURITY_DATA" | cut -d'|' -f1)
    SECURITY_INDICATORS=$(echo "$SECURITY_DATA" | cut -d'|' -f3)

    if [[ $AUTH_PATTERNS -gt 0 || $SECURITY_INDICATORS -gt 0 ]]; then
        ADDITIONAL_PRINCIPLES="${ADDITIONAL_PRINCIPLES}
### Security by Default (Project Practice)
Security practices are established in the codebase. All features must include security considerations, input validation, and follow established security patterns."
    fi

    # Parse documentation data
    README_COUNT=$(echo "$DOCS_DATA" | cut -d'|' -f1)
    COMMENT_PERCENTAGE=$(echo "$DOCS_DATA" | cut -d'|' -f3)

    if [[ $README_COUNT -gt 0 ]]; then
        ADDITIONAL_PRINCIPLES="${ADDITIONAL_PRINCIPLES}
### Documentation Matters (Project Practice)
Documentation practices are established with $README_COUNT README files. All features must include appropriate documentation and maintain existing documentation standards."
    fi

    # Insert additional principles into constitution
    if [[ -n "$ADDITIONAL_PRINCIPLES" ]]; then
        # Find the end of core principles section and insert additional principles
        PROJECT_CONSTITUTION=$(echo "$PROJECT_CONSTITUTION" | sed "/## Additional Constraints/i\\
## Project-Specific Principles\\
$ADDITIONAL_PRINCIPLES")
    fi
fi

# Validate inheritance integrity
if ! $JSON_MODE; then
    validate_inheritance "$TEAM_CONSTITUTION" "$PROJECT_CONSTITUTION"
    echo ""
fi

# Write to file
echo "$PROJECT_CONSTITUTION" > "$CONSTITUTION_FILE"

# Output results
if $JSON_MODE; then
    printf '{"status":"created","file":"%s","team_directives":"%s"}\n' "$CONSTITUTION_FILE" "$TEAM_DIRECTIVES"
else
    echo "Constitution created at: $CONSTITUTION_FILE"
    echo "Team directives source: $TEAM_DIRECTIVES"
    echo ""
    echo "Next steps:"
    echo "1. Review and customize the constitution for your project needs"
    echo "2. Commit the constitution: git add .specify/memory/constitution.md && git commit -m 'docs: initialize project constitution'"
    echo "3. The constitution will be used by planning and implementation commands"
fi