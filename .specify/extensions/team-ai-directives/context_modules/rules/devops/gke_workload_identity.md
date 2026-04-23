# GKE Workload Identity

**Rule Overview**: Using Google Kubernetes Workload Identity for secure GCP authentication without long-lived service account keys in data platform workloads.

**Rationale**: Eliminates need for GCP service account keys, follows security best practices, enables automatic credential rotation, GitOps-friendly.

## Core Patterns

### Service Account Annotation

**Rule**: Annotate Kubernetes ServiceAccounts with Workload Identity for GCP authentication

**Rationale**: Maps KSA to Google Service Account, automatic token management, keyless authentication

**Implementation**:
```yaml
# ServiceAccount annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: airflow-workers
  annotations:
    iam.gke.io/gcp-service-account: my-workflow-sa@project-id.iam.gserviceaccount.com

# Pod service account reference
apiVersion: v1
kind: Pod
metadata:
  name: airflow-worker-xyz
  spec:
    serviceAccountName: airflow-workers
```

**Reference**: @rule:devops/gke_workload_identity.md

### Workload Identity Usage

**Rule**: Use `iam.gke.io/gcp-service-account` annotation on ServiceAccounts and IAM binding for GKE pods

**Rationale**: Secure authentication, no manual key management, automatic token renewal

**Implementation**:
```yaml
# values.yaml
airflow:
  workers:
    serviceAccount:
      create: true
      annotations:
        iam.gke.io/gcp-service-account: "{{ .Values.airflow.serviceAccount.googleEmail }}"
```

**Reference**: @example:devops/gke_workload_identity.md

### IAM Bindings

**Rule**: Create IAM bindings between ServiceAccounts and Google Cloud resources with principle of least privilege

**Rationale**: Security, compliance, minimal access, auditability

**Implementation**:
```yaml
# Terraform resource
resource "google_project_iam_binding" "airflow_sa_bigquery_user" {
  project = var.gcp_project_id
  role    = "roles/bigquery.user"

  members = [
    "serviceAccount:${var.airflow_service_account_email}"
  ]
}
```

**Reference**: @example:devops/gke_workload_identity.md

### Workload Identity Token Source

**Rule**: Configure workload identity token source from environment variables or secret management

**Rationale**: Flexibility, security, GitOps-friendly credential injection

**Implementation**:
```yaml
# values.yaml
airflow:
  workloadIdentity:
    enabled: true

# Or via annotation on ServiceAccount
metadata:
  annotations:
    iam.gke.io/gcp-service-account: "{{ .Values.airflow.serviceAccount.googleEmail }}"
    gke.io/gcp-service-account: "{{ .Values.airflow.serviceAccount.googleEmail }}"
```

**Reference**: @example:devops/gke_workload_identity.md

---

## Common Patterns

### Namespace Scoping

**Rule**: Use namespace-scoped Workload Identity resources for multi-tenant clusters

**Rationale**: Tenant isolation, resource boundaries, access control

**Implementation**:
```yaml
# Namespace-specific Workload Identity
apiVersion: iam.cnrm.cloud.google.com/v1
kind: WorkloadIdentityPool
metadata:
  name: airflow-workload-identity
  namespace: airflow-prod
spec:
  location: "us-central1"
  workloadIdentityPools:
    - projectNumber: "{{ .Values.gcp.project_id }}"
      pool: airflow-pool
      provider: "gke"
```

**Reference**: @example:devops/gke_workload_identity.md

### Multi-Cluster Support

**Rule**: Configure Workload Identity for multiple GKE clusters with consistent configuration

**Rationale**: Consistency across environments, simplified configuration, easier management

**Implementation**:
```yaml
# values.yaml
workloadIdentity:
  gke:
    clusters:
      - name: cluster-1
        location: us-central1
      - name: cluster-2
        location: us-east1
```

**Reference**: @example:devops/gke_workload_identity.md

---

## Security Patterns

### Principle of Least Privilege

**Rule**: Use minimal IAM roles for Workload Identity (e.g., `roles/storage.objectAdmin` instead of `roles/editor`)

**Rationale**: Security, compliance, reduced attack surface, audit trail

**Implementation**:
```yaml
# BigQuery Data Editor role
resource "google_project_iam_binding" "airflow_bigquery_editor" {
  project = var.gcp_project_id
  role    = "roles/bigquery.dataEditor"

  members = [
    "serviceAccount:${var.airflow_service_account_email}"
  ]
}
```

### Service Account Key Management

**Rule**: Avoid creating GCP service account keys, use Workload Identity for all authentication

**Rationale**: Security, credential rotation, simplified operations

**Implementation**:
```yaml
# DO NOT DO THIS - Avoid key-based authentication
# google_service_account_key resource
resource "google_service_account_key" "airflow_key" {
  service_account_id = google_service_account.airflow.id
  public_key_type    = "RSA_X509_PEM"
}

# INSTEAD DO THIS - Use Workload Identity
# Pod annotation for Workload Identity
metadata:
  annotations:
    iam.gke.io/gcp-service-account: "my-workflow-sa@project-id.iam.gserviceaccount.com"
```

**Reference**: @example:devops/gke_workload_identity.md

### Audit Logging

**Rule**: Enable Cloud Audit Logs for GKE workloads with Workload Identity

**Rationale**: Security monitoring, compliance, troubleshooting, forensic analysis

