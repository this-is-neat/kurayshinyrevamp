$ErrorActionPreference = "Stop"

$script:CreatorRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ModRoot = [System.IO.Path]::GetFullPath((Join-Path $script:CreatorRoot ".."))
$script:GameRoot = [System.IO.Path]::GetFullPath((Join-Path $script:ModRoot "..\.."))
$script:WebRoot = Join-Path $script:CreatorRoot "web"
$script:CreatorDataRoot = Join-Path $script:CreatorRoot "data"
$script:CreatorSpeciesFile = Join-Path $script:ModRoot "data\species\user_created_species.json"
$script:CreatorStarterFile = Join-Path $script:ModRoot "data\creator_starter_sets.json"
$script:CreatorDeliveryFile = Join-Path $script:ModRoot "data\creator_delivery_queue.json"
$script:FrameworkConfigFile = Join-Path $script:ModRoot "data\framework_config.json"
$script:LaunchInfoFile = Join-Path $script:CreatorRoot "_creator_server_url.txt"
$script:CatalogFile = Join-Path $script:CreatorDataRoot "game_catalog.json"
$script:CatalogSummaryFile = Join-Path $script:CreatorDataRoot "game_catalog.summary.json"
$script:CatalogSpeciesRoot = Join-Path $script:CreatorDataRoot "catalog_species"
$script:CatalogBuilderScript = Join-Path $script:CreatorRoot "build_catalog_from_install.rb"
$script:CatalogViewsBuilderScript = Join-Path $script:CreatorRoot "build_catalog_views.rb"
$script:ExportRoot = Join-Path $script:CreatorDataRoot "exports"
$script:ImporterRoot = Join-Path $script:ModRoot "importer"
$script:ImporterConfigRoot = Join-Path $script:ImporterRoot "config"
$script:ImporterOutputRoot = Join-Path $script:ImporterRoot "import_output"
$script:ImporterScript = Join-Path $script:ImporterRoot "import_fakemon_pack.ps1"
$script:ImporterManifestFile = Join-Path $script:ImporterConfigRoot "source_manifest.json"
$script:ImporterManifestExampleFile = Join-Path $script:ImporterConfigRoot "source_manifest.example.json"
$script:ImporterConfigFile = Join-Path $script:ImporterConfigRoot "importer_config.json"
$script:ImporterMappingFile = Join-Path $script:ImporterConfigRoot "framework_mapping.json"
$script:ImporterStateFile = Join-Path $script:ImporterRoot "state\import_state.json"
$script:CatalogCache = @{
  stamp = ""
  raw = ""
  served_raw = ""
  parsed = $null
  summary = $null
  metadata = @{
    available = $false
    generated_at = $null
    species_count = 0
  }
}
$script:CatalogSummaryCache = @{
  stamp = ""
  raw = ""
  served_raw = ""
  parsed = $null
  metadata = @{
    available = $false
    generated_at = $null
    species_count = 0
  }
}
$script:LegacyReservedIdMin = 252000
$script:DeliveryHistoryLimit = 36

function Ensure-Directory {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) { return }
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Write-Utf8File {
  param(
    [string]$Path,
    [string]$Content
  )
  Ensure-Directory (Split-Path -Parent $Path)
  $encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Get-CatalogSourceFiles {
  $paths = New-Object System.Collections.Generic.List[string]
  foreach ($path in @(
    (Join-Path $script:GameRoot "Data\species.dat"),
    (Join-Path $script:GameRoot "Data\moves.dat"),
    (Join-Path $script:GameRoot "Data\abilities.dat"),
    (Join-Path $script:GameRoot "Data\items.dat"),
    (Join-Path $script:GameRoot "Data\types.dat"),
    (Join-Path $script:GameRoot "Data\pokedex\all_entries.json"),
    (Join-Path $script:ModRoot "data\species\user_created_species.json")
  )) {
    if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
      [void]$paths.Add($path)
    }
  }

  $speciesDir = Join-Path $script:ModRoot "data\species"
  if (Test-Path -LiteralPath $speciesDir) {
    Get-ChildItem -LiteralPath $speciesDir -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
      [void]$paths.Add($_.FullName)
    }
  }

  return @($paths.ToArray() | Select-Object -Unique)
}

function Test-CatalogNeedsRefresh {
  if (-not (Test-Path -LiteralPath $script:CatalogFile)) {
    return $true
  }

  $catalogItem = Get-Item -LiteralPath $script:CatalogFile -ErrorAction SilentlyContinue
  if ($null -eq $catalogItem -or $catalogItem.Length -le 0) {
    return $true
  }

  return $false
}

function Invoke-StandaloneCatalogBuilder {
  if (-not (Test-Path -LiteralPath $script:CatalogBuilderScript)) {
    return $false
  }

  $rubyCommand = Get-Command ruby -ErrorAction SilentlyContinue
  if ($null -eq $rubyCommand) {
    return $false
  }

  try {
    $null = & $rubyCommand.Source $script:CatalogBuilderScript $script:GameRoot $script:ModRoot $script:CatalogFile 2>&1
  } catch {
    return $false
  }

  return (Test-Path -LiteralPath $script:CatalogFile)
}

function Ensure-CatalogAvailable {
  if (-not (Test-CatalogNeedsRefresh)) {
    return
  }
  Invoke-StandaloneCatalogBuilder | Out-Null
}

function Test-CatalogViewsNeedRefresh {
  if (-not (Test-Path -LiteralPath $script:CatalogSummaryFile)) {
    return $true
  }

  $summaryItem = Get-Item -LiteralPath $script:CatalogSummaryFile -ErrorAction SilentlyContinue
  if ($null -eq $summaryItem -or $summaryItem.Length -le 0) {
    return $true
  }

  if (-not (Test-Path -LiteralPath $script:CatalogSpeciesRoot)) {
    return $true
  }

  $detailCount = @(Get-ChildItem -LiteralPath $script:CatalogSpeciesRoot -Filter *.json -File -ErrorAction SilentlyContinue).Count
  if ($detailCount -le 0) {
    return $true
  }

  $expectedCount = [int]((Get-CatalogMetadata)["species_count"])
  if ($expectedCount -gt 0 -and $detailCount -lt $expectedCount) {
    return $true
  }

  $catalogItem = Get-Item -LiteralPath $script:CatalogFile -ErrorAction SilentlyContinue
  if ($null -eq $catalogItem) {
    return $false
  }

  return ($summaryItem.LastWriteTimeUtc -lt $catalogItem.LastWriteTimeUtc)
}

function Invoke-CatalogViewsBuilder {
  if (-not (Test-Path -LiteralPath $script:CatalogViewsBuilderScript)) {
    return $false
  }

  $rubyCommand = Get-Command ruby -ErrorAction SilentlyContinue
  if ($null -eq $rubyCommand) {
    return $false
  }

  try {
    $null = & $rubyCommand.Source $script:CatalogViewsBuilderScript $script:GameRoot $script:CatalogFile $script:CatalogSummaryFile $script:CatalogSpeciesRoot 2>&1
  } catch {
    return $false
  }

  return (Test-Path -LiteralPath $script:CatalogSummaryFile)
}

function Ensure-CatalogViewsAvailable {
  Ensure-CatalogAvailable
  if (-not (Test-CatalogViewsNeedRefresh)) {
    return
  }
  Invoke-CatalogViewsBuilder | Out-Null
}

function Ensure-ImporterWorkspaceAvailable {
  Ensure-Directory $script:ImporterRoot
  Ensure-Directory $script:ImporterConfigRoot
  Ensure-Directory $script:ImporterOutputRoot
  if (-not (Test-Path -LiteralPath $script:ImporterManifestFile)) {
    Write-JsonFile -Path $script:ImporterManifestFile -Data @{ sources = @() }
  }
}

function Open-CreatorBrowserWindow {
  param([string]$Url)

  $browserCandidates = @(
    @{ Path = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"; Args = @("--new-window", $Url) },
    @{ Path = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"; Args = @("--new-window", $Url) },
    @{ Path = "C:\Program Files\Google\Chrome\Application\chrome.exe"; Args = @("--new-window", $Url) },
    @{ Path = "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"; Args = @("--new-window", $Url) },
    @{ Path = "C:\Program Files\Mozilla Firefox\firefox.exe"; Args = @("-new-window", $Url) },
    @{ Path = "$env:LOCALAPPDATA\Programs\Firefox\firefox.exe"; Args = @("-new-window", $Url) }
  )

  foreach ($browser in $browserCandidates) {
    if (Test-Path -LiteralPath $browser.Path) {
      Start-Process -FilePath $browser.Path -ArgumentList $browser.Args | Out-Null
      return
    }
  }

  Start-Process $Url | Out-Null
}

function Convert-ToHashtable {
  param([object]$Value)
  if ($null -eq $Value) { return $null }
  if ($Value -is [System.Collections.IDictionary]) {
    $result = @{}
    foreach ($key in $Value.Keys) {
      $result[$key] = Convert-ToHashtable $Value[$key]
    }
    return $result
  }
  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    $items = New-Object System.Collections.Generic.List[object]
    foreach ($item in $Value) {
      [void]$items.Add((Convert-ToHashtable $item))
    }
    return @($items.ToArray())
  }
  if ($Value.PSObject -and $Value.PSObject.Properties.Count -gt 0 -and -not ($Value -is [string]) -and -not ($Value -is [ValueType])) {
    $result = @{}
    foreach ($property in $Value.PSObject.Properties) {
      $result[$property.Name] = Convert-ToHashtable $property.Value
    }
    return $result
  }
  return $Value
}

function Read-JsonFile {
  param(
    [string]$Path,
    [object]$Fallback
  )
  if (-not (Test-Path -LiteralPath $Path)) { return $Fallback }
  $raw = Get-Content -LiteralPath $Path -Raw
  if ([string]::IsNullOrWhiteSpace($raw)) { return $Fallback }
  try {
    return Convert-ToHashtable (ConvertFrom-Json $raw)
  } catch {
    return $Fallback
  }
}

function Write-JsonFile {
  param(
    [string]$Path,
    [object]$Data
  )
  $json = $Data | ConvertTo-Json -Depth 100
  Write-Utf8File -Path $Path -Content $json
}

function Read-TextFile {
  param(
    [string]$Path,
    [string]$Fallback = ""
  )
  if (-not (Test-Path -LiteralPath $Path)) {
    return $Fallback
  }
  try {
    return [string]::Concat((Get-Content -LiteralPath $Path -Raw))
  } catch {
    return $Fallback
  }
}

function Normalize-Bool {
  param([object]$Value)
  if ($Value -is [bool]) { return $Value }
  if ($null -eq $Value) { return $false }
  return @("1", "true", "yes", "on") -contains $Value.ToString().Trim().ToLowerInvariant()
}

function Normalize-Int {
  param(
    [object]$Value,
    [int]$Default = 0,
    [int]$Minimum = [int]::MinValue
  )
  try {
    $parsed = [int]$Value
    if ($parsed -lt $Minimum) { return $Minimum }
    return $parsed
  } catch {
    return $Default
  }
}

function Normalize-NullableInt {
  param([object]$Value)
  if ($null -eq $Value) { return $null }
  $text = $Value.ToString().Trim()
  if ($text.Length -eq 0) { return $null }
  if ($text -match '^-?\d+$') { return [int]$text }
  return $text
}

function Normalize-Token {
  param([object]$Value)
  if ($null -eq $Value) { return $null }
  $token = $Value.ToString().Trim().ToUpperInvariant()
  if ($token.Length -eq 0) { return $null }
  $token = [regex]::Replace($token, '[^A-Z0-9_]', '_')
  $token = [regex]::Replace($token, '_+', '_').Trim('_')
  if ($token.Length -eq 0) { return $null }
  return $token
}

function Normalize-Identifier {
  param([object]$Value)
  if ($null -eq $Value) { return $null }
  $text = $Value.ToString().Trim()
  if ($text.Length -eq 0) { return $null }
  $text = [regex]::Replace($text, '[^A-Za-z0-9_]', '_')
  $text = [regex]::Replace($text, '_+', '_').Trim('_')
  if ($text.Length -eq 0) { return $null }
  return $text
}

function Normalize-DisplayText {
  param([object]$Value)
  if ($null -eq $Value) { return "" }
  return $Value.ToString().Trim()
}

function Normalize-StringList {
  param([object]$Value)
  if ($null -eq $Value) { return @() }
  $items = @()
  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    foreach ($entry in $Value) {
      $text = Normalize-DisplayText $entry
      if ($text) { $items += $text }
    }
  } else {
    $text = Normalize-DisplayText $Value
    if ($text) {
      foreach ($entry in ($text -split "[,\r\n;]+")) {
        $clean = $entry.Trim()
        if ($clean) { $items += $clean }
      }
    }
  }
  return @($items | Select-Object -Unique)
}

function Coalesce-Token {
  param(
    [object]$Value,
    [string]$Default
  )
  $normalized = Normalize-Token $Value
  if ($normalized) { return $normalized }
  return $Default
}

