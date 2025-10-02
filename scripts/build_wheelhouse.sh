#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SERVICES=(tei reranker ocr)
LOCK_FILE="${ROOT}/locks/REQUIREMENTS.lock.txt"

echo "[build_wheelhouse] preparing wheel directories" >&2
>"${LOCK_FILE}"
printf '# Generated on %s\n' "$(date -u +%Y-%m-%dT%H-%M-%SZ)" >>"${LOCK_FILE}"

for svc in "${SERVICES[@]}"; do
  req="${ROOT}/services/${svc}/requirements.txt"
  dest="${ROOT}/vendor/wheels/${svc}"
  if [ ! -f "$req" ]; then
    echo "[build_wheelhouse] skipping ${svc} (no requirements.txt)" >&2
    continue
  fi
  rm -rf "${dest}"
  mkdir -p "${dest}"
  echo "[build_wheelhouse] downloading wheels for ${svc}" >&2
  python3 -m pip download --no-cache-dir --dest "${dest}" --requirement "$req"
  printf '\nservice: %s\n' "$svc" >>"${LOCK_FILE}"
  find "${dest}" -maxdepth 1 -type f -name '*.whl' -print0 | sort -z | while IFS= read -r -d '' wheel; do
    base=$(basename "$wheel")
    sha=$(shasum -a 256 "$wheel" | awk '{print $1}')
    printf '  %s sha256=%s\n' "$base" "$sha" >>"${LOCK_FILE}"
  done
done
