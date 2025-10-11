# Tasks Metadata Structure (tasks_meta.json)

This document specifies the structure of `tasks_meta.json`, which complements `tasks.md` by tracking execution metadata, agent assignments, review status, and traceability information for the dual execution loop.

## File Location
- `tasks_meta.json` should be created alongside `tasks.md` in the feature directory
- Example: `specs/001-add-repository-reference/tasks_meta.json`

## JSON Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "feature": {
      "type": "string",
      "description": "Feature/branch name"
    },
    "created_at": {
      "type": "string",
      "format": "date-time",
      "description": "When tasks_meta.json was created"
    },
    "updated_at": {
      "type": "string",
      "format": "date-time",
      "description": "Last update timestamp"
    },
    "execution_mode": {
      "type": "string",
      "enum": ["local", "hybrid", "async"],
      "description": "Overall execution mode for this feature"
    },
    "async_agent": {
      "type": "string",
      "enum": ["jules", "async-copilot", "async-codex"],
      "description": "Configured async agent for ASYNC tasks"
    },
    "tasks": {
      "type": "object",
      "patternProperties": {
        "^T\\d{3}$": {
          "$ref": "#/$defs/task_metadata"
        }
      },
      "description": "Task metadata keyed by task ID (T001, T002, etc.)"
    },
    "phases": {
      "type": "object",
      "description": "Phase-level metadata"
    },
    "reviews": {
      "type": "object",
      "description": "Review tracking and outcomes"
    },
    "traceability": {
      "type": "object",
      "description": "Links to PRs, commits, issues"
    }
  },
  "required": ["feature", "created_at", "tasks"],
  "$defs": {
    "task_metadata": {
      "type": "object",
      "properties": {
        "task_id": {
          "type": "string",
          "pattern": "^T\\d{3}$",
          "description": "Task identifier (T001, T002, etc.)"
        },
        "description": {
          "type": "string",
          "description": "Brief task description"
        },
        "execution_mode": {
          "type": "string",
          "enum": ["SYNC", "ASYNC"],
          "description": "Execution classification"
        },
        "parallel_marker": {
          "type": "boolean",
          "description": "Whether task can run in parallel ([P] marker)"
        },
        "status": {
          "type": "string",
          "enum": ["pending", "in_progress", "completed", "failed", "blocked"],
          "description": "Current execution status"
        },
        "assigned_agent": {
          "type": "string",
          "enum": ["human", "jules", "async-copilot", "async-codex"],
          "description": "Who/what executed this task"
        },
        "started_at": {
          "type": "string",
          "format": "date-time",
          "description": "When execution started"
        },
        "completed_at": {
          "type": "string",
          "format": "date-time",
          "description": "When execution completed"
        },
        "duration_seconds": {
          "type": "number",
          "description": "Execution duration in seconds"
        },
        "review_status": {
          "type": "string",
          "enum": ["pending", "micro_reviewed", "macro_reviewed", "approved", "rejected"],
          "description": "Review status (SYNC=micro, ASYNC=macro)"
        },
        "reviewer": {
          "type": "string",
          "description": "Person who performed the review"
        },
        "review_notes": {
          "type": "string",
          "description": "Review feedback and notes"
        },
        "files_modified": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Files created/modified by this task"
        },
        "commits": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Commit hashes related to this task"
        },
        "pr_links": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Pull request URLs related to this task"
        },
        "async_job_id": {
          "type": "string",
          "description": "Job ID from async agent execution"
        },
        "error_message": {
          "type": "string",
          "description": "Error message if task failed"
        },
        "retry_count": {
          "type": "integer",
          "minimum": 0,
          "description": "Number of retry attempts"
        },
        "dependencies": {
          "type": "array",
          "items": { "type": "string", "pattern": "^T\\d{3}$" },
          "description": "Task IDs this task depends on"
        }
      },
      "required": ["task_id", "execution_mode", "status"]
    }
  }
}
```

## Example Structure

```json
{
  "feature": "add-repository-reference",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-16T14:45:00Z",
  "execution_mode": "hybrid",
  "async_agent": "jules",
  "tasks": {
    "T001": {
      "task_id": "T001",
      "description": "Create repository reference model",
      "execution_mode": "SYNC",
      "parallel_marker": false,
      "status": "completed",
      "assigned_agent": "human",
      "started_at": "2024-01-15T11:00:00Z",
      "completed_at": "2024-01-15T11:30:00Z",
      "duration_seconds": 1800,
      "review_status": "micro_reviewed",
      "reviewer": "alice",
      "review_notes": "Architecture looks good, added validation",
      "files_modified": ["src/models/repository.py"],
      "commits": ["a1b2c3d"],
      "pr_links": ["https://github.com/org/repo/pull/123"]
    },
    "T002": {
      "task_id": "T002",
      "description": "Implement CRUD operations for repository references",
      "execution_mode": "ASYNC",
      "parallel_marker": true,
      "status": "completed",
      "assigned_agent": "jules",
      "started_at": "2024-01-15T14:00:00Z",
      "completed_at": "2024-01-15T14:15:00Z",
      "duration_seconds": 900,
      "review_status": "macro_reviewed",
      "reviewer": "bob",
      "review_notes": "Generated code looks correct, tests pass",
      "files_modified": ["src/services/repository_service.py", "tests/test_repository.py"],
      "async_job_id": "jules-job-456",
      "commits": ["e4f5g6h"],
      "pr_links": ["https://github.com/org/repo/pull/124"]
    }
  },
  "phases": {
    "setup": {
      "status": "completed",
      "completed_at": "2024-01-15T10:45:00Z"
    },
    "us1": {
      "status": "completed",
      "completed_at": "2024-01-15T15:00:00Z",
      "sync_tasks": 1,
      "async_tasks": 1,
      "micro_reviews": 1,
      "macro_reviews": 1
    }
  },
  "reviews": {
    "micro_reviews_completed": 1,
    "macro_reviews_completed": 1,
    "total_reviews": 2
  },
  "traceability": {
    "feature_branch": "feature/add-repository-reference",
    "base_branch": "main",
    "issue_links": ["https://github.com/org/repo/issues/789"],
    "related_prs": ["https://github.com/org/repo/pull/123", "https://github.com/org/repo/pull/124"]
  }
}
```

## Usage Guidelines

1. **Creation**: `tasks_meta.json` should be created when `tasks.md` is generated
2. **Updates**: Update timestamps and task status as execution progresses
3. **SYNC Tasks**: Require `micro_reviewed` status before completion
4. **ASYNC Tasks**: Require `macro_reviewed` status before completion
5. **Traceability**: Link all commits, PRs, and issues for audit trails
6. **Error Handling**: Track retry attempts and error messages for debugging

## Integration Points

- **tasks.md**: Human-readable task list with [SYNC]/[ASYNC] markers
- **tasks_meta.json**: Machine-readable metadata for execution tracking
- **implement command**: Updates task status and review information
- **levelup command**: Uses metadata for knowledge asset generation and review checklists