param(
  [string]$SpecPath = (Join-Path $PSScriptRoot "..\config\community_packs\mongratis_community_sampler.json"),
  [string]$OutputDirectory,
  [switch]$Force
)

$ErrorActionPreference = "Stop"

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
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "JSON file not found: $Path"
  }
  $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
  if ([string]::IsNullOrWhiteSpace($raw)) {
    throw "JSON file is empty: $Path"
  }
  return ConvertTo-NativeData ($raw | ConvertFrom-Json -ErrorAction Stop)
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
  return [System.IO.Path]::GetFullPath((Join-Path $RelativeTo $Path))
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

function Decode-HtmlText {
  param([string]$Text)
  if ($null -eq $Text) { return "" }
  return [System.Net.WebUtility]::HtmlDecode($Text)
}

function Convert-HtmlToText {
  param([string]$Html)
  if ([string]::IsNullOrWhiteSpace($Html)) {
    return ""
  }
  $text = [System.Text.RegularExpressions.Regex]::Replace($Html, "(?i)<br\\s*/?>", "`n")
  $text = [System.Text.RegularExpressions.Regex]::Replace($text, "<[^>]+>", " ")
  $text = Decode-HtmlText $text
  $text = $text -replace "&nbsp;", " "
  $text = $text -replace "[ \t]+", " "
  $text = $text -replace " *`n *", "`n"
  $text = $text -replace "`n{3,}", "`n`n"
  return $text.Trim()
}

function Get-RegexValue {
  param(
    [string]$Text,
    [string]$Pattern,
    [int]$Group = 1
  )

  $options = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline
  $match = [System.Text.RegularExpressions.Regex]::Match($Text, $Pattern, $options)
  if (-not $match.Success) {
    return ""
  }
  return Decode-HtmlText $match.Groups[$Group].Value.Trim()
}

function Get-RegexMatches {
  param(
    [string]$Text,
    [string]$Pattern
  )
  $options = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline
  return [System.Text.RegularExpressions.Regex]::Matches($Text, $Pattern, $options)
}

function Remove-MoveSuffixNoise {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) {
    return ""
  }
  return ($Text -replace "\s+\(N\)$", "").Trim()
}

function Normalize-GrowthRate {
  param([string]$Text)
  $value = (Decode-HtmlText $Text).Trim()
  switch ($value.ToLowerInvariant()) {
    "medium fast" { return "Medium" }
    "medium" { return "Medium" }
    "medium slow" { return "Parabolic" }
    "fast" { return "Fast" }
    "slow" { return "Slow" }
    "erratic" { return "Erratic" }
    "fluctuating" { return "Fluctuating" }
    default { return $value }
  }
}

function Get-FileHashString {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return ""
  }
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-PillowPythonPath {
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
        return $candidate
      }
    } catch {
      continue
    }
  }

  return ""
}

function Convert-ImageToPng {
  param(
    [string]$PythonPath,
    [string]$SourcePath,
    [string]$DestinationPath
  )

  if (-not $PythonPath) {
    throw "No Python runtime with Pillow is available for image conversion."
  }

  $script = @'
from PIL import Image
import sys

source, destination = sys.argv[1], sys.argv[2]
with Image.open(source) as image:
    image.save(destination, format="PNG")
'@

  $tempScript = Join-Path ([System.IO.Path]::GetDirectoryName($DestinationPath)) ("convert_" + [System.Guid]::NewGuid().ToString("N") + ".py")
  try {
    Set-Content -LiteralPath $tempScript -Value $script -Encoding UTF8
    & $PythonPath $tempScript $SourcePath $DestinationPath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $DestinationPath)) {
      throw "Python conversion failed for $SourcePath"
    }
  } finally {
    if (Test-Path -LiteralPath $tempScript) {
      Remove-Item -LiteralPath $tempScript -Force
    }
  }
}

