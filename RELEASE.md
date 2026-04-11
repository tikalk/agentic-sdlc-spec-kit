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
