# CHANGELOG

Todas as mudanças relevantes deste resource pack.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).
Versionamento do pack segue SemVer no `manifest.json`.

## [1.0.0] — 2026-10-05

Primeira release. Desenvolvida e validada **somente por análise estática** —
sem execução dentro do Minecraft.

### Adicionado

**Núcleo do pipeline Vibrant Visuals**
- `manifest.json` com capability `"pbr"` e `min_engine_version: [1, 26, 0]`.
- `pack_icon.png` gerado programaticamente (única imagem do pack).

**Iluminação — `resource_pack/lighting/` (10 arquivos)**
- `global.json` → `cba:lighting_overworld` (temperado)
- `forest.json` → `cba:lighting_forest` (copa densa, `sky.intensity` 0.62)
- `cold.json` → `cba:lighting_cold` (taiga/neve)
- `mountain.json` → `cba:lighting_mountain` (picos)
- `hot.json` → `cba:lighting_hot` (deserto/badlands/savana)
- `ocean.json` → `cba:lighting_ocean`
- `swamp.json` → `cba:lighting_swamp`
- `cave.json` → `cba:lighting_cave`
- `nether.json` → `cba:lighting_nether`
- `end.json` → `cba:lighting_end`
- Keyframes de 24 h em `sun.color`, `sun.illuminance`, `moon.*`, `ambient.*` e
  `sky.intensity`, com os **horários exatos do vanilla** (0.282 / 0.292 / 0.709 /
  0.719 etc.) para não dessincronizar o céu da posição solar real.

**Atmosfera — `resource_pack/atmospherics/` (5 arquivos)**
- `cba:atmos_overworld`, `cba:atmos_cold`, `cba:atmos_hot`, `cba:atmos_nether`,
  `cba:atmos_end` — Rayleigh/Mie, `sun_glare_shape` e `horizon_blend_stops`
  todos keyframados ao longo do dia.

**Color grading — `resource_pack/color_grading/` (7 arquivos)**
- `cba:cg_overworld`, `cba:cg_cold`, `cba:cg_hot`, `cba:cg_swamp`, `cba:cg_cave`,
  `cba:cg_nether`, `cba:cg_end`.
- Split-tone: `shadows` com viés frio, `highlights` com viés quente.
- `temperature` por família (3400 K no Nether a 8200 K na neve).
- `tone_mapping.operator: "aces"` em todos os 7 arquivos (decisão artística
  aprovada; não interpolável, portanto idêntico em todos).

**Fog — `resource_pack/fogs/` (10 arquivos)**
- `cba:fog_default`, `_forest`, `_cold`, `_mountain`, `_hot`, `_ocean`, `_swamp`,
  `_cave`, `_nether`, `_end`.
- Cada arquivo define `air`, `weather`, `water`, `lava`, `lava_resistance` e
  `volumetric.density.air` — é **autossuficiente de propósito**: a pilha de fog
  cai para o vanilla quando um campo falta, não para outro arquivo nosso.
- `henyey_greenstein_g` alto (0.80) em floresta para forward-scattering
  (feixes de luz).

**Água — `resource_pack/water/` (6 arquivos)**
- `cba:water_fresh`, `_ocean`, `_deep`, `_warm`, `_frozen`, `_swamp`.
- `particle_concentrations` por tipo de corpo d'água + `biome_water_color_contribution`.
- `caustics` ligado; **`waves.enabled: false`** em todos (decisão aprovada;
  o vanilla também usa `false`).
- `caustics` e `waves` idênticos nos 6 arquivos — são não interpoláveis.

**Cubemap — `resource_pack/cubemaps/` (1 arquivo)**
- `cba:cubemap_overworld`: faz as nuvens vanilla reagirem ao espalhamento
  atmosférico. **Não substitui a textura do céu.**

**Biomas — `resource_pack/biomes/` (89 arquivos)**
- Cobertura completa da lista oficial `Mojang/bedrock-samples@v1.26.50.4`.
- 16 famílias (T1–T14), atribuição completa em `tools/biome-map.ps1`.
- Cada arquivo **preserva verbatim** os componentes vanilla não-visuais
  (`ambient_sounds`, `biome_music`, `grass_appearance`, `foliage_appearance`,
  `dry_foliage_color`, `sky_color`, `water_appearance`) e substitui apenas os
  identificadores Vibrant Visuals. Nenhum som, música ou cor de bioma foi alterado.

