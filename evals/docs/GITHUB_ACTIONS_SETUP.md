# GitHub Actions Setup for AI Evaluations

This guide explains how to set up GitHub Actions for manual evaluation runs.

## Overview

The GitHub Actions workflow (`.github/workflows/eval.yml`) provides:
- **Manual execution** via GitHub Actions interface
- Quality threshold checks (minimum 70% pass rate)
- Detailed evaluation reports with pass/fail status
- Result artifacts stored for 30 days
- On-demand quality validation

## Required Secrets

The workflow requires two secrets to be configured in your GitHub repository:

### 1. LLM_BASE_URL

Your LiteLLM proxy URL or other LLM provider API base URL.

**Example values:**
- AI API Gateway: `https://your-llm-provider.com/v1`
- Direct API: `https://api.anthropic.com/v1`

### 2. LLM_AUTH_TOKEN

Your authentication token for the API.

**Example values:**
- LLM API token: Your gateway authentication token
- Direct API key: Your API key (e.g., starts with `sk-ant-`)

## Setting Up Secrets

### Step 1: Navigate to Repository Settings

1. Go to your repository on GitHub
2. Click on **Settings** (top menu)
3. In the left sidebar, click **Secrets and variables** → **Actions**

### Step 2: Add New Repository Secret

For each secret:

1. Click **New repository secret**
2. Enter the secret name (e.g., `LLM_BASE_URL`)
3. Paste the secret value
4. Click **Add secret**

Repeat for both `LLM_BASE_URL` and `LLM_AUTH_TOKEN`.

### Step 3: Verify Secrets

After adding both secrets, you should see them listed on the Secrets page:
- `LLM_BASE_URL` (Updated X time ago)
- `LLM_AUTH_TOKEN` (Updated X time ago)

## Running the Workflow

The workflow is configured for **manual execution only**.

### How to Run

1. Go to **Actions** tab in your repository
2. Select **AI Evals** workflow from the left sidebar
3. Click **Run workflow** button (top right)
4. Select the branch to run against (usually `main`)
5. Click the green **Run workflow** button
6. Wait for the workflow to complete (typically 2-3 minutes)
7. Review the results in the workflow run page

### Viewing Results

After the workflow completes:

1. Click on the completed workflow run
2. Click on the **eval** job to see detailed logs
3. Scroll to **Artifacts** section at the bottom
4. Download `eval-results` to get detailed JSON reports
5. View the summary in the workflow logs

## Workflow Behavior

### Trigger Method

The workflow uses **`workflow_dispatch`** for manual execution only:
- No automatic triggers on pull requests
- No automatic triggers on pushes
- No scheduled runs
- Run on-demand when you need quality validation

### Quality Thresholds

The workflow enforces these thresholds:
- **Minimum average score**: 0.70 (70%)
- **Minimum pass rate**: 0.70 (70% of tests must pass)

If either threshold is not met, the workflow will fail and you'll see a red X on the workflow run.

## When to Run Evaluations

Since the workflow is manual-only, consider running it:

- ✅ Before merging significant template changes
- ✅ After updating constitution or directives
- ✅ Weekly as a quality check
- ✅ Before releases
- ✅ When investigating quality issues

## Cost Estimation

Running the full eval suite with Claude Sonnet 4.5:

| Frequency | Tokens | Cost |
|-----------|--------|------|
| Per run | ~60-70K | ~$0.60-$0.80 |
| Weekly runs (4/month) | ~240-280K | ~$2.40-$2.80/month |
| Bi-weekly (2/month) | ~120-140K | ~$1.20-$1.40/month |
| Monthly run | ~60-70K | ~$0.60-$0.80/month |

### Cost Reduction Tips

1. **Run only when needed**: Manual execution means you control costs
2. **Use cheaper model**: Switch to Haiku for quick checks
   - Edit workflow YAML: change `LLM_MODEL` to `claude-3-5-haiku-20241022`
3. **Leverage caching**: LiteLLM or other proxy caches reduce token usage
4. **Test locally first**: Use `act` to test before running in GitHub

## Troubleshooting

### Workflow Fails with "Secrets not set"

**Symptoms:**
```
❌ LLM_BASE_URL not set
```

**Solution:**
1. Verify secrets are added to repository (Settings → Secrets)
2. Check secret names match exactly (case-sensitive)
3. Re-add secrets if needed

### Workflow Fails with "Config files not found"

**Symptoms:**
```
❌ Config files not found
Expected: evals/configs/promptfooconfig-spec.js
```

**Solution:**
- Ensure the PR is based on latest main branch
- Config files should be at repository root
- Check file paths match exactly

### Workflow Times Out

**Symptoms:**
- Workflow runs for >10 minutes
- Eventually times out or gets killed

**Solution:**
1. Check LiteLLM or other provider is responding quickly
2. Reduce token limits in config files
3. Use faster model (Haiku) for CI

### Quality Thresholds Too Strict

**Symptoms:**
- Most runs fail due to threshold checks
- You want to adjust acceptable quality levels

**Solution:**
Edit `.github/workflows/eval.yml` and adjust:
```yaml
- name: Check Quality Thresholds
  run: |
    python3 evals/scripts/check_eval_scores.py \
      --results eval-results.json \
      --min-score 0.60 \     # Lower from 0.70
      --min-pass-rate 0.60 \ # Lower from 0.70
      --verbose
```

## Viewing Results

### In Workflow Logs

1. Go to **Actions** tab
2. Click on the workflow run
3. Click on the **eval** job
4. Expand steps to see detailed logs

### In Artifacts

Detailed results are saved as artifacts:
1. Go to **Actions** tab
2. Click on the workflow run
3. Scroll to **Artifacts** section
4. Download `eval-results` (available for 30 days)

Contains:
- `eval-results.json` - Full PromptFoo results
- `eval-results-spec.json` - Spec template results
- `eval-results-plan.json` - Plan template results
- `eval_summary.txt` - Formatted summary

## Monitoring

### View Workflow History

1. Go to **Actions** tab
2. Filter by **AI Evals** workflow
3. See all runs with status (✅ success, ❌ failure)

### Track Trends

Use the artifacts from multiple runs to track:
- Pass rate over time
- Token usage trends
- Common failure patterns

Consider building a dashboard using:
- GitHub API to fetch workflow runs
- Extract pass rates from artifacts
- Plot trends over time

## Next Steps

After setting up GitHub Actions:

1. ✅ **Run a test workflow** - Verify everything works correctly
2. ✅ **Adjust thresholds** - Based on actual pass rates
3. ✅ **Establish cadence** - Weekly, bi-weekly, or before releases
4. ✅ **Test locally first** - Use `act` to validate before GitHub runs
5. 📋 **Production monitoring** (Optional) - See AI-EVALS-WORKPLAN.md Week 5-6

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [PromptFoo Documentation](https://promptfoo.dev/docs/intro)
- [AI Evals Workplan](AI-EVALS-WORKPLAN.md)
- [Eval Framework README](../README.md)