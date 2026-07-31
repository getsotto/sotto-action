#Requires -Version 5.1

# This action-only preflight stays separate so malformed input fails before cosign is downloaded
# and its exact error can be tested. install.ps1 repeats the check because it can run directly.
$ErrorActionPreference = "Stop"

function Fail([string] $Message) {
    # Write-Host emits an unformatted GitHub annotation; throw supplies the terminating plain error.
    Write-Host "::error::$Message"
    throw "error: $Message"
}

$Version = [string] $env:SOTTO_VERSION
# Absolute .NET anchors reject trailing newlines; IsMatch is case-sensitive without regex options.
if (-not [regex]::IsMatch($Version, '\Av[0-9]+\.[0-9]+\.[0-9]+\z')) {
    Fail "sotto-version must be an exact release such as v0.4.0"
}
