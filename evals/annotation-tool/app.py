#!/usr/bin/env python3
"""
FastHTML Annotation Tool for Spec Review
Provides a fast, keyboard-driven interface for reviewing generated specs.
"""

import json
from datetime import datetime
from pathlib import Path

from fasthtml.common import *
import markdown

# Initialize FastHTML app with Pico CSS
app, rt = fast_app(pico=True)

# Configuration
SPECS_DIR = Path("../datasets/real-specs")
ANNOTATIONS_FILE = Path("annotations.json")

# Global state (in production, use proper state management)
class AnnotationState:
    def __init__(self):
        self.load_specs()
        self.load_annotations()
        self.current_index = 0

    def load_specs(self):
        """Load all spec files"""
        self.specs = sorted(list(SPECS_DIR.glob("spec-*.md")))
        if not self.specs:
            self.specs = []

    def load_annotations(self):
        """Load existing annotations"""
        if ANNOTATIONS_FILE.exists():
            with open(ANNOTATIONS_FILE, 'r') as f:
                self.annotations = json.load(f)
        else:
            self.annotations = {}

    def save_annotations(self):
        """Save annotations to JSON"""
        with open(ANNOTATIONS_FILE, 'w') as f:
            json.dump(self.annotations, f, indent=2)

    def get_current_spec(self):
        """Get current spec content"""
        if not self.specs or self.current_index >= len(self.specs):
            return None, None

        spec_path = self.specs[self.current_index]
        with open(spec_path, 'r') as f:
            content = f.read()

        return spec_path.name, content

    def get_annotation(self, spec_name):
        """Get annotation for a spec"""
        return self.annotations.get(spec_name, {
            "status": "pending",
            "notes": "",
            "timestamp": None
        })

    def set_annotation(self, spec_name, status, notes=""):
        """Set annotation for a spec"""
        self.annotations[spec_name] = {
            "status": status,
            "notes": notes,
            "timestamp": datetime.now().isoformat()
        }
        self.save_annotations()

    def get_stats(self):
        """Get annotation statistics"""
        total = len(self.specs)
        passed = sum(1 for a in self.annotations.values() if a["status"] == "pass")
        failed = sum(1 for a in self.annotations.values() if a["status"] == "fail")
        pending = total - passed - failed

        return {
            "total": total,
            "passed": passed,
            "failed": failed,
            "pending": pending,
            "progress": (passed + failed) / total * 100 if total > 0 else 0
        }

# Initialize state
state = AnnotationState()

