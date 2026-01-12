# AI Evals Work Plan for Agentic SDLC Spec Kit

**Created:** 2026-01-07
**Source:** AI Evals - Frequently Asked Questions.pdf by Hamel Husain and Shreya Shankar
**Purpose:** Apply proven AI evaluation practices to our Agentic SDLC Spec Kit project

---

## 🚀 Implementation Progress (MVP Approach)

**Strategy:** Implement minimum viable features for each step, expand later as time permits.

### 📊 Current Status Summary (Updated: 2026-01-12)

**Overall Progress:** 4/5 weeks completed (80%)

| Phase | Status | Pass Rate |
|-------|--------|-----------|
| Week 1: Error Analysis Foundation | ✅ Complete | **Plan Analysis: 100% (2/2)** |
| Week 2-3: Custom Annotation Tool | ✅ Complete | - |
| Week 4: Extend PromptFoo | ✅ Complete | **90% (9/10 tests)** |
| Week 5: GitHub Actions CI/CD | 📋 TODO | - |
| Week 5-6: Production Monitoring | 📋 Optional | - |

**Latest Evaluation Results (2026-01-12):**
- **Spec Template Tests:** 7/8 passed (87.5%)
- **Plan Template Tests:** 2/2 passed (100%) ✅ **Infrastructure completed today**
- **Plan Error Analysis:** 2/2 passed (100%) ✅ **NEW - automated analysis ready**
- **Overall:** 9/10 tests passing (90%)
- **Improvement:** +20% from initial 70% baseline

**Key Achievements:**
- ✅ Fixed security requirements coverage
- ✅ Fixed plan simplicity constraints
- ✅ Fixed e-commerce completeness
- ✅ Maintained quality while adding guidance
- ✅ **NEW**: Plan error analysis infrastructure complete (2026-01-12)
  - Automated plan evaluation scripts operational
  - 100% pass rate on initial test cases
  - Ready for expansion to 10-20 test scenarios
- ⚠️ 1 minor regression (vague term handling) - acceptable trade-off

### 🎯 Latest Addition: Plan Error Analysis Foundation (2026-01-12)

Successfully extended error analysis infrastructure to support **implementation plan evaluation**.

**What Was Built:**
- ✅ `generate-real-plans.py` - Generate plan test data from eval results
- ✅ `run-automated-plan-analysis.py` - Claude-powered automated plan evaluation
- ✅ `run-auto-plan-analysis.sh` - Shell wrapper for easy execution
- ✅ 2 initial test cases in `evals/datasets/real-plans/`
- ✅ Plan-specific evaluation criteria (simplicity gate, constitution compliance)
- ✅ Automated failure categorization and reporting

**Results:**
- 100% pass rate on 2 initial test cases
- Project count analysis working (1 project for simple apps ✓)
- Constitution compliance verified (no over-engineering detected)
- Integration with existing PromptFoo plan tests (2/2 passing)

**Common Failure Categories Identified:**
- Too many projects (>3)
- Over-engineering
- Missing verification steps
- Unclear project boundaries
- Microservices for simple apps
- Premature optimization
- Missing testing strategy

**Next Steps:**
- Expand test cases to 10-20 diverse scenarios
- Add negative test cases (should fail)
- Test edge cases (exactly 3 projects)
- Integrate with GitHub Actions (Week 5)

### Week 1: Error Analysis Foundation ✅ **COMPLETED**
- [x] **Directory structure** created: `evals/notebooks/`, `evals/datasets/`
- [x] **Test data generation script** created: `evals/scripts/generate-test-data.sh`
  - Generated 17 diverse test case templates (can expand to 100+ later)
  - Covers: simple/medium/complex, web/api/enterprise, multiple tech stacks
- [x] **Error analysis notebook** created: `evals/notebooks/error-analysis.ipynb`
  - MVP: Manual review workflow with open coding → axial coding
  - Dataframe-based analysis with visualization
- [x] **Environment setup** using uv: `evals/scripts/run-error-analysis.sh`
- [x] **Automated error analysis for specs** created: `evals/scripts/run-auto-error-analysis.sh`
  - Uses Claude API to automatically evaluate specs
  - Binary pass/fail with categorization
  - Generates detailed CSV reports and summaries
  - Alternative to manual Jupyter workflow
- [x] **Automated error analysis for plans** created: `evals/scripts/run-auto-plan-analysis.sh`
  - Plan-specific error analysis infrastructure
  - Evaluates simplicity gate (≤3 projects), constitution compliance
  - Automated categorization of plan failures
  - `evals/scripts/run-automated-plan-analysis.py` for execution
  - `evals/scripts/generate-real-plans.py` for test data generation
- [x] **Real test specs generated** - 17 specs in `evals/datasets/real-specs/`
- [x] **Real test plans generated** - 2 plans in `evals/datasets/real-plans/` (expandable)
- [x] **First error analysis session** - Completed through PromptFoo evaluation runs
  - Identified 3 initial failures, fixed iteratively
  - Documented in evaluation reports
- [x] **Plan error analysis results** - 100% pass rate on initial test cases
  - Project count analysis (1 project for simple apps ✓)
  - Constitution compliance verified
  - Analysis reports generated
- [x] **Document findings** - Results documented in this file and README

**Status:** Week 1 infrastructure completed and actively used in Week 4 evaluation work. Plan error analysis foundation added 2026-01-12.

### Week 2-3: Custom Annotation Tool 📋 ✅ **COMPLETED**
- [x] Basic FastHTML annotation app (MVP)
- [x] Keyboard shortcuts (N, P, 1, 2)
- [x] Export to JSON
- [x] Progress tracking with statistics
- [x] Auto-save functionality
- [x] Beautiful markdown rendering
- [x] Notes support for each spec
- [x] Launch script in evals/scripts/

### Week 4: Extend PromptFoo ✅ **COMPLETED**
- [x] **Ran comprehensive evaluation** - All 10 tests executed
- [x] **Identified failures** - 3 initial failures documented
- [x] **Fixed prompts iteratively** - 2 rounds of refinements
- [x] **Achieved 90% pass rate** - 9/10 tests passing
- [x] **Results:**
  - Test #5 (Payment Security): Fixed ✅
  - Test #1 (Plan Simplicity): Fixed ✅
  - Test #7 (E-commerce Completeness): Fixed ✅
  - Test #2, #6: Regressions fixed ✅
  - Test #4 (Vague Terms): 1 remaining failure (acceptable trade-off)
- [x] **Prompt improvements:**
  - Enhanced security requirements guidance (balanced, non-prescriptive)
  - Enhanced edge cases for multi-step flows
  - Strengthened simplicity constraints for plans
  - Explicit section heading requirements

### Week 5-6: Production Monitoring 📈 **TODO (NOT MANDATORY)**
- [ ] Async evaluation script (vanilla Python)
- [ ] Simple alerting mechanism

### Week 5: GitHub Actions Integration 🔄 **TODO**
- [ ] Add GitHub Action for running evals on PR
- [ ] Add threshold checks to fail PR if quality drops
- [ ] Add automated reporting

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

### What You Already Have ✅

You've already set up a **solid foundation** with:

```bash
# Existing setup (already working)
evals/
├── README.md                       # Full documentation
├── configs/                        # Configuration files
│   ├── promptfooconfig.js          # Main config with all tests
│   ├── promptfooconfig-spec.js     # Spec-specific tests
│   └── promptfooconfig-plan.js     # Plan-specific tests
├── prompts/                        # Test prompts
│   ├── spec-prompt.txt             # Spec template test prompt
│   └── plan-prompt.txt             # Plan template test prompt
├── graders/                        # Custom evaluators
│   └── custom_graders.py           # Python graders (security, simplicity, etc.)
└── scripts/                        # Automation scripts
    ├── run-eval.sh                 # Runner script
    └── check_eval_scores.py        # Threshold validation
```

