# Rule: Helm Chart Packaging and Values Design

## Checklist
- Follow the standard Helm directory layout (`Chart.yaml`, `values.yaml`, `templates/`, `charts/`)
- Maintain clear separation between chart templates and application-specific values
- Design values with "smallest possible" philosophy - calculate values in templates when possible
- Provide sensible defaults that work out-of-the-box
- Use `fail` and `required` functions in templates to prevent invalid configurations
- Include comments in `values.yaml` explaining each value's purpose
- Structure values to allow easy environment-specific overrides
- Use named templates for reusable logic
- Leverage Helm's built-in functions before creating custom logic
- Maintain multi-environment parity - same charts work across local, development, staging, and production
- Use values file inheritance: base `values.yaml` → environment-specific overrides

## Related Rules

For advanced Helm patterns and best practices, see:
- **Chart Library Pattern**: See `helm_chart_library.md` for reusable chart library patterns with named templates and helper functions
- **DRY Secrets Management**: See `secrets_management_dry.md` for single-source secrets management with automatic injection patterns

## Recommended (Future Improvements)
- Include `values.schema.json` for value validation to catch configuration errors early (recommended for new charts)

## Chart Structure

### Standard Directory Layout
- **Chart.yaml**: Chart metadata, dependencies, and version information
- **values.yaml**: Default values with clear documentation
- **values.schema.json**: JSON schema for value validation (recommended, not required)
- **templates/**: Kubernetes manifest templates
- **templates/_helpers.tpl**: Reusable template functions
- **charts/**: Chart dependencies (subcharts)
- **README.md**: Chart documentation and usage examples

### Template Organization
- Keep templates readable: prefer clarity over cleverness
- Use `include` for template composition
- Group related templates in subdirectories for complex charts
- Use consistent naming conventions for templates

## Values Design Philosophy

### Smallest Possible values.yaml
- **Principle**: If a value can be calculated in the template, don't ask the user for it
- Calculate derived values using Helm template functions
- Only expose values that require user input or environment-specific configuration
- Example: Calculate resource limits from requests instead of requiring both

### Sensible Defaults
- Provide production-ready defaults that work out-of-the-box
- Defaults should enable the chart to deploy successfully without modification
- Document any required values that don't have defaults
- Use environment-appropriate defaults (e.g., resource limits, replica counts)

### Override-Friendly Structure
- Structure values hierarchically to match Kubernetes resource structure
- Group related values logically (e.g., `image`, `service`, `ingress`)
- Use consistent naming patterns across charts
- Enable partial overrides without duplicating entire value trees

### Documentation
- Include comments in `values.yaml` explaining each value's purpose
- Document value types, allowed values, and constraints
- Provide examples for complex value structures
- Link to relevant Kubernetes documentation for advanced options

## Safety & Validation

### Schema Validation (Recommended)
- **Recommended**: Include `values.schema.json` for value validation when creating new charts
- Define schemas for all top-level value keys when implementing schema validation
- Use schema validation to catch configuration errors before deployment
- Validate required fields, types, and value constraints in schema
- **Note**: Schema validation is recommended but not required at this time

### Template Validation
- Use `fail` functions in templates to prevent invalid configurations
- Validate required values at template render time, not at runtime
- Use `required` function for critical values with clear error messages:
  ```yaml
  {{- required "app.name is required" .Values.app.name }}
  ```
- Check for logical inconsistencies (e.g., min > max)

### Error Messages
- Provide clear, actionable error messages in validation failures
- Include context about which value failed and why
- Suggest valid values or ranges when appropriate

## Template Best Practices

### Named Templates
- Use named templates (defined in `_helpers.tpl`) for reusable logic
- Name templates with chart prefix: `{{- define "mychart.labels" }}`
- Document template parameters and return values
- Reuse templates across multiple resources

### Built-in Functions
- Leverage Helm's built-in functions before creating custom logic
- Use `include` to compose templates
- Use `tpl` for processing template strings from values
- Use `default` for fallback values
- Use `indent` for proper YAML formatting

### Template Composition
- Use `include` for template composition:
  ```yaml
  {{- include "mychart.labels" . | indent 2 }}
  ```
- Compose complex templates from simple building blocks
- Keep template logic focused and single-purpose

### Readability
- Keep templates readable: prefer clarity over cleverness
- Use whitespace and comments to explain complex logic
- Break complex templates into smaller, named templates
- Avoid deeply nested conditionals - extract to named templates

## Values Examples

### Good: Calculated Values
```yaml
# values.yaml - minimal, only user inputs
image:
  repository: nginx
  tag: "1.21"

# Template calculates derived values
resources:
  requests:
    memory: {{ .Values.resources.memory | default "128Mi" }}
  limits:
    memory: {{ .Values.resources.memory | default "128Mi" | multiply 2 }}
```

### Good: Sensible Defaults
```yaml
# values.yaml
replicaCount: 3  # Production-ready default
image:
  pullPolicy: IfNotPresent  # Safe default
service:
  type: ClusterIP  # Kubernetes default
```

### Good: Override-Friendly Structure
```yaml
# values.yaml
app:
  name: myapp
  version: "1.0.0"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  host: example.com
```

## Multi-Environment Parity

### Principle

The same Helm charts must work across all environments: Docker Desktop (local), development EKS, staging, and production. Environment-specific configurations are provided through values file inheritance, not chart duplication.

### Values File Inheritance Strategy

**Base Configuration (`values.yaml`):**
- Contains sensible defaults that work across environments
- Defines base structure and common configurations
- Documents all configurable values

**Environment-Specific Overrides:**
- `values-local.yaml` - Docker Desktop / local development
- `values-development.yaml` - Development EKS environment
- `values-staging.yaml` - Staging environment
- `values-production.yaml` - Production environment

**Inheritance Pattern:**
```bash
# Base values
helm install myapp . -f values.yaml

# With environment override
helm install myapp . -f values.yaml -f values-development.yaml
```

**Override Behavior:**
- Environment files override base values, don't replace them
- Use Helm's `-f` flag ordering: later files override earlier ones
- Only specify differences in environment files
- Don't duplicate base configuration in environment files

### Local Development Pattern

**Infrastructure-Only Mode:**
- Deploy infrastructure (PostgreSQL, Redis, Ingress) to cluster
- Run applications on host for hot-reload during development
- Use `values-infra-only.yaml` or similar for infrastructure deployment

**Service Configuration:**
```yaml
# values-infra-only.yaml
backoffice:
  enabled: true
  replicas: 0  # Don't deploy to cluster
  service:
    enabled: false  # No service needed
  ingress:
    enabled: false  # No ingress needed
```

### Environment-Specific Values

**Service Types:**
- **Local**: NodePort for direct host access
- **Cloud**: ClusterIP for internal cluster communication

**Image Configuration:**
- **Local**: Empty registry (uses local images)
- **Cloud**: ECR registry with environment-specific tags

**Resource Limits:**
- **Local**: Lower limits for development machines
- **Cloud**: Production-appropriate limits

**Example Override:**
```yaml
# values-development.yaml (overrides base)
global:
  registry: "[account].dkr.ecr.[region].amazonaws.com"
  imageTag: "development"

service:
  type: ClusterIP  # Override NodePort from base

resources:
  requests:
    memory: "256Mi"  # Override base defaults
```

### Benefits

- **Consistency**: Same chart logic across all environments
- **Maintainability**: Fix bugs once, works everywhere
- **Testing**: Test charts locally before deploying to cloud
- **Simplicity**: Environment files only contain differences

## Anti-Patterns
- Asking users for values that can be calculated (e.g., both requests and limits)
- Hardcoding values in templates that should be configurable
- Providing no defaults, requiring users to specify everything
- Complex, deeply nested value structures that are hard to override
- Missing documentation in `values.yaml` making charts hard to use
- Using custom template logic when built-in functions would suffice
- Creating templates that are too clever at the expense of readability
- Not validating required values, leading to cryptic Kubernetes errors
- Mixing application-specific values with chart defaults
- **Duplicating chart logic for different environments** - use values inheritance instead
- **Creating separate charts per environment** - use values files for environment differences
- **Hardcoding environment-specific values in templates** - use values with defaults

## Rationale
The "smallest possible values.yaml" philosophy reduces cognitive load for chart users while maintaining flexibility. By calculating derived values in templates and providing sensible defaults, charts become easier to use and less error-prone. Template validation using `fail` and `required` functions provides runtime validation, while schema validation (when implemented) can catch configuration errors even earlier. Clear documentation and override-friendly structure enable users to customize charts for their specific needs without understanding internal template logic. This approach balances ease of use with power and flexibility.

Multi-environment parity ensures that charts work consistently across all environments, reducing operational overhead and enabling local testing of cloud configurations. Values file inheritance allows environment-specific customization without duplicating chart logic, maintaining the DRY principle while supporting diverse deployment scenarios.

