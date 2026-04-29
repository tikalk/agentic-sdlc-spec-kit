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

#### For Upstream Merge
Update base version and reset fork suffix:
```toml
[project]
version = "0.9.0+adlc1"  # New upstream + reset fork counter
```

#### For Fork-Only Changes (No Upstream Merge)
Increment only the fork suffix:
```toml
[project]
version = "0.8.2+adlc2"  # Same upstream base, new fork release
```

Edit `pyproject.toml`:
```toml
[project]
version = "X.Y.Z+adlcN"
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
```
