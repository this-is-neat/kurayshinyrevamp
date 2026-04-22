[CmdletBinding()]
param(
    [string]$ReleaseName = "PIF-player-build-20260422-no-csf-update1",
    [string]$PreviousManifestPath = "",
    [string]$OutputRoot = "",
    [switch]$KeepStage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

$projectRoot = [System.IO.Path]::GetFullPath($scriptRoot)
$resolvedOutputRoot = if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    Join-Path $projectRoot "dist"
} else {
    [System.IO.Path]::GetFullPath($OutputRoot)
}
$resolvedPreviousManifestPath = if ([string]::IsNullOrWhiteSpace($PreviousManifestPath)) {
    Join-Path $resolvedOutputRoot "PIF-player-build-20260422-no-csf.manifest.txt"
} else {
    [System.IO.Path]::GetFullPath($PreviousManifestPath)
}

$stageRoot = Join-Path $resolvedOutputRoot $ReleaseName
$packageRoot = Join-Path $stageRoot "PIF"
$archivePath = Join-Path $resolvedOutputRoot ("{0}.7z" -f $ReleaseName)
$manifestPath = Join-Path $resolvedOutputRoot ("{0}.manifest.txt" -f $ReleaseName)
$hashPath = Join-Path $resolvedOutputRoot ("{0}.sha256.txt" -f $ReleaseName)
$sevenZipPath = Join-Path $projectRoot "REQUIRED_BY_INSTALLER_UPDATER\7z.exe"

$includeDirectories = @(
    "Audio",
    "Data",
    "Fonts",
    "Graphics",
    "Libs",
    "Mods",
    "KIFM"
)

$includeFiles = @(
    "Game.exe",
    "Game-compatibility.exe",
    "Game.ini",
    "mkxp.json",
    "README.md",
    "PIF_readme.txt",
    "PIF_Credits.txt",
    "RGSS100J.dll",
    "RGSS104E.dll",
    "Shiny Finder.bat",
    "Shiny Finder.exe",
    "Shiny Finder.pck",
    "x64-msvcrt-ruby300.dll",
    "x64-msvcrt-ruby310.dll",
    "zlib1.dll"
)

$cleanupPaths = @(
    "Data\.idea",
    "Data\.DS_Store",
    "Data\sprites\sprites_rate_limit.log",
    "Mods\compat_report.txt",
    "Mods\mod_manager_state.json",
    "KIFM\platinum_uuids.txt",
    "KIFM\discord_ids.txt",
    "KIFM\pending_discord_link.txt",
    "KIFM\coop_debug.log",
    "KIFM\pvp_wins.txt",
    "KIFM\discord_link.log"
)

$excludedPackagePaths = @(
    "Mods\custom_species_framework",
    "Data\encounters.json",
    "Data\starter_sets.json",
    "Data\trainer_hooks.json",
    "Data\species",
    "Graphics\Battlers\1202",
    "Graphics\Battlers\1203",
    "Graphics\Battlers\1204",
    "Graphics\Battlers\1205",
    "Graphics\Battlers\1206",
    "Graphics\CustomBattlers\indexed\1202",
    "Graphics\CustomBattlers\indexed\1203",
    "Graphics\CustomBattlers\indexed\1204",
    "Graphics\CustomBattlers\indexed\1205",
    "Graphics\CustomBattlers\indexed\1206",
    "Graphics\Icons\icon1202.png",
    "Graphics\Icons\icon1203.png",
    "Graphics\Icons\icon1204.png",
    "Graphics\Icons\icon1205.png",
    "Graphics\Icons\icon1206.png",
    "Graphics\Pokemon\Back\CSF_AQUALITH.png",
    "Graphics\Pokemon\Back\CSF_CINDRAKE.png",
    "Graphics\Pokemon\Back\CSF_VERDALYK.png",
    "Graphics\Pokemon\Front\CSF_AQUALITH.png",
    "Graphics\Pokemon\Front\CSF_CINDRAKE.png",
    "Graphics\Pokemon\Front\CSF_VERDALYK.png",
    "Graphics\Pokemon\Icons\CSF_AQUALITH.png",
    "Graphics\Pokemon\Icons\CSF_CINDRAKE.png",
    "Graphics\Pokemon\Icons\CSF_VERDALYK.png",
    "Graphics\Pokemon\Icons\CSF_SANDSHREW_GLACIAL.png",
    "Graphics\Pokemon\Icons\CSF_SANDSLASH_GLACIAL.png"
)

$cleanupRecursiveFileNames = @(
    ".DS_Store",
    "Thumbs.db"
)

