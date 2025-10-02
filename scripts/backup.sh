#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/.env.local"
BACKUP_DIR="${ROOT}/backups"
STAMP="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
TRACE_ID="backup-${STAMP}"
TEMP_PRE="/tmp/shs-prearchive.tar"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "${TRACE_ID} missing env file" >&2
  exit 1
fi
if grep -q '\*\*\*FILL\*\*\*' "${ENV_FILE}"; then
  echo "${TRACE_ID} env placeholders present" >&2
  exit 1
fi

mkdir -p "${BACKUP_DIR}"
ARCHIVE="${BACKUP_DIR}/shs-${STAMP}.tar.zst"

# shellcheck source=/dev/null
source "${ENV_FILE}"

cat <<JSON >> "${ROOT}/logs/shs.jsonl"
{"trace_id":"${TRACE_ID}","event":"backup.start","timestamp":"${STAMP}"}
JSON

docker compose --env-file "${ENV_FILE}" exec -T postgres pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB:-shs}" | zstd -q > "${BACKUP_DIR}/postgres-${STAMP}.sql.zst"

tar --sort=name --mtime="${STAMP}" --owner=0 --group=0 --numeric-owner \
  -cf "${TEMP_PRE}" -C "${ROOT}" secrets/tls logs/shs.jsonl VERSIONS.lock \
  -C "${BACKUP_DIR}" "postgres-${STAMP}.sql.zst"

if docker compose --env-file "${ENV_FILE}" exec -T minio which mc >/dev/null 2>&1; then
  MINIO_STAGE="$(mktemp -d)"
  docker compose --env-file "${ENV_FILE}" exec -T minio /bin/sh -c "mc alias set local https://minio:9000 \"${MINIO_ROOT_USER}\" \"${MINIO_ROOT_PASSWORD}\" --api s3v4 && mc mirror --json local/shs /tmp/minio-backup" >/tmp/minio-mirror.log
  docker compose --env-file "${ENV_FILE}" cp minio:/tmp/minio-backup "${MINIO_STAGE}"
  tar --append -f "${TEMP_PRE}" -C "${MINIO_STAGE}" minio-backup
  rm -rf "${MINIO_STAGE}"
  docker compose --env-file "${ENV_FILE}" exec -T minio rm -rf /tmp/minio-backup
else
  echo "${TRACE_ID} skipping minio mirror (mc missing)" >&2
fi

zstd -q < "${TEMP_PRE}" > "${ARCHIVE}"
rm -f "${TEMP_PRE}"

cat <<JSON >> "${ROOT}/logs/shs.jsonl"
{"trace_id":"${TRACE_ID}","event":"backup.complete","timestamp":"${STAMP}","artifact":"${ARCHIVE}"}
JSON

echo "backup archive at ${ARCHIVE}"
