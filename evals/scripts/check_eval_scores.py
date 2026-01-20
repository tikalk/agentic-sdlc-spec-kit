#!/usr/bin/env python3
"""
Check evaluation scores from PromptFoo output.

This script validates that evaluation scores meet minimum thresholds
for use in CI/CD pipelines.
"""

import json
import sys
import argparse
from typing import Dict, List, Any


def load_results(file_path: str) -> Dict[str, Any]:
    """Load PromptFoo results from JSON file."""
    try:
        with open(file_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"❌ Error: Results file not found: {file_path}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON in results file: {e}", file=sys.stderr)
        sys.exit(1)


def is_api_error(result: Dict[str, Any]) -> bool:
    """Check if a result is an API error (rate limit, timeout, etc.)."""
    error = result.get('error', '')
    if isinstance(error, str):
        return 'Rate limited' in error or '429' in error or 'timeout' in error.lower()
    return False


def calculate_stats(results: Dict[str, Any], exclude_api_errors: bool = False) -> Dict[str, Any]:
    """Calculate statistics from evaluation results."""
    test_results = results.get('results', [])

    if not test_results:
        return {
            'total': 0,
            'passed': 0,
            'failed': 0,
            'errors': 0,
            'pass_rate': 0.0,
            'average_score': 0.0,
            'min_score': 0.0,
            'max_score': 0.0
        }

    # Count API errors separately
    api_errors = sum(1 for r in test_results if is_api_error(r))

    # Filter out API errors if requested
    if exclude_api_errors:
        test_results = [r for r in test_results if not is_api_error(r)]

    total = len(test_results)
    passed = sum(1 for r in test_results if r.get('success', False))
    failed = total - passed

    scores = [r.get('score', 0) for r in test_results if 'score' in r and r.get('score', 0) > 0]
    average_score = sum(scores) / len(scores) if scores else 0.0
    min_score = min(scores) if scores else 0.0
    max_score = max(scores) if scores else 0.0

    return {
        'total': total,
        'passed': passed,
        'failed': failed,
        'errors': api_errors,
        'pass_rate': passed / total if total > 0 else 0.0,
        'average_score': average_score,
        'min_score': min_score,
        'max_score': max_score
    }


def print_summary(stats: Dict[str, Any], results: Dict[str, Any]) -> None:
    """Print evaluation summary."""
    print("\n" + "="*60)
    print("📊 Evaluation Summary")
    print("="*60)
    print(f"Total Tests:    {stats['total']}")
    print(f"Passed:         {stats['passed']} ✅")
    print(f"Failed:         {stats['failed']} ❌")
    if stats.get('errors', 0) > 0:
        print(f"API Errors:     {stats['errors']} ⚠️  (excluded from pass rate)")
    print(f"Pass Rate:      {stats['pass_rate']:.1%}")
    print(f"Average Score:  {stats['average_score']:.2f}")
    print(f"Score Range:    {stats['min_score']:.2f} - {stats['max_score']:.2f}")
    print("="*60)

    # Show failed tests
    if stats['failed'] > 0:
        print("\n❌ Failed Tests:")
        for i, result in enumerate(results.get('results', []), 1):
            if not result.get('success', False):
                test_name = result.get('description', f'Test {i}')
                score = result.get('score', 0)
                print(f"  {i}. {test_name} (score: {score:.2f})")


def check_thresholds(
    stats: Dict[str, Any],
    min_score: float,
    min_pass_rate: float
) -> bool:
    """Check if results meet minimum thresholds."""
    score_ok = stats['average_score'] >= min_score
    pass_rate_ok = stats['pass_rate'] >= min_pass_rate

    print("\n" + "="*60)
    print("🎯 Threshold Checks")
    print("="*60)

    # Check average score
    score_status = "✅ PASS" if score_ok else "❌ FAIL"
    print(f"Average Score:  {stats['average_score']:.2f} >= {min_score:.2f}  {score_status}")

    # Check pass rate
    pass_status = "✅ PASS" if pass_rate_ok else "❌ FAIL"
    print(f"Pass Rate:      {stats['pass_rate']:.1%} >= {min_pass_rate:.1%}  {pass_status}")

    print("="*60)

    return score_ok and pass_rate_ok


def main():
    parser = argparse.ArgumentParser(
        description='Check PromptFoo evaluation scores against thresholds'
    )
    parser.add_argument(
        '--results',
        required=True,
        help='Path to PromptFoo results JSON file'
    )
    parser.add_argument(
        '--min-score',
        type=float,
        default=0.75,
        help='Minimum average score threshold (default: 0.75)'
    )
    parser.add_argument(
        '--min-pass-rate',
        type=float,
        default=0.80,
        help='Minimum pass rate threshold (default: 0.80 = 80%%)'
    )
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Show detailed test results'
    )
    parser.add_argument(
        '--allow-api-errors',
        action='store_true',
        help='Exclude API errors (rate limits, timeouts) from pass rate calculation'
    )

    args = parser.parse_args()

    # Load results
    results = load_results(args.results)

    # Calculate stats
    stats = calculate_stats(results, exclude_api_errors=args.allow_api_errors)

    # Print summary
    print_summary(stats, results)

    # Show detailed results if verbose
    if args.verbose:
        print("\n" + "="*60)
        print("📋 Detailed Results")
        print("="*60)
        for i, result in enumerate(results.get('results', []), 1):
            test_name = result.get('description', f'Test {i}')
            success = result.get('success', False)
            score = result.get('score', 0)
            status = "✅" if success else "❌"
            print(f"{i}. {status} {test_name}")
            print(f"   Score: {score:.2f}")
            if not success and 'error' in result:
                print(f"   Error: {result['error']}")
            print()

    # Check thresholds
    passed = check_thresholds(stats, args.min_score, args.min_pass_rate)

    if passed:
        print("\n✅ All quality thresholds met!")
        sys.exit(0)
    else:
        print("\n❌ Quality thresholds not met. Please review failures.")
        sys.exit(1)


if __name__ == '__main__':
    main()