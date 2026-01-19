# Testing GitHub Actions Locally

Guide for testing the AI Evals workflow locally before pushing to GitHub.

## Quick Start (Easiest Method)

We provide a helper script that handles everything for you:

```bash
# 1. Install act (if not already installed)
brew install act  # macOS
# or: curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# 2. Run the helper script
./evals/scripts/test-workflow-locally.sh

# The script will:
# - Check prerequisites (act, Docker)
# - Create secrets template if needed
# - Run the workflow locally
# - Display results

# Options:
./evals/scripts/test-workflow-locally.sh --list           # Dry run (list steps)
./evals/scripts/test-workflow-locally.sh --verbose        # Show details
./evals/scripts/test-workflow-locally.sh --reuse          # Faster iterations
./evals/scripts/test-workflow-locally.sh --skip-pr-comment # Skip PR comment step
./evals/scripts/test-workflow-locally.sh --help           # Show all options
```

That's it! The script handles secrets setup, Docker checks, and runs the workflow.

---

## Manual Setup (Advanced)

If you prefer manual control or need to customize the setup:

## Prerequisites

1. **Docker** - Required for `act` to run workflows in containers
   ```bash
   # Verify Docker is installed and running
   docker --version
   docker ps
   ```

2. **act** - Tool for running GitHub Actions locally
   ```bash
   # macOS
   brew install act

   # Linux
   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

   # Verify installation
   act --version
   ```

## Setup

### 1. Create Secrets File

Create `.github/workflows/.secrets` (gitignored):

```bash
# Create the secrets file
cat > .github/workflows/.secrets << 'EOF'
LLM_BASE_URL=your-llm-base-url
LLM_AUTH_TOKEN=your-api-key
EOF

# Secure the file
chmod 600 .github/workflows/.secrets
```

**Important:** Never commit this file! It's already in `.gitignore`.

### 2. Add to .gitignore

Ensure `.github/workflows/.secrets` is in your `.gitignore`:

```bash
# Add to .gitignore if not already there
echo ".github/workflows/.secrets" >> .gitignore
```

## Running Tests

### Basic Commands

```bash
# List all jobs and steps (dry run)
act pull_request --list

# Run the full workflow
act pull_request --secret-file .github/workflows/.secrets

# Run with verbose output
act pull_request --secret-file .github/workflows/.secrets -v

# Run specific job
act pull_request -j eval --secret-file .github/workflows/.secrets
```

### Simulating Different Events

```bash
# Simulate pull_request event (default)
act pull_request --secret-file .github/workflows/.secrets

# Simulate push to main
act push --secret-file .github/workflows/.secrets

# Simulate schedule (cron)
act schedule --secret-file .github/workflows/.secrets

# Simulate manual workflow_dispatch
act workflow_dispatch --secret-file .github/workflows/.secrets
```

### Advanced Options

```bash
# Use smaller runner image (faster)
act pull_request \
  --secret-file .github/workflows/.secrets \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Run with specific event payload
act pull_request \
  --secret-file .github/workflows/.secrets \
  --eventpath .github/workflows/test-event.json

# Skip steps that can't run locally (e.g., PR comments)
act pull_request \
  --secret-file .github/workflows/.secrets \
  --job eval \
  --skip-steps "Comment PR with Results"

# Reuse containers (faster for repeated runs)
act pull_request \
  --secret-file .github/workflows/.secrets \
  --reuse
```

### Using Environment Variables Instead

```bash
# Export secrets as environment variables
export LLM_BASE_URL="your-url"
export LLM_AUTH_TOKEN="your-token"

# Run with -s flag for each secret
act pull_request \
  -s LLM_BASE_URL \
  -s LLM_AUTH_TOKEN
```

## Testing Specific Scenarios

### Test Only Evaluation Steps

```bash
# Skip setup, just run evals
act pull_request \
  --secret-file .github/workflows/.secrets \
  --matrix ubuntu-latest:catthehacker/ubuntu:act-latest \
  --job eval
```

### Test Threshold Failures

Temporarily modify `check_eval_scores.py` to fail:

```bash
# Edit the threshold to impossible value
# In .github/workflows/eval.yml, change:
#   --min-pass-rate 0.70
# To:
#   --min-pass-rate 0.99

# Then test
act pull_request --secret-file .github/workflows/.secrets
```

### Test PR Comment Logic

The PR comment step won't work locally (requires GitHub API), but you can verify the summary generation:

```bash
# Run up to summary generation
act pull_request \
  --secret-file .github/workflows/.secrets \
  --skip-steps "Comment PR with Results"
```

## Limitations of Local Testing

### What Works ✅

- Job execution
- Step execution
- Environment variables and secrets
- Docker container actions
- Artifacts (stored in local directory)
- Most shell commands
- Python/Node.js setup

### What Doesn't Work ❌

- **GitHub API interactions**: PR comments, issue updates
- **GitHub context**: Some `github.*` variables may be missing
- **Exact GitHub runner environment**: Uses Docker images that approximate GitHub runners
- **Caching between runs**: Less effective than GitHub's cache
- **Concurrent job execution**: Runs sequentially locally