function New-CatalogLookup {
  param($Entries)
  $valid = @{}
  $byName = @{}
  foreach ($entry in @($Entries)) {
    if (-not $entry.id) { continue }
    $id = $entry.id.ToString().ToUpperInvariant()
    $valid[$id] = $true
    if ($entry.name) {
      $byName[(Normalize-LookupToken -Text $entry.name.ToString())] = $id
    }
  }
  return @{
    valid   = $valid
    by_name = $byName
  }
}

function Resolve-CatalogId {
  param(
    [string]$Value,
    [hashtable]$Lookup
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return ""
  }

  $candidate = (Normalize-Slug -Text $Value -Separator "").ToUpperInvariant()
  if ($Lookup.valid[$candidate]) {
    return $candidate
  }

  $token = Normalize-LookupToken -Text $Value
  if ($Lookup.by_name[$token]) {
    return $Lookup.by_name[$token]
  }

  return $candidate
}

function Resolve-MoveAlias {
  param(
    [string]$MoveName,
    [hashtable]$AliasMap
  )

  if ([string]::IsNullOrWhiteSpace($MoveName)) {
    return ""
  }
  if (-not $AliasMap) {
    return $MoveName
  }

  $direct = $AliasMap[$MoveName]
  if ($direct) {
    return $direct.ToString()
  }

  $token = Normalize-LookupToken -Text $MoveName
  foreach ($key in $AliasMap.Keys) {
    if ((Normalize-LookupToken -Text $key) -eq $token) {
      return $AliasMap[$key].ToString()
    }
  }

  return $MoveName
}

function Normalize-LevelMovesAgainstCatalog {
  param(
    [object[]]$Moves,
    [hashtable]$MoveLookup,
    [hashtable]$AliasMap,
    [bool]$KeepUnknown = $true
  )

  $normalized = @()
  $unknown = @()
  foreach ($moveEntry in @($Moves)) {
    $moveName = Resolve-MoveAlias -MoveName $moveEntry.move -AliasMap $AliasMap
    $resolved = Resolve-CatalogId -Value $moveName -Lookup $MoveLookup
    if ($MoveLookup.valid[$resolved]) {
      $normalized += @{
        level = [int]$moveEntry.level
        move  = $resolved
      }
    } elseif ($KeepUnknown) {
      $normalized += @{
        level = [int]$moveEntry.level
        move  = $resolved
      }
      $unknown += $moveName
    } else {
      $unknown += $moveName
    }
  }
  return @{
    moves   = @($normalized)
    unknown = @($unknown | Select-Object -Unique)
  }
}

function Normalize-FlatMovesAgainstCatalog {
  param(
    [string[]]$Moves,
    [hashtable]$MoveLookup,
    [hashtable]$AliasMap
  )

  $normalized = @()
  $unknown = @()
  foreach ($moveName in @($Moves)) {
    $moveName = Resolve-MoveAlias -MoveName $moveName -AliasMap $AliasMap
    $resolved = Resolve-CatalogId -Value $moveName -Lookup $MoveLookup
    if ($MoveLookup.valid[$resolved]) {
      $normalized += $resolved
    } else {
      $unknown += $moveName
    }
  }
  return @{
    moves   = @($normalized | Select-Object -Unique)
    unknown = @($unknown | Select-Object -Unique)
  }
}

function Get-SectionHtml {
  param(
    [string]$Html,
    [string]$Title
  )

  $escapedTitle = [System.Text.RegularExpressions.Regex]::Escape($Title)
  return Get-RegexValue -Text $Html -Pattern ("<div class='light-container-title'><div>{0}</div></div><div class='light-container'>(.*?)</div>" -f $escapedTitle)
}

function Parse-TypeList {
  param([string]$Html)
  $headerBlock = Get-RegexValue -Text $Html -Pattern "<div class='content'>(.*?)<div class='panel'><div class='dex-stats'"
  $types = @()
  foreach ($match in Get-RegexMatches -Text $headerBlock -Pattern "<p class='type [^']+'>([^<]+)</p>") {
    $typeName = Normalize-DisplayName -Text $match.Groups[1].Value
    if ($typeName) {
      $types += $typeName.ToUpperInvariant()
    }
  }
  return @($types | Select-Object -Unique)
}

