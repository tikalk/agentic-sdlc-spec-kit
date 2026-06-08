#!/usr/bin/env bash
# Git extension: tasks-dag.sh
# Fork (tikalk) -- parses tasks.md into a DAG, classifies parallel eligibility,
# and reports coalescable runs. Emits tasks_dag.json alongside tasks.md.
# Single dispatcher; invoked as: tasks-dag.sh <subcommand> [args...]
#
# Subcommands:
#   generate     --tasks-md <path> [--dag <path>] [--feature <name>]
#   validate     --dag <path>
#   show         --dag <path>
#   classify     --task-id <TNNN> --tasks-md <path>
#   coalesce     --tasks-md <path> [--dag <path>]
#
# All subcommands emit JSON to stdout on success. Errors go to stderr with
# non-zero exit codes. DAG schema version: 1.0
#
# The output DAG is the source of truth for `git.task-merge` (Phase 0 of
# implement.md reads this file) and the [P] classification lives here, not in
# tasks.md (which is a human-readable checklist).

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source git-common.sh for get_repo_root, has_git, etc. Optional for DAG
# analysis (which is git-agnostic) but loaded for consistency.
_common_loaded=false
if [ -f "$SCRIPT_DIR/git-common.sh" ]; then
    source "$SCRIPT_DIR/git-common.sh"
    _common_loaded=true
else
    _dir="$SCRIPT_DIR"
    while [ "$_dir" != "/" ]; do
        if [ -f "$_dir/.specify/scripts/bash/common.sh" ]; then
            source "$_dir/.specify/scripts/bash/common.sh"
            _common_loaded=true
            break
        fi
        if [ -f "$_dir/scripts/bash/common.sh" ]; then
            source "$_dir/scripts/bash/common.sh"
            _common_loaded=true
            break
        fi
        _dir="$(dirname "$_dir")"
    done
fi
# Optional: not failing if common is missing — DAG analyzer is git-agnostic.

# Resolve repo root (using the helper if present).
if type get_repo_root >/dev/null 2>&1; then
    REPO_ROOT="$(get_repo_root)"
else
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
DAG_SCHEMA_VERSION="1.0"
DAG_DEFAULT_FILENAME="tasks_dag.json"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_have_jq() { command -v jq >/dev/null 2>&1; }

_json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//	/\\t}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

_err() { echo "Error: $*" >&2; }
_die() { _err "$@"; exit 1; }

# Strip markdown checkbox, ID, [P], [SYNC]/[ASYNC], [Story] labels from a task line.
# Echoes: id|story|is_parallel|execution_mode|description
_parse_task_line() {
    local line="$1"
    # Match: - [ ] TNNN [P] [ASYNC] [US1] Description
    if [[ "$line" =~ ^-[[:space:]]\[[[:space:]]\][[:space:]]+(T[0-9]+)[[:space:]]+(.*)$ ]]; then
        local id="${BASH_REMATCH[1]}"
        local rest="${BASH_REMATCH[2]}"
        local is_parallel=0
        local story=""
        local execution_mode=""
        local desc="$rest"
        # [P] marker
        if [[ "$rest" =~ ^\[P\][[:space:]]+(.*)$ ]]; then
            is_parallel=1
            rest="${BASH_REMATCH[1]}"
        fi
        # [SYNC] or [ASYNC] marker
        if [[ "$rest" =~ ^\[(SYNC|ASYNC)\][[:space:]]+(.*)$ ]]; then
            execution_mode="${BASH_REMATCH[1]}"
            rest="${BASH_REMATCH[2]}"
        fi
        # [USn] or [USnn] story label
        if [[ "$rest" =~ ^\[(US[0-9]+)\][[:space:]]+(.*)$ ]]; then
            story="${BASH_REMATCH[1]}"
            rest="${BASH_REMATCH[2]}"
        fi
        desc="$rest"
        # Trim trailing whitespace
        desc="$(echo "$desc" | sed -E 's/[[:space:]]+$//')"
        printf '%s|%s|%s|%s|%s\n' "$id" "$story" "$is_parallel" "$execution_mode" "$desc"
        return 0
    fi
    return 1
}