**Ferramentas — `tools/`**
- `biome-map.ps1` — fonte única de verdade do mapeamento bioma → configuração.
- `generate-biomes.ps1` — regenera os 89 arquivos; `-RefreshVanilla` reimporta o
  baseline vanilla da tag fixada (requer internet).
- `validate.ps1` — 75 verificações estáticas.
- `build.ps1` — valida e empacota em `dist/`.

**Documentação — `docs/`**
- `research.md`, `compatibility.md`, `art-direction.md`, `inventory.md`.

### Decisões técnicas registradas

- **`min_engine_version: [1, 26, 0]`, sem fallback automático.** É o maior
  `format_version` usado pelo pack. Um valor menor (ex.: `[1, 21, 120]`, mínimo
  documentado para a capability `"pbr"`) permitiria ativar o pack em versões que
  não parseiam nossos arquivos, fazendo-o falhar em silêncio.
- **Todos os `orbital_offset_degrees` iguais a `2.5`.** O parâmetro não é
  interpolável; Originally o pack usava 3.5 nas montanhas e 0.0 no Nether/End, o
  que a validação rejeitou.
- **Ambiente do Nether com `sky.intensity: 0.1`** (mínimo do schema), não `0.0`.
- **Horários de keyframe copiados do vanilla**, em vez dos redondos 0.25/0.75.
- **Escala de `sun.illuminance` do vanilla** (máx. 100), não os 109880 lx dos
  exemplos da documentação.
- **`shadows/` omitido** — a documentação diz `shadows/global.json`, um pack de
  exemplo diz `shadows/shadows.json`, e o vanilla não tem a pasta. Sem caminho
  comprovado, e o padrão do jogo já é `soft_shadows`. Omitido com justificativa.
- **`local_lighting/` omitido** — opcional, sem precedente no vanilla em
  1.26.50.4, e cada entrada exigiria redeclarar `light_type` com risco de mudar a
  classificação das point lights do jogo. O mesmo efeito estético é obtido via
  `emissive.desaturation`.
- **`pbr/global.json` omitido** — mexeria em materiais de renderização, expressamente
  fora do escopo.

### Validação

- 75 verificações estáticas: **0 falhas, 0 avisos**.
- `.mcpack` gerado: 130 entradas, `manifest.json` na raiz, separadores `/`
  conformes à especificação ZIP, nenhum diretório de textura/modelo/som/material.
- **Testes visuais e de desempenho: NÃO executados** (exigem Minecraft instalado).

### Correções durante a implementação

Registradas porque afetam o artefato final:

1. **Separador de caminho no ZIP.** `ZipFile.CreateFromDirectory` do .NET
   Framework grava `\` nas entradas (bug conhecido; o padrão é `/`), o que
   tornaria o `.mcpack` inválido para leitores que seguem a especificação.
   `build.ps1` agora cria as entradas manualmente com `/` e **verifica** isso.
2. **`orbital_offset_degrees` divergente** (3.5 nas montanhas, 0.0 no Nether/End)
   — rejeitado pelo validador por ser não interpolável. Uniformizado em 2.5.
3. **`sky.intensity: 0.0` no Nether** — fora do intervalo documentado
   `[0.1, 1.0]`. Ajustado para 0.1.
4. **Codificação dos scripts.** PowerShell 5.1 lê `.ps1` como ANSI quando não há
   BOM, o que corrompia caracteres acentuados e causava erro de parsing. Todos os
   scripts foram gravados em UTF-8 **com BOM**.
5. **Formatação dos 89 arquivos de bioma.** `ConvertTo-Json` do PowerShell
   produz JSON com alinhamento massivo e ilegível. `generate-biomes.ps1` usa um
   serializador próprio com 2 espaços e ordem de chaves estável.

[1.0.0]: https://github.com/Mojang/bedrock-samples/tree/v1.26.50.4