"""
Skills Package Manager for Agentic SDLC

Inspired by Tessl's approach to treating skills as versioned software dependencies.
"""

import json
import hashlib
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
import re
import requests
from urllib.parse import urlparse


@dataclass
class SkillMetadata:
    """Metadata for an installed skill"""
    version: str
    installed_at: str
    source: str  # 'registry', 'github', 'gitlab', 'local'
    evaluation: Optional[Dict] = None
    skill_metadata: Optional[Dict] = None


@dataclass
class SkillLockEntry:
    """Lockfile entry for reproducible installations"""
    resolved: str
    integrity: Optional[str] = None
    dependencies: Optional[List[str]] = None


class SkillsManifest:
    """Manages the skills.json manifest file"""
    
    def __init__(self, project_path: Path):
        self.manifest_path = project_path / ".specify" / "skills.json"
        self.skills_dir = project_path / ".specify" / "skills"
        self._data = None
    
    def load(self) -> Dict:
        """Load manifest from disk"""
        if self._data is not None:
            return self._data
            
        if not self.manifest_path.exists():
            self._data = self._create_default()
        else:
            with open(self.manifest_path, 'r') as f:
                self._data = json.load(f)
        
        return self._data
    
    def save(self):
        """Save manifest to disk"""
        self.manifest_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.manifest_path, 'w') as f:
            json.dump(self._data, f, indent=2)
    
    def _create_default(self) -> Dict:
        """Create default manifest structure"""
        return {
            "version": "1.0.0",
            "skills": {},
            "lockfile": {},
            "config": {
                "registry_url": "https://registry.agentic-sdlc.io",
                "auto_update": False,
                "evaluation_required": False
            }
        }
    
    def get_skill(self, skill_id: str) -> Optional[SkillMetadata]:
        """Get skill metadata by ID"""
        data = self.load()
        if skill_id not in data["skills"]:
            return None
        
        skill_data = data["skills"][skill_id]
        return SkillMetadata(**skill_data)
    
    def add_skill(self, skill_id: str, metadata: SkillMetadata):
        """Add or update a skill in the manifest"""
        data = self.load()
        data["skills"][skill_id] = asdict(metadata)
        self.save()
    
    def remove_skill(self, skill_id: str) -> bool:
        """Remove a skill from the manifest"""
        data = self.load()
        if skill_id not in data["skills"]:
            return False
        
        del data["skills"][skill_id]
        if skill_id in data.get("lockfile", {}):
            del data["lockfile"][skill_id]
        
        self.save()
        return True
    
    def list_skills(self) -> Dict[str, SkillMetadata]:
        """List all installed skills"""
        data = self.load()
        return {
            skill_id: SkillMetadata(**skill_data)
            for skill_id, skill_data in data["skills"].items()
        }


