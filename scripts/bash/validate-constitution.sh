#!/usr/bin/env bash

set -e

JSON_MODE=false
STRICT_MODE=false
COMPLIANCE_MODE=false

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --strict)
            STRICT_MODE=true
            ;;
        --compliance)
            COMPLIANCE_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [--json] [--strict] [--compliance] [constitution_file]"
            echo "  --json        Output results in JSON format"
            echo "  --strict      Perform strict validation (fail on warnings)"
            echo "  --compliance  Check compliance with team directives"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            CONSTITUTION_FILE="$arg"
            ;;
    esac
done

# Get script directory and load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

eval $(get_feature_paths)

# Default constitution file
if [[ -z "$CONSTITUTION_FILE" ]]; then
    CONSTITUTION_FILE="$REPO_ROOT/.specify/memory/constitution.md"
fi

# Validation result structure
VALIDATION_RESULTS="{}"

# Function to add validation result
add_validation_result() {
    local category="$1"
    local check="$2"
    local status="$3"
    local message="$4"

    VALIDATION_RESULTS=$(echo "$VALIDATION_RESULTS" | jq ".${category} += [{\"check\": \"$check\", \"status\": \"$status\", \"message\": \"$message\"}]")
}

# Function to validate constitution file exists
validate_file_exists() {
    if [[ ! -f "$CONSTITUTION_FILE" ]]; then
        add_validation_result "critical" "file_exists" "fail" "Constitution file not found at $CONSTITUTION_FILE"
        return 1
    fi
    add_validation_result "basic" "file_exists" "pass" "Constitution file found"
    return 0
}

# Function to validate basic structure
validate_basic_structure() {
    local content="$1"

    # Check for required sections
    if ! echo "$content" | grep -q "^# .* Constitution"; then
        add_validation_result "structure" "title" "fail" "Constitution must have a title starting with '# ... Constitution'"
        return 1
    fi
    add_validation_result "structure" "title" "pass" "Title format correct"

    if ! echo "$content" | grep -q "^## Core Principles"; then
        add_validation_result "structure" "core_principles" "fail" "Constitution must have '## Core Principles' section"
        return 1
    fi
    add_validation_result "structure" "core_principles" "pass" "Core Principles section present"

    if ! echo "$content" | grep -q "^##.*Governance"; then
        add_validation_result "structure" "governance" "fail" "Constitution must have a Governance section"
        return 1
    fi
    add_validation_result "structure" "governance" "pass" "Governance section present"
}

