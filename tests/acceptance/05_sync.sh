#!/bin/sh
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ENV_FILE="${SHS_ENV_FILE:-${ROOT}/.env.local}"
TRACE_ID="sync-$(date -u +%Y-%m-%dT%H-%M-%SZ)"
LOG="${ROOT}/logs/shs.jsonl"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

mkdir -p "$(dirname "$LOG")"

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

case "$uri" in
  s3://*)
    bucket="$(printf '%s' "$uri" | sed -E 's|^s3://([^/]+)/.*$|\1|')"
    object_key="$(printf '%s' "$uri" | sed -E 's|^s3://[^/]+/||')"
    if [ -z "$bucket" ] || [ -z "$object_key" ]; then
      log fail "invalid s3 uri: $uri"
      exit 1
    fi
    if ! docker compose --env-file "$ENV_FILE" exec -T minio which mc >/dev/null 2>&1; then
      log fail ": Bitte durch Operator verifizieren! mc missing in minio container"
      exit 1
    fi
    docker compose --env-file "$ENV_FILE" exec -T minio /bin/sh -c "mc alias set local https://minio:9000 \"${MINIO_ROOT_USER}\" \"${MINIO_ROOT_PASSWORD}\" --api s3v4 && mc rm --force \"local/${bucket}/${object_key}\"" >/tmp/sync-delete.log 2>&1 || {
      log fail ": Bitte durch Operator verifizieren! unable to delete ${uri}"
      cat /tmp/sync-delete.log >&2
      exit 1
    }
    log change "s3 cleanup ${uri}"
    ;;
  *)
    if [ -f "$uri" ]; then
      rm -f "$uri"
      log change "removed $uri"
    fi
    ;;
esac

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
