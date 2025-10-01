#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/.env.local"
VERSIONS="${ROOT}/VERSIONS.lock"
TLS_DIR="${ROOT}/secrets/tls"

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
