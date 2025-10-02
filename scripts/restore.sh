#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/.env.local"
TRACE_ID="restore-$(date -u +%Y-%m-%dT%H-%M-%SZ)"
AGE_IDENTITIES_FILE_ENV="${BACKUP_AGE_IDENTITIES_FILE:-}"
AGE_IDENTITIES_ENV="${BACKUP_AGE_IDENTITIES:-}"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <archive.tar.zst[.age]>" >&2
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

# shellcheck source=/dev/null
source "${ENV_FILE}"

TEMP_DIR="$(mktemp -d)"
ARCHIVE_WAS_ENCRYPTED=0
cleanup() {
  rm -rf "${TEMP_DIR}"
  if [[ "${ARCHIVE_WAS_ENCRYPTED}" -eq 1 ]]; then
    rm -f "${PLAINTEXT_ARCHIVE:-}"
  fi
  rm -f "${IDENTITIES_FILE:-}"
}
trap cleanup EXIT

PLAINTEXT_ARCHIVE="${ARCHIVE}"
if [[ "${ARCHIVE}" == *.age ]]; then
  if ! command -v age >/dev/null 2>&1; then
    echo "${TRACE_ID} missing age binary for decryption" >&2
    exit 1
  fi

  IDENTITIES_FILE="$(mktemp)"
  if [[ -n "${AGE_IDENTITIES_FILE_ENV}" ]]; then
    if [[ ! -f "${AGE_IDENTITIES_FILE_ENV}" ]]; then
      echo "${TRACE_ID} age identities file ${AGE_IDENTITIES_FILE_ENV} missing" >&2
      echo "${TRACE_ID} set BACKUP_AGE_IDENTITIES_FILE before retry. : Bitte durch Operator verifizieren!" >&2
      exit 1
    fi
    grep -v '^[[:space:]]*$' "${AGE_IDENTITIES_FILE_ENV}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' > "${IDENTITIES_FILE}"
  fi

  if [[ -z "${AGE_IDENTITIES_FILE_ENV}" ]]; then
    if [[ -z "${AGE_IDENTITIES_ENV}" ]]; then
      echo "${TRACE_ID} no age identities configured" >&2
      echo "${TRACE_ID} set BACKUP_AGE_IDENTITIES or BACKUP_AGE_IDENTITIES_FILE. : Bitte durch Operator verifizieren!" >&2
      exit 1
    fi
    IFS=',' read -r -a IDENTITY_ARRAY <<< "${AGE_IDENTITIES_ENV}"
    : > "${IDENTITIES_FILE}"
    for identity in "${IDENTITY_ARRAY[@]}"; do
      trimmed="$(echo "${identity}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      if [[ -n "${trimmed}" ]]; then
        printf '%s\n' "${trimmed}" >> "${IDENTITIES_FILE}"
      fi
    done
  fi

  if [[ ! -s "${IDENTITIES_FILE}" ]]; then
    echo "${TRACE_ID} no valid age identities resolved" >&2
    echo "${TRACE_ID} update BACKUP_AGE_IDENTITIES(_FILE). : Bitte durch Operator verifizieren!" >&2
    exit 1
  fi

  PLAINTEXT_ARCHIVE="$(mktemp "${TEMP_DIR}/archive.XXXXXX.tar.zst")"
  age --decrypt --output "${PLAINTEXT_ARCHIVE}" --identity-file "${IDENTITIES_FILE}" "${ARCHIVE}"
  ARCHIVE_WAS_ENCRYPTED=1
fi

unzstd -q < "${PLAINTEXT_ARCHIVE}" | tar -xf - -C "${TEMP_DIR}"

cat <<JSON >> "${ROOT}/logs/shs.jsonl"
{"trace_id":"${TRACE_ID}","event":"restore.start","archive":"${ARCHIVE}"}
JSON

docker compose --env-file "${ENV_FILE}" down --remove-orphans
cp "${TEMP_DIR}/secrets/tls/ca.crt" "${ROOT}/secrets/tls/ca.crt"
cp "${TEMP_DIR}/secrets/tls/ca.key" "${ROOT}/secrets/tls/ca.key"
cp "${TEMP_DIR}/secrets/tls/leaf.pem" "${ROOT}/secrets/tls/leaf.pem"
cp "${TEMP_DIR}/secrets/tls/leaf.key" "${ROOT}/secrets/tls/leaf.key"
mkdir -p "${ROOT}/locks"
cp "${TEMP_DIR}/locks/VERSIONS.lock" "${ROOT}/locks/VERSIONS.lock"
cp "${TEMP_DIR}/logs/shs.jsonl" "${ROOT}/logs/shs.jsonl"

if [[ -d "${TEMP_DIR}/minio-backup" ]]; then
  if docker compose --env-file "${ENV_FILE}" exec -T minio which mc >/dev/null 2>&1; then
    docker compose --env-file "${ENV_FILE}" exec -T minio /bin/sh -c 'rm -rf /tmp/minio-restore && mkdir -p /tmp/minio-restore'
    docker compose --env-file "${ENV_FILE}" cp "${TEMP_DIR}/minio-backup/." minio:/tmp/minio-restore
    docker compose --env-file "${ENV_FILE}" exec -T minio /bin/sh -c "mc alias set local https://minio:9000 \"${MINIO_ROOT_USER}\" \"${MINIO_ROOT_PASSWORD}\" --api s3v4 && mc mirror --overwrite --remove /tmp/minio-restore local/shs"
    docker compose --env-file "${ENV_FILE}" exec -T minio rm -rf /tmp/minio-restore
  else
    echo "${TRACE_ID} skipping minio restore (mc missing)" >&2
  fi
fi

SQL_ZST="$(find "${TEMP_DIR}" -maxdepth 1 -type f -name 'postgres-*.sql.zst' -print -quit)"
if [ -z "${SQL_ZST}" ]; then
  echo "${TRACE_ID} missing postgres dump" >&2
  exit 1
fi
unzstd -c "${SQL_ZST}" | docker compose --env-file "${ENV_FILE}" exec -T postgres psql -U "${POSTGRES_USER}" "${POSTGRES_DB:-shs}"

cat <<JSON >> "${ROOT}/logs/shs.jsonl"
{"trace_id":"${TRACE_ID}","event":"restore.complete","archive":"${ARCHIVE}"}
JSON

echo "restore complete"