function Resolve-CatalogId {
  param(
    [object]$Value,
    [string[]]$CatalogKeys = @()
  )
  $normalized = Normalize-Identifier $Value
  if (-not $normalized) { return $null }
  $catalog = Read-Catalog
  foreach ($catalogKey in $CatalogKeys) {
    if (-not ($catalog -is [System.Collections.IDictionary])) { continue }
    if (-not $catalog.ContainsKey($catalogKey)) { continue }
    if ($null -eq $catalog[$catalogKey]) { continue }
    foreach ($entry in @($catalog[$catalogKey])) {
      if ($null -eq $entry) { continue }
      $entryId = $entry["id"]
      if ($entryId -and $entryId.ToString().Equals($normalized, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $entryId.ToString()
      }
    }
  }
  return $normalized
}

function Get-CatalogEntryById {
  param(
    [string]$CatalogKey,
    [object]$Id
  )
  if ([string]::IsNullOrWhiteSpace($CatalogKey) -or $null -eq $Id) { return $null }
  $catalog = Read-Catalog
  if (-not ($catalog -is [System.Collections.IDictionary])) { return $null }
  if (-not $catalog.ContainsKey($CatalogKey)) { return $null }
  if ($null -eq $catalog[$CatalogKey]) { return $null }
  foreach ($entry in @($catalog[$CatalogKey])) {
    if ($null -eq $entry) { continue }
    $entryId = $entry["id"]
    if ($entryId -and $entryId.ToString().Equals($Id.ToString(), [System.StringComparison]::OrdinalIgnoreCase)) {
      return $entry
    }
  }
  return $null
}

function Get-EvolutionParameterKind {
  param([string]$MethodId)
  $methodEntry = Get-CatalogEntryById -CatalogKey "evolution_methods" -Id $MethodId
  if ($methodEntry -and -not [string]::IsNullOrWhiteSpace($methodEntry["parameter_kind"])) {
    return $methodEntry["parameter_kind"].ToString()
  }

  switch ($MethodId) {
    "Level" { return "Integer" }
    "LevelMale" { return "Integer" }
    "LevelFemale" { return "Integer" }
    "LevelDay" { return "Integer" }
    "LevelNight" { return "Integer" }
    "LevelMorning" { return "Integer" }
    "LevelAfternoon" { return "Integer" }
    "LevelEvening" { return "Integer" }
    "LevelNoWeather" { return "Integer" }
    "LevelSun" { return "Integer" }
    "LevelRain" { return "Integer" }
    "LevelSnow" { return "Integer" }
    "LevelSandstorm" { return "Integer" }
    "LevelCycling" { return "Integer" }
    "LevelSurfing" { return "Integer" }
    "LevelDiving" { return "Integer" }
    "LevelDarkness" { return "Integer" }
    "LevelDarkInParty" { return "Integer" }
    "AttackGreater" { return "Integer" }
    "AtkDefEqual" { return "Integer" }
    "DefenseGreater" { return "Integer" }
    "Silcoon" { return "Integer" }
    "Cascoon" { return "Integer" }
    "Ninjask" { return "Integer" }
    "Shedinja" { return "Integer" }
    "Beauty" { return "Integer" }
    "Location" { return "Integer" }
    "Region" { return "Integer" }
    "HappinessMove" { return "Move" }
    "HappinessMoveType" { return "Type" }
    "HappinessHoldItem" { return "Item" }
    "HoldItem" { return "Item" }
    "HoldItemMale" { return "Item" }
    "HoldItemFemale" { return "Item" }
    "DayHoldItem" { return "Item" }
    "NightHoldItem" { return "Item" }
    "HoldItemHappiness" { return "Item" }
    "HasMove" { return "Move" }
    "HasMoveType" { return "Type" }
    "HasInParty" { return "Species" }
    "Item" { return "Item" }
    "ItemMale" { return "Item" }
    "ItemFemale" { return "Item" }
    "ItemDay" { return "Item" }
    "ItemNight" { return "Item" }
    "ItemHappiness" { return "Item" }
    "TradeItem" { return "Item" }
    "TradeSpecies" { return "Species" }
    default { return $null }
  }
}

function Normalize-IdWithPrefix {
  param(
    [object]$Value,
    [string]$DisplayName = ""
  )
  $baseToken = Normalize-Token $Value
  if (-not $baseToken) {
    $baseToken = Normalize-Token $DisplayName
  }
  if (-not $baseToken) {
    $baseToken = "CUSTOMMON"
  }
  if ($baseToken -notmatch '^CSF_') {
    $baseToken = "CSF_$baseToken"
  }
  return $baseToken
}

function Convert-GamePathToCatalogUrl {
  param([string]$RelativePath)
  if ([string]::IsNullOrWhiteSpace($RelativePath)) { return $null }
  $normalized = $RelativePath.TrimStart('\', '/').Replace('\', '/')
  return "/game/$normalized"
}

function Resolve-GameCatalogAssetUrl {
  param([string[]]$RelativeCandidates)
  foreach ($relative in @($RelativeCandidates)) {
    if ([string]::IsNullOrWhiteSpace($relative)) { continue }
    $trimmed = $relative.TrimStart('\', '/')
    $candidate = Join-Path $script:GameRoot ($trimmed.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    if (Test-Path -LiteralPath $candidate) {
      return Convert-GamePathToCatalogUrl $trimmed
    }
  }
  return $null
}

function Resolve-CatalogReferenceId {
  param([object]$Value)
  if ($null -eq $Value) { return $null }
  if ($Value -is [System.Collections.IDictionary]) {
    return Normalize-Identifier $Value["id"]
  }
  return Normalize-Identifier $Value
}

function Repair-CatalogSpeciesVisuals {
  param([hashtable]$Entry)
  if (-not $Entry) { return $Entry }
  $id = Normalize-Identifier $Entry["id"]
  $idNumber = Normalize-Int $Entry["id_number"] 0 0
  $visuals = Convert-ToHashtable $Entry["visuals"]
  if (-not ($visuals -is [System.Collections.IDictionary])) {
    $visuals = @{}
  }

  $front = Resolve-GameCatalogAssetUrl @(
    $(if ($idNumber -gt 0) { "Graphics/BaseSprites/$idNumber.png" }),
    $(if ($idNumber -gt 0) { "Graphics/Battlers/$idNumber/$idNumber.png" }),
    $(if ($id) { "Graphics/Pokemon/Front/$id.png" })
  )
  if ($front) {
    $visuals["front"] = $front
  }

  $back = Resolve-GameCatalogAssetUrl @(
    $(if ($id) { "Graphics/Pokemon/Back/$id.png" })
  )
  if ($back) {
    $visuals["back"] = $back
  } elseif ($front) {
    $visuals["back"] = $front
  }

  $icon = Resolve-GameCatalogAssetUrl @(
    $(if ($id) { "Graphics/Pokemon/Icons/$id.png" }),
    $(if ($idNumber -gt 0) { "Graphics/Icons/icon$idNumber.png" }),
    $(if ($idNumber -gt 0) { ("Graphics/Icons/icon{0:D3}.png" -f $idNumber) })
  )
  if ($icon) {
    $visuals["icon"] = $icon
  } elseif ($front) {
    $visuals["icon"] = $front
  }

  $Entry["visuals"] = $visuals
  return $Entry
}

function Repair-CatalogPayload {
  param([hashtable]$Catalog)
  if (-not ($Catalog -is [System.Collections.IDictionary])) {
    return @{}
  }
  if (-not $Catalog.ContainsKey("species") -or $null -eq $Catalog["species"]) {
    $Catalog["species"] = @()
    return $Catalog
  }

  $speciesById = @{}
  foreach ($entry in @($Catalog["species"])) {
    if ($entry -is [System.Collections.IDictionary] -and $entry["id"]) {
      $speciesById[(Normalize-Identifier $entry["id"])] = $entry
    }
  }

  $repaired = @()
  foreach ($entry in @($Catalog["species"])) {
    $safeEntry = Convert-ToHashtable $entry
    if (-not ($safeEntry -is [System.Collections.IDictionary])) {
      $repaired += ,$safeEntry
      continue
    }
    Repair-CatalogSpeciesVisuals -Entry $safeEntry | Out-Null

    $fallbackId = Resolve-CatalogReferenceId $safeEntry["fallback_species"]
    if (-not $fallbackId) {
      $fallbackId = Resolve-CatalogReferenceId $safeEntry["base_species"]
    }
    if ($fallbackId -and $speciesById.ContainsKey($fallbackId)) {
      $fallbackEntry = Convert-ToHashtable $speciesById[$fallbackId]
      Repair-CatalogSpeciesVisuals -Entry $fallbackEntry | Out-Null
      $visuals = Convert-ToHashtable $safeEntry["visuals"]
      $fallbackVisuals = Convert-ToHashtable $fallbackEntry["visuals"]
      if (-not ($visuals -is [System.Collections.IDictionary])) { $visuals = @{} }
      if ($fallbackVisuals -is [System.Collections.IDictionary]) {
        foreach ($kind in @("front", "back", "icon")) {
          if ([string]::IsNullOrWhiteSpace([string]$visuals[$kind]) -and -not [string]::IsNullOrWhiteSpace([string]$fallbackVisuals[$kind])) {
            $visuals[$kind] = $fallbackVisuals[$kind]
          }
        }
      }
      $safeEntry["visuals"] = $visuals
    }
    $repaired += ,$safeEntry
  }
  $Catalog["species"] = $repaired
  return $Catalog
}

function Read-Catalog {
  Update-CatalogCache
  if ($null -eq $script:CatalogCache["parsed"]) {
    $raw = $script:CatalogCache["raw"]
    $parsed = @{}
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
      try {
        $parsed = Convert-ToHashtable (ConvertFrom-Json $raw)
      } catch {
        $parsed = @{}
      }
    }
    $parsed = Repair-CatalogPayload -Catalog $parsed
    $script:CatalogCache["parsed"] = $parsed
  }
  return $script:CatalogCache["parsed"]
}

function Read-CatalogSummary {
  Update-CatalogSummaryCache
  if ($null -eq $script:CatalogSummaryCache["parsed"]) {
    $raw = $script:CatalogSummaryCache["raw"]
    $parsed = @{}
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
      try {
        $parsed = Convert-ToHashtable (ConvertFrom-Json $raw)
      } catch {
        $parsed = @{}
      }
    }
    $script:CatalogSummaryCache["parsed"] = $parsed
  }
  return $script:CatalogSummaryCache["parsed"]
}

function Get-ServedCatalogRaw {
  Update-CatalogCache
  if ([string]::IsNullOrWhiteSpace($script:CatalogCache["served_raw"])) {
    $script:CatalogCache["served_raw"] = Normalize-ServedCatalogJsonRaw -Raw $script:CatalogCache["raw"]
  }
  return $script:CatalogCache["served_raw"]
}

function Get-CatalogFileStamp {
  if (-not (Test-Path -LiteralPath $script:CatalogFile)) {
    return ""
  }
  $item = Get-Item -LiteralPath $script:CatalogFile -ErrorAction SilentlyContinue
  if ($null -eq $item) {
    return ""
  }
  return "{0}:{1}" -f $item.LastWriteTimeUtc.Ticks, $item.Length
}

function Get-CatalogMetadataFromRaw {
  param([string]$Raw)

  $generatedAt = $null
  if ($Raw -match '"generated_at"\s*:\s*"([^"]+)"') {
    $generatedAt = $Matches[1]
  }
  $speciesCount = ([regex]::Matches($Raw, '"bst"\s*:')).Count
  return @{
    available = ($speciesCount -gt 0)
    generated_at = $generatedAt
    species_count = $speciesCount
  }
}

function Normalize-ServedCatalogJsonRaw {
  param([string]$Raw)

  if ([string]::IsNullOrWhiteSpace($Raw)) {
    return "{}"
  }

  return [regex]::Replace($Raw, '/game/Graphics/BaseSprites/(\d+)k\.png', {
    param($match)
    $plainPath = Join-Path $script:GameRoot ("Graphics\\BaseSprites\\{0}.png" -f $match.Groups[1].Value)
    if (Test-Path -LiteralPath $plainPath) {
      return "/game/Graphics/BaseSprites/{0}.png" -f $match.Groups[1].Value
    }
    return $match.Value
  })
}

function Update-CatalogCache {
  Ensure-CatalogAvailable
  $stamp = Get-CatalogFileStamp
  if ($stamp -eq $script:CatalogCache["stamp"]) {
    return
  }
  if (-not $stamp) {
    $script:CatalogCache["stamp"] = ""
    $script:CatalogCache["raw"] = ""
    $script:CatalogCache["served_raw"] = ""
    $script:CatalogCache["parsed"] = @{}
    $script:CatalogCache["summary"] = $null
    $script:CatalogCache["metadata"] = @{
      available = $false
      generated_at = $null
      species_count = 0
    }
    return
  }

  $raw = ""
  try {
    $raw = Get-Content -LiteralPath $script:CatalogFile -Raw -ErrorAction Stop
  } catch {
    $raw = ""
  }
  $script:CatalogCache["stamp"] = $stamp
  $script:CatalogCache["raw"] = $raw
  $script:CatalogCache["parsed"] = $null
  $script:CatalogCache["summary"] = $null
  $script:CatalogCache["served_raw"] = ""
  $script:CatalogCache["metadata"] = Get-CatalogMetadataFromRaw -Raw $raw
}

function Get-CatalogSummaryFileStamp {
  if (-not (Test-Path -LiteralPath $script:CatalogSummaryFile)) {
    return ""
  }
  $item = Get-Item -LiteralPath $script:CatalogSummaryFile -ErrorAction SilentlyContinue
  if ($null -eq $item) {
    return ""
  }
  return "{0}:{1}" -f $item.LastWriteTimeUtc.Ticks, $item.Length
}

function Update-CatalogSummaryCache {
  Ensure-CatalogViewsAvailable
  $stamp = Get-CatalogSummaryFileStamp
  if ($stamp -eq $script:CatalogSummaryCache["stamp"]) {
    return
  }
  if (-not $stamp) {
    $script:CatalogSummaryCache["stamp"] = ""
    $script:CatalogSummaryCache["raw"] = ""
    $script:CatalogSummaryCache["served_raw"] = ""
    $script:CatalogSummaryCache["parsed"] = $null
    $script:CatalogSummaryCache["metadata"] = @{
      available = $false
      generated_at = $null
      species_count = 0
    }
    return
  }

  $raw = ""
  try {
    $raw = Get-Content -LiteralPath $script:CatalogSummaryFile -Raw -ErrorAction Stop
  } catch {
    $raw = ""
  }

  $script:CatalogSummaryCache["stamp"] = $stamp
  $script:CatalogSummaryCache["raw"] = $raw
  $script:CatalogSummaryCache["served_raw"] = ""
  $script:CatalogSummaryCache["parsed"] = $null
  $script:CatalogSummaryCache["metadata"] = Get-CatalogMetadataFromRaw -Raw $raw
}

function Get-ServedCatalogSummaryRaw {
  Update-CatalogSummaryCache
  if ([string]::IsNullOrWhiteSpace($script:CatalogSummaryCache["served_raw"])) {
    $script:CatalogSummaryCache["served_raw"] = Normalize-ServedCatalogJsonRaw -Raw $script:CatalogSummaryCache["raw"]
  }
  return $script:CatalogSummaryCache["served_raw"]
}

function Get-CatalogSummaryMetadata {
  Update-CatalogSummaryCache
  return $script:CatalogSummaryCache["metadata"]
}

function Get-CatalogMetadata {
  Update-CatalogCache
  return $script:CatalogCache["metadata"]
}

function Get-CatalogSpeciesEntries {
  $catalog = Read-Catalog
  if ($catalog -is [System.Collections.IDictionary] -and $catalog.ContainsKey("species") -and $null -ne $catalog["species"]) {
    return @($catalog["species"])
  }
  return @()
}

function Convert-CatalogNamedEntryToSummary {
  param([object]$Entry)

  if ($null -eq $Entry) {
    return $null
  }

  if ($Entry -is [string]) {
    return @{
      id = $Entry
      name = $Entry
    }
  }

  $normalized = Convert-ToHashtable $Entry
  if (-not ($normalized -is [System.Collections.IDictionary])) {
    $text = $Entry.ToString().Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
      return $null
    }
    return @{
      id = $text
      name = $text
    }
  }

  $id = Normalize-Identifier $normalized["id"]
  if (-not $id) {
    $id = Normalize-Identifier $normalized["move"]
  }
  if (-not $id) {
    $id = Normalize-Identifier $normalized["item"]
  }
  if (-not $id) {
    $id = Normalize-Identifier $normalized["ability"]
  }
  if (-not $id) {
    $id = Normalize-Identifier $normalized["name"]
  }
  if (-not $id) {
    return $null
  }

  $name = Normalize-DisplayText $normalized["name"]
  if ([string]::IsNullOrWhiteSpace($name)) {
    $name = $id
  }

  return @{
    id = $id
    name = $name
  }
}

function Convert-CatalogEnumListToSummary {
  param([object]$Entries)

  $summary = @()
  foreach ($entry in @($Entries)) {
    $normalized = Convert-CatalogNamedEntryToSummary $entry
    if ($normalized) {
      $summary += ,$normalized
    }
  }
  return $summary
}

function Convert-EvolutionMethodsToSummary {
  param([object]$Entries)

  $summary = @()
  foreach ($entry in @($Entries)) {
    if ($null -eq $entry) { continue }
    $normalized = Convert-ToHashtable $entry
    if ($normalized -is [System.Collections.IDictionary]) {
      $id = Normalize-Identifier $normalized["id"]
      if (-not $id) {
        $id = Normalize-Identifier $normalized["name"]
      }
      if (-not $id) { continue }
      $summary += ,@{
        id = $id
        name = if ($normalized["name"]) { $normalized["name"] } else { $id }
        parameter_kind = $normalized["parameter_kind"]
      }
      continue
    }

    $text = Normalize-Identifier $entry
    if (-not $text) { continue }
    $summary += ,@{
      id = $text
      name = $text
      parameter_kind = $null
    }
  }
  return $summary
}

function Convert-CatalogSpeciesToSummary {
  param([hashtable]$Entry)

  if (-not $Entry) {
    return $null
  }

  $visuals = Convert-ToHashtable $Entry["visuals"]
  if (-not ($visuals -is [System.Collections.IDictionary])) {
    $visuals = @{}
  }

  return @{
    id = $Entry["id"]
    species = $Entry["species"]
    name = $Entry["name"]
    id_number = $Entry["id_number"]
    category = $Entry["category"]
    pokedex_entry = $Entry["pokedex_entry"]
    types = @($Entry["types"])
    bst = $Entry["bst"]
    abilities = @(Convert-CatalogEnumListToSummary $Entry["abilities"])
    hidden_abilities = @(Convert-CatalogEnumListToSummary $Entry["hidden_abilities"])
    kind = $Entry["kind"]
    source = $Entry["source"]
    fusion_rule = $Entry["fusion_rule"]
    fusion_compatible = $Entry["fusion_compatible"]
    regional_variant = $Entry["regional_variant"]
    variant_family = $Entry["variant_family"]
    base_species = $Entry["base_species"]
    fallback_species = $Entry["fallback_species"]
    visuals = @{
      front = $visuals["front"]
      back = $visuals["back"]
      icon = $visuals["icon"]
      shiny_front = $visuals["shiny_front"]
      shiny_back = $visuals["shiny_back"]
      overworld = $visuals["overworld"]
    }
    detail_level = "summary"
  }
}

function Get-CatalogSummaryPayload {
  return Read-CatalogSummary
}

function Get-CatalogSpeciesPayload {
  param([System.Net.HttpListenerRequest]$Request)

  $requestedId = [string]$Request.QueryString["id"]
  if ([string]::IsNullOrWhiteSpace($requestedId)) {
    return @{ ok = $false; error = "Species id is required." }
  }

  $requestedId = $requestedId.Trim().ToUpperInvariant()
  $detailFile = Join-Path $script:CatalogSpeciesRoot ("{0}.json" -f ($requestedId -replace '[^A-Z0-9_.-]', '_'))
  if (-not (Test-Path -LiteralPath $detailFile)) {
    return @{
      ok = $false
      error = "Species not found in catalog."
    }
  }

  try {
    return Convert-ToHashtable (ConvertFrom-Json (Get-Content -LiteralPath $detailFile -Raw -ErrorAction Stop))
  } catch {
    return @{
      ok = $false
      error = "Species detail could not be loaded."
    }
  }
}

function Test-CatalogReady {
  return (Get-CatalogSummaryMetadata)["available"]
}

function Get-CatalogSpeciesIds {
  param([hashtable]$Catalog)
  $ids = @{}
  foreach ($entry in @($Catalog["species"])) {
    if ($entry -and $entry["id"]) {
      $ids[$entry["id"].ToString().ToUpperInvariant()] = $true
    }
  }
  return $ids
}

function Get-FrameworkReservedIds {
  $reserved = @{}
  $speciesDir = Join-Path $script:ModRoot "data\species"
  if (-not (Test-Path -LiteralPath $speciesDir)) {
    return $reserved
  }
  Get-ChildItem -LiteralPath $speciesDir -Filter "*.json" -File | ForEach-Object {
    $payload = Read-JsonFile -Path $_.FullName -Fallback @{ species = @() }
    foreach ($entry in @($payload["species"])) {
      if ($entry["id"]) {
        $reserved[$entry["id"].ToString().ToUpperInvariant()] = $true
      }
    }
  }
  return $reserved
}

function Get-FrameworkUsedSlots {
  $usedSlots = @{}
  $speciesDir = Join-Path $script:ModRoot "data\species"
  if (-not (Test-Path -LiteralPath $speciesDir)) {
    return $usedSlots
  }
  Get-ChildItem -LiteralPath $speciesDir -Filter "*.json" -File | ForEach-Object {
    $payload = Read-JsonFile -Path $_.FullName -Fallback @{ species = @() }
    foreach ($entry in @($payload["species"])) {
      $slot = Normalize-Int $entry["slot"] 0 0
      if ($slot -gt 0) {
        $usedSlots[$slot] = $true
        continue
      }
      $legacyIdNumber = Normalize-Int $entry["id_number"] 0 0
      if ($legacyIdNumber -gt $script:LegacyReservedIdMin) {
        $usedSlots[$legacyIdNumber - $script:LegacyReservedIdMin] = $true
      }
    }
  }
  return $usedSlots
}

function Read-UserSpeciesFile {
  $payload = Read-JsonFile -Path $script:CreatorSpeciesFile -Fallback @{ species = @() }
  if (-not $payload.ContainsKey("species")) {
    $payload["species"] = @()
  }
  return $payload
}

function Write-UserSpeciesFile {
  param([array]$Species)
  $payload = @{ species = $Species }
  Write-JsonFile -Path $script:CreatorSpeciesFile -Data $payload
}

function Read-CreatorStarterFile {
  $payload = Read-JsonFile -Path $script:CreatorStarterFile -Fallback @{ starter_sets = @() }
  if (-not $payload.ContainsKey("starter_sets")) {
    $payload["starter_sets"] = @()
  }
  return $payload
}

function Write-CreatorStarterFile {
  param([array]$StarterSets)
  $payload = @{ starter_sets = $StarterSets }
  Write-JsonFile -Path $script:CreatorStarterFile -Data $payload
}

function Read-FrameworkConfig {
  return Read-JsonFile -Path $script:FrameworkConfigFile -Fallback @{}
}

function Write-FrameworkConfig {
  param([hashtable]$Config)
  Write-JsonFile -Path $script:FrameworkConfigFile -Data $Config
}

function Read-DeliveryQueueFile {
  $payload = Read-JsonFile -Path $script:CreatorDeliveryFile -Fallback @{
    version = "1.0.0"
    updated_at = $null
    deliveries = @()
    history = @()
  }
  if (-not ($payload -is [hashtable])) {
    $payload = @{}
  }
  if (-not $payload.ContainsKey("version")) {
    $payload["version"] = "1.0.0"
  }
  if (-not $payload.ContainsKey("updated_at")) {
    $payload["updated_at"] = $null
  }
  if (-not $payload.ContainsKey("deliveries") -or $null -eq $payload["deliveries"]) {
    $payload["deliveries"] = @()
  }
  if (-not $payload.ContainsKey("history") -or $null -eq $payload["history"]) {
    $payload["history"] = @()
  }
  return $payload
}

function Write-DeliveryQueueFile {
  param([hashtable]$Payload)
  $safePayload = @{
    version = if ($Payload["version"]) { $Payload["version"] } else { "1.0.0" }
    updated_at = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    deliveries = @($Payload["deliveries"])
    history = @($Payload["history"])
  }
  Write-JsonFile -Path $script:CreatorDeliveryFile -Data $safePayload
}

function Find-UserSpeciesEntry {
  param([string]$SpeciesId)
  $normalizedId = Normalize-Token $SpeciesId
  if (-not $normalizedId) {
    return $null
  }
  foreach ($entry in @((Read-UserSpeciesFile)["species"])) {
    if ((Normalize-Token $entry["id"]) -eq $normalizedId) {
      return $entry
    }
  }
  return $null
}

function New-DeliveryId {
  return "CSF_DELIVERY_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 12).ToUpperInvariant()
}

function Move-DeliveryToHistory {
  param(
    [hashtable]$Queue,
    [hashtable]$Entry,
    [string]$Status,
    [string]$Context = "",
    [object]$Extra = $null
  )
  $remaining = @()
  foreach ($delivery in @($Queue["deliveries"])) {
    if (($delivery["delivery_id"] | Out-String).Trim() -ne (($Entry["delivery_id"] | Out-String).Trim())) {
      $remaining += ,$delivery
    }
  }
  $historyEntry = @{}
  foreach ($pair in $Entry.GetEnumerator()) {
    $historyEntry[$pair.Key] = Convert-ToHashtable $pair.Value
  }
  $historyEntry["status"] = $Status
  $historyEntry["processed_at"] = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  if (-not [string]::IsNullOrWhiteSpace($Context)) {
    $historyEntry["processed_context"] = $Context
  }
  if ($null -ne $Extra) {
    $historyEntry["processed_extra"] = Convert-ToHashtable $Extra
  }
  $Queue["deliveries"] = $remaining
  $Queue["history"] = @($historyEntry) + @($Queue["history"])
  if ($Queue["history"].Count -gt $script:DeliveryHistoryLimit) {
    $Queue["history"] = @($Queue["history"][0..($script:DeliveryHistoryLimit - 1)])
  }
}

function Remove-QueuedDeliveriesForSpecies {
  param([string]$SpeciesId)
  $normalizedId = Normalize-Token $SpeciesId
  if (-not $normalizedId) {
    return
  }
  $queue = Read-DeliveryQueueFile
  $changed = $false
  foreach ($delivery in @($queue["deliveries"])) {
    if ((Normalize-Token $delivery["species_id"]) -ne $normalizedId) {
      continue
    }
    Move-DeliveryToHistory -Queue $queue -Entry $delivery -Status "canceled" -Context "species_deleted"
    $changed = $true
  }
  if ($changed) {
    Write-DeliveryQueueFile -Payload $queue
  }
}

function Get-DeliveryQueuePayload {
  $payload = Read-DeliveryQueueFile
  $pending = @($payload["deliveries"] | Where-Object {
    ($_ -is [hashtable]) -and ([string]::IsNullOrWhiteSpace($_["status"]) -or $_["status"] -eq "pending")
  })
  $history = @($payload["history"] | Where-Object { $_ -is [hashtable] })
  return @{
    version = $payload["version"]
    updated_at = $payload["updated_at"]
    pending = $pending
    history = $history
    summary = @{
      pending = $pending.Count
      history = $history.Count
      updated_at = $payload["updated_at"]
    }
    path = $script:CreatorDeliveryFile
  }
}

function Build-DeliveryRecord {
  param(
    [hashtable]$SpeciesEntry,
    [hashtable]$DeliveryPayload
  )
  $defaultsToStarterLevel = Normalize-Bool $SpeciesEntry["starter_eligible"]
  $defaultLevel = if ($defaultsToStarterLevel) { 5 } else { 10 }
  $level = Normalize-Int $DeliveryPayload["level"] $defaultLevel 1
  if ($level -gt 100) { $level = 100 }
  $quantity = Normalize-Int $DeliveryPayload["quantity"] 1 1
  if ($quantity -gt 6) { $quantity = 6 }
  $deliveryLabel = Normalize-DisplayText $DeliveryPayload["label"]
  if ([string]::IsNullOrWhiteSpace($deliveryLabel)) {
    $speciesLabel = Normalize-DisplayText $SpeciesEntry["name"]
    if ([string]::IsNullOrWhiteSpace($speciesLabel)) {
      $speciesLabel = Normalize-DisplayText $SpeciesEntry["id"]
    }
    $deliveryLabel = "{0} Delivery" -f $speciesLabel
  }
  $message = Normalize-DisplayText $DeliveryPayload["message"]
  if ([string]::IsNullOrWhiteSpace($message)) {
    $message = "Queued from the browser studio for pickup at the player's home PC."
  }
  $heldItem = Resolve-CatalogId -Value $DeliveryPayload["held_item"] -CatalogKeys @("items")
  return @{
    delivery_id = New-DeliveryId
    status = "pending"
    created_at = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    updated_at = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    source = "creator_publish"
    species_id = $SpeciesEntry["id"]
    species_name = $SpeciesEntry["name"]
    species_slot = Normalize-Int $SpeciesEntry["slot"] 0 0
    species_kind = $SpeciesEntry["kind"]
    delivery_label = $deliveryLabel
    quantity = $quantity
    sender = "Pokedex Studio"
    message = $message
    notes = Normalize-DisplayText $DeliveryPayload["notes"]
    pokemon = @{
      level = $level
      nickname = Normalize-DisplayText $DeliveryPayload["nickname"]
      shiny = Normalize-Bool $DeliveryPayload["shiny"]
      held_item = $heldItem
    }
  }
}

function Get-NextCreatorSlot {
  param([array]$SpeciesEntries)
  $usedSlots = Get-FrameworkUsedSlots
  $maxSlot = 0
  foreach ($slot in $usedSlots.Keys) {
    $normalizedSlot = Normalize-Int $slot 0 0
    if ($normalizedSlot -gt $maxSlot) { $maxSlot = $normalizedSlot }
  }
  foreach ($entry in $SpeciesEntries) {
    $slot = Normalize-Int $entry["slot"] 0 0
    if ($slot -gt $maxSlot) { $maxSlot = $slot }
  }
  return ($maxSlot + 1)
}

function Get-UniqueInternalId {
  param(
    [string]$RequestedId,
    [string]$DisplayName,
    [array]$SpeciesEntries,
    [string]$ExistingId = $null
  )
  $catalog = Read-Catalog
  $reserved = Get-CatalogSpeciesIds $catalog
  foreach ($pair in (Get-FrameworkReservedIds).GetEnumerator()) {
    $reserved[$pair.Key] = $true
  }
  foreach ($entry in $SpeciesEntries) {
    if ($entry["id"]) {
      $reserved[$entry["id"].ToString().ToUpperInvariant()] = $true
    }
  }
  if ($ExistingId) {
    $reserved.Remove($ExistingId.ToUpperInvariant()) | Out-Null
  }

  $candidate = Normalize-IdWithPrefix -Value $RequestedId -DisplayName $DisplayName
  if (-not $reserved.ContainsKey($candidate)) {
    return $candidate
  }

  $suffix = 2
  while ($reserved.ContainsKey("${candidate}_$suffix")) {
    $suffix += 1
  }
  return "${candidate}_$suffix"
}

function Convert-DataUrlToBytes {
  param([string]$DataUrl)
  if ([string]::IsNullOrWhiteSpace($DataUrl)) { return $null }
  if ($DataUrl -notmatch '^data:(?<mime>[^;]+);base64,(?<payload>.+)$') { return $null }
  $mimeType = $Matches["mime"].ToLowerInvariant()
  if ($mimeType -ne "image/png") {
    throw "Artwork must be saved as PNG. The browser creator should convert imported art automatically before upload."
  }
  return [System.Convert]::FromBase64String($Matches["payload"])
}

function Get-AssetPaths {
  param(
    [string]$InternalId,
    [int]$Slot
  )
  $catalog = Read-Catalog
  $standardMin = $null
  if ($catalog.ContainsKey("framework") -and $catalog["framework"]["standard_species_min"]) {
    $standardMin = Normalize-Int $catalog["framework"]["standard_species_min"] 0 0
  }
  $runtimeId = $null
  if ($standardMin -gt 0 -and $Slot -gt 0) {
    $runtimeId = $standardMin + $Slot - 1
  }

  $paths = @{
    front = @{
      relative = "Graphics/Pokemon/Front/$InternalId"
      mod = Join-Path $script:ModRoot "Graphics\Pokemon\Front\$InternalId.png"
      root = Join-Path $script:GameRoot "Graphics\Pokemon\Front\$InternalId.png"
      runtime = @()
    }
    back = @{
      relative = "Graphics/Pokemon/Back/$InternalId"
      mod = Join-Path $script:ModRoot "Graphics\Pokemon\Back\$InternalId.png"
      root = Join-Path $script:GameRoot "Graphics\Pokemon\Back\$InternalId.png"
      runtime = @()
    }
    icon = @{
      relative = "Graphics/Pokemon/Icons/$InternalId"
      mod = Join-Path $script:ModRoot "Graphics\Pokemon\Icons\$InternalId.png"
      root = Join-Path $script:GameRoot "Graphics\Pokemon\Icons\$InternalId.png"
      runtime = @()
    }
  }

  if ($runtimeId) {
    $paths["front"]["runtime"] = @(
      (Join-Path $script:GameRoot "Graphics\Battlers\$runtimeId\$runtimeId.png"),
      (Join-Path $script:GameRoot "Graphics\CustomBattlers\indexed\$runtimeId\$runtimeId.png"),
      (Join-Path $script:GameRoot "Graphics\EBDX\Battlers\Front\$runtimeId.png")
    )
    $paths["back"]["runtime"] = @(
      (Join-Path $script:GameRoot "Graphics\EBDX\Battlers\Back\$runtimeId.png")
    )
    $paths["icon"]["runtime"] = @(
      (Join-Path $script:GameRoot "Graphics\Icons\icon$runtimeId.png"),
      (Join-Path $script:GameRoot "Graphics\Battlers\$runtimeId\${runtimeId}_i.png"),
      (Join-Path $script:GameRoot "Graphics\CustomBattlers\indexed\$runtimeId\${runtimeId}_i.png")
    )
  }
  return $paths
}

function Write-AssetBytes {
  param(
    [byte[]]$Bytes,
    [string[]]$Destinations
  )
  if ($null -eq $Bytes) { return }
  foreach ($destination in $Destinations) {
    Ensure-Directory (Split-Path -Parent $destination)
    [System.IO.File]::WriteAllBytes($destination, $Bytes)
  }
}

function Remove-AssetFiles {
  param(
    [string]$InternalId,
    [int]$Slot
  )
  $paths = Get-AssetPaths -InternalId $InternalId -Slot $Slot
  foreach ($kind in @("front", "back", "icon")) {
    $allPaths = @($paths[$kind]["mod"], $paths[$kind]["root"]) + @($paths[$kind]["runtime"])
    foreach ($path in $allPaths) {
      if ($path -and (Test-Path -LiteralPath $path)) {
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
      }
    }
  }
}

function Test-AnyAssetPath {
  param([hashtable]$AssetPathSet)
  foreach ($path in @($AssetPathSet["mod"], $AssetPathSet["root"]) + @($AssetPathSet["runtime"])) {
    if ($path -and (Test-Path -LiteralPath $path)) {
      return $true
    }
  }
  return $false
}

function Save-SpeciesAssets {
  param(
    [hashtable]$SpeciesEntry,
    [hashtable]$AssetPayload
  )
  $paths = Get-AssetPaths -InternalId $SpeciesEntry["id"] -Slot (Normalize-Int $SpeciesEntry["slot"] 0 0)

  $frontBytes = Convert-DataUrlToBytes $AssetPayload["front_data_url"]
  $backBytes  = Convert-DataUrlToBytes $AssetPayload["back_data_url"]
  $iconBytes  = Convert-DataUrlToBytes $AssetPayload["icon_data_url"]
  $hasFrontAsset = Test-AnyAssetPath $paths["front"]
  $hasBackAsset = Test-AnyAssetPath $paths["back"]
  $hasIconAsset = Test-AnyAssetPath $paths["icon"]
  $canInheritBaseArt = ($SpeciesEntry["kind"] -eq "regional_variant" -and -not [string]::IsNullOrWhiteSpace([string]$SpeciesEntry["base_species"]))

  if (-not $frontBytes -and -not $hasFrontAsset -and -not $canInheritBaseArt) {
    throw "A front sprite is required for new custom species."
  }

  if (-not $backBytes) {
    if ($hasBackAsset -and (Test-Path -LiteralPath $paths["back"]["mod"])) {
      $backBytes = [System.IO.File]::ReadAllBytes($paths["back"]["mod"])
    } elseif ($frontBytes) {
      $backBytes = $frontBytes
    }
  }

  if (-not $iconBytes) {
    if ($hasIconAsset -and (Test-Path -LiteralPath $paths["icon"]["mod"])) {
      $iconBytes = [System.IO.File]::ReadAllBytes($paths["icon"]["mod"])
    } elseif ($frontBytes) {
      $iconBytes = $frontBytes
    }
  }

  if ($frontBytes) {
    Write-AssetBytes -Bytes $frontBytes -Destinations @($paths["front"]["mod"], $paths["front"]["root"]) + @($paths["front"]["runtime"])
  }
  if ($backBytes) {
    Write-AssetBytes -Bytes $backBytes -Destinations @($paths["back"]["mod"], $paths["back"]["root"]) + @($paths["back"]["runtime"])
  }
  if ($iconBytes) {
    Write-AssetBytes -Bytes $iconBytes -Destinations @($paths["icon"]["mod"], $paths["icon"]["root"]) + @($paths["icon"]["runtime"])
  }

  $SpeciesEntry["assets"] = @{}
  if ($frontBytes -or (Test-AnyAssetPath $paths["front"])) {
    $SpeciesEntry["assets"]["front"] = $paths["front"]["relative"]
  }
  if ($backBytes -or (Test-AnyAssetPath $paths["back"])) {
    $SpeciesEntry["assets"]["back"] = $paths["back"]["relative"]
  }
  if ($iconBytes -or (Test-AnyAssetPath $paths["icon"])) {
    $SpeciesEntry["assets"]["icon"] = $paths["icon"]["relative"]
  }
}

function Normalize-MoveListRows {
  param([object]$Rows)
  $result = @()
  foreach ($row in @($Rows)) {
    if ($null -eq $row) { continue }
    $moveId = Resolve-CatalogId -Value $row["move"] -CatalogKeys @("moves")
    if (-not $moveId) { continue }
    $level = Normalize-Int $row["level"] 1 1
    $result += @{
      level = $level
      move = $moveId
    }
  }
  $result = $result | Sort-Object level, move
  return @($result)
}

function Normalize-MoveIdList {
  param([object]$Rows)
  $result = @()
  foreach ($row in @($Rows)) {
    if ($null -eq $row) { continue }
    if ($row -is [string]) {
      $moveId = Resolve-CatalogId -Value $row -CatalogKeys @("moves")
    } elseif ($row -is [System.Collections.IDictionary]) {
      $moveId = Resolve-CatalogId -Value $row["move"] -CatalogKeys @("moves")
    } elseif ($row.PSObject -and $row.PSObject.Properties["move"]) {
      $moveId = Resolve-CatalogId -Value $row.move -CatalogKeys @("moves")
    } else {
      continue
    }
    if ($moveId) { $result += $moveId }
  }
  return @($result | Select-Object -Unique)
}

function Normalize-EvolutionRows {
  param([object]$Rows)
  $result = @()
  foreach ($row in @($Rows)) {
    if ($null -eq $row) { continue }
    $species = Resolve-CatalogId -Value $row["species"] -CatalogKeys @("species")
    $method = Resolve-CatalogId -Value $row["method"] -CatalogKeys @("evolution_methods")
    if (-not $species -or -not $method) { continue }
    $parameterKind = Get-EvolutionParameterKind -MethodId $method
    $parameterText = Normalize-DisplayText $row["parameter"]
    $parameter = $null
    if (-not [string]::IsNullOrWhiteSpace($parameterKind)) {
      if ([string]::IsNullOrWhiteSpace($parameterText)) {
        throw "Evolution method $method requires a $parameterKind parameter."
      }
      switch ($parameterKind.ToString()) {
        "Integer" {
          if ($parameterText -notmatch '^-?\d+$') {
            throw "Evolution method $method requires a numeric parameter."
          }
          $parameter = [int]$parameterText
        }
        "Move" {
          $parameter = Resolve-CatalogId -Value $parameterText -CatalogKeys @("moves")
          if (-not $parameter) { $parameter = Normalize-Identifier $parameterText }
        }
        "Type" {
          $parameter = Resolve-CatalogId -Value $parameterText -CatalogKeys @("types")
          if (-not $parameter) { $parameter = Normalize-Identifier $parameterText }
        }
        "Species" {
          $parameter = Resolve-CatalogId -Value $parameterText -CatalogKeys @("species")
          if (-not $parameter) { $parameter = Normalize-Identifier $parameterText }
        }
        "Item" {
          $parameter = Resolve-CatalogId -Value $parameterText -CatalogKeys @("items")
          if (-not $parameter) { $parameter = Normalize-Identifier $parameterText }
        }
        default {
          $parameter = Normalize-Identifier $parameterText
        }
      }
    }
    $result += @{
      species = $species
      method = $method
      parameter = $parameter
    }
  }
  return @($result)
}

function Build-SpeciesEntry {
  param(
    [hashtable]$Payload,
    [hashtable]$ExistingEntry,
    [array]$AllSpecies
  )
  $name = Normalize-DisplayText $Payload["name"]
  if ([string]::IsNullOrWhiteSpace($name)) {
    throw "Display name is required."
  }

  $kind = Normalize-Token $Payload["kind"]
  if ($kind -ne "REGIONAL_VARIANT") { $kind = "FAKEMON" }
  $kindValue = if ($kind -eq "REGIONAL_VARIANT") { "regional_variant" } else { "fakemon" }

  $internalId = if ($ExistingEntry) {
    $ExistingEntry["id"].ToString()
  } else {
    Get-UniqueInternalId -RequestedId ($Payload["internal_id"]) -DisplayName $name -SpeciesEntries $AllSpecies
  }
  $slot = if ($ExistingEntry) { Normalize-Int $ExistingEntry["slot"] 0 1 } else { Get-NextCreatorSlot -SpeciesEntries $AllSpecies }

  $type1 = Resolve-CatalogId -Value $Payload["type1"] -CatalogKeys @("types")
  if (-not $type1) { $type1 = "NORMAL" }
  $type2 = Resolve-CatalogId -Value $Payload["type2"] -CatalogKeys @("types")
  if ($type2 -eq $type1) { $type2 = $null }

  $starterEligible = Normalize-Bool $Payload["starter_eligible"]
  $fusionRule = switch ((Normalize-Token $Payload["fusion_rule"])) {
    "STANDARD" { "standard" }
    "RESTRICTED" { "restricted" }
    default { "blocked" }
  }

  $moves = Normalize-MoveListRows $Payload["moves"]
  if ($starterEligible -and -not (@($moves) | Where-Object { (Normalize-Int $_["level"] 99 1) -le 5 })) {
    throw "Starter-eligible species must have at least one move at level 5 or lower."
  }

  $baseSpecies = Resolve-CatalogId -Value $Payload["base_species"] -CatalogKeys @("species")
  if ($kindValue -eq "regional_variant" -and -not $baseSpecies) {
    throw "Regional variants must choose a base species."
  }

  $entry = @{
    id = $internalId
    slot = $slot
    kind = $kindValue
    name = $name
    category = (Normalize-DisplayText $Payload["category"])
    template_source_label = (Normalize-DisplayText $Payload["template_source_label"])
    pokedex_entry = (Normalize-DisplayText $Payload["pokedex_entry"])
    design_notes = (Normalize-DisplayText $Payload["design_notes"])
    type1 = $type1
    type2 = $type2
    base_stats = @{
      HP = Normalize-Int $Payload["hp"] 50 1
      ATTACK = Normalize-Int $Payload["attack"] 50 1
      DEFENSE = Normalize-Int $Payload["defense"] 50 1
      SPECIAL_ATTACK = Normalize-Int $Payload["special_attack"] 50 1
      SPECIAL_DEFENSE = Normalize-Int $Payload["special_defense"] 50 1
      SPEED = Normalize-Int $Payload["speed"] 50 1
    }
    base_exp = Normalize-Int $Payload["base_exp"] 64 1
    growth_rate = (Resolve-CatalogId -Value $Payload["growth_rate"] -CatalogKeys @("growth_rates"))
    gender_ratio = (Resolve-CatalogId -Value $Payload["gender_ratio"] -CatalogKeys @("gender_ratios"))
    catch_rate = Normalize-Int $Payload["catch_rate"] 45 1
    happiness = Normalize-Int $Payload["happiness"] 70 0
    moves = $moves
    tutor_moves = Normalize-MoveIdList $Payload["tutor_moves"]
    egg_moves = Normalize-MoveIdList $Payload["egg_moves"]
    tm_moves = Normalize-MoveIdList $Payload["tm_moves"]
    abilities = @()
    hidden_abilities = @()
    egg_groups = @()
    hatch_steps = Normalize-Int $Payload["hatch_steps"] 5120 1
    evolutions = Normalize-EvolutionRows $Payload["evolutions"]
    height = Normalize-Int $Payload["height"] 6 1
    weight = Normalize-Int $Payload["weight"] 60 1
    color = (Resolve-CatalogId -Value $Payload["color"] -CatalogKeys @("body_colors"))
    shape = (Resolve-CatalogId -Value $Payload["shape"] -CatalogKeys @("body_shapes"))
    habitat = (Resolve-CatalogId -Value $Payload["habitat"] -CatalogKeys @("habitats"))
    generation = Normalize-Int $Payload["generation"] 9 0
    starter_eligible = $starterEligible
    encounter_eligible = Normalize-Bool $Payload["encounter_eligible"]
    trainer_eligible = Normalize-Bool $Payload["trainer_eligible"]
    fusion_rule = $fusionRule
    standard_fusion_compatible = ($fusionRule -eq "standard")
  }

  foreach ($abilityField in @("primary_ability", "secondary_ability")) {
    $abilityId = Resolve-CatalogId -Value $Payload[$abilityField] -CatalogKeys @("abilities")
    if ($abilityId) { $entry["abilities"] += $abilityId }
  }
  $entry["abilities"] = @($entry["abilities"] | Select-Object -Unique)

  $hiddenAbility = Resolve-CatalogId -Value $Payload["hidden_ability"] -CatalogKeys @("abilities")
  if ($hiddenAbility) {
    $entry["hidden_abilities"] = @($hiddenAbility)
  }

  foreach ($eggGroupField in @("egg_group_1", "egg_group_2")) {
    $eggGroupId = Resolve-CatalogId -Value $Payload[$eggGroupField] -CatalogKeys @("egg_groups")
    if ($eggGroupId) { $entry["egg_groups"] += $eggGroupId }
  }
  $entry["egg_groups"] = @($entry["egg_groups"] | Select-Object -Unique)
  if ($entry["egg_groups"].Count -eq 0) {
    $entry["egg_groups"] = @("Field")
  }
  if (-not $entry["growth_rate"]) { $entry["growth_rate"] = "Medium" }
  if (-not $entry["gender_ratio"]) { $entry["gender_ratio"] = "Female50Percent" }
  if (-not $entry["color"]) { $entry["color"] = "Red" }
  if (-not $entry["shape"]) { $entry["shape"] = "Head" }
  if (-not $entry["habitat"]) { $entry["habitat"] = "None" }

  if ($kindValue -eq "regional_variant") {
    $entry["base_species"] = $baseSpecies
    $fallbackSpecies = Resolve-CatalogId -Value $Payload["fallback_species"] -CatalogKeys @("species")
    if (-not $fallbackSpecies) {
      $fallbackSpecies = $baseSpecies
    }
    $entry["fallback_species"] = $fallbackSpecies
    $variantFamily = Normalize-DisplayText $Payload["variant_family"]
    if ($variantFamily) {
      $entry["variant_family"] = $variantFamily
    }
  }

  if ([string]::IsNullOrWhiteSpace($entry["category"])) {
    $entry["category"] = if ($kindValue -eq "regional_variant") { "Regional Variant" } else { "Custom Species" }
  }
  if ([string]::IsNullOrWhiteSpace($entry["pokedex_entry"])) {
    $entry["pokedex_entry"] = "A custom species created with the Custom Species Framework browser tool."
  }
  if ($entry["abilities"].Count -eq 0) {
    throw "At least one ability is required."
  }
  if ($entry["moves"].Count -eq 0) {
    throw "At least one level-up move is required."
  }

  $entry["world_data"] = @{
    encounter_rarity = Normalize-DisplayText $Payload["encounter_rarity"]
    encounter_zones = Normalize-StringList $Payload["encounter_zones"]
    trainer_roles = Normalize-StringList $Payload["trainer_roles"]
    trainer_notes = Normalize-DisplayText $Payload["trainer_notes"]
    encounter_level_min = Normalize-Int $Payload["encounter_level_min"] 0 0
    encounter_level_max = Normalize-Int $Payload["encounter_level_max"] 0 0
  }
  $entry["fusion_meta"] = @{
    head_offset_x = Normalize-Int $Payload["head_offset_x"] 0
    head_offset_y = Normalize-Int $Payload["head_offset_y"] 0
    body_offset_x = Normalize-Int $Payload["body_offset_x"] 0
    body_offset_y = Normalize-Int $Payload["body_offset_y"] 0
    naming_notes = Normalize-DisplayText $Payload["fusion_naming_notes"]
    sprite_hints = Normalize-DisplayText $Payload["fusion_sprite_hints"]
  }
  $entry["export_meta"] = @{
    author = Normalize-DisplayText $Payload["export_author"]
    version = Normalize-DisplayText $Payload["export_version"]
    pack_name = Normalize-DisplayText $Payload["export_pack_name"]
    tags = Normalize-StringList $Payload["export_tags"]
  }
  return $entry
}

function Get-CreatorStarterSet {
  $payload = Read-CreatorStarterFile
  foreach ($starterSet in @($payload["starter_sets"])) {
    if ($starterSet["id"] -eq "creator_custom_trio") {
      return $starterSet
    }
  }
  return $null
}

function Save-CreatorStarterSet {
  param([hashtable]$Payload)
  $species = @()
  foreach ($slotSpecies in @($Payload["species"])) {
    $normalized = Normalize-Identifier $slotSpecies
    if ($normalized) { $species += $normalized }
  }
  if ($species.Count -ne 3) {
    throw "Choose exactly 3 species for the starter trio."
  }
  if ((@($species | Select-Object -Unique)).Count -ne 3) {
    throw "Choose 3 different species for the starter trio."
  }

  $rivalCounterpick = @{}
  $counterSource = Convert-ToHashtable $Payload["rival_counterpick"]
  foreach ($speciesId in $species) {
    $counter = Normalize-Identifier $counterSource[$speciesId]
    if (-not $counter -or $counter -eq $speciesId -or -not ($species -contains $counter)) {
      $counter = $species[([array]::IndexOf($species, $speciesId) + 1) % $species.Count]
    }
    $rivalCounterpick[$speciesId] = $counter
  }

  $starterSet = @{
    id = "creator_custom_trio"
    label = $(if ([string]::IsNullOrWhiteSpace((Normalize-DisplayText $Payload["label"]))) { "My Custom Fakemon Trio" } else { Normalize-DisplayText $Payload["label"] })
    replace_default_starters = $true
    intro_selectable = $true
    intro_default = Normalize-Bool $Payload["activate_as_default"]
    intro_order = 6
    startup_mode = "species_override"
    species = $species
    rival_counterpick = $rivalCounterpick
  }

  Write-CreatorStarterFile -StarterSets @($starterSet)

  $config = Read-FrameworkConfig
  if (Normalize-Bool $Payload["activate_as_default"]) {
    $config["active_starter_set"] = "creator_custom_trio"
    $config["replace_default_starters"] = $true
  } elseif ($config["active_starter_set"] -eq "creator_custom_trio") {
    $config["active_starter_set"] = "framework_default"
  }
  Write-FrameworkConfig -Config $config

  return $starterSet
}

function Remove-SpeciesFromStarterSet {
  param([string]$SpeciesId)
  $payload = Read-CreatorStarterFile
  $starterSets = @()
  foreach ($starterSet in @($payload["starter_sets"])) {
    $species = @()
    foreach ($entry in @($starterSet["species"])) {
      $normalized = Normalize-Identifier $entry
      if ($normalized -and $normalized -ne $SpeciesId) {
        $species += $normalized
      }
    }
    if ($species.Count -eq 3) {
      $starterSet["species"] = $species
      $rivalCounterpick = @{}
      $existingCounterpick = Convert-ToHashtable $starterSet["rival_counterpick"]
      if ($existingCounterpick) {
        foreach ($pair in $existingCounterpick.GetEnumerator()) {
          if ($pair.Key -ne $SpeciesId -and $pair.Value -ne $SpeciesId) {
            $rivalCounterpick[$pair.Key] = $pair.Value
          }
        }
      }
      $starterSet["rival_counterpick"] = $rivalCounterpick
      $starterSets += ,$starterSet
    }
  }
  Write-CreatorStarterFile -StarterSets $starterSets
  if ($starterSets.Count -eq 0) {
    $config = Read-FrameworkConfig
    if ($config["active_starter_set"] -eq "creator_custom_trio") {
      $config["active_starter_set"] = "framework_default"
      Write-FrameworkConfig -Config $config
    }
  }
}

function Read-RequestBodyJson {
  param([System.Net.HttpListenerRequest]$Request)
  $reader = New-Object System.IO.StreamReader($Request.InputStream, $Request.ContentEncoding)
  try {
    $body = $reader.ReadToEnd()
  } finally {
    $reader.Dispose()
  }
  if ([string]::IsNullOrWhiteSpace($body)) { return @{} }
  return Convert-ToHashtable (ConvertFrom-Json $body)
}

function Write-JsonResponse {
  param(
    [System.Net.HttpListenerResponse]$Response,
    [int]$StatusCode,
    [object]$Body
  )
  try {
    $json = $Body | ConvertTo-Json -Depth 100
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $Response.StatusCode = $StatusCode
    $Response.ContentType = "application/json; charset=utf-8"
    $Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
    $Response.Headers["Pragma"] = "no-cache"
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } catch [System.ObjectDisposedException] {
  } catch [System.InvalidOperationException] {
  } catch [System.Net.HttpListenerException] {
  } catch [System.IO.IOException] {
  } catch {
  } finally {
    try { $Response.OutputStream.Close() } catch {}
    try { $Response.Close() } catch {}
  }
}

function Write-StringResponse {
  param(
    [System.Net.HttpListenerResponse]$Response,
    [int]$StatusCode,
    [string]$Content,
    [string]$ContentType
  )
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$Content)
    $Response.StatusCode = $StatusCode
    $Response.ContentType = $ContentType
    $Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
    $Response.Headers["Pragma"] = "no-cache"
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } catch [System.ObjectDisposedException] {
  } catch [System.InvalidOperationException] {
  } catch [System.Net.HttpListenerException] {
  } catch [System.IO.IOException] {
  } catch {
  } finally {
    try { $Response.OutputStream.Close() } catch {}
    try { $Response.Close() } catch {}
  }
}