class SkillInstaller:
    """Handles skill installation from various sources"""
    
    def __init__(self, manifest: SkillsManifest):
        self.manifest = manifest
    
    def install(self, skill_ref: str, version: Optional[str] = None, 
                save: bool = True) -> Tuple[bool, str]:
        """
        Install a skill from a reference
        
        Args:
            skill_ref: Skill reference (github:org/repo/skill, local:./path, etc.)
            version: Specific version to install
            save: Save to manifest
            
        Returns:
            Tuple of (success, message)
        """
        # Parse skill reference
        source_type, source_path = self._parse_reference(skill_ref)
        
        if source_type == "github":
            return self._install_from_github(source_path, version, save)
        elif source_type == "gitlab":
            return self._install_from_gitlab(source_path, version, save)
        elif source_type == "local":
            return self._install_from_local(source_path, save)
        elif source_type == "registry":
            return self._install_from_registry(source_path, version, save)
        else:
            return False, f"Unknown source type: {source_type}"
    
    def _parse_reference(self, skill_ref: str) -> Tuple[str, str]:
        """Parse skill reference into (type, path)"""
        if ":" not in skill_ref:
            # Assume registry reference
            return "registry", skill_ref
        
        source_type, source_path = skill_ref.split(":", 1)
        return source_type, source_path
    
    def _install_from_github(self, path: str, version: Optional[str],
                            save: bool) -> Tuple[bool, str]:
        """Install skill from GitHub"""
        # Parse path: org/repo/skill-name[@version]
        match = re.match(r"([^/]+)/([^/]+)/(.+)", path)
        if not match:
            return False, f"Invalid GitHub path: {path}"
        
        org, repo, skill_part = match.groups()
        
        # Check for version in skill_part
        if "@" in skill_part:
            skill_name, specified_version = skill_part.rsplit("@", 1)
            version = version or specified_version
        else:
            skill_name = skill_part
        
        # Construct raw GitHub URL
        version = version or "main"
        url = f"https://raw.githubusercontent.com/{org}/{repo}/{version}/skills/{skill_name}/SKILL.md"
        
        try:
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            content = response.text
            
            # Validate skill structure
            is_valid, error = self._validate_skill(content)
            if not is_valid:
                return False, f"Invalid skill: {error}"
            
            # Install to skills directory
            skill_id = f"github:{org}/{repo}/{skill_name}"
            skill_dir = self.manifest.skills_dir / f"{org}--{repo}--{skill_name}@{version}"
            skill_dir.mkdir(parents=True, exist_ok=True)
            
            skill_file = skill_dir / "SKILL.md"
            with open(skill_file, 'w') as f:
                f.write(content)
            
            # Update manifest
            if save:
                metadata = SkillMetadata(
                    version=version,
                    installed_at=datetime.utcnow().isoformat() + "Z",
                    source="github"
                )
                self.manifest.add_skill(skill_id, metadata)
            
            return True, f"Installed {skill_id}@{version}"
            
        except requests.RequestException as e:
            return False, f"Failed to fetch skill: {e}"
    
    def _install_from_local(self, path: str, save: bool) -> Tuple[bool, str]:
        """Install skill from local path"""
        local_path = Path(path).resolve()
        skill_file = local_path / "SKILL.md"
        
        if not skill_file.exists():
            return False, f"SKILL.md not found at {local_path}"
        
        with open(skill_file, 'r') as f:
            content = f.read()
        
        # Validate
        is_valid, error = self._validate_skill(content)
        if not is_valid:
            return False, f"Invalid skill: {error}"
        
        # Install
        skill_name = local_path.name
        skill_id = f"local:{path}"
        skill_dir = self.manifest.skills_dir / f"local--{skill_name}"
        
        if skill_dir.exists():
            shutil.rmtree(skill_dir)
        
        shutil.copytree(local_path, skill_dir)
        
        if save:
            metadata = SkillMetadata(
                version="*",
                installed_at=datetime.utcnow().isoformat() + "Z",
                source="local"
            )
            self.manifest.add_skill(skill_id, metadata)
        
        return True, f"Installed local:{skill_name}"
    
    def _validate_skill(self, content: str) -> Tuple[bool, Optional[str]]:
        """Validate skill structure"""
        # Check for frontmatter
        if not content.startswith("---"):
            return False, "Missing YAML frontmatter"
        
        # Extract frontmatter
        try:
            _, frontmatter, body = content.split("---", 2)
            metadata = {}
            for line in frontmatter.strip().split("\n"):
                if ":" in line:
                    key, value = line.split(":", 1)
                    metadata[key.strip()] = value.strip()
            
            # Check required fields
            if "name" not in metadata:
                return False, "Missing 'name' in frontmatter"
            if "description" not in metadata:
                return False, "Missing 'description' in frontmatter"
            
            # Check description has trigger keywords
            desc = metadata["description"].lower()
            trigger_words = ["use when", "for", "help"]
            if not any(word in desc for word in trigger_words):
                return False, "Description missing trigger keywords"
            
            return True, None
            
        except ValueError:
            return False, "Invalid frontmatter format"


