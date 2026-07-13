# Exports the whole English catalog to docs/data/catalog.json for the client-side generator.
# Per card: set_id, number, name, rarity, artist, variants (from fact_price), and the exact
# TCGplayer product name + number (from the raw pull) for mass-entry. Per set: name, series,
# release date, and Mass-Entry set code. The browser filters this to build any collection.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $root) { $root = "C:\Users\justd\dev\ultiworld\pokemon-tcg-checklists\checklists" }
$duck = "C:\Users\justd\AppData\Local\Microsoft\WinGet\Packages\DuckDB.cli_Microsoft.Winget.Source_8wekyb3d8bbwe\duckdb.exe"
$db   = "C:\Users\justd\dev\ultiworld\pokemon-tcg-pricing\pipeline.duckdb"
$docs = Join-Path (Split-Path $root -Parent) 'docs'   # docs/ lives at the repo root (GitHub Pages)
$lookupPath = Join-Path $root '_csv_lookup_raw.csv'
New-Item -ItemType Directory -Force -Path (Join-Path $docs 'data') | Out-Null

$VARIANT_ORDER = @('1stEdition','1stEditionHolofoil','unlimited','unlimitedHolofoil','normal','holofoil','reverseHolofoil','cosmosHolofoil','nonHoloDeck','stampedPromo')