function Parse-BaseStats {
  param([string]$Html)
  return @{
    HP              = [int](Get-RegexValue -Text $Html -Pattern "class='dex-stat stat-hp'[^>]*>(\d+)<")
    ATTACK          = [int](Get-RegexValue -Text $Html -Pattern "class='dex-stat stat-att'[^>]*>(\d+)<")
    DEFENSE         = [int](Get-RegexValue -Text $Html -Pattern "class='dex-stat stat-def'[^>]*>(\d+)<")
    SPECIAL_ATTACK  = [int](Get-RegexValue -Text $Html -Pattern "class='dex-stat stat-spatt'[^>]*>(\d+)<")
    SPECIAL_DEFENSE = [int](Get-RegexValue -Text $Html -Pattern "class='dex-stat stat-spdef'[^>]*>(\d+)<")
    SPEED           = [int](Get-RegexValue -Text $Html -Pattern "class='dex-stat stat-spe'[^>]*>(\d+)<")
  }
}

function Parse-Abilities {
  param([string]$Html)
  $abilities = @()
  $hiddenAbility = ""
  foreach ($match in Get-RegexMatches -Text $Html -Pattern "<td class='small'><i>(Ability 1|Ability 2|Hidden)</i></td><td class='ability'><a [^>]*><b>([^<]+)</b>") {
    $slot = $match.Groups[1].Value.Trim()
    $name = Normalize-DisplayName -Text $match.Groups[2].Value
    if (-not $name) { continue }
    if ($slot -ieq "Hidden") {
      $hiddenAbility = $name
    } else {
      $abilities += $name
    }
  }

  return @{
    abilities      = @($abilities | Select-Object -Unique)
    hidden_ability = $hiddenAbility
  }
}

function Parse-LevelMoves {
  param(
    [string]$Html,
    [string]$SectionTitle
  )

  $moves = @()
  $escapedTitle = [System.Text.RegularExpressions.Regex]::Escape($SectionTitle)
  $tableHtml = Get-RegexValue -Text $Html -Pattern ("<div class='dex-moves[^']*'><div class='light-container-title'><div>{0}</div></div><div class='light-container'><table[^>]*>(.*?)</table>" -f $escapedTitle)
  foreach ($match in Get-RegexMatches -Text $tableHtml -Pattern "<tr><td class='level'>([^<]+)</td><td class='move'><a [^>]*>([^<]+)</a>") {
    $levelText = Decode-HtmlText $match.Groups[1].Value
    $level = 1
    if ($levelText -match "^\d+$") {
      $level = [int]$levelText
    }
    $moveName = Remove-MoveSuffixNoise -Text (Decode-HtmlText $match.Groups[2].Value)
    if (-not $moveName) { continue }
    $moves += @{
      level = $level
      move  = $moveName
    }
  }
  return @($moves)
}

function Parse-FlatMoveList {
  param(
    [string]$Html,
    [string]$SectionTitle
  )

  $moves = @()
  $escapedTitle = [System.Text.RegularExpressions.Regex]::Escape($SectionTitle)
  $tableHtml = Get-RegexValue -Text $Html -Pattern ("<div class='dex-moves[^']*'><div class='light-container-title'><div>{0}</div></div><div class='light-container'><table[^>]*>(.*?)</table>" -f $escapedTitle)
  foreach ($match in Get-RegexMatches -Text $tableHtml -Pattern "<td class='move'><a [^>]*>([^<]+)</a>") {
    $moveName = Remove-MoveSuffixNoise -Text (Decode-HtmlText $match.Groups[1].Value)
    if ($moveName) {
      $moves += $moveName
    }
  }
  return @($moves | Select-Object -Unique)
}

