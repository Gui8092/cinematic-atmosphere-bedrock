# Direção artística

**Cinematografia naturalista de alta qualidade.** Cores controladas,
atmosfera marcante, e a identidade visual do Minecraft preservada.

## Princípio que governa tudo

> O pack não mexe em nenhuma textura. A única forma de "errar" a cor é o color
> grading. Portanto o orçamento é apertado e explícito:
>
> | Limite | Valor |
> |---|---|
> | Saturação | ≤ 1.06 (chegando a 0.94 no Nether) |
> | Offset | 0 (zerado na v1.2.0; o split-tone vive no `gain`) |
> | Contraste | 1.10 – 1.22 |
> | Gain | 0.93 – 1.02 |
> | Gamma | 2.2 (padrão) |
>
> Passar disso deixa de ser "realista" e passa a ser "outro jogo".

## O que é proibido

- Sobrescrever textura, modelo, geometria, som, partícula ou UI.
- Trocar a textura do céu/cubemap.
- Geometria de água customizada.
- Escurecer o jogo em vez de iluminá-lo.
- Névoa em tudo.

---

## 1. Curva de 24 horas

Todos os perfis de `lighting/` e `atmospherics/` usam os **mesmos horários de
keyframe do vanilla**, com valores próprios. Ver `docs/research.md` § 5.1.

```
0.000 ─────────────────────────────── 1.000   (0.0 = meio-dia)
        ↓ sobe                        ↓ desce
0.719 sunrise   0.75   0.80   0.95   0.05   0.28 sunset   0.292 noite
```

**Iluminação diurna**
- Sol forte mas com **curva** — não constante. Entre o amanhecer e o meio-dia a
  intensidade sobe de ~1 a 92–118 conforme a família.
- `sky.intensity` entre 0.42 e 1.0: é o controle principal de quão fechada fica a
  sombra.
- `ambient` **sempre colorido**, nunca branco: dia `#8FA4C6` (temperado),
  noite `#46557A`. É o que dá personalidade às áreas escuras.
- Realces contidos: `highlights` com `gain` levemente < 1 nas famílias quentes.

**Amanhecer e pôr do sol**
- `sun.color` interpolando de `[255,238,229]` (meio-dia levemente quente) para
  `[255,143,47]` no pôr do sol e `[255,197,134]` na hora dourada.
- `sun_mie_strength` com pico em `0.265` e `0.735` (1.10) — o **brilho ao redor
  do sol**, que é o efeito mais cinematográfico do céu.
- `sun_glare_shape` de 0.09 nesses mesmos picos: o lóbulo de Mie que dá o halo.
- `horizon_blend_stops` com `start` caindo de 0.80 (meio-dia) para 0.25
  (crepúsculo) e voltando: a faixa quente **avança e recua** com o sol.
- `rayleigh_strength` cai de 10.0 a 2.2 à noite: a noite fica **de fato escura**,
  em vez de azul-lavada.

### A cor do sol é a cor da luz — saturação, não croma (v1.1.0)

> ⚠️ **Correção de 2026-10-05.** Até a v1.0.3 a cor do sol era **lavada**: o
> vanilla põe `[255,127,0]` no pôr do sol (saturação máxima), este pack usava
> `[255,163,104]`. A intenção era "naturalista", mas a alavanca estava errada.

O sol **é** a fonte da luz que bate no terreno. Desaturar a cor do sol não
deixa o resultado naturalista — deixa **errado**. Fotos de hora dourada têm luz
laranja intensa. Naturalismo vem de contraste e curva tonal, não de tirar cor da
fonte.

A métrica usada é o **spread** = `max(canal) − min(canal)`: 0 é cinza puro, 255
é a cor mais saturada que o canal permite. O vanilla **não** usa a mesma
intensidade em todos os horários — é máximo no pôr do sol e bem mais suave na
hora dourada:

| Horário | Vanilla | `global` antes | depois | `cold` antes | depois |
|---|---:|---:|---:|---:|---:|
| `0.242908` pôr do sol | 255 | 151 | **208** | 88 | **180** |
| `0.269504` | 255 | 163 | **214** | 80 | **177** |
| `0.140811` hora dourada | 174 | 57 | **121** | 26 | **108** |
| `0.801062` manhã dourada | 174 | 69 | **127** | 32 | **110** |

