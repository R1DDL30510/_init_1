#!/usr/bin/env sh
set -euo pipefail

# syft must be installed – provide guidance if missing
if ! command -v syft > /dev/null 2>&1; then
    echo 'Syft not found. Install via:'
    echo '  macOS: brew install syft'
    echo '  Ubuntu: sudo snap install syft'
    echo '  Windows: winget install anchore.syft'
    exit 1
fi

LOCK=${BASE_DIR:-$(pwd)}/VERSIONS.lock
SBOM_DIR=${BASE_DIR:-$(pwd)}/sbom
mkdir -p "$SBOM_DIR"

while IFS= read -r line; do
    name=$(echo "$line" | cut -d'=' -f2 | tr -d '"')
    version=$(echo "$line" | cut -d'=' -f4 | tr -d '"')
    path=$(echo "$line" | cut -d'=' -f6 | tr -d '"')
    [ -z "$name" ] && continue
    relpath=${path#./}
    abs=${BASE_DIR:-$(pwd)}/$relpath
    out="$SBOM_DIR/${name}-${version}.cdx.json"
    if [ -d "$abs" ] || [ -f "$abs" ]; then
        echo "Generating SBOM for $name@$version"
        syft dir:"$abs" -o cyclonedx-json="$out"
    fi
done < <(grep '^\[\[artifact\]\]$' -A99 $LOCK | grep '^name\s*=')
