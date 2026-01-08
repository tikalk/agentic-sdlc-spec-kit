# Spec-Kit Evaluation Framework

This directory contains the evaluation framework for testing spec-kit templates and commands.

## Overview

The evaluation framework uses **PromptFoo** with your **LiteLLM Claude** account to automatically test that template changes maintain quality standards.

## Quick Start

### 1. Prerequisites

```bash
# Install Node.js (if not already installed)
# macOS:
brew install node

# Verify Node.js is installed (npx comes with Node.js)
node --version

# Verify npx is available
npx --version
```

### 2. Set Environment Variables

Make sure your LiteLLM credentials are set:

```bash
# Add to ~/.bashrc or ~/.zshrc
export ANTHROPIC_BASE_URL="your-litellm-proxy-url"
export ANTHROPIC_AUTH_TOKEN="your-litellm-auth-token"

# Reload shell
source ~/.zshrc  # or source ~/.bashrc
```

### 3. Run Evaluations

```bash
# From repo root
cd /Users/keren.finkelstein/tikal/agentic-sdlc-spec-kit

# Run all tests (npx will download promptfoo on first run)
npx promptfoo eval

# View results in browser
npx promptfoo view

# Export results to JSON
npx promptfoo eval -o json > eval-results.json

# Check if results meet thresholds
python scripts/check_eval_scores.py --results eval-results.json --min-score 0.75
```

## Configuration

### Main Config: `promptfooconfig.js`

Located in the repo root, this JavaScript file defines:

- **Prompts**: Evaluation prompts (spec-prompt.txt, plan-prompt.txt)
- **Provider**: LiteLLM Claude via OpenAI-compatible endpoint
- **Tests**: 10 test cases covering different quality dimensions
- **Environment Variables**: Uses `process.env` for ANTHROPIC_BASE_URL and ANTHROPIC_AUTH_TOKEN

**Note**: We use JavaScript config instead of YAML to properly support environment variables.

### Custom Graders: `evals/custom_graders.py`

Python functions that check specific quality criteria:

- `check_security_completeness()` - Validates security requirements
- `check_simplicity_gate()` - Ensures ≤3 projects (constitution Article VII)
- `check_constitution_compliance()` - Checks constitutional principles
- `check_vague_terms()` - Flags unmeasurable requirements
- `check_testability()` - Validates acceptance criteria

## Test Suite

The evaluation includes 10 tests:

### Spec Template Tests (Tests 1-6)

1. **Basic Structure** - Validates required sections present
2. **No Premature Tech Stack** - Ensures spec focuses on WHAT, not HOW
3. **Quality User Stories** - Checks for clear acceptance criteria
4. **Clarity** - Flags vague terms needing quantification
5. **Security Requirements** - Security-critical features include security section
6. **Edge Cases** - Validates edge case coverage

### Plan Template Tests (Tests 7-8)

7. **Simplicity Gate** - Simple apps should have ≤3 projects
8. **Constitution Compliance** - No over-engineering, no unnecessary abstractions

### General Tests (Tests 9-10)

9. **Completeness** - Comprehensive requirements for complex features
10. **Regression Test** - Even simple features maintain structure

## Running Specific Tests

```bash
# Run only spec template tests
npx promptfoo eval --filter "Spec Template"

# Run only plan template tests
npx promptfoo eval --filter "Plan Template"

# Run single test by description
npx promptfoo eval --filter "Basic CRUD"
```

## Understanding Results

### Success Criteria

Each test has assertions that must pass:

- **contains/not-contains**: Exact string matching
- **llm-rubric**: LLM judges quality on 0-1 scale
- **python**: Custom Python function returns pass/fail
- **javascript**: Custom JS function returns true/false

### Scores

- **Score**: 0.0 - 1.0 (higher is better)
- **Threshold**: Minimum score to pass (default: 0.75)
- **Pass**: Test passes if score ≥ threshold

### Example Output

```
✅ Test 1: Spec Template: Basic CRUD app - Structure validation
   Score: 0.95
   All required sections present

❌ Test 4: Spec Template: Flags vague requirements
   Score: 0.65 (threshold: 0.70)
   Found 4 vague terms, only 2 properly quantified
```

## Cost Management

### Estimated Costs (via LiteLLM)

Running the full test suite (10 tests):

- **Tokens per run**: ~50-100K tokens (avg, depends on generated content)
- **Cost per run**: ~$0.50-$1.00 (Claude Sonnet 4.5)
- **Monthly cost** (10 runs): ~$5-$10

