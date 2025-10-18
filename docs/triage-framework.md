# Triage Framework: [SYNC] vs [ASYNC] Task Classification

## Overview

The Triage Framework provides structured guidance for classifying implementation tasks as [SYNC] (human-reviewed execution) or [ASYNC] (autonomous agent delegation). This classification optimizes the dual execution loop by routing tasks to the most appropriate execution method.

## Core Principles

1. **Quality First**: Complex tasks requiring human judgment are classified as [SYNC]
2. **Efficiency Optimization**: Routine tasks are delegated to agents as [ASYNC]
3. **Risk Mitigation**: Critical paths maintain human oversight
4. **Continuous Learning**: Triage decisions improve over time through metrics

## Decision Tree: Task Classification

```
START: New Implementation Task
    │
    ├── Is this task security-critical?
    │   ├── YES → [SYNC] (Security classification)
    │   └── NO → Continue
    │
    ├── Does this task involve external integrations?
    │   ├── YES → [SYNC] (Integration classification)
    │   └── NO → Continue
    │
    ├── Is the requirement ambiguous or unclear?
    │   ├── YES → [SYNC] (Clarity classification)
    │   └── NO → Continue
    │
    ├── Does this task require architectural decisions?
    │   ├── YES → [SYNC] (Architecture classification)
    │   └── NO → Continue
    │
    ├── Is this complex business logic?
    │   ├── YES → [SYNC] (Complexity classification)
    │   └── NO → Continue
    │
    ├── Is this well-defined CRUD/standard pattern?
    │   ├── YES → [ASYNC] (Standard pattern classification)
    │   └── NO → Continue
    │
    ├── Does this have comprehensive test coverage?
    │   ├── YES → [ASYNC] (Test coverage classification)
    │   └── NO → [SYNC] (Insufficient testing safeguards)
    │
    └── [ASYNC] (Default classification)
```

## Detailed Classification Criteria

### [SYNC] Classifications (Human Execution Required)

#### 1. Security Classification
**When to Apply**: Tasks involving authentication, authorization, encryption, data protection, or compliance requirements.

**Examples**:
- User authentication flows
- API key management
- Data encryption/decryption
- Access control logic
- GDPR/privacy compliance

**Rationale**: Security-critical code requires human expertise and cannot be delegated due to liability and compliance risks.

#### 2. Integration Classification
**When to Apply**: Tasks involving external APIs, legacy systems, third-party services, or complex data transformations.

**Examples**:
- Payment gateway integration
- External API consumption
- Legacy system migration
- Data import/export pipelines
- Webhook implementations

**Rationale**: Integration complexity often requires domain expertise and error handling that agents cannot reliably implement.

#### 3. Clarity Classification
**When to Apply**: Tasks with ambiguous requirements, unclear acceptance criteria, or multiple interpretation possibilities.

**Examples**:
- Vague user story requirements
- Missing edge case specifications
- Conflicting stakeholder expectations
- Novel feature implementations
- Research-dependent tasks

**Rationale**: Ambiguous requirements need human clarification and interpretation before implementation.

#### 4. Architecture Classification
**When to Apply**: Tasks involving system design decisions, component boundaries, or architectural patterns.

**Examples**:
- Database schema design
- API contract definition
- Component architecture
- Design pattern selection
- Performance optimization strategies

**Rationale**: Architectural decisions have long-term impact and require experienced design judgment.

#### 5. Complexity Classification
**When to Apply**: Tasks involving non-trivial algorithms, state machines, or complex business logic.

**Examples**:
- Custom algorithms
- State machine implementations
- Complex validation logic
- Mathematical computations
- Multi-step business processes

**Rationale**: Complex logic requires deep understanding and careful implementation that benefits from human review.

### [ASYNC] Classifications (Agent Delegation Suitable)

#### 1. Standard Pattern Classification
**When to Apply**: Tasks following well-established patterns, frameworks, or standard implementations.

**Examples**:
- RESTful API endpoints
- Standard CRUD operations
- Form validation
- Basic error handling
- Standard authentication flows

**Rationale**: Standard patterns have predictable implementations that agents can reliably generate.

#### 2. Test Coverage Classification
**When to Apply**: Tasks with comprehensive automated test coverage providing execution safeguards.

