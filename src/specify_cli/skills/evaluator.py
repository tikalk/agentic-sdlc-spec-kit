"""
Skill Evaluator

Evaluates skill quality using review and task evaluations.

Review Evaluation (Structure Quality):
- Frontmatter validation (20 pts)
- Content organization (30 pts)
- Self-containment check (30 pts)
- Documentation quality (20 pts)

Task Evaluation (Behavioral Impact):
- A/B testing methodology
- Metrics: API correctness, best practices, output quality
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any


@dataclass
class EvaluationCheck:
    """A single evaluation check result"""

    name: str
    passed: bool
    points: int
    max_points: int
    message: Optional[str] = None


@dataclass
class EvaluationResult:
    """Complete evaluation result"""

    total_score: int
    max_score: int
    breakdown: Dict[str, int]
    checks: List[EvaluationCheck]
    rating: str

    @property
    def percentage(self) -> float:
        """Score as percentage"""
        return (self.total_score / self.max_score * 100) if self.max_score > 0 else 0


class SkillEvaluator:
    """
    Evaluates skill quality using review and task evaluations.

    Review Evaluation (Structure Quality):
    - Validates skill against best practices
    - Checks frontmatter, organization, self-containment
    - Returns score 0-100

    Task Evaluation (Behavioral Impact):
    - Runs A/B tests with/without skill
    - Measures improvement in agent behavior
    - Requires test scenarios (optional)
    """

    def __init__(self, skills_dir: Optional[Path] = None):
        self.skills_dir = skills_dir

    def evaluate_review(self, skill_path: Path) -> EvaluationResult:
        """
        Run review evaluation on skill structure.

        Scoring:
        - Frontmatter validation: 20 points
        - Content organization: 30 points
        - Self-containment: 30 points
        - Documentation quality: 20 points

        Returns EvaluationResult with detailed breakdown.
        """
        skill_file = skill_path / "SKILL.md"

        if not skill_file.exists():
            return EvaluationResult(
                total_score=0,
                max_score=100,
                breakdown={"error": 0},
                checks=[
                    EvaluationCheck("SKILL.md exists", False, 0, 100, "File not found")
                ],
                rating="Error",
            )

        content = skill_file.read_text(encoding="utf-8")

        checks: List[EvaluationCheck] = []
        breakdown = {
            "frontmatter": 0,
            "organization": 0,
            "self_containment": 0,
            "documentation": 0,
        }

        # === Frontmatter Validation (20 points) ===
        frontmatter_score, frontmatter_checks = self._evaluate_frontmatter(content)
        breakdown["frontmatter"] = frontmatter_score
        checks.extend(frontmatter_checks)

        # === Content Organization (30 points) ===
        org_score, org_checks = self._evaluate_organization(content)
        breakdown["organization"] = org_score
        checks.extend(org_checks)

        # === Self-Containment (30 points) ===
        containment_score, containment_checks = self._evaluate_self_containment(content)
        breakdown["self_containment"] = containment_score
        checks.extend(containment_checks)

        # === Documentation Quality (20 points) ===
        doc_score, doc_checks = self._evaluate_documentation(content)
        breakdown["documentation"] = doc_score
        checks.extend(doc_checks)

        total_score = sum(breakdown.values())
        rating = self._get_rating(total_score)

        return EvaluationResult(
            total_score=total_score,
            max_score=100,
            breakdown=breakdown,
            checks=checks,
            rating=rating,
        )

    def _evaluate_frontmatter(self, content: str) -> Tuple[int, List[EvaluationCheck]]:
        """Evaluate frontmatter (20 points total)"""
        checks = []
        score = 0

        # Check for frontmatter presence (5 pts)
        has_frontmatter = content.startswith("---")
        checks.append(
            EvaluationCheck(
                "YAML frontmatter present",
                has_frontmatter,
                5 if has_frontmatter else 0,
                5,
            )
        )
        if has_frontmatter:
            score += 5

        if not has_frontmatter:
            return score, checks

        # Extract frontmatter
        try:
            parts = content.split("---", 2)
            if len(parts) < 3:
                return score, checks

            frontmatter = parts[1].strip()

            # Check for name field (5 pts)
            has_name = "name:" in frontmatter
            checks.append(
                EvaluationCheck(
                    "Frontmatter has 'name' field", has_name, 5 if has_name else 0, 5
                )
            )
            if has_name:
                score += 5

            # Check for description field (5 pts)
            has_description = "description:" in frontmatter
            checks.append(
                EvaluationCheck(
                    "Frontmatter has 'description' field",
                    has_description,
                    5 if has_description else 0,
                    5,
                )
            )
            if has_description:
                score += 5

            # Check for trigger keywords in description (5 pts)
            trigger_keywords = ["use when", "for ", "help", "when you", "trigger"]
            has_triggers = any(kw in frontmatter.lower() for kw in trigger_keywords)
            checks.append(
                EvaluationCheck(
                    "Description has trigger keywords",
                    has_triggers,
                    5 if has_triggers else 0,
                    5,
                    "Keywords help agents discover when to use this skill",
                )
            )
            if has_triggers:
                score += 5

        except Exception:
            pass

        return score, checks

    def _evaluate_organization(self, content: str) -> Tuple[int, List[EvaluationCheck]]:
        """Evaluate content organization (30 points total)"""
        checks = []
        score = 0

        lines = content.split("\n")

        # Check line count (10 pts) - under 500 lines
        line_count = len(lines)
        under_limit = line_count <= 500
        checks.append(
            EvaluationCheck(
                f"Content under 500 lines ({line_count} lines)",
                under_limit,
                10 if under_limit else 0,
                10,
                "Progressive disclosure keeps context efficient",
            )
        )
        if under_limit:
            score += 10

        content_lower = content.lower()

        # Check for "What This Skill Provides" section (5 pts)
        has_what_section = (
            "what this skill" in content_lower or "## what" in content_lower
        )
        checks.append(
            EvaluationCheck(
                "Has 'What This Skill Provides' section",
                has_what_section,
                5 if has_what_section else 0,
                5,
            )
        )
        if has_what_section:
            score += 5

        # Check for "When to Use" section (5 pts)
        has_when_section = "when to use" in content_lower or "## when" in content_lower
        checks.append(
            EvaluationCheck(
                "Has 'When to Use This Skill' section",
                has_when_section,
                5 if has_when_section else 0,
                5,
            )
        )
        if has_when_section:
            score += 5

        # Check for implementation/patterns section (5 pts)
        has_impl = any(
            kw in content_lower
            for kw in ["pattern", "implementation", "core", "## how", "usage"]
        )
        checks.append(
            EvaluationCheck(
                "Has patterns/implementation section", has_impl, 5 if has_impl else 0, 5
            )
        )
        if has_impl:
            score += 5

        # Check for progressive disclosure structure (5 pts)
        # Should have clear hierarchy with headers
        header_count = content.count("\n#")
        has_structure = header_count >= 3
        checks.append(
            EvaluationCheck(
                f"Has structured headers ({header_count} headers)",
                has_structure,
                5 if has_structure else 0,
                5,
                "Clear hierarchy aids navigation",
            )
        )
        if has_structure:
            score += 5

        return score, checks

    def _evaluate_self_containment(
        self, content: str
    ) -> Tuple[int, List[EvaluationCheck]]:
        """Evaluate self-containment (30 points total)"""
        checks = []
        score = 30  # Start with full score, deduct for issues

        # Check for forbidden @rule: references (10 pts)
        has_rule_refs = "@rule:" in content
        checks.append(
            EvaluationCheck(
                "No @rule: references (self-contained)",
                not has_rule_refs,
                10 if not has_rule_refs else 0,
                10,
                "Skills should not reference external context_modules",
            )
        )
        if has_rule_refs:
            score -= 10

        # Check for forbidden @persona: references (10 pts)
        has_persona_refs = "@persona:" in content
        checks.append(
            EvaluationCheck(
                "No @persona: references (self-contained)",
                not has_persona_refs,
                10 if not has_persona_refs else 0,
                10,
                "Skills should not reference external personas",
            )
        )
        if has_persona_refs:
            score -= 10

        # Check for forbidden @example: references (10 pts)
        has_example_refs = "@example:" in content
        checks.append(
            EvaluationCheck(
                "No @example: references (self-contained)",
                not has_example_refs,
                10 if not has_example_refs else 0,
                10,
                "Skills should include examples inline",
            )
        )
        if has_example_refs:
            score -= 10

        return max(0, score), checks

    def _evaluate_documentation(
        self, content: str
    ) -> Tuple[int, List[EvaluationCheck]]:
        """Evaluate documentation quality (20 points total)"""
        checks = []
        score = 0

        # Check for markdown headers (5 pts)
        has_headers = "#" in content
        checks.append(
            EvaluationCheck(
                "Uses markdown headers", has_headers, 5 if has_headers else 0, 5
            )
        )
        if has_headers:
            score += 5

        # Check for code examples (5 pts)
        has_code = "```" in content
        checks.append(
            EvaluationCheck(
                "Has code examples",
                has_code,
                5 if has_code else 0,
                5,
                "Code examples help agents understand patterns",
            )
        )
        if has_code:
            score += 5

        # Check for references section (5 pts)
        has_refs = "reference" in content.lower() or "## ref" in content.lower()
        checks.append(
            EvaluationCheck("Has references section", has_refs, 5 if has_refs else 0, 5)
        )
        if has_refs:
            score += 5

        # Check for setup/prerequisite info (5 pts)
        has_setup = any(
            kw in content.lower()
            for kw in [
                "setup",
                "install",
                "prerequisite",
                "getting started",
                "quick start",
            ]
        )
        checks.append(
            EvaluationCheck(
                "Has setup/installation instructions",
                has_setup,
                5 if has_setup else 0,
                5,
            )
        )
        if has_setup:
            score += 5

        return score, checks

    def _get_rating(self, score: int) -> str:
        """Convert score to rating"""
        if score >= 90:
            return "Excellent"
        elif score >= 80:
            return "Good"
        elif score >= 70:
            return "Fair"
        else:
            return "Poor"

    def evaluate_task(
        self, skill_path: Path, scenarios_path: Optional[Path] = None
    ) -> Optional[EvaluationResult]:
        """
        Run task evaluation (behavioral impact testing).

        This requires:
        - Test scenarios in YAML/JSON format
        - Baseline vs. skill-enhanced comparison
        - Access to agent execution (typically via promptfoo)

        Returns None if task evaluation is not available.
        """
        # Task evaluation requires external infrastructure
        # (promptfoo, test scenarios, agent access)
        # For now, return None to indicate not available

        if scenarios_path is None:
            return None

        if not scenarios_path.exists():
            return None

        # TODO: Implement task evaluation when infrastructure is ready
        # This would:
        # 1. Load test scenarios
        # 2. Run baseline (without skill)
        # 3. Run with skill
        # 4. Compare results using graders
        # 5. Calculate improvement metrics

        return None

    def evaluate_full(
        self, skill_path: Path, scenarios_path: Optional[Path] = None
    ) -> Dict[str, Any]:
        """
        Run full evaluation (review + task if available).

        Returns dict with:
        - review: EvaluationResult
        - task: Optional[EvaluationResult]
        - overall_score: Combined score
        - recommendation: Install/improve/reject
        """
        review_result = self.evaluate_review(skill_path)
        task_result = self.evaluate_task(skill_path, scenarios_path)

        # Calculate overall score
        # Weight: 40% review, 60% task (if available)
        if task_result:
            overall = int(
                review_result.total_score * 0.4 + task_result.total_score * 0.6
            )
        else:
            overall = review_result.total_score

        # Generate recommendation
        if overall >= 80:
            recommendation = "recommended"
        elif overall >= 60:
            recommendation = "acceptable"
        else:
            recommendation = "needs_improvement"

        return {
            "review": review_result,
            "task": task_result,
            "overall_score": overall,
            "recommendation": recommendation,
            "task_evaluated": task_result is not None,
        }
