param(
  [string]$ManifestPath = (Join-Path $PSScriptRoot "config\source_manifest.json"),
  [string]$ConfigPath = (Join-Path $PSScriptRoot "config\importer_config.json"),
  [string]$MappingPath = (Join-Path $PSScriptRoot "config\framework_mapping.json"),
  [string]$OutputRoot = (Join-Path $PSScriptRoot "import_output"),
  [switch]$ApplyBundle,
  [switch]$Force
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing

$script:ImporterRoot = $PSScriptRoot
$script:FrameworkRoot = [System.IO.Path]::GetFullPath((Join-Path $script:ImporterRoot ".."))
$script:ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $script:FrameworkRoot "..\.."))
$script:CacheRoot = Join-Path $script:ImporterRoot "cache"
$script:StateRoot = Join-Path $script:ImporterRoot "state"
$script:LogFile = Join-Path $OutputRoot "import.log"
$script:Now = Get-Date

$script:DefaultConfig = @{
  allow_partial_entries       = $false
  require_backsprite          = $true
  require_icon                = $true
  overwrite_existing_species  = $false
  strict_permission_mode      = $true
  target_framework_mode       = "custom_species_framework_v1"
  target_sprite_width         = 96
  target_sprite_height        = 96
  target_backsprite_width     = 96
  target_backsprite_height    = 96
  target_icon_width           = 64
  target_icon_height          = 64
  resize_mode                 = "fit_canvas"
  generate_framework_bundle   = $true
  dry_run_only                = $true
  apply_bundle_to_framework   = $false
  html_download_image_assets  = $true
  html_download_linked_archives = $true
  state_file                  = "state\import_state.json"
}

$script:DefaultMapping = @{
  framework_mode = "custom_species_framework_v1"
  species_registry = @{
    mode              = "per_pack_json"
    directory         = "data/species"
    filename_template = "imported_{pack_slug}.json"
  }
  assets = @{
    front       = "Graphics/Pokemon/Imported/{pack_slug}/Front/{internal_id}.png"
    back        = "Graphics/Pokemon/Imported/{pack_slug}/Back/{internal_id}.png"
    icon        = "Graphics/Pokemon/Imported/{pack_slug}/Icons/{internal_id}.png"
    overworld   = "Graphics/Pokemon/Imported/{pack_slug}/Overworld/{internal_id}.png"
    shiny_front = "Graphics/Pokemon/Imported/{pack_slug}/ShinyFront/{internal_id}.png"
    shiny_back  = "Graphics/Pokemon/Imported/{pack_slug}/ShinyBack/{internal_id}.png"
  }
  bundle = @{
    directory = "framework_bundle"
  }
  credits = @{
    directory                 = "importer/applied_manifests"
    credits_manifest_template = "{pack_slug}_credits.json"
    notice_template           = "NOTICE_imports.txt"
  }
}

function Write-ImporterLog {
  param(
    [string]$Message,
    [string]$Level = "INFO"
  )

  $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level.ToUpperInvariant(), $Message
  Write-Host $line
  $logDirectory = Split-Path -Parent $script:LogFile
  if ($logDirectory) {
    New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
  }
  Add-Content -LiteralPath $script:LogFile -Value $line
}

function Ensure-Directory {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) { return }
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function ConvertTo-NativeData {
  param([Parameter(ValueFromPipeline = $true)]$InputObject)

  if ($null -eq $InputObject) {
    return $null
  }
  if ($InputObject -is [System.Collections.IDictionary]) {
    $result = @{}
    foreach ($key in $InputObject.Keys) {
      $result[$key] = ConvertTo-NativeData $InputObject[$key]
    }
    return $result
  }
  if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
    $result = @{}
    foreach ($property in $InputObject.PSObject.Properties) {
      $result[$property.Name] = ConvertTo-NativeData $property.Value
    }
    return $result
  }
  if (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string])) {
    $items = @()
    foreach ($item in $InputObject) {
      $items += ,(ConvertTo-NativeData $item)
    }
    return $items
  }
  return $InputObject
}

function Read-JsonFile {
  param(
    [string]$Path,
    $Fallback
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return $Fallback
  }

  $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
  if ([string]::IsNullOrWhiteSpace($raw)) {
    return $Fallback
  }

  try {
    return ConvertTo-NativeData ($raw | ConvertFrom-Json -ErrorAction Stop)
  } catch {
    Write-ImporterLog "Failed to parse JSON at ${Path}: $($_.Exception.Message)" "WARN"
    return $Fallback
  }
}

function Write-JsonFile {
  param(
    [string]$Path,
    $Data
  )

  Ensure-Directory (Split-Path -Parent $Path)
  $json = $Data | ConvertTo-Json -Depth 20
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
}

function Merge-Hashtables {
  param(
    [hashtable]$Base,
    [hashtable]$Override
  )

  $result = @{}
  foreach ($key in $Base.Keys) {
    $result[$key] = $Base[$key]
  }
  foreach ($key in $Override.Keys) {
    if (($result[$key] -is [hashtable]) -and ($Override[$key] -is [hashtable])) {
      $result[$key] = Merge-Hashtables -Base $result[$key] -Override $Override[$key]
    } else {
      $result[$key] = $Override[$key]
    }
  }
  return $result
}

function Normalize-TextList {
  param($Value)
  $list = @()
  if ($null -eq $Value) { return $list }
  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    foreach ($item in $Value) {
      if ($null -eq $item) { continue }
      $text = $item.ToString().Trim()
      if ($text) { $list += $text }
    }
    return $list
  }
  foreach ($part in $Value.ToString().Split(@("`r", "`n", ",", ";"), [System.StringSplitOptions]::RemoveEmptyEntries)) {
    $text = $part.Trim()
    if ($text) { $list += $text }
  }
  return $list
}

function Get-FirstValue {
  param([object[]]$Values)
  foreach ($value in $Values) {
    if ($null -eq $value) { continue }
    if ($value -is [string]) {
      if (-not [string]::IsNullOrWhiteSpace($value)) {
        return $value
      }
      continue
    }
    return $value
  }
  return $null
}

function Get-FirstDefinedValue {
  param([object[]]$Values)
  foreach ($value in $Values) {
    if ($null -ne $value) {
      return $value
    }
  }
  return $null
}

function Normalize-Slug {
  param(
    [string]$Text,
    [string]$Separator = "_"
  )

  if ([string]::IsNullOrWhiteSpace($Text)) {
    return ""
  }

  $value = $Text.Trim()
  if ([string]::IsNullOrEmpty($Separator)) {
    return [System.Text.RegularExpressions.Regex]::Replace($value, "[^A-Za-z0-9]+", "")
  }
  $value = [System.Text.RegularExpressions.Regex]::Replace($value, "[^A-Za-z0-9]+", $Separator)
  $value = [System.Text.RegularExpressions.Regex]::Replace($value, ([System.Text.RegularExpressions.Regex]::Escape($Separator) + "{2,}"), $Separator)
  $value = $value.Trim($Separator.ToCharArray())
  return $value
}

function Normalize-DisplayName {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) {
    return ""
  }
  $words = Normalize-Slug -Text $Text -Separator " "
  if ([string]::IsNullOrWhiteSpace($words)) {
    return $Text.Trim()
  }
  $culture = [System.Globalization.CultureInfo]::InvariantCulture
  return $culture.TextInfo.ToTitleCase($words.ToLowerInvariant())
}

function Normalize-LookupToken {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) {
    return ""
  }
  return [System.Text.RegularExpressions.Regex]::Replace($Text.ToUpperInvariant(), "[^A-Z0-9]+", "")
}

function Resolve-CatalogIdentifier {
  param(
    [object]$Value,
    [hashtable]$ValidIds,
    [hashtable]$NameIndex
  )

  if ($null -eq $Value) {
    return ""
  }

  $raw = $Value.ToString().Trim()
  if (-not $raw) {
    return ""
  }

  $idCandidate = (Normalize-Slug -Text $raw -Separator "").ToUpperInvariant()
  if ($ValidIds -and $ValidIds[$idCandidate]) {
    return $idCandidate
  }

  $lookupToken = Normalize-LookupToken -Text $raw
  if ($NameIndex -and $NameIndex[$lookupToken]) {
    return $NameIndex[$lookupToken]
  }

  return $idCandidate
}

function Normalize-FrameworkId {
  param(
    [string]$PackSlug,
    [string]$SpeciesName
  )
  $packToken = Normalize-Slug -Text $PackSlug -Separator "_"
  $speciesToken = Normalize-Slug -Text $SpeciesName -Separator "_"
  $raw = "CSF_{0}_{1}" -f $packToken, $speciesToken
  $raw = $raw.Trim("_")
  return $raw.ToUpperInvariant()
}

function Expand-Template {
  param(
    [string]$Template,
    [hashtable]$Variables
  )

  $result = $Template
  foreach ($key in $Variables.Keys) {
    $token = "{0}" -f $key
    $result = $result.Replace("{$token}", $Variables[$key].ToString())
  }
  return $result
}

function Resolve-AbsolutePath {
  param(
    [string]$Path,
    [string]$RelativeTo
  )

  if ([string]::IsNullOrWhiteSpace($Path)) {
    return $null
  }
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  if ([string]::IsNullOrWhiteSpace($RelativeTo)) {
    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Path))
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RelativeTo $Path))
}

function Get-FileHashString {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-PillowPythonPath {
  if ($script:PillowPythonPath) {
    return $script:PillowPythonPath
  }

  $candidates = @()
  $bundledPython = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
  if (Test-Path -LiteralPath $bundledPython) {
    $candidates += $bundledPython
  }
  $globalPython = Get-Command python -ErrorAction SilentlyContinue
  if ($globalPython -and $globalPython.Source) {
    $candidates += $globalPython.Source
  }

  foreach ($candidate in ($candidates | Select-Object -Unique)) {
    try {
      $result = & $candidate -c "from PIL import Image; print('PIL_OK')" 2>$null
      if (($result | Out-String).Trim() -eq "PIL_OK") {
        $script:PillowPythonPath = $candidate
        return $script:PillowPythonPath
      }
    } catch {
      continue
    }
  }

  $script:PillowPythonPath = $null
  return $null
}

function Try-GetImageInfo {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }
  try {
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
      $image = [System.Drawing.Image]::FromStream($stream, $true, $true)
      try {
        return @{
          width  = [int]$image.Width
          height = [int]$image.Height
          format = [System.IO.Path]::GetExtension($Path).TrimStart(".").ToLowerInvariant()
        }
      } finally {
        $image.Dispose()
      }
    } finally {
      $stream.Dispose()
    }
  } catch {
    return $null
  }
}

