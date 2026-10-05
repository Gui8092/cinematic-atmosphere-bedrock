<#
    validate.ps1 — Validacao estatica do resource pack.

    Divide-se em:
      [A] estrutura e sintaxe
      [B] manifesto
      [C] integridade referencial (todo identificador referenciado existe)
      [D] coerencia de schemas (format_version, ranges, nao-blendaveis)
      [E] nao-invasao (nenhuma textura/modelo/som oficial substituido)

    Nao substitui teste visual dentro do Minecraft. Saida: exit code 0 = ok, 1 = falhas.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'biome-map.ps1')

$root      = Split-Path -Parent $PSScriptRoot
$pack      = Join-Path $root 'resource_pack'
$biomesDir = Join-Path $pack 'biomes'

$script:Failures = New-Object System.Collections.Generic.List[string]
$script:Warnings = New-Object System.Collections.Generic.List[string]
$script:Checks   = 0

function Ok  { param($m) $script:Checks++; Write-Host "  [ok]   $m" -ForegroundColor DarkGreen }
function Warn { param($m) $script:Checks++; $script:Warnings.Add($m); Write-Host "  [warn] $m" -ForegroundColor Yellow }
function Fail { param($m) $script:Checks++; $script:Failures.Add($m); Write-Host "  [FAIL] $m" -ForegroundColor Red }

# ============================ [A] estrutura e sintaxe =======================
Write-Host "`n[A] estrutura e sintaxe" -ForegroundColor Cyan

$expectedDirs = @('biomes', 'atmospherics', 'color_grading', 'cubemaps', 'fogs', 'lighting', 'water')
foreach ($d in $expectedDirs) {
    if (Test-Path (Join-Path $pack $d)) { Ok "diretorio $d/ presente" } else { Fail "diretorio $d/ ausente" }
}

$allJson = @(Get-ChildItem $pack -Recurse -Filter *.json)
if ($allJson.Count -gt 0) { Ok "$($allJson.Count) arquivos .json encontrados" } else { Fail "nenhum .json encontrado" }

$parsed = @{}
foreach ($f in $allJson) {
    try {
        $parsed[$f.FullName] = Get-Content -Raw -LiteralPath $f.FullName | ConvertFrom-Json
    } catch {
        Fail "JSON invalido: $($f.FullName) -> $($_.Exception.Message)"
    }
}
if ($script:Failures.Count -eq 0) { Ok "todos os .json parseiam" }

# ============================ [B] manifesto =================================
Write-Host "`n[B] manifesto" -ForegroundColor Cyan

$manifestPath = Join-Path $pack 'manifest.json'
if (-not (Test-Path $manifestPath)) {
    Fail 'manifest.json ausente'
} else {
    $m = $parsed[$manifestPath]
    if ($m.format_version -eq 2) { Ok 'format_version = 2' } else { Fail "format_version esperado 2, obtido $($m.format_version)" }

    $h = $m.header
    foreach ($f in @('name', 'description', 'uuid', 'version', 'min_engine_version')) {
        if ($h.PSObject.Properties.Name -contains $f) { Ok "header.$f presente" } else { Fail "header.$f ausente" }
    }

    $uuidRe = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    if ($h.uuid -match $uuidRe) { Ok "header.uuid e um UUID valido ($($h.uuid))" } else { Fail "header.uuid invalido: $($h.uuid)" }
    if ($m.modules.Count -eq 1) { Ok 'exatamente 1 modulo' } else { Fail "esperado 1 modulo, obtido $($m.modules.Count)" }
    if ($m.modules[0].type -eq 'resources') { Ok 'modulo type = resources' } else { Fail "modulo type invalido: $($m.modules[0].type)" }
    if ($m.modules[0].uuid -match $uuidRe) { Ok 'modules[0].uuid e um UUID valido' } else { Fail 'modules[0].uuid invalido' }
    if ($h.uuid -ne $m.modules[0].uuid) { Ok 'UUIDs de header e modulo sao distintos' } else { Fail 'UUID de header igual ao do modulo' }

    if ($m.capabilities -contains 'pbr') { Ok 'capability "pbr" declarada (habilita Vibrant Visuals)' }
    else { Fail 'capability "pbr" ausente — Vibrant Visuals nao sera habilitado' }

    # min_engine_version deve ser >= maior format_version usado (ver [D])
    $mev = @($h.min_engine_version)
    if ($mev.Count -eq 3) { Ok "min_engine_version = [$($mev -join ', ')]" } else { Fail 'min_engine_version deve ter 3 elementos' }
}

