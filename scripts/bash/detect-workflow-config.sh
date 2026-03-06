#!/bin/bash
# detect-workflow-config.sh
# Returns framework options from spec.md metadata
# Returns default framework options for spec-driven development

detect_workflow_config() {
  # Return default framework options
  echo '{"tdd":true,"contracts":true,"data_models":true,"risk_tests":true}'
}

# If run directly (not sourced), execute the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  detect_workflow_config "$@"
fi
