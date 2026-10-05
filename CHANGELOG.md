# CHANGELOG

Todas as mudanças relevantes deste resource pack.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).
Versionamento do pack segue SemVer no `manifest.json`.

## [1.2.0] — 2026-10-05

Auditoria contra a **documentação oficial do Mojang** e o sistema de água. Nenhuma
textura, modelo, som, material ou bioma alterado. Nenhuma decisão de direção de
arte tomada — este release é sobre **spec e medição**.

## 17 faixas oficiais que não eram conferidas

Os schemas em `Mojang/bedrock-samples@v1.26.50.4/documentation/` declaram faixas
numéricas explícitas. Nenhuma era validada:

| Parâmetro | Faixa oficial | Antes |
|---|---|---|
| `highlightsMin` | 1.0 – 4.0 | não conferido |
| `shadowsMax` | 0.1 – 1.0 | não conferido |
| `sky.intensity` | 0.1 – 1.0 | não conferido |
| `emissive.desaturation` | 0.0 – 1.0 | não conferido |
| `ambient.illuminance` | 0.0 – 5.0 | parcial |
| `caustics.frame_length` | 0.01 – 5.0 | não conferido |
| `caustics.scale` | 0.1 – 5.0 | não conferido |
| `waves.depth` | 0.0 – 3.0 | não conferido |
| `waves.frequency` | 0.01 – 3.0 | não conferido |
| `waves.frequency_scaling` | 0.0 – 2.0 | não conferido |
| `waves.mix` | 0.0 – 1.0 | não conferido |
| `waves.octaves` | 1 – 30 | não conferido |
| `waves.pull` | −1.0 – 1.0 | não conferido |
| `waves.shape` | 1.0 – 10.0 | não conferido |
| `waves.speed` | 0.01 – 10.0 | não conferido |
| `waves.speed_scaling` | 0.0 – 2.0 | não conferido |
| `waves.direction_increment` | 0.0 – 360.0 | não conferido |

Mais dois enums: `temperature.type` (`color_temperature` \| `white_balance`) e
`tone_mapping.operator` (6 valores). Agora **158 valores** em 16 parâmetros são
conferidos.

`waves.direction_increment` é o único que o pack não usa — e o check reporta
isso explicitamente como omissão opcional, não como falha silenciosa.

### Corrigido: `offset` estava sendo validado contra uma faixa errada

O script usava `[-1, 1]`; a documentação diz **`[0.0, 4.0]`** e descreve offset
como "an exponential factor". Somos mais estritos, e isso fica registrado em vez
de silencioso.

## 21 offsets fora do spec foram removidos

Os 7 arquivos de color grading usavam `offset` **negativo** (−0,014 a +0,016)
para alcanzar o lado frio das sombras. Pela documentação, offset vai de 0.0 a 4.0
e é um fator exponencial — negativo não tem significado. O vanilla nunca usa
offset (`midtones.offset: [0,0,0,0,0,0]`).

**Nada se perde.** O split-tone continua inteiro pelo `gain`, que está em faixa
válida e é o mecanismo que efetivamente carrega o efeito — vermelho > azul nas
highlights, azul > vermelho nas shadows, em todos os 7 perfis. Os offsets eram
0,002 a 0,016 numa escala de 0 a 4, ou seja 0,05% a 0,4%.

## Corrigido: o oceano fundo era mais turvo que a superfície

`water/deep_ocean.json` tinha `suspended_sediment: 0.15`, **maior** que
`ocean`'s 0.10 — o fundo seria mais lama que a beira-mar. Corrigido para 0.08.
Diferença pequena o suficiente para ser invisível, mas a direção estava errada.

Foi encontrado pelo check novo, não por leitura.

## Descoberta: o vanilla **não** diferencia raso de fundo

Cinco pares de biomas usam **exatamente a mesma** `water_appearance.surface_color`:

| Raso | Fundo | Cor |
|---|---|---|
| `ocean` | `deep_ocean` | `#1787D4` |
| `cold_ocean` | `deep_cold_ocean` | `#2080C9` |
| `warm_ocean` | `deep_warm_ocean` | `#02B0E5` |
| `lukewarm_ocean` | `deep_lukewarm_ocean` | `#0D96DB` |
| `frozen_ocean` | `deep_frozen_ocean` | `#2570B5` |

