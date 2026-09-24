#!/bin/sh
set -eu

root=${1:-/opt/luna}
source_file=${2:-/tmp/luna-terminal-session-guard.js}
test -f "$root/index.html"
hash=$(sha256sum "$source_file" | cut -c1-16)
filename="terminal-session-guard.$hash.js"
cp "$source_file" "$root/$filename"

# Cover root, generated routes and SPA fallback documents. Install before any
# application script, including classic scripts (not only deferred modules).
find "$root" -type f -name '*.html' -exec sh -eu -c '
    filename=$1
    shift
    for html do
        grep -q "<head>" "$html" || continue
        grep -Fq "/luna/$filename" "$html" && continue
        sed -i "s#<head>#<head><script src=\"/luna/$filename\"></script>#" "$html"
    done
' sh "$filename" {} +
grep -Fq "/luna/$filename" "$root/index.html"
