#!/usr/bin/env bash

set -e

JSON_MODE=false
ACTION=""
ARGS=()
VIEWS="core"
ADR_HEURISTIC="surprising"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --views)
            shift
            VIEWS="$1"
            shift
            ;;
        --views=*)
            VIEWS="${1#*=}"
            shift
            ;;
        --adr-heuristic)
            shift
            ADR_HEURISTIC="$1"
            shift
            ;;
        --adr-heuristic=*)
            ADR_HEURISTIC="${1#*=}"
            shift
            ;;
        init|map|update|review|specify|implement|clarify)
            ACTION="$1"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [action] [context] [--json] [--views VIEWS] [--adr-heuristic HEURISTIC]"
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
            echo "  --json             Output results in JSON format"
            echo "  --views VIEWS      Architecture views to generate: core (default), all, or comma-separated"
            echo "  --adr-heuristic H  ADR generation heuristic: surprising (default), all, minimal"
            echo "  --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 specify \"B2B SaaS for supply chain management\""
            echo "  $0 init --views all \"Django monolith with PostgreSQL\""
            echo "  $0 init --views concurrency,operational \"Microservices architecture\""
            echo "  $0 clarify --adr-heuristic all \"Document all decisions\""
            echo "  $0 implement \"Generate full AD.md from ADRs\""
            echo ""
            echo "Pro Tip: Add context/description after the action for better results."
            echo "The AI will use your input to understand system scope and constraints."
            exit 0
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Default action if not specified
if [[ -z "$ACTION" ]]; then
    if [[ -f "$REPO_ROOT/AD.md" ]]; then
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
mkdir -p "$REPO_ROOT/.specify/memory"

# Architecture files (new structure: AD.md at root, ADRs in memory/)
AD_FILE="$REPO_ROOT/AD.md"
ADR_FILE="$REPO_ROOT/.specify/memory/adr.md"
TEMPLATE_FILE="$REPO_ROOT/.specify/templates/architecture-template.md"
AD_TEMPLATE_FILE="$REPO_ROOT/.specify/templates/AD-template.md"

# Export for use in functions
export ARCHITECTURE_VIEWS="$VIEWS"
export ADR_HEURISTIC="$ADR_HEURISTIC"

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

# Function to scan existing docs for deduplication
scan_existing_docs() {
    local repo_root="${1:-$REPO_ROOT}"
    local findings=""
    
    echo "Scanning existing documentation for deduplication..." >&2
    
    # Check for existing architecture docs
    if [[ -f "$repo_root/AD.md" ]]; then
        findings+="EXISTING_AD: $repo_root/AD.md\n"
    fi
    
    if [[ -f "$repo_root/docs/architecture.md" ]]; then
        findings+="EXISTING_ARCHITECTURE: $repo_root/docs/architecture.md\n"
    fi
    
    # Scan README for tech stack
    if [[ -f "$repo_root/README.md" ]]; then
        if grep -q "Tech Stack\|Technology\|Built with" "$repo_root/README.md" 2>/dev/null; then
            findings+="TECH_STACK_IN_README: $repo_root/README.md\n"
        fi
        if grep -q "PostgreSQL\|MySQL\|MongoDB\|Redis" "$repo_root/README.md" 2>/dev/null; then
            findings+="DATABASE_IN_README: $repo_root/README.md\n"
        fi
        if grep -q "React\|Vue\|Angular" "$repo_root/README.md" 2>/dev/null; then
            findings+="FRONTEND_IN_README: $repo_root/README.md\n"
        fi
    fi
    
    # Scan AGENTS.md for context
    if [[ -f "$repo_root/AGENTS.md" ]]; then
        findings+="AGENTS_CONTEXT: $repo_root/AGENTS.md\n"
    fi
    
    # Scan CONTRIBUTING.md for dev guidelines
    if [[ -f "$repo_root/CONTRIBUTING.md" ]]; then
        findings+="DEV_GUIDELINES: $repo_root/CONTRIBUTING.md\n"
    fi
    
    echo -e "$findings"
}

# Function to parse views flag
parse_views() {
    local views_arg="$1"
    
    case "$views_arg" in
        "all"|"full")
            echo "context functional information concurrency development deployment operational"
            ;;
        "core"|"minimal"|"")
            echo "context functional information development deployment"
            ;;
        *)
            # Parse comma-separated: "concurrency,operational"
            local valid_views=""
            local all_views="context functional information concurrency development deployment operational"
            
            IFS=',' read -ra VIEWS_ARRAY <<< "$views_arg"
            for view in "${VIEWS_ARRAY[@]}"; do
                view=$(echo "$view" | tr -d ' ')  # Trim whitespace
                # Check if view is valid
                if echo "$all_views" | grep -qw "$view"; then
                    valid_views="$valid_views $view"
                fi
            done
            
            # Always include core views
            for view in context functional information development deployment; do
                if ! echo "$valid_views" | grep -qw "$view"; then
                    valid_views="$valid_views $view"
                fi
            done
            
            echo "$valid_views" | sed 's/^ *//'
            ;;
    esac
}

