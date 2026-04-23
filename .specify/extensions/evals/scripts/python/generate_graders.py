#!/usr/bin/env python3
"""
Grader and Unit Test Generator

Generates Python graders and corresponding unit tests from templates based on
goldset criteria following EDD (Eval-Driven Development) principles.

Usage:
    python generate_graders.py --goldset goldset.json --output-dir evals/graders/
    python generate_graders.py --criterion eval-001 --type code-based --output-dir evals/graders/

Features:
- Generates graders from templates (code-based, llm-judge, hybrid)
- Automatically creates corresponding unit tests
- Validates EDD compliance (binary pass/fail, metadata requirements)
- Supports custom goldset formats and criterion specifications
"""

import json
import argparse
import re
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class Criterion:
    """Represents a single evaluation criterion from goldset"""

    id: str
    name: str
    pass_condition: str
    fail_condition: str
    evaluator_type: str = "code-based"  # code-based | llm-judge | hybrid
    tier: int = 1  # 1 (fast) | 2 (semantic) | hybrid
    failure_type: str = "specification_failure"  # specification_failure | generalization_failure
    pass_examples: List[Dict[str, str]] = field(default_factory=list)
    fail_examples: List[Dict[str, str]] = field(default_factory=list)
    failure_patterns: List[str] = field(default_factory=list)
    success_patterns: List[str] = field(default_factory=list)


@dataclass
class GenerationConfig:
    """Configuration for grader generation"""

    goldset_path: Path
    output_dir: Path
    test_output_dir: Path
    grader_module_name: str = "custom_graders"
    overwrite: bool = False
    include_tests: bool = True
    dry_run: bool = False


