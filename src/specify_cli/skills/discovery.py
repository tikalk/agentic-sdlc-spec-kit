"""
Skill Auto-Discovery

Automatically discovers relevant skills based on feature descriptions using
keyword matching and relevance scoring.
"""

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional

from .manifest import SkillsManifest, SkillMetadata


@dataclass
class SkillMatch:
    """A matched skill with relevance information"""

    skill_id: str
    skill_name: str
    description: str
    relevance_score: float  # 0.0 to 1.0
    reason: str
    version: str


class SkillAutoDiscovery:
    """
    Auto-discovers relevant skills based on feature descriptions.

    Uses keyword extraction and matching to find skills that are
    relevant to a given feature description. Scores matches by
    keyword overlap and semantic similarity.

    Configuration (from skills.json):
    - auto_activation_threshold: Minimum score to include (default: 0.7)
    - max_auto_skills: Maximum skills to return (default: 3)
    """

    def __init__(
        self,
        manifest: SkillsManifest,
        threshold: Optional[float] = None,
        max_skills: Optional[int] = None,
    ):
        self.manifest = manifest
        self.threshold = threshold or manifest.get_config(
            "auto_activation_threshold", 0.7
        )
        self.max_skills = max_skills or manifest.get_config("max_auto_skills", 3)

    def discover(self, feature_description: str) -> List[SkillMatch]:
        """
        Discover skills relevant to the feature description.

        Args:
            feature_description: Description of the feature being specified

        Returns:
            List of SkillMatch objects sorted by relevance (highest first)
        """
        skills = self.manifest.list_skills()

        if not skills:
            return []

        # Load skill metadata from SKILL.md files
        skill_data = []
        for skill_id, metadata in skills.items():
            skill_info = self._load_skill_info(skill_id, metadata)
            if skill_info:
                skill_data.append(skill_info)

        # Calculate relevance for each skill
        matches = []
        feature_lower = feature_description.lower()

        for skill in skill_data:
            relevance = self._calculate_relevance(skill, feature_lower)
            if relevance["score"] >= self.threshold:
                matches.append(
                    SkillMatch(
                        skill_id=skill["id"],
                        skill_name=skill["name"],
                        description=skill["description"],
                        relevance_score=relevance["score"],
                        reason=relevance["reason"],
                        version=skill["version"],
                    )
                )

        # Sort by relevance score (descending)
        matches.sort(key=lambda x: x.relevance_score, reverse=True)

        return matches[: self.max_skills]

    def _load_skill_info(
        self, skill_id: str, metadata: SkillMetadata
    ) -> Optional[Dict]:
        """Load skill information from SKILL.md file"""
        skills_dir = self.manifest.skills_dir

        if not skills_dir.exists():
            return None

        # Find the skill directory
        for skill_dir in skills_dir.iterdir():
            if not skill_dir.is_dir():
                continue

            skill_file = skill_dir / "SKILL.md"
            if not skill_file.exists():
                continue

            try:
                content = skill_file.read_text(encoding="utf-8")

                # Extract frontmatter
                if not content.startswith("---"):
                    continue

                parts = content.split("---", 2)
                if len(parts) < 3:
                    continue

                frontmatter = parts[1].strip()
                body = parts[2].lower()

                # Parse frontmatter
                fm_data: Dict[str, str] = {}
                for line in frontmatter.split("\n"):
                    line = line.strip()
                    if ":" in line and not line.startswith("#"):
                        key, value = line.split(":", 1)
                        fm_data[key.strip()] = value.strip().strip('"').strip("'")

                return {
                    "id": skill_id,
                    "name": fm_data.get("name", skill_dir.name),
                    "description": fm_data.get("description", ""),
                    "content": body,
                    "version": metadata.version,
                }

            except Exception:
                continue

        return None

    def _calculate_relevance(self, skill: Dict, feature_lower: str) -> Dict:
        """
        Calculate relevance score between skill and feature.

        Uses:
        - Keyword overlap in description (weighted 60%)
        - Keyword overlap in content (weighted 40%)
        - Category/technology matching (bonus)
        """
        score = 0.0
        reasons = []

        description = skill.get("description", "").lower()
        content = skill.get("content", "")

        # Extract meaningful keywords from feature (exclude common words)
        feature_words = self._extract_keywords(feature_lower)
        desc_words = self._extract_keywords(description)
        content_words = self._extract_keywords(content)

        # Calculate overlaps
        desc_overlap = (
            len(feature_words & desc_words) / max(len(feature_words), 1) * 0.6
        )
        content_overlap = (
            len(feature_words & content_words) / max(len(feature_words), 1) * 0.4
        )

        score = desc_overlap + content_overlap

        # Bonus for exact keyword matches in description
        for word in feature_words:
            if word in description:
                score += 0.05  # Small bonus per match

        # Cap at 1.0
        score = min(score, 1.0)

        # Generate reason
        if desc_overlap > 0:
            reasons.append("description matches")
        if content_overlap > 0:
            reasons.append("content relevant")

        return {
            "score": score,
            "reason": ", ".join(reasons) if reasons else "low relevance",
        }

    def _extract_keywords(self, text: str) -> set:
        """Extract meaningful keywords from text"""
        # Common words to exclude
        stop_words = {
            "the",
            "a",
            "an",
            "and",
            "or",
            "but",
            "in",
            "on",
            "at",
            "to",
            "for",
            "of",
            "with",
            "by",
            "is",
            "are",
            "was",
            "were",
            "be",
            "been",
            "being",
            "have",
            "has",
            "had",
            "do",
            "does",
            "did",
            "will",
            "would",
            "could",
            "should",
            "may",
            "might",
            "must",
            "can",
            "this",
            "that",
            "these",
            "those",
            "i",
            "you",
            "he",
            "she",
            "it",
            "we",
            "they",
            "me",
            "him",
            "her",
            "us",
            "them",
            "my",
            "your",
            "his",
            "her",
            "its",
            "our",
            "their",
        }

        # Extract words (alphanumeric, 3+ chars)
        words = re.findall(r"\b[a-z][a-z0-9_\-]{2,}\b", text)

        # Filter out stop words and return unique set
        return set(w for w in words if w not in stop_words)

    def format_matches_for_context(self, matches: List[SkillMatch]) -> str:
        """
        Format skill matches for injection into context.md

        Returns markdown-formatted skill list.
        """
        if not matches:
            return ""

        lines = ["## Relevant Skills (Auto-Detected)", ""]

        for match in matches:
            confidence_pct = f"{match.relevance_score:.0%}"
            lines.append(
                f"- **{match.skill_name}**@{match.version} (confidence: {confidence_pct})"
            )
            lines.append(f"  - {match.description}")
            lines.append("")

        lines.append(
            "*These skills were automatically selected based on your feature description.*"
        )
        lines.append("")

        return "\n".join(lines)


def discover_skills_for_feature(
    project_path: Path,
    feature_description: str,
    threshold: Optional[float] = None,
    max_skills: Optional[int] = None,
) -> List[SkillMatch]:
    """
    Convenience function to discover skills for a feature.

    Args:
        project_path: Path to the project directory
        feature_description: Description of the feature
        threshold: Minimum relevance score (0.0-1.0)
        max_skills: Maximum number of skills to return

    Returns:
        List of matching skills
    """
    manifest = SkillsManifest(project_path)

    if not manifest.exists():
        return []

    discovery = SkillAutoDiscovery(manifest, threshold, max_skills)
    return discovery.discover(feature_description)
