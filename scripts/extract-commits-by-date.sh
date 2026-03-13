#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
WORKSPACE_DIR="/Users/matiasromera/Worskspace"
OUTPUT_FILE="data/workspace-commit-days-extraction.json"
EXCLUDE_REPO="bitbucket-migration-history"

# --- Get author email ---
AUTHOR_EMAIL=$(git config --global user.email)
if [[ -z "$AUTHOR_EMAIL" ]]; then
  echo "Error: git config --global user.email is not set" >&2
  exit 1
fi
echo "Author email: $AUTHOR_EMAIL" >&2

# --- Temp file for all dates ---
TMP_DATES=$(mktemp)
trap 'rm -f "$TMP_DATES"' EXIT

# --- Find all git repos and extract commit dates ---
while IFS= read -r git_dir; do
  repo_dir=$(dirname "$git_dir")
  repo_name=$(basename "$repo_dir")

  if [[ "$repo_name" == "$EXCLUDE_REPO" ]]; then
    echo "Skipping: $repo_name" >&2
    continue
  fi

  echo "Processing: $repo_name" >&2
  git -C "$repo_dir" log --author="$AUTHOR_EMAIL" --format="%ad" --date=short --all 2>/dev/null >> "$TMP_DATES" || true
done < <(find "$WORKSPACE_DIR" -name ".git" -type d -maxdepth 3)

# --- Count commits per date and generate JSON ---
TOTAL=0
{
  echo "["
  first=true
  while read -r count date; do
    TOTAL=$((TOTAL + count))
    if $first; then
      first=false
    else
      echo ","
    fi
    printf '  { "date": "%s", "quantity": %d }' "$date" "$count"
  done < <(sort "$TMP_DATES" | uniq -c | awk '{print $1, $2}')
  echo ""
  echo "]"
} > "$OUTPUT_FILE"

echo "Done. Total commits: $TOTAL, output: $OUTPUT_FILE" >&2
