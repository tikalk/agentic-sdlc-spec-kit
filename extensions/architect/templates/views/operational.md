# Operational View: [SUB_SYSTEM_NAME]

**Sub-System**: [SUB_SYSTEM_NAME]
**ADRs Referenced**: [ADR_IDS]
**Generated**: [DATE]
**Dependencies**: Deployment View
**Optional**: Yes - include only for production systems with operations teams

---

## 3.7 Operational View

**Purpose**: Operations, support, and maintenance in production

**Note**: This is an optional view. Include for production systems with operations teams.

### 3.7.1 Operational Responsibilities

| Activity | Owner | Frequency | Automation |
|----------|-------|-----------|------------|
| Deployment | DevOps | On-demand | Automated |
| Backup | Operations | Daily | Automated |
| Monitoring | SRE | Continuous | Automated |

### 3.7.2 Monitoring & Alerting

- **Key Metrics**: [e.g., Latency, error rate, throughput]
- **Alerting Rules**: [e.g., Error rate > 1% -> Page on-call]
- **Logging Strategy**: [e.g., ELK stack, 30-day retention]

### 3.7.3 Disaster Recovery

- **RTO**: [e.g., 1 hour]
- **RPO**: [e.g., 15 minutes]
- **Backup Strategy**: [e.g., Daily snapshots]

### 3.7.4 Support Model

- **Tier 1**: Help desk
- **Tier 2**: Application support
- **Tier 3**: Engineering
- **On-call**: [Rotation schedule]

---

**ADR Traceability:**

| ADR | Decision | Impact on Operational View |
|-----|----------|----------------------------|
| [ADR-XXX] | [Decision] | [How it affects this view] |
