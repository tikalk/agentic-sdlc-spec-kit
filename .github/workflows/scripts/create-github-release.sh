#!/usr/bin/env bash
set -euo pipefail

# create-github-release.sh
# Create a GitHub release with all template zip files
# Usage: create-github-release.sh <version>

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

VERSION="$1"

# Remove 'v' prefix from version for release title
VERSION_NO_V=${VERSION#v}

ASSETS=()
AGENTS=(claude gemini copilot cursor qwen opencode windsurf codex kilocode auggie roo q)
SCRIPTS=(sh ps)

for agent in "${AGENTS[@]}"; do
  for script in "${SCRIPTS[@]}"; do
    asset_path=".genreleases/agentic-sdlc-spec-kit-template-${agent}-${script}-${VERSION}.zip"
    if [[ ! -f "$asset_path" ]]; then
      echo "Error: missing release asset $asset_path" >&2
      exit 1
    fi
    ASSETS+=("$asset_path")
  done
done

gh release create "$VERSION" "${ASSETS[@]}" \
  --title "Spec Kit Templates - $VERSION_NO_V" \
  --notes-file release_notes.md