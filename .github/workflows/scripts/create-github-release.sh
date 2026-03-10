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

# Tag prefix must remain in sync with get-next-version
TAG_PREFIX="agentic-sdlc-v"

# Remove prefix from version for release title
VERSION_NO_V=${VERSION#v}

# Use dynamic glob pattern to pick up all generated packages
# This ensures consistency with create-release-packages.sh output naming
gh release create "$VERSION" \
  .genreleases/agentic-sdlc-spec-kit-template-*-"$VERSION".zip \
  --title "Agentic SDLC Spec Kit Templates - $VERSION_NO_V" \
  --notes-file release_notes.md