$cleanupRecursiveDirectoryNames = @(
    ".idea",
    "__pycache__"
)

function Get-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [System.IO.Path]::GetFullPath($Path)
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

function Normalize-RelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return ($Path -replace '/', '\').TrimStart('\')
}

function Parse-ManifestCutoff {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Previous manifest not found: $Path"
    }

    $generatedLine = Get-Content -LiteralPath $Path | Where-Object { $_ -like 'Generated at:*' } | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($generatedLine)) {
        throw "Could not find 'Generated at:' in previous manifest: $Path"
    }

    $timestampText = $generatedLine.Substring('Generated at:'.Length).Trim()
    return [DateTimeOffset]::Parse($timestampText)
}

function New-PathSets {
    $excludedExact = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $excludedPrefixes = New-Object System.Collections.Generic.List[string]

    foreach ($path in $cleanupPaths + $excludedPackagePaths) {
        $normalized = Normalize-RelativePath $path
        if ([System.IO.Path]::GetExtension($normalized)) {
            [void]$excludedExact.Add($normalized)
        } else {
            $excludedPrefixes.Add(($normalized.TrimEnd('\') + '\'))
        }
    }

    $directoryNames = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $cleanupRecursiveDirectoryNames) {
        [void]$directoryNames.Add($name)
    }

    $fileNames = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $cleanupRecursiveFileNames) {
        [void]$fileNames.Add($name)
    }

    return [PSCustomObject]@{
        ExcludedExact = $excludedExact
        ExcludedPrefixes = $excludedPrefixes
        DirectoryNames = $directoryNames
        FileNames = $fileNames
    }
}

function Test-PackagedRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)]$PathSets
    )

    $normalized = Normalize-RelativePath $RelativePath
    if ($PathSets.ExcludedExact.Contains($normalized)) {
        return $false
    }

    foreach ($prefix in $PathSets.ExcludedPrefixes) {
        if ($normalized.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $false
        }
    }

    foreach ($segment in $normalized.Split('\')) {
        if ($PathSets.DirectoryNames.Contains($segment)) {
            return $false
        }
    }

    $fileName = [System.IO.Path]::GetFileName($normalized)
    if ($PathSets.FileNames.Contains($fileName)) {
        return $false
    }

    return $true
}

function Get-PackagedFiles {
    param([Parameter(Mandatory = $true)]$PathSets)

    $packagedFiles = New-Object System.Collections.Generic.List[object]

    foreach ($relativeDirectory in $includeDirectories) {
        $fullDirectory = Join-Path $projectRoot $relativeDirectory
        if (-not (Test-Path -LiteralPath $fullDirectory)) {
            continue
        }

        Get-ChildItem -LiteralPath $fullDirectory -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $relativePath = $_.FullName.Substring($projectRoot.Length).TrimStart('\')
            if (Test-PackagedRelativePath -RelativePath $relativePath -PathSets $PathSets) {
                $packagedFiles.Add([PSCustomObject]@{
                    RelativePath = $relativePath
                    SourcePath = $_.FullName
                    Length = $_.Length
                    LastWriteTime = [DateTimeOffset]$_.LastWriteTime
                })
            }
        }
    }

    foreach ($relativeFile in $includeFiles) {
        $fullPath = Join-Path $projectRoot $relativeFile
        if (-not (Test-Path -LiteralPath $fullPath)) {
            continue
        }

        if (Test-PackagedRelativePath -RelativePath $relativeFile -PathSets $PathSets) {
            $item = Get-Item -LiteralPath $fullPath
            $packagedFiles.Add([PSCustomObject]@{
                RelativePath = $relativeFile
                SourcePath = $item.FullName
                Length = $item.Length
                LastWriteTime = [DateTimeOffset]$item.LastWriteTime
            })
        }
    }

    return $packagedFiles
}

function Copy-ChangedFilesToStage {
    param([Parameter(Mandatory = $true)][object[]]$Files)

    foreach ($file in $Files) {
        $destinationPath = Join-Path $packageRoot $file.RelativePath
        $destinationDirectory = Split-Path -Parent $destinationPath
        if ($destinationDirectory) {
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
        }

        Copy-Item -LiteralPath $file.SourcePath -Destination $destinationPath -Force
    }
}