A profundidade é carregada inteiramente pelas configurações de água, via
`biome_water_color_contribution` e as concentrações de partícula. Por isso o
validador agora **exige** que o perfil `deep` tenha contribuição e sedimento
menores que `ocean` e `warm` — sem isso, raso e fundo seriam indistinguíveis.

## Sobre a calibração de `water_appearance.surface_color`

**Não foi alterada.** E a conclusão honesta é que não precisava.

A `surface_color` é um *tint* iluminado pelo sol: quanto mais saturada a luz,
mais o tint se revela. A correção de sol da v1.1.0 levou o spread do pôr do sol de
**151 para 208** (vanilla: 255) — ou seja, **a calibração da água foi resolvida
indiretamente**, pelo fix do sol. Alterar 89 cores sem poder ver o resultado
seria trocar medição por chute.

Em vez disso, **`tools/water-report.ps1`** torna o sistema auditável offline:

- a física dos 6 perfis (cdom, clorofila, sedimento, contribuição)
- a tabela perfil × cor de superfície com luminância, spread e calor
- três sinais de revisão: tints muito saturados, pares raso/fundo, perfil
  congelado com tint quente
- a relação com o spread do sol, que é o acoplamento não observável offline

O relatório também mostra uma inversão de sedimento que **não é erro**: `fresh`
cobre rios e lagos, que são siltosos (sedimento 0.8 com contribuição 0.25, contra
0.1 e 0.30 do oceano aberto). Menos tint, mais lama. A inversão é o design.

## Testes negativos

12 parâmetros fora de faixa foram injetados, **alterando todos os arquivos de cada
tipo** para que o check de uniformidade passasse e só o de faixa pudesse pegar:

| Injetado | Detectado |
|---|---|
| `sky.intensity = 0.05` | `cave.json: sky.intensity = 0,05 fora da faixa oficial [0,1, 1]` |
| `emissive.desaturation = 1.5` | `fora da faixa oficial [0, 1]` |
| `ambient.illuminance = 9.5` (keyframe) | `ambient.illuminance[0.000000] fora de [0.0, 5.0]` |
| `highlightsMin = 0.5` | `fora da faixa oficial [1, 4]` |
| `shadowsMax = 0.05` | `fora da faixa oficial [0,1, 1]` |
| `waves.octaves = 45` | `fora da faixa oficial [1, 30]` |
| `waves.shape = 20.0` | `fora da faixa oficial [1, 10]` |
| `waves.mix = 1.4` | `fora da faixa oficial [0, 1]` |
| `waves.pull = 1.5` | `fora da faixa oficial [-1, 1]` |
| `caustics.scale = 9.0` | `fora da faixa oficial [0,1, 5]` |
| `tone_mapping.operator = "filmic"` | `nao e um valor oficial` |
| `temperature.type = "kelvin"` | `nao e um valor oficial` |

Mais: `deep` indistinguível de `ocean`, `deep` mais turvo que `ocean`, e
`surface_color = #GGGGGG`. Todos reprovados.

### Quatro erros meus nesta auditoria, todos corrigidos

1. **Check que não conferia nada.** A primeira versão derivava a raiz do caminho e
   usava `color_grading` como chave de topo — que não existe (a real é
   `minecraft:color_grading_settings`). A travessia retornava nulo e o check
   reportava `ok` sem avaliar um único valor. Hoje existe um contador de valores
   e um guard que reprova se uma faixa declarada nunca for avaliada.
2. **Caminho com um nível a menos.** `color_grading.highlightsMin` em vez de
   `color_grading.highlights.highlightsMin`. Pego pelo mesmo guard.
3. **Quebra em keyframe.** `ambient.illuminance` é um objeto de keyframes, não um
   escalar; o check quebrava com *"Não é possível converter ... PSCustomObject em
   Double"*. Agora ele achata escalar, vetor e keyframes.
4. **Arquivo espúrio criado por mim.** Um teste negativo de `water/deep.json`
   (nome inexistente — o real é `deep_ocean.json`) recriou o arquivo vazio no pacote, porque o `finally` escrevia de volta mesmo com a leitura tendo
   falhado. Removido; `git status` em `resource_pack/water/` ficou limpo.

