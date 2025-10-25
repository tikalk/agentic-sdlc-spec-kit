#!/usr/bin/env bash

# Analyze AI session context for team-ai-directives contributions
# This script evaluates AI agent session context packets for potential
# contributions to team-ai-directives components: rules, constitution,
# personas, and examples.

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
            echo "Usage: $0 [--json] [--amendment] [--validate] <ai_session_context_file>"
            echo "  --json        Output results in JSON format"
            echo "  --amendment   Generate team-ai-directives contribution proposals"
            echo "  --validate    Validate directives contributions"
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

# Function to analyze AI session context for team-ai-directives contributions
analyze_team_directives_contributions() {
    local context_file="$1"

    if [[ ! -f "$context_file" ]]; then
        echo "ERROR: AI session context file not found: $context_file"
        exit 1
    fi

    # Read the context file
    local content=""
    content=$(cat "$context_file")

    # Extract different sections for analysis
    local session_overview=""
    session_overview=$(echo "$content" | sed -n '/## Session Overview/,/^## /p' | head -n -1)

    local decision_patterns=""
    decision_patterns=$(echo "$content" | sed -n '/## Decision Patterns/,/^## /p' | head -n -1)

    local execution_context=""
    execution_context=$(echo "$content" | sed -n '/## Execution Context/,/^## /p' | head -n -1)

    local reusable_patterns=""
    reusable_patterns=$(echo "$content" | sed -n '/## Reusable Patterns/,/^## /p' | head -n -1)

    # Analyze for different component contributions
    local constitution_score=0
    local rules_score=0
    local personas_score=0
    local examples_score=0

    local constitution_keywords=("must" "shall" "required" "mandatory" "always" "never" "principle" "governance" "policy" "standard" "quality" "security" "testing" "documentation" "architecture" "compliance" "oversight" "review" "approval")
    local rules_keywords=("agent" "behavior" "interaction" "decision" "pattern" "approach" "strategy" "methodology" "tool" "execution")
    local personas_keywords=("role" "specialization" "capability" "expertise" "persona" "assistant" "specialist" "focus")
    local examples_keywords=("example" "case" "study" "implementation" "usage" "reference" "demonstration" "scenario")

    # Analyze constitution relevance
    for keyword in "${constitution_keywords[@]}"; do
        if echo "$content" | grep -qi "$keyword"; then
            constitution_score=$((constitution_score + 1))
        fi
    done

    # Analyze rules relevance
    for keyword in "${rules_keywords[@]}"; do
        if echo "$decision_patterns $reusable_patterns" | grep -qi "$keyword"; then
            rules_score=$((rules_score + 1))
        fi
    done

    # Analyze personas relevance
    for keyword in "${personas_keywords[@]}"; do
        if echo "$session_overview $execution_context" | grep -qi "$keyword"; then
            personas_score=$((personas_score + 1))
        fi
    done

    # Analyze examples relevance
    for keyword in "${examples_keywords[@]}"; do
        if echo "$execution_context $reusable_patterns" | grep -qi "$keyword"; then
            examples_score=$((examples_score + 1))
        fi
    done

    # Check for imperative language patterns (constitution)
    if echo "$content" | grep -q "^[[:space:]]*-[[:space:]]*[A-Z][a-z]*.*must\|shall\|should\|will"; then
        constitution_score=$((constitution_score + 2))
    fi

    # Return analysis results: constitution|rules|personas|examples|content_sections
    echo "$constitution_score|$rules_score|$personas_score|$examples_score|$session_overview|$decision_patterns|$execution_context|$reusable_patterns"
}