@rt("/")
def get():
    """Main page"""
    spec_name, content = state.get_current_spec()

    if spec_name is None:
        return Html(
            Head(Title("Spec Annotation Tool")),
            Body(
                Main(
                    H1("No specs found"),
                    P(f"Please add spec files to {SPECS_DIR}"),
                    cls="container"
                )
            )
        )

    annotation = state.get_annotation(spec_name)
    stats = state.get_stats()

    # Convert markdown to HTML
    html_content = markdown.markdown(content, extensions=['fenced_code', 'tables'])

    # Status badge color
    status_colors = {
        "pass": "green",
        "fail": "red",
        "pending": "gray"
    }

    return Html(
        Head(
            Title("Spec Annotation Tool"),
            Script(src="https://unpkg.com/htmx.org@1.9.10"),
            Link(rel="stylesheet", href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"),
            Style("""
                .spec-content {
                    padding: 1rem;
                    background: var(--pico-background-color);
                    border-radius: 0.5rem;
                    margin: 1rem 0;
                    max-height: 60vh;
                    overflow-y: auto;
                }
                .controls {
                    display: flex;
                    gap: 1rem;
                    margin: 1rem 0;
                    flex-wrap: wrap;
                }
                .stats {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
                    gap: 1rem;
                    margin: 1rem 0;
                }
                .stat-card {
                    padding: 1rem;
                    background: var(--pico-card-background-color);
                    border-radius: 0.5rem;
                    text-align: center;
                }
                .stat-value {
                    font-size: 2rem;
                    font-weight: bold;
                }
                .stat-label {
                    font-size: 0.9rem;
                    opacity: 0.8;
                }
                .progress-bar {
                    width: 100%;
                    height: 8px;
                    background: var(--pico-muted-color);
                    border-radius: 4px;
                    overflow: hidden;
                    margin: 1rem 0;
                }
                .progress-fill {
                    height: 100%;
                    background: var(--pico-primary);
                    transition: width 0.3s ease;
                }
                .keyboard-help {
                    font-size: 0.9rem;
                    opacity: 0.7;
                    padding: 1rem;
                    background: var(--pico-card-background-color);
                    border-radius: 0.5rem;
                    margin: 1rem 0;
                }
                .status-badge {
                    display: inline-block;
                    padding: 0.25rem 0.75rem;
                    border-radius: 1rem;
                    font-size: 0.9rem;
                    font-weight: bold;
                }
                .status-pass { background: #2ecc71; color: white; }
                .status-fail { background: #e74c3c; color: white; }
                .status-pending { background: #95a5a6; color: white; }
            """)
        ),
        Body(
            Main(
                H1("Spec Annotation Tool"),

                # Stats
                Div(
                    Div(
                        Div(str(stats['total']), cls="stat-value"),
                        Div("Total", cls="stat-label"),
                        cls="stat-card"
                    ),
                    Div(
                        Div(str(stats['passed']), cls="stat-value"),
                        Div("Passed", cls="stat-label"),
                        cls="stat-card"
                    ),
                    Div(
                        Div(str(stats['failed']), cls="stat-value"),
                        Div("Failed", cls="stat-label"),
                        cls="stat-card"
                    ),
                    Div(
                        Div(str(stats['pending']), cls="stat-value"),
                        Div("Pending", cls="stat-label"),
                        cls="stat-card"
                    ),
                    cls="stats"
                ),

                # Progress bar
                Div(
                    Div(style=f"width: {stats['progress']}%", cls="progress-fill"),
                    cls="progress-bar"
                ),

                # Current spec info
                H2(f"Spec {state.current_index + 1} of {len(state.specs)}: {spec_name}"),
                Span(annotation['status'].upper(), cls=f"status-badge status-{annotation['status']}"),

                # Spec content
                Article(
                    NotStr(html_content),
                    cls="spec-content"
                ),

                # Notes
                Form(
                    Textarea(
                        annotation.get('notes', ''),
                        name="notes",
                        placeholder="Add notes about this spec...",
                        rows="3"
                    ),
                    Input(type="hidden", name="spec_name", value=spec_name),
                    Button("Save Notes", type="submit"),
                    hx_post="/save-notes",
                    hx_target="#message",
                    hx_swap="innerHTML"
                ),
                Div(id="message"),

                # Controls
                Div(
                    Button("← Previous (P)",
                           hx_post="/prev",
                           hx_target="body",
                           hx_swap="outerHTML",
                           accesskey="p"),
                    Button("Next (N) →",
                           hx_post="/next",
                           hx_target="body",
                           hx_swap="outerHTML",
                           accesskey="n"),
                    Button("✓ Pass (1)",
                           hx_post=f"/annotate/pass/{spec_name}",
                           hx_target="body",
                           hx_swap="outerHTML",
                           accesskey="1",
                           cls="contrast"),
                    Button("✗ Fail (2)",
                           hx_post=f"/annotate/fail/{spec_name}",
                           hx_target="body",
                           hx_swap="outerHTML",
                           accesskey="2"),
                    Button("Export JSON",
                           hx_get="/export",
                           hx_target="#message"),
                    cls="controls"
                ),

                # Keyboard help
                Details(
                    Summary("Keyboard Shortcuts"),
                    Div(
                        P(Strong("N"), " - Next spec"),
                        P(Strong("P"), " - Previous spec"),
                        P(Strong("1"), " - Mark as Pass"),
                        P(Strong("2"), " - Mark as Fail"),
                        cls="keyboard-help"
                    )
                ),

                cls="container"
            ),
            # JavaScript for additional keyboard shortcuts
            Script("""
                document.addEventListener('keydown', function(e) {
                    // Ignore if user is typing in textarea
                    if (e.target.tagName === 'TEXTAREA' || e.target.tagName === 'INPUT') {
                        return;
                    }

                    switch(e.key.toLowerCase()) {
                        case 'n':
                            document.querySelector('button[accesskey="n"]').click();
                            break;
                        case 'p':
                            document.querySelector('button[accesskey="p"]').click();
                            break;
                        case '1':
                            document.querySelector('button[accesskey="1"]').click();
                            break;
                        case '2':
                            document.querySelector('button[accesskey="2"]').click();
                            break;
                    }
                });
            """)
        )
    )

@rt("/next")
def post():
    """Navigate to next spec"""
    if state.current_index < len(state.specs) - 1:
        state.current_index += 1
    return get()

@rt("/prev")
def post():
    """Navigate to previous spec"""
    if state.current_index > 0:
        state.current_index -= 1
    return get()

@rt("/annotate/{status}/{spec_name}")
def post(status: str, spec_name: str):
    """Annotate spec with pass/fail"""
    annotation = state.get_annotation(spec_name)
    state.set_annotation(spec_name, status, annotation.get('notes', ''))

    # Auto-advance to next spec
    if state.current_index < len(state.specs) - 1:
        state.current_index += 1

    # Return redirect header for HTMX
    return Response(status_code=200, headers={'HX-Redirect': '/'})

@rt("/save-notes")
def post(spec_name: str, notes: str):
    """Save notes for current spec"""
    annotation = state.get_annotation(spec_name)
    state.set_annotation(spec_name, annotation.get('status', 'pending'), notes)
    return Div(
        P("Notes saved!", style="color: green; margin-top: 0.5rem;"),
        id="message"
    )

@rt("/export")
def get():
    """Export annotations to JSON"""
    stats = state.get_stats()
    export_data = {
        "exported_at": datetime.now().isoformat(),
        "statistics": stats,
        "annotations": state.annotations
    }

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    export_path = Path(f"annotations_export_{timestamp}.json")

    with open(export_path, 'w') as f:
        json.dump(export_data, f, indent=2)

    return Div(
        P(f"Exported to {export_path}", style="color: green; margin-top: 0.5rem;"),
        id="message"
    )

if __name__ == "__main__":
    serve()