function New-OverlayPlayerReadme {
    param(
        [Parameter(Mandatory = $true)][DateTimeOffset]$Cutoff,
        [Parameter(Mandatory = $true)][int]$ChangedCount
    )

    $lines = @(
        "Kuray Infinite Fusion Overlay Update",
        "",
        "This package only contains files that changed after the base no-CSF player build generated at {0}." -f $Cutoff.ToString("yyyy-MM-dd HH:mm:ss zzz"),
        "It is meant to be applied on top of the existing 2026-04-22 no-CSF release.",
        "",
        "What this update expects",
        "- Fresh installs should use the updated WebSetup installer so it can download the base release first and then apply this overlay automatically.",
        "- Existing installs from the public 2026-04-22 no-CSF release can apply this update directly through the same updated WebSetup installer.",
        "",
        "Changed packaged files in this overlay: {0}" -f $ChangedCount
    )

    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function New-OverlayManifest {
    param(
        [Parameter(Mandatory = $true)][DateTimeOffset]$Cutoff,
        [Parameter(Mandatory = $true)][object[]]$ChangedFiles,
        [Parameter(Mandatory = $true)][int64]$ChangedBytes
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Overlay Build Manifest")
    $lines.Add("")
    $lines.Add(("Project root: {0}" -f $projectRoot))
    $lines.Add("Package root folder name: PIF")
    $lines.Add(("Generated at: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")))
    $lines.Add(("Base manifest cutoff: {0}" -f $Cutoff.ToString("yyyy-MM-dd HH:mm:ss zzz")))
    $lines.Add(("Changed file count: {0}" -f $ChangedFiles.Count))
    $lines.Add(("Changed payload size: {0:N3} MB" -f ($ChangedBytes / 1MB)))
    $lines.Add("")
    $lines.Add("Changed packaged files:")
    foreach ($file in $ChangedFiles) {
        $lines.Add((" - {0} ({1} bytes, {2})" -f $file.RelativePath, $file.Length, $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss zzz")))
    }

    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

if (-not (Test-Path -LiteralPath $sevenZipPath)) {
    throw "7z.exe was not found at $sevenZipPath"
}

New-Item -ItemType Directory -Path $resolvedOutputRoot -Force | Out-Null
$pathSets = New-PathSets
$cutoff = Parse-ManifestCutoff -Path $resolvedPreviousManifestPath
$packagedFiles = Get-PackagedFiles -PathSets $pathSets
$changedFiles = @($packagedFiles | Where-Object { $_.LastWriteTime -gt $cutoff } | Sort-Object RelativePath)

if ($changedFiles.Count -eq 0) {
    throw "No packaged files changed after the previous manifest cutoff ($($cutoff.ToString('yyyy-MM-dd HH:mm:ss zzz')))."
}

$changedBytes = [int64](($changedFiles | Measure-Object -Property Length -Sum).Sum)

Write-Host ("Building overlay stage at {0}" -f $stageRoot)
Ensure-CleanDirectory -Path $stageRoot
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null
Copy-ChangedFilesToStage -Files $changedFiles

$playerReadmePath = Join-Path $packageRoot "PLAYER_RELEASE_README.txt"
$buildManifestPath = Join-Path $packageRoot "PACKAGED_BUILD_MANIFEST.txt"
Set-Content -LiteralPath $playerReadmePath -Value (New-OverlayPlayerReadme -Cutoff $cutoff -ChangedCount $changedFiles.Count) -Encoding UTF8
Set-Content -LiteralPath $buildManifestPath -Value (New-OverlayManifest -Cutoff $cutoff -ChangedFiles $changedFiles -ChangedBytes $changedBytes) -Encoding UTF8
Set-Content -LiteralPath $manifestPath -Value (New-OverlayManifest -Cutoff $cutoff -ChangedFiles $changedFiles -ChangedBytes $changedBytes) -Encoding UTF8

if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
}

Write-Host ("Creating overlay archive at {0}" -f $archivePath)
Push-Location $stageRoot
try {
    & $sevenZipPath a -t7z -mx=3 -mmt=on $archivePath "PIF" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "7z archive creation failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

$archiveHash = Get-FileHash -LiteralPath $archivePath -Algorithm SHA256
Set-Content -LiteralPath $hashPath -Value ("{0} *{1}" -f $archiveHash.Hash.ToLowerInvariant(), (Split-Path -Leaf $archivePath)) -Encoding ASCII

if (-not $KeepStage) {
    Remove-Item -LiteralPath $stageRoot -Recurse -Force
}

Write-Host ""
Write-Host ("Changed packaged files: {0}" -f $changedFiles.Count)
Write-Host ("Changed payload size: {0:N3} MB" -f ($changedBytes / 1MB))
Write-Host ("Archive: {0}" -f $archivePath)
Write-Host ("SHA256: {0}" -f $hashPath)
