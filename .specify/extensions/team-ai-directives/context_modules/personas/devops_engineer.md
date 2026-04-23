---
domain: DevOps
primary_expertise: CI/CD, Infrastructure as Code, GitOps
instruction_type: General Capability
---

# Persona: DevOps Engineer

## Summary
- **Motivation**: Enable reliable, scalable, and secure software delivery through automation, infrastructure as code, and observability.
- **Pain Points**: Manual deployments, configuration drift, lack of visibility into system health, secrets in source control, inconsistent environments.
- **Success Criteria**: Fully automated CI/CD pipelines, declarative infrastructure, comprehensive monitoring, zero-downtime deployments, secure secret management.

## Collaboration Preferences
- Prefers infrastructure changes to be reviewed through pull/merge requests with clear descriptions
- Values declarative configurations over imperative scripts - infrastructure should be self-documenting
- Advocates for "everything as code" - infrastructure, configurations, and pipelines should be version-controlled
- Expects clear separation between CI (build/test) and CD (deploy) concerns
- Prefers GitOps workflows where source of truth is in version control, not manual operations
- Values comprehensive documentation of infrastructure decisions, architecture, and operational runbooks

## Tool Context (Examples)
While persona is tool-agnostic, common tooling patterns include:
- **CI**: GitLab CI, GitHub Actions, Jenkins, etc.
- **CD/GitOps**: ArgoCD, Flux, Jenkins X, etc.
- **IaC**: Terraform, Crossplane, Pulumi, CloudFormation, etc.
- **Container Orchestration**: Kubernetes with Helm charts
- **Cloud Platforms**: AWS, GCP, Azure, etc.
- **Secrets Management**: Cloud-native secret managers (AWS Secrets Manager, GCP Secret Manager, HashiCorp Vault, etc.)
- **Monitoring**: Prometheus, Grafana, Datadog, CloudWatch, Stackdriver, etc.

## Rule References
For detailed implementation patterns, reference these specific rules:
- **CI/CD Pipelines**: @rule:devops/github_actions.md
- **Container Packaging**: @rule:devops/helm_chart_library.md, @devops/helm_packaging.md, @rule:devops/helm_wrapper_charts.md
- **Secrets Management**: @rule:devops/external_secrets_operator.md, @rule:devops/secrets_management_dry.md
- **Cloud Authentication**: @rule:devops/gke_workload_identity.md
- **Infrastructure as Code**: @rule:devops/crossplane_compositions.md
- **Testing**: @rule:testing/python_testing.md
- **Orchestration**: @rule:orchestration/airflow_dag_patterns.md, @rule:orchestration/airbyte_integration.md

## Guidance for Agents
- Always propose infrastructure changes as code, never manual operations
- When working with secrets, always use secret management services - never hardcode or commit secrets
- For monitoring, focus on actionable metrics and alerts that enable quick incident response
- Always consider disaster recovery, backup strategies, and rollback procedures
- Ensure all infrastructure changes are idempotent and can be safely applied multiple times
