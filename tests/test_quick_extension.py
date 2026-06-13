"""Test quick extension assets — command file structure and extension manifest."""

from pathlib import Path

REPO = Path(__file__).parent.parent


def test_levelup_command_file_exists():
    """Test that quick.levelup command file exists."""
    cmd_file = REPO / "extensions/quick/commands/levelup.md"
    assert cmd_file.exists(), f"Command file not found: {cmd_file}"
    print("✅ quick.levelup command file exists")


def test_levelup_file_frontmatter():
    """Test that levelup.md has valid frontmatter fields."""
    content = (REPO / "extensions/quick/commands/levelup.md").read_text(encoding="utf-8")
    assert content.startswith("---"), "Missing YAML frontmatter start"
    assert "description:" in content, "Missing description field"
    assert "mode:" in content, "Missing mode field"
    assert "scripts:" in content, "Missing scripts field"
    print("✅ quick.levelup has valid frontmatter")


def test_levelup_phase_structure():
    """Test that levelup.md has all 6 verifiable phases."""
    content = (REPO / "extensions/quick/commands/levelup.md").read_text(encoding="utf-8")
    assert "Phase 1: Parse" in content, "Missing Phase 1"
    assert "Phase 2: Structure" in content, "Missing Phase 2"
    assert "Phase 3: Signal Gate" in content, "Missing Phase 3"
    assert "Phase 4: User Review" in content, "Missing Phase 4"
    assert "Phase 5: Publish" in content, "Missing Phase 5"
    assert "Phase 6: PR" in content, "Missing Phase 6"
    print("✅ quick.levelup has all 6 phases")


def test_levelup_verification_gates():
    """Test that phases have entry/gate/exit criteria."""
    content = (REPO / "extensions/quick/commands/levelup.md").read_text(encoding="utf-8")
    assert "**Entry**" in content, "Missing entry criteria markers"
    assert "**Gate**" in content or "### Gate" in content, "Missing verification gates"
    assert "**Exit**" in content, "Missing exit criteria markers"
    print("✅ quick.levelup has verifiable gates")


def test_levelup_signal_gate():
    """Test that Signal Gate criteria are documented."""
    content = (REPO / "extensions/quick/commands/levelup.md").read_text(encoding="utf-8")
    assert "Team-wide applicable" in content, "Missing Signal Gate criterion: team-wide"
    assert "High value" in content, "Missing Signal Gate criterion: high value"
    assert "Unique" in content, "Missing Signal Gate criterion: unique"
    assert "Concrete evidence" in content, "Missing Signal Gate criterion: evidence"
    print("✅ quick.levelup has Signal Gate with all 4 criteria")


def test_levelup_cdr_schema():
    """Test that CDR schema fields are present."""
    content = (REPO / "extensions/quick/commands/levelup.md").read_text(encoding="utf-8")
    assert "### Status" in content, "Missing CDR Status field"
    assert "### Context" in content, "Missing CDR Context field"
    assert "### Decision" in content, "Missing CDR Decision field"
    assert "### Evidence" in content, "Missing CDR Evidence field"
    print("✅ quick.levelup has CDR schema fields")


def test_levelup_descriptor_present():
    """Test that Descriptor is generated (matching levelup.implement format)."""
    content = (REPO / "extensions/quick/commands/levelup.md").read_text(encoding="utf-8")
    assert "Descriptor" in content, "Missing Descriptor field"
    assert "when to use" in content.lower(), "Missing Descriptor description"
    assert "search surface" in content, "Missing Descriptor search surface reference"
    print("✅ quick.levelup generates Descriptor")


def test_levelup_conflict_detection():
    """Test that cross-system conflict detection is implemented."""
    content = (REPO / "extensions/quick/commands/levelup.md").read_text(encoding="utf-8")
    assert "Conflict" in content, "Missing conflict detection"
    assert "Duplicate" in content, "Missing duplicate detection"
    print("✅ quick.levelup has conflict detection")


def test_levelup_handoff():
    """Test that command references /levelup.validate handoff."""
    content = (REPO / "extensions/quick/commands/levelup.md").read_text(encoding="utf-8")
    assert "levelup.validate" in content, "Missing handoff to levelup.validate"
    print("✅ quick.levelup has /levelup.validate handoff")


def test_levelup_skill_detection():
    """Test that companion skill detection is implemented."""
    content = (REPO / "extensions/quick/commands/levelup.md").read_text(encoding="utf-8")
    assert "Skill" in content, "Missing skill detection"
    print("✅ quick.levelup has companion skill detection")


def test_levelup_mandatory_stop():
    """Test that Phase 4 is a mandatory stop."""
    content = (REPO / "extensions/quick/commands/levelup.md").read_text(encoding="utf-8")
    assert "Mandatory Stop" in content, "Missing mandatory stop marker"
    assert "STOP HERE" in content, "Missing STOP HERE marker"
    assert "Wait for user input" in content, "Missing user input wait instruction"
    print("✅ quick.levelup has mandatory stop in Phase 4")


def test_extension_manifest_registers_command():
    """Test that extension.yml registers quick.levelup."""
    ext_file = REPO / "extensions/quick/extension.yml"
    content = ext_file.read_text(encoding="utf-8")
    assert "adlc.quick.levelup" in content, "Command not registered in extension.yml"
    assert "quick.levelup" in content, "Alias not registered in extension.yml"
    print("✅ quick.levelup registered in extension.yml")


def test_extension_manifest_handoff():
    """Test that extension.yml has handoff to levelup.validate."""
    ext_file = REPO / "extensions/quick/extension.yml"
    content = ext_file.read_text(encoding="utf-8")
    assert "levelup.validate" in content, "Handoff not registered in extension.yml"
    print("✅ extension.yml has handoff to levelup.validate")


def test_extension_manifest_version_bump():
    """Test that extension version bumped to 1.2.0."""
    ext_file = REPO / "extensions/quick/extension.yml"
    content = ext_file.read_text(encoding="utf-8")
    assert 'version: "1.2.0"' in content, "Extension version not bumped to 1.2.0"
    print("✅ Quick extension version bumped to 1.2.0")


def test_changelog_has_entry():
    """Test that CHANGELOG.md has 1.2.0 entry."""
    changelog = REPO / "extensions/quick/CHANGELOG.md"
    content = changelog.read_text(encoding="utf-8")
    assert "## [1.2.0]" in content, "Missing 1.2.0 changelog entry"
    print("✅ quick CHANGELOG has 1.2.0 entry")


def test_readme_lists_command():
    """Test that README.md commands table includes quick.levelup."""
    readme = REPO / "extensions/quick/README.md"
    content = readme.read_text(encoding="utf-8")
    assert "quick.levelup" in content, "Missing quick.levelup in README commands table"
    print("✅ quick README lists quick.levelup")


if __name__ == "__main__":
    print("\n🧪 Testing Quick Extension Assets\n")
    print("=" * 60)

    tests = [
        test_levelup_command_file_exists,
        test_levelup_file_frontmatter,
        test_levelup_phase_structure,
        test_levelup_verification_gates,
        test_levelup_signal_gate,
        test_levelup_cdr_schema,
        test_levelup_descriptor_present,
        test_levelup_conflict_detection,
        test_levelup_handoff,
        test_levelup_skill_detection,
        test_levelup_mandatory_stop,
        test_extension_manifest_registers_command,
        test_extension_manifest_handoff,
        test_extension_manifest_version_bump,
        test_changelog_has_entry,
        test_readme_lists_command,
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
