#!/bin/bash

# Run Automated Plan Error Analysis
# Uses Claude API to automatically evaluate plans and categorize failures
# Location: evals/scripts/run-auto-plan-analysis.sh
#
# This script:
# 1. Checks for ANTHROPIC_API_KEY
# 2. Sets up Python environment
# 3. Runs automated plan error analysis
# 4. Generates results CSV and summary report

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🤖 Automated Plan Error Analysis"
echo "========================================" >&2
echo ""

# Check for API key
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ Error: ANTHROPIC_API_KEY not set"
    echo "   Set it with: export ANTHROPIC_API_KEY=your-key"
    exit 1
fi

# Create venv if needed
VENV_DIR="$PROJECT_ROOT/evals/.venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creating virtual environment..."
    cd "$PROJECT_ROOT/evals"
    uv venv
fi

# Install dependencies
echo "📥 Installing dependencies..."
cd "$PROJECT_ROOT/evals"
source "$VENV_DIR/bin/activate"
uv pip install --quiet anthropic pandas

echo ""
echo "🚀 Running automated plan error analysis..."
echo ""

# Run the script
python "$SCRIPT_DIR/run-automated-plan-analysis.py"

echo ""
echo "💡 Results saved to: evals/datasets/analysis-results/"
echo "   - CSV with detailed evaluations"
echo "   - Summary report with failure categories"