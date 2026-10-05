<#
    verify-package.ps1 — Verificacao de seguranca e estrutura de um .mcpack.

    Autonomo: nao depende de validate.ps1 e nao precisa do resource_pack em disco.
    Opera sobre o arquivo .mcpack real, lendo os nomes de entrada do ZIP.

    Verifica:
      - manifest.json presente na RAIZ do zip
      - todos os separadores de caminho usando '/'
      - ausencia de diretorios fora do escopo (texturas, modelos, sons, ...)
      - ausencia de extensoes fora do escopo (script, audio, modelo 3D, imagem)
      - whitelist estrita de caminhos
      - contagem de entradas conferida com o esperado (quando informado)
      - integridade do CRC de todas as entradas

    Uso:
      .\verify-package.ps1 -Package <arquivo.mcpack> [-ExpectedEntries <n>]

    Saida: 0 = aprovado, 1 = reprovado (com motivo no console).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Package,
    [int]$ExpectedEntries = 0
)

$ErrorActionPreference = 'Stop'

# --- listas de escopo --------------------------------------------------------
$forbiddenSegments = @(
    'textures', 'models', 'geometry', 'sounds', 'particles', 'entity', 'entities',
    'items', 'ui', 'animations', 'animation_controllers', 'attachables',
    'render_controllers', 'blocks', 'texts', 'pbr', 'local_lighting',
    'point_lights', 'shadows', 'behavior_pack', 'scripts', 'script'
)
$forbiddenExt = @(
    '.js', '.mjs', '.cjs', '.ts', '.py', '.lua', '.jar', '.class', '.dll', '.exe',
    '.ogg', '.wav', '.mp3', '.nbs', '.mcpack', '.mcaddon', '.mcworld',
    '.obj', '.fbx', '.gltf', '.glb', '.tga', '.jpg', '.jpeg', '.bmp'
)
$allowedRootFiles = @('manifest.json', 'pack_icon.png')
$allowedDirs = @('biomes', 'atmospherics', 'color_grading', 'water', 'fogs', 'lighting', 'cubemaps')
$allowedImages = @('pack_icon.png')

if (-not (Test-Path -LiteralPath $Package)) { Write-Host "ERRO: pacote nao encontrado: $Package" -ForegroundColor Red; exit 1 }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$violations = New-Object System.Collections.Generic.List[string]
$zip = [System.IO.Compression.ZipFile]::OpenRead($Package)
try {
    $entries = @($zip.Entries | Where-Object { $_.Name -ne '' })

    if ($entries.Count -eq 0) { $violations.Add('pacote vazio: nenhuma entrada') }

    # separador de caminho
    foreach ($e in $entries) {
        if ($e.FullName.Contains('\')) {
            $violations.Add("separador '\' (o padrao ZIP exige '/'): $($e.FullName)")
        }
        if ($e.FullName.StartsWith('/')) { $violations.Add("caminho absoluto em $($e.FullName)") }
        if ($e.FullName -match '\.\.') { $violations.Add("caminho com '..' em $($e.FullName)") }
    }

    # manifest na raiz
    if (-not ($entries | Where-Object { $_.FullName -eq 'manifest.json' })) {
        $violations.Add('manifest.json ausente na raiz do zip')
    }

    # escopo de conteudo
    foreach ($e in $entries) {
        $segments = @($e.FullName -split '/')
        $top = $segments[0]

        if ($forbiddenSegments -contains $top) {
            $violations.Add("diretorio proibido '$top': $($e.FullName)")
            continue
        }

        $ext = [System.IO.Path]::GetExtension($e.FullName).ToLowerInvariant()
        if ($forbiddenExt -contains $ext) {
            $violations.Add("extensao proibida '$ext': $($e.FullName)")
            continue
        }

        if ($segments.Count -eq 1) {
            if ($allowedRootFiles -notcontains $top) {
                $violations.Add("arquivo nao autorizado na raiz: $($e.FullName)")
            }
        } else {
            if ($allowedDirs -notcontains $top) {
                $violations.Add("diretorio nao autorizado '$top': $($e.FullName)")
                continue
            }
            if ($top -eq 'cubemaps' -and $segments.Count -gt 2) {
                $violations.Add("subdiretorio unexpectedo em cubemaps: $($e.FullName)")
            }
            $allowedExt = if ($top -eq 'cubemaps') { @('.json') } else { @('.json') }
            if ($allowedExt -notcontains $ext) {
                $violations.Add("extensao nao autorizada em '$top/': $($e.FullName)")
            }
        }

        if (@('.png', '.gif', '.svg', '.webp') -contains $ext -and $allowedImages -notcontains $e.FullName) {
            $violations.Add("imagem nao autorizada: $($e.FullName)")
        }
    }

    # integridade das entradas (CRC)
    foreach ($e in $entries) {
        try {
            $s = $e.Open()
            $buf = New-Object byte[] 8192
            while ($s.Read($buf, 0, $buf.Length) -gt 0) { }
            $s.Dispose()
        } catch {
            $violations.Add("falha ao ler (CRC) entrada $($e.FullName): $($_.Exception.Message)")
        }
    }

    if ($ExpectedEntries -gt 0 -and $entries.Count -ne $ExpectedEntries) {
        $violations.Add("contagem de entradas $($entries.Count), esperado $ExpectedEntries")
    }

    $jsonCount = @($entries | Where-Object { $_.FullName -like '*.json' }).Count
    $imgCount = @($entries | Where-Object { $_.FullName -like '*.png' }).Count
} finally {
    $zip.Dispose()
}

Write-Host ""
Write-Host "verify-package: $Package" -ForegroundColor Cyan
Write-Host "  entradas   : $entries"
Write-Host "  .json      : $jsonCount"
Write-Host "  imagens    : $imgCount"

if ($violations.Count -gt 0) {
    Write-Host "  RESULTADO  : REPROVADO ($($violations.Count) violacoes)" -ForegroundColor Red
    $violations | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "  RESULTADO  : APROVADO" -ForegroundColor Green
Write-Host "  manifest.json na raiz, separadores '/', conteudo dentro do escopo, CRC integro" -ForegroundColor DarkGray
exit 0