# Inventário definitivo

Resolução da inconsistência documental entre a arquitetura inicial
(4 / 3 / 4 / 11) e a contagem revisada (10 / 5 / 7 / 10). Este é o
inventário **real** do projeto.

> Correção de origem: a arquitetura inicial specify `shadows/`,
> `local_lighting/` e `pbr/` sem caminho comprovado. As três foram **omitidas**
> com justificativa — ver § 5.

## 1. Totais

| Grupo | Arquivos |
|---|---:|
| `manifest.json` + `pack_icon.png` | 2 |
| `lighting/` | 10 |
| `atmospherics/` | 5 |
| `color_grading/` | 7 |
| `water/` | 6 |
| `fogs/` | 10 |
| `cubemaps/` | 1 |
| `biomes/` | 89 |
| **Subtotal do `resource_pack/`** | **130** |
| `README.md` + `CHANGELOG.md` | 2 |
| `LICENSE` + `.gitignore` | 2 |
| `docs/` (4 documentos) | 4 |
| `tools/` (4 scripts) | 4 |
| `dist/Cinematic_Atmosphere_Bedrock.mcpack` | 1 |
| **Subtotal do projeto** | **13** |
| **TOTAL** | **143** |

Pacote empacotado: **130 entradas** (129 `.json` + 1 `.png`), confirmado por
`tools/build.ps1`.

---

## 2. `resource_pack/`

### `manifest.json`
`format_version` 2 · capability `pbr` · `min_engine_version [1, 26, 0]` ·
UUIDs v4 distintos para header e módulo · `pack_scope: any`.

### `lighting/` — 10 arquivos

| Arquivo | Identificador | Família | `sky.intensity` |
|---|---|---|---:|
| `global.json` | `cba:lighting_overworld` | Temperado | 1.0 |
| `forest.json` | `cba:lighting_forest` | Floresta densa | 0.62 |
| `cold.json` | `cba:lighting_cold` | Taiga / neve | 0.92 |
| `mountain.json` | `cba:lighting_mountain` | Montanhas | 0.88 |
| `hot.json` | `cba:lighting_hot` | Deserto / badlands / savana | 1.0 |
| `ocean.json` | `cba:lighting_ocean` | Oceanos | 1.0 |
| `swamp.json` | `cba:lighting_swamp` | Pântano | 0.58 |
| `cave.json` | `cba:lighting_cave` | Cavernas | 0.42 |
| `nether.json` | `cba:lighting_nether` | Nether | 0.1 |
| `end.json` | `cba:lighting_end` | End | 0.3 |

`format_version: 1.26.0` — necessário para keyframes de `ambient` e `sky.intensity`.
`global.json` ocupa o nome reservado e serve de default para biomas sem
atribuição explícita (incluindo biomas futuros).

### `atmospherics/` — 5 arquivos

| Arquivo | Identificador | Usado por |
|---|---|---|
| `atmospherics.json` | `cba:atmos_overworld` | T1, T2, T4, T7–T11, T9 |
| `cold.json` | `cba:atmos_cold` | T3, T14 |
| `hot.json` | `cba:atmos_hot` | T5, T6 |
| `nether.json` | `cba:atmos_nether` | T12 |
| `end.json` | `cba:atmos_end` | T13 |

`format_version: 1.21.40`.

### `color_grading/` — 7 arquivos

| Arquivo | Identificador | Temperatura | Contraste |
|---|---|---:|---:|
| `color_grading.json` | `cba:cg_overworld` | 6500 K | 1.12 |
| `cold.json` | `cba:cg_cold` | 8200 K | 1.10 |
| `hot.json` | `cba:cg_hot` | 7200 K | 1.14 |
| `swamp.json` | `cba:cg_swamp` | 6600 K | 1.12 |
| `cave.json` | `cba:cg_cave` | 5200 K | 1.22 |
| `nether.json` | `cba:cg_nether` | 3400 K | 1.18 |
| `end.json` | `cba:cg_end` | 4600 K | 1.20 |

`format_version: 1.21.90` (`temperature` foi adicionado nessa versão).
`tone_mapping.operator: "aces"` em todos — não interpolável, portanto
obrigatoriamente idêntico.

### `water/` — 6 arquivos

| Arquivo | Identificador |
|---|---|
| `water.json` | `cba:water_fresh` |
| `ocean.json` | `cba:water_ocean` |
| `deep_ocean.json` | `cba:water_deep` |
| `warm.json` | `cba:water_warm` |
| `frozen.json` | `cba:water_frozen` |
| `swamp.json` | `cba:water_swamp` |

`format_version: 1.26.0` (`biome_water_color_contribution`).
`caustics` e `waves` **idênticos nos 6** — não interpoláveis.
`waves.enabled: false` em todos (também é o padrão do vanilla).

### `fogs/` — 10 arquivos

| Arquivo | Identificador | `fog_start` (ar) | `max_density` |
|---|---|---:|---:|
| `default.json` | `cba:fog_default` | 0.86 | 0.014 |
| `forest.json` | `cba:fog_forest` | 0.72 | 0.026 |
| `cold.json` | `cba:fog_cold` | 0.80 | 0.020 |
| `mountain.json` | `cba:fog_mountain` | 0.62 | 0.022 |
| `hot.json` | `cba:fog_hot` | 0.90 | 0.010 |
| `ocean.json` | `cba:fog_ocean` | 0.78 | 0.016 |
| `swamp.json` | `cba:fog_swamp` | 0.52 | 0.034 |
| `cave.json` | `cba:fog_cave` | 0.06 | 0.055 |
| `nether.json` | `cba:fog_nether` | 0.03 | 0.048 |
| `end.json` | `cba:fog_end` | 0.05 | 0.040 |

