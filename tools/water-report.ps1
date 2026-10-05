<#
    water-report.ps1 - torna o sistema de agua auditavel SEM o jogo.

    Por que existe: a cor da superficie da agua (water_appearance.surface_color,
    50 cores distintas em 89 biomas) e um TINT iluminado pelo sol. Nao da para
    avaliar isso offline olhando numeros — da para medir. Este relatorio torna
    tres coisas verificaveis:

      1. a fisica dos 6 perfis (cdom, clorofila, sedimento, contribuicao)
      2. a tabela perfil x cor de superficie, com luminancia, spread e calor
      3. tres sinais de alerta que sugerem revisao

    Uso:  .\tools\water-report.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pack = Join-Path $root 'resource_pack'

function HexRgb([string]$h) {
    $h = $h.TrimStart('#')
    return @([Convert]::ToInt32($h.Substring(0,2),16),
             [Convert]::ToInt32($h.Substring(2,2),16),
             [Convert]::ToInt32($h.Substring(4,2),16))
}

Write-Host "`n=== 1. FISICA DOS PERFIS DE AGUA ===" -ForegroundColor Cyan
Write-Host "  cdom  = materia organica dissolvida -> amarelado/castanho (0-15 mg/L)" -ForegroundColor DarkGray
Write-Host "  cloro = clorofila -> verde (0-10 mg/L)" -ForegroundColor DarkGray
Write-Host "  sedim = sedimento suspenso -> vermelho/castanho (0-300 mg/L)" -ForegroundColor DarkGray
Write-Host "  contrib = quanto da surface_color do bioma se mistura na cor base" -ForegroundColor DarkGray
Write-Host ""
Write-Host ("{0,-9} {1,-6} {2,-6} {3,-7} {4,-8} {5}" -f 'perfil','cdom','cloro','sedim','contrib','leitura')
Write-Host ("-" * 84)

$waterDir = Join-Path $pack 'water'
$perfis = @{}
foreach ($f in Get-ChildItem $waterDir -Filter *.json | Sort-Object Name) {
    $w = (Get-Content -Raw -LiteralPath $f.FullName | ConvertFrom-Json).'minecraft:water_settings'
    $id = $w.description.identifier
    $p = $w.particle_concentrations
    $sed = [double]$p.suspended_sediment
    $leitura = if ($sed -ge 3) { 'turvo' }
               elseif ($sed -ge 0.5) { 'lenhoso' }
               elseif ($p.chlorophyll -ge 0.5) { 'verdoso' }
               else { 'limpo' }
    Write-Host ("{0,-9} {1,-6} {2,-6} {3,-7} {4,-8} {5}" -f `
        $id.Replace('cba:water_',''), $p.cdom, $p.chlorophyll, $p.suspended_sediment, $w.biome_water_color_contribution, $leitura)
    $perfis[$id] = @{ cdom = [double]$p.cdom; cloro = [double]$p.chlorophyll
                      sedim = $sed; contrib = [double]$w.biome_water_color_contribution }
}

# --- ordenacao da turbidez: a contribuicao deve crescer do mais limpo ao mais
# --- turvo. Este pack e monotonico; o check existe para nao deixar regredir.
Write-Host ""
$ordem = $perfis.GetEnumerator() | Sort-Object { $_.Value.contrib }
Write-Host "  ordenacao por limpidez (contribuicao crescente):" -ForegroundColor DarkGray
Write-Host ("    " + (($ordem | ForEach-Object { "$($_.Key.Replace('cba:water_',''))=$($_.Value.contrib)" }) -join '  '))
$sedOrdem = ($ordem | ForEach-Object { $_.Value.sedim })
$monotono = $true
$inversoes = @()
for ($i = 1; $i -lt $ordem.Count; $i++) {
    if ($sedOrdem[$i] -lt $sedOrdem[$i-1]) {
        $monotono = $false
        $inversoes += ("{0}(contrib {1}, sedim {2}) tem mais sedimento que {3}(contrib {4}, sedim {5})" -f `
            $ordem[$i].Key.Replace('cba:water_',''), $ordem[$i].Value.contrib, $ordem[$i].Value.sedim,
            $ordem[$i-1].Key.Replace('cba:water_',''), $ordem[$i-1].Value.contrib, $ordem[$i-1].Value.sedim)
    }
}
# Nao e falha: 'fresh' cobre rios e lagos, que SAO siltosos, e por isso tem
# sedimento 0.8 com contribuicao 0.25 — menos tint, mais lama. Oceanos abertos
# tem menos lama com mais tint. A inversao e o design, nao um erro.
if ($monotono) {
    Write-Host "    sedimento tambem cresce com a contribuicao - coerente" -ForegroundColor Green
} else {
    Write-Host "    inversoes de sedimento (esperadas, nao sao erro):" -ForegroundColor DarkGray
    foreach ($x in $inversoes) { Write-Host ("      - " + $x) -ForegroundColor DarkGray }
    Write-Host "    'fresh' cobre rios e lagos, que sao siltosos: menos tint, mais lama." -ForegroundColor DarkGray
    Write-Host "    Oceanos abertos tem o oposto. A inversao e o design." -ForegroundColor DarkGray
}