# Extract file paths from a task description.
# Looks for patterns like:
#   in path/to/file.ext
#   to path/to/file.ext
#   at path/to/file.ext
# Returns one path per line on stdout. No deduplication.
_extract_files() {
    local desc="$1"
    # Common patterns: "in src/foo.py", "to tests/test_foo.py", "via bar.py"
    # Also: bare paths like src/services/auth.py when they end in known extensions
    echo "$desc" | grep -oE '[a-zA-Z0-9_./-]+\.(py|sh|ps1|js|ts|tsx|jsx|go|rs|java|rb|php|c|cpp|h|hpp|cs|swift|kt|mjs|cjs)' 2>/dev/null \
        | sort -u || true
}

# Determine execution mode (SYNC/ASYNC).
# If explicit_mode is non-empty, trust it. Otherwise fall back to heuristics:
#   ASYNC if description contains research/analyze keywords, OR >2 files.
_classify_execution_mode() {
    local explicit_mode="$1"
    local desc="$2"
    local files="$3"
    if [ -n "$explicit_mode" ]; then
        echo "$explicit_mode"
        return
    fi
    if echo "$desc" | grep -qiE "research|analyze|design|plan|review|test|investigate|explore|prototype"; then
        echo "ASYNC"
    else
        local file_count=0
        if [ -n "$files" ]; then
            file_count="$(printf '%s\n' "$files" | grep -c . 2>/dev/null || true)"
            file_count="${file_count//[$'\t\r\n ']/}"
            [ -z "$file_count" ] && file_count=0
        fi
        if [ "$file_count" -gt 2 ] 2>/dev/null; then
            echo "ASYNC"
        else
            echo "SYNC"
        fi
    fi
}

