# External Secrets Operator

**Rule Overview**: Using External Secrets Operator CRD for managing Kubernetes secrets from external secret stores (AWS Secrets Manager, HashiCorp Vault, etc.) in GitOps workflows.

**Rationale**: Secure credential management, automatic secret rotation, GitOps-friendly secret distribution, no secrets in Git history.

## Core Patterns

### ExternalSecret CRD Structure

**Rule**: Use ExternalSecret CRD with proper spec configuration for secret synchronization

**Rationale**: Standardized secret management, automatic refresh, ownership control

**Implementation**:
```yaml
# templates/externalSecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "chart.name" . }}
spec:
  refreshInterval: 10m
  secretStoreRef:
    name: {{ .Values.secretStore.name }}
    kind: {{ .Values.secretStore.kind | default "ClusterSecretStore" }}
  target:
    name: {{ include "chart.name" . }}
    creationPolicy: Owner
  data:
    {{- toYaml .Values.data | nindent 4 }}
  dataFrom:
    {{- toYaml .Values.dataFrom | nindent 4 }}
```

**Reference**: @example:devops/external_secret_manifest.md

### Secret Store Configuration

**Rule**: Configure secret store reference (ClusterSecretStore or SecretStore) with proper kind

**Rationale**: Multi-tenancy support, correct store type selection

**Implementation**:
```yaml
# values.yaml
secretStore:
  name: aws-secrets-manager
  kind: SecretStore
```

**Reference**: @rule:devops/external_secrets_operator.md

### Data Mapping Pattern

**Rule**: Use `data` field for static key-value pairs and `dataFrom` for dynamic references

**Rationale**: Flexibility for different secret types, reusability, separation of concerns

**Implementation**:
```yaml
# templates/externalSecret.yaml
# Static data
data:
  - secretKey: DATABASE_URL
    remoteRef:
      key: infra-database
      property: connection-url

# Dynamic data from other secret
dataFrom:
  - secretRef:
      name: postgres-credentials
      key: db-password
```

**Reference**: @example:devops/external_secret_manifest.md

### Refresh Interval Configuration

**Rule**: Set appropriate refresh intervals based on secret sensitivity and update frequency

**Rationale**: Balance between performance and consistency, timely updates

**Implementation**:
```yaml
# High-frequency secrets (e.g., API keys)
refreshInterval: 1m

# Medium-frequency secrets (e.g., database passwords)
refreshInterval: 10m

# Low-frequency secrets (e.g., long-lived certificates)
refreshInterval: 1h
```

---

## Security Patterns

### Target Secret Creation Policy

**Rule**: Use `creationPolicy: Owner` to ensure the chart/namespace owns the secret

**Rationale**: Access control, lifecycle management, prevent conflicts

**Implementation**:
```yaml
# templates/externalSecret.yaml
spec:
  target:
    creationPolicy: Owner
```

**Reference**: @example:devops/external_secret_manifest.md

### Secret Rotation

**Rule**: Configure automatic secret rotation via external secret store capabilities

**Rationale**: Security compliance, credential lifecycle management

**Implementation**:
```yaml
# External Secrets Manager configuration (AWS Secrets Manager)
# This is configured at the secret store level, not in the chart

# Store rotation settings in secret store
```

### Exclusion Patterns

**Rule**: Exclude template files from secret synchronization

**Rationale**: Prevent unnecessary secret creation, reduce noise

**Implementation**:
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    hooks:
      - id: sqlfluff-lint
        exclude: ^(cli/resources/templates)/
```

**Reference**: @example:devops/dbt_pre_commit_config.md

---

## Common Patterns

### Multiple Secrets in Single ExternalSecret

**Rule**: Use `data` field for multiple key-value pairs and `dataFrom` for references

**Rationale**: Reduced resource count, logical grouping, efficient synchronization

**Implementation**:
```yaml
# templates/externalSecret.yaml
spec:
  data:
    - secretKey: db_password
      remoteRef:
        key: postgres-credentials
        property: password
    - secretKey: api_key
      remoteRef:
        key: api-credentials
        property: key

    - secretKey: tls_cert
      remoteRef:
        key: tls-certificates
        property: certificate