function Parse-Evolutions {
  param([string]$Html)

  $evolutions = @()
  $evoTail = Get-RegexValue -Text $Html -Pattern "<p class='selected'>.*?</p>(.*?)(?:<div class='dex-moves|<div class='martop-16'>Check out)"
  foreach ($match in Get-RegexMatches -Text $evoTail -Pattern "<span class='arrow'><i><span title='([^']*)' data-mon='([^']*)'>([^<]+)</span>.*?<a href='[^']*'><img[^>]*><span>([^<]+)</span>") {
    $methodHint = Convert-HtmlToText $match.Groups[1].Value
    $targetName = Normalize-DisplayName -Text $match.Groups[4].Value
    $label = Convert-HtmlToText $match.Groups[3].Value
    $method = "LEVEL"
    $parameter = $null
    if ($label -match "(?i)lv\.\s*(\d+)") {
      $parameter = [int]$Matches[1]
    } elseif ($methodHint -match "(?i)level up to at least lv\.\s*(\d+)") {
      $parameter = [int]$Matches[1]
    } else {
      $method = "SPECIAL"
      $parameter = $label
    }
    if ($targetName) {
      $evolutions += @{
        species_name = $targetName
        method       = $method
        parameter    = $parameter
      }
    }
  }
  return @($evolutions)
}

function Get-AssetDownloadUrl {
  param(
    [string]$Uid,
    [string]$Kind
  )

  switch ($Kind) {
    "front" { return "https://pokengine.b-cdn.net/play/images/mons/fronts/$Uid.webp" }
    "back" { return "https://pokengine.b-cdn.net/play/images/mons/backs/$Uid.webp" }
    "icon" { return "https://pokengine.b-cdn.net/play/images/mons/icons/$Uid.webp" }
    "overworld" { return "https://pokengine.b-cdn.net/play/images/mons/overworlds/$Uid.webp" }
    default { throw "Unsupported asset kind '$Kind'." }
  }
}

function Download-OptionalAsset {
  param(
    [string]$Url,
    [string]$DestinationPath,
    [string]$UnknownHash,
    [string]$PythonPath
  )

  $tempPath = "$DestinationPath.download"
  try {
    Invoke-WebRequest -Uri $Url -OutFile $tempPath -UseBasicParsing
  } catch {
    if (Test-Path -LiteralPath $tempPath) {
      Remove-Item -LiteralPath $tempPath -Force
    }
    return $false
  }

  if ($UnknownHash) {
    $downloadHash = Get-FileHashString -Path $tempPath
    if ($downloadHash -and $downloadHash -eq $UnknownHash) {
      Remove-Item -LiteralPath $tempPath -Force
      return $false
    }
  }

  Ensure-Directory (Split-Path -Parent $DestinationPath)
  Convert-ImageToPng -PythonPath $PythonPath -SourcePath $tempPath -DestinationPath $DestinationPath
  Remove-Item -LiteralPath $tempPath -Force
  return $true
}

function Write-TextFile {
  param(
    [string]$Path,
    [string[]]$Lines
  )
  Ensure-Directory (Split-Path -Parent $Path)
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, ($Lines -join "`r`n"), $utf8NoBom)
}

$specFullPath = Resolve-AbsolutePath -Path $SpecPath -RelativeTo (Get-Location)
$specDirectory = Split-Path -Parent $specFullPath
$spec = Read-JsonFile -Path $specFullPath
$frameworkRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$catalogPath = Join-Path $frameworkRoot "creator\data\game_catalog.json"
$catalog = if (Test-Path -LiteralPath $catalogPath) { Read-JsonFile -Path $catalogPath } else { @{} }
$typeLookup = New-CatalogLookup -Entries $catalog.types
$abilityLookup = New-CatalogLookup -Entries $catalog.abilities
$moveLookup = New-CatalogLookup -Entries $catalog.moves
$moveAliases = @{}
if ($spec.move_aliases -is [hashtable]) {
  foreach ($aliasKey in @($spec.move_aliases.Keys)) {
    $moveAliases[$aliasKey] = $spec.move_aliases[$aliasKey]
  }
}
$pillowPython = Get-PillowPythonPath
if (-not $pillowPython) {
  throw "A Python runtime with Pillow is required to convert Pokengine WebP assets into PNG for the importer."
}