# Function to generate and insert diagrams into architecture.md
generate_and_insert_diagrams() {
    local arch_file="$1"
    local system_name="${2:-System}"
    local views_list="${3:-$ARCHITECTURE_VIEWS}"
    
    # Parse views
    local parsed_views
    parsed_views=$(parse_views "$views_list")
    
    echo "📊 Generating architecture diagrams..." >&2
    echo "   Views: $parsed_views" >&2
    
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
    
    # Generate each diagram and insert into template
    for view in $parsed_views; do
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
    local adr_file="$REPO_ROOT/.specify/memory/adr.md"
    local adr_template="$REPO_ROOT/.specify/templates/adr-template.md"
    
    echo "📐 Setting up for interactive ADR creation..." >&2
    
    # Ensure memory directory exists
    mkdir -p "$REPO_ROOT/.specify/memory"
    
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
    echo "  4. Save decisions to .specify/memory/adr.md" >&2
    echo "" >&2
    echo "After completion, run '/architect.implement' to generate full AD.md" >&2
    
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"specify\",\"adr_file\":\"$adr_file\",\"context\":\"${ARGS[*]}\"}"
    fi
}

# Action: Clarify (refine existing ADRs)
action_clarify() {
    local adr_file="$REPO_ROOT/.specify/memory/adr.md"
    
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
    local adr_file="$REPO_ROOT/.specify/memory/adr.md"
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
    echo "  1. Read all $adr_count ADR(s) from .specify/memory/adr.md" >&2
    echo "  2. Generate 7 Rozanski & Woods viewpoints" >&2
    echo "  3. Apply Security and Performance perspectives" >&2
    echo "  4. Create Mermaid diagrams for each view" >&2
    echo "  5. Write complete AD.md to project root" >&2
    
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"implement\",\"adr_file\":\"$adr_file\",\"ad_file\":\"$ad_file\",\"adr_count\":$adr_count,\"context\":\"${ARGS[*]}\"}"
    fi
}

# Action: Initialize (brownfield - reverse-engineer from codebase, ADRs only)
action_init() {
    local adr_file="$REPO_ROOT/.specify/memory/adr.md"
    local adr_template="$REPO_ROOT/.specify/templates/adr-template.md"
    
    echo "🔍 Initializing brownfield architecture discovery..." >&2
    
    # Ensure memory directory exists
    mkdir -p "$REPO_ROOT/.specify/memory"
    
    # Scan existing docs for deduplication
    local existing_docs
    existing_docs=$(scan_existing_docs "$REPO_ROOT")
    if [[ -n "$existing_docs" ]]; then
        echo "📋 Found existing documentation:" >&2
        echo "$existing_docs" | while read -r line; do
            echo "  - $line" >&2
        done
        echo "" >&2
    fi
    
    # Detect tech stack for context
    echo "🔍 Scanning codebase..." >&2
    local tech_stack
    tech_stack=$(detect_tech_stack)
    
    local dir_structure
    dir_structure=$(map_directory_structure)
    
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
    echo "📊 Codebase Analysis Summary:" >&2
    echo "$tech_stack" >&2
    echo "" >&2
    echo "$dir_structure" >&2
    
    echo "" >&2
    echo "Ready for brownfield architecture discovery." >&2
    echo "The AI agent will:" >&2
    echo "  1. Analyze codebase structure and patterns" >&2
    echo "  2. Infer architectural decisions from code" >&2
    echo "  3. Create ADRs marked as 'Discovered (Inferred)'" >&2
    echo "  4. Auto-trigger /architect.clarify to validate findings" >&2
    echo "" >&2
    echo "NOTE: AD.md will NOT be created until ADRs are validated." >&2
    echo "      After clarification, run /architect.implement to generate AD.md" >&2
    
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"init\",\"adr_file\":\"$adr_file\",\"tech_stack\":\"$tech_stack\",\"existing_docs\":\"$existing_docs\",\"source\":\"brownfield\"}"
    fi
}

