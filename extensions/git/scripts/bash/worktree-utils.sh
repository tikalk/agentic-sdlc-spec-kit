#!/usr/bin/env bash
# Git extension: worktree-utils.sh
# Fork (tikalk) — manages feature worktrees and task branches.
# Single dispatcher; invoked as: worktree-utils.sh <subcommand> [args...]
#
# Subcommands:
#   create-feature-worktree   --feature <name> [--base <branch>]
#   remove-feature-worktree   --feature <name> [--force]
#   create-task-branch        --feature <name> --task-id <TNNN> --task-slug <slug>
#   remove-task-branch        --feature <name> --task-id <TNNN> [--force]
#   is-in-worktree            (no args; exit 0 in primary, exit 2 inside worktree)
#   list-worktrees            (no args)
#   read-manifest             --worktree-path <path>
#   finish-feature            --feature <name> [--keep-branch] [--force]
#
# All subcommands emit JSON to stdout on success. Errors go to stderr with
# non-zero exit codes. Manifests live at <worktree>/git.worktree-manifest.json
# (see extensions_fork.py:WORKTREE_MANIFEST_FILENAME).
#
# Design alignment: obra/superpowers using-git-worktrees — provenance-based
# cleanup via the manifest, never clobber user-created worktrees.

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source git-common.sh for get_repo_root, has_git, etc.
# Fall back to the project's installed common.sh if git-common.sh is missing.
_common_loaded=false
if [ -f "$SCRIPT_DIR/git-common.sh" ]; then
    source "$SCRIPT_DIR/git-common.sh"
    _common_loaded=true
else
    # Walk up to find .specify/scripts/bash/common.sh
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
if [ "$_common_loaded" != "true" ]; then
    echo "Error: Could not locate git-common.sh or common.sh" >&2
    exit 1
fi

# Resolve repo root (using the helper from git-common.sh if present).
if type get_repo_root >/dev/null 2>&1; then
    REPO_ROOT="$(get_repo_root)"
else
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Constants — mirrored from src/specify_cli/extensions_fork.py.
# If you change these, change them there too. (Single source of truth: the
# Python module. These are read at runtime so the script stays in sync.)
# ---------------------------------------------------------------------------
WORKTREE_BASE_DIR_DEFAULT=".worktrees"
WORKTREE_MANIFEST_FILENAME_DEFAULT="git.worktree-manifest.json"
WORKTREE_TASK_BRANCH_PATTERN_DEFAULT="{feature}--task-{id}-{task-slug}"
WORKTREE_CONFIG_FILE=".specify/extensions/git/git-config.yml"
WORKTREE_CONFIG_KEY="worktrees"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Read a value from .specify/extensions/git/git-config.yml using simple grep.
# Returns the value on stdout, or empty string if not found. Does NOT handle
# nested keys (only flat: `worktrees.isolation_mode` → look for
# `isolation_mode:` inside the `worktrees:` block).
_get_yaml_value() {
    local key="$1"
    local file="$2"
    [ -f "$file" ] || { echo ""; return 0; }
    # Extract value from `key: value` line, stripping quotes.
    grep -E "^[[:space:]]+${key}:" "$file" 2>/dev/null \
        | head -n1 \
        | sed -E "s/^[[:space:]]*${key}:[[:space:]]*//" \
        | sed -E "s/^['\"]//; s/['\"]$//"
}

# Resolve worktree config: returns the worktree section's value for the
# requested key, or the default if not configured.
_worktree_config_value() {
    local key="$1"
    local val
    val="$(_get_yaml_value "$key" "$REPO_ROOT/$WORKTREE_CONFIG_FILE")"
    if [ -z "$val" ]; then
        case "$key" in
            base_dir) echo "$WORKTREE_BASE_DIR_DEFAULT" ;;
            manifest_filename) echo "$WORKTREE_MANIFEST_FILENAME_DEFAULT" ;;
            task_branch_pattern) echo "$WORKTREE_TASK_BRANCH_PATTERN_DEFAULT" ;;
            isolation_mode) echo "branch" ;;
            *) echo "" ;;
        esac
    else
        echo "$val"
    fi
}

# Compute the absolute path of a feature worktree.
_worktree_path_for() {
    local feature="$1"
    local base_dir
    base_dir="$(_worktree_config_value base_dir)"
    # Strip leading "./" or "/" from base_dir for consistency.
    base_dir="${base_dir#./}"
    base_dir="${base_dir#/}"
    echo "$REPO_ROOT/$base_dir/$feature"
}

