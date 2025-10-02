#!/usr/bin/env sh
set -euo pipefail

if ! command -v grype > /dev/null 2>&1; then
    echo 'Grype not found – install via: apt install grype' >&2
    exit 1
fi
if ! command -v trivy > /dev/null 2>&1; then
    echo 'Trivy not found – install via: apt install trivy' >&2
    exit 1
fi

SBOM_DIR=${BASE_DIR:-$(pwd)}/sbom
AUDIT_DIR=${BASE_DIR:-$(pwd)}/audit
mkdir -p "$AUDIT_DIR/cve"
mkdir -p "$AUDIT_DIR/license"

for sbom in $SBOM_DIR/*.cdx.json; do
    name=$(basename "$sbom" .cdx.json | cut -d'-' -f1)
    echo "Auditing $name"
    grype sbom:"$sbom" -o table -o json 2>/dev/null | tee "$AUDIT_DIR/cve/${name}.json"
    trivy sbom "$sbom" --format json --output "$AUDIT_DIR/license/${name}.json" 2>/dev/null
done

# Summary
echo '## Summary' <> "$AUDIT_DIR/summary.md"
echo "CVE findings:" | tee -a "$AUDIT_DIR/summary.md"
for f in $AUDIT_DIR/cve/*.json; do
    cat "$f" | grep -i 'severity' | awk '{print $NF}' | sort | uniq -c | sort -nr | tee -a "$AUDIT_DIR/summary.md"
done
echo "License findings:" | tee -a "$AUDIT_DIR/summary.md"
for f in $AUDIT_DIR/license/*.json; do
    cat "$f" | grep -i 'license' | awk -F'"' '{print $6}' | sort | uniq -c | sort -nr | tee -a "$AUDIT_DIR/summary.md"
done
