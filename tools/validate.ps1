<#
    validate.ps1 — Validacao estatica do resource pack (offline, deterministica).

    Nao usa internet. A lista de biomas vem de tools\biome-map.ps1 e o baseline
    vanilla vem de tools\vanilla-baseline.json, ambos versionados no repositorio.
    A comparacao com a referencia oficial e feita opcionalmente por
    -CheckOfficial (exige internet) e NUNCA altera o resultado padrao.

    Blocos:
      [A] estrutura e sintaxe
      [B] manifesto e coerencia de min_engine_version
      [C] integridade referencial e cobertura de biomas
      [D] regras de versao preservadas da referencia oficial
      [E] coerencia de schemas e parametros nao interpolaveis
      [F] procedencia e nao-invasao

    Saida: 0 = aprovado (avisos permitidos), 1 = reprovado.
#>
[CmdletBinding()]
param(
    [switch]$CheckOfficial
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'biome-map.ps1')

$root      = Split-Path -Parent $PSScriptRoot
$pack      = Join-Path $root 'resource_pack'
$biomesDir = Join-Path $pack 'biomes'

$script:Failures = New-Object System.Collections.Generic.List[string]
$script:Warnings = New-Object System.Collections.Generic.List[string]
$script:Checks   = 0

function Ok   { param($m) $script:Checks++; Write-Host "  [ok]   $m" -ForegroundColor DarkGreen }
function Warn { param($m) $script:Checks++; $script:Warnings.Add($m); Write-Host "  [warn] $m" -ForegroundColor Yellow }
function Fail { param($m) $script:Checks++; $script:Failures.Add($m); Write-Host "  [FAIL] $m" -ForegroundColor Red }

# ============================ [A] estrutura e sintaxe =======================
Write-Host "`n[A] estrutura e sintaxe" -ForegroundColor Cyan

foreach ($d in @('biomes', 'atmospherics', 'color_grading', 'cubemaps', 'fogs', 'lighting', 'water')) {
    if (Test-Path (Join-Path $pack $d)) { Ok "diretorio $d/ presente" } else { Fail "diretorio $d/ ausente" }
}

$allJson = @(Get-ChildItem $pack -Recurse -Filter *.json)
if ($allJson.Count -gt 0) { Ok "$($allJson.Count) arquivos .json encontrados" } else { Fail "nenhum .json encontrado" }

$parsed = @{}
foreach ($f in $allJson) {
    try { $parsed[$f.FullName] = Get-Content -Raw -LiteralPath $f.FullName | ConvertFrom-Json }
    catch { Fail "JSON invalido: $($f.FullName) -> $($_.Exception.Message)" }
}
Ok "todos os .json do pack parseiam"

# ============================ [B] manifesto =================================
Write-Host "`n[B] manifesto e min_engine_version" -ForegroundColor Cyan

$manifestPath = Join-Path $pack 'manifest.json'
if (-not (Test-Path $manifestPath)) {
    Fail 'manifest.json ausente'
    $m = $null; $h = $null
} else {
    $m = $parsed[$manifestPath]
    $h = $m.header
    if ($m.format_version -eq 2) { Ok 'format_version = 2' } else { Fail "format_version esperado 2, obtido $($m.format_version)" }
    foreach ($f in @('name', 'description', 'uuid', 'version', 'min_engine_version')) {
        if ($h.PSObject.Properties.Name -contains $f) { Ok "header.$f presente" } else { Fail "header.$f ausente" }
    }
    $uuidRe = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    if ($h.uuid -match $uuidRe) { Ok 'header.uuid e um UUID valido' } else { Fail "header.uuid invalido: $($h.uuid)" }
    if ($m.modules.Count -eq 1) { Ok 'exatamente 1 modulo' } else { Fail "esperado 1 modulo, obtido $($m.modules.Count)" }
    if ($m.modules[0].type -eq 'resources') { Ok 'modulo type = resources' } else { Fail "modulo type invalido" }
    if ($m.modules[0].uuid -match $uuidRe) { Ok 'modules[0].uuid e um UUID valido' } else { Fail 'modules[0].uuid invalido' }
    if ($h.uuid -ne $m.modules[0].uuid) { Ok 'UUIDs de header e modulo distintos' } else { Fail 'UUID de header igual ao do modulo' }
    if ($m.capabilities -contains 'pbr') { Ok 'capability "pbr" declarada' } else { Fail 'capability "pbr" ausente' }
}

