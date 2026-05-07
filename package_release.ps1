[CmdletBinding()]
param(
    [string]$ReleaseName = "",
    [string]$OutputRoot = "",
    [ValidateSet("archive", "stage", "both")]
    [string]$Mode = "archive"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

$projectRoot = [System.IO.Path]::GetFullPath($scriptRoot)
$projectName = Split-Path -Leaf $projectRoot
$resolvedReleaseName = if ([string]::IsNullOrWhiteSpace($ReleaseName)) {
    "{0}-player-build-{1}" -f $projectName, (Get-Date -Format "yyyyMMdd-HHmmss")
} else {
    $ReleaseName
}
$resolvedOutputRoot = if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    Join-Path $projectRoot "dist"
} else {
    $OutputRoot
}

$outputRootFull = [System.IO.Path]::GetFullPath($resolvedOutputRoot)
$stageRoot = Join-Path $outputRootFull $resolvedReleaseName
$packageRoot = Join-Path $stageRoot $projectName
$archivePath = Join-Path $outputRootFull ("{0}.7z" -f $resolvedReleaseName)
$manifestPath = Join-Path $outputRootFull ("{0}.manifest.txt" -f $resolvedReleaseName)
$hashPath = Join-Path $outputRootFull ("{0}.sha256.txt" -f $resolvedReleaseName)
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

$temporaryMetadataFiles = @(
    "PLAYER_RELEASE_README.txt",
    "PACKAGED_BUILD_MANIFEST.txt"
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
    Assert-UnderRoot -Path $fullPath -Root $outputRootFull

    if (Test-Path -LiteralPath $fullPath) {
        Remove-Item -LiteralPath $fullPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
}

function Get-DirectorySizeBytes {
    param([Parameter(Mandatory = $true)][string[]]$RelativeDirectories)

    $sum = 0L
    foreach ($relativeDirectory in $RelativeDirectories) {
        $fullDirectory = Join-Path $projectRoot $relativeDirectory
        if (Test-Path -LiteralPath $fullDirectory) {
            $directoryBytes = (Get-ChildItem -LiteralPath $fullDirectory -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            if ($null -ne $directoryBytes) {
                $sum += [int64]$directoryBytes
            }
        }
    }

    foreach ($relativeFile in $includeFiles) {
        $fullFile = Join-Path $projectRoot $relativeFile
        if (Test-Path -LiteralPath $fullFile) {
            $sum += (Get-Item -LiteralPath $fullFile).Length
        }
    }

    return $sum
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

function Get-FreeSpaceBytes {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = Get-FullPath -Path $Path
    $driveRoot = [System.IO.Path]::GetPathRoot($fullPath)
    $driveName = $driveRoot.TrimEnd("\", "/").TrimEnd(":")
    $psDrive = Get-PSDrive -Name $driveName
    return [int64]$psDrive.Free
}

function Copy-DirectoryTree {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRelative,
        [Parameter(Mandatory = $true)][string]$DestinationRoot
    )

    $source = Join-Path $projectRoot $SourceRelative
    $destination = Join-Path $DestinationRoot $SourceRelative
    New-Item -ItemType Directory -Path $destination -Force | Out-Null

    $arguments = @(
        $source,
        $destination,
        "/E",
        "/R:1",
        "/W:1",
        "/NFL",
        "/NDL",
        "/NJH",
        "/NJS",
        "/NP"
    )

    & robocopy @arguments | Out-Null
    $exitCode = $LASTEXITCODE
    if ($exitCode -gt 7) {
        throw "robocopy failed for $SourceRelative with exit code $exitCode"
    }
}

function Copy-IncludedFiles {
    param([Parameter(Mandatory = $true)][string]$DestinationRoot)

    foreach ($relativeFile in $includeFiles) {
        $source = Join-Path $projectRoot $relativeFile
        $destination = Join-Path $DestinationRoot $relativeFile
        $destinationDirectory = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $source)) {
            throw "Required file missing: $relativeFile"
        }

        if ($destinationDirectory) {
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
        }

        Copy-Item -LiteralPath $source -Destination $destination -Force
    }
}

function Remove-CleanupPaths {
    param([Parameter(Mandatory = $true)][string]$RootPath)

    foreach ($relativePath in $cleanupPaths) {
        $fullPath = Join-Path $RootPath $relativePath
        if (Test-Path -LiteralPath $fullPath) {
            Assert-UnderRoot -Path $fullPath -Root $RootPath
            Remove-Item -LiteralPath $fullPath -Recurse -Force
        }
    }

    foreach ($relativePath in $excludedPackagePaths) {
        $fullPath = Join-Path $RootPath $relativePath
        if (Test-Path -LiteralPath $fullPath) {
            Assert-UnderRoot -Path $fullPath -Root $RootPath
            Remove-Item -LiteralPath $fullPath -Recurse -Force
        }
    }

    foreach ($fileName in $cleanupRecursiveFileNames) {
        Get-ChildItem -LiteralPath $RootPath -Recurse -Force -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ieq $fileName } |
            ForEach-Object {
                Assert-UnderRoot -Path $_.FullName -Root $RootPath
                Remove-Item -LiteralPath $_.FullName -Force
            }
    }

    foreach ($directoryName in $cleanupRecursiveDirectoryNames) {
        Get-ChildItem -LiteralPath $RootPath -Recurse -Force -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ieq $directoryName } |
            Sort-Object FullName -Descending |
            ForEach-Object {
                Assert-UnderRoot -Path $_.FullName -Root $RootPath
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
            }
    }
}

