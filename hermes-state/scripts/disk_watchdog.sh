#!/usr/bin/env bash
# Disk watchdog — silent unless disk usage exceeds threshold.
# Designed for cron with --no-agent: empty stdout = silent run, no delivery.
THRESHOLD=85
ROOT_USAGE=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')
HOME_USAGE=$(df -P "$HOME" | awk 'NR==2 {gsub("%","",$5); print $5}')
ALERT=0
[ "${ROOT_USAGE:-0}" -ge "$THRESHOLD" ] && ALERT=1
[ "${HOME_USAGE:-0}" -ge "$THRESHOLD" ] && ALERT=1
if [ "$ALERT" -eq 1 ]; then
  echo "WARNING: disk usage high (threshold ${THRESHOLD}%)"
  df -h / "$HOME"
  exit 0
fi
exit 0
