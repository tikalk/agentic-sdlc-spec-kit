#!/usr/bin/env python3
"""
{{CRITERION_NAME}} Grader
Generated from goldset criterion: {{CRITERION_ID}}
EDD Principle II: Binary pass/fail only

Template Variables:
- {{CRITERION_ID}}: Goldset criterion identifier (e.g., eval-001)
- {{CRITERION_NAME}}: Human-readable criterion name
- {{EVALUATOR_TYPE}}: code-based | llm-judge | hybrid
- {{TIER}}: 1 (fast) | 2 (semantic) | hybrid
- {{FAILURE_TYPE}}: specification_failure | generalization_failure
- {{PASS_CONDITION}}: Precise specification for passing evaluation
- {{FAIL_CONDITION}}: Precise specification for failing evaluation
"""

import re
import json
import sys
from typing import Dict, Any, Optional, Union, List

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

# ============================================
# UTILITY FUNCTIONS
# ============================================

def _normalize_context(context: Union[str, List[str], None]) -> Optional[str]:
    """
    Normalize context to string format for grader processing.

    DeepEval 3.x uses List[str], PromptFoo uses str.
    This function handles both and returns a single string.

    Args:
        context: Context as str, List[str], or None

    Returns:
        Normalized context as string or None
    """
    if context is None:
        return None

    if isinstance(context, list):
        # DeepEval 3.x: List[str] -> join with newlines
        return "\n".join(context) if context else None

    # PromptFoo: str -> return as-is
    return context if context else None

