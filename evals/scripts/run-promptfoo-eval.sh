#!/bin/bash
#
# Quick script to run PromptFoo evaluations with proper setup
#

set -e -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Spec-Kit Evaluation Runner (npx)"
echo "=============================="

# Check if Node.js is installed (required for npx)
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not installed${NC}"
    echo ""
    echo "Install Node.js from: https://nodejs.org/"
    echo "Or with Homebrew: brew install node"
    exit 1
fi

echo -e "${GREEN}✓${NC} Node.js installed ($(node --version))"

# Check if npx is available (comes with Node.js)
if ! command -v npx &> /dev/null; then
    echo -e "${RED}❌ npx not available${NC}"
    echo ""
    echo "npx should come with Node.js. Try reinstalling Node.js."
    exit 1
fi

echo -e "${GREEN}✓${NC} npx available"

# Check environment variables
if [ -z "$LLM_BASE_URL" ]; then
    echo -e "${RED}❌ LLM_BASE_URL not set${NC}"
    echo ""
    echo "Set with: export LLM_BASE_URL='your-llm-base-url'"
    exit 1
fi

echo -e "${GREEN}✓${NC} LLM_BASE_URL set"

if [ -z "$LLM_AUTH_TOKEN" ]; then
    echo -e "${RED}❌ LLM_AUTH_TOKEN not set${NC}"
    echo ""
    echo "Set with: export LLM_AUTH_TOKEN='your-token'"
    exit 1
fi

echo -e "${GREEN}✓${NC} LLM_AUTH_TOKEN set"

# Note: Model will be set after parsing command line arguments

# Check if we're in the repo root (look for config files)
if [ ! -f "evals/configs/promptfooconfig-spec.js" ] || [ ! -f "evals/configs/promptfooconfig-plan.js" ]; then
    echo -e "${RED}❌ Config files not found${NC}"
    echo ""
    echo "Expected: evals/configs/promptfooconfig-spec.js and evals/configs/promptfooconfig-plan.js"
    echo "Make sure you're running this from the repository root"
    exit 1
fi

echo -e "${GREEN}✓${NC} Configuration files found"

# Export OpenAI-compatible env vars for PromptFoo
export OPENAI_API_KEY="${LLM_AUTH_TOKEN}"
export OPENAI_BASE_URL="${LLM_BASE_URL}"

echo ""

# Parse command line arguments
FILTER=""
OUTPUT_JSON=false
VIEW_RESULTS=false
MODEL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --filter)
            FILTER="$2"
            shift 2
            ;;
        --json)
            OUTPUT_JSON=true
            shift
            ;;
        --view)
            VIEW_RESULTS=true
            shift
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --help)
            echo "Usage: ./evals/scripts/run-eval.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --filter TEXT    Run only tests matching TEXT"
            echo "  --json           Output results as JSON"
            echo "  --view           Open web UI after running"
            echo "  --model MODEL    Specify model to use (default: claude-sonnet-4-5-20250929)"
            echo "  --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./evals/scripts/run-eval.sh                    # Run all tests"
            echo "  ./evals/scripts/run-eval.sh --filter 'Spec'   # Run only spec template tests"
            echo "  ./evals/scripts/run-eval.sh --json --view     # Run tests, save JSON, open UI"
            echo "  ./evals/scripts/run-eval.sh --model claude-opus-4-5-20251101  # Use Opus 4.5"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set Claude model (priority: --model flag > env var > default)
if [ -n "$MODEL" ]; then
    export LLM_MODEL="$MODEL"
    echo -e "${GREEN}✓${NC} LLM_MODEL set to ${LLM_MODEL} (from --model flag)"
elif [ -z "$LLM_MODEL" ]; then
    export LLM_MODEL="claude-sonnet-4-5-20250929"
    echo -e "${GREEN}✓${NC} LLM_MODEL defaulted to ${LLM_MODEL}"
else
    echo -e "${GREEN}✓${NC} LLM_MODEL set to ${LLM_MODEL} (from environment)"
fi

