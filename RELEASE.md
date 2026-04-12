# Release Process

## Semantic Versioning Guide

| Version Component | When to Bump | Example |
|-------------------|--------------|---------|
| **MAJOR (X.**y.z) | Breaking changes, incompatible API changes | `0.3.32` → `1.0.0` |
| **MINOR** (x.**Y**.z) | New features, backwards compatible | `0.3.32` → `0.4.0` |
| **PATCH** (x.y.**Z**) | Bug fixes, backwards compatible | `0.3.32` → `0.3.33` |

### Decision Tree
- Bug fix only → **PATCH**
- New feature added → **MINOR**
- Breaking change → **MAJOR**
- Mix of bug fix + minor feature → **MINOR**

## Pre-release Checklist

- [ ] All tests pass: `pytest` or `make test`
- [ ] Linting passes: `ruff check .` or `make lint`
- [ ] Type checking: `mypy` or `make typecheck`
- [ ] CHANGELOG.md updated with changes
- [ ] Extension CHANGELOGs updated (if extensions changed)
- [ ] Extension versions bumped in `extension.yml` files (if extensions changed)
- [ ] `pyproject.toml` version bumped
- [ ] Documentation updated (if API changed)

### Path Consistency Validation

Before releasing, verify path consistency across:

- [ ] `scripts/bash/common.sh` - `memory_dir` uses `.specify/memory/` (not `memory/`)
- [ ] All template paths use `{REPO_ROOT}` placeholder (not hardcoded `.specify/`)
- [ ] Extension templates reference correct paths
- [ ] Validation scripts point to correct constitution path

**Common bug**: `common.sh` line 318 uses `$repo_root/memory` but should use `$repo_root/.specify/memory`

## Version Bump Logic

### Step 1: Check Current State
```bash
# Check latest tags
git tag | grep "^agentic-sdlc-v" | sort -V | tail -3

# Check current version in pyproject.toml
cat pyproject.toml | grep "^version"
```

### Step 2: Update Version
Edit `pyproject.toml`:
```toml
[project]
version = "X.Y.Z"
```

### Step 3: Commit Prefix Guide
| Change Type | Prefix | Example |
|-------------|--------|---------|
| Bug fix | `fix:` | `fix: resolve constitution path` |
| New feature | `feat:` | `feat: add handoffs to init` |
| Maintenance | `chore:` | `chore: bump version to 0.3.33` |
| Documentation | `docs:` | `docs: update README` |
| Breaking change | `BREAKING:` | `BREAKING: change CLI interface` |

### Step 4: Commit & Tag
```bash
# Stage all changes
git add -A

# Commit with appropriate prefix
git commit -m "<prefix>: <description>"

# Create tag
git tag agentic-sdlc-vX.Y.Z

# Push to remote
git push origin main
git push origin agentic-sdlc-vX.Y.Z
```

### Step 5: Re-tagging (if version file was missed)
```bash
# Delete old tag locally and remotely
git tag -d agentic-sdlc-vX.Y.Z
git push origin :refs/tags/agentic-sdlc-vX.Y.Z

# Re-tag at correct commit (with updated pyproject.toml)
git tag agentic-sdlc-vX.Y.Z
git push origin agentic-sdlc-vX.Y.Z
```

### Step 6: Verify Installation
```bash
# Install from git to verify
cd /tmp
rm -rf test-install
mkdir test-install
cd test-install
uv tool install agentic-sdlc-specify-cli --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git

# Check installed version
which specify
specify --version
```

### Critical: Version File Must Be Updated BEFORE Tagging

The tag must point to a commit where `pyproject.toml` has the correct version.

**Verification sequence:**
```bash
# 1. Update version
sed -i 's/version = "0.3.33"/version = "0.3.34"/' pyproject.toml

# 2. Stage and commit
git add pyproject.toml  # Stage version file with other changes
git commit -m "fix: description"

# 3. Verify commit has correct version
git show HEAD:pyproject.toml | grep "^version"

# 4. Only then create tag
git tag agentic-sdlc-v0.3.34
```

**If you tagged before updating version:**
```bash
# Move tag to correct commit
git tag -d agentic-sdlc-vX.Y.Z
git push origin :refs/tags/agentic-sdlc-vX.Y.Z
git tag agentic-sdlc-vX.Y.Z
git push origin agentic-sdlc-vX.Y.Z
```

## Extension Version Management

When extensions change, update their individual versions:

1. Edit `extensions/{name}/extension.yml`:
```yaml
extension:
  version: "X.Y.Z"
```