**Examples**:
- Components with >80% test coverage
- TDD-developed features
- Well-tested utility functions
- Components with integration tests

**Rationale**: Comprehensive testing provides confidence that agent-generated code meets requirements.

#### 3. Independent Component Classification
**When to Apply**: Tasks implementing self-contained components with minimal external dependencies.

**Examples**:
- Utility libraries
- Standalone services
- Independent UI components
- Pure functions
- Data transformation helpers

**Rationale**: Independent components have limited blast radius and can be safely delegated.

## Triage Process Workflow

### Phase 1: Task Identification
1. Break down feature into discrete, implementable tasks
2. Estimate effort and dependencies for each task
3. Identify task boundaries and interfaces

### Phase 2: Classification Assessment
1. Apply decision tree to each task
2. Document primary classification criteria
3. Assess risk level of misclassification
4. Record rationale for each decision

### Phase 3: Review and Validation
1. Peer review of triage decisions
2. Validate classification consistency
3. Confirm risk assessments
4. Document any overrides or exceptions

### Phase 4: Execution Planning
1. Group tasks by classification
2. Plan [SYNC] review checkpoints
3. Configure [ASYNC] agent delegation
4. Establish monitoring and rollback procedures

## Triage Metrics and Improvement

### Effectiveness Metrics

#### Classification Accuracy
- **Measurement**: Percentage of tasks correctly classified (validated post-implementation)
- **Target**: >90% accuracy
- **Tracking**: Monthly review of misclassifications

#### Review Efficiency
- **Measurement**: Time spent on [SYNC] reviews vs time saved by [ASYNC] delegation
- **Target**: Net positive efficiency gain
- **Tracking**: Per-feature analysis

#### Quality Impact
- **Measurement**: Defect rates by classification type
- **Target**: [SYNC] defects <5%, [ASYNC] defects <15%
- **Tracking**: Post-implementation defect analysis

### Continuous Improvement

#### Learning Opportunities
- **Common Patterns**: Identify frequently misclassified task types
- **Training Updates**: Update decision trees based on lessons learned
- **Tool Improvements**: Enhance triage guidance based on metrics

#### Feedback Integration
- **Developer Feedback**: Collect classification experience reports
- **Review Feedback**: Analyze review findings for triage improvements
- **Quality Metrics**: Use defect data to refine classification criteria

## Training Module: Triage Decision Making

### Module 1: Understanding Classifications
**Objective**: Understand the difference between [SYNC] and [ASYNC] tasks
**Content**:
- Classification criteria with examples
- Risk assessment frameworks
- Common misclassification patterns

### Module 2: Decision Tree Application
**Objective**: Practice applying the triage decision tree
**Content**:
- Interactive decision tree walkthrough
- Real-world task classification exercises
- Peer review of classification decisions

### Module 3: Risk Assessment
**Objective**: Learn to assess misclassification risks
**Content**:
- Risk level determination
- Impact analysis techniques
- Mitigation strategy development

### Module 4: Metrics and Improvement
**Objective**: Understand triage effectiveness measurement
**Content**:
- Metrics definition and calculation
- Improvement opportunity identification
- Feedback integration processes

## Implementation Checklist

### For Each Feature
- [ ] All tasks classified as [SYNC] or [ASYNC]
- [ ] Classification rationale documented
- [ ] Risk assessment completed
- [ ] Peer review conducted
- [ ] Triage decisions approved

### For Each Sprint/Iteration
- [ ] Classification accuracy measured
- [ ] Review efficiency analyzed
- [ ] Quality metrics collected
- [ ] Improvement opportunities identified
- [ ] Training modules updated

## Appendix: Common Misclassification Patterns

### False Positives ([SYNC] when should be [ASYNC])
- Over-classifying standard CRUD operations
- Treating well-tested components as high-risk
- Misinterpreting "complex" as requiring human review

### False Negatives ([ASYNC] when should be [SYNC])
- Underestimating integration complexity
- Ignoring security implications
- Delegating ambiguous requirements

### Mitigation Strategies
- Regular calibration sessions
- Peer review of classifications
- Metrics-driven refinement
- Clear escalation procedures