#!/bin/sh

set -eu

REPO="getsotto/sotto"
# Resolve helpers beside this script because callers may run the installer from any directory.
script_dir="$(CDPATH= cd "$(dirname "$0")" && pwd)"

say() {
    printf '%s\n' "$*" >&2
}

fail() {
    say "error: $*"
    exit 1
}

download() {
    # Keep a missing release distinct from transient network failures, both for users and tests.
    if http_code="$(
        curl --retry 3 --retry-delay 1 -fsSL -w '%{http_code}' -o "$2" "$1"
    )"; then
        return
    fi
    if [ "$http_code" = "404" ]; then
        fail "release asset not found: $1"
    fi
    fail "download failed: $1"
}

version="${SOTTO_VERSION:-}"
case "$version" in
v[0-9]*.[0-9]*.[0-9]*) ;;
*) fail "sotto-version must be an exact release such as v0.4.0" ;;
esac

# The shell pattern above deliberately stays portable. Reject anything beyond three numeric
# components before using the version in a URL or path.
version_numbers="${version#v}"
case "$version_numbers" in
*[!0-9.]* | *.*.*.* | *.) fail "sotto-version must be an exact release such as v0.4.0" ;;
esac
old_ifs="$IFS"
IFS=.
set -- $version_numbers
IFS="$old_ifs"
[ "$#" -eq 3 ] && [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ] ||
    fail "sotto-version must be an exact release such as v0.4.0"

command -v cosign >/dev/null 2>&1 || fail "cosign is required to verify the Sotto release"

os="$(uname -s)"
arch="$(uname -m)"
case "$os/$arch" in
Darwin/arm64) target="aarch64-apple-darwin" ;;
Darwin/x86_64) target="x86_64-apple-darwin" ;;
Linux/x86_64) target="x86_64-unknown-linux-gnu" ;;
Linux/aarch64 | Linux/arm64) target="aarch64-unknown-linux-gnu" ;;
*) fail "no prebuilt Sotto binary for $os/$arch" ;;
esac

asset="sotto-$version-$target.tar.gz"
base="https://github.com/$REPO/releases/download/$version"
identity="https://github.com/$REPO/.github/workflows/release.yml@refs/tags/$version"
if [ -n "${SOTTO_INSTALL_DIR:-}" ]; then
    install_dir="$SOTTO_INSTALL_DIR"
elif [ -n "${RUNNER_TEMP:-}" ]; then
    install_dir="$RUNNER_TEMP/sotto-bin"
else
    fail "SOTTO_INSTALL_DIR or RUNNER_TEMP must be set"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

say "downloading sotto $version ($target)"
download "$base/$asset" "$tmp/$asset"
download "$base/$asset.sigstore.json" "$tmp/$asset.sigstore.json"
download "$base/SHA256SUMS" "$tmp/SHA256SUMS"
download "$base/SHA256SUMS.sigstore.json" "$tmp/SHA256SUMS.sigstore.json"

verify() {
    file="$1"
    cosign verify-blob \
        --bundle "$tmp/$file.sigstore.json" \
        --certificate-identity "$identity" \
        --certificate-oidc-issuer https://token.actions.githubusercontent.com \
        "$tmp/$file" >/dev/null ||
        fail "Sigstore verification failed for $file"
}

verify "SHA256SUMS"
verify "$asset"
say "signatures verified"

"$script_dir/verify-checksum.sh" "$tmp/$asset" "$tmp/SHA256SUMS"
say "checksum verified"

stage="sotto-$version-$target"
tar -xzf "$tmp/$asset" -C "$tmp" "$stage/sotto" ||
    fail "release archive does not contain $stage/sotto"

mkdir -p "$install_dir"
install -m 755 "$tmp/$stage/sotto" "$install_dir/sotto"

actual="$("$install_dir/sotto" --version)"
expected="sotto ${version#v}"
[ "$actual" = "$expected" ] ||
    fail "installed binary reported '$actual', expected '$expected'"

printf '%s\n' "$install_dir" >>"$GITHUB_PATH"
{
    printf 'version=%s\n' "$version"
    printf 'target=%s\n' "$target"
    printf 'binary-path=%s\n' "$install_dir/sotto"
} >>"$GITHUB_OUTPUT"

say "installed $install_dir/sotto"
