#!/bin/bash

# Generate Real Specs for Error Analysis
# This script generates actual specs for all test case templates
# Uses the same LLM endpoint as PromptFoo evals
#
# Usage: ./evals/scripts/generate-real-specs.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPECS_DIR="$REPO_ROOT/evals/datasets/real-specs"
PROMPT_FILE="$REPO_ROOT/evals/prompts/spec-prompt.txt"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🤖 Real Spec Generator"
echo "======================"
echo ""

# Check environment variables
if [ -z "$ANTHROPIC_BASE_URL" ]; then
    echo -e "${RED}❌ ANTHROPIC_BASE_URL not set${NC}"
    exit 1
fi

if [ -z "$ANTHROPIC_AUTH_TOKEN" ]; then
    echo -e "${RED}❌ ANTHROPIC_AUTH_TOKEN not set${NC}"
    exit 1
fi

# Set default model
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-sonnet-4-5-20250929}"

echo -e "${GREEN}✓${NC} Using model: $CLAUDE_MODEL"
echo -e "${GREEN}✓${NC} API endpoint: $ANTHROPIC_BASE_URL"
echo ""

# Check if prompt template exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo -e "${RED}❌ Prompt template not found: $PROMPT_FILE${NC}"
    exit 1
fi

# Read the prompt template
PROMPT_TEMPLATE=$(cat "$PROMPT_FILE")

# Find all spec files
SPEC_FILES=$(find "$SPECS_DIR" -name "spec-*.md" | sort)
TOTAL=$(echo "$SPEC_FILES" | wc -l | tr -d ' ')

echo "📝 Found $TOTAL spec files to generate"
echo ""

COUNT=0
for SPEC_FILE in $SPEC_FILES; do
    COUNT=$((COUNT + 1))
    FILENAME=$(basename "$SPEC_FILE")

    echo -e "${YELLOW}[$COUNT/$TOTAL]${NC} Processing $FILENAME..."

    # Extract the prompt from the spec file
    USER_PROMPT=$(sed -n '/## Prompt/,/## Generated Spec/p' "$SPEC_FILE" | \
                  sed '1d;$d' | \
                  sed '/^$/d' | \
                  head -n 1)

    if [ -z "$USER_PROMPT" ]; then
        echo "  ⚠️  No prompt found, skipping"
        continue
    fi

    echo "  📋 Prompt: ${USER_PROMPT:0:60}..."

    # Replace {{user_input}} in the template
    FULL_PROMPT="${PROMPT_TEMPLATE//\{\{user_input\}\}/$USER_PROMPT}"

    # Call the LLM API
    echo "  🤖 Generating spec..."

    RESPONSE=$(curl -s -X POST "$ANTHROPIC_BASE_URL/v1/messages" \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_AUTH_TOKEN" \
        -d "{
            \"model\": \"$CLAUDE_MODEL\",
            \"max_tokens\": 4000,
            \"messages\": [{
                \"role\": \"user\",
                \"content\": $(echo "$FULL_PROMPT" | jq -Rs .)
            }]
        }")

    # Check for errors
    if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
        ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message')
        echo -e "  ${RED}❌ API Error: $ERROR_MSG${NC}"
        continue
    fi

    # Extract the generated content
    GENERATED_SPEC=$(echo "$RESPONSE" | jq -r '.content[0].text')

    if [ -z "$GENERATED_SPEC" ] || [ "$GENERATED_SPEC" = "null" ]; then
        echo -e "  ${RED}❌ Failed to extract generated spec${NC}"
        continue
    fi

    # Update the spec file
    # Create a temporary file with the updated content
    TEMP_FILE=$(mktemp)

    # Copy everything up to "## Generated Spec"
    sed -n '1,/## Generated Spec/p' "$SPEC_FILE" > "$TEMP_FILE"

    # Add the generated spec
    echo "$GENERATED_SPEC" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"

    # Add the Review Notes section
    sed -n '/## Review Notes/,$p' "$SPEC_FILE" >> "$TEMP_FILE"

    # Replace the original file
    mv "$TEMP_FILE" "$SPEC_FILE"

    echo -e "  ${GREEN}✓${NC} Saved to $FILENAME"
    echo ""
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Generation complete!${NC}"
echo ""
echo "📊 Next steps:"
echo "   1. Review generated specs in: $SPECS_DIR"
echo "   2. Run error analysis: ./evals/scripts/run-error-analysis.sh"
echo "   3. Annotate specs in Jupyter notebook"
echo ""