class SkillEvaluator:
    """Evaluates skill quality using review and task evaluations"""
    
    def __init__(self, manifest: SkillsManifest):
        self.manifest = manifest
    
    def evaluate_review(self, skill_path: Path) -> Dict:
        """
        Run review evaluation on skill structure
        
        Returns dict with:
        - total_score: 0-100
        - breakdown: detailed scoring
        - checks: list of passed/failed checks
        """
        skill_file = skill_path / "SKILL.md"
        if not skill_file.exists():
            return {"error": "SKILL.md not found"}
        
        with open(skill_file, 'r') as f:
            content = f.read()
        
        score = 0
        breakdown = {}
        checks = []
        
        # Frontmatter validation (20 points)
        frontmatter_score = 0
        if content.startswith("---"):
            try:
                _, frontmatter, _ = content.split("---", 2)
                fm_content = frontmatter.strip()
                
                # Check name field
                if "name:" in fm_content:
                    frontmatter_score += 5
                    checks.append({"name": "Frontmatter has name", "passed": True})
                else:
                    checks.append({"name": "Frontmatter has name", "passed": False})
                
                # Check description field
                if "description:" in fm_content:
                    frontmatter_score += 5
                    checks.append({"name": "Frontmatter has description", "passed": True})
                else:
                    checks.append({"name": "Frontmatter has description", "passed": False})
                
                # Check for trigger keywords in description
                if any(word in fm_content.lower() for word in ["use when", "for ", "help"]):
                    frontmatter_score += 5
                    checks.append({"name": "Description has trigger keywords", "passed": True})
                else:
                    checks.append({"name": "Description has trigger keywords", "passed": False})
                
                # Check YAML validity
                frontmatter_score += 5
                checks.append({"name": "YAML frontmatter valid", "passed": True})
                
            except ValueError:
                checks.append({"name": "YAML frontmatter valid", "passed": False})
        
        score += frontmatter_score
        breakdown["frontmatter"] = frontmatter_score
        
        # Content organization (30 points)
        org_score = 0
        lines = content.split("\n")
        
        # Check length
        if len(lines) <= 500:
            org_score += 10
            checks.append({"name": "Content under 500 lines", "passed": True})
        else:
            checks.append({"name": "Content under 500 lines", "passed": False})
        
        # Check sections
        sections = ["what this skill provides", "when to use this skill"]
        for section in sections:
            if section in content.lower():
                org_score += 5
                checks.append({"name": f"Has '{section}' section", "passed": True})
            else:
                checks.append({"name": f"Has '{section}' section", "passed": False})
        
        # Check for patterns/implementation section
        if "pattern" in content.lower() or "implementation" in content.lower():
            org_score += 5
            checks.append({"name": "Has patterns/implementation section", "passed": True})
        else:
            checks.append({"name": "Has patterns/implementation section", "passed": False})
        
        score += org_score
        breakdown["organization"] = org_score
        
        # Self-containment (30 points)
        containment_score = 30
        
        # Check for forbidden references
        forbidden_patterns = ["@rule:", "@persona:", "@example:"]
        for pattern in forbidden_patterns:
            if pattern in content:
                containment_score -= 10
                checks.append({"name": f"No {pattern} references", "passed": False})
            else:
                checks.append({"name": f"No {pattern} references", "passed": True})
        
        score += containment_score
        breakdown["self_containment"] = containment_score
        
        # Documentation quality (20 points)
        doc_score = 0
        
        # Check markdown syntax (basic)
        if content.count("#") > 0:
            doc_score += 5
            checks.append({"name": "Uses markdown headers", "passed": True})
        
        # Check for code examples
        if "```" in content:
            doc_score += 5
            checks.append({"name": "Has code examples", "passed": True})
        
        # Check for references section
        if "reference" in content.lower():
            doc_score += 5
            checks.append({"name": "Has references section", "passed": True})
        
        # Check for setup/installation
        if any(word in content.lower() for word in ["setup", "install", "prerequisite"]):
            doc_score += 5
            checks.append({"name": "Has setup instructions", "passed": True})
        
        score += doc_score
        breakdown["documentation"] = doc_score
        
        return {
            "total_score": score,
            "breakdown": breakdown,
            "checks": checks,
            "rating": self._get_rating(score)
        }
    
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


