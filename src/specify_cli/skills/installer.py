"""
Skill Installer

Handles skill installation from various sources:
- GitHub repositories (direct download, no npm dependency)
- GitLab repositories
- Local paths
- Registry references (via skills.sh)
"""

import hashlib
import re
import shutil
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

import httpx

from .manifest import SkillsManifest, SkillMetadata, SkillLockEntry, TeamSkillsManifest


@dataclass
class SkillInfo:
    """Parsed skill information"""

    source_type: str  # 'github', 'gitlab', 'local', 'registry'
    org: Optional[str] = None
    repo: Optional[str] = None
    skill_name: Optional[str] = None
    version: Optional[str] = None
    local_path: Optional[str] = None


class SkillInstaller:
    """
    Handles skill installation from various sources.

    Supports:
    - github:org/repo/skill-name[@version]
    - gitlab:org/repo/skill-name[@version]
    - local:./path/to/skill
    - registry:skill-name (resolves via skills.sh)

    Installation process:
    1. Parse skill reference
    2. Check if blocked by team policy
    3. Fetch SKILL.md from source
    4. Validate skill structure
    5. Copy to .specify/skills/
    6. Update skills.json manifest
    """

    def __init__(
        self,
        manifest: SkillsManifest,
        team_manifest: Optional[TeamSkillsManifest] = None,
        http_client: Optional[httpx.Client] = None,
    ):
        self.manifest = manifest
        self.team_manifest = team_manifest
        self.client = http_client or httpx.Client(timeout=30.0)

    def install(
        self,
        skill_ref: str,
        version: Optional[str] = None,
        save: bool = True,
        force: bool = False,
    ) -> Tuple[bool, str]:
        """
        Install a skill from a reference.

        Args:
            skill_ref: Skill reference (github:org/repo/skill, local:./path, etc.)
            version: Specific version to install
            save: Save to manifest
            force: Reinstall even if exists

        Returns:
            Tuple of (success, message)
        """
        # Parse skill reference
        skill_info = self._parse_reference(skill_ref)

        if skill_info is None:
            return False, f"Invalid skill reference: {skill_ref}"

        # Generate skill ID
        skill_id = self._generate_skill_id(skill_info, skill_ref)

        # Check if blocked by team policy
        if self.team_manifest and self.team_manifest.should_enforce_blocked():
            if self.team_manifest.is_blocked(skill_id):
                return False, f"Skill blocked by team policy: {skill_id}"

        # Check if already installed (unless force)
        if not force and self.manifest.get_skill(skill_id) is not None:
            return (
                False,
                f"Skill already installed: {skill_id}. Use --force to reinstall.",
            )

        # Install based on source type
        if skill_info.source_type == "github":
            return self._install_from_github(skill_info, skill_id, version, save)
        elif skill_info.source_type == "gitlab":
            return self._install_from_gitlab(skill_info, skill_id, version, save)
        elif skill_info.source_type == "local":
            return self._install_from_local(skill_info, skill_id, save)
        elif skill_info.source_type == "registry":
            return self._install_from_registry(skill_info, skill_id, version, save)
        else:
            return False, f"Unknown source type: {skill_info.source_type}"

    def _parse_reference(self, skill_ref: str) -> Optional[SkillInfo]:
        """Parse skill reference into SkillInfo"""

        # Handle explicit source types
        if ":" in skill_ref:
            source_type, path = skill_ref.split(":", 1)
            source_type = source_type.lower()

            if source_type == "github":
                return self._parse_github_path(path)
            elif source_type == "gitlab":
                return self._parse_gitlab_path(path)
            elif source_type == "local":
                return SkillInfo(source_type="local", local_path=path)
            elif source_type == "registry":
                return SkillInfo(source_type="registry", skill_name=path)

        # Try to auto-detect (assume registry)
        return SkillInfo(source_type="registry", skill_name=skill_ref)

    def _parse_github_path(self, path: str) -> Optional[SkillInfo]:
        """Parse GitHub path: org/repo/skill-name[@version]"""
        # Handle version suffix
        version = None
        if "@" in path:
            path, version = path.rsplit("@", 1)

        # Parse org/repo/skill-name
        parts = path.split("/")
        if len(parts) < 3:
            return None

        return SkillInfo(
            source_type="github",
            org=parts[0],
            repo=parts[1],
            skill_name="/".join(parts[2:]),  # Handle nested paths
            version=version,
        )

    def _parse_gitlab_path(self, path: str) -> Optional[SkillInfo]:
        """Parse GitLab path: org/repo/skill-name[@version]"""
        # Same structure as GitHub
        return self._parse_github_path(path)

    def _generate_skill_id(self, info: SkillInfo, original_ref: str) -> str:
        """Generate a canonical skill ID"""
        if info.source_type in ("github", "gitlab"):
            return f"{info.source_type}:{info.org}/{info.repo}/{info.skill_name}"
        elif info.source_type == "local":
            return f"local:{info.local_path}"
        else:
            return f"registry:{info.skill_name}"

    def _install_from_github(
        self, info: SkillInfo, skill_id: str, version: Optional[str], save: bool
    ) -> Tuple[bool, str]:
        """Install skill from GitHub"""

        # Determine version
        ver = version or info.version or "main"

        # Build raw GitHub URL
        # Format: https://raw.githubusercontent.com/{org}/{repo}/{ref}/skills/{skill}/SKILL.md
        url = (
            f"https://raw.githubusercontent.com/{info.org}/{info.repo}/"
            f"{ver}/skills/{info.skill_name}/SKILL.md"
        )

        try:
            response = self.client.get(url)

            if response.status_code == 404:
                # Try alternative path without /skills/ prefix
                alt_url = (
                    f"https://raw.githubusercontent.com/{info.org}/{info.repo}/"
                    f"{ver}/{info.skill_name}/SKILL.md"
                )
                response = self.client.get(alt_url)

                if response.status_code == 404:
                    return False, f"Skill not found at {url} or {alt_url}"

                url = alt_url

            response.raise_for_status()
            content = response.text

        except httpx.HTTPError as e:
            return False, f"Failed to fetch skill: {e}"

        # Validate skill structure
        is_valid, error = self._validate_skill(content)
        if not is_valid:
            return False, f"Invalid skill: {error}"

        # Extract metadata from frontmatter
        skill_metadata = self._extract_frontmatter(content)

        # Create skill directory
        safe_name = f"{info.org}--{info.repo}--{info.skill_name}".replace("/", "--")
        skill_dir = self.manifest.skills_dir / f"{safe_name}@{ver}"
        skill_dir.mkdir(parents=True, exist_ok=True)

        # Write SKILL.md
        skill_file = skill_dir / "SKILL.md"
        skill_file.write_text(content, encoding="utf-8")

        # Calculate integrity hash
        integrity = f"sha256:{hashlib.sha256(content.encode()).hexdigest()}"

        # Update manifest
        if save:
            metadata = SkillMetadata(
                version=ver,
                installed_at=datetime.utcnow().isoformat() + "Z",
                source="github",
                metadata=skill_metadata,
            )

            lock_entry = SkillLockEntry(resolved=url, integrity=integrity)

            self.manifest.add_skill(skill_id, metadata, lock_entry)

        return True, f"Installed {skill_id}@{ver}"

    def _install_from_gitlab(
        self, info: SkillInfo, skill_id: str, version: Optional[str], save: bool
    ) -> Tuple[bool, str]:
        """Install skill from GitLab"""

        # Determine version
        ver = version or info.version or "main"

        # Build GitLab raw URL
        # Format: https://gitlab.com/{org}/{repo}/-/raw/{ref}/skills/{skill}/SKILL.md
        url = (
            f"https://gitlab.com/{info.org}/{info.repo}/"
            f"-/raw/{ver}/skills/{info.skill_name}/SKILL.md"
        )

        try:
            response = self.client.get(url)

            if response.status_code == 404:
                # Try alternative path
                alt_url = (
                    f"https://gitlab.com/{info.org}/{info.repo}/"
                    f"-/raw/{ver}/{info.skill_name}/SKILL.md"
                )
                response = self.client.get(alt_url)

                if response.status_code == 404:
                    return False, f"Skill not found at {url} or {alt_url}"

                url = alt_url

            response.raise_for_status()
            content = response.text

        except httpx.HTTPError as e:
            return False, f"Failed to fetch skill: {e}"

        # Validate skill structure
        is_valid, error = self._validate_skill(content)
        if not is_valid:
            return False, f"Invalid skill: {error}"

        # Extract metadata from frontmatter
        skill_metadata = self._extract_frontmatter(content)

        # Create skill directory
        safe_name = f"{info.org}--{info.repo}--{info.skill_name}".replace("/", "--")
        skill_dir = self.manifest.skills_dir / f"{safe_name}@{ver}"
        skill_dir.mkdir(parents=True, exist_ok=True)

        # Write SKILL.md
        skill_file = skill_dir / "SKILL.md"
        skill_file.write_text(content, encoding="utf-8")

        # Calculate integrity hash
        integrity = f"sha256:{hashlib.sha256(content.encode()).hexdigest()}"

        # Update manifest
        if save:
            metadata = SkillMetadata(
                version=ver,
                installed_at=datetime.utcnow().isoformat() + "Z",
                source="gitlab",
                metadata=skill_metadata,
            )

            lock_entry = SkillLockEntry(resolved=url, integrity=integrity)

            self.manifest.add_skill(skill_id, metadata, lock_entry)

        return True, f"Installed {skill_id}@{ver}"

    def _install_from_local(
        self, info: SkillInfo, skill_id: str, save: bool
    ) -> Tuple[bool, str]:
        """Install skill from local path"""

        local_path = Path(info.local_path).resolve()
        skill_file = local_path / "SKILL.md"

        if not skill_file.exists():
            return False, f"SKILL.md not found at {local_path}"

        content = skill_file.read_text(encoding="utf-8")

        # Validate skill structure
        is_valid, error = self._validate_skill(content)
        if not is_valid:
            return False, f"Invalid skill: {error}"

        # Extract metadata from frontmatter
        skill_metadata = self._extract_frontmatter(content)
        skill_name = skill_metadata.get("name", local_path.name)

        # Create skill directory
        skill_dir = self.manifest.skills_dir / f"local--{skill_name}"

        if skill_dir.exists():
            shutil.rmtree(skill_dir)

        # Copy entire directory
        shutil.copytree(local_path, skill_dir)

        # Update manifest
        if save:
            metadata = SkillMetadata(
                version="*",
                installed_at=datetime.utcnow().isoformat() + "Z",
                source="local",
                metadata=skill_metadata,
            )

            lock_entry = SkillLockEntry(resolved=str(local_path))

            self.manifest.add_skill(skill_id, metadata, lock_entry)

        return True, f"Installed local:{skill_name}"

    def _install_from_registry(
        self, info: SkillInfo, skill_id: str, version: Optional[str], save: bool
    ) -> Tuple[bool, str]:
        """Install skill from skills.sh registry"""

        # For registry skills, we need to resolve the GitHub URL first
        # skills.sh stores skills as github:org/repo references

        # Try to fetch skill info from skills.sh
        # The registry uses GitHub URLs, so we resolve and delegate
        search_url = f"https://skills.sh/api/skills/{info.skill_name}"

        try:
            response = self.client.get(search_url)

            if response.status_code == 404:
                return False, f"Skill not found in registry: {info.skill_name}"

            response.raise_for_status()
            skill_data = response.json()

            # Extract GitHub URL from registry response
            github_url = skill_data.get("github_url") or skill_data.get("url")

            if not github_url:
                return False, f"Registry skill missing GitHub URL: {info.skill_name}"

            # Parse and delegate to GitHub installation
            # Extract org/repo/skill from URL
            match = re.search(
                r"github\.com/([^/]+)/([^/]+).*?/skills/([^/]+)", github_url
            )
            if match:
                org, repo, skill_name = match.groups()
                github_info = SkillInfo(
                    source_type="github",
                    org=org,
                    repo=repo,
                    skill_name=skill_name,
                    version=version,
                )
                github_skill_id = f"github:{org}/{repo}/{skill_name}"
                return self._install_from_github(
                    github_info, github_skill_id, version, save
                )

            return False, f"Could not parse GitHub URL from registry: {github_url}"

        except httpx.HTTPError as e:
            return False, f"Failed to query registry: {e}"

    def _validate_skill(self, content: str) -> Tuple[bool, Optional[str]]:
        """Validate skill structure"""

        # Check for frontmatter
        if not content.startswith("---"):
            return False, "Missing YAML frontmatter"

        try:
            # Extract frontmatter
            parts = content.split("---", 2)
            if len(parts) < 3:
                return False, "Invalid frontmatter format"

            frontmatter = parts[1].strip()

            # Parse frontmatter (simple key: value parsing)
            metadata = {}
            for line in frontmatter.split("\n"):
                line = line.strip()
                if ":" in line and not line.startswith("#"):
                    key, value = line.split(":", 1)
                    metadata[key.strip()] = value.strip().strip('"').strip("'")

            # Check required fields
            if "name" not in metadata:
                return False, "Missing 'name' in frontmatter"
            if "description" not in metadata:
                return False, "Missing 'description' in frontmatter"

            return True, None

        except Exception as e:
            return False, f"Error parsing skill: {e}"

    def _extract_frontmatter(self, content: str) -> Dict[str, Any]:
        """Extract metadata from SKILL.md frontmatter"""

        if not content.startswith("---"):
            return {}

        try:
            parts = content.split("---", 2)
            if len(parts) < 3:
                return {}

            frontmatter = parts[1].strip()
            metadata = {}

            for line in frontmatter.split("\n"):
                line = line.strip()
                if ":" in line and not line.startswith("#"):
                    key, value = line.split(":", 1)
                    metadata[key.strip()] = value.strip().strip('"').strip("'")

            return metadata

        except Exception:
            return {}

    def uninstall(self, skill_id: str) -> Tuple[bool, str]:
        """Uninstall a skill"""

        # Check if skill exists
        skill = self.manifest.get_skill(skill_id)
        if skill is None:
            return False, f"Skill not installed: {skill_id}"

        # Remove from manifest
        self.manifest.remove_skill(skill_id)

        # Find and remove skill directory
        # The directory name is derived from the skill_id
        for skill_dir in self.manifest.skills_dir.iterdir():
            if skill_dir.is_dir():
                # Check if this directory matches the skill
                # We store skills as org--repo--skill@version or local--name
                if skill_id.startswith("local:"):
                    if skill_dir.name.startswith("local--"):
                        shutil.rmtree(skill_dir)
                        break
                else:
                    # Extract org/repo/skill from skill_id
                    parts = skill_id.split(":", 1)[1]
                    safe_name = parts.replace("/", "--")
                    if skill_dir.name.startswith(safe_name):
                        shutil.rmtree(skill_dir)
                        break

        return True, f"Uninstalled {skill_id}"

    def update(
        self, skill_id: Optional[str] = None, dry_run: bool = False
    ) -> Tuple[bool, str, Dict[str, str]]:
        """
        Update installed skills.

        Args:
            skill_id: Specific skill to update (or None for all)
            dry_run: Only check for updates, don't install

        Returns:
            Tuple of (success, message, updates dict)
        """
        updates = {}

        if skill_id:
            # Update specific skill
            skill = self.manifest.get_skill(skill_id)
            if skill is None:
                return False, f"Skill not installed: {skill_id}", {}

            # Re-install to update
            if not dry_run:
                success, msg = self.install(skill_id, force=True)
                if success:
                    updates[skill_id] = msg
                    return True, f"Updated {skill_id}", updates
                return False, msg, {}
            else:
                updates[skill_id] = "Would update"
                return True, f"Would update {skill_id}", updates
        else:
            # Update all skills
            skills = self.manifest.list_skills()

            for sid, meta in skills.items():
                if not dry_run:
                    success, msg = self.install(sid, force=True)
                    if success:
                        updates[sid] = msg
                else:
                    updates[sid] = "Would update"

            count = len(updates)
            action = "Updated" if not dry_run else "Would update"
            return True, f"{action} {count} skills", updates