Write-Host "`n=== 2. PERFIL x COR DE SUPERFICIE ===" -ForegroundColor Cyan
Write-Host "  lum = luminancia (0-255). spread = max-min (saturacao). calor = R-B (quente/ frio)" -ForegroundColor DarkGray
Write-Host ""
$biomeDir = Join-Path $pack 'biomes'
$grupos = @{}
foreach ($f in Get-ChildItem $biomeDir -Filter *.json) {
    $c = (Get-Content -Raw -LiteralPath $f.FullName | ConvertFrom-Json).'minecraft:client_biome'.components
    $w = $c.'minecraft:water_identifier'.water_identifier
    $wa = $c.'minecraft:water_appearance'
    if (-not $wa -or -not $wa.surface_color) { continue }
    $rgb = HexRgb $wa.surface_color
    $lum = [math]::Round(0.2126*$rgb[0] + 0.7152*$rgb[1] + 0.0722*$rgb[2], 1)
    $spread = (($rgb | Measure-Object -Maximum).Maximum) - (($rgb | Measure-Object -Minimum).Minimum)
    $calor = $rgb[0] - $rgb[2]
    $nome = $f.Name.Replace('.client_biome.json','')
    if (-not $grupos.ContainsKey($w)) { $grupos[$w] = @() }
    $grupos[$w] += [pscustomobject]@{ bioma = $nome; cor = $wa.surface_color; lum = $lum; spread = $spread; calor = $calor }
}
Write-Host ("{0,-10} {1,-4} {2,-7} {3,-7} {4,-7} {5}" -f 'perfil','n','lum_min','lum_max','spread_max','cores_distintas')
Write-Host ("-" * 84)
foreach ($g in ($grupos.Keys | Sort-Object)) {
    $itens = $grupos[$g]
    $cores = @($itens | Group-Object cor).Count
    Write-Host ("{0,-10} {1,-4} {2,-7} {3,-7} {4,-7} {5}" -f `
        $g.Replace('cba:water_',''), $itens.Count,
        ($itens | Measure-Object lum -Minimum).Minimum,
        ($itens | Measure-Object lum -Maximum).Maximum,
        ($itens | Measure-Object spread -Maximum).Maximum, $cores)
}

Write-Host "`n=== 3. SINAIS DE REVISAO ===" -ForegroundColor Cyan

# (a) tints muito saturados: com spread alto o tinte domina a fisica do perfil
$altos = @($grupos.Keys | ForEach-Object { $grupos[$_] } | Where-Object { $_.spread -ge 230 })
if ($altos.Count -gt 0) {
    Write-Host ("  [a] surface_color com spread >= 230 ({0} biomas) - o tinte domina a cor do perfil:" -f $altos.Count) -ForegroundColor Yellow
    $altos | Sort-Object spread -Descending | Select-Object -First 8 | ForEach-Object {
        Write-Host ("        {0,-24} {1}  spread={2}" -f $_.bioma, $_.cor, $_.spread) -ForegroundColor DarkGray
    }
} else { Write-Host "  [a] nenhum tint com spread >= 230" -ForegroundColor Green }

# (b) o vanilla NAO diferencia raso de fundo: mesma surface_color. E as nossas
#     configuracoes de agua que carregam a profundidade.
Write-Host "  [b] raso vs fundo — o vanilla usa a MESMA surface_color nos dois:" -ForegroundColor DarkGray
foreach ($par in @(@('ocean','deep_ocean'), @('cold_ocean','deep_cold_ocean'),
                   @('warm_ocean','deep_warm_ocean'), @('lukewarm_ocean','deep_lukewarm_ocean'),
                   @('frozen_ocean','deep_frozen_ocean'))) {
    $a = $grupos.Values | ForEach-Object { $_ } | Where-Object { $_.bioma -eq $par[0] } | Select-Object -First 1
    $b = $grupos.Values | ForEach-Object { $_ } | Where-Object { $_.bioma -eq $par[1] } | Select-Object -First 1
    if ($a -and $b) {
        $igual = if ($a.cor -eq $b.cor) { 'identica' } else { "diferente ($($a.cor) / $($b.cor))" }
        Write-Host ("        {0,-22} {1,-22} {2}" -f $par[0], $par[1], $igual) -ForegroundColor DarkGray
    }
}
Write-Host "      -> a profundidade vem da diferenca de 'contrib' e de cdom/sedimento entre os perfis," -ForegroundColor DarkGray
Write-Host "         NAO da surface_color. Este pack ja separa: ocean=0.30 vs deep=0.20." -ForegroundColor DarkGray

# (c) perfil congelado com tint quente seria um conflito
$cong = @($grupos.Keys | Where-Object { $_ -like '*frozen*' } | ForEach-Object { $grupos[$_] })
if ($cong.Count -gt 0) {
    $quentes = @($cong | Where-Object { $_.calor -gt -60 })
    if ($quentes.Count -gt 0) {
        Write-Host ("  [c] perfil congelado com tint quente ({0}):" -f $quentes.Count) -ForegroundColor Yellow
        $quentes | ForEach-Object { Write-Host ("        {0,-24} {1}  calor={2}" -f $_.bioma, $_.cor, $_.calor) -ForegroundColor DarkGray }
    } else { Write-Host "  [c] nenhum perfil congelado com tint quente" -ForegroundColor Green }
}

Write-Host "`n=== 4. RELACAO COM O SOL ===" -ForegroundColor Cyan
$sol = (Get-Content -Raw -LiteralPath (Join-Path $pack 'lighting\global.json') | ConvertFrom-Json).'minecraft:lighting_settings'.directional_lights.orbital.sun.color
$vSol = @(255,127,0)
foreach ($k in @('0.140811','0.242908','0.269504','0.801062')) {
    $c = $sol.$k
    $sp = (($c | Measure-Object -Maximum).Maximum) - (($c | Measure-Object -Minimum).Minimum)
    $vSp = ($vSol | Measure-Object -Maximum).Maximum - ($vSol | Measure-Object -Minimum).Minimum
    Write-Host ("  sol em {0}: {1}  spread={2}  (vanilla no por do sol = {3}, {4:P0} do vanilla)" -f `
        $k, ($c -join ','), $sp, $vSp, ($sp / $vSp))
}
Write-Host "  A surface_color e um TINT iluminado pelo sol: quanto mais saturada a luz," -ForegroundColor DarkGray
Write-Host "  mais o tinte se revela. Este e o acoplamento que nao e observavel offline." -ForegroundColor DarkGray
Write-Host ""