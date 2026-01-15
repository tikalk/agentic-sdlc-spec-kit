# GitHub Actions Eval Workflow - Quick Reference

## 🚀 Quick Commands

### Local Testing

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

### Manual Testing

```bash
# Run all evaluations
./evals/scripts/run-promptfoo-eval.sh

# Run with JSON output
./evals/scripts/run-promptfoo-eval.sh --json

# Run specific tests
./evals/scripts/run-promptfoo-eval.sh --filter "Spec"

# Check scores
python3 evals/scripts/check_eval_scores.py \
  --results eval-results.json \
  --min-pass-rate 0.70
```

## 📁 Important Files

| File | Purpose |
|------|---------|
| `.github/workflows/eval.yml` | Main GitHub Actions workflow |
| `.github/workflows/.secrets` | Local testing secrets (gitignored) |
| `evals/configs/promptfooconfig.js` | All evaluation tests |
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
| Overall | 10/10 tests pass | ✅ Currently passing |

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

- **Pass Rate:** 100% (10/10 tests)
- **Status:** ✅ Production ready
- **Last Updated:** 2026-01-14
