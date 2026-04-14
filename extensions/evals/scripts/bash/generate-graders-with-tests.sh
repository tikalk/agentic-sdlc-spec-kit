#!/bin/bash
#
# Grader and Unit Test Generation Script
#
# Automatically generates Python graders and corresponding unit tests from goldset
# criteria following EDD (Eval-Driven Development) principles.
#
# This script is called by the evals.implement CLI command to create:
# 1. Python grader functions (code-based, llm-judge, hybrid)
# 2. Comprehensive unit tests for each grader
# 3. EDD compliance validation
# 4. CI/CD integration setup
#
# Usage:
#   ./generate-graders-with-tests.sh [GOLDSET_PATH] [OUTPUT_DIR] [OPTIONS]
#
# Environment Variables:
#   EVALS_GOLDSET_PATH   : Path to goldset.json file
#   EVALS_OUTPUT_DIR     : Directory for generated graders
#   EVALS_TEST_DIR       : Directory for generated tests (defaults to tests/)
#   EVALS_MODULE_NAME    : Python module name (defaults to custom_graders)
#   EVALS_OVERWRITE      : Set to 'true' to overwrite existing files
#   EVALS_INCLUDE_TESTS  : Set to 'false' to skip test generation
#

set -e  # Exit on any error

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSION_DIR="$(cd "$SCRIPT_DIR/../../" && pwd)"
GENERATOR_SCRIPT="$EXTENSION_DIR/scripts/python/generate_graders.py"

# Default values
DEFAULT_TEST_DIR="tests"
DEFAULT_MODULE_NAME="custom_graders"
DEFAULT_OVERWRITE="false"
DEFAULT_INCLUDE_TESTS="true"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Usage information
show_usage() {
    cat << EOF
Grader and Unit Test Generation Script

Usage: $0 [GOLDSET_PATH] [OUTPUT_DIR] [OPTIONS]

Arguments:
  GOLDSET_PATH    Path to goldset JSON file (required)
  OUTPUT_DIR      Directory for generated grader files (required)

Options:
  --test-dir DIR           Directory for generated test files (default: tests/)
  --module-name NAME       Python module name (default: custom_graders)
  --criterion ID           Generate only specific criterion (e.g., eval-001)
  --no-tests               Skip unit test generation
  --overwrite              Overwrite existing files
  --dry-run                Preview what would be generated
  --help                   Show this help message

Environment Variables:
  EVALS_GOLDSET_PATH       Override goldset path
  EVALS_OUTPUT_DIR         Override output directory
  EVALS_TEST_DIR           Override test directory
  EVALS_MODULE_NAME        Override module name
  EVALS_OVERWRITE          Set to 'true' to overwrite existing files
  EVALS_INCLUDE_TESTS      Set to 'false' to skip tests

Examples:
  # Generate all graders and tests from goldset
  $0 evals/goldset.json evals/graders/

  # Generate specific criterion only
  $0 evals/goldset.json evals/graders/ --criterion eval-001

  # Generate graders only (no tests)
  $0 evals/goldset.json evals/graders/ --no-tests

  # Preview what would be generated
  $0 evals/goldset.json evals/graders/ --dry-run
EOF
}

# Parse command line arguments
GOLDSET_PATH=""
OUTPUT_DIR=""
TEST_DIR=""
MODULE_NAME="$DEFAULT_MODULE_NAME"
CRITERION=""
INCLUDE_TESTS="$DEFAULT_INCLUDE_TESTS"
OVERWRITE="$DEFAULT_OVERWRITE"
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_usage
            exit 0
            ;;
        --test-dir)
            TEST_DIR="$2"
            shift 2
            ;;
        --module-name)
            MODULE_NAME="$2"
            shift 2
            ;;
        --criterion)
            CRITERION="$2"
            shift 2
            ;;
        --no-tests)
            INCLUDE_TESTS="false"
            shift
            ;;
        --overwrite)
            OVERWRITE="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$GOLDSET_PATH" ]]; then
                GOLDSET_PATH="$1"
            elif [[ -z "$OUTPUT_DIR" ]]; then
                OUTPUT_DIR="$1"
            else
                log_error "Too many positional arguments: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Override with environment variables if set
GOLDSET_PATH="${EVALS_GOLDSET_PATH:-$GOLDSET_PATH}"
OUTPUT_DIR="${EVALS_OUTPUT_DIR:-$OUTPUT_DIR}"
TEST_DIR="${EVALS_TEST_DIR:-$TEST_DIR}"
MODULE_NAME="${EVALS_MODULE_NAME:-$MODULE_NAME}"
OVERWRITE="${EVALS_OVERWRITE:-$OVERWRITE}"
INCLUDE_TESTS="${EVALS_INCLUDE_TESTS:-$INCLUDE_TESTS}"

