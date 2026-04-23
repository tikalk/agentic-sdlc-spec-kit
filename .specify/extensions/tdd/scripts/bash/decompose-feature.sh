#!/usr/bin/env bash
# decompose-feature.sh - Decompose feature into TDD increments based on feature type

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FEATURE_TYPE="${1:-crud}"
OUTPUT_FILE="${2:-}"

echo "Decomposing feature into increments..."
echo "Feature type: $FEATURE_TYPE"

generate_increments() {
    local type="$1"
    
    case "$type" in
        crud|create|read|update|delete)
            cat << 'EOF'
### CRUD Increment Tests

**Degenerate Cases** (empty, null, missing):
- TDD-001 [P] [ASYNC] Create with empty/null input
- TDD-002 [ASYNC] Create with missing required fields

**Happy Path** (valid operations):
- TDD-003 [P] [ASYNC] Create valid entity
- TDD-004 [ASYNC] Read existing entity
- TDD-005 [P] [ASYNC] Update with valid changes
- TDD-006 [ASYNC] Delete existing entity

**Edge Cases** (non-existent, boundaries):
- TDD-007 [ASYNC] Read non-existent entity
- TDD-008 [ASYNC] Update non-existent entity
- TDD-009 [ASYNC] Delete non-existent entity
- TDD-010 [P] [ASYNC] Create duplicate entity

**Error Cases** (invalid, violations):
- TDD-011 [ASYNC] Create with invalid data types
- TDD-012 [ASYNC] Create with constraint violations
EOF
            ;;
            
        state|statemachine|state-machine)
            cat << 'EOF'
### State Machine Increment Tests

**Degenerate Cases**:
- TDD-001 [ASYNC] Initialize with invalid state

**Happy Path** (valid transitions):
- TDD-002 [P] [ASYNC] Valid state transition
- TDD-003 [P] [ASYNC] Complete transition sequence
- TDD-004 [ASYNC] Transition to terminal state

**Edge Cases**:
- TDD-005 [ASYNC] Invalid transition attempt
- TDD-006 [ASYNC] Transition from terminal state
- TDD-007 [ASYNC] Concurrent state changes

**Error Cases**:
- TDD-008 [ASYNC] Handle invalid state input
EOF
            ;;
            
        transform|convert|parse|parsing)
            cat << 'EOF'
### Data Transform Increment Tests

**Degenerate Cases**:
- TDD-001 [ASYNC] Transform empty input
- TDD-002 [ASYNC] Transform null input
- TDD-003 [ASYNC] Transform NaN/invalid numbers

**Happy Path**:
- TDD-004 [P] [ASYNC] Transform valid single item
- TDD-005 [P] [ASYNC] Transform valid multiple items
- TDD-006 [ASYNC] Transform nested structures

**Edge Cases**:
- TDD-007 [P] [ASYNC] Transform boundary values
- TDD-008 [ASYNC] Transform maximum values
- TDD-009 [ASYNC] Transform minimum values

**Error Cases**:
- TDD-010 [ASYNC] Transform malformed input
- TDD-011 [ASYNC] Handle missing required fields
EOF
            ;;
            
        api|integration|service|endpoint|http)
            cat << 'EOF'
### Integration Increment Tests

**Degenerate Cases**:
- TDD-001 [ASYNC] Handle connection error
- TDD-002 [ASYNC] Handle timeout
- TDD-003 [ASYNC] Handle DNS resolution failure

**Happy Path** (success responses):
- TDD-004 [P] [ASYNC] Handle 200 OK response
- TDD-005 [P] [ASYNC] Handle 201 Created response
- TDD-006 [ASYNC] Handle 204 No Content response

**Client Errors**:
- TDD-007 [P] [ASYNC] Handle 400 Bad Request
- TDD-008 [ASYNC] Handle 401 Unauthorized
- TDD-009 [ASYNC] Handle 403 Forbidden
- TDD-010 [ASYNC] Handle 404 Not Found

**Server Errors**:
- TDD-011 [ASYNC] Handle 500 Internal Server Error
- TDD-012 [ASYNC] Handle 502 Bad Gateway
- TDD-013 [ASYNC] Handle 503 Service Unavailable

**Edge Cases**:
- TDD-014 [ASYNC] Handle malformed JSON response
- TDD-015 [ASYNC] Handle redirect responses
EOF
            ;;
            
        auth|authentication|login|jwt|security)
            cat << 'EOF'
### Authentication Increment Tests

**Degenerate Cases**:
- TDD-001 [ASYNC] Authenticate with empty credentials
- TDD-002 [ASYNC] Authenticate with null token

**Happy Path**:
- TDD-003 [P] [ASYNC] Valid authentication succeeds
- TDD-004 [P] [ASYNC] Valid token accepted
- TDD-005 [ASYNC] Refresh token works

**Edge Cases**:
- TDD-006 [P] [ASYNC] Expired token rejected
- TDD-007 [ASYNC] Malformed token rejected
- TDD-008 [ASYNC] Revoked token rejected

**Error Cases**:
- TDD-009 [ASYNC] Invalid credentials rejected
- TDD-010 [ASYNC] Missing credentials rejected
- TDD-011 [ASYNC] SQL injection attempts blocked
EOF
            ;;
            
        database|db|storage|persistence)
            cat << 'EOF'
### Database Increment Tests

**Degenerate Cases**:
- TDD-001 [ASYNC] Query with empty result set
- TDD-002 [ASYNC] Insert with null values

**Happy Path**:
- TDD-003 [P] [ASYNC] Successful CRUD operations
- TDD-004 [P] [ASYNC] Transaction commit works
- TDD-005 [ASYNC] Query returns correct results

**Edge Cases**:
- TDD-006 [P] [ASYNC] Handle large datasets
- TDD-007 [ASYNC] Handle concurrent transactions
- TDD-008 [ASYNC] Handle connection pool exhaustion

**Error Cases**:
- TDD-009 [ASYNC] Handle constraint violations
- TDD-010 [ASYNC] Handle deadlocks
- TDD-011 [ASYNC] Handle query timeouts
EOF
            ;;
            
        *)
            cat << 'EOF'
### Generic Increment Tests

**Degenerate Cases**:
- TDD-001 [ASYNC] Handle empty input
- TDD-002 [ASYNC] Handle null input

**Happy Path**:
- TDD-003 [P] [ASYNC] Valid input processing
- TDD-004 [P] [ASYNC] Multiple valid inputs
- TDD-005 [ASYNC] Complete workflow succeeds

**Edge Cases**:
- TDD-006 [ASYNC] Handle boundary values
- TDD-007 [ASYNC] Handle maximum input size
- TDD-008 [ASYNC] Handle special characters

**Error Cases**:
- TDD-009 [ASYNC] Handle invalid input types
- TDD-010 [ASYNC] Handle malformed data
EOF
            ;;
    esac
}

# Generate increments
if [[ -n "$OUTPUT_FILE" ]]; then
    generate_increments "$FEATURE_TYPE" > "$OUTPUT_FILE"
    echo "Increments written to: $OUTPUT_FILE"
else
    generate_increments "$FEATURE_TYPE"
fi