# CHANGELOG

Todas as mudanças relevantes deste resource pack.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).
Versionamento do pack segue SemVer no `manifest.json`.

## [1.0.2] — 2026-10-05

Resolução das pendências que **não** dependem de execução no Minecraft.
**Nenhuma alteração visual ou direção artística.**

### Pendência 2 resolvida — `local_lighting/` validado

O motivo da omissão era "sem precedente no vanilla". A pesquisa refutou isso:

- A documentação oficial define o caminho, o schema e o `format_version`
  `1.21.120`.
- Um schema JSON independente confirma `light_type` como **obrigatório**, com
  enum `static_light` | `point_light`.
- O template `vv_local_lighting.jsont` da ferramenta Anvil gera esse arquivo.
- dozens de packs reais o utilizam, incluindo `Vanilla-Vibrant-Visuals`.

**O caminho é válido.** A omissão passou a ser uma **decisão artística** — e não
mais uma incerteza técnica. Como incluir mudaria a cor das tochas e lanternas, o
arquivo continua **não incluído**, mas agora com uma **receita pronta e validada**
no `README.md` §5.

### Pendência sobre densidade de fog — agora auditável

`tools/fog-report.ps1` (novo) calcula a densidade efetivo do fog em 11 alturas
representativas e compara com as densidades medidas do vanilla `v1.26.50.4`.
Torna a rampa vertical **auditável sem o jogo**, o que era impossível antes.

A saída confirma o que a auditoria já indicava:

- `cave`, `nether`, `end` → densidade **uniforme** até Y=320 (padrão do vanilla)
- 7 perfis de superfície → **rampa vertical**, que o vanilla nunca usa
- `fog_default` a Y=40 = 0.014, contra 0.05 do `humid` vanilla

### Pendência sobre licença — opção sem valor transcrito

`generate-biomes.ps1 -Minimal` gera os 89 biomas contendo **apenas** os 6
identificadores Vibrant Visuals — zero valores transcritos da referência oficial.

O tradeoff está documentado no cabeçalho do script e no `README.md` §5: se o
motor **substituir** o `client_biome` vanilla em vez de mesclar por componente
—a documentação não esclarece — os biomas perderiam som, música e cores. O modo
padrão continua seguro nas duas hipóteses.

### Pendência de codificação — causa raiz corrigida

O PowerShell 5.1 lê `.ps1` **sem BOM** como ANSI. Isso já causou um erro real de
parsing neste projeto.

- `.editorconfig` (novo) declara `charset = utf-8-bom` para `*.ps1`
- `.gitattributes` (novo) normaliza fim de linha para LF e marca `*.mcpack` como
  binário
- `validate.ps1` agora **verifica** que todo `.ps1` tem exatamente um BOM, e
  alerta sobre `.json` com CRLF

### Adicionado ao validador

| Verificação | Motivo |
|---|---|
| Todo `.ps1` em UTF-8 **com BOM** | O bug acima passou despercebido duas vezes |
| `.mcpack` em `dist/` tem a mesma versão do source | Detecta artefato desatualizado |
| `min_engine_version` do pacote = do source | Idem |
| `manifest.json` do pacote equivalente ao do source (normalizado) | Idem |
| `.json` do pack usam LF | Consistente com `.gitattributes` |
| Contagem de perfis com rampa vertical vs uniformes | Torna explícito o que diverge do vanilla |

**Validação: 73 → 80 verificações.**

### Bugs encontrados durante esta rodada

1. `core.autocrlf = true` reescreveu o working tree com CRLF após um
   `git reset --hard`, deixando o `manifest.json` do source divergente do que
   estava no `.mcpack`. A verificação nova detectou. Comparação ajustada para
   normalizar fim de linha (CRLF → LF), já que isso não altera o comportamento
   no jogo, e o working tree foi normalizado para LF.

2. Um script de normalização que escrevi aplicou **BOM duplo**
   (`EF BB BF EF BB BF`) em 6 scripts PowerShell, quebrando o parsing de todos
   eles. Corrigido, e a verificação de BOM agora exige **exatamente um**.

