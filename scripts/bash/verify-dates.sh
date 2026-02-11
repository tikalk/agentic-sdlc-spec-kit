#!/usr/bin/env bash

# Verify that generated files contain current dates (not stale [DATE] placeholders)
# Usage: verify-dates.sh [feature-dir]
#        verify-dates.sh                    # Checks current feature based on branch
#        verify-dates.sh specs/001-feature  # Checks specific feature directory

set -e

# Resolve repository root
find_repo_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -d "$dir/.specify" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
else
    REPO_ROOT="$(find_repo_root "$SCRIPT_DIR")"
    if [ -z "$REPO_ROOT" ]; then
        echo "Error: Could not determine repository root." >&2
        exit 1
    fi
fi

# Determine feature directory
if [ -n "$1" ]; then
    # Use provided path
    if [[ "$1" = /* ]]; then
        FEATURE_DIR="$1"
    else
        FEATURE_DIR="$REPO_ROOT/$1"
    fi
else
    # Auto-detect from current branch or SPECIFY_FEATURE env var
    if [ -n "$SPECIFY_FEATURE" ]; then
        FEATURE_DIR="$REPO_ROOT/specs/$SPECIFY_FEATURE"
    elif git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        FEATURE_DIR="$REPO_ROOT/specs/$BRANCH"
    else
        echo "Error: Could not determine feature directory. Please provide a path." >&2
        exit 1
    fi
fi

if [ ! -d "$FEATURE_DIR" ]; then
    echo "Error: Feature directory not found: $FEATURE_DIR" >&2
    exit 1
fi

# Get current date in ISO format
CURRENT_DATE=$(date +%Y-%m-%d)

# Track issues found
ISSUES_FOUND=0
FILES_CHECKED=0

echo "=============================================="
echo "Date Verification Report"
echo "=============================================="
echo "Feature Directory: $FEATURE_DIR"
echo "Current Date: $CURRENT_DATE"
echo "=============================================="
echo ""

# Function to check a file for date issues
check_file() {
    local file="$1"
    local file_name=$(basename "$file")
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    FILES_CHECKED=$((FILES_CHECKED + 1))
    
    # Check for remaining [DATE] placeholders
    if grep -q '\[DATE\]' "$file"; then
        echo "❌ FAIL: $file_name contains unresolved [DATE] placeholder"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    fi
    
    # Check if file contains any date in ISO format
    if grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$file"; then
        # Extract the date found
        FOUND_DATE=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$file" | head -1)
        
        # Check if date is in the future (more than 1 day ahead) - likely incorrect
        FOUND_YEAR=$(echo "$FOUND_DATE" | cut -d'-' -f1)
        CURRENT_YEAR=$(date +%Y)
        
        if [ "$FOUND_YEAR" -gt "$CURRENT_YEAR" ]; then
            echo "⚠️  WARN: $file_name contains future date: $FOUND_DATE"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
            return 1
        fi
        
        # Check if date matches current date (ideal case)
        if [ "$FOUND_DATE" = "$CURRENT_DATE" ]; then
            echo "✅ PASS: $file_name has current date ($FOUND_DATE)"
        else
            echo "ℹ️  INFO: $file_name has date: $FOUND_DATE (not today, but valid)"
        fi
    else
        echo "ℹ️  INFO: $file_name has no ISO date (may be okay depending on template)"
    fi
    
    return 0
}

# Check all relevant files
echo "Checking files..."
echo ""

# Check spec.md
check_file "$FEATURE_DIR/spec.md"

# Check plan.md
check_file "$FEATURE_DIR/plan.md"

# Check context.md
check_file "$FEATURE_DIR/context.md"

# Check tasks.md
check_file "$FEATURE_DIR/tasks.md"

# Check checklist.md (if exists)
check_file "$FEATURE_DIR/checklist.md"

echo ""
echo "=============================================="
echo "Summary"
echo "=============================================="
echo "Files Checked: $FILES_CHECKED"
echo "Issues Found: $ISSUES_FOUND"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo ""
    echo "✅ All dates verified successfully!"
    exit 0
else
    echo ""
    echo "❌ Found $ISSUES_FOUND issue(s) that need attention."
    exit 1
fi