# CSV set-name -> set_id  (from build_massentry.ps1)
$setName2Id = @{
  'WoTC Promo'='basep';'Neo Genesis'='neo1';'Neo Discovery'='neo2';'Neo Revelation'='neo3';'Neo Destiny'='neo4'
  'Expedition'='ecard1';'Aquapolis'='ecard2';'Skyridge'='ecard3';'Sandstorm'='ex2';'Dragon'='ex3';'Hidden Legends'='ex5'
  'FireRed & LeafGreen'='ex6';'Team Rocket Returns'='ex7';'Deoxys'='ex8';'Unseen Forces'='ex10';'Delta Species'='ex11'
  'Legend Maker'='ex12';'Crystal Guardians'='ex14';'Dragon Frontiers'='ex15';'Power Keepers'='ex16'
  'EX Trainer Kit 1: Latias & Latios'='tk1b';'POP Series 2'='pop2';'Majestic Dawn'='dp5';'Stormfront'='dp7'
  'Platinum'='pl1';'Rising Rivals'='pl2';'Supreme Victors'='pl3';'Arceus'='pl4'
  'HeartGold SoulSilver'='hgss1';'Unleashed'='hgss2';'Undaunted'='hgss3';'Triumphant'='hgss4'
  'Black and White Promos'='bwp';'Noble Victories'='bw3';'Dark Explorers'='bw5';'Dragons Exalted'='bw6'
  'Boundaries Crossed'='bw7';'Plasma Storm'='bw8';'Legendary Treasures'='bw11'
  'XY Promos'='xyp';'XY Base Set'='xy1';'XY - Flashfire'='xy2';'XY - Furious Fists'='xy3';'XY - Phantom Forces'='xy4'
  'XY - Primal Clash'='xy5';'XY - Roaring Skies'='xy6';'XY - Ancient Origins'='xy7';'XY - BREAKthrough'='xy8'
  'XY - BREAKpoint'='xy9';'XY - Fates Collide'='xy10';'XY - Steam Siege'='xy11';'Generations'='g1';'Generations: Radiant Collection'='g1'
  "McDonald's Promos 2015"='mcd15';"McDonald's Promos 2016"='mcd16';"McDonald's Promos 2022"='mcd22'
  'SM Promos'='smp';'SM Base Set'='sm1';'SM - Guardians Rising'='sm2';'SM - Burning Shadows'='sm3';'Shining Legends'='sm35'
  'SM - Ultra Prism'='sm5';'SM - Forbidden Light'='sm6';'SM - Celestial Storm'='sm7';'SM - Lost Thunder'='sm8';'SM - Team Up'='sm9'
  'SM - Unbroken Bonds'='sm10';'SM - Unified Minds'='sm11';'SM - Cosmic Eclipse'='sm12'
  'SWSH01: Sword & Shield Base Set'='swsh1';'SWSH02: Rebel Clash'='swsh2';'SWSH03: Darkness Ablaze'='swsh3'
  'SWSH04: Vivid Voltage'='swsh4';'SWSH05: Battle Styles'='swsh5';'SWSH06: Chilling Reign'='swsh6'
  'SWSH07: Evolving Skies'='swsh7';'SWSH08: Fusion Strike'='swsh8';'SWSH09: Brilliant Stars'='swsh9'
  'SWSH10: Astral Radiance'='swsh10';'SWSH11: Lost Origin'='swsh11';'SWSH12: Silver Tempest'='swsh12'
  'SWSH: Crown Zenith'='swsh12pt5';'SWSH: Crown Zenith: Galarian Gallery'='swsh12pt5gg';'Pokemon GO'='pgo'
  'SV01: Scarlet & Violet Base Set'='sv1';'SV02: Paldea Evolved'='sv2';'SV03: Obsidian Flames'='sv3'
  'SV: Scarlet & Violet 151'='sv3pt5';'SV04: Paradox Rift'='sv4';'SV05: Temporal Forces'='sv5'
  'SV06: Twilight Masquerade'='sv6';'SV07: Stellar Crown'='sv7';'SV08: Surging Sparks'='sv8'
  'SV09: Journey Together'='sv9';'SV10: Destined Rivals'='sv10';'SV: Black Bolt'='zsv10pt5';'ME02: Phantasmal Flames'='me2'
}
# set_id -> Mass-Entry set code  (from build_massentry.ps1)
$code = @{
  'neo1'='N1';'neo2'='N2';'neo3'='N3';'neo4'='N4';'ecard1'='EX';'ecard2'='AQ';'ecard3'='SK'
  'ex2'='SS';'ex3'='DR';'ex5'='HL';'ex6'='RG';'ex7'='RR';'ex8'='DX';'ex10'='UF';'ex11'='DS';'ex12'='LM';'ex14'='CG';'ex15'='DF';'ex16'='PK'
  'dp5'='MD';'dp7'='SF';'pl1'='PL';'pl2'='RR';'pl3'='SV';'pl4'='AR';'hgss1'='HS';'hgss2'='UL';'hgss3'='UD';'hgss4'='TM'
  'bw3'='NVI';'bw5'='DEX';'bw6'='DRX';'bw7'='BCR';'bw8'='PLS';'bw11'='LTR'
  'xy1'='XY';'xy2'='FLF';'xy3'='FFI';'xy4'='PHF';'xy5'='PRC';'xy6'='ROS';'xy7'='AOR';'xy8'='BKT';'xy9'='BKP';'xy10'='FCO';'xy11'='STS';'g1'='GEN'
  'sm1'='SM01';'sm2'='SM02';'sm3'='SM03';'sm35'='SHL';'sm5'='SM05';'sm6'='SM06';'sm7'='SM07';'sm8'='SM8';'sm9'='SM9';'sm10'='SM10';'sm11'='SM11';'sm12'='SM12'
  'swsh1'='SWSH01';'swsh2'='SWSH02';'swsh3'='SWSH03';'swsh4'='SWSH04';'swsh5'='SWSH05';'swsh6'='SWSH06'
  'swsh7'='SWSH07';'swsh8'='SWSH08';'swsh9'='SWSH09';'swsh10'='SWSH10';'swsh11'='SWSH11';'swsh12'='SWSH12';'swsh12pt5'='CRZ';'pgo'='PGO'
  'sv1'='SVI';'sv2'='PAL';'sv3'='OBF';'sv3pt5'='MEW';'sv4'='PAR';'sv5'='TEF';'sv6'='TWM';'sv7'='SCR';'sv8'='SSP';'sv9'='JTG';'sv10'='DRI';'zsv10pt5'='BLK';'me2'='PFL'
  'basep'='PR';'pop2'='POP';'tk1b'='PR';'bwp'='PR';'xyp'='PR';'smp'='SMP';'mcd15'='M15';'mcd16'='M16';'mcd22'='M22';'swsh12pt5gg'='CRZ:GG'
}

function Norm-Number([string]$n) {
  $n = $n.Trim(); if ($n -match '^(.+?)/') { $n = $matches[1] }
  if ($n -match '^(\d+)([A-Za-z]?)$') { return ([int]$matches[1]).ToString() + $matches[2] }
  return $n
}
$avoid = 'Reverse|Cosmos|Staff|Prerelease|Promo|Stamp|Jumbo|Error|Theme Deck|Deck Exclusive|Gold Star'
function Pick-Best($cands, [string]$nm) {
  $first = ($nm -split '\s+')[0].ToLower()
  $named = @($cands | Where-Object { $_.name.ToLower().Contains($first) })
  $pool  = if ($named.Count) { $named } else { @($cands) }
  $clean = @($pool | Where-Object { $_.name -notmatch $avoid })
  $pool  = if ($clean.Count) { $clean } else { $pool }
  return @($pool | Sort-Object { $_.name.Length })[0]
}

