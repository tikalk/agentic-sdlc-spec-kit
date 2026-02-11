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
    shutil.copy(
        project_root / "templates" / "spec-template.md",
        template_dir / "spec-template.md",
    )
    shutil.copy(
        project_root / "templates" / "spec-template-build.md",
        template_dir / "spec-template-build.md",
    )
    shutil.copy(
        project_root / "templates" / "plan-template.md",
        template_dir / "plan-template.md",
    )
    shutil.copy(
        project_root / "templates" / "plan-template-build.md",
        template_dir / "plan-template-build.md",
    )

    # Test Build mode configuration
    config_file = config_dir / "config.json"
    build_config = {
        "version": "1.0",
        "project": {
            "created": "2025-01-01T00:00:00",
            "last_modified": "2025-01-01T00:00:00",
        },
        "workflow": {"current_mode": "build", "default_mode": "spec"},
        "options": {
            "tdd_enabled": False,
            "contracts_enabled": False,
            "data_models_enabled": False,
            "risk_tests_enabled": False,
        },
        "mode_defaults": {
            "build": {
                "tdd_enabled": False,
                "contracts_enabled": False,
                "data_models_enabled": False,
                "risk_tests_enabled": False,
            },
            "spec": {
                "tdd_enabled": True,
                "contracts_enabled": True,
                "data_models_enabled": True,
                "risk_tests_enabled": True,
            },
        },
        "spec_sync": {
            "enabled": False,
            "queue": {
                "version": "1.0",
                "created": "2025-01-01T00:00:00",
                "pending": [],
                "processed": [],
            },
        },
        "gateway": {"url": None, "token": None, "suppress_warning": False},
    }
    config_file.write_text(json.dumps(build_config))

    # Verify mode config is readable
    with open(config_file) as f:
        config = json.load(f)
        assert config["workflow"]["current_mode"] == "build"

    # Test Spec mode configuration
    spec_config = build_config.copy()
    spec_config["workflow"]["current_mode"] = "spec"
    config_file.write_text(json.dumps(spec_config))

    with open(config_file) as f:
        config = json.load(f)
        assert config["workflow"]["current_mode"] == "spec"


def test_template_content_difference():
    """Test that build and spec templates have different content structures."""
    project_root = Path(__file__).resolve().parent.parent

    spec_template = (project_root / "templates" / "spec-template.md").read_text()
    build_template = (project_root / "templates" / "spec-template-build.md").read_text()

    # Build template should be shorter and simpler
    assert len(build_template) < len(spec_template)

    # Build template should focus on core functionality
    assert (
        "Core user journey" in build_template.lower()
        or "primary user journey" in build_template.lower()
    )
    assert "Success Criteria" in build_template

    # Spec template should have more comprehensive sections
    assert "Functional Requirements" in spec_template
    assert (
        "Non-Functional Requirements" in spec_template
        or "Quality Attributes" in spec_template
    )


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

    analyze_template = (
        project_root / "templates" / "commands" / "analyze.md"
    ).read_text()

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
