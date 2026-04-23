---
instruction_type: Generation
priority: Standard
description: Standards for creating and managing GitHub Actions workflows and reusable actions
---

# Rule: GitHub Actions Workflows and Reusable Actions

## Checklist
- Use reusable workflows and composite actions to reduce duplication across repositories
- Create organization-level reusable workflows in `.github/workflows` or dedicated workflow repositories
- Reference reusable workflows using `workflow_call` trigger and `uses` keyword
- Version reusable workflows and actions using Git tags, branches, or commit SHAs
- Structure reusable components with clear inputs, outputs, and documentation
- Test workflow changes in a test repository before promoting to all repositories
- Use GitHub Actions marketplace actions from trusted sources with pinned versions
- Leverage composite actions for reusable job steps and sequences
- Maintain backward compatibility when updating shared workflows
- Use GitHub secrets and variables for environment-specific and repository-specific configuration
- **Always use OIDC (OpenID Connect) for cloud provider authentication** - never use long-lived credentials
- Configure minimal required permissions using `permissions` block in workflows
- Use `concurrency` groups to prevent duplicate workflow runs
- Implement job timeouts and resource limits for cost control

## Reusable Workflows

### Organization-Level Workflows
- **Location**: `.github/workflows/` in organization repositories or dedicated workflow repos
- **Purpose**: Define baseline workflow patterns and reusable pipeline components
- **Structure**: Organize workflows by function (build, test, deploy, security, etc.)
- **Versioning**: Use Git tags (e.g., `v1.0.0`) or commit SHAs for stable references
- **Documentation**: Include README.md explaining available workflows and their inputs

### Workflow Organization Patterns
- Group related workflows in subdirectories: `workflows/build/`, `workflows/test/`, `workflows/deploy/`
- Use descriptive workflow names: `docker-build.yml`, `terraform-validate.yml`, `helm-deploy.yml`
- Create base workflows that define common job patterns: `base-pipeline.yml`
- Define workflow templates that can be reused across repositories
- Use workflow composition to build complex pipelines from simple components

## Repository-Level Workflow Configuration

### Calling Reusable Workflows
- Use `workflow_call` trigger to invoke reusable workflows:
  ```yaml
  name: CI Pipeline
  on:
    workflow_call:
      inputs:
        environment:
          required: true
          type: string
      secrets:
        deploy_key:
          required: true
  
  jobs:
    build:
      uses: ./.github/workflows/build.yml@v1.2.0
      with:
        node-version: '18'
      secrets: inherit
  ```
- Reference workflows from other repositories using `owner/repo/.github/workflows/workflow.yml@ref`
- Pass inputs and secrets to reusable workflows explicitly
- Use `secrets: inherit` to pass all secrets or specify individual secrets

### Extending Workflows
- Create repository-specific workflows that call reusable workflows
- Add repository-specific jobs before or after calling reusable workflows
- Override workflow inputs when customization is needed
- Preserve reusable workflow functionality while adding repository-specific logic
- Document why workflow extensions are necessary

### Job Composition
- Call specific jobs from reusable workflows using `jobs.<job_id>.uses`
- Compose custom job sequences based on repository needs
- Use conditional jobs with `if` expressions to enable/disable jobs based on context
- Maintain job order consistency across repositories when possible

## Composite Actions

### Creating Composite Actions
- Define composite actions in `action.yml` or `action.yaml`:
  ```yaml
  name: 'Build and Test'
  description: 'Build application and run tests'
  inputs:
    node-version:
      description: 'Node.js version'
      required: true
      default: '18'
  runs:
    using: 'composite'
    steps:
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm install
        shell: bash
      - run: npm test
        shell: bash
  ```
- Store composite actions in repository `.github/actions/` directory
- Version composite actions using Git tags for stability
- Document required and optional inputs in action metadata

