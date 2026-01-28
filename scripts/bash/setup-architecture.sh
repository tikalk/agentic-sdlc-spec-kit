#!/usr/bin/env bash

set -e

JSON_MODE=false
ACTION=""
ARGS=()

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        init|map|update|review)
            ACTION="$arg"
            ;;
        --help|-h)
            echo "Usage: $0 [action] [--json]"
            echo ""
            echo "Actions:"
            echo "  init     Initialize new memory/architecture.md from template"
            echo "  map      Reverse-engineer architecture from existing codebase"
            echo "  update   Update architecture based on code/spec changes"
            echo "  review   Validate architecture against constitution"
            echo ""
            echo "Options:"
            echo "  --json   Output results in JSON format"
            echo "  --help   Show this help message"
            exit 0
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
done

# Default action if not specified
if [[ -z "$ACTION" ]]; then
    if [[ -f "memory/architecture.md" ]]; then
        ACTION="update"
    else
        ACTION="init"
    fi
fi

# Get script directory and load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get all paths and variables from common functions
eval $(get_feature_paths)

# Ensure the memory directory exists
mkdir -p "$REPO_ROOT/memory"

ARCHITECTURE_FILE="$REPO_ROOT/memory/architecture.md"
TEMPLATE_FILE="$REPO_ROOT/.specify/templates/architecture-template.md"
TECH_STACK_FILE="$REPO_ROOT/memory/tech-stack.md"

# Function to detect tech stack from codebase
detect_tech_stack() {
    local tech_stack=""
    
    echo "Scanning codebase for technology stack..." >&2
    
    # Languages
    if [[ -f "package.json" ]]; then
        tech_stack+="**Languages**: JavaScript/TypeScript\n"
        tech_stack+="**Package Manager**: npm/yarn\n"
    fi
    
    if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
        tech_stack+="**Languages**: Python\n"
        if [[ -f "pyproject.toml" ]]; then
            tech_stack+="**Package Manager**: pip/poetry/uv\n"
        fi
    fi
    
    if [[ -f "Cargo.toml" ]]; then
        tech_stack+="**Languages**: Rust\n"
        tech_stack+="**Package Manager**: Cargo\n"
    fi
    
    if [[ -f "go.mod" ]]; then
        tech_stack+="**Languages**: Go\n"
        tech_stack+="**Package Manager**: go modules\n"
    fi
    
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        tech_stack+="**Languages**: Java\n"
        if [[ -f "pom.xml" ]]; then
            tech_stack+="**Build System**: Maven\n"
        else
            tech_stack+="**Build System**: Gradle\n"
        fi
    fi
    
    if [[ -f "*.csproj" ]] || [[ -f "*.sln" ]]; then
        tech_stack+="**Languages**: C#/.NET\n"
        tech_stack+="**Build System**: dotnet\n"
    fi
    
    # Frameworks (basic detection)
    if [[ -f "package.json" ]]; then
        if grep -q "react" package.json 2>/dev/null; then
            tech_stack+="**Frontend Framework**: React\n"
        fi
        if grep -q "vue" package.json 2>/dev/null; then
            tech_stack+="**Frontend Framework**: Vue\n"
        fi
        if grep -q "angular" package.json 2>/dev/null; then
            tech_stack+="**Frontend Framework**: Angular\n"
        fi
        if grep -q "express" package.json 2>/dev/null; then
            tech_stack+="**Backend Framework**: Express\n"
        fi
        if grep -q "fastify" package.json 2>/dev/null; then
            tech_stack+="**Backend Framework**: Fastify\n"
        fi
    fi
    
    if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
        if grep -q "django" requirements.txt 2>/dev/null || grep -q "django" pyproject.toml 2>/dev/null; then
            tech_stack+="**Backend Framework**: Django\n"
        fi
        if grep -q "fastapi" requirements.txt 2>/dev/null || grep -q "fastapi" pyproject.toml 2>/dev/null; then
            tech_stack+="**Backend Framework**: FastAPI\n"
        fi
        if grep -q "flask" requirements.txt 2>/dev/null || grep -q "flask" pyproject.toml 2>/dev/null; then
            tech_stack+="**Backend Framework**: Flask\n"
        fi
    fi
    
    # Databases
    if [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]]; then
        if grep -q "postgres" docker-compose.* 2>/dev/null; then
            tech_stack+="**Database**: PostgreSQL\n"
        fi
        if grep -q "mysql" docker-compose.* 2>/dev/null; then
            tech_stack+="**Database**: MySQL\n"
        fi
        if grep -q "mongodb" docker-compose.* 2>/dev/null; then
            tech_stack+="**Database**: MongoDB\n"
        fi
        if grep -q "redis" docker-compose.* 2>/dev/null; then
            tech_stack+="**Cache**: Redis\n"
        fi
    fi
    
    # Infrastructure
    if [[ -f "Dockerfile" ]]; then
        tech_stack+="**Containerization**: Docker\n"
    fi
    
    if [[ -d "kubernetes" ]] || [[ -d "k8s" ]] || [[ -f "*.yaml" ]] && grep -q "apiVersion:" *.yaml 2>/dev/null; then
        tech_stack+="**Orchestration**: Kubernetes\n"
    fi
    
    if [[ -d "terraform" ]] || [[ -f "*.tf" ]]; then
        tech_stack+="**IaC**: Terraform\n"
    fi
    
    if [[ -f ".github/workflows/"*.yml ]] || [[ -f ".github/workflows/"*.yaml ]]; then
        tech_stack+="**CI/CD**: GitHub Actions\n"
    fi
    
    if [[ -f ".gitlab-ci.yml" ]]; then
        tech_stack+="**CI/CD**: GitLab CI\n"
    fi
    
    if [[ -f "Jenkinsfile" ]]; then
        tech_stack+="**CI/CD**: Jenkins\n"
    fi
    
    echo -e "$tech_stack"
}