function Convert-AssetToPng {
  param(
    [string]$SourcePath,
    [string]$DestinationPath,
    [int]$TargetWidth,
    [int]$TargetHeight,
    [string]$ResizeMode = "fit_canvas"
  )

  Ensure-Directory (Split-Path -Parent $DestinationPath)
  if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Missing source asset $SourcePath"
  }

  $sourceExtension = [System.IO.Path]::GetExtension($SourcePath).ToLowerInvariant()
  if ($sourceExtension -eq ".png" -and $TargetWidth -le 0 -and $TargetHeight -le 0) {
    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
    return
  }

  try {
    $bitmap = $null
    $canvas = $null
    $graphics = $null
    try {
      $bitmap = [System.Drawing.Bitmap]::FromFile($SourcePath)
      $canvasWidth = if ($TargetWidth -gt 0) { $TargetWidth } else { $bitmap.Width }
      $canvasHeight = if ($TargetHeight -gt 0) { $TargetHeight } else { $bitmap.Height }
      $canvas = New-Object System.Drawing.Bitmap $canvasWidth, $canvasHeight, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
      $graphics = [System.Drawing.Graphics]::FromImage($canvas)
      $graphics.Clear([System.Drawing.Color]::Transparent)
      $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
      $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
      $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
      $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

      $drawWidth = $bitmap.Width
      $drawHeight = $bitmap.Height
      if ($ResizeMode -eq "fit_canvas" -and $canvasWidth -gt 0 -and $canvasHeight -gt 0) {
        $scale = [Math]::Min($canvasWidth / [double]$bitmap.Width, $canvasHeight / [double]$bitmap.Height)
        if ($scale -lt 1.0) {
          $drawWidth = [Math]::Max([int][Math]::Round($bitmap.Width * $scale), 1)
          $drawHeight = [Math]::Max([int][Math]::Round($bitmap.Height * $scale), 1)
        }
      }
      $destX = [int][Math]::Floor(($canvasWidth - $drawWidth) / 2)
      $destY = [int][Math]::Floor(($canvasHeight - $drawHeight) / 2)
      $graphics.DrawImage($bitmap, (New-Object System.Drawing.Rectangle $destX, $destY, $drawWidth, $drawHeight))
      $canvas.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
      return
    } finally {
      if ($graphics) { $graphics.Dispose() }
      if ($canvas) { $canvas.Dispose() }
      if ($bitmap) { $bitmap.Dispose() }
    }
  } catch {
    $pythonPath = Get-PillowPythonPath
    if (-not $pythonPath) {
      throw
    }

    $tempScript = Join-Path $script:CacheRoot ("convert_asset_" + [System.Guid]::NewGuid().ToString("N") + ".py")
    $pythonScript = @'
from PIL import Image
import sys

source = sys.argv[1]
destination = sys.argv[2]
target_width = int(sys.argv[3])
target_height = int(sys.argv[4])
resize_mode = sys.argv[5]

with Image.open(source) as image:
    image = image.convert("RGBA")
    canvas_width = target_width if target_width > 0 else image.width
    canvas_height = target_height if target_height > 0 else image.height
    draw_width = image.width
    draw_height = image.height
    if resize_mode == "fit_canvas" and canvas_width > 0 and canvas_height > 0:
        scale = min(canvas_width / image.width, canvas_height / image.height)
        if scale < 1.0:
            draw_width = max(int(round(image.width * scale)), 1)
            draw_height = max(int(round(image.height * scale)), 1)
            image = image.resize((draw_width, draw_height), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
    dest_x = int((canvas_width - draw_width) // 2)
    dest_y = int((canvas_height - draw_height) // 2)
    canvas.alpha_composite(image, (dest_x, dest_y))
    canvas.save(destination, format="PNG")
'@
    try {
      Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
      & $pythonPath $tempScript $SourcePath $DestinationPath $TargetWidth $TargetHeight $ResizeMode
      if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $DestinationPath)) {
        throw
      }
    } finally {
      if (Test-Path -LiteralPath $tempScript) {
        Remove-Item -LiteralPath $tempScript -Force
      }
    }
  }
}

function Get-FrameworkContext {
  $speciesDir = Join-Path $script:FrameworkRoot "data\species"
  $entries = @()
  $byId = @{}
  $byName = @{}
  $bySlug = @{}
  $existingSlots = New-Object System.Collections.Generic.HashSet[int]
  $hashIndex = @{}
  $highestSlot = 0

  if (Test-Path -LiteralPath $speciesDir) {
    Get-ChildItem -LiteralPath $speciesDir -Filter "*.json" | Sort-Object Name | ForEach-Object {
      $payload = Read-JsonFile -Path $_.FullName -Fallback @{}
      foreach ($raw in @($payload.species)) {
        if (-not ($raw -is [hashtable])) { continue }
        $entry = $raw
        $entries += ,$entry
        if ($entry.id) { $byId[$entry.id.ToString().ToUpperInvariant()] = $entry }
        if ($entry.name) { $byName[$entry.name.ToString().Trim().ToLowerInvariant()] = $entry }
        if ($entry.name) { $bySlug[(Normalize-Slug -Text $entry.name -Separator "").ToLowerInvariant()] = $entry }
        $slot = 0
        if ($entry.slot) {
          $slot = [int]$entry.slot
        } elseif ($entry.id_number) {
          $legacy = [int]$entry.id_number
          if ($legacy -ge 252001) {
            $slot = $legacy - 252000
          }
        }
        if ($slot -gt 0) {
          $existingSlots.Add($slot) | Out-Null
          if ($slot -gt $highestSlot) { $highestSlot = $slot }
        }

        $sourcePack = ""
        if ($entry.source_pack) {
          $sourcePack = $entry.source_pack.ToString().Trim().ToLowerInvariant()
        }
        $frontPath = $null
        if ($entry.assets -and $entry.assets.front) {
          $frontPath = Resolve-AbsolutePath -Path $entry.assets.front -RelativeTo $script:FrameworkRoot
          if (-not (Test-Path -LiteralPath $frontPath)) {
            $frontPath = Resolve-AbsolutePath -Path ($entry.assets.front.ToString() + ".png") -RelativeTo $script:FrameworkRoot
          }
        }
        if ($sourcePack -and $frontPath -and (Test-Path -LiteralPath $frontPath)) {
          $assetHash = Get-FileHashString -Path $frontPath
          if ($assetHash) {
            $hashIndex["$sourcePack|$assetHash"] = $entry
          }
        }
      }
    }
  }

  $catalogPath = Join-Path $script:FrameworkRoot "creator\data\game_catalog.json"
  $catalog = Read-JsonFile -Path $catalogPath -Fallback @{}
  $validTypes = @{}
  $validAbilities = @{}
  $validMoves = @{}
  $validItems = @{}
  $typeNameToId = @{}
  $abilityNameToId = @{}
  $moveNameToId = @{}
  $itemNameToId = @{}
  foreach ($item in @($catalog.types)) {
    if ($item.id) {
      $id = $item.id.ToString().ToUpperInvariant()
      $validTypes[$id] = $true
      if ($item.name) {
        $typeNameToId[(Normalize-LookupToken -Text $item.name.ToString())] = $id
      }
    }
  }
  foreach ($item in @($catalog.abilities)) {
    if ($item.id) {
      $id = $item.id.ToString().ToUpperInvariant()
      $validAbilities[$id] = $true
      if ($item.name) {
        $abilityNameToId[(Normalize-LookupToken -Text $item.name.ToString())] = $id
      }
    }
  }
  foreach ($item in @($catalog.moves)) {
    if ($item.id) {
      $id = $item.id.ToString().ToUpperInvariant()
      $validMoves[$id] = $true
      if ($item.name) {
        $moveNameToId[(Normalize-LookupToken -Text $item.name.ToString())] = $id
      }
    }
  }
  foreach ($item in @($catalog.items)) {
    if ($item.id) {
      $id = $item.id.ToString().ToUpperInvariant()
      $validItems[$id] = $true
      if ($item.name) {
        $itemNameToId[(Normalize-LookupToken -Text $item.name.ToString())] = $id
      }
    }
  }

  return @{
    species_entries = $entries
    by_id           = $byId
    by_name         = $byName
    by_slug         = $bySlug
    existing_slots  = $existingSlots
    highest_slot    = $highestSlot
    hash_index      = $hashIndex
    catalog_path    = $catalogPath
    valid_types     = $validTypes
    valid_abilities = $validAbilities
    valid_moves     = $validMoves
    valid_items     = $validItems
    type_name_to_id = $typeNameToId
    ability_name_to_id = $abilityNameToId
    move_name_to_id = $moveNameToId
    item_name_to_id = $itemNameToId
  }
}

function Get-ImporterState {
  param([string]$Path)
  $state = Read-JsonFile -Path $Path -Fallback @{}
  if (-not ($state -is [hashtable])) {
    $state = @{}
  }
  if (-not $state.slot_assignments) { $state.slot_assignments = @{} }
  if (-not $state.applied_bundles) { $state.applied_bundles = @() }
  if (-not $state.source_hashes) { $state.source_hashes = @{} }
  return $state
}

function Save-ImporterState {
  param(
    [string]$Path,
    [hashtable]$State
  )
  Write-JsonFile -Path $Path -Data $State
}