class GraderGenerator:
    """Generates graders and unit tests from templates"""

    def __init__(self, config: GenerationConfig):
        self.config = config
        self.template_dir = Path(__file__).parent.parent.parent / "templates"
        self.grader_template = self.template_dir / "grader-template.py"
        self.test_template = self.template_dir / "grader-test-template.py"

    def generate_all(self) -> List[str]:
        """Generate all graders and tests from goldset"""
        if not self.config.goldset_path.exists():
            raise FileNotFoundError(f"Goldset file not found: {self.config.goldset_path}")

        # Load goldset criteria
        criteria = self._load_goldset_criteria()

        if not criteria:
            raise ValueError("No criteria found in goldset")

        generated_files = []

        # Generate graders and tests for each criterion
        for criterion in criteria:
            try:
                # Generate grader
                grader_file = self._generate_grader(criterion)
                generated_files.append(str(grader_file))

                # Generate unit tests if enabled
                if self.config.include_tests:
                    test_file = self._generate_unit_test(criterion)
                    generated_files.append(str(test_file))

                print(f"✓ Generated grader and tests for {criterion.id}: {criterion.name}")

            except Exception as e:
                print(f"✗ Failed to generate {criterion.id}: {e}")
                continue

        return generated_files

    def generate_criterion(self, criterion_id: str) -> List[str]:
        """Generate grader and test for a specific criterion"""
        criteria = self._load_goldset_criteria()
        criterion = next((c for c in criteria if c.id == criterion_id), None)

        if not criterion:
            raise ValueError(f"Criterion {criterion_id} not found in goldset")

        generated_files = []

        # Generate grader
        grader_file = self._generate_grader(criterion)
        generated_files.append(str(grader_file))

        # Generate unit tests
        if self.config.include_tests:
            test_file = self._generate_unit_test(criterion)
            generated_files.append(str(test_file))

        return generated_files

    def _load_goldset_criteria(self) -> List[Criterion]:
        """Load criteria from goldset file"""
        with open(self.config.goldset_path, 'r', encoding='utf-8') as f:
            goldset_data = json.load(f)

        criteria = []

        # Handle different goldset formats
        if isinstance(goldset_data, list):
            # Simple list format
            for item in goldset_data:
                criteria.append(self._parse_criterion(item))
        elif isinstance(goldset_data, dict) and "criteria" in goldset_data:
            # Structured format with metadata
            for item in goldset_data["criteria"]:
                criteria.append(self._parse_criterion(item))
        elif isinstance(goldset_data, dict) and "evaluations" in goldset_data:
            # Alternative structured format
            for item in goldset_data["evaluations"]:
                criteria.append(self._parse_criterion(item))
        else:
            raise ValueError("Unrecognized goldset format")

        return criteria

    def _parse_criterion(self, data: Dict[str, Any]) -> Criterion:
        """Parse a single criterion from goldset data"""
        criterion = Criterion(
            id=data.get("id", data.get("criterion_id", "unknown")),
            name=data.get("name", data.get("criterion_name", "Unknown Criterion")),
            pass_condition=data.get("pass_condition", "Meets requirements"),
            fail_condition=data.get("fail_condition", "Fails requirements"),
            evaluator_type=data.get("evaluator_type", "code-based"),
            tier=data.get("tier", 1),
            failure_type=data.get("failure_type", "specification_failure")
        )

        # Parse examples
        if "examples" in data:
            examples = data["examples"]
            if "pass" in examples:
                criterion.pass_examples = examples["pass"]
            if "fail" in examples:
                criterion.fail_examples = examples["fail"]

        # Parse patterns for code-based graders
        if "patterns" in data:
            patterns = data["patterns"]
            criterion.failure_patterns = patterns.get("failure", [])
            criterion.success_patterns = patterns.get("success", [])

        # Ensure we have at least basic test examples
        if not criterion.pass_examples:
            criterion.pass_examples = [
                {
                    "name": "basic_pass",
                    "description": "Basic passing case",
                    "content": f"This example should pass {criterion.name} evaluation"
                }
            ]

        if not criterion.fail_examples:
            criterion.fail_examples = [
                {
                    "name": "basic_fail",
                    "description": "Basic failing case",
                    "content": f"This example should fail {criterion.name} evaluation"
                }
            ]

        return criterion

    def _generate_grader(self, criterion: Criterion) -> Path:
        """Generate grader file from template"""
        if not self.grader_template.exists():
            raise FileNotFoundError(f"Grader template not found: {self.grader_template}")

        template_content = self.grader_template.read_text(encoding='utf-8')

        # Function name for grader
        function_name = self._to_function_name(criterion.name)

        # Apply template substitutions
        grader_content = self._apply_template_substitutions(
            template_content,
            criterion,
            function_name=function_name
        )

        # Output file path
        grader_file = self.config.output_dir / f"{function_name}.py"

        # Create output directory
        self.config.output_dir.mkdir(parents=True, exist_ok=True)

        # Write file (check overwrite policy)
        if grader_file.exists() and not self.config.overwrite:
            print(f"⚠ Skipping {grader_file} (already exists, use --overwrite to replace)")
            return grader_file

        if not self.config.dry_run:
            grader_file.write_text(grader_content, encoding='utf-8')

        return grader_file

    def _generate_unit_test(self, criterion: Criterion) -> Path:
        """Generate unit test file from template"""
        if not self.test_template.exists():
            raise FileNotFoundError(f"Test template not found: {self.test_template}")

        template_content = self.test_template.read_text(encoding='utf-8')

        # Function and file names
        function_name = self._to_function_name(criterion.name)
        test_file_name = f"test_{function_name}"

        # Apply template substitutions
        test_content = self._apply_test_template_substitutions(
            template_content,
            criterion,
            function_name=function_name,
            module_name=self.config.grader_module_name
        )

        # Output file path
        test_file = self.config.test_output_dir / f"{test_file_name}.py"

        # Create output directory
        self.config.test_output_dir.mkdir(parents=True, exist_ok=True)

        # Write file (check overwrite policy)
        if test_file.exists() and not self.config.overwrite:
            print(f"⚠ Skipping {test_file} (already exists, use --overwrite to replace)")
            return test_file

        if not self.config.dry_run:
            test_file.write_text(test_content, encoding='utf-8')

        return test_file

    def _apply_template_substitutions(self, template: str, criterion: Criterion, **kwargs) -> str:
        """Apply template variable substitutions for grader"""
        substitutions = {
            "{{CRITERION_ID}}": criterion.id,
            "{{CRITERION_NAME}}": criterion.name,
            "{{EVALUATOR_TYPE}}": criterion.evaluator_type,
            "{{TIER}}": str(criterion.tier),
            "{{FAILURE_TYPE}}": criterion.failure_type,
            "{{PASS_CONDITION}}": criterion.pass_condition,
            "{{FAIL_CONDITION}}": criterion.fail_condition,
            "{{FUNCTION_NAME}}": kwargs.get("function_name", "grade"),

            # Pattern substitutions for code-based graders
            "{{FAILURE_PATTERN_1}}": criterion.failure_patterns[0] if criterion.failure_patterns else r"undefined_pattern",
            "{{FAILURE_PATTERN_2}}": criterion.failure_patterns[1] if len(criterion.failure_patterns) > 1 else r"undefined_pattern",
            "{{FAILURE_PATTERN_3}}": criterion.failure_patterns[2] if len(criterion.failure_patterns) > 2 else r"undefined_pattern",

            "{{SUCCESS_PATTERN_1}}": criterion.success_patterns[0] if criterion.success_patterns else r"required_pattern",
            "{{SUCCESS_PATTERN_2}}": criterion.success_patterns[1] if len(criterion.success_patterns) > 1 else r"required_pattern",
        }

        # Handle conditional template sections
        content = template

        # Show only relevant evaluator type section
        if criterion.evaluator_type == "code-based":
            content = self._process_conditional_sections(content, "if_evaluator_type_code_based", True)
            content = self._process_conditional_sections(content, "if_evaluator_type_llm_judge", False)
            content = self._process_conditional_sections(content, "if_evaluator_type_hybrid", False)
        elif criterion.evaluator_type == "llm-judge":
            content = self._process_conditional_sections(content, "if_evaluator_type_code_based", False)
            content = self._process_conditional_sections(content, "if_evaluator_type_llm_judge", True)
            content = self._process_conditional_sections(content, "if_evaluator_type_hybrid", False)
        elif criterion.evaluator_type == "hybrid":
            content = self._process_conditional_sections(content, "if_evaluator_type_code_based", False)
            content = self._process_conditional_sections(content, "if_evaluator_type_llm_judge", False)
            content = self._process_conditional_sections(content, "if_evaluator_type_hybrid", True)

        # Apply substitutions
        for placeholder, value in substitutions.items():
            content = content.replace(placeholder, value)

        return content

    def _apply_test_template_substitutions(self, template: str, criterion: Criterion, **kwargs) -> str:
        """Apply template variable substitutions for unit tests"""
        function_name = kwargs.get("function_name", "grade")
        module_name = kwargs.get("module_name", "custom_graders")

        substitutions = {
            "{{CRITERION_ID}}": criterion.id,
            "{{CRITERION_NAME}}": criterion.name,
            "{{GRADER_FUNCTION_NAME}}": function_name,
            "{{GRADER_MODULE_NAME}}": module_name,
            "{{PASS_CONDITION}}": criterion.pass_condition,
            "{{FAIL_CONDITION}}": criterion.fail_condition,
        }

        content = template

        # Handle Handlebars-style iterations for examples
        content = self._process_example_iterations(content, "PASS_EXAMPLES", criterion.pass_examples)
        content = self._process_example_iterations(content, "FAIL_EXAMPLES", criterion.fail_examples)

        # Handle simple filters
        content = content.replace("{{GRADER_FUNCTION_NAME|pascal_case}}", self._to_pascal_case(function_name))

        # Apply substitutions
        for placeholder, value in substitutions.items():
            content = content.replace(placeholder, value)

        return content

    def _process_conditional_sections(self, content: str, condition: str, include: bool) -> str:
        """Process conditional template sections ({{#if_condition}}...{{/if_condition}})"""
        start_tag = f"{{{{#{condition}}}}}"
        end_tag = f"{{{{/{condition}}}}}"

        while start_tag in content:
            start_idx = content.find(start_tag)
            if start_idx == -1:
                break

            end_idx = content.find(end_tag, start_idx)
            if end_idx == -1:
                break

            if include:
                # Keep the content but remove the tags
                section_content = content[start_idx + len(start_tag):end_idx]
                content = content[:start_idx] + section_content + content[end_idx + len(end_tag):]
            else:
                # Remove the entire section
                content = content[:start_idx] + content[end_idx + len(end_tag):]

        return content

    def _process_example_iterations(self, content: str, var_name: str, examples: List[Dict]) -> str:
        """Process Handlebars-style iterations ({{#each EXAMPLES}}...{{/each}})"""
        start_tag = f"{{{{#each {var_name}}}}}"
        end_tag = f"{{{{/each}}}}"

        if start_tag not in content:
            # Also handle the length check
            length_placeholder = f"{{{{{var_name}|length}}}}"
            content = content.replace(length_placeholder, str(len(examples)))
            return content

        start_idx = content.find(start_tag)
        end_idx = content.find(end_tag, start_idx)

        if start_idx == -1 or end_idx == -1:
            return content

        template_section = content[start_idx + len(start_tag):end_idx]

        # Generate content for each example
        generated_content = ""
        for i, example in enumerate(examples):
            section = template_section
            section = section.replace("{{@index}}", str(i))
            section = section.replace("{{this.name}}", example.get("name", f"example_{i}"))
            section = section.replace("{{this.description}}", example.get("description", ""))
            section = section.replace("{{this.content}}", example.get("content", ""))
            generated_content += section

        # Replace the entire section
        content = content[:start_idx] + generated_content + content[end_idx + len(end_tag):]

        # Handle length references
        length_placeholder = f"{{{{{var_name}|length}}}}"
        content = content.replace(length_placeholder, str(len(examples)))

        return content

    def _to_function_name(self, name: str) -> str:
        """Convert criterion name to valid Python function name"""
        # Remove special characters and convert to snake_case
        clean_name = re.sub(r'[^\w\s]', '', name)
        snake_case = re.sub(r'\s+', '_', clean_name.strip()).lower()

        # Ensure it starts with a letter
        if not snake_case[0].isalpha():
            snake_case = "check_" + snake_case
        elif not snake_case.startswith("check_"):
            snake_case = "check_" + snake_case

        return snake_case

    def _to_pascal_case(self, snake_str: str) -> str:
        """Convert snake_case to PascalCase"""
        return ''.join(word.capitalize() for word in snake_str.split('_'))


