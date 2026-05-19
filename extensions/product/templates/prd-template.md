<!-- 
TEMPLATE COMPLIANCE REQUIREMENTS (v1.5.3):
- MUST use Mermaid diagrams (```mermaid) - NOT ASCII art
- MUST fill ALL [PLACEHOLDERS] with actual content
- MUST use this exact section structure (1-13, with sub-sections 2.5, 4.5, 6.5, 11.5, 12.5)
- MUST trace all requirements to PDRs
- MUST embed ALL content inline - PRD.md must be self-contained (no reader-facing external links)
- MUST run validation: ./scripts/validate-prd.sh --strict
VIOLATION = Non-compliant PRD

SELF-CONTAINED RULE: The final PRD.md must be readable without opening any other file.
Section files in .specify/product/sections/ are intermediate build artifacts only.
Visual diagrams are embedded inline via Mermaid blocks.
-->

# Product Requirements Document: [PRODUCT_NAME]

---

## 1. Visual Summary

> This PRD is **self-contained** - all diagrams and content are embedded inline below.
> No external files are required to read this document.

### 1.1 Feature Hierarchy

```mermaid
flowchart TD
    subgraph Product["[PRODUCT_NAME]"]
        direction TB
        F1["[Feature 1]<br/>[Status]"]
        F2["[Feature 2]<br/>[Status]"]
        F3["[Feature 3]<br/>[Status]"]
    end
    F1 --> F2
    F2 --> F3
```

### 1.2 Feature Dependencies

```mermaid
flowchart LR
    subgraph "Foundation"
        R1["REQ-001"]
        R2["REQ-002"]
    end
    subgraph "Business"
        R3["REQ-003"]
    end
    R1 --> R2
    R2 --> R3
```

### 1.3 Roadmap Timeline

```mermaid
gantt
    title [PRODUCT_NAME] Roadmap
    dateFormat YYYY-MM-DD
    axisFormat %b %Y
    section [Phase 1]
    [Feature] :done, f1, [START], [DURATION]
    section [Phase 2]
    [Feature] :f2, after f1, [DURATION]
    section Milestones
    [Milestone 1] :milestone, m1, [DATE], 0d
```

*Diagrams are auto-generated from requirements. Run `/product.implement` to regenerate.*

### Quick Stats

| Metric | Value |
|--------|-------|
| **Version** | [X.X] |
| **Status** | Draft \| Review \| Approved |
| **Source PDRs** | [N] Product Decision Records |
| **Requirements** | [N] Must / [N] Should / [N] Could |
| **Last Updated** | [YYYY-MM-DD] |

---

## 2. Document Information

### 2.1 Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| [X.X] | [YYYY-MM-DD] | [Author] | [Description of changes] |

### 2.2 Related Documents

| Document | Description |
|----------|-------------|
| Product Decision Records | Source PDRs with decision rationale (see [Section 13](#13-pdr-summary)) |
| Architecture Description | System architecture and ADRs |
| Constitution | Project principles and constraints |
| Visual Diagrams | Embedded inline in [Section 1](#1-visual-summary) |

### 2.3 Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | [Name] | [Date] | [✓] |
| Tech Lead | [Name] | [Date] | [✓] |
| Stakeholder | [Name] | [Date] | [✓] |

---

## 2.5 Executive Summary

> **For executive decision-makers.** This section summarizes the business case in 60 seconds.

### The Opportunity

[1-2 sentences: What market opportunity does this product address?]

### The Problem (Business Impact)

- [Pain point 1 with quantified business impact]
- [Pain point 2 with quantified business impact]
- [Pain point 3 with quantified business impact]

### The Solution

[2-3 sentences: What the product delivers. Focus on business outcomes.]

### Business Impact

| Metric | Current State | Target (12 months) | Value |
|--------|--------------|-------------------|-------|
| [Efficiency metric] | [Baseline] | [Target] | [$ value] |
| [Quality metric] | [Baseline] | [Target] | [% value] |
| [Adoption metric] | [Baseline] | [Target] | [Multiplier] |

### Investment & ROI

| | Amount |
|---|--------|
| **Annual Investment** | $[N] |
| **Expected ROI (12-month)** | [N]% |
| **Payback Period** | [N] months |

### Recommendation

**[APPROVE / CONDITIONAL / DEFER]** - [1-2 sentence justification]

---

## 3. Overview

[High-level description of the product - what it is and why it exists]

[Derived from Problem PDRs and Vision/Constitution]

### 3.1 Product Description

[2-3 sentences describing the product's core purpose and value proposition]

**Key Differentiators:**
- [Differentiator 1]
- [Differentiator 2]
- [Differentiator 3]

### 3.2 Purpose

[Describe the business/technical problem this product solves]

**Target Outcome:** [What success looks like]

### 3.3 Scope

**In Scope:**

- [Core capability 1]
- [Core capability 2]
- [Core capability 3]

**Out of Scope:**

- [Explicitly excluded capability 1 - with rationale]
- [Explicitly excluded capability 2 - with rationale]

### 3.4 Architecture Overview

```mermaid
flowchart TB
    subgraph "Frontend Layer"
        Web["🌐 Web App"]
        Mobile["📱 Mobile App"]
        Admin["🔧 Admin Panel"]
    end
    
    subgraph "API Gateway"
        Gateway["🔀 API Gateway<br/>Auth/Rate Limiting"]
    end
    
    subgraph "Backend Services"
        AuthSvc["🔐 Auth Service"]
        CoreSvc["👤 Core Service"]
        BusinessSvc["💳 Business Service"]
        GrowthSvc["📈 Growth Service"]
    end
    
    subgraph "Data Layer"
        DB[("📦 Primary DB")]
        Cache[("⚡ Cache")]
        Queue[("📨 Message Queue")]
    end
    
    subgraph "External"
        ThirdParty["🔗 Third-Party APIs"]
        CDN["🚀 CDN"]
    end
    
    Web --> Gateway
    Mobile --> Gateway
    Admin --> Gateway
    
    Gateway --> AuthSvc
    Gateway --> CoreSvc
    Gateway --> BusinessSvc
    Gateway --> GrowthSvc
    
    AuthSvc --> DB
    CoreSvc --> DB
    CoreSvc --> Cache
    BusinessSvc --> DB
    BusinessSvc --> Queue
    GrowthSvc --> DB
    GrowthSvc --> Queue
    
    BusinessSvc --> ThirdParty
    Web --> CDN
    Mobile --> CDN
    
    classDef frontend fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef gateway fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef backend fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    classDef data fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px
    classDef external fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    
    class Web,Mobile,Admin frontend
    class Gateway gateway
    class AuthSvc,CoreSvc,BusinessSvc,GrowthSvc backend
    class DB,Cache,Queue data
    class ThirdParty,CDN external
```

**Architecture Notes**:
- Frontend layer serves multiple client types
- API Gateway handles cross-cutting concerns
- Backend services are organized by feature area
- Data layer provides persistence and messaging
- External integrations are abstracted behind service layer

---

## 4. The Problem

[Problem statement - what pain point or opportunity this product addresses]

**Problem Context:**

- [Current state description - what exists today]
- [Pain points experienced by users - be specific]
- [Impact of not solving this problem - quantitative if possible]

### 4.1 Evidence

> "[Direct quote from user research or market analysis]"
> — [Source]

[Supporting data: user research, market analysis, competitive analysis]

### 4.2 Stakeholder Impact

| Stakeholder | Current Pain | Desired State |
|-------------|--------------|---------------|
| [Persona 1] | [Pain point] | [Ideal outcome] |
| [Persona 2] | [Pain point] | [Ideal outcome] |

**Derived from:** PDR-XXX (Problem category)

---

## 4.5 Market Opportunity

### 4.5.1 Market Size

| Segment | Size | Description |
|---------|------|-------------|
| **TAM** | $[N]B | [Total addressable market] |
| **SAM** | $[N]B | [Serviceable addressable market] |
| **SOM** | $[N]M | [Serviceable obtainable market - year 1-2 target] |

### 4.5.2 Competitive Landscape

| Competitor | Approach | Strength | Our Differentiation |
|------------|----------|----------|---------------------|
| [Competitor 1] | [Approach] | [Strength] | [How we differ] |
| [Competitor 2] | [Approach] | [Strength] | [How we differ] |

### 4.5.3 Market Timing

| Timeframe | Signal | Implication |
|-----------|--------|-------------|
| **Now** | [Current state] | [Why act now] |
| **6 months** | [Trend] | [Opportunity/risk] |
| **12 months** | [Trend] | [Expected shift] |

### 4.5.4 Target Customers (ICP)

**Primary:** [Role] at [Company type]
- **Pain:** [What drives the purchase]
- **Budget:** $[Range]/year
- **Decision Cycle:** [Timeline]

### 4.5.5 Positioning Statement

**For** [target customer] **who** [need], **[product]** is a [category] **that** [key benefit]. **Unlike** [competitor], **our product** [differentiation].

---

## 5. Goals & Objectives

### 5.1 Primary Goal

**[Main product objective - what success looks like]**

[Detailed description of the primary goal with measurable outcomes]

### 5.2 Technical Goals

- **[Goal 1]:** [Technical outcome required]
  - Target: [Metric]
  - Measurement: [How measured]
  
- **[Goal 2]:** [Technical outcome required]
  - Target: [Metric]
  - Measurement: [How measured]

### 5.3 Business Goals

- **[Goal 1]:** [Business value delivered]
  - Target: [Metric]
  - Measurement: [How measured]

**Goals traced to PDRs:**

| Goal | PDR | Category | Target |
|------|-----|----------|--------|
| [Goal] | PDR-XXX | [Category] | [Target] |

---

## 6. Success Metrics

### 6.1 Adoption Metrics

| Metric | Target | Timeframe | Measurement Method |
|--------|--------|-----------|-------------------|
| [Metric 1] | [Target] | [Timeframe] | [Method] |
| [Metric 2] | [Target] | [Timeframe] | [Method] |

### 6.2 Engagement Metrics

| Metric | Target | Timeframe | Measurement Method |
|--------|--------|-----------|-------------------|
| [Metric 1] | [Target] | [Timeframe] | [Method] |

### 6.3 Quality Metrics

| Metric | Target | Timeframe | Measurement Method |
|--------|--------|-----------|-------------------|
| [Metric 1] | [Target] | [Timeframe] | [Method] |

**Metrics traced to PDRs:**

| Metric | Target | PDR |
|--------|--------|-----|
| [Metric] | [Target] | PDR-XXX |

### 6.5 Business Outcome Metrics

| Metric | Target | Business Impact | Measurement |
|--------|--------|-----------------|-------------|
| [Efficiency metric] | [Target] | $[Value]/year | [How measured] |
| [Quality metric] | [Target] | [% reduction] in [cost] | [How measured] |
| [Time metric] | [Target] | [% improvement] | [How measured] |

### 6.6 Financial Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Cost per User** | <$[N]/month | Total cost / active users |
| **ROI** | >[N]% (12-month) | (Value delivered - Cost) / Cost |
| **Payback Period** | <[N] months | Time to positive ROI |

---

## 7. Personas

> **👥 User Flows**: See [Section 1.2](#12-feature-dependencies) for visual journey maps.

### 7.1 Primary Persona: [Persona Name]

**Role:** [Job title/function]

**Demographics:**
- [Age range, experience level, etc.]

**Goals:**
- [Goal 1]
- [Goal 2]

**Needs:**
- [What they need from this product]

**Pain Points:**
- [Current pain point 1]
- [Current pain point 2]

**Success Quote:** 
> "[How they describe success]"

**PDR Reference:** PDR-XXX

### 7.2 Secondary Persona: [Persona Name]

**Role:** [Job title/function]

**Goals:**
- [Goal 1]

**Needs:**
- [What they need from this product]

**Success Quote:** 
> "[How they describe success]"

**PDR Reference:** PDR-XXX

---

## 8. Functional Requirements

> **📈 Visual Hierarchy**: See [Section 1.1](#11-feature-hierarchy) for feature structure diagram
> **🔗 Dependencies**: See [Section 1.2](#12-feature-dependencies) for requirement dependency map

### 8.1 User Stories

| ID | Story | Persona | Priority | PDR |
|----|-------|---------|----------|-----|
| US-001 | As a [persona], I want to [action] so that [benefit] | [Persona] | Must | PDR-XXX |
| US-002 | As a [persona], I want to [action] so that [benefit] | [Persona] | Should | PDR-XXX |
| US-003 | As a [persona], I want to [action] so that [benefit] | [Persona] | Could | PDR-XXX |

### 8.2 Feature Requirements

#### Feature 1: [Feature Name]

**Description:** [What the feature does]

**User Story:** US-XXX

**Requirements:**

- **REQ-001:** [Specific requirement]
  - Priority: Must
  - PDR: PDR-XXX
  
- **REQ-002:** [Specific requirement]
  - Priority: Must
  - PDR: PDR-XXX

**Acceptance Criteria:**

- [ ] [Criterion 1 - testable, specific]
- [ ] [Criterion 2 - testable, specific]
- [ ] [Criterion 3 - testable, specific]

**Traced to:** PDR-XXX (Scope/Feature category)

#### Feature 2: [Feature Name]

**Description:** [What the feature does]

**Requirements:**

- **REQ-003:** [Specific requirement]
- **REQ-004:** [Specific requirement]

**Acceptance Criteria:**

- [ ] [Criterion 1]
- [ ] [Criterion 2]

**Traced to:** PDR-XXX (Scope/Feature category)

### 8.3 Requirements Priority Matrix

| Priority | Count | Description |
|----------|-------|-------------|
| Must | [N] | Critical for launch - product is incomplete without these |
| Should | [N] | Important but not blocking - can ship without |
| Could | [N] | Nice to have - add if time permits |
| Won't | [N] | Explicitly excluded - documented in Out of Scope |

**Total:** [N] requirements

### 8.4 Requirement Dependencies

```mermaid
flowchart LR
    subgraph "Foundation Layer"
        REQ001["REQ-001:<br/>User Authentication"]
        REQ002["REQ-002:<br/>User Profile"]
    end
    
    subgraph "Business Layer"
        REQ003["REQ-003:<br/>Billing Setup"]
        REQ004["REQ-004:<br/>Payment Processing"]
    end
    
    subgraph "Growth Layer"
        REQ005["REQ-005:<br/>Analytics Dashboard"]
        REQ006["REQ-006:<br/>API Access"]
    end
    
    %% Dependencies
    REQ001 -->|"prerequisite"| REQ002
    REQ002 -->|"enables"| REQ003
    REQ001 -->|"required for"| REQ004
    REQ003 -->|"depends on"| REQ004
    REQ002 -->|"provides data"| REQ005
    REQ001 -->|"authorization"| REQ006
    REQ004 -->|"feeds events"| REQ005
    
    %% Styling
    classDef foundation fill:#4a9eff,stroke:#333,stroke-width:2px,color:#fff
    classDef business fill:#66c2a5,stroke:#333,stroke-width:2px,color:#fff
    classDef growth fill:#f47721,stroke:#333,stroke-width:2px,color:#fff
    
    class REQ001,REQ002 foundation
    class REQ003,REQ004 business
    class REQ005,REQ006 growth
```

**Dependency Notes**:
- Foundation layer requirements must be completed first
- Business layer builds on foundation
- Growth layer features can proceed in parallel after foundation
- Critical path: REQ-001 → REQ-002 → REQ-003 → REQ-004

**PDR Traceability:**

| PDR | Decision | Impact on Requirements |
|-----|----------|------------------------|
| [PDR-XXX] | [Decision] | [How it defines requirements] |

> 📋 **State Transitions**: Detailed state machine diagrams are embedded in the Visual Summary ([Section 1](#1-visual-summary)).

---

## 9. Non-Functional Requirements (NFRs)

### 9.1 Performance

| Requirement | Target | Measurement | PDR |
|-------------|--------|-------------|-----|
| [Requirement 1] | [Target] | [Method] | PDR-XXX |
| [Requirement 2] | [Target] | [Method] | PDR-XXX |

### 9.2 Security

| Requirement | Target | Measurement | PDR |
|-------------|--------|-------------|-----|
| [Requirement 1] | [Target] | [Method] | PDR-XXX |

### 9.3 Reliability

| Requirement | Target | Measurement | PDR |
|-------------|--------|-------------|-----|
| [Requirement 1] | [Target] | [Method] | PDR-XXX |

### 9.4 Usability

| Requirement | Target | Measurement | PDR |
|-------------|--------|-------------|-----|
| [Requirement 1] | [Target] | [Method] | PDR-XXX |

### 9.5 Scalability

| Requirement | Target | Measurement | PDR |
|-------------|--------|-------------|-----|
| [Requirement 1] | [Target] | [Method] | PDR-XXX |

**NFRs traced to PDRs:**

| NFR | Requirement | PDR |
|-----|--------------|-----|
| [Type] | [Requirement] | PDR-XXX |

---

## 10. Out of Scope

### 10.1 Features

- **[Feature 1]:** [Explicitly excluded feature with rationale]
  - **Rationale:** [Why excluded]
  - **Future Consideration:** [When/if it might be added]
  
- **[Feature 2]:** [Explicitly excluded feature with rationale]
  - **Rationale:** [Why excluded]

### 10.2 Technical

- **[Technical exclusion 1]:** [What is excluded]
  - **Rationale:** [Why excluded]

### 10.3 Markets

- **[Market exclusion 1]:** [Which markets/users are not targeted]
  - **Rationale:** [Why excluded]

**Scope decisions traced to PDRs:**

| Out of Scope | PDR | Rationale |
|--------------|-----|-----------|
| [Item] | PDR-XXX | [Why excluded] |

---

## 11. Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation Strategy | PDR |
|------|------------|--------|---------------------|-----|
| [Risk description] | H/M/L | H/M/L | [Mitigation approach] | PDR-XXX |

### 11.1 Technical Risks

- **[Risk 1]:** [Technical risk description]
  - **Mitigation:** [How to mitigate]

### 11.2 Market Risks

- **[Risk 1]:** [Market risk description]
  - **Mitigation:** [How to mitigate]

### 11.3 Operational Risks

- **[Risk 1]:** [Operational risk description]
  - **Mitigation:** [How to mitigate]

### 11.4 Business Risks

| Risk | Likelihood | Impact | Mitigation | PDR |
|------|------------|--------|------------|-----|
| [Adoption risk] | H/M/L | H/M/L | [Mitigation] | PDR-XXX |
| [Competitive risk] | H/M/L | H/M/L | [Mitigation] | PDR-XXX |
| [Financial risk] | H/M/L | H/M/L | [Mitigation] | PDR-XXX |

*Risks traced to PDR consequence sections*

---

## 11.5 Investment & Resources

### Team Composition

| Role | FTEs | Phase | Responsibility |
|------|------|-------|----------------|
| [Role 1] | [N] | [Phase] | [Responsibility] |
| [Role 2] | [N] | [Phase] | [Responsibility] |

**Total:** [N] FTEs average, [N] FTEs peak

### Budget Estimate

| Category | Phase 1 | Phase 2 | Phase 3 | Annual |
|----------|---------|---------|---------|--------|
| **Personnel** | $[N]K | $[N]K | $[N]K | $[N]M |
| **Infrastructure** | $[N]K | $[N]K | $[N]K | $[N]K |
| **Total** | **$[N]K** | **$[N]K** | **$[N]K** | **$[N]M** |

### Risk-Adjusted ROI

| Scenario | Probability | 12-Month ROI | NPV (3-year) |
|----------|-------------|--------------|--------------|
| Optimistic | [N]% | [N]% | $[N]M |
| Base Case | [N]% | [N]% | $[N]M |
| Pessimistic | [N]% | [N]% | $[N]M |
| **Weighted** | 100% | **[N]%** | **$[N]M** |

### Go/No-Go Criteria

| Checkpoint | Date | Criteria | Decision |
|------------|------|----------|----------|
| Phase 1 Review | [Date] | [What must be true] | Go / No-Go |
| Phase 2 Review | [Date] | [What must be true] | Go / No-Go |

---

## 12. Roadmap & Milestones

> **📅 Visual Timeline**: See [Section 1.3](#13-roadmap-timeline) for the Gantt chart
> **Sync with external tools**: Run `/product.roadmap --sync` to pull milestones from GitHub/GitLab/Jira/Linear

<!-- Generated from Milestone PDRs -->

### 12.1 Milestone 1: [Name] - [Target Date]

**Demo Sentence:** "After this milestone, the user can: [observable capability]"

**Status:** Planned | In Progress | Complete

**Release Goal:** [What this milestone achieves]

| Feature | Priority | Demo Sentence | Dependencies |
|---------|----------|---------------|--------------|
| [Feature spec name] | Must | "user can ___" | None (leaf) |
| [Feature spec name] | Must | "user can ___" | Depends on [Feature] |
| [Feature spec name] | Should | "user can ___" | Depends on [Feature], [Feature] |

**Success Criteria:**

| Metric | Target | Measurement |
|--------|--------|-------------|
| [Metric] | [Target] | [Method] |

### 12.2 Milestone 2: [Name] - [Target Date]

**Demo Sentence:** "After this milestone, the user can: [observable capability]"

**Status:** Planned | In Progress | Complete

**Release Goal:** [What this milestone achieves]

| Feature | Priority | Demo Sentence | Dependencies |
|---------|----------|---------------|--------------|
| [Feature spec name] | Must | "user can ___" | None (leaf) |
| [Feature spec name] | Should | "user can ___" | Depends on [Feature] |

**Features Deferred from Previous:**

- [Feature] - deferred to this milestone

### 12.3 Milestone 3: [Name] - [Target Date]

**Demo Sentence:** "After this milestone, the user can: [observable capability]"

**Status:** Planned | In Progress | Complete

**Release Goal:** [What this milestone achieves]

| Feature | Priority | Demo Sentence | Dependencies |
|---------|----------|---------------|--------------|
| [Feature spec name] | Must | "user can ___" | None (leaf) |

**Milestones traced to PDRs:**

| Milestone | PDR | Target Date |
|-----------|-----|--------------|
| Milestone 1 | PDR-XXX | [Date] |
| Milestone 2 | PDR-XXX | [Date] |
| Milestone 3 | PDR-XXX | [Date] |

---

## 12.5 Go-to-Market Strategy

### 12.5.1 Launch Phases

| Phase | Timeline | Audience | Goal | Success Metric |
|-------|----------|----------|------|----------------|
| [Phase 1] | [Date] | [Who] | [Goal] | [Metric] |
| [Phase 2] | [Date] | [Who] | [Goal] | [Metric] |
| [Phase 3] | [Date] | [Who] | [Goal] | [Metric] |
| [GA] | [Date] | [Public] | [Revenue target] | [Metric] |

### 12.5.2 Pricing Strategy

| Tier | Price | Includes | Target |
|------|-------|----------|--------|
| **Free** | $0 | [What's included] | [Who] |
| **[Paid]** | $[N]/[unit]/[period] | [What's included] | [Who] |
| **Enterprise** | Custom | [What's included] | [Who] |

### 12.5.3 Key Messaging

| Audience | Message |
|----------|---------|
| **Executives** | "[Value prop for C-level]" |
| **Engineering Leaders** | "[Value prop for eng managers]" |
| **Developers** | "[Value prop for ICs]" |

### 12.5.4 Success Metrics by Phase

| Phase | Adoption | Engagement | Revenue |
|-------|----------|------------|---------|
| [Phase 1] | [Target] | [Target] | [Target] |
| [Phase 2] | [Target] | [Target] | [Target] |
| [GA] | [Target] | [Target] | [Target] |

---

## 13. PDR Summary

Detailed Product Decision Records are summarized below. Full PDR documents are maintained in the project's `.specify/` directory.

### 13.1 Key Decisions

| ID | Category | Decision | Status | Impact |
|----|----------|----------|--------|--------|
| PDR-001 | [Category] | [Title] | Accepted | High/Med/Low |
| PDR-002 | [Category] | [Title] | Accepted | High/Med/Low |

### 13.2 Constitution Alignment

This PRD aligns with the constitutional principles:

| Principle | Alignment | PDRs |
|-----------|-----------|------|
| [Principle 1] | ✓ Aligned | PDR-XXX, PDR-XXX |
| [Principle 2] | ✓ Aligned | PDR-XXX |

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| PRD | Product Requirements Document - this document |
| PDR | Product Decision Record - documented product decisions with rationale |
| NFR | Non-Functional Requirement - quality attributes, not features |
| DAG | Directed Acyclic Graph - the workflow structure used for generation |
| Feature-Area | Logical grouping of related functionality |

---

## Appendix B: References

- [Product vision document]
- [Market research]
- [Competitive analysis]
- [User research findings]
- [Relevant PDRs]

---

## Appendix C: Change History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | YYYY-MM-DD | [Author] | Initial version |

---

<!-- 
VALIDATION CHECKLIST (v1.5.3):
Before marking this PRD complete, verify:
- [ ] All [PLACEHOLDERS] filled with actual content
- [ ] Mermaid diagrams render correctly (NOT ASCII)
- [ ] Section 1 is Visual Summary with inline Mermaid diagrams
- [ ] Section 2.5 Executive Summary present with business impact table
- [ ] Section 4.5 Market Opportunity present with TAM/SAM/SOM
- [ ] Section 6.5 Business Outcome Metrics present
- [ ] Section 11.5 Investment & Resources present with ROI
- [ ] Section 12.5 Go-to-Market Strategy present with pricing
- [ ] All requirements trace to PDRs
- [ ] PRD is SELF-CONTAINED - no reader-facing links to .specify/ files
- [ ] Validation script passes: ./scripts/validate-prd.sh --strict
-->