function Write-FileResponse {
  param(
    [System.Net.HttpListenerResponse]$Response,
    [string]$Path,
    [string]$ContentType
  )
  try {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $Response.StatusCode = 200
    $Response.ContentType = $ContentType
    if ($ContentType -like "text/*" -or $ContentType -like "*javascript*" -or $ContentType -like "application/json*") {
      $Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
      $Response.Headers["Pragma"] = "no-cache"
    }
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } catch [System.ObjectDisposedException] {
  } catch [System.InvalidOperationException] {
  } catch [System.Net.HttpListenerException] {
  } catch [System.IO.IOException] {
  } catch {
  } finally {
    try { $Response.OutputStream.Close() } catch {}
    try { $Response.Close() } catch {}
  }
}

function Get-ContentType {
  param([string]$Path)
  switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
    ".html" { return "text/html; charset=utf-8" }
    ".css"  { return "text/css; charset=utf-8" }
    ".js"   { return "application/javascript; charset=utf-8" }
    ".json" { return "application/json; charset=utf-8" }
    ".png"  { return "image/png" }
    ".jpg"  { return "image/jpeg" }
    ".jpeg" { return "image/jpeg" }
    ".svg"  { return "image/svg+xml" }
    ".zip"  { return "application/zip" }
    default { return "application/octet-stream" }
  }
}

