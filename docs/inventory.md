# Inventário definitivo

Resolução da inconsistência documental entre a arquitetura inicial
(4 / 3 / 4 / 11) e a contagem revisada (10 / 5 / 7 / 10). Este é o
inventário **real** do projeto.

> Correção de origem: a arquitetura inicial especificava `shadows/`,
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
| `LICENSE` + `NOTICE` + `.gitignore` | 3 |
| `docs/` (4 documentos) | 4 |
| `tools/` (6 scripts + 1 baseline) | 7 |
| `dist/Cinematic_Atmosphere_Bedrock.mcpack` | 1 |
| **Subtotal do projeto** | **17** |
| **TOTAL** | **147** |

Pacote empacotado: **130 entradas** (129 `.json` + 1 `.png`), confirmado por
`tools\build.ps1` e `tools\verify-package.ps1`.

---

## 2. `resource_pack/`

### `manifest.json`
`format_version` 2 · capability `pbr` · `min_engine_version [1, 26, 50]` ·
UUIDs v4 distintos para header e módulo · `pack_scope: any`.

**Por que `1.26.50`:** `dappled_forest` usa `format_version` `1.26.50` na
referência oficial e o pack preserva o formato de cada bioma. O mínimo
coerente é a maior versão de formato efetivamente usada.

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

`format_version: 1.26.0` — necessário para keyframes de `ambient` e
`sky.intensity`. `global.json` ocupa o nome reservado e serve de default para
biomas sem atribuição explícita (inclusive biomas futuros).

### `atmospherics/` — 5 arquivos

| Arquivo | Identificador |
|---|---|
| `atmospherics.json` | `cba:atmos_overworld` |
| `cold.json` | `cba:atmos_cold` |
| `hot.json` | `cba:atmos_hot` |
| `nether.json` | `cba:atmos_nether` |
| `end.json` | `cba:atmos_end` |

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

| Arquivo | Identificador | `fog_start` (ar) | `max_density` | `zero` / `max_height` |
|---|---|---:|---:|---|
| `default.json` | `cba:fog_default` | 0.86 | 0.014 | 128 / 48 |
| `forest.json` | `cba:fog_forest` | 0.72 | 0.026 | 140 / 40 |
| `cold.json` | `cba:fog_cold` | 0.80 | 0.020 | 128 / 44 |
| `mountain.json` | `cba:fog_mountain` | 0.62 | 0.022 | 190 / 60 |
| `hot.json` | `cba:fog_hot` | 0.90 | 0.010 | 110 / 44 |
| `ocean.json` | `cba:fog_ocean` | 0.78 | 0.016 | 128 / 48 |
| `swamp.json` | `cba:fog_swamp` | 0.52 | 0.034 | 96 / 32 |
| `cave.json` | `cba:fog_cave` | 0.06 | 0.055 | 320 / 320 |
| `nether.json` | `cba:fog_nether` | 0.03 | 0.048 | 320 / 320 |
| `end.json` | `cba:fog_end` | 0.05 | 0.040 | 320 / 320 |

`format_version: 1.21.90` (volumétrico + `henyey_greenstein_g`).
Cada arquivo é **autossuficiente** (air, weather, water, lava,
lava_resistance, volumetric air) — a pilha de fog não herda entre arquivos
nossos; um campo ausente cairia no vanilla.

> **Rampa vertical:** apenas os 7 perfis de superfície usam
> `zero_density_height` ≠ `max_density_height`. Com alturas iguais (320), a
> densidade é **uniforme na altura**, não uma camada no chão. O vanilla nunca
> usa rampa — ver `docs/research.md` §14.

### `cubemaps/` — 1 arquivo

`overworld.json` → `cba:cubemap_overworld`. `format_version: 1.21.130`.
Ajusta a **iluminação** do cubemap vanilla (nuvens reagindo ao scattering).
Não substitui a textura do céu. **Só vale no Overworld.**

### `biomes/` — 89 arquivos

`identifier: "minecraft:<biome>"` e `format_version` **preservados da
referência oficial**:

| `format_version` | Quantidade | Biomas |
|---|---:|---|
| `1.21.120` | 87 | todos, exceto os dois abaixo |
| `1.26.0` | 1 | `sulfur_caves` |
| `1.26.50` | 1 | `dappled_forest` |

16 famílias, mapeamento completo em `tools\biome-map.ps1`:

