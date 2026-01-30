# Setup architecture description with Rozanski & Woods methodology
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet('init', 'map', 'update', 'review', '')]
    [string]$Action = '',
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

if ($Help) {
    Write-Output "Usage: ./setup-architecture.ps1 [action] [-Json] [-Help]"
    Write-Output ""
    Write-Output "Actions:"
    Write-Output "  init     Initialize new memory/architecture.md from template"
    Write-Output "  map      Reverse-engineer architecture from existing codebase"
    Write-Output "  update   Update architecture based on code/spec changes"
    Write-Output "  review   Validate architecture against constitution"
    Write-Output ""
    Write-Output "Options:"
    Write-Output "  -Json    Output results in JSON format"
    Write-Output "  -Help    Show this help message"
    exit 0
}

# Get repository root
function Get-RepositoryRoot {
    # Try environment variable first
    if ($env:REPO_ROOT -and (Test-Path $env:REPO_ROOT)) {
        return $env:REPO_ROOT
    }

    # Fallback: search for repository markers
    $currentDir = Get-Location
    while ($currentDir -and (Test-Path $currentDir)) {
        if ((Test-Path "$currentDir\.git") -or (Test-Path "$currentDir\.specify")) {
            return $currentDir
        }
        $currentDir = Split-Path $currentDir -Parent
    }

    throw "Could not determine repository root"
}

# Detect tech stack from codebase
function Get-TechStack {
    Write-Host "Scanning codebase for technology stack..." -ForegroundColor Cyan
    
    $techStack = @()
    
    # Languages
    if (Test-Path "package.json") {
        $techStack += "**Languages**: JavaScript/TypeScript"
        $techStack += "**Package Manager**: npm/yarn"
    }
    
    if ((Test-Path "requirements.txt") -or (Test-Path "setup.py") -or (Test-Path "pyproject.toml")) {
        $techStack += "**Languages**: Python"
        if (Test-Path "pyproject.toml") {
            $techStack += "**Package Manager**: pip/poetry/uv"
        }
    }
    
    if (Test-Path "Cargo.toml") {
        $techStack += "**Languages**: Rust"
        $techStack += "**Package Manager**: Cargo"
    }
    
    if (Test-Path "go.mod") {
        $techStack += "**Languages**: Go"
        $techStack += "**Package Manager**: go modules"
    }
    
    if ((Test-Path "pom.xml") -or (Test-Path "build.gradle")) {
        $techStack += "**Languages**: Java"
        if (Test-Path "pom.xml") {
            $techStack += "**Build System**: Maven"
        } else {
            $techStack += "**Build System**: Gradle"
        }
    }
    
    if ((Get-ChildItem -Filter "*.csproj" -ErrorAction SilentlyContinue).Count -gt 0 -or 
        (Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue).Count -gt 0) {
        $techStack += "**Languages**: C#/.NET"
        $techStack += "**Build System**: dotnet"
    }
    
    # Frameworks
    if (Test-Path "package.json") {
        $packageJson = Get-Content "package.json" -Raw -ErrorAction SilentlyContinue
        if ($packageJson) {
            if ($packageJson -match "react") {
                $techStack += "**Frontend Framework**: React"
            }
            if ($packageJson -match "vue") {
                $techStack += "**Frontend Framework**: Vue"
            }
            if ($packageJson -match "angular") {
                $techStack += "**Frontend Framework**: Angular"
            }
            if ($packageJson -match "express") {
                $techStack += "**Backend Framework**: Express"
            }
            if ($packageJson -match "fastify") {
                $techStack += "**Backend Framework**: Fastify"
            }
        }
    }
    
    # Databases
    if ((Test-Path "docker-compose.yml") -or (Test-Path "docker-compose.yaml")) {
        $dockerCompose = Get-Content "docker-compose.*" -Raw -ErrorAction SilentlyContinue
        if ($dockerCompose) {
            if ($dockerCompose -match "postgres") {
                $techStack += "**Database**: PostgreSQL"
            }
            if ($dockerCompose -match "mysql") {
                $techStack += "**Database**: MySQL"
            }
            if ($dockerCompose -match "mongodb") {
                $techStack += "**Database**: MongoDB"
            }
            if ($dockerCompose -match "redis") {
                $techStack += "**Cache**: Redis"
            }
        }
    }
    
    # Infrastructure
    if (Test-Path "Dockerfile") {
        $techStack += "**Containerization**: Docker"
    }
    
    if ((Test-Path "kubernetes") -or (Test-Path "k8s")) {
        $techStack += "**Orchestration**: Kubernetes"
    }
    
    if ((Test-Path "terraform") -or (Get-ChildItem -Filter "*.tf" -ErrorAction SilentlyContinue).Count -gt 0) {
        $techStack += "**IaC**: Terraform"
    }
    
    if (Test-Path ".github/workflows") {
        $techStack += "**CI/CD**: GitHub Actions"
    }
    
    if (Test-Path ".gitlab-ci.yml") {
        $techStack += "**CI/CD**: GitLab CI"
    }
    
    if (Test-Path "Jenkinsfile") {
        $techStack += "**CI/CD**: Jenkins"
    }
    
    return $techStack -join "`n"
}

