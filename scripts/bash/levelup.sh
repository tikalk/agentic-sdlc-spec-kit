#!/bin/bash
# scripts/bash/levelup.sh - Entrypoint for the /levelup command (Bash)
# Usage: scripts/bash/levelup.sh "<knowledge description>"

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 '<knowledge description>'"
  exit 1
fi

DESCRIPTION="$1"

CORE_SCRIPT=".specify/scripts/bash/levelup.sh"
if [ ! -f "$CORE_SCRIPT" ]; then
  echo "Error: Core script $CORE_SCRIPT not found. Please implement the core logic."
  exit 2
fi

bash "$CORE_SCRIPT" "$DESCRIPTION"
