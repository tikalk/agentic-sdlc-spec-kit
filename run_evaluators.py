#!/usr/bin/env python3
"""Generic evaluator execution framework.

Discovers and executes evaluators against test examples, generates structured results.
Designed to work with any evaluation project structure.
"""

import json
import sys
import importlib.util
from pathlib import Path
from datetime import datetime
from typing import Any, Dict, List, Optional, Callable
import traceback


class EvaluatorRunner:
    """Generic evaluator execution engine."""

    def __init__(
        self,
        goldset_path: Path,
        graders_dir: Path,
        results_dir: Path,
        grader_mapping: Optional[Dict[str, str]] = None
    ):
        self.goldset_path = goldset_path
        self.graders_dir = graders_dir
        self.results_dir = results_dir
        self.grader_mapping = grader_mapping or {}

    def discover_graders(self) -> Dict[str, Callable]:
        """Auto-discover grader functions from graders directory."""
        graders = {}

        if not self.graders_dir.exists():
            print(f"⚠️  Graders directory not found: {self.graders_dir}")
            return graders

        for grader_file in self.graders_dir.glob("*.py"):
            if grader_file.name.startswith("_"):
                continue

            try:
                # Load module dynamically
                spec = importlib.util.spec_from_file_location(
                    grader_file.stem, grader_file
                )
                if spec and spec.loader:
                    module = importlib.util.module_from_spec(spec)
                    spec.loader.exec_module(module)

                    # Look for grade() or evaluate() function
                    if hasattr(module, "grade"):
                        graders[grader_file.stem] = module.grade
                    elif hasattr(module, "evaluate"):
                        graders[grader_file.stem] = module.evaluate

            except Exception as e:
                print(f"⚠️  Failed to load grader {grader_file.name}: {e}")

        return graders

    def load_goldset(self) -> Dict[str, Any]:
        """Load test examples from goldset file."""
        if not self.goldset_path.exists():
            raise FileNotFoundError(f"Goldset not found: {self.goldset_path}")

        with open(self.goldset_path) as f:
            data = json.load(f)

        # Support multiple goldset formats
        if "evaluations" in data:
            return data
        elif "examples" in data:
            # Flat format - wrap into evaluations structure
            return {
                "version": data.get("version", "1.0"),
                "evaluations": [{"id": "default", "name": "Evaluation", "examples": data["examples"]}]
            }
        else:
            raise ValueError(f"Unknown goldset format in {self.goldset_path}")

    def normalize_input(self, example_input: Any) -> str:
        """Convert example input to string for grader."""
        if isinstance(example_input, dict):
            return json.dumps(example_input)
        elif isinstance(example_input, list):
            return ", ".join(str(x) for x in example_input)
        else:
            return str(example_input)

    def run_grader(
        self,
        grader_fn: Callable,
        example: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Execute grader function against single example."""
        example_input = example.get("input", "")
        expected_output = example.get("expected_output")
        expected_pass = example.get("expected_pass", True)
        context = example.get("context")

        input_str = self.normalize_input(example_input)

        try:
            # Try different grader signatures
            result = None

            # Signature 1: grade(output, context) - promptfoo style
            try:
                result = grader_fn(input_str, context)
            except TypeError:
                pass

            # Signature 2: evaluate(input) - simple style
            if result is None:
                try:
                    result = grader_fn(input_str)
                except TypeError:
                    pass

            # Signature 3: evaluate(input, expected) - comparison style
            if result is None and expected_output is not None:
                result = grader_fn(input_str, expected_output)

            if result is None:
                return {
                    "pass": False,
                    "error": "Could not call grader with any known signature"
                }

            # Normalize result format
            if isinstance(result, bool):
                return {"pass": result}
            elif isinstance(result, dict):
                if "pass" not in result and "score" in result:
                    result["pass"] = result["score"] >= 0.5
                return result
            else:
                return {"pass": bool(result)}

        except Exception as e:
            return {
                "pass": False,
                "error": str(e),
                "traceback": traceback.format_exc()
            }

    def evaluate_criterion(
        self,
        criterion: Dict[str, Any],
        graders: Dict[str, Callable]
    ) -> Dict[str, Any]:
        """Evaluate all examples for single criterion."""
        criterion_id = criterion["id"]
        criterion_name = criterion.get("name", criterion_id)

        print(f"\n📊 Evaluating {criterion_id}: {criterion_name}")

        results = {
            "criterion_id": criterion_id,
            "criterion_name": criterion_name,
            "examples_evaluated": 0,
            "passed": 0,
            "failed": 0,
            "errors": 0,
            "example_results": []
        }

        # Find grader for this criterion
        grader_name = self.grader_mapping.get(criterion_id, criterion_id)
        grader_fn = graders.get(grader_name)

        if not grader_fn:
            print(f"  ⚠️  No grader found for {criterion_id} (tried: {grader_name})")
            print(f"      Available graders: {list(graders.keys())}")
            return results

        # Evaluate each example
        for i, example in enumerate(criterion.get("examples", []), 1):
            grader_result = self.run_grader(grader_fn, example)

            expected_pass = example.get("expected_pass", True)
            grader_pass = grader_result.get("pass", False)
            has_error = "error" in grader_result

            matches_expected = (grader_pass == expected_pass)

            example_result = {
                "example_number": i,
                "input": example.get("input"),
                "expected_pass": expected_pass,
                "grader_pass": grader_pass,
                "matches_expected": matches_expected,
                "grader_output": grader_result
            }

            results["example_results"].append(example_result)
            results["examples_evaluated"] += 1

            if has_error:
                results["errors"] += 1
                status = "⚠️ "
            elif matches_expected:
                results["passed"] += 1
                status = "✅"
            else:
                results["failed"] += 1
                status = "❌"

            example_type = example.get("type", "test")
            print(f"  {status} Example {i} ({example_type}): Expected {expected_pass}, Got {grader_pass}")

        # Calculate metrics
        if results["examples_evaluated"] > 0:
            results["accuracy"] = results["passed"] / results["examples_evaluated"]
            print(f"  📈 Accuracy: {results['passed']}/{results['examples_evaluated']} ({results['accuracy']*100:.1f}%)")

        return results

    def run(self) -> Dict[str, Any]:
        """Execute full evaluation run."""
        print("🚀 Starting evaluation...")

        # Load components
        goldset = self.load_goldset()
        graders = self.discover_graders()

        print(f"📦 Loaded {len(graders)} graders: {list(graders.keys())}")

        results = {
            "execution_date": datetime.now().isoformat(),
            "goldset_version": goldset.get("version", "unknown"),
            "goldset_path": str(self.goldset_path),
            "graders_discovered": len(graders),
            "criteria_results": {}
        }

        total_pass = 0
        total_fail = 0
        total_error = 0

        # Evaluate each criterion
        for criterion in goldset.get("evaluations", []):
            criterion_results = self.evaluate_criterion(criterion, graders)
            results["criteria_results"][criterion["id"]] = criterion_results

            total_pass += criterion_results["passed"]
            total_fail += criterion_results["failed"]
            total_error += criterion_results["errors"]

        # Summary
        total_evaluated = total_pass + total_fail + total_error
        overall_accuracy = total_pass / total_evaluated if total_evaluated > 0 else 0

        results["summary"] = {
            "total_evaluated": total_evaluated,
            "total_passed": total_pass,
            "total_failed": total_fail,
            "total_errors": total_error,
            "overall_accuracy": overall_accuracy
        }

        # Save results
        self.results_dir.mkdir(parents=True, exist_ok=True)
        results_file = self.results_dir / f"evaluation_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

        with open(results_file, "w") as f:
            json.dump(results, f, indent=2)

        # Also save as latest
        latest_file = self.results_dir / "evaluation_results_latest.json"
        with open(latest_file, "w") as f:
            json.dump(results, f, indent=2)

        print(f"\n\n📊 EVALUATION SUMMARY")
        print(f"{'='*50}")
        print(f"Total Examples: {total_evaluated}")
        print(f"Passed: {total_pass}")
        print(f"Failed: {total_fail}")
        print(f"Errors: {total_error}")
        print(f"Overall Accuracy: {overall_accuracy*100:.1f}%")
        print(f"\n✅ Results saved to: {results_file}")

        return results


def main():
    """Main entry point with configurable paths."""
    import argparse

    parser = argparse.ArgumentParser(description="Run evaluators against goldset")
    parser.add_argument(
        "--goldset",
        type=Path,
        default=Path("evals/goldset.json"),
        help="Path to goldset file"
    )
    parser.add_argument(
        "--graders",
        type=Path,
        default=Path("evals/graders"),
        help="Path to graders directory"
    )
    parser.add_argument(
        "--results",
        type=Path,
        default=Path("evals/results"),
        help="Path to results output directory"
    )
    parser.add_argument(
        "--mapping",
        type=Path,
        help="Path to JSON file mapping criterion IDs to grader names"
    )
    parser.add_argument(
        "--pass-threshold",
        type=float,
        default=0.8,
        help="Minimum accuracy threshold for success (default: 0.8)"
    )

    args = parser.parse_args()

    # Load grader mapping if provided
    grader_mapping = {}
    if args.mapping and args.mapping.exists():
        with open(args.mapping) as f:
            grader_mapping = json.load(f)

    # Run evaluation
    runner = EvaluatorRunner(
        goldset_path=args.goldset,
        graders_dir=args.graders,
        results_dir=args.results,
        grader_mapping=grader_mapping
    )

    results = runner.run()

    # Exit with appropriate code
    success = results["summary"]["overall_accuracy"] >= args.pass_threshold
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()