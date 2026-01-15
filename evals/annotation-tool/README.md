# Spec Annotation Tool

A fast, keyboard-driven interface for reviewing generated specs. Built with FastHTML for 10x faster annotation.

## Features

- **Keyboard-driven navigation**: N (next), P (previous), 1 (pass), 2 (fail)
- **Progress tracking**: See how many specs reviewed, passed, failed
- **Notes**: Add notes for each spec
- **Auto-save**: Annotations automatically saved to JSON
- **Export**: Export all annotations with statistics
- **Beautiful rendering**: Markdown specs rendered with syntax highlighting

## Quick Start

```bash
# Run using the provided script (from project root)
./evals/scripts/run-annotation-tool.sh
```

Or manually:

```bash
# Install dependencies with uv
cd evals/annotation-tool
uv venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
uv pip install python-fasthtml markdown

# Run the app
python app.py
```

Then open your browser to `http://localhost:5001` (or the port shown in the terminal).

## Usage

### Keyboard Shortcuts

- **N** - Next spec
- **P** - Previous spec
- **1** - Mark as Pass (and advance to next)
- **2** - Mark as Fail (and advance to next)

### Workflow

1. Review the spec content displayed
2. Add notes in the text area (optional)
3. Mark as Pass (1) or Fail (2)
4. The tool automatically advances to the next spec
5. Use Export button to save all annotations with timestamp

### Output

Annotations are saved to:

- `annotations.json` - Current annotations (auto-saved)
- `annotations_export_YYYYMMDD_HHMMSS.json` - Exported snapshots

## Data Structure

```json
{
  "exported_at": "2026-01-08T14:30:00",
  "statistics": {
    "total": 17,
    "passed": 12,
    "failed": 3,
    "pending": 2,
    "progress": 88.2
  },
  "annotations": {
    "spec-001.md": {
      "status": "pass",
      "notes": "Good structure, all sections present",
      "timestamp": "2026-01-08T14:25:00"
    },
    "spec-002.md": {
      "status": "fail",
      "notes": "Missing acceptance criteria",
      "timestamp": "2026-01-08T14:26:00"
    }
  }
}
```

## Customization

### Change Specs Directory

Edit `SPECS_DIR` in `app.py`:

```python
SPECS_DIR = Path("path/to/your/specs")
```

### Add Filtering

The MVP doesn't include filtering by status yet. To add:

1. Add filter buttons in the UI
2. Modify `get_current_spec()` to filter specs list
3. Reset index when filter changes

### Add Semantic Search

For advanced features, you can extend with:

- Vector embeddings for similar spec clustering
- AI-powered categorization suggestions
- Bulk operations

## Architecture

- **FastHTML**: Lightweight web framework with HTMX
- **Pico CSS**: Minimal, beautiful styling
- **JSON storage**: Simple file-based persistence
- **Markdown**: Renders spec content with code highlighting

## Next Steps

After using this tool for initial reviews:

1. Export annotations for error analysis in Jupyter
2. Use findings to extend PromptFoo tests
3. Build LLM-as-Judge evaluators based on failure patterns
4. Add discovered failure modes to CI/CD pipeline
