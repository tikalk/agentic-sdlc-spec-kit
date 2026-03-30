---
description: Match published evals to feature tasks → [EVAL] markers following EDD task-eval alignment and coverage verification
scripts:
  sh: scripts/bash/setup-evals.sh "tasks {ARGS}"
  ps: scripts/powershell/setup-evals.ps1 "tasks {ARGS}"
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

**Examples of User Input**:

- `"Match all published evals to current feature tasks"`
- `"Add eval markers for security-related tasks only"`
- `"Dry run matching with conflict detection and resolution"`
- `"Apply eval markers to tasks.md files after manual review"`
- `"Match evals by exact tag matching instead of keyword overlap"`
- Empty input: Run comprehensive eval-to-task matching with dry-run preview

When users provide specific matching criteria or scope limitations, apply those constraints to the matching process.

## Goal

**Comprehensive eval-to-task alignment** that ensures every feature task has appropriate evaluation coverage through systematic matching and marker application following **EDD principles** for spec-driven contracts and evaluation coverage.

**Output**:

1. **Goldset Discovery** - Comprehensive scan of all published evaluation criteria
2. **Task Discovery** - Complete inventory of feature tasks across all specs
3. **Matching Analysis** - Keyword overlap and tag-based matching with confidence scoring
4. **Conflict Detection** - Identify ambiguous matches requiring human review
5. **Marker Generation** - Create properly formatted [EVAL] markers for tasks
6. **Coverage Analysis** - Verify comprehensive evaluation coverage across all tasks
7. **Application** - Write markers to task files (with --apply flag or hook mode)

**Key EDD Principles Applied**:

- **Principle I**: Spec-Driven Contracts - Evals validate spec compliance, tasks implement specs
- **Principle IV**: Evaluation Pyramid - Ensure appropriate eval coverage across task complexity
- **Principle IX**: Test Data is Code - Version-controlled eval-task relationships
- **Principle X**: Cross-Functional Observability - Clear eval coverage visible to all stakeholders

### Flags

- `--dry-run`: Show proposed markers without writing files (default for manual invocation)
- `--apply`: Write [EVAL] markers directly to tasks.md files
- `--scope PATTERN`: Limit matching to specific task patterns (e.g., "auth", "security")
- `--matching-mode MODE`: Use 'keywords' (default), 'tags', or 'hybrid' matching
- `--confidence-threshold FLOAT`: Minimum match confidence score (default: 0.7)
- `--conflict-review`: Flag ambiguous matches for manual review before applying
- `--json`: Output structured JSON for programmatic integration

## Role & Context

You are acting as an **Evaluation Coverage Coordinator** ensuring comprehensive alignment between evaluation criteria and implementation tasks. Your role involves:

- **Coverage Analysis**: Systematic verification that all tasks have appropriate evaluation coverage
- **Matching Logic**: Intelligent keyword and tag-based matching between evals and tasks
- **Conflict Resolution**: Identifying and flagging ambiguous matches for human review
- **Marker Management**: Precise application of [EVAL] markers following established format standards

### Tasks vs Validation

| Phase | Focus | Input | Output |
|-------|-------|-------|--------|
| **Tasks** (this command) | Coverage alignment | Published evals + feature tasks | [EVAL] markers in tasks.md |
| **Validation** (validate) | Quality assurance | Complete evaluation system | Production readiness assessment |

## Outline

1. **Discovery Phase** (Phase 0): Comprehensive scan of published evals and feature tasks
2. **Matching Analysis**: Intelligent keyword and tag-based eval-to-task matching
3. **Conflict Detection**: Identify ambiguous matches requiring human review
4. **Confidence Scoring**: Assess match quality and confidence levels
5. **Coverage Gap Analysis**: Identify tasks without eval coverage and over-evaluated tasks
6. **Marker Generation**: Create properly formatted [EVAL] markers with standardized format
7. **Application Decision**: Apply markers based on dry-run/apply mode and confidence thresholds
8. **Coverage Verification**: Confirm comprehensive evaluation coverage across all tasks

## Execution Steps

### Phase 0: Discovery and Inventory

**Objective**: Comprehensive discovery of published evaluations and feature tasks

#### Step 1: Published Evaluations Discovery

Scan all published goldset evaluations for matching:

```bash
# Execute via setup script
{SCRIPT} tasks --discover-evals
```

**Expected Evaluation Inventory**:
```markdown
## Published Evaluations Inventory

**Discovery Date**: {current_date}
**Evaluation System**: promptfoo

### Available Evaluations

| Eval ID | Name | Description | Keywords | Tags |
|---------|------|-------------|----------|------|
| **eval-001** | Regulatory Compliance Check | Ensures responses comply with regulatory requirements | regulatory, compliance, legal, finance | [regulatory] |
| **eval-002** | Context Adherence Validation | Validates response stays within provided context | context, adherence, scope, boundaries | [context, safety] |
| **eval-003** | Safety Boundary Enforcement | Prevents harmful or dangerous responses | safety, harmful, dangerous, boundary | [safety] |
| **eval-006** | Authentication Token Validation | Verifies proper auth token handling | auth, token, authentication, security | [auth, security] |

### Security Baseline Evaluations (Always Applied)

| Eval ID | Name | Type | Auto-Applied |
|---------|------|------|--------------|
| **pii_leakage** | PII Leakage Detection | Security baseline | ✅ All tasks |
| **prompt_injection** | Prompt Injection Prevention | Security baseline | ✅ All tasks |
| **hallucination_detection** | Hallucination Prevention | Security baseline | ✅ All tasks |
| **misinformation_detection** | Misinformation Prevention | Security baseline | ✅ All tasks |

### Evaluation Coverage Statistics
- **Total Published Evals**: 4
- **Security Baseline Evals**: 4 (auto-applied)
- **Custom Domain Evals**: 4
- **Total Available for Matching**: 8

**Evaluation Discovery Status**: ✅ COMPLETE INVENTORY AVAILABLE
```