`cold` era o pior caso do pack: spread 26 na hora dourada, contra 174 do vanilla.

A regra aplicada nas 8 famílias de Overworld foi uniforme e reprodutível:

```
nova = vanilla + 0,45 × (nosso_anterior − vanilla)
```

Cada família mantém **45% do seu desvio** do vanilla — então `cold` continua mais
frio, `hot` mais quente — e ganha 55% da saturação do vanilla. O resultado não
é uma cópia do vanilla: o pôr do sol da família `cold` é `[251,153,71]` e o da
`hot` é `[255,149,49]`.

> O meio-dia também mudou, de `[255,251,246]` para `[255,238,229]`. Não é
> arbitrário: o sol do vanilla ao meio-dia **já é** quente (`[255,227,215]`), e
> o azul do céu vem do Rayleigh, não da cor do sol.

### O violeta do crepúsculo — a faixa mais cinematográfica do ciclo

Logo após o pôr do sol e antes do nascer do sol existe uma faixa **violeta**. É o
momento mais bonito do ciclo, e era justamente o mais apagado deste pack:

| Horário | Vanilla | Antes (`global`) | **Depois** |
|---|---|---|---|
| `0.361464` crepúsculo noturno | `[168,168,238]` | `[120,122,176]` | **`[164,162,238]`** |
| `0.654508` alvorada | `[144,144,238]` | `[126,126,178]` | **`[148,146,240]`** |
| `0.706861` alvorada | `[223,187,237]` | `[178,158,194]` | **`[219,184,236]`** |

A soma das diferenças por canal era **156** em `0.361464` — 4× maior que em
qualquer outro horário do horizonte. O desvio estava concentrado exatamente onde
o vanilla é mais expressivo.

Os alvos foram escolhidos por mão, preservando o tint de cada família: `cold`
fica mais azul (`[168,170,242]`), `hot` mais quente (`[224,180,230]`).

Também foi **removida a chave `0.314561`** do horizonte, que **não existe no
vanilla**. Ela preenchia o espaço entre o dusk quente e o violeta com
`[150,128,168]` — um cinza-roxo sem saturação que **aduava** justamente a
transição que queríamos ver. Sem ela, o vanilla salta de `[136,108,108]` para
`[168,168,238]` e o crepúsculo **estala** em violeta.

### Tabela de reversão

Todos os valores alterados na v1.1.0, para reverter campo a campo:

| Arquivo | Campo | Antes | Depois |
|---|---|---|---|
| `lighting/global.json` | `sun.color.0.242908` | `[255,163,104]` | `[255,143,47]` |
| `lighting/global.json` | `sun.color.0.140811` | `[255,226,198]` | `[255,197,134]` |
| `lighting/global.json` | `sun.color.1.000000` | `[255,251,246]` | `[255,238,229]` |
| `atmospherics/atmospherics.json` | `sky_horizon_color.0.361464` | `[120,122,176]` | `[164,162,238]` |
| `atmospherics/atmospherics.json` | `sky_horizon_color.0.314561` | `[150,128,168]` | **removida** |

O mesmo padrão vale para as outras 7 famílias de lighting e as outras 2
atmosferas; os valores estão em `dist/` das releases v1.0.3 e v1.1.0 para
comparação direta. `git diff v1.0.3..v1.1.0 -- resource_pack/` dá a lista
completa.

**Noite**
- Luar 0.26–0.42, cor `#A8BEF0`-``#BCC4F0` (frio).
- `ambient` noturno entre 0.009 e 0.014 — escuro, mas **não preto**.
- `moon_mie_strength` até 0.30: um halo sutil em torno da lua.

---

## 2. split-tone — o coração do look

Todos os 7 arquivos de `color_grading/` têm `shadows` e `highlights` com
`"enabled": true`, e é isso que separa "cubo de Minecraft" de "cena":