# Function to generate team-ai-directives proposals
generate_directives_proposals() {
    local context_file="$1"
    local analysis_result="$2"

    local constitution_score="" rules_score="" personas_score="" examples_score=""
    local session_overview="" decision_patterns="" execution_context="" reusable_patterns=""

    IFS='|' read -r constitution_score rules_score personas_score examples_score session_overview decision_patterns execution_context reusable_patterns <<< "$analysis_result"

    # Extract feature name from file path
    local feature_name=""
    feature_name=$(basename "$context_file" | sed 's/-session\.md$//')

    local proposals=""

    # Generate constitution amendment if relevant
    if [[ $constitution_score -ge 3 ]]; then
        local amendment_title=""
        amendment_title=$(echo "$session_overview" | head -3 | grep -v "^#" | head -1 | sed 's/^[[:space:]]*-[[:space:]]*//' | cut -c1-50)

        if [[ -z "$amendment_title" ]]; then
            amendment_title="Constitution Amendment from $feature_name"
        fi

        proposals="${proposals}**CONSTITUTION AMENDMENT PROPOSAL**

**Proposed Principle:** $amendment_title

**Description:**
$(echo "$session_overview" | sed 's/^#/###/')

**Rationale:** This principle was derived from AI agent session in feature '$feature_name'. The approach demonstrated governance and quality considerations that should be codified.

**Evidence:** See AI session context at $context_file

**Impact Assessment:**
- Adds new governance requirement for AI agent sessions
- May require updates to agent behavior guidelines
- Enhances project quality and consistency
- Should be reviewed by team before adoption

---
"
    fi

    # Generate rules proposal if relevant
    if [[ $rules_score -ge 2 ]]; then
        proposals="${proposals}**RULES CONTRIBUTION**

**Proposed Rule:** AI Agent Decision Pattern from $feature_name

**Pattern Description:**
$(echo "$decision_patterns" | sed 's/^#/###/')

**When to Apply:** Use this decision pattern when facing similar challenges in $feature_name-type features.

**Evidence:** See AI session context at $context_file

---
"
    fi

    # Generate personas proposal if relevant
    if [[ $personas_score -ge 2 ]]; then
        proposals="${proposals}**PERSONA DEFINITION**

**Proposed Persona:** Specialized Agent for $feature_name-type Features

**Capabilities Demonstrated:**
$(echo "$execution_context" | sed 's/^#/###/')

**Specialization:** $feature_name implementation and similar complex feature development.

**Evidence:** See AI session context at $context_file

---
"
    fi

    # Generate examples proposal if relevant
    if [[ $examples_score -ge 2 ]]; then
        proposals="${proposals}**EXAMPLE CONTRIBUTION**

**Example:** $feature_name Implementation Approach

**Scenario:** Complete feature development from spec to deployment.

**Approach Used:**
$(echo "$reusable_patterns" | sed 's/^#/###/')

**Outcome:** Successful implementation with quality gates passed.

**Evidence:** See AI session context at $context_file

---
"
    fi

    if [[ -z "$proposals" ]]; then
        echo "No significant team-ai-directives contributions identified from this session."
        return 1
    fi

    echo "$proposals"
}