#### Step 2: Feature Tasks Discovery

Scan all feature tasks across specification directories:

```markdown
## Feature Tasks Inventory

**Discovery Scope**: All specs/ directories
**Task File Pattern**: `specs/{feature}/tasks.md`

### Discovered Feature Tasks

| Feature | Tasks Count | Task IDs | Keywords Present |
|---------|-------------|----------|------------------|
| **authentication** | 3 tasks | TASK-001, TASK-002, TASK-003 | auth, login, token, password |
| **user-management** | 4 tasks | TASK-001, TASK-002, TASK-003, TASK-004 | user, profile, registration, permissions |
| **payment-processing** | 2 tasks | TASK-001, TASK-002 | payment, billing, transaction, financial |
| **content-moderation** | 3 tasks | TASK-001, TASK-002, TASK-003 | content, moderation, safety, harmful |

### Task Details Example

**specs/authentication/tasks.md**:
```markdown
## TASK-001: Implement token validation
- Validate JWT tokens for API requests
- Check token expiration and signature
- Handle token refresh workflows

## TASK-002: Build user login system
- Create secure login interface
- Implement password hashing
- Add brute force protection

## TASK-003: Add OAuth integration
- Support Google and GitHub OAuth
- Handle OAuth callback flows
- Store OAuth user profiles securely
```

### Task Analysis Summary
- **Total Features**: 4
- **Total Tasks**: 12
- **Currently Marked Tasks**: 0 (no existing [EVAL] markers)
- **Keywords Extracted**: 47 unique terms
- **Estimated Matchable Tasks**: 11 (92%)

**Task Discovery Status**: ✅ COMPREHENSIVE TASK INVENTORY COMPLETE
```

### Phase 1: Matching Analysis

**Objective**: Intelligent matching of evaluations to tasks using multiple algorithms

#### Step 1: Keyword-Based Matching

Apply keyword overlap analysis between evaluations and tasks:

```python
# Keyword matching implementation
import re
import json
from typing import Dict, List, Tuple, Set
from collections import defaultdict

def extract_keywords(text: str) -> Set[str]:
    """Extract relevant keywords from task or evaluation text."""
    # Remove common stop words and extract meaningful terms
    stopwords = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'}
    words = re.findall(r'\b\w+\b', text.lower())
    return set(word for word in words if len(word) > 2 and word not in stopwords)

def calculate_keyword_overlap(eval_keywords: Set[str], task_keywords: Set[str]) -> float:
    """Calculate keyword overlap score between evaluation and task."""
    if not eval_keywords or not task_keywords:
        return 0.0

    intersection = eval_keywords.intersection(task_keywords)
    union = eval_keywords.union(task_keywords)

    # Jaccard similarity with length normalization
    jaccard_score = len(intersection) / len(union) if union else 0.0

    # Boost score for high-value keyword matches
    high_value_keywords = {'auth', 'security', 'safety', 'regulatory', 'compliance', 'token', 'payment'}
    high_value_matches = intersection.intersection(high_value_keywords)
    boost = len(high_value_matches) * 0.1

    return min(jaccard_score + boost, 1.0)

def match_evals_to_tasks(evaluations: Dict, tasks: Dict) -> Dict[str, List[Tuple]]:
    """
    Match evaluations to tasks using keyword overlap analysis.
    Returns dict of task_id -> [(eval_id, confidence_score, match_reason)]
    """

    matches = defaultdict(list)

    for task_id, task_data in tasks.items():
        task_keywords = extract_keywords(task_data['content'])

        for eval_id, eval_data in evaluations.items():
            eval_keywords = extract_keywords(eval_data['description'] + ' ' + ' '.join(eval_data.get('keywords', [])))

            confidence = calculate_keyword_overlap(eval_keywords, task_keywords)

            if confidence >= 0.7:  # Configurable threshold
                match_reason = f"keyword_overlap_{confidence:.2f}"
                matches[task_id].append((eval_id, confidence, match_reason))

    return matches
```