`format_version: 1.21.90` (volumétrico + `henyey_greenstein_g`).
**Cada arquivo é autossuficiente** (air, weather, water, lava, lava_resistance,
volumetric air) — a pilha de fog não herda entre arquivos nossos.

### `cubemaps/` — 1 arquivo

`overworld.json` → `cba:cubemap_overworld`. `format_version: 1.21.130`.
Ajusta a **iluminação** do cubemap vanilla (nuvens reagindo ao scattering).
Não substitui a textura do céu. Só vale no Overworld.

### `biomes/` — 89 arquivos

`format_version: 1.21.120`, `identifier: "minecraft:<biome>"` — ambos copiados
do vanilla `v1.26.50.4`.

16 famílias, mapeamento completo em `tools/biome-map.ps1`:

| Família | N | Biomas |
|---|---:|---|
| `temperate` | 14 | plains, sunflower_plains, meadow, river, birch_forest(+hills,+mutated×2), forest, forest_hills, flower_forest, cherry_grove, mushroom_island, mushroom_island_shore |
| `forest` | 15 | roofed_forest(+mutated), jungle(+edge/hills/mutated×3), bamboo_jungle(+hills), mega_taiga(+hills), redwood_taiga(+mutated/hills_mutated), grove, **dappled_forest** |
| `cold` | 11 | taiga(+hills/mutated), cold_taiga(+hills/mutated), ice_plains, ice_plains_spikes, ice_mountains, frozen_river, snowy_slopes |
| `mountain` | 8 | extreme_hills(+edge/mutated/plus_trees/plus_trees_mutated), jagged_peaks, stony_peaks, frozen_peaks |
| `hot` | 9 | desert(+hills/mutated), mesa, mesa_bryce, mesa_plateau(+mutated/stone/stone_mutated) |
| `savanna` | 4 | **savanna, savanna_mutated, savanna_plateau, savanna_plateau_mutated** |
| `beach` | 3 | beach, stone_beach, cold_beach |
| `swamp` | 3 | swampland(+mutated), mangrove_swamp |
| `cave` | 4 | dripstone_caves, lush_caves, deep_dark, **sulfur_caves** |
| `pale_garden` | 1 | pale_garden |
| `ocean_plain` | 2 | ocean, cold_ocean |
| `ocean_warm` | 4 | lukewarm_ocean, warm_ocean, deep_warm_ocean, deep_lukewarm_ocean |
| `ocean_frozen` | 3 | frozen_ocean, deep_frozen_ocean, legacy_frozen_ocean |
| `ocean_deep` | 2 | deep_ocean, deep_cold_ocean |
| `nether` | 5 | hell, crimson_forest, warped_forest, basalt_deltas, soulsand_valley |
| `end` | 1 | the_end |
| | **89** | |

Cada arquivo **preserva verbatim** todos os componentes vanilla não-visuais
(`ambient_sounds`, `biome_music`, `grass_appearance`, `foliage_appearance`,
`dry_foliage_color`, `sky_color`, `water_appearance`) e substitui apenas os
identificadores Vibrant Visuals.

---

## 3. `tools/`

| Arquivo | Função | Rede |
|---|---|:--:|
| `biome-map.ps1` | Fonte única de verdade: identificadores, 16 famílias, lista de biomas, tag vanilla de referência | não |
| `generate-biomes.ps1` | Regenera os 89 arquivos; `-RefreshVanilla` reimporta o baseline | só com `-RefreshVanilla` |
| `validate.ps1` | 75 verificações estáticas | não |
| `build.ps1` | Valida e empacota em `dist/` | não |

Todos gravados em **UTF-8 com BOM** — obrigatório para o PowerShell 5.1
decodificar corretamente os acentos.

---

## 4. `docs/`

| Arquivo | Conteúdo |
|---|---|
| `research.md` | Pesquisa, fontes, fatos vs inferências, semântica real do fog |
| `compatibility.md` | Matriz de compatibilidade, riscos, estado dos testes, checklist visual |
| `art-direction.md` | Direção artística, curva de 24 h, split-tone, o caso das cavernas |
| `inventory.md` | Este documento |

---

## 5. Omitido, e por quê

| Item | Motivo | Prejudica o objetivo principal? |
|---|---|---|
| `shadows/` | A documentação diz `shadows/global.json`; um pack de exemplo diz `shadows/shadows.json`; o vanilla em 1.26.50.4 **não tem a pasta**. Sem caminho comprovado. O padrão do jogo já é `soft_shadows`, então omitir não custa nada | **Não** |
| `local_lighting/` | Documentado, mas **sem precedente no vanilla 1.26.50.4**. Cada entrada exigiria redeclarar `light_type`, com risco de mudar a classificação das point lights do jogo. O mesmo efeito é obtido por `emissive.desaturation` | **Não** |
| `pbr/global.json` | Alteraria materiais de renderização — explicitamente fora do escopo. O valor vanilla equivalente é um no-op | **Não** |
| `waves` ligadas | Decisão artística aprovada: preserva a animação de textura original do Minecraft | **Não** — receita no `README.md` § 5 |
| Texturas / modelos / sons / UI | Fora do escopo por definição | **Não** |
| Behavior Pack / scripts | Fora do escopo por definição | **Não** |
| Variante para modo clássico | Desnecessária: as mesmas `fogs` e os mesmos `client_biome` já funcionam nos dois pipelines | **Não** |

---

## 6. Como conferir este inventário

```powershell
.\tools\validate.ps1
```

O validador compara a contagem e o conteúdo de cada diretório contra as
expectativas deste documento, confere a cobertura exata de 89 biomas contra
`tools/biome-map.ps1` e falha se algum identificador referenciado não existir.