```

**Reference**: @example:devops/external_secret_manifest.md

### Secret Naming Conventions

**Rule**: Use consistent naming: `{chart-name}-secret` or descriptive names

**Rationale**: Discoverability, ownership, conflict prevention

**Implementation**:
```yaml
# values.yaml
externalSecrets:
  - name: airflow-backend
    secretStoreRef:
      name: secret-store
```

**Reference**: @example:devops/external_secret_manifest.md

---

## Testing and Validation

### Secret Verification

**Rule**: Use `kubectl get secret` and `kubectl describe secret` to verify secret creation

**Rationale**: Debug deployment, verify secret propagation, troubleshoot issues

**Implementation**:
```bash
# Check secret exists
kubectl get secret airflow-backend -n airflow-prod

# Describe secret details
kubectl describe secret airflow-backend -n airflow-prod
```

### ExternalSecret Status

**Rule**: Monitor ExternalSecret status with `kubectl get externalsecret` and `kubectl describe externalsecret`

**Rationale**: Verify secret synchronization, check for errors, ensure refresh working

**Implementation**:
```bash
# List ExternalSecrets in namespace
kubectl get externalsecret -n airflow-prod

# Describe specific ExternalSecret
kubectl describe externalsecret airflow-backend -n airflow-prod
```

**Reference**: @rule:devops/external_secrets_operator.md

---

## Troubleshooting

### Secret Not Syncing

**Rule**: Check ExternalSecret resource status and refresh interval configuration

**Rationale**: Debug synchronization issues, verify configuration

**Implementation**:
```bash
# Check if secret is ready
kubectl get externalsecret airflow-backend -n airflow-prod -o jsonpath='{.status.conditions[?(@.type=="Ready")].reason}'

# Force refresh if needed
kubectl annotate externalsecret airflow-backend -n airflow-prod force-sync=true --overwrite=true

# Check operator logs
kubectl logs -n external-secrets-operator -l external-secrets-operator-xxx
```

### Secret Not Created

**Rule**: Check ExternalSecret creation events in operator logs and Kubernetes events

**Rationale**: Troubleshoot creation failures, verify secret store connectivity

**Implementation**:
```bash
# Check ExternalSecret operator events
kubectl get events -n airflow-prod --field-selector involvedObject.kind=ExternalSecret

# Check operator pod logs
kubectl logs -n external-secrets-operator -l external-secrets-operator-xxx --tail=100
```

### Secret Access Issues

**Rule**: Verify RBAC permissions for ExternalSecret operator and pods

**Rationale**: Access control, security compliance, permission troubleshooting

**Implementation**:
```bash
# Check operator service account permissions
kubectl get sa -n external-secrets-operator
kubectl describe sa external-secrets-operator -n external-secrets-operator
```

---

## Contributing to Team Knowledge Base

### Proposed New Rules
1. **Secret Store Configuration** - Proper store reference and kind selection
2. **Data Mapping Patterns** - Static vs dynamic secret references
3. **Refresh Interval Tuning** - Performance vs consistency trade-offs
4. **Creation Policy Management** - Using Owner policy for proper lifecycle

### Proposed New Examples
1. **Complete ExternalSecret Manifest** - Full CRD with data and dataFrom
2. **Multiple Secrets Pattern** - Managing several secrets in one resource
3. **Secret Verification Commands** - kubectl commands for troubleshooting

When contributing these back to the repository, follow the guidelines in @CONTRIBUTING.md and use the /levelup process for formalizing new patterns.

---

## Tool Context

- **external-secrets-operator**: Kubernetes operator for secret management
- **kubectl**: Kubernetes CLI for cluster operations
- **aws-secrets-manager**: AWS secret store
- **hashicorp-vault**: HashiCorp Vault for secret storage
- **vault**: HashiCorp Vault CLI

**Rule References**:
- **ExternalSecret Operator**: @rule:devops/external_secrets_operator.md
- **Wrapper Charts**: @rule:devops/helm_wrapper_charts.md
- **External Secret Manifest**: @example:devops/external_secret_manifest.md
- **GKE Workload Identity**: @rule:devops/gke_workload_identity.md

**Example References**:
- **ExternalSecret Manifest**: @example:devops/external_secret_manifest.md
- **Secret Verification**: Example commands in rule documentation
