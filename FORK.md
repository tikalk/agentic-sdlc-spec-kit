# Fork Maintenance Guide

This document describes how the tikalk fork (`tikalk/agentic-sdlc-spec-kit`) maintains customizations while staying synced with upstream `github/spec-kit`.

## Philosophy

The fork isolates all customizations into a single file (`cli_customization.py`) to minimize merge conflicts. When syncing with upstream:

1. Only the import block in `__init__.py` may conflict
2. All customization logic lives in `cli_customization.py`
3. Upstream changes to other parts of `__init__.py` merge cleanly

## Fork Versioning Scheme

The fork uses a suffix-based versioning system to track both upstream and fork-specific changes:

### Version Format
`<upstream-version>+adlc<N>`

Examples:
- `0.8.2+adlc1` - Fork based on upstream 0.8.2, first fork release
- `0.8.2+adlc2` - Same upstream base, second fork release with new features
- `0.9.0+adlc1` - After upstream merge to 0.9.0, reset fork counter

### When to Bump

| Scenario | Version Change | Example |
|----------|---------------|---------|
| Fork adds new feature | Increment adlc suffix | `0.8.2+adlc1` → `0.8.2+adlc2` |
| Merge upstream release | Update base, reset suffix | `0.8.2+adlc5` → `0.9.0+adlc1` |
| Hotfix/patch | Increment adlc suffix | `0.8.2+adlc1` → `0.8.2+adlc2` |

### Tag Format
Use `agentic-sdlc-v<version>` with plus:
- Version: `0.8.2+adlc2`
- Tag: `agentic-sdlc-v0.8.2+adlc2`

### Version History

| Version | Date | Base Upstream | Changes |
|---------|------|---------------|---------|
| 0.8.12+adlc31 | 2026-05-29 | 0.8.12 | Team AI Directives extension v1.7.6: Renamed {KNOWLEDGE_BASE} to {TEAM_AI_DIRECTIVES} placeholder |
| 0.8.12+adlc26 | 2026-05-28 | 0.8.12 | Architect extension v2.1.1: Hardened DAG orchestration (threshold enforcement, DAG-guarded views, per-view state updates, Accepted-only ADR promotion), AD-template.md link fix |
| 0.8.12+adlc25 | 2026-05-28 | 0.8.12 | Hook execution hardening in all preset command files: pre-execution hooks moved to absolute top, compact imperative format, post-execution hooks extracted and standardized |
| 0.8.12+adlc24 | 2026-05-28 | 0.8.12 | Reference extension auto-update: specify extension update detects and applies updates for source: reference extensions with rollback support |
| 0.8.12+adlc23 | 2026-05-28 | 0.8.12 | Windows test failures: Replaced f-string JSON construction with json.dumps() to properly escape Windows paths |
| 0.8.12+adlc22 | 2026-05-28 | 0.8.12 | PresetResolver reference extension path resolution: resolve_extension_dir() for reference extensions living outside .specify/extensions/ |
| 0.8.12+adlc21 | 2026-05-28 | 0.8.12 | Reference extension support: full support for extensions registered with source: reference and a top-level path across CLI commands and config loading |
| 0.8.12+adlc20 | 2026-05-26 | 0.8.12 | Fix extension download URL {{VERSION}} placeholder substitution in download_extension method |
| 0.8.12+adlc19 | 2026-05-23 | 0.8.12 | LevelUp extension v1.6.1: Fix redundant ID generation, CDR ref preservation, AGENTS.md grep pattern, validate-directives.sh jq error |
| 0.8.12+adlc18 | 2026-05-23 | 0.8.12 | Fix team-ai-directives reference mode registration in extension registry |
| 0.8.12+adlc17 | 2026-05-22 | 0.8.12 | LevelUp extension v1.6.0: Repair command for CDR.md, .skills.json, and AGENTS.md reindexing |
| 0.8.12+adlc16 | 2026-05-20 | 0.8.12 | Architect extension v2.1.0: Technology neutrality in Functional View, Functional-Development view parity, analyze Pass E.6/E.7 |
| 0.8.12+adlc14 | 2026-05-19 | 0.8.12 | Product extension v1.5.6: In-section diagrams, remove Visual Summary, sections renumbered 1-12, delete visual templates, no .specify/product/visuals/ |
| 0.8.12+adlc13 | 2026-05-19 | 0.8.12 | Product extension v1.5.5: PDR lifecycle enforcement - mandatory memory promotion, state schema lifecycle fields, 9-check final gate |
| 0.8.12+adlc12 | 2026-05-19 | 0.8.12 | Product extension v1.5.4: Fix self-contained PRD enforcement - Step 3.3 structure, embedding rules, prd-template .specify/ references |
| 0.8.12+adlc11 | 2026-05-19 | 0.8.12 | Product extension v1.5.3: Business stakeholder sections (Executive Summary, Market Opportunity, Investment, GTM), self-contained PRD generation, enhanced validation |
| 0.8.12+adlc10 | 2026-05-19 | 0.8.12 | Product extension v1.5.2: Hardened implement command with compliance checklist, validation scripts, strict template enforcement, ASCII→Mermaid conversion |
| 0.8.12+adlc9 | 2026-05-19 | 0.8.12 | Product extension v1.5.1: Mermaid v10 syntax fixes, new diagram types (architecture, journey, gantt), mandatory visual generation |
| 0.8.12+adlc4 | 2026-05-17 | 0.8.12 | CLI bundled extension update support: specify extension update now checks CLI wheel for bundled extension updates |
| 0.8.12+adlc3 | 2026-05-17 | 0.8.12 | Architect extension v2.0.8 hardening: clarify→implement workflow enforcement, placeholder validation, --force flag |
| 0.8.12+adlc2 | 2026-05-16 | 0.8.12 | Architect extension comprehensive hardening: Phase execution enforcement, view file generation, sub-system detection with mandatory interactive proposal |
| 0.8.12+adlc1 | 2026-05-15 | 0.8.12 | Git extension enhancements (workspace command with force flag, setup-ignore command) |