2. Update `extensions/{name}/CHANGELOG.md`:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Fixed/Added/Changed
- Description of change
```

3. Commit with extension-specific message:
```bash
git commit -m "fix(architect): resolve template path resolution"
```

## Change Scope Detection

Before versioning, check for changes in:

| Location | Files to Check | Version Impact |
|----------|---------------|----------------|
| Main CLI | `pyproject.toml`, `src/` | Bump main version |
| Extensions | `extensions/*/extension.yml`, `CHANGELOG.md` | Bump extension versions |
| Presets | `presets/*/commands/*.md` | May need main version bump |
| Core Scripts | `scripts/bash/common.sh` | Usually PATCH bump |

**Command to check all changes:**
```bash
git status
git diff --stat
```

## Common Mistakes

1. ❌ **Tagging before updating `pyproject.toml`**
   - Tag must point to commit with correct version
   
2. ❌ **Forgetting to push the tag**
   - `git push origin agentic-sdlc-vX.Y.Z`
   
3. ❌ **Wrong commit prefix**
   - Use `fix:`, `feat:`, `chore:`, `docs:`, `BREAKING:`
   
4. ❌ **Not running tests before release**
   - Always run test suite first
   
5. ❌ **Forgetting extension versions**
   - Update `extension.yml` and `CHANGELOG.md` for each modified extension

## Release Script (Optional)

For automated releases, use this pattern:

```bash
#!/bin/bash
set -e

VERSION=$1
PREFIX=$2

if [ -z "$VERSION" ] || [ -z "$PREFIX" ]; then
    echo "Usage: $0 <version> <prefix>"
    echo "Example: $0 0.3.33 fix"
    exit 1
fi

# Update pyproject.toml
sed -i "s/version = \"[0-9.]*\"/version = \"$VERSION\"/" pyproject.toml

# Stage and commit
git add -A
git commit -m "$PREFIX: release version $VERSION"

# Tag and push
git tag "agentic-sdlc-v$VERSION"
git push origin main
git push origin "agentic-sdlc-v$VERSION"

echo "Released agentic-sdlc-v$VERSION"
```

## Lessons Learned

### Session 2026-04-11: Path Resolution Bug

**Problem**: `common.sh` used `$repo_root/memory` but constitution stored in `.specify/memory/`

**Impact**: Validation script failed silently, `get_feature_paths()` returned wrong path

**Fix**: Changed line 318 to `$repo_root/.specify/memory`

**Prevention**: Always verify path consistency between:
- `common.sh` `memory_dir` variable
- Where files are actually stored (`.specify/memory/`)
- Template references

### Session 2026-04-11: Tag Before Version Update

**Problem**: Created tag `agentic-sdlc-v0.3.32` before updating `pyproject.toml`

**Impact**: Tag pointed to commit with wrong version (0.3.31), installation showed old version

**Fix**: Re-tagged at correct commit after updating version file

**Prevention**: Always update `pyproject.toml` BEFORE creating tag

### Session 2026-04-12: Check Remote Before Local Version

**Problem**: Local files showed version `0.3.36` but remote/origin was at `0.3.35`. Attempted to bump to `0.3.37` based on stale local state.

**Impact**: Confusion about which version to release; wasted time correcting version numbers.

**Fix**: Checked `git show origin/main:pyproject.toml` to verify actual remote version.

**Prevention**: Before any release, always verify remote state:

```bash
# Check what's actually pushed (not local state)
git fetch origin
git show origin/main:pyproject.toml | grep "^version"

# Compare with local
cat pyproject.toml | grep "^version"

# Check for uncommitted changes
git status
```

**Key insight**: Local uncommitted changes can make `pyproject.toml` show a different version than what's actually released. Always verify against origin before deciding the next version number.

### Session 2026-04-13: Releasing from a Submodule

**Problem**: When working in a parent repo with spec-kit as a submodule, `git commit` and `git tag` commands run in the wrong directory (parent repo instead of submodule).

**Impact**: 
- Tag `agentic-sdlc-v0.3.40` was initially created in the parent repo instead of the spec-kit submodule
- Commands like `git diff --stat` showed changes but `git commit` failed with "no changes added"

**Fix**: Always explicitly set the working directory when releasing from a submodule:
```bash
cd /path/to/agentic-sdlc-spec-kit
git add -A && git commit -m "fix: description"
git tag agentic-sdlc-vX.Y.Z
git push origin main
git push origin agentic-sdlc-vX.Y.Z
```

**Prevention**: Before any release commit/tag operation:
```bash
# Verify you're in the correct directory
pwd  # Should show .../agentic-sdlc-spec-kit

# Verify pyproject.toml exists in current directory
ls pyproject.toml

# Then proceed with release
```

**Key insight**: When spec-kit is used as a submodule, always navigate into the submodule directory before running any git operations for releases.
```
