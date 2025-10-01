#!/bin/sh
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ENV_FILE="${SHS_ENV_FILE:-${ROOT}/.env.local}"
TRACE_ID="resilience-$(date -u +%Y-%m-%dT%H-%M-%SZ)"
LOG="${ROOT}/logs/shs.jsonl"

log() {
  printf '{"trace_id":"%s","event":"%s","detail":"%s"}\n' "$TRACE_ID" "$1" "$2" >> "$LOG"
}

if ! docker compose --env-file "$ENV_FILE" ps ocr >/dev/null 2>&1; then
  log skip "ocr not running"
  exit 0
fi

log action "stopping ocr"
docker compose --env-file "$ENV_FILE" stop ocr >/dev/null 2>&1 || true
sleep 5
log action "starting ocr"
docker compose --env-file "$ENV_FILE" start ocr >/dev/null 2>&1
sleep 5

status=$(docker compose --env-file "$ENV_FILE" ps --status running | grep -c ocr || true)
if [ "$status" -ge 1 ]; then
  log pass "ocr restarted"
  exit 0
fi
log fail "ocr not running after restart"
exit 1
