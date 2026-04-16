#!/usr/bin/env python3
"""
Generate Test Cases from Goldset
Converts goldset.md → goldset.json for DeepEval integration

This script parses the goldset.md file and extracts test cases
into a structured JSON format that can be loaded by test runners.

Template Variables (if used as template):
- None - this is a standalone utility script

Usage:
    python generate_test_cases.py [--goldset goldset.md] [--output goldset.json]
"""

import json
import re
import sys
import argparse
from pathlib import Path
from typing import List, Dict, Any, Optional


def parse_goldset_markdown(content: str) -> Dict[str, Any]:
    """
    Parse goldset.md format and extract test cases.

    Expected format:
    ---
    criterion_id: eval-001
    criterion_name: Example Criterion
    evaluator_type: llm-judge
    tier: 1
    failure_type: specification_failure
    ---

    ## Pass Examples
    ### Example 1
    **Input:** ...
    **Expected Output:** ...
    **Context:** ...

    ## Fail Examples
    ### Example 1
    **Input:** ...
    **Expected Output:** ...
    **Context:** ...

    ## Adversarial Examples
    ### Example 1
    **Input:** ...
    **Expected Output:** ...
    **Context:** ...
    **Attack Vector:** ...
    """

    # Extract YAML frontmatter
    frontmatter_match = re.search(r'^---\n(.*?)\n---', content, re.MULTILINE | re.DOTALL)
    if not frontmatter_match:
        raise ValueError("No YAML frontmatter found in goldset.md")

    frontmatter = {}
    for line in frontmatter_match.group(1).split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip()
            # Try to convert to int if possible
            try:
                value = int(value)
            except ValueError:
                pass
            frontmatter[key] = value

    # Extract examples by section
    result = {
        "metadata": frontmatter,
        "pass_examples": [],
        "fail_examples": [],
        "adversarial_examples": []
    }

    # Remove frontmatter from content
    content_without_frontmatter = content[frontmatter_match.end():].strip()

    # Split by main sections
    sections = {
        "pass": r'## Pass Examples(.*?)(?=## |$)',
        "fail": r'## Fail Examples(.*?)(?=## |$)',
        "adversarial": r'## Adversarial Examples(.*?)(?=## |$)'
    }

    for section_type, pattern in sections.items():
        section_match = re.search(pattern, content_without_frontmatter, re.DOTALL | re.IGNORECASE)
        if not section_match:
            continue

        section_content = section_match.group(1).strip()

        # Extract individual examples (### Example N)
        examples = re.split(r'###\s+Example\s+\d+', section_content)

        for example_text in examples:
            if not example_text.strip():
                continue

            example = _parse_example(example_text)
            if example:
                if section_type == "pass":
                    result["pass_examples"].append(example)
                elif section_type == "fail":
                    result["fail_examples"].append(example)
                elif section_type == "adversarial":
                    result["adversarial_examples"].append(example)

    return result


def _parse_example(text: str) -> Optional[Dict[str, Any]]:
    """Parse an individual example from markdown text."""

    example = {}

    # Extract Input
    input_match = re.search(r'\*\*Input:\*\*\s*(.*?)(?=\*\*|$)', text, re.DOTALL)
    if input_match:
        example["input"] = input_match.group(1).strip()

    # Extract Expected Output
    output_match = re.search(r'\*\*Expected Output:\*\*\s*(.*?)(?=\*\*|$)', text, re.DOTALL)
    if output_match:
        example["expected_output"] = output_match.group(1).strip()
    else:
        example["expected_output"] = ""

    # Extract Context (optional)
    context_match = re.search(r'\*\*Context:\*\*\s*(.*?)(?=\*\*|$)', text, re.DOTALL)
    if context_match:
        context = context_match.group(1).strip()
        if context and context.lower() not in ['none', 'n/a', '']:
            # Split context into list if it contains multiple items
            example["context"] = [ctx.strip() for ctx in context.split('\n') if ctx.strip()]
        else:
            example["context"] = None
    else:
        example["context"] = None

    # Extract Attack Vector (for adversarial examples)
    attack_match = re.search(r'\*\*Attack Vector:\*\*\s*(.*?)(?=\*\*|$)', text, re.DOTALL)
    if attack_match:
        example["attack_vector"] = attack_match.group(1).strip()

    # Only return if we have at least input
    if "input" in example:
        return example

    return None


def generate_goldset_json(goldset_md_path: Path, output_path: Path) -> None:
    """
    Generate goldset.json from goldset.md

    Args:
        goldset_md_path: Path to goldset.md file
        output_path: Path to output goldset.json file
    """

    # Read goldset.md
    if not goldset_md_path.exists():
        raise FileNotFoundError(f"Goldset file not found: {goldset_md_path}")

    content = goldset_md_path.read_text(encoding='utf-8')

    # Parse content
    result = parse_goldset_markdown(content)

    # Add generation metadata
    result["_generated"] = {
        "source": str(goldset_md_path),
        "version": "1.0.0"
    }

    # Write JSON output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding='utf-8')

    # Print statistics
    print(f"✓ Generated goldset.json from {goldset_md_path}")
    print(f"  Criterion: {result['metadata'].get('criterion_id', 'N/A')} - {result['metadata'].get('criterion_name', 'N/A')}")
    print(f"  Pass examples: {len(result['pass_examples'])}")
    print(f"  Fail examples: {len(result['fail_examples'])}")
    print(f"  Adversarial examples: {len(result['adversarial_examples'])}")
    print(f"  Total: {len(result['pass_examples']) + len(result['fail_examples']) + len(result['adversarial_examples'])} test cases")
    print(f"  Output: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate goldset.json from goldset.md for DeepEval integration"
    )
    parser.add_argument(
        "--goldset",
        type=Path,
        default=Path("goldset.md"),
        help="Path to goldset.md file (default: goldset.md)"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("goldset.json"),
        help="Path to output goldset.json file (default: goldset.json)"
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate goldset structure without generating output"
    )

    args = parser.parse_args()

    try:
        if args.validate:
            # Validation mode
            content = args.goldset.read_text(encoding='utf-8')
            result = parse_goldset_markdown(content)
            print(f"✓ Goldset validation passed")
            print(f"  Criterion: {result['metadata'].get('criterion_id', 'N/A')}")
            print(f"  Total test cases: {len(result['pass_examples']) + len(result['fail_examples']) + len(result['adversarial_examples'])}")
        else:
            # Generation mode
            generate_goldset_json(args.goldset, args.output)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
