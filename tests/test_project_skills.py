"""Tests for project-level skill installation via install_project_skills()."""

from unittest.mock import patch
from pathlib import Path
import json
import pytest
from specify_cli._init_fork import install_project_skills


def test_no_skills_when_no_config(tmp_path):
    """No skills installed when neither .skills.json nor .specify/skills/ exist."""
    with patch("specify_cli._init_fork._resolve_skills_dest") as mock_resolve:
        skills_dest = tmp_path / ".agent" / "skills"
        mock_resolve.return_value = skills_dest

        result = install_project_skills(tmp_path, "test-agent")

        assert result == []
        assert not skills_dest.exists()


def test_installs_skills_from_skills_json(tmp_path):
    """Skills from project-root .skills.json are installed with adlc- prefix."""
    skill_dir = tmp_path / "skills" / "my-custom-skill"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: my-custom-skill\n---\n# Custom Skill\n")

    (tmp_path / ".skills.json").write_text(json.dumps({
        "skills": {"required": {"local:./skills/my-custom-skill": {}}}
    }))

    with patch("specify_cli._init_fork._resolve_skills_dest") as mock_resolve:
        skills_dest = tmp_path / ".agent" / "skills"
        mock_resolve.return_value = skills_dest

        result = install_project_skills(tmp_path, "test-agent")

        assert result == ["adlc-my-custom-skill"]
        skill_file = skills_dest / "adlc-my-custom-skill" / "SKILL.md"
        assert skill_file.exists()
        content = skill_file.read_text()
        assert "name: adlc-my-custom-skill" in content


def test_installs_local_skills_from_specify_skills(tmp_path):
    """Skills from .specify/skills/ are installed with adlc- prefix."""
    skill_dir = tmp_path / ".specify" / "skills" / "local-tool"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: local-tool\n---\n# Local Tool\n")

    with patch("specify_cli._init_fork._resolve_skills_dest") as mock_resolve:
        skills_dest = tmp_path / ".agent" / "skills"
        mock_resolve.return_value = skills_dest

        result = install_project_skills(tmp_path, "test-agent")

        assert result == ["adlc-local-tool"]
        skill_file = skills_dest / "adlc-local-tool" / "SKILL.md"
        assert skill_file.exists()
        content = skill_file.read_text()
        assert "name: adlc-local-tool" in content


def test_skips_existing_skills_without_force(tmp_path):
    """Existing skill is not reinstalled when force=False."""
    skill_dir = tmp_path / "skills" / "existing"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: existing\n---\n# Original\n")

    (tmp_path / ".skills.json").write_text(json.dumps({
        "skills": {"required": {"local:./skills/existing": {}}}
    }))

    with patch("specify_cli._init_fork._resolve_skills_dest") as mock_resolve:
        skills_dest = tmp_path / ".agent" / "skills"
        mock_resolve.return_value = skills_dest

        existing_target = skills_dest / "adlc-existing" / "SKILL.md"
        existing_target.parent.mkdir(parents=True)
        existing_target.write_text("---\nname: adlc-existing\n---\n# Already Here\n")

        result = install_project_skills(tmp_path, "test-agent", force=False)

        assert "adlc-existing" not in result
        assert existing_target.read_text() == "---\nname: adlc-existing\n---\n# Already Here\n"


def test_reinstalls_existing_skills_when_force(tmp_path):
    """Existing skill is reinstalled when force=True."""
    skill_dir = tmp_path / "skills" / "existing"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: existing\n---\n# Fresh Copy\n")

    (tmp_path / ".skills.json").write_text(json.dumps({
        "skills": {"required": {"local:./skills/existing": {}}}
    }))

    with patch("specify_cli._init_fork._resolve_skills_dest") as mock_resolve:
        skills_dest = tmp_path / ".agent" / "skills"
        mock_resolve.return_value = skills_dest

        existing_target = skills_dest / "adlc-existing" / "SKILL.md"
        existing_target.parent.mkdir(parents=True)
        existing_target.write_text("---\nname: adlc-existing\n---\n# Stale\n")

        result = install_project_skills(tmp_path, "test-agent", force=True)

        assert result == ["adlc-existing"]
        assert "Fresh Copy" in existing_target.read_text()
        assert "name: adlc-existing" in existing_target.read_text()


def test_skips_non_local_refs(tmp_path):
    """Non-local references in .skills.json are skipped."""
    (tmp_path / ".skills.json").write_text(json.dumps({
        "skills": {"required": {
            "github:org/repo/skill": {},
            "marketplace:some-skill": {},
        }}
    }))

    with patch("specify_cli._init_fork._resolve_skills_dest") as mock_resolve:
        skills_dest = tmp_path / ".agent" / "skills"
        mock_resolve.return_value = skills_dest

        result = install_project_skills(tmp_path, "test-agent")

        assert result == []


def test_both_sources_installed(tmp_path):
    """Skills from both .skills.json and .specify/skills/ are installed."""
    skill_dir = tmp_path / "skills" / "json-skill"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: json-skill\n---\n")

    local_dir = tmp_path / ".specify" / "skills" / "local-skill"
    local_dir.mkdir(parents=True)
    (local_dir / "SKILL.md").write_text("---\nname: local-skill\n---\n")

    (tmp_path / ".skills.json").write_text(json.dumps({
        "skills": {"required": {"local:./skills/json-skill": {}}}
    }))

    with patch("specify_cli._init_fork._resolve_skills_dest") as mock_resolve:
        skills_dest = tmp_path / ".agent" / "skills"
        mock_resolve.return_value = skills_dest

        result = install_project_skills(tmp_path, "test-agent")

        assert set(result) == {"adlc-json-skill", "adlc-local-skill"}
        assert (skills_dest / "adlc-json-skill" / "SKILL.md").exists()
        assert (skills_dest / "adlc-local-skill" / "SKILL.md").exists()


def test_missing_skill_md_skipped(tmp_path):
    """Skill directories without SKILL.md are silently skipped."""
    skill_dir = tmp_path / "skills" / "no-md"
    skill_dir.mkdir(parents=True)
    (skill_dir / "other.txt").write_text("not a skill")

    (tmp_path / ".skills.json").write_text(json.dumps({
        "skills": {"required": {"local:./skills/no-md": {}}}
    }))

    with patch("specify_cli._init_fork._resolve_skills_dest") as mock_resolve:
        skills_dest = tmp_path / ".agent" / "skills"
        mock_resolve.return_value = skills_dest

        result = install_project_skills(tmp_path, "test-agent")

        assert result == []


def test_does_not_double_prefix(tmp_path):
    """If SKILL.md name already has adlc- prefix, don't double it."""
    skill_dir = tmp_path / "skills" / "prefixed"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: adlc-prefixed\n---\n# Already prefixed\n")

    (tmp_path / ".skills.json").write_text(json.dumps({
        "skills": {"required": {"local:./skills/prefixed": {}}}
    }))

    with patch("specify_cli._init_fork._resolve_skills_dest") as mock_resolve:
        skills_dest = tmp_path / ".agent" / "skills"
        mock_resolve.return_value = skills_dest

        result = install_project_skills(tmp_path, "test-agent")

        assert result == ["adlc-prefixed"]
        skill_file = skills_dest / "adlc-prefixed" / "SKILL.md"
        content = skill_file.read_text()
        assert content.count("adlc-prefixed") >= 1
        assert "name: adlc-prefixed" in content
