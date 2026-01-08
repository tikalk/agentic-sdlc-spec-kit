#!/usr/bin/env python3
"""
Automated Error Analysis using Claude API
Automatically evaluates generated specs and categorizes failures
Location: evals/scripts/run-automated-error-analysis.py
"""

import os
import glob
import json
import re
from pathlib import Path
from anthropic import Anthropic
import pandas as pd
from datetime import datetime

# Configuration
DATASET_DIR = Path(__file__).parent.parent / 'datasets' / 'real-specs'
RESULTS_DIR = Path(__file__).parent.parent / 'datasets' / 'analysis-results'
RESULTS_DIR.mkdir(exist_ok=True)

# Initialize Claude client
client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

# Evaluation prompt
EVAL_PROMPT = """You are an expert software engineer reviewing a technical specification document.

**Task:** Evaluate the following spec and determine if it meets professional quality standards.

**Spec to Review:**
{spec}

**Original Prompt:**
{prompt}

**Evaluation Criteria:**
1. **Completeness:** Are all requirements clearly defined?
2. **Clarity:** Are user stories and acceptance criteria unambiguous?
3. **Appropriateness:** Is the scope appropriate (not over-engineered)?
4. **Constraints:** Are technical constraints and assumptions documented?
5. **Testability:** Can QA write tests from this spec?

**Your Task:**
Respond with a JSON object containing:
{{
  "pass": true/false,
  "issues": ["issue 1", "issue 2", ...],
  "categories": ["category 1", "category 2", ...],
  "reasoning": "Brief explanation of your decision"
}}

**Common failure categories:**
- "Incomplete requirements"
- "Ambiguous specifications"
- "Over-engineering"
- "Missing constraints"
- "Tech stack mismatch"
- "Missing edge cases"
- "Unclear acceptance criteria"

Be strict but fair. A spec should fail if it has significant issues that would block implementation.
"""


def extract_spec_content(file_path):
    """Extract prompt and spec from markdown file"""
    with open(file_path, 'r') as f:
        content = f.read()

    # Extract prompt
    prompt_match = re.search(r'## Prompt\n(.+?)\n\n', content, re.DOTALL)
    prompt = prompt_match.group(1).strip() if prompt_match else ''

    # Extract generated spec
    spec_match = re.search(r'## Generated Spec\n(.+?)(?:\n\n##|$)', content, re.DOTALL)
    spec = spec_match.group(1).strip() if spec_match else ''

    return prompt, spec


def evaluate_spec(prompt, spec, model="claude-sonnet-4-5-20250929"):
    """Use Claude to evaluate a spec"""
    try:
        message = client.messages.create(
            model=model,
            max_tokens=2000,
            messages=[{
                "role": "user",
                "content": EVAL_PROMPT.format(spec=spec, prompt=prompt)
            }]
        )

        response_text = message.content[0].text

        # Try to extract JSON from response
        json_match = re.search(r'\{[^}]+\}', response_text, re.DOTALL)
        if json_match:
            result = json.loads(json_match.group(0))
        else:
            # Fallback: parse manually
            result = {
                "pass": "pass" in response_text.lower(),
                "issues": [],
                "categories": [],
                "reasoning": response_text
            }

        return result

    except Exception as e:
        print(f"⚠️  Error evaluating spec: {e}")
        return {
            "pass": None,
            "issues": [f"Evaluation error: {str(e)}"],
            "categories": ["Evaluation error"],
            "reasoning": str(e)
        }


def main():
    print("🤖 Automated Error Analysis")
    print("=" * 60)
    print()

    # Check for API key
    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("❌ Error: ANTHROPIC_API_KEY not set")
        print("   Set it with: export ANTHROPIC_API_KEY=your-key")
        return 1

    # Load spec files
    spec_files = sorted(glob.glob(str(DATASET_DIR / 'spec-*.md')))
    print(f"📝 Found {len(spec_files)} spec files")
    print()

    if len(spec_files) == 0:
        print("❌ No spec files found in:", DATASET_DIR)
        return 1

    # Evaluate each spec
    results = []
    for i, spec_file in enumerate(spec_files, 1):
        filename = os.path.basename(spec_file)
        print(f"[{i}/{len(spec_files)}] Evaluating {filename}...", end=" ")

        prompt, spec = extract_spec_content(spec_file)

        if not spec:
            print("⚠️  No spec content found")
            continue

        evaluation = evaluate_spec(prompt, spec)

        results.append({
            'file': filename,
            'prompt': prompt,
            'spec': spec[:200] + '...',  # Truncate for CSV
            'pass': 'Pass' if evaluation['pass'] else 'Fail',
            'issues': '; '.join(evaluation.get('issues', [])),
            'categories': '; '.join(evaluation.get('categories', [])),
            'reasoning': evaluation.get('reasoning', '')
        })

        status = "✅ Pass" if evaluation['pass'] else "❌ Fail"
        print(status)

    print()
    print("=" * 60)

    # Create DataFrame
    df = pd.DataFrame(results)

    # Calculate stats
    total = len(df)
    failed = len(df[df['pass'] == 'Fail'])
    passed = total - failed
    pass_rate = (passed / total * 100) if total > 0 else 0

    print(f"\n📊 Results:")
    print(f"   Total specs: {total}")
    print(f"   Passed: {passed}")
    print(f"   Failed: {failed}")
    print(f"   Pass rate: {pass_rate:.1f}%")
    print()

    # Categorize failures
    if failed > 0:
        print("❌ Failure Categories:")
        all_categories = []
        for categories in df[df['pass'] == 'Fail']['categories']:
            if categories:
                all_categories.extend([c.strip() for c in categories.split(';')])

        from collections import Counter
        category_counts = Counter(all_categories)
        for category, count in category_counts.most_common():
            print(f"   {category}: {count}")
        print()

    # Save results
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

    # Save detailed CSV
    csv_file = RESULTS_DIR / f'automated-analysis-{timestamp}.csv'
    df.to_csv(csv_file, index=False)
    print(f"💾 Saved detailed results: {csv_file}")

    # Save summary report
    summary_file = RESULTS_DIR / f'summary-{timestamp}.txt'
    with open(summary_file, 'w') as f:
        f.write(f"Automated Error Analysis Report\n")
        f.write(f"{'=' * 60}\n\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Model: claude-sonnet-4-5-20250929\n\n")
        f.write(f"Results:\n")
        f.write(f"  Total specs: {total}\n")
        f.write(f"  Passed: {passed}\n")
        f.write(f"  Failed: {failed}\n")
        f.write(f"  Pass rate: {pass_rate:.1f}%\n\n")

        if failed > 0:
            f.write(f"Failure Categories:\n")
            for category, count in category_counts.most_common():
                f.write(f"  - {category}: {count}\n")
            f.write("\n")

            f.write("Failed Specs:\n")
            for _, row in df[df['pass'] == 'Fail'].iterrows():
                f.write(f"\n[{row['file']}]\n")
                f.write(f"  Issues: {row['issues']}\n")
                f.write(f"  Categories: {row['categories']}\n")

    print(f"📄 Saved summary report: {summary_file}")
    print()
    print("✅ Automated error analysis complete!")

    return 0


if __name__ == '__main__':
    exit(main())