function Get-SourceRootFromAdapter {
  param(
    [hashtable]$Source,
    [string]$ManifestDirectory
  )

  $sourceType = (Get-FirstValue @($Source.type, $Source.adapter, "folder")).ToString().ToLowerInvariant()
  $workingRoot = $null
  $cleanupPaths = @()
  $downloadedFiles = @()

  switch ($sourceType) {
    "folder" { 
      $workingRoot = Resolve-AbsolutePath -Path $Source.location -RelativeTo $ManifestDirectory
    }
    "structured_pack" {
      $workingRoot = Resolve-AbsolutePath -Path $Source.location -RelativeTo $ManifestDirectory
    }
    "zip" {
      $zipPath = Resolve-AbsolutePath -Path $Source.location -RelativeTo $ManifestDirectory
      if (-not (Test-Path -LiteralPath $zipPath)) {
        throw "Zip source not found at $zipPath"
      }
      $extractDir = Join-Path $script:CacheRoot ("zip_" + (Normalize-Slug -Text (Get-FirstValue @($Source.id, [System.IO.Path]::GetFileNameWithoutExtension($zipPath))) -Separator "_"))
      if (Test-Path -LiteralPath $extractDir) {
        Remove-Item -LiteralPath $extractDir -Recurse -Force
      }
      Ensure-Directory $extractDir
      [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractDir)
      $workingRoot = $extractDir
      $cleanupPaths += $extractDir
    }
    "github_zip" {
  $archiveUrl = (Get-FirstDefinedValue @($Source.archive_url, $Source.source_url, "")).ToString()
      if ([string]::IsNullOrWhiteSpace($archiveUrl)) {
        throw "GitHub zip source $($Source.id) is missing archive_url or source_url."
      }
      $downloadPath = Join-Path $script:CacheRoot ((Normalize-Slug -Text (Get-FirstValue @($Source.id, "github_pack")) -Separator "_") + ".zip")
      Ensure-Directory (Split-Path -Parent $downloadPath)
      Invoke-WebRequest -Uri $archiveUrl -OutFile $downloadPath -UseBasicParsing
      $extractDir = Join-Path $script:CacheRoot ("github_" + (Normalize-Slug -Text (Get-FirstValue @($Source.id, "github_pack")) -Separator "_"))
      if (Test-Path -LiteralPath $extractDir) {
        Remove-Item -LiteralPath $extractDir -Recurse -Force
      }
      Ensure-Directory $extractDir
      [System.IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, $extractDir)
      $workingRoot = $extractDir
      $cleanupPaths += $extractDir
      $downloadedFiles += $downloadPath
    }
    "html_page" {
      $pageUrl = (Get-FirstDefinedValue @($Source.source_url, $Source.url, "")).ToString()
      if ([string]::IsNullOrWhiteSpace($pageUrl)) {
        throw "HTML page source $($Source.id) is missing source_url."
      }
      $pageDir = Join-Path $script:CacheRoot ("html_" + (Normalize-Slug -Text (Get-FirstValue @($Source.id, "html_pack")) -Separator "_"))
      if (Test-Path -LiteralPath $pageDir) {
        Remove-Item -LiteralPath $pageDir -Recurse -Force
      }
      Ensure-Directory $pageDir
      $htmlFile = Join-Path $pageDir "source.html"
      $response = Invoke-WebRequest -Uri $pageUrl -UseBasicParsing
      Set-Content -LiteralPath $htmlFile -Value $response.Content -Encoding UTF8
      $downloadedFiles += $htmlFile
      if ($Source.location) {
        $localDir = Resolve-AbsolutePath -Path $Source.location -RelativeTo $ManifestDirectory
        if (Test-Path -LiteralPath $localDir) {
          Copy-Item -LiteralPath $localDir -Destination (Join-Path $pageDir "local_assets") -Recurse -Force
        }
      }
      if ($script:RuntimeConfig.html_download_image_assets -or $script:RuntimeConfig.html_download_linked_archives) {
        $html = $response.Content
        $baseUri = [System.Uri]$pageUrl
        $matches = [System.Text.RegularExpressions.Regex]::Matches($html, '(?i)(?:href|src)\s*=\s*["'']([^"'']+)["'']')
        foreach ($match in $matches) {
          $href = $match.Groups[1].Value
          if ([string]::IsNullOrWhiteSpace($href)) { continue }
          if ($href.StartsWith("data:", [System.StringComparison]::OrdinalIgnoreCase)) { continue }
          $absoluteUri = $null
          try {
            $absoluteUri = New-Object System.Uri($baseUri, $href)
          } catch {
            continue
          }
          $extension = [System.IO.Path]::GetExtension($absoluteUri.AbsolutePath).ToLowerInvariant()
          $shouldDownload = $false
          if ($script:RuntimeConfig.html_download_image_assets -and @(".png", ".gif", ".bmp", ".jpg", ".jpeg", ".webp").Contains($extension)) {
            $shouldDownload = $true
          }
          if ($script:RuntimeConfig.html_download_linked_archives -and @(".zip").Contains($extension)) {
            $shouldDownload = $true
          }
          if (-not $shouldDownload) { continue }
          $targetFile = Join-Path $pageDir ("downloaded_" + [System.IO.Path]::GetFileName($absoluteUri.AbsolutePath))
          try {
            Invoke-WebRequest -Uri $absoluteUri.AbsoluteUri -OutFile $targetFile -UseBasicParsing
            $downloadedFiles += $targetFile
            if ($extension -eq ".zip") {
              $archiveExtractDir = Join-Path $pageDir ([System.IO.Path]::GetFileNameWithoutExtension($targetFile))
              Ensure-Directory $archiveExtractDir
              [System.IO.Compression.ZipFile]::ExtractToDirectory($targetFile, $archiveExtractDir)
            }
          } catch {
            Write-ImporterLog "Skipped HTML-linked asset $($absoluteUri.AbsoluteUri): $($_.Exception.Message)" "WARN"
          }
        }
      }
      $workingRoot = $pageDir
      $cleanupPaths += $pageDir
    }
    default {
      throw "Unsupported source adapter type '$sourceType'."
    }
  }

  if ([string]::IsNullOrWhiteSpace($workingRoot) -or -not (Test-Path -LiteralPath $workingRoot)) {
    throw "Resolved working root is missing for source $((Get-FirstValue @($Source.id, $Source.pack_name, $sourceType)))."
  }

  return @{
    source_type      = $sourceType
    working_root     = $workingRoot
    cleanup_paths    = $cleanupPaths
    downloaded_files = $downloadedFiles
  }
}

function Get-SourceTextFiles {
  param(
    [string]$WorkingRoot,
    [hashtable]$Source
  )

  $explicitFiles = Normalize-TextList (Get-FirstValue @($Source.license_files, @()))
  $files = @()
  foreach ($file in $explicitFiles) {
    $resolved = Resolve-AbsolutePath -Path $file -RelativeTo $WorkingRoot
    if ($resolved -and (Test-Path -LiteralPath $resolved)) {
      $files += $resolved
    }
  }
  if ($files.Count -gt 0) {
    return $files | Select-Object -Unique
  }

  $patterns = @("README*", "LICENSE*", "CREDITS*", "NOTICE*", "*.txt", "*.md", "*.html", "*.htm")
  foreach ($pattern in $patterns) {
    Get-ChildItem -Path $WorkingRoot -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue | ForEach-Object {
      $files += $_.FullName
    }
  }
  return $files | Select-Object -Unique
}

function Get-SourceMetadataFiles {
  param(
    [string]$WorkingRoot,
    [hashtable]$Source
  )

  $explicitFiles = Normalize-TextList (Get-FirstValue @($Source.metadata_files, @()))
  $files = @()
  foreach ($file in $explicitFiles) {
    $resolved = Resolve-AbsolutePath -Path $file -RelativeTo $WorkingRoot
    if ($resolved -and (Test-Path -LiteralPath $resolved)) {
      $files += $resolved
    }
  }
  if ($files.Count -gt 0) {
    return $files | Select-Object -Unique
  }

  $patterns = @("species*.json", "*fakemon*.json", "*pokemon*.json", "pokemon.txt", "species.txt", "*.pbs")
  foreach ($pattern in $patterns) {
    Get-ChildItem -Path $WorkingRoot -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue | ForEach-Object {
      $files += $_.FullName
    }
  }
  return $files | Select-Object -Unique
}

function Get-SourceImageFiles {
  param([string]$WorkingRoot)
  $files = @()
  Get-ChildItem -Path $WorkingRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    @(".png", ".gif", ".bmp", ".jpg", ".jpeg", ".webp").Contains($_.Extension.ToLowerInvariant())
  } | ForEach-Object {
    $files += $_.FullName
  }
  return $files
}

function Get-PermissionStatus {
  param(
    [hashtable]$Source,
    [string[]]$TextFiles,
    [bool]$StrictMode
  )

  $evidence = @()
  $combinedText = @()
  foreach ($file in $TextFiles) {
    try {
      $content = Get-Content -LiteralPath $file -Raw -ErrorAction Stop
      if (-not [string]::IsNullOrWhiteSpace($content)) {
        $combinedText += $content
        $evidence += @{
          file    = $file
          excerpt = $content.Substring(0, [Math]::Min(280, $content.Length)).Trim()
        }
      }
    } catch {
      Write-ImporterLog "Permission scan skipped unreadable file ${file}: $($_.Exception.Message)" "WARN"
    }
  }

  foreach ($field in @("usage_permission", "credit_text", "notes", "permission_notes")) {
    if ($Source[$field]) {
      $combinedText += $Source[$field].ToString()
    }
  }

  $fullText = ($combinedText -join "`n").ToLowerInvariant()
  $approvedPatterns = @(
    "free to use",
    "free-use",
    "use with credit",
    "credit required",
    "non-commercial use",
    "non commercial use",
    "free for fangames",
    "free for fan games",
    "reusable with credit",
    "public use with credit"
  )
  $rejectedPatterns = @(
    "personal use only",
    "do not use",
    "do not redistribute",
    "all rights reserved",
    "ask permission",
    "permission required",
    "not for reuse",
    "not free to use",
    "commercial license required"
  )

  $status = "REVIEW"
  $reason = "Permission language was not clearly detected."

  if ($Source.permission_override) {
    $override = $Source.permission_override.ToString().Trim().ToUpperInvariant()
    if (@("APPROVED", "REVIEW", "REJECTED").Contains($override)) {
      $status = $override
      $reason = "Permission status forced by source manifest override."
      return @{
        status   = $status
        reason   = $reason
        evidence = $evidence
      }
    }
  }

  foreach ($pattern in $rejectedPatterns) {
    if ($fullText.Contains($pattern)) {
      $status = "REJECTED"
      $reason = "Matched rejected permission phrase '$pattern'."
      return @{
        status   = $status
        reason   = $reason
        evidence = $evidence
      }
    }
  }

  foreach ($pattern in $approvedPatterns) {
    if ($fullText.Contains($pattern)) {
      $status = "APPROVED"
      $reason = "Matched approved permission phrase '$pattern'."
      break
    }
  }

  if ($status -eq "APPROVED" -and $StrictMode) {
    if ([string]::IsNullOrWhiteSpace((Get-FirstDefinedValue @($Source.creator, "")).ToString()) -or
        [string]::IsNullOrWhiteSpace((Get-FirstDefinedValue @($Source.credit_text, "")).ToString()) -or
        [string]::IsNullOrWhiteSpace((Get-FirstDefinedValue @($Source.usage_permission, "")).ToString())) {
      $status = "REVIEW"
      $reason = "Strict mode requires creator, credit_text, and usage_permission fields."
    }
  }

  return @{
    status   = $status
    reason   = $reason
    evidence = $evidence
  }
}

