# Spec-Kit Evaluation Framework

Comprehensive evaluation infrastructure for testing spec-kit template quality using PromptFoo with Claude.

## 📊 Current Evaluation Results (Updated: 2026-01-12)

**Overall Pass Rate: 90% (9/10 tests passing)** ✅

| Test Suite | Pass Rate | Status |
|------------|-----------|--------|
| **Spec Template** | 7/8 (87.5%) | ✅ |
| **Plan Template** | 2/2 (100%) | ✅ |
| **Total** | **9/10 (90%)** | ✅ |

### Recent Improvements

- ✅ **Fixed Payment Security (Test #5)**: Enhanced security requirements coverage (auth, encryption, validation, logging, compliance)
- ✅ **Fixed Plan Simplicity (Test #1)**: Strengthened simplicity constraints (≤3 projects)
- ✅ **Fixed E-commerce Completeness (Test #7)**: Improved multi-step flow coverage
- ✅ **Fixed Regressions (Tests #2, #6)**: Balanced security guidance, explicit section headings
- ⚠️ **1 Minor Issue (Test #4)**: Vague term handling (acceptable trade-off for better security/completeness)

### Progress Tracking

| Metric | Initial | Current | Improvement |
|--------|---------|---------|-------------|
| Spec Tests | 6/8 (75%) | 7/8 (87.5%) | +12.5% |
| Plan Tests | 1/2 (50%) | 2/2 (100%) | +50% |
| **Overall** | **7/10 (70%)** | **9/10 (90%)** | **+20%** |

## Directory Structure

```
evals/
├── README.md              # This file
├── configs/               # PromptFoo configuration files
│   ├── promptfooconfig.js        # Main config (all 10 tests)
│   ├── promptfooconfig-spec.js   # Spec template tests only
│   └── promptfooconfig-plan.js   # Plan template tests only
├── prompts/               # Templates under test
│   ├── spec-prompt.txt           # Specification generation template
│   └── plan-prompt.txt           # Implementation plan template
├── graders/               # Custom evaluation logic
│   └── custom_graders.py         # Security, simplicity, constitution checks
├── scripts/               # Test execution utilities
│   ├── run-promptfoo-eval.sh     # PromptFoo test runner
│   ├── run-error-analysis.sh     # Error analysis workflow
│   ├── run-annotation-tool.sh    # Annotation tool launcher
│   └── check_eval_scores.py      # Score validation
├── annotation-tool/       # Custom FastHTML annotation interface
│   ├── app.py                    # FastHTML web application
│   ├── README.md                 # Tool documentation
│   └── annotations.json          # Saved annotations (gitignored)
├── notebooks/             # Jupyter notebooks for error analysis
│   └── error-analysis.ipynb      # Manual review workflow
└── datasets/              # Test data and results
    ├── real-specs/               # Generated specs for review
    ├── real-plans/               # Generated plans for review
    ├── generate-test-data.sh     # Data generation script
    └── analysis-results/         # Analysis outputs
```

## Quick Start

### 1. Prerequisites

```bash
# Install Node.js (if not already installed)
# macOS:
brew install node

# Verify installation
node --version  # Should be v18+
npx --version   # Comes with Node.js
```

### 2. Configure Environment Variables

```bash
# Add to ~/.bashrc or ~/.zshrc
export ANTHROPIC_BASE_URL="your-litellm-proxy-url"
export ANTHROPIC_AUTH_TOKEN="your-litellm-auth-token"
export CLAUDE_MODEL="claude-sonnet-4-5-20250929"  # Optional, defaults to Sonnet 4.5

# Reload shell
source ~/.zshrc  # or source ~/.bashrc
```

### 3. Run Evaluations

```bash
# From repo root - run all PromptFoo tests
./evals/scripts/run-promptfoo-eval.sh

# Run with JSON output
./evals/scripts/run-promptfoo-eval.sh --json

# Run and open web UI
./evals/scripts/run-promptfoo-eval.sh --view

# Filter specific tests
./evals/scripts/run-promptfoo-eval.sh --filter "Spec Template"
```

## Test Suite

### Overview

The evaluation includes **10 automated tests** covering:
- **Spec Template (8 tests)**: Structure, clarity, security, completeness
- **Plan Template (2 tests)**: Simplicity, constitution compliance

### Spec Template Tests

1. **Basic Structure** - Validates required sections (Overview, Requirements, User Stories, etc.)
2. **No Premature Tech Stack** - Ensures spec focuses on WHAT, not HOW
3. **Quality User Stories** - Checks for proper format and acceptance criteria
4. **Clarity & Vague Terms** - Flags unmeasurable requirements needing quantification
5. **Security Requirements** - Security-critical features include security considerations
6. **Edge Cases Coverage** - Validates error scenarios and boundary conditions
7. **Completeness** - Comprehensive requirements for complex features
8. **Regression** - Even simple features maintain proper structure

### Plan Template Tests

9. **Simplicity Gate** - Simple apps should have ≤3 projects (Constitution Article VII)
10. **Constitution Compliance** - No over-engineering or unnecessary abstractions

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ANTHROPIC_BASE_URL` | **Yes** | - | LiteLLM proxy URL |
| `ANTHROPIC_AUTH_TOKEN` | **Yes** | - | LiteLLM authentication token |
| `CLAUDE_MODEL` | No | `claude-sonnet-4-5-20250929` | Claude model identifier |

### Changing the Model

```bash
# Use Claude Opus instead
export CLAUDE_MODEL="claude-opus-4-5-20241101"
./evals/scripts/run-eval.sh

# Use Claude Haiku for faster/cheaper evals
export CLAUDE_MODEL="claude-3-5-haiku-20241022"
./evals/scripts/run-eval.sh
```

### Config Files

- **`promptfooconfig.js`**: Main config with all 10 tests
- **`promptfooconfig-spec.js`**: Only spec template tests (for targeted testing)
- **`promptfooconfig-plan.js`**: Only plan template tests (for targeted testing)

All configs use JavaScript (not YAML) to support environment variables.

## Custom Graders

Python functions in `graders/custom_graders.py` validate specific quality criteria:

- **`check_security_completeness()`** - Validates presence of authentication, authorization, encryption
- **`check_simplicity_gate()`** - Ensures ≤3 projects for simple apps (Constitution Article VII)
- **`check_constitution_compliance()`** - Checks for over-engineering patterns
- **`check_vague_terms()`** - Flags unmeasurable requirements
- **`check_testability()`** - Validates acceptance criteria clarity

## Running Evaluations

### Using the Helper Script (Recommended)

```bash
# Run all tests
./evals/scripts/run-eval.sh

# Show help
./evals/scripts/run-eval.sh --help

# Options:
#   --filter TEXT    Run only tests matching TEXT (regex pattern)
#   --json           Output results as JSON files
#   --view           Open web UI after running
```

### Using PromptFoo Directly

```bash
# All tests (main config)
npx promptfoo eval -c evals/configs/promptfooconfig.js --no-share

# Only spec tests
npx promptfoo eval -c evals/configs/promptfooconfig-spec.js --no-share

# Only plan tests
npx promptfoo eval -c evals/configs/promptfooconfig-plan.js --no-share

# Filter by test description
npx promptfoo eval -c evals/configs/promptfooconfig.js --filter-pattern "Security" --no-share

# View results in browser
npx promptfoo view
```

## Understanding Results

### Assertion Types

- **`icontains` / `not-icontains`**: Case-insensitive string matching
- **`llm-rubric`**: LLM judges quality on 0-1 scale against rubric
- **`python`**: Custom Python function returns pass/fail with score
- **`javascript`**: Custom JS function returns boolean

### Success Criteria

Each test has a **threshold** (default: 0.70-0.80):
- **Score ≥ threshold**: ✅ PASS
- **Score < threshold**: ❌ FAIL

### Example Output

```
📋 Running Spec Template tests...

✅ Test 1: Spec Template: Basic CRUD app - Structure validation
   All required sections present

❌ Test 4: Spec Template: Flags vague requirements
   Score: 0.65 (threshold: 0.70)
   Found 4 vague terms, only 2 properly quantified

Results: ✓ 6 passed, ✗ 2 failed, 0 errors (75.00%)
```

## Cost Management

### Estimated Costs

Running the full test suite (10 tests) with Claude Sonnet 4.5:

- **Tokens per run**: ~60-70K tokens
- **Cost per run**: ~$0.60-$0.80
- **Monthly cost** (10 runs): ~$6-$8

### Reducing Costs

1. **Run selectively**: Only test changed templates
   ```bash
   ./evals/scripts/run-eval.sh --filter "Spec Template"
   ```

2. **Use cheaper models**: Switch to Haiku for development
   ```bash
   export CLAUDE_MODEL="claude-3-5-haiku-20241022"
   ```

3. **Leverage caching**: LiteLLM caches responses (reflected in token counts)

4. **Run locally**: Only run in CI for important PRs

## CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/eval.yml`:

```yaml
name: Evaluate Templates

on:
  pull_request:
    paths:
      - 'team-ai-directives/**'
      - 'evals/**'

jobs:
  eval:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Run Evaluations
        env:
          ANTHROPIC_BASE_URL: ${{ secrets.ANTHROPIC_BASE_URL }}
          ANTHROPIC_AUTH_TOKEN: ${{ secrets.ANTHROPIC_AUTH_TOKEN }}
          CLAUDE_MODEL: claude-sonnet-4-5-20250929
        run: |
          ./evals/scripts/run-promptfoo-eval.sh --json

      - name: Check Minimum Pass Rate
        run: |
          python3 evals/scripts/check_eval_scores.py \
            --results eval-results.json \
            --min-pass-rate 0.70

      - name: Upload Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: eval-results
          path: |
            eval-results*.json
```

## Adding New Tests

### 1. Add Test to Config File

Edit `evals/configs/promptfooconfig.js`:

```javascript
{
  description: 'Spec Template: Your test name',
  prompt: 'file://../prompts/spec-prompt.txt',
  vars: {
    user_input: 'Your test input prompt',
  },
  assert: [
    { type: 'icontains', value: 'Expected string' },
    {
      type: 'llm-rubric',
      value: 'Judge criteria:\n1. Check X\n2. Check Y\nReturn 0-1 score.',
      threshold: 0.75,
    },
  ],
}
```

### 2. Add Custom Grader (Optional)

Add function to `evals/graders/custom_graders.py`:

```python
def check_your_criteria(output: str, context: dict) -> dict:
    """
    Your custom validation logic.

    Args:
        output: LLM output to evaluate
        context: Test context with vars, etc.

    Returns:
        dict with 'pass', 'score', and 'reason' keys
    """
    # Your logic here
    passed = your_check(output)
    score = calculate_score(output)

    return {
        'pass': passed,
        'score': score,
        'reason': f'Explanation: {details}'
    }
```

### 3. Use Custom Grader in Test

```javascript
assert: [
  {
    type: 'python',
    value: 'file://../graders/custom_graders.py:check_your_criteria',
  },
]
```

## Troubleshooting

### Common Issues

**Error: "ANTHROPIC_BASE_URL not set"**
```bash
# Check env vars
env | grep ANTHROPIC

# Set if missing
export ANTHROPIC_BASE_URL="your-url"
export ANTHROPIC_AUTH_TOKEN="your-token"
```

**Error: "Config files not found"**
```bash
# Make sure you're in repo root
cd /path/to/agentic-sdlc-spec-kit
./evals/scripts/run-promptfoo-eval.sh
```

**Error: "Could not connect to API"**
```bash
# Test LiteLLM endpoint directly
curl -X POST ${ANTHROPIC_BASE_URL}/chat/completions \
  -H "Authorization: Bearer ${ANTHROPIC_AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "messages": [{"role": "user", "content": "test"}],
    "max_tokens": 10
  }'
```

**Python grader failed**
```bash
# Test grader directly
cd evals
python3 -c "
from graders.custom_graders import check_security_completeness
result = check_security_completeness('test authentication encryption', {})
print(result)
"
```

**Tests taking too long**
- Reduce `max_tokens` in config (default: 4000)
- Use faster model: `export CLAUDE_MODEL="claude-3-5-haiku-20241022"`
- Check LiteLLM proxy isn't rate limiting

## Best Practices

### When to Run Evals

- ✅ **Before committing** template changes
- ✅ **In PR** for template/directive changes
- ✅ **Weekly** as regression check
- ❌ Not on every commit (too expensive)
- ❌ Not for non-template changes

### Development Workflow

1. Make template changes locally
2. Run eval: `./evals/scripts/run-promptfoo-eval.sh`
3. Fix failures
4. Commit changes
5. PR triggers eval in CI
6. Merge if passes

### Quality Thresholds

Current thresholds (adjust in config files):

- **LLM rubric tests**: 0.70-0.80
- **Python graders**: 0.70-0.80
- **Overall pass rate**: 70%+ recommended

## Resources

- **PromptFoo Docs**: https://promptfoo.dev/docs/intro
- **LiteLLM Docs**: https://docs.litellm.ai
- **Custom Graders Guide**: https://promptfoo.dev/docs/configuration/expected-outputs/python
- **Claude Models**: https://docs.anthropic.com/claude/docs/models-overview

## Error Analysis Workflow (NEW)

PromptFoo provides automated regression testing, but **error analysis on real outputs** is the most important evaluation activity. According to AI evaluation best practices:

> "We spent 60-80% of our development time on error analysis and evaluation. Expect most of your effort to go toward understanding failures (i.e. looking at data) rather than building automated checks."

### Quick Start

```bash
# 1. Generate test data
cd evals/datasets
./generate-test-data.sh  # Creates 17 diverse test case templates

# 2. Run error analysis workflow (sets up environment + launches Jupyter)
cd ../scripts
./run-error-analysis.sh

# 4. Run error analysis session (30-60 minutes)
# - Load specs
# - Review and annotate (pass/fail, issues, categories)
# - Categorize failures
# - Prioritize fixes
```

### Directory Structure

```
evals/
├── notebooks/              # Error analysis
│   ├── error-analysis.ipynb       # Main analysis notebook (manual)
│   └── .venv/                     # Virtual environment
├── scripts/                # Automation scripts
│   ├── run-promptfoo-eval.sh              # PromptFoo test runner
│   ├── run-error-analysis.sh              # Manual error analysis (Jupyter)
│   ├── run-auto-error-analysis.sh         # Automated error analysis for specs (Claude API)
│   ├── run-automated-error-analysis.py    # Python script for spec automation
│   ├── run-auto-plan-analysis.sh          # Automated error analysis for plans
│   ├── run-automated-plan-analysis.py     # Python script for plan automation
│   ├── generate-real-plans.py             # Generate plan test data
│   └── check_eval_scores.py               # Score validation
└── datasets/               # Test data
    ├── real-specs/                # Generated specs for review (17 templates)
    ├── real-plans/                # Generated plans for review (2 templates, expandable)
    ├── generate-test-data.sh      # Data generation script for specs
    └── analysis-results/          # Analysis output (CSV, summaries)
        ├── automated-analysis-*.csv     # Automated spec eval results
        ├── plan-analysis-*.csv          # Automated plan eval results
        ├── plan-eval-analysis-*.txt     # Plan evaluation analysis reports
        ├── summary-*.txt                # Summary reports
        └── error-analysis-results.csv   # Manual review results
```

### The 80/20 Rule

**80% of value** comes from:
1. ✅ Jupyter notebooks for error analysis (manual review)
2. ✅ Custom annotation tools (planned - Week 2)
3. ✅ PromptFoo for CI/CD (already working)

**20% of value** comes from:
- Production monitoring (planned - Week 5-6)
- Advanced features (clustering, AI assistance)

### Error Analysis Process

You can run error analysis in two ways:

#### Option 1: Automated Analysis (Using Claude API)

Uses Claude API to automatically evaluate specs and categorize failures:

```bash
# Run automated error analysis
./evals/scripts/run-auto-error-analysis.sh

# Requirements:
# - ANTHROPIC_API_KEY environment variable set
# - Generated specs in evals/datasets/real-specs/

# Output:
# - Detailed CSV: evals/datasets/analysis-results/automated-analysis-<timestamp>.csv
# - Summary report: evals/datasets/analysis-results/summary-<timestamp>.txt
```

**Features:**
- Evaluates all specs automatically using Claude
- Binary pass/fail with reasoning
- Categorizes failures (incomplete requirements, ambiguous specs, etc.)
- Generates comprehensive reports
- Saves time on initial review

#### Option 2: Manual Analysis (Using Jupyter Notebook)

Traditional error analysis workflow for deep investigation:

```bash
# Launch Jupyter Lab
./evals/scripts/run-error-analysis.sh

# In Jupyter:
# 1. Load specs from datasets/real-specs/
# 2. Review and annotate manually
# 3. Categorize failures
# 4. Export results
```

**Process:**
1. **Open Coding** (Week 1)
   - Domain expert reviews 10-20 real specs/plans
   - Notes issues without categorization yet
   - Binary pass/fail (no Likert scales)

2. **Axial Coding** (Week 1-2)
   - Group similar failures into categories
   - Count frequency of each failure mode
   - Prioritize by impact

3. **Fix & Iterate** (Ongoing)
   - Fix high-frequency failure modes
   - Add automated checks to PromptFoo
   - Re-run error analysis monthly

### Plan Error Analysis (NEW)

In addition to spec evaluation, we now support error analysis for **implementation plans**.

#### Quick Start - Plan Analysis

```bash
# 1. Generate plan test data
cd evals/scripts
ANTHROPIC_BASE_URL="your-url" \
ANTHROPIC_AUTH_TOKEN="your-token" \
./evals/.venv/bin/python generate-real-plans.py

# 2. Run automated plan analysis
export ANTHROPIC_API_KEY="your-anthropic-key"
./run-auto-plan-analysis.sh

# Output:
# - evals/datasets/analysis-results/plan-analysis-<timestamp>.csv
# - evals/datasets/analysis-results/plan-summary-<timestamp>.txt
```

#### Plan Analysis Features

**Evaluation Criteria:**
- **Simplicity Gate**: ≤3 projects (CRITICAL - Constitution compliance)
- **Completeness**: All necessary components and phases defined
- **Clarity**: Project boundaries, tasks, and milestones clear
- **Appropriateness**: Simple architecture, no over-engineering
- **Constitution Compliance**: No microservices for simple apps, no premature optimization
- **Testability**: Testing strategy and verification steps included

**Common Failure Categories for Plans:**
- Too many projects (>3)
- Over-engineering
- Missing verification steps
- Unclear project boundaries
- Microservices for simple app
- Premature optimization
- Missing testing strategy
- Tech stack mismatch
- Incomplete milestones

**Current Status:**
- Plan evaluation integrated with PromptFoo (100% pass rate on 2 test cases)
- Error analysis infrastructure ready for expansion
- Support for both automated (Claude API) and manual review workflows

## Custom Annotation Tool

A fast, keyboard-driven web interface for reviewing generated specs - **10x faster than manual review**.

### Quick Start

```bash
# Run the annotation tool
./evals/scripts/run-annotation-tool.sh
```

Open your browser to `http://localhost:5001` and start reviewing specs.

### Features

- **Keyboard shortcuts**: N (next), P (previous), 1 (pass), 2 (fail)
- **Progress tracking**: Visual progress bar with statistics
- **Notes**: Add observations for each spec
- **Auto-save**: Annotations saved automatically to JSON
- **Export**: Export all annotations with timestamps

### Workflow

1. Review the spec displayed on the page
2. Evaluate quality (structure, completeness, clarity)
3. Add notes about any issues (optional)
4. Press **1** for Pass or **2** for Fail
5. Tool automatically advances to next spec
6. Click "Export JSON" when done

### Output

Annotations are saved to:
- `evals/annotation-tool/annotations.json` - Auto-saved current state
- `evals/annotation-tool/annotations_export_YYYYMMDD_HHMMSS.json` - Timestamped exports

Example output structure:

```json
{
  "exported_at": "2026-01-08T14:30:00",
  "statistics": {
    "total": 17,
    "passed": 12,
    "failed": 3,
    "pending": 2,
    "progress": 88.2
  },
  "annotations": {
    "spec-001.md": {
      "status": "pass",
      "notes": "Good structure, all sections present",
      "timestamp": "2026-01-08T14:25:00"
    }
  }
}
```

### What to Look For

Common failure patterns to note during review:
- Missing required sections
- Vague or unmeasurable requirements
- Premature technical decisions
- Missing acceptance criteria
- Incomplete user stories
- Security considerations missing
- Over-engineering indicators

See [annotation-tool/README.md](annotation-tool/README.md) for detailed documentation.

### What's Next

See [AI-EVALS-WORKPLAN.md](../AI-EVALS-WORKPLAN.md) for the complete implementation roadmap:

- **Week 1**: Error analysis foundation ✅ COMPLETED
- **Week 2-3**: Custom annotation tool ✅ COMPLETED
- **Week 4**: Extend PromptFoo based on findings ✅ COMPLETED (90% pass rate achieved!)
- **Week 5**: GitHub Actions CI/CD integration (NEXT)
- **Week 5-6**: Production monitoring (OPTIONAL)

### MVP Approach

We're following an iterative MVP approach:
- ✅ **Done**: Basic structure, notebooks, test data generation, annotation tool, PromptFoo extended with 90% pass rate
- 🔄 **Next**: GitHub Actions CI/CD to automate evals on every PR
- 📋 **Later (Optional)**: Production monitoring, advanced features

## Support

For evaluation framework issues:
- PromptFoo Discord: https://discord.gg/promptfoo
- PromptFoo GitHub: https://github.com/promptfoo/promptfoo

For spec-kit specific questions:
- Open issue: https://github.com/tikalk/agentic-sdlc-spec-kit/issues
