<#
    fog-report.ps1 — Relatorio de densidade do fog volumetrico.

    O pipeline de fog volumetrico nao e testavel offline, e os perfis deste pack
    incluem uma rampa vertical que o vanilla NAO usa. Este script torna essa
    escolha auditavel sem o jogo: calcula a densidade efetivo em alturas
    representativas e compara com os perfis do vanilla.

    O que a ferramenta FAZ:
      - le os 10 perfis em resource_pack\fogs\
      - calcula a densidade interpolada em Y = 0, 20, 40, 60, 80, 100, 128,
        160, 200, 260, 320 para cada perfil
      - compara com as densidades do vanilla v1.26.50.4 (medidas na auditoria)
      - alerta sobre perfis de superficie cuja rampa NAO e padrao do vanilla

    O que a ferramenta NAO FAZ:
      - nao substitui teste visual. Os valores sao calculados a partir do schema,
        nao medidos no motor.

    Uso:  .\fog-report.ps1 [-Csv <arquivo>]
#>
[CmdletBinding()]
param([string]$Csv)

$ErrorActionPreference = 'Stop'
# Sem isto, a cultura pt-BR formata 0.02 como "0,02" e a viraula decimal num
# contexto de numero quebra a leitura da tabela.
$inv = [System.Globalization.CultureInfo]::InvariantCulture
[System.Threading.Thread]::CurrentThread.CurrentCulture = $inv

$root = Split-Path -Parent $PSScriptRoot
$fogDir = Join-Path $root 'resource_pack\fogs'

function Num {
    param($v, [string]$fmt = '0.#####')
    if ($null -eq $v) { return '   n/a' }
    return ([double]$v).ToString($fmt, [System.Globalization.CultureInfo]::InvariantCulture)
}

# densidades medidas no vanilla v1.26.50.4 (docs/research.md §14)
$vanilla = @{
    'default (sem volumetric)' = $null
    'desert / dry / ice_plains' = 0.0
    'humid, jungle, taiga, swamp' = 0.05
    'lush_caves' = 0.05
    'pale_garden, sulfur_cave' = 0.07
    'the_end' = 0.25
    'hell' = $null
}

function Get-Density {
    param([double]$maxDensity, [double]$zeroH, [double]$maxH, [int]$y, [bool]$uniform)
    if ($null -eq $maxDensity) { return $null }
    if ($uniform) { return $maxDensity }
    if ($zeroH -eq $maxH) {
        # rampa de altura zero: uniforme abaixo do teto, zero acima
        if ($y -ge $zeroH) { return 0.0 }
        return $maxDensity
    }
    if ($y -ge $zeroH) { return 0.0 }
    if ($y -le $maxH) { return $maxDensity }
    $t = ($zeroH - $y) / ($zeroH - $maxH)
    return [math]::Round($maxDensity * $t, 6)
}

$rows = New-Object System.Collections.Generic.List[object]
foreach ($f in Get-ChildItem $fogDir -Filter *.json | Sort-Object Name) {
    $j = Get-Content -Raw -LiteralPath $f.FullName | ConvertFrom-Json
    $fg = $j.'minecraft:fog_settings'
    $d = $fg.volumetric.density.air
    $id = $fg.description.identifier
    if (-not $d) {
        $rows.Add([pscustomobject]@{ Perfil = $f.Name; Identificador = $id; MaxDensity = $null; Zero = $null; MaxH = $null; Uniform = $null; Rampa = 'sem volumetric' })
        continue
    }
    $uniform = [bool]($d.PSObject.Properties.Name -contains 'uniform' -and $d.uniform)
    $zeroH = if ($d.PSObject.Properties.Name -contains 'zero_density_height') { [double]$d.zero_density_height } else { 320.0 }
    $maxH  = if ($d.PSObject.Properties.Name -contains 'max_density_height')  { [double]$d.max_density_height }  else { 320.0 }
    $rampa = if ($uniform) { 'uniform=true' }
             elseif ($zeroH -eq $maxH) { 'uniforme ate Y=' + [int]$zeroH }
             else { "rampa $zeroH -> $maxH" }
    foreach ($y in @(0, 20, 40, 60, 80, 100, 128, 160, 200, 260, 320)) {
        $rows.Add([pscustomobject]@{
            Perfil = $f.Name; Identificador = $id; Y = $y
            MaxDensity = [double]$d.max_density; Zero = $zeroH; MaxH = $maxH
            Uniform = $uniform; Rampa = $rampa
            Densidade = Get-Density -maxDensity ([double]$d.max_density) -zeroH $zeroH -maxH $maxH -y $y -uniform $uniform
        })
    }
}