if (Test-Path (Join-Path $pack 'pack_icon.png')) { Ok 'pack_icon.png presente' } else { Warn 'pack_icon.png ausente' }

# ============================ [C] integridade referencial ===================
Write-Host "`n[C] integridade referencial" -ForegroundColor Cyan

$declared = @{ Lighting = @(); Atmospherics = @(); ColorGrading = @(); Water = @(); Fog = @(); Cubemap = @() }

function Get-Ids {
    param([string]$Dir, [string]$Prop)
    $ids = @()
    foreach ($f in Get-ChildItem $Dir -Filter *.json -ErrorAction SilentlyContinue) {
        if (-not $parsed.ContainsKey($f.FullName)) { continue }
        $p = $parsed[$f.FullName]
        if ($p.PSObject.Properties.Name -contains $Prop) {
            $ids += $p.$Prop.description.identifier
        } else {
            Fail "$($f.Name): propriedade '$Prop' ausente"
        }
    }
    return $ids
}

$declared.Lighting     = Get-Ids (Join-Path $pack 'lighting') 'minecraft:lighting_settings'
$declared.Atmospherics = Get-Ids (Join-Path $pack 'atmospherics') 'minecraft:atmosphere_settings'
$declared.ColorGrading = Get-Ids (Join-Path $pack 'color_grading') 'minecraft:color_grading_settings'
$declared.Water        = Get-Ids (Join-Path $pack 'water') 'minecraft:water_settings'
$declared.Fog          = Get-Ids (Join-Path $pack 'fogs') 'minecraft:fog_settings'
$declared.Cubemap      = Get-Ids (Join-Path $pack 'cubemaps') 'minecraft:cubemap_settings'

foreach ($k in @('Lighting', 'Atmospherics', 'ColorGrading', 'Water', 'Fog', 'Cubemap')) {
    $list = @($declared[$k])
    $expect = @($CbaIdentifiers[$k])
    if ($list.Count -eq $expect.Count) { Ok "$k : $($list.Count) configuracoes (esperado $($expect.Count))" }
    else { Fail "$k : $($list.Count) configuracoes, esperado $($expect.Count)" }

    $dupes = @($list | Group-Object | Where-Object Count -gt 1)
    if ($dupes.Count -eq 0) { Ok "$k : sem identificadores duplicados" }
    else { foreach ($d in $dupes) { Fail "$k : identificador duplicado $($d.Name)" } }

    foreach ($id in $list) {
        if ($id -notlike 'cba:*') { Fail "$k : identificador fora do namespace cba -> $id" }
        if ($expect -notcontains $id) { Fail "$k : identificador inesperado -> $id" }
    }
}

