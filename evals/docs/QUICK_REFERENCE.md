# GitHub Actions Eval Workflow - Quick Reference

## 🚀 Quick Commands

### LLM Eval Tests (requires API key)

```bash
# Run all 23 LLM eval tests
./evals/scripts/run-promptfoo-eval.sh

# Run with JSON output
./evals/scripts/run-promptfoo-eval.sh --json

# Run specific suite
./evals/scripts/run-promptfoo-eval.sh --filter "Architecture"

# Open results in web UI
./evals/scripts/run-promptfoo-eval.sh --view

# Check scores against thresholds
python3 evals/scripts/check_eval_scores.py \
  --results eval-results.json \
  --min-pass-rate 0.70
```

### Unit Tests (no API key needed — fast)

```bash
# Security graders (39 tests, ~0.03s)
uv run pytest tests/test_security_graders.py -v

# Extension system (40+ tests)
uv run pytest tests/test_extensions.py -v

# All unit tests
uv run pytest tests/ -v
```

### Local CI Testing

```bash
# Install act (first time only)
brew install act  # macOS

# Test workflow locally (easiest)
./evals/scripts/test-workflow-locally.sh

# With options
./evals/scripts/test-workflow-locally.sh --list      # Dry run
./evals/scripts/test-workflow-locally.sh --verbose   # Detailed output
./evals/scripts/test-workflow-locally.sh --reuse     # Faster iterations
```

## 📁 Important Files

| File | Purpose |
|------|---------|
| `.github/workflows/eval.yml` | Main GitHub Actions workflow |
| `.github/workflows/.secrets` | Local testing secrets (gitignored) |
| `evals/configs/promptfooconfig.js` | Combined suite (all 23 LLM tests) |
| `evals/configs/promptfooconfig-spec.js` | Spec template tests (10) |
| `evals/configs/promptfooconfig-plan.js` | Plan template tests (2) |
| `evals/configs/promptfooconfig-arch.js` | Architecture template tests (4) |
| `evals/configs/promptfooconfig-ext.js` | Extension system tests (3) |
| `evals/configs/promptfooconfig-clarify.js` | Clarify command tests (2) |
| `evals/configs/promptfooconfig-trace.js` | Trace validation tests (2) |
| `evals/graders/custom_graders.py` | 14 Python graders (quality + 4 security) |
| `tests/test_security_graders.py` | Unit tests for security graders (39 tests) |
| `tests/test_extensions.py` | Unit tests for extension system (40+ tests) |
| `evals/scripts/check_eval_scores.py` | Threshold validation |
| `evals/scripts/run-promptfoo-eval.sh` | Evaluation runner |
| `evals/scripts/test-workflow-locally.sh` | Local testing helper |

## 🔧 Setup Checklist

### For GitHub Actions (Production)

- [ ] Add `LLM_BASE_URL` secret to GitHub
- [ ] Add `LLM_AUTH_TOKEN` secret to GitHub
- [ ] Run workflow manually from Actions tab
- [ ] (Optional) Set `LLM_MODEL` in the workflow dispatch UI.
- [ ] Verify results in workflow logs
- [ ] Download and review artifacts

**Guide:** See [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)

### For Local Testing

- [ ] Install `act`: `brew install act`
- [ ] Ensure Docker is running
- [ ] Run: `./evals/scripts/test-workflow-locally.sh`
- [ ] Edit `.github/workflows/.secrets` with your values
- [ ] Run again to test

**Guide:** See [LOCAL_TESTING.md](LOCAL_TESTING.md)

## 🎯 Workflow Triggers

| Trigger | When | Purpose |
|---------|------|---------|
| **workflow_dispatch** | Manual trigger only | On-demand quality validation |

**Note:** The workflow does NOT run automatically on PRs, pushes, or schedules.
Run manually from GitHub Actions tab when you need quality validation.

## 📊 Quality Thresholds

| Metric | Threshold | Action if Failed |
|--------|-----------|------------------|
| Average Score | ≥ 0.70 | ❌ Workflow fails |
| Pass Rate | ≥ 70% | ❌ Workflow fails |
| P0/P1 tests | All must pass | ❌ Block merge |
| Security graders | Zero violations | ❌ Hard fail (score 0.0) |

## 🐛 Troubleshooting

### Workflow Fails Locally

```bash
# Check Docker is running
docker ps

# Verify secrets
cat .github/workflows/.secrets

# Run with verbose output
./evals/scripts/test-workflow-locally.sh --verbose

# Check logs
act pull_request --secret-file .github/workflows/.secrets -v
```

### Workflow Fails on GitHub

- Check **Actions** tab for error logs
- Verify secrets are set in repository settings
- Test locally first with `act`
- Ensure API credentials are valid

## 🎓 Learning Resources

| Topic | Link |
|-------|------|
| **Full Setup Guide** | [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) |
| **Local Testing** | [LOCAL_TESTING.md](LOCAL_TESTING.md) |
| **Eval Framework** | [README.md](../README.md) |
| **act Documentation** | <https://github.com/nektos/act> |
| **GitHub Actions** | <https://docs.github.com/en/actions> |

## 📞 Getting Help

1. Check [LOCAL_TESTING.md](LOCAL_TESTING.md) troubleshooting section
2. Check [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) common issues
3. Review workflow logs in GitHub Actions tab
4. Open issue: <https://github.com/tikalk/agentic-sdlc-spec-kit/issues>

## ✅ Current Status

[![AI Evals](https://github.com/tikalk/agentic-sdlc-spec-kit/actions/workflows/eval.yml/badge.svg)](https://github.com/tikalk/agentic-sdlc-spec-kit/actions/workflows/eval.yml)

- **LLM eval tests:** 23 (across 6 suites)
- **Security graders:** 4 (run on every test automatically)
- **Unit tests:** 39 security grader tests + 40+ extension tests
- **Status:** ✅ All implemented, ready to run
- **Last Updated:** 2026-02-18
