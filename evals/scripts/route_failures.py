#!/usr/bin/env python3
"""
Failure routing script for EDD Principle VIII
Routes failures to appropriate actions based on failure type
"""

import json
import sys
import os
from datetime import datetime

def route_failure(result_file):
    """Route failures based on EDD failure types."""

    with open(result_file, 'r') as f:
        results = json.load(f)

    for result in results.get('tests', []):
        if not result.get('pass', True):
            failure_type = result.get('metadata', {}).get('failure_type')
            criterion = result.get('metadata', {}).get('criterion', 'unknown')

            if failure_type == 'specification_failure':
                generate_fix_directive(criterion, result)
            elif failure_type == 'generalization_failure':
                add_to_evaluator_backlog(criterion, result)

def generate_fix_directive(criterion, result):
    """Generate fix directive for specification failures."""

    directive = {
        "criterion": criterion,
        "failure_type": "specification_failure",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "priority": "critical" if "security" in criterion else "high",
        "failure_reason": result.get('reason', 'Unknown failure'),
        "action_required": "fix_directive",
        "status": "open"
    }

    output_path = f"../results/fix_directives/{criterion}_fix.json"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with open(output_path, 'w') as f:
        json.dump(directive, f, indent=2)

def add_to_evaluator_backlog(criterion, result):
    """Add to evaluator backlog for generalization failures."""

    backlog_item = {
        "criterion": criterion,
        "failure_type": "generalization_failure",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "priority": "normal",
        "failure_pattern": result.get('reason', 'Unknown pattern'),
        "action_required": "build_evaluator",
        "status": "pending"
    }

    output_path = f"../results/evaluator_backlog/{criterion}_backlog.json"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with open(output_path, 'w') as f:
        json.dump(backlog_item, f, indent=2)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        route_failure(sys.argv[1])
    else:
        print("Usage: python route_failures.py <result_file>")
