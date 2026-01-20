# Advanced Workflows

This document provides detailed information on the error analysis and annotation workflows used in the Spec-Kit Evaluation Framework.

## Error Analysis Workflow

PromptFoo provides automated regression testing, but **error analysis on real outputs** is the most important evaluation activity. According to AI evaluation best practices:

> "We spent 60-80% of our development time on error analysis and evaluation. Expect most of your effort to go toward understanding failures (i.e. looking at data) rather than building automated checks."

### Quick Start

```bash
# 1. Generate test data
cd evals/scripts
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

```text
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
# Run automated error analysis (uses default model)
./evals/scripts/run-auto-error-analysis.sh

# Use a specific model
./evals/scripts/run-auto-error-analysis.sh --model claude-opus-4-5-20251101

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
LLM_BASE_URL="your-url" \
LLM_AUTH_TOKEN="your-key" \
./evals/.venv/bin/python generate-real-plans.py

# 2. Run automated plan analysis (uses default model)
export ANTHROPIC_API_KEY="your-anthropic-key"
./run-auto-plan-analysis.sh

# Or use a specific model
./run-auto-plan-analysis.sh --model claude-opus-4-5-20251101

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

See [annotation-tool/README.md](../annotation-tool/README.md) for detailed documentation.
