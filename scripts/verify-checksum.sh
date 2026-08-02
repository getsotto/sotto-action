#!/bin/sh

# Kept separate so the installer and offline tampered fixtures exercise the same checksum path.
set -eu

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

asset_path="$1"
sums_path="$2"
asset="${asset_path##*/}"

# Require one 64-character hexadecimal digest and one filename so malformed or trailing fields
# cannot become a valid match. Binary-mode checksum tools prefix the filename with '*'.
expected="$({
    awk -v asset="$asset" \
        'NF == 2 && length($1) == 64 && $1 ~ /^[0-9a-fA-F]+$/ && ($2 == asset || $2 == "*" asset) { hash = tolower($1); found++ } END { if (found == 1) print hash; else exit 1 }' \
        "$sums_path"
})" || fail "$asset must appear exactly once in SHA256SUMS"

# Keep comparisons case-insensitive explicitly because checksum tools and manifests vary in case.
if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$asset_path" | awk '{ print tolower($1) }')"
else
    actual="$(shasum -a 256 "$asset_path" | awk '{ print tolower($1) }')"
fi

[ "$actual" = "$expected" ] || fail "checksum verification failed for $asset"
