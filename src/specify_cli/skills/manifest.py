"""
Skills Manifest Management

Manages the skills.json manifest file that tracks installed skills,
their versions, and evaluation scores.
"""

import json
from dataclasses import dataclass, asdict, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


@dataclass
class SkillEvaluation:
    """Evaluation scores for a skill"""

    review_score: Optional[int] = None  # 0-100
    task_score: Optional[int] = None  # 0-100
    last_evaluated: Optional[str] = None


@dataclass
class SkillMetadata:
    """Metadata for an installed skill"""

    version: str
    installed_at: str
    source: str  # 'github', 'gitlab', 'local', 'registry'
    evaluation: Optional[SkillEvaluation] = None
    metadata: Optional[Dict[str, Any]] = None

    def to_dict(self) -> Dict:
        """Convert to dictionary for JSON serialization"""
        result = {
            "version": self.version,
            "installed_at": self.installed_at,
            "source": self.source,
        }
        if self.evaluation:
            result["evaluation"] = {
                k: v for k, v in asdict(self.evaluation).items() if v is not None
            }
        if self.metadata:
            result["metadata"] = self.metadata
        return result

    @classmethod
    def from_dict(cls, data: Dict) -> "SkillMetadata":
        """Create from dictionary"""
        eval_data = data.get("evaluation")
        evaluation = None
        if eval_data:
            evaluation = SkillEvaluation(
                review_score=eval_data.get("review_score"),
                task_score=eval_data.get("task_score"),
                last_evaluated=eval_data.get("last_evaluated"),
            )

        return cls(
            version=data["version"],
            installed_at=data["installed_at"],
            source=data["source"],
            evaluation=evaluation,
            metadata=data.get("metadata"),
        )


@dataclass
class SkillLockEntry:
    """Lockfile entry for reproducible installations"""

    resolved: str  # Resolved URL
    integrity: Optional[str] = None  # SHA256 hash
    dependencies: Optional[List[str]] = None


class SkillsManifest:
    """
    Manages the skills.json manifest file.

    Location: .specify/skills.json (project-level)

    Structure:
    {
        "version": "1.0.0",
        "skills": {
            "github:org/repo/skill-name": { ... metadata ... }
        },
        "lockfile": {
            "github:org/repo/skill-name": { ... lock entry ... }
        },
        "config": { ... }
    }
    """

    def __init__(self, project_path: Path):
        self.project_path = project_path
        self.manifest_path = project_path / ".specify" / "skills.json"
        self.skills_dir = project_path / ".specify" / "skills"
        self._data: Optional[Dict] = None

    def load(self) -> Dict:
        """Load manifest from disk, creating default if not exists"""
        if self._data is not None:
            return self._data

        if not self.manifest_path.exists():
            self._data = self._create_default()
        else:
            with open(self.manifest_path, "r", encoding="utf-8") as f:
                self._data = json.load(f)

        return self._data

    def save(self) -> None:
        """Save manifest to disk"""
        if self._data is None:
            self._data = self._create_default()

        self.manifest_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.manifest_path, "w", encoding="utf-8") as f:
            json.dump(self._data, f, indent=2)

    def _create_default(self) -> Dict:
        """Create default manifest structure"""
        return {
            "version": "1.0.0",
            "skills": {},
            "lockfile": {},
            "config": {
                "auto_activation_threshold": 0.7,
                "max_auto_skills": 3,
                "preserve_user_edits": True,
            },
        }

    def exists(self) -> bool:
        """Check if manifest file exists"""
        return self.manifest_path.exists()

    def get_skill(self, skill_id: str) -> Optional[SkillMetadata]:
        """Get skill metadata by ID"""
        data = self.load()
        skill_data = data["skills"].get(skill_id)
        if skill_data is None:
            return None
        return SkillMetadata.from_dict(skill_data)

    def add_skill(
        self,
        skill_id: str,
        metadata: SkillMetadata,
        lock_entry: Optional[SkillLockEntry] = None,
    ) -> None:
        """Add or update a skill in the manifest"""
        data = self.load()
        data["skills"][skill_id] = metadata.to_dict()

        if lock_entry:
            data["lockfile"][skill_id] = {
                "resolved": lock_entry.resolved,
            }
            if lock_entry.integrity:
                data["lockfile"][skill_id]["integrity"] = lock_entry.integrity
            if lock_entry.dependencies:
                data["lockfile"][skill_id]["dependencies"] = lock_entry.dependencies

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
            skill_id: SkillMetadata.from_dict(skill_data)
            for skill_id, skill_data in data["skills"].items()
        }

    def get_config(self, key: str, default: Any = None) -> Any:
        """Get a config value"""
        data = self.load()
        return data.get("config", {}).get(key, default)

    def set_config(self, key: str, value: Any) -> None:
        """Set a config value"""
        data = self.load()
        if "config" not in data:
            data["config"] = {}
        data["config"][key] = value
        self.save()

    def update_evaluation(
        self,
        skill_id: str,
        review_score: Optional[int] = None,
        task_score: Optional[int] = None,
    ) -> bool:
        """Update evaluation scores for a skill"""
        data = self.load()

        if skill_id not in data["skills"]:
            return False

        if "evaluation" not in data["skills"][skill_id]:
            data["skills"][skill_id]["evaluation"] = {}

        if review_score is not None:
            data["skills"][skill_id]["evaluation"]["review_score"] = review_score
        if task_score is not None:
            data["skills"][skill_id]["evaluation"]["task_score"] = task_score

        data["skills"][skill_id]["evaluation"]["last_evaluated"] = (
            datetime.utcnow().isoformat() + "Z"
        )

        self.save()
        return True


