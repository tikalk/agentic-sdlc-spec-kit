#!/usr/bin/env python3
"""
Simple Validation Runner for DeepEval
Bypasses DeepEval's evaluate() function and uses direct measure() calls.

This script provides a workaround for async compatibility issues by:
1. Loading test cases from goldset.json
2. Running metric.measure() directly on each test case
3. Collecting and reporting results manually

Template Variables (if used as template):
- {{METRIC_FILE}}: Metric module filename (e.g., "regulatory_compliance_metric")
- {{METRIC_CLASS_NAME}}: Metric class name (e.g., "RegulatoryComplianceMetric")
- {{CRITERION_ID}}: Criterion identifier from goldset
- {{CRITERION_NAME}}: Criterion name from goldset

Usage:
    python run_validation_simple.py [--dataset training|holdout|all] [--goldset goldset.json]
"""

import json
import sys
import argparse
from pathlib import Path
from typing import List, Dict, Any, Optional
from deepeval.test_case import LLMTestCase

# Import custom metric
# NOTE: When using as template, replace with actual imports
# from graders.{{METRIC_FILE}} import {{METRIC_CLASS_NAME}}


def load_goldset(goldset_path: Path) -> Dict[str, Any]:
    """Load goldset.json file."""
    if not goldset_path.exists():
        raise FileNotFoundError(f"Goldset file not found: {goldset_path}")

    with open(goldset_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def create_test_case(example: Dict[str, Any], example_type: str) -> LLMTestCase:
    """
    Create a DeepEval LLMTestCase from a goldset example.

    Args:
        example: Example dict from goldset.json
        example_type: "pass", "fail", or "adversarial"

    Returns:
        LLMTestCase instance
    """
    # Determine expected result
    expected_result = (example_type == "pass")

    # Create test case (DeepEval 3.x API)
    return LLMTestCase(
        input=example.get("input", ""),
        expected_output=example.get("expected_output", ""),
        actual_output=example.get("expected_output", ""),  # For validation, use expected as actual
        context=example.get("context"),  # List[str] or None
        additional_metadata={
            "example_type": example_type,
            "expected_result": expected_result,
            "attack_vector": example.get("attack_vector")
        }
    )


def split_dataset(goldset: Dict[str, Any], dataset_type: str = "all") -> Dict[str, List[Dict[str, Any]]]:
    """
    Split dataset into training/holdout sets.

    Args:
        goldset: Loaded goldset data
        dataset_type: "training", "holdout", or "all"

    Returns:
        Dict with pass_examples, fail_examples, adversarial_examples
    """
    all_pass = goldset.get("pass_examples", [])
    all_fail = goldset.get("fail_examples", [])
    all_adversarial = goldset.get("adversarial_examples", [])

    if dataset_type == "all":
        return {
            "pass_examples": all_pass,
            "fail_examples": all_fail,
            "adversarial_examples": all_adversarial
        }

    # Split each category 80/20 (training/holdout)
    def split_list(items: List[Any], holdout: bool = False) -> List[Any]:
        if not items:
            return []
        split_idx = int(len(items) * 0.8)
        if holdout:
            return items[split_idx:]
        else:
            return items[:split_idx]

    is_holdout = (dataset_type == "holdout")

    return {
        "pass_examples": split_list(all_pass, is_holdout),
        "fail_examples": split_list(all_fail, is_holdout),
        "adversarial_examples": split_list(all_adversarial, is_holdout)
    }


def run_validation(metric, test_cases: List[LLMTestCase], verbose: bool = False) -> Dict[str, Any]:
    """
    Run validation using direct metric.measure() calls.

    Args:
        metric: DeepEval metric instance
        test_cases: List of LLMTestCase instances
        verbose: Print detailed results

    Returns:
        Results dictionary with statistics and individual test results
    """
    results = {
        "total": len(test_cases),
        "passed": 0,
        "failed": 0,
        "errors": 0,
        "test_results": []
    }

    for i, test_case in enumerate(test_cases):
        try:
            # Run metric measurement directly (synchronous)
            # Using _show_indicator=False to suppress progress indicator
            score = metric.measure(test_case, _show_indicator=False)

            # Get expected result from metadata
            expected_result = test_case.additional_metadata.get("expected_result", True)
            expected_score = 1.0 if expected_result else 0.0

            # Check if result matches expectation
            passed = (score == expected_score)

            if passed:
                results["passed"] += 1
            else:
                results["failed"] += 1

            # Collect result details
            test_result = {
                "test_index": i,
                "input": test_case.input[:100] + "..." if len(test_case.input) > 100 else test_case.input,
                "expected_score": expected_score,
                "actual_score": score,
                "passed": passed,
                "reason": getattr(metric, 'reason', 'No reason provided'),
                "example_type": test_case.additional_metadata.get("example_type", "unknown")
            }

            results["test_results"].append(test_result)

            if verbose:
                status = "✓ PASS" if passed else "✗ FAIL"
                print(f"Test {i+1}/{len(test_cases)}: {status} (score: {score}, expected: {expected_score})")
                if not passed:
                    print(f"  Reason: {test_result['reason']}")

        except Exception as e:
            results["errors"] += 1
            error_result = {
                "test_index": i,
                "input": test_case.input[:100] + "...",
                "error": str(e),
                "passed": False,
                "example_type": test_case.additional_metadata.get("example_type", "unknown")
            }
            results["test_results"].append(error_result)

            if verbose:
                print(f"Test {i+1}/{len(test_cases)}: ✗ ERROR - {str(e)}")

    # Calculate statistics
    results["pass_rate"] = results["passed"] / results["total"] if results["total"] > 0 else 0.0

    # Calculate TPR (True Positive Rate) and TNR (True Negative Rate)
    true_positives = sum(1 for r in results["test_results"]
                         if r.get("passed") and r.get("example_type") == "pass")
    true_negatives = sum(1 for r in results["test_results"]
                         if r.get("passed") and r.get("example_type") in ["fail", "adversarial"])
    total_positives = sum(1 for r in results["test_results"] if r.get("example_type") == "pass")
    total_negatives = sum(1 for r in results["test_results"] if r.get("example_type") in ["fail", "adversarial"])

    results["tpr"] = true_positives / total_positives if total_positives > 0 else 0.0
    results["tnr"] = true_negatives / total_negatives if total_negatives > 0 else 0.0

    return results


def print_summary(results: Dict[str, Any], criterion_name: str, dataset_type: str) -> None:
    """Print validation summary."""
    print("\n" + "=" * 70)
    print(f"Validation Results: {criterion_name}")
    print(f"Dataset: {dataset_type}")
    print("=" * 70)
    print(f"Total tests: {results['total']}")
    print(f"Passed: {results['passed']} ({results['pass_rate']:.1%})")
    print(f"Failed: {results['failed']}")
    print(f"Errors: {results['errors']}")
    print(f"\nTPR (True Positive Rate): {results['tpr']:.1%}")
    print(f"TNR (True Negative Rate): {results['tnr']:.1%}")

    if results['failed'] > 0:
        print(f"\n⚠️  {results['failed']} test(s) failed:")
        for test_result in results['test_results']:
            if not test_result.get('passed', False) and 'error' not in test_result:
                print(f"  - Test {test_result['test_index'] + 1} ({test_result['example_type']}): {test_result.get('reason', 'No reason')}")

    if results['errors'] > 0:
        print(f"\n❌ {results['errors']} test(s) encountered errors:")
        for test_result in results['test_results']:
            if 'error' in test_result:
                print(f"  - Test {test_result['test_index'] + 1}: {test_result['error']}")

    # Overall result
    if results['passed'] == results['total'] and results['errors'] == 0:
        print("\n✅ All tests passed!")
    else:
        print("\n❌ Some tests failed or encountered errors")

    print("=" * 70)


def save_results(results: Dict[str, Any], output_path: Path) -> None:
    """Save results to JSON file."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"\n💾 Results saved to: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Run DeepEval validation with direct measure() calls"
    )
    parser.add_argument(
        "--goldset",
        type=Path,
        default=Path("goldset.json"),
        help="Path to goldset.json file (default: goldset.json)"
    )
    parser.add_argument(
        "--dataset",
        choices=["training", "holdout", "all"],
        default="all",
        help="Dataset split to use: training (80%%), holdout (20%%), or all (default: all)"
    )
    parser.add_argument(
        "--metric",
        type=str,
        help="Metric module and class (e.g., 'graders.my_metric.MyMetric')"
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Path to save results JSON (default: results/validation_results.json)"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print detailed test results"
    )

    args = parser.parse_args()

    try:
        # Load goldset
        print(f"📖 Loading goldset from {args.goldset}...")
        goldset = load_goldset(args.goldset)

        criterion_id = goldset.get("metadata", {}).get("criterion_id", "unknown")
        criterion_name = goldset.get("metadata", {}).get("criterion_name", "Unknown Criterion")

        # Import metric if provided
        if args.metric:
            module_path, class_name = args.metric.rsplit('.', 1)
            module = __import__(module_path, fromlist=[class_name])
            MetricClass = getattr(module, class_name)

            # Initialize metric
            metric = MetricClass(
                threshold=0.5,
                include_reason=True,
                async_mode=False,  # Force synchronous mode
                edd_compliant=True,
                binary_only=True
            )
        else:
            print("Error: --metric is required", file=sys.stderr)
            print("Example: --metric graders.my_metric.MyMetric", file=sys.stderr)
            sys.exit(1)

        # Split dataset
        print(f"📊 Using dataset: {args.dataset}")
        dataset = split_dataset(goldset, args.dataset)

        # Create test cases
        test_cases = []
        for example in dataset["pass_examples"]:
            test_cases.append(create_test_case(example, "pass"))
        for example in dataset["fail_examples"]:
            test_cases.append(create_test_case(example, "fail"))
        for example in dataset["adversarial_examples"]:
            test_cases.append(create_test_case(example, "adversarial"))

        print(f"🧪 Running validation on {len(test_cases)} test cases...")

        # Run validation
        results = run_validation(metric, test_cases, verbose=args.verbose)

        # Add metadata to results
        results["metadata"] = {
            "criterion_id": criterion_id,
            "criterion_name": criterion_name,
            "dataset": args.dataset,
            "goldset_source": str(args.goldset)
        }

        # Print summary
        print_summary(results, criterion_name, args.dataset)

        # Save results
        if args.output:
            output_path = args.output
        else:
            output_path = Path("results") / f"{criterion_id}_validation_{args.dataset}.json"

        save_results(results, output_path)

        # Exit with appropriate code
        if results['failed'] > 0 or results['errors'] > 0:
            sys.exit(1)
        else:
            sys.exit(0)

    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
