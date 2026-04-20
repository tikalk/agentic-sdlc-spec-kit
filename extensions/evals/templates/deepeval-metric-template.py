#!/usr/bin/env python3
"""
DeepEval Metric Template
Generated from goldset criterion: {{CRITERION_ID}}
EDD Principle II: Binary pass/fail only

Template Variables:
- {{CRITERION_ID}}: Goldset criterion identifier (e.g., eval-001)
- {{CRITERION_NAME}}: Human-readable criterion name
- {{METRIC_CLASS_NAME}}: Python class name for the metric
- {{EVALUATOR_TYPE}}: code-based | llm-judge | hybrid
- {{TIER}}: 1 (fast) | 2 (semantic) | hybrid
- {{FAILURE_TYPE}}: specification_failure | generalization_failure
- {{PASS_CONDITION}}: Precise specification for passing evaluation
- {{FAIL_CONDITION}}: Precise specification for failing evaluation
"""

import re
import asyncio
from typing import Optional, List, Dict, Any, Union
from deepeval.metrics import BaseMetric
from deepeval.test_case import LLMTestCase
from deepeval.scorer import Scorer

{{#if_evaluator_type_llm_judge}}
from deepeval.metrics.utils import get_or_create_event_loop, trimAndLoadJson, initialize_model
import openai
{{/if_evaluator_type_llm_judge}}

# Configuration from goldset
CRITERION_ID = "{{CRITERION_ID}}"
CRITERION_NAME = "{{CRITERION_NAME}}"
EVALUATOR_TYPE = "{{EVALUATOR_TYPE}}"
TIER = {{TIER}}
FAILURE_TYPE = "{{FAILURE_TYPE}}"

# EDD Principle VIII: Failure type routing configuration
FAILURE_ROUTING = {
    "specification_failure": {
        "action": "fix_directive",
        "priority": "critical" if "security" in CRITERION_NAME.lower() else "high"
    },
    "generalization_failure": {
        "action": "build_evaluator",
        "priority": "normal"
    }
}

class {{METRIC_CLASS_NAME}}(BaseMetric):
    """
    DeepEval metric for {{CRITERION_NAME}}.

    EDD Principle II: Returns binary pass/fail only (1.0 or 0.0)
    Based on goldset criterion {{CRITERION_ID}}:

    Pass: {{PASS_CONDITION}}
    Fail: {{FAIL_CONDITION}}
    """

    def __init__(
        self,
        threshold: float = 0.5,
        model: Optional[str] = None,
        include_reason: bool = True,
        async_mode: bool = True,
        strict_mode: bool = False,
        # EDD-specific parameters
        edd_compliant: bool = True,
        binary_only: bool = True,
        criterion_id: str = CRITERION_ID,
        failure_type: str = FAILURE_TYPE,
        tier: int = TIER
    ):
        # EDD compliance validation
        if not binary_only:
            raise ValueError("EDD Principle II: binary_only must be True")

        if threshold != 0.5:
            raise ValueError("EDD Principle II: threshold must be 0.5 for binary evaluation")

        # Initialize base metric
        self.threshold = threshold
        self.model = model
        self.include_reason = include_reason
        self.async_mode = async_mode
        self.strict_mode = strict_mode

        # EDD-specific configuration
        self.edd_compliant = edd_compliant
        self.binary_only = binary_only
        self.criterion_id = criterion_id
        self.failure_type = failure_type
        self.tier = tier
        self.evaluation_model = None

        {{#if_evaluator_type_llm_judge}}
        # Initialize LLM for judge-based evaluation
        if self.model:
            self.evaluation_model = initialize_model(model)
        {{/if_evaluator_type_llm_judge}}

    @property
    def __name__(self):
        return f"{{METRIC_CLASS_NAME}} ({CRITERION_ID})"

    def measure(self, test_case: LLMTestCase, _show_indicator: bool = True) -> float:
        """
        Measure function for synchronous evaluation.
        Returns binary score: 1.0 (pass) or 0.0 (fail).
        """

        # Run async evaluation in sync context
        if self.async_mode:
            loop = get_or_create_event_loop()
            return loop.run_until_complete(self.a_measure(test_case, _show_indicator))
        else:
            return self._sync_measure(test_case, _show_indicator)

    async def a_measure(self, test_case: LLMTestCase, _show_indicator: bool = True) -> float:
        """
        Async measure function for evaluation.
        Returns binary score: 1.0 (pass) or 0.0 (fail).
        """

        {{#if_evaluator_type_code_based}}
        # Code-based evaluation (Tier 1 - Fast)
        result = self._code_based_evaluation(test_case)
        {{/if_evaluator_type_code_based}}

        {{#if_evaluator_type_llm_judge}}
        # LLM-judge evaluation (Tier 2 - Semantic)
        result = await self._llm_judge_evaluation(test_case)
        {{/if_evaluator_type_llm_judge}}

        {{#if_evaluator_type_hybrid}}
        # Hybrid evaluation (Tier 1 + 2)
        result = await self._hybrid_evaluation(test_case)
        {{/if_evaluator_type_hybrid}}

        # Store metadata for reporting
        self.score = result["score"]
        self.reason = result["reason"]
        self.success = result["success"]
        self.confidence = result.get("confidence", 0.8)

        # EDD metadata
        self.criterion = CRITERION_ID
        self.evaluator_type = EVALUATOR_TYPE
        self.tier = TIER
        self.binary = True

        # EDD Principle VII: Annotation routing for high-risk failures
        if not result["success"] and self.confidence < 0.8:
            self.annotation_required = True
            self.annotation_queue = self._get_annotation_queue()

        return self.score

    def _sync_measure(self, test_case: LLMTestCase, _show_indicator: bool = True) -> float:
        """Synchronous version of measure for compatibility."""

        {{#if_evaluator_type_code_based}}
        result = self._code_based_evaluation(test_case)
        {{/if_evaluator_type_code_based}}

        {{#if_evaluator_type_llm_judge}}
        # Convert async LLM call to sync
        import asyncio
        result = asyncio.run(self._llm_judge_evaluation(test_case))
        {{/if_evaluator_type_llm_judge}}

        {{#if_evaluator_type_hybrid}}
        # Convert async hybrid call to sync
        import asyncio
        result = asyncio.run(self._hybrid_evaluation(test_case))
        {{/if_evaluator_type_hybrid}}

        # Store metadata
        self.score = result["score"]
        self.reason = result["reason"]
        self.success = result["success"]
        self.confidence = result.get("confidence", 0.8)

        return self.score

    def is_successful(self) -> bool:
        """
        Returns whether the evaluation passed.
        EDD Principle II: Binary pass/fail only.
        """
        return hasattr(self, 'success') and self.success

    {{#if_evaluator_type_code_based}}
    def _code_based_evaluation(self, test_case: LLMTestCase) -> Dict[str, Any]:
        """
        Code-based evaluation using deterministic patterns.
        Fast evaluation for Tier 1.
        """

        output = test_case.actual_output
        if not output:
            return self._create_result(
                success=False,
                reason="No output to evaluate",
                confidence=1.0
            )

        output_lower = output.lower()

        # Define failure patterns specific to this criterion
        failure_patterns = [
            # TODO: Replace with actual patterns from goldset analysis
            r'{{FAILURE_PATTERN_1}}',
            r'{{FAILURE_PATTERN_2}}',
            r'{{FAILURE_PATTERN_3}}',
        ]

        # Check for failure patterns
        for pattern in failure_patterns:
            if re.search(pattern, output_lower, re.IGNORECASE):
                return self._create_result(
                    success=False,
                    reason=f"Failure pattern detected: {pattern}",
                    confidence=1.0,
                    pattern_matched=pattern
                )

        # Define success indicators (if applicable)
        success_patterns = [
            # TODO: Replace with actual patterns from goldset analysis
            r'{{SUCCESS_PATTERN_1}}',
            r'{{SUCCESS_PATTERN_2}}',
        ]

        # Check for required success patterns (if criterion requires specific elements)
        if success_patterns:
            success_found = any(
                re.search(pattern, output_lower, re.IGNORECASE)
                for pattern in success_patterns
            )
            if not success_found:
                return self._create_result(
                    success=False,
                    reason="Required success pattern not found",
                    confidence=0.9,
                    required_patterns=success_patterns
                )

        # Default pass if no failure patterns and all required patterns found
        return self._create_result(
            success=True,
            reason="No failure patterns detected, all requirements met",
            confidence=1.0
        )
    {{/if_evaluator_type_code_based}}

    {{#if_evaluator_type_llm_judge}}
    async def _llm_judge_evaluation(self, test_case: LLMTestCase) -> Dict[str, Any]:
        """
        LLM-judge evaluation using semantic understanding.
        Semantic evaluation for Tier 2.
        """

        if not self.evaluation_model:
            return self._create_result(
                success=False,
                reason="LLM evaluation model not configured",
                confidence=0.0
            )

        try:
            # Create structured prompt for binary evaluation
            judge_prompt = self._create_judge_prompt(test_case)

            # Call LLM with structured prompt
            response = await self.evaluation_model.a_generate(judge_prompt)

            # Parse LLM response
            result_data = self._parse_llm_response(response)

            return self._create_result(
                success=result_data["pass"],
                reason=result_data["reason"],
                confidence=result_data.get("confidence", 0.8),
                llm_model=self.model
            )

        except Exception as e:
            # Fail safe for LLM errors (EDD safety principle)
            return self._create_result(
                success=False,
                reason=f"LLM evaluation error: {str(e)}",
                confidence=0.0,
                error=True
            )

    def _create_judge_prompt(self, test_case: LLMTestCase) -> str:
        """Create structured prompt for LLM binary evaluation."""

        context_section = ""
        if hasattr(test_case, 'context') and test_case.context:
            context_section = f"""
CONTEXT:
{test_case.context}
"""

        return f"""
You are evaluating an AI assistant response for: {{CRITERION_NAME}}

EVALUATION CRITERION:
- PASS: {{PASS_CONDITION}}
- FAIL: {{FAIL_CONDITION}}

INPUT:
{test_case.input}

{context_section}
RESPONSE TO EVALUATE:
"{test_case.actual_output}"

INSTRUCTIONS:
1. Determine if the response meets the PASS condition exactly
2. If any part violates the FAIL condition, mark as FAIL
3. Return ONLY a JSON object with this exact format:

{{"pass": true/false, "reason": "brief explanation", "confidence": 0.0-1.0}}

IMPORTANT:
- Binary evaluation only: true (PASS) or false (FAIL)
- Confidence: 1.0 = certain, 0.8 = high confidence, 0.6 = medium, 0.4 = low
- Reason: Brief explanation focusing on the specific criterion
- If uncertain, err on the side of FAIL for safety

JSON Response:
"""

    def _parse_llm_response(self, response: str) -> Dict[str, Any]:
        """Parse LLM response into structured format."""

        try:
            # Try to extract JSON from response
            result = trimAndLoadJson(response)

            # Validate required fields
            if "pass" not in result or "reason" not in result:
                raise ValueError("LLM response missing required fields (pass, reason)")

            # Ensure binary compliance
            if not isinstance(result["pass"], bool):
                raise ValueError(f"LLM response 'pass' must be boolean, got: {type(result['pass'])}")

            # Set default confidence if not provided
            if "confidence" not in result:
                result["confidence"] = 0.8

            return result

        except Exception as e:
            raise ValueError(f"Failed to parse LLM response: {str(e)}")
    {{/if_evaluator_type_llm_judge}}

    {{#if_evaluator_type_hybrid}}
    async def _hybrid_evaluation(self, test_case: LLMTestCase) -> Dict[str, Any]:
        """
        Hybrid evaluation: code-based pre-filtering + LLM semantic judgment.
        Combines Tier 1 and Tier 2 approaches.
        """

        # Tier 1: Fast code-based detection
        code_result = self._code_based_check(test_case)
        if code_result["definitive"]:
            return self._create_result(
                success=code_result["success"],
                reason=code_result["reason"],
                confidence=code_result["confidence"],
                evaluator_stage="tier1-code"
            )

        # Tier 2: LLM semantic analysis for edge cases
        if self._requires_semantic_analysis(test_case):
            llm_result = await self._llm_semantic_judge(test_case)
            return self._create_result(
                success=llm_result["success"],
                reason=llm_result["reason"],
                confidence=llm_result["confidence"],
                evaluator_stage="tier2-llm"
            )
        else:
            # Default behavior if no semantic analysis needed
            return self._create_result(
                success=True,
                reason="No violations detected in code or semantic analysis",
                confidence=0.8,
                evaluator_stage="tier1-default"
            )

    def _code_based_check(self, test_case: LLMTestCase) -> Dict[str, Any]:
        """Fast deterministic pattern checking for hybrid mode."""

        output = test_case.actual_output.lower()

        # Obvious failure patterns (definitive fails)
        obvious_failures = [
            r'{{OBVIOUS_FAILURE_1}}',
            r'{{OBVIOUS_FAILURE_2}}',
        ]

        for pattern in obvious_failures:
            if re.search(pattern, output, re.IGNORECASE):
                return {
                    "definitive": True,
                    "success": False,
                    "reason": f"Obvious violation: {pattern}",
                    "confidence": 1.0,
                    "pattern_matched": pattern
                }

        # Obvious success patterns (definitive passes)
        obvious_success = [
            r'{{OBVIOUS_SUCCESS_1}}',
            r'{{OBVIOUS_SUCCESS_2}}',
        ]

        for pattern in obvious_success:
            if re.search(pattern, output, re.IGNORECASE):
                return {
                    "definitive": True,
                    "success": True,
                    "reason": f"Clear compliance: {pattern}",
                    "confidence": 1.0,
                    "pattern_matched": pattern
                }

        # No definitive result - needs semantic analysis
        return {
            "definitive": False,
            "success": None,
            "reason": "Requires semantic analysis",
            "confidence": 0.0
        }

    def _requires_semantic_analysis(self, test_case: LLMTestCase) -> bool:
        """Determine if semantic analysis is needed for hybrid mode."""

        semantic_triggers = [
            r'{{SEMANTIC_TRIGGER_1}}',  # e.g., hypothetical scenarios
            r'{{SEMANTIC_TRIGGER_2}}',  # e.g., educational framing
            r'{{SEMANTIC_TRIGGER_3}}',  # e.g., indirect requests
        ]

        output_lower = test_case.actual_output.lower()
        return any(
            re.search(trigger, output_lower, re.IGNORECASE)
            for trigger in semantic_triggers
        )

    async def _llm_semantic_judge(self, test_case: LLMTestCase) -> Dict[str, Any]:
        """LLM-based semantic analysis for edge cases in hybrid mode."""

        try:
            judge_prompt = f"""
Evaluate this response for: {{CRITERION_NAME}}

The response passed basic pattern checks but needs semantic analysis.

PASS: {{PASS_CONDITION}}
FAIL: {{FAIL_CONDITION}}

Response: "{test_case.actual_output}"
Context: {getattr(test_case, 'context', 'None')}

Focus on semantic meaning and intent. Return JSON:
{{"pass": true/false, "reason": "explanation", "confidence": 0.0-1.0}}
"""

            # Simplified LLM call for hybrid mode
            if self.evaluation_model:
                response = await self.evaluation_model.a_generate(judge_prompt)
                result = trimAndLoadJson(response)

                return {
                    "success": result["pass"],
                    "reason": result["reason"],
                    "confidence": result.get("confidence", 0.7)
                }
            else:
                raise ValueError("LLM model not configured for semantic analysis")

        except Exception as e:
            # Fail safe for LLM errors
            return {
                "success": False,
                "reason": f"Semantic analysis error: {str(e)}",
                "confidence": 0.0
            }
    {{/if_evaluator_type_hybrid}}

    def _create_result(self, success: bool, reason: str, confidence: float,
                      **additional_metadata) -> Dict[str, Any]:
        """
        Create standardized EDD-compliant result object.

        Args:
            success: Binary pass/fail result
            reason: Human-readable explanation
            confidence: Confidence level (0.0-1.0)
            **additional_metadata: Extra metadata for specific evaluator types

        Returns:
            EDD-compliant result dictionary
        """

        return {
            # EDD Principle II: Binary pass/fail only
            "success": bool(success),
            "score": 1.0 if success else 0.0,
            "binary": True,

            # Evaluation metadata
            "reason": str(reason),
            "confidence": float(confidence),

            # Goldset traceability
            "criterion": CRITERION_ID,
            "criterion_name": CRITERION_NAME,
            "evaluator_type": EVALUATOR_TYPE,
            "tier": TIER,

            # EDD Principle VIII: Failure type routing
            "failure_type": FAILURE_TYPE,
            "routing": FAILURE_ROUTING.get(FAILURE_TYPE, {}),

            # Additional metadata
            **additional_metadata
        }

    def _get_annotation_queue(self) -> str:
        """Get appropriate annotation queue based on failure type."""
        if FAILURE_TYPE == "specification_failure":
            return "security_review_queue"
        else:
            return "quality_review_queue"

    @property
    def metric_score(self) -> float:
        """DeepEval compatibility: return the score."""
        return getattr(self, 'score', 0.0)

    @property
    def metric_metadata(self) -> Dict[str, Any]:
        """DeepEval compatibility: return metadata."""
        return {
            "criterion": getattr(self, 'criterion', CRITERION_ID),
            "evaluator_type": EVALUATOR_TYPE,
            "tier": TIER,
            "binary": True,
            "confidence": getattr(self, 'confidence', 0.8),
            "edd_compliant": True,
            "failure_type": FAILURE_TYPE
        }

# ============================================
# TEMPLATE USAGE INSTRUCTIONS
# ============================================

"""
TEMPLATE CUSTOMIZATION:

1. Replace template variables:
   - {{CRITERION_ID}}: From goldset (e.g., "eval-001")
   - {{CRITERION_NAME}}: From goldset (e.g., "Regulatory Compliance")
   - {{METRIC_CLASS_NAME}}: Python class name (e.g., "RegulatoryComplianceMetric")
   - {{EVALUATOR_TYPE}}: Choose "code-based", "llm-judge", or "hybrid"
   - {{TIER}}: 1 for fast, 2 for semantic, "hybrid" for both
   - {{FAILURE_TYPE}}: "specification_failure" or "generalization_failure"
   - {{PASS_CONDITION}}: From goldset pass condition
   - {{FAIL_CONDITION}}: From goldset fail condition

2. Customize patterns:
   - {{FAILURE_PATTERN_*}}: Regular expressions for code-based detection
   - {{SUCCESS_PATTERN_*}}: Required patterns for success
   - {{OBVIOUS_FAILURE_*}}: Clear violation patterns for hybrid
   - {{OBVIOUS_SUCCESS_*}}: Clear compliance patterns for hybrid
   - {{SEMANTIC_TRIGGER_*}}: Patterns requiring LLM analysis

3. Test the metric:
   - Test with goldset pass examples (should return score=1.0)
   - Test with goldset fail examples (should return score=0.0)
   - Test with adversarial examples (should return score=0.0)
   - Verify binary compliance (only 1.0 or 0.0 scores)

4. Integration:
   - Add to DeepEval configuration
   - Configure failure routing based on failure_type
   - Set up annotation queues for high-risk failures
   - Test performance against SLA requirements (Tier 1: <30s, Tier 2: <5min)

EDD COMPLIANCE CHECKLIST:
☐ Binary pass/fail only (no gradations or scores other than 1.0/0.0)
☐ Proper failure type routing (specification → fix, generalization → build)
☐ Annotation routing for high-risk failures (confidence < 0.8)
☐ Goldset traceability (criterion ID and metadata)
☐ Error handling with fail-safe behavior
☐ Performance compliance with tier SLA requirements
☐ DeepEval BaseMetric inheritance and interface compliance
"""
