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
        init|map|update|review|specify|implement|clarify)
            ACTION="$arg"
            ;;
        --help|-h)
            echo "Usage: $0 [action] [context] [--json]"
            echo ""
            echo "Actions:"
            echo "  specify  Interactive PRD exploration to create system ADRs (greenfield)"
            echo "  clarify  Refine and resolve ambiguities in existing ADRs"
            echo "  init     Reverse-engineer architecture from existing codebase (brownfield)"
            echo "  implement Generate full Architecture Description (AD.md) from ADRs"
            echo "  map      (alias for init) Reverse-engineer architecture from existing codebase"
            echo "  update   Update architecture based on code/spec changes"
            echo "  review   Validate architecture against constitution"
            echo ""
            echo "Options:"
            echo "  --json   Output results in JSON format"
            echo "  --help   Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 specify \"B2B SaaS for supply chain management\""
            echo "  $0 clarify \"Focus on authentication and data persistence decisions\""
            echo "  $0 init \"Django monolith with PostgreSQL and React\""
            echo "  $0 implement \"Generate full AD.md from ADRs\""
            echo "  $0 update \"Added microservices and event sourcing\""
            echo "  $0 review \"Focus on security and performance\""
            echo ""
            echo "Pro Tip: Add context/description after the action for better results."
            echo "The AI will use your input to understand system scope and constraints."
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
eval "$(get_feature_paths)"

# Ensure the memory directory exists
mkdir -p "$REPO_ROOT/memory"

ARCHITECTURE_FILE="$REPO_ROOT/memory/architecture.md"
TEMPLATE_FILE="$REPO_ROOT/.specify/templates/architecture-template.md"

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
    
    local yaml_files=(*.yaml)
    if [[ -d "kubernetes" ]] || [[ -d "k8s" ]] || [[ -f "${yaml_files[0]}" ]] && grep -q "apiVersion:" *.yaml 2>/dev/null; then
        tech_stack+="**Orchestration**: Kubernetes\n"
    fi
    
    if [[ -d "terraform" ]] || [[ -f "*.tf" ]]; then
        tech_stack+="**IaC**: Terraform\n"
    fi
    
    local github_yml_files=(".github/workflows/"*.yml)
    local github_yaml_files=(".github/workflows/"*.yaml)
    if [[ -f "${github_yml_files[0]}" ]] || [[ -f "${github_yaml_files[0]}" ]]; then
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

