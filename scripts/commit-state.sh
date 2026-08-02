#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${HERMES_STATE_DIR:-hermes-state}"
SOURCE="$HOME/.hermes"

mkdir -p "$STATE_DIR"
rsync -a --delete \
  --exclude 'hermes-agent' \
  --exclude '.env' \
  --exclude '.env.example' \
  --exclude 'auth' \
  --exclude 'whatsapp' \
  --exclude 'bin' \
  --exclude 'logs' \
  --exclude 'checkpoints' \
  --exclude 'venvs' \
  --exclude '*.pyc' \
  "$SOURCE/" "$STATE_DIR/"
printf '.env\nauth/\nwhatsapp/\n' > "$STATE_DIR/.gitignore"

git config user.name "hermes-bot"
git config user.email "hermes-bot@users.noreply.github.com"
git add "$STATE_DIR"
if git diff --cached --quiet; then
  echo "No state changes"
else
  git commit -m "$1"
  git push
  echo "State committed and pushed"
fi