$resolvedOutputDirectory = if ($OutputDirectory) {
  Resolve-AbsolutePath -Path $OutputDirectory -RelativeTo (Get-Location)
} else {
  Resolve-AbsolutePath -Path $spec.output_directory -RelativeTo $specDirectory
}

if ((Test-Path -LiteralPath $resolvedOutputDirectory) -and -not $Force.IsPresent) {
  throw "Output directory already exists: $resolvedOutputDirectory. Re-run with -Force to replace it."
}
if (Test-Path -LiteralPath $resolvedOutputDirectory) {
  Remove-Item -LiteralPath $resolvedOutputDirectory -Recurse -Force
}

$rawPagesDir = Join-Path $resolvedOutputDirectory "raw_pages"
$assetsRoot = Join-Path $resolvedOutputDirectory "assets"
$assetDirs = @{
  front = Join-Path $assetsRoot "front"
  back = Join-Path $assetsRoot "back"
  icon = Join-Path $assetsRoot "icon"
  overworld = Join-Path $assetsRoot "overworld"
}

Ensure-Directory $resolvedOutputDirectory
Ensure-Directory $rawPagesDir
foreach ($dir in $assetDirs.Values) {
  Ensure-Directory $dir
}

$unknownHashes = @{}
foreach ($kind in @("icon", "overworld")) {
  $unknownPath = Join-Path $resolvedOutputDirectory ("unknown_{0}.png" -f $kind)
  $unknownUrl = Get-AssetDownloadUrl -Uid "unknown" -Kind $kind
  if (Download-OptionalAsset -Url $unknownUrl -DestinationPath $unknownPath -UnknownHash "" -PythonPath $pillowPython) {
    $unknownHashes[$kind] = Get-FileHashString -Path $unknownPath
    Remove-Item -LiteralPath $unknownPath -Force
  }
}

$collectionHtml = ""
if ($spec.collection_url) {
  $collectionResponse = Invoke-WebRequest -Uri $spec.collection_url -UseBasicParsing
  $collectionHtml = $collectionResponse.Content
  Set-Content -LiteralPath (Join-Path $rawPagesDir "collection.html") -Value $collectionHtml -Encoding UTF8
}

$packIdSource = if ($spec.pack_id) { $spec.pack_id } else { $spec.pack_name }
$packSlug = (Normalize-Slug -Text $packIdSource -Separator "_").ToLowerInvariant()
$idPrefixSource = if ($spec.id_prefix) { $spec.id_prefix } else { "CSF_" + (Normalize-Slug -Text $packSlug -Separator "_").ToUpperInvariant() }
$idPrefix = $idPrefixSource.ToString().ToUpperInvariant()
$permissionNeedleSource = if ($spec.required_permission_text) { $spec.required_permission_text } else { "Free to use with credit" }
$permissionNeedle = $permissionNeedleSource.ToString()
$requiredAssets = @($spec.required_assets)
if ($requiredAssets.Count -eq 0) {
  $requiredAssets = @("front", "back", "icon")
}

