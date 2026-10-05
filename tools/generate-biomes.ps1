<#
    generate-biomes.ps1 — Gera os 89 arquivos resource_pack\biomes\*.client_biome.json.

    POR QUE REESCREVER OS ARQUIVOS VANILLA
    Desde 1.21.90 as configuracoes por bioma do pack base vanilla tem precedencia
    sobre os JSONs globais de packs customizados. Sem um *.client_biome.json por
    bioma, lighting\global.json e atmospherics\atmospherics.json seriam ignorados.

    COMO O MERGE FUNCIONA (nao documentado pela Mojang)
    A documentacao nao informa se um *.client_biome.json de maior prioridade
    SUBSTITUI ou MESCLA o do vanilla. Como nao podemos presumir, o gerador
    aplica a alteracao minima e reproduz verbatim todos os componentes vanilla
    que nao pertencem ao escopo visual (sons, musica, cores, precipitacao).
    Isso e seguro sob as duas hipoteses: se houver merge, o resultado e o mesmo;
    se houver substituicao total, nada se perde.

    PROCEDENCIA E LICENCA
    Os valores vem de tools\vanilla-baseline.json, transcrito de
    https://github.com/Mojang/bedrock-samples/tree/v1.26.50.4/resource_pack/biomes
    -> (c) Mojang AB, todos os direitos reservados, sujeito ao Minecraft EULA.
    O baseline contem SOMENTE valores factuais: identificadores do jogo (bioma,
    evento de som, faixa de musica) e cores hexadecimais. NENHUM asset oficial
    (textura, modelo, som, geometria, particula) e incluido ou redistribuido.

    VERSIONAMENTO
    O format_version e o MESMO do arquivo vanilla de origem, bioma a bioma.
    Nao e rebaixado: rebaixar pode mudar a interpretacao do schema ou fazer o
    motor rejeitar propriedades. vanilla usa 1.21.120 (87 biomas),
    1.26.0 (sulfur_caves) e 1.26.50 (dappled_forest).

    USO
      .\generate-biomes.ps1              # offline: usa tools\vanilla-baseline.json
      .\generate-biomes.ps1 -SyncBaseline # baixa a referencia fixada e regrava o baseline (requer internet)
#>
[CmdletBinding()]
param(
    [switch]$SyncBaseline,
    [switch]$Minimal
)

# -Minimal: escreve SOMENTE os componentes que este pack define (os 6
# identificadores Vibrant Visuals). Produz um pack sem nenhum valor transcrito
# da referencia oficial — util para quem prefere zero ambiguidade de licenca.
#
# ATENCAO: o tradeoff e real. Se o motor SUBSTITUI o client_biome vanilla em vez
# de mesclar por componente, o modo -Minimal faz o bioma perder os componentes
# que o jogo define:
#     ambient_sounds (88/89 biomas), biome_music (56/89), water_appearance (89/89),
#     grass_appearance (13), foliage_appearance (11), dry_foliage_color (7),
#     sky_color (3), precipitation (4)
# A documentacao da Mojang NAO informa qual das duas hipoteses vale.
# O modo padrao (sem -Minimal) e seguro nas duas. Use -Minimal apenas se
# aceitar esse risco em troca de zero conteudo transcrito.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'biome-map.ps1')

$root       = Split-Path -Parent $PSScriptRoot
$biomesDir  = Join-Path $root 'resource_pack\biomes'
$baselinePath = Join-Path $root $CbaVanillaRef.Baseline
$biomeIndex = Get-CbaBiomeIndex
$expected   = 89
$VV = $CbaVvComponents

# --- Serializador JSON deterministico (2 espacos, ordem de property preservada)
function Format-CbaJson {
    param($Value, [int]$Indent = 0)
    $pad   = ' ' * $Indent
    $padIn = ' ' * ($Indent + 2)
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [bool]) { if ($Value) { return 'true' } else { return 'false' } }
    if ($Value -is [string]) { return '"' + ($Value -replace '\\', '\\\\' -replace '"', '\"') + '"' }
    if ($Value -is [byte] -or $Value -is [int16] -or $Value -is [int] -or $Value -is [long] -or
        $Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        return [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0}', $Value)
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $keys = @($Value.Keys)
        if ($keys.Count -eq 0) { return '{}' }
        $lines = foreach ($k in $keys) { $padIn + '"' + $k + '": ' + (Format-CbaJson $Value[$k] ($Indent + 2)) }
        return "{`n" + ($lines -join ",`n") + "`n$pad}"
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $items = @($Value)
        if ($items.Count -eq 0) { return '[]' }
        $lines = foreach ($i in $items) { $padIn + (Format-CbaJson $i ($Indent + 2)) }
        return "[`n" + ($lines -join ",`n") + "`n$pad]"
    }
    $props = @($Value.PSObject.Properties | Where-Object { $_.MemberType -ne 'Method' })
    if ($props.Count -eq 0) { return '{}' }
    $lines = foreach ($p in $props) { $padIn + '"' + $p.Name + '": ' + (Format-CbaJson $p.Value ($Indent + 2)) }
    return "{`n" + ($lines -join ",`n") + "`n$pad}"
}