**Keyword Matching Results**:
```markdown
## Keyword-Based Matching Analysis

### High-Confidence Matches (≥0.8)

**authentication/TASK-001: Implement token validation**
- eval-006 (Authentication Token Validation): 0.89 confidence
  - Shared keywords: auth, token, validation, security
  - Match reason: Direct domain alignment + high-value keyword overlap

**authentication/TASK-002: Build user login system**
- eval-006 (Authentication Token Validation): 0.82 confidence
  - Shared keywords: auth, login, user, security
  - Match reason: Authentication domain + security overlap

**content-moderation/TASK-001: Content safety filtering**
- eval-003 (Safety Boundary Enforcement): 0.91 confidence
  - Shared keywords: safety, harmful, boundary, content
  - Match reason: Direct safety domain alignment

### Medium-Confidence Matches (0.7-0.8)

**payment-processing/TASK-001: Process payments securely**
- eval-001 (Regulatory Compliance Check): 0.76 confidence
  - Shared keywords: regulatory, compliance, financial
  - Match reason: Financial regulatory overlap

**user-management/TASK-003: Handle user permissions**
- eval-002 (Context Adherence Validation): 0.74 confidence
  - Shared keywords: context, scope, boundaries, permissions
  - Match reason: Context boundary similarity

### Matching Statistics
- **High-confidence matches**: 6 matches (≥0.8)
- **Medium-confidence matches**: 4 matches (0.7-0.8)
- **Low-confidence matches**: 8 matches (<0.7, filtered out)
- **Unmatched tasks**: 2 tasks (17%)
- **Over-matched tasks**: 3 tasks (multiple evals matched)

**Keyword Matching Status**: ✅ STRONG MATCHES IDENTIFIED
```

#### Step 2: Tag-Based Exact Matching

Apply exact tag matching where evaluations define specific task_tags:

```markdown
## Tag-Based Exact Matching Analysis

### Evaluation Tag Definitions

| Eval ID | Defined Tags | Task Tags (if specified) |
|---------|--------------|-------------------------|
| **eval-001** | [regulatory] | task_tags: ["payment", "financial", "legal"] |
| **eval-002** | [context, safety] | task_tags: ["user-context", "scoping"] |
| **eval-003** | [safety] | task_tags: ["content-moderation", "safety"] |
| **eval-006** | [auth, security] | task_tags: ["authentication", "login"] |

### Exact Tag Matches

**authentication/TASK-001** tagged with: ["authentication", "security"]
- ✅ **eval-006**: Direct match on "authentication" tag
- Confidence: 1.0 (exact tag match)

**authentication/TASK-002** tagged with: ["authentication", "login"]
- ✅ **eval-006**: Direct match on "authentication" + "login" tags
- Confidence: 1.0 (exact tag match)

**content-moderation/TASK-001** tagged with: ["content-moderation", "safety"]
- ✅ **eval-003**: Direct match on "safety" tag
- Confidence: 1.0 (exact tag match)

**payment-processing/TASK-001** tagged with: ["payment", "financial"]
- ✅ **eval-001**: Direct match on "payment" and "financial" tags
- Confidence: 1.0 (exact tag match)

### Tag Matching Statistics
- **Exact tag matches**: 4 matches
- **Tasks with tags**: 8/12 tasks (67%)
- **Evaluations with task_tags**: 4/4 evaluations (100%)
- **Perfect confidence scores**: 4 matches (tag matching)

**Tag Matching Status**: ✅ PRECISE MATCHES VIA TAGS
```

#### Step 3: Hybrid Matching with Confidence Aggregation

Combine keyword and tag matching for comprehensive coverage:

```markdown
## Hybrid Matching Results (Keywords + Tags)

### Consolidated Matches by Task

**authentication/TASK-001: Implement token validation**
- ✅ **eval-006** (Authentication Token): 1.0 confidence (exact tag) + 0.89 (keyword) = **STRONG MATCH**
- ✅ **pii_leakage** (Security baseline): Auto-applied to all tasks

**authentication/TASK-002: Build user login system**
- ✅ **eval-006** (Authentication Token): 1.0 confidence (exact tag) + 0.82 (keyword) = **STRONG MATCH**
- ✅ **pii_leakage** (Security baseline): Auto-applied to all tasks

**authentication/TASK-003: Add OAuth integration**
- ✅ **eval-006** (Authentication Token): 0.74 confidence (keyword only) = **MEDIUM MATCH**
- ✅ **pii_leakage** (Security baseline): Auto-applied to all tasks

**content-moderation/TASK-001: Content safety filtering**
- ✅ **eval-003** (Safety Boundary): 1.0 confidence (exact tag) + 0.91 (keyword) = **STRONG MATCH**
- ✅ **eval-002** (Context Adherence): 0.72 confidence (keyword) = **MEDIUM MATCH**
- ✅ **pii_leakage, hallucination_detection** (Security baseline): Auto-applied

**payment-processing/TASK-001: Process payments securely**
- ✅ **eval-001** (Regulatory Compliance): 1.0 confidence (exact tag) + 0.76 (keyword) = **STRONG MATCH**
- ✅ **pii_leakage** (Security baseline): Auto-applied

**user-management/TASK-002: User profile management**
- ✅ **eval-002** (Context Adherence): 0.74 confidence (keyword only) = **MEDIUM MATCH**
- ⚠ **No strong matches** - potential coverage gap
- ✅ **pii_leakage** (Security baseline): Auto-applied

### Match Quality Distribution
- **Strong matches** (confidence ≥0.9): 8 matches
- **Medium matches** (confidence 0.7-0.9): 6 matches
- **Weak matches** (confidence <0.7): 2 matches (filtered)
- **Auto-applied security baseline**: 12 tasks (100%)

**Hybrid Matching Status**: ✅ COMPREHENSIVE COVERAGE WITH QUALITY SCORING
```

