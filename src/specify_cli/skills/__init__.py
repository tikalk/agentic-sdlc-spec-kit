"""
Skills Package Manager for Agentic SDLC

A developer-grade package manager for agent skills treating them as versioned
software dependencies with evaluation, lifecycle management, and dual registry
integration.

Architecture:
- skills.sh (Discovery Only) - Community registry for search
- team-ai-directives/.skills.json - Team's curated skill manifest
- .specify/skills.json - Project's installed skills

References:
- skills.sh Registry: https://skills.sh
- Agent Skills Format: https://agentskills.io/
"""

from .manifest import SkillsManifest, SkillMetadata
from .installer import SkillInstaller
from .registry import SkillsRegistryClient
from .evaluator import SkillEvaluator
from .discovery import SkillAutoDiscovery, SkillMatch, discover_skills_for_feature

__all__ = [
    "SkillsManifest",
    "SkillMetadata",
    "SkillInstaller",
    "SkillsRegistryClient",
    "SkillEvaluator",
    "SkillAutoDiscovery",
    "SkillMatch",
    "discover_skills_for_feature",
]