# nomes de arquivo reservados (viram default global)
$reserved = @{
    'lighting/global.json'        = 'minecraft:lighting_identifier'
    'atmospherics/atmospherics.json' = 'minecraft:atmosphere_identifier'
    'color_grading/color_grading.json' = 'minecraft:color_grading_identifier'
    'water/water.json'            = 'minecraft:water_identifier'
}
foreach ($rel in $reserved.Keys) {
    $p = Join-Path $pack ($rel -replace '/', '\')
    if (Test-Path $p) { Ok "arquivo reservado presente: $rel" } else { Fail "arquivo reservado ausente: $rel" }
}

# --- biomas
$biomeFiles = @(Get-ChildItem $biomesDir -Filter *.client_biome.json -ErrorAction SilentlyContinue)
if ($biomeFiles.Count -eq 89) { Ok "89 arquivos *.client_biome.json" }
else { Fail "esperado 89 arquivos *.client_biome.json, obtido $($biomeFiles.Count)" }

$biomeIndex = Get-CbaBiomeIndex
$onDisk = @($biomeFiles | ForEach-Object { $_.BaseName -replace '\.client_biome$','' } | Sort-Object)
$inMap  = @($biomeIndex.Keys | Sort-Object)

$missing = @($inMap  | Where-Object { $onDisk -notcontains $_ })
$extra   = @($onDisk | Where-Object { $inMap  -notcontains $_ })
if ($missing.Count -eq 0) { Ok 'nenhum bioma do mapeamento esta sem arquivo' }
else { foreach ($x in $missing) { Fail "bioma do mapeamento sem arquivo: $x" } }
if ($extra.Count -eq 0) { Ok 'nenhum arquivo sem entrada no mapeamento' }
else { foreach ($x in $extra) { Fail "arquivo de bioma fora do mapeamento: $x" } }

$seenId = @{}
foreach ($f in $biomeFiles) {
    $p = $parsed[$f.FullName]
    if (-not $p) { continue }
    $id = $p.'minecraft:client_biome'.description.identifier
    if ($id -notmatch '^minecraft:[a-z0-9_]+$') { Fail "$($f.Name): identifier '$id' invalido" }
    if ($seenId.ContainsKey($id)) { Fail "$($f.Name): identifier duplicado '$id'" } else { $seenId[$id] = $true }

    $c = $p.'minecraft:client_biome'.components
    foreach ($pair in @(
        @('minecraft:atmosphere_identifier',    'atmosphere_identifier',    $declared.Atmospherics),
        @('minecraft:color_grading_identifier', 'color_grading_identifier', $declared.ColorGrading),
        @('minecraft:lighting_identifier',      'lighting_identifier',      $declared.Lighting),
        @('minecraft:water_identifier',         'water_identifier',         $declared.Water),
        @('minecraft:cubemap_identifier',       'cubemap_identifier',       $declared.Cubemap),
        @('minecraft:fog_appearance',           'fog_identifier',           $declared.Fog)
    )) {
        $comp = $c.PSObject.Properties[$pair[0]]
        if (-not $comp) { continue }
        $val = $comp.Value.($pair[1])
        if ($pair[2] -notcontains $val) { Fail "$($f.Name): $($pair[1]) -> '$val' nao existe em nenhum arquivo do pack" }
    }
    # cubemap so e valido no Overworld
    if ($c.PSObject.Properties['minecraft:cubemap_identifier'] -and $id -match '^minecraft:(the_end|hell|crimson_forest|warped_forest|basalt_deltas|soulsand_valley)$') {
        Fail "$($f.Name): cubemap_identifier atribuido em dimensao na-Overworld"
    }
}
Ok 'integridade referencial dos 89 biomas verificada'

# componentes vanilla preservados (som/musica/cores) — smoke test
$mustKeep = @('the_end', 'sulfur_caves', 'pale_garden', 'swampland', 'ocean')
foreach ($b in $mustKeep) {
    $p = $parsed[(Join-Path $biomesDir "$b.client_biome.json")]
    if (-not $p) { continue }
    $c = $p.'minecraft:client_biome'.components
    if ($c.PSObject.Properties['minecraft:ambient_sounds']) { Ok "$b : minecraft:ambient_sounds preservado" }
    else { Fail "$b : minecraft:ambient_sounds foi perdido ao sobrescrever o bioma" }
    if ($c.PSObject.Properties['minecraft:water_appearance']) { Ok "$b : minecraft:water_appearance preservado" }
    else { Fail "$b : minecraft:water_appearance foi perdido" }
}

# ============================ [D] coerencia de schemas ======================
Write-Host "`n[D] coerencia de schemas" -ForegroundColor Cyan

$expectedFormat = @{
    'lighting'     = '1.26.0'
    'atmospherics' = '1.21.40'
    'color_grading'= '1.21.90'
    'water'        = '1.26.0'
    'fogs'         = '1.21.90'
    'cubemaps'     = '1.21.130'
}
foreach ($dir in $expectedFormat.Keys) {
    foreach ($f in Get-ChildItem (Join-Path $pack $dir) -Filter *.json -ErrorAction SilentlyContinue) {
        $p = $parsed[$f.FullName]
        if ($p.format_version -ne $expectedFormat[$dir]) {
            Fail "$($f.Name): format_version $($p.format_version), esperado $($expectedFormat[$dir])"
        }
    }
    Ok "$dir : format_version $($expectedFormat[$dir]) em todos os arquivos"
}
foreach ($f in $biomeFiles) {
    $p = $parsed[$f.FullName]
    if ($p.format_version -ne '1.21.120') { Fail "$($f.Name): format_version $($p.format_version), esperado 1.21.120" }
}
Ok 'biomes : format_version 1.21.120 em todos os 89 arquivos'

# min_engine_version >= maior format_version do pack
if ($parsed.ContainsKey($manifestPath)) {
    $mev = @($parsed[$manifestPath].header.min_engine_version)
    $maxFv = @('1.26.0', '1.21.120', '1.21.90', '1.21.40', '1.21.130') |
        ForEach-Object { [version]$_ } | Sort-Object -Descending | Select-Object -First 1
    if (($mev[0] -eq 1) -and ($mev[1] -eq 26) -and ($mev[2] -ge 0)) { Ok "min_engine_version [$($mev -join ',')] coerente com format_version maximo $maxFv" }
    else { Fail "min_engine_version [$($mev -join ',')] incoerente com format_version maximo $maxFv" }
}

# parametros NAO blendableis precisam ser identicos em todos os arquivos do tipo
function Assert-Uniform {
    param([string]$Dir, [scriptblock]$Extract, [string]$Label)
    $vals = @{}
    foreach ($f in Get-ChildItem (Join-Path $pack $Dir) -Filter *.json -ErrorAction SilentlyContinue) {
        $v = (& $Extract $parsed[$f.FullName])
        $vals[$f.Name] = ($v | ConvertTo-Json -Compress -Depth 10)
    }
    $distinct = @($vals.Values | Sort-Object -Unique)
    if ($distinct.Count -le 1) { Ok "$Label : identico em todos os arquivos de $Dir/ (nao blendavel)" }
    else { Fail "$Label : valores divergentes entre arquivos de $Dir/ -> $($vals.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" })" }
}