# Action: Map (brownfield)
action_map() {
    echo "🔍 Mapping existing codebase to architecture..." >&2
    
    # Scan existing docs
    local existing_docs
    existing_docs=$(scan_existing_docs "$REPO_ROOT")
    
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
    
    # Output structured data for AI agent to populate AD.md
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"map\",\"tech_stack\":\"$tech_stack\",\"directory_structure\":\"$dir_structure\",\"existing_docs\":\"$existing_docs\"}"
    else
        echo "" >&2
        echo "📋 Mapping complete. Use this information to populate AD.md:" >&2
        
        if [[ -n "$existing_docs" ]]; then
            echo "" >&2
            echo "Existing Documentation (reference, don't duplicate):" >&2
            echo "$existing_docs" | while read -r line; do
                echo "  - $line" >&2
            done
        fi
        
        echo "" >&2
        echo "Architecture Sections:" >&2
        echo "  - Context View (3.1): Define system boundaries" >&2
        echo "  - Development View (3.5): Use directory structure above" >&2
        echo "  - Deployment View (3.6): Check docker-compose.yml, k8s configs, terraform" >&2
        echo "  - Functional View (3.2): Use API endpoints detected" >&2
        echo "  - Information View (3.3): Check database schemas, ORM models" >&2
    fi
}

# Action: Update
action_update() {
    if [[ ! -f "$AD_FILE" ]]; then
        echo "❌ Architecture does not exist: $AD_FILE" >&2
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
    
    # Regenerate diagrams with current format and views
    generate_and_insert_diagrams "$AD_FILE" "System" "$VIEWS"
    
    echo "" >&2
    echo "✅ Update analysis complete" >&2
    echo "Review the architecture document and update affected sections:" >&2
    echo "  - New tables/models? → Update Information View" >&2
    echo "  - New services/components? → Update Functional View + Deployment View" >&2
    echo "  - New queues/async? → Update Concurrency View (if included)" >&2
    echo "  - New dependencies? → Update Development View" >&2
    echo "  - Add ADR if significant decision was made" >&2
    
    if $JSON_MODE; then
        echo "{\"status\":\"success\",\"action\":\"update\",\"ad_file\":\"$AD_FILE\",\"adr_file\":\"$ADR_FILE\"}"
    fi
}

# Action: Review
action_review() {
    if [[ ! -f "$AD_FILE" ]]; then
        echo "❌ Architecture does not exist: $AD_FILE" >&2
        echo "Run '/architect.specify' or '/architect.init' first" >&2
        exit 1
    fi
    
    echo "🔍 Reviewing architecture..." >&2
    
    # Check for completeness
    local issues=()
    
    # Check for required sections
    if ! grep -q "## 1\. Introduction" "$AD_FILE"; then
        issues+=("Missing: Introduction section")
    fi
    
    if ! grep -q "## 2\. Stakeholders & Concerns" "$AD_FILE"; then
        issues+=("Missing: Stakeholders section")
    fi
    
    if ! grep -q "## 3\. Architectural Views" "$AD_FILE"; then
        issues+=("Missing: Architectural Views section")
    fi
    
    if ! grep -q "### 3.1 Context View" "$AD_FILE"; then
        issues+=("Missing: Context View")
    fi
    
    if ! grep -q "### 3.2 Functional View" "$AD_FILE"; then
        issues+=("Missing: Functional View")
    fi
    
    if ! grep -q "## 4\. Architectural Perspectives" "$AD_FILE"; then
        issues+=("Missing: Perspectives section")
    fi
    
    if ! grep -q "## 5\. Global Constraints & Principles" "$AD_FILE"; then
        issues+=("Missing: Global Constraints section")
    fi
    
    # Check for placeholder content
    if grep -q "\[SYSTEM_NAME\]" "$AD_FILE"; then
        issues+=("Placeholder: System name not filled in")
    fi
    
    if grep -q "\[STAKEHOLDER_" "$AD_FILE"; then
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
    
    # Check for ADRs
    if [[ -f "$ADR_FILE" ]]; then
        echo "" >&2
        echo "📋 ADR file found: $ADR_FILE" >&2
        local adr_count
        adr_count=$(grep -c "^## ADR-" "$ADR_FILE" 2>/dev/null || echo "0")
        echo "   Found $adr_count ADR(s)" >&2
    fi
    
    if $JSON_MODE; then
        if [[ ${#issues[@]} -eq 0 ]]; then
            echo "{\"status\":\"success\",\"action\":\"review\",\"ad_file\":\"$AD_FILE\",\"adr_file\":\"$ADR_FILE\",\"issues\":[]}"
        else
            # Format issues as JSON array
            issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
            echo "{\"status\":\"warning\",\"action\":\"review\",\"ad_file\":\"$AD_FILE\",\"adr_file\":\"$ADR_FILE\",\"issues\":$issues_json}"
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
