# Rule: Generic Crossplane Compositions

## Checklist
- Use Crossplane Compositions to define reusable infrastructure patterns
- Create Composition resources that abstract cloud provider specifics
- Define CompositeResourceDefinitions (XRDs) to create custom resource types
- Use Composition Functions or Patch and Transform (P&T) for resource composition
- Store Composition and XRD manifests in Git, version-controlled with application code
- Use Composition to create resources from unified definitions across any cloud provider
- Leverage Crossplane Providers for cloud resource management (AWS, GCP, Azure, etc.)
- Use Composition Functions for complex transformations and validations
- Define input schemas in XRD `spec.versions[].schema.openAPIV3Schema` for validation
- Test Compositions in non-production environments before applying to production

## Composition Structure

### CompositeResourceDefinition (XRD)
- Define custom resource API that applications will use
- Specify `spec.group` and `spec.names` for the custom resource kind
- Define `spec.versions[].schema` with OpenAPI schema for input validation
- Use `spec.claimNames` to create claim-based resources (optional)
- Document required and optional fields in schema descriptions

### Composition Resource
- Reference XRD via `spec.compositeTypeRef.apiVersion` and `kind`
- Define `spec.resources` array with base resources and patches
- Use `spec.patchSets` to reuse common patch patterns
- Configure `spec.writeConnectionSecretsToRef` for credential management
- Use `spec.environment` for environment-specific configurations

## Generic Resource Composition Patterns

### Base Resources
- Define base resources in `spec.resources[].base` using provider-specific APIs
- Use generic provider resources: `provider.example.com/ResourceType`
- Reference provider credentials via `spec.resources[].base.spec.providerConfigRef`
- Maintain provider-agnostic resource definitions

### Patch and Transform (P&T)
- Use `spec.resources[].patches` to map XRD input to base resource fields
- Apply patches using `FromFieldPath`, `ToFieldPath`, and `Transforms`
- Use transform functions: `string`, `convert`, `math`, `map`, `stringToJson`
- Chain multiple transforms for complex field mappings
- Use `spec.resources[].patches[].policy` to control patch behavior (Merge, Replace)

### Composition Functions
- Use Functions for complex logic that P&T cannot handle
- Package Functions as OCI images and reference in `spec.functionPipeline`
- Use Functions for multi-step transformations, validations, and external API calls
- Chain Functions in pipeline for sequential processing
- Document Function behavior and required inputs

## Generic Multi-Cloud Abstraction

### Unified API Approach
- Create XRD that abstracts cloud provider differences
- Use Composition to map unified API to provider-specific resources
- Use environment or label-based selection to choose provider resources
- Leverage `spec.resources[].patches[].transforms` to handle provider differences

### Provider-Agnostic Compositions
- Create generic Compositions that work with any provider
- Use same XRD but different Composition resources per provider
- Select Composition via `spec.compositionRef` or `spec.compositionSelector`
- Document provider-specific limitations and capabilities

### Generic Resource Patterns
- Use placeholder provider resources: `provider.example.com/ResourceType`
- Configure `spec.resources[].base` with generic fields:
  - Region, environment, instance types
  - Generic configuration parameters
  - Provider-agnostic settings
- Map XRD inputs to generic resource specifications
- Use provider credentials via `providerConfigRef`

## Generic Input Schema Design

### Provider-Agnostic Schema
- Define clear, provider-agnostic input schema in XRD
- Use descriptive field names that don't expose cloud provider specifics
- Mark required fields with `required: ["fieldName"]` in schema
- Provide default values where appropriate in Composition patches
- Use schema validation to catch errors before resource creation

### Universal Field Design
```yaml
spec:
  versions:
  - name: v1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              provider:
                type: string
                enum: ["aws", "gcp", "azure", "generic"]
                description: "Cloud provider for resource deployment"
              region:
                type: string
                description: "Deployment region"
              environment:
                type: string
                enum: ["development", "staging", "production"]
                description: "Target environment"
              size:
                type: string
                enum: ["small", "medium", "large"]
                description: "Resource size specification"
```

## Generic Credential Management

### Universal Credential Patterns
- Store provider credentials in Kubernetes Secrets
- Reference credentials via `ProviderConfig` resources, not inline in Compositions
- Use `spec.writeConnectionSecretsToRef` to expose connection details
- Never hardcode credentials in Composition or XRD manifests
- Rotate credentials regularly and update ProviderConfig references

### Provider-Agnostic Secret Management
- Use cloud-native secret managers for credential storage
- Integrate with External Secrets Operator for secret synchronization
- Maintain separate credentials for different environments
- Apply least-privilege access to credential resources

## Standalone Generic Examples

### Example 1: Generic XRD Structure

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: genericinfrastructure.example.com
spec:
  group: example.com
  names:
    kind: GenericInfrastructure
    plural: genericinfrastructures
  claimNames:
    kind: GenericInfrastructureClaim
    plural: genericinfrastructureclaims
  versions:
  - name: v1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              provider:
                type: string
                description: "Cloud provider (aws, gcp, azure, generic)"
              region:
                type: string
                description: "Deployment region"
              environment:
                type: string
                description: "Target environment"
              size:
                type: string
                enum: ["small", "medium", "large"]
                description: "Resource size specification"
            required:
            - provider
            - region
