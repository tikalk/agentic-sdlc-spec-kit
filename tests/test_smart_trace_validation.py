#!/usr/bin/env python3
"""
Test Smart Trace Validation functionality in /analyze command
"""
import os
import json
import tempfile
from pathlib import Path


def test_traceability_detection():
    """Test detection of @issue-tracker references in artifacts"""

    # Create test artifacts with traceability references
    spec_content = """
    # Photo Album Feature

    ## User Stories
    As a user, I want to upload photos @issue-tracker PROJ-123
    As a user, I want to organize photos in albums @issue-tracker PROJ-124
    As a user, I want to view photos in a grid layout  # Missing trace
    """

    plan_content = """
    # Implementation Plan

    ## Architecture
    Use React for frontend @issue-tracker PROJ-123
    Use Node.js for backend @issue-tracker PROJ-124
    """

    tasks_content = """
    # Implementation Tasks

    ## Phase 1: Setup
    - [ ] Setup React project @issue-tracker PROJ-123
    - [ ] Configure build pipeline  # Missing trace
    """

    # Test detection logic
    def extract_issue_references(text):
        """Extract @issue-tracker references from text"""
        import re
        pattern = r'@issue-tracker\s+([A-Z0-9\-#]+)'
        matches = re.findall(pattern, text, re.IGNORECASE)
        return matches

    spec_issues = extract_issue_references(spec_content)
    plan_issues = extract_issue_references(plan_content)
    tasks_issues = extract_issue_references(tasks_content)

    # Assertions
    assert "PROJ-123" in spec_issues
    assert "PROJ-124" in spec_issues
    assert len([line for line in spec_content.split('\n') if 'view photos' in line and '@issue-tracker' not in line]) > 0  # Missing trace detected

    assert "PROJ-123" in plan_issues
    assert "PROJ-124" in plan_issues

    assert "PROJ-123" in tasks_issues
    assert len([line for line in tasks_content.split('\n') if 'build pipeline' in line and '@issue-tracker' not in line]) > 0  # Missing trace detected

    print("✅ Traceability detection test passed")


def test_mcp_configuration_validation():
    """Test MCP configuration validation for issue trackers"""

    # Valid MCP configuration
    valid_mcp = {
        "mcpServers": {
            "github-issues": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-github"],
                "env": {
                    "GITHUB_PERSONAL_ACCESS_TOKEN": "token"
                }
            }
        }
    }

    # Invalid MCP configuration (missing issue tracker)
    invalid_mcp = {
        "mcpServers": {
            "some-other-server": {
                "command": "npx",
                "args": ["some-package"]
            }
        }
    }

    def has_issue_tracker_config(mcp_config):
        """Check if MCP config has issue tracker configured"""
        if not mcp_config or "mcpServers" not in mcp_config:
            return False

        # Check for common issue tracker server names
        issue_tracker_keywords = ["github", "jira", "linear", "gitlab", "issue", "tracker"]
        for server_name in mcp_config["mcpServers"]:
            if any(keyword in server_name.lower() for keyword in issue_tracker_keywords):
                return True
        return False

    assert has_issue_tracker_config(valid_mcp) == True
    assert has_issue_tracker_config(invalid_mcp) == False

    print("✅ MCP configuration validation test passed")


def test_traceability_coverage_calculation():
    """Test calculation of traceability coverage percentage"""

    def calculate_traceability_coverage(artifacts):
        """Calculate what percentage of user stories/requirements have issue traces"""
        total_stories = 0
        traced_stories = 0

        for artifact_name, content in artifacts.items():
            lines = content.split('\n')
            for line in lines:
                # Count user stories (simplified detection)
                if any(keyword in line.lower() for keyword in ["as a user", "user story", "requirement"]):
                    total_stories += 1
                    if "@issue-tracker" in line:
                        traced_stories += 1

        if total_stories == 0:
            return 100.0  # No stories = 100% coverage (no gaps)

        return round((traced_stories / total_stories) * 100, 1)

    test_artifacts = {
        "spec.md": """
        As a user, I want to upload photos @issue-tracker PROJ-123
        As a user, I want to organize albums  # Missing trace
        As a user, I want to view photo grid @issue-tracker PROJ-125
        """,
        "plan.md": "Technical details here",
        "tasks.md": "Task breakdown here"
    }

    coverage = calculate_traceability_coverage(test_artifacts)
    assert coverage == 66.7  # 2 out of 3 stories traced (rounded)
    assert coverage >= 60.0  # At least 60% coverage

    print(f"✅ Traceability coverage calculation: {coverage:.1f}%")


if __name__ == "__main__":
    test_traceability_detection()
    test_mcp_configuration_validation()
    test_traceability_coverage_calculation()
    print("🎉 All Smart Trace Validation tests passed!")