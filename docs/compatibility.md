# Compatibilidade, riscos e plano de testes

## 1. Matriz de requisitos

| | Valor |
|---|---|
| Versão mínima | `1.26.0` (`min_engine_version`) |
| Versão de desenvolvimento | `1.26.50.x` (tag estável `v1.26.50.4`) |
| SO alvo | Windows 10 / 11 |
| Modo gráfico principal | **Vibrant Visuals** |
| Modo gráfico secundário | Clássico (degradação limpa) |
| Capability do manifesto | `pbr` |

---

## 2. Comportamento por modo gráfico

| Efeito | Vibrant Visuals | Modo clássico |
|---|:--:|:--:|
| Fog de distância por bioma (`fogs\*.json`, bloco `distance`) | ✅ | ✅ |
| `sky_color` / `water_appearance.surface_color` | ✅ | ✅ |
| Sol e lua com cor e intensidade por hora | ✅ | ❌ |
| Céu Rayleigh/Mie e gradiente de amanhecer/pôr do sol | ✅ | ❌ |
| Névoa volumétrica e feixes de luz | ✅ | ❌ |
| Tone mapping ACES, split de sombras/realces, temperatura | ✅ | ❌ |
| Caustics e propagação de partículas na água | ✅ | ❌ |
| Nuvens reagindo ao espalhamento atmosférico | ✅ | ❌ |

**Sem variante duplicada.** As mesmas `fogs\*.json` e os mesmos componentes de
`client_biome` servem aos dois pipelines. No modo clássico o resultado é
"melhor que o vanilla, nunca quebrado".

---

## 3. Riscos

| # | Risco | Impacto | Mitigação implementada |
|---|---|---|---|
| R1 | Vanilla por bioma sobrescreve os JSONs globais | Pack "não faz nada" | 89 `*.client_biome.json` + verificação de cobertura no `validate.ps1` |
| R2 | Merge de `client_biome` entre packs não documentado | Perda de som/música/cores ao sobrescrever | Alteração mínima: componentes vanilla preservados verbatim; teste de fumaça em `the_end`, `sulfur_caves`, `pale_garden`, `swampland`, `ocean` |
| R3 | `min_engine_version` inconsistente com `format_version` | Pack ativo mas inerte | `[1, 26, 0]` = maior `format_version` usado; sem fallback automático |
| R4 | Keyframes em horários redondos (0.25/0.75) | Céu dessincronizado do sol | Horários exatos do vanilla como esqueleto |
| R5 | Parâmetro não interpolável divergente entre arquivos | Transições com popping | `validate.ps1` compara `tone_mapping`, `orbital_offset_degrees`, `caustics`, `waves` |
| R6 | Absorção de fog só em luminância | Neblina sem cor | Cor vem de `fog_color` + atmosfera + color grading |
| R7 | Tone mapping filmico mais caro | Desempenho | `aces` escolhido por decisão artística; `"generic"` documentado como alternativa |
| R8 | Névoo volumétrica em hardware fraco | Desempenho | Densidades baixas (0.010–0.055); `zero_density_height` alto deixa a área de superfície **exatamente** sem névoa |
| R9 | Conflito com outro pack de iluminação | Visual imprevisível | README: ativar este pack **no topo** da lista |
| R10 | Bioma novo em versão futura fica com visual vanilla | Inconsistência | `lighting/global.json`, `atmospherics/atmospherics.json`, `color_grading/color_grading.json` e `water/water.json` são default global para biomas sem atribuição explícita |
| R11 | `dappled_forest` / `sulfur_caves` ausentes em versões antigas | — | `client_biome.json` extra é **inofensivo**: simplesmente não usado |
| R12 | `shadows/` e `local_lighting/` com caminho não comprovado | Config ignorada | **Omitidos** com justificativa (`docs/inventory.md`) |

---

## 4. Estado dos testes

### 4.1 Testes automatizados — ✅ EXECUTADOS