```

### Example 2: Generic Composition Structure

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: genericinfrastructure.example.com
  labels:
    provider: generic
    crossplane.io/managed-by: "crossplane"
spec:
  compositeTypeRef:
    apiVersion: example.com
    kind: GenericInfrastructure
  resources:
  - name: generic-resource
    base:
      apiVersion: provider.example.com/v1
      kind: GenericResource
      spec:
        # Generic provider-agnostic configuration
        region: {{ .spec.region }}
        size: {{ .spec.size }}
        environment: {{ .spec.environment }}
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.provider
      toFieldPath: spec.provider
    - type: FromCompositeFieldPath
      fromFieldPath: spec.region
      toFieldPath: spec.region
    - type: FromCompositeFieldPath
      fromFieldPath: spec.size
      toFieldPath: spec.size
    connectionDetails:
    - name: connection-secret
      type: FromCompositeFieldPath
      fromFieldPath: spec.connectionSecretName
```

### Example 3: Multi-Provider Composition

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: genericinfrastructure.example.com
spec:
  compositeTypeRef:
    apiVersion: example.com
    kind: GenericInfrastructure
  resources:
  - name: aws-resource
    base:
      apiVersion: ec2.aws.crossplane.io/v1
      kind: VPC
      spec:
        region: {{ .spec.region }}
        forProvider:
          cidrBlock: "10.0.0.0/16"
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.provider
      toFieldPath: spec.provider
    conditions:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.provider
      toFieldPath: status.atProvider.provider
      when: "aws"
  - name: gcp-resource
    base:
      apiVersion: compute.gcp.crossplane.io/v1
      kind: Network
      spec:
        forProvider:
          name: {{ .spec.name }}-network
          autoCreateSubnetworks: false
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.provider
      toFieldPath: spec.provider
    conditions:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.provider
      toFieldPath: status.atProvider.provider
      when: "gcp"
```

## Integration Examples

### Example 1: Integration with External Secrets

```yaml
# In Composition resource
spec:
  writeConnectionSecretToRef:
    namespace: crossplane-system
    name: {{ .spec.name }}-connection
  resources:
  - name: generic-resource
    base:
      apiVersion: provider.example.com/v1
      kind: GenericResource
      spec:
        # Generic configuration
        region: {{ .spec.region }}
        credentials:
          secretRef:
            name: {{ .spec.credentialsSecret }}
            namespace: {{ .spec.credentialsNamespace }}
```

### Example 2: Multi-Environment Configuration

```yaml
# Development environment
apiVersion: example.com/v1
kind: GenericInfrastructure
metadata:
  name: dev-infrastructure
  namespace: development
spec:
  provider: aws
  region: us-east-1
  environment: development
  size: small
  credentialsSecret: dev-credentials

---
# Production environment
apiVersion: example.com/v1
kind: GenericInfrastructure
metadata:
  name: prod-infrastructure
  namespace: production
spec:
  provider: gcp
  region: us-central1
  environment: production
  size: large
  credentialsSecret: prod-credentials
```

## Generic Best Practices

### Composition Design
- Keep Compositions focused on a single infrastructure pattern or use case
- Use meaningful names for XRD resources that reflect their purpose
- Version Compositions and XRDs independently using Git tags
- Document Composition behavior, required inputs, and created resources
- Use `spec.resources[].patches[].transforms` for data type conversions
- Leverage `spec.patchSets` to reduce duplication across Compositions

### Schema Design
- Use provider-agnostic field names that don't expose cloud specifics
- Provide clear descriptions for all schema fields
- Include validation patterns for common input errors
- Use enum types for constrained choices (provider, environment, size)
- Document field purposes and constraints

### Multi-Cloud Patterns
- Design XRDs that work with any provider
- Use conditional logic in Compositions for provider-specific behavior
- Maintain separate Compositions for significantly different provider patterns
- Document provider-specific limitations and capabilities
- Test Compositions against multiple providers

## Generic Anti-Patterns

### Common Mistakes
- Creating Compositions that are too generic or try to handle all use cases
- Hardcoding cloud provider-specific values in Compositions
- Storing credentials inline in Composition manifests
- Skipping input validation in XRD schemas
- Creating Compositions without testing provider connectivity
- Mixing application code and Composition manifests without clear organization

### Schema Anti-Patterns
- Creating XRDs without proper OpenAPI schema validation
- Using provider-specific field names in schemas
- Skipping required field validation
- Not documenting field purposes and constraints
- Creating overly complex schemas that are hard to use

### Composition Anti-Patterns
- Ignoring Crossplane provider version compatibility
- Creating Compositions without proper error handling
- Not testing Compositions in development environments
- Mixing provider-specific and generic logic without clear separation
- Not documenting Composition behavior and requirements

## Generic Rationale

Crossplane Compositions enable infrastructure as code patterns that abstract cloud provider specifics while maintaining the flexibility to leverage provider-specific features. Using generic Compositions allows teams to define infrastructure patterns once and deploy them across any cloud provider. This approach promotes consistency, reduces duplication, and enables GitOps workflows where infrastructure changes are version-controlled and reviewed like application code.

**Universal Benefits:**
- Works with any cloud provider (AWS, GCP, Azure, etc.)
- Maintains consistent infrastructure patterns across providers
- Enables multi-cloud strategies without code duplication
- Supports GitOps workflows with version-controlled infrastructure
- Reduces provider lock-in through abstraction layers

**Integration Advantages:**
- Integrates with External Secrets Operator for credential management
- Works with any Crossplane provider and version
- Supports both simple and complex infrastructure patterns
- Enables testing and validation across multiple providers
- Maintains backward compatibility with existing Crossplane setups