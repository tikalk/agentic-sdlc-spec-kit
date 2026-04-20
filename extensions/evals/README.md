# Evals Extension

Build AI evaluation systems following Eval-Driven Development (EDD) principles with PromptFoo or DeepEval integration.

## Overview

The Evals extension implements a systematic evaluation lifecycle for AI systems, following EDD methodology to transform how teams validate and maintain LLM applications. It provides bottom-up error analysis, binary pass/fail evaluations, and production observability.

**Key Features**:
- Complete implementation of 10 EDD principles
- Goldset lifecycle (Draft → Accept → Publish)
- Evaluation pyramid (fast checks + semantic judges)
- PromptFoo or DeepEval integration
- Cross-functional insights for PMs, engineers, and domain experts

## Commands

| Command | Purpose |
|---------|---------|
| `/evals.init` | Set up evals/ directory (brownfield/greenfield, choose PromptFoo or DeepEval) |
| `/evals.specify` | Extract eval criteria from spec + error analysis (bottom-up) |
| `/evals.clarify` | Resolve ambiguities → accept criteria → goldset.md |
| `/evals.implement` | Generate config + graders (PromptFoo or DeepEval) |
| `/evals.validate` | Run evals + validate quality (TPR/TNR + pass rates) |
| `/evals.analyze` | Analyze results → team insights → optional PR |

## Quick Start

### Greenfield (From Spec)

```bash
/evals.init --system promptfoo    # Or --system deepeval
/evals.specify "Security requirements from spec"
/evals.clarify
/evals.implement
/evals.validate
```

### Brownfield (From Failures)

```bash
/evals.init
/evals.specify "Analyze auth bypass traces from production"
/evals.clarify
/evals.implement
/evals.validate
/evals.analyze                      # Generate team insights
```

## Goldset Lifecycle

Evaluations follow a structured lifecycle similar to ADRs/PDRs:

```
/evals.specify → /evals.clarify → /evals.implement → /evals.validate → /evals.analyze
   (draft)          (accept)        (publish)          (run)          (analyze)
```

| Phase | Command | Input | Output |
|-------|---------|-------|--------|
| **Draft** | `/evals.specify` | Failure traces + error analysis | Draft eval criteria in `.specify/drafts/` |
| **Accept** | `/evals.clarify` | Draft criteria | Accepted goldset in `evals/{system}/goldset.md` |
| **Publish** | `/evals.implement` | Goldset criteria | Executable graders + config files |
| **Run** | `/evals.validate` | Implemented evals | Test results + quality metrics |
| **Analyze** | `/evals.analyze` | Evaluation results | Team insights + patterns |

## Command Flow

```text
Brownfield (Error Analysis):
  /evals.init → /evals.specify → /evals.clarify → /evals.implement → /evals.validate → /evals.analyze
                   (analyze           (accept              (generate           (run evals)      (team insights)
                    failures)          criteria)            graders)

Greenfield (Spec-Driven):
  /evals.init → /evals.specify → /evals.clarify → /evals.implement → /evals.validate
                   (extract           (accept              (generate           (run evals)
                    from spec)         criteria)            graders)
```

## Integration Options

Choose between two evaluation frameworks:

### PromptFoo

**Best for**: Mixed tech stacks, extensive provider support, JavaScript-familiar teams

- JavaScript configuration + Python graders
- 50+ LLM provider support
- Rich dashboard and visualization
- Mature ecosystem

### DeepEval

**Best for**: Python-native projects, unified Python ecosystem

- Pure Python configuration and metrics
- Built-in LLM evaluation metrics
- Native pytest integration
- Async/await support

| Factor | PromptFoo | DeepEval |
|--------|-----------|----------|
| Configuration | JavaScript | Python |
| Graders | Python functions | Python classes |
| Providers | 50+ | OpenAI, Anthropic, custom |
| CI/CD | CLI-based | Python script |
| Learning Curve | Moderate | Low |

## The 10 EDD Principles

| # | Principle | Implementation |
|---|---|---|
| **I** | Spec-Driven Contracts | Specs precede evals; `/evals.specify` creates criteria from spec analysis |
| **II** | Binary Pass/Fail | All graders return `1.0` (pass) or `0.0` (fail) — no Likert scales |
| **III** | Error Analysis | Open/axial coding → bottom-up failure taxonomy from traces |
| **IV** | Evaluation Pyramid | Tier 1 (<30s CI/CD) + Tier 2 (<5min goldset judges) + Production sampling |
| **V** | Trajectory Observability | Full multi-turn traces with tool calls, not just outputs |
| **VI** | RAG Decomposition | Separate retrieval (IR metrics) from generation (LLM judges) |
| **VII** | Annotation Queues | High-risk traces route to humans for binary review |
| **VIII** | Close Production Loop | Spec failures → fix directives; Gen failures → build evaluator |
| **IX** | Test Data as Code | Version datasets; 10%+ adversarial; 20% holdout set |
| **X** | Cross-Functional | PMs, domain experts, AI engineers collaborate via `/evals.analyze` |

### Key Implementation Details

- **Binary Enforcement**: No confidence scores or subjective scales allowed
- **Error Analysis**: `/evals.specify` (open coding) → `/evals.clarify` (axial coding) → theoretical saturation
- **Evaluation Pyramid**: Fast security checks + semantic judges in CI/CD; 10-20% production sampling
- **Production Loop**: `evals.implement` gates route `specification_failure` to specs/ and `generalization_failure` to evaluator backlog

## Evaluation Files

