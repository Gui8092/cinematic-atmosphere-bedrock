<#
    test-negative.ps1 — Testes negativos de verify-package.ps1.

    Um verificador de seguranca que nunca falha e inutil. Este script constroi
    pacotes .mcpack sinteticos com conteudo proibido e exige que
    verify-package.ps1 REPROVE cada um deles. Se o verificador aprovar um
    pacote invalido, este script falha.

    Nao toca no resource_pack real: tudo acontece em um diretorio temporario.

    Uso:  .\test-negative.ps1
    Saida: 0 = todos os testes passaram, 1 = alguma falha.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$verify = Join-Path $PSScriptRoot 'verify-package.ps1'
if (-not (Test-Path $verify)) { throw "verify-package.ps1 nao encontrado em $verify" }

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("cba-negtest-" + [guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null

$script:Pass = 0
$script:FailCount = 0

function New-TestZip {
    param([string]$Name, [hashtable]$Files)
    $zipPath = Join-Path $tmpRoot "$Name.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($k in $Files.Keys) {
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $zip, $Files[$k], $k, [System.IO.Compression.CompressionLevel]::Optimal)
        }
    } finally { $zip.Dispose() }
    return $zipPath
}

# Escreve arquivos de fixture em disco
function New-FixtureFile {
    param([string]$Relative, [string]$Content = '{}')
    $p = Join-Path $tmpRoot "fixture\$Relative"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $p) | Out-Null
    [System.IO.File]::WriteAllText($p, $Content, (New-Object System.Text.UTF8Encoding($false)))
    return $p
}

function Test-Case {
    param([string]$Nome, [hashtable]$Files, [bool]$EsperarAprovar = $false, [int]$ExpectedEntries = 0)

    $zip = New-TestZip -Name $Nome -Files $Files
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $verify -Package $zip -ExpectedEntries $ExpectedEntries 2>&1
    $code = $LASTEXITCODE
    $aprovou = ($code -eq 0)

    # Passa quando o resultado real coincide com o esperado:
    #   EsperarAprovar=$false -> o verificador deve reprovar ($aprovou = $false)
    #   EsperarAprovar=$true  -> o verificador deve aprovar  ($aprovou = $true)
    if ($aprovou -eq $EsperarAprovar) {
        # esperado reprovar e reprovou  -> OK
        # esperado aprovar e aprovou  -> OK
        $script:Pass++
        Write-Host "  [ok]   $Nome -> $(if($aprovou){'aprovado'}else{'reprovado'}) (conforme esperado)" -ForegroundColor DarkGreen
    } else {
        $script:FailCount++
        $motivo = if ($EsperarAprovar) { 'APROVADO (deveria ser reprovado)' } else { 'REPROVADO (deveria ser aprovado)' }
        Write-Host "  [FAIL] $Nome -> $(if($aprovou){'aprovado'}else{'reprovado'}) — $motivo" -ForegroundColor Red
        $out | Select-Object -First 6 | ForEach-Object { Write-Host "         $_" -ForegroundColor DarkRed }
    }
}

Write-Host "`n=== verify-package.ps1 — testes negativos ===" -ForegroundColor Cyan
Write-Host "fixture em: $tmpRoot`n" -ForegroundColor DarkGray

$okManifest = New-FixtureFile 'ok/manifest.json' '{"format_version":2}'
$okIcon     = New-FixtureFile 'ok/pack_icon.png' 'fake'
$okBiome    = New-FixtureFile 'ok/biomes/plains.client_biome.json' '{}'
$okFog      = New-FixtureFile 'ok/fogs/default.json' '{}'

# --- caso positivo: pacote legitimo deve ser aprovado -----------------------
Write-Host "Controle positivo:" -ForegroundColor Cyan
# ATENCAO: use a sintaxe com DOIS PONTOS para parametros [bool].
#   -EsperarAprovar=$true  ->  chega como False (silenciosamente errado)
#   -EsperarAprovar:$true  ->  chega como True  (correto)
Test-Case -Nome 'pacote-valido' -EsperarAprovar:$true -ExpectedEntries 4 -Files @{
    'manifest.json' = $okManifest; 'pack_icon.png' = $okIcon
    'biomes/plains.client_biome.json' = $okBiome; 'fogs/default.json' = $okFog
}

