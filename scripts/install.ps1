#Requires -Version 5.1

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Fail([string] $Message) {
    throw "error: $Message"
}

function Download([string] $Uri, [string] $OutFile) {
    $LastError = $null
    foreach ($Attempt in 1..3) {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $OutFile
            return
        } catch {
            $LastError = $_
            if ($Attempt -lt 3) {
                Start-Sleep -Seconds 1
            }
        }
    }
    Fail "download failed: $Uri ($LastError)"
}

$Version = $env:SOTTO_VERSION
if (-not $Version -or $Version -notmatch '^v[0-9]+\.[0-9]+\.[0-9]+$') {
    Fail "sotto-version must be an exact release such as v0.4.0"
}

if (-not (Get-Command cosign -ErrorAction SilentlyContinue)) {
    Fail "cosign is required to verify the Sotto release"
}

$Architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
if ("$Architecture" -ne "X64") {
    Fail "no prebuilt Sotto binary for Windows/$Architecture"
}

$Repo = "getsotto/sotto"
$Target = "x86_64-pc-windows-msvc"
$Asset = "sotto-$Version-$Target.zip"
$Base = "https://github.com/$Repo/releases/download/$Version"
$Identity = "https://github.com/$Repo/.github/workflows/release.yml@refs/tags/$Version"
$InstallDir = if ($env:SOTTO_INSTALL_DIR) {
    $env:SOTTO_INSTALL_DIR
} elseif ($env:RUNNER_TEMP) {
    Join-Path $env:RUNNER_TEMP "sotto-bin"
} else {
    Fail "SOTTO_INSTALL_DIR or RUNNER_TEMP must be set"
}

$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $Tmp | Out-Null

try {
    Write-Host "downloading sotto $Version ($Target)"
    $ArchivePath = Join-Path $Tmp $Asset
    $ArchiveBundlePath = Join-Path $Tmp "$Asset.sigstore.json"
    $SumsPath = Join-Path $Tmp "SHA256SUMS"
    $SumsBundlePath = Join-Path $Tmp "SHA256SUMS.sigstore.json"

    Download "$Base/$Asset" $ArchivePath
    Download "$Base/$Asset.sigstore.json" $ArchiveBundlePath
    Download "$Base/SHA256SUMS" $SumsPath
    Download "$Base/SHA256SUMS.sigstore.json" $SumsBundlePath

    & cosign verify-blob `
        --bundle $SumsBundlePath `
        --certificate-identity $Identity `
        --certificate-oidc-issuer https://token.actions.githubusercontent.com `
        $SumsPath *> $null
    if ($LASTEXITCODE -ne 0) {
        Fail "Sigstore verification failed for SHA256SUMS"
    }

    & cosign verify-blob `
        --bundle $ArchiveBundlePath `
        --certificate-identity $Identity `
        --certificate-oidc-issuer https://token.actions.githubusercontent.com `
        $ArchivePath *> $null
    if ($LASTEXITCODE -ne 0) {
        Fail "Sigstore verification failed for $Asset"
    }
    Write-Host "signatures verified"

    $ExpectedHashes = @()
    foreach ($Line in Get-Content -Path $SumsPath) {
        if ($Line -match '^([0-9a-fA-F]{64})\s+\*?(.+)$' -and $Matches[2] -eq $Asset) {
            $ExpectedHashes += $Matches[1]
        }
    }
    if ($ExpectedHashes.Count -ne 1) {
        Fail "$Asset must appear exactly once in SHA256SUMS"
    }

    $ActualHash = (Get-FileHash -Algorithm SHA256 -Path $ArchivePath).Hash
    if ($ActualHash -ne $ExpectedHashes[0]) {
        Fail "checksum verification failed for $Asset"
    }
    Write-Host "checksum verified"

    Expand-Archive -Path $ArchivePath -DestinationPath $Tmp -Force
    $SourceBinary = Join-Path $Tmp "sotto-$Version-$Target\sotto.exe"
    if (-not (Test-Path -Path $SourceBinary -PathType Leaf)) {
        Fail "release archive does not contain sotto-$Version-$Target\sotto.exe"
    }

    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    $BinaryPath = Join-Path $InstallDir "sotto.exe"
    Copy-Item -Path $SourceBinary -Destination $BinaryPath -Force

    $ActualVersion = (& $BinaryPath --version | Out-String).Trim()
    $ExpectedVersion = "sotto $($Version.Substring(1))"
    if ($ActualVersion -ne $ExpectedVersion) {
        Fail "installed binary reported '$ActualVersion', expected '$ExpectedVersion'"
    }

    $InstallDir | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append

    Write-Host "installed $BinaryPath"
} finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