### Phase 2: Conflict Detection

**Objective**: Identify ambiguous matches requiring human review

#### Step 1: Multiple Match Analysis

Detect tasks with multiple evaluation matches and assess conflicts:

```markdown
## Conflict Detection Analysis

### Tasks with Multiple Matches

**content-moderation/TASK-001: Content safety filtering**
- **eval-003** (Safety Boundary): 1.0 confidence - Safety domain expert
- **eval-002** (Context Adherence): 0.72 confidence - Context boundary expert
- **Analysis**: Both relevant, different aspects of content safety
- **Resolution**: ✅ COMPLEMENTARY - Both evals appropriate

**authentication/TASK-001: Implement token validation**
- **eval-006** (Authentication Token): 1.0 confidence - Primary match
- **eval-001** (Regulatory Compliance): 0.68 confidence - Financial context
- **Analysis**: Token validation may need regulatory compliance in financial contexts
- **Resolution**: ⚠ CONTEXT-DEPENDENT - Review based on application domain

**payment-processing/TASK-002: Handle payment failures**
- **eval-001** (Regulatory Compliance): 0.85 confidence - Financial regulations
- **eval-003** (Safety Boundary): 0.71 confidence - Error handling safety
- **Analysis**: Payment failures involve both regulatory and safety concerns
- **Resolution**: ✅ COMPLEMENTARY - Both evals needed for comprehensive coverage

### Ambiguous Matches Requiring Review

**user-management/TASK-003: Handle user permissions**
- **eval-002** (Context Adherence): 0.74 confidence - Context scoping
- **eval-006** (Authentication Token): 0.69 confidence - Authorization overlap
- **Conflict**: Unclear which evaluation better covers permission handling
- **Resolution**: ⚠ AMBIGUOUS - Human review needed to determine primary eval

**user-management/TASK-004: Delete user accounts**
- **eval-001** (Regulatory Compliance): 0.73 confidence - Data retention regulations
- **eval-002** (Context Adherence): 0.71 confidence - Context preservation during deletion
- **Conflict**: Both have similar confidence, different focus areas
- **Resolution**: ⚠ AMBIGUOUS - Review needed for primary vs secondary eval designation

### Conflict Resolution Summary

| Conflict Type | Count | Resolution Strategy |
|---------------|-------|-------------------|
| **Complementary** | 3 matches | Accept both evaluations |
| **Context-Dependent** | 1 match | Flag for domain-specific review |
| **Ambiguous** | 2 matches | Require human review before application |
| **No Conflicts** | 8 matches | Direct application approved |

**Conflict Detection Status**: ✅ 2 AMBIGUOUS CASES IDENTIFIED FOR REVIEW
```

#### Step 2: Confidence Threshold Analysis

Analyze matches against confidence thresholds for application decisions:

```markdown
## Confidence Threshold Analysis

### Match Quality Distribution

**High Confidence (≥0.8)**: 8 matches - **DIRECT APPLICATION**
- authentication/TASK-001 → eval-006 (1.0)
- authentication/TASK-002 → eval-006 (1.0)
- content-moderation/TASK-001 → eval-003 (1.0)
- payment-processing/TASK-001 → eval-001 (1.0)
- payment-processing/TASK-002 → eval-001 (0.85)
- content-moderation/TASK-002 → eval-003 (0.83)
- authentication/TASK-003 → eval-006 (0.82)
- user-management/TASK-001 → eval-002 (0.81)

**Medium Confidence (0.7-0.8)**: 6 matches - **REVIEW RECOMMENDED**
- user-management/TASK-003 → eval-002 (0.74)
- user-management/TASK-004 → eval-001 (0.73)
- content-moderation/TASK-001 → eval-002 (0.72) [secondary]
- payment-processing/TASK-002 → eval-003 (0.71) [secondary]
- user-management/TASK-002 → eval-002 (0.74)
- user-management/TASK-003 → eval-006 (0.69) [conflicting]

**Below Threshold (<0.7)**: 4 matches - **FILTERED OUT**
- Various low-confidence keyword matches excluded from application

### Application Decision Matrix

| Task | Primary Eval | Secondary Eval | Decision | Reason |
|------|--------------|----------------|----------|---------|
| **auth/TASK-001** | eval-006 (1.0) | - | ✅ APPLY | High confidence, clear match |
| **auth/TASK-002** | eval-006 (1.0) | - | ✅ APPLY | High confidence, clear match |
| **content/TASK-001** | eval-003 (1.0) | eval-002 (0.72) | ✅ APPLY BOTH | Complementary evaluations |
| **payment/TASK-001** | eval-001 (1.0) | - | ✅ APPLY | High confidence, clear match |
| **user/TASK-003** | - | - | ⚠ REVIEW | Ambiguous between eval-002 and eval-006 |

**Confidence Analysis Status**: ✅ CLEAR APPLICATION DECISIONS FOR 10/12 TASKS
```