function Parse-PbsSpeciesFile {
  param([string]$Path)

  $speciesEntries = @()
  $current = $null
  foreach ($line in Get-Content -LiteralPath $Path) {
    $trimmed = $line.Trim()
    if (-not $trimmed -or $trimmed.StartsWith("#")) { continue }
    if ($trimmed.StartsWith("[") -and $trimmed.EndsWith("]")) {
      if ($current) { $speciesEntries += ,$current }
      $current = @{}
      continue
    }
    if (-not $current) { continue }
    $parts = $trimmed.Split("=", 2)
    if ($parts.Count -lt 2) { continue }
    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    $current[$key] = $value
  }
  if ($current) { $speciesEntries += ,$current }

  $normalized = @()
  foreach ($entry in $speciesEntries) {
    $name = $entry["Name"]
    if (-not $name) { continue }
    $types = @()
    if ($entry["Type1"]) { $types += $entry["Type1"].ToUpperInvariant() }
    if ($entry["Type2"]) { $types += $entry["Type2"].ToUpperInvariant() }
    $abilities = @()
    foreach ($ability in Normalize-TextList $entry["Abilities"]) {
      $abilities += (Normalize-Slug -Text $ability -Separator "_").ToUpperInvariant()
    }
    $hiddenAbility = $null
    if ($entry["HiddenAbility"]) {
      $hiddenAbility = (Normalize-Slug -Text $entry["HiddenAbility"] -Separator "_").ToUpperInvariant()
    }
    $moves = @()
    if ($entry["Moves"]) {
      $parts = Normalize-TextList $entry["Moves"]
      for ($i = 0; $i -lt ($parts.Count - 1); $i += 2) {
        $level = 1
        [void][int]::TryParse($parts[$i], [ref]$level)
        $moveName = (Normalize-Slug -Text $parts[$i + 1] -Separator "_").ToUpperInvariant()
        $moves += @{ level = $level; move = $moveName }
      }
    }
    $baseStats = @{
      HP              = 50
      ATTACK          = 50
      DEFENSE         = 50
      SPECIAL_ATTACK  = 50
      SPECIAL_DEFENSE = 50
      SPEED           = 50
    }
    if ($entry["BaseStats"]) {
      $parts = Normalize-TextList $entry["BaseStats"]
      if ($parts.Count -ge 6) {
        $baseStats.HP = [int]$parts[0]
        $baseStats.ATTACK = [int]$parts[1]
        $baseStats.DEFENSE = [int]$parts[2]
        $baseStats.SPEED = [int]$parts[3]
        $baseStats.SPECIAL_ATTACK = [int]$parts[4]
        $baseStats.SPECIAL_DEFENSE = [int]$parts[5]
      }
    }
    $evolutions = @()
    if ($entry["Evolutions"]) {
      $parts = Normalize-TextList $entry["Evolutions"]
      for ($i = 0; $i -lt ($parts.Count - 2); $i += 3) {
        $parameter = $parts[$i + 2]
        if ($parameter -match '^\d+$') { $parameter = [int]$parameter }
        $evolutions += @{
          species   = (Normalize-Slug -Text $parts[$i] -Separator "_").ToUpperInvariant()
          method    = (Normalize-Slug -Text $parts[$i + 1] -Separator "_").ToUpperInvariant()
          parameter = $parameter
        }
      }
    }
    $normalized += @{
      id                = (Normalize-Slug -Text (Get-FirstValue @($entry["InternalName"], $name)) -Separator "_").ToUpperInvariant()
      display_name      = $name
      species_name      = $name
      category          = (Get-FirstDefinedValue @($entry["Kind"], ""))
      pokedex_entry     = (Get-FirstDefinedValue @($entry["Pokedex"], ""))
      types             = $types
      abilities         = $abilities
      hidden_ability    = $hiddenAbility
      base_stats        = $baseStats
      moves             = $moves
      egg_groups        = Normalize-TextList $entry["Compatibility"]
      catch_rate        = if ($entry["Rareness"]) { [int]$entry["Rareness"] } else { $null }
      height            = if ($entry["Height"]) { [double]$entry["Height"] } else { $null }
      weight            = if ($entry["Weight"]) { [double]$entry["Weight"] } else { $null }
      growth_rate       = (Get-FirstDefinedValue @($entry["GrowthRate"], ""))
      gender_ratio      = (Get-FirstDefinedValue @($entry["GenderRate"], ""))
      happiness         = if ($entry["Happiness"]) { [int]$entry["Happiness"] } else { $null }
      evolutions        = $evolutions
    }
  }

  return $normalized
}

function Parse-JsonSpeciesFile {
  param([string]$Path)
  $payload = Read-JsonFile -Path $Path -Fallback @{}
  if ($payload -is [System.Collections.IEnumerable] -and -not ($payload -is [hashtable])) {
    return @($payload)
  }
  if ($payload.species) { return @($payload.species) }
  if ($payload.pokemon) { return @($payload.pokemon) }
  if ($payload.entries) { return @($payload.entries) }
  return @()
}

function Normalize-MoveEntryList {
  param(
    [object[]]$RawMoves,
    [hashtable]$FrameworkContext,
    [bool]$IncludeLevels = $false
  )

  $moves = @()
  foreach ($moveEntry in @($RawMoves)) {
    if ($null -eq $moveEntry) { continue }
    if ($moveEntry -is [hashtable]) {
      $moveName = (Get-FirstDefinedValue @($moveEntry.move, $moveEntry.id, $moveEntry.name, "")).ToString()
      if (-not $moveName) { continue }
      $resolvedMove = Resolve-CatalogIdentifier -Value $moveName -ValidIds $FrameworkContext.valid_moves -NameIndex $FrameworkContext.move_name_to_id
      if (-not $resolvedMove) { continue }
      if ($IncludeLevels) {
        $moves += @{
          level = [int](Get-FirstValue @($moveEntry.level, 1))
          move  = $resolvedMove
        }
      } else {
        $moves += $resolvedMove
      }
      continue
    }

    $resolvedMove = Resolve-CatalogIdentifier -Value $moveEntry -ValidIds $FrameworkContext.valid_moves -NameIndex $FrameworkContext.move_name_to_id
    if (-not $resolvedMove) { continue }
    if ($IncludeLevels) {
      $moves += @{
        level = 1
        move  = $resolvedMove
      }
    } else {
      $moves += $resolvedMove
    }
  }

  return @($moves)
}

function Normalize-MetadataEntry {
  param(
    [hashtable]$Raw,
    [hashtable]$FrameworkContext
  )

  $name = (Get-FirstDefinedValue @($Raw.display_name, $Raw.species_name, $Raw.name, "")).ToString()
  if ([string]::IsNullOrWhiteSpace($name)) { return $null }

  $types = @()
  if ($Raw.types) {
    foreach ($type in @($Raw.types)) {
      if ($null -eq $type) { continue }
      $resolvedType = Resolve-CatalogIdentifier -Value $type -ValidIds $FrameworkContext.valid_types -NameIndex $FrameworkContext.type_name_to_id
      if ($resolvedType) {
        $types += $resolvedType
      }
    }
  } else {
    if ($Raw.type1) {
      $resolvedType = Resolve-CatalogIdentifier -Value $Raw.type1 -ValidIds $FrameworkContext.valid_types -NameIndex $FrameworkContext.type_name_to_id
      if ($resolvedType) { $types += $resolvedType }
    }
    if ($Raw.type2) {
      $resolvedType = Resolve-CatalogIdentifier -Value $Raw.type2 -ValidIds $FrameworkContext.valid_types -NameIndex $FrameworkContext.type_name_to_id
      if ($resolvedType) { $types += $resolvedType }
    }
  }

  $abilities = @()
  if ($Raw.abilities) {
    foreach ($ability in @($Raw.abilities)) {
      if ($null -eq $ability) { continue }
      $resolvedAbility = Resolve-CatalogIdentifier -Value $ability -ValidIds $FrameworkContext.valid_abilities -NameIndex $FrameworkContext.ability_name_to_id
      if ($resolvedAbility) {
        $abilities += $resolvedAbility
      }
    }
  }
  if ($Raw.hidden_abilities) {
    foreach ($ability in @($Raw.hidden_abilities)) {
      if ($null -eq $ability) { continue }
      $resolvedAbility = Resolve-CatalogIdentifier -Value $ability -ValidIds $FrameworkContext.valid_abilities -NameIndex $FrameworkContext.ability_name_to_id
      if ($resolvedAbility) {
        $abilities += $resolvedAbility
      }
    }
  }

  $hiddenAbility = $null
  if ($Raw.hidden_ability) {
    $hiddenAbility = Resolve-CatalogIdentifier -Value $Raw.hidden_ability -ValidIds $FrameworkContext.valid_abilities -NameIndex $FrameworkContext.ability_name_to_id
  }

  $moves = Normalize-MoveEntryList -RawMoves @($Raw.moves) -FrameworkContext $FrameworkContext -IncludeLevels $true
  $teachMoves = Normalize-MoveEntryList -RawMoves @($Raw.teach_moves) -FrameworkContext $FrameworkContext
  $eggMoves = Normalize-MoveEntryList -RawMoves @($Raw.egg_moves) -FrameworkContext $FrameworkContext

  $evolutions = @()
  foreach ($evolution in @($Raw.evolutions)) {
    if (-not ($evolution -is [hashtable])) { continue }
    $speciesName = (Get-FirstDefinedValue @($evolution.species, "")).ToString()
    $methodName = (Get-FirstDefinedValue @($evolution.method, "")).ToString()
    if (-not $speciesName -or -not $methodName) { continue }
    $parameter = $evolution.parameter
    if ($parameter -is [string] -and $parameter -match '^\d+$') {
      $parameter = [int]$parameter
    }
    $evolutions += @{
      species   = (Normalize-Slug -Text $speciesName -Separator "_").ToUpperInvariant()
      method    = (Normalize-Slug -Text $methodName -Separator "_").ToUpperInvariant()
      parameter = $parameter
    }
  }

  return @{
    id                = (Get-FirstDefinedValue @($Raw.id, $Raw.internal_id, "")).ToString().ToUpperInvariant()
    display_name      = $name
    species_name      = $name
    category          = (Get-FirstDefinedValue @($Raw.category, "")).ToString()
    pokedex_entry     = (Get-FirstDefinedValue @($Raw.pokedex_entry, $Raw.dex_entry, "")).ToString()
    types             = $types
    abilities         = $abilities | Select-Object -Unique
    hidden_ability    = $hiddenAbility
    base_stats        = if ($Raw.base_stats) { ConvertTo-NativeData $Raw.base_stats } else { @{} }
    moves             = $moves
    teach_moves       = $teachMoves | Select-Object -Unique
    egg_moves         = $eggMoves | Select-Object -Unique
    egg_groups        = Normalize-TextList (Get-FirstValue @($Raw.egg_groups, $Raw.compatibility))
    catch_rate        = if ($null -ne $Raw.catch_rate -and $Raw.catch_rate.ToString().Trim() -ne "") { [int]$Raw.catch_rate } else { $null }
    height            = if ($null -ne $Raw.height -and $Raw.height.ToString().Trim() -ne "") { $Raw.height } else { $null }
    weight            = if ($null -ne $Raw.weight -and $Raw.weight.ToString().Trim() -ne "") { $Raw.weight } else { $null }
    growth_rate       = (Get-FirstDefinedValue @($Raw.growth_rate, "")).ToString()
    gender_ratio      = (Get-FirstDefinedValue @($Raw.gender_ratio, "")).ToString()
    happiness         = if ($null -ne $Raw.happiness -and $Raw.happiness.ToString().Trim() -ne "") { [int]$Raw.happiness } else { $null }
    evolutions        = $evolutions
    notes             = (Get-FirstDefinedValue @($Raw.notes, "")).ToString()
    source_pack       = (Get-FirstDefinedValue @($Raw.source_pack, "")).ToString()
    source_url        = (Get-FirstDefinedValue @($Raw.source_url, "")).ToString()
    creator           = (Get-FirstDefinedValue @($Raw.creator, "")).ToString()
    credit_text       = (Get-FirstDefinedValue @($Raw.credit_text, "")).ToString()
    usage_permission  = (Get-FirstDefinedValue @($Raw.usage_permission, "")).ToString()
  }
}