# Map directory structure
function Get-DirectoryStructure {
    Write-Host "Scanning directory structure..." -ForegroundColor Cyan
    
    $structure = @()
    
    if (Test-Path "src") {
        $structure += "**Source Code**: src/"
        if ((Test-Path "src/api") -or (Test-Path "src/routes")) {
            $structure += "  - API Layer: src/api/ or src/routes/"
        }
        if (Test-Path "src/services") {
            $structure += "  - Business Logic: src/services/"
        }
        if (Test-Path "src/models") {
            $structure += "  - Data Models: src/models/"
        }
        if (Test-Path "src/utils") {
            $structure += "  - Utilities: src/utils/"
        }
    }
    
    if ((Test-Path "tests") -or (Test-Path "test")) {
        $structure += "**Tests**: tests/ or test/"
    }
    
    if (Test-Path "docs") {
        $structure += "**Documentation**: docs/"
    }
    
    if (Test-Path "scripts") {
        $structure += "**Scripts**: scripts/"
    }
    
    if ((Test-Path "infra") -or (Test-Path "infrastructure")) {
        $structure += "**Infrastructure**: infra/ or infrastructure/"
    }
    
    return $structure -join "`n"
}

# Initialize action
function Invoke-Init {
    param($repoRoot, $architectureFile, $templateFile)
    
    if (Test-Path $architectureFile) {
        Write-Error "Architecture already exists: $architectureFile`nUse 'update' action to modify or delete the file to reinitialize"
        exit 1
    }
    
    if (-not (Test-Path $templateFile)) {
        Write-Error "Template not found: $templateFile"
        exit 1
    }
    
    Write-Host "📐 Initializing architecture from template..." -ForegroundColor Cyan
    Copy-Item $templateFile $architectureFile
    
    Write-Host "✅ Created: $architectureFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Review and customize the architecture document"
    Write-Host "2. Fill in stakeholder concerns and system scope"
    Write-Host "3. Complete each viewpoint section with your system details"
    Write-Host "4. Run '/speckit.architect review' to validate"
    
    if ($Json) {
        @{status="success"; action="init"; file=$architectureFile} | ConvertTo-Json
    }
}

# Map action (brownfield)
function Invoke-Map {
    param($repoRoot)
    
    Write-Host "🔍 Mapping existing codebase to architecture..." -ForegroundColor Cyan
    
    # Detect tech stack
    Write-Host ""
    Write-Host "Tech Stack Detected:" -ForegroundColor Yellow
    $techStack = Get-TechStack
    Write-Host $techStack
    
    # Map directory structure
    Write-Host ""
    Write-Host "Code Organization:" -ForegroundColor Yellow
    $dirStructure = Get-DirectoryStructure
    Write-Host $dirStructure
    
    # Output structured data for AI agent to populate architecture.md Section C
    if ($Json) {
        @{
            status="success"
            action="map"
            tech_stack=$techStack
            directory_structure=$dirStructure
        } | ConvertTo-Json
    } else {
        Write-Host ""
        Write-Host "📋 Mapping complete. Use this information to populate memory/architecture.md:"
        Write-Host "  - Section C (Tech Stack Summary): Use detected technologies above"
        Write-Host "  - Development View: Use directory structure above"
        Write-Host "  - Deployment View: Check docker-compose.yml, k8s configs, terraform"
        Write-Host "  - Functional View: Use API endpoints detected"
        Write-Host "  - Information View: Check database schemas, ORM models"
    }
}

