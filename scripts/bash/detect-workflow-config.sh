#!/bin/bash
# detect-workflow-config.sh
# Detects workflow mode and framework options from spec.md metadata
# Returns JSON: {"mode":"build|spec","tdd":true|false,"contracts":true|false,"data_models":true|false,"risk_tests":true|false}

detect_workflow_config() {
  local spec_file="${1:-spec.md}"
  
  # Default values (spec mode defaults)
  local mode="spec"
  local tdd="true"
  local contracts="true"
  local data_models="true"
  local risk_tests="true"
  
  # If spec.md doesn't exist, return defaults as JSON
  if [[ ! -f "$spec_file" ]]; then
    echo "{\"mode\":\"$mode\",\"tdd\":$tdd,\"contracts\":$contracts,\"data_models\":$data_models,\"risk_tests\":$risk_tests}"
    return 0
  fi
  
  # Extract mode (look for line: **Workflow Mode**: build|spec)
local mode_line
    mode_line=$(grep "^\*\*Workflow Mode\*\*:" "$spec_file" | head -1)
    local mode="spec"
    if [[ -n "$mode_line" ]]; then
        mode=$(echo "$mode_line" | sed 's/.*: *\(.*\)/\1/' | tr -d '[:space:]')
    fi
  
  # Validate mode (must be build or spec)
  if [[ ! "$mode" =~ ^(build|spec)$ ]]; then
    mode="spec"  # fallback on invalid
  fi
  
  # Set option defaults based on mode
  if [[ "$mode" == "build" ]]; then
    tdd="false"
    contracts="false"
    data_models="false"
    risk_tests="false"
  fi
  
  # Extract and override with explicit options
  # Look for line: **Framework Options**: tdd=true, contracts=false, ...
local options_line
    options_line=$(grep "^\*\*Framework Options\*\*:" "$spec_file" | head -1 | sed 's/.*: *\(.*\)/\1/')
    local tdd_val="true"
    local contracts_val="true"
    local data_models_val="true"
    local risk_tests_val="true"
    
    if [[ -n "$options_line" ]]; then
        tdd_val=$(echo "$options_line" | grep -o "tdd=[^,]*" | cut -d= -f2 | tr -d '[:space:]')
        contracts_val=$(echo "$options_line" | grep -o "contracts=[^,]*" | cut -d= -f2 | tr -d '[:space:]')
        data_models_val=$(echo "$options_line" | grep -o "data_models=[^,]*" | cut -d= -f2 | tr -d '[:space:]')
        risk_tests_val=$(echo "$options_line" | grep -o "risk_tests=[^,]*" | cut -d= -f2 | tr -d '[:space:]')
    fi
  
  # Return as JSON
  echo "{\"mode\":\"$mode\",\"tdd\":$tdd,\"contracts\":$contracts,\"data_models\":$data_models,\"risk_tests\":$risk_tests}"
}

# If run directly (not sourced), execute the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  detect_workflow_config "$@"
fi
