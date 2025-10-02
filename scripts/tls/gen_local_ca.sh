#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TLS_DIR="${ROOT}/secrets/tls"
DOMAIN="${SHS_DOMAIN:-localhost}"
MODE="${TLS_MODE:-local-ca}"

if [[ "${MODE}" != "local-ca" ]]; then
  echo "Unsupported TLS_MODE=${MODE}" >&2
  exit 1
fi

mkdir -p "${TLS_DIR}"
CA_KEY="${TLS_DIR}/ca.key"
CA_CRT="${TLS_DIR}/ca.crt"
LEAF_KEY="${TLS_DIR}/leaf.key"
LEAF_CSR="${TLS_DIR}/leaf.csr"
LEAF_PEM="${TLS_DIR}/leaf.pem"
OPENSSL_CNF="${TLS_DIR}/openssl.cnf"

cat > "${OPENSSL_CNF}" <<CNF
[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
x509_extensions    = v3_ca
req_extensions     = v3_req
prompt             = no

[ req_distinguished_name ]
C  = EU
ST = SHS
L  = Local
O  = Secure Home Systems
OU = Bootstrap
CN = ${DOMAIN} CA

[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_req ]
subjectAltName = @alt_names
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth

[ alt_names ]
DNS.1 = ${DOMAIN}
DNS.2 = localhost
IP.1 = 127.0.0.1
CNF

if [[ ! -f "${CA_KEY}" || ! -f "${CA_CRT}" ]]; then
  openssl req -x509 -newkey rsa:4096 -sha384 -days 825 -nodes \
    -keyout "${CA_KEY}" -out "${CA_CRT}" -config "${OPENSSL_CNF}" >/dev/null 2>&1
fi

if [[ ! -f "${LEAF_KEY}" || ! -f "${LEAF_PEM}" ]]; then
  openssl req -new -nodes -newkey rsa:4096 -keyout "${LEAF_KEY}" -out "${LEAF_CSR}" \
    -subj "/C=EU/ST=SHS/L=Local/O=Secure Home Systems/OU=Bootstrap/CN=${DOMAIN}" \
    -config "${OPENSSL_CNF}" >/dev/null 2>&1
  openssl x509 -req -in "${LEAF_CSR}" -CA "${CA_CRT}" -CAkey "${CA_KEY}" -CAcreateserial \
    -out "${LEAF_PEM}" -days 398 -sha384 -extfile "${OPENSSL_CNF}" -extensions v3_req >/dev/null 2>&1
fi

rm -f "${LEAF_CSR}" "${TLS_DIR}/ca.srl"
chmod 600 "${CA_KEY}" "${LEAF_KEY}"
chmod 644 "${CA_CRT}" "${LEAF_PEM}"

echo "TLS assets ready in ${TLS_DIR}"