class SkillAutoDiscovery:
    """Auto-discovers relevant skills based on feature descriptions"""
    
    def __init__(self, manifest: SkillsManifest):
        self.manifest = manifest
    
    def discover(self, feature_description: str) -> List[Dict]:
        """
        Discover skills relevant to feature description
        
        Returns list of dicts with:
        - skill_id
        - skill_name
        - relevance_score
        - reason
        """
        skills = self.manifest.list_skills()
        
        if not skills:
            return []
        
        # Load all skill metadata
        skill_data = []
        for skill_id, metadata in skills.items():
            skill_info = self._load_skill_info(skill_id, metadata)
            if skill_info:
                skill_data.append(skill_info)
        
        # Use simple keyword matching (in production, use LLM)
        matches = []
        feature_lower = feature_description.lower()
        
        for skill in skill_data:
            relevance = self._calculate_relevance(skill, feature_lower)
            if relevance["score"] > 0.3:  # Threshold
                matches.append({
                    "skill_id": skill["id"],
                    "skill_name": skill["name"],
                    "relevance_score": relevance["score"],
                    "reason": relevance["reason"]
                })
        
        # Sort by relevance
        matches.sort(key=lambda x: x["relevance_score"], reverse=True)
        
        return matches[:5]  # Top 5
    
    def _load_skill_info(self, skill_id: str, metadata: SkillMetadata) -> Optional[Dict]:
        """Load skill info from SKILL.md"""
        # Find skill directory
        skills_dir = self.manifest.skills_dir
        
        for skill_dir in skills_dir.iterdir():
            if skill_dir.is_dir():
                skill_file = skill_dir / "SKILL.md"
                if skill_file.exists():
                    with open(skill_file, 'r') as f:
                        content = f.read()
                    
                    # Extract frontmatter
                    try:
                        if content.startswith("---"):
                            _, frontmatter, body = content.split("---", 2)
                            fm_lines = frontmatter.strip().split("\n")
                            fm = {}
                            for line in fm_lines:
                                if ":" in line:
                                    k, v = line.split(":", 1)
                                    fm[k.strip()] = v.strip()
                            
                            return {
                                "id": skill_id,
                                "name": fm.get("name", skill_dir.name),
                                "description": fm.get("description", ""),
                                "content": body.lower()
                            }
                    except ValueError:
                        pass
        
        return None
    
    def _calculate_relevance(self, skill: Dict, feature_lower: str) -> Dict:
        """Calculate relevance score between skill and feature"""
        score = 0.0
        reasons = []
        
        # Keyword matching
        description = skill.get("description", "").lower()
        content = skill.get("content", "").lower()
        
        # Extract keywords from feature (simple approach)
        feature_words = set(feature_lower.split())
        desc_words = set(description.split())
        content_words = set(content.split())
        
        # Calculate overlap
        desc_overlap = len(feature_words & desc_words) / max(len(feature_words), 1)
        content_overlap = len(feature_words & content_words) / max(len(feature_words), 1)
        
        score = desc_overlap * 0.6 + content_overlap * 0.4
        
        if desc_overlap > 0:
            reasons.append("Description matches")
        if content_overlap > 0:
            reasons.append("Content matches")
        
        return {
            "score": min(score, 1.0),
            "reason": ", ".join(reasons) if reasons else "Low relevance"
        }


# CLI Integration
import typer
from typing import List

skills_app = typer.Typer(help="Manage agent skills")


@skills_app.command()
def search(
    query: str = typer.Argument(..., help="Search query"),
    category: Optional[str] = typer.Option(None, "--category", help="Filter by category"),
    min_score: Optional[int] = typer.Option(None, "--min-score", help="Minimum evaluation score"),
    json_output: bool = typer.Option(False, "--json", help="Output as JSON")
):
    """Search for skills in the registry"""
    typer.echo(f"Searching for: {query}")
    # Implementation would search registry
    typer.echo("Feature coming soon - registry integration needed")


@skills_app.command()
def install(
    skill_ref: str = typer.Argument(..., help="Skill reference (github:org/repo/skill, local:./path)"),
    version: Optional[str] = typer.Option(None, "--version", help="Specific version"),
    no_save: bool = typer.Option(False, "--no-save", help="Don't save to manifest"),
    force: bool = typer.Option(False, "--force", help="Reinstall if exists")
):
    """Install a skill"""
    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)
    installer = SkillInstaller(manifest)
    
    success, message = installer.install(skill_ref, version, save=not no_save)
    
    if success:
        typer.echo(typer.style(f"✓ {message}", fg=typer.colors.GREEN))
    else:
        typer.echo(typer.style(f"✗ {message}", fg=typer.colors.RED))
        raise typer.Exit(1)