Write-Host "loading TCGplayer lookup..."
$lookup = @{}
foreach ($row in (Import-Csv -Path $lookupPath -Encoding UTF8)) {
  $sid = $setName2Id[$row.set_name]; if (-not $sid) { continue }
  $k = "$sid|$(Norm-Number $row.number_raw)"
  if (-not $lookup.ContainsKey($k)) { $lookup[$k] = New-Object System.Collections.ArrayList }
  [void]$lookup[$k].Add(@{ name = $row.product_name; numraw = $row.number_raw })
}

Write-Host "querying catalog..."
$rowsCsv = Join-Path $env:TEMP 'catalog_rows.csv'
if (Test-Path $rowsCsv) { Remove-Item $rowsCsv -Force }
$sql = @"
COPY (
  SELECT c.set_id, c.number, c.name, COALESCE(c.rarity,'') rarity, COALESCE(c.artist,'') artist,
         s.name set_name, COALESCE(s.series,'') series, s.release_date, c.number_sort,
         COALESCE(string_agg(DISTINCT fp.variant_key,'|'),'') variants
  FROM dim_card c JOIN dim_set s ON s.set_id=c.set_id
  LEFT JOIN fact_price fp ON fp.card_id=c.card_id
  GROUP BY c.set_id,c.number,c.number_sort,c.name,c.rarity,c.artist,s.name,s.series,s.release_date
  ORDER BY s.release_date, c.set_id, c.number_sort
) TO '$($rowsCsv -replace '\\','/')' (HEADER, DELIMITER ',', QUOTE '"');
"@
$tmpSql = New-TemporaryFile
[System.IO.File]::WriteAllText($tmpSql.FullName, $sql, [System.Text.UTF8Encoding]::new($false))
& $duck $db ".read '$($tmpSql.FullName -replace '\\','/')'" | Out-Null
Remove-Item $tmpSql.FullName -Force
$rows = @(Import-Csv -Path $rowsCsv -Encoding UTF8)
Write-Host "  $($rows.Count) cards"

function J([string]$s) { if ($null -eq $s) { return '""' }; '"' + ((($s -replace '\\','\\') -replace '"','\"') -replace "[`r`n`t]",' ') + '"' }

$setsSeen = [ordered]@{}
$cardsJson = New-Object System.Text.StringBuilder
$first = $true
foreach ($r in $rows) {
  $sid = $r.set_id
  if (-not $setsSeen.Contains($sid)) {
    $cd = if ($code.ContainsKey($sid)) { $code[$sid] } else { '' }
    $setsSeen[$sid] = 'J($sid):{"n":J(set_name),"s":series,"d":date,"c":code}'  # placeholder; built below
    $setsSeen[$sid] = (J $sid) + ':{"n":' + (J $r.set_name) + ',"s":' + (J $r.series) + ',"d":' + (J ($r.release_date -replace '-','/')) + ',"c":' + (J $cd) + '}'
  }
  $vs = @(); if ($r.variants) { $vs = @($r.variants -split '\|' | Where-Object { $VARIANT_ORDER -contains $_ }) }
  $vs = @($VARIANT_ORDER | Where-Object { $vs -contains $_ })
  $pname = ''; $nraw = ''
  $k = "$sid|$(Norm-Number $r.number)"
  if ($lookup.ContainsKey($k)) { $b = Pick-Best $lookup[$k] $r.name; $pname = $b.name; $nraw = $b.numraw }
  $arr = '[' + (J $sid) + ',' + (J $r.number) + ',' + (J $r.name) + ',' + (J $r.rarity) + ',' + (J $r.artist) + ',' + (J ($vs -join '|')) + ',' + (J $pname) + ',' + (J $nraw) + ']'
  if ($first) { $first = $false } else { [void]$cardsJson.Append(',') }
  [void]$cardsJson.Append($arr)
}
$setsJson = ($setsSeen.Values -join ',')
$out = '{"sets":{' + $setsJson + '},"cards":[' + $cardsJson.ToString() + ']}'
[System.IO.File]::WriteAllText((Join-Path $docs 'data\catalog.json'), $out, [System.Text.UTF8Encoding]::new($false))
$kb = [math]::Round((Get-Item (Join-Path $docs 'data\catalog.json')).Length/1KB)
Write-Host "Wrote docs/data/catalog.json  ($($rows.Count) cards, $($setsSeen.Count) sets, ${kb} KB)"