# Compute the "phase" of a task. A phase is a section in tasks.md starting
# with "## Phase N: ..." or "## Phase N+1: ...". The current phase is
# tracked via a side-channel file. Echoes phase name (e.g., "Phase 1: Setup").
_detect_phase() {
    local line="$1"
    if [[ "$line" =~ ^##[[:space:]]+(Phase[[:space:]]+[0-9]+[^[:space:]]*)(.*)$ ]]; then
        echo "${BASH_REMATCH[1]}${BASH_REMATCH[2]}" | sed -E 's/[[:space:]]+$//'
        return 0
    fi
    return 1
}

# Topological wave assignment. Inputs (one task per line):
#   id|story|is_parallel|files
# Outputs JSON array of waves (array of id arrays).
_compute_waves() {
    # Read all tasks into bash arrays.
    local lines=()
    while IFS= read -r line; do
        [ -n "$line" ] && lines+=("$line")
    done

    local n=${#lines[@]}
    if [ "$n" -eq 0 ]; then
        echo "[]"
        return
    fi

    # Parse into parallel arrays.
    local -a ids stories parallels files_list
    for line in "${lines[@]}"; do
        IFS='|' read -r id story par exec_mode desc fl phase <<< "$line"
        ids+=("$id")
        stories+=("$story")
        parallels+=("$par")
        files_list+=("$fl")
    done

    # Determine dependencies and waves using a simple rule:
    # - A new wave is started whenever:
    #   (a) The current task is non-[P] (sequential task), OR
    #   (b) The story changes (cross-story boundaries don't merge), OR
    #   (c) The current task's files overlap with the current wave.
    # - A [P] task joins the current wave if it has the same story AND
    #   touches different files from the [P] tasks already in the wave.

    local waves="[]"
    local current_wave_ids=""
    local current_wave_files=""
    local current_wave_story=""

    for i in $(seq 0 $((n - 1))); do
        local id="${ids[$i]}"
        local story="${stories[$i]}"
        local par="${parallels[$i]}"
        local fl="${files_list[$i]}"

        if [ -z "$current_wave_ids" ]; then
            # Start of first wave.
            current_wave_ids="$id"
            current_wave_files="$fl"
            current_wave_story="$story"
            continue
        fi

        local can_join=false
        if [ "$par" = "1" ] && [ "$story" = "$current_wave_story" ]; then
            # Check if this task's files overlap with the current wave.
            local overlap=false
            if [ -n "$fl" ] && [ -n "$current_wave_files" ]; then
                local file
                while IFS= read -r file; do
                    [ -z "$file" ] && continue
                    if printf '%s\n' "$current_wave_files" | grep -qxF "$file"; then
                        overlap=true
                        break
                    fi
                done <<< "$fl"
            fi
            if [ "$overlap" = "false" ]; then
                can_join=true
            fi
        fi

        if [ "$can_join" = "true" ]; then
            current_wave_ids="$current_wave_ids $id"
            if [ -n "$fl" ]; then
                if [ -n "$current_wave_files" ]; then
                    current_wave_files="$current_wave_files
$fl"
                else
                    current_wave_files="$fl"
                fi
            fi
        else
            # Commit current wave and start a new one.
            if _have_jq; then
                local wave_arr
                wave_arr="$(echo "$current_wave_ids" | tr ' ' '\n' | jq -R . | jq -s .)"
                waves="$(echo "$waves" | jq --argjson w "$wave_arr" '. + [$w]')"
            else
                # Fallback: append as raw string (best-effort).
                local wave_arr_str
                wave_arr_str="$(echo "$current_wave_ids" | tr ' ' '\n' | sed 's/^/"/' | sed 's/$/"/' | paste -sd, -)"
                waves="${waves%]},[\"${wave_arr_str//,/\",\"}\"]]"
            fi
            current_wave_ids="$id"
            current_wave_files="$fl"
            current_wave_story="$story"
        fi
    done

    # Commit the last wave.
    if [ -n "$current_wave_ids" ]; then
        if _have_jq; then
            local wave_arr
            wave_arr="$(echo "$current_wave_ids" | tr ' ' '\n' | jq -R . | jq -s .)"
            waves="$(echo "$waves" | jq --argjson w "$wave_arr" '. + [$w]')"
        else
            local wave_arr_str
            wave_arr_str="$(echo "$current_wave_ids" | tr ' ' '\n' | sed 's/^/"/' | sed 's/$/"/' | paste -sd, -)"
            waves="${waves%]},[\"${wave_arr_str//,/\",\"}\"]]"
        fi
    fi

    echo "$waves"
}

# Build a single task JSON object via jq.
_build_task_obj() {
    local id="$1"
    local story="$2"
    local is_parallel="$3"
    local desc="$4"
    local files="$5"
    local execution_mode="$6"
    local wave_index="$7"
    local depends_on="$8"

    local story_json
    if [ -z "$story" ]; then
        story_json="null"
    else
        story_json="\"$(_json_escape "$story")\""
    fi

    local files_json
    if [ -z "$files" ]; then
        files_json="[]"
    elif _have_jq; then
        files_json="$(echo "$files" | jq -R . | jq -s 'map(select(length > 0))')"
    else
        files_json="$(echo "$files" | sed 's/^/"/;s/$/"/' | paste -sd, - | sed 's/^/[/;s/$/]/')"
    fi

    local deps_json
    if [ -z "$depends_on" ]; then
        deps_json="[]"
    elif _have_jq; then
        deps_json="$(echo "$depends_on" | tr ' ' '\n' | jq -R . | jq -s 'map(select(length > 0))')"
    else
        deps_json="$(echo "$depends_on" | sed 's/^/"/;s/$/"/' | paste -sd, - | sed 's/^/[/;s/$/]/')"
    fi

    if _have_jq; then
        jq -cn \
            --arg id "$id" \
            --arg desc "$(_json_escape "$desc")" \
            --argjson story "$story_json" \
            --argjson is_parallel "$is_parallel" \
            --argjson files "$files_json" \
            --arg execution_mode "$execution_mode" \
            --argjson wave "$wave_index" \
            --argjson depends_on "$deps_json" \
            '{
                id: $id,
                description: $desc,
                story: $story,
                is_parallel: $is_parallel,
                files: $files,
                execution_mode: $execution_mode,
                execution_wave: $wave,
                depends_on: $depends_on
            }'
    else
        # Manual JSON build.
        local esc_desc
        esc_desc="$(_json_escape "$desc")"
        cat <<EOF
{
  "id": "$id",
  "description": "$esc_desc",
  "story": $story_json,
  "is_parallel": $is_parallel,
  "files": $files_json,
  "execution_mode": "$execution_mode",
  "execution_wave": $wave_index,
  "depends_on": $deps_json
}
EOF
    fi
}

_usage() {
    cat <<'EOF'
Usage: tasks-dag.sh <subcommand> [options]

Subcommands:
  generate     --tasks-md <path> [--dag <path>] [--feature <name>]
  validate     --dag <path>
  show         --dag <path>
  classify     --task-id <TNNN> --tasks-md <path>
  coalesce     --tasks-md <path> [--dag <path>]

Run `tasks-dag.sh <subcommand> --help` for subcommand-specific options.
EOF
}

# ---------------------------------------------------------------------------
# Subcommand: generate
# ---------------------------------------------------------------------------
cmd_generate() {
    local tasks_md=""
    local dag_path=""
    local feature=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --tasks-md) tasks_md="$2"; shift 2 ;;
            --dag) dag_path="$2"; shift 2 ;;
            --feature) feature="$2"; shift 2 ;;
            --help|-h)
                echo "Usage: tasks-dag.sh generate --tasks-md <path> [--dag <path>] [--feature <name>]"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$tasks_md" ] || _die "--tasks-md is required"
    [ -f "$tasks_md" ] || _die "Tasks file not found: $tasks_md"

    # Default dag path: <tasks_dir>/tasks_dag.json
    if [ -z "$dag_path" ]; then
        local tasks_dir
        tasks_dir="$(dirname "$tasks_md")"
        dag_path="$tasks_dir/$DAG_DEFAULT_FILENAME"
    fi

    # Default feature: tasks dir basename
    if [ -z "$feature" ]; then
        feature="$(basename "$(dirname "$tasks_md")")"
    fi

    # First pass: parse all task lines + collect task records.
    local -a task_records
    local current_phase=""
    while IFS= read -r line; do
        if phase="$(_detect_phase "$line")"; then
            current_phase="$phase"
            continue
        fi
        if parsed="$(_parse_task_line "$line")"; then
            IFS='|' read -r id story par exec_mode desc <<< "$parsed"
            local files
            files="$(_extract_files "$desc")"
            local final_mode
            final_mode="$(_classify_execution_mode "$exec_mode" "$desc" "$files")"
            task_records+=("$id|$story|$par|$final_mode|$desc|$files|$current_phase")
        fi
    done < "$tasks_md"

    # Second pass: compute waves.
    local wave_input=""
    local i=0
    for rec in "${task_records[@]}"; do
        if [ -n "$wave_input" ]; then
            wave_input="$wave_input