function Set-Prop {
    param($Object, [string]$Name, $Value)
    if ($Object.PSObject.Properties.Name -contains $Name) { $Object.$Name = $Value }
    else { $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}

# ---------------------------------------------------------------------------
# -SyncBaseline: atualiza o baseline a partir da referencia fixada (requer rede)
# ---------------------------------------------------------------------------
if ($SyncBaseline) {
    Write-Host "Sincronizando baseline com $($CbaVanillaRef.Repo)@$($CbaVanillaRef.Tag) ..." -ForegroundColor Cyan
    $api = "https://api.github.com/repos/$($CbaVanillaRef.Repo)/contents/$($CbaVanillaRef.BiomesDir)?ref=$($CbaVanillaRef.Tag)"
    $listing = @(Invoke-RestMethod -Uri $api -UseBasicParsing -Headers @{ 'User-Agent' = 'cinematic-atmosphere-bedrock' } -TimeoutSec 30)
    $names = @($listing | Where-Object { $_.name -like '*.client_biome.json' } | ForEach-Object { $_.name })
    if ($names.Count -ne $expected) { throw "Referencia oficial tem $($names.Count) biomas; esperado $expected." }

    $biomesOut = [ordered]@{}
    foreach ($n in ($names | Sort-Object)) {
        $biome = $n -replace '\.client_biome\.json$', ''
        $url = "https://raw.githubusercontent.com/$($CbaVanillaRef.Repo)/$($CbaVanillaRef.Tag)/$($CbaVanillaRef.BiomesDir)/$n"
        $src = Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 30
        $cb = $src.'minecraft:client_biome'
        if (-not $cb) { throw "$biome : 'minecraft:client_biome' ausente na referencia." }
        $expectedId = "minecraft:$biome"
        if ($cb.description.identifier -ne $expectedId) {
            throw "$biome : identificador da referencia e '$($cb.description.identifier)', esperado '$expectedId'."
        }
        $preserve = [ordered]@{}
        foreach ($p in $cb.components.PSObject.Properties) {
            if ($VV -contains $p.Name) { continue }
            $preserve[$p.Name] = $p.Value
        }
        $biomesOut[$biome] = [ordered]@{ format_version = $src.format_version; preserve = $preserve }
    }

    $doc = [ordered]@{
        source = [ordered]@{
            repository = $CbaVanillaRef.Repo
            tag        = $CbaVanillaRef.Tag
            path       = $CbaVanillaRef.BiomesDir
            retrieved  = (Get-Date -Format 'yyyy-MM-dd')
            license    = '(c) Mojang AB. All rights reserved - subject to the Minecraft EULA'
            note       = 'Baseline transcribed from the official reference. Contains ONLY factual values: game identifiers (biome, sound event, music track) and hex colors. No texture, model, sound, geometry or other Minecraft asset is included.'
        }
        biome_count = $biomesOut.Count
        biomes      = $biomesOut
    }
    [System.IO.File]::WriteAllText($baselinePath, (Format-CbaJson $doc 0) + "`n", (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Baseline regravado: $($biomesOut.Count) biomas." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Gera os arquivos de bioma a partir do baseline (offline)
# ---------------------------------------------------------------------------
$baseline = Get-CbaBaseline -Root $root

$baselineBiomes = @($baseline.biomes.PSObject.Properties.Name)
$mapBiomes = @($biomeIndex.Keys)

$missing = @($mapBiomes | Where-Object { $baselineBiomes -notcontains $_ })
$extra   = @($baselineBiomes | Where-Object { $mapBiomes -notcontains $_ })
if ($missing.Count -gt 0) { throw "Biomas no mapa ausentes no baseline: $($missing -join ', ')" }
if ($extra.Count -gt 0)   { throw "Biomas no baseline ausentes no mapa: $($extra -join ', ')" }
if ($mapBiomes.Count -ne $expected) { throw "Mapeamento contem $($mapBiomes.Count) biomas; esperado $expected." }

New-Item -ItemType Directory -Force -Path $biomesDir | Out-Null

# Componentes preservados declarados no baseline mas nao cobertos pela lista de
# preservacao -> erro de configuracao do proprio mapa, detectado aqui.
$allPreserve = @{}
foreach ($b in $baselineBiomes) {
    foreach ($p in $baseline.biomes.$b.preserve.PSObject.Properties) { $allPreserve[$p.Name] = $true }
}
foreach ($c in $allPreserve.Keys) {
    if ($CbaPreservedComponents -notcontains $c) {
        throw "Componente preservado '$c' esta no baseline mas nao em `$CbaPreservedComponents."
    }
}

$written = 0
foreach ($biome in $biomeIndex.Keys) {
    $family = $CbaFamilies[$biomeIndex[$biome]]
    $entry  = $baseline.biomes.$biome

    # --- format_version: o MESMO do vanilla, nunca rebaixado
    $fv = $entry.format_version
    if ([string]::IsNullOrWhiteSpace($fv)) { throw "$biome : baseline sem format_version." }

    # --- componentes nao-visuais, verbatim do baseline (pulado em -Minimal)
    $comps = [ordered]@{}
    if (-not $Minimal) {
        foreach ($p in $entry.preserve.PSObject.Properties) { $comps[$p.Name] = $p.Value }
    }

    # --- identificadores Vibrant Visuals
    $comps['minecraft:fog_appearance'] = [ordered]@{ fog_identifier = $family.Fog }
    $comps['minecraft:atmosphere_identifier']    = [ordered]@{ atmosphere_identifier    = $family.Atmospherics }
    $comps['minecraft:color_grading_identifier'] = [ordered]@{ color_grading_identifier = $family.ColorGrading }
    $comps['minecraft:lighting_identifier']      = [ordered]@{ lighting_identifier      = $family.Lighting }
    $comps['minecraft:water_identifier']         = [ordered]@{ water_identifier         = $family.Water }
    if ($family.Cubemap) {
        $comps['minecraft:cubemap_identifier'] = [ordered]@{ cubemap_identifier = $family.Cubemap }
    }

    # --- ordem estavel de leitura
    $ordered = [ordered]@{}
    foreach ($name in @('minecraft:sky_color', 'minecraft:fog_appearance', 'minecraft:water_appearance',
                        'minecraft:grass_appearance', 'minecraft:foliage_appearance', 'minecraft:dry_foliage_color',
                        'minecraft:precipitation', 'minecraft:atmosphere_identifier', 'minecraft:color_grading_identifier',
                        'minecraft:lighting_identifier', 'minecraft:water_identifier', 'minecraft:cubemap_identifier',
                        'minecraft:ambient_sounds', 'minecraft:biome_music')) {
        if ($comps.Contains($name)) { $ordered[$name] = $comps[$name] }
    }
    foreach ($name in $comps.Keys) {
        if (-not $ordered.Contains($name)) { $ordered[$name] = $comps[$name] }
    }

    $doc = [ordered]@{
        format_version           = $fv
        'minecraft:client_biome' = [ordered]@{
            description = [ordered]@{ identifier = "minecraft:$biome" }
            components  = $ordered
        }
    }

    $path = Join-Path $biomesDir "$biome.client_biome.json"
    [System.IO.File]::WriteAllText($path, (Format-CbaJson $doc 0) + "`n", (New-Object System.Text.UTF8Encoding($false)))
    $written++
}

Write-Host "generate-biomes: $written arquivos escritos em resource_pack\biomes (esperado $expected)." -ForegroundColor Green
$fvSet = @($baselineBiomes | ForEach-Object { $baseline.biomes.$_.format_version } | Sort-Object -Unique)
Write-Host "format_version preservados da referencia: $($fvSet -join ', ')"
if ($Minimal) {
    Write-Host "MODO -MINIMAL: nenhum componente transcrito da referencia oficial foi escrito." -ForegroundColor Yellow
    Write-Host "  O pack fica livre de valores da Mojang, mas biomas podem perder som, musica e cores" -ForegroundColor Yellow
    Write-Host "  caso o motor substitua (em vez de mesclar) o client_biome vanilla. Ver o cabecalho do script." -ForegroundColor Yellow
}
if ($SyncBaseline) {
    Write-Host "Baseline atualizado de $($CbaVanillaRef.Repo)@$($CbaVanillaRef.Tag)." -ForegroundColor DarkGray
} else {
    Write-Host "Modo offline: baseline local. Use -SyncBaseline para atualizar a referencia." -ForegroundColor DarkGray
}