### Using Composite Actions
- Reference composite actions using `uses` keyword:
  ```yaml
  - uses: ./.github/actions/build-and-test@v1.0.0
    with:
      node-version: '20'
  ```
- Reference actions from other repositories: `owner/repo/.github/actions/action-name@ref`
- Pass inputs to composite actions explicitly
- Use action outputs for job-to-job communication

## Workflow Design Patterns

### Reusable Job Templates
- Define parameterized job templates using `jobs.<job_id>` with inputs:
  ```yaml
  build-job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: ${{ inputs.build-command }}
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-output
          path: dist/
  ```
- Use `inputs` context for job-level parameterization
- Document required and optional job inputs
- Use `!reference` tags to reference other job definitions (if supported)

### Stage Definitions
- Define standard job sequences: `build`, `test`, `lint`, `security`, `deploy`
- Allow repositories to add custom jobs when needed
- Use job dependencies with `needs` keyword for execution order
- Document job dependencies and execution order

### Workflow Triggers
- Use standard triggers: `push`, `pull_request`, `workflow_dispatch`, `schedule`
- Create reusable workflows with `workflow_call` trigger
- Use `workflow_run` for cross-workflow dependencies
- Allow repositories to override trigger conditions when necessary

## Multi-Repository Architecture Considerations

### Repository Independence
- Each repository maintains its own workflow files that call reusable workflows
- Repositories can customize workflows while benefiting from centralized improvements
- Workflow updates propagate to all repositories that reference them
- Repositories can pin to specific workflow versions for stability

### Workflow Versioning Strategy
- Use semantic versioning for workflow releases: `v1.0.0`, `v1.1.0`, `v2.0.0`
- Tag stable workflow versions for production use
- Allow repositories to reference `main` branch for latest features (with caution)
- Document breaking changes in workflow version release notes

### Cross-Repository Consistency
- Establish baseline workflow standards through shared reusable workflows
- Ensure consistent job naming, artifact handling, and step ordering
- Use common input names across workflows for interoperability
- Maintain consistent security scanning and quality gates

## Variable and Secret Management

### Workflow Variables
- Define default variables in workflow files with clear documentation
- Use `env` context for workflow-level environment variables
- Allow repositories to override workflow variables in their workflow files
- Use GitHub repository variables for organization-wide defaults

### Repository Variables
- Store repository-specific variables in GitHub repository settings (not in code)
- Use variable precedence: repository variables override workflow defaults
- Group related variables using variable sets when available
- Document required repository variables in repository README

### Secrets Management
- Use GitHub secrets for sensitive values (API keys, tokens, credentials)
- Reference secrets from cloud secret managers using OIDC or service accounts
- Never hardcode secrets in workflow files or action code
- Use `secrets` context to access secrets in workflows
- Rotate secrets regularly and audit access
- **Prefer OIDC authentication over long-lived credentials** for cloud provider access

## OIDC Authentication Pattern (Keyless Authentication)

### Overview
OpenID Connect (OIDC) enables GitHub Actions to authenticate with cloud providers (AWS, GCP, Azure) without storing long-lived credentials. This eliminates the security risk of credential compromise and follows the Security-Shift-Left principle.

### Benefits
- **No Long-Lived Credentials**: Eliminates the need to store AWS access keys, service account keys, or other secrets
- **Automatic Rotation**: OIDC tokens are short-lived and automatically rotated
- **Fine-Grained Access Control**: IAM roles can restrict access by repository, branch, environment, or workflow path
- **Audit Trail**: All authentication attempts are logged in cloud provider audit logs

### AWS OIDC Configuration

#### 1. OIDC Provider Setup (Infrastructure)
Create an OIDC provider in AWS IAM that trusts GitHub Actions:

```terraform
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = ["sts.amazonaws.com"]
  
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1", # GitHub's primary thumbprint
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"  # GitHub's secondary thumbprint
  ]
  
  tags = {
    Name = "github-actions-oidc-provider"
  }
}
```