Assert-Uniform 'color_grading' { param($p) $p.'minecraft:color_grading_settings'.tone_mapping } 'tone_mapping.operator'
Assert-Uniform 'lighting'      { param($p) $p.'minecraft:lighting_settings'.directional_lights.orbital.orbital_offset_degrees } 'orbital_offset_degrees'
Assert-Uniform 'water'         { param($p) $p.'minecraft:water_settings'.caustics } 'caustics'
Assert-Uniform 'water'         { param($p) $p.'minecraft:water_settings'.waves } 'waves'

# waves desligado (decisao artistica aprovada)
$wavesOn = @()
foreach ($f in Get-ChildItem (Join-Path $pack 'water') -Filter *.json) {
    if ($parsed[$f.FullName].'minecraft:water_settings'.waves.enabled -ne $false) { $wavesOn += $f.Name }
}
if ($wavesOn.Count -eq 0) { Ok 'waves.enabled = false em todos os arquivos de agua (decisao aprovada)' }
else { Fail "waves.enabled deveria ser false em: $($wavesOn -join ', ')" }

# tone mapping ACES (decisao aprovada)
$ops = @{}
foreach ($f in Get-ChildItem (Join-Path $pack 'color_grading') -Filter *.json) {
    $ops[$parsed[$f.FullName].'minecraft:color_grading_settings'.tone_mapping.operator] = $true
}
if ($ops.Keys.Count -eq 1 -and $ops.ContainsKey('aces')) { Ok 'tone_mapping.operator = aces em todos os arquivos (decisao aprovada)' }
else { Fail "tone_mapping_operator divergente ou diferente de aces: $($ops.Keys -join ', ')" }

# ranges documentados
$ambientMin = 0.0; $ambientMax = 5.0
foreach ($f in Get-ChildItem (Join-Path $pack 'lighting') -Filter *.json) {
    $a = $parsed[$f.FullName].'minecraft:lighting_settings'.ambient.illuminance
    if ($null -eq $a) {
        Fail "$($f.Name): ambient.illuminance ausente"
    } elseif ($a -is [System.ValueType]) {
        if ([double]$a -lt $ambientMin -or [double]$a -gt $ambientMax) { Fail "$($f.Name): ambient.illuminance $a fora de [$ambientMin, $ambientMax]" }
    } else {
        foreach ($kp in $a.PSObject.Properties) {
            if ([double]$kp.Value -lt $ambientMin -or [double]$kp.Value -gt $ambientMax) {
                Fail "$($f.Name): ambient.illuminance[$($kp.Name)] = $($kp.Value) fora de [$ambientMin, $ambientMax]"
            }
        }
    }

    $s = $parsed[$f.FullName].'minecraft:lighting_settings'.sky.intensity
    if ($null -eq $s) {
        Fail "$($f.Name): sky.intensity ausente"
    } elseif ($s -is [System.ValueType]) {
        $sVal = [double]$s
        if ($sVal -lt 0.1 -or $sVal -gt 1.0) { Fail "$($f.Name): sky.intensity $sVal fora de [0.1, 1.0]" }
    } else {
        foreach ($kp in $s.PSObject.Properties) {
            $kv = [double]$kp.Value
            if ($kv -lt 0.1 -or $kv -gt 1.0) { Fail "$($f.Name): sky.intensity[$($kp.Name)] = $kv fora de [0.1, 1.0]" }
        }
    }
}
Ok 'ranges de ambient.illuminance e sky.intensity dentro do schema'