### Phase 3: Coverage Gap Analysis

**Objective**: Identify tasks without adequate evaluation coverage

#### Step 1: Coverage Gap Identification

Identify tasks with insufficient evaluation coverage:

```markdown
## Evaluation Coverage Gap Analysis

### Tasks with Insufficient Coverage

**user-management/TASK-005: Archive inactive users**
- **Matched Evals**: None above threshold
- **Keywords**: archive, inactive, user, cleanup, retention
- **Gap Analysis**: No evaluations cover data archival or retention policies
- **Risk Level**: MEDIUM - Data handling without evaluation coverage
- **Recommendation**: Create data-handling evaluation criterion

**integration/TASK-001: Third-party API integration**
- **Matched Evals**: None above threshold
- **Keywords**: api, integration, third-party, external, service
- **Gap Analysis**: No evaluations cover external service integration
- **Risk Level**: HIGH - External integrations pose security and reliability risks
- **Recommendation**: Create integration-safety evaluation criterion

### Over-Evaluated Tasks

**content-moderation/TASK-001: Content safety filtering**
- **Matched Evals**: eval-003 (1.0) + eval-002 (0.72) + 4 security baseline
- **Analysis**: 6 total evaluations for single task
- **Assessment**: ✅ APPROPRIATE - Content safety requires comprehensive evaluation

**authentication/TASK-001: Implement token validation**
- **Matched Evals**: eval-006 (1.0) + 4 security baseline
- **Analysis**: 5 total evaluations for single task
- **Assessment**: ✅ APPROPRIATE - Authentication is security-critical

### Coverage Statistics by Feature

| Feature | Tasks | Fully Covered | Partially Covered | No Coverage | Risk Level |
|---------|-------|---------------|------------------|-------------|------------|
| **authentication** | 3 | 3 (100%) | 0 | 0 | ✅ LOW |
| **content-moderation** | 3 | 3 (100%) | 0 | 0 | ✅ LOW |
| **payment-processing** | 2 | 2 (100%) | 0 | 0 | ✅ LOW |
| **user-management** | 4 | 2 (50%) | 1 (25%) | 1 (25%) | ⚠ MEDIUM |
| **integration** | 1 | 0 (0%) | 0 | 1 (100%) | ❌ HIGH |

### Coverage Improvement Recommendations

1. **Create Data Handling Evaluation**: Cover archival, retention, and cleanup operations
2. **Create Integration Safety Evaluation**: Cover third-party service integration risks
3. **Review User Management Coverage**: Assess if additional user-specific evaluations needed
4. **Validate Over-Evaluation**: Confirm security-critical tasks appropriately evaluated

**Coverage Gap Analysis Status**: ✅ 2 GAPS IDENTIFIED WITH IMPROVEMENT PLAN
```

#### Step 2: Security Baseline Coverage Verification

Ensure security baseline evaluations are properly applied:

```markdown
## Security Baseline Coverage Verification

### Security Baseline Auto-Application

All tasks automatically receive security baseline evaluations:

| Security Eval | Applied To | Coverage Rate | Notes |
|---------------|------------|---------------|-------|
| **pii_leakage** | All 12 tasks | 100% | Personal data protection |
| **prompt_injection** | All 12 tasks | 100% | Input validation security |
| **hallucination_detection** | All 12 tasks | 100% | Response accuracy verification |
| **misinformation_detection** | All 12 tasks | 100% | Information reliability check |

### Security Coverage Analysis by Risk Level

**High-Risk Tasks** (Authentication, Payments):
- ✅ All 5 security evals applied (4 baseline + domain-specific)
- ✅ Domain-specific evaluations present
- ✅ Comprehensive security coverage

**Medium-Risk Tasks** (User Management, Content):
- ✅ All 4 security baseline evals applied
- ✅ Most have additional domain evaluations
- ✅ Adequate security coverage

**Standard Tasks** (General features):
- ✅ All 4 security baseline evals applied
- ⚠ Some lack domain-specific evaluations
- ✅ Minimum security coverage met

### Security Coverage Compliance
- **Baseline Coverage**: 100% compliance
- **Domain Security**: 83% coverage (10/12 tasks)
- **High-Risk Task Coverage**: 100% comprehensive coverage
- **Security Policy Compliance**: ✅ FULL COMPLIANCE

**Security Coverage Status**: ✅ COMPREHENSIVE SECURITY BASELINE COVERAGE
```

### Phase 4: Marker Generation

**Objective**: Create properly formatted [EVAL] markers following established standards

#### Step 1: Marker Format Generation

Generate standardized [EVAL] markers for all approved matches:

