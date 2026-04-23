# Rule: Generic DRY Secrets Management Pattern

## Checklist
- Use two-pattern approach: local pattern for development, cloud pattern for cloud environments
- Local pattern: `secret:` dictionary (1 line per secret) → generates `secretKeyRef` structures
- Cloud pattern: `externalSecretsKey:` (1 line total) → injects all keys from cloud secrets manager via `envFrom`
- Never duplicate secret declarations - use single source pattern
- Automate secret management with task commands (`add-secret`, `remove-secret`)
- Cloud environments: Adding/removing secrets only requires cloud secrets manager updates (no values.yaml changes)
- Use standalone Helm templates for local pattern, External Secrets Operator for cloud pattern
- Integrate with any cloud provider (AWS, GCP, Azure, etc.) via External Secrets Operator

## Overview

The DRY secrets management pattern eliminates duplication by using a single-source approach for secret declarations. Two complementary patterns support different environments: a local pattern for development and a cloud pattern for cloud deployments.

**Related Rules:**
- See `external_secrets_operator.md` for External Secrets Operator integration patterns
- See `helm_packaging.md` for general Helm packaging principles

## Two-Pattern Approach

### Pattern 1: Local Development (secret: dictionary)

**Use Case**: Local development environments (Docker Desktop, minikube, kind)

**Values Declaration:**
```yaml
# values.yaml or values-local.yaml
secret:
  DATABASE_URL: "database-url-key"
  API_KEY: "api-key-key"
  JWT_SECRET: "jwt-secret-key"
```

**How It Works:**
- `secret:` dictionary maps environment variable names to secret key names
- Standalone Helm template generates `valueFrom.secretKeyRef` structures
- Secrets are stored in Kubernetes Secrets (created manually or via tools)

**Generated Output:**
```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: [service-name]
        key: database-url-key
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: [service-name]
        key: api-key-key
  - name: JWT_SECRET
    valueFrom:
      secretKeyRef:
        name: [service-name]
        key: jwt-secret-key
```

### Pattern 2: Cloud Environments (externalSecretsKey:)

**Use Case**: Cloud environments (EKS, GKE, AKS) with cloud secrets manager integration

**Values Declaration:**
```yaml
# values-production.yaml
externalSecretsKey: "backoffice"
```

**How It Works:**
- Single `externalSecretsKey:` value points to secret path in cloud secrets manager
- External Secrets Operator syncs secret from cloud to Kubernetes
- Standalone Helm template injects all keys automatically via `envFrom`
- All keys from the cloud secret become environment variables

**Generated Resources:**

**ExternalSecret Resource:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: [service-name]
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: cluster-secret-store
  refreshInterval: "1m"
  target:
    name: [service-name]
    deletionPolicy: Delete
  dataFrom:
    - extract:
        key: [externalSecretsKey-path]
```

**Pod Environment Injection:**
```yaml
envFrom:
  - secretRef:
      name: [service-name]
```

**Result**: All keys from the cloud secret are automatically available as environment variables in the pod.

## Standalone Helm Templates

### Template 1: Local Secret Pattern

**File:** `templates/secrets-local.yaml`

```yaml
{{- if .Values.secret }}
{{- $secretName := .Values.secretName | default (include "chart.fullname" .) }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ $secretName }}
type: Opaque
data:
  {{- range $key, $value := .Values.secret }}
  {{ $key }}: {{ $value | b64enc | quote }}
  {{- end }}
{{- end }}
```

**File:** `templates/env-local.yaml`

```yaml
{{- if .Values.secret }}
{{- $secretName := .Values.secretName | default (include "chart.fullname" .) }}
{{- $env := list }}
{{- range $key, $value := .Values.secret }}
{{- $env = append $env (dict "name" $key "valueFrom" (dict "secretKeyRef" (dict "name" $secretName "key" $value))) }}
{{- end }}
env:
{{- range $env }}
  - name: {{ .name }}
    valueFrom:
      secretKeyRef:
        name: {{ .valueFrom.secretKeyRef.name }}
        key: {{ .valueFrom.secretKeyRef.key }}
{{- end }}
{{- end }}
```

### Template 2: Cloud Secret Pattern

**File:** `templates/external-secret.yaml`

```yaml
{{- if .Values.externalSecretsKey }}
{{- $secretName := .Values.secretName | default (include "chart.fullname" .) }}
{{- $secretStoreName := .Values.secretStoreName | default "cluster-secret-store" }}
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ $secretName }}
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: {{ $secretStoreName }}
  refreshInterval: {{ .Values.secretRefreshInterval | default "1m" }}
  target:
    name: {{ $secretName }}
    deletionPolicy: Delete
  dataFrom:
    - extract:
        key: {{ .Values.externalSecretsKey }}
{{- end }}
```

**File:** `templates/env-cloud.yaml`

```yaml
{{- if .Values.externalSecretsKey }}
{{- $secretName := .Values.secretName | default (include "chart.fullname" .) }}
envFrom:
  - secretRef:
      name: {{ $secretName }}
{{- end }}
```

## Integration Examples

### Example 1: Local Development Setup

**values-local.yaml:**
```yaml
secret:
  DATABASE_URL: "database-url-key"
  API_KEY: "api-key-key"
  JWT_SECRET: "jwt-secret-key"
