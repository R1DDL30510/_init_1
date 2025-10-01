#!/bin/sh
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ENV_FILE="${SHS_ENV_FILE:-${ROOT}/.env.local}"
TRACE_ID="sync-$(date -u +%Y-%m-%dT%H-%M-%SZ)"
LOG="${ROOT}/logs/shs.jsonl"

log() {
  printf '{"trace_id":"%s","event":"%s","detail":"%s"}\n' "$TRACE_ID" "$1" "$2" >> "$LOG"
}

services="n8n postgres minio"
for svc in $services; do
  if ! docker compose --env-file "$ENV_FILE" ps "$svc" >/dev/null 2>&1; then
    log skip "$svc not running"
    exit 0
  fi
done

uri=$(docker compose --env-file "$ENV_FILE" exec -T postgres psql -U "${POSTGRES_USER:-shs_app}" -d "${POSTGRES_DB:-shs}" -Atc "SELECT uri FROM documents WHERE deleted_at IS NULL LIMIT 1")
if [ -z "$uri" ]; then
  log skip "no documents to sync"
  exit 0
fi

if [ -f "$uri" ]; then
  rm -f "$uri"
  log change "removed $uri"
fi

attempt=0
while [ $attempt -lt 20 ]; do
  deleted=$(docker compose --env-file "$ENV_FILE" exec -T postgres psql -U "${POSTGRES_USER:-shs_app}" -d "${POSTGRES_DB:-shs}" -Atc "SELECT deleted_at IS NOT NULL FROM documents WHERE uri='${uri}'")
  if echo "$deleted" | grep -q t; then
    log pass "sync marked ${uri} deleted"
    exit 0
  fi
  sleep 3
  attempt=$((attempt + 1))
done

log fail "sync did not mark ${uri}"
exit 1
