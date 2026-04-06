# Fork Maintenance Guide

This document describes how the tikalk fork (`tikalk/agentic-sdlc-spec-kit`) maintains customizations while staying synced with upstream `github/spec-kit`.

## Philosophy

The fork isolates all customizations into a single file (`cli_customization.py`) to minimize merge conflicts. When syncing with upstream:

1. Only the import block in `__init__.py` may conflict
2. All customization logic lives in `cli_customization.py`
3. Upstream changes to other parts of `__init__.py` merge cleanly

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
        accent,
        accent_style,
        TEAM_DIRECTIVES_DIRNAME,
        PKG_NAMES,
    )
except ImportError:
    # Fallback to upstream defaults if cli_customization.py doesn't exist
    ACCENT_COLOR = "cyan"
    BANNER_COLORS = ["#00ffff", "#00cccc", "cyan", "#009999", "white", "bright_white"]

    def accent(text: str, bold: bool = False, italic: bool = False, dim: bool = False) -> str:
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

    TEAM_DIRECTIVES_DIRNAME = "team-ai-directives"
    PKG_NAMES = ("specify-cli",)
```

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

**Strategy**: Keep origin (fork) changes as base, adapt upstream changes to work with them.

If there are conflicts in `__init__.py`, resolve the import block to use our pattern:

```python
# Tikalk fork customizations - import with fallback to upstream defaults
try:
    from .cli_customization import (
        ACCENT_COLOR,
        BANNER_COLORS,
        accent,
        accent_style,
        TEAM_DIRECTIVES_DIRNAME,
        PKG_NAMES,
    )
except ImportError:
    # Fallback to upstream defaults if cli_customization.py doesn't exist
    ACCENT_COLOR = "cyan"
    BANNER_COLORS = ["#00ffff", "#00cccc", "cyan", "#009999", "white", "bright_white"]

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
```

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