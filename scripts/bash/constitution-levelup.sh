#!/usr/bin/env bash

set -e

JSON_MODE=false
AMENDMENT_MODE=false
VALIDATE_MODE=false

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --amendment)
            AMENDMENT_MODE=true
            ;;
        --validate)
            VALIDATE_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [--json] [--amendment] [--validate] <knowledge_asset_file>"
            echo "  --json        Output results in JSON format"
            echo "  --amendment   Generate constitution amendment proposal"
            echo "  --validate    Validate constitution amendment"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            KNOWLEDGE_FILE="$arg"
            ;;
    esac
done

# Get script directory and load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

eval $(get_feature_paths)

# Function to analyze knowledge asset for constitution-relevant rules
analyze_constitution_relevance() {
    local knowledge_file="$1"

    if [[ ! -f "$knowledge_file" ]]; then
        echo "ERROR: Knowledge asset file not found: $knowledge_file"
        exit 1
    fi

    # Read the knowledge asset
    local content=""
    content=$(cat "$knowledge_file")

    # Extract the reusable rule/best practice section
    local rule_section=""
    rule_section=$(echo "$content" | sed -n '/## Reusable rule or best practice/,/^## /p' | head -n -1)

    if [[ -z "$rule_section" ]]; then
        rule_section=$(echo "$content" | sed -n '/### Reusable rule or best practice/,/^## /p' | head -n -1)
    fi

    # Keywords that indicate constitution-level significance
    local constitution_keywords=(
        "must" "shall" "required" "mandatory" "always" "never"
        "principle" "governance" "policy" "standard" "quality"
        "security" "testing" "documentation" "architecture"
        "compliance" "oversight" "review" "approval"
    )

    local relevance_score=0
    local matched_keywords=()

    for keyword in "${constitution_keywords[@]}"; do
        if echo "$rule_section" | grep -qi "$keyword"; then
            relevance_score=$((relevance_score + 1))
            matched_keywords+=("$keyword")
        fi
    done

    # Check for imperative language patterns
    if echo "$rule_section" | grep -q "^[[:space:]]*-[[:space:]]*[A-Z][a-z]*.*must\|shall\|should\|will"; then
        relevance_score=$((relevance_score + 2))
    fi

    # Return analysis results
    echo "$relevance_score|${matched_keywords[*]}|$rule_section"
}

# Function to generate constitution amendment proposal
generate_amendment_proposal() {
    local knowledge_file="$1"
    local analysis_result="$2"

    local relevance_score=""
    local matched_keywords=""
    local rule_section=""

    IFS='|' read -r relevance_score matched_keywords rule_section <<< "$analysis_result"

    if [[ $relevance_score -lt 3 ]]; then
        echo "Rule does not appear constitution-level (score: $relevance_score)"
        return 1
    fi

    # Extract feature name from file path
    local feature_name=""
    feature_name=$(basename "$knowledge_file" | sed 's/-levelup\.md$//')

    # Generate amendment proposal
    local amendment_title=""
    local amendment_description=""

    # Try to extract a concise title from the rule
    amendment_title=$(echo "$rule_section" | head -3 | grep -v "^#" | head -1 | sed 's/^[[:space:]]*-[[:space:]]*//' | cut -c1-50)

    if [[ -z "$amendment_title" ]]; then
        amendment_title="Amendment from $feature_name"
    fi

    # Create full amendment description
    amendment_description="**Proposed Principle:** $amendment_title

**Description:**
$(echo "$rule_section" | sed 's/^#/###/')

**Rationale:** This principle was derived from successful implementation of feature '$feature_name'. The rule addresses $(echo "$matched_keywords" | tr ' ' ', ') considerations identified during development.

**Evidence:** See knowledge asset at $knowledge_file

**Impact Assessment:**
- Adds new governance requirement
- May require updates to existing processes
- Enhances project quality/consistency
- Should be reviewed by team before adoption"

    echo "$amendment_description"
}

