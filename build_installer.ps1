[CmdletBinding()]
param(
    [string]$PayloadArchivePath = "",
    [string]$InstallerName = "",
    [string]$OutputRoot = "",
    [string]$RuntimeIdentifier = "win-x64",
    [string]$Configuration = "Release",
    [switch]$KeepPublishOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

$projectRoot = [System.IO.Path]::GetFullPath($scriptRoot)
$defaultPayloadArchiveName = "PIF-player-build-20260422-no-csf.7z"
$bootstrapProjectPath = Join-Path $projectRoot "InstallerBootstrap\InstallerBootstrap.csproj"
$trailerMagic = [System.Text.Encoding]::ASCII.GetBytes("PIFINST1")

function Get-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [System.IO.Path]::GetFullPath($Path)
}

function Resolve-InputPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return Get-FullPath -Path $Path
    }

    return Get-FullPath -Path (Join-Path $projectRoot $Path)
}

function Assert-UnderRoot {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $fullPath = Get-FullPath -Path $Path
    $fullRoot = Get-FullPath -Path $Root
    $comparisonRoot = if ($fullRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $fullRoot
    } else {
        $fullRoot + [System.IO.Path]::DirectorySeparatorChar
    }

    if (($fullPath -ne $fullRoot) -and (-not $fullPath.StartsWith($comparisonRoot, [System.StringComparison]::OrdinalIgnoreCase))) {
        throw "Refusing to operate on path outside root. Path: $fullPath Root: $fullRoot"
    }
}

function Ensure-CleanDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = Get-FullPath -Path $Path
    Assert-UnderRoot -Path $fullPath -Root $resolvedOutputRoot

    if (Test-Path -LiteralPath $fullPath) {
        Remove-Item -LiteralPath $fullPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
}

function Copy-StreamData {
    param(
        [Parameter(Mandatory = $true)][System.IO.Stream]$InputStream,
        [Parameter(Mandatory = $true)][System.IO.Stream]$OutputStream
    )

    $buffer = New-Object byte[] (4MB)
    while (($bytesRead = $InputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $OutputStream.Write($buffer, 0, $bytesRead)
    }
}

function Get-FreeSpaceBytes {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = Get-FullPath -Path $Path
    $driveRoot = [System.IO.Path]::GetPathRoot($fullPath)
    $driveName = $driveRoot.TrimEnd("\", "/").TrimEnd(":")
    $psDrive = Get-PSDrive -Name $driveName
    return [int64]$psDrive.Free
}

function Format-Bytes {
    param([Parameter(Mandatory = $true)][int64]$Bytes)

    if ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }

    if ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    }

    if ($Bytes -ge 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    }

    return "{0} B" -f $Bytes
}

$resolvedOutputRoot = if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    Join-Path $projectRoot "dist"
} else {
    Resolve-InputPath -Path $OutputRoot
}
$resolvedPayloadArchive = if ([string]::IsNullOrWhiteSpace($PayloadArchivePath)) {
    Join-Path $projectRoot ("dist\{0}" -f $defaultPayloadArchiveName)
} else {
    Resolve-InputPath -Path $PayloadArchivePath
}

New-Item -ItemType Directory -Path $resolvedOutputRoot -Force | Out-Null

if ((-not (Test-Path -LiteralPath $resolvedPayloadArchive)) -and [string]::IsNullOrWhiteSpace($PayloadArchivePath)) {
    $packageReleaseScript = Join-Path $projectRoot "package_release.ps1"
    $releaseName = [System.IO.Path]::GetFileNameWithoutExtension($defaultPayloadArchiveName)
    $archiveOutputRoot = Split-Path -Parent $resolvedPayloadArchive

    if (-not (Test-Path -LiteralPath $packageReleaseScript)) {
        throw "Default payload archive not found and package_release.ps1 is missing: $packageReleaseScript"
    }

    Write-Host "Payload archive not found. Rebuilding it first."
    & powershell -ExecutionPolicy Bypass -File $packageReleaseScript -ReleaseName $releaseName -OutputRoot $archiveOutputRoot -Mode archive
    if ($LASTEXITCODE -ne 0) {
        throw "package_release.ps1 failed with exit code $LASTEXITCODE"
    }
}

if (-not (Test-Path -LiteralPath $resolvedPayloadArchive)) {
    throw "Payload archive not found: $resolvedPayloadArchive"
}

$payloadItem = Get-Item -LiteralPath $resolvedPayloadArchive
$resolvedInstallerName = if ([string]::IsNullOrWhiteSpace($InstallerName)) {
    "{0}-Setup" -f [System.IO.Path]::GetFileNameWithoutExtension($payloadItem.Name)
} else {
    [System.IO.Path]::GetFileNameWithoutExtension($InstallerName)
}