# Compute the task branch name from feature + id + slug, using the configured
# pattern. Slug is sanitized to kebab-case.
_task_branch_name() {
    local feature="$1"
    local task_id="$2"
    local task_slug="$3"
    local pattern
    pattern="$(_worktree_config_value task_branch_pattern)"
    # Strip "T" prefix from id (T005 -> 5) for the {id} substitution per
    # AGENTS.md branch naming example: "003-auth--task-5-auth-middleware".
    local id_num="${task_id#T}"
    id_num=$((10#$id_num))
    # Sanitize slug: lowercase, alphanum + dash only, no leading/trailing dash.
    local clean_slug
    clean_slug="$(echo "$task_slug" | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
    # Apply pattern substitution using bash parameter expansion.
    local result="${pattern//\{feature\}/$feature}"
    result="${result//\{id\}/$id_num}"
    result="${result//\{task-slug\}/$clean_slug}"
    echo "$result"
}

# Detect whether the current working directory is inside a worktree under the
# configured base dir. Returns "true" or "false".
_is_inside_worktree() {
    local toplevel
    toplevel="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
    [ -z "$toplevel" ] && { echo "false"; return 0; }
    local base_dir
    base_dir="$(_worktree_config_value base_dir)"
    base_dir="${base_dir#./}"
    base_dir="${base_dir#/}"
    local base_path="$REPO_ROOT/$base_dir/"
    case "$toplevel/" in
        "$base_path"*) echo "true" ;;
        *) echo "false" ;;
    esac
}

# JSON emission helpers — prefer jq, fall back to printf.
_have_jq() { command -v jq >/dev/null 2>&1; }

_json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//	/\\t}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

# Write a manifest JSON file. Takes feature, worktree_path, and a list of
# task branch records on stdin (one JSON object per line).
_write_manifest() {
    local feature="$1"
    local worktree_path="$2"
    local manifest_filename
    manifest_filename="$(_worktree_config_value manifest_filename)"
    local manifest_file="$worktree_path/$manifest_filename"
    local created_at
    created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # Read task branch records from stdin (one per line, each is a JSON object).
    local task_records=()
    while IFS= read -r line; do
        [ -n "$line" ] && task_records+=("$line")
    done

    local tasks_json
    if _have_jq; then
        # Build tasks array from records.
        local tmpf
        tmpf="$(mktemp)"
        : > "$tmpf"
        for rec in "${task_records[@]}"; do
            echo "$rec" >> "$tmpf"
        done
        tasks_json="$(jq -s '.' "$tmpf")"
        rm -f "$tmpf"
        jq -n \
            --arg schema "1.0" \
            --arg feature "$feature" \
            --arg branch "$feature" \
            --arg wpath "$worktree_path" \
            --arg created_at "$created_at" \
            --arg created_by "worktree-utils.sh" \
            --argjson tasks "$tasks_json" \
            '{
                schema_version: $schema,
                feature: $feature,
                feature_branch: $branch,
                worktree_path: $wpath,
                created_at: $created_at,
                task_branches: $tasks,
                provenance: {created_by: $created_by, version: $schema}
            }' > "$manifest_file"
    else
        # Manual JSON build (no jq).
        local tasks_str="["
        local first=1
        for rec in "${task_records[@]}"; do
            [ $first -eq 0 ] && tasks_str+=","
            tasks_str+="$rec"
            first=0
        done
        tasks_str+="]"
        local esc_feature esc_path esc_branch esc_created esc_creator
        esc_feature="$(_json_escape "$feature")"
        esc_path="$(_json_escape "$worktree_path")"
        esc_branch="$(_json_escape "$feature")"
        esc_created="$(_json_escape "$created_at")"
        esc_creator="$(_json_escape "worktree-utils.sh")"
        cat > "$manifest_file" <<EOF
{
  "schema_version": "1.0",
  "feature": "${esc_feature}",
  "feature_branch": "${esc_branch}",
  "worktree_path": "${esc_path}",
  "created_at": "${esc_created}",
  "task_branches": ${tasks_str},
  "provenance": {"created_by": "${esc_creator}", "version": "1.0"}
}
EOF
    fi
}

# Mark the manifest file as skip-worktree (tracked in the index but with the
# skip-worktree bit set). This makes git consider it "tracked" so `git worktree
# remove` won't complain about untracked files, while still letting our script
# freely rewrite the on-disk content without dirtying the worktree. We use
# `--add` to put the file in the index even though there's no commit yet, and
# `git update-index --skip-worktree` to mark local edits as ignored.
_exclude_manifest_in_worktree() {
    local worktree_path="$1"
    local manifest_filename
    manifest_filename="$(_worktree_config_value manifest_filename)"
    local manifest_file="$worktree_path/$manifest_filename"

    [ -f "$manifest_file" ] || return 0

    # `git update-index` requires either a clean working file (when adding) or
    # --add to add a new path. Use --add to register, then --skip-worktree so
    # subsequent in-place rewrites don't dirty the worktree.
    git -C "$worktree_path" update-index --add --skip-worktree -- "$manifest_filename" >&2 2>/dev/null || true
}

# Read a manifest file. Returns 0 on success with content on stdout, 1 if not
# found. Uses jq for parsing if available.
_read_manifest_field() {
    local manifest_file="$1"
    local field="$2"
    [ -f "$manifest_file" ] || return 1
    if _have_jq; then
        jq -r ".$field // empty" "$manifest_file" 2>/dev/null
    else
        # Fallback: simple regex extraction for top-level string fields.
        grep -E "^[[:space:]]*\"${field}\":" "$manifest_file" \
            | head -n1 \
            | sed -E "s/^[[:space:]]*\"${field}\":[[:space:]]*\"([^\"]*)\".*/\1/"
    fi
}

