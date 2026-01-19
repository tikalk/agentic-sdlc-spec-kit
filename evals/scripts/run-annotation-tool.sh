#!/bin/bash
# Run the FastHTML annotation tool for spec review
# Usage: ./evals/scripts/run-annotation-tool.sh

set -e

ANNOTATION_DIR="evals/annotation-tool"

echo "Setting up annotation tool..."

# Navigate to annotation tool directory
cd "$ANNOTATION_DIR"

# Create venv if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment with uv..."
    uv venv
fi

# Activate venv and install dependencies
echo "Installing dependencies..."
source .venv/bin/activate
uv pip install python-fasthtml markdown

echo ""
echo "Starting annotation tool..."
echo "Open your browser to the URL shown below:"
echo ""

python app.py