function Get-PackMetadataIndex {
  param(
    [string[]]$MetadataFiles,
    [hashtable]$Source,
    [hashtable]$FrameworkContext
  )

  $index = @{}
  foreach ($path in $MetadataFiles) {
    $extension = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
    $entries = @()
    if ($extension -eq ".json") {
      $entries = Parse-JsonSpeciesFile -Path $path
    } else {
      $entries = Parse-PbsSpeciesFile -Path $path
    }
    foreach ($rawEntry in $entries) {
      if (-not ($rawEntry -is [hashtable])) { continue }
      $entry = Normalize-MetadataEntry -Raw $rawEntry -FrameworkContext $FrameworkContext
      if (-not $entry) { continue }
      $keys = @()
      if ($entry.display_name) { $keys += (Normalize-Slug -Text $entry.display_name -Separator "").ToLowerInvariant() }
      if ($entry.id) { $keys += (Normalize-Slug -Text $entry.id -Separator "").ToLowerInvariant() }
      foreach ($key in ($keys | Select-Object -Unique)) {
        if (-not $key) { continue }
        $index[$key] = $entry
      }
    }
  }

  if ($Source.species_overrides -is [hashtable]) {
    foreach ($overrideKey in @($Source.species_overrides.Keys)) {
      $normalizedKey = (Normalize-Slug -Text $overrideKey -Separator "").ToLowerInvariant()
      $overrideEntry = Normalize-MetadataEntry -Raw (ConvertTo-NativeData $Source.species_overrides[$overrideKey]) -FrameworkContext $FrameworkContext
      if ($overrideEntry) {
        $index[$normalizedKey] = $overrideEntry
      }
    }
  }

  return $index
}

function Get-AssetKindFromPath {
  param([string]$Path)
  $name = [System.IO.Path]::GetFileNameWithoutExtension($Path).ToLowerInvariant()
  $directory = [System.IO.Path]::GetDirectoryName($Path).ToLowerInvariant()

  if ($name -match 'shiny.*back|back.*shiny' -or $directory -match 'shiny.?back') { return "shiny_back" }
  if ($name -match 'shiny|altshiny' -or $directory -match 'shiny') { return "shiny_front" }
  if ($directory -match 'overworld|follower|ow' -or $name -match 'overworld|follower|_ow|ow_') { return "overworld" }
  if ($directory -match 'icon' -or $name -match 'icon|menu') { return "icon" }
  if ($directory -match 'back' -or $name -match '(^|[_\-\s])back($|[_\-\s])|_b$|-b$') { return "back" }
  return "front"
}

function Get-SpeciesNameFromAssetPath {
  param(
    [string]$Path,
    [string]$PackSlug
  )

  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
  $sanitized = $baseName
  $packPattern = [System.Text.RegularExpressions.Regex]::Escape($PackSlug)
  if ($packPattern) {
    $sanitized = [System.Text.RegularExpressions.Regex]::Replace($sanitized, $packPattern, "", "IgnoreCase")
  }
  $sanitized = [System.Text.RegularExpressions.Regex]::Replace($sanitized, '(?i)(front|back|icon|icons|sprite|battler|shiny|overworld|follower|menu|sheet|ow)', ' ')
  $sanitized = [System.Text.RegularExpressions.Regex]::Replace($sanitized, '[_\-\.\(\)\[\]]+', ' ')
  $sanitized = [System.Text.RegularExpressions.Regex]::Replace($sanitized, '\s{2,}', ' ')
  $sanitized = $sanitized.Trim()
  if (-not $sanitized) {
    $sanitized = [System.IO.Path]::GetFileNameWithoutExtension($Path)
  }
  return Normalize-DisplayName -Text $sanitized
}

function Discover-SpeciesCandidates {
  param(
    [hashtable]$Source,
    [string]$WorkingRoot,
    [hashtable]$MetadataIndex
  )

  $packSlug = (Normalize-Slug -Text (Get-FirstValue @($Source.pack_name, $Source.id, "pack")) -Separator "_").ToLowerInvariant()
  $candidates = @{}
  $seenMetadataKeys = New-Object System.Collections.Generic.HashSet[string]
  foreach ($imagePath in Get-SourceImageFiles -WorkingRoot $WorkingRoot) {
    $kind = Get-AssetKindFromPath -Path $imagePath
    $speciesName = Get-SpeciesNameFromAssetPath -Path $imagePath -PackSlug $packSlug
    $lookupKey = (Normalize-Slug -Text $speciesName -Separator "").ToLowerInvariant()
    $metadata = $MetadataIndex[$lookupKey]
    if ($metadata -and $metadata.display_name) {
      $speciesName = $metadata.display_name
    }
    if (-not $speciesName) { continue }
    if (-not $candidates.ContainsKey($lookupKey)) {
      $candidates[$lookupKey] = @{
        species_name = $speciesName
        metadata     = $metadata
        assets       = @{}
        files        = @()
      }
    }
    $candidates[$lookupKey].assets[$kind] = $imagePath
    $candidates[$lookupKey].files += $imagePath
    if ($metadata) {
      if ($metadata.id) {
        $seenMetadataKeys.Add(("id:" + $metadata.id.ToString().ToUpperInvariant())) | Out-Null
      }
      if ($metadata.display_name) {
        $seenMetadataKeys.Add(("name:" + (Normalize-Slug -Text $metadata.display_name -Separator "").ToLowerInvariant())) | Out-Null
      }
    }
  }

  foreach ($metadataKey in $MetadataIndex.Keys) {
    $entry = $MetadataIndex[$metadataKey]
    $canonicalKeys = @()
    if ($entry.id) {
      $canonicalKeys += ("id:" + $entry.id.ToString().ToUpperInvariant())
    }
    if ($entry.display_name) {
      $canonicalKeys += ("name:" + (Normalize-Slug -Text $entry.display_name -Separator "").ToLowerInvariant())
    }

    $alreadyPresent = $false
    foreach ($canonicalKey in $canonicalKeys) {
      if ($seenMetadataKeys.Contains($canonicalKey)) {
        $alreadyPresent = $true
        break
      }
    }

    if (-not $candidates.ContainsKey($metadataKey) -and -not $alreadyPresent) {
      $candidates[$metadataKey] = @{
        species_name = $entry.display_name
        metadata     = $entry
        assets       = @{}
        files        = @()
      }
      foreach ($canonicalKey in $canonicalKeys) {
        $seenMetadataKeys.Add($canonicalKey) | Out-Null
      }
    }
  }

  return $candidates.Values
}

function Get-NextAvailableSlot {
  param(
    [hashtable]$FrameworkContext,
    [hashtable]$State,
    [string]$InternalId
  )

  $stateKey = $InternalId.ToUpperInvariant()
  if ($State.slot_assignments[$stateKey]) {
    $assignedSlot = [int]$State.slot_assignments[$stateKey]
    $duplicateOwner = $null
    foreach ($otherKey in @($State.slot_assignments.Keys)) {
      if ($otherKey -eq $stateKey) { continue }
      if ([int]$State.slot_assignments[$otherKey] -ne $assignedSlot) { continue }
      $duplicateOwner = $otherKey
      break
    }

    if (-not $duplicateOwner) {
      return $assignedSlot
    }

    Write-ImporterLog "Reassigning duplicate state slot $assignedSlot for $stateKey (already claimed by $duplicateOwner)." "WARN"
    $State.slot_assignments.Remove($stateKey) | Out-Null
  }

  $candidate = [Math]::Max([int]$FrameworkContext.highest_slot + 1, 1)
  while ($FrameworkContext.existing_slots.Contains($candidate)) {
    $candidate++
  }
  $FrameworkContext.existing_slots.Add($candidate) | Out-Null
  if ($candidate -gt $FrameworkContext.highest_slot) {
    $FrameworkContext.highest_slot = $candidate
  }
  $State.slot_assignments[$stateKey] = $candidate
  return $candidate
}

function New-ReviewItem {
  param(
    [hashtable]$Entry,
    [string]$Issue,
    [string]$SuggestedFix,
    [string[]]$FileReferences
  )
  return @{
    species_name   = $Entry.display_name
    source_pack    = $Entry.source_pack
    detected_issue = $Issue
    suggested_fix  = $SuggestedFix
    file_references = @($FileReferences | Select-Object -Unique)
  }
}