**Current coverage:**
- ✅ Template structure validation
- ✅ Constitution compliance (no over-engineering)
- ✅ Security requirement checks
- ✅ CI/CD-ready with threshold enforcement

### The Gap: What's Missing (Per FAQ) ⚠️

According to the FAQ, **PromptFoo alone is only ~20% of what you need**:

> "We spent 60-80% of our development time on error analysis and evaluation. Expect most of your effort to go toward understanding failures (i.e. looking at data) rather than building automated checks."

**What you're missing:**
- ❌ **Error analysis on REAL outputs** (not synthetic test prompts)
- ❌ **Custom annotation tool** (FAQ: "10x faster iteration")
- ❌ **Production monitoring** (async eval of live generations)
- ❌ **Failure taxonomy** (categorizing real failure modes)

### Hybrid Tool Strategy 🎯

Use **different tools for different purposes**:

| Purpose | Tool | Why | Priority |
|---------|------|-----|----------|
| **Error Analysis** | Jupyter Notebooks | Flexible, exploratory, visualization | 🔥 **CRITICAL** |
| **Fast Annotation** | Custom FastHTML App | 10x faster than manual review | 🔥 **HIGH** |
| **CI/CD Template Testing** | PromptFoo (keep existing) | Fast, deterministic regression tests | ✅ **Keep** |
| **Production Monitoring** | Vanilla Python + Vendor | Async, streaming, alerting | 🔥 **HIGH** |
| **LLM-as-Judge Building** | Notebooks → PromptFoo | Prototype → Productionize | **MEDIUM** |

### The FAQ's Core Message 💡

> "Use notebooks to help you review traces and analyze data. In our opinion, this is the single most effective tool for evals because you can write arbitrary code, visualize data, and iterate quickly."

> "Build a custom annotation tool. This is the single most impactful investment you can make for your AI evaluation workflow... teams with custom annotation tools iterate ~10x faster."

### What Each Tool Does Best

#### **1. PromptFoo (Keep & Extend)**
**Current use:** Testing template quality with synthetic prompts
**Config location:** `evals/configs/`
```bash
# What it's good for:
✅ CI/CD regression tests (fast, cheap)
✅ Template structure validation
✅ Constitution compliance checks
✅ Deterministic assertions

# What it CAN'T do:
❌ Review REAL generated specs/plans
❌ Interactive error analysis
❌ Custom annotation UI
❌ Production monitoring (it's synchronous)
```

#### **2. Jupyter Notebooks (Add - Week 1)**
**New use:** Error analysis on real outputs (THE most important activity)
```bash
# Create:
evals/notebooks/
├── error-analysis.ipynb           # Main workflow
├── review-specs.ipynb             # Review 100 real specs
├── review-plans.ipynb             # Review 100 real plans
└── failure-taxonomy.ipynb         # Categorize failures

# What it's good for:
✅ Open coding (noting failures)
✅ Axial coding (categorizing failures)
✅ Data visualization
✅ Exploratory analysis
✅ Building LLM-as-Judge prototypes

# Example workflow:
1. Generate 100 real specs with diverse prompts
2. Load into notebook
3. Domain expert reviews, notes issues
4. LLM helps categorize into taxonomy
5. Count frequency of each failure mode
6. Prioritize fixes by impact
```

#### **3. Custom FastHTML App (Add - Week 2-3)**
**New use:** Fast, keyboard-driven annotation of outputs
```bash
# Create:
evals/annotation-tool/
├── app.py                         # FastHTML server
├── requirements.txt
└── templates/
    └── review.html                # Review interface

# What it's good for:
✅ 10x faster than manual review
✅ Keyboard shortcuts (N, P, 1, 2)
✅ Progress tracking
✅ Side-by-side comparison
✅ Export annotations → dataset

# Features (per FAQ):
- Render specs/plans beautifully
- Binary pass/fail (no Likert scales)
- Keyboard navigation
- Cluster similar failures
- Export to JSON for analysis
```

#### **4. Vanilla Python (Add - Week 5-6)**
**New use:** Production monitoring and async evaluation
```bash
# Create:
evals/monitoring/
├── sample-production.py           # Sample live traces
├── run-evals-async.py            # Async LLM-as-Judge
├── alert-on-failures.py          # Quality alerts
└── dashboard.py                   # Real-time metrics

# What it's good for:
✅ Async evaluation of live generations
✅ Streaming trace analysis
✅ Alerting when quality drops
✅ Production metrics dashboard

# Why not PromptFoo:
- PromptFoo is synchronous (blocks on each test)
- Production needs async, non-blocking evals
- Need custom sampling strategies
- Need to integrate with observability tools
```

### Decision Matrix: When to Use What

```yaml
Scenario: "I want to test if templates have required sections"
Tool: PromptFoo (already set up)
Why: Fast, deterministic, good for CI/CD

Scenario: "I need to understand why 30% of generated specs fail"
Tool: Jupyter Notebook (NEW)
Why: Error analysis requires exploration and visualization

Scenario: "I need to review 100 real specs and mark pass/fail"
Tool: Custom FastHTML App (NEW)
Why: 10x faster with keyboard shortcuts and progress tracking

Scenario: "I want to monitor quality of live spec generations"
Tool: Vanilla Python + optional vendor (NEW)
Why: Async, streaming, production-grade

Scenario: "I want to prevent template regressions"
Tool: PromptFoo (KEEP)
Why: Already working well for this

Scenario: "I want to build a new LLM-as-Judge evaluator"
Tool: Prototype in Notebook → Productionize in PromptFoo (HYBRID)
Why: Fast iteration → Stable automation
```

### What NOT to Do ❌

Per the FAQ, **avoid these common mistakes**:

1. ❌ **Don't rely only on PromptFoo**
   - It tests synthetic prompts, not REAL outputs
   - Can't do interactive error analysis
   - No custom UI for fast review

