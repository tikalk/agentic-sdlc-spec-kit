#!/usr/bin/env python3
"""
Unit tests for {{CRITERION_NAME}} Grader
Generated from goldset criterion: {{CRITERION_ID}}
EDD Principle II: Binary pass/fail testing only

Template Variables:
- {{CRITERION_ID}}: Goldset criterion identifier (e.g., eval-001)
- {{CRITERION_NAME}}: Human-readable criterion name
- {{GRADER_FUNCTION_NAME}}: Function name for the grader (e.g., check_pii_leakage)
- {{GRADER_MODULE_NAME}}: Module name containing the grader
- {{PASS_CONDITION}}: Precise specification for passing evaluation
- {{FAIL_CONDITION}}: Precise specification for failing evaluation
- {{PASS_EXAMPLES}}: List of example inputs that should pass
- {{FAIL_EXAMPLES}}: List of example inputs that should fail
"""

import sys
import pytest
from pathlib import Path

# Make the graders importable without installing the evals package
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "evals" / "graders"))

# Import the specific grader function
try:
    from {{GRADER_MODULE_NAME}} import {{GRADER_FUNCTION_NAME}}
except ImportError:
    pytest.skip(f"Grader module {{GRADER_MODULE_NAME}} not found", allow_module_level=True)

CTX = {}  # Empty context - graders accept but don't require context


class Test{{GRADER_FUNCTION_NAME|pascal_case}}:
    """
    Test class for {{CRITERION_NAME}} grader.

    Tests both positive (pass) and negative (fail) cases based on:
    - Pass: {{PASS_CONDITION}}
    - Fail: {{FAIL_CONDITION}}
    """

    # ─────────────────────────────────────────────
    # Positive Test Cases (Should Pass)
    # ─────────────────────────────────────────────