3. **A verificação de versão do artefato não funcionava.** Escrevi
   `$a -join '.' -eq $b -join '.'`, e por precedência entre `-join` e `-eq` a
   comparação retornava o resultado errado: com o source em `9.9.9` e o pacote em
   `1.0.2`, ela aprovava. Só percebi porque forcei uma divergência proposital.
   Corrigido com parênteses explícitos e **testado nos dois sentidos**.

Os três bugs são do mesmo tipo: verificações escritas sem prova de que falham.
Por isso o `test-negative.ps1` existe e é obrigatório passar.

### Também

- Descrição do repositório GitHub corrigida com acentuação correta
- 8 topics adicionados: `minecraft`, `minecraft-bedrock`, `resource-pack`,
  `vibrant-visuals`, `lighting`, `atmosphere`, `color-grading`,
  `volumetric-fog`

### Validação

| Execução | Verificações | Falhas | Avisos |
|---|---:|---:|---:|
| `validate.ps1` (offline) | 80 | 0 | 0 |
| `validate.ps1 -CheckOfficial` | 82 | 0 | 0 |
| `test-negative.ps1` | 29 | 0 | 0 |

`.mcpack`: 130 entradas, CRC íntegro, APROVADO.

### Pendente

**Testes visuais e de desempenho continuam NÃO executados** — dependem do
Minecraft instalado. Ver `docs/compatibility.md` §4.4.

---

## [1.0.1] — 2026-10-05

Correção de auditoria. **Cinco defeitos reais encontrados e corrigidos**,
um deles de natureza legal. Nenhuma decisão artística foi alterada.

### Corrigido

**1. Declaração de licença incorreta (grave)**
A v1.0.0 declarava MIT para o repositório inteiro. Isso estava errado: os 89
`*.client_biome.json` incorporam valores transcritos de
`Mojang/bedrock-samples@v1.26.50.4`, cuja licença é
*"(c) Mojang AB. All rights reserved — sujeito ao Minecraft EULA"*.

- `LICENSE` reescrito com **escopo do MIT delimitado** e exclusão explícita dos
  valores transcritos.
- `NOTICE` criado: atribuição, fonte, tag, as **5 categorias** de conteúdo
  pedidas, citações do EULA e a limitação declarada de que **não é parecer
  jurídico**.
- `README.md` e `docs/research.md` §11 corrigidos — a afirmação anterior de que
  "todos os arquivos de configuração são gerados originalmente" era uma
  **exageragem**.