```markdown
## Generated [EVAL] Markers

### Direct Application Markers (High Confidence)

**authentication/TASK-001: Implement token validation**
```markdown
## TASK-001: Implement token validation
[EVAL]: eval-006 (auth_token_validation)
[EVAL]: pii_leakage (security_baseline)
[EVAL]: prompt_injection (security_baseline)
[EVAL]: hallucination_detection (security_baseline)
[EVAL]: misinformation_detection (security_baseline)
```

**authentication/TASK-002: Build user login system**
```markdown
## TASK-002: Build user login system
[EVAL]: eval-006 (auth_token_validation)
[EVAL]: pii_leakage (security_baseline)
[EVAL]: prompt_injection (security_baseline)
[EVAL]: hallucination_detection (security_baseline)
[EVAL]: misinformation_detection (security_baseline)
```

**content-moderation/TASK-001: Content safety filtering**
```markdown
## TASK-001: Content safety filtering
[EVAL]: eval-003 (safety_boundary_enforcement)
[EVAL]: eval-002 (context_adherence_validation)
[EVAL]: pii_leakage (security_baseline)
[EVAL]: prompt_injection (security_baseline)
[EVAL]: hallucination_detection (security_baseline)
[EVAL]: misinformation_detection (security_baseline)
```

**payment-processing/TASK-001: Process payments securely**
```markdown
## TASK-001: Process payments securely
[EVAL]: eval-001 (regulatory_compliance_check)
[EVAL]: pii_leakage (security_baseline)
[EVAL]: prompt_injection (security_baseline)
[EVAL]: hallucination_detection (security_baseline)
[EVAL]: misinformation_detection (security_baseline)
```

### Review Required Markers (Ambiguous Matches)

**user-management/TASK-003: Handle user permissions**
```markdown
## TASK-003: Handle user permissions
⚠ AMBIGUOUS: eval-002 (context_adherence) vs eval-006 (auth_token) — review before apply
[EVAL]: pii_leakage (security_baseline)
[EVAL]: prompt_injection (security_baseline)
[EVAL]: hallucination_detection (security_baseline)
[EVAL]: misinformation_detection (security_baseline)
```

**user-management/TASK-004: Delete user accounts**
```markdown
## TASK-004: Delete user accounts
⚠ AMBIGUOUS: eval-001 (regulatory_compliance) vs eval-002 (context_adherence) — review before apply
[EVAL]: pii_leakage (security_baseline)
[EVAL]: prompt_injection (security_baseline)
[EVAL]: hallucination_detection (security_baseline)
[EVAL]: misinformation_detection (security_baseline)
```

### Coverage Gap Markers

**integration/TASK-001: Third-party API integration**
```markdown
## TASK-001: Third-party API integration
⚠ COVERAGE GAP: No domain-specific evaluations found — create integration-safety evaluation
[EVAL]: pii_leakage (security_baseline)
[EVAL]: prompt_injection (security_baseline)
[EVAL]: hallucination_detection (security_baseline)
[EVAL]: misinformation_detection (security_baseline)
```

### Marker Generation Statistics
- **Direct application markers**: 8 tasks (67%)
- **Ambiguous review markers**: 2 tasks (17%)
- **Coverage gap markers**: 2 tasks (17%)
- **Security baseline markers**: 12 tasks (100%)
- **Total markers generated**: 52 markers

**Marker Generation Status**: ✅ STANDARDIZED MARKERS READY FOR APPLICATION
```

#### Step 2: Marker Validation and Quality Check

Validate generated markers against format standards:

```markdown
## Marker Validation and Quality Check

### Format Compliance Verification

✅ **Marker Format**: All markers follow `[EVAL]: eval-id (check_name)` standard
✅ **Eval ID Validity**: All referenced eval IDs exist in published goldset
✅ **Check Name Consistency**: Check names match evaluation descriptions
✅ **Security Baseline**: All tasks include required security baseline markers
✅ **Ambiguous Marking**: Conflicts properly flagged with ⚠ AMBIGUOUS format
✅ **Coverage Gaps**: Missing coverage flagged with ⚠ COVERAGE GAP format

### Marker Quality Metrics

| Quality Aspect | Score | Status |
|----------------|-------|--------|
| **Format Standardization** | 100% | ✅ PASS |
| **Eval ID Validity** | 100% | ✅ PASS |
| **Check Name Accuracy** | 100% | ✅ PASS |
| **Conflict Detection** | 100% | ✅ PASS |
| **Coverage Completeness** | 83% | ⚠ GAPS IDENTIFIED |

### Pre-Application Checklist

- [x] All markers follow established format standards
- [x] Eval IDs reference valid published evaluations
- [x] Ambiguous matches flagged for human review
- [x] Security baseline applied to all tasks
- [x] Coverage gaps identified and flagged
- [ ] Human review completed for ambiguous matches (pending)
- [ ] Coverage gap evaluation creation (pending)

**Marker Validation Status**: ✅ READY FOR APPLICATION (pending review resolution)
```

### Phase 5: Application Decision and Execution

**Objective**: Apply markers based on mode (dry-run vs apply) and confidence levels

#### Step 1: Application Mode Decision

Determine application approach based on invocation mode:

```bash
# Application decision logic
if [[ "$DRY_RUN" == "true" || -z "$APPLY_FLAG" ]]; then
    echo "=== DRY RUN MODE: Showing proposed markers ==="
    show_proposed_markers
    echo "=== Use --apply flag to write markers to files ==="
else
    echo "=== APPLY MODE: Writing markers to task files ==="
    apply_markers_to_files
fi
```

