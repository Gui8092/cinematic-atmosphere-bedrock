<#
    build.ps1 — Valida, empacota e verifica o resource pack em dist\*.mcpack

    O .mcpack e um ZIP comum com manifest.json na RAIZ (sem pasta intermediaria).
    O build so Conclusion se TODAS as etapas passarem:
      1. validate.ps1      — validacao estatica do source
      2. empacotamento     — ZIP com entradas '/'
      3. verify-package.ps1 — verificacao de seguranca do .mcpack gerado

    A etapa 3 e AUTONOMA: nao consulta validate.ps1 e nao le o resource_pack.
    Ela existe justamente para nao compartilhar ponto cego com a etapa 1.
   Os testes negativos dela ficam em tools\test-negative.ps1.

    Uso:  .\build.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputName = 'Cinematic_Atmosphere_Bedrock.mcpack',
    [switch]$SkipValidate
)

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$pack    = Join-Path $root 'resource_pack'
$distDir = Join-Path $root 'dist'
$outFile = Join-Path $distDir $OutputName

# --- 1. validacao estatica ---------------------------------------------------
# O artefato em dist/ NAO e verificado aqui: ele esta prestes a ser
# regenerado. A verificacao completa, incluindo o artefato, roda no passo 3.
Write-Host "`n=== 1/4  Validacao estatica (pre-empacotamento) ===" -ForegroundColor Cyan
if ($SkipValidate) {
    Write-Host "  (ignorada por -SkipValidate)" -ForegroundColor Yellow
} else {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate.ps1') -SkipArtifact
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nBuild abortado: validate.ps1 reportou falhas. Nada foi empacotado." -ForegroundColor Red
        exit 1
    }
}

# --- 2. empacotamento -------------------------------------------------------
Write-Host "`n=== 2/4  Empacotamento ===" -ForegroundColor Cyan
if (-not (Test-Path $pack)) { throw "resource_pack nao encontrado em $pack" }
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
if (Test-Path $outFile) { Remove-Item $outFile -Force }

# .NET Framework grava '\' como separador nas entradas do ZIP, o que viola a
# especificacao (o padrao e '/') e torna o .mcpack invalido para leitores que a
# seguem. As entradas sao criadas manualmente com '/'.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipOut = [System.IO.Compression.ZipFile]::Open($outFile, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $files = @(Get-ChildItem $pack -Recurse -File | Sort-Object FullName)
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($pack.Length + 1).Replace('\', '/')
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zipOut, $f.FullName, $rel, [System.IO.Compression.CompressionLevel]::Optimal)
    }
    $packed = $files.Count
} finally { $zipOut.Dispose() }

$info = Get-Item $outFile
Write-Host "Gerado : $($info.FullName)"
Write-Host ("Tamanho: {0:N0} bytes  ({1} arquivos)" -f $info.Length, $packed)

# --- 3. verificacao de seguranca do pacote -----------------------------------
Write-Host "`n=== 3/4  Verificacao de seguranca do pacote ===" -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'verify-package.ps1') `
    -Package $outFile -ExpectedEntries $packed
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nBuild abortado: verify-package.ps1 reprovou o pacote gerado." -ForegroundColor Red
    exit 1
}

# --- 4. validacao pos-empacotamento, agora incluindo o artefato --------------
Write-Host "`n=== 4/4  Validacao pos-empacotamento (inclui o artefato) ===" -ForegroundColor Cyan
if ($SkipValidate) {
    Write-Host "  (ignorada por -SkipValidate)" -ForegroundColor Yellow
} else {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate.ps1')
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nBuild abortado: o artefato gerado nao passou na validacao final." -ForegroundColor Red
        exit 1
    }
}

$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $outFile).Hash
Write-Host "`nSHA256: $hash" -ForegroundColor DarkGray
Write-Host "`nBuild concluido." -ForegroundColor Green
Write-Host "Instalacao: clique duas vezes no .mcpack e ative-o em Global Resources." -ForegroundColor DarkGray
Write-Host "Lembre: ative Vibrant Visuals ANTES (Settings > Video settings > Graphics Mode)." -ForegroundColor DarkGray
exit 0