# Function to map directory structure
map_directory_structure() {
    echo "Scanning directory structure..." >&2
    
    local structure=""
    
    # Common patterns
    if [[ -d "src" ]]; then
        structure+="**Source Code**: src/\n"
        if [[ -d "src/api" ]] || [[ -d "src/routes" ]]; then
            structure+="  - API Layer: src/api/ or src/routes/\n"
        fi
        if [[ -d "src/services" ]]; then
            structure+="  - Business Logic: src/services/\n"
        fi
        if [[ -d "src/models" ]]; then
            structure+="  - Data Models: src/models/\n"
        fi
        if [[ -d "src/utils" ]]; then
            structure+="  - Utilities: src/utils/\n"
        fi
    fi
    
    if [[ -d "tests" ]] || [[ -d "test" ]]; then
        structure+="**Tests**: tests/ or test/\n"
    fi
    
    if [[ -d "docs" ]]; then
        structure+="**Documentation**: docs/\n"
    fi
    
    if [[ -d "scripts" ]]; then
        structure+="**Scripts**: scripts/\n"
    fi
    
    if [[ -d "infra" ]] || [[ -d "infrastructure" ]]; then
        structure+="**Infrastructure**: infra/ or infrastructure/\n"
    fi
    
    echo -e "$structure"
}

# Function to extract API endpoints (basic pattern matching)
extract_api_endpoints() {
    echo "Scanning for API endpoints..." >&2
    
    local endpoints=""
    
    # Look for common API route patterns
    if [[ -d "src" ]]; then
        # Express.js style
        endpoints+=$(grep -r "router\.\(get\|post\|put\|delete\|patch\)" src 2>/dev/null | head -10 || true)
        
        # FastAPI style
        endpoints+=$(grep -r "@app\.\(get\|post\|put\|delete\|patch\)" src 2>/dev/null | head -10 || true)
        
        # Flask style
        endpoints+=$(grep -r "@app\.route" src 2>/dev/null | head -10 || true)
    fi
    
    if [[ -n "$endpoints" ]]; then
        echo "API Endpoints detected (sample):"
        echo "$endpoints" | head -10
    fi
}

# Action: Initialize
action_init() {
    if [[ -f "$ARCHITECTURE_FILE" ]]; then
        echo "❌ Architecture already exists: $ARCHITECTURE_FILE" >&2
        echo "Use 'update' action to modify or delete the file to reinitialize" >&2
        exit 1
    fi
    
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        echo "❌ Template not found: $TEMPLATE_FILE" >&2
        exit 1
    fi
    
    echo "📐 Initializing architecture from template..." >&2
    cp "$TEMPLATE_FILE" "$ARCHITECTURE_FILE"
    
    echo "✅ Created: $ARCHITECTURE_FILE" >&2
    echo "" >&2
    echo "Next steps:" >&2
    echo "1. Review and customize the architecture document" >&2
    echo "2. Fill in stakeholder concerns and system scope" >&2
    echo "3. Complete each viewpoint section with your system details" >&2
    echo "4. Run '/speckit.architect review' to validate" >&2
    
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"init\",\"file\":\"$ARCHITECTURE_FILE\"}"
    fi
}

# Action: Map (brownfield)
action_map() {
    echo "🔍 Mapping existing codebase to architecture..." >&2
    
    # Detect tech stack
    echo "" >&2
    echo "Tech Stack Detected:" >&2
    tech_stack=$(detect_tech_stack)
    echo "$tech_stack" >&2
    
    # Map directory structure
    echo "" >&2
    echo "Code Organization:" >&2
    dir_structure=$(map_directory_structure)
    echo "$dir_structure" >&2
    
    # Extract API endpoints
    echo "" >&2
    extract_api_endpoints >&2
    
    # Save tech stack summary
    echo "$tech_stack" > "$TECH_STACK_FILE"
    echo "" >&2
    echo "✅ Tech stack summary saved to: $TECH_STACK_FILE" >&2
    
    # Output structured data for AI agent to populate architecture.md
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"map\",\"tech_stack_file\":\"$TECH_STACK_FILE\",\"tech_stack\":\"$tech_stack\",\"directory_structure\":\"$dir_structure\"}"
    else
        echo "" >&2
        echo "📋 Mapping complete. Use this information to populate memory/architecture.md:" >&2
        echo "  - Development View: Use directory structure above" >&2
        echo "  - Deployment View: Check docker-compose.yml, k8s configs, terraform" >&2
        echo "  - Functional View: Use API endpoints detected" >&2
        echo "  - Information View: Check database schemas, ORM models" >&2
    fi
}