# --- casos negativos: cada um DEVE ser reprovado ---------------------------
Write-Host "`nDiretorios proibidos (devem reprovar):" -ForegroundColor Cyan
$dirCases = @{
    'textures' = 'ok/dirt.png'; 'models' = 'ok/entity.json'; 'geometry' = 'ok/g.json'
    'sounds' = 'ok/sound.json'; 'particles' = 'ok/p.json'; 'entity' = 'ok/zombie.json'
    'items' = 'ok/diamond.json'; 'ui' = 'ok/u.json'; 'pbr' = 'ok/global.json'
    'local_lighting' = 'ok/ll.json'; 'shadows' = 'ok/shadows.json'; 'render_controllers' = 'ok/rc.json'
}
foreach ($d in $dirCases.Keys) {
    $f = New-FixtureFile "neg/$d/arquivo.txt" 'x'
    Test-Case -Nome "dir-proibido-$d" -Files @{
        'manifest.json' = $okManifest; 'pack_icon.png' = $okIcon
        "$d/arquivo.txt" = $f
    }
}

Write-Host "`nExtensoes proibidas (devem reprovar):" -ForegroundColor Cyan
$extCases = @{
    'js' = 'behavior.js'; 'py' = 'script.py'; 'exe' = 'run.exe'
    'ogg' = 'step.ogg'; 'wav' = 'step.wav'; 'mcpack' = 'outro.mcpack'
    'glb' = 'model.glb'; 'tga' = 'tex.tga'; 'jpg' = 'tex.jpg'
}
foreach ($e in $extCases.Keys) {
    $f = New-FixtureFile "neg/ext/arquivo.$e" 'x'
    Test-Case -Nome "ext-proibida-$e" -Files @{
        'manifest.json' = $okManifest; 'pack_icon.png' = $okIcon
        "biomes/arquivo.$e" = $f
    }
}

Write-Host "`nWhitelist / estrutura (devem reprovar):" -ForegroundColor Cyan
$img = New-FixtureFile 'neg2/textures_extra/block.png' 'x'
Test-Case -Nome 'imagem-nao-autorizada' -Files @{
    'manifest.json' = $okManifest; 'pack_icon.png' = $okIcon; 'biomes/extra.png' = $img
}
Test-Case -Nome 'arquivo-nao-autorizado-na-raiz' -Files @{
    'manifest.json' = $okManifest; 'pack_icon.png' = $okIcon; 'readme.txt' = $img
}
Test-Case -Nome 'manifest-fora-da-raiz' -Files @{
    'biomes/manifest.json' = $okManifest; 'pack_icon.png' = $okIcon
}
Test-Case -Nome 'diretorio-desconhecido' -Files @{
    'manifest.json' = $okManifest; 'pack_icon.png' = $okIcon; 'extras/x.json' = $okFog
}
Test-Case -Nome 'subdiretorio-em-cubemaps' -Files @{
    'manifest.json' = $okManifest; 'pack_icon.png' = $okIcon; 'cubemaps/sub/x.json' = $okFog
}
Test-Case -Nome 'contagem-entries-errada' -ExpectedEntries 99 -Files @{
    'manifest.json' = $okManifest; 'pack_icon.png' = $okIcon
}
Test-Case -Nome 'pacote-vazio' -Files @{ }

Write-Host "`n--- resumo ---"
Write-Host "  aprovados : $script:Pass"
Write-Host "  falhas    : $script:FailCount" -ForegroundColor $(if ($script:FailCount) { 'Red' } else { 'Green' })

Remove-Item $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue

if ($script:FailCount -gt 0) { exit 1 } else { exit 0 }