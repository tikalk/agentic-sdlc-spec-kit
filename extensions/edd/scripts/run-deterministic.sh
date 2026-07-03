#!/usr/bin/env bash
# EDD Deterministic Checks — Bash Runner
# Runs lint, tests, and smoke checks, writes structured JSON to stdout.
# Usage: run-deterministic.sh [--feature-dir <dir>] [--config <file>]

set -euo pipefail

FEATURE_DIR="${1:-.}"
CONFIG_FILE="${2:-.specify/extensions/edd/edd-config.yml}"
OUT_FILE="$(cd "$FEATURE_DIR" && pwd)/.eval/deterministic.json"

mkdir -p "$(dirname "$OUT_FILE")"

# Initialize result
RESULT='{}'

# ─── LINT ─────────────────────────────────────────────────────────────────────
run_lint() {
    local cmd=""
    if [ -f "pyproject.toml" ] && command -v ruff &>/dev/null; then
        cmd="ruff check ."
    elif [ -f "package.json" ] && command -v npm &>/dev/null; then
        if grep -q '"lint"' package.json 2>/dev/null; then
            cmd="npm run lint"
        elif command -v eslint &>/dev/null; then
            cmd="eslint ."
        fi
    elif [ -f "go.mod" ] && command -v golangci-lint &>/dev/null; then
        cmd="golangci-lint run ./..."
    elif [ -f "Cargo.toml" ] && command -v cargo &>/dev/null; then
        cmd="cargo clippy -- -D warnings"
    fi

    if [ -z "$cmd" ]; then
        echo '{"passed": null, "errors": null, "warnings": null, "detail": "No linter detected"}'
        return
    fi

    local out rc
    out=$(eval "$cmd" 2>&1) && rc=0 || rc=$?

    if [ "$rc" -eq 0 ]; then
        echo '{"passed": true, "errors": 0, "warnings": 0, "detail": "Lint clean"}'
    else
        local errors=0 warnings=0
        errors=$(echo "$out" | grep -ci "error" || true)
        warnings=$(echo "$out" | grep -ci "warning" || true)
        [ "$errors" -eq 0 ] && errors=1
        printf '{"passed": false, "errors": %s, "warnings": %s, "detail": "Lint failed"}\n' "$errors" "$warnings"
    fi
}

# ─── TESTS ────────────────────────────────────────────────────────────────────
run_tests() {
    local cmd=""
    local coverage="null"
    if [ -f "pyproject.toml" ] && command -v pytest &>/dev/null; then
        cmd="pytest -x --tb=short --cov"
        coverage="0"
    elif [ -f "package.json" ] && command -v npm &>/dev/null; then
        if grep -q '"test"' package.json 2>/dev/null; then
            cmd="npm test"
        elif command -v jest &>/dev/null; then
            cmd="jest --bail"
        fi
    elif [ -f "go.mod" ] && command -v go &>/dev/null; then
        cmd="go test ./..."
        coverage="0"
    elif [ -f "Cargo.toml" ] && command -v cargo &>/dev/null; then
        cmd="cargo test"
    fi

    if [ -z "$cmd" ]; then
        echo '{"passed": null, "pass_count": null, "fail_count": null, "coverage": null, "detail": "No test runner detected"}'
        return
    fi

    local out rc pass_count=0 fail_count=0
    out=$(eval "$cmd" 2>&1) && rc=0 || rc=$?

    pass_count=$(echo "$out" | grep -oP '\d+(?= passed)' | tail -1 || echo "0")
    fail_count=$(echo "$out" | grep -oP '\d+(?= failed)' | tail -1 || echo "0")

    if [ "$coverage" = "0" ]; then
        coverage=$(echo "$out" | grep -oP '\d+(?=%)' | tail -1 || echo "null")
    fi

    if [ "$rc" -eq 0 ]; then
        printf '{"passed": true, "pass_count": %s, "fail_count": 0, "coverage": %s, "detail": "All tests pass"}\n' "$pass_count" "$coverage"
    else
        [ "$fail_count" -eq 0 ] && fail_count=1
        printf '{"passed": false, "pass_count": %s, "fail_count": %s, "coverage": %s, "detail": "Some tests failed"}\n' "$pass_count" "$fail_count" "$coverage"
    fi
}

# ─── SMOKE ────────────────────────────────────────────────────────────────────
run_smoke() {
    local cmd=""
    if [ -f "package.json" ] && grep -q '"smoke"' package.json 2>/dev/null; then
        cmd="npm run smoke"
    elif [ -f "Makefile" ] && grep -q '^smoke' Makefile 2>/dev/null; then
        cmd="make smoke"
    elif [ -f "justfile" ] && grep -q '^smoke' justfile 2>/dev/null; then
        cmd="just smoke"
    fi

    if [ -z "$cmd" ]; then
        echo '{"passed": null, "scenarios": null, "detail": "No smoke tests detected"}'
        return
    fi

    local out rc scenarios=0
    out=$(eval "$cmd" 2>&1) && rc=0 || rc=$?
    scenarios=$(echo "$out" | grep -oP '\d+(?= (scenario|test))' | tail -1 || echo "0")

    if [ "$rc" -eq 0 ]; then
        printf '{"passed": true, "scenarios": %s, "detail": "Smoke tests pass"}\n' "$scenarios"
    else
        printf '{"passed": false, "scenarios": %s, "detail": "Smoke tests failed"}\n' "$scenarios"
    fi
}

# ─── MAIN ─────────────────────────────────────────────────────────────────────
cd "$FEATURE_DIR" || exit 1

LINT=$(run_lint)
TESTS=$(run_tests)
SMOKE=$(run_smoke)

printf '{
  "lint": %s,
  "tests": %s,
  "smoke": %s
}\n' "$LINT" "$TESTS" "$SMOKE" > "$OUT_FILE"

cat "$OUT_FILE"
