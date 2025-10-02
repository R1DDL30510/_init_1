#!/usr/bin/env sh
set -euo pipefail

LOCK=${BASE_DIR:-$(pwd)}/VERSIONS.lock
BASE=${BASE_DIR:-$(pwd)}
OUTDIR=${BASE:-$(pwd)}/generated/split-repos
TARDIR=${BASE:-$(pwd)}/generated/dist
mkdir -p "$OUTDIR" "$TARDIR"

while IFS= read -r line; do
    name=$(echo "$line" | cut -d'=' -f2 | tr -d '"')
    version=$(echo "$line" | cut -d'=' -f4 | tr -d '"')
    relpath=$(echo "$line" | cut -d'=' -f6 | tr -d '"')
    [ -z "$name" ] && continue
    slug=${name}-${version}
    repo=$OUTDIR/$slug
    mkdir -p "$repo"
    # copy or link artifact
    src=${BASE}/${relpath}
    dst=${repo}/$(basename "$src")
    if [ -d "$src" ]; then
        cp -R "$src" "${repo}/" && mv "${repo}/$(basename "$src")" "$dst"
    else
        ln -s "$src" "$dst"
    fi
    # Manifest
    cp ${BASE}/templates/MANIFEST.yaml "$repo/MANIFEST.yaml"
    # SBOM
    cp ${BASE}/sbom/${name}-${version}.cdx.json "$repo/SBOM.cdx.json"
    # License placeholder
    cp ${BASE}/audit/license/${name}.json "$repo/LICENSE.json"
    # README
    echo "# $name" > "$repo/README.md"
    echo "Version: $version" >> "$repo/README.md"
    # tarball
    tar -czf "$TARDIR/${slug}.tar.gz" -C "$repo" .
    echo "Created repo and tarball for $slug"
done < <(grep '^\[\[artifact\]\]$' -A99 $LOCK | grep '^name\s*=')