function New-PlayerReadmeContent {
    $lines = @(
        "Kuray Infinite Fusion Player Build",
        "",
        "How to use this package",
        "1. Extract the archive into its own folder.",
        "2. Launch Game.exe. If that has compatibility issues on your machine, try Game-compatibility.exe.",
        "3. Keep the Audio, Data, Fonts, Graphics, Libs, Mods, and KIFM folders next to the game executable.",
        "",
        "What is included",
        "- Full game client data and graphics, including the packed sprite payload.",
        "- The current Mods folder and multiplayer KIFM folder used by this build.",
        "- Shiny Finder utility files that ship with the client.",
        "",
        "What was intentionally excluded",
        "- Personal configuration and local state files.",
        "- Savefile shortcuts, debug logs, Discord bot files, and updater scripts tied to an older release flow.",
        "- Experimental custom_species_framework content and its generated assets are not included in this package yet.",
        "",
        "Savefiles and user settings",
        "- Savefiles and some settings are stored outside this folder under %APPDATA%\\kurayinfinitefusion.",
        "- This package does not include personal save data.",
        "",
        ("Packaged on: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"))
    )

    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function New-ManifestContent {
    param(
        [Parameter(Mandatory = $true)][string]$SelectedMode,
        [Parameter(Mandatory = $true)][int64]$IncludedBytes
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Packaged Build Manifest")
    $lines.Add("")
    $lines.Add(("Project root: {0}" -f $projectRoot))
    $lines.Add(("Package root folder name: {0}" -f $projectName))
    $lines.Add(("Packaging mode: {0}" -f $SelectedMode))
    $lines.Add(("Included source size: {0}" -f (Format-Bytes -Bytes $IncludedBytes)))
    $lines.Add(("Generated at: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")))
    $lines.Add("")
    $lines.Add("Included directories:")
    foreach ($relativeDirectory in $includeDirectories) {
        $lines.Add((" - {0}" -f $relativeDirectory))
    }
    $lines.Add("")
    $lines.Add("Included root files:")
    foreach ($relativeFile in $includeFiles) {
        $lines.Add((" - {0}" -f $relativeFile))
    }
    $lines.Add("")
    $lines.Add("Cleanup removals after copy:")
    foreach ($relativePath in $cleanupPaths) {
        $lines.Add((" - {0}" -f $relativePath))
    }
    $lines.Add("")
    $lines.Add("Excluded package paths:")
    foreach ($relativePath in $excludedPackagePaths) {
        $lines.Add((" - {0}" -f $relativePath))
    }
    $lines.Add("")
    $lines.Add("Recursive cleanup file names:")
    foreach ($fileName in $cleanupRecursiveFileNames) {
        $lines.Add((" - {0}" -f $fileName))
    }
    $lines.Add("")
    $lines.Add("Recursive cleanup directory names:")
    foreach ($directoryName in $cleanupRecursiveDirectoryNames) {
        $lines.Add((" - {0}" -f $directoryName))
    }

    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function Write-MetadataFiles {
    param(
        [Parameter(Mandatory = $true)][string]$RootPath,
        [Parameter(Mandatory = $true)][string]$SelectedMode,
        [Parameter(Mandatory = $true)][int64]$IncludedBytes
    )

    $playerReadmePath = Join-Path $RootPath "PLAYER_RELEASE_README.txt"
    $buildManifestPath = Join-Path $RootPath "PACKAGED_BUILD_MANIFEST.txt"

    Set-Content -LiteralPath $playerReadmePath -Value (New-PlayerReadmeContent) -Encoding UTF8
    Set-Content -LiteralPath $buildManifestPath -Value (New-ManifestContent -SelectedMode $SelectedMode -IncludedBytes $IncludedBytes) -Encoding UTF8
}

function Remove-TemporaryMetadataFiles {
    param([Parameter(Mandatory = $true)][string]$RootPath)

    foreach ($fileName in $temporaryMetadataFiles) {
        $fullPath = Join-Path $RootPath $fileName
        if (Test-Path -LiteralPath $fullPath) {
            Remove-Item -LiteralPath $fullPath -Force
        }
    }
}

function Build-StageDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$StageRootPath,
        [Parameter(Mandatory = $true)][string]$PackageRootPath,
        [Parameter(Mandatory = $true)][int64]$IncludedBytes
    )

    Write-Host ("Creating staged package folder at {0}" -f $StageRootPath)
    Ensure-CleanDirectory -Path $StageRootPath
    New-Item -ItemType Directory -Path $PackageRootPath -Force | Out-Null

    foreach ($relativeDirectory in $includeDirectories) {
        Write-Host ("Copying directory: {0}" -f $relativeDirectory)
        Copy-DirectoryTree -SourceRelative $relativeDirectory -DestinationRoot $PackageRootPath
    }

    Write-Host "Copying root files"
    Copy-IncludedFiles -DestinationRoot $PackageRootPath
    Write-MetadataFiles -RootPath $PackageRootPath -SelectedMode $Mode -IncludedBytes $IncludedBytes
    Remove-CleanupPaths -RootPath $PackageRootPath
}