# Read all task branch records as a JSON array. Returns "[]" if no tasks.
_read_manifest_tasks() {
    local manifest_file="$1"
    [ -f "$manifest_file" ] || { echo "[]"; return 0; }
    if _have_jq; then
        jq -c '.task_branches // []' "$manifest_file" 2>/dev/null
    else
        # Try to extract the task_branches array literally.
        awk '/"task_branches":[[:space:]]*\[/,/\][[:space:]]*,?[[:space:]]*$/' "$manifest_file" \
            | sed -E 's/,$//' | tr -d '\n'
        echo ""
    fi
}

# Print a single emit-only JSON success object.
_emit_ok() {
    local key="$1"
    local value="$2"
    if _have_jq; then
        jq -cn --arg k "$key" --arg v "$value" '{($k): $v, ok: true}'
    else
        printf '{"%s":"%s","ok":true}\n' "$(_json_escape "$key")" "$(_json_escape "$value")"
    fi
}

# Print a JSON object from a key-value pair list.
_emit_json() {
    if _have_jq; then
        jq -cn "$@"
    else
        # Fallback: simple key-value output (caller should use _emit_ok for
        # single keys, or build a printf template).
        local out="{"
        local first=1
        for arg in "$@"; do
            # Strip leading --arg / --argjson
            case "$arg" in
                --arg|--argjson) shift; continue ;;
            esac
            # Each remaining arg is "key=value"
            local k="${arg%%=*}"
            local v="${arg#*=}"
            [ $first -eq 0 ] && out+=","
            out+="\"$(_json_escape "$k")\":\"$(_json_escape "$v")\""
            first=0
        done
        out+="}"
        printf '%s\n' "$out"
    fi
}

_err() {
    echo "Error: $*" >&2
}

_die() {
    _err "$@"
    exit 1
}

_usage() {
    cat <<'EOF'
Usage: worktree-utils.sh <subcommand> [options]

Subcommands:
  create-feature-worktree   --feature <name> [--base <branch>]
  remove-feature-worktree   --feature <name> [--force]
  create-task-branch        --feature <name> --task-id <TNNN> --task-slug <slug>
  remove-task-branch        --feature <name> --task-id <TNNN> [--force]
  merge-task-branch         --feature <name> --task-id <TNNN> [--delegate-conflicts]
  is-in-worktree
  list-worktrees
  read-manifest             --worktree-path <path>
  finish-feature            --feature <name> [--keep-branch] [--force]

Run `worktree-utils.sh <subcommand> --help` for subcommand-specific options.
EOF
}

# ---------------------------------------------------------------------------
# Subcommand: create-feature-worktree
# ---------------------------------------------------------------------------
cmd_create_feature_worktree() {
    local feature=""
    local base_branch=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --feature) feature="$2"; shift 2 ;;
            --base) base_branch="$2"; shift 2 ;;
            --help|-h)
                echo "Usage: worktree-utils.sh create-feature-worktree --feature <name> [--base <branch>]"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$feature" ] || _die "--feature is required"
    if ! has_git "$REPO_ROOT" 2>/dev/null && ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        _die "Not a git repository"
    fi

    local base_dir
    base_dir="$(_worktree_config_value base_dir)"
    base_dir="${base_dir#./}"
    base_dir="${base_dir#/}"
    local worktree_path="$REPO_ROOT/$base_dir/$feature"

    # Default base: current branch (whatever the user is on when they invoke
    # git.feature). If on a feature branch, base off main/master to avoid
    # nested feature worktrees.
    if [ -z "$base_branch" ]; then
        base_branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"
        # If currently on a feature branch, use main/master if it exists.
        if [ "$base_branch" = "$feature" ]; then
            # Self-referencing — just use HEAD.
            base_branch="HEAD"
        fi
    fi

    # Refuse if a worktree already exists at the target path.
    if [ -d "$worktree_path" ]; then
        _die "Worktree path already exists: $worktree_path"
    fi

    # Refuse if the feature branch already exists in the primary checkout.
    if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$feature"; then
        _die "Branch '$feature' already exists in primary checkout"
    fi

    # Create the .worktrees directory if needed.
    mkdir -p "$REPO_ROOT/$base_dir"

    # Add the worktree with a new branch. Route git's informational output to
    # stderr so stdout carries only the final JSON.
    if ! git -C "$REPO_ROOT" worktree add "$worktree_path" -b "$feature" "$base_branch" >&2; then
        _die "git worktree add failed for $worktree_path"
    fi

    # Write initial manifest (no task branches yet).
    _write_manifest "$feature" "$worktree_path"

    # Exclude the manifest from the worktree's gitdir so `git worktree remove`
    # doesn't refuse over an untracked file.
    _exclude_manifest_in_worktree "$worktree_path"

    local manifest_filename
    manifest_filename="$(_worktree_config_value manifest_filename)"
    local rel_path="${worktree_path#"$REPO_ROOT/"}"

    if _have_jq; then
        jq -cn \
            --arg worktree_path "$rel_path" \
            --arg worktree_branch "$feature" \
            --arg manifest "$(echo "$rel_path/$manifest_filename")" \
            --arg base_dir "$base_dir" \
            '{worktree_path:$worktree_path, worktree_branch:$worktree_branch, manifest_written:true, manifest_path:$manifest, base_dir:$base_dir, ok:true}'
    else
        printf '{"worktree_path":"%s","worktree_branch":"%s","manifest_written":true,"manifest_path":"%s","base_dir":"%s","ok":true}\n' \
            "$(_json_escape "$rel_path")" \
            "$(_json_escape "$feature")" \
            "$(_json_escape "$rel_path/$manifest_filename")" \
            "$(_json_escape "$base_dir")"
    fi
}