### Workarounds

1. **PR Comments**: Test summary generation, skip actual commenting
   ```bash
   act pull_request --secret-file .github/workflows/.secrets --skip-steps "Comment PR"
   ```

2. **GitHub Context**: Create mock event file
   ```json
   {
     "pull_request": {
       "number": 123,
       "head": {
         "ref": "test-branch"
       }
     }
   }
   ```

3. **Artifacts**: Check local `.artifacts/` directory

## Debugging

### View Detailed Logs

```bash
# Maximum verbosity
act pull_request --secret-file .github/workflows/.secrets -v -v

# Show Docker commands
act pull_request --secret-file .github/workflows/.secrets --verbose
```

### Interactive Debugging

```bash
# Start interactive shell in workflow container
act pull_request --secret-file .github/workflows/.secrets --shell

# Then manually run commands to debug
cd /github/workspace
./evals/scripts/run-promptfoo-eval.sh --json
```

### Check Container Logs

```bash
# Keep containers after run
act pull_request --secret-file .github/workflows/.secrets --reuse

# List containers
docker ps -a | grep act-

# View container logs
docker logs <container-id>

# Exec into container
docker exec -it <container-id> /bin/bash
```

## Best Practices

### 1. Use Smaller Test Suite Locally

Create a minimal config for local testing:

```bash
# Create evals/configs/promptfooconfig-test.js
# With just 1-2 tests for quick iteration

# Modify workflow to use test config locally
# Or pass --filter flag to run-promptfoo-eval.sh
```

### 2. Cache Dependencies

```bash
# Use --reuse flag for faster iterations
act pull_request --secret-file .github/workflows/.secrets --reuse

# This keeps containers running between tests
```

### 3. Test Incrementally

```bash
# Test just the setup steps first
act pull_request --secret-file .github/workflows/.secrets --list

# Then test evaluation steps
act pull_request --secret-file .github/workflows/.secrets -j eval

# Finally test full workflow
act pull_request --secret-file .github/workflows/.secrets
```

### 4. Use Smaller Runner Image

The default `ubuntu-latest` image is large (~18GB). Use a smaller one:

```bash
# Create .actrc in repo root
echo "-P ubuntu-latest=catthehacker/ubuntu:act-latest" > .actrc

# Now act will use smaller image by default
act pull_request --secret-file .github/workflows/.secrets
```

## Common Issues

### Issue: Docker Not Running

```
Error: Cannot connect to Docker daemon
```

**Solution:**
```bash
# Start Docker Desktop (macOS)
open -a Docker

# Or start Docker service (Linux)
sudo systemctl start docker

# Verify
docker ps
```

### Issue: Secrets Not Found

```
Error: LLM_BASE_URL not set
```

**Solution:**
```bash
# Verify secrets file exists and has correct format
cat .github/workflows/.secrets

# Use absolute path
act pull_request --secret-file $(pwd)/.github/workflows/.secrets
```

### Issue: Node.js/Python Not Found

```
Error: node: command not found
```

**Solution:**
```bash
# Use official runner images (larger but more compatible)
act pull_request \
  --secret-file .github/workflows/.secrets \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:runner-latest
```

### Issue: Workflow Takes Too Long

```
# Runs forever or very slow
```

**Solution:**
```bash
# Use smaller image
act pull_request --secret-file .github/workflows/.secrets \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Skip non-essential steps
act pull_request --secret-file .github/workflows/.secrets \
  --skip-steps "Upload Results Artifact"

# Run specific job only
act pull_request -j eval --secret-file .github/workflows/.secrets
```

## Quick Reference

```bash
# Complete local test workflow
# 1. Ensure Docker is running
docker ps

# 2. Verify secrets file
cat .github/workflows/.secrets

# 3. List jobs (dry run)
act pull_request --list

# 4. Run workflow
act pull_request --secret-file .github/workflows/.secrets

# 5. Check results
ls -la eval-results*.json

# 6. View summary
cat eval_summary.txt
```

## Integration with Development Workflow

### Pre-commit Hook (Optional)

Create `.git/hooks/pre-push`:

```bash
#!/bin/bash
echo "Running local GitHub Actions tests..."

act pull_request \
  --secret-file .github/workflows/.secrets \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest \
  --quiet

if [ $? -ne 0 ]; then
    echo "❌ Workflow tests failed. Fix issues before pushing."
    exit 1
fi

echo "✅ Workflow tests passed."
```

Make it executable:
```bash
chmod +x .git/hooks/pre-push
```

## Resources

- **act Documentation**: https://github.com/nektos/act
- **act Runner Images**: https://github.com/catthehacker/docker_images
- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Docker Installation**: https://docs.docker.com/get-docker/

## Next Steps

After testing locally:

1. ✅ Fix any issues found during local testing
2. ✅ Push changes to GitHub
3. ✅ Verify workflow runs successfully on GitHub
4. ✅ Set up GitHub secrets (if not already done)
5. ✅ Test with real PR

See [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) for production deployment.
