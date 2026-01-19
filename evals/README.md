# Spec-Kit Evaluation Framework

[![AI Evals](https://github.com/tikalk/agentic-sdlc-spec-kit/actions/workflows/eval.yml/badge.svg)](https://github.com/tikalk/agentic-sdlc-spec-kit/actions/workflows/eval.yml)

Comprehensive evaluation infrastructure for testing spec-kit template quality using PromptFoo with Claude.

## 📊 Current Evaluation Results (Updated: 2026-01-14)

**Overall Pass Rate: 100% (10/10 tests passing)** ✅

| Test Suite | Pass Rate | Status |
|------------|-----------|--------|
| **Spec Template** | 8/8 (100%) | ✅ |
| **Plan Template** | 2/2 (100%) | ✅ |
| **Total** | **10/10 (100%)** | ✅ |

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
# From repo root - run all PromptFoo tests
./evals/scripts/run-promptfoo-eval.sh

# Run with JSON output
./evals/scripts/run-promptfoo-eval.sh --json

# Run and open web UI
./evals/scripts/run-promptfoo-eval.sh --view

# Use a specific model (overrides LLM_MODEL env var)
./evals/scripts/run-promptfoo-eval.sh --model claude-opus-4-5-20251101
```

## Test Suite

The evaluation includes **10 automated tests** covering:

- **Spec Template (8 tests)**: Structure, clarity, security, completeness
- **Plan Template (2 tests)**: Simplicity, constitution compliance

For more details on the test suite and individual tests, see the `tests` array in the `promptfooconfig.js` files.

## Advanced Workflows

For more advanced use cases, see our detailed workflow guides:

- **[Error Analysis & Annotation](docs/WORKFLOWS.md)**: Deep dive into manual and automated error analysis, and how to use the annotation tool.
- **[CI/CD & Local Testing](docs/GITHUB_ACTIONS_SETUP.md)**: Set up and run evaluations in GitHub Actions or test them locally with `act`.

## Support

For evaluation framework issues:

- PromptFoo Discord: <https://discord.gg/promptfoo>
- PromptFoo GitHub: <https://github.com/promptfoo/promptfoo>

For spec-kit specific questions:

- Open issue: <https://github.com/tikalk/agentic-sdlc-spec-kit/issues>