## Customization Module

**File**: `src/specify_cli/cli_customization.py`

This module provides:

| Feature | Upstream Default | Fork Override |
|---------|------------------|---------------|
| ACCENT_COLOR | "cyan" | "#f47721" (tikalk orange) |
| BANNER_COLORS | cyan gradient | orange gradient |
| accent() | N/A | Helper function for theming |
| accent_style() | N/A | Helper for Rich style= params |
| PKG_NAMES | ("specify-cli",) | ("agentic-sdlc-specify-cli", "specify-cli") |
| TEAM_DIRECTIVES_DIRNAME | N/A | "team-ai-directives" |
| EXTENSION_NAMESPACES | ["speckit"] | ["speckit", "adlc"] |
| EXTENSION_ALIAS_PATTERN_ENABLED | False | True |

## Import Block

The `__init__.py` file starts with this import block that you should preserve during merges:

```python
# Tikalk fork customizations - import with fallback to upstream defaults
try:
    from .cli_customization import (
        ACCENT_COLOR,
        BANNER_COLORS,
        TAGLINE,
        accent,
        accent_style,
        TEAM_DIRECTIVES_DIRNAME,
        PKG_NAMES,
        pre_init,
        post_init,
        compute_skill_output_name,
    )
except ImportError:
    ACCENT_COLOR = "cyan"
    BANNER_COLORS = ["#00ffff", "#00cccc", "cyan", "#009999", "white", "bright_white"]
    TEAM_DIRECTIVES_DIRNAME = "team-ai-directives"
    PKG_NAMES = ["specify-cli"]

    def accent(
        text: str, bold: bool = False, italic: bool = False, dim: bool = False
    ) -> str:
        style = ACCENT_COLOR
        if bold:
            style = f"bold {style}"
        if italic:
            style = f"italic {style}"
        if dim:
            style = f"dim {style}"
        return f"[{style}]{text}[/]"

    def accent_style() -> str:
        return ACCENT_COLOR

    def pre_init(project_path, selected_ai, team_ai_directives, tracker=None):
        pass

    def post_init(project_path, selected_ai, tracker=None, no_git=False):
        pass

    def compute_skill_output_name():
        return None
```

**Critical**: This block must include ALL fork customizations with fallbacks, not just partial imports. The import block is the SINGLE SOURCE OF TRUTH for fork customizations - all theming, hooks (pre_init, post_init), and helper functions must be defined here.

## Extension Namespace Configuration

In `extensions.py`, the fork configures command name patterns:

