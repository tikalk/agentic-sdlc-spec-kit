# Running Evaluators

Generic evaluator execution framework. Auto-discovers graders, runs against goldset, saves results.

## Quick Start

```bash
# Basic run with defaults
./run_evaluators.py

# Custom paths
./run_evaluators.py \
  --goldset evals/deepeval/goldset.json \
  --graders evals/deepeval/graders \
  --results evals/results

# With grader mapping
./run_evaluators.py --mapping evals/grader_mapping.json

# Custom pass threshold
./run_evaluators.py --pass-threshold 0.9
```

## Project Structure Expected

```
project/
├── evals/
│   ├── goldset.json              # Test examples
│   ├── graders/                  # Evaluator functions
│   │   ├── check_*.py
│   │   └── ...
│   ├── results/                  # Generated results (auto-created)
│   └── grader_mapping.json       # Optional: criterion → grader mapping
└── run_evaluators.py
```

## Goldset Format

Two supported formats:

### Format 1: Structured evaluations
```json
{
  "version": "1.0",
  "evaluations": [
    {
      "id": "eval-001",
      "name": "PII Detection",
      "examples": [
        {
          "input": "My email is user@example.com",
          "expected_pass": false,
          "type": "fail_case"
        }
      ]
    }
  ]
}
```

### Format 2: Flat examples
```json
{
  "version": "1.0",
  "examples": [
    {
      "input": "Test input",
      "expected_pass": true
    }
  ]
}
```

## Grader Functions

Supports multiple signatures:

```python
# Signature 1: PromptFoo style
def grade(output: str, context: dict) -> dict:
    return {"pass": True, "score": 1.0, "reason": "..."}

# Signature 2: Simple
def evaluate(input: str) -> bool:
    return True

# Signature 3: Comparison
def evaluate(input: str, expected: str) -> dict:
    return {"pass": input == expected}
```

## Results Format

```json
{
  "execution_date": "2026-04-20T...",
  "goldset_version": "1.0",
  "summary": {
    "total_evaluated": 50,
    "total_passed": 45,
    "total_failed": 3,
    "total_errors": 2,
    "overall_accuracy": 0.9
  },
  "criteria_results": {
    "eval-001": {
      "passed": 8,
      "failed": 2,
      "accuracy": 0.8,
      "example_results": [...]
    }
  }
}
```

## Exit Codes

- `0`: Success (accuracy >= threshold)
- `1`: Failure (accuracy < threshold)

## Integration with Analyze

After running evaluators:

```bash
# Run evaluators
./run_evaluators.py

# Analyze results
specify analyze evals/results/
```

## Grader Mapping

Optional `grader_mapping.json` maps criterion IDs to grader module names:

```json
{
  "eval-001": "check_pii_leakage",
  "eval-002": "check_security"
}
```

Without mapping, uses criterion ID as grader name.
