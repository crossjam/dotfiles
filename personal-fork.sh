#!/usr/bin/env bash
set -euo pipefail

# personal-fork.sh
#
# Usage:
#   personal-fork.sh <source_repo> [--owner <target_owner>] [--visibility public|private|internal] [--protocol ssh|https] [--rename <new_name>]
#
# Examples:
#   personal-fork.sh https://github.com/org/project.git
#   personal-fork.sh org/project --owner my-username --visibility private
#   personal-fork.sh org/project --rename project-fork --protocol ssh
#
# What it does:
#   1. Clone the source repo
#   2. Rename 'origin' → 'upstream'
#   3. Create a new repo under your account (same name as source, or --rename)
#   4. Add a new 'origin' remote pointing to your personal repo
#   5. Push all branches and tags

usage() {
  echo "Usage: $0 <source_repo> [--owner <target_owner>] [--visibility public|private|internal] [--protocol ssh|https] [--rename <new_name>]" >&2
  exit 1
}

# --- Sanity checks ---
command -v gh >/dev/null 2>&1 || { echo "Error: 'gh' CLI required"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Error: 'git' required"; exit 1; }

[[ $# -lt 1 ]] && usage

SOURCE_REPO="$1"
shift

TARGET_OWNER=""
VISIBILITY="private"
PROTOCOL=""
RENAME_TO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) TARGET_OWNER="${2:-}"; shift 2 ;;
    --visibility) VISIBILITY="${2:-}"; shift 2 ;;
    --protocol) PROTOCOL="${2:-}"; shift 2 ;;
    --rename) RENAME_TO="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1" >&2; usage ;;
  esac
done

# --- Authentication ---
if ! gh auth status >/dev/null 2>&1; then
  echo "Error: please run 'gh auth login' first." >&2
  exit 1
fi

# --- Determine target owner (your username) ---
if [[ -z "$TARGET_OWNER" ]]; then
  TARGET_OWNER="$(gh api user -q .login)"
fi

# --- Extract repo name from source repo string ---
parse_repo_name() {
  local input="$1"
  local path=""
  if [[ "$input" =~ ^git@github\.com:(.+)\.git$ ]]; then
    path="${BASH_REMATCH[1]}"
  elif [[ "$input" =~ ^git@github\.com:(.+)$ ]]; then
    path="${BASH_REMATCH[1]}"
  elif [[ "$input" =~ ^https?://github\.com/(.+)\.git$ ]]; then
    path="${BASH_REMATCH[1]}"
  elif [[ "$input" =~ ^https?://github\.com/(.+)$ ]]; then
    path="${BASH_REMATCH[1]}"
  else
    path="$input"
  fi
  echo "${path##*/}" | sed 's/\.git$//'
}

REPO_NAME="$(parse_repo_name "$SOURCE_REPO")"
TARGET_REPO_NAME="${RENAME_TO:-$REPO_NAME}"

echo "🔹 Cloning source repo: $SOURCE_REPO"
git clone "$SOURCE_REPO"
cd "$REPO_NAME"

echo "🔹 Renaming 'origin' → 'upstream'"
git remote rename origin upstream

# --- Determine protocol for new origin ---
if [[ -z "$PROTOCOL" ]]; then
  PROTOCOL="$(gh config get git_protocol 2>/dev/null || true)"
  [[ -z "$PROTOCOL" ]] && PROTOCOL="https"
fi

TARGET_FULL="${TARGET_OWNER}/${TARGET_REPO_NAME}"

# --- Create the new personal repo ---
if gh repo view "$TARGET_FULL" >/dev/null 2>&1; then
  echo "ℹ️ Repo '$TARGET_FULL' already exists on GitHub — skipping creation."
else
  echo "🔹 Creating repo '$TARGET_FULL' (visibility: $VISIBILITY)"
  gh repo create "$TARGET_FULL" --"$VISIBILITY" \
    --description "Personal fork of $SOURCE_REPO" \
    --disable-issues=false --disable-wiki=false
fi

# --- Add or set the new origin remote ---
if [[ "$PROTOCOL" == "ssh" ]]; then
  NEW_ORIGIN_URL="git@github.com:${TARGET_FULL}.git"
else
  NEW_ORIGIN_URL="https://github.com/${TARGET_FULL}.git"
fi

if git remote get-url origin >/dev/null 2>&1; then
  echo "🔹 Setting 'origin' URL → $NEW_ORIGIN_URL"
  git remote set-url origin "$NEW_ORIGIN_URL"
else
  echo "🔹 Adding new remote 'origin' → $NEW_ORIGIN_URL"
  git remote add origin "$NEW_ORIGIN_URL"
fi

# --- Push branches and tags ---
echo "🔹 Pushing all branches..."
git push -u origin --all

echo "🔹 Pushing all tags..."
git push -u origin --tags

echo "✅ Done. Local remotes:"
git remote -v