{{#each PASS_EXAMPLES}}
    def test_{{@index}}_{{this.name}}_passes(self):
        """Test case: {{this.description}}"""
        output = """{{this.content}}"""
        result = {{GRADER_FUNCTION_NAME}}(output, CTX)

        assert result["pass"] is True, f"Expected pass but got fail: {result['reason']}"
        assert result["score"] == 1.0, f"Expected score 1.0 but got {result['score']}"
        assert "binary" in result and result["binary"] is True, "Result must be binary"
        assert "criterion" in result and result["criterion"] == "{{CRITERION_ID}}", "Must include criterion ID"

{{/each}}

    # ─────────────────────────────────────────────
    # Negative Test Cases (Should Fail)
    # ─────────────────────────────────────────────

{{#each FAIL_EXAMPLES}}
    def test_{{@index}}_{{this.name}}_fails(self):
        """Test case: {{this.description}}"""
        output = """{{this.content}}"""
        result = {{GRADER_FUNCTION_NAME}}(output, CTX)

        assert result["pass"] is False, f"Expected fail but got pass: {result['reason']}"
        assert result["score"] == 0.0, f"Expected score 0.0 but got {result['score']}"
        assert "binary" in result and result["binary"] is True, "Result must be binary"
        assert "criterion" in result and result["criterion"] == "{{CRITERION_ID}}", "Must include criterion ID"

        # Verify failure reason is informative
        assert "reason" in result and result["reason"], "Must provide failure reason"

{{/each}}

    # ─────────────────────────────────────────────
    # Edge Cases and Validation Tests
    # ─────────────────────────────────────────────

    def test_empty_output_handling(self):
        """Test behavior with empty output"""
        result = {{GRADER_FUNCTION_NAME}}("", CTX)

        # Should not crash and should return valid binary result
        assert isinstance(result["pass"], bool), "Must return boolean pass/fail"
        assert result["score"] in [0.0, 1.0], "Score must be binary (0.0 or 1.0)"
        assert result["binary"] is True, "Must be marked as binary evaluation"

    def test_whitespace_only_output(self):
        """Test behavior with whitespace-only output"""
        result = {{GRADER_FUNCTION_NAME}}("   \n\t   \n", CTX)

        assert isinstance(result["pass"], bool), "Must return boolean pass/fail"
        assert result["score"] in [0.0, 1.0], "Score must be binary"

    def test_very_long_output(self):
        """Test behavior with very long output"""
        long_output = "This is a test. " * 1000  # 16KB of text
        result = {{GRADER_FUNCTION_NAME}}(long_output, CTX)

        assert isinstance(result["pass"], bool), "Must handle long input without crashing"
        assert result["score"] in [0.0, 1.0], "Score must remain binary"

    def test_unicode_handling(self):
        """Test behavior with unicode characters"""
        unicode_output = "Testing with émojis 🔒 and unicode: αβγδε"
        result = {{GRADER_FUNCTION_NAME}}(unicode_output, CTX)

        assert isinstance(result["pass"], bool), "Must handle unicode without crashing"

    def test_context_parameter_optional(self):
        """Test that context parameter is optional"""
        output = "Basic test output for context handling"

        # Should work with no context
        result1 = {{GRADER_FUNCTION_NAME}}(output)
        assert isinstance(result1["pass"], bool)

        # Should work with empty context
        result2 = {{GRADER_FUNCTION_NAME}}(output, {})
        assert isinstance(result2["pass"], bool)

        # Should work with populated context
        result3 = {{GRADER_FUNCTION_NAME}}(output, {"key": "value"})
        assert isinstance(result3["pass"], bool)

    # ─────────────────────────────────────────────
    # EDD Compliance Validation Tests
    # ─────────────────────────────────────────────

    def test_edd_principle_ii_binary_compliance(self):
        """Test EDD Principle II: Binary Pass/Fail Only"""
        test_outputs = [
            "Clean test output",
            "Potentially problematic output",
            "Clearly failing output with violations"
        ]

        for output in test_outputs:
            result = {{GRADER_FUNCTION_NAME}}(output, CTX)

            # Must be binary
            assert result["pass"] in [True, False], f"Pass must be boolean, got {type(result['pass'])}"
            assert result["score"] in [0.0, 1.0], f"Score must be 0.0 or 1.0, got {result['score']}"
            assert result["binary"] is True, "Binary flag must be True"

            # Score must match pass/fail
            expected_score = 1.0 if result["pass"] else 0.0
            assert result["score"] == expected_score, f"Score {result['score']} doesn't match pass={result['pass']}"

    def test_required_metadata_fields(self):
        """Test that all required EDD metadata fields are present"""
        result = {{GRADER_FUNCTION_NAME}}("Test output", CTX)

        # Core EDD fields
        assert "pass" in result, "Missing 'pass' field"
        assert "score" in result, "Missing 'score' field"
        assert "binary" in result, "Missing 'binary' field"
        assert "reason" in result, "Missing 'reason' field"
        assert "confidence" in result, "Missing 'confidence' field"

        # Goldset traceability fields
        assert "criterion" in result, "Missing 'criterion' field"
        assert "criterion_name" in result, "Missing 'criterion_name' field"
        assert "evaluator_type" in result, "Missing 'evaluator_type' field"
        assert "tier" in result, "Missing 'tier' field"

        # Failure type routing fields
        assert "failure_type" in result, "Missing 'failure_type' field"
        assert "routing" in result, "Missing 'routing' field"

        # Validate criterion matches expected
        assert result["criterion"] == "{{CRITERION_ID}}", f"Expected criterion {{CRITERION_ID}}, got {result['criterion']}"
        assert result["criterion_name"] == "{{CRITERION_NAME}}", f"Criterion name mismatch"

    def test_confidence_range_validation(self):
        """Test that confidence values are in valid range [0.0, 1.0]"""
        test_outputs = [
            "Clean output",
            "Ambiguous output that might trigger uncertainty",
            "Clear violation that should be high confidence"
        ]

        for output in test_outputs:
            result = {{GRADER_FUNCTION_NAME}}(output, CTX)
            confidence = result.get("confidence", 0.5)

            assert 0.0 <= confidence <= 1.0, f"Confidence {confidence} outside valid range [0.0, 1.0]"
            assert isinstance(confidence, (int, float)), f"Confidence must be numeric, got {type(confidence)}"

    def test_failure_type_routing(self):
        """Test EDD Principle VIII: Failure Type Routing"""
        # Test with an input that should fail
        failing_input = "{{FAIL_EXAMPLES.[0].content}}"
        result = {{GRADER_FUNCTION_NAME}}(failing_input, CTX)

        if not result["pass"]:
            # Validate failure type routing
            assert "failure_type" in result, "Failed evaluations must include failure_type"
            assert result["failure_type"] in ["specification_failure", "generalization_failure"], \
                f"Invalid failure_type: {result.get('failure_type')}"

            # Validate routing configuration
            routing = result.get("routing", {})
            if routing:
                assert "action" in routing, "Routing must specify action"
                assert routing["action"] in ["fix_directive", "build_evaluator"], \
                    f"Invalid routing action: {routing.get('action')}"

    def test_annotation_queue_routing(self):
        """Test EDD Principle VII: Annotation Queue Routing for High-Risk Failures"""
        # Test multiple outputs to potentially trigger low-confidence failures
        test_outputs = [
            "Ambiguous edge case that might be hard to classify",
            "{{FAIL_EXAMPLES.[0].content}}"
        ]

        for output in test_outputs:
            result = {{GRADER_FUNCTION_NAME}}(output, CTX)

            # If failed with low confidence, should trigger annotation
            if not result["pass"] and result.get("confidence", 1.0) < 0.8:
                assert "annotation_required" in result, "Low confidence failures should trigger annotation"
                assert result["annotation_required"] is True, "Annotation flag should be True"
                assert "annotation_priority" in result, "Must specify annotation priority"
                assert "annotation_queue" in result, "Must specify annotation queue"

    # ─────────────────────────────────────────────
    # Performance and SLA Tests
    # ─────────────────────────────────────────────

    def test_performance_sla_compliance(self):
        """Test that grader meets EDD performance SLA requirements"""
        import time

        output = "Standard test output for performance testing"

        start_time = time.time()
        result = {{GRADER_FUNCTION_NAME}}(output, CTX)
        execution_time = time.time() - start_time

        # Get tier from result to determine SLA
        tier = result.get("tier", 1)

        if tier == 1:
            # Tier 1: Fast checks should complete in < 30 seconds
            assert execution_time < 30.0, f"Tier 1 grader took {execution_time:.2f}s (SLA: <30s)"
        elif tier == 2:
            # Tier 2: Semantic checks should complete in < 5 minutes
            assert execution_time < 300.0, f"Tier 2 grader took {execution_time:.2f}s (SLA: <300s)"

    def test_grader_is_deterministic(self):
        """Test that grader produces consistent results across multiple runs"""
        output = "Deterministic test output for consistency checking"

        # Run multiple times
        results = []
        for _ in range(3):
            result = {{GRADER_FUNCTION_NAME}}(output, CTX)
            results.append({
                "pass": result["pass"],
                "score": result["score"],
                "reason": result["reason"]
            })

        # All results should be identical for deterministic graders
        first_result = results[0]
        for i, result in enumerate(results[1:], 1):
            assert result["pass"] == first_result["pass"], \
                f"Run {i+1} pass differs: {result['pass']} vs {first_result['pass']}"
            assert result["score"] == first_result["score"], \
                f"Run {i+1} score differs: {result['score']} vs {first_result['score']}"


# ============================================
# Test Data Generation Helpers
# ============================================

def test_criterion_examples_coverage():
    """Meta-test: Verify that test examples cover both pass and fail cases"""
    pass_examples = {{PASS_EXAMPLES|length}}
    fail_examples = {{FAIL_EXAMPLES|length}}

    assert pass_examples > 0, "Must have at least one passing test case"
    assert fail_examples > 0, "Must have at least one failing test case"
    assert pass_examples + fail_examples >= 4, "Should have at least 4 total test cases for good coverage"


# ============================================
# Pytest Configuration and Fixtures
# ============================================

@pytest.fixture
def grader_function():
    """Fixture providing the grader function for parameterized tests"""
    return {{GRADER_FUNCTION_NAME}}


@pytest.fixture
def sample_context():
    """Fixture providing sample context for testing"""
    return {
        "request_id": "test-123",
        "timestamp": "2026-04-14T12:00:00Z",
        "system": "test"
    }


def pytest_configure(config):
    """Configure pytest with custom markers for grader tests"""
    config.addinivalue_line(
        "markers",
        "edd_compliance: mark tests that validate EDD principle compliance"
    )
    config.addinivalue_line(
        "markers",
        "performance: mark tests that validate performance SLA compliance"
    )
    config.addinivalue_line(
        "markers",
        "edge_cases: mark tests for edge case handling"
    )


# ============================================
# Test Execution Instructions
# ============================================

"""
RUNNING THESE TESTS:

1. Install test dependencies:
   pip install -e ".[test]"
   pip install pytest pytest-cov

2. Run all tests for this grader:
   pytest tests/test_{{GRADER_FUNCTION_NAME}}.py -v

3. Run with coverage:
   pytest tests/test_{{GRADER_FUNCTION_NAME}}.py --cov={{GRADER_MODULE_NAME}} --cov-report=html

4. Run only EDD compliance tests:
   pytest tests/test_{{GRADER_FUNCTION_NAME}}.py -m edd_compliance -v

5. Run performance tests:
   pytest tests/test_{{GRADER_FUNCTION_NAME}}.py -m performance -v

6. Run in CI/CD:
   pytest tests/test_{{GRADER_FUNCTION_NAME}}.py --junit-xml=test-results-{{GRADER_FUNCTION_NAME}}.xml

EXPECTED OUTPUT:
- All tests should pass for a properly implemented grader
- Coverage should be >90% for the grader function
- Performance tests should pass within SLA limits
- EDD compliance tests validate adherence to binary evaluation principles

TEST FAILURE TROUBLESHOOTING:
- Binary compliance failures: Check that grader only returns 0.0/1.0 scores
- Metadata failures: Ensure all required EDD fields are included
- Performance failures: Optimize grader logic or check for infinite loops
- Deterministic failures: Remove randomness or time-based logic from grader
"""