Ferramenta: `tools/validate.ps1`. **75 verificações, 0 falhas, 0 avisos.**

| Bloco | Cobre |
|---|---|
| `[A]` Estrutura e sintaxe | 7 diretórios obrigatórios, parse de todos os `.json` |
| `[B]` Manifesto | `format_version`, campos de `header`, UUIDs no formato correto e **distintos**, módulo `resources`, capability `pbr`, `min_engine_version` |
| `[C]` Integridade referencial | Todo `lighting`/`atmosphere`/`color_grading`/`water`/`fog`/`cubemap` identifier referenciado pelos 89 biomas **existe**; namespace `cba`; sem duplicados; arquivos reservados presentes; cobertura exata de 89 biomas; cubemap nunca atribuído a dimensão não-Overworld; componentes vanilla preservados |
| `[D]` Schemas | `format_version` por tipo; coerência `min_engine_version`; 4 parâmetros não interpoláveis; `waves.enabled == false`; `operator == "aces"`; ranges de `ambient.illuminance`, `sky.intensity`, `caustics.power`, concentrações de partículas, `biome_water_color_contribution`, `temperature`, `contrast`/`gain`/`gamma`/`offset`/`saturation`, `shadowsMax < highlightsMin`, `fog_start < fog_end`, `max_density`, `zero_density_height >= max_density_height`, `henyey_greenstein_g`; keyframes com `0.0` e `1.0` |
| `[E]` Não-invasão | Ausência de `textures`, `models`, `geometry`, `sounds`, `particles`, `entity`, `items`, `ui`, `textures_list.json`, `pbr`, `local_lighting`, `point_lights`, `shadows`; única imagem = `pack_icon.png`; nenhum arquivo de som |

Empacotamento: **✅ executado** — 130 entradas, ZIP plano,
`manifest.json` na raiz, SHA256 registrado por `build.ps1`.

### 4.2 Testes visuais dentro do Minecraft — ⏳ NÃO EXECUTADOS

> **Não houve execução dentro do jogo.** Não existe captura de tela, nem
> verificação in-game, nem medição de FPS. Os valores configurados são pontos de
> partida fundamentados no vanilla e na documentação, e **precisam de calibração
> visual**.

#### Ciclo do dia (Overworld)

| # | Momento | Critério de aceitação |
|---|---|---|
| D1 | t ≈ 0.72–0.78 (amanhecer) | Horizonte dourado, zênite ainda azul, **transição contínua** sem degrau |
| D2 | t = 0.0 (meio-dia) | Realces abaixo de branco puro; sombras com detalhe visível |
| D3 | t ≈ 0.22–0.28 (pôr do sol) | Luz rasante atravessando a copa; horizonte com gradiente, não uma faixa |
| D4 | t = 0.5 (meia-noite) | Azul frio legível; tochas com halo quente, **não** pontos brancos |
| D5 | t = 0.25 → 0.30 (crepúsculo) | Azul-hour visível; sem "corte" no horizonte |

#### Ambientes

| # | Cenário | Critério de aceitação |
|---|---|---|
| A1 | Floresta densa | 3 planos de profundidade distinguíveis; chão da mata visível; **feixes de luz** perceptíveis entre as árvores |
| A2 | Montanhas / picos | Névoa **separa** morro médio de montanha distante; picos **não** encobertos (regressão do `zero_density_height: 190`) |
| A3 | Oceano | Mar e horizonte fundem; caustics visíveis submerso; **nenhuma textura de água alterada** |
| A4 | Rio / margem | Sem "parede" de névoa na linha da água |
| A5 | Deserto / savana | Céu quase branco no horizonte; quase sem névoa; sol forte sem estourar tudo |
| A6 | Neve / gelo | Azul frio, **não** branco leitoso |
| A7 | Pântano | Névoa rasteira, verde-oliva; água turva |
| A8 | Pale Garden | Morto e acinzentado, sem ficar ilegível |
| A9 | Nether | Atmosfera opressiva; **sem fluorescência**; mobs e obstáculos legíveis |
| A10 | End | Violeta profundo, sensação de isolamento |