# Update action
function Invoke-Update {
    param($repoRoot, $architectureFile)
    
    if (-not (Test-Path $architectureFile)) {
        Write-Error "Architecture does not exist: $architectureFile`nRun '/speckit.architect init' first"
        exit 1
    }
    
    Write-Host "🔄 Updating architecture based on recent changes..." -ForegroundColor Cyan
    
    # Check for recent commits
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Recent changes:" -ForegroundColor Yellow
        git log --oneline --since="7 days ago" 2>$null | Select-Object -First 10
    }
    
    # Detect current tech stack
    Write-Host ""
    Write-Host "Current Tech Stack:" -ForegroundColor Yellow
    Get-TechStack
    
    Write-Host ""
    Write-Host "✅ Update analysis complete" -ForegroundColor Green
    Write-Host "Review the architecture document and update affected sections:"
    Write-Host "  - New tables/models? → Update Information View"
    Write-Host "  - New services/components? → Update Functional View + Deployment View"
    Write-Host "  - New queues/async? → Update Concurrency View"
    Write-Host "  - New dependencies? → Update Development View"
    Write-Host "  - Add ADR if significant decision was made"
    
    if ($Json) {
        @{status="success"; action="update"; file=$architectureFile} | ConvertTo-Json
    }
}

# Review action
function Invoke-Review {
    param($repoRoot, $architectureFile)
    
    if (-not (Test-Path $architectureFile)) {
        Write-Error "Architecture does not exist: $architectureFile`nRun '/speckit.architect init' first"
        exit 1
    }
    
    Write-Host "🔍 Reviewing architecture..." -ForegroundColor Cyan
    
    $issues = @()
    $content = Get-Content $architectureFile -Raw
    
    # Check for required sections
    if ($content -notmatch "## 1\. Introduction") {
        $issues += "Missing: Introduction section"
    }
    
    if ($content -notmatch "## 2\. Stakeholders & Concerns") {
        $issues += "Missing: Stakeholders section"
    }
    
    if ($content -notmatch "## 3\. Architectural Views") {
        $issues += "Missing: Architectural Views section"
    }
    
    if ($content -notmatch "### 3\.1 Context View") {
        $issues += "Missing: Context View"
    }
    
    if ($content -notmatch "### 3\.2 Functional View") {
        $issues += "Missing: Functional View"
    }
    
    if ($content -notmatch "## 4\. Architectural Perspectives") {
        $issues += "Missing: Perspectives section"
    }
    
    if ($content -notmatch "## 5\. Global Constraints & Principles") {
        $issues += "Missing: Global Constraints section"
    }
    
    # Check for placeholders
    if ($content -match "\[SYSTEM_NAME\]") {
        $issues += "Placeholder: System name not filled in"
    }
    
    if ($content -match "\[STAKEHOLDER_") {
        $issues += "Placeholder: Stakeholders not filled in"
    }
    
    # Report results
    if ($issues.Count -eq 0) {
        Write-Host "✅ Architecture review passed - no major issues found" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Architecture review found issues:" -ForegroundColor Yellow
        foreach ($issue in $issues) {
            Write-Host "  - $issue"
        }
    }
    
    # Check constitution alignment
    $constitutionFile = Join-Path $repoRoot ".specify\memory\constitution.md"
    if (Test-Path $constitutionFile) {
        Write-Host ""
        Write-Host "📜 Checking constitution alignment..." -ForegroundColor Cyan
        Write-Host "✅ Constitution file found: $constitutionFile" -ForegroundColor Green
        Write-Host "Manually verify that architecture adheres to constitutional principles"
    }
    
    if ($Json) {
        if ($issues.Count -eq 0) {
            @{status="success"; action="review"; issues=@()} | ConvertTo-Json
        } else {
            @{status="warning"; action="review"; issues=$issues} | ConvertTo-Json
        }
    }
}

# Main execution
try {
    $repoRoot = Get-RepositoryRoot
    
    # Ensure memory directory exists
    $memoryDir = Join-Path $repoRoot "memory"
    if (-not (Test-Path $memoryDir)) {
        New-Item -ItemType Directory -Path $memoryDir -Force | Out-Null
    }
    
    $architectureFile = Join-Path $repoRoot "memory\architecture.md"
    $templateFile = Join-Path $repoRoot ".specify\templates\architecture-template.md"
    
    # Default action if not specified
    if (-not $Action) {
        if (Test-Path $architectureFile) {
            $Action = "update"
        } else {
            $Action = "init"
        }
    }
    
    # Execute action
    switch ($Action) {
        'init' {
            Invoke-Init -repoRoot $repoRoot -architectureFile $architectureFile -templateFile $templateFile
        }
        'map' {
            Invoke-Map -repoRoot $repoRoot
        }
        'update' {
            Invoke-Update -repoRoot $repoRoot -architectureFile $architectureFile
        }
        'review' {
            Invoke-Review -repoRoot $repoRoot -architectureFile $architectureFile
        }
        default {
            Write-Error "Unknown action: $Action`nUse -Help for usage information"
            exit 1
        }
    }
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
