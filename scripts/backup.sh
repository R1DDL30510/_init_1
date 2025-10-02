#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/.env.local"
BACKUP_DIR="${ROOT}/backups"
STAMP="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
TRACE_ID="backup-${STAMP}"
TEMP_PRE="/tmp/shs-prearchive.tar"
AGE_RECIPIENTS_FILE_ENV="${BACKUP_AGE_RECIPIENTS_FILE:-}"
AGE_RECIPIENTS_ENV="${BACKUP_AGE_RECIPIENTS:-}"

if ! command -v age >/dev/null 2>&1; then
  echo "${TRACE_ID} missing age binary for encryption" >&2
  echo "${TRACE_ID} configure age on the host and retry. : Bitte durch Operator verifizieren!" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "${TRACE_ID} missing env file" >&2
  exit 1
fi
if grep -q '\*\*\*FILL\*\*\*' "${ENV_FILE}"; then
  echo "${TRACE_ID} env placeholders present" >&2
  exit 1
fi

mkdir -p "${BACKUP_DIR}"
PLAINTEXT_ARCHIVE="${BACKUP_DIR}/shs-${STAMP}.tar.zst"
ARCHIVE="${PLAINTEXT_ARCHIVE}.age"

# shellcheck source=/dev/null
source "${ENV_FILE}"

mkdir -p "${ROOT}/logs"

cat <<JSON >> "${ROOT}/logs/shs.jsonl"
{"trace_id":"${TRACE_ID}","event":"backup.start","timestamp":"${STAMP}"}
JSON

docker compose --env-file "${ENV_FILE}" exec -T postgres pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB:-shs}" | zstd -q > "${BACKUP_DIR}/postgres-${STAMP}.sql.zst"

tar --sort=name --mtime="${STAMP}" --owner=0 --group=0 --numeric-owner \
  -cf "${TEMP_PRE}" -C "${ROOT}" secrets/tls logs/shs.jsonl locks/VERSIONS.lock \
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

zstd -q < "${TEMP_PRE}" > "${PLAINTEXT_ARCHIVE}"
rm -f "${TEMP_PRE}"

RECIPIENTS_FILE="$(mktemp)"
cleanup_recipients() {
  rm -f "${RECIPIENTS_FILE}"
}
trap cleanup_recipients EXIT

if [[ -n "${AGE_RECIPIENTS_FILE_ENV}" ]]; then
  if [[ ! -f "${AGE_RECIPIENTS_FILE_ENV}" ]]; then
    echo "${TRACE_ID} age recipients file ${AGE_RECIPIENTS_FILE_ENV} missing" >&2
    echo "${TRACE_ID} supply BACKUP_AGE_RECIPIENTS_FILE before retry. : Bitte durch Operator verifizieren!" >&2
    exit 1
  fi
  grep -v '^[[:space:]]*$' "${AGE_RECIPIENTS_FILE_ENV}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' > "${RECIPIENTS_FILE}"
fi

if [[ -z "${AGE_RECIPIENTS_FILE_ENV}" ]]; then
  if [[ -z "${AGE_RECIPIENTS_ENV}" ]]; then
    echo "${TRACE_ID} no age recipients configured" >&2
    echo "${TRACE_ID} set BACKUP_AGE_RECIPIENTS or BACKUP_AGE_RECIPIENTS_FILE. : Bitte durch Operator verifizieren!" >&2
    exit 1
  fi
  IFS=',' read -r -a RECIPIENT_ARRAY <<< "${AGE_RECIPIENTS_ENV}"
  : > "${RECIPIENTS_FILE}"
  for recipient in "${RECIPIENT_ARRAY[@]}"; do
    trimmed="$(echo "${recipient}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    if [[ -n "${trimmed}" ]]; then
      printf '%s\n' "${trimmed}" >> "${RECIPIENTS_FILE}"
    fi
  done
fi

if [[ ! -s "${RECIPIENTS_FILE}" ]]; then
  echo "${TRACE_ID} no valid age recipients resolved" >&2
  echo "${TRACE_ID} update BACKUP_AGE_RECIPIENTS(_FILE). : Bitte durch Operator verifizieren!" >&2
  exit 1
fi

age --encrypt --output "${ARCHIVE}" --recipients-file "${RECIPIENTS_FILE}" "${PLAINTEXT_ARCHIVE}"
shred --remove "${PLAINTEXT_ARCHIVE}" 2>/dev/null || rm -f "${PLAINTEXT_ARCHIVE}"

cat <<JSON >> "${ROOT}/logs/shs.jsonl"
{"trace_id":"${TRACE_ID}","event":"backup.complete","timestamp":"${STAMP}","artifact":"${ARCHIVE}"}
JSON

echo "backup archive at ${ARCHIVE}"