function Normalize-EntryForFramework {
  param(
    [hashtable]$Source,
    [hashtable]$Candidate,
    [hashtable]$FrameworkContext
  )

  $packName = (Get-FirstValue @($Source.pack_name, $Source.id, "Imported Pack")).ToString()
  $packSlug = (Normalize-Slug -Text $packName -Separator "_").ToLowerInvariant()
  $displayName = (Get-FirstDefinedValue @($Candidate.metadata.display_name, $Candidate.species_name, "")).ToString()
  $displayName = Normalize-DisplayName -Text $displayName
  $internalId = (Get-FirstDefinedValue @($Candidate.metadata.id, "")).ToString().Trim().ToUpperInvariant()
  if (-not $internalId) {
    $internalId = Normalize-FrameworkId -PackSlug $packSlug -SpeciesName $displayName
  }

  $metadata = $Candidate.metadata
  $types = @($metadata.types)
  if ($types.Count -eq 0) { $types = @("NORMAL") }
  $type1 = $types[0]
  $type2 = if ($types.Count -gt 1) { $types[1] } else { $null }

  $baseStats = @{
    HP              = 50
    ATTACK          = 50
    DEFENSE         = 50
    SPECIAL_ATTACK  = 50
    SPECIAL_DEFENSE = 50
    SPEED           = 50
  }
  if ($metadata.base_stats -is [hashtable]) {
    foreach ($key in $metadata.base_stats.Keys) {
      $normalizedKey = (Normalize-Slug -Text $key -Separator "_").ToUpperInvariant()
      switch ($normalizedKey) {
        "HP" { $baseStats.HP = [int]$metadata.base_stats[$key] }
        "ATTACK" { $baseStats.ATTACK = [int]$metadata.base_stats[$key] }
        "DEFENSE" { $baseStats.DEFENSE = [int]$metadata.base_stats[$key] }
        "SPECIAL_ATTACK" { $baseStats.SPECIAL_ATTACK = [int]$metadata.base_stats[$key] }
        "SPECIAL_DEFENSE" { $baseStats.SPECIAL_DEFENSE = [int]$metadata.base_stats[$key] }
        "SP_ATTACK" { $baseStats.SPECIAL_ATTACK = [int]$metadata.base_stats[$key] }
        "SP_DEFENSE" { $baseStats.SPECIAL_DEFENSE = [int]$metadata.base_stats[$key] }
        "SPEED" { $baseStats.SPEED = [int]$metadata.base_stats[$key] }
      }
    }
  }

  $entry = @{
    id                     = $internalId
    display_name           = $displayName
    species_name           = $displayName
    source_pack            = (Get-FirstDefinedValue @($metadata.source_pack, $packName)).ToString()
    source_url             = (Get-FirstDefinedValue @($metadata.source_url, $Source.source_url, "")).ToString()
    creator                = (Get-FirstDefinedValue @($metadata.creator, $Source.creator, "")).ToString()
    credit_text            = (Get-FirstDefinedValue @($metadata.credit_text, $Source.credit_text, "")).ToString()
    usage_permission       = (Get-FirstDefinedValue @($metadata.usage_permission, $Source.usage_permission, "")).ToString()
    auto_import_allowed    = $false
    manual_review_required = $false
    assets                 = @{
      front       = $Candidate.assets.front
      back        = $Candidate.assets.back
      icon        = $Candidate.assets.icon
      overworld   = $Candidate.assets.overworld
      shiny_front = $Candidate.assets.shiny_front
      shiny_back  = $Candidate.assets.shiny_back
    }
    game_data              = @{
      kind             = (Get-FirstValue @($Source.kind, "fakemon")).ToString()
      category         = (Get-FirstValue @($metadata.category, "Imported Species")).ToString()
      pokedex_entry    = (Get-FirstDefinedValue @($metadata.pokedex_entry, "")).ToString()
      types            = @(@($type1, $type2) | Where-Object { $_ })
      abilities        = @($metadata.abilities)
      hidden_ability   = (Get-FirstDefinedValue @($metadata.hidden_ability, "")).ToString()
      base_stats       = $baseStats
      moves            = @($metadata.moves)
      teach_moves      = @($metadata.teach_moves)
      egg_moves        = @($metadata.egg_moves)
      egg_groups       = Normalize-TextList $metadata.egg_groups
      catch_rate       = $metadata.catch_rate
      height           = $metadata.height
      weight           = $metadata.weight
      growth_rate      = (Get-FirstValue @($metadata.growth_rate, "Medium")).ToString()
      gender_ratio     = (Get-FirstValue @($metadata.gender_ratio, "Female50Percent")).ToString()
      happiness        = if ($null -ne $metadata.happiness -and $metadata.happiness.ToString().Trim() -ne "") { [int]$metadata.happiness } else { 70 }
      evolutions       = @($metadata.evolutions)
    }
    integration            = @{
      framework_species_key = $internalId
      insert_status         = "pending"
      insert_errors         = @()
      fusion_ready          = $false
    }
    notes                  = (Get-FirstDefinedValue @($metadata.notes, $Source.notes, "")).ToString()
    file_references        = @($Candidate.files)
    pack_slug              = $packSlug
    visible_name_slug      = (Normalize-Slug -Text $displayName -Separator "").ToLowerInvariant()
  }

  if ($FrameworkContext.by_id[$internalId] -and -not [bool]$script:RuntimeConfig.overwrite_existing_species) {
    $entry.integration.insert_errors += "Framework species key '$internalId' already exists."
  }

  return $entry
}

function Validate-NormalizedEntry {
  param(
    [hashtable]$Entry,
    [hashtable]$FrameworkContext,
    [hashtable]$Permission,
    [hashtable]$Source
  )

  $errors = @()
  $warnings = @()
  $suggestions = @()
  $reviewItems = @()
  $frontPath = $Entry.assets.front
  $frontHash = $null

  if (-not $Entry.display_name) {
    $errors += "Missing species display name."
    $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Missing species name" -SuggestedFix "Provide a visible species name or a metadata entry with a Name field." -FileReferences $Entry.file_references)
  }
  if (-not $Entry.creator) {
    $errors += "Missing creator attribution."
    $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Missing creator attribution" -SuggestedFix "Fill the source manifest creator field before importing." -FileReferences $Entry.file_references)
  }
  if (-not $Entry.credit_text) {
    $errors += "Missing credit text."
    $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Missing credit text" -SuggestedFix "Add exact release credit text in the source manifest." -FileReferences $Entry.file_references)
  }
  if ($Permission.status -ne "APPROVED") {
    $errors += "Permission status is $($Permission.status)."
    $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Permission not auto-approved" -SuggestedFix $Permission.reason -FileReferences $Entry.file_references)
  }
  if (-not $frontPath -or -not (Test-Path -LiteralPath $frontPath)) {
    $errors += "Missing front sprite."
    $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Missing front sprite" -SuggestedFix "Provide a readable front battler sprite before insertion." -FileReferences $Entry.file_references)
  } else {
    $imageInfo = Try-GetImageInfo -Path $frontPath
    if (-not $imageInfo) {
      $errors += "Front sprite uses an unsupported or unreadable format."
      $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Unsupported front sprite format" -SuggestedFix "Convert the front sprite to PNG, BMP, GIF, JPG, or JPEG before import." -FileReferences @($frontPath))
    } else {
      $frontHash = Get-FileHashString -Path $frontPath
    }
  }

  if ($script:RuntimeConfig.require_backsprite -and (-not $Entry.assets.back -or -not (Test-Path -LiteralPath $Entry.assets.back))) {
    $errors += "Backsprite is required by config."
    $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Missing backsprite" -SuggestedFix "Provide a backsprite or disable require_backsprite for dry-run ingestion." -FileReferences $Entry.file_references)
  } elseif (-not $Entry.assets.back) {
    if (-not $script:RuntimeConfig.allow_partial_entries) {
      $warnings += "Backsprite missing; partial entries are disabled."
      $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Missing backsprite" -SuggestedFix "Add a backsprite to allow automatic insertion." -FileReferences $Entry.file_references)
    }
  }

  if ($script:RuntimeConfig.require_icon -and (-not $Entry.assets.icon -or -not (Test-Path -LiteralPath $Entry.assets.icon))) {
    $errors += "Icon is required by config."
    $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Missing icon" -SuggestedFix "Provide an icon sprite or disable require_icon for dry-run ingestion." -FileReferences $Entry.file_references)
  }

  $existingByName = $FrameworkContext.by_name[$Entry.display_name.Trim().ToLowerInvariant()]
  if ($existingByName) {
    $existingSource = (Get-FirstDefinedValue @($existingByName.source_pack, "")).ToString().Trim().ToLowerInvariant()
    if ($existingSource -and $existingSource -ne $Entry.source_pack.Trim().ToLowerInvariant()) {
      $errors += "Species name '$($Entry.display_name)' already exists from a different source."
      $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Species name conflict" -SuggestedFix "Rename the imported species or add an alias mapping after manual review." -FileReferences $Entry.file_references)
    }
  }

  $normalizedSlug = $Entry.visible_name_slug
  if ($normalizedSlug -and $FrameworkContext.by_slug[$normalizedSlug] -and -not $existingByName) {
    $warnings += "A near-identical species name already exists in the framework."
    $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Near-identical species name" -SuggestedFix "Confirm this is not a duplicate and add an alias mapping if you keep both." -FileReferences $Entry.file_references)
  }

  if ($frontHash) {
    $hashKey = "{0}|{1}" -f $Entry.source_pack.Trim().ToLowerInvariant(), $frontHash
    if ($FrameworkContext.hash_index[$hashKey]) {
      $existing = $FrameworkContext.hash_index[$hashKey]
      $warnings += "Matching source pack and front asset hash already exist in the framework."
      $Entry.integration.insert_status = "skipped_duplicate"
      $Entry.integration.insert_errors += "Already imported as $($existing.id)."
    }
  }

  foreach ($type in @($Entry.game_data.types)) {
    $normalized = $type.ToString().ToUpperInvariant()
    if (-not $FrameworkContext.valid_types[$normalized]) {
      $errors += "Unknown type '$normalized'."
      $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Invalid type" -SuggestedFix "Map the type to a real game internal name from the exported catalog." -FileReferences $Entry.file_references)
    }
  }
  foreach ($ability in @($Entry.game_data.abilities)) {
    $normalized = $ability.ToString().ToUpperInvariant()
    if (-not $FrameworkContext.valid_abilities[$normalized]) {
      $errors += "Unknown ability '$normalized'."
      $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Invalid ability" -SuggestedFix "Replace the ability with a real internal ability ID from the game catalog." -FileReferences $Entry.file_references)
    }
  }
  if ($Entry.game_data.hidden_ability) {
    $hidden = $Entry.game_data.hidden_ability.ToString().ToUpperInvariant()
    if (-not $FrameworkContext.valid_abilities[$hidden]) {
      $errors += "Unknown hidden ability '$hidden'."
      $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Invalid hidden ability" -SuggestedFix "Replace the hidden ability with a valid internal ability ID." -FileReferences $Entry.file_references)
    }
  }
  foreach ($move in @($Entry.game_data.moves)) {
    $moveId = (Get-FirstDefinedValue @($move.move, "")).ToString().ToUpperInvariant()
    if ($moveId -and -not $FrameworkContext.valid_moves[$moveId]) {
      $errors += "Unknown move '$moveId'."
      $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Invalid move" -SuggestedFix "Replace the move with a valid internal move ID from the exported catalog." -FileReferences $Entry.file_references)
    }
  }
  foreach ($moveId in @($Entry.game_data.teach_moves)) {
    $normalizedMove = $moveId.ToString().ToUpperInvariant()
    if ($normalizedMove -and -not $FrameworkContext.valid_moves[$normalizedMove]) {
      $errors += "Unknown teach move '$normalizedMove'."
      $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Invalid teach move" -SuggestedFix "Replace the move with a valid internal move ID from the exported catalog." -FileReferences $Entry.file_references)
    }
  }
  foreach ($moveId in @($Entry.game_data.egg_moves)) {
    $normalizedMove = $moveId.ToString().ToUpperInvariant()
    if ($normalizedMove -and -not $FrameworkContext.valid_moves[$normalizedMove]) {
      $errors += "Unknown egg move '$normalizedMove'."
      $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Invalid egg move" -SuggestedFix "Replace the move with a valid internal move ID from the exported catalog." -FileReferences $Entry.file_references)
    }
  }

  $bst = 0
  foreach ($statValue in $Entry.game_data.base_stats.Values) {
    $bst += [int]$statValue
  }
  if ($bst -lt 180) {
    $suggestions += "BST is very low ($bst). Consider verifying whether the source pack included complete base stats."
  }
  if ($bst -gt 720) {
    $warnings += "BST is very high ($bst)."
  }

  if (@($Entry.game_data.moves).Count -eq 0) {
    $warnings += "Species has no level-up learnset."
    $reviewItems += ,(New-ReviewItem -Entry $Entry -Issue "Missing learnset" -SuggestedFix "Add at least starter-level moves before insertion." -FileReferences $Entry.file_references)
  }

  if (-not $script:RuntimeConfig.allow_partial_entries) {
    if (-not $Entry.assets.back) { $errors += "Partial entry missing backsprite." }
    if (-not $Entry.assets.icon) { $errors += "Partial entry missing icon." }
  }

  return @{
    errors      = $errors | Select-Object -Unique
    warnings    = $warnings | Select-Object -Unique
    suggestions = $suggestions | Select-Object -Unique
    review      = $reviewItems
    front_hash  = $frontHash
  }
}