```python
# Get namespaces from customization module (supports speckit and adlc)
try:
    from .cli_customization import EXTENSION_NAMESPACES, EXTENSION_ALIAS_PATTERN_ENABLED
except ImportError:
    EXTENSION_NAMESPACES = ["speckit"]
    EXTENSION_ALIAS_PATTERN_ENABLED = False

EXTENSION_COMMAND_NAME_PATTERN = re.compile(
    rf"^(?:{'|' . join(EXTENSION_NAMESPACES)})\.([a-z0-9-]+)\.([a-z0-9-]+)$"
)

if EXTENSION_ALIAS_PATTERN_ENABLED:
    EXTENSION_ALIAS_NAME_PATTERN = re.compile(r"^([a-z0-9-]+)\.([a-z0-9-]+)$")
else:
    EXTENSION_ALIAS_NAME_PATTERN = None
```

## Merging Upstream

This section documents the complete workflow for merging upstream changes from `github/spec-kit`.

### Pre-Merge: Check for New Upstream Commits

```bash
# Fetch latest upstream changes
git fetch upstream

# Check what commits are new in upstream (not in origin)
git log origin/main --not upstream/main
git log upstream/main --not origin/main
```

### Complete Merge Workflow

#### Step 1: Create Backup Branch

```bash
git checkout main
git branch backup-before-upstream-merge-$(date +%Y%m%d)
```

#### Step 2: Fetch and Merge

```bash
git fetch upstream
git merge upstream/main
```

#### Step 3: Resolve Conflicts

**CRITICAL: Never use `git checkout --theirs` for __init__.py or pyproject.toml**

**Correct Strategy**: Use upstream as clean base, then ADD fork customizations on top.

##### New Upstream Module Structure (v0.8.9+)

Upstream has extracted code from `__init__.py` into separate modules:

| Module | Contents | Fork Action |
|--------|----------|-------------|
| `_console.py` | BANNER, TAGLINE, StepTracker, console | Keep upstream, fork theming overrides in `show_banner()` |
| `_version.py` | Version checking, self-update | Override GITHUB_API_LATEST via cli_customization |
| `_assets.py` | Bundled asset location | Accept as-is |
| `_utils.py` | Utility functions | Accept as-is |
| `catalogs.py` | Catalog config loading | Accept as-is |
| `integration_state.py` | Integration state management | Accept as-is |

##### __init__.py Resolution

1. Keep upstream imports from extracted modules (`_console`, `_assets`, `_utils`, `_version`)
2. Keep fork's cli_customization import block AFTER upstream imports
3. Keep fork's custom functions that depend on cli_customization:
   - `show_banner()` (overrides upstream to apply theming)
   - `TEAM_DIRECTIVES_DIRNAME` (from cli_customization)
   - `sync_team_ai_directives()` (imported from cli_customization)
   - `get_team_directives_path()` (imported from cli_customization)

##### pyproject.toml Resolution

NEVER use `--theirs`. Manually edit to preserve fork values:
- `name = "agentic-sdlc-specify-cli"`
- `version = "0.8.X+adlcN"` (fork version)
- `description` (fork description)
- Wheel paths: keep bundled extensions/presets paths
- Keep `httpx>=0.27.0` dependency

##### Test Files Resolution

