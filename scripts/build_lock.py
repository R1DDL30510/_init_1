#!/usr/bin/env python3
"""Generate VERSIONS.lock from tmp/components.csv"""
import csv, datetime, os, sys, textwrap
from pathlib import Path

CSV = Path("tmp/components.csv")
LOCK = Path("VERSIONS.lock")

def load():
    artifacts = []
    with CSV.open(newline='') as f:
        r = csv.DictReader(f)
        for row in r:
            artifacts.append(row)
    return artifacts

def write(artifacts):
    out = ["# Auto‑generated lockfile – DO NOT EDIT"]
    for a in sorted(artifacts, key=lambda x: (x['name'], x['version'], x['relpath'])):
        entry = textwrap.dedent(f'''\
        [[artifact]]
        name = "{a['name']}"
        version = "{a['version']}"
        path = "{a['relpath']}"
        sha256 = "{a['sha256']}"
        size = {a['bytes']}
        type = "{a['detected_type']}"
        origin = "{a['origin_hint']}"
        fetched_at_utc = "{datetime.datetime.utcnow().isoformat()}Z"
        license = "unknown"
        notes = ""
        ''')
        out.append(entry.rstrip())
    LOCK.write_text("\n".join(out) + "\n")

def main():
    artifacts = load()
    write(artifacts)
    print(f"Lockfile updated: {LOCK}")

if __name__ == "__main__":
    main()
