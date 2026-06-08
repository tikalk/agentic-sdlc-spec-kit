# EDD Components vs Internal Evaluation Systems - Usage Guide

## Overview

This repository contains **two separate evaluation systems** with different purposes. Understanding when to use each is crucial for proper implementation.

---

## 📋 **Internal Evaluation System** (`evals/configs/`)

### Purpose
- **Evaluates the quality of the prompt templates** in this repository
- Tests whether `spec-prompt.txt`, `plan-prompt.txt`, `arch-prompt.txt`, etc. generate good outputs
- **Quality assurance for the toolkit itself**

### Structure
```
evals/
├── configs/
│   ├── promptfooconfig.js           # Main evaluation config
│   ├── promptfooconfig-spec.js      # Tests spec-prompt.txt quality
│   ├── promptfooconfig-plan.js      # Tests plan-prompt.txt quality
│   ├── promptfooconfig-arch.js      # Tests arch-prompt.txt quality
│   ├── promptfooconfig-ext.js       # Tests ext-prompt.txt quality
│   └── promptfooconfig-clarify.js   # Tests clarify-prompt.txt quality
├── graders/
│   └── custom_graders.py            # Custom graders for prompt quality
└── prompts/
    ├── spec-prompt.txt              # The actual prompts being tested
    ├── plan-prompt.txt
    └── ...
```

### When to Use
- ✅ Testing if your prompt templates generate good specifications
- ✅ Regression testing after modifying prompts
- ✅ Quality assurance for the toolkit development
- ✅ Ensuring prompts follow best practices

---

## 🛡️ **EDD Components** (`evals/edd-components/`)

### Purpose
- **Framework for evaluating external projects** that use this toolkit
- Security baseline checks, compliance validation, etc.
- **Methodology for others to implement in their projects**

### Structure
```
evals/
├── edd-components/
│   ├── graders/
│   │   ├── check_pii_leakage.py           # Security grader
│   │   ├── check_prompt_injection.py      # Security grader
│   │   ├── check_hallucination.py         # Security grader
│   │   ├── check_misinformation.py        # Security grader
│   │   ├── check_regulatory_compliance.py # Compliance grader
│   │   └── check_context_adherence.py     # Context grader
│   ├── configs/
│   │   ├── config.js                      # EDD example config
│   │   ├── config-tier1.js                # Tier 1 (fast) evaluations
│   │   └── config-tier2.js                # Tier 2 (semantic) evaluations
│   └── goldset/
│       └── goldset.csv                    # Reference test data
└── scripts/
    ├── edd_failure_routing.py             # EDD failure routing
    └── audit_binary_compliance.py         # EDD compliance audit
```

### When to Use
- ✅ **External teams** implementing this toolkit in their projects
- ✅ Evaluating **AI systems built using the prompts** from this toolkit
- ✅ Security baseline validation for production AI systems
- ✅ Compliance checking for regulated industries

---

## 🔄 **Command Alignment Across Extensions**

All extensions in Spec Kit follow a consistent workflow pattern:

| Step | `/architect.*` | `/levelup.*` | `/evals.*` | Purpose |
|------|---------------|--------------|-----------|---------|
| **1. Initialize** | `/architect.init` | — | `/evals.init` | Reverse-engineer from existing codebase (brownfield) |
| **2. Specify** | `/architect.specify` | `/levelup.specify` | `/evals.specify` | Extract core artifacts (ADRs, CDRs, eval criteria) from spec |
| **3. Clarify** | `/architect.clarify` | `/levelup.clarify` | `/evals.clarify` | Resolve ambiguities through interactive questions |
| **4. Implement** | `/architect.implement` | `/levelup.implement` | `/evals.implement` | Generate final outputs (AD.md, skills, PromptFoo config) |
| **5. Validate** | `/architect.validate` | — | `/evals.validate` | Validate alignment/quality (READ-ONLY for architect) |
| **6. Analyze/Trace** | `/architect.analyze` | `/spec.trace` | `/evals.analyze` | Post-implementation analysis and reporting |

### Pattern Summary

**Common workflow**:
1. **init** (optional, brownfield only) →
2. **specify** (extract) →
3. **clarify** (refine) →
4. **implement** (generate) →
5. **validate/trace** (verify/analyze)

**Key differences**:
- **`/architect.*`**: Focuses on architectural decisions (ADRs → AD.md)
- **`/levelup.*`**: Focuses on coding directives (CDRs → skills → team-ai-directives)
- **`/evals.*`**: Focuses on evaluation criteria (goldset → PromptFoo config → test results)
