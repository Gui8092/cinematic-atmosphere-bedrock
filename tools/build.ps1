<#
    build.ps1 — Valida e empacota o resource pack em dist\*.mcpack

    O .mcpack e um ZIP comum com manifest.json na RAIZ (sem pasta intermediaria).
    O script so empacota se validate.ps1 passar sem falhas.

    Uso:
      .\build.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputName = 'Cinematic_Atmosphere_Bedrock.mcpack'
)

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$pack    = Join-Path $root 'resource_pack'
$distDir = Join-Path $root 'dist'
$outFile = Join-Path $distDir $OutputName

Write-Host "`n=== 1/3  Validacao estatica ===" -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate.ps1')
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nBuild abortado: validate.ps1 reportou falhas. Nada foi empacotado." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== 2/3  Empacotamento ===" -ForegroundColor Cyan
if (-not (Test-Path $pack)) { throw "resource_pack nao encontrado em $pack" }
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
if (Test-Path $outFile) { Remove-Item $outFile -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# .NET Framework grava '\' como separador nas entradas do ZIP, o que viola a
# especificacao (o padrao e '/') e torna o .mcpack invalido. Criamos as entradas
# manualmente com '/' para garantir portabilidade.
$zipOut = [System.IO.Compression.ZipFile]::Open($outFile, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $files = @(Get-ChildItem $pack -Recurse -File | Sort-Object FullName)
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($pack.Length + 1).Replace('\', '/')
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zipOut, $f.FullName, $rel, [System.IO.Compression.CompressionLevel]::Optimal)
    }
    $packed = $files.Count
} finally {
    $zipOut.Dispose()
}

$info = Get-Item $outFile
Write-Host "Gerado: $($info.FullName)"
Write-Host ("Tamanho: {0:N0} bytes  ({1} arquivos)" -f $info.Length, $packed)

# --- 3. verificacao do pacote gerado
Write-Host "`n=== 3/3  Verificacao do pacote ===" -ForegroundColor Cyan
$zip = [System.IO.Compression.ZipFile]::OpenRead($outFile)
try {
    $entries = @($zip.Entries | Where-Object { $_.Name -ne '' })

    if ($entries.Count -ne $packed) {
        Write-Host "ERRO: esperado $packed entradas, encontrado $($entries.Count)" -ForegroundColor Red; exit 1
    }
    Write-Host "Contagem de entradas confere: $($entries.Count)" -ForegroundColor DarkGreen

    $bad = @($entries | Where-Object { $_.FullName.Contains('\') })
    if ($bad.Count -gt 0) {
        Write-Host "ERRO: $($bad.Count) entrada(s) com separador '\' — o ZIP exige '/'" -ForegroundColor Red
        $bad | Select-Object -First 3 | ForEach-Object { Write-Host "  $($_.FullName)" -ForegroundColor Red }
        exit 1
    }
    Write-Host "Separadores de caminho: todos '/' (conforme especificacao ZIP)" -ForegroundColor DarkGreen

    $dirs = @($entries | ForEach-Object { ($_.FullName -split '/')[0] } | Sort-Object -Unique)
    Write-Host "Diretorios no pacote: $($dirs -join ', ')"

    $mf = $entries | Where-Object { $_.FullName -eq 'manifest.json' }
    if ($mf) { Write-Host "manifest.json na raiz do zip" -ForegroundColor DarkGreen }
    else { Write-Host "ERRO: manifest.json nao esta na raiz do zip" -ForegroundColor Red; exit 1 }

    # nenhum diretorio de textura, modelo, som ou material
    $forbidden = @('textures/', 'models/', 'geometry/', 'sounds/', 'particles/', 'entity/', 'items/', 'ui/', 'pbr/', 'local_lighting/', 'point_lights/', 'shadows/')
    $leak = @($dirs | Where-Object { $forbidden -contains "$_" })
    if ($leak.Count -gt 0) { Write-Host "ERRO: diretorio proibido no pacote: $($leak -join ', ')" -ForegroundColor Red; exit 1 }
    Write-Host "Nenhum diretorio de textura/modelo/som/material no pacote" -ForegroundColor DarkGreen

    $jsonCount = @($entries | Where-Object { $_.FullName -like '*.json' }).Count
    $imgCount  = @($entries | Where-Object { $_.FullName -like '*.png' }).Count
    Write-Host "Conteudo: $jsonCount arquivos .json, $imgCount imagem(ns)"
} finally {
    $zip.Dispose()
}

$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $outFile).Hash
Write-Host "SHA256: $hash" -ForegroundColor DarkGray

Write-Host "`nBuild concluido." -ForegroundColor Green
Write-Host "Instalacao: clique duas vezes no .mcpack (o Minecraft Bedrock importa e abre a tela de Add-Ons)," -ForegroundColor DarkGray
Write-Host "ou Settings > Video settings > Graphics Mode > ative 'Vibrant Visuals' ANTES de criar o mundo." -ForegroundColor DarkGray
exit 0