## `docs/scope-decisions.md` — novo

Registro de decisão com o que cada alternativa custa:

- **grama e folhagem** — 31 biomas intocados, fora do escopo declarado. As três
  opções (manter / ampliar / seletiva) com ganho e custo de cada uma.
  **Em aberto, aguardando sua decisão.**
- **`local_lighting/`** — corrigida uma afirmação anterior minha: o termo
  **não aparece** em nenhum dos 6 documentos oficiais. Sem documentação do
  Mojang, fica de fora.
- **`biomes_client.json`**, **`shadows/`** — fora, com o motivo.
- **split-tone por offset** — a decisão e por que nada se perde.
- **a noite** — as quatro reduções empilhadas, risco de jogabilidade, não
  ajustado.

## Validação

| Execução | Verificações | Falhas | Avisos |
|---|---:|---:|---:|
| `validate.ps1` (offline) | 104 | 0 | 0 |
| `validate.ps1 -CheckOfficial` | 109 | 0 | 0 |
| `test-negative.ps1` | 29 | 0 | 0 |

Testes visuais e de desempenho continuam **não executados**.

---

## [1.1.0] — 2026-10-05

Correção de direção de arte. **84 valores** em 11 arquivos, todos concentrados
em dois pontos: a cor do sol na hora dourada e o violeta do crepúsculo.

Escopo deliberadamente limitado: **color grading e a noite não foram tocados**,
porque exigem teste dentro do jogo para ser calibrados. Ver "Não foi alterado".

## A cor do sol estava lavada — esta era a maior diferença em relação ao vanilla

A cor do sol **é** a cor da luz que bate no terreno. O vanilla a satura
deliberadamente no pôr do sol: `[255,127,0]`, o máximo que o canal permite.
Este pack usava `[255,163,104]`.

A intenção original era "naturalista", mas **a alavanca estava errada**.
Desaturar a cor do sol não deixa o resultado naturalista — deixa errado. Fotos de
hora dourada têm luz laranja intensa. Naturalismo vem de contraste e curva
tonal, não de tirar cor da fonte de luz.

Métrica: **spread** = `max(canal) − min(canal)`. 0 é cinza puro, 255 é
saturação máxima.

| Horário | Vanilla | `global` antes | depois | `cold` antes | depois |
|---|---:|---:|---:|---:|---:|
| `0.242908` pôr do sol | 255 | 151 | **208** | 88 | **180** |
| `0.269504` | 255 | 163 | **214** | 80 | **177** |
| `0.140811` hora dourada | 174 | 57 | **121** | 26 | **108** |
| `0.801062` manhã dourada | 174 | 69 | **127** | 32 | **110** |

`cold` era o pior caso do pack: spread 26 na hora dourada contra 174 do vanilla.

A regra aplicada nas 8 famílias de Overworld foi uniforme e reprodutível:

```
nova = vanilla + 0,45 × (nosso_anterior − vanilla)
```

Cada família mantém 45% do seu desvio do vanilla — `cold` continua mais frio,
`hot` mais quente — e ganha 55% da saturação do vanilla. Não é uma cópia: o pôr
do sol de `cold` é `[251,153,71]`, o de `hot` é `[255,149,49]`.

O meio-dia mudou de `[255,251,246]` para `[255,238,229]`. Não é arbitrário: o
sol do vanilla ao meio-dia **já é** quente (`[255,227,215]`), e o azul do céu vem
do Rayleigh, não da cor do sol.

## O violeta do crepúsculo — o momento mais bonito do dia era o mais apagado

Logo após o pôr do sol e antes do nascer do sol existe uma faixa violeta:

| Horário | Vanilla | Antes | **Depois** |
|---|---|---|---|
| `0.361464` crepúsculo noturno | `[168,168,238]` | `[120,122,176]` | **`[164,162,238]`** |
| `0.654508` alvorada | `[144,144,238]` | `[126,126,178]` | **`[148,146,240]`** |
| `0.706861` alvorada | `[223,187,237]` | `[178,158,194]` | **`[219,184,236]`** |

