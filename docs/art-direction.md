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
> | Offset | ±0.03 |
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
- `sun.color` interpolando de `[255,251,246]` (meio-dia quase neutro) para
  `[255,163,104]` / `[214,150,108]` no crepúsculo.
- `sun_mie_strength` com pico em `0.265` e `0.735` (1.10) — o **brilho ao redor
  do sol**, que é o efeito mais cinematográfico do céu.
- `sun_glare_shape` de 0.09 nesses mesmos picos: o lóbulo de Mie que dá o halo.
- `horizon_blend_stops` com `start` caindo de 0.80 (meio-dia) para 0.25
  (crepúsculo) e voltando: a faixa quente **avança e recua** com o sol.
- `rayleigh_strength` cai de 10.0 a 2.2 à noite: a noite fica **de fato escura**,
  em vez de azul-lavada.

**Noite**
- Luar 0.26–0.42, cor `#A8BEF0`-``#BCC4F0` (frio).
- `ambient` noturno entre 0.009 e 0.014 — escuro, mas **não preto**.
- `moon_mie_strength` até 0.30: um halo sutil em torno da lua.

---

## 2. split-tone — o coração do look

Todos os 7 arquivos de `color_grading/` têm `shadows` e `highlights` com
`"enabled": true`, e é isso que separa "cubo de Minecraft" de "cena":

| Família | `shadows.offset` (frio) | `highlights.offset` (quente) | Contraste | Temperatura |
|---|---|---|---|---|
| `cg_overworld` | `[-0.010, -0.004, +0.012]` | `[+0.012, +0.004, -0.008]` | 1.12 | 6500 K |
| `cg_cold` | `[-0.010, -0.004, +0.014]` | `[+0.004, +0.006, +0.012]` | 1.10 | 8200 K |
| `cg_hot` | `[-0.006, -0.002, +0.008]` | `[+0.014, +0.004, -0.010]` | 1.14 | 7200 K |
| `cg_swamp` | `[-0.008, 0.000, -0.002]` (verde) | `[+0.008, +0.004, -0.004]` | 1.12 | 6600 K |
| `cg_cave` | `[-0.014, -0.008, +0.016]` | `[+0.004, +0.004, +0.006]` | 1.22 | 5200 K |
| `cg_nether` | `[-0.008, -0.008, -0.006]` | `[+0.002, -0.002, -0.006]` | 1.18 | 3400 K |
| `cg_end` | `[-0.010, -0.010, +0.008]` | `[+0.004, 0.000, +0.012]` | 1.20 | 4600 K |

Sombras frias + realces quentes é a assinatura cinema-digital padrão e resolve
boa parte do pedido de "tonalidade das sombras e realces".

**Contenção de realces** — crítico em caverna e Nether:
`highlightsMin` é 1.35 (caverna) e 1.40 (Nether), com `gain` < 1. Isso impede
que uma tocha ou a lava vire um borrão branco. No Nether é o que evita o
"cenário fluorescente".

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

### Feixes de luz

`henyey_greenstein_g` alto = *forward-scattering*: a luz atravessa a névoa em
direção ao observador, que é exatamente o que se enxerga como um feixe.

| Família | `henyey_greenstein_g` | Efeito |
|---|---|---|
| `fog_forest` | **0.80** | Feixes entre as árvores — a família com maior `scattering` (0.045) |
| `fog_default` / `fog_cold` | 0.72 | Padrão do jogo, unchanged |
| `fog_ocean` | 0.75 | Leve |
| `fog_cave` / `fog_nether` / `fog_end` | 0.40 / 0.35 / 0.45 | Atenuado; scattering alto aqui só daria névoa chapada |

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
- `cg_nether` a 3400 K com `highlights` contidos: tons quentes, zero
  fluorescência.

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