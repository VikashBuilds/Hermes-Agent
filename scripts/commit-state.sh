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
  --exclude 'auth.json' \
  --exclude 'auth.lock' \
  --exclude 'whatsapp' \
  --exclude 'bin' \
  --exclude 'logs' \
  --exclude 'checkpoints' \
  --exclude 'venvs' \
  --exclude '*.pyc' \
  --exclude 'gateway.pid' \
  --exclude 'gateway.lock' \
  --exclude 'stop-heartbeat' \
  --exclude 'ticker_heartbeat' \
  "$SOURCE/" "$STATE_DIR/"
printf '.env\n.env.example\nauth/\nauth.json\nauth.lock\nwhatsapp/\ngateway.pid\ngateway.lock\nstop-heartbeat\nticker_heartbeat\n' > "$STATE_DIR/.gitignore"

git config user.name "hermes-bot"
git config user.email "hermes-bot@users.noreply.github.com"
git add "$STATE_DIR"
if git diff --cached --quiet; then
  echo "No state changes"
else
  git commit -m "$1"
  if git push; then
    echo "State committed and pushed"
  else
    echo "Push rejected - syncing with remote and retrying"
    git fetch origin
    if git rebase origin/main; then
      git push
      echo "State committed and pushed after rebase"
    else
      git rebase --abort
      echo "Rebase failed - keeping commit locally; release snapshot is the backup"
    fi
  fi
fi
