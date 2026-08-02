#Requires -Version 5.1

# Kept separate so the installer and offline tampered fixtures exercise the same checksum path.
param(
    [Parameter(Mandatory = $true)]
    [string] $AssetPath,
    [Parameter(Mandatory = $true)]
    [string] $SumsPath
)

$ErrorActionPreference = "Stop"

function Fail([string] $Message) {
    throw "error: $Message"
}

$Asset = Split-Path -Leaf $AssetPath
$ExpectedHashes = @()
foreach ($Line in Get-Content -Path $SumsPath) {
    if ($Line -match '^([0-9a-fA-F]{64})\s+(\*?)(.+)$' -and $Matches[3] -eq $Asset) {
        $ExpectedHashes += $Matches[1]
    }
}
if ($ExpectedHashes.Count -ne 1) {
    Fail "$Asset must appear exactly once in SHA256SUMS"
}

$ActualHash = (Get-FileHash -Algorithm SHA256 -Path $AssetPath).Hash
if ($ActualHash -ne $ExpectedHashes[0]) {
    Fail "checksum verification failed for $Asset"
}