| File | Location | Purpose |
|------|----------|---------|
| Draft Criteria | `.specify/drafts/eval-*.md` | Draft eval records (bottom-up from failures) |
| Goldset | `evals/{system}/goldset.md` | Published eval criteria (markdown + YAML) |
| Goldset JSON | `evals/{system}/goldset.json` | Auto-generated for framework consumption |
| Graders | `evals/{system}/graders/` | Python functions (PromptFoo) or classes (DeepEval) |
| Config | `evals/{system}/config.{js,py}` | Framework-specific configuration |
| Results | `evals/results/` | Git-ignored evaluation outputs |

```
{project}/
├── .specify/
│   ├── drafts/eval-*.md          # Draft eval records
│   └── config.yml                # System configuration
├── evals/{system}/               # promptfoo | deepeval
│   ├── goldset.md                # Published evals
│   ├── goldset.json              # Auto-generated
│   ├── config.{js,py}            # Framework config
│   ├── graders/                  # Python graders or metrics
│   └── holdout.md                # Protected dataset
└── specs/{feature}/tasks.md     # [EVAL] markers
```

## Using Commands

### `/evals.init` - Initialize Eval System

```bash
/evals.init                      # Choose integration interactively
/evals.init --system promptfoo   # JavaScript + Python
/evals.init --system deepeval    # Python-native
```

Creates directory structure and framework configuration.

### `/evals.specify` - Extract Eval Criteria

```bash
/evals.specify "Analyze auth failures from production"
```

Bottom-up error analysis: traces → open coding → draft criteria.

### `/evals.clarify` - Accept Criteria

```bash
/evals.clarify
```

Axial coding to cluster patterns → goldset.md + goldset.json.

### `/evals.implement` - Generate Graders

```bash
/evals.implement
```

Creates executable graders + framework configs (Tier 1 + Tier 2).

### `/evals.validate` - Run and Validate

```bash
/evals.validate
/evals.validate --holdout-only
```

Executes evals + validates quality (TPR/TNR, SLA compliance, EDD principles).

### `/evals.analyze` - Team Insights

```bash
/evals.analyze
/evals.analyze --focus security
```

Analyzes results → failure patterns → cross-functional insights → optional PR.

## CI/CD Integration

### PromptFoo Pipeline

```yaml
# .github/workflows/evals.yml
- run: npm install -g promptfoo
- run: promptfoo eval --config evals/promptfoo/config-tier1.js
  timeout-minutes: 1
- run: promptfoo eval --config evals/promptfoo/config-tier2.js
  timeout-minutes: 5
```

### DeepEval Pipeline

```yaml
# .github/workflows/evals.yml
- run: pip install deepeval pytest
- run: python evals/deepeval/config-tier1.py
  timeout-minutes: 1
- run: pytest evals/deepeval/tests/ -v
```

### PromptFoo Grader Example

```python
# evals/promptfoo/graders/check_auth_token.py
def evaluate(output: str, context: dict) -> dict:
    """Binary pass/fail - EDD Principle II"""
    if re.search(r'token.*exposed', output):
        return {'pass': False, 'score': 0.0, 'reason': 'Token exposure'}
    return {'pass': True, 'score': 1.0, 'reason': 'Safe handling'}
```

### DeepEval Metric Example

```python
# evals/deepeval/graders/auth_token_metric.py
from deepeval.metrics import BaseMetric

class AuthTokenMetric(BaseMetric):
    """Binary metric - EDD Principle II"""
    def measure(self, test_case) -> float:
        if re.search(r'token.*exposed', test_case.actual_output):
            self.success = False
            return 0.0
        self.success = True
        return 1.0
```

## Configuration

Configure via `.specify/extensions/evals/evals-config.yml`:

```yaml
# Core settings
system: "promptfoo"  # promptfoo | deepeval

# Evaluation pyramid (EDD Principle IV)
evaluation_pyramid:
  tier1:
    timeout_seconds: 30
    security_baseline: true
  tier2:
    timeout_seconds: 300
    goldset_judges: true

# Test data hygiene (EDD Principle IX)
test_data:
  adversarial_ratio: 0.1
  holdout_ratio: 0.2

# Quality thresholds
quality:
  min_pass_rate: 0.8
  min_true_positive_rate: 0.9
  max_false_positive_rate: 0.1
```

## Integration with Spec Workflow

Evals integrate via automatic task markers:

```text
/architect.specify → /architect.implement → /spec.specify → /spec.tasks
                                                                  │
                                                                  ▼
                                                     /evals.tasks (auto-match)
                                                                  │
                                                                  ▼
                                                      tasks.md with [EVAL] markers
```

**Automatic matching**: Published evals auto-match to tasks via keyword overlap and tags.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Low coverage | `/evals.tasks --dry-run` to identify gaps, `/evals.specify` to add evals |
| Config errors | `/evals.implement --force-regenerate` |
| SLA timeouts | `/evals.validate --performance-only`, move complex graders to Tier 2 |
| High false positives | `/evals.clarify` to refine criteria, `/evals.analyze` to add examples |

**Debug mode**: `export EVALS_DEBUG=1` for detailed logging.

## Best Practices

1. **Start with error analysis** - Use actual failure traces, not hypothetical scenarios
2. **Binary pass/fail only** - Never use Likert scales or confidence scores
3. **Balance speed/coverage** - Tier 1 (<30s) for fast checks, Tier 2 (<5min) for semantic judges
4. **Version everything** - Goldsets, datasets, configs under version control
5. **Cross-functional collaboration** - Include domain experts, use `/evals.analyze` for insights

## Related

- **EDD Methodology**: [Google Doc](https://docs.google.com/document/d/1O0XSF31Fp9e6SXFCujO6C2zATPVAk_HJayzhg-KYAEo)
- **PromptFoo**: https://promptfoo.dev/
- **DeepEval**: https://docs.confident-ai.com/
- **Error Analysis**: Paweł Huryn's methodology (Issue #78)
- **Spec Kit**: https://github.com/tikalk/agentic-sdlc-spec-kit

## License

MIT