function Get-StatePayload {
  $speciesPayload = Read-UserSpeciesFile
  $starterSet = Get-CreatorStarterSet
  $config = Read-FrameworkConfig
  $catalogInfo = Get-CatalogSummaryMetadata
  $deliveryQueue = Get-DeliveryQueuePayload
  return @{
    species = @($speciesPayload["species"])
    creator_starter_set = $starterSet
    delivery_queue = $deliveryQueue
    framework_config = $config
    catalog = @{
      available = $catalogInfo["available"]
      generated_at = $catalogInfo["generated_at"]
      species_count = $catalogInfo["species_count"]
    }
  }
}

function Get-AssetDataPayload {
  param([System.Net.HttpListenerRequest]$Request)

  $requestedPath = [string]$Request.QueryString["path"]
  if ([string]::IsNullOrWhiteSpace($requestedPath)) {
    return @{ ok = $false; error = "Asset path is required." }
  }

  $cleanPath = $requestedPath.Split("?")[0].Trim()
  $basePath = $null
  $relativePath = $null

  if ($cleanPath.StartsWith("/game/")) {
    $basePath = $script:GameRoot
    $relativePath = $cleanPath.Substring(6)
  } elseif ($cleanPath.StartsWith("/mod/")) {
    $basePath = $script:ModRoot
    $relativePath = $cleanPath.Substring(5)
  } else {
    return @{ ok = $false; error = "Unsupported asset path." }
  }

  $filePath = Get-SafeStaticPath -BasePath $basePath -RequestedPath $relativePath
  if (-not $filePath) {
    return @{ ok = $false; error = "Asset file not found." }
  }

  $contentType = Get-ContentType $filePath
  $bytes = [System.IO.File]::ReadAllBytes($filePath)
  return @{
    ok = $true
    path = $cleanPath
    content_type = $contentType
    data_url = "data:{0};base64,{1}" -f $contentType, [System.Convert]::ToBase64String($bytes)
  }
}

