#!/bin/bash

# Script to parse tasks.md and output JSON for issue tracker integration.

TASKS_FILE="$1"
OUTPUT_FILE="$2"

if [ -z "$TASKS_FILE" ]; then
  echo "Usage: $0 <path_to_tasks.md> [output_file.json]"
  exit 1
fi

if [ ! -f "$TASKS_FILE" ]; then
  echo "Error: tasks file not found at $TASKS_FILE"
  exit 1
fi

# Initialize JSON array
JSON_OUTPUT="["
FIRST_TASK=true

# Read tasks.md line by line
while IFS= read -r line; do
  # Regex to match task format: - [ ] T001 [P] [SYNC] Description
  if [[ "$line" =~ ^-[\ ]\[[\ ]\][\ ](T[0-9]{3})[\ ](\[P\][\ ]?)?(\[(SYNC|ASYNC)\])[\ ](.*)$ ]]; then
    TASK_ID="${BASH_REMATCH[1]}"
    IS_PARALLEL="false"
    if [[ "${BASH_REMATCH[2]}" == "[P] " ]]; then
      IS_PARALLEL="true"
    fi
    TASK_TYPE="${BASH_REMATCH[3]}"
    TASK_TYPE="${TASK_TYPE//[\[\]]/}" # Remove brackets
    DESCRIPTION="${BASH_REMATCH[5]}"

    # Escape double quotes in description
    ESCAPED_DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/"/\\"/g')

    if [ "$FIRST_TASK" = false ]; then
      JSON_OUTPUT+=","
    fi
    FIRST_TASK=false

    JSON_OUTPUT+="{ \"id\": \"$TASK_ID\", \"is_parallel\": $IS_PARALLEL, \"type\": \"$TASK_TYPE\", \"description\": \"$ESCAPED_DESCRIPTION\" }"
  fi
done < "$TASKS_FILE"

JSON_OUTPUT+="]"

if [ -n "$OUTPUT_FILE" ]; then
  echo "$JSON_OUTPUT" > "$OUTPUT_FILE"
  echo "Tasks successfully parsed and saved to $OUTPUT_FILE"
else
  echo "$JSON_OUTPUT"
  echo -e "\nTasks successfully parsed and printed to stdout."
fi

exit 0