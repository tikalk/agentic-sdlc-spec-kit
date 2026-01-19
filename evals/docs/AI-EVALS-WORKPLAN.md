# AI Evals Work Plan for Agentic SDLC Spec Kit

**Purpose:** Apply proven AI evaluation practices to our Agentic SDLC Spec Kit project.

---

## 🚀 Implementation Progress (MVP Approach)

**Strategy:** Implement minimum viable features for each step, expand later as time permits.

### 📊 Current Status Summary

**Overall Progress:** 5/5 core weeks completed (100%) ✅

| Phase | Status | Pass Rate |
|-------|--------|-----------|
| Week 1: Error Analysis Foundation | ✅ Complete | **Plan Analysis: 100% (2/2)** |
| Week 2-3: Custom Annotation Tool | ✅ Complete | - |
| Week 4: Extend PromptFoo | ✅ Complete | **100% (10/10 tests)** |
| Week 5: GitHub Actions CI/CD | ✅ Complete | - |
| Week 5-6: Production Monitoring | 📋 Optional | - |

**Latest Evaluation Results:**
- **Spec Template Tests:** 8/8 passed (100%)
- **Plan Template Tests:** 2/2 passed (100%)
- **Overall:** 10/10 tests passing (100%)

### Week 1: Error Analysis Foundation ✅ **COMPLETED**
- **Directory structure** created: `evals/notebooks/`, `evals/datasets/`
- **Test data generation script** created: `evals/scripts/generate-test-data.sh`
- **Error analysis notebook** created: `evals/notebooks/error-analysis.ipynb`
- **Environment setup** using uv: `evals/scripts/run-error-analysis.sh`
- **Automated error analysis for specs** created: `evals/scripts/run-auto-error-analysis.sh`
- **Automated error analysis for plans** created: `evals/scripts/run-auto-plan-analysis.sh`
- **Real test specs generated** - 17 specs in `evals/datasets/real-specs/`
- **Real test plans generated** - 2 plans in `evals/datasets/real-plans/` (expandable)
- **First error analysis session** - Completed through PromptFoo evaluation runs
- **Plan error analysis results** - 100% pass rate on initial test cases
- **Document findings** - Results documented in this file and README

### Week 2-3: Custom Annotation Tool 📋 ✅ **COMPLETED**
- Basic FastHTML annotation app (MVP)
- Keyboard shortcuts (N, P, 1, 2)
- Export to JSON
- Progress tracking with statistics
- Auto-save functionality
- Beautiful markdown rendering
- Notes support for each spec
- Launch script in evals/scripts/

### Week 4: Extend PromptFoo ✅ **COMPLETED**
- **Ran comprehensive evaluation** - All 10 tests executed
- **Identified failures** - 3 initial failures documented
- **Fixed prompts iteratively** - 2 rounds of refinements
- **Achieved 100% pass rate** - 10/10 tests passing

### Week 5-6: Production Monitoring 📈 **TODO (NOT MANDATORY)**
- [ ] Async evaluation script (vanilla Python)
- [ ] Simple alerting mechanism

### Week 5: GitHub Actions Integration 🔄 ✅ **COMPLETED**
- [x] Add GitHub Action for running evals on PR
- [x] Add threshold checks to fail PR if quality drops
- [x] Add automated reporting
- [x] Create comprehensive setup documentation
- [x] Add status badge to README
- [x] Configure PR commenting for results

---

## Table of Contents

1. [Tool Strategy & Current State](#1-tool-strategy--current-state) ⭐ **START HERE**
2. [Foundation & Strategy](#2-foundation--strategy)
3. [Evaluation Infrastructure](#3-evaluation-infrastructure)
4. [Data & Datasets](#4-data--datasets)
5. [Error Analysis & Debugging](#5-error-analysis--debugging)
6. [Evaluators & Metrics](#6-evaluators--metrics)
7. [RAG & Retrieval Evaluation](#7-rag--retrieval-evaluation)
8. [Agentic Workflows](#8-agentic-workflows)
9. [CI/CD & Production Monitoring](#9-cicd--production-monitoring) ⭐ **GitHub Actions + Optional Production**
10. [Team & Process](#10-team--process)
11. [Tools & Vendors](#11-tools--vendors)

---

## 1. Tool Strategy & Current State

### Hybrid Tool Strategy 🎯

Use **different tools for different purposes**:

| Purpose | Tool | Why | Priority |
|---------|------|-----|----------|
| **Error Analysis** | Jupyter Notebooks | Flexible, exploratory, visualization | 🔥 **CRITICAL** |
| **Fast Annotation** | Custom FastHTML App | 10x faster than manual review | 🔥 **HIGH** |
| **CI/CD Template Testing** | PromptFoo (keep existing) | Fast, deterministic regression tests | ✅ **Keep** |
| **Production Monitoring** | Vanilla Python + Vendor | Async, streaming, alerting | 🔥 **HIGH** |
| **LLM-as-Judge Building** | Notebooks → PromptFoo | Prototype → Productionize | **MEDIUM** |

### What NOT to Do ❌

Per the FAQ, **avoid these common mistakes**:

1. ❌ **Don't rely only on PromptFoo**
2. ❌ **Don't use generic eval metrics from PromptFoo**
3. ❌ **Don't skip error analysis**
4. ❌ **Don't build annotation UI in PromptFoo**

### Quick Start: What to Do Now

**Week 1 (START HERE):**
```bash
# 1. Generate REAL test data (not synthetic prompts)
mkdir -p evals/datasets/real-specs
for i in {1..100}; do
  # Use diverse prompts
  specify init "test-$i" --ai claude
  cp test-$i/.specify/specs/*/spec.md evals/datasets/real-specs/spec-$i.md
done

# 2. Create error analysis notebook
jupyter lab evals/notebooks/error-analysis.ipynb
# - Load 100 real specs
# - Domain expert notes failures (open coding)
# - Categorize into taxonomy (axial coding)
# - Count failure modes

# 3. Keep running PromptFoo for CI
npx promptfoo eval  # This tests TEMPLATES, not real outputs
```

**Week 2-3:**
```bash
# Build custom annotation tool
cd evals/annotation-tool
uv venv
uv pip install fasthtml
python app.py  # Start annotation server
```

**Week 4:**
```bash
# Extend PromptFoo based on discovered failures
# Add new tests to evals/configs/promptfooconfig-spec.js or promptfooconfig-plan.js
# Add new graders to evals/graders/custom_graders.py
```