#### Cavernas

| # | Cenário | Critério de aceitação |
|---|---|---|
| C1 | Dripstone cave natural (Y ≈ 10–40) | Bruma cresce com a profundidade; `distance.air` encurta; ainda legível |
| C2 | Lush cave | Mesma densidade, com o verde do bioma |
| C3 | Sulfur cave (Y ≈ −20 a 40) | **O verde vem do `fog_color`, não do `absorption`** — confirmar que sobrevive |
| C4 | Deep dark / sculk | Escuridão máxima; `ambient` no piso; tocha com halo contido |
| C5 | **Túnel sob planícies (Y ≈ 12)** | Bruma modesta + tom frio; confirmar que **não** é tão densa quanto C1 (limitação documentada) |
| C6 | Mesmo túnel a Y ≈ 10 vs Y ≈ 100 | Gradiente vertical visivelmente diferente |
| C7 | **Regressão de superfície**: vale de planícies a Y ≈ 40 | Névoa **subtil**, paisagem **não** encoberta — teste de regressão do piso universal |
| C8 | Teto do Nether (Y ≈ 120) e do End (Y ≈ 240) | Densidade coerente com os perfis por dimensão |
| C9 | Render distance 4 vs 16 chunks | As cavernas usam `fixed`, então não devem mudar |

#### Integração e sanidade

| # | Cenário | Critério de aceitação |
|---|---|---|
| S1 | Caminhar de floresta → campo | Interpolação suave, sem degrau |
| S2 | Content log | **Zero** `CONTENT_ERROR` |
| S3 | Console | Nenhum aviso de JSON/schema |
| S4 | Outro pack de iluminação ativo | Colocar este no topo; verificar precedência |
| S5 | Modo clássico (VV desligado) | Névoa de distância + cores de céu/água presentes, sem erro |
| S6 | Desempenho | Observação qualitativa. **Não registrar FPS sem medição real.** |

---

## 5. Como reportar problemas

Inclua sempre:

1. Versão exata do jogo (*Settings → About*).
2. Modo gráfico ativo (Vibrant Visuals sim/não).
3. Bioma e altura (`F3`).
4. Hora do dia (também no `F3`).
5. Se o content log tem `CONTENT_ERROR` e o trecho relevante.
6. O JSON exato que você alterou, se alterou algo.

---

## 6. Compatibilidade futura

| Situação | Comportamento |
|---|---|
| Bioma novo em versão futura | Não terá atribuição nossa → herda os **defaults globais** (`lighting/global.json`, `atmospherics/atmospherics.json`, `color_grading/color_grading.json`, `water/water.json`). Fog cai no vanilla. Não quebra, mas fica inconsistente |
| Remoção de um bioma | O `client_biome.json` correspondente fica sem uso — inofensivo |
| Atualização do vanilla | `tools/generate-biomes.ps1 -RefreshVanilla` reimporta o baseline; a tag está fixada em `tools/biome-map.ps1` |
| Mudança de schema do jogo | `validate.ps1` avisa quando um `format_version` esperado deixa de bater. Não detecta schemas novos |

---

## 7. Lacunas conhecidas

1. **Nenhuma validação visual foi feita.** É a maior lacuna do projeto.
2. **Nenhuma medição de desempenho.** Os riscos R7/R8 são qualitativos.
3. **Merge de `client_biome` entre packs não documentado** — a mitigação é
   defensiva, não comprovada.
4. **Nome do arquivo de sombras em desacordo entre as fontes** — omitido.
5. **`local_lighting/` sem precedente no vanilla 1.26.50.4** — omitido.
6. **`waves`, `caustics`, `tone_mapping` e `orbital_offset_degrees` não podem ser
   interpoláveis.** Qualquer mudança precisa ser replicada em todos os arquivos do
   mesmo tipo, ou a validação falha.