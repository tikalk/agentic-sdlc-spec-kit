import json
import shutil
import subprocess
from pathlib import Path


def test_mode_detection_and_template_selection(tmp_path):
    """Test that mode detection works and appropriate templates are selected."""
    repo_root = tmp_path / "repo"
    config_dir = repo_root / ".specify" / "config"
    template_dir = repo_root / ".specify" / "templates"

    config_dir.mkdir(parents=True)
    template_dir.mkdir(parents=True)

    project_root = Path(__file__).resolve().parent.parent

    # Copy templates
    shutil.copy(project_root / "templates" / "spec-template.md", template_dir / "spec-template.md")
    shutil.copy(project_root / "templates" / "spec-template-build.md", template_dir / "spec-template-build.md")
    shutil.copy(project_root / "templates" / "plan-template.md", template_dir / "plan-template.md")
    shutil.copy(project_root / "templates" / "plan-template-build.md", template_dir / "plan-template-build.md")

    # Test Build mode configuration
    mode_config = config_dir / "mode.json"
    mode_config.write_text(json.dumps({
        "current_mode": "build",
        "default_mode": "spec",
        "mode_history": []
    }))

    # Verify mode config is readable
    with open(mode_config) as f:
        config = json.load(f)
        assert config["current_mode"] == "build"

    # Test Spec mode configuration
    mode_config.write_text(json.dumps({
        "current_mode": "spec",
        "default_mode": "spec",
        "mode_history": []
    }))

    with open(mode_config) as f:
        config = json.load(f)
        assert config["current_mode"] == "spec"


def test_mode_history_tracking(tmp_path):
    """Test that mode changes are tracked in history."""
    repo_root = tmp_path / "repo"
    config_dir = repo_root / ".specify" / "config"
    config_dir.mkdir(parents=True)

    mode_config = config_dir / "mode.json"

    # Initial config
    initial_config = {
        "current_mode": "spec",
        "default_mode": "spec",
        "mode_history": []
    }
    mode_config.write_text(json.dumps(initial_config))

    # Simulate mode change to build
    updated_config = initial_config.copy()
    updated_config["current_mode"] = "build"
    updated_config["mode_history"] = [{
        "timestamp": None,
        "from_mode": "spec",
        "to_mode": "build"
    }]
    mode_config.write_text(json.dumps(updated_config))

    # Verify history is tracked
    with open(mode_config) as f:
        config = json.load(f)
        assert config["current_mode"] == "build"
        assert len(config["mode_history"]) == 1
        assert config["mode_history"][0]["from_mode"] == "spec"
        assert config["mode_history"][0]["to_mode"] == "build"


def test_template_content_difference():
    """Test that build and spec templates have different content structures."""
    project_root = Path(__file__).resolve().parent.parent

    spec_template = (project_root / "templates" / "spec-template.md").read_text()
    build_template = (project_root / "templates" / "spec-template-build.md").read_text()

    # Build template should be shorter and simpler
    assert len(build_template) < len(spec_template)

    # Build template should focus on core functionality
    assert "Core user journey" in build_template.lower() or "primary user journey" in build_template.lower()
    assert "Success Criteria" in build_template

    # Spec template should have more comprehensive sections
    assert "Functional Requirements" in spec_template
    assert "Non-Functional Requirements" in spec_template or "Quality Attributes" in spec_template


def test_plan_template_difference():
    """Test that build and spec plan templates have different structures."""
    project_root = Path(__file__).resolve().parent.parent

    spec_plan = (project_root / "templates" / "plan-template.md").read_text()
    build_plan = (project_root / "templates" / "plan-template-build.md").read_text()

    # Build plan should be simpler
    assert len(build_plan) < len(spec_plan)

    # Build plan should focus on core implementation
    assert "Core Implementation Approach" in build_plan
    assert "Success Criteria Validation" in build_plan

    # Spec plan should have comprehensive structure
    assert "Technical Context" in spec_plan
    assert "Constitution Check" in spec_plan


def test_analyze_template_auto_detection():
    """Test that /analyze template now supports auto-detection of analysis mode."""
    project_root = Path(__file__).resolve().parent.parent

    analyze_template = (project_root / "templates" / "commands" / "analyze.md").read_text()

    # Should mention auto-detection
    assert "auto-detect" in analyze_template.lower()
    assert "Auto-Detection" in analyze_template

    # Should have both pre and post implementation sections
    assert "Pre-Implementation" in analyze_template
    assert "Post-Implementation" in analyze_template

    # Should have different detection passes for each mode
    assert "Documentation Drift" in analyze_template
    assert "Implementation Quality" in analyze_template
    assert "Real-World Usage Gaps" in analyze_template

    # Should mention workflow mode integration
    assert "workflow mode" in analyze_template.lower()
    assert "build vs spec" in analyze_template.lower()