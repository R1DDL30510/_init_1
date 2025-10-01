#!/bin/sh
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ENV_FILE="${SHS_ENV_FILE:-${ROOT}/.env.local}"
TRACE_ID="ingest-$(date -u +%Y-%m-%dT%H-%M-%SZ)"
LOG="${ROOT}/logs/shs.jsonl"
SAMPLES_DIR="${ROOT}/tests/samples"

log() {
  printf '{"trace_id":"%s","event":"%s","detail":"%s"}\n' "$TRACE_ID" "$1" "$2" >> "$LOG"
}

services="proxy n8n postgres minio ocr tei reranker"
for svc in $services; do
  if ! docker compose --env-file "$ENV_FILE" ps "$svc" >/dev/null 2>&1; then
    log skip "$svc not running"
    exit 0
  fi
done

watch_path=$(grep -E '^WATCH_PATH=' "$ENV_FILE" | cut -d'=' -f2)
: "${watch_path:=./ingest}"
case $watch_path in
  /*) ;;
  *) watch_path="$ROOT/$watch_path" ;;
esac
mkdir -p "$watch_path"

hashes=""
for file in "$SAMPLES_DIR"/*; do
  base=$(basename "$file")
  cp "$file" "$watch_path/$base"
  hash=$(sha256sum "$watch_path/$base" | awk '{print $1}')
  hashes="$hashes $hash"
  log enqueue "$base queued"
done

for hash in $hashes; do
  attempt=0
  while [ $attempt -lt 30 ]; do
    if docker compose --env-file "$ENV_FILE" exec -T postgres psql -U "${POSTGRES_USER:-shs_app}" -d "${POSTGRES_DB:-shs}" -Atc "SELECT 1 FROM documents WHERE sha256='${hash}'" | grep -q 1; then
      log db "document ${hash} present"
      break
    fi
    attempt=$((attempt + 1))
    sleep 2
  done
  if [ $attempt -eq 30 ]; then
    log fail "document ${hash} missing"
    exit 1
  fi

done

log pass "ingest pipeline ok"
exit 0