# ---------------------------------------------------------------------------
# Subcommand: remove-feature-worktree
# ---------------------------------------------------------------------------
cmd_remove_feature_worktree() {
    local feature=""
    local force=false

    while [ $# -gt 0 ]; do
        case "$1" in
            --feature) feature="$2"; shift 2 ;;
            --force) force=true; shift ;;
            --help|-h)
                echo "Usage: worktree-utils.sh remove-feature-worktree --feature <name> [--force]"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$feature" ] || _die "--feature is required"

    local worktree_path
    worktree_path="$(_worktree_path_for "$feature")"
    local manifest_filename
    manifest_filename="$(_worktree_config_value manifest_filename)"
    local manifest_file="$worktree_path/$manifest_filename"

    if [ ! -d "$worktree_path" ]; then
        _die "Worktree does not exist: $worktree_path"
    fi

    # Provenance check: refuse to remove without manifest unless --force.
    if [ ! -f "$manifest_file" ] && [ "$force" != "true" ]; then
        _die "No manifest at $manifest_file — refusing to remove (use --force to override)"
    fi

    # If there are task branches in the manifest, refuse unless --force.
    local task_count=0
    if [ -f "$manifest_file" ] && _have_jq; then
        task_count="$(jq '.task_branches | length' "$manifest_file" 2>/dev/null || echo 0)"
    fi
    if [ "$task_count" -gt 0 ] && [ "$force" != "true" ]; then
        _die "Manifest has $task_count task branch(es) — use 'finish-feature' for proper cleanup, or --force to override"
    fi

    # Remove the worktree. The manifest file is untracked by design (ephemeral
    # state), so `git worktree remove`'s built-in dirty-check would falsely
    # refuse. Run a pre-check that filters the manifest out of the dirty
    # list — if anything else is dirty, fail with details; otherwise use
    # --force (safe because we've verified only the manifest was dirty).
    # Route git's chatter to stderr.
    local dirty
    dirty="$(git -C "$worktree_path" status --porcelain 2>/dev/null | grep -v "^?? $manifest_filename\$" | grep -v "^.. $manifest_filename\$" || true)"
    if [ -n "$dirty" ] && [ "$force" != "true" ]; then
        _die "Worktree has uncommitted changes (excluding the manifest, which is ignored):
$dirty
Use --force to override."
    fi

    # We've already verified the worktree is clean (modulo the manifest), so
    # --force is safe here even when the caller didn't request it.
    git -C "$REPO_ROOT" worktree remove --force "$worktree_path" >&2 2>/dev/null \
        || rm -rf "$worktree_path"

    # Clean up: delete the feature branch if it still exists.
    local branch_deleted=false
    if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$feature"; then
        git -C "$REPO_ROOT" branch -D "$feature" >&2 2>/dev/null && branch_deleted=true
    fi

    local rel_path="${worktree_path#"$REPO_ROOT/"}"
    if _have_jq; then
        jq -cn \
            --arg path "$rel_path" \
            --argjson branch_deleted "$branch_deleted" \
            '{removed:true, worktree_path:$path, branch_deleted:$branch_deleted, ok:true}'
    else
        printf '{"removed":true,"worktree_path":"%s","branch_deleted":%s,"ok":true}\n' \
            "$(_json_escape "$rel_path")" "$branch_deleted"
    fi
}

