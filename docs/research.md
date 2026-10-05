# Pesquisa técnica

Data da pesquisa: **2026-10-05**. Este documento registra o que foi verificado,
em qual fonte, e o que é **fato documentado** versus **inferência**.

Todas as afirmações sobrevanilla foram verificadas lendo os arquivos reais do
repositório oficial [`Mojang/bedrock-samples`](https://github.com/Mojang/bedrock-samples),
release estável **`v1.26.50.4`** (publicado 2026-09-16, `prerelease: false`).

---

## 1. Ambiente gráfico

### 1.1 O que é Vibrant Visuals

Fato. Pipeline de renderização baseado em PBR com *deferred lighting*.
Ativado em *Settings → Video settings → Graphics Mode*, onde o dropdown vira um
checklist com a opção **Vibrant Visuals**. É **cross-platform** — o ray tracing
RTX é que é restrito a dispositivos RTX.

- <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/introvibrantvisuals>

### 1.2 Como declarar um pack de Vibrant Visuals

Fato. Capability `"pbr"` no `manifest.json` + `min_engine_version >= [1, 21, 120]`.

- <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/vvresourcepacks>

> O guia de Resource Packs introdutório do portal ainda descreve um tutorial de
> textura (`dirt.png`), não os JSONs de iluminação. Os documentos de Vibrant
> Visuals são a referência correta para este projeto.

### 1.3 Numeração de versões

Fato. A partir de **1.26.0** os releases passaram a ser numerados por ano
(`26.x`). Cita literal das notas oficiais:

> "Welcome to 1.26.0 – the first release following Minecraft's new version
> numbering system! … For the purposes of APIs and the platform, and because
> this is what is used within various JSON files, we'll continue to use
> **1.26.xx.yyz** versioning here."
> — <https://learn.microsoft.com/en-us/minecraft/creator/documents/update1.26.0>

**Prova de que `min_engine_version` continua no formato vetor `1.26.x`** — o
manifesto do próprio pack vanilla em `v1.26.50.4`:

```json
"min_engine_version": [ 1, 26, 50 ]
```

### 1.4 Qual é a versão estável

- **1.26.50.x** — release estável mais recente (`v1.26.50.4`, 2026-09-16).
- **1.26.60.x** — apenas *preview* (`v1.26.60.29-preview`, 2026-10-02,
  `prerelease: true`).
- A wiki lista `26.52` como o build estável mais recente; a tag da Mojang é
  `v1.26.50.4`. **Incerteza:** build interno vs. tag. Irrelevante para o pack,
  porque o maior `format_version` que usamos é `1.26.0`.

---

## 2. A descoberta que definiu a arquitetura

Fato, citação literal de *Per-Biome Customization*:

> "As of this update, biome-specific settings included in the Vanilla base game
> pack now take precedence over both the built-in global default values **and any
> global Vibrant Visual JSON files provided by custom packs**."

— <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/biomecustomization>

**Consequência:** um pack só com `lighting/global.json` e
`atmospherics/atmospherics.json` é **silenciosamente ignorado**. É obrigatório
sobrescrever os 89 `*.client_biome.json`.

Nomes de arquivo reservados (função de default global):

| Arquivo | Componente que recebe automaticamente |
|---|---|
| `lighting/global.json` | `minecraft:lighting_identifier` |
| `atmospherics/atmospherics.json` | `minecraft:atmosphere_identifier` |
| `color_grading/color_grading.json` | `minecraft:color_grading_identifier` |
| `water/water.json` | `minecraft:water_identifier` |

---

## 3. Componentes de client_biome

Fato. Lista oficial completa (14), de
<https://learn.microsoft.com/en-us/minecraft/creator/reference/content/clientbiomesreference/examples/componentlist>:

`ambient_sounds`, `atmosphere_identifier`, `biome_music`,
`color_grading_identifier`, `cubemap_identifier`, `dry_foliage_color`,
`fog_appearance`, `foliage_appearance`, `grass_appearance`,
`lighting_identifier`, `precipitation`, `sky_color`, `water_appearance`,
`water_identifier`.

> A página *Client Biomes Overview* lista só 7 componentes e está desatualizada
> frente a esta lista e frente ao vanilla em 1.26.50.4. Não foi usada.

### 3.1 Como o vanilla escreve esses arquivos

Fato, lendo `Mojang/bedrock-samples@v1.26.50.4/resource_pack/biomes/`:

```json
{
  "format_version": "1.21.120",
  "minecraft:client_biome": {
    "description": { "identifier": "minecraft:plains" },
    ...
```

- `format_version` é **`1.21.120`** (não `1.21.70` como nos exemplos da doc).
- O `identifier` é **namespaced**: `minecraft:plains`, não `plains`.
  A nota de 1.26.0 confirma a importância do namespace:
  "Biomes without a namespace in `biomes_client.json` will be applied to worlds
  below `base_game_version` 1.21.40 with the default namespace."
- `sulfur_caves.client_biome.json` (bioma novo) usa `format_version: "1.26.0"`.

**Decisão:** seguimos o vanilla — `1.21.120` e `minecraft:<biome>`.

### 3.2 Merge entre resource packs: NÃO DOCUMENTADO

Não há documentação sobre como dois `*.client_biome.json` com o mesmo
`identifier` combinam entre packs — nem por arquivo, nem por componente.
Pesquisa na API de documentação do portal não retornou nada.

**Mitigação escolhida:** reescrever cada arquivo vanilla aplicando a **alteração
mínima** — preservando verbatim todo componente não-visual
(`ambient_sounds`, `biome_music`, `grass_appearance`, `foliage_appearance`,
`dry_foliage_color`, `sky_color`, `water_appearance`) e trocando apenas os
identificadores Vibrant Visuals. Assim, mesmo que o arquivo seja substituído
inteiro, nada de som, música ou cor de bioma se perde.

Isto é **inferência defensiva**, não fato documentado. Se o motor realmente
mesclar por componente, o resultado é o mesmo.

---

## 4. Fog — semântica real de `zero_density_height`

Fato, pela referência de fog:
<https://learn.microsoft.com/en-us/minecraft/creator/documents/foginresourcepacks>

- `max_density`: multiplicador sobre quanto a névoa atrapalha a luz.
  `0.0` = sem névoa, `1.0` = quase opaca.
- `uniform`: densidade uniforme em todas as alturas.
- `zero_density_height`: **altura em blocos onde a névoa começa a aparecer.**
- `max_density_height`: **altura em blocos onde a névoa atinge `max_density`.**

São um **perfil vertical de densidade em Y absoluto**. Não existe nenhum campo
que detecte "a câmera está confinada" ou "o jogador está subterrâneo".

### 4.1 Como o vanilla usa esses campos

Fato, lendo `v1.26.50.4/resource_pack/fogs/`:

| Arquivo | `max_density` | `zero_density_height` | `max_density_height` |
|---|---|---|---|
| `default_fog_setting.json` | *(sem bloco `volumetric`)* | — | — |
| `dry_fog_setting.json` | **0.0** | 320.0 | 320.0 |
| `humid_fog_setting.json` | 0.05 | 320.0 | 320.0 |
| `lush_caves_fog_setting.json` | 0.05 | 320.0 | 320.0 |
| `sulfur_cave_fog_setting.json` | 0.07 | 320.0 | 320.0 |

Os dois valores são **sempre iguais** — rampa de altura zero. Ou seja, a Mojang
os usa como **teto + interruptor on/off**, não como gradiente de profundidade.
`default_fog_setting` **não tem fog volumétrico**: no vanilla, um túnel sob
planícies tem **zero** névoa.

**Conclusão:** a atmosfera de caverna vem do **bioma na posição do jogador**, e
`dripstone_caves`, `lush_caves`, `deep_dark` e `sulfur_caves` são os únicos
biomas de caverna. Um túnel sob planícies continua sendo `plains`.

### 4.2 Pilha de fog e herança

Fato. Ordem de precedência: **Command > Biomes > Data Default > Engine Default**.
Se um fog da pilha não define o tipo atual, "the game will continue checking
down the stack".

**Armadilha evitada:** um `cba:fog_cold` que só defina `distance.air` **não**
herda de `cba:fog_default` — cai no vanilla. Por isso **cada arquivo nosso é
autossuficiente** (air, weather, water, lava, lava_resistance e volumetric air).

### 4.3 Absorção só em luminância

Fato, de *Volumetric Fog and Light Shafts*: "in Vibrant Visuals, volumes only
operate at a single channel of granularity, and the engine calculates the
standard luminance of the specified RGB value".

```
Luminance = 0.2126·R + 0.7152·G + 0.0722·B
```

O `absorption: [0.25, 0.125, 0.125]` do `sulfur_caves` vanilla vira um único
≈ 0.152 — **o verde se perde**. Por isso as cavernas deste pack são
"esverdeadas" via `distance.air.fog_color` e color grading, nunca por
absorption.

### 4.4 `henyey_greenstein_g`

Fato. Disponível a partir de `format_version 1.21.90`, faixa `[-1.0, 1.0]`.
Positivo = forward-scattering (luz através da névoa em direção ao observador —
é o que produz **feixes de luz**). Padrão do jogo: 0.75 no ar, 0.6 na água.

---

## 5. Keyframes

Fato, de *Key Frame JSON Syntax*. Qualquer valor anotado `optkeyframe` aceita:

```json
"illuminance": { "0.0": 100.0, "0.25": 20.0, "0.5": 1.0, "1.0": 100.0 }
```

- Chave = hora do dia: `0.0` meio-dia, `0.25` pôr do sol, `0.5` meia-noite,
  `0.75` nascer do sol, `1.0` próximo meio-dia.
- Interpolação **linear**; suporta float e cor (RGB ou hex).
- `ambient.illuminance`, `ambient.color` e `sky.intensity` só passaram a aceitar
  keyframe em **1.26.0** — por isso `lighting/*.json` usa `format_version 1.26.0`.

### 5.1 Os horários redondos estão errados

Fato, lendo `v1.26.50.4/resource_pack/lighting/global.json`. O vanilla **não usa
0.25/0.75** para o nascer/pôr do sol:

```
sun.illuminance : 0.000000→100  0.050000→100  0.282000→1  0.291500→0.01
                  0.292000→0    0.709000→0    0.719000→1  0.950000→100
sun.color       : 0.140811  0.216944  0.242908  0.269504  0.314561
                  0.506998  0.717949  0.801062  1.000000
moon.illuminance: 0.225→0.4   0.735→0.4   (resto 0)
```

O sol se põe por volta de **0.282** e nasce em **0.719** — assimétrico em
relação ao meio-dia, e muito diferente de 0.25/0.75.

**Decisão:** o pack **adota os horários exatos do vanilla como esqueleto** e só
remedia amplitudes e cores. Chavear em 0.25/0.75 deixaria o horizonte dourado
com o sol ainda alto.

### 5.2 Escala de `illuminance`

Fato, mas divergente entre doc e vanilla. A documentação diz que o sol ao
meio-dia mede "upwards of 100,000 lux" e o exemplo usa `109880.0`. O vanilla usa
**100**. Este pack usa a **escala do vanilla** e modula por multiplicador.
Divergência registrada, sem tentativa de reconciliação.

---

## 6. Parâmetros não interpoláveis

Fato, de *Per-Biome Customization*:

> "Tone mapping operators cannot be blended. … Orbital offset degrees cannot be
> blended. … Caustics cannot be blended. … Waves enabled/disabled cannot be
> blended. All color grading and tone mapping schemas in a given pack should use
> the same tone mapping operator."

Interpoláveis, por outro lado: **atmospherics, color grading, cubemaps e
lighting** (por posição da câmera) e **water** (por geometria).

`validate.ps1` verifica os quatro parâmetros não interpoláveis. Foi ele que
rejeitou um `orbital_offset_degrees` de 3.5 nas montanhas — hoje todos os 10
arquivos usam **2.5**.

---

## 7. Componentes opcionais — o que foi omitido e por quê

### 7.1 `shadows/` — OMITIDO

Divergência real entre fontes:
- Documentação: **"configured by the `shadows/global.json` file"**.
- Pack de exemplo da Microsoft: `shadows/shadows.json`.
- **Vanilla em 1.26.50.4: a pasta `shadows/` não existe.**

Sem caminho comprovado. E o padrão do jogo já é `soft_shadows`
("If a pack does not customize the shadow stylization, then soft shadows will be
used by default"), enquanto `blocky_shadows` seria uma regressão para a estética
original. Omitido conforme a instrução de não incluir caminhos não comprovados.

### 7.2 `local_lighting/` — OMITIDO

Documentação confirma o caminho (`local_lighting/local_lighting.json`,
`format_version 1.21.120`, renomeado de `point_lights/global.json`), mas o
**vanilla em 1.26.50.4 não tem a pasta** — não há precedente para confirmar
vigência. Além disso, cada entrada precisaria redeclarar `light_type`, com risco
de mudar a classificação de point lights que o jogo já define. O mesmo efeito
estético (tom quente nas tochas) é obtido por `emissive.desaturation`, que é um
campo validado do schema de `lighting` que já usamos.

### 7.3 `pbr/global.json` — OMITIDO

Mexeria em materiais de renderização — explicitamente fora do escopo. O valor
vanilla equivalente (`[0,0,255,0]`) é um no-op.

### 7.4 `cubemaps/` — INCLUÍDO

Documentação com schema completo e exemplo explícito
(`cubemaps/mycubemap.json`, `format_version 1.21.130`) e componente
`minecraft:cubemap_identifier` na lista oficial. **Só ajusta a iluminação do
cubemap existente — não substitui a textura do céu**, que é proibido pelo escopo.
Limitação registrada: **só funciona no Overworld**; o End usa seu cubemap
embutido. Por isso `cubemap_identifier` não é atribuído a nenhum bioma do
Nether nem ao End (`validate.ps1` verifica isso).

---

## 8. Valor do vanilla como linha de base

Fato. Os valores deste pack derivam dos arquivos reais do vanilla, não de
exemplos da documentação:

| Conceito | Vanilla 1.26.50.4 | Aqui |
|---|---|---|
| `sun.illuminance` máx. | 100 | 92–118 por família |
| `sun.illuminance` nos zeros do crepúsculo | 0.292 / 0.709 | idênticos |
| Escala do luar | 0.4 | 0.26–0.42 |
| Cor do luar | `[163,182,255]` | `[168,196,255]` (mais fria) |
| `ambient` | `#FFFFFF` @ 0.02 | 0.009–0.050, **sempre com cor** |
| `sky.intensity` | 1.0 | 0.42–1.0 |
| `emissive.desaturation` | 0.0 | 0.05–0.16 |
| Color grading midtones | contrast 1.15, sat 1.05 | contrast 1.10–1.22, sat 0.94–1.03 |
| `waves.enabled` | **false** | **false** |
| `caustics` | power 1, scale 0.5, frame 0.09 | idênticos (não interpolável) |
| Rayleigh Strength | 10.0 / 5.0 | 10.0 → 2.2 à noite |
| `rayleigh_strength` no End | 50.0 | 34.0 |
| `rayleigh_strength` no Nether | 0.15 | 0.15 |
| Teto do fog volumétrico | 320.0 | 190.0 (montanha) a 320.0 |

---

## 9. Desempenho — o que a documentação diz

Fato, citações:

- Point lights: "*considerably more resource-intensive*"; limitados por
  disponibilidade de recursos; "*Analytic/point lights will now phase in or out
  according to their importance to the scene's lighting*".
- Tone mapping filmico: "*they come at a higher performance cost compared to the
  non-filmic variants*".
- `waves.octaves` até 30, "*high values result in more complex waves*".
- Névoa volumétrica usa "*a terrain-aware volumetric representation of the world*".

**Mitigações aplicadas:** nenhum point light novo; `waves` desligado;
`caustics` com os parâmetros do vanilla; densidades de ar entre 0.010 e 0.055
(o vanilla chega a 0.07 em `sulfur_caves`); `zero_density_height` alto para que a
névoa seja **exatamente zero** na maior parte do ar de superfície.

**Não medido.** Nenhuma afirmação de FPS em lugar nenhum.

---

## 10. Fontes

**Documentação oficial**
- Creator: <https://learn.microsoft.com/en-us/minecraft/creator/>
- Resource packs: <https://learn.microsoft.com/en-us/minecraft/creator/documents/resourcepack>
- Fog reference: <https://learn.microsoft.com/en-us/minecraft/creator/reference/content/fogsreference/fogs>
- Fog in resource packs: <https://learn.microsoft.com/en-us/minecraft/creator/documents/foginresourcepacks>
- Vibrant Visuals: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/>
- Intro VV: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/introvibrantvisuals>
- VV Resource Packs: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/vvresourcepacks>
- Light Sources: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/lightingcustomization>
- Atmospheric Effects: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/atmosphericscustomization>
- Volumetric Fog / Light Shafts: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/volumetricfoglightshaftscustomization>
- Color Grading: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/colorgradingtonemappingcustomization>
- Water Effects: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/watercustomization>
- Shadows: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/shadowscustomization>
- Cubemaps: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/cubemapcustomization>
- Per-Biome: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/biomecustomization>
- Key Frame Syntax: <https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/keyframejsonsyntax>
- Client Biomes (lista): <https://learn.microsoft.com/en-us/minecraft/creator/reference/content/clientbiomesreference/examples/componentlist>
- manifest.json: <https://learn.microsoft.com/en-us/minecraft/creator/reference/content/addonsreference/packmanifest>
- Notas 1.26.0: <https://learn.microsoft.com/en-us/minecraft/creator/documents/update1.26.0>
- Notas 1.26.40: <https://learn.microsoft.com/en-us/minecraft/creator/documents/update1.26.40>

**Fontes primárias de dados**
- Pack vanilla oficial `v1.26.50.4`:
  <https://github.com/Mojang/bedrock-samples/tree/v1.26.50.4/resource_pack>
- Pack de exemplo da Microsoft (referência secundária, desatualizado):
  <https://github.com/microsoft/minecraft-samples/tree/main/deferred_lighting_starter>
- Notas de numeração de versão: <https://aka.ms/MinecraftVersionUpdate>
- Histórico de versões Bedrock (wiki, **fonte secundária**):
  <https://minecraft.wiki/w/Bedrock_Edition_version_history>