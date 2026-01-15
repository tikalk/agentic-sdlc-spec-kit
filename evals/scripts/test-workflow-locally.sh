#!/bin/bash
#
# Helper script to test GitHub Actions workflow locally using act
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 GitHub Actions Local Testing${NC}"
echo "================================"
echo ""

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo -e "${RED}❌ 'act' not installed${NC}"
    echo ""
    echo "Install with:"
    echo "  macOS:  brew install act"
    echo "  Linux:  curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
    echo ""
    echo "See: https://github.com/nektos/act"
    exit 1
fi

echo -e "${GREEN}✓${NC} act installed ($(act --version))"

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker not running${NC}"
    echo ""
    echo "Start Docker Desktop (macOS) or:"
    echo "  sudo systemctl start docker"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker running"

# Check for secrets file
SECRETS_FILE=".github/workflows/.secrets"
if [ ! -f "$SECRETS_FILE" ]; then
    echo -e "${YELLOW}⚠️  Secrets file not found${NC}"
    echo ""
    echo "Creating template: $SECRETS_FILE"
    mkdir -p .github/workflows
    cat > "$SECRETS_FILE" << 'EOF'
# GitHub Actions Secrets for Local Testing
# DO NOT COMMIT THIS FILE!

LLM_BASE_URL=your-llm-base-url
LLM_API_KEY=your-auth-token
EOF
    chmod 600 "$SECRETS_FILE"

    echo ""
    echo -e "${YELLOW}Please edit $SECRETS_FILE with your actual values${NC}"
    echo "Then run this script again."
    exit 1
fi

echo -e "${GREEN}✓${NC} Secrets file exists"

# Verify secrets have values
if grep -q "your-llm-base-url" "$SECRETS_FILE" || grep -q "your-api-key" "$SECRETS_FILE"; then
    echo -e "${YELLOW}⚠️  Warning: Secrets file contains placeholder values${NC}"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""

# Parse command line options
EVENT="pull_request"
VERBOSE=""
LIST_ONLY=false
REUSE=""
SKIP_STEPS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --event)
            EVENT="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE="-v"
            shift
            ;;
        --list)
            LIST_ONLY=true
            shift
            ;;
        --reuse)
            REUSE="--reuse"
            shift
            ;;
        --skip-pr-comment)
            SKIP_STEPS="Comment PR with Results"
            shift
            ;;
        --help|-h)
            echo "Usage: ./evals/scripts/test-workflow-locally.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --event TYPE        Event to simulate (default: pull_request)"
            echo "                      Options: pull_request, push, schedule, workflow_dispatch"
            echo "  --verbose, -v       Show verbose output"
            echo "  --list              List jobs and steps only (dry run)"
            echo "  --reuse             Reuse containers for faster iterations"
            echo "  --skip-pr-comment   Skip PR comment step (doesn't work locally)"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./evals/scripts/test-workflow-locally.sh                # Run with defaults"
            echo "  ./evals/scripts/test-workflow-locally.sh --list        # Dry run"
            echo "  ./evals/scripts/test-workflow-locally.sh --verbose     # Verbose output"
            echo "  ./evals/scripts/test-workflow-locally.sh --reuse       # Faster iterations"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build act command
ACT_CMD="act $EVENT --secret-file $SECRETS_FILE"

# Add optional flags
if [ -n "$VERBOSE" ]; then
    ACT_CMD="$ACT_CMD $VERBOSE"
fi

if [ -n "$REUSE" ]; then
    ACT_CMD="$ACT_CMD $REUSE"
fi

if [ -n "$SKIP_STEPS" ]; then
    ACT_CMD="$ACT_CMD --skip-steps \"$SKIP_STEPS\""
fi

# Use smaller runner image for faster execution
ACT_CMD="$ACT_CMD -P ubuntu-latest=catthehacker/ubuntu:act-latest"

# Execute
echo -e "${BLUE}Running:${NC} $ACT_CMD"
echo ""

if [ "$LIST_ONLY" = true ]; then
    echo -e "${YELLOW}📋 Listing jobs and steps (dry run)...${NC}"
    act $EVENT --secret-file "$SECRETS_FILE" --list
    exit 0
fi

echo -e "${YELLOW}🚀 Running workflow locally...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run with eval to properly handle the command with potential quotes
eval $ACT_CMD

EXIT_CODE=$?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Workflow completed successfully${NC}"

    # Show results if they exist
    if [ -f "eval-results.json" ]; then
        echo ""
        echo "📊 Results available in:"
        echo "  - eval-results.json"
        echo "  - eval-results-spec.json"
        echo "  - eval-results-plan.json"

        if [ -f "eval_summary.txt" ]; then
            echo "  - eval_summary.txt"
            echo ""
            echo "Summary:"
            cat eval_summary.txt
        fi
    fi
else
    echo -e "${RED}❌ Workflow failed with exit code $EXIT_CODE${NC}"
    echo ""
    echo "💡 Tips:"
    echo "  - Run with --verbose for more details"
    echo "  - Check Docker logs: docker ps -a | grep act-"
    echo "  - Verify secrets are correct: cat .github/workflows/.secrets"
    echo "  - See LOCAL_TESTING.md for troubleshooting"
fi

echo ""
exit $EXIT_CODE