A soma das diferenças por canal era 156 em `0.361464` — 4× maior que em
qualquer outro horário do horizonte. O desvio estava concentrado exatamente onde
o vanilla é mais expressivo.

Foi **removida a chave `0.314561`** do horizonte, que não existe no vanilla. Ela
preenchia o espaço entre o dusk quente e o violeta com `[150,128,168]` — um
cinza-roxo sem saturação que aduava a transição que queríamos ver. Sem ela o
crepúsculo **estala** em violeta.

Alvos escolhidos por mão, preservando o tint de cada família: `cold` mais azul
(`[168,170,242]`), `hot` mais quente (`[224,180,230]`).

## Verificações novas (2 blocos, 8+8 checagens)

**Piso de saturação do sol**, por horário. Escolhido a partir dos valores reais de
antes e depois, para reprovar a versão lavada e aprovar a atual com folga:

| Horário | Piso | Pior família antes | Pior depois |
|---|---:|---:|---:|
| `0.242908`, `0.269504` | 150 | `cold` 80 | `cold` 177 |
| `0.140811`, `0.801062` | 90 | `cold` 26 | `cold` 108 |

**Violeta do crepúsculo**: spread mínimo de 60 em `0.361464` e `0.654508`, mais
uma exigência de que **B seja o canal mais alto** — uma cor clara com spread alto
mas sem azul dominante não passa.

**Testado nos dois sentidos.** Cada uma das 8 famílias de lighting foi
reintroduzida individualmente na versão lavada e todas foram reprovadas (2 a 4
falhas cada). As 3 atmosferasidem. Um violeta convertido em cinza-azulado
(`[200,205,198]`) é reprovado pelos dois critérios.

> Nota de honestidade: na primeira versão do piso eu use um valor único de 140
> para todos os horários, e ele **reprovava a hora dourada correta**. O piso foi
> recalibrado por horário. Do mesmo modo, o primeiro teste negativo "passou" —
> porque o regex não casava com o espaçamento real do JSON (`[ 255, 143, 47 ]`),
> ou seja, o teste não estava alterando nada. Os dois foram corrigidos e
> repetidos.

## Não foi alterado (deliberadamente)

- **Color grading** — o contraste global (1,12) está abaixo do vanilla (1,15) e
  os offsets de split-tone (0,008–0,016) são provavelmente imperceptíveis.
  Provavelmente é a próxima correção, mas **não** foi aplicada aqui: mexer em
  contraste e split-tone muda o look de tudo ao mesmo tempo, e isso exige ver.
- **A noite** — `rayleigh_strength` noturno está em 2,2 contra 5,0 do vanilla,
  `ambient` em 0,010 contra 0,02, e o luar em 0,34 contra 0,4. Quatro reduções
  empilhadas podem deixar a noite **escura demais para navegar**, o que seria
  regressão de jogabilidade. Precisa de teste in-game antes de qualquer ajuste.

## Validação

| Execução | Verificações | Falhas | Avisos |
|---|---:|---:|---:|
| `validate.ps1` (offline) | 98 | 0 | 0 |
| `validate.ps1 -CheckOfficial` | 103 | 0 | 0 |
| `test-negative.ps1` | 29 | 0 | 0 |

## Reversão

A tabela completa de valores alterados está em `docs/art-direction.md`
("Tabela de reversão"). `git diff v1.0.3..v1.1.0 -- resource_pack/` dá a lista
completa.

---

## [1.0.3] — 2026-10-05

Revisão completa do projeto. **Um bug de alcance visual grave** e três bugs de
ferramenta encontrados. Nenhuma decisão artística alterada.

### Corrigido: alcance da névoa até 18× mais agressivo que o vanilla

**Este era o achado mais grave de toda a revisão.**

`render_distance_type: "render"` interpreta `fog_start` / `fog_end` como
**fração da distância de render** (chunks × 16). Nenhum teste estático pegava
isso, porque os números estavam dentro do intervalo do schema — apenas não
significavam o que eu acreditava.

Convertendo para blocos a 16 chunks, contra o vanilla `v1.26.50.4`:

| Perfil | Antes | **Corrigido** | Vanilla | Razão |
|---|---:|---:|---:|---|
| `fog_cave` | **15 b** | **46 b** | 236 b | 15,3× mais cedo |
| `fog_end` | **13 b** | **115 b** | 236 b | 18,4× mais cedo |
| `fog_nether` | 8–67 b (render) | **8–80 b (fixed)** | 10–96 b | escalava com a distância de render |

Os perfis de superfície já estavam corretos: `fog_default` a 220 b contra 236 do
vanilla (93%), `fog_hot` a 230 (98%).

O End era o pior caso: `fog_start: 0.05` significava **13 blocos** de
visibilidade num vazio que o vanilla mantém visível a 236. Iria virar sopa roxa.

`fog_nether` passou de `render` para `fixed`, como o vanilla: com `render`, a
sensação de fechamento da Nether mudava conforme a configuração de render
distance do jogador — não seria a mesma a 8 e a 32 chunks.

### Corrigido: deadlock no `build.ps1`

`validate.ps1` conferia se `dist/.mcpack` tinha a mesma versão do source — mas
`build.ps1` rodava a validação **antes** de empacotar. Resultado: era impossível
incrementar a versão e recompilar. A mensagem de erro dizia *"rode build.ps1"*,
que não podia ser satisfeita.

- `validate.ps1 -SkipArtifact` pula o bloco do artefato.
- `build.ps1` passou a 4 etapas: valida (sem artefato) → empacota → verifica o
  pacote → **revalida incluindo o artefato**.

Isso é mais forte que antes: o artefato é verificado duas vezes, e a validação
final sempre roda sobre o estado real.

### Corrigido: documentação desatualizada

`docs/compatibility.md` afirmava 73/75 verificações quando eram 80/82. Várias
tabelas do `README.md` tinham linhas que falharam em substituições anteriores
(tabela de estado dos testes estava incompleta).

### Adicionado: verificação de alcance em blocos

`validate.ps1` agora calcula o alcance da névoa de ar dos **10 perfis** em blocos
e reprova abaixo do piso de legibilidade por dimensão — Overworld 40, Nether 5,
End 25. O Nether tem piso menor porque o próprio vanilla usa 10 blocos lá.

`fog-report.ps1` passou a mostrar o alcance em blocos a 8 e 16 chunks, com
comparação direta ao vanilla.

**Testado nos dois sentidos:** com `fog_cave.fog_start` de volta a `0.06`, a
verificação reprova com *"nevoa de ar comeca em 15 blocos"*.

### Revisão independente — o que foi verificado e estava limpo

- **Chaves JSON duplicadas** em todos os 129 arquivos — 0 (o `ConvertFrom-Json`
  do PowerShell ignora silenciosamente; a checagem usou um scanner manual)
- **BOM dentro do pack** — 0 (um BOM no meio da lista de arquivos tornaria o
  manifesto ilegível para o motor)
- **Vírgulas finais** — 0
- **Keyframes:** todos numéricos, dentro de `[0,1]`, sem repetição, com `0.0` e
  `1.0` presentes e **iguais** (nenhum salto na virada do dia)
- **Cores:** todos os hex de 6/8 dígitos, todos os arrays RGB com 3–4 valores em
  `[0,255]` — 0 problemas
- **Configurações mortas:** toda config declarada é referenciada por ao menos um
  bioma — 0 mortas
- **Case dos nomes de arquivo:** tudo em minúsculas
- **`pack_icon.png`:** PNG válido, 128×128, 8-bit, RGBA
- **Agrupamento por bioma:** 14 assinaturas distintas, soma 89, coincide com o
  mapa de 16 famílias

### Validação

| Execução | Verificações | Falhas | Avisos |
|---|---:|---:|---:|
| `validate.ps1` (offline) | 90 | 0 | 0 |
| `validate.ps1 -CheckOfficial` | 92 | 0 | 0 |
| `test-negative.ps1` | 29 | 0 | 0 |

`.mcpack`: 130 entradas, CRC íntegro, APROVADO.

### Pendente

**Testes visuais e de desempenho continuam NÃO executados.** O alcance da névoa
agora é previsível em blocos, o que torna o teste visual muito mais fácil de
interpretar — se algo parecer errado, dá para dizer "a 46 blocos deveria ver
mais".

---

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