@skills_app.command()
def list(
    outdated: bool = typer.Option(False, "--outdated", help="Show only outdated"),
    json_output: bool = typer.Option(False, "--json", help="Output as JSON")
):
    """List installed skills"""
    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)
    skills = manifest.list_skills()
    
    if not skills:
        typer.echo("No skills installed")
        return
    
    if json_output:
        typer.echo(json.dumps({
            skill_id: {
                "version": m.version,
                "source": m.source,
                "installed_at": m.installed_at
            }
            for skill_id, m in skills.items()
        }, indent=2))
    else:
        typer.echo(f"Installed Skills ({len(skills)}):\n")
        for skill_id, metadata in skills.items():
            eval_score = ""
            if metadata.evaluation:
                review = metadata.evaluation.get("review_score", "N/A")
                task = metadata.evaluation.get("task_score", "N/A")
                eval_score = f" (Review: {review}, Task: {task})"
            
            typer.echo(f"  {skill_id}@{metadata.version}")
            typer.echo(f"    Source: {metadata.source}")
            typer.echo(f"    Installed: {metadata.installed_at[:10]}{eval_score}\n")


@skills_app.command()
def remove(
    skill_name: str = typer.Argument(..., help="Skill name to remove"),
    force: bool = typer.Option(False, "--force", help="Remove without confirmation")
):
    """Remove an installed skill"""
    if not force:
        confirm = typer.confirm(f"Remove {skill_name}?")
        if not confirm:
            typer.echo("Cancelled")
            return
    
    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)
    
    # Find skill by name
    skills = manifest.list_skills()
    skill_id = None
    for sid in skills.keys():
        if skill_name in sid:
            skill_id = sid
            break
    
    if not skill_id:
        typer.echo(typer.style(f"Skill not found: {skill_name}", fg=typer.colors.RED))
        raise typer.Exit(1)
    
    success = manifest.remove_skill(skill_id)
    if success:
        typer.echo(typer.style(f"✓ Removed {skill_id}", fg=typer.colors.GREEN))
    else:
        typer.echo(typer.style(f"✗ Failed to remove {skill_id}", fg=typer.colors.RED))


@skills_app.command()
def eval(
    skill_path: str = typer.Argument(..., help="Path to skill or skill name"),
    review: bool = typer.Option(False, "--review", help="Review evaluation only"),
    task: bool = typer.Option(False, "--task", help="Task evaluation only"),
    full: bool = typer.Option(False, "--full", help="Full evaluation"),
    report: bool = typer.Option(False, "--report", help="Generate report")
):
    """Evaluate skill quality"""
    project_path = Path.cwd()
    manifest = SkillsManifest(project_path)
    evaluator = SkillEvaluator(manifest)
    
    # Resolve skill path
    skill_path_obj = Path(skill_path)
    if not skill_path_obj.exists():
        # Try to find in installed skills
        skills_dir = project_path / ".specify" / "skills"
        for skill_dir in skills_dir.iterdir():
            if skill_dir.is_dir() and skill_path in skill_dir.name:
                skill_path_obj = skill_dir
                break
    
    if not skill_path_obj.exists():
        typer.echo(typer.style(f"Skill not found: {skill_path}", fg=typer.colors.RED))
        raise typer.Exit(1)
    
    # Run review evaluation
    if review or full or (not review and not task):
        typer.echo("Running review evaluation...")
        result = evaluator.evaluate_review(skill_path_obj)
        
        if "error" in result:
            typer.echo(typer.style(f"Error: {result['error']}", fg=typer.colors.RED))
            return
        
        typer.echo(f"\nReview Score: {result['total_score']}/100 ({result['rating']})")
        typer.echo("\nBreakdown:")
        for category, score in result['breakdown'].items():
            typer.echo(f"  {category}: {score} points")
        
        if report:
            typer.echo("\nDetailed Checks:")
            for check in result['checks']:
                status = "✓" if check['passed'] else "✗"
                color = typer.colors.GREEN if check['passed'] else typer.colors.RED
                typer.echo(typer.style(f"  {status} {check['name']}", fg=color))


if __name__ == "__main__":
    skills_app()