### Reducing Costs

1. **Run selectively**: Only test changed templates
   ```bash
   # Only test spec template if that changed
   npx promptfoo eval --filter "Spec Template"
   ```

2. **Use caching**: LiteLLM may cache responses (saves $$)

3. **Run locally**: Only run in CI for important PRs

4. **Reduce test count**: Comment out less critical tests

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/eval.yml`:

```yaml
name: Evaluate Templates

on:
  pull_request:
    paths:
      - 'templates/**'

jobs:
  eval:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Run Evaluations
        env:
          ANTHROPIC_BASE_URL: ${{ secrets.ANTHROPIC_BASE_URL }}
          ANTHROPIC_AUTH_TOKEN: ${{ secrets.ANTHROPIC_AUTH_TOKEN }}
        run: |
          npx promptfoo eval --no-interactive -o json > results.json

      - name: Check Thresholds
        run: |
          python scripts/check_eval_scores.py \
            --results results.json \
            --min-score 0.75 \
            --min-pass-rate 0.80

      - name: Upload Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: eval-results
          path: results.json
```

## Adding New Tests

### 1. Add Test to `promptfooconfig.js`

```javascript
// In the tests array
{
  description: 'Your test description',
  vars: {
    user_input: 'Your test prompt',
  },
  assert: [
    { type: 'contains', value: 'Expected string' },
    {
      type: 'llm-rubric',
      value: 'Judge criteria (0-1)',
      threshold: 0.75,
    },
  ],
}
```

### 2. Add Custom Grader (if needed)

Add function to `evals/custom_graders.py`:

```python
def check_your_criteria(output: str, context: dict) -> dict:
    """
    Your custom validation logic.

    Returns:
        dict with 'pass', 'score', and 'reason' keys
    """
    # Your logic here
    passed = your_check(output)
    score = calculate_score(output)

    return {
        'pass': passed,
        'score': score,
        'reason': 'Explanation of result'
    }
```

### 3. Use in Test

```javascript
assert: [
  {
    type: 'python',
    value: 'file://evals/custom_graders.py:check_your_criteria',
  },
]
```

## Troubleshooting

### Error: "ANTHROPIC_BASE_URL not set"

```bash
# Check env vars are set
env | grep ANTHROPIC

# If not, export them
export ANTHROPIC_BASE_URL="your-url"
export ANTHROPIC_AUTH_TOKEN="your-token"
```

### Error: "Could not connect to API"

```bash
# Test your LiteLLM endpoint directly
curl -X POST ${ANTHROPIC_BASE_URL}/messages \
  -H "x-api-key: ${ANTHROPIC_AUTH_TOKEN}" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model": "claude-sonnet-4", "max_tokens": 100, "messages": [{"role": "user", "content": "test"}]}'
```

### Error: "Python grader failed"

```bash
# Test grader directly
python3 -c "
from evals.custom_graders import check_security_completeness
result = check_security_completeness('test authentication authorization', {})
print(result)
"
```

### Tests taking too long

- Reduce `max_tokens` in config (default: 4000)
- Run fewer tests at once
- Check LiteLLM proxy isn't rate limiting

## Best Practices

### When to Run Evals

- ✅ **Before committing** template changes
- ✅ **In PR** for template/command changes
- ✅ **Weekly** as regression check
- ❌ Not on every commit (too expensive)
- ❌ Not for non-template changes

### Development Workflow

1. Make template changes locally
2. Run eval: `npx promptfoo eval`
3. Fix failures
4. Commit changes
5. PR triggers eval in CI
6. Merge if passes

### Quality Thresholds

Current thresholds (adjust in `promptfooconfig.js`):

- **LLM rubric tests**: 0.75 (75%)
- **Python graders**: 0.70-0.80 depending on criticality
- **Pass rate**: 80% of tests must pass

## Resources

- **PromptFoo Docs**: https://promptfoo.dev/docs/intro
- **LiteLLM Docs**: https://docs.litellm.ai
- **Custom Graders Guide**: https://promptfoo.dev/docs/configuration/expected-outputs/python

## Questions?

For evaluation framework issues:
- Check PromptFoo docs: https://promptfoo.dev/docs/intro
- PromptFoo Discord: https://discord.gg/promptfoo

For spec-kit specific questions:
- Open issue: https://github.com/tikalk/agentic-sdlc-spec-kit/issues