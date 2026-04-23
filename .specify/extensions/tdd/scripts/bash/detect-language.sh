#!/usr/bin/env bash
# detect-language.sh - Detect language and test framework from project files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT_DIR="$(dirname "$SCRIPT_DIR")"

OUTPUT_FILE="${OUTPUT_FILE:-$EXT_DIR/language-detected.json}"

echo "Detecting language and test framework..."

detect_language() {
    local language="unknown"
    local framework="unknown"
    local test_dir="tests/"
    local binary=""
    local flags="-xvs"
    
    # Check for Python
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        language="python"
        
        if [[ -f "pyproject.toml" ]]; then
            if grep -q "pytest" "pyproject.toml" 2>/dev/null; then
                framework="pytest"
                binary="pytest"
            elif grep -q "unittest" "pyproject.toml" 2>/dev/null; then
                framework="unittest"
                binary="python -m unittest"
            else
                framework="pytest"
                binary="pytest"
            fi
        elif [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
            if grep -q "pytest" "requirements.txt" "setup.py" 2>/dev/null; then
                framework="pytest"
                binary="pytest"
            else
                framework="pytest"
                binary="pytest"
            fi
        fi
        
        test_dir="tests/"
        flags="-xvs"
    fi
    
    # Check for TypeScript/JavaScript
    if [[ -f "package.json" ]] && [[ "$language" == "unknown" ]]; then
        language="typescript"
        
        if grep -q '"vitest"' "package.json" 2>/dev/null; then
            framework="vitest"
            binary="vitest"
            flags="run"
        elif grep -q '"jest"' "package.json" 2>/dev/null; then
            framework="jest"
            binary="npx jest"
            flags="--passWithNoTests"
        else
            framework="vitest"
            binary="vitest"
            flags="run"
        fi
        
        if [[ -d "__tests__" ]]; then
            test_dir="__tests__/"
        else
            test_dir="tests/"
        fi
    fi
    
    # Check for Go
    if [[ -f "go.mod" ]] && [[ "$language" == "unknown" ]]; then
        language="go"
        framework="testing"
        binary="go test"
        flags="-v"
        test_dir=""
    fi
    
    # Check for Rust
    if [[ -f "Cargo.toml" ]] && [[ "$language" == "unknown" ]]; then
        language="rust"
        framework="cargo"
        binary="cargo test"
        flags=""
        test_dir=""
    fi
    
    # Check for Java
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        language="java"
        
        if [[ -f "pom.xml" ]]; then
            framework="junit"
            binary="mvn test"
            flags=""
        else
            framework="junit"
            binary="./gradlew test"
            flags=""
        fi
        
        test_dir="src/test/java/"
    fi
    
    # Check for C#/.NET
    if [[ -f "*.csproj" ]] || [[ -f "*.sln" ]]; then
        language="csharp"
        
        if ls *.csproj 2>/dev/null | head -1 | grep -q "Test"; then
            framework="xunit"
        else
            framework="nunit"
        fi
        
        binary="dotnet test"
        flags=""
        test_dir="Tests/"
    fi
    
    # Output detected configuration
    cat > "$OUTPUT_FILE" << EOF
{
  "language": "$language",
  "framework": "$framework",
  "test_directory": "$test_dir",
  "binary": "$binary",
  "flags": "$flags",
  "detected_at": "$(date -Iseconds)"
}
EOF
    
    echo "Detected: $language / $framework"
    echo "Test directory: $test_dir"
    echo "Test command: $binary $flags"
    echo ""
    echo "Configuration saved to: $OUTPUT_FILE"
}

# Run detection
detect_language