$rec"
        else
            wave_input="$rec"
        fi
        i=$((i + 1))
    done

    local waves_json
    waves_json="$(_compute_waves <<< "$wave_input")"

    # Build task array and depends_on by parsing wave assignments.
    # For each task, depends_on = last task in the previous wave (if any).
    local -a wave_indices
    local -a wave_ids_lists
    if _have_jq; then
        local wave_count
        wave_count="$(echo "$waves_json" | jq 'length')"
        for w in $(seq 0 $((wave_count - 1))); do
            local wids
            wids="$(echo "$waves_json" | jq -c ".[$w]")"
            wave_ids_lists+=("$wids")
        done
    else
        # Fallback: no jq, can't determine wave structure. Use 1 task per wave.
        wave_count="${#task_records[@]}"
        for i in $(seq 0 $((wave_count - 1))); do
            wave_ids_lists+=("[\"$(echo "${task_records[$i]}" | cut -d'|' -f1)\"]")
        done
    fi

    # Build depends_on map: for each task, find its wave and the last task
    # in the previous wave.
    local -a all_dependencies
    for i in "${!task_records[@]}"; do
        local rec="${task_records[$i]}"
        local id
        id="$(echo "$rec" | cut -d'|' -f1)"
        # Find which wave contains this id.
        local my_wave=-1
        local w
        for w in "${!wave_ids_lists[@]}"; do
            local wids="${wave_ids_lists[$w]}"
            if _have_jq; then
                if echo "$wids" | jq -e --arg i "$id" '. | index($i)' >/dev/null 2>&1; then
                    my_wave=$w
                    break
                fi
            else
                if [[ "$wids" == *"\"$id\""* ]]; then
                    my_wave=$w
                    break
                fi
            fi
        done
        local deps=""
        if [ "$my_wave" -gt 0 ] && _have_jq; then
            local prev_wave="${wave_ids_lists[$((my_wave - 1))]}"
            local prev_count
            prev_count="$(echo "$prev_wave" | jq 'length')"
            if [ "$prev_count" -gt 0 ]; then
                deps="$(echo "$prev_wave" | jq -r ".[$((prev_count - 1))]")"
            fi
        fi
        all_dependencies+=("$deps")
    done

    # Assemble the DAG JSON.
    local tasks_json="[]"
    for i in "${!task_records[@]}"; do
        local rec="${task_records[$i]}"
        IFS='|' read -r id story par exec_mode desc files phase <<< "$rec"
        # Find the wave index for this task.
        local wave_index=0
        local w
        for w in "${!wave_ids_lists[@]}"; do
            local wids="${wave_ids_lists[$w]}"
            if _have_jq; then
                if echo "$wids" | jq -e --arg i "$id" '. | index($i)' >/dev/null 2>&1; then
                    wave_index=$w
                    break
                fi
            else
                if [[ "$wids" == *"\"$id\""* ]]; then
                    wave_index=$w
                    break
                fi
            fi
        done
        local deps="${all_dependencies[$i]}"
        local task_obj
        task_obj="$(_build_task_obj "$id" "$story" "$par" "$desc" "$files" "$exec_mode" "$wave_index" "$deps")"
        if _have_jq; then
            tasks_json="$(echo "$tasks_json" | jq --argjson t "$task_obj" '. + [$t]')"
        else
            # Manual append.
            if [ "$tasks_json" = "[]" ]; then
                tasks_json="[$task_obj]"
            else
                tasks_json="${tasks_json%]},$task_obj]"
            fi
        fi
    done

    # Compute stats.
    local total parallel_count story_count wave_count_final
    total="${#task_records[@]}"
    if [ "$total" -eq 0 ]; then
        _die "No tasks found in $tasks_md (file may be empty or tasks may lack the required 'TNNN' id prefix)"
    fi
    parallel_count=0
    for rec in "${task_records[@]}"; do
        local par
        par="$(echo "$rec" | cut -d'|' -f3)"
        [ "$par" = "1" ] && parallel_count=$((parallel_count + 1))
    done
    if _have_jq; then
        wave_count_final="$(echo "$waves_json" | jq 'length')"
        story_count="$(echo "$tasks_json" | jq '[.[] | select(.story != null) | .story] | unique | length')"
    else
        wave_count_final="${#wave_ids_lists[@]}"
        # Count unique stories (rough).
        local -A seen_stories
        story_count=0
        for rec in "${task_records[@]}"; do
            local s
            s="$(echo "$rec" | cut -d'|' -f2)"
            if [ -n "$s" ] && [ -z "${seen_stories[$s]:-}" ]; then
                seen_stories["$s"]=1
                story_count=$((story_count + 1))
            fi
        done
    fi

    local created_at
    created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # Emit DAG.
    if _have_jq; then
        local stats_json
        stats_json="$(jq -cn \
            --argjson total "$total" \
            --argjson parallel "$parallel_count" \
            --argjson stories "$story_count" \
            --argjson waves "$wave_count_final" \
            '{total_tasks: $total, parallel_tasks: $parallel, stories: $stories, total_waves: $waves}')"
        jq -n \
            --arg schema "$DAG_SCHEMA_VERSION" \
            --arg feature "$feature" \
            --arg src "$tasks_md" \
            --arg created "$created_at" \
            --argjson tasks "$tasks_json" \
            --argjson waves "$waves_json" \
            --argjson stats "$stats_json" \
            '{
                schema_version: $schema,
                feature: $feature,
                source: $src,
                generated_at: $created,
                tasks: $tasks,
                execution_waves: $waves,
                stats: $stats
            }' > "$dag_path"
    else
        # Fallback: build JSON manually.
        local esc_feature esc_src esc_created
        esc_feature="$(_json_escape "$feature")"
        esc_src="$(_json_escape "$tasks_md")"
        esc_created="$(_json_escape "$created_at")"
        local tasks_str="$tasks_json"
        local waves_str="$waves_json"
        cat > "$dag_path" <<EOF
{
  "schema_version": "$DAG_SCHEMA_VERSION",
  "feature": "$esc_feature",
  "source": "$esc_src",
  "generated_at": "$esc_created",
  "tasks": $tasks_str,
  "execution_waves": $waves_str,
  "stats": {
    "total_tasks": $total,
    "parallel_tasks": $parallel_count,
    "stories": $story_count,
    "total_waves": $wave_count_final
  }
}
EOF
    fi

    # Emit summary JSON to stdout.
    if _have_jq; then
        jq -cn \
            --arg dag_path "$dag_path" \
            --arg feature "$feature" \
            --argjson total "$total" \
            --argjson parallel "$parallel_count" \
            --argjson waves "$wave_count_final" \
            --argjson stories "$story_count" \
            '{dag_written:true, dag_path:$dag_path, feature:$feature, total_tasks:$total, parallel_tasks:$parallel, total_waves:$waves, stories:$stories, ok:true}'
    else
        local rel_dag="${dag_path#"$REPO_ROOT/"}"
        printf '{"dag_written":true,"dag_path":"%s","feature":"%s","total_tasks":%d,"parallel_tasks":%d,"total_waves":%d,"stories":%d,"ok":true}\n' \
            "$(_json_escape "$rel_dag")" \
            "$(_json_escape "$feature")" \
            "$total" "$parallel_count" "$wave_count_final" "$story_count"
    fi
}

