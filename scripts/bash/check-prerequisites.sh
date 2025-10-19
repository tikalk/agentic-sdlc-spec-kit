#!/usr/bin/env bash

# Consolidated prerequisite checking script
#
# This script provides unified prerequisite checking for Spec-Driven Development workflow.
# It replaces the functionality previously spread across multiple scripts.
#
# Usage: ./check-prerequisites.sh [OPTIONS]
#
# OPTIONS:
#   --json              Output in JSON format
#   --require-tasks     Require tasks.md to exist (for implementation phase)
#   --include-tasks     Include tasks.md in AVAILABLE_DOCS list
#   --paths-only        Only output path variables (no validation)
#   --help, -h          Show help message
#
# OUTPUTS:
#   JSON mode: {"FEATURE_DIR":"...", "AVAILABLE_DOCS":["..."]}
#   Text mode: FEATURE_DIR:... \n AVAILABLE_DOCS: \n ✓/✗ file.md
#   Paths only: REPO_ROOT: ... \n BRANCH: ... \n FEATURE_DIR: ... etc.

set -e

# Parse command line arguments
JSON_MODE=false
REQUIRE_TASKS=false
INCLUDE_TASKS=false
PATHS_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --require-tasks)
            REQUIRE_TASKS=true
            ;;
        --include-tasks)
            INCLUDE_TASKS=true
            ;;
        --paths-only)
            PATHS_ONLY=true
            ;;
        --help|-h)
            cat << 'EOF'
Usage: check-prerequisites.sh [OPTIONS]

Consolidated prerequisite checking for Spec-Driven Development workflow.

OPTIONS:
  --json              Output in JSON format
  --require-tasks     Require tasks.md to exist (for implementation phase)
  --include-tasks     Include tasks.md in AVAILABLE_DOCS list
  --paths-only        Only output path variables (no prerequisite validation)
  --help, -h          Show this help message

EXAMPLES:
  # Check task prerequisites (plan.md required in spec mode)
  ./check-prerequisites.sh --json
  
  # Check implementation prerequisites (plan.md required in spec mode, tasks.md always required)
  ./check-prerequisites.sh --json --require-tasks --include-tasks
  
  # Get feature paths only (no validation)
  ./check-prerequisites.sh --paths-only
  
EOF
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option '$arg'. Use --help for usage information." >&2
            exit 1
            ;;
    esac
done

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Extract risk entries from a markdown file's Risk Register section
extract_risks() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "[]"
        return
    fi

    python3 - "$file" <<'PY'
import json
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
pattern = re.compile(r"^-\s*RISK:\s*(.+)$", re.IGNORECASE)
risks = []

def normalize_severity(value):
    """Normalize severity/impact to standard levels."""
    if not value:
        return "Medium"
    value = value.lower().strip()
    if value in ["critical", "crit", "high", "hi"]:
        return "Critical" if value.startswith("crit") else "High"
    elif value in ["medium", "med"]:
        return "Medium"
    elif value in ["low", "lo"]:
        return "Low"
    else:
        # Try to map numeric or other values
        return "Medium"

for line in path.read_text().splitlines():
    match = pattern.match(line.strip())
    if not match:
        continue

    parts = [p.strip() for p in match.group(1).split("|") if p.strip()]
    data = {}

    if parts and ":" not in parts[0]:
        data["id"] = parts[0]
        parts = parts[1:]

    for part in parts:
        if ":" not in part:
            continue
        key, value = part.split(":", 1)
        key = key.strip()
        value = value.strip()
        normalized = key.lower().replace(" ", "_")
        if normalized == "risk":
            data["id"] = value
        else:
            data[normalized] = value

    if data:
        if "id" not in data:
            data["id"] = f"missing-id-{len(risks)+1}"
        # Normalize severity from impact or severity field
        severity = data.get("severity") or data.get("impact")
        data["severity"] = normalize_severity(severity)
        risks.append(data)

print(json.dumps(risks, ensure_ascii=False))
PY
}

# Extract mode configuration
get_mode_config() {
    local config_file=".specify/config/config.json"

    # Extract current mode and options from consolidated config
    python3 - "$config_file" <<'PY'
import json
import sys
from pathlib import Path

config_file = Path(sys.argv[1])
try:
    with open(config_file, 'r') as f:
        data = json.load(f)

    # Mode is now under workflow.current_mode
    current_mode = data.get('workflow', {}).get('current_mode', 'spec')
    # Options are at the top level
    options = data.get('options', {})

    # Ensure all expected options are present with defaults
    defaults = {
        'tdd_enabled': True,
        'contracts_enabled': True,
        'data_models_enabled': True,
        'risk_tests_enabled': True
    }

    # Merge with defaults for any missing options
    for key, default_value in defaults.items():
        if key not in options:
            options[key] = default_value

    result = {
        'current_mode': current_mode,
        'options': options
    }

    print(json.dumps(result))

except Exception as e:
    # Fallback to defaults on any error
    print('{"current_mode":"spec","options":{"tdd_enabled":true,"contracts_enabled":true,"data_models_enabled":true,"risk_tests_enabled":true}}')
PY
}

# Get feature paths and validate branch
eval $(get_feature_paths)
check_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" || exit 1