Write-Host "`n=== Densidade do fog volumetric por altura ===" -ForegroundColor Cyan
Write-Host "   (calculado a partir do schema; NAO medido no motor)" -ForegroundColor DarkGray

$byProfile = $rows | Group-Object Perfil
$ys = @(0, 20, 40, 60, 80, 100, 128, 160, 200, 260, 320)
Write-Host ""
Write-Host ("{0,-16} {1,-9} {2,-24} {3}" -f 'perfil', 'max', 'perfil vertical', ($ys -join ' '.PadLeft(8)))
Write-Host ("-" * 170)
foreach ($g in ($byProfile | Sort-Object Name)) {
    $first = $g.Group | Select-Object -First 1
    $vals = @()
    foreach ($y in $ys) {
        $r = $g.Group | Where-Object { $_.Y -eq $y } | Select-Object -First 1
        $vals += ('{0,8}' -f (Num $r.Densidade))
    }
    $max = if ($null -eq $first.MaxDensity) { 'n/a' } else { (Num $first.MaxDensity) }
    Write-Host ("{0,-16} {1,-8} {2,-24} {3}" -f $first.Perfil, $max, $first.Rampa, ($vals -join ' '))
}

Write-Host "`n=== Alcance da nevoa de ar em BLOCOS ===" -ForegroundColor Cyan
Write-Host "  type 'render' = fracao do render distance (render_distance_chunks x 16)" -ForegroundColor DarkGray
Write-Host "  type 'fixed'  = blocos absolutos, independem do render distance" -ForegroundColor DarkGray
Write-Host ""
Write-Host ("{0,-14} {1,-12} {2,-16} {3,-16} {4,-16}" -f 'perfil', 'tipo', 'pack @8ch', 'pack @16ch', 'vanilla @16ch')
Write-Host ("-" * 88)

# referencias medidas do vanilla v1.26.50.4 (docs/research.md §14)
$vanRef = @{
    'default'  = @{ f = 'default_fog_setting.json';                          t = 'render' }
    'forest'   = @{ f = 'jungle_fog_setting.json';                            t = 'render' }
    'cold'     = @{ f = 'cold_taiga_fog_setting.json';                       t = 'render' }
    'mountain' = @{ f = 'extreme_hills_plus_trees_fog_setting.json';          t = 'render' }
    'hot'      = @{ f = 'desert_fog_setting.json';                            t = 'render' }
    'ocean'    = @{ f = 'lukewarm_ocean_fog_setting.json';                   t = 'render' }
    'swamp'    = @{ f = 'swampland_fog_setting.json';                        t = 'render' }
    'cave'     = @{ f = 'lush_caves_fog_setting.json';                       t = 'render' }
    'nether'   = @{ f = 'hell_fog_setting.json';                             t = 'fixed'  }
    'end'      = @{ f = 'the_end_fog_setting.json';                          t = 'render' }
}
# valores vanilla medidos (air): start,end
$vanVals = @{
    'default' = @(0.92, 1.0); 'forest' = @(0.92, 1.0); 'cold' = @(0.92, 1.0)
    'mountain'= @(0.92, 1.0); 'hot' = @(0.92, 1.0); 'ocean' = @(0.92, 1.0)
    'swamp'   = @(0.92, 1.0); 'cave' = @(0.92, 1.0)
    'nether'  = @(10.0, 96.0); 'end' = @(0.92, 1.0)
}