# ---------------------------------------------------------------------------
# Subcommand: validate
# ---------------------------------------------------------------------------
cmd_validate() {
    local dag_path=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --dag) dag_path="$2"; shift 2 ;;
            --help|-h)
                echo "Usage: tasks-dag.sh validate --dag <path>"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$dag_path" ] || _die "--dag is required"
    [ -f "$dag_path" ] || _die "DAG file not found: $dag_path"

    local errors=()
    if ! _have_jq; then
        _die "validate requires jq (no fallback available)"
    fi

    # Check schema_version
    local schema
    schema="$(jq -r '.schema_version // empty' "$dag_path" 2>/dev/null)"
    if [ -z "$schema" ]; then
        errors+=("missing schema_version")
    elif [ "$schema" != "$DAG_SCHEMA_VERSION" ]; then
        errors+=("unsupported schema_version: $schema (expected $DAG_SCHEMA_VERSION)")
    fi

    # Check unique IDs
    local dup_count
    dup_count="$(jq '[.tasks[].id] | group_by(.) | map(select(length > 1)) | length' "$dag_path" 2>/dev/null || echo 0)"
    if [ "$dup_count" -gt 0 ]; then
        errors+=("duplicate task IDs found: $dup_count groups")
    fi

    # Check depends_on reference valid IDs
    local invalid_deps_count
    invalid_deps_count="$(jq -r '
        [.tasks[].id] as $ids |
        [.tasks[] as $t | $t.depends_on[]? | select(. as $d | $ids | index($d) | not)] | length
    ' "$dag_path" 2>/dev/null || echo 0)"
    if [ "$invalid_deps_count" -gt 0 ] 2>/dev/null; then
        errors+=("depends_on references unknown IDs: $invalid_deps_count found")
    fi

    # Check waves is array of arrays
    local waves_valid
    waves_valid="$(jq '.execution_waves | type == "array" and (.[0] | type == "array" or length == 0)' "$dag_path" 2>/dev/null)"
    if [ "$waves_valid" != "true" ]; then
        errors+=("execution_waves must be array of arrays")
    fi

    local valid=true
    if [ "${#errors[@]}" -gt 0 ]; then
        valid=false
    fi

    local errs_json
    if [ "${#errors[@]}" -gt 0 ]; then
        errs_json="$(printf '%s\n' "${errors[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]')"
    else
        errs_json="[]"
    fi
    jq -cn \
        --argjson valid "$valid" \
        --argjson errors "$errs_json" \
        --arg dag "$dag_path" \
        '{valid: $valid, errors: $errors, dag_path: $dag, ok: true}'
}

