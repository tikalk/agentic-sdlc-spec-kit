#!/bin/bash

# Run Error Analysis Workflow
# Sets up Jupyter environment and launches error-analysis notebook
# Location: evals/scripts/run-error-analysis.sh
#
# This script:
# 1. Creates/activates virtual environment
# 2. Installs required packages (jupyter, pandas, matplotlib, etc.)
# 3. Launches Jupyter Lab with error-analysis notebook

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTEBOOKS_DIR="$(cd "$SCRIPT_DIR/../notebooks" && pwd)"

echo "🔍 Starting Error Analysis Workflow..."
echo "📁 Notebooks directory: $NOTEBOOKS_DIR"
echo ""

# Create venv if it doesn't exist
if [ ! -d "$NOTEBOOKS_DIR/.venv" ]; then
    echo "📦 Creating virtual environment..."
    cd "$NOTEBOOKS_DIR"
    uv venv

    # Install packages
    echo "📥 Installing packages..."
    uv pip install jupyter pandas matplotlib seaborn ipywidgets
else
    echo "✅ Virtual environment exists"

    # Check if packages need updating
    echo "📥 Ensuring packages are installed..."
    cd "$NOTEBOOKS_DIR"
    uv pip install --quiet jupyter pandas matplotlib seaborn ipywidgets
fi

echo ""
echo "✅ Environment ready!"
echo "🚀 Launching Jupyter Lab..."
echo ""
echo "💡 In Jupyter Lab:"
echo "   - Open: error-analysis.ipynb"
echo "   - Review specs in datasets/real-specs/"
echo "   - Annotate with pass/fail and notes"
echo "   - Categorize failures and prioritize"
echo ""

# Activate and launch
cd "$NOTEBOOKS_DIR"
source .venv/bin/activate
jupyter lab error-analysis.ipynb