# ---------------------------------------------------------------------------
# Subcommand: create-task-branch
# ---------------------------------------------------------------------------
cmd_create_task_branch() {
    local feature=""
    local task_id=""
    local task_slug=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --feature) feature="$2"; shift 2 ;;
            --task-id) task_id="$2"; shift 2 ;;
            --task-slug) task_slug="$2"; shift 2 ;;
            --help|-h)
                echo "Usage: worktree-utils.sh create-task-branch --feature <name> --task-id <TNNN> --task-slug <slug>"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$feature" ] || _die "--feature is required"
    [ -n "$task_id" ] || _die "--task-id is required"
    [ -n "$task_slug" ] || _die "--task-slug is required"

    # Validate task_id format (T followed by digits).
    if ! [[ "$task_id" =~ ^T[0-9]+$ ]]; then
        _die "Invalid task_id: '$task_id' (expected T followed by digits)"
    fi

    local worktree_path
    worktree_path="$(_worktree_path_for "$feature")"
    local manifest_filename
    manifest_filename="$(_worktree_config_value manifest_filename)"
    local manifest_file="$worktree_path/$manifest_filename"

    if [ ! -d "$worktree_path" ]; then
        _die "Feature worktree does not exist: $worktree_path (run create-feature-worktree first)"
    fi

    local task_branch
    task_branch="$(_task_branch_name "$feature" "$task_id" "$task_slug")"

    # Refuse if task branch already exists.
    if git -C "$worktree_path" show-ref --verify --quiet "refs/heads/$task_branch"; then
        _die "Task branch '$task_branch' already exists"
    fi

    # Create the task branch from the feature branch HEAD.
    if ! git -C "$worktree_path" branch "$task_branch" 2>&1; then
        _die "git branch $task_branch failed"
    fi

    # Update manifest: append the new task record.
    local created_at
    created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local new_record
    if _have_jq; then
        new_record="$(jq -cn \
            --arg id "$task_id" \
            --arg branch "$task_branch" \
            --arg created_at "$created_at" \
            '{id:$id, branch:$branch, created_at:$created_at}')"
    else
        new_record="$(printf '{"id":"%s","branch":"%s","created_at":"%s"}' \
            "$(_json_escape "$task_id")" \
            "$(_json_escape "$task_branch")" \
            "$(_json_escape "$created_at")")"
    fi

    if [ -f "$manifest_file" ] && _have_jq; then
        local tmpf
        tmpf="$(mktemp)"
        jq --argjson rec "$new_record" \
            '.task_branches += [$rec]' "$manifest_file" > "$tmpf" \
            && mv "$tmpf" "$manifest_file"
    fi
    # If no manifest or no jq, silently skip manifest update (best-effort).

    if _have_jq; then
        jq -cn \
            --arg task_branch "$task_branch" \
            --arg worktree_path "${worktree_path#"$REPO_ROOT/"}" \
            '{task_branch:$task_branch, worktree_path:$worktree_path, manifest_updated:true, ok:true}'
    else
        printf '{"task_branch":"%s","worktree_path":"%s","manifest_updated":true,"ok":true}\n' \
            "$(_json_escape "$task_branch")" \
            "$(_json_escape "${worktree_path#"$REPO_ROOT/"}")"
    fi
}

# ---------------------------------------------------------------------------
# Subcommand: remove-task-branch
# ---------------------------------------------------------------------------
cmd_remove_task_branch() {
    local feature=""
    local task_id=""
    local force=false

    while [ $# -gt 0 ]; do
        case "$1" in
            --feature) feature="$2"; shift 2 ;;
            --task-id) task_id="$2"; shift 2 ;;
            --force) force=true; shift ;;
            --help|-h)
                echo "Usage: worktree-utils.sh remove-task-branch --feature <name> --task-id <TNNN> [--force]"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$feature" ] || _die "--feature is required"
    [ -n "$task_id" ] || _die "--task-id is required"

    local worktree_path
    worktree_path="$(_worktree_path_for "$feature")"

    if [ ! -d "$worktree_path" ]; then
        _die "Feature worktree does not exist: $worktree_path"
    fi

    # Find the task branch from the manifest.
    local manifest_filename
    manifest_filename="$(_worktree_config_value manifest_filename)"
    local manifest_file="$worktree_path/$manifest_filename"
    local task_branch=""

    if [ -f "$manifest_file" ] && _have_jq; then
        task_branch="$(jq -r --arg id "$task_id" \
            '.task_branches[] | select(.id == $id) | .branch' "$manifest_file" 2>/dev/null | head -n1)"
    fi

    if [ -z "$task_branch" ]; then
        # Fallback: compute from pattern (in case manifest is missing).
        task_branch="$(_task_branch_name "$feature" "$task_id" "task")"
        if [ "$force" != "true" ]; then
            _die "Task branch not found in manifest; cannot safely derive. Use --force with explicit --task-slug, or run with manifest."
        fi
    fi

    if ! git -C "$worktree_path" show-ref --verify --quiet "refs/heads/$task_branch"; then
        if [ "$force" != "true" ]; then
            _die "Task branch '$task_branch' does not exist"
        fi
    else
        if [ "$force" = "true" ]; then
            git -C "$worktree_path" branch -D "$task_branch" >&2 2>/dev/null || true
        else
            git -C "$worktree_path" branch -d "$task_branch" >&2 2>/dev/null \
                || _die "Branch '$task_branch' is not fully merged; use --force to delete anyway"
        fi
    fi

    # Update manifest: remove the task record.
    if [ -f "$manifest_file" ] && _have_jq; then
        local tmpf
        tmpf="$(mktemp)"
        jq --arg id "$task_id" \
            '.task_branches |= map(select(.id != $id))' "$manifest_file" > "$tmpf" \
            && mv "$tmpf" "$manifest_file"
    fi

    if _have_jq; then
        jq -cn \
            --arg task_branch "$task_branch" \
            --arg task_id "$task_id" \
            '{removed:true, task_branch:$task_branch, task_id:$task_id, manifest_updated:true, ok:true}'
    else
        printf '{"removed":true,"task_branch":"%s","task_id":"%s","manifest_updated":true,"ok":true}\n' \
            "$(_json_escape "$task_branch")" "$(_json_escape "$task_id")"
    fi
}

