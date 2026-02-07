# Skill Evaluation Framework

## Overview

Based on Tessl's approach, we implement two types of evaluations to ensure skill quality and effectiveness.

## Review Evaluation (Structure Quality)

Validates skill structure against best practices.

### Checklist (100 points total)

#### Frontmatter Validation (20 points)
- [ ] YAML frontmatter present (5 pts)
- [ ] `name` field exists and is kebab-case (5 pts)
- [ ] `description` field exists (5 pts)
- [ ] Description includes trigger keywords (5 pts)

#### Content Organization (30 points)
- [ ] Content under 500 lines (10 pts)
- [ ] Has "What This Skill Provides" section (5 pts)
- [ ] Has "When to Use This Skill" section (5 pts)
- [ ] Has "Core Patterns" or "Implementation Details" section (5 pts)
- [ ] Progressive disclosure structure (5 pts)

#### Self-Containment (30 points)
- [ ] No @rule: references to context_modules (10 pts)
- [ ] No @persona: references to context_modules (10 pts)
- [ ] References use relative paths or local files (10 pts)

#### Documentation Quality (20 points)
- [ ] Proper markdown syntax (5 pts)
- [ ] Code examples are valid (5 pts)
- [ ] References section exists (5 pts)
- [ ] Installation/setup instructions (if applicable) (5 pts)

### Scoring
- 90-100: Excellent (production ready)
- 80-89: Good (minor improvements needed)
- 70-79: Fair (needs work)
- <70: Poor (significant issues)

## Task Evaluation (Behavioral Impact)

Measures actual impact on agent behavior using A/B testing methodology.

### Process

1. **Define Test Scenarios**
   ```json
   {
     "scenarios": [
       {
         "id": "react-component-creation",
         "description": "Create a React component with proper hooks usage",
         "validation_criteria": [
           "Uses functional component pattern",
           "Proper hook usage",
           "Error handling present"
         ]
       }
     ]
   }
   ```

2. **Run Baseline (Without Skill)**
   - Execute scenario with vanilla agent
   - Record output quality metrics
   - Capture common errors

3. **Run With Skill**
   - Execute same scenario with skill loaded
   - Record output quality metrics
   - Compare against baseline

4. **Calculate Metrics**

#### Quality Metrics (0-100 scale)

**API Usage Correctness** (40 pts)
- Correct API calls
- Proper parameter usage
- Error handling

**Best Practice Adherence** (30 pts)
- Follows conventions
- Proper patterns
- Security considerations

**Output Quality** (30 pts)
- Completeness
- Code quality
- Documentation

### Scoring Formula

```
Task Score = (API_Correctness × 0.4) + (Best_Practices × 0.3) + (Output_Quality × 0.3)
```

### Grader Implementation

```python
def evaluate_skill_task(skill_path: str, scenario: dict) -> dict:
    """
    Evaluate skill using promptfoo or custom graders
    """
    # Run baseline
    baseline_result = run_agent(scenario, skill=None)
    
    # Run with skill
    skill_result = run_agent(scenario, skill=skill_path)
    
    # Compare using grader
    comparison = grade_outputs(baseline_result, skill_result)
    
    return {
        "baseline_score": comparison.baseline,
        "skill_score": comparison.with_skill,
        "improvement": comparison.improvement_percentage,
        "metrics": comparison.detailed_metrics
    }
```

## Combined Score

```
Overall Score = (Review_Score × 0.4) + (Task_Score × 0.6)
```

Weighting prioritizes behavioral impact over structure.

## Evaluation Commands

```bash
# Review evaluation only
specify skill eval --review ./my-skill

# Task evaluation (requires scenarios)
specify skill eval --task ./my-skill --scenarios ./scenarios/

# Full evaluation
specify skill eval --full ./my-skill

# Evaluate installed skill
specify skill eval react-best-practices

# Generate evaluation report
specify skill eval --report ./my-skill --output eval-report.md
```

## Continuous Evaluation

Skills can be re-evaluated:
- After updates
- When new scenarios added
- Periodically (quarterly)
- Before publishing to registry

## Registry Quality Gates

Skills published to registry must meet:
- Review Score >= 80
- Task Score >= 75
- Overall Score >= 78

This ensures only high-quality skills are distributed.
