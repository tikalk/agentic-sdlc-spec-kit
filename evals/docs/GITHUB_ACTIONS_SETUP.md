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

### 2. LLM_AUTH_TOKEN

Your authentication token for the API.

## Setting Up Secrets

1. Go to your repository on GitHub
2. Click on **Settings** (top menu)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Enter the secret name (e.g., `LLM_BASE_URL`)
6. Paste the secret value
7. Click **Add secret**

Repeat for both `LLM_BASE_URL` and `LLM_AUTH_TOKEN`.

## Running the Workflow

The workflow is configured for **manual execution only**.

1. Go to **Actions** tab in your repository
2. Select **AI Evals** workflow from the left sidebar
3. Click **Run workflow** button (top right)
4. Select the branch to run against (usually `main`)
5. (Optional) Enter the model name in the **Model** input field.
6. Click the green **Run workflow** button

## Viewing Results

After the workflow completes:

1. Click on the completed workflow run
2. Click on the **eval** job to see detailed logs
3. Scroll to **Artifacts** section at the bottom
4. Download `eval-results` to get detailed JSON reports
5. View the summary in the workflow logs
