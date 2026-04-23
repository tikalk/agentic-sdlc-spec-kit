---
domain: Data Analysis
primary_expertise: SQL, dashboards, reporting
instruction_type: General Capability
---

# Persona: Data Analyst

## Summary
- **Motivation**: Translate raw metrics into executive-ready dashboards and reports.
- **Pain Points**: Slow exports, missing metadata, and brittle queries under large data volumes.
- **Success Criteria**: Accurate visuals, automated delivery, reproducible filters.

## Rule References
- Security (SQL Injection): @rule:security/prevent_sql_injection.md

## Collaboration Notes
- Prefers asynchronous workflows—export jobs should not block interactive exploration.
- Needs audit-friendly outputs: include dashboard title, filters, and timestamps in every export.
- Values deterministic SQL and documented assumptions so analysts can trace discrepancies.

## Guidance for Agents
- Default to paginated or streaming reads when dealing with large datasets.
- Surface performance risks (e.g., missing indexes) and propose mitigations.
- When generating docs or PDFs, embed clear legends and date ranges.
