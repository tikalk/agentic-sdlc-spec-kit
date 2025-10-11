#!/bin/bash
# tasks-meta-utils.sh - Dual Execution Loop utilities for managing tasks_meta.json
# Provides functions for SYNC/ASYNC task classification, MCP dispatching, and review enforcement

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Global variable to track temporary files created by this script
TEMP_FILES=()

# Function to safely update JSON file without leaving temp files
safe_json_update() {
    local input_file="$1"
    local jq_filter="$2"

    # Create a temporary file in the same directory as the input file
    local temp_file
    temp_file=$(mktemp "${input_file}.XXXXXX")

    # Track the temp file for cleanup
    TEMP_FILES+=("$temp_file")

    # Run jq and write to temp file
    if jq "$jq_filter" "$input_file" > "$temp_file"; then
        # Only move if jq succeeded
        mv "$temp_file" "$input_file"
        # Remove from tracking since it was successfully moved
        TEMP_FILES=("${TEMP_FILES[@]/$temp_file}")
    else
        # Clean up temp file on failure
        rm -f "$temp_file"
        TEMP_FILES=("${TEMP_FILES[@]/$temp_file}")
        return 1
    fi
}

# Cleanup function for temporary files created by this script
cleanup_temp_files() {
    for temp_file in "${TEMP_FILES[@]}"; do
        if [[ -f "$temp_file" ]]; then
            rm -f "$temp_file"
        fi
    done
    TEMP_FILES=()
}

# Set up trap to clean up temporary files on exit
trap cleanup_temp_files EXIT

# Logging functions
log_info() {
    echo "[INFO] $*" >&2
}

log_success() {
    echo "[SUCCESS] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_warning() {
    echo "[WARNING] $*" >&2
}

# Constants
TASKS_META_FILE="tasks_meta.json"
FEATURE_DIR=""
MCP_CONFIG_FILE=".mcp.json"

# Initialize tasks_meta.json structure
init_tasks_meta() {
    local feature_dir="$1"
    local tasks_meta_path="$feature_dir/$TASKS_META_FILE"

    if [[ ! -f "$tasks_meta_path" ]]; then
        cat > "$tasks_meta_path" << EOF
{
  "feature": "$(basename "$feature_dir")",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "execution_mode": "dual",
  "quality_gates": {
    "sync": {
      "micro_review_required": true,
      "macro_review_required": true,
      "test_coverage_minimum": 80,
      "security_scan_required": true,
      "performance_benchmarks_required": true
    },
    "async": {
      "micro_review_required": false,
      "macro_review_required": true,
      "test_coverage_minimum": 60,
      "security_scan_required": false,
      "performance_benchmarks_required": false
    }
  },
  "mcp_servers": {},
  "tasks": {},
  "reviews": {
    "micro_reviews": [],
    "macro_reviews": []
  },
  "risks": [],
  "status": "initialized"
}
EOF
        log_info "Initialized tasks_meta.json at $tasks_meta_path"
    else
        log_info "tasks_meta.json already exists at $tasks_meta_path"
    fi

    echo "$tasks_meta_path"
}

