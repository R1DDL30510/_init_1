#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/.env.local"
BACKUP_DIR="${ROOT}/backups"
TRACE_ID="restore-$(date -u +%Y-%m-%dT%H-%M-%SZ)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <archive.tar.zst>" >&2
  exit 1
fi
ARCHIVE="$1"
if [[ ! -f "${ARCHIVE}" ]]; then
  echo "${TRACE_ID} archive not found" >&2
  exit 1
fi
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "${TRACE_ID} missing env file" >&2
  exit 1
fi

source "${ENV_FILE}"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT
unzstd -q < "${ARCHIVE}" | tar -xf - -C "${TEMP_DIR}"

cat <<JSON >> "${ROOT}/logs/shs.jsonl"
{"trace_id":"${TRACE_ID}","event":"restore.start","archive":"${ARCHIVE}"}
JSON

docker compose --env-file "${ENV_FILE}" down --remove-orphans
cp "${TEMP_DIR}/secrets/tls/ca.crt" "${ROOT}/secrets/tls/ca.crt"
cp "${TEMP_DIR}/secrets/tls/ca.key" "${ROOT}/secrets/tls/ca.key"
cp "${TEMP_DIR}/secrets/tls/leaf.pem" "${ROOT}/secrets/tls/leaf.pem"
cp "${TEMP_DIR}/secrets/tls/leaf.key" "${ROOT}/secrets/tls/leaf.key"
cp "${TEMP_DIR}/VERSIONS.lock" "${ROOT}/VERSIONS.lock"
cp "${TEMP_DIR}/logs/shs.jsonl" "${ROOT}/logs/shs.jsonl"

SQL_ZST=$(ls "${TEMP_DIR}"/postgres-*.sql.zst | head -n1)
if [ -z "${SQL_ZST}" ]; then
  echo "${TRACE_ID} missing postgres dump" >&2
  exit 1
fi
unzstd -c "${SQL_ZST}" | docker compose --env-file "${ENV_FILE}" exec -T postgres psql -U "${POSTGRES_USER}" "${POSTGRES_DB:-shs}"

cat <<JSON >> "${ROOT}/logs/shs.jsonl"
{"trace_id":"${TRACE_ID}","event":"restore.complete","archive":"${ARCHIVE}"}
JSON

echo "restore complete"
