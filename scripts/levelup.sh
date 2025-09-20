#!/bin/bash
# /levelup command entrypoint for agentic-sdlc-spec-kit
# Usage: ./levelup.sh "<description>"

if [ -z "$1" ]; then
  echo "Usage: $0 '<description of knowledge asset>'"
  exit 1
fi

DESCRIPTION="$1"

# Call the main levelup logic (assume .specify/scripts/bash/levelup.sh exists)
if [ -f ".specify/scripts/bash/levelup.sh" ]; then
  bash .specify/scripts/bash/levelup.sh "$DESCRIPTION"
else
  echo "Error: .specify/scripts/bash/levelup.sh not found. Please ensure the core logic is implemented."
  exit 2
fi
