#!/bin/bash

# Generate test data for evaluation
# This script creates diverse test specs for error analysis
# MVP version: Generates 10-20 specs (can be expanded to 100+ later)

set -e

DATASET_DIR="$(cd "$(dirname "$0")" && pwd)"
SPECS_DIR="$DATASET_DIR/real-specs"
PLANS_DIR="$DATASET_DIR/real-plans"

echo "🚀 Generating test data for evaluation..."
echo "Output directory: $SPECS_DIR"
echo ""

# Test prompts with diverse dimensions:
# - Complexity: simple, medium, complex
# - Domain: web-app, api, mobile
# - Tech stack: nodejs, dotnet, python
# - Team size: solo, small-team

declare -a TEST_PROMPTS=(
    # Simple web apps
    "Build a simple todo list web application with task creation, editing, and deletion"
    "Create a personal blog platform with posts, comments, and basic authentication"
    "Develop a simple calculator web app with basic arithmetic operations"

    # Medium complexity
    "Build an e-commerce platform with product catalog, shopping cart, and checkout flow"
    "Create a customer relationship management (CRM) system with contact management and sales pipeline"
    "Develop a project management dashboard with task tracking, team collaboration, and reporting"

    # Complex / Enterprise
    "Build a distributed microservices architecture for a real-time analytics platform"
    "Create an enterprise inventory management system with multi-warehouse support and compliance tracking"
    "Develop a multi-tenant SaaS application with role-based access control and API integrations"

    # API focused
    "Design a RESTful API for a social media platform with user profiles, posts, and messaging"
    "Build a GraphQL API for a content management system with flexible querying"

    # Different tech stacks
    "Create a .NET Core web application for employee onboarding with document management"
    "Build a Python Flask API for data processing and machine learning model serving"
    "Develop a Node.js/Express backend with real-time WebSocket communication"

    # Specific constraints
    "Build a HIPAA-compliant healthcare appointment scheduling system"
    "Create a financial transaction processing system with audit trails and compliance reporting"
    "Develop a legacy system integration middleware using REST and SOAP protocols"
)

# Count prompts
TOTAL_PROMPTS=${#TEST_PROMPTS[@]}
echo "📝 Will generate $TOTAL_PROMPTS test cases"
echo ""

# Generate specs
for i in "${!TEST_PROMPTS[@]}"; do
    PROMPT="${TEST_PROMPTS[$i]}"
    SPEC_NUM=$((i + 1))
    SPEC_FILE="$SPECS_DIR/spec-$(printf "%03d" $SPEC_NUM).md"

    echo "[$SPEC_NUM/$TOTAL_PROMPTS] Generating spec for: ${PROMPT:0:60}..."

    # Create a markdown file with the prompt and placeholder for output
    # In real usage, you would run: specify init "test-$SPEC_NUM" --ai claude
    # For MVP, we'll create placeholder files that can be filled in manually or via the specify command

    cat > "$SPEC_FILE" << EOF
# Test Spec $SPEC_NUM

## Prompt
$PROMPT

## Generated Spec
<!-- TODO: Run specify command or paste generated spec here -->

## Review Notes
<!-- Domain expert notes go here during error analysis -->
- [ ] Pass/Fail:
- [ ] Issues found:
- [ ] Failure category:

EOF

done

echo ""
echo "✅ Generated $TOTAL_PROMPTS test spec placeholders in: $SPECS_DIR"
echo ""
echo "📌 Next steps:"
echo "   1. Fill in specs by running: specify init <project-name> --ai claude"
echo "   2. Copy generated specs to the placeholder files"
echo "   3. Or manually paste generated specs into the files"
echo "   4. Run error analysis in Jupyter notebook"
echo ""
echo "💡 To expand dataset to 100+ specs, add more prompts to this script"
