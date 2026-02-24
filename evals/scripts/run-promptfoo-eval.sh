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

# Detect available config files for new suites
ARCH_CONFIG="evals/configs/promptfooconfig-arch.js"
EXT_CONFIG="evals/configs/promptfooconfig-ext.js"
CLARIFY_CONFIG="evals/configs/promptfooconfig-clarify.js"
TRACE_CONFIG="evals/configs/promptfooconfig-trace.js"

HAS_ARCH=false; [ -f "$ARCH_CONFIG" ] && HAS_ARCH=true
HAS_EXT=false; [ -f "$EXT_CONFIG" ] && HAS_EXT=true
HAS_CLARIFY=false; [ -f "$CLARIFY_CONFIG" ] && HAS_CLARIFY=true
HAS_TRACE=false; [ -f "$TRACE_CONFIG" ] && HAS_TRACE=true

SUITE_COUNT=2
$HAS_ARCH && SUITE_COUNT=$((SUITE_COUNT + 1))
$HAS_EXT && SUITE_COUNT=$((SUITE_COUNT + 1))
$HAS_CLARIFY && SUITE_COUNT=$((SUITE_COUNT + 1))
$HAS_TRACE && SUITE_COUNT=$((SUITE_COUNT + 1))

echo -e "${GREEN}✓${NC} Found ${SUITE_COUNT} eval suites"

# Export OpenAI-compatible env vars for PromptFoo
export OPENAI_API_KEY="${LLM_AUTH_TOKEN}"
export OPENAI_BASE_URL="${LLM_BASE_URL}"

echo ""

# Parse command line arguments
FILTER=""
OUTPUT_JSON=false
VIEW_RESULTS=false
MODEL=""
NO_CACHE=false

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
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --help)
            echo "Usage: ./evals/scripts/run-eval.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --filter TEXT    Run only tests matching TEXT (uses --filter-pattern)"
            echo "  --json           Output results as JSON"
            echo "  --view           Open web UI after running"
            echo "  --model MODEL    Specify model to use (default: claude-sonnet-4-5-20250929)"
            echo "  --no-cache       Disable PromptFoo cache (always call the LLM)"
            echo "  --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./evals/scripts/run-eval.sh                    # Run all tests (with cache)"
            echo "  ./evals/scripts/run-eval.sh --no-cache         # Run all tests, bypass cache"
            echo "  ./evals/scripts/run-eval.sh --filter 'Spec'   # Run only spec template tests"
            echo "  ./evals/scripts/run-eval.sh --json --view     # Run tests, save JSON, open UI"
            echo "  ./evals/scripts/run-eval.sh --model claude-opus-4-6  # Use Opus 4.6"
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
    FILTER_ARG="--filter-pattern $FILTER"
fi

# Build cache argument
CACHE_ARG=""
if [ "$NO_CACHE" = true ]; then
    CACHE_ARG="--no-cache"
    echo -e "${YELLOW}⚠️  Cache disabled — all tests will call the LLM${NC}"
fi

echo ""
echo "🚀 Running evaluations with npx..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run spec tests (don't exit on failure, capture exit code)
echo "📋 Running Spec Template tests... [$(date '+%H:%M:%S')]"
if [ "$OUTPUT_JSON" = true ]; then
    npx promptfoo eval -c evals/configs/promptfooconfig-spec.js -o eval-results-spec.json $FILTER_ARG $CACHE_ARG || SPEC_EXIT=$?
else
    npx promptfoo eval -c evals/configs/promptfooconfig-spec.js $FILTER_ARG $CACHE_ARG || SPEC_EXIT=$?
fi
SPEC_EXIT=${SPEC_EXIT:-0}
echo "   Spec done (exit=$SPEC_EXIT) [$(date '+%H:%M:%S')]"

echo ""
echo "📋 Running Plan Template tests... [$(date '+%H:%M:%S')]"
if [ "$OUTPUT_JSON" = true ]; then
    npx promptfoo eval -c evals/configs/promptfooconfig-plan.js -o eval-results-plan.json $FILTER_ARG $CACHE_ARG || PLAN_EXIT=$?
else
    npx promptfoo eval -c evals/configs/promptfooconfig-plan.js $FILTER_ARG $CACHE_ARG || PLAN_EXIT=$?
fi
PLAN_EXIT=${PLAN_EXIT:-0}
echo "   Plan done (exit=$PLAN_EXIT) [$(date '+%H:%M:%S')]"

# Run Architecture Template tests (if config exists)
ARCH_EXIT=0
if [ "$HAS_ARCH" = true ]; then
    echo ""
    echo "📋 Running Architecture Template tests... [$(date '+%H:%M:%S')]"
    if [ "$OUTPUT_JSON" = true ]; then
        npx promptfoo eval -c "$ARCH_CONFIG" -o eval-results-arch.json $FILTER_ARG $CACHE_ARG || ARCH_EXIT=$?
    else
        npx promptfoo eval -c "$ARCH_CONFIG" $FILTER_ARG $CACHE_ARG || ARCH_EXIT=$?
    fi
    echo "   Arch done (exit=$ARCH_EXIT) [$(date '+%H:%M:%S')]"
fi