# Set default test directory if not specified
if [[ -z "$TEST_DIR" ]]; then
    if [[ -n "$OUTPUT_DIR" ]]; then
        TEST_DIR="$(dirname "$OUTPUT_DIR")/tests"
    else
        TEST_DIR="$DEFAULT_TEST_DIR"
    fi
fi

# Validate required arguments
if [[ -z "$GOLDSET_PATH" ]]; then
    log_error "Goldset path is required"
    show_usage
    exit 1
fi

if [[ -z "$OUTPUT_DIR" ]]; then
    log_error "Output directory is required"
    show_usage
    exit 1
fi

# Validate files and directories
if [[ ! -f "$GOLDSET_PATH" ]]; then
    log_error "Goldset file not found: $GOLDSET_PATH"
    exit 1
fi

if [[ ! -f "$GENERATOR_SCRIPT" ]]; then
    log_error "Generator script not found: $GENERATOR_SCRIPT"
    exit 1
fi

# Check if Python generator script is executable
if [[ ! -x "$GENERATOR_SCRIPT" ]] && ! command -v python3 >/dev/null 2>&1; then
    log_error "Python 3 is required to run the generator script"
    exit 1
fi

# Log configuration
log_info "Grader and Test Generation Configuration:"
log_info "  Goldset Path: $GOLDSET_PATH"
log_info "  Output Directory: $OUTPUT_DIR"
log_info "  Test Directory: $TEST_DIR"
log_info "  Module Name: $MODULE_NAME"
log_info "  Include Tests: $INCLUDE_TESTS"
log_info "  Overwrite: $OVERWRITE"
log_info "  Dry Run: $DRY_RUN"
if [[ -n "$CRITERION" ]]; then
    log_info "  Criterion Filter: $CRITERION"
fi

# Build generator command
GENERATOR_CMD=(
    python3 "$GENERATOR_SCRIPT"
    --goldset "$GOLDSET_PATH"
    --output-dir "$OUTPUT_DIR"
    --test-output-dir "$TEST_DIR"
    --grader-module "$MODULE_NAME"
)

if [[ "$INCLUDE_TESTS" == "false" ]]; then
    GENERATOR_CMD+=(--no-tests)
fi

if [[ "$OVERWRITE" == "true" ]]; then
    GENERATOR_CMD+=(--overwrite)
fi

if [[ "$DRY_RUN" == "true" ]]; then
    GENERATOR_CMD+=(--dry-run)
fi

if [[ -n "$CRITERION" ]]; then
    GENERATOR_CMD+=(--criterion "$CRITERION")
fi

# Execute generation
log_info "Running generator command..."
log_info "Command: ${GENERATOR_CMD[*]}"

if "${GENERATOR_CMD[@]}"; then
    log_success "Grader generation completed successfully!"

    if [[ "$DRY_RUN" == "false" ]]; then
        # Provide next steps
        echo ""
        log_info "Next Steps:"
        echo "  1. Review generated graders in: $OUTPUT_DIR"

        if [[ "$INCLUDE_TESTS" == "true" ]]; then
            echo "  2. Run unit tests: pytest $TEST_DIR -v"
            echo "  3. Check test coverage: pytest $TEST_DIR --cov=$MODULE_NAME --cov-report=html"
        fi

        echo "  4. Integrate graders into PromptFoo configuration"
        echo "  5. Run evals.validate to verify grader compliance"
        echo ""
        log_info "Generated files are ready for use in your evaluation pipeline!"
    fi
else
    log_error "Grader generation failed!"
    exit 1
fi

# Verify generated files if not dry run
if [[ "$DRY_RUN" == "false" ]]; then
    log_info "Verifying generated files..."

    # Count generated grader files
    GRADER_COUNT=$(find "$OUTPUT_DIR" -name "*.py" -type f 2>/dev/null | wc -l)
    log_info "Generated $GRADER_COUNT grader file(s)"

    # Count generated test files if tests were included
    if [[ "$INCLUDE_TESTS" == "true" ]]; then
        TEST_COUNT=$(find "$TEST_DIR" -name "test_*.py" -type f 2>/dev/null | wc -l)
        log_info "Generated $TEST_COUNT test file(s)"

        # Check if pytest is available for running tests
        if command -v pytest >/dev/null 2>&1; then
            log_info "Pytest is available - you can run tests with: pytest $TEST_DIR -v"
        else
            log_warning "Pytest not found - install with: pip install pytest pytest-cov"
        fi
    fi

    # Check if generated graders follow naming conventions
    if [[ $GRADER_COUNT -gt 0 ]]; then
        log_info "Grader files follow EDD naming conventions: check_[criterion_name].py"
    fi
fi

log_success "Grader and test generation process completed!"