# ---------------------------------------------------------------------------
# Subcommand: is-in-worktree
# ---------------------------------------------------------------------------
cmd_is_in_worktree() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                echo "Usage: worktree-utils.sh is-in-worktree"
                echo "  Exit codes: 0 = in primary checkout, 2 = inside a feature worktree"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    local in_wt
    in_wt="$(_is_inside_worktree)"

    local toplevel=""
    if toplevel="$(git rev-parse --show-toplevel 2>/dev/null)"; then
        toplevel="${toplevel#"$REPO_ROOT/"}"
    fi

    local feature=""
    if [ "$in_wt" = "true" ]; then
        # Extract feature name from path: <base_dir>/<feature>
        local base_dir
        base_dir="$(_worktree_config_value base_dir)"
        base_dir="${base_dir#./}"
        base_dir="${base_dir#/}"
        feature="${toplevel#$base_dir/}"
    fi

    if _have_jq; then
        jq -cn \
            --argjson in_wt "$([ "$in_wt" = "true" ] && echo true || echo false)" \
            --arg worktree_path "$toplevel" \
            --arg feature "$feature" \
            '{is_in_worktree:$in_wt, worktree_path:$worktree_path, feature:$feature}'
    else
        local in_wt_lc
        in_wt_lc="$([ "$in_wt" = "true" ] && echo true || echo false)"
        printf '{"is_in_worktree":%s,"worktree_path":"%s","feature":"%s"}\n' \
            "$in_wt_lc" "$(_json_escape "$toplevel")" "$(_json_escape "$feature")"
    fi

    if [ "$in_wt" = "true" ]; then
        exit 2
    fi
    exit 0
}

# ---------------------------------------------------------------------------
# Subcommand: list-worktrees
# ---------------------------------------------------------------------------
cmd_list_worktrees() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                echo "Usage: worktree-utils.sh list-worktrees"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    local base_dir
    base_dir="$(_worktree_config_value base_dir)"
    base_dir="${base_dir#./}"
    base_dir="${base_dir#/}"
    local base_path="$REPO_ROOT/$base_dir"

    if _have_jq; then
        local entries="[]"
        if [ -d "$base_path" ]; then
            for d in "$base_path"/*/; do
                [ -d "$d" ] || continue
                local feature
                feature="$(basename "$d")"
                local rel="${d#"$REPO_ROOT/"}"
                rel="${rel%/}"
                local has_manifest="false"
                local manifest_filename
                manifest_filename="$(_worktree_config_value manifest_filename)"
                [ -f "$d/$manifest_filename" ] && has_manifest="true"
                local entry
                entry="$(jq -cn \
                    --arg path "$rel" \
                    --arg branch "$feature" \
                    --argjson has_manifest "$has_manifest" \
                    --arg feature "$feature" \
                    '{path:$path, branch:$branch, has_manifest:$has_manifest, feature:$feature}')"
                entries="$(echo "$entries" | jq --argjson e "$entry" '. + [$e]')"
            done
        fi
        jq -cn --argjson worktrees "$entries" '{worktrees:$worktrees, ok:true}'
    else
        # Fallback: build array manually.
        local first=1
        printf '{"worktrees":['
        if [ -d "$base_path" ]; then
            for d in "$base_path"/*/; do
                [ -d "$d" ] || continue
                local feature
                feature="$(basename "$d")"
                local rel="${d#"$REPO_ROOT/"}"
                rel="${rel%/}"
                local has_manifest="false"
                local manifest_filename
                manifest_filename="$(_worktree_config_value manifest_filename)"
                [ -f "$d/$manifest_filename" ] && has_manifest="true"
                [ $first -eq 0 ] && printf ","
                printf '{"path":"%s","branch":"%s","has_manifest":%s,"feature":"%s"}' \
                    "$(_json_escape "$rel")" \
                    "$(_json_escape "$feature")" \
                    "$has_manifest" \
                    "$(_json_escape "$feature")"
                first=0
            done
        fi
        printf '],"ok":true}\n'
    fi
}

