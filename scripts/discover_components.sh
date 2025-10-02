#!/usr/bin/env sh
set -euo pipefail

### Discover third‑party artifacts

BASE_DIR=$(realpath ..)
TMPDIR=${BASE_DIR}/tmp
mkdir -p "$TMPDIR"
OUTPUT="$TMPDIR/components.csv"
echo 'name,version,relpath,bytes,sha256,detected_type,origin_hint' > "$OUTPUT"

detect_type() {
    case "$1" in
        *.tar.gz|*.tgz) echo 'tar-gz' ;;
        *.zip) echo 'zip' ;;
        *.tar.bz2|*.tbz2) echo 'tar-bz2' ;;
        *.whl) echo 'wheel' ;;
        *.jar) echo 'jar' ;;
        *.exe|*.bin|*.sh) echo 'binary' ;;
        *) echo 'unknown' ;;
    esac
}

sha256sum_fn() {
    if command -v shasum > /dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        sha256sum "$1" | awk '{print $1}'
    fi
}

for file in $(find "$BASE_DIR/third_party" -type f); do
    relpath=${file#${BASE_DIR}/}
    bytes=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file")
    sha=$(sha256sum_fn "$file")
    type=$(detect_type "$file")
    name=$(basename "$file" | cut -d'.' -f1)
    version=$(basename "$file" | sed -E "s/.*-([0-9]+(?:\.[0-9]+)*)\..*/\1/" | head -n1)
    origin=$(basename $(dirname "$file"))
    echo "$name,$version,$relpath,$bytes,$sha,$type,$origin" >> "$OUTPUT"
done

# Template directory artifacts
for file in $(find "$BASE_DIR/templates" -type f -name '*.yaml'); do
    relpath=${file#${BASE_DIR}/}
    bytes=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file")
    sha=$(sha256sum_fn "$file")
    type='yaml'
    name=$(basename "$file" | cut -d'.' -f1)
    version='n/a'
    origin='template'
    echo "$name,$version,$relpath,$bytes,$sha,$type,$origin" >> "$OUTPUT"
done

echo 'Discovered artifacts written to $OUTPUT'
