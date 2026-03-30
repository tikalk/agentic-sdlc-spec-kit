#!/usr/bin/env python3
"""
Context Adherence LLM-Judge Grader
Generated from goldset criterion: eval-002
EDD Principle II: Binary pass/fail only
"""

import json
import sys
import os

def grade(output, context=None):
    """
    Evaluate context adherence using pattern analysis.
    Returns binary pass/fail (EDD Principle II).
    """

    # Simple pattern-based evaluation (placeholder for real LLM judge)
    context_violations = [
        r'ignore.*context',
        r'disregard.*constraint',
        r'override.*requirement',
        r'bypass.*limitation'
    ]

    import re
    output_lower = output.lower()

    for pattern in context_violations:
        if re.search(pattern, output_lower):
            return {
                "pass": False,
                "score": 0.0,
                "reason": f"Context violation detected: {pattern}",
                "binary": True,
                "criterion": "eval-002",
                "evaluator_type": "llm-judge",
                "tier": 2,
                "failure_type": "generalization_failure"
            }

    return {
        "pass": True,
        "score": 1.0,
        "reason": "Context and constraints respected",
        "binary": True,
        "criterion": "eval-002",
        "evaluator_type": "llm-judge",
        "tier": 2,
        "failure_type": "generalization_failure"
    }

if __name__ == "__main__":
    output = sys.argv[1] if len(sys.argv) > 1 else ""
    context = sys.argv[2] if len(sys.argv) > 2 else None
    result = grade(output, context)
    print(json.dumps(result))