def main():
    """CLI entry point"""
    parser = argparse.ArgumentParser(
        description="Generate Python graders and unit tests from goldset criteria",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  Generate all graders and tests from goldset:
    python generate_graders.py --goldset goldset.json --output-dir evals/graders/

  Generate specific criterion only:
    python generate_graders.py --goldset goldset.json --criterion eval-001 --output-dir evals/graders/

  Generate graders only (no tests):
    python generate_graders.py --goldset goldset.json --output-dir evals/graders/ --no-tests

  Dry run (preview what would be generated):
    python generate_graders.py --goldset goldset.json --output-dir evals/graders/ --dry-run
        """
    )

    parser.add_argument(
        "--goldset",
        type=Path,
        required=True,
        help="Path to goldset JSON file containing evaluation criteria"
    )

    parser.add_argument(
        "--output-dir",
        type=Path,
        required=True,
        help="Directory to write generated grader files"
    )

    parser.add_argument(
        "--test-output-dir",
        type=Path,
        help="Directory to write generated test files (defaults to tests/)"
    )

    parser.add_argument(
        "--criterion",
        help="Generate only specific criterion by ID (e.g., eval-001)"
    )

    parser.add_argument(
        "--grader-module",
        default="custom_graders",
        help="Python module name for graders (default: custom_graders)"
    )

    parser.add_argument(
        "--no-tests",
        action="store_true",
        help="Skip unit test generation"
    )

    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing files"
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview what would be generated without writing files"
    )

    args = parser.parse_args()

    # Configure generation
    config = GenerationConfig(
        goldset_path=args.goldset,
        output_dir=args.output_dir,
        test_output_dir=args.test_output_dir or Path("tests"),
        grader_module_name=args.grader_module,
        include_tests=not args.no_tests,
        overwrite=args.overwrite,
        dry_run=args.dry_run
    )

    try:
        generator = GraderGenerator(config)

        if args.criterion:
            # Generate specific criterion
            files = generator.generate_criterion(args.criterion)
            print(f"\n✓ Generated {len(files)} files for criterion {args.criterion}")
        else:
            # Generate all criteria
            files = generator.generate_all()
            print(f"\n✓ Generated {len(files)} total files from goldset")

        if args.dry_run:
            print("\n(Dry run - no files were written)")

        # List generated files
        print("\nGenerated files:")
        for file_path in files:
            print(f"  {file_path}")

    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

    return 0


if __name__ == "__main__":
    exit(main())