function Convert-ToPublicAssetPath {
  param([string]$AbsolutePath)
  if ([string]::IsNullOrWhiteSpace($AbsolutePath)) {
    return $null
  }
  $fullPath = [System.IO.Path]::GetFullPath($AbsolutePath)
  if ($fullPath.StartsWith($script:GameRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    $relative = $fullPath.Substring($script:GameRoot.Length).TrimStart('\', '/')
    return "/game/" + $relative.Replace('\', '/')
  }
  if ($fullPath.StartsWith($script:ModRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    $relative = $fullPath.Substring($script:ModRoot.Length).TrimStart('\', '/')
    return "/mod/" + $relative.Replace('\', '/')
  }
  return $null
}

function Convert-VariantPublicPathToAbsolutePath {
  param([string]$PublicPath)
  if ([string]::IsNullOrWhiteSpace($PublicPath)) {
    return $null
  }
  if ($PublicPath.StartsWith("/game/")) {
    return Join-Path $script:GameRoot ($PublicPath.Substring(6).Replace('/', '\'))
  }
  if ($PublicPath.StartsWith("/mod/")) {
    return Join-Path $script:ModRoot ($PublicPath.Substring(5).Replace('/', '\'))
  }
  return $null
}

function Get-VariantLabelFromName {
  param(
    [string]$FileName,
    [string]$BaseToken,
    [string]$DefaultLabel,
    [string]$VariantPrefix = "Alt"
  )
  $nameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
  if ([string]::IsNullOrWhiteSpace($nameWithoutExtension)) {
    return $DefaultLabel
  }
  if ($nameWithoutExtension.Equals($BaseToken, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $DefaultLabel
  }
  $suffix = $nameWithoutExtension.Substring([Math]::Min($BaseToken.Length, $nameWithoutExtension.Length)).Trim('_', '-', '.')
  if ([string]::IsNullOrWhiteSpace($suffix)) {
    return $DefaultLabel
  }
  return "$VariantPrefix $suffix"
}

function Add-VisualVariantEntry {
  param(
    [System.Collections.ArrayList]$List,
    [hashtable]$Seen,
    [string]$AbsolutePath,
    [string]$Label,
    [string]$Source
  )
  if ([string]::IsNullOrWhiteSpace($AbsolutePath) -or -not (Test-Path -LiteralPath $AbsolutePath)) {
    return
  }
  $publicPath = Convert-ToPublicAssetPath $AbsolutePath
  if ([string]::IsNullOrWhiteSpace($publicPath) -or $Seen.ContainsKey($publicPath)) {
    return
  }
  $Seen[$publicPath] = $true
  [void]$List.Add(@{
    path = $publicPath
    label = $Label
    source = $Source
    file_name = [System.IO.Path]::GetFileName($AbsolutePath)
  })
}

function Add-MatchingVisualVariants {
  param(
    [System.Collections.ArrayList]$List,
    [hashtable]$Seen,
    [string]$Directory,
    [string]$Filter,
    [string]$MatchPattern,
    [string]$BaseToken,
    [string]$DefaultLabel,
    [string]$Source,
    [string]$VariantPrefix = "Alt"
  )
  if ([string]::IsNullOrWhiteSpace($Directory) -or -not (Test-Path -LiteralPath $Directory)) {
    return
  }
  Get-ChildItem -LiteralPath $Directory -Filter $Filter -File -ErrorAction SilentlyContinue |
    Sort-Object Name |
    ForEach-Object {
      if (-not [string]::IsNullOrWhiteSpace($MatchPattern) -and $_.Name -notmatch $MatchPattern) {
        return
      }
      $label = Get-VariantLabelFromName -FileName $_.Name -BaseToken $BaseToken -DefaultLabel $DefaultLabel -VariantPrefix $VariantPrefix
      Add-VisualVariantEntry -List $List -Seen $Seen -AbsolutePath $_.FullName -Label $label -Source $Source
    }
}

function Get-VisualVariantsPayload {
  param([System.Net.HttpListenerRequest]$Request)

  $entryId = Normalize-Token $Request.QueryString["id"]
  $idNumber = Normalize-Int $Request.QueryString["id_number"] 0 0
  if ([string]::IsNullOrWhiteSpace($entryId) -and $idNumber -le 0) {
    return @{ ok = $false; error = "Choose a species or fusion entry first." }
  }

  $front = New-Object System.Collections.ArrayList
  $back = New-Object System.Collections.ArrayList
  $icon = New-Object System.Collections.ArrayList
  $seen = @{
    front = @{}
    back = @{}
    icon = @{}
  }

  if (-not [string]::IsNullOrWhiteSpace($entryId)) {
    Add-MatchingVisualVariants -List $front -Seen $seen["front"] -Directory (Join-Path $script:ModRoot "Graphics\Pokemon\Front") -Filter "$entryId*.png" -MatchPattern ("^{0}(?:[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape($entryId)) -BaseToken $entryId -DefaultLabel "Framework Front" -Source "Framework" -VariantPrefix "Framework"
    Add-MatchingVisualVariants -List $front -Seen $seen["front"] -Directory (Join-Path $script:GameRoot "Graphics\Pokemon\Front") -Filter "$entryId*.png" -MatchPattern ("^{0}(?:[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape($entryId)) -BaseToken $entryId -DefaultLabel "Installed Front" -Source "Installed" -VariantPrefix "Alt"
    Add-MatchingVisualVariants -List $back -Seen $seen["back"] -Directory (Join-Path $script:ModRoot "Graphics\Pokemon\Back") -Filter "$entryId*.png" -MatchPattern ("^{0}(?:[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape($entryId)) -BaseToken $entryId -DefaultLabel "Framework Back" -Source "Framework" -VariantPrefix "Framework"
    Add-MatchingVisualVariants -List $back -Seen $seen["back"] -Directory (Join-Path $script:GameRoot "Graphics\Pokemon\Back") -Filter "$entryId*.png" -MatchPattern ("^{0}(?:[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape($entryId)) -BaseToken $entryId -DefaultLabel "Installed Back" -Source "Installed" -VariantPrefix "Alt"
    Add-MatchingVisualVariants -List $icon -Seen $seen["icon"] -Directory (Join-Path $script:ModRoot "Graphics\Pokemon\Icons") -Filter "$entryId*.png" -MatchPattern ("^{0}(?:[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape($entryId)) -BaseToken $entryId -DefaultLabel "Framework Icon" -Source "Framework" -VariantPrefix "Framework"
    Add-MatchingVisualVariants -List $icon -Seen $seen["icon"] -Directory (Join-Path $script:GameRoot "Graphics\Pokemon\Icons") -Filter "$entryId*.png" -MatchPattern ("^{0}(?:[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape($entryId)) -BaseToken $entryId -DefaultLabel "Installed Icon" -Source "Installed" -VariantPrefix "Alt"
  }

  if ($entryId -match '^B(?<body>\d+)H(?<head>\d+)$') {
    $bodyDex = [int]$Matches["body"]
    $headDex = [int]$Matches["head"]
    $fusionToken = "$headDex.$bodyDex"
    $fusionPattern = ("^{0}(?:[A-Za-z]+|[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape($fusionToken))
    Add-MatchingVisualVariants -List $front -Seen $seen["front"] -Directory (Join-Path $script:GameRoot "Graphics\CustomBattlers\indexed\$headDex") -Filter "$fusionToken*.png" -MatchPattern $fusionPattern -BaseToken $fusionToken -DefaultLabel "Custom Fusion" -Source "Custom Battler" -VariantPrefix "Custom"
    Add-MatchingVisualVariants -List $front -Seen $seen["front"] -Directory (Join-Path $script:GameRoot "Graphics\Battlers\$headDex") -Filter "$fusionToken*.png" -MatchPattern $fusionPattern -BaseToken $fusionToken -DefaultLabel "Default Fusion" -Source "Battler" -VariantPrefix "Alt"
    if ($idNumber -gt 0) {
      Add-MatchingVisualVariants -List $icon -Seen $seen["icon"] -Directory (Join-Path $script:GameRoot "Graphics\Pokemon\FusionIcons") -Filter "icon$idNumber*.png" -MatchPattern ("^icon{0}(?:[A-Za-z]+|[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape([string]$idNumber)) -BaseToken "icon$idNumber" -DefaultLabel "Fusion Icon" -Source "Fusion Icon" -VariantPrefix "Alt"
      Add-MatchingVisualVariants -List $icon -Seen $seen["icon"] -Directory (Join-Path $script:GameRoot "Graphics\Icons") -Filter "icon$idNumber*.png" -MatchPattern ("^icon{0}(?:[A-Za-z]+|[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape([string]$idNumber)) -BaseToken "icon$idNumber" -DefaultLabel "Battle Icon" -Source "Icon Sheet" -VariantPrefix "Alt"
    }
  } else {
    if ($idNumber -gt 0) {
      Add-MatchingVisualVariants -List $front -Seen $seen["front"] -Directory (Join-Path $script:GameRoot "Graphics\BaseSprites") -Filter "$idNumber*.png" -MatchPattern ("^{0}(?:[A-Za-z]+)?\.png$" -f [regex]::Escape([string]$idNumber)) -BaseToken ([string]$idNumber) -DefaultLabel "Default Base Sprite" -Source "BaseSprites" -VariantPrefix "Alt"
      Add-MatchingVisualVariants -List $front -Seen $seen["front"] -Directory (Join-Path $script:GameRoot "Graphics\EBDX\Battlers\Front") -Filter "$idNumber*.png" -MatchPattern ("^{0}(?:[A-Za-z]+|[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape([string]$idNumber)) -BaseToken ([string]$idNumber) -DefaultLabel "EBDX Front" -Source "EBDX" -VariantPrefix "Alt"
      Add-MatchingVisualVariants -List $back -Seen $seen["back"] -Directory (Join-Path $script:GameRoot "Graphics\EBDX\Battlers\Back") -Filter "$idNumber*.png" -MatchPattern ("^{0}(?:[A-Za-z]+|[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape([string]$idNumber)) -BaseToken ([string]$idNumber) -DefaultLabel "EBDX Back" -Source "EBDX" -VariantPrefix "Alt"
      Add-MatchingVisualVariants -List $icon -Seen $seen["icon"] -Directory (Join-Path $script:GameRoot "Graphics\Icons") -Filter "icon$idNumber*.png" -MatchPattern ("^icon{0}(?:[A-Za-z]+|[_-][A-Za-z0-9]+)*\.png$" -f [regex]::Escape([string]$idNumber)) -BaseToken "icon$idNumber" -DefaultLabel "Battle Icon" -Source "Icon Sheet" -VariantPrefix "Alt"
    }
  }

  if ($back.Count -eq 0 -and $front.Count -gt 0) {
    foreach ($entry in @($front)) {
      Add-VisualVariantEntry -List $back -Seen $seen["back"] -AbsolutePath (Convert-VariantPublicPathToAbsolutePath ([string]$entry["path"])) -Label (([string]$entry["label"]) + " (Front Reuse)") -Source ([string]$entry["source"])
    }
  }
  if ($icon.Count -eq 0 -and $front.Count -gt 0) {
    foreach ($entry in @($front)) {
      Add-VisualVariantEntry -List $icon -Seen $seen["icon"] -AbsolutePath (Convert-VariantPublicPathToAbsolutePath ([string]$entry["path"])) -Label (([string]$entry["label"]) + " (Front Reuse)") -Source ([string]$entry["source"])
    }
  }

  return @{
    ok = $true
    entry = @{
      id = $entryId
      id_number = $idNumber
      kind = $(if ($entryId -match '^B\d+H\d+$') { "fusion" } else { "species" })
    }
    variants = @{
      front = @($front)
      back = @($back)
      icon = @($icon)
    }
  }
}

function Get-ImporterLogTail {
  param([int]$MaxLines = 80)
  $logPath = Join-Path $script:ImporterOutputRoot "import.log"
  if (-not (Test-Path -LiteralPath $logPath)) {
    return @()
  }
  try {
    $lines = @(Get-Content -LiteralPath $logPath)
    if ($lines.Count -le $MaxLines) {
      return $lines
    }
    return @($lines[($lines.Count - $MaxLines)..($lines.Count - 1)])
  } catch {
    return @()
  }
}

function Get-ImporterStatePayload {
  Ensure-ImporterWorkspaceAvailable
  $defaultManifestText = "{`n  `"sources`": []`n}`n"
  $manifestText = Read-TextFile -Path $script:ImporterManifestFile -Fallback $defaultManifestText
  $exampleManifestText = Read-TextFile -Path $script:ImporterManifestExampleFile -Fallback $manifestText
  $config = Read-JsonFile -Path $script:ImporterConfigFile -Fallback @{}
  $mapping = Read-JsonFile -Path $script:ImporterMappingFile -Fallback @{}
  $report = Read-JsonFile -Path (Join-Path $script:ImporterOutputRoot "import_report.json") -Fallback @{}
  $reviewPayload = Read-JsonFile -Path (Join-Path $script:ImporterOutputRoot "review_queue.json") -Fallback @{ review = @() }
  $rejectedPayload = Read-JsonFile -Path (Join-Path $script:ImporterOutputRoot "rejected_items.json") -Fallback @{ rejected = @() }
  $creditsPayload = Read-JsonFile -Path (Join-Path $script:ImporterOutputRoot "credits_manifest.json") -Fallback @{ credits = @() }
  $speciesManifestPayload = Read-JsonFile -Path (Join-Path $script:ImporterOutputRoot "species\species_manifest.json") -Fallback @{ species = @() }
  $speciesDataPayload = Read-JsonFile -Path (Join-Path $script:ImporterOutputRoot "species\species_data.json") -Fallback @{ species = @() }
  $rollbackPayload = Read-JsonFile -Path (Join-Path $script:ImporterOutputRoot "rollback_manifest.json") -Fallback @{}
  $statePayload = Read-JsonFile -Path $script:ImporterStateFile -Fallback @{}

  $reviewItems = @($reviewPayload["review"])
  $rejectedItems = @($rejectedPayload["rejected"])
  $creditsItems = @($creditsPayload["credits"])
  $speciesManifest = @($speciesManifestPayload["species"])
  $speciesData = @($speciesDataPayload["species"])
  $bundleDirectory = "framework_bundle"
  if ($mapping -is [hashtable] -and $mapping.ContainsKey("bundle") -and ($mapping["bundle"] -is [hashtable]) -and $mapping["bundle"]["directory"]) {
    $bundleDirectory = $mapping["bundle"]["directory"].ToString()
  }

  $totals = if ($report -is [hashtable] -and $report.ContainsKey("totals")) {
    Convert-ToHashtable $report["totals"]
  } else {
    @{}
  }

  return @{
    manifest_text = $manifestText
    example_manifest_text = $exampleManifestText
    config = $config
    mapping = $mapping
    report = $report
    review_queue = $reviewItems
    rejected_items = $rejectedItems
    credits_manifest = $creditsItems
    species_manifest = $speciesManifest
    species_data = $speciesData
    rollback_manifest = $rollbackPayload
    state_file = $statePayload
    log_tail = @(Get-ImporterLogTail)
    output_ready = (Test-Path -LiteralPath (Join-Path $script:ImporterOutputRoot "import_report.json"))
    paths = @{
      manifest = $script:ImporterManifestFile
      config = $script:ImporterConfigFile
      mapping = $script:ImporterMappingFile
      output_root = $script:ImporterOutputRoot
      bundle_root = (Join-Path $script:ImporterOutputRoot $bundleDirectory)
    }
    summary = @{
      generated_at = if ($report["generated_at"]) { $report["generated_at"] } else { $null }
      discovered = if ($totals["discovered"]) { [int]$totals["discovered"] } else { $speciesData.Count }
      ready = if ($totals["ready"]) { [int]$totals["ready"] } else { $speciesManifest.Count }
      review = if ($totals["review"]) { [int]$totals["review"] } else { $reviewItems.Count }
      rejected = if ($totals["rejected"]) { [int]$totals["rejected"] } else { $rejectedItems.Count }
      dry_run_only = Normalize-Bool $report["dry_run_only"]
      apply_bundle = Normalize-Bool $report["apply_bundle"]
    }
  }
}

function Save-ImporterWorkspace {
  param([hashtable]$Body)

  Ensure-ImporterWorkspaceAvailable
  $manifestText = if ($Body.ContainsKey("manifest_text")) { [string]$Body["manifest_text"] } else { $null }
  if ($null -ne $manifestText) {
    try {
      $manifestObject = Convert-ToHashtable (ConvertFrom-Json $manifestText)
    } catch {
      throw "Importer source manifest JSON is invalid: $($_.Exception.Message)"
    }
    if (-not ($manifestObject -is [hashtable])) {
      throw "Importer source manifest must be a JSON object."
    }
    if (-not $manifestObject.ContainsKey("sources")) {
      $manifestObject["sources"] = @()
    }
    Write-JsonFile -Path $script:ImporterManifestFile -Data $manifestObject
  }

  if ($Body.ContainsKey("config")) {
    $configObject = Convert-ToHashtable $Body["config"]
    if (-not ($configObject -is [hashtable])) {
      throw "Importer config must be a JSON object."
    }
    Write-JsonFile -Path $script:ImporterConfigFile -Data $configObject
  }

  return @{
    ok = $true
    importer = Get-ImporterStatePayload
  }
}

function Invoke-ImporterPipeline {
  param(
    [bool]$ApplyBundle = $false
  )

  Ensure-ImporterWorkspaceAvailable
  if (-not (Test-Path -LiteralPath $script:ImporterScript)) {
    throw "Importer script not found at $script:ImporterScript."
  }

  Ensure-Directory $script:ImporterOutputRoot
  $argumentList = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $script:ImporterScript,
    "-ManifestPath", $script:ImporterManifestFile,
    "-ConfigPath", $script:ImporterConfigFile,
    "-MappingPath", $script:ImporterMappingFile,
    "-OutputRoot", $script:ImporterOutputRoot
  )
  if ($ApplyBundle) {
    $argumentList += "-ApplyBundle"
  }

  $outputLines = @()
  $hadFailure = $false
  try {
    & powershell @argumentList 2>&1 | ForEach-Object {
      $outputLines += $_.ToString()
    }
    if ($LASTEXITCODE -ne 0) {
      $hadFailure = $true
    }
  } catch {
    $hadFailure = $true
    $outputLines += $_.Exception.Message
  }

  if ($hadFailure) {
    $tail = @($outputLines | Select-Object -Last 12)
    $message = if ($tail.Count -gt 0) {
      "Importer run failed. " + ($tail -join " | ")
    } else {
      "Importer run failed."
    }
    throw $message
  }

  return @{
    ok = $true
    run_output = $outputLines
    importer = Get-ImporterStatePayload
  }
}

function Save-SpeciesRequest {
  param([hashtable]$Body)
  $speciesPayload = Read-UserSpeciesFile
  $speciesEntries = @($speciesPayload["species"])
  $requestedExistingId = Normalize-Token $Body["existing_id"]
  $existingEntry = $null
  $existingIndex = -1

  for ($index = 0; $index -lt $speciesEntries.Count; $index++) {
    if ((Normalize-Token $speciesEntries[$index]["id"]) -eq $requestedExistingId) {
      $existingIndex = $index
      $existingEntry = $speciesEntries[$index]
      break
    }
  }

  $entry = Build-SpeciesEntry -Payload $Body["species"] -ExistingEntry $existingEntry -AllSpecies $speciesEntries
  Save-SpeciesAssets -SpeciesEntry $entry -AssetPayload (Convert-ToHashtable $Body["assets"])

  if ($existingEntry -and $existingEntry["id"] -ne $entry["id"]) {
    Remove-AssetFiles -InternalId $existingEntry["id"] -Slot (Normalize-Int $existingEntry["slot"] 0 0)
  }

  if ($existingIndex -ge 0) {
    $speciesEntries[$existingIndex] = $entry
  } else {
    $speciesEntries += ,$entry
  }

  $speciesEntries = @($speciesEntries | Sort-Object { Normalize-Int $_["slot"] 0 0 }, { $_["name"] })
  Write-UserSpeciesFile -Species $speciesEntries

  return @{
    ok = $true
    species = $entry
    all_species = $speciesEntries
  }
}

function Delete-SpeciesRequest {
  param([hashtable]$Body)
  $speciesId = Normalize-Token $Body["id"]
  if (-not $speciesId) {
    throw "Species ID is required."
  }

  $speciesPayload = Read-UserSpeciesFile
  $remaining = @()
  $deletedEntry = $null
  foreach ($entry in @($speciesPayload["species"])) {
    if ((Normalize-Token $entry["id"]) -eq $speciesId) {
      $deletedEntry = $entry
      continue
    }
    $remaining += ,$entry
  }

  if (-not $deletedEntry) {
    throw "Could not find species $speciesId."
  }

  Remove-QueuedDeliveriesForSpecies -SpeciesId $speciesId
  Remove-AssetFiles -InternalId $deletedEntry["id"] -Slot (Normalize-Int $deletedEntry["slot"] 0 0)
  Remove-SpeciesFromStarterSet -SpeciesId $speciesId
  Write-UserSpeciesFile -Species @($remaining)

  return @{
    ok = $true
    deleted_id = $speciesId
    all_species = @($remaining)
  }
}

function Publish-SpeciesToHomePcRequest {
  param([hashtable]$Body)
  $saveResult = Save-SpeciesRequest -Body $Body
  $speciesEntry = $saveResult["species"]
  if (-not $speciesEntry) {
    throw "The species could not be saved before publishing."
  }

  $deliveryPayload = Convert-ToHashtable $Body["delivery"]
  if (-not ($deliveryPayload -is [hashtable])) {
    $deliveryPayload = @{}
  }

  $queue = Read-DeliveryQueueFile
  $record = Build-DeliveryRecord -SpeciesEntry $speciesEntry -DeliveryPayload $deliveryPayload
  $queue["deliveries"] = @($queue["deliveries"]) + @($record)
  Write-DeliveryQueueFile -Payload $queue

  return @{
    ok = $true
    species = $speciesEntry
    all_species = @($saveResult["all_species"])
    delivery = $record
    delivery_queue = Get-DeliveryQueuePayload
  }
}

function Cancel-DeliveryRequest {
  param([hashtable]$Body)
  $deliveryId = Normalize-DisplayText $Body["delivery_id"]
  if ([string]::IsNullOrWhiteSpace($deliveryId)) {
    throw "Delivery ID is required."
  }

  $queue = Read-DeliveryQueueFile
  $entry = $null
  foreach ($delivery in @($queue["deliveries"])) {
    if (($delivery["delivery_id"] | Out-String).Trim() -eq $deliveryId) {
      $entry = $delivery
      break
    }
  }
  if (-not $entry) {
    throw "Could not find queued delivery $deliveryId."
  }

  Move-DeliveryToHistory -Queue $queue -Entry $entry -Status "canceled" -Context "creator_cancel"
  Write-DeliveryQueueFile -Payload $queue
  return @{
    ok = $true
    canceled_delivery_id = $deliveryId
    delivery_queue = Get-DeliveryQueuePayload
  }
}

function Export-SpeciesBundle {
  param([hashtable]$Body)
  $speciesId = Normalize-Token $Body["id"]
  if (-not $speciesId) {
    throw "Choose a saved species to export."
  }

  $speciesEntry = $null
  foreach ($entry in @((Read-UserSpeciesFile)["species"])) {
    if ((Normalize-Token $entry["id"]) -eq $speciesId) {
      $speciesEntry = $entry
      break
    }
  }
  if (-not $speciesEntry) {
    throw "Could not find creator species $speciesId."
  }

  Ensure-Directory $script:ExportRoot
  $safeId = $speciesEntry["id"].ToString().ToLowerInvariant()
  $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("csf_export_" + [System.Guid]::NewGuid().ToString("N"))
  $packRoot = Join-Path $tempRoot ("custom_species_framework_pack_" + $safeId)
  $speciesJsonPath = Join-Path $packRoot ("data\species\" + $safeId + ".json")
  $manifestPath = Join-Path $packRoot "manifest.json"
  $zipPath = Join-Path $script:ExportRoot ($safeId + ".zip")
  $copiedFiles = @()

  try {
    Ensure-Directory $packRoot
    Write-JsonFile -Path $speciesJsonPath -Data @{ species = @($speciesEntry) }
    $copiedFiles += "data/species/$safeId.json"

    $assetPaths = Get-AssetPaths -InternalId $speciesEntry["id"] -Slot (Normalize-Int $speciesEntry["slot"] 0 0)
    foreach ($kind in @("front", "back", "icon")) {
      $sourcePath = $assetPaths[$kind]["mod"]
      if ($sourcePath -and (Test-Path -LiteralPath $sourcePath)) {
        $relative = ($assetPaths[$kind]["relative"].ToString().TrimStart('\', '/').Replace('/', '\')) + ".png"
        $destination = Join-Path $packRoot $relative
        Ensure-Directory (Split-Path -Parent $destination)
        Copy-Item -LiteralPath $sourcePath -Destination $destination -Force
        $copiedFiles += $relative.Replace('\', '/')
      }
    }

    Write-JsonFile -Path $manifestPath -Data @{
      exported_at = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
      species_id = $speciesEntry["id"]
      species_name = $speciesEntry["name"]
      files = $copiedFiles
    }
    $copiedFiles += "manifest.json"

    if (Test-Path -LiteralPath $zipPath) {
      Remove-Item -LiteralPath $zipPath -Force
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($packRoot, $zipPath)

    return @{
      ok = $true
      species_id = $speciesEntry["id"]
      species_name = $speciesEntry["name"]
      files = $copiedFiles
      download_path = "/exports/" + [System.IO.Path]::GetFileName($zipPath)
    }
  } finally {
    if (Test-Path -LiteralPath $tempRoot) {
      Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}

function Handle-ApiRequest {
  param([System.Net.HttpListenerContext]$Context)
  $path = $Context.Request.Url.AbsolutePath
  switch ($path) {
    "/api/health" {
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body @{ ok = $true }
      return
    }
    "/api/catalog" {
      if (-not (Test-CatalogReady)) {
        Write-JsonResponse -Response $Context.Response -StatusCode 404 -Body @{
          ok = $false
          error = "Creator catalog is missing or empty. Restart the creator so it can rebuild the local catalog views."
        }
        return
      }
      Write-StringResponse -Response $Context.Response -StatusCode 200 -Content (Get-ServedCatalogRaw) -ContentType "application/json; charset=utf-8"
      return
    }
    "/api/catalog-summary" {
      if (-not (Test-CatalogReady)) {
        Write-JsonResponse -Response $Context.Response -StatusCode 404 -Body @{
          ok = $false
          error = "Creator catalog summary is missing or empty. Restart the creator so it can rebuild the local catalog views."
        }
        return
      }
      Write-StringResponse -Response $Context.Response -StatusCode 200 -Content (Get-ServedCatalogSummaryRaw) -ContentType "application/json; charset=utf-8"
      return
    }
    "/api/catalog-species" {
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body (Get-CatalogSpeciesPayload -Request $Context.Request)
      return
    }
    "/api/state" {
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body (Get-StatePayload)
      return
    }
    "/api/delivery/state" {
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body @{
        ok = $true
        delivery_queue = Get-DeliveryQueuePayload
      }
      return
    }
    "/api/asset-data" {
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body (Get-AssetDataPayload -Request $Context.Request)
      return
    }
    "/api/visual-variants" {
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body (Get-VisualVariantsPayload -Request $Context.Request)
      return
    }
    "/api/delivery/publish" {
      $body = Read-RequestBodyJson $Context.Request
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body (Publish-SpeciesToHomePcRequest -Body $body)
      return
    }
    "/api/delivery/cancel" {
      $body = Read-RequestBodyJson $Context.Request
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body (Cancel-DeliveryRequest -Body $body)
      return
    }
    "/api/importer/state" {
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body @{
        ok = $true
        importer = Get-ImporterStatePayload
      }
      return
    }
    "/api/importer/save" {
      $body = Read-RequestBodyJson $Context.Request
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body (Save-ImporterWorkspace -Body $body)
      return
    }
    "/api/importer/run" {
      $body = Read-RequestBodyJson $Context.Request
      if ($body.ContainsKey("manifest_text") -or $body.ContainsKey("config")) {
        Save-ImporterWorkspace -Body $body | Out-Null
      }
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body (Invoke-ImporterPipeline -ApplyBundle (Normalize-Bool $body["apply_bundle"]))
      return
    }
    "/api/species/save" {
      $body = Read-RequestBodyJson $Context.Request
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body (Save-SpeciesRequest -Body $body)
      return
    }
    "/api/species/delete" {
      $body = Read-RequestBodyJson $Context.Request
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body (Delete-SpeciesRequest -Body $body)
      return
    }
    "/api/starter-trio/save" {
      $body = Read-RequestBodyJson $Context.Request
      $starterSet = Save-CreatorStarterSet -Payload $body
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body @{
        ok = $true
        starter_set = $starterSet
      }
      return
    }
    "/api/export/species" {
      $body = Read-RequestBodyJson $Context.Request
      Write-JsonResponse -Response $Context.Response -StatusCode 200 -Body (Export-SpeciesBundle -Body $body)
      return
    }
    default {
      Write-JsonResponse -Response $Context.Response -StatusCode 404 -Body @{ ok = $false; error = "Unknown API route." }
      return
    }
  }
}

function Get-SafeStaticPath {
  param(
    [string]$BasePath,
    [string]$RequestedPath
  )
  $normalizedRequest = $RequestedPath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
  $candidate = [System.IO.Path]::GetFullPath((Join-Path $BasePath $normalizedRequest))
  $fullBase = [System.IO.Path]::GetFullPath($BasePath)
  if (-not $candidate.StartsWith($fullBase, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $null
  }
  if (-not (Test-Path -LiteralPath $candidate)) {
    return $null
  }
  return $candidate
}

function Handle-StaticRequest {
  param([System.Net.HttpListenerContext]$Context)
  $path = $Context.Request.Url.AbsolutePath

  if ($path.StartsWith("/mod/")) {
    $filePath = Get-SafeStaticPath -BasePath $script:ModRoot -RequestedPath ($path.Substring(5))
    if (-not $filePath) {
      Write-JsonResponse -Response $Context.Response -StatusCode 404 -Body @{ ok = $false; error = "File not found." }
      return
    }
    Write-FileResponse -Response $Context.Response -Path $filePath -ContentType (Get-ContentType $filePath)
    return
  }

  if ($path.StartsWith("/game/")) {
    $filePath = Get-SafeStaticPath -BasePath $script:GameRoot -RequestedPath ($path.Substring(6))
    if (-not $filePath) {
      Write-JsonResponse -Response $Context.Response -StatusCode 404 -Body @{ ok = $false; error = "File not found." }
      return
    }
    Write-FileResponse -Response $Context.Response -Path $filePath -ContentType (Get-ContentType $filePath)
    return
  }

  if ($path.StartsWith("/exports/")) {
    $filePath = Get-SafeStaticPath -BasePath $script:ExportRoot -RequestedPath ($path.Substring(9))
    if (-not $filePath) {
      Write-JsonResponse -Response $Context.Response -StatusCode 404 -Body @{ ok = $false; error = "File not found." }
      return
    }
    Write-FileResponse -Response $Context.Response -Path $filePath -ContentType (Get-ContentType $filePath)
    return
  }

  $relativePath = if ($path -eq "/") { "index.html" } else { $path.TrimStart('/') }
  $filePath = Get-SafeStaticPath -BasePath $script:WebRoot -RequestedPath $relativePath
  if (-not $filePath) {
    Write-JsonResponse -Response $Context.Response -StatusCode 404 -Body @{ ok = $false; error = "Page not found." }
    return
  }
  Write-FileResponse -Response $Context.Response -Path $filePath -ContentType (Get-ContentType $filePath)
}

function Find-FreePort {
  param([int]$PreferredPort = 39077)
  $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $PreferredPort)
  try {
    $listener.Start()
    return $PreferredPort
  } catch {
    $fallback = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 0)
    $fallback.Start()
    $port = $fallback.LocalEndpoint.Port
    $fallback.Stop()
    return $port
  } finally {
    try { $listener.Stop() } catch {}
  }
}

Ensure-Directory $script:CreatorDataRoot
Ensure-Directory $script:CatalogSpeciesRoot
Ensure-Directory $script:ExportRoot
if (-not (Test-Path -LiteralPath $script:CreatorSpeciesFile)) {
  Write-JsonFile -Path $script:CreatorSpeciesFile -Data @{ species = @() }
}
if (-not (Test-Path -LiteralPath $script:CreatorStarterFile)) {
  Write-JsonFile -Path $script:CreatorStarterFile -Data @{ starter_sets = @() }
}

$preferredPort = Normalize-Int $env:CSF_CREATOR_PORT 39077 1
$port = Find-FreePort -PreferredPort $preferredPort
$prefix = "http://127.0.0.1:$port/"
Ensure-CatalogViewsAvailable
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Utf8File -Path $script:LaunchInfoFile -Content $prefix

Write-Host "Custom Species Framework Creator"
Write-Host "Serving browser UI at $prefix"
Write-Host "Close this window to stop the creator server."

if ($env:CSF_CREATOR_NO_BROWSER -ne "1") {
  try {
    Open-CreatorBrowserWindow -Url $prefix
  } catch {
  }
}

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    try {
      if ($context.Request.Url.AbsolutePath.StartsWith("/api/")) {
        Handle-ApiRequest -Context $context
      } else {
        Handle-StaticRequest -Context $context
      }
    } catch {
      Write-JsonResponse -Response $context.Response -StatusCode 500 -Body @{
        ok = $false
        error = $_.Exception.Message
      }
    }
  }
} finally {
  Remove-Item -LiteralPath $script:LaunchInfoFile -ErrorAction SilentlyContinue
  $listener.Stop()
}
