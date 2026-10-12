# Keep raw arguments: advanced PowerShell parameters consume Flutter's --debug.
$cashewFlutterArgs = @($args)

$ErrorActionPreference = 'Stop'
$cashewRoot = Split-Path -Parent $PSScriptRoot
$cashewSdk = Join-Path $cashewRoot '.tooling\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $cashewSdk)) {
    throw 'Flutter SDK is missing. Run scripts\setup-flutter.ps1 first.'
}

$cashewPreviousPubCache = $env:PUB_CACHE
$cashewPreviousAnalytics = $env:FLUTTER_SUPPRESS_ANALYTICS
$cashewExitCode = 1
Push-Location (Join-Path $cashewRoot 'budget')
try {
    $env:PUB_CACHE = Join-Path $cashewRoot '.tooling\pub-cache'
    $env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
    & $cashewSdk --suppress-analytics @cashewFlutterArgs
    $cashewExitCode = $LASTEXITCODE
}
finally {
    $env:PUB_CACHE = $cashewPreviousPubCache
    $env:FLUTTER_SUPPRESS_ANALYTICS = $cashewPreviousAnalytics
    Pop-Location
}
exit $cashewExitCode