# Action: Update
action_update() {
    if [[ ! -f "$ARCHITECTURE_FILE" ]]; then
        echo "❌ Architecture does not exist: $ARCHITECTURE_FILE" >&2
        echo "Run '/speckit.architect init' first" >&2
        exit 1
    fi
    
    echo "🔄 Updating architecture based on recent changes..." >&2
    
    # Check for recent commits (basic approach)
    if command -v git &> /dev/null && [[ -d "$REPO_ROOT/.git" ]]; then
        echo "" >&2
        echo "Recent changes:" >&2
        git log --oneline --since="7 days ago" 2>/dev/null | head -10 >&2 || true
    fi
    
    # Detect changes in tech stack
    echo "" >&2
    echo "Current Tech Stack:" >&2
    detect_tech_stack >&2
    
    echo "" >&2
    echo "✅ Update analysis complete" >&2
    echo "Review the architecture document and update affected sections:" >&2
    echo "  - New tables/models? → Update Information View" >&2
    echo "  - New services/components? → Update Functional View + Deployment View" >&2
    echo "  - New queues/async? → Update Concurrency View" >&2
    echo "  - New dependencies? → Update Development View" >&2
    echo "  - Add ADR if significant decision was made" >&2
    
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"update\",\"file\":\"$ARCHITECTURE_FILE\"}"
    fi
}

# Action: Review
action_review() {
    if [[ ! -f "$ARCHITECTURE_FILE" ]]; then
        echo "❌ Architecture does not exist: $ARCHITECTURE_FILE" >&2
        echo "Run '/speckit.architect init' first" >&2
        exit 1
    fi
    
    echo "🔍 Reviewing architecture..." >&2
    
    # Check for completeness
    local issues=()
    
    # Check for required sections
    if ! grep -q "## 1\. Introduction" "$ARCHITECTURE_FILE"; then
        issues+=("Missing: Introduction section")
    fi
    
    if ! grep -q "## 2\. Stakeholders & Concerns" "$ARCHITECTURE_FILE"; then
        issues+=("Missing: Stakeholders section")
    fi
    
    if ! grep -q "## 3\. Architectural Views" "$ARCHITECTURE_FILE"; then
        issues+=("Missing: Architectural Views section")
    fi
    
    if ! grep -q "### 3.1 Context View" "$ARCHITECTURE_FILE"; then
        issues+=("Missing: Context View")
    fi
    
    if ! grep -q "### 3.2 Functional View" "$ARCHITECTURE_FILE"; then
        issues+=("Missing: Functional View")
    fi
    
    if ! grep -q "## 4\. Architectural Perspectives" "$ARCHITECTURE_FILE"; then
        issues+=("Missing: Perspectives section")
    fi
    
    if ! grep -q "## 5\. Global Constraints & Principles" "$ARCHITECTURE_FILE"; then
        issues+=("Missing: Global Constraints section")
    fi
    
    # Check for placeholder content
    if grep -q "\[SYSTEM_NAME\]" "$ARCHITECTURE_FILE"; then
        issues+=("Placeholder: System name not filled in")
    fi
    
    if grep -q "\[STAKEHOLDER_" "$ARCHITECTURE_FILE"; then
        issues+=("Placeholder: Stakeholders not filled in")
    fi
    
    # Report results
    if [[ ${#issues[@]} -eq 0 ]]; then
        echo "✅ Architecture review passed - no major issues found" >&2
    else
        echo "⚠️  Architecture review found issues:" >&2
        for issue in "${issues[@]}"; do
            echo "  - $issue" >&2
        done
    fi
    
    # Check constitution alignment if it exists
    local constitution_file="$REPO_ROOT/.specify/memory/constitution.md"
    if [[ -f "$constitution_file" ]]; then
        echo "" >&2
        echo "📜 Checking constitution alignment..." >&2
        echo "✅ Constitution file found: $constitution_file" >&2
        echo "Manually verify that architecture adheres to constitutional principles" >&2
    fi
    
    if $JSON_MODE; then
        if [[ ${#issues[@]} -eq 0 ]]; then
            echo "{\"status\":\"success\",\"action\":\"review\",\"issues\":[]}"
        else
            # Format issues as JSON array
            issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
            echo "{\"status\":\"warning\",\"action\":\"review\",\"issues\":$issues_json}"
        fi
    fi
}

# Execute action
case "$ACTION" in
    init)
        action_init
        ;;
    map)
        action_map
        ;;
    update)
        action_update
        ;;
    review)
        action_review
        ;;
    *)
        echo "❌ Unknown action: $ACTION" >&2
        echo "Use --help for usage information" >&2
        exit 1
        ;;
esac