# If paths-only mode, output paths and exit (support JSON + paths-only combined)
if $PATHS_ONLY; then
    if $JSON_MODE; then
        # Minimal JSON paths payload (no validation performed)
        printf '{"REPO_ROOT":"%s","BRANCH":"%s","FEATURE_DIR":"%s","FEATURE_SPEC":"%s","IMPL_PLAN":"%s","TASKS":"%s"}\n' \
            "$REPO_ROOT" "$CURRENT_BRANCH" "$FEATURE_DIR" "$FEATURE_SPEC" "$IMPL_PLAN" "$TASKS"
    else
        echo "REPO_ROOT: $REPO_ROOT"
        echo "BRANCH: $CURRENT_BRANCH"
        echo "FEATURE_DIR: $FEATURE_DIR"
        echo "FEATURE_SPEC: $FEATURE_SPEC"
        echo "IMPL_PLAN: $IMPL_PLAN"
        echo "TASKS: $TASKS"
    fi
    exit 0
fi

# Validate required directories and files
if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "ERROR: Feature directory not found: $FEATURE_DIR" >&2
    echo "Run /speckit.specify first to create the feature structure." >&2
    exit 1
fi

# Check for plan.md (required in spec mode, optional in build mode)
if [[ ! -f "$IMPL_PLAN" ]]; then
    # Get current mode to determine if plan.md is required
    local current_mode="spec"
    if [[ -f ".specify/config/config.json" ]]; then
        current_mode=$(python3 -c "
import json
try:
    with open('.specify/config/config.json', 'r') as f:
        data = json.load(f)
    print(data.get('workflow', {}).get('current_mode', 'spec'))
except:
    print('spec')
" 2>/dev/null || echo "spec")
    fi

    if [[ "$current_mode" == "spec" ]]; then
        echo "ERROR: plan.md not found in $FEATURE_DIR" >&2
        echo "Run /speckit.plan first to create the implementation plan." >&2
        exit 1
    fi
    # In build mode, plan.md is optional - allow implementation to proceed
fi

if [[ ! -f "$CONTEXT" ]]; then
    echo "ERROR: context.md not found in $FEATURE_DIR" >&2
    echo "Run /specify and populate context.md before continuing." >&2
    exit 1
fi

if grep -q "\[NEEDS INPUT\]" "$CONTEXT"; then
    echo "ERROR: context.md contains unresolved [NEEDS INPUT] markers." >&2
    echo "Update $CONTEXT with current mission, code paths, directives, research, and gateway details before proceeding." >&2
    exit 1
fi

# Check for tasks.md if required
if $REQUIRE_TASKS && [[ ! -f "$TASKS" ]]; then
    echo "ERROR: tasks.md not found in $FEATURE_DIR" >&2
    echo "Run /speckit.tasks first to create the task list." >&2
    exit 1
fi

# Build list of available documents
docs=()

# Always check these optional docs
[[ -f "$RESEARCH" ]] && docs+=("research.md")
[[ -f "$DATA_MODEL" ]] && docs+=("data-model.md")

# Check contracts directory (only if it exists and has files)
if [[ -d "$CONTRACTS_DIR" ]] && [[ -n "$(ls -A "$CONTRACTS_DIR" 2>/dev/null)" ]]; then
    docs+=("contracts/")
fi

[[ -f "$QUICKSTART" ]] && docs+=("quickstart.md")

# Include tasks.md if requested and it exists
if $INCLUDE_TASKS && [[ -f "$TASKS" ]]; then
    docs+=("tasks.md")
fi

# Output results
if $JSON_MODE; then
    # Build JSON array of documents
    if [[ ${#docs[@]} -eq 0 ]]; then
        json_docs="[]"
    else
        json_docs=$(printf '"%s",' "${docs[@]}")
        json_docs="[${json_docs%,}]"
    fi
    
    SPEC_RISKS=$(extract_risks "$FEATURE_SPEC")
    PLAN_RISKS=$(extract_risks "$IMPL_PLAN")
    MODE_CONFIG=$(get_mode_config)
    printf '{"FEATURE_DIR":"%s","AVAILABLE_DOCS":%s,"SPEC_RISKS":%s,"PLAN_RISKS":%s,"MODE_CONFIG":%s}\n' "$FEATURE_DIR" "$json_docs" "$SPEC_RISKS" "$PLAN_RISKS" "$MODE_CONFIG"
else
    # Text output
    echo "FEATURE_DIR:$FEATURE_DIR"
    echo "AVAILABLE_DOCS:"
    
    # Show status of each potential document
    check_file "$RESEARCH" "research.md"
    check_file "$DATA_MODEL" "data-model.md"
    check_dir "$CONTRACTS_DIR" "contracts/"
    check_file "$QUICKSTART" "quickstart.md"
    
    if $INCLUDE_TASKS; then
        check_file "$TASKS" "tasks.md"
    fi

    spec_risks_count=$(extract_risks "$FEATURE_SPEC" | python3 - <<'PY'
import json, sys
try:
    data = json.load(sys.stdin)
except json.JSONDecodeError:
    data = []
print(len(data))
PY
    )
    plan_risks_count=$(extract_risks "$IMPL_PLAN" | python3 - <<'PY'
import json, sys
try:
    data = json.load(sys.stdin)
except json.JSONDecodeError:
    data = []
print(len(data))
PY
    )

    echo "SPEC_RISKS: $spec_risks_count"
    echo "PLAN_RISKS: $plan_risks_count"
fi