Investigação: o EULA proíbe distribuir **assets** ("Do not distribute or make
commercial use of anything we've made"). Este repositório **não contém nenhum
asset** — nem textura, modelo, som, geometria ou partícula. O que há são
identificadores (bioma, evento de som, faixa de música) e literais hexadecimais,
que não são criação autoral.

**2. `format_version` rebaixado nos arquivos de bioma**
O gerador aplicava `1.21.120` a todos. A referência oficial usa **três**
formatos: `1.21.120` (87 biomas), `1.26.0` (`sulfur_caves`) e `1.26.50`
(`dappled_forest`). Rebaixar pode mudar a interpretação do schema ou fazer o
motor rejeitar propriedades.

- O gerador agora **preserva o formato de cada bioma**.
- `min_engine_version` subiu de `[1, 26, 0]` para `[1, 26, 50]`, o mínimo
  coerente com o maior formato efetivamente usado. Sem fallback.
- O validador reprova qualquer divergência contra a referência.

**3. Cobertura de cubemap incompleta**
As famílias `hot`, `savanna` e `cave` não recebiam `cba:cubemap_overworld`,
embora **todas sejam do Overworld** — única dimensão onde a customização de
cubemap é válida. Era inconsistência sem justificativa técnica.

- Regra explícita por dimensão: Overworld **deve** receber (83 de 83 agora);
  Nether e End **nunca**.
- O validador deixou de checar "alguns casos proibidos" e passou a exigir
  cobertura completa **e** ausência total nas outras dimensões.

**4. Verificação de diretórios proibidos no empacotador nunca disparava**
`build.ps1` extraía nomes como `textures` e comparava com uma lista contendo
`textures/`. As strings nunca coincidiam — **a verificação não detectava nada**.

- `verify-package.ps1` criado: verificador **autônomo**, que opera sobre o
  `.mcpack` real e não divide lógica com o `validate.ps1`.
- Detecta diretórios proibidos, extensões proibidas (script, áudio, modelo 3D,
  imagem), violações de whitelist, `manifest.json` fora da raiz, separadores `\`,
  caminhos com `..` e CRC corrompido.
- `test-negative.ps1` criado com **29 casos** que provam que o verificador
  **reprova** cada tipo de violação. Sem ele, um verificador que nunca falha
  pareceria correto.

**5. Documentação do fog imprecisa**
A auditoria tabulou os 80 perfis de fog volumétrico do vanilla e encontrou que
**nenhum** usa rampa vertical: `zero_density_height` e `max_density_height` são
sempre iguais (320.0).

- Corrigida a afirmação de que a bruma em cavernas "cresce com a profundidade".
  Com alturas iguais a densidade é **uniforme na altura**.
- Documentado que a rampa dos perfis de superfície é um desenho **original**,
  não um padrão do vanilla, e **ainda não verificado em jogo**.
- Acrescentada comparação quantitativa com o vanilla: `fog_default` a 0.014 é
  **28%** do `humid` vanilla (0.05); `fog_end` a 0.040 é **16%** do `the_end`
  vanilla (0.25). Um vale baixo não fica com névoa excessiva.
- Teste C10 adicionado: confirmar que cavernas a Y=10 e Y=200 são idênticas.

### Adicionado

- `tools\vanilla-baseline.json` — baseline transcrito da referência oficial, com
  `format_version` por bioma e componentes a preservar. Declara repositório, tag,
  data e licença.
- `tools\verify-package.ps1` — verificação de segurança do `.mcpack`.
- `tools\test-negative.ps1` — 29 testes negativos.
- `NOTICE` — procedência e licenciamento.
- `validate.ps1 -CheckOfficial` — comparação opcional com a referência oficial
  viva, com degradação correcta quando não há rede.

### Alterado

- `tools\biome-map.ps1` — `Dimension` por família; regra de cubemap; conjunto de
  `format_version` aceitos por tipo; helper para carregar o baseline.
- `tools\generate-biomes.ps1` — reescrito. Gera a partir do baseline (**offline**
  por padrão); `-RefreshVanilla` passou a `-SyncBaseline`; valida que mapa e
  baseline têm os mesmos 89 biomas; valida que todo componente preservado no
  baseline está na lista de preservação.
- `tools\build.ps1` — delega a verificação a `verify-package.ps1`.
- `tools\validate.ps1` — cobertura em **três lados** (mapa ↔ baseline ↔ disco);
  verificação de `format_version` por bioma contra a referência; comparação de
  componentes preservados contra o baseline; regra de cubemap explícita;
  `min_engine_version` comparado com o maior formato usado.
- `resource_pack\manifest.json` — versão `1.0.1`, `min_engine_version` `1.26.50`.

### Corrigido durante a própria auditoria

- `test-negative.ps1` usava `-EsperarAprovar=$true`, que o PowerShell entrega
  como `False` para parâmetros `[bool]`. A suíte reportava **29 falhas falsas**.
  Corrigido para a sintaxe com dois-pontos (`-EsperarAprovar:$true`) e a
  mensagem de falha foi corrigida.
- `validate.ps1` lia `sky.intensity` incorretamente quando o valor era numérico,
  produzindo `0` e 10 falsos positivos.

### Validação

| Execução | Verificações | Falhas | Avisos |
|---|---:|---:|---:|
| `validate.ps1` (offline) | 73 | 0 | 0 |
| `validate.ps1 -CheckOfficial` | 75 | 0 | 0 |
| `validate.ps1 -CheckOfficial` sem rede | 73 | 0 | 1 (aviso) |
| `test-negative.ps1` | 29 | 0 | 0 |

`.mcpack`: 130 entradas, CRC íntegro, `verify-package.ps1` APROVADO.

### Não alterado (decisõeswartísticas preservadas)

`tone_mapping.operator = "aces"`, color grading naturalista e contido,
`waves.enabled = false`, nenhuma textura substituída, nenhum modelo/material/som
alterado, nenhum Behavior Pack ou script, Vibrant Visuals como pipeline
prioritário, configurações por bioma e dimensão, documentação do modo clássico.

### Pendente

**Testes visuais e de desempenho continuam NÃO executados.** Requerem o
Minecraft instalado. Ver `docs/compatibility.md` §4.4.

---

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