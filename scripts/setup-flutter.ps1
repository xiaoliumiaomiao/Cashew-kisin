$ErrorActionPreference = 'Stop'
$cashewRoot = Split-Path -Parent $PSScriptRoot
$cashewSdkRoot = Join-Path $cashewRoot '.tooling\flutter'
$cashewExpectedRevision = '54e66469a933b60ddf175f858f82eaeb97e48c8d'

if (-not (Test-Path -LiteralPath $cashewSdkRoot)) {
    New-Item -ItemType Directory -Path (Join-Path $cashewRoot '.tooling') -Force | Out-Null
    & git clone --depth 1 --branch 3.19.6 --single-branch https://github.com/flutter/flutter.git $cashewSdkRoot
    if ($LASTEXITCODE -ne 0) { throw 'Flutter SDK download failed.' }
}

$cashewActualRevision = & git -C $cashewSdkRoot rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $cashewActualRevision -ne $cashewExpectedRevision) {
    throw 'Existing SDK is not the pinned Flutter 3.19.6 revision. It was left unchanged.'
}

$cashewPreviousPubCache = $env:PUB_CACHE
$cashewPreviousAnalytics = $env:FLUTTER_SUPPRESS_ANALYTICS
try {
    $env:PUB_CACHE = Join-Path $cashewRoot '.tooling\pub-cache'
    $env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
    & (Join-Path $cashewSdkRoot 'bin\flutter.bat') --suppress-analytics --version
    if ($LASTEXITCODE -ne 0) { throw 'Flutter SDK initialization failed.' }
}
finally {
    $env:PUB_CACHE = $cashewPreviousPubCache
    $env:FLUTTER_SUPPRESS_ANALYTICS = $cashewPreviousAnalytics
}
