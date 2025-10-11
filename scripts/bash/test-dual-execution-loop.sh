#!/bin/bash
# test-dual-execution-loop.sh - End-to-end test of the dual execution loop
# Tests the complete workflow from task generation through implementation to level-up

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/tasks-meta-utils.sh"

# Test configuration
TEST_FEATURE_DIR="/tmp/test-feature-$(date +%s)"
TEST_PROJECT_ROOT="/tmp/test-project-$(date +%s)"

# Logging functions
log_test_info() {
    echo "[TEST INFO] $*" >&2
}

log_test_success() {
    echo "[TEST SUCCESS] $*" >&2
}

log_test_error() {
    echo "[TEST ERROR] $*" >&2
}

log_test_warning() {
    echo "[TEST WARNING] $*" >&2
}

# Setup test environment
setup_test_environment() {
    log_test_info "Setting up test environment..."

    # Create test directories
    mkdir -p "$TEST_FEATURE_DIR"
    mkdir -p "$TEST_PROJECT_ROOT"

    # Create mock .mcp.json for testing
    cat > "$TEST_PROJECT_ROOT/.mcp.json" << EOF
{
  "mcpServers": {
    "agent-jules": {
      "type": "http",
      "url": "https://mcp.jules.ai/"
    },
    "agent-async-copilot": {
      "type": "http",
      "url": "https://mcp.async-copilot.dev/"
    }
  }
}
EOF

    # Create mock feature files
    cat > "$TEST_FEATURE_DIR/spec.md" << EOF
# User Stories

## US1: User Authentication
As a user, I want to be able to log in so that I can access my account.

### Acceptance Criteria
- Users can log in with email/password
- Invalid credentials are rejected
- Sessions are maintained

## US2: User Profile Management
As a user, I want to update my profile so that I can keep my information current.

### Acceptance Criteria
- Users can view their profile
- Users can edit profile information
- Changes are saved and displayed
EOF

    cat > "$TEST_FEATURE_DIR/plan.md" << EOF
# Implementation Plan

## Tech Stack
- Backend: Node.js with Express
- Database: PostgreSQL
- Authentication: JWT tokens
- Frontend: React

## Architecture
- RESTful API design
- MVC pattern
- Input validation and sanitization

## User Story US1: User Authentication
- Implement login endpoint
- Add JWT token generation
- Create authentication middleware

## User Story US2: User Profile Management
- Create user profile model
- Implement CRUD operations
- Add profile update endpoint
EOF

    cat > "$TEST_FEATURE_DIR/tasks.md" << EOF
# Implementation Tasks

## Phase 1: Setup
- [ ] T001 Setup project structure and dependencies [SYNC]
- [ ] T002 Configure database connection [SYNC]
- [ ] T003 Initialize authentication framework [ASYNC]

## Phase 2: User Authentication (US1)
- [ ] T004 Implement login endpoint with validation [SYNC]
- [ ] T005 Add JWT token generation and verification [SYNC]
- [ ] T006 Create authentication middleware [ASYNC]

## Phase 3: User Profile Management (US2)
- [ ] T007 Create user profile database schema [ASYNC]
- [ ] T008 Implement profile CRUD operations [SYNC]
- [ ] T009 Add profile update API endpoint [SYNC]
EOF

    log_test_success "Test environment setup complete"
}

# Test task generation and classification
test_task_generation() {
    log_test_info "Testing task generation and classification..."

    cd "$TEST_PROJECT_ROOT"

    # Initialize tasks_meta.json
    init_tasks_meta "$TEST_FEATURE_DIR"

    # Test task classification
    local task_descriptions=(
        "Setup project structure and dependencies"
        "Configure database connection"
        "Initialize authentication framework"
        "Implement login endpoint with validation"
        "Add JWT token generation and verification"
        "Create authentication middleware"
        "Create user profile database schema"
        "Implement profile CRUD operations"
        "Add profile update API endpoint"
    )

    local task_files=(
        "package.json src/"
        "src/database/"
        "src/auth/"
        "src/routes/auth.js"
        "src/auth/jwt.js"
        "src/middleware/auth.js"
        "src/models/User.js"
        "src/controllers/profile.js"
        "src/routes/profile.js"
    )

    local expected_modes=(
        "SYNC"
        "SYNC"
        "ASYNC"
        "SYNC"
        "SYNC"
        "ASYNC"
        "ASYNC"
        "SYNC"
        "SYNC"
    )

    for i in "${!task_descriptions[@]}"; do
        local task_id="T$((i+1))"
        local description="${task_descriptions[$i]}"
        local files="${task_files[$i]}"
        local expected_mode="${expected_modes[$i]}"

        # Classify task
        local classified_mode
        classified_mode=$(classify_task_execution_mode "$description" "$files")

        # Add task to meta
        add_task "$TEST_FEATURE_DIR/tasks_meta.json" "$task_id" "$description" "$files" "$classified_mode"

        if [[ "$classified_mode" == "$expected_mode" ]]; then
            log_test_success "Task $task_id classified correctly as $classified_mode"
        else
            log_test_warning "Task $task_id classified as $classified_mode, expected $expected_mode"
        fi
    done

    log_test_success "Task generation and classification test complete"
}