| Família | `shadows.gain` (frio) | `highlights.gain` (quente) | Contraste | Temperatura |
|---|---|---|---|---|
| `cg_overworld` | `[0.97, 0.99, 1.04]` | `[1.02, 1.00, 0.97]` | 1.12 | 6500 K |
| `cg_cold` | `[0.96, 0.99, 1.05]` | `[1.00, 1.00, 1.01]` | 1.10 | 5200 K |
| `cg_hot` | `[0.98, 0.99, 1.02]` | `[1.02, 1.00, 0.96]` | 1.14 | 7200 K |
| `cg_swamp` | `[0.96, 1.00, 0.98]` | `[1.01, 1.00, 0.98]` | 1.12 | 6600 K |
| `cg_cave` | `[0.93, 0.96, 1.04]` | `[0.99, 0.99, 1.00]` | 1.22 | 5200 K |
| `cg_nether` | `[0.96, 0.95, 0.95]` | `[0.98, 0.97, 0.96]` | 1.18 | 7200 K |
| `cg_end` | `[0.95, 0.94, 1.03]` | `[1.00, 0.99, 1.02]` | 1.20 | 4600 K |

> Os `offset` desta tabela foram zerados na v1.2.0: o spec oficial define
> `offset` em [0.0, 4.0] como fator exponencial, e os valores negativos
> usados antes não tinham significado. O split-tone vive no `gain` acima —
> azul acima do vermelho nas sombras, vermelho acima do azul nos realces.
> Detalhes em `docs/scope-decisions.md` §6.

Sombras frias + realces quentes é a assinatura cinema-digital padrão e resolve
boa parte do pedido de "tonalidade das sombras e realces".

**Contenção de realces** — crítico em caverna e Nether:
`highlightsMin` é 1.35 (caverna) e 1.40 (Nether), com `gain` < 1. Isso impede
que uma tocha ou a lava vire um borrão branco. No Nether é o que evita o
"cenário fluorescente".

### Direção da temperature (v1.3.0)

> ⚠️ **Correção de 2026-10-05.** Com `type: color_temperature`, valores **altos
> esquentam** a imagem e valores **baixos esfriam** (spec oficial). Até a v1.2.1,
> `cold` usava 8200 K (esquentando um bioma de neve) e `nether` usava 3400 K
> (esfriando a dimensão do fogo) — o inverso da intenção documentada. É a
> confusão clássica: uma lâmpada de 3400 K *é* laranja, mas dizer ao motor "a
> luz é 3400 K" faz ele *esfriar* a imagem para compensar.

| Família | Antes | Depois | Efeito |
|---|---|---:|---|
| `cold` | 8200 K | **5200 K** | esfria, como `cave` |
| `nether` | 3400 K | **7200 K** | esquenta, como `hot` |

Os valores novos reutilizam âncoras já existentes no pack, em vez de inventar
números. `validate.ps1` agora codifica a intenção: famílias frias (`cold`,
`cave`, `end`) não podem passar de 6500 K, famílias quentes (`hot`, `nether`)
não podem ficar abaixo. Testado nos dois sentidos: os valores antigos são
reprovados.

**Tone mapping: `aces`.** Curva filmic que comprime os realces em vez de
estourá-los. É o que faz o sol forte do deserto não virar um patch branco.
Obrigatório em **todos** os 7 arquivos — o parâmetro não é interpolável.

---

## 3. Névoa: o motor da profundidade

A névoa é o que separa os planos de uma paisagem. Cada família tem um
`fog_start` diferente, e essa diferença é a sensação de escala:

| Família | `fog_start` | Leitura |
|---|---|---|
| `fog_mountain` | **0.62** | Perspectiva aérea forte — morro médio se separa da montanha distante |
| `fog_swamp` | 0.52 | Névoa rasteira que fecha o chão |
| `fog_forest` | 0.72 | Profundidade entre árvores |
| `fog_cold` | 0.80 | Difusão de neve, sem esconder |
| `fog_ocean` | 0.78 | Funde mar e céu no horizonte |
| `fog_default` | 0.86 | Quase transparente — planície aberta |
| `fog_hot` | **0.90** | Quase sem névoa; só poeira quente |
| `fog_cave` | 0.18 | Fecha o túnel; ver §Alcance da névoa em blocos |
| `fog_nether` | 8.0 (`fixed`) | Fecha rápido e não muda com a distância de render |
| `fog_end` | 0.45 | Vazio profundo, mas com visibilidade preservada |

