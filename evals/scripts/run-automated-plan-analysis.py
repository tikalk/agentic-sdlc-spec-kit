#!/usr/bin/env python3
"""
Automated Plan Error Analysis using Claude API
Automatically evaluates generated plans and categorizes failures
Location: evals/scripts/run-automated-plan-analysis.py
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
DATASET_DIR = Path(__file__).parent.parent / 'datasets' / 'real-plans'
RESULTS_DIR = Path(__file__).parent.parent / 'datasets' / 'analysis-results'
RESULTS_DIR.mkdir(exist_ok=True)

# Initialize Claude client
client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

# Evaluation prompt for plans
EVAL_PROMPT = """You are an expert software architect reviewing an implementation plan document.

**Task:** Evaluate the following implementation plan and determine if it meets professional quality standards.

**Plan to Review:**
{plan}

**Original Prompt:**
{prompt}

**Evaluation Criteria:**
1. **Simplicity Gate:** Does the plan respect the ≤3 projects limit? (THIS IS CRITICAL)
2. **Completeness:** Are all necessary components and phases defined?
3. **Clarity:** Are project boundaries, tasks, and milestones clear?
4. **Appropriateness:** Is the architecture simple enough? No over-engineering?
5. **Constitution Compliance:** Does it follow the principles (no microservices for simple apps, no premature optimization)?
6. **Testability:** Does the plan include testing strategy and verification steps?

**Your Task:**
Respond with a JSON object containing:
{{
  "pass": true/false,
  "project_count": number,
  "issues": ["issue 1", "issue 2", ...],
  "categories": ["category 1", "category 2", ...],
  "reasoning": "Brief explanation of your decision"
}}

**Common failure categories:**
- "Too many projects (>3)"
- "Over-engineering"
- "Missing verification steps"
- "Unclear project boundaries"
- "Microservices for simple app"
- "Premature optimization"
- "Missing testing strategy"
- "Tech stack mismatch"
- "Incomplete milestones"

Be strict but fair. A plan should fail if it violates the simplicity gate (>3 projects) or has significant architectural issues that would lead to over-engineering.
"""


def extract_plan_content(file_path):
    """Extract prompt and plan from markdown file"""
    with open(file_path, 'r') as f:
        content = f.read()

    # Extract prompt
    prompt_match = re.search(r'## Prompt\n(.+?)\n\n', content, re.DOTALL)
    prompt = prompt_match.group(1).strip() if prompt_match else ''

    # Extract generated plan
    plan_match = re.search(r'## Generated Plan\n(.+?)(?:\n\n##|$)', content, re.DOTALL)
    plan = plan_match.group(1).strip() if plan_match else ''

    return prompt, plan


def evaluate_plan(prompt, plan, model="claude-sonnet-4-5-20250929"):
    """Use Claude to evaluate a plan"""
    try:
        message = client.messages.create(
            model=model,
            max_tokens=2000,
            messages=[{
                "role": "user",
                "content": EVAL_PROMPT.format(plan=plan, prompt=prompt)
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
                "project_count": None,
                "issues": [],
                "categories": [],
                "reasoning": response_text
            }

        return result

    except Exception as e:
        print(f"⚠️  Error evaluating plan: {e}")
        return {
            "pass": None,
            "project_count": None,
            "issues": [f"Evaluation error: {str(e)}"],
            "categories": ["Evaluation error"],
            "reasoning": str(e)
        }


def main():
    print("🤖 Automated Plan Error Analysis")
    print("=" * 60)
    print()

    # Check for API key
    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("❌ Error: ANTHROPIC_API_KEY not set")
        print("   Set it with: export ANTHROPIC_API_KEY=your-key")
        return 1

    # Load plan files
    plan_files = sorted(glob.glob(str(DATASET_DIR / 'plan-*.md')))
    print(f"📝 Found {len(plan_files)} plan files")
    print()

    if len(plan_files) == 0:
        print("❌ No plan files found in:", DATASET_DIR)
        return 1

    # Evaluate each plan
    results = []
    for i, plan_file in enumerate(plan_files, 1):
        filename = os.path.basename(plan_file)
        print(f"[{i}/{len(plan_files)}] Evaluating {filename}...", end=" ")

        prompt, plan = extract_plan_content(plan_file)

        if not plan:
            print("⚠️  No plan content found")
            continue

        evaluation = evaluate_plan(prompt, plan)

        results.append({
            'file': filename,
            'prompt': prompt,
            'plan_summary': plan[:200] + '...',  # Truncate for CSV
            'project_count': evaluation.get('project_count', 'N/A'),
            'pass': 'Pass' if evaluation['pass'] else 'Fail',
            'issues': '; '.join(evaluation.get('issues', [])),
            'categories': '; '.join(evaluation.get('categories', [])),
            'reasoning': evaluation.get('reasoning', '')
        })

        status = "✅ Pass" if evaluation['pass'] else "❌ Fail"
        project_count = f" ({evaluation.get('project_count', '?')} projects)" if evaluation.get('project_count') else ""
        print(status + project_count)

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
    print(f"   Total plans: {total}")
    print(f"   Passed: {passed}")
    print(f"   Failed: {failed}")
    print(f"   Pass rate: {pass_rate:.1f}%")
    print()

    # Project count analysis
    if 'project_count' in df.columns:
        print("📐 Project Count Distribution:")
        project_counts = df[df['project_count'] != 'N/A']['project_count'].value_counts().sort_index()
        for count, freq in project_counts.items():
            print(f"   {count} projects: {freq}")
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
    csv_file = RESULTS_DIR / f'plan-analysis-{timestamp}.csv'
    df.to_csv(csv_file, index=False)
    print(f"💾 Saved detailed results: {csv_file}")

    # Save summary report
    summary_file = RESULTS_DIR / f'plan-summary-{timestamp}.txt'
    with open(summary_file, 'w') as f:
        f.write(f"Automated Plan Error Analysis Report\n")
        f.write(f"{'=' * 60}\n\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Model: claude-sonnet-4-5-20250929\n\n")
        f.write(f"Results:\n")
        f.write(f"  Total plans: {total}\n")
        f.write(f"  Passed: {passed}\n")
        f.write(f"  Failed: {failed}\n")
        f.write(f"  Pass rate: {pass_rate:.1f}%\n\n")

        if 'project_count' in df.columns:
            f.write(f"Project Count Distribution:\n")
            for count, freq in project_counts.items():
                f.write(f"  {count} projects: {freq}\n")
            f.write("\n")

        if failed > 0:
            f.write(f"Failure Categories:\n")
            for category, count in category_counts.most_common():
                f.write(f"  - {category}: {count}\n")
            f.write("\n")

            f.write("Failed Plans:\n")
            for _, row in df[df['pass'] == 'Fail'].iterrows():
                f.write(f"\n[{row['file']}]\n")
                f.write(f"  Project Count: {row['project_count']}\n")
                f.write(f"  Issues: {row['issues']}\n")
                f.write(f"  Categories: {row['categories']}\n")

    print(f"📄 Saved summary report: {summary_file}")
    print()
    print("✅ Automated plan error analysis complete!")

    return 0


if __name__ == '__main__':
    exit(main())
