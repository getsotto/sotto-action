#Requires -Version 5.1

# This action-only preflight stays separate so malformed input fails before cosign is downloaded
# and its exact error can be tested. install.ps1 repeats the check because it can run directly.
$ErrorActionPreference = "Stop"

function Fail([string] $Message) {
    # Keep the action annotation while matching the installers' plain error format in the log.
    Write-Host "::error::$Message"
    throw "error: $Message"
}

if (-not $env:SOTTO_VERSION -or $env:SOTTO_VERSION -notmatch '^v[0-9]+\.[0-9]+\.[0-9]+$') {
    Fail "sotto-version must be an exact release such as v0.4.0"
}