| Família | Dim. | N | Cubemap | Biomas |
|---|---|---:|:--:|---|
| `temperate` | overworld | 14 | sim | plains, sunflower_plains, meadow, river, birch_forest(+hills,+mutated×2), forest, forest_hills, flower_forest, cherry_grove, mushroom_island, mushroom_island_shore |
| `forest` | overworld | 15 | sim | roofed_forest(+mutated), jungle(+edge/hills/mutated×3), bamboo_jungle(+hills), mega_taiga(+hills), redwood_taiga(+mutated/hills_mutated), grove, dappled_forest |
| `cold` | overworld | 11 | sim | taiga(+hills/mutated), cold_taiga(+hills/mutated), ice_plains, ice_plains_spikes, ice_mountains, frozen_river, snowy_slopes |
| `mountain` | overworld | 8 | sim | extreme_hills(+edge/mutated/plus_trees/plus_trees_mutated), jagged_peaks, stony_peaks, frozen_peaks |
| `hot` | overworld | 9 | sim | desert(+hills/mutated), mesa, mesa_bryce, mesa_plateau(+mutated/stone/stone_mutated) |
| `savanna` | overworld | 4 | sim | savanna, savanna_mutated, savanna_plateau, savanna_plateau_mutated |
| `beach` | overworld | 3 | sim | beach, stone_beach, cold_beach |
| `swamp` | overworld | 3 | sim | swampland(+mutated), mangrove_swamp |
| `cave` | overworld | 4 | sim | dripstone_caves, lush_caves, deep_dark, sulfur_caves |
| `pale_garden` | overworld | 1 | sim | pale_garden |
| `ocean_plain` | overworld | 2 | sim | ocean, cold_ocean |
| `ocean_warm` | overworld | 4 | sim | lukewarm_ocean, warm_ocean, deep_warm_ocean, deep_lukewarm_ocean |
| `ocean_frozen` | overworld | 3 | sim | frozen_ocean, deep_frozen_ocean, legacy_frozen_ocean |
| `ocean_deep` | overworld | 2 | sim | deep_ocean, deep_cold_ocean |
| `nether` | **nether** | 5 | **não** | hell, crimson_forest, warped_forest, basalt_deltas, soulsand_valley |
| `end` | **end** | 1 | **não** | the_end |
| | | **89** | | |

**Cobertura de cubemap:** 83 de 83 biomas do Overworld recebem
`cba:cubemap_overworld`; os 5 do Nether e o do End nunca. Regra verificada pelo
validador nos dois sentidos.

Cada arquivo reproduz verbatim, a partir de `tools\vanilla-baseline.json`, os
componentes vanilla fora do escopo visual: `minecraft:ambient_sounds`,
`minecraft:biome_music`, `minecraft:water_appearance`,
`minecraft:grass_appearance`, `minecraft:foliage_appearance`,
`minecraft:dry_foliage_color`, `minecraft:sky_color`, `minecraft:precipitation`.

---

## 3. `tools/`

| Arquivo | Função | Rede |
|---|---|:--:|
| `biome-map.ps1` | Fonte única de verdade: identificadores, 16 famílias, versões aceitas por tipo, regra de cubemap, tag da referência | não |
| `vanilla-baseline.json` | Baseline transcrito: `format_version` por bioma + componentes a preservar. Declara repositório, tag e licença | não |
| `generate-biomes.ps1` | Gera os 89 arquivos a partir do mapa + baseline; `-SyncBaseline` reimporta a referência | só com `-SyncBaseline` |
| `validate.ps1` | 73 verificações estáticas (`-CheckOfficial` adiciona 2) | não (opcional) |
| `verify-package.ps1` | Verificação de segurança do `.mcpack`, **autônoma** | não |
| `test-negative.ps1` | 29 testes negativos que provam que o verificador reprova | não |
| `build.ps1` | Valida → empacota → verifica | não |

Todos gravados em **UTF-8 com BOM** — obrigatório para o PowerShell 5.1
decodificar corretamente os acentos.

---

## 4. `docs/` e raiz

| Arquivo | Conteúdo |
|---|---|
| `LICENSE` | MIT com **escopo delimitado**; exclui os valores transcritos |
| `NOTICE` | Procedência, as 5 categorias de conteúdo, citações do EULA, limitação declarada |
| `docs/research.md` | Pesquisa, fontes, fatos vs inferências, fog, versionamento, cubemap, licenciamento |
| `docs/compatibility.md` | Compatibilidade, riscos, estado dos testes, checklist visual |
| `docs/art-direction.md` | Direção artística, curva de 24 h, split-tone, o caso das cavernas |
| `docs/inventory.md` | Este documento |

---

## 5. Omitido, e por quê

| Item | Motivo | Prejudica o objetivo principal? |
|---|---|---|
| `shadows/` | A documentação diz `shadows/global.json`; um pack de exemplo diz `shadows/shadows.json`; o vanilla em 1.26.50.4 **não tem a pasta**. Sem caminho comprovado. O padrão do jogo já é `soft_shadows` | **Não** |
| `local_lighting/` | Documentado, mas **sem precedente no vanilla 1.26.50.4**. Cada entrada exigiria redeclarar `light_type`, com risco de mudar a classificação das point lights do jogo. Mesmo efeito por `emissive.desaturation` | **Não** |
| `pbr/global.json` | Alteraria materiais de renderização — fora do escopo. O valor vanilla equivalente é um no-op | **Não** |
| `waves` ligadas | Decisão artística aprovada: preserva a animação de textura original do Minecraft | **Não** — receita no `README.md` §5 |
| Texturas / modelos / sons / UI | Fora do escopo por definição | **Não** |
| Behavior Pack / scripts | Fora do escopo por definição | **Não** |
| Variante para modo clássico | Desnecessária: as mesmas `fogs` e os mesmos `client_biome` já funcionam nos dois pipelines | **Não** |

---

## 6. Como conferir este inventário

```powershell
.\tools\validate.ps1
```

O validador compara contagem e conteúdo de cada diretório contra as
expectativas deste documento, confere a cobertura de 89 biomas em **três lados**
(mapa ↔ baseline ↔ disco), reprova qualquer divergência de `format_version`
contra a referência oficial e falha se algum identificador referenciado não
existir.