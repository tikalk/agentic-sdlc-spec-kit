#!/usr/bin/env bash

set -e

JSON_MODE=false
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON_MODE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Source common functions
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/git-common.sh"

REPO_ROOT=$(get_repo_root)
cd "$REPO_ROOT"

# Check if this is a git repo
if ! has_git; then
  if $JSON_MODE; then
    echo '{"error": "Not a git repository. Workspace must be initialized with git."}'
  else
    echo "Error: Not a git repository. Workspace must be initialized with git." >&2
  fi
  exit 1
fi

# Arrays to track results
declare -a REGISTERED_REPOS=()
declare -a SKIPPED_REPOS=()
declare -a ERROR_REPOS=()

# Function to check if a path is already a submodule
is_submodule() {
  local path="$1"
  git config --file .gitmodules --get-regexp "^submodule\\..*\\.path$" 2>/dev/null | grep -q "^[^ ]* $path$"
}

# Function to get remote URL from a child repo
get_remote_url() {
  local repo_path="$1"
  git -C "$repo_path" remote get-url origin 2>/dev/null || echo ""
}

# Discover child repos at depth 1
discover_child_repos() {
  local discovered=()
  
  for dir in "$REPO_ROOT"/*/; do
    # Skip if not a directory
    [[ -d "$dir" ]] || continue
    
    local basename=$(basename "$dir")
    
    # Skip common non-project directories
    case "$basename" in
      .specify|.git|node_modules|__pycache__|.venv|venv|dist|build|target|.idea|.vscode)
        continue
        ;;
    esac
    
    # Check if it has a .git directory
    if [[ -d "$dir/.git" ]] || [[ -f "$dir/.git" ]]; then
      discovered+=("$basename")
    fi
  done
  
  echo "${discovered[@]}"
}

# Main processing
CHILD_REPOS=$(discover_child_repos)

for repo_name in $CHILD_REPOS; do
  repo_path="$REPO_ROOT/$repo_name"
  
  # Check if already a submodule
  if is_submodule "$repo_name"; then
    SKIPPED_REPOS+=("$repo_name: already a submodule")
    continue
  fi
  
  # Get remote URL
  remote_url=$(get_remote_url "$repo_path")
  
  if [[ -z "$remote_url" ]]; then
    ERROR_REPOS+=("$repo_name: no remote URL configured")
    continue
  fi
  
  # Register as submodule
  if [[ "$DRY_RUN" == true ]]; then
    REGISTERED_REPOS+=("$repo_name → $remote_url [DRY RUN]")
  else
    if git submodule add "$remote_url" "$repo_name" 2>/dev/null; then
      REGISTERED_REPOS+=("$repo_name → $remote_url")
    else
      ERROR_REPOS+=("$repo_name: failed to add submodule")
    fi
  fi
done

# Commit changes if not dry run and we registered repos
if [[ "$DRY_RUN" == false ]] && [[ ${#REGISTERED_REPOS[@]} -gt 0 ]]; then
  if [[ -f ".gitmodules" ]]; then
    git add .gitmodules 2>/dev/null || true
    # Try to commit, but don't fail if nothing to commit
    git commit -m "[Spec Kit] Register workspace submodules" 2>/dev/null || true
  fi
fi

# Output results
if $JSON_MODE; then
  # Build JSON output
  registered_json="["
  first=1
  for repo in "${REGISTERED_REPOS[@]}"; do
    [[ $first -eq 0 ]] && registered_json+=","
    registered_json+=$(printf '"%s"' "$repo")
    first=0
  done
  registered_json+="]"
  
  skipped_json="["
  first=1
  for repo in "${SKIPPED_REPOS[@]}"; do
    [[ $first -eq 0 ]] && skipped_json+=","
    skipped_json+=$(printf '"%s"' "$repo")
    first=0
  done
  skipped_json+="]"
  
  errors_json="["
  first=1
  for repo in "${ERROR_REPOS[@]}"; do
    [[ $first -eq 0 ]] && errors_json+=","
    errors_json+=$(printf '"%s"' "$repo")
    first=0
  done
  errors_json+="]"
  
  cat <<EOF
{
  "DISCOVERED_COUNT": $(($(echo "$CHILD_REPOS" | wc -w))),
  "REGISTERED_COUNT": ${#REGISTERED_REPOS[@]},
  "SKIPPED_COUNT": ${#SKIPPED_REPOS[@]},
  "ERROR_COUNT": ${#ERROR_REPOS[@]},
  "REGISTERED_REPOS": $registered_json,
  "SKIPPED_REPOS": $skipped_json,
  "ERROR_REPOS": $errors_json,
  "DRY_RUN": $([[ "$DRY_RUN" == true ]] && echo "true" || echo "false")
}
EOF
else
  # Text output
  echo "=========================================="
  echo "Workspace Submodule Setup"
  echo "=========================================="
  echo ""
  
  if [[ ${#REGISTERED_REPOS[@]} -gt 0 ]]; then
    echo "Registered (${#REGISTERED_REPOS[@]}):"
    for repo in "${REGISTERED_REPOS[@]}"; do
      echo "  ✓ $repo"
    done
    echo ""
  fi
  
  if [[ ${#SKIPPED_REPOS[@]} -gt 0 ]]; then
    echo "Skipped (${#SKIPPED_REPOS[@]}):"
    for repo in "${SKIPPED_REPOS[@]}"; do
      echo "  - $repo"
    done
    echo ""
  fi
  
  if [[ ${#ERROR_REPOS[@]} -gt 0 ]]; then
    echo "Errors (${#ERROR_REPOS[@]}):"
    for repo in "${ERROR_REPOS[@]}"; do
      echo "  ⚠ $repo"
    done
    echo ""
  fi
  
  if [[ ${#REGISTERED_REPOS[@]} -eq 0 ]] && [[ ${#SKIPPED_REPOS[@]} -eq 0 ]] && [[ ${#ERROR_REPOS[@]} -eq 0 ]]; then
    echo "No child repositories found at depth 1."
    echo ""
  fi
  
  if [[ "$DRY_RUN" == false ]] && [[ ${#REGISTERED_REPOS[@]} -gt 0 ]]; then
    echo "Next steps:"
    echo "  - Team members can clone with: git clone --recursive <workspace-url>"
    echo "  - Or initialize submodules: git submodule update --init"
  fi
fi
