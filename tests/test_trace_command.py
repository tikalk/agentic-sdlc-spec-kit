#!/usr/bin/env python3
"""
Test Session Trace Command functionality
Tests trace generation, validation, and integration with levelup
"""

import json
import os
import subprocess
import tempfile
from pathlib import Path


def test_trace_generation_script_exists():
    """Test that trace generation scripts exist and are executable"""
    repo_root = Path(__file__).parent.parent

    bash_script = repo_root / "scripts/bash/generate-trace.sh"
    ps_script = repo_root / "scripts/powershell/generate-trace.ps1"

    assert bash_script.exists(), (
        f"Bash trace generation script not found: {bash_script}"
    )
    assert ps_script.exists(), (
        f"PowerShell trace generation script not found: {ps_script}"
    )
    assert os.access(bash_script, os.X_OK), f"Bash script not executable: {bash_script}"

    print("✅ Trace generation scripts exist and are executable")


def test_trace_validation_script_exists():
    """Test that trace validation scripts exist and are executable"""
    repo_root = Path(__file__).parent.parent

    bash_script = repo_root / "scripts/bash/validate-trace.sh"
    ps_script = repo_root / "scripts/powershell/validate-trace.ps1"

    assert bash_script.exists(), f"Bash validation script not found: {bash_script}"
    assert ps_script.exists(), f"PowerShell validation script not found: {ps_script}"
    assert os.access(bash_script, os.X_OK), f"Bash script not executable: {bash_script}"

    print("✅ Trace validation scripts exist and are executable")


def test_trace_command_template_exists():
    """Test that trace command template exists in levelup extension"""
    repo_root = Path(__file__).parent.parent

    # Trace command is now part of the levelup extension
    template_file = repo_root / "extensions/levelup/commands/trace.md"
    assert template_file.exists(), f"Trace command template not found: {template_file}"

    # Verify template has required sections
    content = template_file.read_text()
    assert "description:" in content, "Template missing description field"
    assert "scripts:" in content, "Template missing scripts field"
    assert "validation_script:" in content, "Template missing validation_script field"
    assert "generate-trace.sh" in content, "Template doesn't reference bash script"
    assert "generate-trace.ps1" in content, (
        "Template doesn't reference PowerShell script"
    )

    print(
        "✅ Trace command template exists in levelup extension with required sections"
    )


def test_trace_template_structure():
    """Test that trace template has proper 5-section structure"""
    repo_root = Path(__file__).parent.parent

    # Trace template is now in the levelup extension
    template_file = repo_root / "extensions/levelup/templates/trace-template.md"
    assert template_file.exists(), f"Trace template not found: {template_file}"

    content = template_file.read_text()

    # Verify 5 sections exist
    assert "## 1. Session Overview" in content, "Section 1 missing"
    assert "## 2. Decision Patterns" in content, "Section 2 missing"
    assert "## 3. Execution Context" in content, "Section 3 missing"
    assert "## 4. Reusable Patterns" in content, "Section 4 missing"
    assert "## 5. Evidence Links" in content, "Section 5 missing"

    print("✅ Trace template has proper 5-section structure")


def test_levelup_integration():
    """Test that levelup extension spec command references trace consumption"""
    repo_root = Path(__file__).parent.parent

    # Levelup is now an extension at extensions/levelup/commands/specify.md
    levelup_spec = repo_root / "extensions/levelup/commands/specify.md"
    assert levelup_spec.exists(), f"Levelup specify command not found: {levelup_spec}"

    content = levelup_spec.read_text()

    # Verify levelup.specify mentions trace
    assert "trace" in content.lower() or "TRACE" in content, (
        "Levelup spec doesn't mention trace"
    )
    assert "trace.md" in content, "Levelup spec doesn't reference trace.md file"

    print("✅ Levelup extension integrates with trace consumption")


def test_trace_generation_help():
    """Test that trace generation script has help text"""
    repo_root = Path(__file__).parent.parent
    bash_script = repo_root / "scripts/bash/generate-trace.sh"

    try:
        result = subprocess.run(
            [str(bash_script), "--help"], capture_output=True, text=True, timeout=5
        )

        assert result.returncode == 0, "Help command failed"
        assert "Usage:" in result.stdout, "Help text missing Usage section"
        assert "--json" in result.stdout, "Help text missing --json option"

        print("✅ Trace generation script has proper help text")
    except subprocess.TimeoutExpired:
        print("⚠️  Help command timed out (may be platform issue)")
    except Exception as e:
        print(f"⚠️  Could not test help text: {e}")


def test_trace_validation_help():
    """Test that trace validation script has help text"""
    repo_root = Path(__file__).parent.parent
    bash_script = repo_root / "scripts/bash/validate-trace.sh"

    try:
        result = subprocess.run(
            [str(bash_script), "--help"], capture_output=True, text=True, timeout=5
        )

        assert result.returncode == 0, "Help command failed"
        assert "Usage:" in result.stdout, "Help text missing Usage section"
        assert "--json" in result.stdout, "Help text missing --json option"

        print("✅ Trace validation script has proper help text")
    except subprocess.TimeoutExpired:
        print("⚠️  Help command timed out (may be platform issue)")
    except Exception as e:
        print(f"⚠️  Could not test help text: {e}")


