#!/usr/bin/env bash
# validate-test-quality.sh - Validate test quality based on TDD principles

TEST_FILE="${1:-tests/}"

TEST_FILE="${1:-tests/}"

echo "Analyzing test quality in: $TEST_FILE"
echo "Based on TDD best practices:"
echo "- Vertical slicing: ONE test → ONE implementation"
echo "- Public interface testing, not implementation details"
echo "- Test WHAT (behavior), not HOW (implementation)"
echo ""

find_test_files() {
    if [[ -f "$TEST_FILE" ]]; then
        echo "$TEST_FILE"
    elif [[ -d "$TEST_FILE" ]]; then
        find "$TEST_FILE" -type f \( -name "test_*.py" -o -name "*_test.py" -o -name "*.test.ts" -o -name "*.test.js" -o -name "*_test.go" \) 2>/dev/null
    else
        echo "Test file/directory not found: $TEST_FILE"
        exit 1
    fi
}

analyze_file() {
    local file="$1"
    local score=0
    
    [[ ! -f "$file" ]] && return 0
    
    echo "Analyzing: $file"
    
    # ========================================
    # POSITIVE PATTERNS
    # ========================================
    
    # +10: Public interface tests (TDD: test what system does)
    grep -qE "^def test_|^func Test|describe\(|it\(|test\(" "$file" 2>/dev/null && score=$((score + 10))
    
    # +10: Behavior-focused assertions (TDD: test results, not side effects)
    grep -qE "assertEqual|assertEquals|assert.*==|expect.*toBe|should.*equal" "$file" 2>/dev/null && score=$((score + 10))
    
    # +5: Descriptive test names (TDD: read like specifications)
    grep -qE "def test_[a-z_]+|it\(['\"]" "$file" 2>/dev/null && score=$((score + 5))
    
    # +10: ONE BEHAVIOR PER TEST (vertical slicing
    local assertion_count
    assertion_count=$(grep -oE "assert |expect |should |t\.Errorf" "$file" 2>/dev/null | wc -l)
    if [[ -n "$assertion_count" ]] && [[ $assertion_count -le 3 ]]; then
        score=$((score + 10))
    fi
    
    # +10: EDGE CASE TESTS (simplest case first
    grep -qiE "empty|nil|zero|null|none|boundary|edge|limit|max|min|negative" "$file" 2>/dev/null && score=$((score + 10))
    
    # +10: TEST ISOLATION (no dependencies between tests)
    ! grep -qE "global |@beforeClass|setUpClass|conftest" "$file" 2>/dev/null && score=$((score + 10))
    
    # +5: AAA PATTERN
    grep -qE "# Arrange|# Act|# Assert|// Arrange|// Act|// Assert" "$file" 2>/dev/null && score=$((score + 5))
    
    # +5: ERROR/HAPPY PATH COVERAGE
    grep -qE "raises|throws|toThrow|Error|error|exception" "$file" 2>/dev/null && score=$((score + 5))
    
    # ========================================
    # ANTI-PATTERNS (TDD
    # ========================================
    
    # -15: Excessive mocking (TDD: mocks test imagined behavior)
    local mock_cnt
    mock_cnt=$(grep -cE "Mock|mock|MockObject|when\(|thenReturn\(|doReturn" "$file" 2>/dev/null)
    if [[ -n "$mock_cnt" ]] && [[ $mock_cnt -gt 3 ]]; then
        score=$((score - 15))
    fi
    
    # -15: Tests implementation details (TDD: break on refactors)
    grep -qE "private|_internal|__private" "$file" 2>/dev/null && score=$((score - 15))
    
    # -15: DB query tests (TDD: bypass interface)
    grep -qE "db\.query|SELECT.*FROM|executeQuery|sql.*select" "$file" 2>/dev/null && score=$((score - 15))
    
    # -15: Call count verification (TDD: verify HOW not WHAT)
    grep -qE "assertCalled|toHaveBeenCalled|toHaveBeenCalledTimes|assert_called" "$file" 2>/dev/null && score=$((score - 15))
    
    # -15: File system checks (TDD: bypass interface)
    grep -qE "exists\(|isfile\(|readFile\(|writeFile\(|new File\(.*\)" "$file" 2>/dev/null && score=$((score - 15))
    
    # -10: Brittle tests
    if [[ -n "$assertion_count" ]] && [[ $assertion_count -gt 10 ]]; then
        score=$((score - 10))
    fi
    
    # -10: Missing assertions (test without verification)
    local line_count
    line_count=$(wc -l < "$file" 2>/dev/null || echo "0")
    local assert_lines
    assert_lines=$(grep -cE "assert |expect |should |t\.Error" "$file" 2>/dev/null || echo "0")
    if [[ "$line_count" -gt 20 ]] && [[ "$assert_lines" -lt 2 ]]; then
        score=$((score - 10))
    fi
    
    [[ $score -lt 0 ]] && score=0
    
    echo "Score: $score/100"
    echo "$score" > /tmp/score_$$
    return 0
}

main() {
    local test_files
    test_files=$(find_test_files)
    
    [[ -z "$test_files" ]] && echo "No test files found." && return
    
    echo "Found test files:"
    echo "$test_files"
    echo ""
    
    local total_score=0
    local file_count=0
    
    rm -f /tmp/score_$$
    
    while IFS= read -r file; do
        [[ -z "$file" || ! -f "$file" ]] && continue
        file_count=$((file_count + 1))
        analyze_file "$file"
        if [[ -f /tmp/score_$$ ]]; then
            total_score=$((total_score + $(cat /tmp/score_$$)))
            rm -f /tmp/score_$$
        fi
    done <<< "$test_files"
    
    rm -f /tmp/score_$$
    
    [[ $file_count -eq 0 ]] && return
    
    local overall_score=$((total_score / file_count))
    
    echo "=========================================="
    echo "Overall Test Quality Score"
    echo "=========================================="
    echo ""
    echo "Files analyzed: $file_count"
    echo "Overall score: $overall_score/100"
    echo ""
    
    if [[ $overall_score -ge 90 ]]; then
        echo "Excellent test quality!"
        echo "- Vertical slicing compliant"
        echo "- Public interface testing"
        echo "- No implementation coupling"
    elif [[ $overall_score -ge 70 ]]; then
        echo "Good test quality"
    elif [[ $overall_score -ge 50 ]]; then
        echo "Acceptable test quality"
    else
        echo "Needs improvement"
        echo ""
        echo "Tips based on TDD + TDD best practices:"
        echo "1. Write ONE test → ONE implementation (vertical slicing)"
        echo "2. Test WHAT (behavior) through public interfaces"
        echo "3. Test edge cases (empty, nil, zero, boundaries)"
        echo "4. Avoid: mocking internals, call counts, DB queries"
        echo "5. Tests should survive refactors unchanged"
    fi
}

main