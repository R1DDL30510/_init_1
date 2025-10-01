#!/bin/sh
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ENV_FILE="${SHS_ENV_FILE:-${ROOT}/.env.local}"
TRACE_ID="sql-$(date -u +%Y-%m-%dT%H-%M-%SZ)"
LOG="${ROOT}/logs/shs.jsonl"

log() {
  printf '{"trace_id":"%s","event":"%s","detail":"%s"}\n' "$TRACE_ID" "$1" "$2" >> "$LOG"
}

services="proxy postgres"
for svc in $services; do
  if ! docker compose --env-file "$ENV_FILE" ps "$svc" >/dev/null 2>&1; then
    log skip "$svc not running"
    exit 0
  fi
done

sql='SELECT id, sha256 FROM documents ORDER BY created_at DESC LIMIT 5;'
domain=$(grep -E '^SHS_DOMAIN=' "$ENV_FILE" | cut -d'=' -f2)
port=$(grep -E '^SHS_PROXY_PORT=' "$ENV_FILE" | cut -d'=' -f2)
: "${domain:=localhost}"
: "${port:=8443}"

response=$(curl --silent --fail --cacert "${ROOT}/secrets/tls/ca.crt" \
  -H "X-Trace-Id: ${TRACE_ID}" \
  -H 'Content-Type: application/json' \
  -d "{\"sql\":\"${sql}\"}" \
  "https://${domain}:${port}/api/sql_query") || {
    log fail "sql query request failed"
    exit 1
  }

rows=$(printf '%s' "$response" | jq '.rows | length')
if [ "$rows" -ge 0 ]; then
  log pass "sql rows ${rows}"
  exit 0
fi
log fail "sql response invalid"
exit 1