$publishRoot = Join-Path $resolvedOutputRoot "_installer_publish"
$publishAppDir = Join-Path $publishRoot "app"
$outputInstallerPath = Join-Path $resolvedOutputRoot ("{0}.exe" -f $resolvedInstallerName)
$hashPath = Join-Path $resolvedOutputRoot ("{0}.sha256.txt" -f $resolvedInstallerName)
$bootstrapExePath = Join-Path $publishAppDir "InstallerBootstrap.exe"

$estimatedNeededBytes = $payloadItem.Length + 350MB
$freeBytes = Get-FreeSpaceBytes -Path $resolvedOutputRoot
if ($freeBytes -lt $estimatedNeededBytes) {
    throw ("Not enough free space to build the installer. Need about {0}, found {1}." -f (Format-Bytes -Bytes $estimatedNeededBytes), (Format-Bytes -Bytes $freeBytes))
}

Ensure-CleanDirectory -Path $publishRoot

$publishArguments = @(
    "publish",
    $bootstrapProjectPath,
    "-c", $Configuration,
    "-r", $RuntimeIdentifier,
    "--self-contained", "true",
    "-p:PublishSingleFile=true",
    "-p:EnableCompressionInSingleFile=false",
    "-p:DebugType=None",
    "-p:DebugSymbols=false",
    "-o", $publishAppDir
)

Write-Host ("Publishing bootstrap app for {0}" -f $RuntimeIdentifier)
& dotnet @publishArguments
if ($LASTEXITCODE -ne 0) {
    throw "dotnet publish failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path -LiteralPath $bootstrapExePath)) {
    throw "Published bootstrap executable not found: $bootstrapExePath"
}

if (Test-Path -LiteralPath $outputInstallerPath) {
    Remove-Item -LiteralPath $outputInstallerPath -Force
}

$publishedBootstrapLength = (Get-Item -LiteralPath $bootstrapExePath).Length
$payloadOffset = 0L
$payloadLength = [int64]$payloadItem.Length

Write-Host ("Embedding payload archive: {0}" -f $payloadItem.FullName)
Write-Host ("Writing installer: {0}" -f $outputInstallerPath)

try {
    $outputStream = [System.IO.File]::Open($outputInstallerPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $bootstrapStream = [System.IO.File]::OpenRead($bootstrapExePath)
        try {
            Copy-StreamData -InputStream $bootstrapStream -OutputStream $outputStream
        }
        finally {
            $bootstrapStream.Dispose()
        }

        $payloadOffset = $outputStream.Position

        $payloadStream = [System.IO.File]::OpenRead($payloadItem.FullName)
        try {
            Copy-StreamData -InputStream $payloadStream -OutputStream $outputStream
        }
        finally {
            $payloadStream.Dispose()
        }

        $binaryWriter = New-Object System.IO.BinaryWriter($outputStream, [System.Text.Encoding]::ASCII, $true)
        try {
            $binaryWriter.Write($trailerMagic)
            $binaryWriter.Write([int64]$payloadOffset)
            $binaryWriter.Write([int64]$payloadLength)
            $binaryWriter.Flush()
        }
        finally {
            $binaryWriter.Dispose()
        }
    }
    finally {
        $outputStream.Dispose()
    }
}
catch {
    if (Test-Path -LiteralPath $outputInstallerPath) {
        Remove-Item -LiteralPath $outputInstallerPath -Force
    }

    throw
}

$installerHash = Get-FileHash -LiteralPath $outputInstallerPath -Algorithm SHA256
Set-Content -LiteralPath $hashPath -Value ("{0} *{1}" -f $installerHash.Hash.ToLowerInvariant(), (Split-Path -Leaf $outputInstallerPath)) -Encoding ASCII

if (-not $KeepPublishOutput) {
    Remove-Item -LiteralPath $publishRoot -Recurse -Force
}

$summaryLines = @(
    ("Payload: {0}" -f $payloadItem.FullName),
    ("Payload size: {0}" -f (Format-Bytes -Bytes $payloadItem.Length)),
    ("Bootstrap size: {0}" -f (Format-Bytes -Bytes $publishedBootstrapLength)),
    ("Payload offset: {0}" -f $payloadOffset),
    ("Installer: {0}" -f $outputInstallerPath),
    ("Installer size: {0}" -f (Format-Bytes -Bytes (Get-Item -LiteralPath $outputInstallerPath).Length)),
    ("SHA256: {0}" -f $hashPath)
)

Write-Host ""
Write-Host ($summaryLines -join [Environment]::NewLine)