# ---------------------------------------------------------------------------
# Subcommand: read-manifest
# ---------------------------------------------------------------------------
cmd_read_manifest() {
    local worktree_path=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --worktree-path) worktree_path="$2"; shift 2 ;;
            --help|-h)
                echo "Usage: worktree-utils.sh read-manifest --worktree-path <path>"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$worktree_path" ] || _die "--worktree-path is required"

    # Resolve relative path against REPO_ROOT.
    case "$worktree_path" in
        /*) ;;
        *)  worktree_path="$REPO_ROOT/${worktree_path#./}" ;;
    esac

    local manifest_filename
    manifest_filename="$(_worktree_config_value manifest_filename)"
    local manifest_file="$worktree_path/$manifest_filename"

    if [ ! -f "$manifest_file" ]; then
        _die "Manifest not found: $manifest_file"
    fi

    if _have_jq; then
        jq '.' "$manifest_file"
    else
        cat "$manifest_file"
    fi
}

# ---------------------------------------------------------------------------
# Subcommand: finish-feature
# Obra-aligned provenance-based cleanup:
#  1. Read manifest
#  2. Delete all task branches listed in manifest
#  3. Delete feature worktree via git worktree remove
#  4. Delete feature branch from primary checkout
#  5. Refuse to do any of this if manifest is missing (unless --force)
# ---------------------------------------------------------------------------
cmd_finish_feature() {
    local feature=""
    local keep_branch=false
    local force=false

    while [ $# -gt 0 ]; do
        case "$1" in
            --feature) feature="$2"; shift 2 ;;
            --keep-branch) keep_branch=true; shift ;;
            --force) force=true; shift ;;
            --help|-h)
                echo "Usage: worktree-utils.sh finish-feature --feature <name> [--keep-branch] [--force]"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$feature" ] || _die "--feature is required"

    local worktree_path
    worktree_path="$(_worktree_path_for "$feature")"
    local manifest_filename
    manifest_filename="$(_worktree_config_value manifest_filename)"
    local manifest_file="$worktree_path/$manifest_filename"

    # Provenance check: refuse to clean up without manifest.
    if [ ! -f "$manifest_file" ] && [ "$force" != "true" ]; then
        _die "No manifest at $manifest_file — refusing to clean up. Use --force to override (will skip task-branch cleanup)"
    fi

    local removed_task_branches=0

    if [ -f "$manifest_file" ] && _have_jq; then
        # Read task branches from manifest and delete them.
        while IFS= read -r branch; do
            [ -z "$branch" ] && continue
            if git -C "$worktree_path" show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
                if git -C "$worktree_path" branch -D "$branch" >&2 2>/dev/null; then
                    removed_task_branches=$((removed_task_branches + 1))
                fi
            fi
        done < <(jq -r '.task_branches[].branch // empty' "$manifest_file" 2>/dev/null)
    fi

    # Remove the worktree. The manifest file is untracked by design; run a
    # pre-check that filters it from the dirty list. --force is always used
    # after the pre-check (safe because we've verified only the manifest
    # was dirty). Route git's chatter to stderr.
    local worktree_removed=false
    if [ -d "$worktree_path" ]; then
        local dirty
        dirty="$(git -C "$worktree_path" status --porcelain 2>/dev/null | grep -v "^?? $manifest_filename\$" | grep -v "^.. $manifest_filename\$" || true)"
        if [ -n "$dirty" ] && [ "$force" != "true" ]; then
            _die "Worktree has uncommitted changes (excluding the manifest, which is ignored):
$dirty
Use --force to override."
        fi
        git -C "$REPO_ROOT" worktree remove --force "$worktree_path" >&2 2>/dev/null \
            && worktree_removed=true
    fi

    # Delete the feature branch from the primary checkout (unless --keep-branch).
    local branch_deleted=false
    if [ "$keep_branch" != "true" ]; then
        if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$feature" 2>/dev/null; then
            git -C "$REPO_ROOT" branch -D "$feature" >&2 2>/dev/null && branch_deleted=true
        fi
    fi

    # Clean up manifest if it survived (worktree_path is gone after removal).
    # The manifest lives inside the worktree so it's already gone.

    local rel_path="${worktree_path#"$REPO_ROOT/"}"
    if _have_jq; then
        jq -cn \
            --argjson task_branches_removed "$removed_task_branches" \
            --argjson worktree_removed "$worktree_removed" \
            --argjson branch_deleted "$branch_deleted" \
            --argjson keep_branch "$keep_branch" \
            --argjson force "$force" \
            '{task_branches_removed:$task_branches_removed, worktree_removed:$worktree_removed, branch_deleted:$branch_deleted, keep_branch:$keep_branch, force:$force, ok:true}'
    else
        printf '{"task_branches_removed":%d,"worktree_removed":%s,"branch_deleted":%s,"keep_branch":%s,"force":%s,"ok":true}\n' \
            "$removed_task_branches" \
            "$worktree_removed" \
            "$branch_deleted" \
            "$keep_branch" \
            "$force"
    fi
}

# ---------------------------------------------------------------------------
# Subcommand: merge-task-branch
# Merges a completed task branch back into the feature branch with --no-ff.
# On conflict, reports machine-readable conflict state.
# ---------------------------------------------------------------------------
cmd_merge_task_branch() {
    local feature=""
    local task_id=""
    local delegate_conflicts=false

    while [ $# -gt 0 ]; do
        case "$1" in
            --feature) feature="$2"; shift 2 ;;
            --task-id) task_id="$2"; shift 2 ;;
            --delegate-conflicts) delegate_conflicts=true; shift ;;
            --help|-h)
                echo "Usage: worktree-utils.sh merge-task-branch --feature <name> --task-id <TNNN> [--delegate-conflicts]"
                exit 0
                ;;
            *) _die "Unknown arg: $1" ;;
        esac
    done

    [ -n "$feature" ] || _die "--feature is required"
    [ -n "$task_id" ] || _die "--task-id is required"

    local worktree_path
    worktree_path="$(_worktree_path_for "$feature")"

    if [ ! -d "$worktree_path" ]; then
        _die "Feature worktree does not exist: $worktree_path"
    fi

    local manifest_filename
    manifest_filename="$(_worktree_config_value manifest_filename)"
    local manifest_file="$worktree_path/$manifest_filename"

    # Resolve task branch from manifest.
    local task_branch=""
    if [ -f "$manifest_file" ] && _have_jq; then
        task_branch="$(jq -r --arg id "$task_id" '.task_branches[] | select(.id == $id) | .branch' "$manifest_file" 2>/dev/null | head -n1)"
    fi

    if [ -z "$task_branch" ]; then
        _die "Task $task_id not found in manifest"
    fi

    # Ensure feature branch is checked out in the worktree.
    local current_branch
    current_branch="$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
    if [ "$current_branch" != "$feature" ]; then
        git -C "$worktree_path" checkout "$feature" >&2 2>/dev/null \
            || _die "Failed to checkout feature branch $feature"
    fi

    # Merge with --no-ff.
    local merge_output=""
    local merge_rc=0
    merge_output="$(git -C "$worktree_path" merge --no-ff "$task_branch" -m "Merge task $task_id into $feature" 2>&1)" || merge_rc=$?

    local conflict_files=""
    local has_conflict=false
    if [ "$merge_rc" -ne 0 ]; then
        has_conflict=true
        conflict_files="$(git -C "$worktree_path" diff --name-only --diff-filter=U 2>/dev/null | tr '\n' ' ' | sed 's/ $//')"
    fi

    # On conflict, abort merge and report.
    if [ "$has_conflict" = "true" ]; then
        git -C "$worktree_path" merge --abort 2>/dev/null || true
        if _have_jq; then
            jq -cn \
                --arg task_id "$task_id" \
                --arg task_branch "$task_branch" \
                --arg feature "$feature" \
                --argjson has_conflict true \
                --arg conflict_files "$conflict_files" \
                --argjson delegate "$delegate_conflicts" \
                --arg merge_output "$merge_output" \
                '{
                    task_id: $task_id,
                    task_branch: $task_branch,
                    feature: $feature,
                    merged: false,
                    has_conflict: true,
                    conflict_files: $conflict_files,
                    delegate_conflicts: $delegate,
                    merge_output: $merge_output,
                    ok: true
                }'
        else
            printf '{"task_id":"%s","task_branch":"%s","feature":"%s","merged":false,"has_conflict":true,"conflict_files":"%s","delegate_conflicts":%s,"merge_output":"%s","ok":true}\n' \
                "$(_json_escape "$task_id")" \
                "$(_json_escape "$task_branch")" \
                "$(_json_escape "$feature")" \
                "$(_json_escape "$conflict_files")" \
                "$delegate_conflicts" \
                "$(_json_escape "$merge_output")"
        fi
        return 0
    fi

    # Remove task branch from git and manifest.
    git -C "$worktree_path" branch -d "$task_branch" >&2 2>/dev/null || true

    if [ -f "$manifest_file" ] && _have_jq; then
        local tmpf
        tmpf="$(mktemp)"
        jq --arg id "$task_id" \
            '.task_branches |= map(select(.id != $id))' "$manifest_file" > "$tmpf" \
            && mv "$tmpf" "$manifest_file"
    fi

    local feature_tip
    feature_tip="$(git -C "$worktree_path" rev-parse --short HEAD 2>/dev/null || echo "")"

    if _have_jq; then
        jq -cn \
            --arg task_id "$task_id" \
            --arg task_branch "$task_branch" \
            --arg feature "$feature" \
            --arg feature_tip "$feature_tip" \
            --argjson has_conflict false \
            '{
                task_id: $task_id,
                task_branch: $task_branch,
                feature: $feature,
                merged: true,
                has_conflict: false,
                feature_tip: $feature_tip,
                ok: true
            }'
    else
        printf '{"task_id":"%s","task_branch":"%s","feature":"%s","merged":true,"has_conflict":false,"feature_tip":"%s","ok":true}\n' \
            "$(_json_escape "$task_id")" \
            "$(_json_escape "$task_branch")" \
            "$(_json_escape "$feature")" \
            "$(_json_escape "$feature_tip")"
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
    create-feature-worktree)   cmd_create_feature_worktree   "$@" ;;
    remove-feature-worktree)   cmd_remove_feature_worktree   "$@" ;;
    create-task-branch)        cmd_create_task_branch        "$@" ;;
    remove-task-branch)        cmd_remove_task_branch        "$@" ;;
    merge-task-branch)         cmd_merge_task_branch         "$@" ;;
    is-in-worktree)            cmd_is_in_worktree            "$@" ;;
    list-worktrees)            cmd_list_worktrees            "$@" ;;
    read-manifest)             cmd_read_manifest             "$@" ;;
    finish-feature)            cmd_finish_feature            "$@" ;;
    -h|--help|help)            _usage; exit 0 ;;
    *) _err "Unknown subcommand: $SUBCOMMAND"; _usage; exit 1 ;;
esac
