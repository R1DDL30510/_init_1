#!/usr/bin/env bash
# Export a workstation bundle with CA + client materials for SHS mutual TLS.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TLS_DIR="${REPO_ROOT}/secrets/tls"
CLIENT_DIR="${TLS_DIR}/client"
TIMESTAMP="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
ARCHIVE_NAME="client-bundle-${TIMESTAMP}.tar.zst"
ARCHIVE_PATH="${CLIENT_DIR}/${ARCHIVE_NAME}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

required_files=("ca.crt" "leaf.pem" "leaf.key")
for file in "${required_files[@]}"; do
  if [[ ! -f "${TLS_DIR}/${file}" ]]; then
    echo "[export-client-bundle] missing ${TLS_DIR}/${file}; run make bootstrap first" >&2
    exit 1
  fi
  cp "${TLS_DIR}/${file}" "${TMP_DIR}/${file}"
  chmod 600 "${TMP_DIR}/${file}"
  if [[ "${file}" == "ca.crt" ]]; then
    chmod 644 "${TMP_DIR}/${file}"
  fi
  if [[ "${file}" == "leaf.pem" ]]; then
    openssl x509 -in "${TLS_DIR}/${file}" -outform DER -out "${TMP_DIR}/leaf.der" >/dev/null 2>&1
    cp "${TLS_DIR}/${file}" "${TMP_DIR}/leaf.cer"
    chmod 644 "${TMP_DIR}/leaf.cer"
  fi
  if [[ "${file}" == "leaf.key" ]]; then
    openssl pkcs8 -topk8 -inform PEM -outform DER -in "${TLS_DIR}/${file}" -out "${TMP_DIR}/leaf.key.der" -nocrypt >/dev/null 2>&1
    openssl pkcs12 -export -inkey "${TLS_DIR}/leaf.key" -in "${TLS_DIR}/leaf.pem" -certfile "${TLS_DIR}/ca.crt" -passout pass: -out "${TMP_DIR}/leaf.p12" >/dev/null 2>&1
  fi
  if [[ "${file}" == "ca.crt" ]]; then
    openssl x509 -in "${TLS_DIR}/${file}" -outform DER -out "${TMP_DIR}/ca.der" >/dev/null 2>&1
  fi

done

mkdir -p "${CLIENT_DIR}"
umask 077
for artifact in ca.crt ca.der leaf.pem leaf.der leaf.cer leaf.key leaf.key.der leaf.p12; do
  if [[ -f "${TMP_DIR}/${artifact}" ]]; then
    cp "${TMP_DIR}/${artifact}" "${CLIENT_DIR}/${artifact}"
    chmod 600 "${CLIENT_DIR}/${artifact}"
    if [[ "${artifact}" == ca.crt || "${artifact}" == ca.der || "${artifact}" == leaf.cer ]]; then
      chmod 644 "${CLIENT_DIR}/${artifact}"
    fi
  fi
done

tar -C "${TMP_DIR}" -cf - . | zstd -q -o "${ARCHIVE_PATH}"
chmod 600 "${ARCHIVE_PATH}"

echo "[export-client-bundle] wrote ${ARCHIVE_PATH}"
