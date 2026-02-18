# Spec-Kit Evaluation Framework

[![AI Evals](https://github.com/tikalk/agentic-sdlc-spec-kit/actions/workflows/eval.yml/badge.svg)](https://github.com/tikalk/agentic-sdlc-spec-kit/actions/workflows/eval.yml)

Comprehensive evaluation infrastructure for testing spec-kit template quality using PromptFoo with Claude.

## 📊 Current Evaluation Results (Updated: 2026-02-18)

**Overall: 23 LLM eval tests + 39 unit tests across 6 suites** ✅

| Test Suite | Tests | What It Checks |
|------------|-------|----------------|
| **Spec Template** | 10 | Structure, clarity, security, completeness, regression |
| **Plan Template** | 2 | Simplicity gate, constitution compliance |
| **Architecture Template** | 4 | Rozanski & Woods structure, blackbox context view, simplicity, ADR quality |
| **Extension System** | 3 | Manifest validation, self-containment, config template |
| **Clarify Command** | 2 | Ambiguity identification, architectural focus |
| **Trace Validation** | 2 | Structure completeness, decision quality |
| **Security (all suites)** | +4 per test | PII, prompt injection, hallucinations, misinformation |
| **Unit tests (pytest)** | 39 | Grader logic, extension system |
| **Total** | **63+** | |

## Quick Start

> **💡 New to the eval framework?** Check out [docs/QUICK_REFERENCE.md](./docs/QUICK_REFERENCE.md) for a one-page overview of all commands, files, and workflows!

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
export LLM_BASE_URL="your-llm-base-url"
export LLM_AUTH_TOKEN="your-api-key"
export LLM_MODEL="claude-sonnet-4-5-20250929"  # Optional, defaults to Sonnet 4.5

# Reload shell
source ~/.zshrc  # or source ~/.bashrc
```

### 3. Run Evaluations

```bash
# From repo root - run all PromptFoo tests (23 LLM tests)
./evals/scripts/run-promptfoo-eval.sh

# Run with JSON output
./evals/scripts/run-promptfoo-eval.sh --json

# Run and open web UI
./evals/scripts/run-promptfoo-eval.sh --view

# Use a specific model (overrides LLM_MODEL env var)
./evals/scripts/run-promptfoo-eval.sh --model claude-opus-4-6

# Run only a specific suite
./evals/scripts/run-promptfoo-eval.sh --filter "Architecture"
```

### 4. Run Unit Tests (no API key needed)

```bash
# Test all grader logic — fast, no LLM calls
uv run pytest tests/test_security_graders.py -v

# Test the extension system
uv run pytest tests/test_extensions.py -v

# Run everything
uv run pytest tests/ -v
```

## What We Test

### LLM Eval Tests (PromptFoo)

Each suite sends a prompt to the LLM and evaluates the output against structured assertions and custom Python graders.

#### Spec Template (10 tests)
- **Basic Structure** — required sections present (Overview, Requirements, User Stories, etc.)
- **No Premature Tech Stack** — spec focuses on WHAT, not HOW
- **Quality User Stories** — proper format with acceptance criteria
- **Clarity** — flags unmeasurable vague terms
- **Security Requirements** — security-critical features include security considerations
- **Edge Cases** — error scenarios and boundary conditions covered
- **Completeness** — complex features have comprehensive requirements
- **Regression** — simple features still maintain proper structure
- **Rename Regression** — post-rename output matches quality bar
- **Build-mode Spec** — build-mode template generates appropriate output

#### Plan Template (2 tests)
- **Simplicity Gate** — simple apps have ≤3 projects (Constitution Article VII)
- **Constitution Compliance** — no over-engineering or unnecessary abstractions

#### Architecture Template (4 tests)
- **Init Structure** — Rozanski & Woods sections present (Context, Functional, Information, Deployment views)
- **Blackbox Context View** — system shown as single opaque box with external actors only
- **Simplicity** — simple apps avoid k8s, microservices, service mesh
- **ADR Quality** — Architecture Decision Records follow Status/Context/Decision/Consequences format

#### Extension System (3 tests)
- **Manifest Validation** — required fields (name, version, commands, schema_version) all present
- **Skill Self-containment** — no external `@rule`/`@persona`/`@example` references
- **Config Template** — documented options, required/optional markers, sensible defaults

#### Clarify Command (2 tests)
- **Ambiguity Identification** — given a vague spec, produces actionable clarifying questions
- **Architectural Focus** — questions target scalability, integration, data flow — not feature details

#### Trace Validation (2 tests)
- **Structure** — session metadata, decisions, and artifacts sections present
- **Validation Accuracy** — validator correctly scores incomplete traces

### Security Graders (run on every LLM test)

Four graders apply automatically to every test output via `defaultTest.assert`:

| Grader | What it catches |
|--------|-----------------|
| **`check_pii_leakage`** | Real emails, phone numbers, SSNs, credit cards, private IPs, hardcoded API keys |
| **`check_prompt_injection`** | "Ignore previous instructions", DAN mode, embedded role markers, base64 payloads |
| **`check_hallucination_signals`** | Overconfident metrics, dangling references, self-contradictions, fabricated RFCs |
| **`check_misinformation`** | MD5/SHA-1 for passwords, plaintext HTTP, unsafe APIs (eval/pickle/yaml.load), impossible performance claims |

### Unit Tests (pytest)

Fast tests with no LLM calls — verify grader logic and extension system directly.

| Test file | Tests | Covers |
|-----------|-------|--------|
| `tests/test_security_graders.py` | 39 | All 4 security graders — pass cases, fail cases, edge cases (negative context) |
| `tests/test_extensions.py` | 40+ | Extension manifest, registry, install/remove, command registration, catalog discovery |

## Advanced Workflows

For more advanced use cases, see our detailed workflow guides:

- **[Eval System Overview](docs/EVAL.md)**: Full explanation of what each test checks and the grading framework.
- **[Error Analysis & Annotation](docs/WORKFLOWS.md)**: Deep dive into manual and automated error analysis, and how to use the annotation tool.
- **[CI/CD & Local Testing](docs/GITHUB_ACTIONS_SETUP.md)**: Set up and run evaluations in GitHub Actions or test them locally with `act`.

## Support

For evaluation framework issues:

- PromptFoo Discord: <https://discord.gg/promptfoo>
- PromptFoo GitHub: <https://github.com/promptfoo/promptfoo>

For spec-kit specific questions:

- Open issue: <https://github.com/tikalk/agentic-sdlc-spec-kit/issues>