```

**Manual Secret Creation:**
```bash
kubectl create secret generic myapp-secret \
  --from-literal=database-url-key="postgresql://localhost:5432/mydb" \
  --from-literal=api-key-key="sk-1234567890abcdef" \
  --from-literal=jwt-secret-key="your-jwt-secret-key"
```

### Example 2: Cloud Environment Setup

**values-production.yaml:**
```yaml
externalSecretsKey: "backoffice"
secretStoreName: "aws-secrets-store"
secretRefreshInterval: "5m"
```

**ExternalSecret Store Configuration:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-store
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
            namespace: external-secrets
```

### Example 3: Multi-Environment Configuration

**values.yaml (base):**
```yaml
# Common configuration
image:
  repository: myapp
  tag: "1.0.0"

# Environment-specific secrets will be overridden
```

**values-local.yaml:**
```yaml
secret:
  DATABASE_URL: "database-url-key"
  API_KEY: "api-key-key"
```

**values-production.yaml:**
```yaml
externalSecretsKey: "backoffice"
secretStoreName: "aws-secrets-store"
```

## Best Practices

### Security Considerations
- Never commit actual secret values to version control
- Use different secret stores for different environments
- Rotate secrets regularly using cloud provider tools
- Apply least-privilege access to secret stores

### Environment Management
- Use separate values files for each environment
- Maintain clear separation between local and cloud patterns
- Document secret naming conventions for consistency
- Use environment-specific secret store configurations

### Template Management
- Keep templates simple and readable
- Use meaningful variable names
- Include comments explaining complex logic
- Test templates with different input combinations

### Integration Patterns
- Combine with External Secrets Operator for cloud environments
- Use manual secrets for local development
- Support hybrid environments with both patterns
- Ensure templates work with any cloud provider

## Anti-Patterns

### Common Mistakes
- Duplicating secret declarations across environments
- Mixing local and cloud patterns in the same deployment
- Hardcoding secret values in templates or values files
- Using the same secret keys across different environments
- Skipping secret validation and testing

### Template Anti-Patterns
- Creating overly complex template logic
- Using template functions that obscure secret flow
- Mixing secret management with other configuration
- Creating templates that depend on external helpers
- Ignoring error handling for missing secrets

## Rationale

The DRY secrets management pattern provides a clean, maintainable approach to handling secrets across different environments while eliminating duplication. The two-pattern approach allows teams to use simple manual secrets for local development and robust cloud-native secret management for production deployments, all while maintaining consistent configuration patterns.

**Integration Benefits:**
- Works with any cloud provider (AWS, GCP, Azure, etc.)
- Integrates seamlessly with External Secrets Operator
- Supports both manual and automated secret management
- Maintains consistency across environments
- Reduces configuration complexity and duplication

**Universal Applicability:**
- Generic patterns work with any Kubernetes setup
- Standalone templates require no external dependencies
- Cloud integration works with any provider
- Local development pattern works with any local cluster
- Templates can be adapted to any Helm chart structure