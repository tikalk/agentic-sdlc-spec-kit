"""Test agentic-quick preset assets — command file structure and preset manifest."""

from pathlib import Path

REPO = Path(__file__).parent.parent
PRESET = REPO / "presets/agentic-quick"
LEVELUP = PRESET / "commands/adlc.quick.levelup.md"
MANIFEST = PRESET / "preset.yml"
CHANGELOG = REPO / "CHANGELOG.md"
README = REPO / "README.md"


def test_levelup_command_file_exists():
    """Test that quick.levelup command file exists."""
    assert LEVELUP.exists(), f"Command file not found: {LEVELUP}"
    print("[\u2705 quick.levelup command file exists")


def test_levelup_file_frontmatter():
    """Test that levelup.md has valid frontmatter fields."""
    content = LEVELUP.read_text(encoding="utf-8")
    assert content.startswith("---"), "Missing YAML frontmatter start"
    assert "description:" in content, "Missing description field"
    assert "mode:" in content, "Missing mode field"
    assert "scripts:" in content, "Missing scripts field"
    print("[\u2705 quick.levelup has valid frontmatter")


def test_levelup_phase_structure():
    """Test that levelup.md has all 6 verifiable phases."""
    content = LEVELUP.read_text(encoding="utf-8")
    assert "Phase 1: Parse" in content, "Missing Phase 1"
    assert "Phase 2: Structure" in content, "Missing Phase 2"
    assert "Phase 3: Signal Gate" in content, "Missing Phase 3"
    assert "Phase 4: User Review" in content, "Missing Phase 4"
    assert "Phase 5: Publish" in content, "Missing Phase 5"
    assert "Phase 6: PR" in content, "Missing Phase 6"
    print("[\u2705 quick.levelup has all 6 phases")


def test_levelup_verification_gates():
    """Test that phases have entry/gate/exit criteria."""
    content = LEVELUP.read_text(encoding="utf-8")
    assert "**Entry**" in content, "Missing entry criteria markers"
    assert "**Gate**" in content or "### Gate" in content, "Missing verification gates"
    assert "**Exit**" in content, "Missing exit criteria markers"
    print("[\u2705 quick.levelup has verifiable gates")


def test_levelup_signal_gate():
    """Test that Signal Gate criteria are documented."""
    content = LEVELUP.read_text(encoding="utf-8")
    assert "Team-wide applicable" in content, "Missing Signal Gate criterion: team-wide"
    assert "High value" in content, "Missing Signal Gate criterion: high value"
    assert "Unique" in content, "Missing Signal Gate criterion: unique"
    assert "Concrete evidence" in content, "Missing Signal Gate criterion: evidence"
    print("[\u2705 quick.levelup has Signal Gate with all 4 criteria")


def test_levelup_cdr_schema():
    """Test that CDR schema fields are present."""
    content = LEVELUP.read_text(encoding="utf-8")
    assert "### Status" in content, "Missing CDR Status field"
    assert "### Context" in content, "Missing CDR Context field"
    assert "### Decision" in content, "Missing CDR Decision field"
    assert "### Evidence" in content, "Missing CDR Evidence field"
    print("[\u2705 quick.levelup has CDR schema fields")


def test_levelup_descriptor_present():
    """Test that Descriptor is generated (matching levelup format)."""
    content = LEVELUP.read_text(encoding="utf-8")
    assert "Descriptor" in content, "Missing Descriptor field"
    assert "when to use" in content.lower(), "Missing Descriptor description"
    assert "search surface" in content, "Missing Descriptor search surface reference"
    print("[\u2705 quick.levelup generates Descriptor")


def test_levelup_conflict_detection():
    """Test that cross-system conflict detection is implemented."""
    content = LEVELUP.read_text(encoding="utf-8")
    assert "Conflict" in content, "Missing conflict detection"
    assert "Duplicate" in content, "Missing duplicate detection"
    print("[\u2705 quick.levelup has conflict detection")


def test_levelup_handoff():
    """Test that command references /levelup.validate handoff."""
    content = LEVELUP.read_text(encoding="utf-8")
    assert "levelup.validate" in content, "Missing handoff to levelup.validate"
    print("[\u2705 quick.levelup has /levelup.validate handoff")


def test_levelup_skill_detection():
    """Test that companion skill detection is implemented."""
    content = LEVELUP.read_text(encoding="utf-8")
    assert "Skill" in content, "Missing skill detection"
    print("[\u2705 quick.levelup has companion skill detection")


def test_levelup_mandatory_stop():
    """Test that Phase 4 is a mandatory stop."""
    content = LEVELUP.read_text(encoding="utf-8")
    assert "Mandatory Stop" in content, "Missing mandatory stop marker"
    assert "STOP HERE" in content, "Missing STOP HERE marker"
    assert "Wait for user input" in content, "Missing user input wait instruction"
    print("[\u2705 quick.levelup has mandatory stop in Phase 4")


def test_preset_manifest_registers_command():
    """Test that preset.yml registers adlc.quick.levelup."""
    content = MANIFEST.read_text(encoding="utf-8")
    assert "adlc.quick.levelup" in content, "Command not registered in preset.yml"
    assert "quick.levelup" in content, "Alias not registered in preset.yml"
    print("[\u2705 quick.levelup registered in preset.yml")


def test_preset_manifest_has_version():
    """Test that preset.yml has version."""
    content = MANIFEST.read_text(encoding="utf-8")
    assert 'version: "1.2.2"' in content, "Version not set in preset.yml"
    print("[\u2705 quick preset version is 1.2.2")


def test_changelog_has_entry():
    """Test that CHANGELOG.md has adlc29 entry."""
    content = CHANGELOG.read_text(encoding="utf-8")
    assert "adlc29" in content, "Missing adlc29 changelog entry"
    print("[\u2705 CHANGELOG has adlc29 entry")


def test_readme_lists_command():
    """Test that README.md commands table includes quick.levelup."""
    content = README.read_text(encoding="utf-8")
    assert "quick.levelup" in content, "Missing quick.levelup in README commands table"
    print("[\u2705 README lists quick.levelup")