See [Test Merge Strategy](#test-merge-strategy) section. Do NOT use `git checkout --theirs tests/`.

**Why this works**:
- Upstream refactoring isolates code into stable modules
- Fork customizations stay in cli_customization.py and import block
- Clear separation of concerns reduces future conflicts
- pyproject.toml needs manual edit to preserve fork version (never use --theirs)

#### Step 4: Verify

```bash
python3 -m pytest tests/ -v
```

#### Step 5: Bump Version

Update `pyproject.toml`:
```toml
version = "0.3.X"  # Increment from current version
```

#### Step 6: Update CHANGELOG

Add new entry at top of changelog (after ## [Unreleased] or before latest release):

```markdown
## [0.3.X] - YYYY-MM-DD

### Changed

- **Upstream merge**: Synced with github/spec-kit
  - [List upstream commits merged]
```

#### Step 7: Commit and Push

```bash
git add -A
git commit -m "chore: merge upstream and bump to v0.3.X"
git push origin main
```

#### Step 8: Create Tag

```bash
git tag -a agentic-sdlc-v0.3.X -m "Release agentic-sdlc-v0.3.X"
git push origin agentic-sdlc-v0.3.X
```

### Conflict Resolution Strategy

When conflicts occur during merge:

1. **Keep origin changes as base** - Our customizations in `cli_customization.py` and fork-specific features must be preserved
2. **Adapt upstream changes** - Integrate upstream improvements to work with our customizations
3. **Test after resolving** - Always run tests before committing

### Common Conflict Points

| File | Why It Conflicts | Resolution |
|------|-----------------|------------|
| `__init__.py` | Import block at top | Use our try/except import pattern with fallback |
| `pyproject.toml` | Version number | Increment version after merge |
| `CHANGELOG.md` | New entries | Add fork-specific entries, preserve upstream section |

### What NOT to Change During Merge

These fork customizations should NEVER be modified unless intentionally updating them:

- `cli_customization.py` - All theming and customization constants
- `extensions.py` - Extension namespace configuration
- Bundled extensions in `pyproject.toml` - levelup, architect, quick, product, tdd
- Bundled presets in `pyproject.toml` - agentic-sdlc

## What Stays in cli_customization.py

The following customization categories must stay in `cli_customization.py`:

1. **Theming**: ACCENT_COLOR, BANNER_COLORS, accent(), accent_style()
2. **Package Identity**: PKG_NAMES for version detection
3. **Team Directives**: TEAM_DIRECTIVES_DIRNAME
4. **Extension Namespaces**: EXTENSION_NAMESPACES, EXTENSION_ALIAS_PATTERN_ENABLED

## What Can Stay in __init__.py

The following tikalk-specific features are implemented directly in `__init__.py` because they require access to internal functions:

1. `install_bundled_extensions()` - Installs bundled extensions during init
2. `install_bundled_presets()` - Installs bundled presets during init
3. `get_preinstalled_extensions()` - Returns list of pre-installed extensions
4. `sync_team_ai_directives()` - Syncs team-ai-directives repository

These functions are called during init but don't conflict with upstream because they use conditional checks (e.g., `if skip_bundled:`).

## Fork-Only Files and Directories

The following files and directories exist **only in the fork** and were never present in upstream. During merges, git will show these as "deleted by them" — always reject the deletion.

### `src/specify_cli/cli_customization.py` — Fork Customization Module

**File**: `src/specify_cli/cli_customization.py`

The central customization module providing theming, team directives, and fork-specific features. This is the single source of truth for fork identity.

**Key exports**:
- Theming: `ACCENT_COLOR`, `BANNER_COLORS`, `accent()`, `accent_style()`
- Package Identity: `PKG_NAMES`
- Team Directives: `TEAM_DIRECTIVES_DIRNAME`, `sync_team_ai_directives()`
- Extension Namespaces: `EXTENSION_NAMESPACES`, `EXTENSION_ALIAS_PATTERN_ENABLED`

**Total**: ~1700 lines of fork-only code

### Test Files

The following test files are fork-only:
- `tests/test_fork_inventory.py` — Fork inventory tests
- `tests/integrations/test_fork_inventory.py` — Integration inventory tests
- `tests/test_bundled_extension_hooks.py` — Bundled extension hook tests
- `tests/test_check_prerequisites_risks.py` — Prerequisite risk tests
- `tests/test_create_new_feature.py` — Feature creation tests
- `tests/auth_helpers.py` — Authentication test helpers
- `tests/test_team_directives.py` — Team AI directives tests

## Testing

Run tests to verify customization module works correctly:

```bash
python3 -c "
from src.specify_cli import ACCENT_COLOR, BANNER_COLORS, accent, accent_style
from src.specify_cli.extensions import EXTENSION_COMMAND_NAME_PATTERN

print('ACCENT_COLOR:', ACCENT_COLOR)
print('accent test:', accent('Test', bold=True))
print('Extension pattern:', EXTENSION_COMMAND_NAME_PATTERN.pattern)
"
```

Expected output:
```
ACCENT_COLOR: #f47721
accent test: [bold #f47721]Test[/]
Extension pattern: ^(?:speckit|adlc)\.([a-z0-9-]+)\.([a-z0-9-]+)$
```

## Tag Management

**IMPORTANT**: The fork uses the tag pattern `agentic-sdlc-v*` to distinguish from upstream `v*` tags.

### Why This Matters

Upstream uses tags like `v0.5.0`, `v0.5.1`, etc. These tags from origin trigger GitHub Actions workflows designed for upstream, which causes confusion and wasted CI runs.

### Tag Naming Convention

- **Fork tags**: `agentic-sdlc-v0.3.11` (our releases)
- **Upstream tags**: `v0.5.0` (from upstream/main, don't push these to origin)

### Before Pushing Tags

Always check before pushing to avoid triggering upstream workflows:

```bash
# Check what tags you're about to push
git push origin --dry-run --tags

# List only fork-pattern tags
git tag -l "agentic-sdlc-*"
```

### Removing Stray Tags

If upstream tags get pushed to origin by mistake, remove them:

```bash
# Local cleanup
git tag -l "v*" | xargs -I {} git tag -d {}

# Remote cleanup (example for v0.5.0)
git push origin --delete v0.5.0
```

Or delete multiple at once:
```bash
git push origin --delete v0.0.1 v0.1.0 v0.2.0 v0.5.0
```

## Test Merge Strategy

Tests should be **manually merged** (NOT `git checkout --theirs tests/`):

1. **Accept upstream test refactoring** for new extracted modules (`test_console_imports.py`, `test_version_imports.py`, `test_utils_assets_imports.py`)
2. **Keep fork-only test files** that upstream shows as "deleted" (they were never upstream):
   - `tests/test_fork_inventory.py`
   - `tests/integrations/test_fork_inventory.py`
   - `tests/test_bundled_extension_hooks.py`
   - `tests/test_check_prerequisites_risks.py`
   - `tests/test_create_new_feature.py`
   - `tests/auth_helpers.py`
   - `tests/test_team_directives.py`
3. **Merge and re-apply** `PKG_NAMES` skip guards to upstream tests that expect upstream-only behavior
4. **New fork tests are additive** — they should not conflict with upstream tests

### Skip Guard Pattern

```python
def test_complete_file_inventory_sh(self, tmp_path):
    """Every file produced by specify init --integration <key> --script sh."""
    from specify_cli import PKG_NAMES
    if any("agentic-sdlc" in pkg for pkg in PKG_NAMES):
        import pytest
        pytest.skip("Fork has bundled extensions/presets with different file counts")
    # ... rest of test
```

## _version.py Override

Upstream `_version.py` hardcodes GitHub API URLs pointing to `github/spec-kit`:

```python
GITHUB_API_LATEST = "https://api.github.com/repos/github/spec-kit/releases/latest"
```

The fork should override these via `cli_customization.py`:
- `GITHUB_API_LATEST` → point to `tikalk/agentic-sdlc-spec-kit` releases
- Install instructions → reference fork's repo URL

## CI Troubleshooting

This section documents common CI failures and how to debug them.

### Common Issues

#### 1. Unresolved Merge Conflict Markers

**Symptom**: ruff fails with `invalid-syntax: Expected ,, found <<`

**Example error**:
```
invalid-syntax: Expected `,`, found `<<`
    --> src/specify_cli/__init__.py:1064:1
     |
1064 | <<<<<<< HEAD
     | ^^
```

**Cause**: Merge conflict not fully resolved - `<<<<<<< HEAD` markers remain in code

**Fix**:
```bash
# Find remaining conflict markers
grep -rn "<<<<<< HEAD" src/

# Fix in editor (remove the marker line)
# Verify fix
uvx ruff check src/

# Commit and push
git add -A
git commit -m "fix: remove unresolved merge conflict marker"
git push origin main
```

**Prevention**: Always run `uvx ruff check src/` locally before pushing

#### 2. Test Failures After Merge

**Symptom**: pytest fails after upstream merge

**Fix**:
```bash
# Run tests locally
uv run pytest

# If tests fail, investigate and fix
# Then commit and push
```

#### 3. Python Version Compatibility

**Symptom**: Tests fail on specific Python versions in CI matrix

**Fix**: Ensure code is compatible with Python 3.11, 3.12, and 3.13

### Debugging CI Failures

1. **Check the workflow run**: Look at the GitHub Actions logs for the specific error
2. **Reproduce locally**: Run the same commands locally:
   ```bash
   uvx ruff check src/
   uv run pytest
   ```
3. **Check for conflicts**: `grep -rn "<<<<<<" src/`
4. **Review recent changes**: `git log --oneline -10`

## Lessons Learned from Upstream Merge

This section documents hard-won lessons from merging upstream changes.

### Critical Rules

1. **NEVER use `git checkout --theirs` for pyproject.toml or __init__.py**
   - Using `--theirs` on pyproject.toml discards the fork version entirely
   - The stash with fork changes gets lost
   - Always manually edit to preserve fork values after merge

2. **Use upstream as clean base, then ADD fork customizations**
   - Merge upstream/main cleanly first
   - Then manually add fork-specific functions/values AFTER merge
   - This prevents accidental overwriting

3. **The import block is the SINGLE SOURCE OF TRUTH**
   - All fork customizations must be in the try/except import block
   - Both the imports AND the fallback functions must be complete
   - Missing fallbacks = runtime errors when cli_customization.py is not available

### pyproject.toml Wheel Paths

The fork uses `specify_cli/core_pack/...` paths (NOT root-level directories):

```toml
[tool.hatch.build.targets.wheel.force-include]
# Tikalk bundled extensions
"extensions/levelup" = "specify_cli/core_pack/extensions/levelup"
"extensions/evals" = "specify_cli/core_pack/extensions/evals"
"extensions/architect" = "specify_cli/core_pack/extensions/architect"
"extensions/quick" = "specify_cli/core_pack/extensions/quick"
"extensions/product" = "specify_cli/core_pack/extensions/product"
"extensions/tdd" = "specify_cli/core_pack/extensions/tdd"  # Don't forget!
# Tikalk bundled presets
"presets/agentic-sdlc" = "specify_cli/bundled_presets/agentic-sdlc"
# Core pack assets
"templates/agent-file-template.md" = "specify_cli/core_pack/templates/agent-file-template.md"
# ... etc
```

**Common mistake**: Using root-level paths like `"extensions/levelup" = "extensions/levelup"` will cause build errors because those paths don't exist inside the wheel.

### __init__.py Required Customizations

After merging upstream, ensure these are present in __init__.py:

1. **Full import block** (see above) - with ALL imports and fallbacks
2. **TEAM_DIRECTIVES_DIRNAME** - for team-ai-directives feature
3. **_run_git_command()** - helper for git operations
4. **sync_team_ai_directives()** - clones/updates team repo
5. **compute_skill_output_name()** - delegates to cli_customization
6. **TAGLINE** - fork's tagline (different from upstream)

### __init__.py Theming

Apply theming to all UI elements using `accent_style()` and `accent()`:

- `show_banner()`: Use `BANNER_COLORS` and `accent_style()` for tagline
- StepTracker title: `f"[{accent_style()}]{self.title}"`
- "Selected AI assistant:" and "Selected script type:": Use `accent()`
- "Project ready.": Use `accent(bold=True)`
- All Panel borders: Use `border_style=accent_style()`
- Next Steps and Enhancement Commands panels

### Tracker Steps

The init flow must include these steps in order:

```python
for key, label in [
    ("chmod", "Ensure scripts executable"),
    ("constitution", "Constitution setup"),
    ("git", "Install git extension"),
    ("workflow", "Install bundled workflow"),
    ("team-directives", "Team AI Directives setup"),
    ("extensions", "Install bundled extensions"),
    ("presets", "Install bundled presets"),
]:
    tracker.add(key, label)

# Final MUST be added LAST
tracker.add("final", "Finalize")
```

### Command Prefix

The fork uses `/spec.*` prefix instead of upstream's `/speckit.*`:

```python
def _display_cmd(name: str) -> str:
    # ... agent-specific cases ...
    # Fork default: use "spec." prefix instead of "speckit."
    return f"/spec.{name}"
```

### Backup Before Merge

Always create a backup branch BEFORE merging:

```bash
git branch backup-before-upstream-merge-$(date +%Y%m%d-%H%M%S)
```

This allows you to:
- Compare against backup to see exactly what changed
- Restore any accidentally lost customizations
- Debug issues by comparing working vs broken state

### Integration Test File Inventory Tests

The fork bundles extensions, presets, and skills that aren't present in upstream. This causes the `test_complete_file_inventory_*` tests to fail because they expect upstream's file count.

**Solution**: Skip these tests on the fork by checking `PKG_NAMES`:

```python
def test_complete_file_inventory_sh(self, tmp_path):
    """Every file produced by specify init --integration <key> --script sh."""
    from specify_cli import PKG_NAMES
    if any("agentic-sdlc" in pkg for pkg in PKG_NAMES):
        import pytest
        pytest.skip("Fork has bundled extensions/presets with different file counts")
    # ... rest of test
```

This check exists in:
- `tests/integrations/test_integration_base_markdown.py`
- `tests/integrations/test_integration_base_skills.py`

The tests pass upstream (no skip) and skip on the fork (with skip), ensuring CI passes in both environments.