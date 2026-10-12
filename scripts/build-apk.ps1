param([switch]$Optimized)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$cashewRoot = Split-Path -Parent $PSScriptRoot
$cashewTooling = Join-Path $cashewRoot '.tooling'
$cashewJdkRoot = Join-Path $cashewTooling 'jdk\jdk-17.0.20.1+1'
$cashewSdkRoot = Join-Path $cashewTooling 'android-sdk'
$cashewFlutterScript = Join-Path $PSScriptRoot 'flutter.ps1'
$cashewMode = if ($Optimized) { 'release' } else { 'debug' }
$cashewOutputTag = if ($Optimized) { 'test' } else { 'debug' }
$cashewBuiltApk = Join-Path $cashewRoot "budget\build\app\outputs\flutter-apk\app-$cashewMode.apk"
$cashewOutputDirectory = Join-Path $cashewRoot 'output'

foreach ($requiredTool in @(
    (Join-Path $cashewJdkRoot 'bin\java.exe'),
    (Join-Path $cashewSdkRoot 'platforms\android-34\android.jar'),
    (Join-Path $cashewSdkRoot 'build-tools\34.0.0\aapt2.exe'),
    $cashewFlutterScript
)) {
    if (-not (Test-Path -LiteralPath $requiredTool -PathType Leaf)) {
        throw "Android build prerequisite is missing: $requiredTool. Run scripts\setup-android.ps1 first."
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $cashewRoot 'budget\.dart_tool\package_config.json') -PathType Leaf)) {
    throw 'Flutter packages are missing. Run scripts\flutter.ps1 pub get before building with --no-pub.'
}

$previousEnvironment = @{}
$environmentNames = @('JAVA_HOME', 'ANDROID_HOME', 'ANDROID_SDK_ROOT', 'GRADLE_USER_HOME', 'ANDROID_USER_HOME', 'APPDATA', 'PATH', 'ORG_GRADLE_PROJECT_CASHEW_TEST_SIGNING')
foreach ($environmentName in $environmentNames) {
    $previousEnvironment[$environmentName] = [Environment]::GetEnvironmentVariable($environmentName, 'Process')
}
$cashewBuildExitCode = 1
$cashewPreviousApk = $null
Push-Location (Join-Path $cashewRoot 'budget')
try {
    $env:JAVA_HOME = $cashewJdkRoot
    $env:ANDROID_HOME = $cashewSdkRoot
    $env:ANDROID_SDK_ROOT = $cashewSdkRoot
    $env:GRADLE_USER_HOME = Join-Path $cashewTooling 'gradle-cache'
    $env:ANDROID_USER_HOME = Join-Path $cashewTooling 'android-user'
    $env:APPDATA = Join-Path $cashewTooling 'flutter-config\android-build'
    # Dart normalizes Windows environment names to uppercase.
    $env:ORG_GRADLE_PROJECT_CASHEW_TEST_SIGNING = if ($Optimized) { 'true' } else { $null }
    $env:PATH = "$(Join-Path $cashewJdkRoot 'bin');$($previousEnvironment['PATH'])"
    New-Item -ItemType Directory -Path $env:GRADLE_USER_HOME -Force | Out-Null
    New-Item -ItemType Directory -Path $env:ANDROID_USER_HOME -Force | Out-Null
    New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null

    # Flutter checks its configured jdk-dir before JAVA_HOME. On Windows this
    # configuration lives under APPDATA, isolated here from the user's settings.
    & $cashewFlutterScript config --jdk-dir $cashewJdkRoot
    if ($LASTEXITCODE -ne 0) {
        throw 'Setting the project-local Flutter JDK configuration failed.'
    }

    # Preserve an earlier build, then require this invocation to recreate the output.
    # File copying can preserve mtime, so timestamps alone are not a freshness check.
    if (Test-Path -LiteralPath $cashewBuiltApk) {
        if (-not (Test-Path -LiteralPath $cashewBuiltApk -PathType Leaf)) {
            throw "Expected APK path is not a file and was left unchanged: $cashewBuiltApk"
        }
        $cashewPreviousApk = Join-Path (Split-Path -Parent $cashewBuiltApk) "app-$cashewMode-before-$([guid]::NewGuid().ToString('N')).apk"
        [System.IO.File]::Move($cashewBuiltApk, $cashewPreviousApk)
    }
    # Keep Flutter's default supported ABIs in one APK for device testing.
    & $cashewFlutterScript build apk "--$cashewMode" --no-pub
    $cashewBuildExitCode = $LASTEXITCODE
    if ($cashewBuildExitCode -ne 0) {
        throw "Flutter $cashewMode APK build failed with exit code $cashewBuildExitCode."
    }
    if (-not (Test-Path -LiteralPath $cashewBuiltApk -PathType Leaf)) {
        throw "Flutter returned success without producing the APK: $cashewBuiltApk"
    }
    $builtApk = Get-Item -LiteralPath $cashewBuiltApk
    if ($builtApk.Length -eq 0) {
        throw 'The newly produced APK is empty; it was not exported.'
    }

    $apkHash = (Get-FileHash -LiteralPath $cashewBuiltApk -Algorithm SHA256).Hash
    New-Item -ItemType Directory -Path $cashewOutputDirectory -Force | Out-Null
    $outputApk = Join-Path $cashewOutputDirectory "cashew-personal-5.4.3-$cashewOutputTag.apk"
    if (Test-Path -LiteralPath $outputApk) {
        if (-not (Test-Path -LiteralPath $outputApk -PathType Leaf) -or
            (Get-FileHash -LiteralPath $outputApk -Algorithm SHA256).Hash -ne $apkHash) {
            $suffix = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$($apkHash.Substring(0, 12).ToLowerInvariant())"
            $outputApk = Join-Path $cashewOutputDirectory "cashew-personal-5.4.3-$cashewOutputTag-$suffix.apk"
        }
    }
    if (Test-Path -LiteralPath $outputApk) {
        if (-not (Test-Path -LiteralPath $outputApk -PathType Leaf) -or
            (Get-FileHash -LiteralPath $outputApk -Algorithm SHA256).Hash -ne $apkHash) {
            throw "Refusing to overwrite an existing different output: $outputApk"
        }
    }
    else {
        # File.Copy(..., false) refuses to overwrite even if another process creates the file.
        [System.IO.File]::Copy($cashewBuiltApk, $outputApk, $false)
    }
    if ((Get-FileHash -LiteralPath $outputApk -Algorithm SHA256).Hash -ne $apkHash) {
        throw "Exported APK failed SHA-256 verification: $outputApk"
    }
    Write-Host "APK: $outputApk"
    Write-Host "Size: $($builtApk.Length) bytes ($([math]::Round($builtApk.Length / 1MB, 2)) MiB)"
    Write-Host "SHA256: $apkHash"
    if ($cashewPreviousApk) { Write-Host "Previous build APK retained: $cashewPreviousApk" }
}
finally {
    foreach ($environmentName in $environmentNames) {
        [Environment]::SetEnvironmentVariable($environmentName, $previousEnvironment[$environmentName], 'Process')
    }
    Pop-Location
    if ($cashewPreviousApk -and (Test-Path -LiteralPath $cashewPreviousApk -PathType Leaf) -and
        -not (Test-Path -LiteralPath $cashewBuiltApk)) {
        try {
            [System.IO.File]::Move($cashewPreviousApk, $cashewBuiltApk)
        }
        catch {
            Write-Warning "The previous APK could not be restored and remains at: $cashewPreviousApk"
        }
    }
}
