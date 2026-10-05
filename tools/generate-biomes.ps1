<#
    generate-biomes.ps1 — Gera os 89 arquivos resource_pack\biomes\*.client_biome.json.

    Por que reescrever os arquivos vanilla em vez de so usar os JSONs globais:
    desde 1.21.90 as configuracoes por bioma do pack base vanilla tem precedencia
    sobre os JSONs globais de packs customizados. Sem um *.client_biome.json por
    bioma, lighting/global.json e atmospherics/atmospherics.json seriam ignorados.

    Como nao ha documentacao sobre merge de client_biome entre resource packs,
    este script aplica a alteracao minima: preserva todos os componentes
    vanilla verbatim (sons, musica, cores de grama/folhagem, sky_color,
    water_appearance) e so substitui os identificadores Vibrant Visuals.

    Uso:
      .\generate-biomes.ps1                 # reaplica o mapa nos arquivos locais
      .\generate-biomes.ps1 -RefreshVanilla # reimporta os componentes vanilla da tag fixada
#>
[CmdletBinding()]
param(
    [switch]$RefreshVanilla
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'biome-map.ps1')

$root       = Split-Path -Parent $PSScriptRoot
$biomesDir  = Join-Path $root 'resource_pack\biomes'
$biomeIndex = Get-CbaBiomeIndex
$expected   = 89

if ($biomeIndex.Count -ne $expected) {
    throw "Mapeamento contem $($biomeIndex.Count) biomas; esperado $expected."
}
New-Item -ItemType Directory -Force -Path $biomesDir | Out-Null

# --- Serializador JSON deterministico (2 espacos, ordem de property preservada)
function Format-CbaJson {
    param($Value, [int]$Indent = 0)
    $pad   = ' ' * $Indent
    $padIn = ' ' * ($Indent + 2)

    if ($null -eq $Value) { return 'null' }
    if ($Value -is [bool]) { if ($Value) { return 'true' } else { return 'false' } }

    if ($Value -is [string]) {
        return '"' + ($Value -replace '\\', '\\\\' -replace '"', '\"') + '"'
    }
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

function Get-VanillaBiome {
    param([string]$Biome)
    $file = "$Biome.client_biome.json"
    $url  = "https://raw.githubusercontent.com/$($CbaVanillaRef.Repo)/$($CbaVanillaRef.Tag)/$($CbaVanillaRef.BiomesDir)/$file"
    try {
        return Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 30
    } catch {
        throw "Falha ao baixar $url : $($_.Exception.Message)"
    }
}

function Set-Prop {
    param($Object, [string]$Name, $Value)
    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

# --- Ordem canonica das chaves de um client_biome ---------------------------
$keyOrder = @(
    'format_version', 'minecraft:client_biome'
)

$written = 0
foreach ($biome in $biomeIndex.Keys) {
    $family = $CbaFamilies[$biomeIndex[$biome]]
    $path   = Join-Path $biomesDir "$biome.client_biome.json"

    if ($RefreshVanilla -or -not (Test-Path $path)) {
        $src = Get-VanillaBiome -Biome $biome
    } else {
        $src = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
    }

    $cb = $src.'minecraft:client_biome'
    if (-not $cb) { throw "$biome : propriedade 'minecraft:client_biome' ausente." }

    $cb.description.identifier = "minecraft:$biome"
    $comps = $cb.components

    # --- identificadores Vibrant Visuals (nomes reservados) ---
    Set-Prop $comps 'minecraft:atmosphere_identifier'    ([pscustomobject]@{ atmosphere_identifier    = $family.Atmospherics })
    Set-Prop $comps 'minecraft:color_grading_identifier' ([pscustomobject]@{ color_grading_identifier = $family.ColorGrading })
    Set-Prop $comps 'minecraft:lighting_identifier'      ([pscustomobject]@{ lighting_identifier      = $family.Lighting })
    Set-Prop $comps 'minecraft:water_identifier'         ([pscustomobject]@{ water_identifier         = $family.Water })

    if ($family.Cubemap) {
        Set-Prop $comps 'minecraft:cubemap_identifier' ([pscustomobject]@{ cubemap_identifier = $family.Cubemap })
    } else {
        $comps.PSObject.Properties.Remove('minecraft:cubemap_identifier')
    }

    # fog_appearance ja existe no vanilla: preserva o resto e troca so o identificador
    if (-not $comps.'minecraft:fog_appearance') {
        $comps | Add-Member -NotePropertyName 'minecraft:fog_appearance' -NotePropertyValue ([pscustomobject]@{ fog_identifier = $family.Fog })
    } else {
        $comps.'minecraft:fog_appearance'.fog_identifier = $family.Fog
    }

    # --- reordena: format_version, description, components (ordem estavel) ---
    $compsOrdered = [ordered]@{}
    foreach ($name in @('minecraft:sky_color', 'minecraft:fog_appearance', 'minecraft:water_appearance',
                        'minecraft:grass_appearance', 'minecraft:foliage_appearance', 'minecraft:dry_foliage_color',
                        'minecraft:precipitation', 'minecraft:atmosphere_identifier', 'minecraft:color_grading_identifier',
                        'minecraft:lighting_identifier', 'minecraft:water_identifier', 'minecraft:cubemap_identifier',
                        'minecraft:ambient_sounds', 'minecraft:biome_music')) {
        if ($comps.PSObject.Properties.Name -contains $name) { $compsOrdered[$name] = $comps.$name }
    }
    # qualquer componente vanilla restante e preservado no fim
    foreach ($p in $comps.PSObject.Properties) {
        if (-not $compsOrdered.Contains($p.Name)) { $compsOrdered[$p.Name] = $p.Value }
    }

    $doc = [ordered]@{
        format_version        = '1.21.120'
        'minecraft:client_biome' = [ordered]@{
            description = [ordered]@{ identifier = "minecraft:$biome" }
            components  = $compsOrdered
        }
    }

    $json = Format-CbaJson $doc 0
    [System.IO.File]::WriteAllText($path, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))
    $written++
}

Write-Host "generate-biomes: $written arquivos escritos em resource_pack\biomes (esperado $expected)."
if ($RefreshVanilla) {
    Write-Host "Componentes vanilla reimportados de $($CbaVanillaRef.Repo)@$($CbaVanillaRef.Tag)."
}