**Note**: GitHub maintains two certificate thumbprints for OIDC. Both should be included for redundancy.

#### 2. IAM Role with OIDC Trust Policy
Create an IAM role that can be assumed by GitHub Actions via OIDC:

```terraform
data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_oidc.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:[org]/[repo]:*"]  # Restrict to specific repository
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "GitHubActionsDeploymentRole"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
}
```

**Condition Keys**:
- **`aud`**: Must equal `sts.amazonaws.com` (AWS requirement)
- **`sub`**: Repository path pattern (e.g., `repo:org/repo:*` for all branches, `repo:org/repo:ref:refs/heads/main` for main branch only)

**Security Best Practices**:
- Restrict `sub` condition to specific repositories or branches for production accounts
- Use separate roles for different environments (development, staging, production)
- Attach least-privilege IAM policies to roles

#### 3. GitHub Actions Workflow with OIDC
Use OIDC in workflows to authenticate with AWS:

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  id-token: write  # Required for OIDC token request
  contents: read   # Required for actions/checkout

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsDeploymentRole
          aws-region: us-east-1
          role-session-name: GitHubActionsSession
      
      - name: Deploy infrastructure
        run: |
          terragrunt apply-all
```

**Key Requirements**:
- `permissions.id-token: write` is **required** for OIDC authentication
- `permissions.contents: read` is required for `actions/checkout`
- Use `aws-actions/configure-aws-credentials@v4` (or latest) for OIDC support
- Specify `role-to-assume` with the full ARN of the IAM role

### Multi-Account OIDC Pattern

For multi-account AWS architectures, configure OIDC providers in each account:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Determine target account
        id: account
        run: |
          # Logic to determine account based on branch or environment
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "account_id=123456789012" >> $GITHUB_OUTPUT
            echo "role_arn=arn:aws:iam::123456789012:role/GitHubActionsRole" >> $GITHUB_OUTPUT
          else
            echo "account_id=987654321098" >> $GITHUB_OUTPUT
            echo "role_arn=arn:aws:iam::987654321098:role/GitHubActionsRole" >> $GITHUB_OUTPUT
          fi
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ steps.account.outputs.role_arn }}
          aws-region: us-east-1
```

### GCP and Azure OIDC

Similar patterns apply for GCP (Workload Identity Federation) and Azure (Managed Identity):

**GCP Example**:
```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v3
  with:
    workload_identity_provider: projects/[project-number]/locations/global/workloadIdentityPools/[pool-id]/providers/[provider-id]
    service_account: [service-account]@[project-id].iam.gserviceaccount.com
```

**Azure Example**:
```yaml
- name: Azure Login
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### OIDC Testing and Validation

Create a validation workflow to test OIDC authentication:

```yaml
name: Validate OIDC Authentication

on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
          aws-region: us-east-1
      
      - name: Verify authentication
        run: |
          aws sts get-caller-identity
          echo "✓ OIDC authentication successful"