**Implementation**:
```yaml
# values.yaml
airflow:
  workers:
    serviceAccount:
      create: true
      annotations:
        # Enable Cloud Audit Logs
        iam.gke.io/gcp-service-account: "{{ .Values.airflow.serviceAccount.googleEmail }}"
        gke.io/gcp-service-account: "{{ .Values.airflow.serviceAccount.googleEmail }}"

# Terraform
resource "google_project_iam_audit_config" "airflow_audit" {
  project = var.gcp_project_id
  service = cloudresourcemanager.googleapis.com
  log_type = DATA_ACCESS

  dataset = {
    project_id = var.gcp_project_id
    table_name = "airflow_audit_logs"
  }
}
```

---

## Common Patterns

### Workload Identity for Multiple Pods

**Rule**: Reuse ServiceAccount annotations across multiple pods for consistent authentication

**Rationale**: Efficient resource usage, consistent authentication, simplified configuration

**Implementation**:
```yaml
# Multiple pods sharing ServiceAccount
apiVersion: v1
kind: PodList
items:
  - metadata:
      name: airflow-worker-1
      annotations:
        iam.gke.io/gcp-service-account: "{{ .Values.airflow.serviceAccount.googleEmail }}"
  - metadata:
      name: airflow-worker-2
      annotations:
        iam.gke.io/gcp-service-account: "{{ .Values.airflow.serviceAccount.googleEmail }}"
```

**Reference**: @example:devops/gke_workload_identity.md

### Cross-Account Workload Identity

**Rule**: Use Workload Identity pools when pods need access to multiple projects

**Rationale**: Cross-project access without managing multiple ServiceAccounts

**Implementation**:
```yaml
# WorkloadIdentityPool
apiVersion: iam.cnrm.cloud.google.com/v1
kind: WorkloadIdentityPool
metadata:
  name: shared-workload-pools
spec:
  workloadIdentityPools:
    - projectNumber: "{{ .Values.gcp.project_id }}"
      pool: shared-pool
    - projectNumber: "another-project-id"
      pool: another-pool
```

**Reference**: @example:devops/gke_workload_identity.md

---

## Testing and Validation

### Workload Identity Verification

**Rule**: Verify Workload Identity tokens are being issued and renewed properly

**Rationale**: Ensure authentication working, debug token issues, monitor expiry

**Implementation**:
```bash
# Check GSA Workload Identity membership
gcloud iam service-accounts get-iam-policy --format=json | jq '.bindings[] | select(.[].[] == "serviceAccount:my-workflow-sa@project-id.iam.gserviceaccount.com")'

# Check WorkloadIdentityPool configuration
kubectl get workloadidentitypools -A jsonpath='{.items[?(@.spec.workloadIdentityPools[?(@.pool=="shared-pool")].status)]}'
```

**Reference**: @example:devops/gke_workload_identity.md

---

## Troubleshooting

### Workload Identity Not Working

**Rule**: Check pod events and logs for Workload Identity token acquisition failures

**Rationale**: Debug authentication issues, verify IAM configuration, check network connectivity

**Implementation**:
```bash
# Check pod events for Workload Identity issues
kubectl get events -n airflow-prod --field-selector involvedObject.kind=WorkloadIdentity

# Check service account status
gcloud iam service-accounts get-iam-policy --format=json

# Verify WorkloadIdentityPool configuration
kubectl get workloadidentitypools -A jsonpath='{.items[?(@.spec.workloadIdentityPools[?(@.pool=="shared-pool")].status)]}'
```

### Token Acquisition Delays

**Rule**: Monitor token issuance frequency and check for unusual delays

**Rationale**: Performance monitoring, early issue detection, SLA tracking

**Implementation**:
```bash
# Monitor token issuance in logs
kubectl logs -n external-secrets-operator -l external-secrets-operator-xxx | grep "token"

# Check for throttling
gcloud monitoring time-series list --metrics 'workload.googleapis.com/token_operations'
```

---

## Contributing to Team Knowledge Base

### Proposed New Rules
1. **Service Account Annotation** - Standard Workload Identity annotation pattern
2. **IAM Binding Patterns** - Minimal privileges and audit logging
3. **Workload Identity Pools** - Multi-cluster and cross-project support
4. **Audit Logging Configuration** - Enable and configure Cloud Audit Logs

### Proposed New Examples
1. **Service Account with Workload Identity** - Complete KSA annotation configuration
2. **IAM Binding for BigQuery** - Minimal role with Workload Identity member
3. **WorkloadIdentityPool Configuration** - Multi-cluster pool setup
4. **Pod List with Shared SA** - Multiple pods using same Workload Identity

When contributing these back to the repository, follow the guidelines in @CONTRIBUTING.md and use the /levelup process for formalizing new patterns.

---

## Tool Context

- **gke**: Google Kubernetes Engine
- **gcloud**: Google Cloud CLI
- **iam**: Cloud IAM and Resource Manager APIs
- **external-secrets-operator**: Kubernetes operator for secret management
- **audit-logs**: Cloud Audit Logs service

**Rule References**:
- **GKE Workload Identity**: @rule:devops/gke_workload_identity.md
- **External Secrets**: @rule:devops/external_secrets_operator.md
- **Wrapper Charts**: @rule:devops/helm_wrapper_charts.md

**Example References**:
- **GKE Workload Identity**: @example:devops/gke_workload_identity.md
- **External Secret Manifest**: @example:devops/external_secret_manifest.md