# ---------------------------------------------------------------------------
# Subcommand: show
# ---------------------------------------------------------------------------
cmd_show() {
    local dag_path=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --dag) dag_path="$2"; shift 2 ;;
            --help|-h)
                echo "Usage: tasks-dag.sh show --dag <path>"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$dag_path" ] || _die "--dag is required"
    [ -f "$dag_path" ] || _die "DAG file not found: $dag_path"

    if ! _have_jq; then
        _die "show requires jq (no fallback available)"
    fi

    local feature
    feature="$(jq -r '.feature // "unknown"' "$dag_path")"
    local total
    total="$(jq -r '.stats.total_tasks // (.tasks | length)' "$dag_path")"
    local parallel
    parallel="$(jq -r '.stats.parallel_tasks // ([.tasks[] | select(.is_parallel == true)] | length)' "$dag_path")"
    local waves
    waves="$(jq -r '.stats.total_waves // (.execution_waves | length)' "$dag_path")"
    local stories
    stories="$(jq -r '.stats.stories // ([.tasks[] | select(.story != null) | .story] | unique | length)' "$dag_path")"

    echo "DAG: $dag_path"
    echo "  Feature:        $feature"
    echo "  Total tasks:    $total"
    echo "  Parallel tasks: $parallel"
    echo "  User stories:   $stories"
    echo "  Wave count:     $waves"
    echo
    echo "Execution waves:"
    local w=0
    while [ $w -lt "$waves" ]; do
        local wave_ids
        wave_ids="$(jq -r --argjson w "$w" '.execution_waves[$w] | join(", ")' "$dag_path")"
        echo "  Wave $((w + 1)): $wave_ids"
        w=$((w + 1))
    done
    echo
    echo "Per-story task counts:"
    jq -r '
        .tasks
        | group_by(.story // "<no-story>")
        | .[]
        | "  \(.[0].story // "<no-story>"): \(length) task(s)"
    ' "$dag_path"
}