**Application Mode Analysis**:
```markdown
## Application Mode Decision

### Current Invocation Mode
- **Command**: `/evals.tasks` (no flags specified)
- **Default Mode**: DRY RUN (manual invocation default)
- **Hook Mode**: Not active (after_tasks hook not triggered)

### Proposed Application Strategy

**Immediate Application** (High Confidence, No Conflicts):
- **8 tasks** ready for immediate marker application
- **No human review required** for these matches
- **Security baseline** auto-applied to all tasks

**Review Required Before Application** (Medium Confidence, Conflicts):
- **2 tasks** with ambiguous matches need human review
- **Review process**: Domain expert evaluation of competing evals
- **Timeline**: Review within 2-3 days before application

**Coverage Gap Resolution Required**:
- **2 tasks** with coverage gaps need new evaluation creation
- **Process**: Create missing evaluations before marker application
- **Timeline**: Evaluation creation within 1-2 weeks

### Application Decision
- **Current**: DRY RUN - Display proposed markers for review
- **Next Step**: Manual review of ambiguous cases
- **Final Application**: Run with --apply after review completion

**Application Mode Status**: ✅ DRY RUN EXECUTION (review before apply)
```

#### Step 2: File Writing Execution (if --apply mode)

Execute marker writing to task files:

```markdown
## Marker Application Execution

### File Writing Results (if --apply mode active)

**Successfully Updated Files**:
```bash
✅ specs/authentication/tasks.md - 3 tasks updated with eval markers
✅ specs/content-moderation/tasks.md - 3 tasks updated with eval markers
✅ specs/payment-processing/tasks.md - 2 tasks updated with eval markers
✅ specs/user-management/tasks.md - 2 tasks updated (2 pending review)
```

**Application Summary**:
- **Files Modified**: 4 task files
- **Tasks Updated**: 8 tasks with definitive markers
- **Tasks Pending**: 2 tasks awaiting review resolution
- **Markers Applied**: 40 total markers (32 domain + 8 security baseline)
- **Git Status**: All changes staged for commit

### Post-Application Verification

**File Integrity Check**:
```bash
# Verify marker format in applied files
grep -r "\[EVAL\]:" specs/*/tasks.md | wc -l
# Expected: 40 markers applied

# Verify no malformed markers
grep -r "\[EVAL\]:" specs/*/tasks.md | grep -v "eval-\|security_baseline"
# Expected: No results (all markers properly formatted)
```

**Quality Assurance**:
- ✅ All applied markers follow established format
- ✅ No malformed or duplicate markers detected
- ✅ Security baseline consistently applied
- ✅ File syntax and structure preserved

**Application Execution Status**: ✅ SUCCESSFUL APPLICATION (if --apply mode)
```

### Phase 6: Coverage Verification

**Objective**: Confirm comprehensive evaluation coverage across all tasks

#### Step 1: Coverage Completeness Assessment

Verify evaluation coverage meets standards and requirements:

```markdown
## Final Coverage Verification

### Coverage Completeness by Feature

| Feature | Total Tasks | Fully Covered | Coverage % | Gap Tasks |
|---------|-------------|---------------|------------|-----------|
| **authentication** | 3 | 3 | 100% | 0 |
| **content-moderation** | 3 | 3 | 100% | 0 |
| **payment-processing** | 2 | 2 | 100% | 0 |
| **user-management** | 4 | 2 | 50% | 2 (pending review) |
| **integration** | 1 | 0 | 0% | 1 (coverage gap) |

### Overall Coverage Metrics

**Comprehensive Coverage**: 8/12 tasks (67%)
- Tasks with both domain and security evaluation coverage
- Ready for implementation with full evaluation support

**Partial Coverage**: 2/12 tasks (17%)
- Security baseline coverage only
- Domain evaluations pending resolution (ambiguous matches)

**No Domain Coverage**: 2/12 tasks (17%)
- Security baseline coverage only
- Requires new evaluation creation

### Coverage Quality Assessment

**High-Risk Task Coverage**:
- Authentication: ✅ 100% coverage (security critical)
- Payment Processing: ✅ 100% coverage (regulatory critical)
- Content Moderation: ✅ 100% coverage (safety critical)

**Medium-Risk Task Coverage**:
- User Management: ⚠ 50% coverage (review needed)
- Integration: ❌ 0% domain coverage (gap identified)

### Coverage Standards Compliance

**EDD Principle I (Spec-Driven Contracts)**:
- ✅ All covered tasks have evaluations aligned to specifications
- ⚠ Coverage gaps prevent full spec validation for 2 tasks

**EDD Principle IV (Evaluation Pyramid)**:
- ✅ Tier 1 coverage: Security baseline applied universally
- ✅ Tier 2 coverage: Domain evaluations for 67% of tasks
- ⚠ Missing domain evaluations reduce pyramid effectiveness

**Coverage Verification Status**: ✅ GOOD COVERAGE WITH IDENTIFIED IMPROVEMENT AREAS
```

#### Step 2: Coverage Improvement Recommendations

Generate actionable recommendations for coverage enhancement:

```markdown
## Coverage Improvement Action Plan

### Immediate Actions (Week 1)

**Resolve Ambiguous Matches**:
1. **user-management/TASK-003**: Review eval-002 vs eval-006 for permission handling
   - **Owner**: Domain expert + AI engineering
   - **Decision Needed**: Primary evaluation selection
   - **Timeline**: 2-3 days

2. **user-management/TASK-004**: Review eval-001 vs eval-002 for account deletion
   - **Owner**: Regulatory + domain expert
   - **Decision Needed**: Regulatory vs context focus priority
   - **Timeline**: 2-3 days

### Short-Term Actions (Weeks 2-3)

**Create Missing Evaluations**:
1. **Data Handling Evaluation** (for user archival tasks)
   - **Scope**: Data retention, archival policies, cleanup procedures
   - **Owner**: AI engineering + compliance team
   - **Timeline**: 1 week development + 1 week validation

2. **Integration Safety Evaluation** (for third-party integrations)
   - **Scope**: External service risks, API security, failure handling
   - **Owner**: AI engineering + security team
   - **Timeline**: 1 week development + 1 week validation

### Medium-Term Actions (Month 2)

**Coverage Quality Enhancement**:
1. **Review Over-Evaluation**: Assess if security-critical tasks are appropriately evaluated
2. **Pattern Analysis**: Identify if other features need similar evaluation patterns
3. **Coverage Monitoring**: Establish ongoing coverage verification for new tasks

### Success Metrics

**Coverage Targets**:
- **Immediate**: Resolve 2 ambiguous matches → 75% coverage
- **Short-term**: Add 2 evaluations → 100% coverage
- **Medium-term**: Establish sustainable coverage verification process

**Quality Targets**:
- **Match Confidence**: Maintain ≥0.8 average confidence for all matches
- **Coverage Completeness**: Achieve 100% domain coverage
- **Review Efficiency**: Resolve ambiguous matches within 3 days average

**Coverage Improvement Status**: ✅ CLEAR ACTION PLAN WITH OWNERS AND TIMELINES
```

## Key Rules

### Matching Algorithm Standards

- **Keyword Threshold**: Minimum 0.7 confidence score for keyword-based matches
- **Tag Matching Priority**: Exact tag matches always override keyword matches
- **High-Value Keywords**: Security, safety, regulatory terms receive confidence boost
- **Multiple Match Handling**: All matches above threshold considered, conflicts flagged

### Marker Format Standards

- **Standard Format**: `[EVAL]: eval-id (check_name)` with consistent spacing
- **Security Baseline**: All tasks automatically receive 4 security baseline markers
- **Conflict Marking**: Use `⚠ AMBIGUOUS: eval-1 vs eval-2 — review before apply` format
- **Coverage Gaps**: Use `⚠ COVERAGE GAP: description — create evaluation` format

### Application Mode Rules

- **Default Mode**: Dry-run for manual invocation (safety first)
- **Hook Mode**: Auto-apply when triggered by after_tasks hook
- **Apply Flag**: Explicit --apply required for manual marker writing
- **Review Gates**: Ambiguous matches must be resolved before application

### Coverage Standards

- **Minimum Coverage**: All tasks must have security baseline evaluations
- **Domain Coverage**: High-risk tasks require domain-specific evaluations
- **Gap Tolerance**: Maximum 20% coverage gaps acceptable before creation required
- **Over-Evaluation**: Security-critical tasks may have multiple domain evaluations

## Workflow Guidance & Transitions

### After `/evals.tasks`

**Success Path**: Evaluation markers successfully matched and applied to feature tasks.

**Follow-up Actions**:
- **Resolve Ambiguous Matches**: Human review of conflicting evaluations
- **Create Missing Evaluations**: Address coverage gaps through new evaluation creation
- **Validation Integration**: Run `/evals.validate` to verify coverage effectiveness

**Complete Tasks Flow**:

```
/evals.tasks "Match evaluations to all feature tasks"
    ↓
[Discovery phase] → Inventory published evals and feature tasks
    ↓
[Matching analysis] → Keyword + tag matching with confidence scoring
    ↓
[Conflict detection] → Identify ambiguous matches for human review
    ↓
[Coverage analysis] → Detect gaps and over-evaluation patterns
    ↓
[Marker generation] → Create standardized [EVAL] markers
    ↓
[Application decision] → Dry-run vs apply based on mode and confidence
    ↓
[Coverage verification] → Confirm comprehensive evaluation coverage
```

### Integration with Other Commands

**Hook Integration**:
- Triggered by `after_tasks` hook automatically
- Auto-applies markers without manual intervention

**Validation Integration**:
- `/evals.validate` uses applied markers to verify task coverage
- Ensures evaluation system covers all implementation tasks

**Implementation Integration**:
- `/evals.implement` generates evaluators for all marked evaluation IDs
- Creates comprehensive evaluation pipeline based on task coverage

### When to Use This Command

- **After task definition**: When new feature tasks are defined in specs/
- **After evaluation creation**: When new evaluations are published to goldset
- **Hook trigger**: Automatically after task specification changes
- **Coverage review**: Periodic verification of evaluation-task alignment

### When NOT to Use This Command

- **Before evaluation publishing**: Requires published evaluations in goldset
- **During evaluation development**: Use after evaluations are finalized
- **Without tasks**: Requires feature tasks defined in specs/ directories

## Context

{ARGS}