$speciesRecords = @()
foreach ($item in @($spec.species)) {
  $speciesUrl = $item.url
  if ([string]::IsNullOrWhiteSpace($speciesUrl)) {
    throw "Each species entry must include a url."
  }

  $pageResponse = Invoke-WebRequest -Uri $speciesUrl -UseBasicParsing
  $html = $pageResponse.Content
  $titleName = Normalize-DisplayName -Text (Get-RegexValue -Text $html -Pattern "<title>([^<]+?) - Pok")
  $speciesName = if ($item.display_name) { Normalize-DisplayName -Text $item.display_name } else { $titleName }
  $uid = if ($item.uid) { $item.uid.ToString().Trim() } else { Get-RegexValue -Text $html -Pattern "\(([A-Za-z0-9]+)\)</a><br>" }
  if (-not $speciesName -or -not $uid) {
    throw "Could not determine name or uid for $speciesUrl"
  }

  Set-Content -LiteralPath (Join-Path $rawPagesDir ("{0}.html" -f $uid)) -Value $html -Encoding UTF8

  $permission = Get-RegexValue -Text $html -Pattern "<b class='free-to-use'>Permission</b><a [^>]*>([^<]+)</a>"
  if ($permissionNeedle -and ($permission -notlike "*$permissionNeedle*")) {
    throw "Species '$speciesName' does not meet the required permission rule. Found '$permission'."
  }

  $types = Parse-TypeList -Html $html
  $abilityInfo = Parse-Abilities -Html $html
  $stats = Parse-BaseStats -Html $html
  $flavor = Convert-HtmlToText (Get-SectionHtml -Html $html -Title "Flavor")
  $notes = Convert-HtmlToText (Get-SectionHtml -Html $html -Title "Notes")
  $levelMoves = Parse-LevelMoves -Html $html -SectionTitle "Level-up moves"
  $teachMoves = Parse-FlatMoveList -Html $html -SectionTitle "Teach moves"
  $eggMoves = Parse-FlatMoveList -Html $html -SectionTitle "Egg moves"
  $evolutions = Parse-Evolutions -Html $html
  $normalizedTypes = @()
  foreach ($typeName in @($types)) {
    $normalizedTypes += Resolve-CatalogId -Value $typeName -Lookup $typeLookup
  }
  $normalizedAbilities = @()
  foreach ($abilityName in @($abilityInfo.abilities)) {
    $normalizedAbilities += Resolve-CatalogId -Value $abilityName -Lookup $abilityLookup
  }
  $normalizedHiddenAbility = Resolve-CatalogId -Value $abilityInfo.hidden_ability -Lookup $abilityLookup
  $normalizedLevelMoves = Normalize-LevelMovesAgainstCatalog -Moves $levelMoves -MoveLookup $moveLookup -AliasMap $moveAliases -KeepUnknown $true
  $normalizedTeachMoves = Normalize-FlatMovesAgainstCatalog -Moves $teachMoves -MoveLookup $moveLookup -AliasMap $moveAliases
  $normalizedEggMoves = Normalize-FlatMovesAgainstCatalog -Moves $eggMoves -MoveLookup $moveLookup -AliasMap $moveAliases

  $internalId = "{0}_{1}" -f $idPrefix, (Normalize-Slug -Text $speciesName -Separator "_").ToUpperInvariant()
  $creator = Get-RegexValue -Text $html -Pattern "<b class='designer'>Designer</b><a [^>]*>([^<]+)</a>"
  $owner = Get-RegexValue -Text $html -Pattern "<b class='owner'>Owner</b><a [^>]*>([^<]+)</a>"
  $category = Normalize-DisplayName -Text (Get-RegexValue -Text $html -Pattern "<b class='bold'>([^<]+)</b> Mon")
  $heightMeters = Get-RegexValue -Text $html -Pattern "<b class='height'>Height</b><small>([0-9.]+) m"
  $weightKg = Get-RegexValue -Text $html -Pattern "<b class='weight'>Weight</b><small>([0-9.]+) kg"
  $eggGroups = @((Convert-HtmlToText (Get-RegexValue -Text $html -Pattern "<b class='egg-groups'>Egg groups</b>([^<]+)<br>")) -split ",\s*" | Where-Object { $_ })
  $growthRate = Normalize-GrowthRate -Text (Get-RegexValue -Text $html -Pattern "<b class='growth'>Growth rate</b>([^<]+)<br>")
  $happiness = Get-RegexValue -Text $html -Pattern "<b class='happiness'>Happiness</b>([^<]+)<br>"
  $catchRate = Get-RegexValue -Text $html -Pattern "<b class='catch-rate'>Catch rate</b><div class='bar' title='([^']*)'"
  $collectionSummary = if ($collectionHtml) {
    Convert-HtmlToText (Get-RegexValue -Text $collectionHtml -Pattern "<div class='martop-4'>(.*?)</div>")
  } else {
    Convert-HtmlToText (Get-RegexValue -Text $html -Pattern "<div class='martop-4'>(.*?)</div>")
  }

  $assetFiles = @{}
  foreach ($kind in @("front", "back", "icon", "overworld")) {
    $fileName = "{0}_{1}.png" -f (Normalize-Slug -Text $speciesName -Separator "_"), $kind
    $destinationPath = Join-Path $assetDirs[$kind] $fileName
    $downloaded = Download-OptionalAsset -Url (Get-AssetDownloadUrl -Uid $uid -Kind $kind) -DestinationPath $destinationPath -UnknownHash $unknownHashes[$kind] -PythonPath $pillowPython
    if ($downloaded) {
      $assetFiles[$kind] = $destinationPath
    } elseif ($requiredAssets -contains $kind) {
      throw "Species '$speciesName' is missing required asset kind '$kind'."
    }
  }

  $noteLines = @()
  if ($notes) {
    $noteLines += $notes
  }
  if (@($normalizedTeachMoves.unknown).Count -gt 0) {
    $noteLines += ("Dropped unsupported teach moves during import prep: {0}" -f (@($normalizedTeachMoves.unknown) -join ", "))
  }
  if (@($normalizedEggMoves.unknown).Count -gt 0) {
    $noteLines += ("Dropped unsupported egg moves during import prep: {0}" -f (@($normalizedEggMoves.unknown) -join ", "))
  }
  if (@($normalizedLevelMoves.unknown).Count -gt 0) {
    $noteLines += ("Level-up moves requiring manual review: {0}" -f (@($normalizedLevelMoves.unknown) -join ", "))
  }

  $creditText = if ($creator -and $owner -and ($creator -ne $owner)) {
    "Credit to $creator for $speciesName via Pokengine Mongratis. Pack owner/maintainer: $owner. Source page: $speciesUrl. Use with credit for non-commercial fangames."
  } elseif ($creator) {
    "Credit to $creator for $speciesName via Pokengine Mongratis. Source page: $speciesUrl. Use with credit for non-commercial fangames."
  } else {
    "Credit the original Mongratis creator(s) for $speciesName and retain the source page link: $speciesUrl."
  }

  $speciesRecords += @{
    id                = $internalId
    uid               = $uid
    display_name      = $speciesName
    species_name      = $speciesName
    source_pack       = $spec.collection_name
    source_url        = $speciesUrl
    creator           = $creator
    owner             = $owner
    credit_text       = $creditText
    usage_permission  = $permission
    permission_notes  = $collectionSummary
    category          = $category
    pokedex_entry     = $flavor
    types             = @($normalizedTypes | Select-Object -Unique)
    abilities         = @($normalizedAbilities | Select-Object -Unique)
    hidden_ability    = $normalizedHiddenAbility
    base_stats        = $stats
    moves             = @($normalizedLevelMoves.moves)
    teach_moves       = @($normalizedTeachMoves.moves)
    egg_moves         = @($normalizedEggMoves.moves)
    egg_groups        = @($eggGroups)
    catch_rate        = if ($catchRate -match "^\d+$") { [int]$catchRate } else { $null }
    height            = if ($heightMeters) { [double]$heightMeters * 10.0 } else { $null }
    weight            = if ($weightKg) { [double]$weightKg * 10.0 } else { $null }
    growth_rate       = $growthRate
    happiness         = if ($happiness -match "^\d+$") { [int]$happiness } else { $null }
    evolutions_raw    = @($evolutions)
    notes             = ($noteLines -join "`n`n").Trim()
    assets_downloaded = $assetFiles
  }
}