# Function to validate amendment against existing constitution
validate_amendment() {
    local amendment="$1"
    local constitution_file="$REPO_ROOT/.specify/memory/constitution.md"

    if [[ ! -f "$constitution_file" ]]; then
        echo "WARNING: No project constitution found at $constitution_file"
        return 0
    fi

    local constitution_content=""
    constitution_content=$(cat "$constitution_file")

    # Check for conflicts with existing principles
    local conflicts=()

    # Extract principle names from amendment
    local amendment_principle=""
    amendment_principle=$(echo "$amendment" | grep "^\*\*Proposed Principle:\*\*" | sed 's/.*: //' | head -1)

    # Check if similar principle already exists
    if echo "$constitution_content" | grep -qi "$amendment_principle"; then
        conflicts+=("Similar principle already exists: $amendment_principle")
    fi

    # Check for contradictory language
    local amendment_rules=""
    amendment_rules=$(echo "$amendment" | sed -n '/^\*\*Description:\*\*/,/^\*\*Rationale:\*\*/p' | grep -E "^[[:space:]]*-[[:space:]]*[A-Z]")

    for rule in $amendment_rules; do
        # Look for contradictions in existing constitution
        if echo "$constitution_content" | grep -qi "never.*$(echo "$rule" | sed 's/.* //')" || echo "$constitution_content" | grep -qi "must not.*$(echo "$rule" | sed 's/.* //')"; then
            conflicts+=("Potential contradiction with existing rule: $rule")
        fi
    done

    if [[ ${#conflicts[@]} -gt 0 ]]; then
        echo "VALIDATION ISSUES:"
        for conflict in "${conflicts[@]}"; do
            echo "  - $conflict"
        done
        return 1
    else
        echo "✓ Amendment validation passed - no conflicts detected"
        return 0
    fi
}

# Main logic
if [[ -z "$KNOWLEDGE_FILE" && $AMENDMENT_MODE == false && $VALIDATE_MODE == false ]]; then
    echo "ERROR: Must specify knowledge asset file or use --amendment/--validate mode"
    exit 1
fi

if $VALIDATE_MODE; then
    if [[ -z "$KNOWLEDGE_FILE" ]]; then
        echo "ERROR: Must specify amendment file for validation"
        exit 1
    fi

    amendment_content=$(cat "$KNOWLEDGE_FILE")
    if validate_amendment "$amendment_content"; then
        if $JSON_MODE; then
            printf '{"status":"valid","file":"%s"}\n' "$KNOWLEDGE_FILE"
        else
            echo "Amendment validation successful"
        fi
    else
        if $JSON_MODE; then
            printf '{"status":"invalid","file":"%s"}\n' "$KNOWLEDGE_FILE"
        else
            echo "Amendment validation failed"
        fi
        exit 1
    fi
    exit 0
fi

if $AMENDMENT_MODE; then
    if [[ -z "$KNOWLEDGE_FILE" ]]; then
        echo "ERROR: Must specify knowledge asset file for amendment generation"
        exit 1
    fi

    analysis=$(analyze_constitution_relevance "$KNOWLEDGE_FILE")
    proposal=$(generate_amendment_proposal "$KNOWLEDGE_FILE" "$analysis")

    if [[ $? -eq 0 ]]; then
        if $JSON_MODE; then
            printf '{"status":"proposed","file":"%s","proposal":%s}\n' "$KNOWLEDGE_FILE" "$(echo "$proposal" | jq -R -s .)"
        else
            echo "Constitution Amendment Proposal:"
            echo "================================="
            echo "$proposal"
            echo ""
            echo "To apply this amendment, run:"
            echo "  constitution-amend --file amendment.md"
        fi
    else
        if $JSON_MODE; then
            printf '{"status":"not_constitution_level","file":"%s"}\n' "$KNOWLEDGE_FILE"
        else
            echo "$proposal"
        fi
    fi
    exit 0
fi

# Default: analyze mode
analysis=$(analyze_constitution_relevance "$KNOWLEDGE_FILE")

if $JSON_MODE; then
    relevance_score=$(echo "$analysis" | cut -d'|' -f1)
    matched_keywords=$(echo "$analysis" | cut -d'|' -f2)
    printf '{"file":"%s","relevance_score":%d,"matched_keywords":"%s"}\n' "$KNOWLEDGE_FILE" "$relevance_score" "$matched_keywords"
else
    relevance_score=$(echo "$analysis" | cut -d'|' -f1)
    matched_keywords=$(echo "$analysis" | cut -d'|' -f2)

    echo "Constitution Relevance Analysis for: $KNOWLEDGE_FILE"
    echo "Relevance Score: $relevance_score/10"
    echo "Matched Keywords: $matched_keywords"

    if [[ $relevance_score -ge 3 ]]; then
        echo "✓ This learning appears constitution-level"
        echo "Run with --amendment to generate a proposal"
    else
        echo "ℹ This learning appears project-level, not constitution-level"
    fi
fi