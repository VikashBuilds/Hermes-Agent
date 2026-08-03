#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${HERMES_STATE_DIR:-hermes-state}"
SOURCE="$HOME/.hermes"
REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY not set}"
RUN_ID="${GITHUB_RUN_ID:-local}"
MESSAGE="${1:-save}"

ts=$(date -u +%Y%m%dT%H%M%SZ)
tag="hermes-state-${RUN_ID}-${ts}"

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

archive="/tmp/${tag}.tar.gz"
enc="${archive}.enc"

tar -czf "$archive" -C . "$STATE_DIR"
openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
  -pass env:STATE_ENCRYPTION_KEY \
  -in "$archive" -out "$enc"

gh release create "$tag" "$enc" \
  --repo "$REPO" \
  --title "Hermes state $ts" \
  --notes "Encrypted snapshot of ~/.hermes (memory, sessions, skills, cron) - $MESSAGE. Kept forever."

size=$(du -h "$enc" | cut -f1)
rm -f "$archive" "$enc"
echo "Released encrypted snapshot $tag ($size)"