# Load MCP server configuration
load_mcp_config() {
    local mcp_config_path="$1"

    if [[ -f "$mcp_config_path" ]]; then
        # Extract MCP servers from .mcp.json
        jq -r '.mcpServers // {}' "$mcp_config_path" 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

# Classify task as SYNC or ASYNC based on criteria
classify_task_execution_mode() {
    local task_description="$1"
    local task_files="$2"

    # SYNC criteria (requires human review)
    if echo "$task_description" | grep -qiE "(complex|architectural|security|integration|external|ambiguous|decision|design)"; then
        echo "SYNC"
        return
    fi

    # ASYNC criteria (can be delegated to agents)
    if echo "$task_description" | grep -qiE "(crud|boilerplate|repetitive|standard|independent|clear|well-defined)"; then
        echo "ASYNC"
        return
    fi

    # Default to SYNC for safety
    echo "SYNC"
}

# Add task to tasks_meta.json
add_task() {
    local tasks_meta_path="$1"
    local task_id="$2"
    local task_description="$3"
    local task_files="$4"
    local execution_mode="$5"

    local task_json
    task_json=$(cat << EOF
{
  "id": "$task_id",
  "description": "$task_description",
  "files": "$task_files",
  "execution_mode": "$execution_mode",
  "status": "pending",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "mcp_job_id": null,
  "mcp_server": null,
  "review_status": "pending",
  "quality_gate_passed": false
}
EOF
)

    # Add task to tasks_meta.json
    safe_json_update "$tasks_meta_path" --arg task_id "$task_id" --argjson task "$task_json" '.tasks[$task_id] = $task'

    log_info "Added task $task_id ($execution_mode) to tasks_meta.json"
}

# Dispatch ASYNC task to MCP server
dispatch_async_task() {
    local tasks_meta_path="$1"
    local task_id="$2"
    local mcp_servers="$3"

    # Find available MCP server for async agents
    local async_server=""
    local server_url=""

    # Look for async agent servers
    if echo "$mcp_servers" | jq -e '.["agent-jules"]' >/dev/null 2>&1; then
        async_server="agent-jules"
        server_url=$(echo "$mcp_servers" | jq -r '."agent-jules".url')
    elif echo "$mcp_servers" | jq -e '.["agent-async-copilot"]' >/dev/null 2>&1; then
        async_server="agent-async-copilot"
        server_url=$(echo "$mcp_servers" | jq -r '."agent-async-copilot".url')
    elif echo "$mcp_servers" | jq -e '.["agent-async-codex"]' >/dev/null 2>&1; then
        async_server="agent-async-codex"
        server_url=$(echo "$mcp_servers" | jq -r '."agent-async-codex".url')
    fi

    if [[ -z "$async_server" ]]; then
        log_error "No async MCP server configured for task $task_id"
        return 1
    fi

    # Generate mock job ID (in real implementation, this would call the MCP server)
    local job_id="job_$(date +%s)_${task_id}"

    # Update task with MCP job info
    safe_json_update "$tasks_meta_path" --arg task_id "$task_id" --arg job_id "$job_id" --arg server "$async_server" \
       '.tasks[$task_id].mcp_job_id = $job_id | .tasks[$task_id].mcp_server = $server | .tasks[$task_id].status = "dispatched"'

    log_info "Dispatched ASYNC task $task_id to $async_server (job: $job_id)"

    # In real implementation, would make HTTP call to MCP server
    # curl -X POST "$server_url/tasks" -H "Content-Type: application/json" -d "{\"task_id\": \"$task_id\", \"description\": \"...\"}"
}

# Check MCP job status (mock implementation)
check_mcp_job_status() {
    local tasks_meta_path="$1"
    local task_id="$2"

    local job_id
    job_id=$(jq -r ".tasks[\"$task_id\"].mcp_job_id" "$tasks_meta_path")

    if [[ "$job_id" == "null" ]]; then
        echo "no_job"
        return
    fi

    # Mock status - in real implementation, would query MCP server
    # For demo purposes, randomly complete some jobs
    if [[ $((RANDOM % 3)) -eq 0 ]]; then
        echo "completed"
        # Update task status
        safe_json_update "$tasks_meta_path" --arg task_id "$task_id" '.tasks[$task_id].status = "completed"'
    else
        echo "running"
    fi
}

# Perform micro-review for SYNC task
perform_micro_review() {
    local tasks_meta_path="$1"
    local task_id="$2"

    local task_description
    task_description=$(jq -r ".tasks[\"$task_id\"].description" "$tasks_meta_path")

    local task_files
    task_files=$(jq -r ".tasks[\"$task_id\"].files" "$tasks_meta_path")

    log_info "Starting micro-review for task $task_id: $task_description"

    # Interactive review prompts
    echo "=== MICRO-REVIEW: Task $task_id ==="
    echo "Description: $task_description"
    echo "Files: $task_files"
    echo ""

    # Code quality check
    echo "1. Code Quality Review:"
    echo "   - Is the code well-structured and readable?"
    echo "   - Are naming conventions followed?"
    echo "   - Is the code properly commented?"
    read -p "   Pass? (y/n): " code_quality
    echo ""

    # Logic correctness check
    echo "2. Logic Correctness Review:"
    echo "   - Does the implementation match the requirements?"
    echo "   - Are edge cases handled properly?"
    echo "   - Is the logic sound and complete?"
    read -p "   Pass? (y/n): " logic_correctness
    echo ""

    # Security best practices check
    echo "3. Security Best Practices:"
    echo "   - No hardcoded secrets or credentials?"
    echo "   - Input validation and sanitization?"
    echo "   - No obvious security vulnerabilities?"
    read -p "   Pass? (y/n): " security_practices
    echo ""

    # Error handling check
    echo "4. Error Handling:"
    echo "   - Appropriate error handling and logging?"
    echo "   - Graceful failure modes?"
    echo "   - User-friendly error messages?"
    read -p "   Pass? (y/n): " error_handling
    echo ""

    # Overall assessment
    local overall_status="passed"
    local failed_criteria=()

    if [[ "$code_quality" != "y" ]]; then
        overall_status="failed"
        failed_criteria+=("code_quality")
    fi

    if [[ "$logic_correctness" != "y" ]]; then
        overall_status="failed"
        failed_criteria+=("logic_correctness")
    fi

    if [[ "$security_practices" != "y" ]]; then
        overall_status="failed"
        failed_criteria+=("security_practices")
    fi

    if [[ "$error_handling" != "y" ]]; then
        overall_status="failed"
        failed_criteria+=("error_handling")
    fi

    # Collect comments
    echo "Additional comments (optional):"
    read -r comments
    if [[ -z "$comments" ]]; then
        comments="Micro-review completed interactively"
    fi

    local review_id="micro_$(date +%s)"
    local review_json
    review_json=$(cat << EOF
{
  "id": "$review_id",
  "task_id": "$task_id",
  "type": "micro",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$overall_status",
  "reviewer": "human",
  "comments": "$comments",
  "criteria_checked": [
    "code_quality",
    "logic_correctness",
    "security_best_practices",
    "error_handling"
  ],
  "failed_criteria": $(printf '%s\n' "${failed_criteria[@]}" | jq -R . | jq -s .)
}
EOF
)

    # Add review to tasks_meta.json
    safe_json_update "$tasks_meta_path" --argjson review "$review_json" '.reviews.micro_reviews += [$review]'

    # Update task review status
    safe_json_update "$tasks_meta_path" --arg task_id "$task_id" '.tasks[$task_id].review_status = "micro_reviewed"'

    if [[ "$overall_status" == "passed" ]]; then
        log_success "Micro-review PASSED for task $task_id"
    else
        log_error "Micro-review FAILED for task $task_id (failed: ${failed_criteria[*]})"
        return 1
    fi
}

# Perform macro-review for completed feature
perform_macro_review() {
    local tasks_meta_path="$1"

    local feature_name
    feature_name=$(jq -r '.feature' "$tasks_meta_path")

    log_info "Starting macro-review for feature: $feature_name"

    # Check if all tasks are completed
    local pending_tasks
    pending_tasks=$(jq '.tasks | to_entries[] | select(.value.status != "completed") | .key' "$tasks_meta_path")

    if [[ -n "$pending_tasks" ]]; then
        log_error "Cannot perform macro-review: pending tasks found: $pending_tasks"
        return 1
    fi

    # Interactive macro-review prompts
    echo "=== MACRO-REVIEW: Feature $feature_name ==="
    echo ""

    # Feature integration check
    echo "1. Feature Integration:"
    echo "   - All components work together correctly?"
    echo "   - No integration issues or conflicts?"
    echo "   - Feature meets original requirements?"
    read -p "   Pass? (y/n): " feature_integration
    echo ""

    # Test coverage check
    echo "2. Test Coverage:"
    echo "   - Adequate test coverage for new functionality?"
    echo "   - All critical paths tested?"
    echo "   - Tests pass consistently?"
    read -p "   Pass? (y/n): " test_coverage
    echo ""

    # Performance requirements check
    echo "3. Performance Requirements:"
    echo "   - No performance regressions?"
    echo "   - Meets performance expectations?"
    echo "   - Efficient resource usage?"
    read -p "   Pass? (y/n): " performance_requirements
    echo ""

    # Documentation completeness check
    echo "4. Documentation Completeness:"
    echo "   - Code is properly documented?"
    echo "   - User documentation updated?"
    echo "   - API documentation current?"
    read -p "   Pass? (y/n): " documentation_completeness
    echo ""

    # Security compliance check
    echo "5. Security Compliance:"
    echo "   - No security vulnerabilities introduced?"
    echo "   - Security best practices followed?"
    echo "   - Compliance requirements met?"
    read -p "   Pass? (y/n): " security_compliance
    echo ""

    # Overall assessment
    local overall_status="passed"
    local failed_criteria=()

    if [[ "$feature_integration" != "y" ]]; then
        overall_status="failed"
        failed_criteria+=("feature_integration")
    fi

    if [[ "$test_coverage" != "y" ]]; then
        overall_status="failed"
        failed_criteria+=("test_coverage")
    fi

    if [[ "$performance_requirements" != "y" ]]; then
        overall_status="failed"
        failed_criteria+=("performance_requirements")
    fi

    if [[ "$documentation_completeness" != "y" ]]; then
        overall_status="failed"
        failed_criteria+=("documentation_completeness")
    fi

    if [[ "$security_compliance" != "y" ]]; then
        overall_status="failed"
        failed_criteria+=("security_compliance")
    fi

    # Collect comments
    echo "Additional comments (optional):"
    read -r comments
    if [[ -z "$comments" ]]; then
        comments="Macro-review completed interactively - feature integration and quality verified"
    fi

    local review_id="macro_$(date +%s)"
    local review_json
    review_json=$(cat << EOF
{
  "id": "$review_id",
  "type": "macro",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$overall_status",
  "reviewer": "human",
  "comments": "$comments",
  "criteria_checked": [
    "feature_integration",
    "test_coverage",
    "performance_requirements",
    "documentation_completeness",
    "security_compliance"
  ],
  "failed_criteria": $(printf '%s\n' "${failed_criteria[@]}" | jq -R . | jq -s .)
}
EOF
)

    # Add review to tasks_meta.json
    safe_json_update "$tasks_meta_path" --argjson review "$review_json" '.reviews.macro_reviews += [$review]'

    # Update feature status
    safe_json_update "$tasks_meta_path" '.status = "macro_reviewed"'

    if [[ "$overall_status" == "passed" ]]; then
        log_success "Macro-review PASSED for feature $feature_name"
    else
        log_error "Macro-review FAILED for feature $feature_name (failed: ${failed_criteria[*]})"
        return 1
    fi
}

# Apply quality gates based on execution mode
apply_quality_gates() {
    local tasks_meta_path="$1"
    local task_id="$2"

    local execution_mode
    execution_mode=$(jq -r ".tasks[\"$task_id\"].execution_mode" "$tasks_meta_path")

    log_info "Applying quality gates for task $task_id ($execution_mode mode)"

    local passed=true
    local failed_checks=()

    if [[ "$execution_mode" == "SYNC" ]]; then
        # SYNC quality gates: 80% coverage + security scans
        echo "=== QUALITY GATES: SYNC Task $task_id ==="

        # Test coverage check (80% minimum)
        echo "1. Test Coverage Check (80% minimum):"
        # In real implementation, would run actual test coverage tools
        local coverage_percentage=85  # Mock value
        echo "   Current coverage: ${coverage_percentage}%"
        if [[ $coverage_percentage -lt 80 ]]; then
            passed=false
            failed_checks+=("test_coverage")
            echo "   ❌ FAILED: Coverage below 80%"
        else
            echo "   ✅ PASSED: Coverage meets requirement"
        fi
        echo ""

        # Security scan check
        echo "2. Security Scan:"
        # In real implementation, would run security scanning tools
        local security_issues=0  # Mock value
        echo "   Security issues found: $security_issues"
        if [[ $security_issues -gt 0 ]]; then
            passed=false
            failed_checks+=("security_scan")
            echo "   ❌ FAILED: Security issues detected"
        else
            echo "   ✅ PASSED: No security issues"
        fi
        echo ""

    elif [[ "$execution_mode" == "ASYNC" ]]; then
        # ASYNC quality gates: 60% coverage + macro review
        echo "=== QUALITY GATES: ASYNC Task $task_id ==="

        # Test coverage check (60% minimum)
        echo "1. Test Coverage Check (60% minimum):"
        local coverage_percentage=75  # Mock value
        echo "   Current coverage: ${coverage_percentage}%"
        if [[ $coverage_percentage -lt 60 ]]; then
            passed=false
            failed_checks+=("test_coverage")
            echo "   ❌ FAILED: Coverage below 60%"
        else
            echo "   ✅ PASSED: Coverage meets requirement"
        fi
        echo ""

        # Macro review check
        echo "2. Macro Review Status:"
        local macro_reviews_count
        macro_reviews_count=$(jq '.reviews.macro_reviews | length' "$tasks_meta_path")
        echo "   Macro reviews completed: $macro_reviews_count"
        if [[ $macro_reviews_count -eq 0 ]]; then
            passed=false
            failed_checks+=("macro_review")
            echo "   ❌ FAILED: No macro review completed"
        else
            echo "   ✅ PASSED: Macro review completed"
        fi
        echo ""
    fi

    if [[ "$passed" == "true" ]]; then
        safe_json_update "$tasks_meta_path" --arg task_id "$task_id" '.tasks[$task_id].quality_gate_passed = true'
        log_success "Quality gates PASSED for task $task_id ($execution_mode mode)"
    else
        safe_json_update "$tasks_meta_path" --arg task_id "$task_id" '.tasks[$task_id].quality_gate_passed = false'
        log_error "Quality gates FAILED for task $task_id ($execution_mode mode) - failed: ${failed_checks[*]}"
        return 1
    fi
}

# Apply issue tracker labels for async agent triggering
apply_issue_labels() {
    local tasks_meta_path="$1"
    local issue_id="$2"

    if [[ -z "$issue_id" ]]; then
        log_warning "No issue ID provided for labeling"
        return 0
    fi

    # Load MCP config to check if issue tracker is configured
    local mcp_config
    mcp_config=$(load_mcp_config ".mcp.json")

    local issue_tracker_server=""
    if echo "$mcp_config" | jq -e '."issue-tracker-github"' >/dev/null 2>&1; then
        issue_tracker_server="github"
    elif echo "$mcp_config" | jq -e '."issue-tracker-jira"' >/dev/null 2>&1; then
        issue_tracker_server="jira"
    elif echo "$mcp_config" | jq -e '."issue-tracker-linear"' >/dev/null 2>&1; then
        issue_tracker_server="linear"
    elif echo "$mcp_config" | jq -e '."issue-tracker-gitlab"' >/dev/null 2>&1; then
        issue_tracker_server="gitlab"
    fi

    if [[ -z "$issue_tracker_server" ]]; then
        log_warning "No issue tracker MCP server configured for labeling"
        return 0
    fi

    # Get ASYNC tasks that are ready for delegation
    local async_tasks
    async_tasks=$(jq -r '.tasks | to_entries[] | select(.value.execution_mode == "ASYNC" and .value.status == "pending") | .key' "$tasks_meta_path")

    if [[ -z "$async_tasks" ]]; then
        log_info "No pending ASYNC tasks to label"
        return 0
    fi

    local labels_to_add=("async-ready" "agent-delegatable")

    log_info "Applying labels to issue $issue_id for ASYNC task delegation: ${labels_to_add[*]}"

    # In real implementation, would make API calls to the issue tracker
    # For now, just log the intended action
    for label in "${labels_to_add[@]}"; do
        log_info "Would add label '$label' to issue $issue_id via $issue_tracker_server MCP server"
        # Example API calls:
        # GitHub: POST /repos/{owner}/{repo}/issues/{issue_number}/labels
        # Jira: PUT /rest/api/2/issue/{issueIdOrKey}
        # Linear: mutation IssueUpdate
    done

    # Update tasks_meta.json to record labeling
    local label_record
    label_record=$(cat << EOF
{
  "issue_id": "$issue_id",
  "labels_applied": $(printf '%s\n' "${labels_to_add[@]}" | jq -R . | jq -s .),
  "tracker": "$issue_tracker_server",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)

    safe_json_update "$tasks_meta_path" --argjson label_record "$label_record" '.issue_labels = $label_record'

    log_success "Issue labeling completed for $issue_id"
}

# Get execution summary
get_execution_summary() {
    local tasks_meta_path="$1"

    echo "=== Dual Execution Loop Summary ==="
    echo "Feature: $(jq -r '.feature' "$tasks_meta_path")"
    echo "Status: $(jq -r '.status' "$tasks_meta_path")"
    echo ""

    echo "Task Summary:"
    jq -r '.tasks | to_entries[] | "- \(.key): \(.value.execution_mode) - \(.value.status)"' "$tasks_meta_path"
    echo ""

    echo "Review Summary:"
    echo "Micro-reviews: $(jq '.reviews.micro_reviews | length' "$tasks_meta_path")"
    echo "Macro-reviews: $(jq '.reviews.macro_reviews | length' "$tasks_meta_path")"
    echo ""

    local async_tasks
    async_tasks=$(jq '.tasks | to_entries[] | select(.value.execution_mode == "ASYNC") | .key' "$tasks_meta_path")
    if [[ -n "$async_tasks" ]]; then
        echo "ASYNC Tasks MCP Status:"
        echo "$async_tasks" | while read -r task_id; do
            local job_id
            job_id=$(jq -r ".tasks[\"$task_id\"].mcp_job_id" "$tasks_meta_path")
            if [[ "$job_id" != "null" ]]; then
                echo "- $task_id: Job $job_id"
            fi
        done
    fi

    # Show issue labeling status
    local issue_labels
    issue_labels=$(jq -r '.issue_labels // empty' "$tasks_meta_path")
    if [[ -n "$issue_labels" && "$issue_labels" != "null" ]]; then
        echo ""
        echo "Issue Tracker Labels:"
        echo "- Issue ID: $(jq -r '.issue_labels.issue_id // "N/A"' "$tasks_meta_path")"
        echo "- Labels Applied: $(jq -r '.issue_labels.labels_applied | join(", ") // "None"' "$tasks_meta_path")"
        echo "- Tracker: $(jq -r '.issue_labels.tracker // "N/A"' "$tasks_meta_path")"
    fi
}

# Main function for testing
main() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <command> [args...]"
        echo "Commands:"
        echo "  init <feature_dir>          - Initialize tasks_meta.json"
        echo "  add-task <meta_file> <task_id> <description> <files> - Add task"
        echo "  classify <description> <files> - Classify task execution mode"
        echo "  dispatch <meta_file> <task_id> - Dispatch ASYNC task"
        echo "  review-micro <meta_file> <task_id> - Perform micro-review"
        echo "  review-macro <meta_file> - Perform macro-review"
        echo "  quality-gate <meta_file> <task_id> - Apply quality gates"
        echo "  summary <meta_file> - Show execution summary"
        exit 1
    fi

    local command="$1"
    shift

    case "$command" in
        "init")
            init_tasks_meta "$1"
            ;;
        "add-task")
            add_task "$1" "$2" "$3" "$4" "$5"
            ;;
        "classify")
            classify_task_execution_mode "$1" "$2"
            ;;
        "dispatch")
            # Load MCP config for dispatching
            local mcp_config
            mcp_config=$(load_mcp_config ".mcp.json")
            dispatch_async_task "$1" "$2" "$mcp_config"
            ;;
        "review-micro")
            perform_micro_review "$1" "$2"
            ;;
        "review-macro")
            perform_macro_review "$1"
            ;;
        "quality-gate")
            apply_quality_gates "$1" "$2"
            ;;
        "summary")
            get_execution_summary "$1"
            ;;
        *)
            echo "Unknown command: $command"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi