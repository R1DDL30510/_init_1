#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
MODELS_DIR="${ROOT}/vendor/models"

mkdir -p "${MODELS_DIR}/tei" "${MODELS_DIR}/reranker" "${MODELS_DIR}/ocr"

cat <<'JSON' >"${MODELS_DIR}/tei/hash_embedding.json"
{
  "name": "shs-hash-embedding",
  "dimension": 384,
  "version": "1.0.0",
  "description": "Deterministic hashing-based embedding model for offline TEI"
}
JSON

cat <<'JSON' >"${MODELS_DIR}/reranker/hash_reranker.json"
{
  "name": "shs-hash-reranker",
  "dimension": 384,
  "version": "1.0.0",
  "description": "Deterministic hashing-based reranker"
}
JSON

cat <<'JSON' >"${MODELS_DIR}/ocr/metadata.json"
{
  "name": "shs-light-ocr",
  "version": "1.0.0",
  "description": "Lightweight OCR pipeline using MinIO-backed storage and PyPDF"
}
JSON

echo "[fetch_models] populated metadata in ${MODELS_DIR}" >&2
