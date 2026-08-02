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
    # Require one 64-character hexadecimal digest and one filename so trailing fields are rejected.
    $Parts = $Line.Trim() -split '\s+', 2
    if ($Parts.Count -eq 2 -and $Parts[0] -match '^[0-9a-fA-F]{64}$') {
        $EntryName = $Parts[1].Trim()
        # Binary-mode checksum tools prefix the filename with '*'; text-mode entries do not.
        if ($EntryName.StartsWith('*')) {
            $EntryName = $EntryName.Substring(1)
        }
        if ($EntryName -eq $Asset) {
            $ExpectedHashes += $Parts[0].ToLowerInvariant()
        }
    }
}
if ($ExpectedHashes.Count -ne 1) {
    Fail "$Asset must appear exactly once in SHA256SUMS"
}

# Get-FileHash returns uppercase while manifests commonly use lowercase; normalise both explicitly.
$ActualHash = (Get-FileHash -Algorithm SHA256 -Path $AssetPath).Hash.ToLowerInvariant()
if ($ActualHash -ne $ExpectedHashes[0]) {
    Fail "checksum verification failed for $Asset"
}