# ---------------------------------------------------------------------------
# Subcommand: classify
# ---------------------------------------------------------------------------
cmd_classify() {
    local task_id=""
    local tasks_md=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --task-id) task_id="$2"; shift 2 ;;
            --tasks-md) tasks_md="$2"; shift 2 ;;
            --help|-h)
                echo "Usage: tasks-dag.sh classify --task-id <TNNN> --tasks-md <path>"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$task_id" ] || _die "--task-id is required"
    [ -n "$tasks_md" ] || _die "--tasks-md is required"
    [ -f "$tasks_md" ] || _die "Tasks file not found: $tasks_md"

    if ! _have_jq; then
        _die "classify requires jq (no fallback available)"
    fi

    # Find the task line.
    local task_line
    task_line="$(grep -E "^- \[[ x]\] ${task_id}\b" "$tasks_md" | head -n1 || true)"
    if [ -z "$task_line" ]; then
        _die "Task $task_id not found in $tasks_md"
    fi

    local parsed
    if ! parsed="$(_parse_task_line "$task_line")"; then
        _die "Failed to parse task line: $task_line"
    fi
    IFS='|' read -r id story par exec_mode desc <<< "$parsed"
    local files
    files="$(_extract_files "$desc")"
    local final_mode
    final_mode="$(_classify_execution_mode "$exec_mode" "$desc" "$files")"

    local files_json
    files_json="$(echo "$files" | jq -R . | jq -s 'map(select(length > 0))')"

    # Compute the wave by replaying the same algorithm as _compute_waves,
    # so classify's wave number always matches generate's `execution_wave` field
    # on the per-task record (0-based).
    #
    # The first task is in wave 0. Each subsequent task either:
    #   (a) joins the current wave (P + same story + no file overlap), or
    #   (b) starts a new wave (non-P, story change, or file overlap).
    # The wave for a task = the current_wave index AT THE TIME the task is
    # processed, AFTER incrementing if it starts a new wave.
    local wave=0
    local cur_wave_story=""
    local cur_wave_files=""
    local cur_wave_has_task=false
    local saw_target=false
    while IFS= read -r line; do
        if parsed="$(_parse_task_line "$line")"; then
            IFS='|' read -r tid tstory tpar texec_mode tdesc <<< "$parsed"
            local tfl
            tfl="$(_extract_files "$tdesc")"

            local is_target=false
            if [ "$tid" = "$task_id" ]; then
                is_target=true
            fi

            # Decide whether this task starts a new wave.
            local starts_new_wave=false
            if [ "$cur_wave_has_task" = "false" ]; then
                # First task: it IS wave 0; no increment needed.
                starts_new_wave=false
            elif [ "$tpar" = "1" ] && [ "$tstory" = "$cur_wave_story" ]; then
                # P + same story: check file overlap.
                local overlap=false
                if [ -n "$tfl" ] && [ -n "$cur_wave_files" ]; then
                    local tfile
                    while IFS= read -r tfile; do
                        [ -z "$tfile" ] && continue
                        if printf '%s\n' "$cur_wave_files" | grep -qxF "$tfile"; then
                            overlap=true
                            break
                        fi
                    done <<< "$tfl"
                fi
                if [ "$overlap" = "true" ]; then
                    starts_new_wave=true
                fi
            else
                # Non-P, OR story change.
                starts_new_wave=true
            fi

            if [ "$starts_new_wave" = "true" ]; then
                wave=$((wave + 1))
            fi

            if [ "$is_target" = "true" ]; then
                saw_target=true
                break
            fi

            # Update current wave anchor (for the next task).
            cur_wave_has_task=true
            if [ -n "$tfl" ]; then
                if [ -n "$cur_wave_files" ]; then
                    cur_wave_files="$cur_wave_files