foreach ($f in Get-ChildItem (Join-Path $pack 'water') -Filter *.json) {
    $w = $parsed[$f.FullName].'minecraft:water_settings'
    $pc = $w.particle_concentrations
    if ($pc.cdom -lt 0 -or $pc.cdom -gt 15)          { Fail "$($f.Name): cdom $($pc.cdom) fora de [0,15]" }
    if ($pc.chlorophyll -lt 0 -or $pc.chlorophyll -gt 10) { Fail "$($f.Name): chlorophyll $($pc.chlorophyll) fora de [0,10]" }
    if ($pc.suspended_sediment -lt 0 -or $pc.suspended_sediment -gt 300) { Fail "$($f.Name): suspended_sediment fora de [0,300]" }
    if ($w.caustics.power -lt 1 -or $w.caustics.power -gt 6) { Fail "$($f.Name): caustics.power $($w.caustics.power) fora de [1,6]" }
    $bw = $w.biome_water_color_contribution
    if ($bw -lt 0 -or $bw -gt 1) { Fail "$($f.Name): biome_water_color_contribution $bw fora de [0,1]" }
}
Ok 'ranges de water schema dentro do documento'

foreach ($f in Get-ChildItem (Join-Path $pack 'color_grading') -Filter *.json) {
    $g = $parsed[$f.FullName].'minecraft:color_grading_settings'.color_grading
    $t = $g.temperature
    if ($t.temperature -lt 1000 -or $t.temperature -gt 15000) { Fail "$($f.Name): temperature $($t.temperature) fora de [1000,15000]" }
    foreach ($range in @('midtones', 'highlights', 'shadows')) {
        $blk = $g.$range
        if (-not $blk) { continue }
        foreach ($ch in $blk.gain)      { if ([double]$ch -lt 0 -or [double]$ch -gt 10) { Fail "$($f.Name): $range.gain $ch fora de [0,10]" } }
        foreach ($ch in $blk.saturation) { if ([double]$ch -lt 0 -or [double]$ch -gt 10) { Fail "$($f.Name): $range.saturation $ch fora de [0,10]" } }
        foreach ($ch in $blk.offset)    { if ([double]$ch -lt -1 -or [double]$ch -gt 1) { Fail "$($f.Name): $range.offset $ch fora de [-1,1]" } }
        foreach ($ch in $blk.contrast)  { if ([double]$ch -lt 0 -or [double]$ch -gt 4) { Fail "$($f.Name): $range.contrast $ch fora de [0,4]" } }
        foreach ($ch in $blk.gamma)     { if ([double]$ch -lt 0 -or [double]$ch -gt 4) { Fail "$($f.Name): $range.gamma $ch fora de [0,4]" } }
    }
    if ($g.shadows -and $g.highlights -and $g.shadows.shadowsMax -ge $g.highlights.highlightsMin) {
        Fail "$($f.Name): shadowsMax ($($g.shadows.shadowsMax)) deve ser menor que highlightsMin ($($g.highlights.highlightsMin))"
    }
}
Ok 'ranges de color_grading schema dentro do documento'

