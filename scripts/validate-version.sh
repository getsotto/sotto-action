#!/bin/bash

# This action-only preflight stays separate so malformed input fails before cosign is downloaded
# and its exact error can be tested. Bash is deliberate here for the anchored regex; install.sh
# remains POSIX sh because it is also a standalone user-facing installer.

set -eu

fail() {
    message="$1"
    # Keep both lines on stderr so the validator has no successful output and callers can capture
    # the complete failure through the shell's single error stream.
    printf '::error::%s\n' "$message" >&2
    printf 'error: %s\n' "$message" >&2
    exit 1
}

# Bash's ERE anchors reject trailing newlines and keep this check case-sensitive.
if [[ ! "${SOTTO_VERSION:-}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    fail "sotto-version must be an exact release such as v0.4.0"
fi