# Run Extension System tests (if config exists)
EXT_EXIT=0
if [ "$HAS_EXT" = true ]; then
    echo ""
    echo "📋 Running Extension System tests... [$(date '+%H:%M:%S')]"
    if [ "$OUTPUT_JSON" = true ]; then
        npx promptfoo eval -c "$EXT_CONFIG" -o eval-results-ext.json $FILTER_ARG $CACHE_ARG || EXT_EXIT=$?
    else
        npx promptfoo eval -c "$EXT_CONFIG" $FILTER_ARG $CACHE_ARG || EXT_EXIT=$?
    fi
    echo "   Ext done (exit=$EXT_EXIT) [$(date '+%H:%M:%S')]"
fi

# Run Clarify Command tests (if config exists)
CLARIFY_EXIT=0
if [ "$HAS_CLARIFY" = true ]; then
    echo ""
    echo "📋 Running Clarify Command tests... [$(date '+%H:%M:%S')]"
    if [ "$OUTPUT_JSON" = true ]; then
        npx promptfoo eval -c "$CLARIFY_CONFIG" -o eval-results-clarify.json $FILTER_ARG $CACHE_ARG || CLARIFY_EXIT=$?
    else
        npx promptfoo eval -c "$CLARIFY_CONFIG" $FILTER_ARG $CACHE_ARG || CLARIFY_EXIT=$?
    fi
    echo "   Clarify done (exit=$CLARIFY_EXIT) [$(date '+%H:%M:%S')]"
fi

# Run Trace Template tests (if config exists)
TRACE_EXIT=0
if [ "$HAS_TRACE" = true ]; then
    echo ""
    echo "📋 Running Trace Template tests... [$(date '+%H:%M:%S')]"
    if [ "$OUTPUT_JSON" = true ]; then
        npx promptfoo eval -c "$TRACE_CONFIG" -o eval-results-trace.json $FILTER_ARG $CACHE_ARG || TRACE_EXIT=$?
    else
        npx promptfoo eval -c "$TRACE_CONFIG" $FILTER_ARG $CACHE_ARG || TRACE_EXIT=$?
    fi
    echo "   Trace done (exit=$TRACE_EXIT) [$(date '+%H:%M:%S')]"
fi

EXIT_CODE=0
if [ $SPEC_EXIT -ne 0 ] || [ $PLAN_EXIT -ne 0 ] || [ $ARCH_EXIT -ne 0 ] || [ $EXT_EXIT -ne 0 ] || [ $CLARIFY_EXIT -ne 0 ] || [ $TRACE_EXIT -ne 0 ]; then
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
if [ "$OUTPUT_JSON" = true ] && [ -f "eval-results-spec.json" ] && [ -f "eval-results-plan.json" ]; then
    echo ""
    echo "📊 Combining results..."
    python3 << 'PYTHON_EOF'
import json
import os

# Collect all result files
result_files = [
    'eval-results-spec.json',
    'eval-results-plan.json',
    'eval-results-arch.json',
    'eval-results-ext.json',
    'eval-results-clarify.json',
    'eval-results-trace.json',
]

# Load available result files
datasets = []
for f in result_files:
    if os.path.exists(f):
        with open(f, 'r') as fh:
            datasets.append(json.load(fh))

if not datasets:
    print("No result files found")
    exit(1)

base = datasets[0]

# Combine all results
combined = {
    'evalId': 'combined',
    'results': {
        'version': base['results']['version'],
        'timestamp': base['results']['timestamp'],
        'prompts': [],
        'results': [],
        'stats': {
            'successes': 0,
            'failures': 0,
            'tokenUsage': {
                'total': 0,
                'prompt': 0,
                'completion': 0,
                'cached': 0,
            }
        }
    },
    'config': base['config'],
    'shareableUrl': None,
}

for data in datasets:
    combined['results']['prompts'].extend(data['results']['prompts'])
    combined['results']['results'].extend(data['results']['results'])
    combined['results']['stats']['successes'] += data['results']['stats']['successes']
    combined['results']['stats']['failures'] += data['results']['stats']['failures']
    combined['results']['stats']['tokenUsage']['total'] += data['results']['stats']['tokenUsage']['total']
    combined['results']['stats']['tokenUsage']['prompt'] += data['results']['stats']['tokenUsage']['prompt']
    combined['results']['stats']['tokenUsage']['completion'] += data['results']['stats']['tokenUsage']['completion']
    combined['results']['stats']['tokenUsage']['cached'] += data['results']['stats']['tokenUsage']['cached']

with open('eval-results.json', 'w') as f:
    json.dump(combined, f, indent=2)

# Print summary
total = combined['results']['stats']['successes'] + combined['results']['stats']['failures']
pass_rate = (combined['results']['stats']['successes'] / total * 100) if total > 0 else 0
print(f"✓ Combined results from {len(datasets)} suites: {combined['results']['stats']['successes']}/{total} passed ({pass_rate:.0f}%)")
PYTHON_EOF
fi

# Open web UI if requested
if [ "$VIEW_RESULTS" = true ]; then
    echo ""
    echo "🌐 Opening web UI..."
    npx promptfoo view
fi

echo ""
exit $EXIT_CODE