$rows2 = @{}
foreach ($f in Get-ChildItem $fogDir -Filter *.json | Sort-Object Name) {
    $key = $f.BaseName
    $j = Get-Content -Raw -LiteralPath $f.FullName | ConvertFrom-Json
    $a = $j.'minecraft:fog_settings'.distance.air
    if (-not $a) { continue }
    if ($a.render_distance_type -eq 'fixed') {
        $b8 = '{0:N0}-{1:N0}' -f $a.fog_start, $a.fog_end
        $b16 = '{0:N0}-{1:N0}' -f $a.fog_start, $a.fog_end
    } else {
        $b8  = '{0:N0}-{1:N0}' -f ($a.fog_start * 8 * 16),  ($a.fog_end * 8 * 16)
        $b16 = '{0:N0}-{1:N0}' -f ($a.fog_start * 16 * 16), ($a.fog_end * 16 * 16)
    }
    $vr = $vanVals[$key]
    $vanTxt = if ($vanRef[$key].t -eq 'fixed') { '{0:N0}-{1:N0}' -f $vr[0], $vr[1] }
              else { '{0:N0}-{1:N0}' -f ($vr[0] * 16 * 16), ($vr[1] * 16 * 16) }
    Write-Host ("{0,-14} {1,-12} {2,-16} {3,-16} {4,-16}" -f $key, $a.render_distance_type, "$b8 b", "$b16 b", "$vanTxt b")

    $startB = if ($a.render_distance_type -eq 'fixed') { [double]$a.fog_start } else { [double]$a.fog_start * 16 * 16 }
    $rows2[$key] = $startB
}

Write-Host ""
$piso = @{ overworld = 40; nether = 5; end = 25 }
$dimOf = @{ nether = 'nether'; end = 'end' }
$minTxt = @()
foreach ($k in ($rows2.Keys | Sort-Object)) {
    $dim = if ($dimOf.ContainsKey($k)) { $dimOf[$k] } else { 'overworld' }
    $p = $piso[$dim]
    $mark = if ($rows2[$k] -lt $p) { 'ABAIXO DO PISO' } else { 'ok' }
    $minTxt += ('{0}={1:N0}b/{2} {3}' -f $k, $rows2[$k], $p, $mark)
}
Write-Host ("Alcance inicial a 16 chunks (piso por dimensao: Overworld 40, Nether 5, End 25):") -ForegroundColor Cyan
Write-Host ("  " + ($minTxt -join '  |  '))
$below = @($minTxt | Where-Object { $_ -match 'ABAIXO DO PISO' })
if ($below.Count -gt 0) { Write-Host ("  PERFILES ABAIXO DO PISO: " + ($below -join ', ')) -ForegroundColor Red }
else { Write-Host "  todos os perfis dentro do piso" -ForegroundColor Green }
Write-Host "  type 'fixed' nao muda com o render distance; type 'render' escala." -ForegroundColor DarkGray
Write-Host "  O vanilla usa 'fixed' no Nether e 'render' em todos os outros." -ForegroundColor DarkGray
foreach ($g in ($byProfile | Sort-Object Name)) {
    $first = $g.Group | Select-Object -First 1
    $rampa = $first.Rampa
    $nota = switch -Wildcard ($rampa) {
        'rampa*' { 'RAMPA VERTICAL - original deste pack, o vanilla nunca usa' }
        'uniforme*' { 'uniforme abaixo do teto - mesmo padrao do vanilla' }
        default { 'sem fog volumetric' }
    }
    Write-Host ("  {0,-16} {1,-34} {2}" -f $first.Perfil, $rampa, $nota) -ForegroundColor DarkGray
}

Write-Host "`n=== Referencia vanilla v1.26.50.4 ===" -ForegroundColor Cyan
foreach ($k in ($vanilla.Keys | Sort-Object)) {
    $v = $vanilla[$k]
    Write-Host ("  {0,-34} {1}" -f $k, $(if ($null -eq $v) { 'sem fog volumetric' } else { $v }))
}

Write-Host "`n=== Interpretacao ===" -ForegroundColor Cyan
Write-Host "  - Os 7 perfis de superficie usam RAMPA (zero > max_height). Soma zero"
Write-Host "    acima de zero_density_height e densidade maxima abaixo de max_density_height."
Write-Host "    O vanilla NAO usa rampa em nenhum dos seus 80 perfis."
Write-Host "  - cavern / nether / end usam alturas iguais (320): densidade UNIFORME na"
Write-Host "    altura, nao uma camada no chao. Uma caverna a Y=10 e igual a uma a Y=200."
Write-Host "  - Para bruma concentrada no chao seria necessario max_density_height > zero_density_height."
Write-Host "  - Estes valores sao calculados, nao medidos. Ver docs/compatibility.md secao 4.4." -ForegroundColor Yellow

if ($Csv) {
    $rows | Export-Csv -LiteralPath $Csv -NoTypeInformation -Encoding UTF8
    Write-Host "`nCSV gravado em $Csv" -ForegroundColor Green
}

exit 0