foreach ($f in Get-ChildItem (Join-Path $pack 'fogs') -Filter *.json) {
    $fg = $parsed[$f.FullName].'minecraft:fog_settings'
    foreach ($t in @('air', 'weather', 'water', 'lava', 'lava_resistance')) {
        $b = $fg.distance.$t
        if (-not $b) { continue }
        if ([double]$b.fog_start -ge [double]$b.fog_end) { Fail "$($f.Name): distance.$t fog_start >= fog_end" }
        if ($b.render_distance_type -notin @('fixed', 'render')) { Fail "$($f.Name): distance.$t render_distance_type invalido" }
    }
    $d = $fg.volumetric.density.air
    if ($d) {
        if ([double]$d.max_density -lt 0 -or [double]$d.max_density -gt 1) { Fail "$($f.Name): volumetric air max_density fora de [0,1]" }
        if (-not $d.uniform) {
            if ([double]$d.zero_density_height -lt [double]$d.max_density_height) {
                Fail "$($f.Name): zero_density_height ($($d.zero_density_height)) deve ser >= max_density_height ($($d.max_density_height))"
            }
        }
    }
    $g = $fg.volumetric.henyey_greenstein_g.air.henyey_greenstein_g
    if ($g -ne $null -and ([double]$g -lt -1 -or [double]$g -gt 1)) { Fail "$($f.Name): henyey_greenstein_g $g fora de [-1,1]" }
}
Ok 'ranges e coerencia de fog schema dentro do documento'

# keyframes: 0.0 e 1.0 devem fechar o ciclo
foreach ($f in Get-ChildItem (Join-Path $pack 'lighting') -Filter *.json) {
    $L = $parsed[$f.FullName].'minecraft:lighting_settings'
    foreach ($path in @('directional_lights.orbital.sun.color', 'directional_lights.orbital.moon.color',
                        'ambient.color', 'ambient.illuminance')) {
        $node = $L
        foreach ($seg in $path.Split('.')) { if ($node -and $node.PSObject.Properties.Name -contains $seg) { $node = $node.$seg } else { $node = $null; break } }
        if (-not $node) { continue }
        if ($node -is [string] -or $node -is [double] -or $node -is [int]) { continue }
        $keys = @($node.PSObject.Properties.Name)
        if ($keys.Count -lt 2) { continue }
        if (-not ($keys -contains '0.000000')) { Warn "$($f.Name): $path sem keyframe 0.000000" }
        if (-not ($keys -contains '1.000000')) { Warn "$($f.Name): $path sem keyframe 1.000000" }
    }
}
Ok 'keyframes de lighting presentes em 0.0 e 1.0'

# ============================ [E] nao-invasao ===============================
Write-Host "`n[E] nao-invasao" -ForegroundColor Cyan

$forbidden = @('textures', 'models', 'geometry', 'sounds', 'animation_controllers', 'animations',
               'attachables', 'render_controllers', 'particles', 'entity', 'items', 'ui',
               'textures_list.json', 'pbr', 'local_lighting', 'point_lights', 'shadows')
foreach ($d in $forbidden) {
    $p = Join-Path $pack $d
    if (Test-Path $p) { Fail "pack contem '$d' — fora do escopo (nenhuma textura/modelo/material oficial deve ser alterado)" }
}
Ok 'nenhuma pasta de textura, modelo, som, material ou particula no pack'

$png = @(Get-ChildItem $pack -Recurse -Include *.png, *.tga, *.jpg, *.jpeg -File)
if ($png.Count -eq 1 -and $png[0].Name -eq 'pack_icon.png') { Ok 'unica imagem do pack e pack_icon.png' }
else { Fail "imagens encontradas: $(($png | ForEach-Object Name) -join ', ')" }

$sfx = @(Get-ChildItem $pack -Recurse -Include *.sound.json, *.wav, *.ogg -File)
if ($sfx.Count -eq 0) { Ok 'nenhum arquivo de som' } else { Fail 'pack contem arquivos de som' }

# ============================ resumo ========================================
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " Verificacoes executadas : $($script:Checks)"
Write-Host " Falhas                 : $($script:Failures.Count)" -ForegroundColor $(if ($script:Failures.Count) { 'Red' } else { 'Green' })
Write-Host " Avisos                 : $($script:Warnings.Count)" -ForegroundColor $(if ($script:Warnings.Count) { 'Yellow' } else { 'Gray' })
Write-Host "=====================================================" -ForegroundColor Cyan

foreach ($w in $script:Warnings) { Write-Host "  aviso: $w" -ForegroundColor Yellow }
foreach ($f in $script:Failures) { Write-Host "  FALHA: $f" -ForegroundColor Red }

if ($script:Failures.Count -gt 0) { exit 1 } else { exit 0 }