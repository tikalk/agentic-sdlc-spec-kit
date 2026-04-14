#!/usr/bin/env python3
"""
DeepEval Test Template
Generated unit tests for {{CRITERION_NAME}} metric
EDD-compliant testing with binary pass/fail validation

Template Variables:
- {{CRITERION_ID}}: Goldset criterion identifier (e.g., eval-001)
- {{CRITERION_NAME}}: Human-readable criterion name
- {{METRIC_CLASS_NAME}}: Python class name for the metric
- {{METRIC_FILE}}: Metric module filename (without .py)
- {{EVALUATOR_TYPE}}: code-based | llm-judge | hybrid
- {{TIER}}: 1 (fast) | 2 (semantic) | hybrid
- {{FAILURE_TYPE}}: specification_failure | generalization_failure
"""

import pytest
import asyncio
from typing import List, Dict, Any
from deepeval.test_case import LLMTestCase
from deepeval import assert_test

# Import the metric being tested
from graders.{{METRIC_FILE}} import {{METRIC_CLASS_NAME}}

# Test configuration
CRITERION_ID = "{{CRITERION_ID}}"
CRITERION_NAME = "{{CRITERION_NAME}}"
METRIC_CLASS_NAME = "{{METRIC_CLASS_NAME}}"

class Test{{METRIC_CLASS_NAME}}:
    """
    Test suite for {{CRITERION_NAME}} metric.
    Tests EDD Principle II compliance and goldset validation.
    """

    @pytest.fixture
    def metric(self):
        """Create metric instance for testing."""
        return {{METRIC_CLASS_NAME}}(
            threshold=0.5,
            include_reason=True,
            async_mode=True,
            edd_compliant=True,
            binary_only=True
        )

    @pytest.fixture
    def pass_examples(self) -> List[Dict[str, str]]:
        """Goldset examples that should pass evaluation."""
        return [
            {
                "input": "{{PASS_EXAMPLE_1_INPUT}}",
                "expected_output": "{{PASS_EXAMPLE_1_OUTPUT}}",
                "context": "{{PASS_EXAMPLE_1_CONTEXT}}",
                "description": "Pass example 1 from goldset"
            },
            {
                "input": "{{PASS_EXAMPLE_2_INPUT}}",
                "expected_output": "{{PASS_EXAMPLE_2_OUTPUT}}",
                "context": "{{PASS_EXAMPLE_2_CONTEXT}}",
                "description": "Pass example 2 from goldset"
            }
        ]

    @pytest.fixture
    def fail_examples(self) -> List[Dict[str, str]]:
        """Goldset examples that should fail evaluation."""
        return [
            {
                "input": "{{FAIL_EXAMPLE_1_INPUT}}",
                "expected_output": "{{FAIL_EXAMPLE_1_OUTPUT}}",
                "context": "{{FAIL_EXAMPLE_1_CONTEXT}}",
                "description": "Fail example 1 from goldset"
            },
            {
                "input": "{{FAIL_EXAMPLE_2_INPUT}}",
                "expected_output": "{{FAIL_EXAMPLE_2_OUTPUT}}",
                "context": "{{FAIL_EXAMPLE_2_CONTEXT}}",
                "description": "Fail example 2 from goldset"
            }
        ]

    @pytest.fixture
    def adversarial_examples(self) -> List[Dict[str, str]]:
        """Adversarial examples that should fail evaluation."""
        return [
            {
                "input": "{{ADVERSARIAL_1_INPUT}}",
                "expected_output": "{{ADVERSARIAL_1_OUTPUT}}",
                "context": "{{ADVERSARIAL_1_CONTEXT}}",
                "attack_vector": "{{ADVERSARIAL_1_VECTOR}}",
                "description": "Adversarial example 1"
            },
            {
                "input": "{{ADVERSARIAL_2_INPUT}}",
                "expected_output": "{{ADVERSARIAL_2_OUTPUT}}",
                "context": "{{ADVERSARIAL_2_CONTEXT}}",
                "attack_vector": "{{ADVERSARIAL_2_VECTOR}}",
                "description": "Adversarial example 2"
            }
        ]

    # ============================================
    # EDD COMPLIANCE TESTS
    # ============================================

    def test_metric_initialization(self, metric):
        """Test that metric initializes with EDD compliance."""

        # Verify EDD-specific attributes
        assert hasattr(metric, 'edd_compliant')
        assert metric.edd_compliant == True

        assert hasattr(metric, 'binary_only')
        assert metric.binary_only == True

        assert hasattr(metric, 'criterion_id')
        assert metric.criterion_id == CRITERION_ID

        # Verify threshold is 0.5 for binary evaluation
        assert metric.threshold == 0.5

    def test_binary_compliance_enforcement(self):
        """Test that non-binary configuration is rejected."""

        # Should raise error for binary_only=False
        with pytest.raises(ValueError, match="binary_only must be True"):
            {{METRIC_CLASS_NAME}}(binary_only=False)

        # Should raise error for non-0.5 threshold
        with pytest.raises(ValueError, match="threshold must be 0.5"):
            {{METRIC_CLASS_NAME}}(threshold=0.7)

    # ============================================
    # GOLDSET VALIDATION TESTS
    # ============================================

    @pytest.mark.asyncio
    async def test_goldset_pass_examples(self, metric, pass_examples):
        """Test that goldset pass examples return 1.0 (pass)."""

        for example in pass_examples:
            test_case = LLMTestCase(
                input=example["input"],
                actual_output=example["expected_output"],
                context=example.get("context", [])
            )

            # Evaluate using the metric
            score = await metric.a_measure(test_case)

            # EDD Principle II: Must be exactly 1.0 (pass)
            assert score == 1.0, f"Pass example failed: {example['description']} - Score: {score}, Reason: {getattr(metric, 'reason', 'No reason')}"

            # Verify binary compliance
            assert hasattr(metric, 'binary')
            assert metric.binary == True

            # Verify success flag
            assert metric.is_successful() == True

    @pytest.mark.asyncio
    async def test_goldset_fail_examples(self, metric, fail_examples):
        """Test that goldset fail examples return 0.0 (fail)."""

        for example in fail_examples:
            test_case = LLMTestCase(
                input=example["input"],
                actual_output=example["expected_output"],
                context=example.get("context", [])
            )

            # Evaluate using the metric
            score = await metric.a_measure(test_case)

            # EDD Principle II: Must be exactly 0.0 (fail)
            assert score == 0.0, f"Fail example passed unexpectedly: {example['description']} - Score: {score}, Reason: {getattr(metric, 'reason', 'No reason')}"

            # Verify binary compliance
            assert hasattr(metric, 'binary')
            assert metric.binary == True

            # Verify success flag
            assert metric.is_successful() == False

    @pytest.mark.asyncio
    async def test_adversarial_examples(self, metric, adversarial_examples):
        """Test that adversarial examples return 0.0 (fail)."""

        for example in adversarial_examples:
            test_case = LLMTestCase(
                input=example["input"],
                actual_output=example["expected_output"],
                context=example.get("context", [])
            )

            # Evaluate using the metric
            score = await metric.a_measure(test_case)

            # EDD Principle II: Adversarial examples must fail
            assert score == 0.0, f"Adversarial example passed unexpectedly: {example['description']} - Attack: {example.get('attack_vector', 'Unknown')}, Score: {score}"

            # Verify binary compliance
            assert hasattr(metric, 'binary')
            assert metric.binary == True

            # Verify success flag
            assert metric.is_successful() == False

    # ============================================
    # EDGE CASE TESTS
    # ============================================

    @pytest.mark.asyncio
    async def test_empty_output(self, metric):
        """Test handling of empty output."""

        test_case = LLMTestCase(
            input="Test input",
            actual_output="",
            context=[]
        )

        score = await metric.a_measure(test_case)

        # Empty output should fail
        assert score == 0.0
        assert metric.is_successful() == False
        assert hasattr(metric, 'reason')
        assert "empty" in metric.reason.lower() or "no output" in metric.reason.lower()

    @pytest.mark.asyncio
    async def test_none_output(self, metric):
        """Test handling of None output."""

        test_case = LLMTestCase(
            input="Test input",
            actual_output=None,
            context=[]
        )

        score = await metric.a_measure(test_case)

        # None output should fail
        assert score == 0.0
        assert metric.is_successful() == False

    @pytest.mark.asyncio
    async def test_very_long_output(self, metric):
        """Test handling of very long output."""

        # Create a very long output (10KB)
        long_output = "This is a test. " * 1000

        test_case = LLMTestCase(
            input="Test input",
            actual_output=long_output,
            context=[]
        )

        score = await metric.a_measure(test_case)

        # Should handle long output gracefully
        assert score in [0.0, 1.0]  # Must be binary
        assert hasattr(metric, 'binary')
        assert metric.binary == True

    @pytest.mark.asyncio
    async def test_special_characters(self, metric):
        """Test handling of special characters and encoding."""

        test_cases = [
            "Response with emoji 🤖",
            "Response with unicode: café naïve",
            "Response with symbols: @#$%^&*()",
            "Response with newlines:\nLine 1\nLine 2",
            "Response with tabs:\tTabbed content",
        ]

        for output in test_cases:
            test_case = LLMTestCase(
                input="Test input",
                actual_output=output,
                context=[]
            )

            score = await metric.a_measure(test_case)

            # Should handle special characters gracefully
            assert score in [0.0, 1.0]  # Must be binary
            assert hasattr(metric, 'binary')
            assert metric.binary == True

    # ============================================
    # PERFORMANCE TESTS
    # ============================================

    @pytest.mark.asyncio
    async def test_performance_tier1(self, metric):
        """Test that Tier 1 evaluations meet SLA (<30s)."""

        if {{TIER}} != 1:
            pytest.skip("Performance test only for Tier 1 metrics")

        test_case = LLMTestCase(
            input="Performance test input",
            actual_output="Performance test output",
            context=[]
        )

        import time
        start_time = time.time()

        await metric.a_measure(test_case)

        elapsed_time = time.time() - start_time

        # EDD Principle IV: Tier 1 SLA is 30 seconds
        assert elapsed_time < 30, f"Tier 1 evaluation took {elapsed_time:.2f}s (SLA: 30s)"

    @pytest.mark.asyncio
    async def test_performance_tier2(self, metric):
        """Test that Tier 2 evaluations meet SLA (<300s)."""

        if {{TIER}} != 2:
            pytest.skip("Performance test only for Tier 2 metrics")

        test_case = LLMTestCase(
            input="Performance test input",
            actual_output="Performance test output",
            context=[]
        )

        import time
        start_time = time.time()

        await metric.a_measure(test_case)

        elapsed_time = time.time() - start_time

        # EDD Principle IV: Tier 2 SLA is 300 seconds (5 minutes)
        assert elapsed_time < 300, f"Tier 2 evaluation took {elapsed_time:.2f}s (SLA: 300s)"

    # ============================================
    # METADATA AND TRACEABILITY TESTS
    # ============================================

    @pytest.mark.asyncio
    async def test_goldset_traceability(self, metric):
        """Test that metric maintains goldset traceability."""

        test_case = LLMTestCase(
            input="Traceability test input",
            actual_output="Traceability test output",
            context=[]
        )

        await metric.a_measure(test_case)

        # Check goldset traceability
        assert hasattr(metric, 'criterion')
        assert metric.criterion == CRITERION_ID

        assert hasattr(metric, 'evaluator_type')
        assert metric.evaluator_type == "{{EVALUATOR_TYPE}}"

        assert hasattr(metric, 'tier')
        assert metric.tier == {{TIER}}

    @pytest.mark.asyncio
    async def test_annotation_routing(self, metric):
        """Test annotation routing for high-risk failures."""

        # Create a test case that should fail with low confidence
        # This tests EDD Principle VII: Annotation queues
        test_case = LLMTestCase(
            input="Edge case input that may have low confidence",
            actual_output="Ambiguous output that may trigger annotation",
            context=[]
        )

        await metric.a_measure(test_case)

        # If the evaluation failed with low confidence, check annotation routing
        if not metric.is_successful() and hasattr(metric, 'confidence') and metric.confidence < 0.8:
            assert hasattr(metric, 'annotation_required')
            assert metric.annotation_required == True

            assert hasattr(metric, 'annotation_queue')
            assert metric.annotation_queue in ["security_review_queue", "quality_review_queue"]

    # ============================================
    # SYNCHRONOUS COMPATIBILITY TESTS
    # ============================================

    def test_sync_measure_compatibility(self, metric):
        """Test synchronous measure function for compatibility."""

        test_case = LLMTestCase(
            input="Sync test input",
            actual_output="Sync test output",
            context=[]
        )

        # Test synchronous evaluation
        score = metric.measure(test_case, _show_indicator=False)

        # Should return binary score
        assert score in [0.0, 1.0]

        # Should set the same metadata as async version
        assert hasattr(metric, 'binary')
        assert metric.binary == True

    # ============================================
    # DEEPEVAL INTEGRATION TESTS
    # ============================================

    @pytest.mark.asyncio
    async def test_deepeval_assert_integration(self, metric, pass_examples):
        """Test integration with DeepEval's assert_test function."""

        if not pass_examples:
            pytest.skip("No pass examples available for integration test")

        example = pass_examples[0]
        test_case = LLMTestCase(
            input=example["input"],
            actual_output=example["expected_output"],
            context=example.get("context", [])
        )

        # Test with DeepEval's assert function
        assert_test(test_case, [metric])

        # Verify the test passed
        assert metric.is_successful() == True

    def test_metric_properties(self, metric):
        """Test DeepEval metric property compatibility."""

        # Create a simple test case
        test_case = LLMTestCase(
            input="Property test input",
            actual_output="Property test output",
            context=[]
        )

        # Run evaluation
        metric.measure(test_case, _show_indicator=False)

        # Test metric properties
        assert hasattr(metric, 'metric_score')
        assert metric.metric_score in [0.0, 1.0]

        assert hasattr(metric, 'metric_metadata')
        metadata = metric.metric_metadata
        assert isinstance(metadata, dict)
        assert 'criterion' in metadata
        assert 'binary' in metadata
        assert metadata['binary'] == True

    # ============================================
    # ERROR HANDLING TESTS
    # ============================================

    @pytest.mark.asyncio
    async def test_error_handling(self, metric):
        """Test graceful error handling and fail-safe behavior."""

        # Test with invalid test case structure
        invalid_test_case = LLMTestCase(
            input=None,  # Invalid input
            actual_output="Valid output",
            context=[]
        )

        try:
            score = await metric.a_measure(invalid_test_case)

            # Should handle error gracefully and fail safe
            assert score == 0.0  # Fail safe
            assert metric.is_successful() == False

        except Exception as e:
            # If exception is raised, it should be handled appropriately
            pytest.fail(f"Metric should handle errors gracefully, but raised: {e}")

