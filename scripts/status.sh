#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/.env.local"
VERSIONS="${ROOT}/VERSIONS.lock"
TLS_DIR="${ROOT}/secrets/tls"

CHECK_DIGESTS=0
SUPPRESS_LOG=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--check-digests] [--suppress-log]

Options:
  --check-digests   verify *_IMAGE digest pins against VERSIONS.lock and fail on drift
  --suppress-log    skip writing to logs/shs.jsonl (useful for CI/pre-commit checks)
  --help            display this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-digests)
      CHECK_DIGESTS=1
      shift
      ;;
    --suppress-log)
      SUPPRESS_LOG=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

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
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +a
else
  echo "No .env.local found; using defaults" >&2
fi

DOMAIN="${SHS_DOMAIN:-localhost}"
BASE_URL="https://${DOMAIN}:${SHS_PROXY_PORT:-8443}"
TRACE_ID="status-$(date -u +%Y-%m-%dT%H-%M-%SZ)"

if [[ "${SUPPRESS_LOG}" -eq 0 ]]; then
  mkdir -p "${ROOT}/logs"
  cat <<JSON >> "${ROOT}/logs/shs.jsonl"
{"trace_id":"${TRACE_ID}","event":"status.run","domain":"${DOMAIN}"}
JSON
fi

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

declare -a SERVICE_PAIRS=()

if [[ -f "${VERSIONS}" ]]; then
  while IFS= read -r pair; do
    [[ -z "${pair}" ]] && continue
    SERVICE_PAIRS+=("${pair}")
  done < <(VERSIONS_PATH="${VERSIONS}" python3 <<'PY'
import os
import re

versions_path = os.environ['VERSIONS_PATH']
pairs = []
in_services = False
current = None
digest_pattern = re.compile(r'digest:\s*"?(sha256:[0-9a-f]+)"?')

with open(versions_path, 'r', encoding='utf-8') as fh:
    for raw_line in fh:
        line = raw_line.rstrip('\n')
        stripped = line.strip()
        if stripped == 'services:':
            in_services = True
            current = None
            continue

        if not line.startswith(' '):
            in_services = False
            current = None
            continue

        if not in_services:
            continue

        if line.startswith('  ') and not line.startswith('    '):
            current = stripped.rstrip(':')
            continue

        if current is None:
            continue

        match = digest_pattern.search(line)
        if match:
            pairs.append(f"{current}|{match.group(1)}")
            current = None

print('\n'.join(pairs))
PY
)
fi

verify_digests() {
  if [[ ! -f "${VERSIONS}" ]]; then
    echo "Digest verification: VERSIONS.lock missing" >&2
    return 1
  fi

  if [[ ${#SERVICE_PAIRS[@]} -eq 0 ]]; then
    echo "Digest verification: no services detected in VERSIONS.lock" >&2
    return 1
  fi

  local failure=0
  local -a env_files=("${ROOT}/.env.example")
  if [[ -f "${ENV_FILE}" ]]; then
    env_files+=("${ENV_FILE}")
  fi

  echo "Digest verification:"

  for env_file in "${env_files[@]}"; do
    if [[ ! -f "${env_file}" ]]; then
      echo "  - ${env_file}: missing"
      failure=1
      continue
    fi

    local -a issues=()
    for pair in "${SERVICE_PAIRS[@]}"; do
      local service="${pair%%|*}"
      local digest="${pair#*|}"
      local env_var="$(echo "${service}" | tr '[:lower:]-' '[:upper:]_')_IMAGE"
      local line
      line="$(grep -E "^${env_var}=" "${env_file}" | head -n1 || true)"

      if [[ -z "${line}" ]]; then
        issues+=("${env_var} missing")
        continue
      fi

      local value="${line%%#*}"
      value="${value#${env_var}=}"
      local trimmed="$(printf '%s' "${value}" | tr -d '[:space:]')"
      if [[ "${trimmed}" != *@* ]]; then
        issues+=("${env_var} missing digest pin (expected @${digest})")
        continue
      fi

      local observed="${trimmed##*@}"
      if [[ "${observed}" != "${digest}" ]]; then
        issues+=("${env_var} digest drift (expected ${digest}, saw ${observed})")
      fi
    done

    if [[ ${#issues[@]} -eq 0 ]]; then
      echo "  - ${env_file}: OK"
    else
      failure=1
      echo "  - ${env_file}:"
      for issue in "${issues[@]}"; do
        echo "      * ${issue}"
      done
    fi
  done

  if [[ ${failure} -ne 0 ]]; then
    return 1
  fi

  return 0
}

if verify_digests; then
  DIGEST_STATUS=0
else
  DIGEST_STATUS=1
fi

if [[ ${CHECK_DIGESTS} -eq 1 ]]; then
  exit ${DIGEST_STATUS}
fi
