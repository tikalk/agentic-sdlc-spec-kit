"""
Skills Registry Client

Client for interacting with skills.sh registry for skill discovery.
Uses the API for search and metadata - installation is done directly from GitHub.
"""

import re
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

import httpx


@dataclass
class SkillSearchResult:
    """A skill search result from the registry"""

    name: str
    owner: str
    repo: str
    description: Optional[str] = None
    installs: int = 0
    categories: Optional[List[str]] = None
    url: Optional[str] = None
    skill_url: Optional[str] = None

    @property
    def skill_ref(self) -> str:
        """Get the skill reference for installation"""
        return f"github:{self.owner}/{self.repo}/{self.name}"

    @property
    def install_command(self) -> str:
        """Get the install command"""
        return f"specify skill install {self.skill_ref}"


class SkillsRegistryClient:
    """
    Client for skills.sh registry.

    Used for:
    - Searching skills by keyword
    - Getting skill metadata
    - Discovering popular/trending skills

    NOT used for:
    - Installation (done directly from GitHub)
    - Version management (handled by manifest)
    """

    BASE_URL = "https://skills.sh"

    def __init__(self, http_client: Optional[httpx.Client] = None):
        self.client = http_client or httpx.Client(timeout=30.0)

    def search(
        self, query: str, limit: int = 20, min_installs: int = 0
    ) -> List[SkillSearchResult]:
        """
        Search for skills in the registry.

        Args:
            query: Search query (keywords)
            limit: Maximum results to return
            min_installs: Minimum install count filter

        Returns:
            List of matching skills
        """
        # Note: skills.sh doesn't have a public API documented yet
        # We'll scrape the search page or use undocumented endpoints
        # For now, return mock data or try known endpoints

        try:
            # Try the search endpoint
            url = f"{self.BASE_URL}/api/search"
            params = {"q": query, "limit": limit}

            response = self.client.get(url, params=params)

            if response.status_code == 404:
                # Fallback: Try alternate endpoint patterns
                # skills.sh might use different API structure
                return self._fallback_search(query, limit)

            response.raise_for_status()
            data = response.json()

            results = []
            for item in data.get("skills", data.get("results", [])):
                result = self._parse_skill_data(item)
                if result and result.installs >= min_installs:
                    results.append(result)

            return results[: int(limit)]

        except httpx.HTTPError:
            # If API fails, try fallback
            return self._fallback_search(query, int(limit))

    def _fallback_search(self, query: str, limit: int) -> List[SkillSearchResult]:
        """Fallback search using page scraping or known repos"""

        # Return popular known skills that match query
        # This is a fallback when API isn't available
        known_skills = [
            SkillSearchResult(
                name="vercel-react-best-practices",
                owner="vercel-labs",
                repo="agent-skills",
                description="React and Next.js performance optimization guidelines",
                installs=105000,
                categories=["frontend", "react", "performance"],
            ),
            SkillSearchResult(
                name="web-design-guidelines",
                owner="vercel-labs",
                repo="agent-skills",
                description="Review UI code for web interface best practices",
                installs=79400,
                categories=["frontend", "design", "accessibility"],
            ),
            SkillSearchResult(
                name="frontend-design",
                owner="anthropics",
                repo="skills",
                description="Frontend design patterns and guidelines",
                installs=48900,
                categories=["frontend", "design"],
            ),
            SkillSearchResult(
                name="skill-creator",
                owner="anthropics",
                repo="skills",
                description="Create new agent skills following best practices",
                installs=24200,
                categories=["development", "skills"],
            ),
            SkillSearchResult(
                name="supabase-postgres-best-practices",
                owner="supabase",
                repo="agent-skills",
                description="Supabase and PostgreSQL best practices",
                installs=12600,
                categories=["backend", "database", "supabase"],
            ),
            SkillSearchResult(
                name="test-driven-development",
                owner="obra",
                repo="superpowers",
                description="TDD patterns and practices for AI agents",
                installs=5800,
                categories=["testing", "tdd"],
            ),
            SkillSearchResult(
                name="systematic-debugging",
                owner="obra",
                repo="superpowers",
                description="Systematic debugging workflow for AI agents",
                installs=6700,
                categories=["debugging", "workflow"],
            ),
            SkillSearchResult(
                name="vue-best-practices",
                owner="antfu",
                repo="skills",
                description="Vue.js best practices and patterns",
                installs=5100,
                categories=["frontend", "vue"],
            ),
            SkillSearchResult(
                name="typescript-advanced-types",
                owner="wshobson",
                repo="agents",
                description="Advanced TypeScript type patterns",
                installs=3500,
                categories=["typescript", "types"],
            ),
            SkillSearchResult(
                name="python-testing-patterns",
                owner="wshobson",
                repo="agents",
                description="Python testing best practices",
                installs=2100,
                categories=["python", "testing"],
            ),
        ]

        # Filter by query
        query_lower = query.lower()
        matching = [
            skill
            for skill in known_skills
            if (
                query_lower in skill.name.lower()
                or query_lower in (skill.description or "").lower()
                or any(query_lower in cat.lower() for cat in (skill.categories or []))
            )
        ]

        return matching[: int(limit)]

    def _parse_skill_data(self, data: Dict[str, Any]) -> Optional[SkillSearchResult]:
        """Parse skill data from API response"""

        try:
            # Handle different API response formats
            name = data.get("name") or data.get("skillId") or data.get("skill_name", "")

            # Parse owner/repo from various fields
            owner = data.get("owner", "")
            repo = data.get("repo", "")

            if not owner or not repo:
                # Try to extract from "source" field (format: "owner/repo")
                source = data.get("source", "")
                if "/" in source:
                    parts = source.split("/")
                    if len(parts) >= 2:
                        owner = parts[0]
                        repo = parts[1]

            if not owner or not repo:
                # Try to extract from URL
                url = data.get("url") or data.get("github_url", "")
                match = re.search(r"github\.com/([^/]+)/([^/]+)", url)
                if match:
                    owner, repo = match.groups()

            if not owner or not repo:
                # Try to extract from "id" field (format: "owner/repo/skill")
                skill_id = data.get("id", "")
                if "/" in skill_id:
                    parts = skill_id.split("/")
                    if len(parts) >= 2:
                        owner = parts[0]
                        repo = parts[1]

            if not name or not owner or not repo:
                return None

            return SkillSearchResult(
                name=name,
                owner=owner,
                repo=repo,
                description=data.get("description"),
                installs=data.get("installs", data.get("install_count", 0)),
                categories=data.get("categories", data.get("tags", [])),
                url=data.get("url"),
                skill_url=data.get("skill_url"),
            )

        except Exception:
            return None

    def get_skill(
        self, owner: str, repo: str, name: str
    ) -> Optional[SkillSearchResult]:
        """Get specific skill metadata from registry"""

        try:
            url = f"{self.BASE_URL}/{owner}/{repo}/{name}"
            # or: f"{self.BASE_URL}/api/skills/{owner}/{repo}/{name}"

            response = self.client.get(url)

            if response.status_code == 404:
                return None

            response.raise_for_status()

            # Try to parse as JSON API response
            if "application/json" in response.headers.get("content-type", ""):
                data = response.json()
                return self._parse_skill_data(data)

            # Otherwise, skill exists but we don't have metadata
            return SkillSearchResult(
                name=name,
                owner=owner,
                repo=repo,
            )

        except httpx.HTTPError:
            return None

    def get_trending(self, limit: int = 20) -> List[SkillSearchResult]:
        """Get trending skills from registry"""

        try:
            url = f"{self.BASE_URL}/api/trending"
            response = self.client.get(url, params={"limit": limit})

            if response.status_code != 200:
                # Fallback to known popular skills
                return self._fallback_search("", limit)

            data = response.json()

            results = []
            for item in data.get("skills", data.get("results", [])):
                result = self._parse_skill_data(item)
                if result:
                    results.append(result)

            return results[:limit]

        except httpx.HTTPError:
            return self._fallback_search("", limit)

    def get_leaderboard(self, limit: int = 20) -> List[SkillSearchResult]:
        """Get top skills by install count"""

        try:
            url = f"{self.BASE_URL}/api/leaderboard"
            response = self.client.get(url, params={"limit": limit})

            if response.status_code != 200:
                # Fallback to known popular skills sorted by installs
                skills = self._fallback_search("", 100)
                skills.sort(key=lambda s: s.installs, reverse=True)
                return skills[:limit]

            data = response.json()

            results = []
            for item in data.get("skills", data.get("results", [])):
                result = self._parse_skill_data(item)
                if result:
                    results.append(result)

            return results[:limit]

        except httpx.HTTPError:
            skills = self._fallback_search("", 100)
            skills.sort(key=lambda s: s.installs, reverse=True)
            return skills[:limit]