### Feixes de luz

`henyey_greenstein_g` alto = *forward-scattering*: a luz atravessa a névoa em
direção ao observador, que é exatamente o que se enxerga como um feixe.

| Família | `henyey_greenstein_g` | Efeito |
|---|---|---|
| `fog_forest` | **0.80** | Feixes entre as árvores — a família com maior `scattering` (0.045) |
| `fog_default` / `fog_cold` | 0.72 | Padrão do jogo, unchanged |
| `fog_ocean` | 0.75 | Leve |
| `fog_cave` / `fog_nether` / `fog_end` | 0.40 / 0.35 / 0.45 | Atenuado; scattering alto aqui só daria névoa chapada |

### Alcance da névoa em blocos — o ajuste mais importante desta revisão

`render_distance_type: "render"` interpreta `fog_start` / `fog_end` como
**fração da distância de render** (chunks × 16). Isso significa que
`0.05` não é "5% de algo pequeno": a 16 chunks, são **13 blocos**.

Na v1.0.2, três perfis tinham valores **até 18× mais agressivos que o vanilla**
e nenhum teste estático os detectava, porque os números estavam "dentro do
intervalo do schema". O vanilla começa a névoa a **236 blocos**; este pack
começava a:

| Perfil | Antes | **Agora** | Vanilla | Correção |
|---|---:|---:|---:|---|
| `fog_cave` | 15 b | **46 b** | 236 b | `0.06 → 0.18` no início |
| `fog_end` | 13 b | **115 b** | 236 b | `0.05 → 0.45` no início |
| `fog_nether` | 8–67 b | **8–80 b fixo** | 10–96 b | `render` → `fixed` |

Os perfis de superfície já estavam correctos: `fog_default` começa a 220 blocos
contra 236 do vanilla (93%), `fog_hot` a 230 (98%).

**`fog_nether` passou a `fixed`**, como o vanilla. Com `render`, o alcance da
Nether mudava conforme a configuração de render distance do jogador — a sensação
de fechamento não seria a mesma a 8 e a 32 chunks. Com `fixed` em 8–80 blocos
contra 10–96 do vanilla, o fechamento é determinístico.

`fog_cave` a 20% do vanilla é **intencional**: caverna deve parecer fechada. Mas
46 blocos ainda dão tempo para ver perigo e obstáculo antes da névoa.

Agora `validate.ps1` calcula o alcance em blocos de todos os 10 perfis e
reprova se algum cair abaixo do piso de legibilidade por dimensão
(Overworld 40, Nether 5, End 25). O teste foi rodado nos dois sentidos: com
`cave.fog_start` de volta a 0.06, a verificação reprova.

### O piso universal de baixa altitude

> ⚠️ **Escolha original, não um padrão do vanilla.** Nos 80 perfis de fog
> volumétrico do vanilla `v1.26.50.4`, `zero_density_height` e
> `max_density_height` são **sempre iguais (320.0)** e `uniform` nunca aparece.
> O vanilla **não usa rampa vertical em lugar nenhum**. O que segue é um desenho
> nosso, e **ainda não foi verificado dentro do jogo**.

`zero_density_height` alto + `max_density_height` baixo cria um perfil em que a
densidade é **exatamente zero** acima de certo Y:

```json
"air": { "max_density": 0.014, "zero_density_height": 128.0, "max_density_height": 48.0 }
```

Acima de Y=128: sem névoa, sem custo, paisagem totalmente limpa. Abaixo de Y=48:
densidade máxima. Nas montanhas o teto sobe para **190** — picos e cumes ficam
limpos. No pântano desce para **96** com `max_density_height` 32 — a única
família de superfície com uma camada de bruma baixa de verdade.

**Nas cavernas, no Nether e no End os dois valores são iguais (320):** a densidade
é **uniforme em toda a altura abaixo de Y=320**, e não uma camada no chão. É o
padrão do vanilla (`lush_caves`, `sulfur_caves`, `pale_garden`, `the_end`).
Uma caverna a Y=10 tem a **mesma** densidade que uma a Y=200.

### Comparação de intensidade com o vanilla