$speciesByName = @{}
foreach ($record in $speciesRecords) {
  $speciesByName[(Normalize-LookupToken -Text $record.display_name)] = $record.id
}

$metadataEntries = @()
$creditsManifest = @()
foreach ($record in $speciesRecords) {
  $resolvedEvolutions = @()
  foreach ($evolution in @($record.evolutions_raw)) {
    $targetId = $speciesByName[(Normalize-LookupToken -Text $evolution.species_name)]
    if (-not $targetId) { continue }
    $resolvedEvolutions += @{
      species   = $targetId
      method    = $evolution.method
      parameter = $evolution.parameter
    }
  }

  $metadataEntries += @{
    id                = $record.id
    display_name      = $record.display_name
    species_name      = $record.species_name
    source_pack       = $record.source_pack
    source_url        = $record.source_url
    creator           = $record.creator
    credit_text       = $record.credit_text
    usage_permission  = $record.usage_permission
    category          = $record.category
    pokedex_entry     = $record.pokedex_entry
    types             = $record.types
    abilities         = $record.abilities
    hidden_ability    = $record.hidden_ability
    base_stats        = $record.base_stats
    moves             = $record.moves
    teach_moves       = $record.teach_moves
    egg_moves         = $record.egg_moves
    egg_groups        = $record.egg_groups
    catch_rate        = $record.catch_rate
    height            = $record.height
    weight            = $record.weight
    growth_rate       = $record.growth_rate
    happiness         = $record.happiness
    evolutions        = $resolvedEvolutions
    notes             = $record.notes
  }

  $creditsManifest += @{
    species_name      = $record.display_name
    creator           = $record.creator
    owner             = $record.owner
    source_pack       = $record.source_pack
    source_url        = $record.source_url
    usage_permission  = $record.usage_permission
    credit_text       = $record.credit_text
  }
}