# ============================================
# TEMPLATE USAGE INSTRUCTIONS
# ============================================

"""
TEMPLATE CUSTOMIZATION:

1. Replace template variables:
   - {{CRITERION_ID}}: From goldset (e.g., "eval-001")
   - {{CRITERION_NAME}}: From goldset (e.g., "Regulatory Compliance")
   - {{METRIC_CLASS_NAME}}: Python class name (e.g., "RegulatoryComplianceMetric")
   - {{METRIC_FILE}}: Metric module filename without .py (e.g., "regulatory_compliance_metric")
   - {{EVALUATOR_TYPE}}: Choose "code-based", "llm-judge", or "hybrid"
   - {{TIER}}: 1 for fast, 2 for semantic, "hybrid" for both
   - {{FAILURE_TYPE}}: "specification_failure" or "generalization_failure"

2. Customize test examples:
   - {{PASS_EXAMPLE_*}}: Real examples from goldset that should pass
   - {{FAIL_EXAMPLE_*}}: Real examples from goldset that should fail
   - {{ADVERSARIAL_*}}: Adversarial examples that should fail

3. Run the tests:
   ```bash
   # Run all tests
   pytest test_{{METRIC_FILE}}.py -v

   # Run specific test categories
   pytest test_{{METRIC_FILE}}.py -k "goldset" -v
   pytest test_{{METRIC_FILE}}.py -k "performance" -v
   pytest test_{{METRIC_FILE}}.py -k "edd" -v

   # Run with coverage
   pytest test_{{METRIC_FILE}}.py --cov=graders.{{METRIC_FILE}} --cov-report=html
   ```

4. Integration testing:
   ```bash
   # Test with actual DeepEval evaluation
   python -c "
   from test_{{METRIC_FILE}} import Test{{METRIC_CLASS_NAME}}
   from deepeval import evaluate
   # Add integration test code here
   "
   ```

EDD COMPLIANCE CHECKLIST:
☐ Binary pass/fail validation (only 1.0 or 0.0 scores)
☐ Goldset traceability (criterion ID and metadata)
☐ Performance SLA validation (Tier 1: <30s, Tier 2: <300s)
☐ Annotation routing for high-risk failures
☐ Error handling and fail-safe behavior
☐ DeepEval integration compatibility
☐ Synchronous and asynchronous operation support
☐ Edge case handling (empty, None, long, special characters)
"""