function Get-AssetOutputPath {
  param(
    [string]$Kind,
    [hashtable]$Entry,
    [hashtable]$Mapping,
    [string]$BaseRoot
  )
  $template = (Get-FirstDefinedValue @($Mapping.assets[$Kind], "")).ToString()
  if (-not $template) { return $null }
  $relative = Expand-Template -Template $template -Variables @{
    pack_slug    = $Entry.pack_slug
    internal_id  = $Entry.id
    species_name = $Entry.display_name
  }
  return @{
    relative = $relative.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
    absolute = Join-Path $BaseRoot $relative
  }
}

function Build-FrameworkSpeciesPayload {
  param(
    [hashtable]$Entry,
    [int]$Slot,
    [hashtable]$Mapping,
    [string]$BundleRoot
  )

  $assets = @{}
  $hiddenAbilities = @()
  if ($Entry.game_data.hidden_ability) {
    $hiddenAbilities += $Entry.game_data.hidden_ability
  }
  foreach ($kind in @("front", "back", "icon", "overworld", "shiny_front", "shiny_back")) {
    if (-not $Entry.assets[$kind]) { continue }
    $assetInfo = Get-AssetOutputPath -Kind $kind -Entry $Entry -Mapping $Mapping -BaseRoot $BundleRoot
    if ($assetInfo) {
      $assets[$kind] = $assetInfo.relative.Replace([System.IO.Path]::DirectorySeparatorChar, "/")
    }
  }

  $payload = @{
    id                     = $Entry.id
    slot                   = $Slot
    kind                   = $Entry.game_data.kind
    name                   = $Entry.display_name
    category               = $Entry.game_data.category
    pokedex_entry          = $Entry.game_data.pokedex_entry
    type1                  = $Entry.game_data.types[0]
    type2                  = if ($Entry.game_data.types.Count -gt 1) { $Entry.game_data.types[1] } else { $null }
    base_stats             = $Entry.game_data.base_stats
    base_exp               = 64
    growth_rate            = $Entry.game_data.growth_rate
    gender_ratio           = $Entry.game_data.gender_ratio
    catch_rate             = if ($null -ne $Entry.game_data.catch_rate) { [int]$Entry.game_data.catch_rate } else { 45 }
    happiness              = [int]$Entry.game_data.happiness
    moves                  = @($Entry.game_data.moves)
    teach_moves            = @($Entry.game_data.teach_moves)
    egg_moves              = @($Entry.game_data.egg_moves)
    abilities              = @($Entry.game_data.abilities)
    hidden_abilities       = $hiddenAbilities
    egg_groups             = Normalize-TextList $Entry.game_data.egg_groups
    hatch_steps            = 5120
    evolutions             = @($Entry.game_data.evolutions)
    height                 = if ($null -ne $Entry.game_data.height) { [int][Math]::Round([double]$Entry.game_data.height) } else { 10 }
    weight                 = if ($null -ne $Entry.game_data.weight) { [int][Math]::Round([double]$Entry.game_data.weight) } else { 100 }
    color                  = "Red"
    shape                  = "Head"
    habitat                = "None"
    generation             = 9
    starter_eligible       = $false
    encounter_eligible     = $false
    trainer_eligible       = $false
    fusion_rule            = "blocked"
    standard_fusion_compatible = $false
    assets                 = $assets
    source_pack            = $Entry.source_pack
    source_url             = $Entry.source_url
    creator                = $Entry.creator
    credit_text            = $Entry.credit_text
    usage_permission       = $Entry.usage_permission
    auto_import_allowed    = [bool]$Entry.auto_import_allowed
    manual_review_required = [bool]$Entry.manual_review_required
    integration            = $Entry.integration
    notes                  = $Entry.notes
    export_meta            = @{
      author    = $Entry.creator
      pack_name = $Entry.source_pack
      version   = (Get-FirstValue @($Entry.pack_version, "1.0.0"))
      tags      = @("imported_pack", $Entry.pack_slug)
    }
  }
  return $payload
}

function Stage-EntryAssets {
  param(
    [hashtable]$Entry,
    [hashtable]$Mapping,
    [string]$OutputAssetsRoot,
    [string]$BundleRoot
  )

  $stagedAssets = @{}
  foreach ($kind in @("front", "back", "icon", "overworld", "shiny_front", "shiny_back")) {
    $source = $Entry.assets[$kind]
    if (-not $source -or -not (Test-Path -LiteralPath $source)) { continue }
    $targetName = "{0}.png" -f $Entry.id
    $transformedPath = Join-Path (Join-Path $OutputAssetsRoot $kind) $targetName
    $targetWidth = 0
    $targetHeight = 0
    switch ($kind) {
      "front" { $targetWidth = [int]$script:RuntimeConfig.target_sprite_width; $targetHeight = [int]$script:RuntimeConfig.target_sprite_height }
      "back" { $targetWidth = [int]$script:RuntimeConfig.target_backsprite_width; $targetHeight = [int]$script:RuntimeConfig.target_backsprite_height }
      "icon" { $targetWidth = [int]$script:RuntimeConfig.target_icon_width; $targetHeight = [int]$script:RuntimeConfig.target_icon_height }
      "shiny_front" { $targetWidth = [int]$script:RuntimeConfig.target_sprite_width; $targetHeight = [int]$script:RuntimeConfig.target_sprite_height }
      "shiny_back" { $targetWidth = [int]$script:RuntimeConfig.target_backsprite_width; $targetHeight = [int]$script:RuntimeConfig.target_backsprite_height }
    }
    Convert-AssetToPng -SourcePath $source -DestinationPath $transformedPath -TargetWidth $targetWidth -TargetHeight $targetHeight -ResizeMode $script:RuntimeConfig.resize_mode
    $stagedAssets[$kind] = $transformedPath

    $bundleTarget = Get-AssetOutputPath -Kind $kind -Entry $Entry -Mapping $Mapping -BaseRoot $BundleRoot
    if ($bundleTarget) {
      Ensure-Directory (Split-Path -Parent $bundleTarget.absolute)
      Copy-Item -LiteralPath $transformedPath -Destination $bundleTarget.absolute -Force
    }
  }
  return $stagedAssets
}

