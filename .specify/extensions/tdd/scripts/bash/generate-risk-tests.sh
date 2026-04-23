#!/usr/bin/env bash
# generate-risk-tests.sh - Parse Risk Register and generate risk-based test tasks

set -euo pipefail

SPEC_FILE="${1:-spec.md}"
OUTPUT_FILE="${2:-}"

echo "Parsing Risk Register from: $SPEC_FILE"

parse_risks() {
    local spec_file="$1"
    
    if [[ ! -f "$spec_file" ]]; then
        echo "Error: spec file not found: $spec_file"
        return 1
    fi
    
    # Find Risk Register section
    if ! grep -q "^##.*Risk Register" "$spec_file"; then
        echo "No Risk Register section found in $spec_file"
        echo "Skipping risk-based test generation."
        return 0
    fi
    
    # Extract Risk Register content (handle case where Risk Register is last section)
    local risks
    risks=$(sed -n '/^##.*Risk Register/,/^##/p' "$spec_file" | grep -i "RISK:" || true)
    
    if [[ -z "$risks" ]]; then
        echo "No risk entries found in Risk Register"
        return 0
    fi
    
    echo "Found risk entries:"
    echo ""
    
    local counter=1
    echo "$risks" | while read -r line; do
        # Parse: RISK: [name] | Severity: [High/Medium/Low] | Impact: [what] | Test: [specific test]
        local risk_name severity impact test_desc
        
        risk_name=$(echo "$line" | sed -n 's/.*RISK: \([^|]*\).*/\1/p' | xargs)
        severity=$(echo "$line" | sed -n 's/.*Severity: \([^|]*\).*/\1/p' | xargs)
        impact=$(echo "$line" | sed -n 's/.*Impact: \([^|]*\).*/\1/p' | xargs)
        test_desc=$(echo "$line" | sed -n 's/.*| Test: \([^|]*\).*/\1/p' | xargs)
        
        if [[ -n "$test_desc" ]]; then
            echo "- [ ] TDD-R$(printf "%02d" $counter) [RISK] $test_desc"
            counter=$((counter + 1))
        fi
    done
}

generate_risk_tests() {
    local spec_file="$1"
    local output_file="$2"
    
    local risks_output
    risks_output=$(parse_risks "$spec_file")
    
    if [[ -n "$output_file" ]]; then
        cat > "$output_file" << EOF
# Risk-Based Test Tasks
# Generated from Risk Register in $spec_file

$risks_output

EOF
        echo "Risk tests written to: $output_file"
    else
        echo "$risks_output"
    fi
}

# Run generation
if [[ -n "$OUTPUT_FILE" ]]; then
    generate_risk_tests "$SPEC_FILE" "$OUTPUT_FILE"
else
    generate_risk_tests "$SPEC_FILE" ""
fi