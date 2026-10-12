$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$cashewRoot = Split-Path -Parent $PSScriptRoot
$cashewTooling = Join-Path $cashewRoot '.tooling'
$cashewDownloads = Join-Path $cashewTooling 'downloads'
$cashewJdkRoot = Join-Path $cashewTooling 'jdk\jdk-17.0.20.1+1'
$cashewSdkRoot = Join-Path $cashewTooling 'android-sdk'
$cashewCommandTools = Join-Path $cashewSdkRoot 'cmdline-tools\23.0'
$cashewJdkUrl = 'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.20.1%2B1/OpenJDK17U-jdk_x64_windows_hotspot_17.0.20.1_1.zip'
$cashewJdkHash = 'e53a79c3c3d86865bd7e787903884331068e71321714ffd44f145785affc7cb0'
$cashewCommandToolsUrl = 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip'
$cashewCommandToolsHash = '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a'

function Get-CashewContainedToolingPath {
    param([string]$CandidatePath)

    $toolingPath = [System.IO.Path]::GetFullPath($cashewTooling).TrimEnd('\', '/')
    $fullPath = [System.IO.Path]::GetFullPath($CandidatePath)
    if (-not $fullPath.StartsWith("$toolingPath\", [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing a toolchain operation outside the project .tooling directory: $fullPath"
    }
    # An existing junction could redirect an otherwise-contained path outside .tooling.
    $ancestorPath = $fullPath
    while ($ancestorPath) {
        if (Test-Path -LiteralPath $ancestorPath) {
            $ancestor = Get-Item -LiteralPath $ancestorPath -Force
            if (($ancestor.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Refusing a toolchain path through a junction or symbolic link: $ancestorPath"
            }
        }
        if ($ancestorPath.Equals($toolingPath, [StringComparison]::OrdinalIgnoreCase)) { break }
        $ancestorPath = Split-Path -Parent $ancestorPath
    }
    return $fullPath
}

function Get-CashewVerifiedArchive {
    param([string]$Url, [string]$FileName, [string]$ExpectedHash)

    $archivePath = Get-CashewContainedToolingPath (Join-Path $cashewDownloads $FileName)
    if (Test-Path -LiteralPath $archivePath) {
        if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf) -or
            (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne $ExpectedHash) {
            throw "Existing download failed SHA-256 verification and was left unchanged: $archivePath"
        }
        return $archivePath
    }

    New-Item -ItemType Directory -Path $cashewDownloads -Force | Out-Null
    $partialPath = Get-CashewContainedToolingPath "$archivePath.$([guid]::NewGuid().ToString('N')).partial"
    Write-Host "Downloading $FileName into the project toolchain..."
    Invoke-WebRequest -Uri $Url -OutFile $partialPath -UseBasicParsing
    if ((Get-FileHash -LiteralPath $partialPath -Algorithm SHA256).Hash -ne $ExpectedHash) {
        throw "Downloaded archive failed SHA-256 verification; it was not extracted: $partialPath"
    }
    $partialPath = Get-CashewContainedToolingPath $partialPath
    $archivePath = Get-CashewContainedToolingPath $archivePath
    [System.IO.File]::Move($partialPath, $archivePath)
    return $archivePath
}

function Install-CashewArchive {
    param([string]$ArchivePath, [string]$ArchiveDirectory, [string]$TargetDirectory)

    if (Test-Path -LiteralPath $TargetDirectory) {
        throw "Refusing to replace an existing toolchain directory: $TargetDirectory"
    }
    $TargetDirectory = Get-CashewContainedToolingPath $TargetDirectory
    $stagingDirectory = Get-CashewContainedToolingPath (Join-Path $cashewTooling "setup-staging-$([guid]::NewGuid().ToString('N'))")
    New-Item -ItemType Directory -Path $stagingDirectory | Out-Null
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $stagingDirectory
    $extractedDirectory = Join-Path $stagingDirectory $ArchiveDirectory
    if (-not (Test-Path -LiteralPath $extractedDirectory -PathType Container)) {
        throw "Archive has an unexpected directory layout. Extraction was preserved: $stagingDirectory"
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $TargetDirectory) -Force | Out-Null
    $extractedDirectory = Get-CashewContainedToolingPath $extractedDirectory
    $TargetDirectory = Get-CashewContainedToolingPath $TargetDirectory
    [System.IO.Directory]::Move($extractedDirectory, $TargetDirectory)
    # Remove only this now-empty staging directory; preserve unexpected archive contents.
    if (@(Get-ChildItem -LiteralPath $stagingDirectory -Force).Count -eq 0) {
        [System.IO.Directory]::Delete($stagingDirectory, $false)
    }
}

function Assert-CashewSignedExecutable {
    param([string]$ExecutablePath, [string]$SignerName)

    if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
        throw "Required executable is missing: $ExecutablePath"
    }
    $signature = Get-AuthenticodeSignature -LiteralPath $ExecutablePath
    if ($signature.Status -ne 'Valid' -or -not $signature.SignerCertificate -or
        $signature.SignerCertificate.Subject -notmatch [regex]::Escape($SignerName)) {
        throw "Executable has no valid expected publisher signature: $ExecutablePath"
    }
}

$cashewJdkRoot = Get-CashewContainedToolingPath $cashewJdkRoot
$cashewCommandTools = Get-CashewContainedToolingPath $cashewCommandTools
if (-not (Test-Path -LiteralPath $cashewJdkRoot)) {
    $jdkArchive = Get-CashewVerifiedArchive -Url $cashewJdkUrl `
        -FileName 'OpenJDK17U-jdk_x64_windows_hotspot_17.0.20.1_1.zip' -ExpectedHash $cashewJdkHash
    Install-CashewArchive -ArchivePath $jdkArchive -ArchiveDirectory 'jdk-17.0.20.1+1' `
        -TargetDirectory $cashewJdkRoot
}
$jdkReleasePath = Join-Path $cashewJdkRoot 'release'
if (-not (Test-Path -LiteralPath $jdkReleasePath -PathType Leaf) -or
    -not (Select-String -LiteralPath $jdkReleasePath -Pattern '^JAVA_VERSION="17\.0\.20\.1"$' -Quiet)) {
    throw "Existing JDK is not the pinned Temurin 17.0.20.1. It was left unchanged: $cashewJdkRoot"
}
Assert-CashewSignedExecutable -ExecutablePath (Join-Path $cashewJdkRoot 'bin\java.exe') `
    -SignerName 'Eclipse Foundation'
Assert-CashewSignedExecutable -ExecutablePath (Join-Path $cashewJdkRoot 'bin\javac.exe') `
    -SignerName 'Eclipse Foundation'

if (-not (Test-Path -LiteralPath $cashewCommandTools)) {
    $toolsArchive = Get-CashewVerifiedArchive -Url $cashewCommandToolsUrl `
        -FileName 'commandlinetools-win-15859902_latest.zip' -ExpectedHash $cashewCommandToolsHash
    Install-CashewArchive -ArchivePath $toolsArchive -ArchiveDirectory 'cmdline-tools' `
        -TargetDirectory $cashewCommandTools
}
$commandToolsProperties = Join-Path $cashewCommandTools 'source.properties'
if (-not (Test-Path -LiteralPath $commandToolsProperties -PathType Leaf) -or
    -not (Select-String -LiteralPath $commandToolsProperties -Pattern '^Pkg\.Revision\s*=\s*23\.0\s*$' -Quiet)) {
    throw "Existing Android command-line tools are not pinned revision 23.0. They were left unchanged: $cashewCommandTools"
}
$androidCli = Join-Path $cashewCommandTools 'bin\android.exe'
Assert-CashewSignedExecutable -ExecutablePath $androidCli -SignerName 'Google LLC'

$sdkPackages = @(
    @{ Name = 'platforms/android-34'; Directory = 'platforms\android-34'; Files = @('platforms\android-34\android.jar'); RevisionPattern = '^AndroidVersion\.ApiLevel\s*=\s*34\s*$' },
    @{ Name = 'build-tools/34.0.0'; Directory = 'build-tools\34.0.0'; Files = @('build-tools\34.0.0\aapt2.exe', 'build-tools\34.0.0\zipalign.exe', 'build-tools\34.0.0\apksigner.bat'); RevisionPattern = '^Pkg\.Revision\s*=\s*34\.0\.0\s*$' },
    @{ Name = 'platform-tools'; Directory = 'platform-tools'; Files = @('platform-tools\adb.exe'); RevisionPattern = '^Pkg\.Revision\s*=' }
)
$missingPackages = @()
foreach ($package in $sdkPackages) {
    $packageDirectory = Join-Path $cashewSdkRoot $package.Directory
    if (-not (Test-Path -LiteralPath $packageDirectory)) {
        $missingPackages += $package.Name
        continue
    }
    foreach ($requiredFile in $package.Files) {
        if (-not (Test-Path -LiteralPath (Join-Path $cashewSdkRoot $requiredFile) -PathType Leaf)) {
            throw "Existing Android package is incomplete and was left unchanged: $packageDirectory"
        }
    }
    $packageProperties = Join-Path $packageDirectory 'source.properties'
    if (-not (Test-Path -LiteralPath $packageProperties -PathType Leaf) -or
        -not (Select-String -LiteralPath $packageProperties -Pattern $package.RevisionPattern -Quiet)) {
        throw "Existing Android package has unexpected metadata and was left unchanged: $packageDirectory"
    }
}

$previousEnvironment = @{}
$environmentNames = @('JAVA_HOME', 'ANDROID_HOME', 'ANDROID_SDK_ROOT', 'ANDROID_USER_HOME', 'PATH')
foreach ($environmentName in $environmentNames) {
    $previousEnvironment[$environmentName] = [Environment]::GetEnvironmentVariable($environmentName, 'Process')
}
try {
    $env:JAVA_HOME = $cashewJdkRoot
    $env:ANDROID_HOME = $cashewSdkRoot
    $env:ANDROID_SDK_ROOT = $cashewSdkRoot
    $env:ANDROID_USER_HOME = Join-Path $cashewTooling 'android-user'
    $env:PATH = "$(Join-Path $cashewJdkRoot 'bin');$($previousEnvironment['PATH'])"
    New-Item -ItemType Directory -Path $env:ANDROID_USER_HOME -Force | Out-Null

    & (Join-Path $cashewJdkRoot 'bin\java.exe') -version
    if ($LASTEXITCODE -ne 0) { throw 'Pinned Java version check failed.' }
    & $androidCli --no-metrics --version
    if ($LASTEXITCODE -ne 0) { throw 'Android CLI version check failed.' }
    if ($missingPackages.Count -gt 0) {
        Write-Host 'Installing project-local Android packages. Accept the official license prompt if shown.'
        & $androidCli --no-metrics "--sdk=$cashewSdkRoot" sdk install @missingPackages
        if ($LASTEXITCODE -ne 0) { throw 'Android SDK package installation failed.' }
    }
    foreach ($package in $sdkPackages) {
        foreach ($requiredFile in $package.Files) {
            if (-not (Test-Path -LiteralPath (Join-Path $cashewSdkRoot $requiredFile) -PathType Leaf)) {
                throw "SDK installation did not produce required file: $requiredFile"
            }
        }
        $packageProperties = Join-Path (Join-Path $cashewSdkRoot $package.Directory) 'source.properties'
        if (-not (Test-Path -LiteralPath $packageProperties -PathType Leaf) -or
            -not (Select-String -LiteralPath $packageProperties -Pattern $package.RevisionPattern -Quiet)) {
            throw "SDK installation did not produce the expected package metadata: $($package.Name)"
        }
    }
    Assert-CashewSignedExecutable -ExecutablePath (Join-Path $cashewSdkRoot 'platform-tools\adb.exe') -SignerName 'Google LLC'
    Write-Host "Android toolchain is ready: $cashewSdkRoot"
    Write-Host "JDK: $cashewJdkRoot"
}
finally {
    foreach ($environmentName in $environmentNames) {
        [Environment]::SetEnvironmentVariable($environmentName, $previousEnvironment[$environmentName], 'Process')
    }
}
