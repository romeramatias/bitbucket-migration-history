#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

REPO_PATH=""
DATA_PATH="$PROJECT_ROOT/data/bitbucket-commit-days-extraction.json"
DRY_RUN=false
BATCH_SIZE=500
PUSH_DELAY=5

usage() {
  cat <<EOF
Usage: $(basename "$0") --repo <path> [--data <path>] [--batch <size>] [--delay <secs>] [--dry-run]

Options:
  --repo <path>    Path to the Git repository where commits will be created (required)
  --data <path>    Path to the JSON file (default: data/commit-days.json)
  --batch <size>   Push every N commits (default: 500, 0 = push only at end)
  --delay <secs>   Seconds to wait after each push (default: 5)
  --dry-run        Show what would be done without executing commits
  -h, --help       Show this help message
EOF
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO_PATH="$2"
      shift 2
      ;;
    --data)
      DATA_PATH="$2"
      shift 2
      ;;
    --batch)
      BATCH_SIZE="$2"
      shift 2
      ;;
    --delay)
      PUSH_DELAY="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Error: unknown argument '$1'"
      usage
      ;;
  esac
done

# Validate required params
if [[ -z "$REPO_PATH" ]]; then
  echo "Error: --repo is required"
  usage
fi

# Validate dependencies
for cmd in jq git; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not installed."
    exit 1
  fi
done

# Validate repo path
if [[ ! -d "$REPO_PATH/.git" ]]; then
  echo "Error: '$REPO_PATH' is not a valid Git repository"
  exit 1
fi

# Validate JSON file
if [[ ! -f "$DATA_PATH" ]]; then
  echo "Error: JSON file not found at '$DATA_PATH'"
  exit 1
fi

TOTAL_DAYS=$(jq 'length' "$DATA_PATH")
TOTAL_COMMITS=$(jq '[.[].quantity] | add' "$DATA_PATH")

echo "=== Backfill Commits ==="
echo "Repo:    $REPO_PATH"
echo "Data:    $DATA_PATH"
echo "Days:    $TOTAL_DAYS"
echo "Commits: $TOTAL_COMMITS"
echo "Batch:   $BATCH_SIZE (0 = push at end)"
echo "Delay:   ${PUSH_DELAY}s after each push"
echo "Dry run: $DRY_RUN"
echo "========================"

cd "$REPO_PATH"

GIT_USER=$(git config user.name || echo "not set")
GIT_EMAIL=$(git config user.email || echo "not set")
GIT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "no remote")
SSH_HOST=$(echo "$GIT_REMOTE" | sed -n 's/.*@\([^:]*\):.*/\1/p')
SSH_KEY=$(ssh -G "$SSH_HOST" 2>/dev/null | awk '/^identityfile / {print $2}' | tail -1 || echo "unknown")

echo "=== Git Identity ==="
echo "User:    $GIT_USER"
echo "Email:   $GIT_EMAIL"
echo "Remote:  $GIT_REMOTE"
echo "SSH Key: $SSH_KEY"
echo "====================="
echo ""

CONTRIB_FILE="contributions.md"
COMMITS_DONE=0

for i in $(seq 0 $((TOTAL_DAYS - 1))); do
  DATE=$(jq -r ".[$i].date" "$DATA_PATH")
  QUANTITY=$(jq -r ".[$i].quantity" "$DATA_PATH")
  DAY_NUM=$((i + 1))

  if $DRY_RUN; then
    COMMITS_DONE=$((COMMITS_DONE + QUANTITY))
    echo "[$DAY_NUM/$TOTAL_DAYS] $DATE — $QUANTITY commits (total: $COMMITS_DONE/$TOTAL_COMMITS)"
    if [[ "$BATCH_SIZE" -gt 0 ]] && (( COMMITS_DONE % BATCH_SIZE < QUANTITY )) && (( COMMITS_DONE >= BATCH_SIZE )); then
      BATCH_NUM=$((COMMITS_DONE / BATCH_SIZE))
      echo "  >> [DRY RUN] Would push batch #$BATCH_NUM (at commit $((BATCH_NUM * BATCH_SIZE))/$TOTAL_COMMITS) and wait ${PUSH_DELAY}s"
    fi
    continue
  fi

  if [[ ! -f "$CONTRIB_FILE" ]]; then
    echo "# Contribution History" > "$CONTRIB_FILE"
  fi

  echo "" >> "$CONTRIB_FILE"
  echo "## $DATE" >> "$CONTRIB_FILE"

  for j in $(seq 1 "$QUANTITY"); do
    MINUTE=$(printf "%02d" $(( (j - 1) % 60 )))
    HOUR=$(( 9 + (j - 1) / 60 ))
    COMMIT_DATE="${DATE}T$(printf "%02d" $HOUR):${MINUTE}:00"
    COMMIT_TIME="$(printf "%02d" $HOUR):${MINUTE}:00"

    echo "- \`$COMMIT_TIME\` migrated from bitbucket" >> "$CONTRIB_FILE"

    git add "$CONTRIB_FILE"
    GIT_AUTHOR_DATE="$COMMIT_DATE" GIT_COMMITTER_DATE="$COMMIT_DATE" \
      git commit -m "chore: migrate bitbucket contribution $COMMIT_DATE" --quiet

    COMMITS_DONE=$((COMMITS_DONE + 1))

    if [[ "$BATCH_SIZE" -gt 0 ]] && (( COMMITS_DONE % BATCH_SIZE == 0 )); then
      BATCH_NUM=$((COMMITS_DONE / BATCH_SIZE))
      echo "  >> Pushing batch #$BATCH_NUM ($COMMITS_DONE/$TOTAL_COMMITS)..."
      git push --quiet
      echo "  >> Waiting ${PUSH_DELAY}s before next batch..."
      sleep "$PUSH_DELAY"
    fi
  done

  echo "[$DAY_NUM/$TOTAL_DAYS] $DATE — $QUANTITY commits (total: $COMMITS_DONE/$TOTAL_COMMITS)"
done

TOTAL_PUSHES=$(( BATCH_SIZE > 0 ? (COMMITS_DONE / BATCH_SIZE) + 1 : 1 ))

echo ""
echo "Done! $COMMITS_DONE commits created in $TOTAL_PUSHES pushes."

if ! $DRY_RUN; then
  echo "Pushing remaining commits..."
  git push
  echo "Push complete."
fi