if (Test-Path (Join-Path $pack 'pack_icon.png')) { Ok 'pack_icon.png presente' } else { Fail 'pack_icon.png ausente' }

# ============================ [C] referencias e cobertura ===================
Write-Host "`n[C] integridade referencial e cobertura de biomas" -ForegroundColor Cyan

$declared = @{ Lighting = @(); Atmospherics = @(); ColorGrading = @(); Water = @(); Fog = @(); Cubemap = @() }
function Get-Ids {
    param([string]$Dir, [string]$Prop)
    $ids = @()
    foreach ($f in Get-ChildItem $Dir -Filter *.json -ErrorAction SilentlyContinue) {
        if (-not $parsed.ContainsKey($f.FullName)) { continue }
        $p = $parsed[$f.FullName]
        if ($p.PSObject.Properties.Name -contains $Prop) { $ids += $p.$Prop.description.identifier }
        else { Fail "$($f.Name): propriedade '$Prop' ausente" }
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
    $list = @($declared[$k]); $expect = @($CbaIdentifiers[$k])
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

$reserved = @('lighting/global.json', 'atmospherics/atmospherics.json', 'color_grading/color_grading.json', 'water/water.json')
foreach ($rel in $reserved) {
    if (Test-Path (Join-Path $pack ($rel -replace '/', '\'))) { Ok "arquivo reservado presente: $rel" }
    else { Fail "arquivo reservado ausente: $rel" }
}

# --- baseline vanilla
$baseline = Get-CbaBaseline -Root $root
$baselineBiomes = @($baseline.biomes.PSObject.Properties.Name)
Ok "baseline vanilla carregado: $($baselineBiomes.Count) biomas (tag $($baseline.source.tag))"

# --- cobertura: mapa <-> baseline <-> disco (tres lados, nao apenas dois)
$biomeIndex = Get-CbaBiomeIndex
$onDisk = @(Get-ChildItem $biomesDir -Filter *.client_biome.json -ErrorAction SilentlyContinue |
            ForEach-Object { $_.BaseName -replace '\.client_biome$', '' } | Sort-Object)
$inMap  = @($biomeIndex.Keys | Sort-Object)

$missingMapVsBaseline = @($inMap | Where-Object { $baselineBiomes -notcontains $_ })
$missingBaseVsMap   = @($baselineBiomes | Where-Object { $inMap -notcontains $_ })
$missingDiskVsMap   = @($inMap | Where-Object { $onDisk -notcontains $_ })
$extraDisk          = @($onDisk | Where-Object { $inMap -notcontains $_ })

if ($missingMapVsBaseline.Count -eq 0) { Ok 'todo bioma do mapa existe no baseline oficial' }
else { foreach ($x in $missingMapVsBaseline) { Fail "bioma do mapa ausente no baseline: $x" } }
if ($missingBaseVsMap.Count -eq 0) { Ok 'todo bioma do baseline oficial esta mapeado' }
else { foreach ($x in $missingBaseVsMap) { Fail "bioma oficial nao mapeado: $x" } }
if ($missingDiskVsMap.Count -eq 0) { Ok 'todo bioma do mapa tem arquivo em disco' }
else { foreach ($x in $missingDiskVsMap) { Fail "bioma do mapa sem arquivo: $x" } }
if ($extraDisk.Count -eq 0) { Ok 'nenhum arquivo de bioma fora do mapa' }
else { foreach ($x in $extraDisk) { Fail "arquivo de bioma fora do mapa: $x" } }
Ok "cobertura consistente: $($onDisk.Count) arquivos == $($inMap.Count) no mapa == $($baselineBiomes.Count) no baseline"

# --- conteudo de cada bioma
$seenId = @{}
$cubemapByDimension = @{ overworld = @{ sim = 0; nao = @() }; nether = @{ sim = 0; nao = @() }; end = @{ sim = 0; nao = @() } }
foreach ($biome in $inMap) {
    $f = Join-Path $biomesDir "$biome.client_biome.json"
    if (-not $parsed.ContainsKey($f)) { continue }
    $p = $parsed[$f]
    $cb = $p.'minecraft:client_biome'
    if (-not $cb) { Fail "$biome : 'minecraft:client_biome' ausente"; continue }

    $id = $cb.description.identifier
    if ($id -ne "minecraft:$biome") { Fail "$biome : identifier '$id' invalido (esperado minecraft:$biome)" }
    if ($seenId.ContainsKey($id)) { Fail "$biome : identifier duplicado '$id'" } else { $seenId[$id] = $true }

    $c = $cb.components
    $family = $CbaFamilies[$biomeIndex[$biome]]
    $dim = $family.Dimension

    foreach ($pair in @(
        @('minecraft:atmosphere_identifier',    'atmosphere_identifier',    $declared.Atmospherics),
        @('minecraft:color_grading_identifier', 'color_grading_identifier', $declared.ColorGrading),
        @('minecraft:lighting_identifier',      'lighting_identifier',      $declared.Lighting),
        @('minecraft:water_identifier',         'water_identifier',         $declared.Water),
        @('minecraft:cubemap_identifier',       'cubemap_identifier',       $declared.Cubemap),
        @('minecraft:fog_appearance',           'fog_identifier',           $declared.Fog)
    )) {
        $comp = $c.PSObject.Properties[$pair[0]]
        if (-not $comp) {
            if ($pair[0] -ne 'minecraft:cubemap_identifier') { Fail "$biome : componente $($pair[0]) ausente" }
            continue
        }
        $val = $comp.Value.($pair[1])
        if ($pair[2] -notcontains $val) { Fail "$biome : $($pair[1]) -> '$val' nao existe em nenhum arquivo do pack" }
    }

    # --- REGRA DE CUBEMAP (explicita e verificavel)
    $temCubemap = [bool]$c.PSObject.Properties['minecraft:cubemap_identifier']
    if ($dim -eq 'overworld') {
        if ($temCubemap) { $cubemapByDimension.overworld.sim++ }
        else {
            $cubemapByDimension.overworld.nao += $biome
            Fail "$biome (Overworld): cubemap_identifier ausente — a personalizacao de cubemap SE APLICA ao Overworld"
        }
    } else {
        if ($temCubemap) {
            $cubemapByDimension[$dim].sim++
            Fail "$biome ($dim): cubemap_identifier proibido — cubemap so e customizavel no Overworld"
        } else { $cubemapByDimension[$dim].nao += $biome }
    }

    # --- componentes preservados: devem bater com o baseline, verbatim
    $entry = $baseline.biomes.$biome
    $preserveNames = @($entry.preserve.PSObject.Properties.Name)
    foreach ($name in $preserveNames) {
        if (-not $c.PSObject.Properties[$name]) { Fail "$biome : componente preservado '$name' ausente (som/musica/cor perdidos)"; continue }
        $want = ($entry.preserve.$name | ConvertTo-Json -Compress -Depth 20)
        $got = ($c.$name | ConvertTo-Json -Compress -Depth 20)
        if ($want -ne $got) { Fail "$biome : componente preservado '$name' difere do baseline" }
    }
    $gotNames = @($c.PSObject.Properties.Name)
    $extraNonVv = @($gotNames | Where-Object { $CbaVvComponents -notcontains $_ -and $preserveNames -notcontains $_ })
    if ($extraNonVv.Count -gt 0) { Fail "$biome : componente nao-vibrant nao declarado no baseline -> $($extraNonVv -join ', ')" }
}

Ok "conteudo e procedencia dos $($onDisk.Count) biomas verificados contra o baseline"
Ok "cubemap: Overworld $($cubemapByDimension.overworld.sim)/$(@($inMap | Where-Object { $CbaFamilies[$biomeIndex[$_]].Dimension -eq 'overworld' }).Count) atribuidos | Nether $($cubemapByDimension.nether.nao.Count) sem | End $($cubemapByDimension.end.nao.Count) sem"

# --- comparacao opcional com a referencia oficial (exige internet)
if ($CheckOfficial) {
    Write-Host "  (comparando com a referencia oficial online...)" -ForegroundColor DarkGray
    try {
        $api = "https://api.github.com/repos/$($CbaVanillaRef.Repo)/contents/$($CbaVanillaRef.BiomesDir)?ref=$($CbaVanillaRef.Tag)"
        $listing = @(Invoke-RestMethod -Uri $api -UseBasicParsing -Headers @{ 'User-Agent' = 'cba-validate' } -TimeoutSec 30)
        $official = @($listing | Where-Object { $_.name -like '*.client_biome.json' } |
                      ForEach-Object { $_.name -replace '\.client_biome\.json$', '' } | Sort-Object)
        $diffA = @($official | Where-Object { $inMap -notcontains $_ })
        $diffB = @($inMap | Where-Object { $official -notcontains $_ })
        if ($official.Count -eq 89) { Ok "referencia oficial $($CbaVanillaRef.Tag) tem 89 biomas" }
        else { Fail "referencia oficial tem $($official.Count) biomas; esperado 89" }
        if ($diffA.Count -eq 0) { Ok 'inventario identico a referencia oficial (nenhum bioma faltando)' }
        else { foreach ($x in $diffA) { Fail "bioma da referencia oficial ausente no projeto: $x" } }
        if ($diffB.Count -eq 0) { Ok 'nenhum bioma indevido no projeto' }
        else { foreach ($x in $diffB) { Fail "bioma indevido no projeto: $x" } }
    } catch {
        Warn "comparacao oficial indisponivel (sem rede?): $($_.Exception.Message). As demais verificacoes seguem validas."
    }
} else {
    Ok 'comparacao com a referencia oficial pulada (offline). Use -CheckOfficial para habilitar.'
}

# ============================ [D] versoes preservadas =======================
Write-Host "`n[D] format_version preservado da referencia oficial" -ForegroundColor Cyan

foreach ($dir in $CbaFormatVersions.Keys) {
    $expected = @($CbaFormatVersions[$dir])
    $found = @()
    foreach ($f in Get-ChildItem (Join-Path $pack $dir) -Filter *.json -ErrorAction SilentlyContinue) {
        $v = $parsed[$f.FullName].format_version
        $found += $v
        if ($expected -notcontains $v) { Fail "$($f.Name): format_version '$v' fora do conjunto aceito ($($expected -join ', '))" }
    }
    $uniq = @($found | Sort-Object -Unique)
    Ok "$dir : format_version $($uniq -join ', ') (aceito: $($expected -join ', '))"
}

$fvBiomes = @{}
foreach ($biome in $inMap) {
    $f = Join-Path $biomesDir "$biome.client_biome.json"
    if (-not $parsed.ContainsKey($f)) { continue }
    $v = $parsed[$f].format_version
    $want = $baseline.biomes.$biome.format_version
    if ($v -ne $want) { Fail "$biome : format_version '$v' difere do vanilla '$want' (nao deve ser rebaixado)" }
    if (-not $fvBiomes.ContainsKey($v)) { $fvBiomes[$v] = @() }
    $fvBiomes[$v] += $biome
}
foreach ($v in ($fvBiomes.Keys | Sort-Object)) {
    Ok "biomas com format_version $v : $($fvBiomes[$v].Count) -> $(($fvBiomes[$v] | Sort-Object) -join ', ')"
}

# min_engine_version coerente com o MAIOR format_version efetivamente usado
if ($h) {
    $mev = @($h.min_engine_version)
    $mevVer = [version]::new($mev[0], $mev[1], $mev[2])
    $maxFvVer = $null
    foreach ($v in @($fvBiomes.Keys) + @($CbaFormatVersions.Values | ForEach-Object { $_ })) {
        try { $cv = [version]$v; if ($null -eq $maxFvVer -or $cv -gt $maxFvVer) { $maxFvVer = $cv } } catch { }
    }
    if ($null -ne $maxFvVer -and $mevVer -ge $maxFvVer) {
        Ok "min_engine_version [$($mev -join ',')] >= maior format_version usado ($maxFvVer)"
    } else {
        Fail "min_engine_version [$($mev -join ',')] < maior format_version usado ($maxFvVer): allows pack ativo com arquivos inertes"
    }
}

# ============================ [E] schemas ==================================
Write-Host "`n[E] coerencia de schemas" -ForegroundColor Cyan

function Assert-Uniform {
    param([string]$Dir, [scriptblock]$Extract, [string]$Label)
    $vals = @{}
    foreach ($f in Get-ChildItem (Join-Path $pack $Dir) -Filter *.json -ErrorAction SilentlyContinue) {
        $vals[$f.Name] = ((& $Extract $parsed[$f.FullName]) | ConvertTo-Json -Compress -Depth 10)
    }
    $distinct = @($vals.Values | Sort-Object -Unique)
    if ($distinct.Count -le 1) { Ok "$Label : identico em todos os arquivos de $Dir/ (nao interpolavel)" }
    else { Fail "$Label : divergente entre arquivos de $Dir/ -> $($vals.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" })" }
}
Assert-Uniform 'color_grading' { param($p) $p.'minecraft:color_grading_settings'.tone_mapping } 'tone_mapping.operator'
Assert-Uniform 'lighting'      { param($p) $p.'minecraft:lighting_settings'.directional_lights.orbital.orbital_offset_degrees } 'orbital_offset_degrees'
Assert-Uniform 'water'         { param($p) $p.'minecraft:water_settings'.caustics } 'caustics'
Assert-Uniform 'water'         { param($p) $p.'minecraft:water_settings'.waves } 'waves'

$wavesOn = @(Get-ChildItem (Join-Path $pack 'water') -Filter *.json | Where-Object { $parsed[$_.FullName].'minecraft:water_settings'.waves.enabled -ne $false } | ForEach-Object Name)
if ($wavesOn.Count -eq 0) { Ok 'waves.enabled = false em todos (decisao artistica aprovada)' } else { Fail "waves.enabled deveria ser false em: $($wavesOn -join ', ')" }

$ops = @{}
foreach ($f in Get-ChildItem (Join-Path $pack 'color_grading') -Filter *.json) { $ops[$parsed[$f.FullName].'minecraft:color_grading_settings'.tone_mapping.operator] = $true }
if ($ops.Keys.Count -eq 1 -and $ops.ContainsKey('aces')) { Ok 'tone_mapping.operator = aces em todos (decisao aprovada)' }
else { Fail "tone_mapping operator divergente ou diferente de aces: $($ops.Keys -join ', ')" }

foreach ($f in Get-ChildItem (Join-Path $pack 'lighting') -Filter *.json) {
    $L = $parsed[$f.FullName].'minecraft:lighting_settings'
    $a = $L.ambient.illuminance
    if ($null -eq $a) { Fail "$($f.Name): ambient.illuminance ausente" }
    elseif ($a -is [System.ValueType]) {
        if ([double]$a -lt 0.0 -or [double]$a -gt 5.0) { Fail "$($f.Name): ambient.illuminance $a fora de [0.0, 5.0]" }
    } else {
        foreach ($kp in $a.PSObject.Properties) {
            if ([double]$kp.Value -lt 0.0 -or [double]$kp.Value -gt 5.0) { Fail "$($f.Name): ambient.illuminance[$($kp.Name)] fora de [0.0, 5.0]" }
        }
    }
    $s = $L.sky.intensity
    if ($null -eq $s) { Fail "$($f.Name): sky.intensity ausente" }
    elseif ($s -is [System.ValueType]) {
        if ([double]$s -lt 0.1 -or [double]$s -gt 1.0) { Fail "$($f.Name): sky.intensity $s fora de [0.1, 1.0]" }
    } else {
        foreach ($kp in $s.PSObject.Properties) {
            if ([double]$kp.Value -lt 0.1 -or [double]$kp.Value -gt 1.0) { Fail "$($f.Name): sky.intensity[$($kp.Name)] fora de [0.1, 1.0]" }
        }
    }
    foreach ($path in @('directional_lights.orbital.sun.color', 'directional_lights.orbital.moon.color', 'ambient.color', 'ambient.illuminance')) {
        $node = $L
        foreach ($seg in $path.Split('.')) { if ($node -and $node.PSObject.Properties.Name -contains $seg) { $node = $node.$seg } else { $node = $null; break } }
        if (-not $node -or $node -is [string] -or $node -is [System.ValueType]) { continue }
        $keys = @($node.PSObject.Properties.Name)
        if ($keys.Count -lt 2) { continue }
        if (-not ($keys -contains '0.000000')) { Warn "$($f.Name): $path sem keyframe 0.000000" }
        if (-not ($keys -contains '1.000000')) { Warn "$($f.Name): $path sem keyframe 1.000000" }
    }
}
Ok 'ranges de ambient/sky e ciclos de keyframe conferidos'

foreach ($f in Get-ChildItem (Join-Path $pack 'water') -Filter *.json) {
    $w = $parsed[$f.FullName].'minecraft:water_settings'
    $pc = $w.particle_concentrations
    if ($pc.cdom -lt 0 -or $pc.cdom -gt 15) { Fail "$($f.Name): cdom fora de [0,15]" }
    if ($pc.chlorophyll -lt 0 -or $pc.chlorophyll -gt 10) { Fail "$($f.Name): chlorophyll fora de [0,10]" }
    if ($pc.suspended_sediment -lt 0 -or $pc.suspended_sediment -gt 300) { Fail "$($f.Name): suspended_sediment fora de [0,300]" }
    if ($w.caustics.power -lt 1 -or $w.caustics.power -gt 6) { Fail "$($f.Name): caustics.power fora de [1,6]" }
    $bw = $w.biome_water_color_contribution
    if ($bw -lt 0 -or $bw -gt 1) { Fail "$($f.Name): biome_water_color_contribution $bw fora de [0,1]" }
}
Ok 'ranges de water schema conferidos'

foreach ($f in Get-ChildItem (Join-Path $pack 'color_grading') -Filter *.json) {
    $g = $parsed[$f.FullName].'minecraft:color_grading_settings'.color_grading
    if ($g.temperature.temperature -lt 1000 -or $g.temperature.temperature -gt 15000) { Fail "$($f.Name): temperature fora de [1000,15000]" }
    foreach ($range in @('midtones', 'highlights', 'shadows')) {
        $blk = $g.$range
        if (-not $blk) { continue }
        foreach ($ch in $blk.gain) { if ([double]$ch -lt 0 -or [double]$ch -gt 10) { Fail "$($f.Name): $range.gain fora de [0,10]" } }
        foreach ($ch in $blk.saturation) { if ([double]$ch -lt 0 -or [double]$ch -gt 10) { Fail "$($f.Name): $range.saturation fora de [0,10]" } }
        foreach ($ch in $blk.offset) { if ([double]$ch -lt -1 -or [double]$ch -gt 1) { Fail "$($f.Name): $range.offset fora de [-1,1]" } }
        foreach ($ch in $blk.contrast) { if ([double]$ch -lt 0 -or [double]$ch -gt 4) { Fail "$($f.Name): $range.contrast fora de [0,4]" } }
        foreach ($ch in $blk.gamma) { if ([double]$ch -lt 0 -or [double]$ch -gt 4) { Fail "$($f.Name): $range.gamma fora de [0,4]" } }
    }
    if ($g.shadows -and $g.highlights -and $g.shadows.shadowsMax -ge $g.highlights.highlightsMin) {
        Fail "$($f.Name): shadowsMax deve ser menor que highlightsMin"
    }
}
Ok 'ranges de color_grading conferidos'

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
        if (-not $d.PSObject.Properties['uniform']) {
            $zero = [double]$d.zero_density_height; $maxh = [double]$d.max_density_height
            if ($zero -lt $maxh) { Fail "$($f.Name): zero_density_height ($zero) deve ser >= max_density_height ($maxh)" }
            if ($zero -eq $maxh) { } # perfil uniforme abaixo do teto: padrao do vanilla
        }
        $g2 = $fg.volumetric.henyey_greenstein_g.air.henyey_greenstein_g
        if ($null -ne $g2 -and ([double]$g2 -lt -1 -or [double]$g2 -gt 1)) { Fail "$($f.Name): henyey_greenstein_g fora de [-1,1]" }
        if ($null -ne $fg.volumetric.density.water -or $null -ne $fg.volumetric.density.lava) {
            Warn "$($f.Name): volumetric define agua/lava — confirme se e intencional"
        }
    }
}
Ok 'ranges e coerencia de fog schema conferidos'

# ============================ [F] procedencia e nao-invasao =================
Write-Host "`n[F] procedencia e nao-invasao" -ForegroundColor Cyan

$forbidden = @('textures', 'models', 'geometry', 'sounds', 'animation_controllers', 'animations',
               'attachables', 'render_controllers', 'particles', 'entity', 'items', 'ui',
               'textures_list.json', 'pbr', 'local_lighting', 'point_lights', 'shadows')
foreach ($d in $forbidden) {
    if (Test-Path (Join-Path $pack $d)) { Fail "pack contem '$d' — fora do escopo" }
}
Ok 'nenhuma pasta de textura, modelo, som, material ou particula no pack'

$media = @(Get-ChildItem $pack -Recurse -Include *.png,*.tga,*.jpg,*.jpeg,*.gif,*.svg,*.webp -File)
if ($media.Count -eq 1 -and $media[0].Name -eq 'pack_icon.png') { Ok 'unica midia do pack e pack_icon.png (recurso original)' }
else { Fail "midias encontradas: $(($media | ForEach-Object Name) -join ', ')" }

$sfx = @(Get-ChildItem $pack -Recurse -Include *.ogg,*.wav,*.mp3,*.nbs -File)
if ($sfx.Count -eq 0) { Ok 'nenhum arquivo de som' } else { Fail "arquivos de som: $($sfx.Count)" }

$scripts = @(Get-ChildItem $pack -Recurse -Include *.js,*.mjs,*.ts,*.py,*.lua -File)
if ($scripts.Count -eq 0) { Ok 'nenhum script no pack' } else { Fail "scripts encontrados: $($scripts.Count)" }

if ($baseline.source.tag -and $baseline.source.license) {
    Ok "baseline declara procedencia: $($baseline.source.repository)@$($baseline.source.tag)"
    Ok "baseline declara licenca da referencia: $($baseline.source.license)"
} else { Fail 'baseline sem metadados de procedencia/licenca' }

# ============================ resumo =======================================
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " Verificacoes executadas : $($script:Checks)"
Write-Host " Falhas                 : $($script:Failures.Count)" -ForegroundColor $(if ($script:Failures.Count) { 'Red' } else { 'Green' })
Write-Host " Avisos                 : $($script:Warnings.Count)" -ForegroundColor $(if ($script:Warnings.Count) { 'Yellow' } else { 'Gray' })
Write-Host "=====================================================" -ForegroundColor Cyan
foreach ($w in $script:Warnings) { Write-Host "  aviso: $w" -ForegroundColor Yellow }
foreach ($f in $script:Failures) { Write-Host "  FALHA: $f" -ForegroundColor Red }

if ($script:Failures.Count -gt 0) { exit 1 } else { exit 0 }