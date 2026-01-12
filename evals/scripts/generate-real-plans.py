#!/usr/bin/env python3

"""
Generate Real Plans for Error Analysis
Uses Claude API to generate actual plans for all test case templates
"""

import os
import sys
import re
import json
import requests
from pathlib import Path

# Colors for terminal output
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
RED = '\033[0;31m'
NC = '\033[0m'

def main():
    print("🤖 Real Plan Generator (Python)")
    print("=" * 35)
    print()

    # Get config
    api_url = os.getenv('ANTHROPIC_BASE_URL')
    api_key = os.getenv('ANTHROPIC_AUTH_TOKEN')
    model = os.getenv('CLAUDE_MODEL', 'claude-sonnet-4-5-20250929')

    if not api_url:
        print(f"{RED}❌ ANTHROPIC_BASE_URL not set{NC}")
        sys.exit(1)

    if not api_key:
        print(f"{RED}❌ ANTHROPIC_AUTH_TOKEN not set{NC}")
        sys.exit(1)

    print(f"{GREEN}✓{NC} Using model: {model}")
    print(f"{GREEN}✓{NC} API endpoint: {api_url}")
    print()

    # Get paths
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent.parent
    plans_dir = repo_root / 'evals' / 'datasets' / 'real-plans'
    prompt_file = repo_root / 'evals' / 'prompts' / 'plan-prompt.txt'

    # Read prompt template
    if not prompt_file.exists():
        print(f"{RED}❌ Prompt template not found: {prompt_file}{NC}")
        sys.exit(1)

    with open(prompt_file, 'r') as f:
        prompt_template = f.read()

    # Find all plan files
    plan_files = sorted(plans_dir.glob('plan-*.md'))
    total = len(plan_files)

    print(f"📝 Found {total} plan files to generate")
    print()

    count = 0
    for plan_file in plan_files:
        count += 1
        filename = plan_file.name

        print(f"{YELLOW}[{count}/{total}]{NC} Processing {filename}...")

        # Read the plan file
        with open(plan_file, 'r') as f:
            content = f.read()

        # Extract the prompt
        prompt_match = re.search(r'## Prompt\n(.+?)\n\n', content, re.DOTALL)
        if not prompt_match:
            print(f"  ⚠️  No prompt found, skipping")
            continue

        user_prompt = prompt_match.group(1).strip()
        print(f"  📋 Prompt: {user_prompt[:60]}...")

        # Replace {{user_input}} in template
        full_prompt = prompt_template.replace('{{ user_input }}', user_prompt)

        # Call the API
        print(f"  🤖 Generating plan...")

        try:
            # Use OpenAI-compatible endpoint format for LiteLLM
            response = requests.post(
                f"{api_url}/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {api_key}"
                },
                json={
                    "model": model,
                    "max_tokens": 4000,
                    "temperature": 0.7,
                    "messages": [{
                        "role": "user",
                        "content": full_prompt
                    }]
                },
                timeout=60
            )

            response.raise_for_status()
            result = response.json()

            # Extract generated content (OpenAI format)
            if 'choices' not in result or len(result['choices']) == 0:
                print(f"  {RED}❌ No content in response{NC}")
                continue

            generated_plan = result['choices'][0]['message']['content']

            # Update the plan file
            # Split at "## Generated Plan"
            parts = content.split('## Generated Plan\n', 1)
            if len(parts) != 2:
                print(f"  {RED}❌ Could not find '## Generated Plan' marker{NC}")
                continue

            before = parts[0] + '## Generated Plan\n'

            # Find the "## Review Notes" section
            review_match = re.search(r'\n## Review Notes', parts[1])
            if review_match:
                after = '\n## Review Notes' + parts[1][review_match.end():]
            else:
                after = '\n\n## Review Notes\n<!-- Domain expert notes go here during error analysis -->\n- [ ] Pass/Fail:\n- [ ] Issues found:\n- [ ] Failure category:\n'

            # Write updated content
            new_content = before + generated_plan + '\n' + after

            with open(plan_file, 'w') as f:
                f.write(new_content)

            print(f"  {GREEN}✓{NC} Saved to {filename}")
            print()

        except requests.exceptions.RequestException as e:
            print(f"  {RED}❌ API Error: {e}{NC}")
            continue
        except Exception as e:
            print(f"  {RED}❌ Error: {e}{NC}")
            continue

    print()
    print("━" * 35)
    print(f"{GREEN}✅ Generation complete!{NC}")
    print()
    print("📊 Next steps:")
    print(f"   1. Review generated plans in: {plans_dir}")
    print("   2. Run error analysis: ./evals/scripts/run-auto-plan-analysis.sh")
    print("   3. Review analysis results")
    print()

if __name__ == '__main__':
    main()