# Build filter argument if provided
FILTER_ARG=""
if [ -n "$FILTER" ]; then
    echo -e "${YELLOW}🔍 Running tests matching: ${FILTER}${NC}"
    FILTER_ARG="--filter-pattern \"$FILTER\""
fi

echo ""
echo "🚀 Running evaluations with npx..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run spec tests (don't exit on failure, capture exit code)
echo "📋 Running Spec Template tests..."
if [ "$OUTPUT_JSON" = true ]; then
    npx promptfoo eval -c evals/configs/promptfooconfig-spec.js -o eval-results-spec.json $FILTER_ARG || SPEC_EXIT=$?
else
    npx promptfoo eval -c evals/configs/promptfooconfig-spec.js $FILTER_ARG || SPEC_EXIT=$?
fi
SPEC_EXIT=${SPEC_EXIT:-0}

echo ""
echo "📋 Running Plan Template tests..."
if [ "$OUTPUT_JSON" = true ]; then
    npx promptfoo eval -c evals/configs/promptfooconfig-plan.js -o eval-results-plan.json $FILTER_ARG || PLAN_EXIT=$?
else
    npx promptfoo eval -c evals/configs/promptfooconfig-plan.js $FILTER_ARG || PLAN_EXIT=$?
fi
PLAN_EXIT=${PLAN_EXIT:-0}

EXIT_CODE=0
if [ $SPEC_EXIT -ne 0 ] || [ $PLAN_EXIT -ne 0 ]; then
    EXIT_CODE=1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ All evaluations completed successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Some evaluations had issues${NC}"
fi

# Combine JSON results if requested
if [ "$OUTPUT_JSON" = true ] && [ -f "evals/results-spec.json" ] && [ -f "evals/results-plan.json" ]; then
    echo ""
    echo "📊 Combining results..."
    PASS_RATE=$(python3 << 'PYTHON_EOF'
import json

# Load both result files
with open('evals/results-spec.json', 'r') as f:
    spec_data = json.load(f)
with open('evals/results-plan.json', 'r') as f:
    plan_data = json.load(f)

# Combine results
combined = {
    'evalId': 'combined',
    'results': {
        'version': spec_data['results']['version'],
        'timestamp': spec_data['results']['timestamp'],
        'prompts': spec_data['results']['prompts'] + plan_data['results']['prompts'],
        'results': spec_data['results']['results'] + plan_data['results']['results'],
        'stats': {
            'successes': spec_data['results']['stats']['successes'] + plan_data['results']['stats']['successes'],
            'failures': spec_data['results']['stats']['failures'] + plan_data['results']['stats']['failures'],
            'tokenUsage': {
                'total': spec_data['results']['stats']['tokenUsage']['total'] + plan_data['results']['stats']['tokenUsage']['total'],
                'prompt': spec_data['results']['stats']['tokenUsage']['prompt'] + plan_data['results']['stats']['tokenUsage']['prompt'],
                'completion': spec_data['results']['stats']['tokenUsage']['completion'] + plan_data['results']['stats']['tokenUsage']['completion'],
                'cached': spec_data['results']['stats']['tokenUsage']['cached'] + plan_data['results']['stats']['tokenUsage']['cached'],
            }
        }
    },
    'config': spec_data['config'],
    'shareableUrl': None,
}

with open('eval-results.json', 'w') as f:
    json.dump(combined, f, indent=2)

# Print summary
total = combined['results']['stats']['successes'] + combined['results']['stats']['failures']
pass_rate = (combined['results']['stats']['successes'] / total * 100) if total > 0 else 0
print(f"✓ Combined results: {combined['results']['stats']['successes']}/{total} passed ({pass_rate:.0f}%)")
print(pass_rate)
PYTHON_EOF
)
fi

# Open web UI if requested
if [ "$VIEW_RESULTS" = true ]; then
    echo ""
    echo "🌐 Opening web UI..."
    npx promptfoo view
fi

echo ""

if [ -n "$PASS_RATE" ] && [ "$(echo "$PASS_RATE > 80" | bc -l)" -eq 1 ]; then
    exit 0
else
    exit $EXIT_CODE
fi