Nossas densidades são deliberadamente mais baixas que as do vanilla:

| Perfil | `max_density` | Referência vanilla | Razão |
|---|---:|---|---|
| `fog_default` | 0.014 | 0.05 (`humid`) | 28% do vanilla |
| `fog_cold` | 0.020 | 0.05 (`cold_taiga`) | 40% |
| `fog_forest` | 0.026 | 0.05 (`jungle`) | 52% |
| `fog_mountain` | 0.022 | 0.05 (`taiga`) | 44% |
| `fog_hot` | 0.010 | 0.0 (`desert`) | mais contido que o vanilla |
| `fog_swamp` | 0.034 | 0.05 (`swampland`) | 68% |
| `fog_cave` | 0.055 | 0.05 (`lush_caves`) | 1.1× o vanilla |
| `fog_nether` | 0.048 | `hell` vanilla **não tem** fog volumétrico | original nosso |
| `fog_end` | 0.040 | 0.25 (`the_end`) | **16%** — o caso mais distante |

**Vales baixos:** com `fog_default`, um vale a Y=40 atinge a densidade máxima de
0.014 — cerca de um terço da névoa de um bioma úmido do vanilla, e só abaixo de
Y=48. Não é excessivo, mas **não foi verificado dentro do jogo** (teste C7).

---

## 4. Cavernas — o caso especial

O erro original do planejamento era tratar `zero_density_height` como um
detector de ambiente subterrâneo. **Não é** (ver `docs/research.md` § 4). A
estratégia correta tem três camadas:

**A. Perfil vertical nos perfis de superfície.**
O piso universal descrito acima. É o único lever universal que existe, e é
suficiente para dar "ar" a qualquer túnel.

**B. Densidade alta nos biomas de caverna.**
`cba:fog_cave` usa `max_density: 0.055` — alinhado aos 0.05 / 0.07 que a própria
Mojang usa em `lush_caves` e `sulfur_caves`. Pode ser mais denso que a
superfície **sem custo**, porque `dripstone_caves`, `lush_caves`, `deep_dark` e
`sulfur_caves` só existem no subsolo. Também recebe `distance.air` curto
(`0.06 → 0.34`) para túneis longos desvanecerem.

Como os dois valores de altura são iguais (320), a densidade é **uniforme na
altura**, não uma camada no chão: uma caverna a Y=10 e outra a Y=200 têm a mesma
bruma. A variação vertical só existe nos **perfis de superfície** (A).

**C. `ambient` é a identidade real da caverna — e é de graça.**
Os termos de sol e céu não chegam ao subsolo. Portanto **o `ambient` é o único
termo que importa lá embaixo**, e ele é o mesmo em todos os biomas. Um `ambient`
baixo e frio no perfil `lighting_overworld` produz "rocha escura e azulada" em
qualquer túnel sob qualquer bioma, **sem nenhuma detecção de caverna**. É
fisicamente correto e é o lever de maior valor do projeto para cavernas.

### Limitações declaradas

- Um túnel sob planícies **não** fica tão denso quanto uma dripstone cave. É o
  limite do mecanismo. Testado como C5 em `docs/compatibility.md`.
- A **absorção é só luminância** → o verde de `sulfur_caves` vem do `fog_color`
  e do color grading, não do `absorption`.
- Fog é a **média dos biomas vizinhos**: numa fronteira caverna/superfície a
  densidade interpola — o que é desejável.
- Y é absoluto e o teto varia por dimensão (Nether 128, End 256): cada perfil
  define os seus próprios valores.
- **Dentro de uma caverna não há gradiente vertical.** A densidade é uniforme
  abaixo de Y=320. Se o objetivo fosse bruma concentrada no chão, seria preciso
  `max_density_height` **maior** que `zero_density_height` — o oposto do que
  este pack faz.
- A rampa vertical dos perfis de superfície é um desenho **original e não
  verificado em jogo**; o vanilla não a usa.

---

## 5. Água

`particle_concentrations` descreve a cor por composição física em vez de
escolher uma cor:

| Água | `cdom` | `chlorophyll` | `suspended_sediment` | Leitura |
|---|---|---|---|---|
| `water_fresh` | 1.2 | 0.35 | 0.8 | Rio levemente verde-brown |
| `water_ocean` | 0.15 | 0.25 | 0.1 | Azul limpo |
| `water_deep` | 0.05 | 0.40 | 0.15 | Azul profundo, um toque de verde |
| `water_warm` | 0.10 | 0.55 | 0.20 | Turquesa |
| `water_frozen` | 0.10 | 0.15 | 0.05 | Quase cristalino |
| `water_swamp` | 3.5 | 1.20 | 6.0 | Verde-lodoso, turvo |

`biome_water_color_contribution` (0.15–0.45) deixa a cor vanilla do bioma
aparecer como um "corante" antes das concentrações — o que preserva a
identidade do jogo em vez de substituí-la.

**`waves.enabled: false`** em todos os 6 arquivos. Preserva a animação de
textura original do Minecraft (que o escopo exige) e economiza GPU. Receita
para ligar: `docs` → `README.md` § 5. `caustics` fica ligado com os parâmetros
exatos do vanilla.

---

## 6. Dimensões

**Nether** — opressivo, mas legível.
- Sem sol nem lua (`illuminance` 0). A luz vem só de `ambient` **#C4521C @ 0.18**
  (o vanilla usa `#FFFFFF @ 0.5` — muito mais neutro e claro).
- Atmosfera: zênite `[46,14,10]`, horizonte `[122,42,16]`, `rayleigh_strength`
  0.15 (o vanilla também usa 0.15).
- `distance.air` 0.03 → 0.26: o mundo **fecha rápido**.
- `cg_nether` a 7200 K com `highlights` contidos: tons quentes, zero
  fluorescência. (Até a v1.2.1 eram 3400 K, que **esfriam** a imagem com
  `type: color_temperature` — o inverso da intenção documentada. Ver §"Direção
  da temperature" abaixo.)

**End** — isolamento.
- `ambient` `#6A5A9E @ 0.075`, `sky.intensity` 0.3.
- `flash` em `[222,168,255]` com 2.2 (vanilla: 3.0) — presente, mas não
  ofuscante.
- Atmosfera zênite `[30,22,52]`, horizonte `[14,10,34]`,
  `rayleigh_strength` 34.0 (vanilla 50.0 — reduzido para o vazio não ficar
  lavado).
- `cg_end` a 4600 K com sombras violetas.

**Cobertura de cubemap.** A customização de cubemap só é válida no **Overworld**
(o End usa o cubemap embutido, e a documentação não define cubemap para o
Nether). A regra adotada é explícita e verificada pelo validador:

| Dimensão | `cubemap_identifier` | Quantidade |
|---|---|---:|
| Overworld (superfície e cavernas) | `cba:cubemap_overworld` | 83 de 83 |
| Nether | nunca | 5 de 5 |
| End | nunca | 1 de 1 |

Todos os 83 biomas do Overworld recebem o identificador — inclusive deserto,
savana e as cavernas, que antes da auditoria estavam sem ele.

---

## 7. Fronteiras de bioma

`atmospherics`, `color grading`, `lighting` e `cubemaps` **interpolam pela
posição da câmera**. `water` interpola **por geometria** — dá para ver quatro
tipos de água diferentes de um penhasco.

Consequências de design:
- Andar da floresta para a planície é uma **dissolução contínua**, nunca um degrau.
- É por isso que `orbital_offset_degrees` precisa ser **igual em todos** os
  arquivos: se divergisse, a interpolação produziria um arco solar piscando ao
  cruzar a fronteira.
- A família é uma unidade de look, não um bioma. Vinte biomas de floresta
  compartilham 1 `lighting` + 1 `atmospherics` + 1 `color_grading` + 1 `fog`
  + 1 `water` — o que mantém o pacote legível e as transições previsíveis.

---

## 8. Pale Garden

Reaproveita `lighting_cold` (superfície fria e luminosa), `cg_cave` (grade
morta e de alto contraste), `fog_cold` e `water_swamp`. Não usa `lighting_cave`
porque `sky.intensity: 0.42` deixaria um bioma **de superfície** ilegível.
Reaproveitamento deliberado, registrado em `tools/biome-map.ps1`.
