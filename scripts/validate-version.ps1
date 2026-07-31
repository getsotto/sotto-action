#Requires -Version 5.1

if (-not $env:SOTTO_VERSION -or $env:SOTTO_VERSION -notmatch '^v[0-9]+\.[0-9]+\.[0-9]+$') {
    throw "sotto-version must be an exact release such as v0.4.0"
}