# Function to validate principle quality
validate_principle_quality() {
    local content="$1"

    # Extract principles (lines starting with ###)
    local principles=""
    principles=$(echo "$content" | grep "^### " | sed 's/^### //')

    local principle_count=0
    while IFS= read -r principle; do
        if [[ -n "$principle" ]]; then
            ((principle_count++))

            # Check principle name quality
            if [[ ${#principle} -lt 10 ]]; then
                add_validation_result "quality" "principle_name_length" "warn" "Principle '$principle' name is very short"
            elif [[ ${#principle} -gt 80 ]]; then
                add_validation_result "quality" "principle_name_length" "warn" "Principle '$principle' name is very long"
            else
                add_validation_result "quality" "principle_name_length" "pass" "Principle '$principle' name length appropriate"
            fi

            # Check for vague language
            if echo "$principle" | grep -qi "should\|may\|might\|try\|consider"; then
                add_validation_result "quality" "principle_clarity" "warn" "Principle '$principle' contains vague language (should/may/might/try/consider)"
            else
                add_validation_result "quality" "principle_clarity" "pass" "Principle '$principle' uses clear language"
            fi
        fi
    done <<< "$principles"

    if [[ $principle_count -lt 3 ]]; then
        add_validation_result "quality" "principle_count" "warn" "Only $principle_count principles found (recommended: 3-7)"
    elif [[ $principle_count -gt 10 ]]; then
        add_validation_result "quality" "principle_count" "warn" "$principle_count principles found (consider consolidating)"
    else
        add_validation_result "quality" "principle_count" "pass" "$principle_count principles (appropriate range)"
    fi
}

# Function to validate versioning
validate_versioning() {
    local content="$1"

    # Check for version line
    if ! echo "$content" | grep -q "\*\*Version\*\*:"; then
        add_validation_result "versioning" "version_present" "fail" "Version information not found"
        return 1
    fi
    add_validation_result "versioning" "version_present" "pass" "Version information present"

    # Extract version
    local version=""
    version=$(echo "$content" | grep "\*\*Version\*\*:" | sed 's/.*Version\*\*: *\([0-9.]*\).*/\1/')

    if [[ -z "$version" ]]; then
        add_validation_result "versioning" "version_format" "fail" "Could not parse version number"
        return 1
    fi

    # Check semantic versioning format
    if ! echo "$version" | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+$"; then
        add_validation_result "versioning" "version_format" "warn" "Version '$version' does not follow semantic versioning (X.Y.Z)"
    else
        add_validation_result "versioning" "version_format" "pass" "Version follows semantic versioning"
    fi

    # Check dates
    local ratified_date=""
    local amended_date=""

    ratified_date=$(echo "$content" | grep "\*\*Ratified\*\*:" | sed 's/.*Ratified\*\*: *\([0-9-]*\).*/\1/')
    amended_date=$(echo "$content" | grep "\*\*Last Amended\*\*:" | sed 's/.*Last Amended\*\*: *\([0-9-]*\).*/\1/')

    if [[ -z "$ratified_date" ]]; then
        add_validation_result "versioning" "ratified_date" "fail" "Ratification date not found"
    elif ! echo "$ratified_date" | grep -q "^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$"; then
        add_validation_result "versioning" "ratified_date" "warn" "Ratification date '$ratified_date' not in YYYY-MM-DD format"
    else
        add_validation_result "versioning" "ratified_date" "pass" "Ratification date format correct"
    fi

    if [[ -z "$amended_date" ]]; then
        add_validation_result "versioning" "amended_date" "fail" "Last amended date not found"
    elif ! echo "$amended_date" | grep -q "^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$"; then
        add_validation_result "versioning" "amended_date" "warn" "Last amended date '$amended_date' not in YYYY-MM-DD format"
    else
        add_validation_result "versioning" "amended_date" "pass" "Last amended date format correct"
    fi
}

# Function to validate team compliance
validate_team_compliance() {
    local content="$1"

    # Load team constitution
    local team_constitution=""
    if [[ -n "$TEAM_DIRECTIVES" && -d "$TEAM_DIRECTIVES" ]]; then
        if [[ -f "$TEAM_DIRECTIVES/constitution.md" ]]; then
            team_constitution=$(cat "$TEAM_DIRECTIVES/constitution.md")
        elif [[ -f "$TEAM_DIRECTIVES/context_modules/constitution.md" ]]; then
            team_constitution=$(cat "$TEAM_DIRECTIVES/context_modules/constitution.md")
        fi
    fi

    if [[ -z "$team_constitution" ]]; then
        add_validation_result "compliance" "team_constitution" "warn" "Team constitution not found - cannot validate compliance"
        return 0
    fi

    add_validation_result "compliance" "team_constitution" "pass" "Team constitution found"

    # Extract team principles
    local team_principles=""
    team_principles=$(echo "$team_constitution" | grep "^[0-9]\+\. \*\*.*\*\*" | sed 's/^[0-9]\+\. \*\{2\}\(.*\)\*\{2\}.*/\1/')

    # Check each team principle is represented
    local missing_principles=""
    while IFS= read -r principle; do
        if [[ -n "$principle" ]]; then
            if ! echo "$content" | grep -qi "$principle"; then
                missing_principles="$missing_principles$principle, "
            fi
        fi
    done <<< "$team_principles"

    if [[ -n "$missing_principles" ]]; then
        add_validation_result "compliance" "team_principles" "fail" "Missing team principles: ${missing_principles%, }"
    else
        add_validation_result "compliance" "team_principles" "pass" "All team principles represented"
    fi
}

# Function to check for conflicts
validate_conflicts() {
    local content="$1"

    # Look for contradictory terms
    local contradictions_found=0

    if echo "$content" | grep -qi "must.*never\|never.*must\|required.*forbidden\|forbidden.*required"; then
        add_validation_result "conflicts" "contradictory_terms" "warn" "Found potentially contradictory terms (must/never, required/forbidden)"
        ((contradictions_found++))
    fi

    # Check for duplicate principles
    local principle_names=""
    principle_names=$(echo "$content" | grep "^### " | sed 's/^### //' | tr '[:upper:]' '[:lower:]')

    local duplicates=""
    while IFS= read -r name; do
        if [[ -n "$name" ]]; then
            local count=""
            count=$(echo "$principle_names" | grep -c "^$name$")
            if [[ $count -gt 1 ]]; then
                duplicates="$duplicates$name, "
            fi
        fi
    done <<< "$principle_names"

    if [[ -n "$duplicates" ]]; then
        add_validation_result "conflicts" "duplicate_principles" "warn" "Duplicate principle names found: ${duplicates%, }"
        ((contradictions_found++))
    fi

    if [[ $contradictions_found -eq 0 ]]; then
        add_validation_result "conflicts" "no_conflicts" "pass" "No obvious conflicts detected"
    fi
}

# Main validation logic
if ! validate_file_exists; then
    if $JSON_MODE; then
        echo "$VALIDATION_RESULTS"
    else
        echo "CRITICAL: Constitution file not found"
        exit 1
    fi
fi

# Read constitution content
CONTENT=$(cat "$CONSTITUTION_FILE")

# Initialize validation results
VALIDATION_RESULTS=$(jq -n '{}')

# Run validations
validate_basic_structure "$CONTENT"
validate_principle_quality "$CONTENT"
validate_versioning "$CONTENT"

if $COMPLIANCE_MODE; then
    validate_team_compliance "$CONTENT"
fi

validate_conflicts "$CONTENT"

# Calculate overall status
CRITICAL_FAILS=$(echo "$VALIDATION_RESULTS" | jq '[.critical[]? | select(.status == "fail")] | length')
STRUCTURE_FAILS=$(echo "$VALIDATION_RESULTS" | jq '[.structure[]? | select(.status == "fail")] | length')
QUALITY_FAILS=$(echo "$VALIDATION_RESULTS" | jq '[.quality[]? | select(.status == "fail")] | length')
VERSIONING_FAILS=$(echo "$VALIDATION_RESULTS" | jq '[.versioning[]? | select(.status == "fail")] | length')
COMPLIANCE_FAILS=$(echo "$VALIDATION_RESULTS" | jq '[.compliance[]? | select(.status == "fail")] | length')

TOTAL_FAILS=$((CRITICAL_FAILS + STRUCTURE_FAILS + QUALITY_FAILS + VERSIONING_FAILS + COMPLIANCE_FAILS))

if [[ $TOTAL_FAILS -gt 0 ]]; then
    OVERALL_STATUS="fail"
elif $STRICT_MODE && echo "$VALIDATION_RESULTS" | jq -e '[.[]?[]? | select(.status == "warn")] | length > 0' > /dev/null; then
    OVERALL_STATUS="fail"
else
    OVERALL_STATUS="pass"
fi

VALIDATION_RESULTS=$(echo "$VALIDATION_RESULTS" | jq ".overall = \"$OVERALL_STATUS\"")

# Output results
if $JSON_MODE; then
    echo "$VALIDATION_RESULTS"
else
    echo "Constitution Validation Results for: $CONSTITUTION_FILE"
    echo "Overall Status: $(echo "$OVERALL_STATUS" | tr '[:lower:]' '[:upper:]')"
    echo ""

    # Display results by category
    for category in critical structure quality versioning compliance conflicts; do
        if echo "$VALIDATION_RESULTS" | jq -e ".${category}" > /dev/null 2>&1; then
            echo "$category checks:"
            echo "$VALIDATION_RESULTS" | jq -r ".${category}[]? | \"  [\(.status | ascii_upcase)] \(.check): \(.message)\""
            echo ""
        fi
    done

    if [[ "$OVERALL_STATUS" == "fail" ]]; then
        echo "❌ Validation failed - address the issues above"
        exit 1
    else
        echo "✅ Validation passed"
    fi
fi