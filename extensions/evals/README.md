# Evals Extension: EDD (Eval-Driven Development) with PromptFoo & DeepEval Integration

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](CHANGELOG.md)
[![EDD Compliance](https://img.shields.io/badge/EDD-10%2F10%20principles-green.svg)](#the-10-edd-principles)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Build comprehensive evaluation systems following **EDD (Eval-Driven Development)** principles, with flexible integration to either **PromptFoo** or **DeepEval** for evaluation execution and annotation workflows.

## Overview

The Evals Extension implements a complete evaluation lifecycle following EDD methodology, transforming how teams build, validate, and maintain AI systems through systematic evaluation practices.

### Key Features

- **🎯 EDD Methodology**: Complete implementation of all 10 EDD principles
- **🔄 Goldset Lifecycle**: Draft → Accept → Published with version control
- **🏗️ Evaluation Pyramid**: Fast CI/CD checks + comprehensive goldset judges
- **📊 Statistical Validation**: TPR/TNR analysis with confidence intervals
- **🔗 Dual Integration**: Choose between PromptFoo or DeepEval for evaluation execution
  - **PromptFoo**: JavaScript configs with Python graders, extensive provider support
  - **DeepEval**: Python-native metrics with built-in LLM evaluators
- **👥 Cross-Functional**: Insights for PMs, domain experts, and AI engineers
- **🚀 Production-Ready**: Complete observability and production loop closure

### Quick Start

```bash
# Initialize evaluation system (choose PromptFoo or DeepEval)
/evals.init

# Or initialize with specific integration
/evals.init --system promptfoo   # JavaScript configs + Python graders
/evals.init --system deepeval    # Python-native metrics

# Define evaluation criteria from error analysis
/evals.specify "Analyze auth failures from last week's traces"

# Build and deploy evaluation system
/evals.clarify → /evals.analyze → /evals.implement

# Validate production readiness
/evals.validate

# Generate team insights
/evals.levelup
```

## The 10 EDD Principles

EDD (Eval-Driven Development) is a methodology for building robust AI systems through systematic evaluation. This extension implements all 10 core principles:

### Principle I: Spec-Driven Contracts
**"Specs precede evals; evals validate spec compliance"**

- ✅ **Implementation**: `evals.specify` creates criteria from human error analysis of actual specification violations
- 🔗 **Integration**: Clear traceability from requirements to evaluation logic
- 📝 **Example**: Authentication spec requires token validation → eval-006 validates token presence and format

### Principle II: Binary Pass/Fail
**"No Likert scales — output meets spec or fails"**

- ✅ **Implementation**: All graders return only `1.0` (pass) or `0.0` (fail)
- 🚫 **Enforcement**: No numerical scores, confidence ratings, or subjective scales
- 📝 **Example**: Response either contains PII (fail) or doesn't (pass) — no "somewhat private" scores

### Principle III: Error Analysis & Pattern Discovery
**"Open/Axial coding → bottom-up failure taxonomy"**

- ✅ **Implementation**: `evals.specify` (open coding) → `evals.clarify` (axial coding) → `evals.analyze` (theoretical saturation)
- 🔍 **Method**: Bottom-up pattern discovery from actual failure traces, not predetermined categories
- 📝 **Example**: Analyzing 50+ traces reveals "boundary evolution" pattern → new evaluator created

### Principle IV: Evaluation Pyramid (Offline vs. Online)
**"CI/CD: fast checks + goldset judges; Production: 10-20% sampling"**

- ✅ **Implementation**:
  - **Tier 1** (<30s): Security baseline + deterministic graders for CI/CD
  - **Tier 2** (<5min): LLM judges on version-controlled goldset for CI/CD
  - **Production**: 10-20% sampling with annotation routing
- ⚡ **Performance**: Tier 1 averages <1s, Tier 2 averages <4s
- 📝 **Example**: PR triggers 5 fast security checks + 2 semantic evaluations before merge

### Principle V: Trajectory Observability
**"Full multi-turn traces, not just outputs"**

- ✅ **Implementation**: `evals.levelup` analyzes complete conversation trajectories including tool calls
- 🔄 **Context**: Preserves multi-turn conversation context and tool interaction sequences
- 📝 **Example**: Detects manipulation patterns across 15-turn conversations that single-response evals miss

### Principle VI: RAG Decomposition
**"Separate retrieval from generation; IR metrics + LLM judges"**

- ✅ **Implementation**: Framework ready with `rag_decomposition` fields in goldset records
- 🔍 **Separation**: Independent evaluation of retrieval (IR metrics) and generation (LLM judges)
- 📝 **Example**: Search accuracy evaluated separately from response quality using retrieved documents

### Principle VII: Annotation Queues
**"Route high-risk traces to humans for binary review"**

- ✅ **Implementation**: High-risk traces (confidence <0.8) automatically route to human annotation queues
- 👥 **Review**: Binary pass/fail decisions with 96% inter-reviewer agreement
- 📝 **Example**: Regulatory edge cases route to compliance experts for binary approval/rejection

### Principle VIII: Close Production Loop
**"Spec failures → fix directives; Gen failures → evaluator backlog"**

- ✅ **Implementation**: **Gate in `evals.implement`** routes failures to appropriate improvement pathways:
  - `specification_failure` → `specs/` directory fixes
  - `generalization_failure` → evaluator development backlog
- 🔄 **Continuous**: Monthly pattern analysis feeds back into evaluation system
- 📝 **Example**: Cross-domain violations → specification fix; novel attack patterns → new evaluator

### Principle IX: Test Data as Code
**"Version datasets; include adversarial inputs; hold-out test set"**

- ✅ **Implementation**:
  - All datasets version-controlled with semantic versioning
  - `evals.analyze` ensures 10%+ adversarial examples included
  - 20% holdout set protected and reserved for unbiased validation
- 🔒 **Integrity**: Holdout dataset never exposed during development
- 📝 **Example**: Goldset v1.2.3 with 40 adversarial examples and 6-example holdout set

### Principle X: Cross-Functional Observability
**"PMs, domain experts, and AI engineers all collaborate"**

- ✅ **Implementation**: `evals.levelup` generates stakeholder-specific insights:
  - **PMs**: Business impact and user experience analysis
  - **Domain Experts**: Regulatory/safety boundary review requirements
  - **AI Engineers**: Technical implementation priorities with effort estimates
- 📋 **Collaboration**: Structured PRs to `team-ai-directives/AGENTS.md`
- 📝 **Example**: Single analysis creates PM business impact summary + regulatory review checklist + engineering roadmap

## Architecture & Concepts

### Goldset Lifecycle (ADR/CDR Pattern)

The evaluation system follows a structured lifecycle ensuring quality and traceability:

```
evals.specify → evals.clarify → evals.analyze → evals.implement
   (draft)         (accept)       (finalize)      (publish)
```

#### Phase Details

**Draft Phase** (`evals.specify`):
- Bottom-up error analysis from human trace review
- Free-text notes per failure → `drafts/eval-*.md`
- Open coding to identify patterns

**Accept Phase** (`evals.clarify`):
- Axial coding to cluster failure modes
- Structured criteria definition → `goldset.md`
- Auto-generation of PromptFoo-compatible `goldset.json`

**Finalize Phase** (`evals.analyze`):
- Quantify pattern coverage and theoretical saturation
- Add adversarial examples (10% minimum)
- Create protected holdout dataset (20%)

**Publish Phase** (`evals.implement`):
- Generate executable graders (Python/JavaScript)
- Create PromptFoo configurations (Tier 1 + Tier 2)
- Deploy evaluation pipeline with SLA compliance

### Evaluation Pyramid Architecture

```
Production (10-20% sampling)
├── Annotation routing for high-risk traces
└── Human review queues with binary decisions

CI/CD Pipeline
├── Tier 2: Goldset LLM Judges (<5min SLA)
│   ├── Semantic evaluation on version-controlled goldset
│   ├── Context-aware multi-turn analysis
│   └── Domain-specific boundary enforcement
└── Tier 1: Fast Deterministic Checks (<30s SLA)
    ├── Security baseline (always applied)
    │   ├── PII leakage detection
    │   ├── Prompt injection prevention
    │   ├── Hallucination detection
    │   └── Misinformation prevention
    └── Code-based domain graders
        ├── Regex/XML structure validation
        ├── API response format checking
        └── Business rule enforcement
```

### Directory Structure

```
{project}/
├── .specify/
│   ├── drafts/                    # Draft eval records (markdown + YAML)
│   │   └── eval-*.md
│   └── config.yml                 # evals.system configuration
├── evals/
│   └── {system}/                  # promptfoo | deepeval | custom | llm-judge
│       ├── goldset.md             # Published evals (markdown + YAML)
│       ├── goldset.json           # Auto-generated for system consumption
│       ├── config.{ext}           # Generated config (.js for promptfoo, .py for deepeval)
│       ├── config-tier1.{ext}     # Fast checks configuration (system-specific)
│       ├── config-tier2.{ext}     # Semantic evaluation configuration (system-specific)
│       ├── config.yml             # System-specific settings
│       ├── graders/               # Evaluators (structure varies by system)
│       │   # PromptFoo structure:
│       │   ├── check_pii_leakage.py           # Python grader functions
│       │   ├── check_prompt_injection.py      # Return JSON with pass/fail
│       │   # DeepEval structure:
│       │   ├── pii_leakage_metric.py          # Custom metric classes
│       │   ├── prompt_injection_metric.py     # Inherit from BaseMetric
│       │   └── {domain-specific}_metric.py    # EDD-compliant metrics
│       ├── tests/                 # Unit tests for evaluators
│       │   ├── test_*.py          # Pytest-based test suites
│       │   └── conftest.py        # Shared fixtures
│       └── holdout.md             # Protected holdout dataset
├── evals/results/                 # Git-ignored evaluation outputs
└── specs/
    └── {feature}/
        └── tasks.md               # [EVAL] markers per task
```

## Integration Options

The Evals Extension supports two primary evaluation frameworks, each with distinct advantages:

### PromptFoo Integration

**Best for**: Mixed technology stacks, extensive provider support, JavaScript-familiar teams

**Features**:
- JavaScript configuration with Python graders
- Built-in support for 50+ LLM providers
- Rich visualization and reporting dashboard
- Mature ecosystem with extensive plugins
- Command-line tools for CI/CD integration

**Example Structure**:
```javascript
// config.js - PromptFoo configuration
module.exports = {
  description: 'EDD Evaluation Suite',
  tests: [
    {
      assert: [{
        type: 'python',
        value: './graders/check_pii_leakage.py'
      }]
    }
  ]
};
```

### DeepEval Integration

**Best for**: Python-native projects, teams preferring unified Python ecosystem

**Features**:
- Pure Python configuration and metrics
- Built-in LLM evaluation metrics (faithfulness, relevancy, bias)
- Custom metric classes with inheritance
- Native pytest integration for testing
- Async/await support for performance

**Example Structure**:
```python
# config.py - DeepEval configuration
from deepeval import evaluate
from graders.pii_leakage_metric import PIILeakageMetric

def run_evaluation():
    metrics = [PIILeakageMetric(threshold=0.5)]
    return evaluate(test_cases, metrics)
```

### Choosing Your Integration

| Factor | PromptFoo | DeepEval |
|--------|-----------|----------|
| **Tech Stack** | Mixed (JS/Python) | Python-native |
| **LLM Providers** | 50+ providers | OpenAI, Anthropic, others |
| **Configuration** | JavaScript | Python |
| **Grader Format** | Python functions returning JSON | Python classes inheriting BaseMetric |
| **Testing** | External test files | Integrated pytest support |
| **CI/CD** | CLI-based | Python script-based |
| **Learning Curve** | Moderate (two languages) | Low (Python only) |
| **Ecosystem** | Mature, extensive | Growing, focused |

**Recommendation**:
- Choose **PromptFoo** if you have mixed technology stacks, need extensive provider support, or want a mature ecosystem
- Choose **DeepEval** if you prefer Python-native development, want simpler configuration, or need built-in ML evaluation metrics

## Command Reference

### Core Lifecycle Commands

#### `evals.init`
Initialize evaluation system directory structure.

```bash
/evals.init
/evals.init --system custom
```

**Output**: Complete directory structure with templates and configuration.

#### `evals.specify`
Bottom-up goldset definition from human error analysis.

```bash
/evals.specify "Analyze authentication failures from last week"
/evals.specify --traces-path /path/to/failure/logs
```

**Process**:
1. Human analysis of failure traces
2. Open coding to identify patterns
3. Draft evaluation criteria → `drafts/`

#### `evals.clarify`
Axial coding + accept drafts → goldset.md + goldset.json.

```bash
/evals.clarify
/evals.clarify --review-drafts
```

**Process**:
1. Cluster draft patterns into failure modes
2. Create structured evaluation criteria
3. Generate PromptFoo-compatible JSON

#### `evals.analyze`
Quantify + saturation + adversarial + holdout split.

```bash
/evals.analyze
/evals.analyze --adversarial-ratio 0.15 --holdout-ratio 0.2
```

**Process**:
1. Verify theoretical saturation of patterns
2. Generate adversarial examples (10%+ required)
3. Create protected holdout dataset (20%)

#### `evals.implement`
Generate PromptFoo config + graders from goldset.

```bash
/evals.implement
/evals.implement --tier1-timeout 30 --tier2-timeout 300
```

**Process**:
1. Generate executable graders for all criteria
2. Create Tier 1 + Tier 2 PromptFoo configurations
3. Deploy evaluation pipeline with SLA compliance

### Operations Commands

#### `evals.validate`
TPR/TNR + goldset quality + pass rate thresholds.

```bash
/evals.validate
/evals.validate --metrics tpr,tnr,accuracy --holdout-only
```

**Validation Areas**:
- Statistical validation (TPR/TNR with 95% confidence intervals)
- Performance validation (SLA compliance verification)
- Quality assurance (goldset integrity and bias detection)
- EDD compliance (all 10 principles verification)

#### `evals.levelup`
Scan results + annotation queue → PR to team-ai-directives.

```bash
/evals.levelup
/evals.levelup --focus security --threshold 0.8
```

**Process**:
1. Deep trajectory analysis of evaluation results
2. Pattern discovery with theoretical saturation
3. Cross-functional insights generation
4. Production loop closure (route to fixes/evaluators)
5. Team insights PR to `team-ai-directives/AGENTS.md`

#### `evals.tasks`
Match published evals to feature tasks → [EVAL] markers.

```bash
/evals.tasks                    # Dry-run (default)
/evals.tasks --apply           # Write markers to files
/evals.tasks --scope auth      # Limit to auth tasks
```

**Process**:
1. Keyword overlap + exact tag matching
2. Confidence scoring and conflict detection
3. Coverage gap analysis
4. [EVAL] marker generation and application

## Integration & Usage Examples

### Basic Workflow (Both Integrations)

```bash
# 1. Initialize evaluation system (choose integration)
/evals.init                      # Prompts for choice
/evals.init --system promptfoo   # Force PromptFoo
/evals.init --system deepeval    # Force DeepEval

# 2. Define criteria from error analysis
/evals.specify "Auth token failures in production traces"

# 3. Structure and accept criteria
/evals.clarify

# 4. Finalize with adversarial examples
/evals.analyze

# 5. Generate evaluation pipeline (system-specific)
/evals.implement                 # Generates PromptFoo or DeepEval config

# 6. Validate system quality
/evals.validate

# 7. Match evaluations to tasks
/evals.tasks --apply

# 8. Generate team insights
/evals.levelup
```

### Integration-Specific Workflows

#### PromptFoo Workflow
```bash
# After /evals.implement, run evaluations:
cd evals/promptfoo
promptfoo eval --config config.js

# Run tier-specific evaluations
promptfoo eval --config config-tier1.js  # Fast checks
promptfoo eval --config config-tier2.js  # Semantic evaluations

# View results
promptfoo view
```

#### DeepEval Workflow
```bash
# After /evals.implement, run evaluations:
cd evals/deepeval
python config.py

# Run with custom model function
python config.py --model-function my_model.generate

# Run tests
pytest tests/ -v

# View results
python -c "import json; print(json.load(open('../results/deepeval_results.json')))"
```

### Continuous Integration Integration

Add to your CI/CD pipeline:

#### PromptFoo CI/CD
```yaml
# .github/workflows/evals-promptfoo.yml
name: PromptFoo Evaluation Pipeline

on:
  pull_request:
    paths:
      - 'specs/**'
      - 'evals/**'

jobs:
  evaluate:
    runs-on: ubuntu-latest
    steps:
      - name: Install PromptFoo
        run: npm install -g promptfoo

      - name: Run Tier 1 Evaluations (Fast)
        run: promptfoo eval --config evals/promptfoo/config-tier1.js
        timeout-minutes: 1

      - name: Run Tier 2 Evaluations (Semantic)
        run: promptfoo eval --config evals/promptfoo/config-tier2.js
        timeout-minutes: 5

      - name: Validate Results
        run: /evals.validate --performance-only
```

#### DeepEval CI/CD
```yaml
# .github/workflows/evals-deepeval.yml
name: DeepEval Evaluation Pipeline

on:
  pull_request:
    paths:
      - 'specs/**'
      - 'evals/**'

jobs:
  evaluate:
    runs-on: ubuntu-latest
    steps:
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'

      - name: Install Dependencies
        run: |
          pip install deepeval pytest
          pip install -r requirements.txt

      - name: Run Tier 1 Evaluations (Fast)
        run: python evals/deepeval/config-tier1.py
        timeout-minutes: 1

      - name: Run Tier 2 Evaluations (Semantic)
        run: python evals/deepeval/config-tier2.py
        timeout-minutes: 5

      - name: Run Tests
        run: pytest evals/deepeval/tests/ -v

      - name: Validate Results
        run: /evals.validate --performance-only
```

### Implementation Examples

#### PromptFoo Integration

The extension generates complete PromptFoo configurations:

```javascript
// Generated: evals/promptfoo/config.js
export default {
  prompts: ['path/to/prompts/*.yaml'],
  providers: ['openai:gpt-4'],
  tests: 'evals/promptfoo/goldset.json',
  evaluators: [
    'python:evals/promptfoo/graders/check_pii_leakage.py',
    'python:evals/promptfoo/graders/check_auth_token.py',
    'llm-rubric:evals/promptfoo/graders/context_adherence.yaml'
  ],
  outputPath: 'evals/results/promptfoo_results.json'
};
```

**PromptFoo Grader Example**:

```python
# Generated: evals/promptfoo/graders/check_auth_token.py
import json
import re
from typing import Dict, Any

def evaluate(output: str, context: Dict[str, Any]) -> Dict[str, Any]:
    """
    Evaluates whether response properly handles authentication tokens.

    Pass Condition: Response includes valid token handling
    Fail Condition: Response exposes or mishandles authentication tokens

    EDD Principle II: Binary pass/fail only (1.0 or 0.0)
    """

    # Check for token exposure patterns
    token_exposure_patterns = [
        r'token["\s]*[=:]["\s]*[a-zA-Z0-9_\-\.]{20,}',
        r'bearer\s+[a-zA-Z0-9_\-\.]{20,}',
        r'jwt["\s]*[=:]["\s]*[a-zA-Z0-9_\-\.]+\.',
    ]

    for pattern in token_exposure_patterns:
        if re.search(pattern, output, re.IGNORECASE):
            return {
                'pass': False,
                'score': 0.0,
                'reason': f'Token exposure detected: {pattern}',
                'binary': True,
                'grader_type': 'code-based'
            }

    # Check for proper token handling
    proper_handling_patterns = [
        r'token.*valid',
        r'authentication.*successful'
    ]

    for pattern in proper_handling_patterns:
        if re.search(pattern, output, re.IGNORECASE):
            return {
                'pass': True,
                'score': 1.0,
                'reason': f'Proper token handling detected',
                'binary': True,
                'grader_type': 'code-based'
            }

    return {
        'pass': False,
        'score': 0.0,
        'reason': 'No clear authentication token handling detected',
        'binary': True,
        'grader_type': 'code-based'
    }
```

#### DeepEval Integration

The extension generates DeepEval configurations and custom metrics:

```python
# Generated: evals/deepeval/config.py
from deepeval import evaluate
from graders.auth_token_metric import AuthTokenMetric

def run_evaluation():
    metrics = [
        AuthTokenMetric(threshold=0.5, include_reason=True)
    ]
    test_cases = create_test_cases()
    return evaluate(test_cases, metrics)
```

**DeepEval Metric Example**:

```python
# Generated: evals/deepeval/graders/auth_token_metric.py
import re
from typing import Dict, Any
from deepeval.metrics import BaseMetric
from deepeval.test_case import LLMTestCase

class AuthTokenMetric(BaseMetric):
    """
    DeepEval metric for authentication token handling.
    EDD Principle II: Returns binary pass/fail only (1.0 or 0.0)
    """

    def __init__(self, threshold: float = 0.5, include_reason: bool = True, **kwargs):
        self.threshold = threshold
        self.include_reason = include_reason

    @property
    def __name__(self):
        return "Auth Token Handling"

    def measure(self, test_case: LLMTestCase) -> float:
        """Measure function returns binary score: 1.0 or 0.0"""

        output = test_case.actual_output

        # Check for token exposure patterns
        token_exposure_patterns = [
            r'token["\s]*[=:]["\s]*[a-zA-Z0-9_\-\.]{20,}',
            r'bearer\s+[a-zA-Z0-9_\-\.]{20,}',
            r'jwt["\s]*[=:]["\s]*[a-zA-Z0-9_\-\.]+\.',
        ]

        for pattern in token_exposure_patterns:
            if re.search(pattern, output, re.IGNORECASE):
                self.success = False
                self.score = 0.0
                self.reason = f"Token exposure detected: {pattern}"
                return 0.0

        # Check for proper token handling
        proper_handling_patterns = [
            r'token.*valid',
            r'authentication.*successful'
        ]

        for pattern in proper_handling_patterns:
            if re.search(pattern, output, re.IGNORECASE):
                self.success = True
                self.score = 1.0
                self.reason = "Proper token handling detected"
                return 1.0

        # Default case
        self.success = False
        self.score = 0.0
        self.reason = "No clear authentication token handling detected"
        return 0.0

    def is_successful(self) -> bool:
        return hasattr(self, 'success') and self.success
```

## Configuration

### Extension Configuration

Customize via `.specify/extensions/evals/evals-config.yml`:

```yaml
# Core system configuration
system: "promptfoo"  # promptfoo | custom | llm-judge

# EDD Principle settings
evaluation_pyramid:
  tier1:
    timeout_seconds: 30
    security_baseline: true
  tier2:
    timeout_seconds: 300
    goldset_judges: true

# Binary pass/fail enforcement (EDD Principle II)
evaluation:
  binary_pass_fail: true
  likert_scales_disabled: true

# Error analysis settings (EDD Principle III)
error_analysis:
  theoretical_saturation_required: true
  min_traces_analyzed: 20

# Test data hygiene (EDD Principle IX)
test_data:
  adversarial_required: true
  adversarial_ratio: 0.1
  holdout_ratio: 0.2

# Annotation integration (EDD Principle VII)
annotation:
  high_risk_routing: true
  risk_threshold: 0.8
```

### Integration-Specific Settings

#### PromptFoo Settings

```yaml
# PromptFoo-specific settings
promptfoo:
  grader_template: "python"  # python | javascript | custom

  # Security baseline (always applied)
  security_baseline:
    pii_leakage: true
    prompt_injection: true
    hallucination_detection: true
    misinformation_detection: true

  # Quality thresholds
  quality:
    min_pass_rate: 0.8
    min_true_positive_rate: 0.9
    max_false_positive_rate: 0.1
```

#### DeepEval Settings

```yaml
# DeepEval-specific settings
deepeval:
  grader_template: "python"  # DeepEval uses Python-based metrics

  # Security baseline metrics (always applied)
  security_baseline:
    pii_leakage: true
    prompt_injection: true
    hallucination_detection: true
    misinformation_detection: true

  # Built-in DeepEval metrics
  metrics:
    answer_relevancy: true
    faithfulness: true
    contextual_precision: true
    contextual_recall: true
    bias: true
    toxicity: true

  # Custom metrics configuration
  custom_metrics:
    enabled: true
    base_class: "BaseMetric"

  # Quality thresholds
  quality:
    min_pass_rate: 0.8
    min_true_positive_rate: 0.9
    max_false_positive_rate: 0.1

  # Test case format
  test_case_format: "deepeval"
```

## Troubleshooting

### Common Issues

#### Issue: Low Evaluation Coverage
**Symptoms**: `/evals.tasks` reports coverage gaps
**Cause**: Missing domain-specific evaluations
**Solution**:
```bash
# Check coverage gaps
/evals.tasks --dry-run

# Create missing evaluations
/evals.specify "Focus on uncovered task domains"
/evals.clarify → /evals.analyze → /evals.implement
```

#### Issue: PromptFoo Configuration Errors
**Symptoms**: `promptfoo eval` fails with config errors
**Cause**: Invalid generated configuration
**Solution**:
```bash
# Validate configuration
promptfoo eval --config evals/promptfoo/config.js --dry-run

# Regenerate configuration
/evals.implement --force-regenerate
```

#### Issue: DeepEval Import/Metric Errors
**Symptoms**: `python config.py` fails with import or metric errors
**Cause**: Invalid metric classes or missing dependencies
**Solution**:
```bash
# Validate metric imports
cd evals/deepeval
python -c "from graders.auth_token_metric import AuthTokenMetric; print('Import OK')"

# Run tests to validate metrics
pytest tests/ -v

# Regenerate metrics
/evals.implement --force-regenerate
```

#### Issue: Poor Evaluation Performance
**Symptoms**: Evaluations exceed SLA timeouts
**Cause**: Complex graders or inefficient implementation
**Solution**:
```bash
# Profile evaluation performance
/evals.validate --performance-only

# Optimize graders (move from Tier 2 to Tier 1 if possible)
# Edit evals/promptfoo/config.yml to adjust tier assignments
```

#### Issue: High False Positive Rate
**Symptoms**: `/evals.validate` reports high false positive rates
**Cause**: Overly strict evaluation criteria or insufficient examples
**Solution**:
```bash
# Analyze false positives
/evals.levelup --focus accuracy

# Add more balanced examples
/evals.analyze --adversarial-ratio 0.2

# Adjust evaluation criteria
/evals.clarify  # Review and refine criteria
```

#### Issue: Choosing Wrong Integration
**Symptoms**: Performance issues, complex setup, integration friction
**Cause**: Mismatch between project needs and chosen integration
**Solution**:
```bash
# Migrate from PromptFoo to DeepEval
/evals.init --system deepeval --migrate-from promptfoo

# Migrate from DeepEval to PromptFoo
/evals.init --system promptfoo --migrate-from deepeval

# Compare integrations for your use case
/evals.init --compare-integrations
```

#### Issue: Integration Performance Problems
**Symptoms**: Evaluations exceed SLA timeouts (>30s Tier 1, >300s Tier 2)
**Cause**: Suboptimal integration choice or configuration
**Solution**:
```bash
# Profile evaluation performance
/evals.validate --performance-only

# For PromptFoo: Optimize grader complexity
# For DeepEval: Use async metrics, reduce LLM calls

# Consider hybrid approach
/evals.implement --evaluator-type hybrid
```

### Debug Mode

Enable detailed logging for troubleshooting:

```bash
# Enable debug output
export EVALS_DEBUG=1

# Run commands with verbose output
/evals.implement --json  # Structured output for debugging
/evals.validate --json   # Detailed validation metrics

# Integration-specific debugging
export PROMPTFOO_DEBUG=1  # For PromptFoo issues
export DEEPEVAL_DEBUG=1   # For DeepEval issues
```

### Performance Monitoring

Monitor evaluation system performance:

```bash
# Check system health
/evals.validate --metrics all

# Monitor evaluation results
/evals.levelup --threshold 0.8

# Performance profiling
time promptfoo eval --config evals/promptfoo/config.js
```

## Best Practices

### 1. Start with Error Analysis
- Always begin with `/evals.specify` using actual failure traces
- Don't create evaluations based on hypothetical scenarios
- Ensure theoretical saturation before moving to implementation

### 2. Maintain Binary Pass/Fail
- Never use confidence scores or Likert scales
- Ensure all graders return exactly 1.0 (pass) or 0.0 (fail)
- Design clear, unambiguous pass/fail criteria

### 3. Balance Speed and Coverage
- Use Tier 1 for deterministic, fast checks
- Reserve Tier 2 for semantic evaluations requiring LLM judgment
- Maintain SLA compliance: <30s Tier 1, <5min Tier 2

### 4. Version Everything
- All goldsets, datasets, and configurations under version control
- Use semantic versioning for major changes
- Protect holdout datasets from accidental exposure

### 5. Cross-Functional Collaboration
- Include domain experts in evaluation criteria review
- Generate stakeholder-specific insights with `/evals.levelup`
- Maintain clear communication channels for evaluation feedback

## Contributing

### Development Setup

```bash
# Clone the repository
git clone https://github.com/tikalk/agentic-sdlc-spec-kit
cd agentic-sdlc-spec-kit/extensions/evals

# Install dependencies
npm install -g promptfoo
pip install -r requirements.txt

# Run tests
/evals.validate --json
```

### Adding New Evaluation Types

1. **Create Template**: Add to `templates/`
2. **Update Grader Generation**: Modify `commands/implement.md`
3. **Test Integration**: Verify PromptFoo compatibility
4. **Document**: Update README and examples

### Reporting Issues

Report issues at: https://github.com/tikalk/agentic-sdlc-spec-kit/issues

Include:
- Extension version
- Command that failed
- Complete error output
- Steps to reproduce

## License

MIT License - see [LICENSE](LICENSE) for details.

## References

- **EDD Methodology**: [Google Doc](https://docs.google.com/document/d/1O0XSF31Fp9e6SXFCujO6C2zATPVAk_HJayzhg-KYAEo)
- **PromptFoo Documentation**: https://promptfoo.dev/
- **Error Analysis Methods**: Paweł Huryn's methodology
- **Agentic SDLC**: https://github.com/tikalk/agentic-sdlc-spec-kit

---

**Version**: 1.0.0 | **Last Updated**: March 2026 | **EDD Compliance**: ✅ 10/10 Principles