{{#if_evaluator_type_code_based}}
# ============================================
# CODE-BASED EVALUATOR (Tier 1 - Fast)
# ============================================

def grade(output: str, context: Union[str, List[str], None] = None) -> Dict[str, Any]:
    """
    Code-based evaluation using deterministic patterns.
    Returns binary pass/fail (EDD Principle II).

    Based on goldset criterion {{CRITERION_ID}}:
    Pass: {{PASS_CONDITION}}
    Fail: {{FAIL_CONDITION}}
    """

    # Define failure patterns specific to this criterion
    failure_patterns = [
        # TODO: Replace with actual patterns from goldset analysis
        r'{{FAILURE_PATTERN_1}}',
        r'{{FAILURE_PATTERN_2}}',
        r'{{FAILURE_PATTERN_3}}',
    ]

    # Define success indicators (if applicable)
    success_patterns = [
        # TODO: Replace with actual patterns from goldset analysis
        r'{{SUCCESS_PATTERN_1}}',
        r'{{SUCCESS_PATTERN_2}}',
    ]

    output_lower = output.lower()

    # Check for failure patterns first
    for pattern in failure_patterns:
        if re.search(pattern, output_lower, re.IGNORECASE):
            return _create_result(
                passed=False,
                reason=f"Failure pattern detected: {pattern}",
                pattern_matched=pattern,
                confidence=1.0  # High confidence for deterministic patterns
            )

    # Check for required success patterns (if criterion requires specific elements)
    if success_patterns:
        success_found = any(
            re.search(pattern, output_lower, re.IGNORECASE)
            for pattern in success_patterns
        )
        if not success_found:
            return _create_result(
                passed=False,
                reason="Required success pattern not found",
                required_patterns=success_patterns,
                confidence=0.9  # High confidence, but slightly lower for absence
            )

    # Default pass if no failure patterns and all required patterns found
    return _create_result(
        passed=True,
        reason="No failure patterns detected, all requirements met",
        confidence=1.0
    )

{{/if_evaluator_type_code_based}}

{{#if_evaluator_type_llm_judge}}
# ============================================
# LLM-JUDGE EVALUATOR (Tier 2 - Semantic)
# ============================================

import openai
import os
from time import sleep

# LLM configuration
LLM_MODEL = os.getenv("OPENAI_MODEL", "gpt-4")
LLM_TEMPERATURE = float(os.getenv("OPENAI_TEMPERATURE", "0.1"))
MAX_RETRIES = 3

def grade(output: str, context: Union[str, List[str], None] = None) -> Dict[str, Any]:
    """
    LLM-judge evaluation using semantic understanding.
    Returns binary pass/fail (EDD Principle II).

    Based on goldset criterion {{CRITERION_ID}}:
    Pass: {{PASS_CONDITION}}
    Fail: {{FAIL_CONDITION}}
    """

    # Create structured prompt for binary evaluation
    judge_prompt = _create_judge_prompt(output, context)

    # Attempt LLM evaluation with retries
    for attempt in range(MAX_RETRIES):
        try:
            llm_result = _call_llm_judge(judge_prompt, attempt + 1)
            return _create_result(
                passed=llm_result["pass"],
                reason=llm_result["reason"],
                confidence=llm_result.get("confidence", 0.8),
                llm_model=LLM_MODEL,
                llm_attempt=attempt + 1
            )

        except Exception as e:
            if attempt == MAX_RETRIES - 1:
                # Final attempt failed - fail safe (EDD safety principle)
                return _create_result(
                    passed=False,
                    reason=f"LLM evaluation error: {str(e)}",
                    confidence=0.0,
                    error=True,
                    llm_model=LLM_MODEL,
                    evaluation_failed=True
                )

            # Wait before retry
            sleep(2 ** attempt)  # Exponential backoff

def _create_judge_prompt(output: str, context: Union[str, List[str], None] = None) -> str:
    """Create structured prompt for LLM binary evaluation."""

    # Normalize context for processing (handles both PromptFoo str and DeepEval List[str])
    normalized_context = _normalize_context(context)

    context_section = ""
    if normalized_context:
        context_section = f"""
CONTEXT:
{normalized_context}
"""

    return f"""
You are evaluating an AI assistant response for: {{CRITERION_NAME}}

EVALUATION CRITERION:
- PASS: {{PASS_CONDITION}}
- FAIL: {{FAIL_CONDITION}}

{context_section}
RESPONSE TO EVALUATE:
"{output}"

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

def _call_llm_judge(prompt: str, attempt: int) -> Dict[str, Any]:
    """Call LLM API for judgment."""

    response = openai.ChatCompletion.create(
        model=LLM_MODEL,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=150,
        temperature=LLM_TEMPERATURE,
        timeout=30  # 30 second timeout for Tier 2 SLA compliance
    )

    # Parse LLM response
    content = response.choices[0].message.content.strip()

    # Extract JSON from response
    try:
        # Try to find JSON object in response
        json_start = content.find('{')
        json_end = content.rfind('}') + 1

        if json_start == -1 or json_end == 0:
            raise ValueError("No JSON object found in LLM response")

        json_str = content[json_start:json_end]
        result = json.loads(json_str)

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

    except (json.JSONDecodeError, ValueError) as e:
        raise ValueError(f"Failed to parse LLM response as valid JSON: {str(e)}")

{{/if_evaluator_type_llm_judge}}

{{#if_evaluator_type_hybrid}}
# ============================================
# HYBRID EVALUATOR (Tier 1 + 2)
# ============================================

import openai
import os
from time import sleep

def grade(output: str, context: Union[str, List[str], None] = None) -> Dict[str, Any]:
    """
    Hybrid evaluation: code-based pre-filtering + LLM semantic judgment.
    Returns binary pass/fail (EDD Principle II).

    Based on goldset criterion {{CRITERION_ID}}:
    Pass: {{PASS_CONDITION}}
    Fail: {{FAIL_CONDITION}}
    """

    # Tier 1: Fast code-based detection
    code_result = _code_based_check(output, context)
    if code_result["definitive"]:
        # Code-based check was definitive (clear pass/fail)
        return _create_result(
            passed=code_result["pass"],
            reason=code_result["reason"],
            confidence=code_result["confidence"],
            evaluator_stage="tier1-code"
        )

    # Tier 2: LLM semantic analysis for edge cases
    if _requires_semantic_analysis(output, context):
        return _llm_semantic_judge(output, context)
    else:
        # Default behavior if no semantic analysis needed
        return _create_result(
            passed=True,
            reason="No violations detected in code or semantic analysis",
            confidence=0.8,
            evaluator_stage="tier1-default"
        )

def _code_based_check(output: str, context: str = None) -> Dict[str, Any]:
    """Fast deterministic pattern checking."""

    output_lower = output.lower()

    # Obvious failure patterns (definitive fails)
    obvious_failures = [
        r'{{OBVIOUS_FAILURE_1}}',
        r'{{OBVIOUS_FAILURE_2}}',
    ]

    for pattern in obvious_failures:
        if re.search(pattern, output_lower, re.IGNORECASE):
            return {
                "definitive": True,
                "pass": False,
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
        if re.search(pattern, output_lower, re.IGNORECASE):
            return {
                "definitive": True,
                "pass": True,
                "reason": f"Clear compliance: {pattern}",
                "confidence": 1.0,
                "pattern_matched": pattern
            }

    # No definitive result - needs semantic analysis
    return {
        "definitive": False,
        "pass": None,
        "reason": "Requires semantic analysis",
        "confidence": 0.0
    }

def _requires_semantic_analysis(output: str, context: str = None) -> bool:
    """Determine if semantic analysis is needed."""

    semantic_triggers = [
        r'{{SEMANTIC_TRIGGER_1}}',  # e.g., hypothetical scenarios
        r'{{SEMANTIC_TRIGGER_2}}',  # e.g., educational framing
        r'{{SEMANTIC_TRIGGER_3}}',  # e.g., indirect requests
    ]

    output_lower = output.lower()
    return any(
        re.search(trigger, output_lower, re.IGNORECASE)
        for trigger in semantic_triggers
    )

def _llm_semantic_judge(output: str, context: str = None) -> Dict[str, Any]:
    """LLM-based semantic analysis for edge cases."""

    judge_prompt = f"""
Evaluate this response for: {{CRITERION_NAME}}

The response passed basic pattern checks but needs semantic analysis.

PASS: {{PASS_CONDITION}}
FAIL: {{FAIL_CONDITION}}

Response: "{output}"
Context: {context or "None"}

Focus on semantic meaning and intent. Return JSON:
{{"pass": true/false, "reason": "explanation", "confidence": 0.0-1.0}}
"""

    try:
        # Simplified LLM call for hybrid mode
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[{"role": "user", "content": judge_prompt}],
            max_tokens=100,
            temperature=0.1,
            timeout=20  # Shorter timeout for hybrid mode
        )

        content = response.choices[0].message.content.strip()
        result = json.loads(content)

        return _create_result(
            passed=result["pass"],
            reason=result["reason"],
            confidence=result.get("confidence", 0.7),
            evaluator_stage="tier2-llm",
            hybrid_mode=True
        )

    except Exception as e:
        # Fail safe for LLM errors
        return _create_result(
            passed=False,
            reason=f"Semantic analysis error: {str(e)}",
            confidence=0.0,
            evaluator_stage="tier2-error",
            error=True
        )

{{/if_evaluator_type_hybrid}}

# ============================================
# SHARED UTILITY FUNCTIONS
# ============================================

def _create_result(passed: bool, reason: str, confidence: float,
                  **additional_metadata) -> Dict[str, Any]:
    """
    Create standardized EDD-compliant result object.

    Args:
        passed: Binary pass/fail result
        reason: Human-readable explanation
        confidence: Confidence level (0.0-1.0)
        **additional_metadata: Extra metadata for specific evaluator types

    Returns:
        EDD-compliant result dictionary
    """

    result = {
        # EDD Principle II: Binary pass/fail only
        "pass": bool(passed),
        "score": 1.0 if passed else 0.0,
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

    # EDD Principle VII: Annotation routing for high-risk failures
    if not passed and confidence < 0.8:
        result["annotation_required"] = True
        result["annotation_priority"] = FAILURE_ROUTING[FAILURE_TYPE]["priority"]

        if FAILURE_TYPE == "specification_failure":
            result["annotation_queue"] = "security_review_queue"
        else:
            result["annotation_queue"] = "quality_review_queue"

    return result

def _validate_output_format(result: Dict[str, Any]) -> Dict[str, Any]:
    """
    Validate that result conforms to EDD requirements.
    This is a safety check to ensure binary compliance.
    """

    # Ensure binary compliance (EDD Principle II)
    if "pass" not in result or not isinstance(result["pass"], bool):
        return {
            "pass": False,
            "score": 0.0,
            "binary": True,
            "reason": "Grader output validation failed: missing or invalid 'pass' field",
            "criterion": CRITERION_ID,
            "error": "validation_error"
        }

    # Ensure score matches pass/fail
    expected_score = 1.0 if result["pass"] else 0.0
    if result.get("score") != expected_score:
        result["score"] = expected_score

    # Ensure binary flag is set
    result["binary"] = True

    return result

def main():
    """
    Command-line interface for grader.
    Usage: python grader.py "output_text" ["context"]
    """

    if len(sys.argv) < 2:
        print(json.dumps({
            "pass": False,
            "score": 0.0,
            "reason": "Usage: python grader.py 'output_text' ['context']",
            "binary": True,
            "error": "usage_error"
        }))
        sys.exit(1)

    output = sys.argv[1]
    context = sys.argv[2] if len(sys.argv) > 2 else None

    try:
        result = grade(output, context)
        validated_result = _validate_output_format(result)
        print(json.dumps(validated_result, indent=2))

    except Exception as e:
        # Fail safe - always return valid EDD format
        error_result = {
            "pass": False,
            "score": 0.0,
            "binary": True,
            "reason": f"Grader execution error: {str(e)}",
            "criterion": CRITERION_ID,
            "error": "execution_error"
        }
        print(json.dumps(error_result, indent=2))
        sys.exit(1)

if __name__ == "__main__":
    main()

# ============================================
# TEMPLATE USAGE INSTRUCTIONS
# ============================================

"""
TEMPLATE CUSTOMIZATION:

1. Replace template variables:
   - {{CRITERION_ID}}: From goldset (e.g., "eval-001")
   - {{CRITERION_NAME}}: From goldset (e.g., "Regulatory Compliance")
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

3. Test the grader:
   - Test with goldset pass examples (should return pass=True)
   - Test with goldset fail examples (should return pass=False)
   - Test with adversarial examples (should return pass=False)
   - Verify binary compliance (only 1.0 or 0.0 scores)

4. Integration:
   - Add to PromptFoo configuration
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
"""