```

**Related Rules:**
- See `aws_multi_account.md` for multi-account OIDC provider setup patterns
- See `terragrunt_organization.md` for bootstrap layer OIDC configuration

## Best Practices

### Workflow Development
- Test workflow changes in a dedicated test repository before releasing
- Use GitHub Actions linting: `actionlint` or GitHub UI validation
- Maintain backward compatibility when possible
- Document workflow changes in pull request descriptions
- Use feature branches for workflow development and merge to main after review

### Repository Workflow Configuration
- Keep repository workflow files minimal - delegate to reusable workflows
- Document repository-specific customizations and why they're needed
- Review and update reusable workflow references periodically
- Use specific workflow versions (tags) in production, `main` in development
- Validate workflow configuration changes before merging

### Pipeline Optimization
- Use `actions/cache` consistently across workflows for dependency caching
- Leverage `matrix` strategy for parallel job execution
- Use `needs` keyword to create DAG workflows instead of sequential jobs
- Implement job timeouts and resource limits in workflows
- Use `concurrency` groups to prevent duplicate workflow runs
- Leverage `actions/download-artifact` and `actions/upload-artifact` for job artifacts

### Security Best Practices
- **Always use OIDC for cloud authentication** - eliminate long-lived credentials
- Configure minimal required permissions using `permissions` block
- Use environment protection rules for production deployments
- Enable branch protection rules to require workflow approval
- Scan dependencies and container images for vulnerabilities
- Use `GITHUB_TOKEN` with minimal permissions (default is read-only)
- Rotate secrets regularly and audit access logs
- Never log secrets or sensitive information in workflow output
- Use `::add-mask::` to mask sensitive values in logs

## Workflow Examples

### Reusable Workflow
```yaml
# .github/workflows/build.yml
name: Build Workflow
on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string
      build-command:
        required: false
        type: string
        default: 'npm run build'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ inputs.node-version }}
      - run: ${{ inputs.build-command }}
      - uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: dist/
```

### Repository-Level Usage
```yaml
# .github/workflows/ci.yml in repository
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read
  pull-requests: write

jobs:
  build:
    uses: owner/repo/.github/workflows/build.yml@v1.2.0
    with:
      node-version: '18'
      build-command: 'npm run build:production'
  
  test:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: build-artifacts
      - run: npm test
```

### OIDC Authentication Example
```yaml
# .github/workflows/deploy.yml
name: Deploy to AWS

on:
  push:
    branches: [main]

permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
          aws-region: us-east-1
      
      - name: Deploy
        run: |
          echo "Deploying to AWS..."
          # Deployment commands
```

### Composite Action Example
```yaml
# .github/actions/security-scan/action.yml
name: 'Security Scan'
description: 'Run security scanning tools'
inputs:
  scan-type:
    description: 'Type of scan to run'
    required: true
  severity-threshold:
    description: 'Minimum severity to report'
    required: false
    default: 'high'
runs:
  using: 'composite'
  steps:
    - name: Run security scan
      run: |
        echo "Running ${{ inputs.scan-type }} scan"
        # Scan implementation
      shell: bash
```

## Anti-Patterns
- Duplicating workflow logic in repository workflows instead of using reusable workflows
- Hardcoding values in workflows that should be inputs or variables
- Referencing reusable workflows without version pinning in production repositories
- Modifying shared workflows without testing in isolation first
- **Storing long-lived credentials (AWS keys, service account keys) in GitHub secrets** - use OIDC instead
- **Missing `permissions.id-token: write`** when using OIDC authentication
- Creating repository-specific workflows that should be shared organization-wide
- Ignoring workflow updates and staying on outdated versions indefinitely
- Mixing workflow logic with repository-specific logic without clear separation
- Using inline scripts for complex logic instead of composite actions
- Creating circular dependencies between workflows
- Not using `concurrency` groups leading to duplicate workflow runs
- Hardcoding runner types instead of making them configurable
- Using overly permissive IAM roles for OIDC authentication
- Not restricting OIDC trust policies to specific repositories or branches
- Logging sensitive information without masking

## Rationale
Reusable workflows and composite actions enable consistency across a multi-repository architecture while allowing individual repositories to customize as needed. This pattern reduces duplication, ensures baseline quality standards, and makes it easier to roll out improvements organization-wide. By versioning workflows and actions and allowing repositories to reference specific stages, teams can balance standardization with flexibility. The GitHub Actions ecosystem supports this through `workflow_call` triggers and composite actions, enabling a scalable CI/CD strategy.

OIDC authentication eliminates the security risk of long-lived credentials by using short-lived, automatically rotated tokens. This follows the Security-Shift-Left principle by integrating secure authentication patterns directly into CI/CD workflows. Combined with fine-grained IAM policies and OIDC condition keys, teams can achieve least-privilege access control while maintaining operational simplicity.