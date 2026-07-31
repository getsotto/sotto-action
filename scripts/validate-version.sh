#!/bin/bash

set -eu

if [[ ! "${SOTTO_VERSION:-}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "sotto-version must be an exact release such as v0.4.0" >&2
    exit 1
fi
