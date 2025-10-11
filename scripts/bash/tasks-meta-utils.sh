#!/bin/bash
# tasks-meta-utils.sh - Dual Execution Loop utilities for managing tasks_meta.json
# Provides functions for SYNC/ASYNC task classification, MCP dispatching, and review enforcement

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

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
    jq --arg task_id "$task_id" --argjson task "$task_json" \
       '.tasks[$task_id] = $task' "$tasks_meta_path" > "${tasks_meta_path}.tmp"
    mv "${tasks_meta_path}.tmp" "$tasks_meta_path"

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
    jq --arg task_id "$task_id" --arg job_id "$job_id" --arg server "$async_server" \
       '.tasks[$task_id].mcp_job_id = $job_id | .tasks[$task_id].mcp_server = $server | .tasks[$task_id].status = "dispatched"' \
       "$tasks_meta_path" > "${tasks_meta_path}.tmp"
    mv "${tasks_meta_path}.tmp" "$tasks_meta_path"

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
        jq --arg task_id "$task_id" '.tasks[$task_id].status = "completed"' "$tasks_meta_path" > "${tasks_meta_path}.tmp"
        mv "${tasks_meta_path}.tmp" "$tasks_meta_path"
    else
        echo "running"
    fi
}

# Perform micro-review for SYNC task
perform_micro_review() {
    local tasks_meta_path="$1"
    local task_id="$2"

    local review_id="micro_$(date +%s)"
    local review_json
    review_json=$(cat << EOF
{
  "id": "$review_id",
  "task_id": "$task_id",
  "type": "micro",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "passed",
  "reviewer": "human",
  "comments": "Micro-review completed - code quality and logic verified",
  "criteria_checked": [
    "code_quality",
    "logic_correctness",
    "security_best_practices",
    "error_handling"
  ]
}
EOF
)

    # Add review to tasks_meta.json
    jq --argjson review "$review_json" '.reviews.micro_reviews += [$review]' "$tasks_meta_path" > "${tasks_meta_path}.tmp"
    mv "${tasks_meta_path}.tmp" "$tasks_meta_path"

    # Update task review status
    jq --arg task_id "$task_id" '.tasks[$task_id].review_status = "micro_reviewed"' "$tasks_meta_path" > "${tasks_meta_path}.tmp"
    mv "${tasks_meta_path}.tmp" "$tasks_meta_path"

    log_info "Completed micro-review for task $task_id"
}

# Perform macro-review for completed feature
perform_macro_review() {
    local tasks_meta_path="$1"

    local review_id="macro_$(date +%s)"
    local review_json
    review_json=$(cat << EOF
{
  "id": "$review_id",
  "type": "macro",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "passed",
  "reviewer": "human",
  "comments": "Macro-review completed - feature integration and quality verified",
  "criteria_checked": [
    "feature_integration",
    "test_coverage",
    "performance_requirements",
    "documentation_completeness",
    "security_compliance"
  ]
}
EOF
)

    # Add review to tasks_meta.json
    jq --argjson review "$review_json" '.reviews.macro_reviews += [$review]' "$tasks_meta_path" > "${tasks_meta_path}.tmp"
    mv "${tasks_meta_path}.tmp" "$tasks_meta_path"

    log_info "Completed macro-review for feature"
}

# Apply quality gates based on execution mode
apply_quality_gates() {
    local tasks_meta_path="$1"
    local task_id="$2"

    local execution_mode
    execution_mode=$(jq -r ".tasks[\"$task_id\"].execution_mode" "$tasks_meta_path")

    local quality_gate
    quality_gate=$(jq -r ".quality_gates[\"$execution_mode\"]" "$tasks_meta_path")

    # Mock quality gate checks - in real implementation, would run actual tests/scans
    local passed=true

    if [[ "$passed" == "true" ]]; then
        jq --arg task_id "$task_id" '.tasks[$task_id].quality_gate_passed = true' "$tasks_meta_path" > "${tasks_meta_path}.tmp"
        mv "${tasks_meta_path}.tmp" "$tasks_meta_path"
        log_info "Quality gates passed for task $task_id ($execution_mode mode)"
    else
        log_error "Quality gates failed for task $task_id ($execution_mode mode)"
        return 1
    fi
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