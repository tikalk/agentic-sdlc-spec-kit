# Security Perspective: [SUB_SYSTEM_NAME]

**Sub-System**: [SUB_SYSTEM_NAME]
**ADRs Referenced**: [ADR_IDS]
**Generated**: [DATE]
**Applies to**: All views

---

## 4.1 Security Perspective

**Applies to**: All views

### 4.1.1 Authentication & Authorization

- **Identity Provider**: [e.g., OAuth2 via Auth0]
- **Authorization Model**: [e.g., RBAC, ABAC]
- **Session Management**: [e.g., JWT with 1-hour expiry]

### 4.1.2 Data Protection

- **Encryption at Rest**: [e.g., AES-256]
- **Encryption in Transit**: [e.g., TLS 1.3]
- **Secrets Management**: [e.g., AWS Secrets Manager]
- **PII Handling**: [e.g., Data minimization]

### 4.1.3 Threat Model

| Threat | View Affected | Likelihood | Impact | Mitigation |
|--------|---------------|------------|--------|------------|
| [THREAT_1] | [View] | [H/M/L] | [H/M/L] | [Mitigation] |

### 4.1.4 Compliance Requirements

| Requirement | Standard | Status | Notes |
|-------------|----------|--------|-------|
| [REQ_1] | [e.g., GDPR, SOC2] | [Compliant/In Progress] | [Notes] |

---

**ADR Traceability:**

| ADR | Decision | Impact on Security |
|-----|----------|-------------------|
| [ADR-XXX] | [Decision] | [How it affects security] |