$sourceManifestEntry = @{
  id               = $packSlug
  enabled          = $true
  type             = "structured_pack"
  location         = "../sources/$packSlug"
  pack_name        = $spec.pack_name
  source_url       = $spec.collection_url
  creator          = "See per-species metadata"
  credit_text      = "See per-species credit_text fields generated from Pokengine source pages."
  usage_permission = $spec.collection_permission_summary
  license_files    = @("README.txt", "PERMISSIONS.txt")
  metadata_files   = @("species.json")
  notes            = "Generated by build_pokengine_pack.ps1 from explicitly selected Pokengine community species pages."
}

Write-JsonFile -Path (Join-Path $resolvedOutputDirectory "species.json") -Data @{ species = $metadataEntries }
Write-JsonFile -Path (Join-Path $resolvedOutputDirectory "credits_manifest.json") -Data @{ credits = $creditsManifest }
Write-JsonFile -Path (Join-Path $resolvedOutputDirectory "source_manifest_entry.json") -Data $sourceManifestEntry
Write-JsonFile -Path (Join-Path $resolvedOutputDirectory "pack_info.json") -Data @{
  pack_name              = $spec.pack_name
  pack_id                = $packSlug
  collection_name        = $spec.collection_name
  collection_url         = $spec.collection_url
  collection_permission  = $spec.collection_permission_summary
  generated_at           = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  generated_from_spec    = $specFullPath
  species_count          = @($metadataEntries).Count
}

$readmeLines = @(
  $spec.pack_name,
  "",
  "Generated from approved Pokengine community pages.",
  "Collection: $($spec.collection_name)",
  "Collection URL: $($spec.collection_url)",
  "",
  "This structured pack is designed for the Custom Species Framework importer.",
  "Metadata: species.json",
  "Credits: credits_manifest.json",
  "Source manifest fragment: source_manifest_entry.json",
  "",
  "Included species:"
)
foreach ($record in $speciesRecords) {
  $readmeLines += "  - $($record.display_name) ($($record.uid))"
}
Write-TextFile -Path (Join-Path $resolvedOutputDirectory "README.txt") -Lines $readmeLines

$permissionLines = @(
  "Permission Summary",
  "",
  "Collection-level statement:",
  $spec.collection_permission_summary,
  "",
  "Per-species permission pages:"
)
foreach ($record in $speciesRecords) {
  $permissionLines += "  - $($record.display_name): $($record.usage_permission)"
  $permissionLines += "    Source: $($record.source_url)"
}
Write-TextFile -Path (Join-Path $resolvedOutputDirectory "PERMISSIONS.txt") -Lines $permissionLines

Write-Host ("Built community pack '{0}' with {1} species at {2}" -f $spec.pack_name, @($metadataEntries).Count, $resolvedOutputDirectory)