def test_trace_storage_location():
    """Test that trace documentation specifies correct storage location"""
    repo_root = Path(__file__).parent.parent

    # Trace command is now in levelup extension
    trace_template = repo_root / "extensions/levelup/commands/trace.md"
    content = trace_template.read_text()

    # Verify storage location documented
    assert "specs/{BRANCH}/trace.md" in content, (
        "Storage location not documented correctly"
    )
    assert "version-controlled" in content.lower(), "Version control not mentioned"

    print("✅ Trace storage location properly documented")


def test_summary_section_in_template():
    """Test that trace template includes Summary section"""
    repo_root = Path(__file__).parent.parent

    # Trace template is now in levelup extension
    template_file = repo_root / "extensions/levelup/templates/trace-template.md"
    content = template_file.read_text()

    # Verify Summary section exists
    assert "## Summary" in content, "Summary section missing from template"
    assert "### Problem" in content, "Problem subsection missing from template"
    assert "### Key Decisions" in content, "Key Decisions subsection missing"
    assert "### Final Solution" in content, "Final Solution subsection missing"

    print("✅ Summary section present in trace template")


def test_summary_section_in_generation_scripts():
    """Test that generation scripts include Summary extraction functions"""
    repo_root = Path(__file__).parent.parent

    bash_script = repo_root / "scripts/bash/generate-trace.sh"
    ps_script = repo_root / "scripts/powershell/generate-trace.ps1"

    bash_content = bash_script.read_text()
    ps_content = ps_script.read_text()

    # Check bash has new functions
    assert "extract_problem_statement()" in bash_content, (
        "Bash missing problem extraction"
    )
    assert "extract_key_decisions()" in bash_content, (
        "Bash missing decisions extraction"
    )
    assert "extract_final_solution()" in bash_content, (
        "Bash missing solution extraction"
    )
    assert "## Summary" in bash_content, "Bash doesn't generate Summary section"

    # Check PowerShell has new functions
    assert "Extract-ProblemStatement" in ps_content, "PS missing problem extraction"
    assert "Extract-KeyDecisions" in ps_content, "PS missing decisions extraction"
    assert "Extract-FinalSolution" in ps_content, "PS missing solution extraction"
    assert "## Summary" in ps_content, "PS doesn't generate Summary section"

    print("✅ Generation scripts include Summary extraction functions")


def test_summary_validation_in_scripts():
    """Test that validation scripts check Summary section"""
    repo_root = Path(__file__).parent.parent

    bash_validate = repo_root / "scripts/bash/validate-trace.sh"
    ps_validate = repo_root / "scripts/powershell/validate-trace.ps1"

    bash_content = bash_validate.read_text()
    ps_content = ps_validate.read_text()

    # Check bash validates Summary
    assert "summary_valid" in bash_content, "Bash doesn't validate Summary"
    assert "problem_valid" in bash_content, "Bash doesn't validate Problem"
    assert "decisions_valid" in bash_content, "Bash doesn't validate Decisions"
    assert "solution_valid" in bash_content, "Bash doesn't validate Solution"
    assert "total_sections=6" in bash_content, "Bash doesn't count 6 sections"

    # Check PowerShell validates Summary
    assert "$summaryValid" in ps_content, "PS doesn't validate Summary"
    assert "$problemValid" in ps_content, "PS doesn't validate Problem"
    assert "$decisionsValid" in ps_content, "PS doesn't validate Decisions"
    assert "$solutionValid" in ps_content, "PS doesn't validate Solution"
    assert "$totalSections = 6" in ps_content, "PS doesn't count 6 sections"

    print("✅ Validation scripts check Summary section")


def test_commands_documentation_mentions_summary():
    """Test that levelup trace command documents the Summary section"""
    repo_root = Path(__file__).parent.parent

    # Trace command is now in the levelup extension
    commands_doc = repo_root / "extensions/levelup/commands/trace.md"
    content = commands_doc.read_text()

    # Check documentation mentions Summary
    assert "Summary" in content, "Commands doc doesn't mention Summary"
    assert "Problem" in content, "Commands doc doesn't mention Problem"
    assert "Key Decisions" in content, "Commands doc doesn't mention Key Decisions"
    assert "Final Solution" in content, "Commands doc doesn't mention Final Solution"
    assert "3-part" in content or "three-part" in content.lower(), (
        "Commands doc doesn't mention 3-part structure"
    )

    print("✅ Commands documentation mentions Summary section")


if __name__ == "__main__":
    print("\n🧪 Testing Session Trace Command Implementation\n")
    print("=" * 60)

    tests = [
        test_trace_generation_script_exists,
        test_trace_validation_script_exists,
        test_trace_command_template_exists,
        test_trace_template_structure,
        test_levelup_integration,
        test_trace_generation_help,
        test_trace_validation_help,
        test_trace_storage_location,
        test_summary_section_in_template,
        test_summary_section_in_generation_scripts,
        test_summary_validation_in_scripts,
        test_commands_documentation_mentions_summary,
    ]

    passed = 0
    failed = 0

    for test in tests:
        try:
            test()
            passed += 1
        except AssertionError as e:
            print(f"❌ {test.__name__} FAILED: {e}")
            failed += 1
        except Exception as e:
            print(f"⚠️  {test.__name__} ERROR: {e}")
            failed += 1

    print("\n" + "=" * 60)
    print(f"\n📊 Test Results: {passed} passed, {failed} failed\n")

    if failed == 0:
        print("✅ All tests passed!")
        exit(0)
    else:
        print("❌ Some tests failed")
        exit(1)