# Function to validate directives contributions
validate_directives_contributions() {
    local contributions="$1"
    local constitution_file="$REPO_ROOT/.specify/memory/constitution.md"

    # For now, just check constitution conflicts if constitution file exists
    # Future enhancement: check for conflicts in rules, personas, examples
    if [[ ! -f "$constitution_file" ]]; then
        echo "WARNING: No project constitution found at $constitution_file"
        return 0
    fi

    local constitution_content=""
    constitution_content=$(cat "$constitution_file")

    # Check for conflicts with existing principles (constitution amendments only)
    local conflicts=()

    # Extract constitution amendment if present
    local constitution_section=""
    constitution_section=$(echo "$contributions" | sed -n '/\*\*CONSTITUTION AMENDMENT PROPOSAL\*\*/,/---/p' | head -n -1)

    if [[ -n "$constitution_section" ]]; then
        local amendment_principle=""
        amendment_principle=$(echo "$constitution_section" | grep "^\*\*Proposed Principle:\*\*" | sed 's/.*: //' | head -1)

        # Check if similar principle already exists
        if echo "$constitution_content" | grep -qi "$amendment_principle"; then
            conflicts+=("Similar constitution principle already exists: $amendment_principle")
        fi

        # Check for contradictory language
        local amendment_rules=""
        amendment_rules=$(echo "$constitution_section" | sed -n '/^\*\*Description:\*\*/,/^\*\*Rationale:\*\*/p' | grep -E "^[[:space:]]*-[[:space:]]*[A-Z]")

        for rule in $amendment_rules; do
            # Look for contradictions in existing constitution
            if echo "$constitution_content" | grep -qi "never.*$(echo "$rule" | sed 's/.* //')" || echo "$constitution_content" | grep -qi "must not.*$(echo "$rule" | sed 's/.* //')"; then
                conflicts+=("Potential contradiction with existing constitution rule: $rule")
            fi
        done
    fi

    if [[ ${#conflicts[@]} -gt 0 ]]; then
        echo "VALIDATION ISSUES:"
        for conflict in "${conflicts[@]}"; do
            echo "  - $conflict"
        done
        return 1
    else
        echo "✓ Directives contributions validation passed - no conflicts detected"
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
        echo "ERROR: Must specify directives contributions file for validation"
        exit 1
    fi

    contributions_content=$(cat "$KNOWLEDGE_FILE")
    if validate_directives_contributions "$contributions_content"; then
        if $JSON_MODE; then
            printf '{"status":"valid","file":"%s"}\n' "$KNOWLEDGE_FILE"
        else
            echo "Directives contributions validation successful"
        fi
    else
        if $JSON_MODE; then
            printf '{"status":"invalid","file":"%s"}\n' "$KNOWLEDGE_FILE"
        else
            echo "Directives contributions validation failed"
        fi
        exit 1
    fi
    exit 0
fi

if $AMENDMENT_MODE; then
    if [[ -z "$KNOWLEDGE_FILE" ]]; then
        echo "ERROR: Must specify AI session context file for directives proposals"
        exit 1
    fi

    analysis=$(analyze_team_directives_contributions "$KNOWLEDGE_FILE")
    proposals=$(generate_directives_proposals "$KNOWLEDGE_FILE" "$analysis")

    if [[ $? -eq 0 ]]; then
        if $JSON_MODE; then
            printf '{"status":"proposed","file":"%s","proposals":%s}\n' "$KNOWLEDGE_FILE" "$(echo "$proposals" | jq -R -s .)"
        else
            echo "Team-AI-Directives Contribution Proposals:"
            echo "=========================================="
            echo "$proposals"
            echo ""
            echo "To apply these contributions, run:"
            echo "  directives-update --file proposals.md"
        fi
    else
        if $JSON_MODE; then
            printf '{"status":"no_contributions","file":"%s"}\n' "$KNOWLEDGE_FILE"
        else
            echo "$proposals"
        fi
    fi
    exit 0
fi

# Default: analyze mode
analysis=$(analyze_team_directives_contributions "$KNOWLEDGE_FILE")

if $JSON_MODE; then
    constitution_score=$(echo "$analysis" | cut -d'|' -f1)
    rules_score=$(echo "$analysis" | cut -d'|' -f2)
    personas_score=$(echo "$analysis" | cut -d'|' -f3)
    examples_score=$(echo "$analysis" | cut -d'|' -f4)
    printf '{"file":"%s","constitution_score":%d,"rules_score":%d,"personas_score":%d,"examples_score":%d}\n' "$KNOWLEDGE_FILE" "$constitution_score" "$rules_score" "$personas_score" "$examples_score"
else
    constitution_score=$(echo "$analysis" | cut -d'|' -f1)
    rules_score=$(echo "$analysis" | cut -d'|' -f2)
    personas_score=$(echo "$analysis" | cut -d'|' -f3)
    examples_score=$(echo "$analysis" | cut -d'|' -f4)

    echo "Team-AI-Directives Contribution Analysis for: $KNOWLEDGE_FILE"
    echo "Constitution Score: $constitution_score/10"
    echo "Rules Score: $rules_score/5"
    echo "Personas Score: $personas_score/5"
    echo "Examples Score: $examples_score/5"

    local has_contributions=false
    if [[ $constitution_score -ge 3 ]]; then
        echo "✓ Constitution contribution potential detected"
        has_contributions=true
    fi
    if [[ $rules_score -ge 2 ]]; then
        echo "✓ Rules contribution potential detected"
        has_contributions=true
    fi
    if [[ $personas_score -ge 2 ]]; then
        echo "✓ Personas contribution potential detected"
        has_contributions=true
    fi
    if [[ $examples_score -ge 2 ]]; then
        echo "✓ Examples contribution potential detected"
        has_contributions=true
    fi

    if [[ "$has_contributions" == true ]]; then
        echo "Run with --amendment to generate contribution proposals"
    else
        echo "ℹ No significant team-ai-directives contributions identified"
    fi
fi