function Apply-FrameworkBundle {
  param(
    [string]$BundleRoot,
    [string]$FrameworkRoot,
    [bool]$OverwriteExisting
  )

  $applied = @()
  $skipped = @()
  $conflicts = @()
  Get-ChildItem -Path $BundleRoot -Recurse -File | ForEach-Object {
    $relative = $_.FullName.Substring($BundleRoot.Length).TrimStart("\", "/")
    $target = Join-Path $FrameworkRoot $relative
    Ensure-Directory (Split-Path -Parent $target)
    if (Test-Path -LiteralPath $target) {
      $sourceHash = Get-FileHashString -Path $_.FullName
      $targetHash = Get-FileHashString -Path $target
      if ($sourceHash -and $sourceHash -eq $targetHash) {
        $skipped += $target
        return
      }
      if (-not $OverwriteExisting) {
        $conflicts += $target
        return
      }
    }
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    $applied += $target
  }

  return @{
    applied   = $applied
    skipped   = $skipped
    conflicts = $conflicts
  }
}

Ensure-Directory $script:CacheRoot
Ensure-Directory $script:StateRoot
Ensure-Directory $OutputRoot

$manifestDirectory = Split-Path -Parent (Resolve-AbsolutePath -Path $ManifestPath -RelativeTo (Get-Location))
$loadedConfig = Read-JsonFile -Path $ConfigPath -Fallback @{}
$script:RuntimeConfig = Merge-Hashtables -Base $script:DefaultConfig -Override $loadedConfig
if ($ApplyBundle.IsPresent) {
  $script:RuntimeConfig.dry_run_only = $false
  $script:RuntimeConfig.apply_bundle_to_framework = $true
}
$loadedMapping = Read-JsonFile -Path $MappingPath -Fallback @{}
$script:FrameworkMapping = Merge-Hashtables -Base $script:DefaultMapping -Override $loadedMapping

$frameworkContext = Get-FrameworkContext
$statePath = Resolve-AbsolutePath -Path $script:RuntimeConfig.state_file -RelativeTo $script:ImporterRoot
$state = Get-ImporterState -Path $statePath
$manifest = Read-JsonFile -Path $ManifestPath -Fallback @{ sources = @() }

$bundleRoot = Join-Path $OutputRoot $script:FrameworkMapping.bundle.directory
$outputAssetsRoot = Join-Path $OutputRoot "assets"
$outputSpeciesRoot = Join-Path $OutputRoot "species"
Ensure-Directory $bundleRoot
Ensure-Directory $outputAssetsRoot
Ensure-Directory $outputSpeciesRoot

$allNormalizedEntries = @()
$approvedEntries = @()
$reviewQueue = @()
$rejectedItems = @()
$creditsManifest = @()
$importSummary = @()

foreach ($source in @($manifest.sources)) {
  if (-not ($source -is [hashtable])) { continue }
  if ($source.enabled -eq $false) {
    Write-ImporterLog "Skipping disabled source $((Get-FirstValue @($source.id, $source.pack_name)))." "INFO"
    continue
  }

  $packName = (Get-FirstValue @($source.pack_name, $source.id, "pack")).ToString()
  Write-ImporterLog "Ingesting source '$packName'." "INFO"

  $adapter = $null
  try {
    $adapter = Get-SourceRootFromAdapter -Source $source -ManifestDirectory $manifestDirectory
  } catch {
    Write-ImporterLog "Failed to prepare source '$packName': $($_.Exception.Message)" "ERROR"
    $rejectedItems += @{
      source_pack = $packName
      reason      = $_.Exception.Message
      source_type = (Get-FirstValue @($source.type, $source.adapter, "folder"))
    }
    continue
  }

  $textFiles = Get-SourceTextFiles -WorkingRoot $adapter.working_root -Source $source
  $permission = Get-PermissionStatus -Source $source -TextFiles $textFiles -StrictMode ([bool]$script:RuntimeConfig.strict_permission_mode)
  $metadataFiles = Get-SourceMetadataFiles -WorkingRoot $adapter.working_root -Source $source
  $metadataIndex = Get-PackMetadataIndex -MetadataFiles $metadataFiles -Source $source -FrameworkContext $frameworkContext
  $candidates = Discover-SpeciesCandidates -Source $source -WorkingRoot $adapter.working_root -MetadataIndex $metadataIndex

  $packSummary = @{
    pack_name         = $packName
    source_type       = $adapter.source_type
    permission_status = $permission.status
    permission_reason = $permission.reason
    discovered_species = @($candidates).Count
    approved_entries  = 0
    review_entries    = 0
    rejected_entries  = 0
  }

  foreach ($candidate in $candidates) {
    $entry = Normalize-EntryForFramework -Source $source -Candidate $candidate -FrameworkContext $frameworkContext
    $validation = Validate-NormalizedEntry -Entry $entry -FrameworkContext $frameworkContext -Permission $permission -Source $source
    $entry.integration.insert_errors += @($validation.errors)
    $entry.validation = @{
      errors      = $validation.errors
      warnings    = $validation.warnings
      suggestions = $validation.suggestions
    }

    if ($entry.integration.insert_status -eq "skipped_duplicate") {
      $entry.auto_import_allowed = $false
      $entry.manual_review_required = $false
      $packSummary.review_entries += 0
    } elseif (@($validation.errors).Count -gt 0) {
      if ($permission.status -eq "REJECTED") {
        $entry.integration.insert_status = "rejected"
        $packSummary.rejected_entries++
        $rejectedItems += @{
          species_name = $entry.display_name
          source_pack  = $entry.source_pack
          reasons      = @($validation.errors)
          files        = $entry.file_references
        }
      } else {
        $entry.integration.insert_status = "review"
        $entry.manual_review_required = $true
        $packSummary.review_entries++
        $reviewQueue += @($validation.review)
      }
    } else {
      $entry.integration.insert_status = "ready"
      $entry.auto_import_allowed = $true
      $slot = Get-NextAvailableSlot -FrameworkContext $frameworkContext -State $state -InternalId $entry.id
      $entry.integration.framework_slot = $slot
      $approvedEntries += $entry
      $packSummary.approved_entries++
      $creditsManifest += @{
        species_name      = $entry.display_name
        creator           = $entry.creator
        source_pack       = $entry.source_pack
        source_url        = $entry.source_url
        usage_permission  = $entry.usage_permission
        credit_text       = $entry.credit_text
        required_release_note = if ($entry.credit_text) { $true } else { $false }
      }
    }

    $allNormalizedEntries += $entry
  }

  $importSummary += $packSummary
}

$speciesManifest = @()
$packGroups = @{}
foreach ($entry in $approvedEntries) {
  if (-not $packGroups.ContainsKey($entry.pack_slug)) {
    $packGroups[$entry.pack_slug] = @()
  }
  $packGroups[$entry.pack_slug] += $entry
}

foreach ($entry in $approvedEntries) {
  $stagedAssets = Stage-EntryAssets -Entry $entry -Mapping $script:FrameworkMapping -OutputAssetsRoot $outputAssetsRoot -BundleRoot $bundleRoot
  $entry.staged_assets = $stagedAssets
  $payload = Build-FrameworkSpeciesPayload -Entry $entry -Slot ([int]$entry.integration.framework_slot) -Mapping $script:FrameworkMapping -BundleRoot $bundleRoot
  $speciesManifest += @{
    id              = $entry.id
    display_name    = $entry.display_name
    source_pack     = $entry.source_pack
    framework_slot  = $entry.integration.framework_slot
    insert_status   = $entry.integration.insert_status
    permission      = $entry.usage_permission
    assets          = $payload.assets
  }
}

foreach ($packSlug in $packGroups.Keys) {
  $entries = $packGroups[$packSlug]
  $speciesPayload = @{
    species = @()
  }
  foreach ($entry in $entries) {
    $speciesPayload.species += Build-FrameworkSpeciesPayload -Entry $entry -Slot ([int]$entry.integration.framework_slot) -Mapping $script:FrameworkMapping -BundleRoot $bundleRoot
  }
  $fileTemplate = $script:FrameworkMapping.species_registry.filename_template
  $relativeSpeciesFile = Expand-Template -Template $fileTemplate -Variables @{ pack_slug = $packSlug }
  $speciesOutputPath = Join-Path $bundleRoot (Join-Path $script:FrameworkMapping.species_registry.directory $relativeSpeciesFile)
  Write-JsonFile -Path $speciesOutputPath -Data $speciesPayload
}

$creditsByPack = @{}
foreach ($credit in $creditsManifest) {
  $packSlug = (Normalize-Slug -Text $credit.source_pack -Separator "_").ToLowerInvariant()
  if (-not $creditsByPack.ContainsKey($packSlug)) {
    $creditsByPack[$packSlug] = @()
  }
  $creditsByPack[$packSlug] += $credit
}
foreach ($packSlug in $creditsByPack.Keys) {
  $relativeCreditsPath = Join-Path $script:FrameworkMapping.credits.directory (Expand-Template -Template $script:FrameworkMapping.credits.credits_manifest_template -Variables @{ pack_slug = $packSlug })
  Write-JsonFile -Path (Join-Path $bundleRoot $relativeCreditsPath) -Data @{ credits = $creditsByPack[$packSlug] }
}

$noticeLines = @()
$noticeLines += "Custom Species Framework Import Notice"
$noticeLines += "Generated: $($script:Now.ToString("yyyy-MM-dd HH:mm:ss"))"
$noticeLines += ""
foreach ($packSummary in $importSummary) {
  $noticeLines += ("Pack: {0}" -f $packSummary.pack_name)
  $packCredits = $creditsManifest | Where-Object { $_.source_pack -eq $packSummary.pack_name }
  foreach ($credit in $packCredits) {
    $noticeLines += ("  - {0}: {1} ({2})" -f $credit.species_name, $credit.creator, $credit.usage_permission)
    if ($credit.credit_text) {
      $noticeLines += ("    Credit: {0}" -f $credit.credit_text)
    }
  }
  $noticeLines += ""
}
$noticeFileName = $script:FrameworkMapping.credits.notice_template
Set-Content -LiteralPath (Join-Path $OutputRoot $noticeFileName) -Value ($noticeLines -join "`r`n") -Encoding UTF8
Set-Content -LiteralPath (Join-Path $bundleRoot $noticeFileName) -Value ($noticeLines -join "`r`n") -Encoding UTF8

Write-JsonFile -Path (Join-Path $OutputRoot "species\species_manifest.json") -Data @{ species = $speciesManifest }
Write-JsonFile -Path (Join-Path $OutputRoot "species\species_data.json") -Data @{ species = $allNormalizedEntries }
Write-JsonFile -Path (Join-Path $OutputRoot "credits_manifest.json") -Data @{ credits = $creditsManifest }
Write-JsonFile -Path (Join-Path $OutputRoot "review_queue.json") -Data @{ review = $reviewQueue }
Write-JsonFile -Path (Join-Path $OutputRoot "rejected_items.json") -Data @{ rejected = $rejectedItems }

$report = @{
  generated_at = $script:Now.ToString("yyyy-MM-dd HH:mm:ss")
  framework_root = $script:FrameworkRoot
  dry_run_only = [bool]$script:RuntimeConfig.dry_run_only
  apply_bundle = [bool]$script:RuntimeConfig.apply_bundle_to_framework
  sources = $importSummary
  totals = @{
    discovered = @($allNormalizedEntries).Count
    ready      = @($approvedEntries).Count
    review     = @($reviewQueue).Count
    rejected   = @($rejectedItems).Count
  }
}

$applyResult = $null
if ([bool]$script:RuntimeConfig.apply_bundle_to_framework -and -not [bool]$script:RuntimeConfig.dry_run_only) {
  Write-ImporterLog "Applying framework bundle into $script:FrameworkRoot." "INFO"
  $applyResult = Apply-FrameworkBundle -BundleRoot $bundleRoot -FrameworkRoot $script:FrameworkRoot -OverwriteExisting ([bool]$script:RuntimeConfig.overwrite_existing_species)
  $report.apply_result = $applyResult
  Write-JsonFile -Path (Join-Path $OutputRoot "rollback_manifest.json") -Data @{
    generated_at = $script:Now.ToString("yyyy-MM-dd HH:mm:ss")
    applied_files = $applyResult.applied
    skipped_files = $applyResult.skipped
    conflicts     = $applyResult.conflicts
  }
} else {
  $report.apply_result = @{
    applied_files = @()
    skipped_files = @()
    conflicts     = @()
  }
}

Write-JsonFile -Path (Join-Path $OutputRoot "import_report.json") -Data $report
Save-ImporterState -Path $statePath -State $state

Write-ImporterLog ("Import complete: {0} ready, {1} review items, {2} rejected." -f @($approvedEntries).Count, @($reviewQueue).Count, @($rejectedItems).Count) "INFO"
