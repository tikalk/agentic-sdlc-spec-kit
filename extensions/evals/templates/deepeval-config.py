#!/usr/bin/env python3
"""
DeepEval Configuration Template
Generated EDD-compliant evaluation configuration for DeepEval integration

Template Variables:
- {{SYSTEM}} - evaluation system (deepeval)
- {{CRITERION_ID}} - goldset criterion ID (eval-001, eval-002, etc.)
- {{CRITERION_NAME}} - human-readable criterion name
- {{METRIC_FILE}} - metric script filename
- {{FAILURE_TYPE}} - specification_failure | generalization_failure
- {{TIER}} - 1 (fast) | 2 (semantic) | hybrid
- {{EVALUATOR_TYPE}} - code-based | llm-judge | hybrid
"""

import os
import sys
import json
from typing import List, Dict, Any, Optional
from deepeval import evaluate
from deepeval.test_case import LLMTestCase
from deepeval.dataset import EvaluationDataset

# Import custom metrics (generated from goldset)
{{#each_metric}}
from graders.{{METRIC_FILE}} import {{METRIC_CLASS_NAME}}
{{/each_metric}}

# Configuration from goldset
CRITERION_ID = "{{CRITERION_ID}}"
CRITERION_NAME = "{{CRITERION_NAME}}"
EVALUATOR_TYPE = "{{EVALUATOR_TYPE}}"
TIER = {{TIER}}
FAILURE_TYPE = "{{FAILURE_TYPE}}"

# EDD Principle IV: Evaluation Pyramid Configuration
EVALUATION_CONFIG = {
    "criterion_id": CRITERION_ID,
    "criterion_name": CRITERION_NAME,
    "tier": TIER,
    "evaluator_type": EVALUATOR_TYPE,
    "failure_type": FAILURE_TYPE,
    "edd_compliant": True,
    "binary_only": True,
    "generated_from": "goldset-v1.0.0"
}

# EDD Principle VIII: Failure type routing
FAILURE_ROUTING = {
    "specification_failure": {
        "action": "fix_directive",
        "target": "specs/",
        "priority": "critical" if "security" in CRITERION_NAME.lower() else "high"
    },
    "generalization_failure": {
        "action": "build_evaluator",
        "target": "evaluator_backlog/",
        "priority": "normal"
    }
}

def create_test_cases() -> List[LLMTestCase]:
    """
    Create DeepEval LLMTestCase objects from goldset examples.
    Returns test cases for binary pass/fail evaluation.

    Note: DeepEval 3.x requires context to be List[str] or None
    """

    test_cases = []

    # Pass examples from goldset
    pass_examples = [
        {
            "input": "{{PASS_EXAMPLE_1_INPUT}}",
            "expected_output": "{{PASS_EXAMPLE_1_OUTPUT}}",
            "context": ["{{PASS_EXAMPLE_1_CONTEXT}}"] if "{{PASS_EXAMPLE_1_CONTEXT}}" else None,  # List[str] or None
            "expected_result": True  # Should pass
        },
        {
            "input": "{{PASS_EXAMPLE_2_INPUT}}",
            "expected_output": "{{PASS_EXAMPLE_2_OUTPUT}}",
            "context": ["{{PASS_EXAMPLE_2_CONTEXT}}"] if "{{PASS_EXAMPLE_2_CONTEXT}}" else None,  # List[str] or None
            "expected_result": True  # Should pass
        }
    ]

    # Fail examples from goldset
    fail_examples = [
        {
            "input": "{{FAIL_EXAMPLE_1_INPUT}}",
            "expected_output": "{{FAIL_EXAMPLE_1_OUTPUT}}",
            "context": ["{{FAIL_EXAMPLE_1_CONTEXT}}"] if "{{FAIL_EXAMPLE_1_CONTEXT}}" else None,  # List[str] or None
            "expected_result": False  # Should fail
        },
        {
            "input": "{{FAIL_EXAMPLE_2_INPUT}}",
            "expected_output": "{{FAIL_EXAMPLE_2_OUTPUT}}",
            "context": ["{{FAIL_EXAMPLE_2_CONTEXT}}"] if "{{FAIL_EXAMPLE_2_CONTEXT}}" else None,  # List[str] or None
            "expected_result": False  # Should fail
        }
    ]

    # Adversarial examples (from clarify phase)
    adversarial_examples = [
        {
            "input": "{{ADVERSARIAL_1_INPUT}}",
            "expected_output": "",  # We'll test actual output
            "context": ["{{ADVERSARIAL_1_CONTEXT}}"] if "{{ADVERSARIAL_1_CONTEXT}}" else None,  # List[str] or None
            "attack_vector": "{{ADVERSARIAL_1_VECTOR}}",
            "expected_result": False  # Should fail
        },
        {
            "input": "{{ADVERSARIAL_2_INPUT}}",
            "expected_output": "",  # We'll test actual output
            "context": ["{{ADVERSARIAL_2_CONTEXT}}"] if "{{ADVERSARIAL_2_CONTEXT}}" else None,  # List[str] or None
            "attack_vector": "{{ADVERSARIAL_2_VECTOR}}",
            "expected_result": False  # Should fail
        }
    ]

    # Create LLMTestCase objects (DeepEval 3.x API)
    for i, example in enumerate(pass_examples + fail_examples + adversarial_examples):
        test_case = LLMTestCase(
            input=example["input"],
            expected_output=example["expected_output"],
            context=example.get("context"),  # Pass List[str] or None directly
            additional_metadata={
                "criterion_id": CRITERION_ID,
                "example_type": "pass" if example["expected_result"] else "fail",
                "example_index": i,
                "tier": TIER,
                "failure_type": FAILURE_TYPE,
                "attack_vector": example.get("attack_vector"),
                "edd_binary_expected": example["expected_result"]
            }
        )
        test_cases.append(test_case)

    return test_cases

def create_evaluation_metrics() -> List[Any]:
    """
    Create custom DeepEval metrics from goldset criteria.
    Returns list of EDD-compliant binary metrics.
    """

    metrics = []

    {{#each_metric}}
    # {{METRIC_DESCRIPTION}}
    {{METRIC_VARIABLE_NAME}} = {{METRIC_CLASS_NAME}}(
        threshold=0.5,  # Binary threshold (pass = 1.0, fail = 0.0)
        model="gpt-4",  # LLM model for LLM-judge metrics
        include_reason=True,

        # EDD-specific configuration
        edd_compliant=True,
        binary_only=True,
        criterion_id="{{CRITERION_ID}}",
        failure_type=FAILURE_TYPE,
        tier=TIER
    )
    metrics.append({{METRIC_VARIABLE_NAME}})
    {{/each_metric}}

    return metrics

def run_evaluation(model_output_function=None, save_results=True) -> Dict[str, Any]:
    """
    Run DeepEval evaluation with EDD compliance.

    Args:
        model_output_function: Function that takes input and returns model output
        save_results: Whether to save results to disk

    Returns:
        EDD-compliant evaluation results
    """

    # Create test cases and metrics
    test_cases = create_test_cases()
    metrics = create_evaluation_metrics()

    # If no model function provided, use test outputs from goldset
    if model_output_function is None:
        # Use expected outputs from test cases (for validation)
        for test_case in test_cases:
            test_case.actual_output = test_case.expected_output
    else:
        # Generate actual outputs using provided function
        for test_case in test_cases:
            try:
                test_case.actual_output = model_output_function(
                    test_case.input,
                    test_case.context
                )
            except Exception as e:
                test_case.actual_output = f"ERROR: {str(e)}"

    # Run evaluation
    evaluation_results = evaluate(
        test_cases=test_cases,
        metrics=metrics,
        hyperparameters={
            # EDD configuration
            "edd_binary_only": True,
            "criterion_id": CRITERION_ID,
            "tier": TIER,
            "failure_type": FAILURE_TYPE,

            # Performance configuration
            "timeout_seconds": 30 if TIER == 1 else 300,  # EDD Principle IV SLA
            "max_retries": 3,
            "fail_on_error": False  # Graceful error handling
        },
        print_results=False,  # We'll handle our own output
        write_cache=False,    # Disable caching for fresh evaluation
        use_cache=False
    )

    # Process results for EDD compliance
    processed_results = _process_evaluation_results(
        evaluation_results,
        test_cases,
        metrics
    )

    # Save results if requested
    if save_results:
        _save_evaluation_results(processed_results)

    # EDD Principle VIII: Route failures appropriately
    _route_failures(processed_results)

    return processed_results

def _process_evaluation_results(evaluation_results, test_cases, metrics) -> Dict[str, Any]:
    """Process DeepEval results into EDD-compliant format."""

    # Calculate binary metrics
    total_tests = len(test_cases)
    passed_tests = sum(1 for result in evaluation_results if result.overall_score == 1.0)
    failed_tests = total_tests - passed_tests

    # Calculate confidence metrics
    confidence_scores = []
    for result in evaluation_results:
        for metric_data in result.metrics_metadata:
            if hasattr(metric_data, 'confidence'):
                confidence_scores.append(metric_data.confidence)

    avg_confidence = sum(confidence_scores) / len(confidence_scores) if confidence_scores else 0.0

    # Identify high-risk failures (EDD Principle VII)
    high_risk_failures = []
    for i, result in enumerate(evaluation_results):
        if result.overall_score == 0.0:  # Failed
            # Check if any metric has low confidence
            low_confidence = any(
                hasattr(metric_data, 'confidence') and metric_data.confidence < 0.8
                for metric_data in result.metrics_metadata
            )

            if low_confidence:
                high_risk_failures.append({
                    "test_index": i,
                    "test_case": test_cases[i],
                    "result": result,
                    "requires_annotation": True,
                    "annotation_queue": _get_annotation_queue(FAILURE_TYPE)
                })

    # Create EDD-compliant results
    return {
        # Core evaluation metrics (EDD Principle II: Binary)
        "criterion_id": CRITERION_ID,
        "criterion_name": CRITERION_NAME,
        "overall_pass": passed_tests == total_tests,
        "overall_score": 1.0 if passed_tests == total_tests else 0.0,
        "binary": True,

        # Statistical summary
        "statistics": {
            "total_tests": total_tests,
            "passed_tests": passed_tests,
            "failed_tests": failed_tests,
            "pass_rate": passed_tests / total_tests,
            "average_confidence": avg_confidence
        },

        # EDD metadata
        "edd_compliance": {
            "tier": TIER,
            "evaluator_type": EVALUATOR_TYPE,
            "failure_type": FAILURE_TYPE,
            "binary_only": True,
            "sla_compliant": True  # TODO: Add actual timing check
        },

        # Individual test results
        "test_results": [
            {
                "test_index": i,
                "input": test_cases[i].input,
                "expected_output": test_cases[i].expected_output,
                "actual_output": test_cases[i].actual_output,
                "passed": result.overall_score == 1.0,
                "score": result.overall_score,
                "binary": True,
                "metrics": [
                    {
                        "name": metric_data.metric,
                        "score": metric_data.score,
                        "reason": getattr(metric_data, 'reason', ''),
                        "confidence": getattr(metric_data, 'confidence', 0.8)
                    }
                    for metric_data in result.metrics_metadata
                ]
            }
            for i, result in enumerate(evaluation_results)
        ],

        # EDD Principle VII: Annotation routing
        "annotation": {
            "high_risk_failures": high_risk_failures,
            "requires_human_review": len(high_risk_failures) > 0,
            "annotation_queue": _get_annotation_queue(FAILURE_TYPE)
        },

        # EDD Principle VIII: Failure routing
        "failure_routing": FAILURE_ROUTING[FAILURE_TYPE],

        # Metadata
        "evaluation_metadata": {
            "framework": "deepeval",
            "generated_at": os.path.basename(__file__),
            "edd_version": "1.0.0",
            "goldset_version": "{{GOLDSET_VERSION}}",
            "configuration": EVALUATION_CONFIG
        }
    }

def _get_annotation_queue(failure_type: str) -> str:
    """Get appropriate annotation queue based on failure type."""
    if failure_type == "specification_failure":
        return "security_review_queue"
    else:
        return "quality_review_queue"

def _save_evaluation_results(results: Dict[str, Any]) -> None:
    """Save results to disk with proper EDD structure."""

    # Create results directory if it doesn't exist
    results_dir = "../results"
    os.makedirs(results_dir, exist_ok=True)

    # Save main results
    results_file = os.path.join(results_dir, f"{CRITERION_ID}_deepeval_results.json")
    with open(results_file, 'w') as f:
        json.dump(results, f, indent=2)

    # Save summary for quick access
    summary = {
        "criterion_id": CRITERION_ID,
        "overall_pass": results["overall_pass"],
        "pass_rate": results["statistics"]["pass_rate"],
        "requires_annotation": results["annotation"]["requires_human_review"],
        "failure_type": FAILURE_TYPE,
        "tier": TIER
    }

    summary_file = os.path.join(results_dir, f"{CRITERION_ID}_summary.json")
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)

    print(f"Results saved to {results_file}")
    print(f"Summary saved to {summary_file}")

def _route_failures(results: Dict[str, Any]) -> None:
    """Route failures according to EDD Principle VIII."""

    if not results["overall_pass"]:
        failure_action = FAILURE_ROUTING[FAILURE_TYPE]

        if failure_action["action"] == "fix_directive":
            _create_fix_directive(results)
        elif failure_action["action"] == "build_evaluator":
            _add_to_evaluator_backlog(results)

def _create_fix_directive(results: Dict[str, Any]) -> None:
    """Create fix directive for specification failures."""

    directives_dir = "../results/fix_directives"
    os.makedirs(directives_dir, exist_ok=True)

    directive_content = f"""# Fix Directive: {CRITERION_NAME}

## Specification Failure Detected

**Criterion**: {CRITERION_ID} - {CRITERION_NAME}
**Failure Type**: {FAILURE_TYPE}
**Priority**: {FAILURE_ROUTING[FAILURE_TYPE]['priority']}

## Summary

Evaluation failed with {results['statistics']['failed_tests']} failed tests out of {results['statistics']['total_tests']} total tests.

## Failed Test Cases

"""

    for test_result in results["test_results"]:
        if not test_result["passed"]:
            directive_content += f"""
### Test {test_result['test_index']}
- **Input**: {test_result['input']}
- **Expected**: Pass
- **Actual**: Fail
- **Reason**: {test_result['metrics'][0]['reason'] if test_result['metrics'] else 'No reason provided'}

"""

    directive_content += f"""
## Recommended Actions

1. Review specification compliance in affected areas
2. Update implementation to handle identified failure patterns
3. Re-run evaluation to verify fixes

## Priority: {FAILURE_ROUTING[FAILURE_TYPE]['priority'].upper()}
"""

    directive_file = os.path.join(directives_dir, f"{CRITERION_ID}_fix_directive.md")
    with open(directive_file, 'w') as f:
        f.write(directive_content)

    print(f"Fix directive created: {directive_file}")

def _add_to_evaluator_backlog(results: Dict[str, Any]) -> None:
    """Add to evaluator backlog for generalization failures."""

    backlog_dir = "../results/evaluator_backlog"
    os.makedirs(backlog_dir, exist_ok=True)

    backlog_content = f"""# Evaluator Backlog: {CRITERION_NAME}

## Generalization Failure Detected

**Criterion**: {CRITERION_ID} - {CRITERION_NAME}
**Failure Type**: {FAILURE_TYPE}
**Priority**: {FAILURE_ROUTING[FAILURE_TYPE]['priority']}

## Analysis

The current evaluator failed to properly assess {results['statistics']['failed_tests']} test cases. This suggests the need for:

1. Enhanced pattern detection
2. Improved semantic understanding
3. Additional training data

## Failed Patterns

"""

    for test_result in results["test_results"]:
        if not test_result["passed"]:
            backlog_content += f"- Pattern: {test_result['input'][:100]}...\n"

    backlog_content += f"""
## Recommended Evaluator Improvements

1. Analyze failed patterns for new detection rules
2. Consider hybrid evaluator approach (code + LLM)
3. Expand goldset with similar failure modes
4. Improve confidence scoring

## Priority: {FAILURE_ROUTING[FAILURE_TYPE]['priority'].upper()}
"""

    backlog_file = os.path.join(backlog_dir, f"{CRITERION_ID}_evaluator_backlog.md")
    with open(backlog_file, 'w') as f:
        f.write(backlog_content)

    print(f"Evaluator backlog entry created: {backlog_file}")

def main():
    """
    Command-line interface for DeepEval evaluation.
    Usage: python deepeval_config.py [--model-function MODULE.FUNCTION]
    """

    import argparse

    parser = argparse.ArgumentParser(description="Run EDD-compliant DeepEval evaluation")
    parser.add_argument(
        "--model-function",
        help="Module and function name for model output (e.g., 'my_model.generate')"
    )
    parser.add_argument(
        "--no-save",
        action="store_true",
        help="Don't save results to disk"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON"
    )

    args = parser.parse_args()

    # Load model function if provided
    model_function = None
    if args.model_function:
        module_name, function_name = args.model_function.rsplit('.', 1)
        module = __import__(module_name, fromlist=[function_name])
        model_function = getattr(module, function_name)

    try:
        # Run evaluation
        results = run_evaluation(
            model_output_function=model_function,
            save_results=not args.no_save
        )

        if args.json:
            print(json.dumps(results, indent=2))
        else:
            # Human-readable output
            print(f"\n=== EDD Evaluation Results: {CRITERION_NAME} ===")
            print(f"Criterion: {CRITERION_ID}")
            print(f"Overall Result: {'PASS' if results['overall_pass'] else 'FAIL'}")
            print(f"Pass Rate: {results['statistics']['pass_rate']:.2%}")
            print(f"Tests: {results['statistics']['passed_tests']}/{results['statistics']['total_tests']}")

            if results['annotation']['requires_human_review']:
                print(f"⚠️  High-risk failures require human annotation")

            print(f"Tier: {TIER} | Type: {EVALUATOR_TYPE} | Failure Type: {FAILURE_TYPE}")

    except Exception as e:
        error_result = {
            "criterion_id": CRITERION_ID,
            "overall_pass": False,
            "error": str(e),
            "binary": True,
            "edd_compliant": False
        }

        if args.json:
            print(json.dumps(error_result, indent=2))
        else:
            print(f"Evaluation error: {str(e)}")

        sys.exit(1)

if __name__ == "__main__":
    main()