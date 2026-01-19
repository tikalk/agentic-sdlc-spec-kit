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

# Parse command line arguments
MODEL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: ./evals/scripts/run-auto-plan-analysis.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --model MODEL    Specify model to use (default: claude-sonnet-4-5-20250929)"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./evals/scripts/run-auto-plan-analysis.sh"
            echo "  ./evals/scripts/run-auto-plan-analysis.sh --model claude-opus-4-5-20251101"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "🤖 Automated Plan Error Analysis"
echo "========================================" >&2
echo ""

# Check for API key
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ Error: ANTHROPIC_API_KEY not set"
    echo "   Set it with: export ANTHROPIC_API_KEY=your-key"
    exit 1
fi

# Set model if provided via --model flag
if [ -n "$MODEL" ]; then
    export CLAUDE_MODEL="$MODEL"
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