function Build-ArchiveFromSource {
    param([Parameter(Mandatory = $true)][int64]$IncludedBytes)

    if (-not (Test-Path -LiteralPath $sevenZipPath)) {
        throw "7z.exe was not found at $sevenZipPath"
    }

    $parentDirectory = Split-Path -Parent $projectRoot
    $parentOutputRoot = if ($outputRootFull.StartsWith($parentDirectory, [System.StringComparison]::OrdinalIgnoreCase)) {
        $outputRootFull
    } else {
        $outputRootFull
    }

    Write-MetadataFiles -RootPath $projectRoot -SelectedMode $Mode -IncludedBytes $IncludedBytes

    $archiveItems = @()
    foreach ($relativeDirectory in $includeDirectories) {
        $archiveItems += ("{0}\{1}" -f $projectName, $relativeDirectory)
    }
    foreach ($relativeFile in $includeFiles) {
        $archiveItems += ("{0}\{1}" -f $projectName, $relativeFile)
    }
    foreach ($fileName in $temporaryMetadataFiles) {
        $archiveItems += ("{0}\{1}" -f $projectName, $fileName)
    }

    $excludeArgs = @(
        "-x!{0}\Data\.idea" -f $projectName,
        "-x!{0}\Data\.idea\*" -f $projectName,
        "-x!{0}\Data\.DS_Store" -f $projectName,
        "-x!{0}\Data\sprites\sprites_rate_limit.log" -f $projectName,
        "-x!{0}\Mods\mod_manager_state.json" -f $projectName,
        "-x!{0}\Mods\compat_report.txt" -f $projectName,
        "-x!{0}\KIFM\platinum_uuids.txt" -f $projectName,
        "-x!{0}\KIFM\discord_ids.txt" -f $projectName,
        "-x!{0}\KIFM\pending_discord_link.txt" -f $projectName,
        "-x!{0}\KIFM\coop_debug.log" -f $projectName,
        "-x!{0}\KIFM\pvp_wins.txt" -f $projectName,
        "-x!{0}\KIFM\discord_link.log" -f $projectName,
        "-x!{0}\Mods\custom_species_framework" -f $projectName,
        "-x!{0}\Mods\custom_species_framework\*" -f $projectName,
        "-x!{0}\Data\encounters.json" -f $projectName,
        "-x!{0}\Data\starter_sets.json" -f $projectName,
        "-x!{0}\Data\trainer_hooks.json" -f $projectName,
        "-x!{0}\Data\species" -f $projectName,
        "-x!{0}\Data\species\*" -f $projectName,
        "-x!{0}\Graphics\Battlers\1202" -f $projectName,
        "-x!{0}\Graphics\Battlers\1202\*" -f $projectName,
        "-x!{0}\Graphics\Battlers\1203" -f $projectName,
        "-x!{0}\Graphics\Battlers\1203\*" -f $projectName,
        "-x!{0}\Graphics\Battlers\1204" -f $projectName,
        "-x!{0}\Graphics\Battlers\1204\*" -f $projectName,
        "-x!{0}\Graphics\Battlers\1205" -f $projectName,
        "-x!{0}\Graphics\Battlers\1205\*" -f $projectName,
        "-x!{0}\Graphics\Battlers\1206" -f $projectName,
        "-x!{0}\Graphics\Battlers\1206\*" -f $projectName,
        "-x!{0}\Graphics\CustomBattlers\indexed\1202" -f $projectName,
        "-x!{0}\Graphics\CustomBattlers\indexed\1202\*" -f $projectName,
        "-x!{0}\Graphics\CustomBattlers\indexed\1203" -f $projectName,
        "-x!{0}\Graphics\CustomBattlers\indexed\1203\*" -f $projectName,
        "-x!{0}\Graphics\CustomBattlers\indexed\1204" -f $projectName,
        "-x!{0}\Graphics\CustomBattlers\indexed\1204\*" -f $projectName,
        "-x!{0}\Graphics\CustomBattlers\indexed\1205" -f $projectName,
        "-x!{0}\Graphics\CustomBattlers\indexed\1205\*" -f $projectName,
        "-x!{0}\Graphics\CustomBattlers\indexed\1206" -f $projectName,
        "-x!{0}\Graphics\CustomBattlers\indexed\1206\*" -f $projectName,
        "-x!{0}\Graphics\Icons\icon1202.png" -f $projectName,
        "-x!{0}\Graphics\Icons\icon1203.png" -f $projectName,
        "-x!{0}\Graphics\Icons\icon1204.png" -f $projectName,
        "-x!{0}\Graphics\Icons\icon1205.png" -f $projectName,
        "-x!{0}\Graphics\Icons\icon1206.png" -f $projectName,
        "-x!{0}\Graphics\Pokemon\Back\CSF_AQUALITH.png" -f $projectName,
        "-x!{0}\Graphics\Pokemon\Back\CSF_CINDRAKE.png" -f $projectName,
        "-x!{0}\Graphics\Pokemon\Back\CSF_VERDALYK.png" -f $projectName,
        "-x!{0}\Graphics\Pokemon\Front\CSF_AQUALITH.png" -f $projectName,
        "-x!{0}\Graphics\Pokemon\Front\CSF_CINDRAKE.png" -f $projectName,
        "-x!{0}\Graphics\Pokemon\Front\CSF_VERDALYK.png" -f $projectName,
        "-x!{0}\Graphics\Pokemon\Icons\CSF_AQUALITH.png" -f $projectName,
        "-x!{0}\Graphics\Pokemon\Icons\CSF_CINDRAKE.png" -f $projectName,
        "-x!{0}\Graphics\Pokemon\Icons\CSF_VERDALYK.png" -f $projectName,
        "-x!{0}\Graphics\Pokemon\Icons\CSF_SANDSHREW_GLACIAL.png" -f $projectName,
        "-x!{0}\Graphics\Pokemon\Icons\CSF_SANDSLASH_GLACIAL.png" -f $projectName,
        "-xr!{0}\__pycache__" -f $projectName,
        "-xr!{0}\Thumbs.db" -f $projectName,
        "-xr!{0}\*.DS_Store" -f $projectName
    )

    New-Item -ItemType Directory -Path $parentOutputRoot -Force | Out-Null
    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }

    Write-Host ("Creating archive at {0}" -f $archivePath)

    Push-Location $parentDirectory
    try {
        & $sevenZipPath a -t7z -mx=3 -mmt=on $archivePath @archiveItems @excludeArgs | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "7z archive creation failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
        Remove-TemporaryMetadataFiles -RootPath $projectRoot
    }
}

