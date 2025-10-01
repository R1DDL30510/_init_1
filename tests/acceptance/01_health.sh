#!/bin/sh
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ENV_FILE="${SHS_ENV_FILE:-${ROOT}/.env.local}"
TRACE_ID="health-$(date -u +%Y-%m-%dT%H-%M-%SZ)"
LOG="${ROOT}/logs/shs.jsonl"

log() {
  printf '{"trace_id":"%s","event":"%s","detail":"%s"}\n' "$TRACE_ID" "$1" "$2" >> "$LOG"
}

if ! docker compose --env-file "$ENV_FILE" ps proxy >/dev/null 2>&1; then
  log skip "proxy not running"
  exit 0
fi

domain=$(grep -E '^SHS_DOMAIN=' "$ENV_FILE" | cut -d'=' -f2)
port=$(grep -E '^SHS_PROXY_PORT=' "$ENV_FILE" | cut -d'=' -f2)
: "${domain:=localhost}"
: "${port:=8443}"

url="https://${domain}:${port}/healthz"
if curl --fail --silent --cacert "${ROOT}/secrets/tls/ca.crt" "$url" >/dev/null; then
  log pass "healthz ok"
  exit 0
fi
log fail "healthz unreachable"
exit 1