$tfl"
                else
                    cur_wave_files="$tfl"
                fi
            fi
            cur_wave_story="$tstory"
        fi
    done < "$tasks_md"

    [ "$saw_target" = "true" ] || _die "Task $task_id not found in walk"

    local story_json
    if [ -z "$story" ]; then
        story_json="null"
    else
        story_json="\"$(_json_escape "$story")\""
    fi

    jq -cn \
        --arg id "$task_id" \
        --arg desc "$(_json_escape "$desc")" \
        --argjson story "$story_json" \
        --argjson is_parallel "$par" \
        --argjson files "$files_json" \
        --arg exec_mode "$final_mode" \
        --argjson wave "$wave" \
        '{id: $id, description: $desc, story: $story, is_parallel: $is_parallel, files: $files, execution_mode: $exec_mode, execution_wave: $wave, ok: true}'
}

# ---------------------------------------------------------------------------
# Subcommand: coalesce (report-only per C1)
# ---------------------------------------------------------------------------
cmd_coalesce() {
    local tasks_md=""
    local dag_path=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --tasks-md) tasks_md="$2"; shift 2 ;;
            --dag) dag_path="$2"; shift 2 ;;
            --help|-h)
                echo "Usage: tasks-dag.sh coalesce --tasks-md <path> [--dag <path>]"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$tasks_md" ] || _die "--tasks-md is required"
    [ -f "$tasks_md" ] || _die "Tasks file not found: $tasks_md"

    # Build a per-phase list of (id, story, par, desc, files).
    # Then find adjacent pairs that meet the coalesce criteria:
    #   1. Same story (or both no-story)
    #   2. Both non-parallel (sequential)
    #   3. Short descriptions (< 80 chars after stripping)
    #   4. Touch the same primary file
    # Report as JSON. No rewrite per C1.

    local coalescable="[]"
    local prev_id="" prev_story="" prev_par="" prev_desc="" prev_file=""
    while IFS= read -r line; do
        if parsed="$(_parse_task_line "$line")"; then
            IFS='|' read -r id story par exec_mode desc <<< "$parsed"
            local files
            files="$(_extract_files "$desc")"
            local first_file
            first_file="$(echo "$files" | head -n1)"

            if [ -n "$prev_id" ]; then
                local short_enough=false
                if [ "${#desc}" -lt 80 ] && [ "${#prev_desc}" -lt 80 ]; then
                    short_enough=true
                fi
                if [ "$short_enough" = "true" ] && [ "$story" = "$prev_story" ] \
                    && [ "$par" = "0" ] && [ "$prev_par" = "0" ] \
                    && [ -n "$first_file" ] && [ "$first_file" = "$prev_file" ]; then
                    local record
                    if _have_jq; then
                        record="$(jq -cn \
                            --arg t1 "$prev_id" \
                            --arg t2 "$id" \
                            --arg file "$first_file" \
                            --arg reason "Both non-parallel tasks in same story touch $first_file; both descriptions < 80 chars" \
                            '{tasks: [$t1, $t2], file: $file, reason: $reason}')"
                        coalescable="$(echo "$coalescable" | jq --argjson r "$record" '. + [$r]')"
                    else
                        # Manual append (no jq fallback).
                        if [ "$coalescable" = "[]" ]; then
                            coalescable="[$record]"
                        fi
                    fi
                fi
            fi

            prev_id="$id"; prev_story="$story"; prev_par="$par"
            prev_desc="$desc"; prev_file="$first_file"
        fi
    done < "$tasks_md"

    local count=0
    if _have_jq; then
        count="$(echo "$coalescable" | jq 'length')"
    else
        count=0
    fi

    if _have_jq; then
        jq -cn \
            --argjson count "$count" \
            --argjson pairs "$coalescable" \
            --arg tasks_md "$tasks_md" \
            '{coalescable_count: $count, pairs: $pairs, tasks_md: $tasks_md, mode: "report-only", ok: true}'
    else
        # Manual JSON when no jq.
        printf '{"coalescable_count":%d,"pairs":[],"tasks_md":"%s","mode":"report-only","ok":true}\n' \
            "$count" "$(_json_escape "$tasks_md")"
    fi
}

# ---------------------------------------------------------------------------
# Main dispatcher
# ---------------------------------------------------------------------------
SUBCOMMAND="${1:-}"
if [ -z "$SUBCOMMAND" ]; then
    _usage
    exit 1
fi
shift

case "$SUBCOMMAND" in
    generate)    cmd_generate    "$@" ;;
    validate)    cmd_validate    "$@" ;;
    show)        cmd_show        "$@" ;;
    classify)    cmd_classify    "$@" ;;
    coalesce)    cmd_coalesce    "$@" ;;
    -h|--help|help) _usage; exit 0 ;;
    *) _err "Unknown subcommand: $SUBCOMMAND"; _usage; exit 1 ;;
esac