function Build-ArchiveFromStage {
    if (-not (Test-Path -LiteralPath $sevenZipPath)) {
        throw "7z.exe was not found at $sevenZipPath"
    }

    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }

    Write-Host ("Creating archive from staged folder at {0}" -f $archivePath)

    Push-Location $stageRoot
    try {
        & $sevenZipPath a -t7z -mx=3 -mmt=on $archivePath $projectName | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "7z archive creation from staged folder failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

function Remove-ArchivePaths {
    param([Parameter(Mandatory = $true)][string]$ArchiveFilePath)

    if (-not (Test-Path -LiteralPath $ArchiveFilePath)) {
        throw "Archive does not exist: $ArchiveFilePath"
    }

    $archiveCleanupItems = @(
        ("{0}\Data\.idea" -f $projectName),
        ("{0}\Data\.idea\*" -f $projectName),
        ("{0}\Data\.DS_Store" -f $projectName),
        ("{0}\Data\sprites\sprites_rate_limit.log" -f $projectName),
        ("{0}\Mods\mod_manager_state.json" -f $projectName),
        ("{0}\Mods\compat_report.txt" -f $projectName),
        ("{0}\KIFM\platinum_uuids.txt" -f $projectName),
        ("{0}\KIFM\discord_ids.txt" -f $projectName),
        ("{0}\KIFM\pending_discord_link.txt" -f $projectName),
        ("{0}\KIFM\coop_debug.log" -f $projectName),
        ("{0}\KIFM\pvp_wins.txt" -f $projectName),
        ("{0}\KIFM\discord_link.log" -f $projectName),
        ("{0}\Mods\custom_species_framework" -f $projectName),
        ("{0}\Mods\custom_species_framework\*" -f $projectName),
        ("{0}\Data\encounters.json" -f $projectName),
        ("{0}\Data\starter_sets.json" -f $projectName),
        ("{0}\Data\trainer_hooks.json" -f $projectName),
        ("{0}\Data\species" -f $projectName),
        ("{0}\Data\species\*" -f $projectName),
        ("{0}\Graphics\Battlers\1202" -f $projectName),
        ("{0}\Graphics\Battlers\1202\*" -f $projectName),
        ("{0}\Graphics\Battlers\1203" -f $projectName),
        ("{0}\Graphics\Battlers\1203\*" -f $projectName),
        ("{0}\Graphics\Battlers\1204" -f $projectName),
        ("{0}\Graphics\Battlers\1204\*" -f $projectName),
        ("{0}\Graphics\Battlers\1205" -f $projectName),
        ("{0}\Graphics\Battlers\1205\*" -f $projectName),
        ("{0}\Graphics\Battlers\1206" -f $projectName),
        ("{0}\Graphics\Battlers\1206\*" -f $projectName),
        ("{0}\Graphics\CustomBattlers\indexed\1202" -f $projectName),
        ("{0}\Graphics\CustomBattlers\indexed\1202\*" -f $projectName),
        ("{0}\Graphics\CustomBattlers\indexed\1203" -f $projectName),
        ("{0}\Graphics\CustomBattlers\indexed\1203\*" -f $projectName),
        ("{0}\Graphics\CustomBattlers\indexed\1204" -f $projectName),
        ("{0}\Graphics\CustomBattlers\indexed\1204\*" -f $projectName),
        ("{0}\Graphics\CustomBattlers\indexed\1205" -f $projectName),
        ("{0}\Graphics\CustomBattlers\indexed\1205\*" -f $projectName),
        ("{0}\Graphics\CustomBattlers\indexed\1206" -f $projectName),
        ("{0}\Graphics\CustomBattlers\indexed\1206\*" -f $projectName),
        ("{0}\Graphics\Icons\icon1202.png" -f $projectName),
        ("{0}\Graphics\Icons\icon1203.png" -f $projectName),
        ("{0}\Graphics\Icons\icon1204.png" -f $projectName),
        ("{0}\Graphics\Icons\icon1205.png" -f $projectName),
        ("{0}\Graphics\Icons\icon1206.png" -f $projectName),
        ("{0}\Graphics\Pokemon\Back\CSF_AQUALITH.png" -f $projectName),
        ("{0}\Graphics\Pokemon\Back\CSF_CINDRAKE.png" -f $projectName),
        ("{0}\Graphics\Pokemon\Back\CSF_VERDALYK.png" -f $projectName),
        ("{0}\Graphics\Pokemon\Front\CSF_AQUALITH.png" -f $projectName),
        ("{0}\Graphics\Pokemon\Front\CSF_CINDRAKE.png" -f $projectName),
        ("{0}\Graphics\Pokemon\Front\CSF_VERDALYK.png" -f $projectName),
        ("{0}\Graphics\Pokemon\Icons\CSF_AQUALITH.png" -f $projectName),
        ("{0}\Graphics\Pokemon\Icons\CSF_CINDRAKE.png" -f $projectName),
        ("{0}\Graphics\Pokemon\Icons\CSF_VERDALYK.png" -f $projectName),
        ("{0}\Graphics\Pokemon\Icons\CSF_SANDSHREW_GLACIAL.png" -f $projectName),
        ("{0}\Graphics\Pokemon\Icons\CSF_SANDSLASH_GLACIAL.png" -f $projectName)
    )

    & $sevenZipPath d $ArchiveFilePath @archiveCleanupItems | Out-Null
    if (($LASTEXITCODE -ne 0) -and ($LASTEXITCODE -ne 1)) {
        throw "7z archive cleanup failed with exit code $LASTEXITCODE"
    }
}

$includedBytes = Get-DirectorySizeBytes -RelativeDirectories $includeDirectories
$freeBytes = Get-FreeSpaceBytes -Path $outputRootFull
$stageRequiresSpace = $Mode -in @("stage", "both")
$archiveRequiresSevenZip = $Mode -in @("archive", "both")

Write-Host ("Selected mode: {0}" -f $Mode)
Write-Host ("Included source size: {0}" -f (Format-Bytes -Bytes $includedBytes))
Write-Host ("Free space on output drive: {0}" -f (Format-Bytes -Bytes $freeBytes))

if ($stageRequiresSpace -and ($freeBytes -lt ($includedBytes + 2GB))) {
    throw "Not enough free space to safely create a staged build. Use -Mode archive or free more disk space."
}

if ($archiveRequiresSevenZip -and (-not (Test-Path -LiteralPath $sevenZipPath))) {
    throw "Archive mode requires 7z.exe at $sevenZipPath"
}

New-Item -ItemType Directory -Path $outputRootFull -Force | Out-Null
Set-Content -LiteralPath $manifestPath -Value (New-ManifestContent -SelectedMode $Mode -IncludedBytes $includedBytes) -Encoding UTF8

switch ($Mode) {
    "archive" {
        Build-ArchiveFromSource -IncludedBytes $includedBytes
    }
    "stage" {
        Build-StageDirectory -StageRootPath $stageRoot -PackageRootPath $packageRoot -IncludedBytes $includedBytes
    }
    "both" {
        Build-StageDirectory -StageRootPath $stageRoot -PackageRootPath $packageRoot -IncludedBytes $includedBytes
        Build-ArchiveFromStage
    }
}

if ($Mode -in @("archive", "both")) {
    $hash = Get-FileHash -LiteralPath $archivePath -Algorithm SHA256
    Set-Content -LiteralPath $hashPath -Value ("{0} *{1}" -f $hash.Hash.ToLowerInvariant(), (Split-Path -Leaf $archivePath)) -Encoding ASCII
}

$summaryLines = New-Object System.Collections.Generic.List[string]
$summaryLines.Add(("Packaging mode: {0}" -f $Mode))
$summaryLines.Add(("Manifest: {0}" -f $manifestPath))
if ($Mode -in @("stage", "both")) {
    $summaryLines.Add(("Staged build: {0}" -f $stageRoot))
}
if ($Mode -in @("archive", "both")) {
    $archiveItem = Get-Item -LiteralPath $archivePath
    $summaryLines.Add(("Archive: {0}" -f $archiveItem.FullName))
    $summaryLines.Add(("Archive size: {0}" -f (Format-Bytes -Bytes $archiveItem.Length)))
    $summaryLines.Add(("SHA256: {0}" -f $hashPath))
}

$summaryText = ($summaryLines -join [Environment]::NewLine)
Write-Host ""
Write-Host $summaryText
