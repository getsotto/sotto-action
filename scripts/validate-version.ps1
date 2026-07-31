#Requires -Version 5.1

# This action-only preflight stays separate so malformed input fails before cosign is downloaded
# and its exact error can be tested. install.ps1 repeats the check because it can run directly.
$ErrorActionPreference = "Stop"

function Fail([string] $Message) {
    # Keep the action annotation while matching the installers' plain error format in the log.
    Write-Host "::error::$Message"
    throw "error: $Message"
}

$Version = [string] $env:SOTTO_VERSION
if (-not [regex]::IsMatch($Version, '\Av[0-9]+\.[0-9]+\.[0-9]+\z')) {
    Fail "sotto-version must be an exact release such as v0.4.0"
}