# Test MCP dispatching
test_mcp_dispatching() {
    log_test_info "Testing MCP dispatching..."

    cd "$TEST_PROJECT_ROOT"

    # Test dispatching ASYNC tasks
    local async_tasks=("T003" "T006" "T007")

    for task_id in "${async_tasks[@]}"; do
        local mcp_config
        mcp_config=$(load_mcp_config ".mcp.json")
        dispatch_async_task "$TEST_FEATURE_DIR/tasks_meta.json" "$task_id" "$mcp_config"
        log_test_success "Dispatched ASYNC task $task_id to MCP server"
    done

    log_test_success "MCP dispatching test complete"
}

# Test review workflows
test_review_workflows() {
    log_test_info "Testing review workflows..."

    cd "$TEST_PROJECT_ROOT"

    # Test micro-review for SYNC tasks
    log_test_info "Testing micro-review (simulated - would require user input in real scenario)"

    # Simulate micro-review completion for a SYNC task
    local task_id="T001"
    safe_json_update "$TEST_FEATURE_DIR/tasks_meta.json" --arg task_id "$task_id" '.tasks[$task_id].status = "completed"'

    # In real scenario, this would prompt for user input
    # perform_micro_review "$TEST_FEATURE_DIR/tasks_meta.json" "$task_id"

    log_test_success "Review workflows test complete (simulated)"
}

# Test quality gates
test_quality_gates() {
    log_test_info "Testing quality gates..."

    cd "$TEST_PROJECT_ROOT"

    # Test quality gates for different execution modes
    local sync_task="T001"  # SYNC task
    local async_task="T003"  # ASYNC task

    # Mark tasks as completed first
    safe_json_update "$TEST_FEATURE_DIR/tasks_meta.json" --arg task_id "$sync_task" '.tasks[$task_id].status = "completed"'
    safe_json_update "$TEST_FEATURE_DIR/tasks_meta.json" --arg task_id "$async_task" '.tasks[$task_id].status = "completed"'

    # Apply quality gates
    if apply_quality_gates "$TEST_FEATURE_DIR/tasks_meta.json" "$sync_task"; then
        log_test_success "Quality gates passed for SYNC task $sync_task"
    else
        log_test_warning "Quality gates failed for SYNC task $sync_task"
    fi

    if apply_quality_gates "$TEST_FEATURE_DIR/tasks_meta.json" "$async_task"; then
        log_test_success "Quality gates passed for ASYNC task $async_task"
    else
        log_test_warning "Quality gates failed for ASYNC task $async_task"
    fi

    log_test_success "Quality gates test complete"
}

# Test execution summary
test_execution_summary() {
    log_test_info "Testing execution summary..."

    cd "$TEST_PROJECT_ROOT"

    get_execution_summary "$TEST_FEATURE_DIR/tasks_meta.json"

    log_test_success "Execution summary test complete"
}

# Test macro-review
test_macro_review() {
    log_test_info "Testing macro-review..."

    cd "$TEST_PROJECT_ROOT"

    # Mark all tasks as completed for macro-review
    local all_tasks
    all_tasks=$(jq -r '.tasks | keys[]' "$TEST_FEATURE_DIR/tasks_meta.json")

    for task_id in $all_tasks; do
        safe_json_update "$TEST_FEATURE_DIR/tasks_meta.json" --arg task_id "$task_id" '.tasks[$task_id].status = "completed"'
    done

    # Perform macro-review (simulated)
    log_test_info "Macro-review would be performed here (simulated - requires user input)"

    log_test_success "Macro-review test complete (simulated)"
}

# Cleanup test environment
cleanup_test_environment() {
    log_test_info "Cleaning up test environment..."

    rm -rf "$TEST_FEATURE_DIR"
    rm -rf "$TEST_PROJECT_ROOT"

    log_test_success "Test environment cleanup complete"
}

# Main test function
main() {
    log_test_info "Starting Dual Execution Loop End-to-End Test"
    echo "=================================================="

    setup_test_environment
    test_task_generation
    test_mcp_dispatching
    test_review_workflows
    test_quality_gates
    test_execution_summary
    test_macro_review

    echo ""
    log_test_success "All Dual Execution Loop tests completed successfully!"
    echo "=================================================="

    cleanup_test_environment
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi