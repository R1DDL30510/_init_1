#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
export ROOT
LOCK_REQ="${ROOT}/locks/REQUIREMENTS.lock.txt"
LOCK_VERSIONS="${ROOT}/locks/VERSIONS.lock"

python3 <<'PY'
import hashlib
import os
from pathlib import Path

root = Path(os.environ['ROOT'])
req_lock = root / 'locks' / 'REQUIREMENTS.lock.txt'
if not req_lock.exists():
    raise SystemExit(f"missing lock file: {req_lock}")

services = {}
current = None
for line in req_lock.read_text().splitlines():
    if line.startswith('service:'):
        current = line.split(':', 1)[1].strip()
        services[current] = {}
    elif line.startswith('  ') and 'sha256=' in line and current:
        name, digest = line.strip().split(' sha256=')
        services[current][name] = digest

for service, wheels in services.items():
    wheel_dir = root / 'vendor' / 'wheels' / service
    if not wheel_dir.exists():
        raise SystemExit(f"wheel directory missing for {service}: {wheel_dir}")
    for wheel_name, expected_sha in wheels.items():
        wheel_path = wheel_dir / wheel_name
        if not wheel_path.exists():
            raise SystemExit(f"wheel missing: {wheel_path}")
        sha = hashlib.sha256(wheel_path.read_bytes()).hexdigest()
        if sha != expected_sha:
            raise SystemExit(f"sha mismatch for {wheel_path}: {sha} != {expected_sha}")

versions_path = root / 'locks' / 'VERSIONS.lock'
if not versions_path.exists():
    raise SystemExit(f"missing versions lock: {versions_path}")

service_digests = {}
current = None
for raw in versions_path.read_text().splitlines():
    line = raw.rstrip()
    if line.strip() == 'services:':
        current = None
        continue
    if line.startswith('  ') and line.endswith(':') and not line.strip().startswith('digest'):
        current = line.strip().rstrip(':')
        continue
    if current and 'digest:' in line:
        digest = line.split(':', 1)[1].strip().strip('"')
        service_digests[current] = digest

for env_name in ('.env.example', '.env.local'):
    env_path = root / env_name
    if not env_path.exists():
        continue
    entries = {}
    for line in env_path.read_text().splitlines():
        if '=' not in line or line.lstrip().startswith('#'):
            continue
        key, value = line.split('=', 1)
        if key.endswith('_IMAGE') and '@sha256:' in value:
            entries[key[:-6].lower()] = value.split('@')[-1]
    for service_key, digest in service_digests.items():
        env_digest = entries.get(service_key)
        if env_digest and env_digest != digest:
            raise SystemExit(f"digest mismatch for {service_key} in {env_name}: {env_digest} != {digest}")
print('hash verification passed')
PY