# Function to generate and insert diagrams into architecture.md
generate_and_insert_diagrams() {
    local arch_file="$1"
    local system_name="${2:-System}"
    
    echo "📊 Generating architecture diagrams..." >&2
    
    # Get diagram format from config
    local diagram_format
    diagram_format=$(get_architecture_diagram_format)
    
    echo "   Using diagram format: $diagram_format" >&2
    
    # Source diagram generators
    local generator_dir="$SCRIPT_DIR"
    if [[ "$diagram_format" == "mermaid" ]]; then
        source "$generator_dir/mermaid-generator.sh"
    else
        source "$generator_dir/ascii-generator.sh"
    fi
    
    # Array of views to generate diagrams for
    local views=("context" "functional" "information" "concurrency" "development" "deployment" "operational")
    
    # Generate each diagram and insert into template
    for view in "${views[@]}"; do
        echo "   Generating ${view} view diagram..." >&2
        
        local diagram_code
        if [[ "$diagram_format" == "mermaid" ]]; then
            diagram_code=$(generate_mermaid_diagram "$view" "$system_name")
            
            # Validate Mermaid syntax
            if ! validate_mermaid_syntax "$diagram_code"; then
                echo "   ⚠️  Mermaid validation failed for ${view} view, using ASCII fallback" >&2
                source "$generator_dir/ascii-generator.sh"
                diagram_code=$(generate_ascii_diagram "$view" "$system_name")
                diagram_format="ascii"
            fi
        else
            diagram_code=$(generate_ascii_diagram "$view" "$system_name")
        fi
        
        # Create the diagram block with appropriate markdown
        local diagram_block
        if [[ "$diagram_format" == "mermaid" ]]; then
            diagram_block="\`\`\`mermaid
$diagram_code
\`\`\`"
        else
            diagram_block="\`\`\`text
$diagram_code
\`\`\`"
        fi
        
        # Insert diagram into the architecture file at appropriate location
        # This is a simplified insertion - AI agent via architect.md template will do the real work
        # We're just providing the diagram generation capability here
    done
    
    echo "✅ Diagram generation complete" >&2
}

# Action: Specify (greenfield - interactive PRD exploration to create ADRs)
action_specify() {
    local adr_file="$REPO_ROOT/memory/adr.md"
    local adr_template="$REPO_ROOT/.specify/templates/adr-template.md"
    
    echo "📐 Setting up for interactive ADR creation..." >&2
    
    # Ensure memory directory exists
    mkdir -p "$REPO_ROOT/memory"
    
    # Initialize ADR file from template if it doesn't exist
    if [[ ! -f "$adr_file" ]]; then
        if [[ -f "$adr_template" ]]; then
            echo "Creating ADR file from template..." >&2
            cp "$adr_template" "$adr_file"
            echo "✅ Created: $adr_file" >&2
        else
            # Create minimal ADR file
            cat > "$adr_file" << 'EOF'
# Architecture Decision Records

## ADR Index

| ID | Decision | Status | Date | Owner |
|----|----------|--------|------|-------|

---

EOF
            echo "✅ Created minimal ADR file: $adr_file" >&2
        fi
    else
        echo "✅ ADR file already exists: $adr_file" >&2
    fi
    
    echo "" >&2
    echo "Ready for interactive PRD exploration." >&2
    echo "The AI agent will:" >&2
    echo "  1. Analyze your PRD/requirements input" >&2
    echo "  2. Ask clarifying questions about architecture" >&2
    echo "  3. Create ADRs for each key decision" >&2
    echo "  4. Save decisions to memory/adr.md" >&2
    echo "" >&2
    echo "After completion, run '/architect.implement' to generate full AD.md" >&2
    
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"specify\",\"adr_file\":\"$adr_file\",\"context\":\"${ARGS[*]}\"}"
    fi
}

# Action: Clarify (refine existing ADRs)
action_clarify() {
    local adr_file="$REPO_ROOT/memory/adr.md"
    
    if [[ ! -f "$adr_file" ]]; then
        echo "❌ ADR file does not exist: $adr_file" >&2
        echo "Run '/architect.specify' or '/architect.init' first" >&2
        exit 1
    fi
    
    echo "🔍 Loading existing ADRs for clarification..." >&2
    
    # Count existing ADRs
    local adr_count
    adr_count=$(grep -c "^## ADR-" "$adr_file" 2>/dev/null || echo "0")
    echo "Found $adr_count ADR(s) in $adr_file" >&2
    
    echo "" >&2
    echo "Ready for ADR refinement." >&2
    echo "The AI agent will:" >&2
    echo "  1. Review existing ADRs" >&2
    echo "  2. Ask targeted clarification questions" >&2
    echo "  3. Update ADRs based on your responses" >&2
    echo "  4. Flag any inconsistencies or gaps" >&2
    
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"clarify\",\"adr_file\":\"$adr_file\",\"adr_count\":$adr_count,\"context\":\"${ARGS[*]}\"}"
    fi
}

# Action: Implement (generate full AD.md from ADRs)
action_implement() {
    local adr_file="$REPO_ROOT/memory/adr.md"
    local ad_file="$REPO_ROOT/AD.md"
    local ad_template="$REPO_ROOT/.specify/templates/AD-template.md"
    
    if [[ ! -f "$adr_file" ]]; then
        echo "❌ ADR file does not exist: $adr_file" >&2
        echo "Run '/architect.specify' or '/architect.init' first" >&2
        exit 1
    fi
    
    echo "📐 Setting up for Architecture Description generation..." >&2
    
    # Initialize AD.md from template if it doesn't exist
    if [[ ! -f "$ad_file" ]]; then
        if [[ -f "$ad_template" ]]; then
            echo "Creating AD.md from template..." >&2
            cp "$ad_template" "$ad_file"
            echo "✅ Created: $ad_file" >&2
        else
            echo "⚠️  AD template not found: $ad_template" >&2
            echo "The AI agent will create AD.md from scratch" >&2
        fi
    else
        echo "✅ AD.md already exists, will be updated: $ad_file" >&2
    fi
    
    # Count ADRs for context
    local adr_count
    adr_count=$(grep -c "^## ADR-" "$adr_file" 2>/dev/null || echo "0")
    
    echo "" >&2
    echo "Ready for Architecture Description generation." >&2
    echo "The AI agent will:" >&2
    echo "  1. Read all $adr_count ADR(s) from memory/adr.md" >&2
    echo "  2. Generate 7 Rozanski & Woods viewpoints" >&2
    echo "  3. Apply Security and Performance perspectives" >&2
    echo "  4. Create Mermaid diagrams for each view" >&2
    echo "  5. Write complete AD.md to project root" >&2
    
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"implement\",\"adr_file\":\"$adr_file\",\"ad_file\":\"$ad_file\",\"adr_count\":$adr_count,\"context\":\"${ARGS[*]}\"}"
    fi
}

# Action: Initialize (brownfield - reverse-engineer from codebase)
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
    
    # Generate diagrams based on user config
    generate_and_insert_diagrams "$ARCHITECTURE_FILE" "System"
    
    echo "✅ Created: $ARCHITECTURE_FILE" >&2
    echo "" >&2
    echo "Next steps:" >&2
    echo "1. Review and customize the architecture document" >&2
    echo "2. Fill in stakeholder concerns and system scope" >&2
    echo "3. Complete each viewpoint section with your system details" >&2
    echo "4. Run '/architect.implement' to generate full AD.md" >&2
    
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
    
    # Output structured data for AI agent to populate architecture.md Section C
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"map\",\"tech_stack\":\"$tech_stack\",\"directory_structure\":\"$dir_structure\"}"
    else
        echo "" >&2
        echo "📋 Mapping complete. Use this information to populate memory/architecture.md:" >&2
        echo "  - Section C (Tech Stack Summary): Use detected technologies above" >&2
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
        echo "Run '/architect.specify' or '/architect.init' first" >&2
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
    
    # Regenerate diagrams with current format
    generate_and_insert_diagrams "$ARCHITECTURE_FILE" "System"
    
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
        echo "Run '/architect.specify' or '/architect.init' first" >&2
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
    specify)
        action_specify
        ;;
    clarify)
        action_clarify
        ;;
    init|map)
        action_init
        ;;
    implement)
        action_implement
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