class TeamSkillsManifest:
    """
    Manages the team-ai-directives/.skills.json manifest.

    This manifest defines team-curated skills including:
    - Required skills (auto-install on init)
    - Recommended skills (suggested but optional)
    - Internal skills (local team skills)
    - Blocked skills (disallowed)
    - Policy settings
    """

    def __init__(self, directives_path: Path):
        self.directives_path = directives_path
        self.manifest_path = directives_path / ".skills.json"
        self._data: Optional[Dict] = None

    def load(self) -> Dict:
        """Load team manifest from disk"""
        if self._data is not None:
            return self._data

        if not self.manifest_path.exists():
            self._data = self._create_default()
        else:
            with open(self.manifest_path, "r", encoding="utf-8") as f:
                self._data = json.load(f)

        return self._data

    def exists(self) -> bool:
        """Check if team manifest exists"""
        return self.manifest_path.exists()

    def _create_default(self) -> Dict:
        """Create default team manifest structure"""
        return {
            "version": "1.0.0",
            "source": "team-ai-directives",
            "skills": {
                "required": {},
                "recommended": {},
                "internal": {},
                "blocked": [],
            },
            "policy": {
                "auto_install_required": True,
                "enforce_blocked": True,
                "allow_project_override": True,
            },
        }

    def get_required_skills(self) -> Dict[str, str]:
        """Get required skills with their version constraints"""
        data = self.load()
        return data.get("skills", {}).get("required", {})

    def get_recommended_skills(self) -> Dict[str, str]:
        """Get recommended skills with their version constraints"""
        data = self.load()
        return data.get("skills", {}).get("recommended", {})

    def get_internal_skills(self) -> Dict[str, str]:
        """Get internal (local) skills"""
        data = self.load()
        return data.get("skills", {}).get("internal", {})

    def get_blocked_skills(self) -> List[str]:
        """Get list of blocked skill IDs"""
        data = self.load()
        return data.get("skills", {}).get("blocked", [])

    def is_blocked(self, skill_id: str) -> bool:
        """Check if a skill is blocked"""
        blocked = self.get_blocked_skills()
        return skill_id in blocked

    def get_policy(self, key: str, default: Any = None) -> Any:
        """Get a policy setting"""
        data = self.load()
        return data.get("policy", {}).get(key, default)

    def should_auto_install_required(self) -> bool:
        """Check if required skills should auto-install"""
        return self.get_policy("auto_install_required", True)

    def should_enforce_blocked(self) -> bool:
        """Check if blocked skills should be enforced"""
        return self.get_policy("enforce_blocked", True)