2. ❌ **Don't use generic eval metrics from PromptFoo**
   - Ignore "helpfulness", "toxicity", "coherence" (not domain-specific)
   - Build custom graders for YOUR failure modes (you're already doing this ✓)

3. ❌ **Don't skip error analysis**
   - This is #1 most important activity (per FAQ)
   - Can't be automated - needs human domain expert
   - Use notebooks, not PromptFoo

4. ❌ **Don't build annotation UI in PromptFoo**
   - PromptFoo's UI is for test results, not annotation
   - Build custom FastHTML app instead

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

---

## 2. Foundation & Strategy

### Q: What are LLM Evals?
**Context:** Our spec kit generates specs, plans, and tasks. We need to validate quality at each phase.

**Action Items:**
- [ ] **Define eval levels for our workflow:**
  - Level 1: Unit tests for spec/plan/task generation (deterministic checks)
  - Level 2: Human & model evaluation of spec quality
  - Level 3: A/B testing different prompt strategies
- [ ] **Document our eval philosophy** in `docs/evaluation-philosophy.md`
- [ ] **Identify key failure modes** for each workflow phase:
  - `/speckit.specify`: Incomplete requirements, ambiguous user stories
  - `/speckit.plan`: Over-engineering, missing tech stack details
  - `/speckit.tasks`: Incorrect dependencies, missing steps
  - `/speckit.implement`: Code quality issues, failed tests

**Priority:** HIGH (Foundation for everything else)
**Timeline:** Week 1

---

### Q: How much of my development budget should I allocate to evals?
**Context:** We need to balance evaluation investment with feature development.

**Action Items:**
- [ ] **Expect 60-80% of development time** on error analysis and evaluation
- [ ] **Track time spent** on eval activities vs feature work for one sprint
- [ ] **Focus on error analysis** (looking at data) rather than building complex automated checks
- [ ] **Avoid optimizing for 100% pass rates** - aim for 70% as meaningful validation
- [ ] **Document cost-benefit analysis** for each evaluator we build

**Priority:** MEDIUM
**Timeline:** Ongoing monitoring

---

## 3. Evaluation Infrastructure

### Q: Should I build a custom annotation tool or use something off-the-shelf?
**Context:** We need to review spec/plan/task quality efficiently.

**Action Items:**
- [ ] **Build a custom annotation tool** for reviewing generated artifacts
  - Use FastHTML or similar lightweight framework
  - Show spec, plan, and tasks side-by-side
  - Render markdown beautifully
  - Add keyboard shortcuts (N for next, P for previous, 1/2 for pass/fail)
  - Include progress indicators
- [ ] **Key features to implement:**
  - Intelligent rendering (syntax highlighting for code blocks)
  - Collapsible sections for long specs
  - Filtering by failure mode
  - Semantic search for similar issues
  - Export annotations to dataset
- [ ] **Start simple:** Notebook-based review first, then custom UI

**Priority:** HIGH
**Timeline:** Week 2-3
**Effort:** ~10-20 hours with AI assistance

---

### Q: What gaps in eval tooling should I be prepared to fill myself?
**Context:** Off-the-shelf tools won't capture our domain-specific needs.

**Action Items:**
- [ ] **1. Error Analysis & Pattern Discovery**
  - Build clustering for similar spec failures
  - AI-powered categorization of failure modes
  - Semantic search for finding related issues
- [ ] **2. AI-Powered Assistance**
  - LLM helps categorize observations into failure taxonomies
  - AI suggests prompt fixes based on failure patterns
  - Use Julius/Hex/SolveIt for data analysis of annotations
- [ ] **3. Custom Evaluators**
  - Build spec-specific metrics (completeness, clarity, testability)
  - Plan-specific metrics (dependency correctness, tech stack alignment)
  - Task-specific metrics (execution order, file path accuracy)
- [ ] **4. APIs for Custom Annotation Apps**
  - Design data export/import APIs
  - Bulk annotation support
  - Integration with our `specify` CLI

**Priority:** HIGH
**Timeline:** Weeks 3-6

---

### Q: What makes a good custom interface for reviewing LLM outputs?
**Context:** We need fast, clear, and motivating review experience.

**Action Items:**
- [ ] **1. Intelligent Rendering**
  - Render specs as structured documents with TOC
  - Syntax highlight code in plans
  - Show task dependencies as graphs
- [ ] **2. Progress & Keyboard Navigation**
  - "Trace 45 of 100" progress bar
  - Hotkeys: N (next), P (prev), 1 (pass), 2 (fail), D (defer)
- [ ] **3. Clustering & Search**
  - Group similar spec failures
  - Filter by phase (specify, plan, tasks)
  - Search by keyword or semantic similarity
- [ ] **4. Prioritize Problematic Cases**
  - Surface specs flagged by automated checks
  - Show CI failure traces first
  - Display eval scores inline
- [ ] **5. Keep It Minimal**
  - Only add features that provide clear value
  - Start with notebooks, evolve to custom UI

**Priority:** MEDIUM
**Timeline:** Week 3-4

---

## 4. Data & Datasets

### Q: What is the best approach for generating synthetic data?
**Context:** We need diverse test cases for spec/plan/task generation.

**Action Items:**
- [ ] **Define dimensions for test queries:**
  - Project complexity: simple, medium, complex, enterprise
  - Domain: web app, mobile, API, data pipeline, infrastructure
  - Tech stack: .NET, Node.js, Python, Go, polyglot
  - Team size: solo, small team, large org
  - Constraints: time-critical, compliance-heavy, legacy integration
- [ ] **Generate tuples** (combinations of dimensions):
  - Example: (Complex, Web App, .NET, Large Org, Compliance-heavy)
  - Write 20 tuples manually first
  - Use LLM to generate 100+ tuples
- [ ] **Two-step generation:**
  - Step 1: LLM generates structured tuples
  - Step 2: Convert tuples to natural language prompts
- [ ] **Run synthetic queries through pipeline** to capture full traces
- [ ] **Sample 100 traces** for error analysis (not thousands)
- [ ] **Don't generate synthetic data for trivial issues** - fix the prompt first

**Priority:** HIGH
**Timeline:** Week 2
**Effort:** 1-2 days

---

### Q: How can I efficiently sample production traces for review?
**Context:** Need to find problematic specs/plans without reviewing everything.

**Action Items:**
- [ ] **Outlier detection:** Sort by length, complexity score, generation time
- [ ] **User feedback signals:** Prioritize specs with negative feedback or failed implementations
- [ ] **Metric-based sorting:** Use generic metrics as exploration signals (not evaluation)
- [ ] **Stratified sampling:** Sample across dimensions (project type, tech stack, complexity)
- [ ] **Build sampling features into annotation tool**

**Priority:** MEDIUM
**Timeline:** Week 4

---

## 5. Error Analysis & Debugging

### Q: Why is "error analysis" so important in LLM evals, and how is it performed?
**Context:** This is THE MOST IMPORTANT activity for improving our system.

**Action Items:**
- [ ] **Establish error analysis workflow:**
  1. **Create dataset:** Gather 100 representative specs/plans/tasks
  2. **Open coding:** Domain expert reviews and notes issues (journaling style)
  3. **Axial coding:** Group similar failures into categories/taxonomy
  4. **Iterative refinement:** Continue until theoretical saturation (no new patterns)
- [ ] **For each phase, identify failure modes:**
  - Specify phase: Incomplete requirements, ambiguous stories, missing constraints
  - Plan phase: Over-engineering, tech stack mismatch, missing details
  - Tasks phase: Wrong dependencies, missing steps, incorrect file paths
  - Implement phase: Code quality, test coverage, runtime errors
- [ ] **Designate "benevolent dictator"** - single domain expert for quality standards
- [ ] **Use LLMs to help with categorization** and pattern discovery
- [ ] **Count failures in each category** to prioritize fixes
- [ ] **Revisit error analysis regularly** (monthly or per major feature)

**Priority:** CRITICAL (Start here!)
**Timeline:** Week 1 (ongoing)
**Effort:** 30-60 mins per review session, ~100 traces to start

---

### Q: How do I debug multi-turn conversation traces?
**Context:** Our workflow spans multiple commands (/specify → /plan → /tasks → /implement).

**Action Items:**
- [ ] **Start simple:** Check if whole workflow achieved user's goal (pass/fail)
- [ ] **Focus on first upstream failure:**
  - If plan is wrong, check if spec was incomplete
  - If tasks are wrong, check if plan was unclear
- [ ] **Reproduce with simplest test case:**
  - Don't debug full workflow if single-command issue
  - Example: If plan fails, test just `/speckit.plan` with fixed spec
- [ ] **Generate test cases:**
  - N-1 testing: Use first N-1 commands from real trace, test Nth
  - User simulation: Generate synthetic multi-turn conversations
- [ ] **Balance thoroughness with efficiency** - not every multi-turn failure needs full analysis

**Priority:** HIGH
**Timeline:** Week 2

---

### Q: How do I approach evaluation when my system handles diverse user queries?
**Context:** We handle simple apps, complex enterprise systems, various tech stacks.

**Action Items:**
- [ ] **Start with error analysis** (not predetermined query classifications)
- [ ] **Let failure patterns emerge organically:**
  - Maybe all "real-time" requirements fail similarly
  - Maybe "microservices" architectures have consistent issues
- [ ] **Group by discovered patterns, not assumptions:**
  - Could be tech stack, complexity, domain, or something unexpected
- [ ] **Don't create massive eval matrix upfront**
- [ ] **Let real behavior guide evaluation priorities**

**Priority:** MEDIUM
**Timeline:** Week 3

---

## 6. Evaluators & Metrics

### Q: Why do you recommend binary (pass/fail) evaluations instead of 1-5 ratings?
**Context:** Need clear, consistent evaluation criteria.

**Action Items:**
- [ ] **Use binary pass/fail for all evaluations:**
  - Spec quality: Pass/Fail (not 1-5)
  - Plan completeness: Pass/Fail
  - Task correctness: Pass/Fail
- [ ] **For granular measurement:**
  - Break into multiple binary checks
  - Example: "5 out of 7 required sections present" = 5 individual binary checks
- [ ] **Benefits we'll gain:**
  - Faster annotation (no debating 3 vs 4)
  - More consistent across reviewers
  - Forces clear decisions
  - Smaller sample sizes for statistical significance

**Priority:** HIGH
**Timeline:** Week 1 (design decision)

---

### Q: Should I build automated evaluators for every failure mode I find?
**Context:** Need to balance automation cost with value.

**Action Items:**
- [ ] **Focus on failures that persist after prompt fixes**
- [ ] **Use cost hierarchy:**
  - **Cheap:** Assertions, regex, structural validation (build these)
  - **Expensive:** LLM-as-Judge (only for persistent generalization failures)
- [ ] **Only build for problems we'll iterate on repeatedly**
- [ ] **Example cheap checks for our domain:**
  - Spec has all required sections
  - Plan references existing tech stack from spec
  - Tasks include file paths
  - No circular dependencies in tasks
- [ ] **Example expensive checks (LLM-as-Judge):**
  - Spec clarity and completeness
  - Plan appropriateness for requirements
  - Task order correctness

**Priority:** HIGH
**Timeline:** Week 2-3

---

### Q: Can I use the same model for both the main task and evaluation?
**Context:** We use Claude/Gemini/Copilot for generation, can we use same for judging?

**Action Items:**
- [ ] **Yes, same model is fine** for LLM-as-Judge
  - Judge does different task (binary classification)
  - Focus on TPR/TNR on held-out test set
- [ ] **Start with most capable models** (Claude Opus, etc.)
- [ ] **Optimize for cost later** once judges are validated
- [ ] **Don't use same model for open-ended quality ratings**

**Priority:** LOW
**Timeline:** Week 4+

---

### Q: Are similarity metrics (BERTScore, ROUGE, etc.) useful for evaluating LLM outputs?
**Context:** Should we use semantic similarity for spec/plan evaluation?

**Action Items:**
- [ ] **Do NOT use generic similarity metrics** for spec/plan/task quality
- [ ] **Instead, use:**
  - Error analysis → identify specific failure modes
  - Binary pass/fail evals (LLM-as-Judge or code-based)
- [ ] **Similarity metrics CAN be useful for:**
  - Debugging retrieval (if we add RAG for tech docs)
  - Measuring output diversity (e.g., different plan approaches)
- [ ] **Avoid off-the-shelf metrics** like "helpfulness" or "coherence"

**Priority:** LOW (mostly "don't do this")
**Timeline:** N/A

---

### Q: Should I use "ready-to-use" evaluation metrics?
**Context:** Eval libraries offer generic scores - should we use them?

**Action Items:**
- [ ] **NO - Don't use generic metrics** like "helpfulness", "quality", "toxicity"
- [ ] **They create false confidence** without measuring what matters
- [ ] **Instead:**
  - Conduct error analysis
  - Define binary failure modes from real problems
  - Build custom evaluators validated against human judgment
- [ ] **Can use generic metrics for exploration** (to find interesting traces)
- [ ] **Focus on application-specific metrics:**
  - Spec: All user stories testable
  - Plan: Tech stack matches requirements
  - Tasks: Correct execution order

**Priority:** HIGH (design principle)
**Timeline:** Week 1

---

## 7. RAG & Retrieval Evaluation

### Q: Is RAG dead?
**Context:** Should we add RAG for retrieving tech docs, examples, team directives?

**Action Items:**
- [ ] **RAG is NOT dead** - we need retrieval for context
- [ ] **Our use cases:**
  - Retrieve relevant team-ai-directives for spec generation
  - Find similar past specs/plans for reference
  - Pull tech documentation for planning
- [ ] **Use appropriate retrieval strategies:**
  - Vector search for semantic similarity
  - Keyword matching for exact terms
  - Agentic search for complex queries
- [ ] **Experiment and measure** what works best

**Priority:** MEDIUM
**Timeline:** Week 5+

---

### Q: How should I approach evaluating my RAG system?
**Context:** If we add RAG, how do we evaluate it?

**Action Items:**
- [ ] **Separate retrieval and generation evaluation:**
  - **Retrieval:** Use IR metrics (Recall@k, Precision@k, MRR)
  - **Generation:** Use our standard eval process (error analysis, LLM-as-Judge)
- [ ] **For retrieval:**
  - Create query-document pairs synthetically
  - Extract facts from docs → generate questions
- [ ] **For generation:**
  - Error analysis on outputs
  - LLM-as-Judge for quality
  - Check: Context relevant (C|Q), Answer faithful (A|C), Answer addresses question (A|Q)
- [ ] **Domain-specific failure modes:**
  - Example: Confusing different versions of frameworks
  - Example: Mixing up similar tech stacks

**Priority:** LOW (only if we add RAG)
**Timeline:** TBD

---

### Q: How do I choose the right chunk size for my document processing tasks?
**Context:** If we process large specs or docs, how to chunk?

**Action Items:**
- [ ] **Understand the tradeoff:** Large chunks = global context, Small chunks = focused attention
- [ ] **For fixed-output tasks** (e.g., "What tech stack?"):
  - Use largest chunk that contains answer
  - Avoid irrelevant text (models distracted by noise)
- [ ] **For expansive-output tasks** (e.g., "Summarize all requirements"):
  - Use smaller chunks
  - Process independently, then aggregate (map-reduce)
- [ ] **Respect content boundaries** (paragraphs, sections)
- [ ] **Treat chunk size as hyperparameter** - experiment and validate

**Priority:** LOW (future optimization)
**Timeline:** TBD

---

## 8. Agentic Workflows

### Q: How do I evaluate agentic workflows?
**Context:** Our entire spec-driven process is agentic (multi-step with tool use).

**Action Items:**
- [ ] **Phase 1: End-to-end task success**
  - Did the workflow achieve user's goal? (Pass/Fail)
  - Treat whole pipeline as black box
  - Use human or aligned LLM judges
  - Note first upstream failure in error analysis
- [ ] **Phase 2: Step-level diagnostics**
  - Instrument system with tool call details
  - Score individual components:
    - Command choice: Was `/speckit.plan` appropriate?
    - Parameter extraction: Were inputs complete?
    - Error handling: Did agent recover from failures?
    - Context retention: Did it preserve earlier constraints?
    - Efficiency: Steps, time, tokens spent
    - Goal checkpoints: Key milestones validated
- [ ] **Use transition failure matrices:**
  - Rows: Last successful state
  - Columns: First failure state
  - Find hotspots (e.g., many failures from Plan → Tasks)
- [ ] **Create test cases:**
  - Reproduce in simplest form
  - Use N-1 testing (provide first N-1 steps)
  - Only use multi-turn tests when actually needed

**Priority:** CRITICAL
**Timeline:** Week 2-3

**Example for our workflow:**
```
Workflow: Specify → Clarify → Plan → Tasks → Implement

Checkpoints:
1. Spec contains all user stories ✓
2. Clarifications answered ✓
3. Plan includes tech stack ✗ (FIRST FAILURE)
4. Tasks have dependencies ⧗ (Not reached)
5. Implementation complete ⧗ (Not reached)

Debug: Why did Plan fail? Check if Spec was incomplete.
```

---

## 9. CI/CD & Production Monitoring

### Q: How do I set up GitHub Actions for CI/CD evaluation?
**Context:** Automate eval runs on every PR to prevent quality regressions.

**Action Items:**
- [ ] **Create GitHub Action workflow** (`.github/workflows/eval.yml`)
  ```yaml
  name: AI Evals
  on:
    pull_request:
      paths:
        - 'prompts/**'
        - 'evals/**'
  jobs:
    eval:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v3
        - name: Setup Node
          uses: actions/setup-node@v3
        - name: Run PromptFoo Evals
          run: |
            cd evals
            npm install -g promptfoo
            npx promptfoo eval
        - name: Check Thresholds
          run: |
            python evals/scripts/check_eval_scores.py
  ```
- [ ] **Add eval results as PR comment**
  - Show pass/fail status
  - Display score changes
  - Link to detailed results
- [ ] **Fail PR if quality drops below threshold**
  - Set minimum scores in config
  - Block merge if critical tests fail
- [ ] **Cache evaluation results** for faster runs
- [ ] **Run on schedule** (daily/weekly) to catch drift

**Priority:** HIGH
**Timeline:** Week 5
**Effort:** 1-2 days

---

### Q: How are evaluations used differently in CI/CD vs. monitoring production? (NOT MANDATORY)
**Context:** Production monitoring is optional - CI/CD is the priority.

**Action Items:**
- [ ] **CI/CD Evaluation:** (HIGH PRIORITY)
  - Small dataset (~100 examples)
  - Purpose-built: core features, regression tests, edge cases
  - Fast execution (cost-conscious)
  - Favor assertions over expensive LLM-as-Judge
  - **Implement via GitHub Actions** (see above)
- [ ] **Production Monitoring:** (OPTIONAL - NOT MANDATORY)
  - Sample live traces asynchronously
  - Reference-free evaluators (LLM-as-Judge)
  - Track confidence intervals
  - Alert when lower bound crosses threshold
- [ ] **Feedback loop:** (OPTIONAL)
  - Production failures → add to CI dataset
  - Prevents regression on new issues
- [ ] **Our implementation:**
  - CI: Run promptfoo on test dataset before merge via GitHub Actions
  - Production (optional): Sample generated specs/plans, run evals async
  - Add failed production cases to test suite

**Priority:** HIGH (CI/CD), LOW (Production)
**Timeline:** Week 5 (GitHub Actions)

---

### Q: What's a minimum viable evaluation setup?
**Context:** What's the fastest path to value?

**Action Items:**
- [ ] **Start with error analysis, not infrastructure**
  - Spend 30 mins manually reviewing 20-50 outputs per change
  - One domain expert as "benevolent dictator"
- [ ] **Use notebooks for review and data analysis:**
  - Jupyter/Julius/Hex/SolveIt
  - Write arbitrary code, visualize data
  - Build custom annotation interface in notebook
- [ ] **Our MVP:**
  1. Generate 50 specs from diverse prompts
  2. Domain expert reviews in notebook (30-60 mins)
  3. Note failure patterns
  4. Fix obvious issues
  5. Repeat

**Priority:** CRITICAL (Start here!)
**Timeline:** Week 1
**Effort:** 30-60 mins per review session

---

## 10. Team & Process

### Q: How many people should annotate my LLM outputs?
**Context:** How many reviewers for spec/plan/task quality?

**Action Items:**
- [ ] **Appoint single domain expert** as "benevolent dictator"
  - For spec-kit: PM or senior engineer with broad project experience
  - Eliminates annotation conflicts
  - Can incorporate feedback from others but drives process
- [ ] **Only use multiple annotators if:**
  - Multiple domains (e.g., multinational company with different contexts)
  - Large organization requirement
- [ ] **If multiple annotators needed:**
  - Measure agreement with Cohen's Kappa
  - But use judgment - even large companies often fine with single expert

**Priority:** HIGH
**Timeline:** Week 1

---

### Q: What's the difference between guardrails & evaluators?
**Context:** Should we block bad outputs or just measure them?

**Action Items:**
- [ ] **Guardrails (inline, fast, user-visible):**
  - Simple, deterministic checks
  - Regex, schema validation, type checks
  - Fast (<100ms)
  - Examples for our domain:
    - Spec has required sections
    - Plan doesn't reference non-existent tech
    - Tasks don't have circular dependencies
    - No PII in generated specs
- [ ] **Evaluators (async, comprehensive, internal):**
  - Run after generation
  - Measure subjective quality
  - Can use expensive LLM-as-Judge
  - Feed dashboards, regression tests, improvement loops
  - Examples:
    - Spec clarity and completeness
    - Plan appropriateness
    - Task correctness
- [ ] **Implement both:** Guardrails for safety, evaluators for quality

**Priority:** MEDIUM
**Timeline:** Week 3-4

---

### Q: How much time should I spend on model selection?
**Context:** Should we optimize which model generates specs/plans?

**Action Items:**
- [ ] **Don't fixate on model selection** as primary improvement axis
- [ ] **Start with error analysis first:**
  - Does error analysis suggest model is the problem?
  - Or is it prompt, context, or process issue?
- [ ] **Model switching is last resort** after fixing obvious issues
- [ ] **Our approach:**
  - Support multiple agents (Claude, Gemini, Copilot, etc.)
  - Let users choose
  - Focus on improving prompts and process, not model selection

**Priority:** LOW
**Timeline:** Ongoing (user choice)

---

## 11. Tools & Vendors

### Q: Seriously Hamel. Stop the bullshit. What's your favorite eval vendor?
**Context:** Should we adopt a vendor platform?

**Action Items:**
- [ ] **Consider vendors:** Langsmith, Arize, Braintrust
- [ ] **Decision factors:**
  - Support quality (most important!)
  - Feature parity (less important - changes weekly)
  - Pricing
  - Integration with our stack
- [ ] **Expect to build custom tools anyway:**
  - Custom annotation interfaces
  - Domain-specific evaluators
  - Error analysis workflows
- [ ] **Start with open source (promptfoo)** and evaluate vendors later

**Priority:** LOW
**Timeline:** Week 8+ (after we have baseline)

---

## Implementation Roadmap

### Week 1: Error Analysis Foundation (CRITICAL) 🔥
**Primary Tool:** Jupyter Notebooks
**Goal:** Understand real failure modes through manual review

**Setup:**
```bash
# 1. Create directory structure
mkdir -p evals/{notebooks,datasets/real-specs,datasets/real-plans}

# 2. Generate 100 REAL outputs (diverse prompts)
cd evals/scripts
./generate-test-data.sh  # Create this script

# 3. Install notebook environment
uv venv
uv pip install jupyter pandas matplotlib seaborn
jupyter lab
```

**Tasks:**
- [ ] **Generate 100 diverse real specs** (not synthetic test prompts)
  - Simple apps (todo, blog, calculator)
  - Medium complexity (e-commerce, CRM, dashboard)
  - Complex systems (distributed, microservices, enterprise)
  - Different tech stacks (Node.js, .NET, Python, Go)
- [ ] **Create error-analysis.ipynb notebook**
  - Load 100 specs into dataframe
  - Add column for notes (open coding)
  - Add column for pass/fail
- [ ] **Designate benevolent dictator** (single domain expert)
- [ ] **First error analysis session** (60-90 mins)
  - Domain expert reviews each spec
  - Notes issues: "Missing edge cases", "Vague requirements", etc.
  - Mark pass/fail (binary, no Likert)
- [ ] **Create failure-taxonomy.ipynb notebook**
  - Group similar failures together (axial coding)
  - Use LLM to help categorize
  - Count frequency of each category
  - Prioritize by impact
- [ ] **Document findings** in `evals/week1-findings.md`

**Deliverables:**
- 100 real specs with annotations
- Failure taxonomy with frequencies
- Prioritized list of fixes

**Tools Used:** Jupyter, pandas, matplotlib (NO PromptFoo this week)
**Time:** 60-80% of week spent looking at data

---

### Week 2: Custom Annotation Tool (HIGH PRIORITY) 🚀
**Primary Tool:** FastHTML (or Streamlit for faster MVP)
**Goal:** Build 10x faster review interface

**Setup:**
```bash
# Create annotation tool
mkdir -p evals/annotation-tool
cd evals/annotation-tool
uv venv
uv pip install fasthtml  # or streamlit for MVP
```

**Tasks:**
- [ ] **Build MVP annotation interface**
  - Load specs from `evals/datasets/real-specs/`
  - Display one spec at a time (beautiful markdown rendering)
  - Show progress (e.g., "45/100")
  - Binary buttons: Pass / Fail
  - Text area for notes
  - Export to JSON
- [ ] **Add keyboard shortcuts**
  - `N` = Next spec
  - `P` = Previous spec
  - `1` = Mark as Pass
  - `2` = Mark as Fail
  - `D` = Defer (skip for now)
  - `?` = Show keyboard guide
- [ ] **Add filtering and search**
  - Filter by status (pass/fail/pending)
  - Filter by failure mode
  - Keyword search
  - Semantic search (optional)
- [ ] **Side-by-side comparison**
  - Show spec + plan + tasks together
  - Collapsible sections
  - Syntax highlighting
- [ ] **Export annotations**
  - JSON format for analysis
  - CSV for spreadsheets
  - Back to notebook for further analysis

**Deliverables:**
- Working annotation tool (local web server)
- 10x faster than manual review
- Annotations in structured format

**Tools Used:** FastHTML/Streamlit, Python
**Time:** ~10-20 hours with AI assistance

---

### Week 3: Synthetic Data Generation (MEDIUM) 📊
**Primary Tool:** Jupyter Notebooks + Python scripts
**Goal:** Generate diverse test cases systematically

**Tasks:**
- [ ] **Define dimensions** (per FAQ methodology)
  ```python
  dimensions = {
      'complexity': ['simple', 'medium', 'complex', 'enterprise'],
      'domain': ['web-app', 'mobile', 'api', 'data-pipeline', 'infrastructure'],
      'tech_stack': ['nodejs', 'dotnet', 'python', 'go', 'polyglot'],
      'team_size': ['solo', 'small-team', 'large-org'],
      'constraints': ['time-critical', 'compliance-heavy', 'legacy-integration']
  }
  ```
- [ ] **Generate tuples** (combinations of dimensions)
  - Write 20 tuples manually first
  - Use LLM to generate 100+ more
  - Example: `(complex, web-app, nodejs, large-org, compliance-heavy)`
- [ ] **Convert tuples to prompts** (two-step process)
  - Step 1: LLM generates structured tuples
  - Step 2: Separate LLM call converts to natural language
  - This prevents repetitive phrasing
- [ ] **Run through pipeline** and capture traces
- [ ] **Sample 100 traces** for second error analysis
- [ ] **Update failure taxonomy** with new findings

**Deliverables:**
- 100+ synthetic test prompts
- Updated failure taxonomy
- Scripts for generating more test data

**Tools Used:** Jupyter, Python, LLM for generation
**Time:** 1-2 days

---

### Week 4: Extend PromptFoo Based on Findings ✅
**Primary Tool:** PromptFoo + Python (custom graders)
**Goal:** Add automated checks for discovered failure modes

**Tasks:**
- [ ] **Review failure taxonomy** from Weeks 1-3
- [ ] **Identify automatable checks**
  - Which failures can be caught with assertions?
  - Which need LLM-as-Judge?
  - Which should stay manual?
- [ ] **Add new tests to config files**
  ```javascript
  // Example: If error analysis revealed "missing API contracts"
  // Add to evals/configs/promptfooconfig-plan.js
  {
    description: 'Plan includes API contracts for endpoints',
    assert: [
      { type: 'python', value: 'file://evals/graders/custom_graders.py:check_api_contracts' }
    ]
  }
  ```
- [ ] **Add new Python graders**
  ```python
  # evals/graders/custom_graders.py
  def check_api_contracts(output: str, context: dict) -> dict:
      # Based on real failure mode from error analysis
      pass
  ```
- [ ] **Build cheap evaluators first** (regex, assertions)
- [ ] **Then expensive ones** (LLM-as-Judge) if needed
- [ ] **Validate against labeled dataset** from annotation tool

**Deliverables:**
- 5-10 new automated tests in PromptFoo
- Based on REAL discovered failure modes
- Validated against human annotations

**Tools Used:** PromptFoo, Python (extending existing setup)
**Time:** 2-3 days

---

### Week 5: GitHub Actions CI/CD Integration (HIGH PRIORITY) 🔄
**Primary Tool:** GitHub Actions + PromptFoo
**Goal:** Automate evals on every PR to prevent regressions

**Setup:**
```bash
mkdir -p .github/workflows
```

**Tasks:**
- [ ] **Create eval workflow** (`.github/workflows/eval.yml`)
  ```yaml
  name: AI Evals

  on:
    pull_request:
      paths:
        - 'prompts/**'
        - 'evals/**'
        - 'team-ai-directives/**'
    push:
      branches: [main]
    schedule:
      - cron: '0 0 * * 0'  # Weekly on Sunday

  jobs:
    eval:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v3

        - name: Setup Node.js
          uses: actions/setup-node@v3
          with:
            node-version: '18'

        - name: Setup Python
          uses: actions/setup-python@v4
          with:
            python-version: '3.11'

        - name: Install PromptFoo
          run: npm install -g promptfoo

        - name: Install Python dependencies
          run: |
            cd evals
            pip install -r requirements.txt

        - name: Run Evaluations
          env:
            ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          run: |
            cd evals
            npx promptfoo eval --config configs/promptfooconfig.js --output results.json

        - name: Check Thresholds
          run: |
            python evals/scripts/check_eval_scores.py evals/results.json

        - name: Comment PR with Results
          if: github.event_name == 'pull_request'
          uses: actions/github-script@v6
          with:
            script: |
              const fs = require('fs');
              const results = JSON.parse(fs.readFileSync('evals/results.json'));
              // Format and post comment with results
              github.rest.issues.createComment({
                issue_number: context.issue.number,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: `## 📊 Eval Results\n\n${formatResults(results)}`
              });
  ```
- [ ] **Add secrets to GitHub repo:**
  - `ANTHROPIC_API_KEY` (or other model API keys)
  - Settings → Secrets → Actions → New repository secret
- [ ] **Configure threshold checks** in `check_eval_scores.py`
  - Fail if score drops below minimum
  - Return exit code 1 to fail workflow
- [ ] **Add status badges to README**
  ```markdown
  ![Eval Status](https://github.com/user/repo/actions/workflows/eval.yml/badge.svg)
  ```
- [ ] **Set up branch protection rules:**
  - Require eval workflow to pass before merge
  - Settings → Branches → Add rule
- [ ] **Add eval results artifact upload**
  - Store detailed results for review
  - Retain for 30 days

**Deliverables:**
- GitHub Action running on every PR
- Automated threshold checks
- PR comments with eval results
- Branch protection preventing low-quality merges
- Scheduled weekly runs to catch drift

**Tools Used:** GitHub Actions, PromptFoo, Python
**Time:** 1-2 days

---

### Week 5-6: Production Monitoring (OPTIONAL - NOT MANDATORY) 📈
**Primary Tool:** Vanilla Python (NOT PromptFoo - needs async)
**Goal:** Monitor quality of live generations

**Note:** This is an optional advanced feature. Focus on CI/CD first.

**Setup:**
```bash
mkdir -p evals/monitoring
cd evals/monitoring
uv venv
uv pip install asyncio aiohttp pandas
```

**Tasks:**
- [ ] **Build production sampler**
  ```python
  # evals/monitoring/sample-production.py
  # - Sample 100 traces/day from live usage
  # - Stratified by: complexity, domain, tech stack
  # - Store in evals/datasets/production/
  ```
- [ ] **Build async evaluator**
  ```python
  # evals/monitoring/run-evals-async.py
  # - Run LLM-as-Judge on sampled traces
  # - Non-blocking (can't use PromptFoo)
  # - Track TPR/TNR over time
  ```
- [ ] **Build alerting system**
  ```python
  # evals/monitoring/alert-on-failures.py
  # - Track confidence intervals
  # - Alert if quality drops below threshold
  # - Slack/email notifications
  ```
- [ ] **Build simple dashboard**
  ```python
  # evals/monitoring/dashboard.py
  # - Real-time metrics (pass rate, failure modes)
  # - Trends over time
  # - Top failure categories
  ```
- [ ] **Feedback loop:** Production failures → CI dataset

**Deliverables:**
- Production monitoring pipeline
- Async evaluation (can't use PromptFoo)
- Alerting when quality drops
- Feedback loop to CI tests

**Tools Used:** Vanilla Python, asyncio (NOT PromptFoo)
**Time:** 3-5 days
**Priority:** OPTIONAL

---

### Week 6: Advanced Features & Integration 🔧
**Primary Tool:** Mix of all tools
**Goal:** Polish and integrate everything

**Tasks:**
- [ ] **Enhance annotation tool**
  - Clustering similar failures (embedding similarity)
  - AI-powered categorization suggestions
  - Bulk operations
- [ ] **Build transition failure matrices** (for agentic workflow)
  - Track: Specify → Plan → Tasks → Implement
  - Visualize hotspots (where failures occur most)
- [ ] **Implement guardrails** (inline, fast checks)
  - Spec has required sections
  - Plan doesn't reference non-existent tech
  - Tasks have no circular dependencies
- [ ] **Document everything**
  - Error analysis process
  - Annotation tool usage
  - PromptFoo extension guide
  - Production monitoring setup
- [ ] **Team training session** (60-90 mins)

**Deliverables:**
- Complete eval framework
- Documentation
- Team trained on all tools

**Tools Used:** All (notebooks, FastHTML, PromptFoo, vanilla Python)
**Time:** Full week

---

### Ongoing: Weekly Rhythm 🔄

**Every Week:**
- [ ] **Error analysis session** (60 mins, Jupyter Notebook)
  - Review 20-50 new outputs
  - Update failure taxonomy
  - Prioritize fixes
- [ ] **Run PromptFoo before template changes**
  ```bash
  npx promptfoo eval
  ```
- [ ] **Review production metrics** (dashboard)
- [ ] **Add production failures to CI dataset**

**Every Month:**
- [ ] **Deep error analysis** (90-120 mins, Notebook)
  - Review 100+ traces
  - Refine failure taxonomy
  - Update evaluators
- [ ] **Expand test dataset** with new edge cases
- [ ] **Review and optimize eval costs**

**Every Quarter:**
- [ ] **Eval retrospective**
  - What's working?
  - What's not?
  - Tool improvements needed?
- [ ] **Update this roadmap**

---

## Success Metrics

### Immediate (Week 1-2)
- [ ] 100+ traces reviewed with failure taxonomy
- [ ] Single domain expert established
- [ ] Minimum viable eval setup working
- [ ] First round of prompt improvements deployed

### Short-term (Week 3-6)
- [ ] Custom annotation tool operational
- [ ] 5+ code-based evaluators deployed
- [ ] 2-3 validated LLM-as-Judge evaluators
- [ ] CI/CD pipeline with automated evals
- [ ] 10x faster review with custom tooling

### Long-term (Month 2-3)
- [ ] Production monitoring catching real issues
- [ ] Feedback loop preventing regressions
- [ ] Documented improvement in spec/plan/task quality
- [ ] Team trained on eval process
- [ ] Eval framework reusable for new features

---

## Key Principles to Remember

1. **Error analysis is THE MOST IMPORTANT activity** - start here, do it regularly
2. **Build custom annotation tools** - 10x faster iteration
3. **Use binary pass/fail** - clearer, faster, more consistent
4. **Avoid generic metrics** - build domain-specific evaluators
5. **Start cheap (assertions) before expensive (LLM-as-Judge)**
6. **Single domain expert** as benevolent dictator
7. **Expect 60-80% time on evaluation** - it's part of development
8. **Don't optimize for 100% pass rates** - 70% is meaningful
9. **Notebooks are your friend** - fast, flexible, powerful
10. **Production failures → CI tests** - close the feedback loop

---

## Tool Architecture Summary

### The Complete Eval Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Eval Ecosystem                       │
└─────────────────────────────────────────────────────────────┘

Layer 1: Error Analysis (60-80% of time) 🔥 MOST IMPORTANT
├─ Jupyter Notebooks
│  ├─ error-analysis.ipynb          (Weekly sessions)
│  ├─ failure-taxonomy.ipynb        (Categorization)
│  └─ llm-judge-prototypes.ipynb    (Build evaluators)
│
└─ Process: Open Coding → Axial Coding → Prioritization

Layer 2: Fast Annotation (10x speedup) 🚀
├─ Custom FastHTML App
│  ├─ Keyboard-driven review (N, P, 1, 2)
│  ├─ Progress tracking
│  ├─ Side-by-side comparison
│  └─ Export to JSON/CSV
│
└─ Alternative: Streamlit for faster MVP

Layer 3: CI/CD Regression Tests ✅ (Keep existing)
├─ PromptFoo
│  ├─ configs/
│  │  ├─ promptfooconfig.js         (Main config with all tests)
│  │  ├─ promptfooconfig-spec.js    (Spec-specific tests)
│  │  └─ promptfooconfig-plan.js    (Plan-specific tests)
│  ├─ graders/custom_graders.py     (Domain-specific checks)
│  ├─ prompts/                      (Test prompts)
│  └─ scripts/run-eval.sh           (CI runner)
│
└─ Purpose: Prevent template quality regressions

Layer 4: GitHub Actions CI/CD 🔄 **HIGH PRIORITY**
├─ GitHub Actions
│  ├─ .github/workflows/eval.yml   (Run on PR)
│  ├─ Threshold checks             (Fail if quality drops)
│  ├─ PR comments                  (Show results)
│  └─ Branch protection            (Prevent bad merges)
│
└─ Purpose: Automate evals on every PR, prevent regressions

Layer 5: Production Monitoring 📈 **OPTIONAL**
├─ Vanilla Python (async)
│  ├─ sample-production.py          (Stratified sampling)
│  ├─ run-evals-async.py           (Non-blocking LLM-as-Judge)
│  ├─ alert-on-failures.py         (Quality alerts)
│  └─ dashboard.py                  (Real-time metrics)
│
└─ Why not PromptFoo: Need async, streaming, custom sampling
└─ Note: Optional advanced feature - focus on CI/CD first
```

### Tool Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│ START: What do you need to do?                              │
└─────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
   Understand          Review           Prevent
   failures?          outputs?         regressions?
        │                  │                  │
        ▼                  ▼                  ▼
   Jupyter            FastHTML          PromptFoo
   Notebook           App               (existing)
        │                  │                  │
   60-90 min          30-60 min          5 min
   session            for 100            automated
                      specs                  │
                                             │
                                             ▼
                                        Automate in
                                        CI/CD?
                                             │
                                             ▼
                                        GitHub Actions
                                             │
                                        Run on every PR
        │
        ▼
   Monitor
   production?
   (OPTIONAL)
        │
        ▼
   Vanilla Python
   (async)
```

### What Each Tool Can and Cannot Do

| Task | Jupyter | FastHTML | PromptFoo | GitHub Actions | Vanilla Python |
|------|---------|----------|-----------|----------------|----------------|
| **Error analysis** | ✅ Best | ❌ | ❌ | ❌ | ❌ |
| **Fast annotation** | ⚠️ Slow | ✅ Best | ❌ | ❌ | ❌ |
| **CI/CD tests** | ❌ | ❌ | ✅ Manual | ✅ Automated | ⚠️ Possible |
| **Production monitoring** | ❌ | ❌ | ❌ Sync | ❌ | ✅ Best (Optional) |
| **Exploratory analysis** | ✅ Best | ❌ | ❌ | ❌ | ⚠️ Possible |
| **LLM-as-Judge prototyping** | ✅ Best | ❌ | ⚠️ Productionize | ❌ | ❌ |
| **Template regression tests** | ❌ | ❌ | ✅ Best | ✅ Automated | ⚠️ Possible |
| **PR quality gates** | ❌ | ❌ | ❌ | ✅ Best | ❌ |
| **Real-time dashboards** | ❌ | ⚠️ Possible | ❌ | ❌ | ✅ Best (Optional) |

### Cost & Time Breakdown

**Time Distribution (per FAQ guidance):**
```
Total eval time: 100%
├─ Error analysis: 60-80%  (Jupyter)
├─ Annotation: 10-15%      (FastHTML)
├─ Automation: 5-10%       (PromptFoo + Python)
└─ Monitoring: 5-10%       (Vanilla Python)
```

**Dollar Cost (per week):**
```
PromptFoo (CI tests):     $5-10   (10 runs @ $0.50-1.00 each)
Jupyter (manual review):  $0      (human time, no LLM calls)
FastHTML (annotation):    $0      (local tool, no LLM calls)
Production monitoring:    $20-50  (async evals on 100+ traces)
────────────────────────────────
Total:                    $25-70/week
```

### The 80/20 Rule for This Project

**80% of value comes from:**
1. ✅ **Jupyter notebooks** for error analysis (Week 1)
2. ✅ **Custom FastHTML app** for fast annotation (Week 2)
3. ✅ **Keep PromptFoo** for CI/CD (already have it)
4. ✅ **GitHub Actions** for automated CI/CD (Week 5)

**20% of value comes from:**
- Production monitoring (OPTIONAL - nice to have, not critical)
- Advanced features (clustering, AI assistance, dashboards)
- Vendor integration (Langsmith, Arize, etc.)

### Recommendation: Start Simple, Scale Up

**Phase 1 (Weeks 1-2): Essential** 🔥
```bash
✅ Jupyter notebooks    (error analysis)
✅ FastHTML app         (fast annotation)
✅ PromptFoo           (keep existing CI tests)
```

**Phase 2 (Weeks 3-4): Enhancement** ⭐
```bash
✅ Extend PromptFoo     (add tests based on findings)
✅ Synthetic data       (systematic test generation)
```

**Phase 3 (Week 5): Automation** 🔄
```bash
✅ GitHub Actions       (automate CI/CD)
✅ PR quality gates     (prevent regressions)
✅ Scheduled runs       (catch drift)
```

**Phase 4 (Weeks 5-6): OPTIONAL Production Monitoring** 📈
```bash
⚠️ Vanilla Python       (async monitoring) - OPTIONAL
⚠️ Dashboards          (real-time metrics) - OPTIONAL
⚠️ Alerting            (quality drops) - OPTIONAL
```

### Final Answer to Your Question

**"Can I use PromptFoo for this? Or should I use another tool? Or vanilla code?"**

**Answer: ALL OF THEM - Use the right tool for each job:**

1. **Keep PromptFoo** ✅
   - What it's good for: CI/CD regression tests
   - What you have: 10 template quality tests
   - Action: Keep running it, extend based on error analysis

2. **Add Jupyter Notebooks** 🔥 (CRITICAL - Start here!)
   - What it's for: Error analysis (THE most important activity)
   - What you're missing: Understanding real failure modes
   - Action: Week 1, 60-90 min sessions

3. **Add Custom FastHTML App** 🚀 (HIGH PRIORITY)
   - What it's for: 10x faster annotation
   - What you're missing: Efficient review workflow
   - Action: Week 2, build MVP

4. **Add GitHub Actions** 🔄 (HIGH PRIORITY)
   - What it's for: Automate CI/CD on every PR
   - What you're missing: Automated quality gates
   - Action: Week 5, 1-2 days

5. **Add Vanilla Python** 📈 (OPTIONAL - Later, for production)
   - What it's for: Async production monitoring
   - What PromptFoo can't do: Non-blocking, streaming evals
   - Action: Weeks 5-6 (if needed)

**The FAQ is clear: "We spent 60-80% of our development time on error analysis and evaluation. Expect most of your effort to go toward understanding failures (i.e. looking at data) rather than building automated checks."**

Translation: PromptFoo = 20%, Notebooks + Annotation = 80%

---

## Next Steps

1. **Review this plan** with the team
2. **Designate benevolent dictator** for quality standards
3. **Schedule Week 1 kickoff** - first error analysis session
4. **Generate initial test dataset** (100 real specs, not synthetic prompts)
5. **Set up notebook environment** for manual review
6. **Begin error analysis in Jupyter** 🚀 (NOT PromptFoo!)
7. **Keep running PromptFoo** for CI/CD (it's still useful!)
8. **Set up GitHub Actions** (Week 5) for automated CI/CD
9. **Production monitoring is OPTIONAL** - focus on CI/CD first

---

## References

- Source PDF: AI Evals - Frequently Asked Questions.pdf
- Authors: Hamel Husain & Shreya Shankar
- Course: [AI Evals Course](https://hamel.dev/evals)
- Related articles:
  - [Your AI Product Needs Eval (Evaluation Systems)](https://hamel.dev/blog/posts/evals/)
  - [Creating a LLM-as-a-Judge That Drives Business Results](https://hamel.dev/blog/posts/llm-judge/)
  - [A Field Guide to Rapidly Improving AI Products](https://hamel.dev/blog/posts/field-guide/)
  - [Error Analysis: The Highest ROI Technique In AI Engineering](https://hamel.dev/blog/posts/error-analysis/)

---

**Document Status:** v2.4 (Plan Error Analysis Foundation Added)
**Owner:** [Assign owner]
**Last Updated:** 2026-01-12

**Key Changes in v2.4:**
- Added Plan Error Analysis Foundation (2026-01-12)
- Created automated plan evaluation infrastructure (3 new scripts)
- Generated 2 initial plan test cases with 100% pass rate
- Updated Week 1 tasks to include plan error analysis completion
- Updated status summary table with plan analysis pass rate
- Added "Latest Addition" section documenting plan analysis work
- Updated evals/README.md with plan analysis documentation
- Updated .gitignore for plan analysis artifacts

**Key Changes in v2.3:**
- Updated Week 4 status to COMPLETED with 90% pass rate (9/10 tests)
- Documented prompt improvements and fixes
- Added current status summary table
- Updated Week 1 error analysis tasks as completed
- Ready for Week 5: GitHub Actions CI/CD integration

**Key Changes in v2.2:**
- Added GitHub Actions section for CI/CD automation (HIGH PRIORITY)
- Marked Production Monitoring as OPTIONAL throughout
- Restructured Week 5 to focus on GitHub Actions instead of production monitoring
- Updated tool architecture to include GitHub Actions as Layer 4
- Updated decision trees, tables, and phased approach
- Production monitoring moved to optional Phase 4

**Key Changes in v2.1:**
- Updated directory structure to reflect organized layout:
  - `evals/configs/` for configuration files (main, spec, plan)
  - `evals/prompts/` for test prompts
  - `evals/graders/` for custom graders
  - `evals/scripts/` for automation scripts
- All paths updated throughout document to reflect new structure

**Key Changes in v2.0:**
- Added Section 0: Tool Strategy & Current State (comprehensive analysis)
- Updated Implementation Roadmap with specific tools for each week
- Added Tool Architecture Summary with decision matrices
- Clarified: PromptFoo = 20%, Notebooks + Annotation = 80%
- Clear guidance on when to use each tool
