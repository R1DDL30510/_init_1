#!/bin/sh
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ENV_FILE="${SHS_ENV_FILE:-${ROOT}/.env.local}"
TRACE_ID="semantic-$(date -u +%Y-%m-%dT%H-%M-%SZ)"
LOG="${ROOT}/logs/shs.jsonl"

log() {
  printf '{"trace_id":"%s","event":"%s","detail":"%s"}\n' "$TRACE_ID" "$1" "$2" >> "$LOG"
}

services="proxy tei reranker postgres"
for svc in $services; do
  if ! docker compose --env-file "$ENV_FILE" ps "$svc" >/dev/null 2>&1; then
    log skip "$svc not running"
    exit 0
  fi
done

question='Describe the security posture of SHS.'
domain=$(grep -E '^SHS_DOMAIN=' "$ENV_FILE" | cut -d'=' -f2)
port=$(grep -E '^SHS_PROXY_PORT=' "$ENV_FILE" | cut -d'=' -f2)
: "${domain:=localhost}"
: "${port:=8443}"

response=$(curl --silent --fail --cacert "${ROOT}/secrets/tls/ca.crt" \
  -H "X-Trace-Id: ${TRACE_ID}" \
  -H 'Content-Type: application/json' \
  -d "{\"query\":\"${question}\",\"top_k\":5}" \
  "https://${domain}:${port}/api/vector_query") || {
    log fail "vector query request failed"
    exit 1
  }

count=$(printf '%s' "$response" | jq '.citations | length')
if [ "$count" -ge 3 ]; then
  log pass "semantic citations ${count}"
  exit 0
fi
log fail "insufficient citations"
exit 1
