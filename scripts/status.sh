#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/.env.local"
VERSIONS="${ROOT}/VERSIONS.lock"
TLS_DIR="${ROOT}/secrets/tls"

normalize_fingerprint() {
  local value="${1:-}"
  value="$(printf '%s' "${value}" | tr -d '[:space:]:-' | tr '[:lower:]' '[:upper:]')"
  printf '%s' "${value}"
}

format_fingerprint_display() {
  local normalized
  normalized="$(normalize_fingerprint "${1:-}")"
  if [[ -z "${normalized}" ]]; then
    return 1
  fi

  local length="${#normalized}"
  local result=""
  local i=0
  while [[ "${i}" -lt "${length}" ]]; do
    local chunk="${normalized:${i}:2}"
    if [[ -n "${chunk}" ]]; then
      if [[ -n "${result}" ]]; then
        result+=":${chunk}"
      else
        result="${chunk}"
      fi
    fi
    i=$((i + 2))
  done

  printf '%s' "${result}"
}

read_expected_fingerprint() {
  local inline_value="${1:-}"
  local file_path="${2:-}"

  if [[ -n "${inline_value}" ]]; then
    printf '%s' "${inline_value}"
    return 0
  fi

  if [[ -n "${file_path}" && -f "${file_path}" ]]; then
    tr -d '\r\n' < "${file_path}"
    return 0
  fi

  return 1
}

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  source "${ENV_FILE}"
  set +a
else
  echo "No .env.local found; using defaults" >&2
fi

DOMAIN="${SHS_DOMAIN:-localhost}"
BASE_URL="https://${DOMAIN}:${SHS_PROXY_PORT:-8443}"
TRACE_ID="status-$(date -u +%Y-%m-%dT%H-%M-%SZ)"

cat <<JSON >> "${ROOT}/logs/shs.jsonl"
{"trace_id":"${TRACE_ID}","event":"status.run","domain":"${DOMAIN}"}
JSON

VERSIONS_CONTENT=""
if [[ -f "${VERSIONS}" ]]; then
  VERSIONS_CONTENT="$(sed 's/^/    /' "${VERSIONS}")"
fi

echo "Secure Home Systems :: status"
echo "Base URL       : ${BASE_URL}"
echo "TLS directory  : ${TLS_DIR}"
echo "Profiles       : minimal (cpu-only), gpu (optional)"
echo "Services       : proxy, openwebui, n8n, postgres, minio, ocr, tei, reranker, ollama"
echo "Feature flags  : OFFLINE=${OFFLINE:-1} TRACE_SAMPLE_RATE=${TRACE_SAMPLE_RATE:-1.0}"
echo "Versions.lock  :"
if [[ -n "${VERSIONS_CONTENT}" ]]; then
  echo "${VERSIONS_CONTENT}"
else
  echo "    (missing)"
fi
echo "Health probes  :"
echo "  - ${BASE_URL}/healthz"
echo "  - ${BASE_URL}/readyz"
echo "  - ${BASE_URL}/api/status"
echo "TLS fingerprints:"

if ! command -v openssl >/dev/null 2>&1; then
  echo "  - openssl not available; skipping fingerprint verification"
elif [[ ! -d "${TLS_DIR}" ]]; then
  echo "  - TLS directory missing (${TLS_DIR}); run make bootstrap"
else
  LEAF_CERT="${TLS_DIR}/leaf.pem"
  EXPECTED_FILE="${SHS_TLS_LEAF_FINGERPRINT_FILE:-${TLS_DIR}/leaf.sha256}"

  if [[ ! -f "${LEAF_CERT}" ]]; then
    echo "  - Leaf certificate missing (${LEAF_CERT}); run scripts/tls/gen_local_ca.sh"
  elif ACTUAL_RAW="$(openssl x509 -in "${LEAF_CERT}" -noout -fingerprint -sha256 2>/dev/null)"; then
    ACTUAL_VALUE="${ACTUAL_RAW#*=}"
    ACTUAL_NORMALIZED="$(normalize_fingerprint "${ACTUAL_VALUE}")"
    if ! ACTUAL_DISPLAY="$(format_fingerprint_display "${ACTUAL_NORMALIZED}")"; then
      ACTUAL_DISPLAY="$(printf '%s' "${ACTUAL_VALUE}" | tr -d '[:space:]')"
    fi

    EXPECTED_RAW=""
    EXPECTED_NORMALIZED=""
    EXPECTED_DISPLAY=""
    if EXPECTED_RAW="$(read_expected_fingerprint "${SHS_TLS_LEAF_FINGERPRINT_SHA256:-}" "${EXPECTED_FILE}" 2>/dev/null)"; then
      EXPECTED_NORMALIZED="$(normalize_fingerprint "${EXPECTED_RAW}")"
      if [[ -n "${EXPECTED_NORMALIZED}" ]]; then
        if ! EXPECTED_DISPLAY="$(format_fingerprint_display "${EXPECTED_NORMALIZED}")"; then
          EXPECTED_DISPLAY="$(printf '%s' "${EXPECTED_RAW}" | tr -d '[:space:]')"
        fi
      fi
    fi

    if [[ -n "${EXPECTED_NORMALIZED}" ]]; then
      if [[ "${ACTUAL_NORMALIZED}" == "${EXPECTED_NORMALIZED}" ]]; then
        echo "  - Leaf certificate fingerprint matches baseline (${ACTUAL_DISPLAY})"
      else
        echo "  - Leaf certificate fingerprint mismatch"
        if [[ -n "${EXPECTED_DISPLAY}" ]]; then
          echo "    expected: ${EXPECTED_DISPLAY}"
        fi
        echo "    observed: ${ACTUAL_DISPLAY}"
      fi
    else
      echo "  - Baseline fingerprint not provided"
      if [[ -n "${ACTUAL_DISPLAY}" ]]; then
        echo "    observed: ${ACTUAL_DISPLAY}"
      fi
      echo "    configure SHS_TLS_LEAF_FINGERPRINT_SHA256 or SHS_TLS_LEAF_FINGERPRINT_FILE"
    fi
  else
    echo "  - Unable to read fingerprint from ${LEAF_CERT}"
  fi
fi
