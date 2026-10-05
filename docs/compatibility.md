# Compatibilidade, riscos e plano de testes

## 1. Matriz de requisitos

| | Valor |
|---|---|
| Versão mínima | `1.26.50` (`min_engine_version: [1, 26, 50]`) |
| Versão de desenvolvimento | `1.26.50.x` (tag estável `v1.26.50.4` da Mojang) |
| SO alvo | Windows 10 / 11 |
| Modo gráfico principal | **Vibrant Visuals** |
| Modo gráfico secundário | Clássico (degradação limpa) |
| Capability do manifesto | `pbr` |

**Por que `1.26.50` e não `1.26.0`:** o arquivo de bioma de `dappled_forest` usa
`format_version` `1.26.50` na referência oficial, e o pack preserva o
`format_version` original de cada bioma em vez de rebaixá-lo. Rebaixar poderia
mudar a interpretação do schema ou fazer o motor rejeitar propriedades. Logo, o
mínimo coerente é a maior versão de formato efetivamente usada.

Não há fallback para versão antiga: um `min_engine_version` menor permitiria
ativar o pack numa versão em que parte dos arquivos seria inerte.

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
| R1 | Vanilla por bioma sobrescreve os JSONs globais | Pack "nao faz nada" | 89 `*.client_biome.json` + verificacao de cobertura em tres lados (mapa, baseline, disco) |
| R2 | Merge de `client_biome` entre packs **nao documentado** | Perda de som/musica/cores | Alteracao minima: componentes vanilla reproduzidos verbatim a partir de `tools\vanilla-baseline.json`; o validador compara o conteudo de cada bioma contra o baseline. Seguro sob as duas hipoteses (merge ou substituicao total) |
| R3 | `min_engine_version` inconsistente com `format_version` | Pack ativo mas inerte | `[1, 26, 50]` = maior formato usado; o validador compara `min_engine_version` contra o maior `format_version` presente |
| R4 | Rebaixar `format_version` de bioma | Propriedades rejeitadas ou mal interpretadas | O gerador **preserva** o formato da referencia por bioma (1.21.120 x87, 1.26.0 x1, 1.26.50 x1); o validador reprova qualquer divergencia |
| R5 | Keyframes em horarios redondos (0.25/0.75) | Ceu dessincronizado do sol | Horarios exatos do vanilla como esqueleto |
| R6 | Parametro nao interpolavel divergente | Transicoes com popping | `validate.ps1` compara `tone_mapping`, `orbital_offset_degrees`, `caustics`, `waves` |
| R7 | Absorcao de fog so em luminancia | Neblina sem cor | Cor vem de `fog_color` + atmosfera + color grading |
| R8 | Tone mapping filmico mais caro | Desempenho | `aces` por decisao artistica; `"generic"` documentado como alternativa |
| R9 | Nevoa volumetrica em hardware fraco | Desempenho | Densidades 0.010 a 0.055 (o vanilla chega a 0.25 no End); `zero_density_height` alto deixa o ar de superficie **exatamente** sem nevoa |
| R10 | Conflito com outro pack de iluminacao | Visual imprevisivel | README: ativar este pack **no topo** da lista |
| R11 | Bioma novo em versao futura fica com visual vanilla | Inconsistencia | Os quatro arquivos de nome reservado servem de default global para biomas sem atribuicao explicita |
| R12 | `shadows/` e `local_lighting/` com caminho nao comprovado | Config ignorada | **Omitidos** com justificativa (`docs/inventory.md`) |
| R13 | Verificacao de seguranca do pacote com ponto cego | Bug escapado | `verify-package.ps1` e **autonomo** e tem **29 testes negativos** que provam que reprova; nao divide logica com o `validate.ps1` |
| R14 | Build depender de rede | Irreprodutibilidade | Baseline vanilla versionado; caminho padrao 100% offline |
| R15 | Procedencia legal dos valores transcritos | Reclamacao de direitos | `NOTICE` com atribuicao, escopo do MIT e limitacao declarada de que nao e parecer juridico |
| R16 | Rampa vertical de fog nao e padrao do vanilla | Efeito diferente do esperado | Mantida por decisao tecnica, mas **documentada como original e nao verificada em jogo**; teste C10 confirma uniformidade dentro da caverna |

---

## 4. Estado dos testes

### 4.1 Testes automatizados — ✅ EXECUTADOS

`tools\validate.ps1` (offline, determinístico) e `tools\test-negative.ps1`.

| Execução | Verificações | Falhas | Avisos |
|---|---:|---:|---:|
| `validate.ps1` (padrão, sem rede) | 104 | 0 | 0 |
| `validate.ps1 -CheckOfficial` (com rede) | 109 | 0 | 0 |
| `test-negative.ps1` | 29 | 0 | 0 |

| Bloco | Cobre |
|---|---|
| `[A]` Estrutura e sintaxe | 7 diretórios obrigatórios, parse de todos os `.json` |
| `[B]` Manifesto | `format_version`, campos de `header`, UUIDs válidos e **distintos**, módulo `resources`, capability `pbr` |
| `[C]` Referenciais e cobertura | Todo identificador referenciado **existe**; namespace `cba`; sem duplicados; arquivos reservados presentes; **cobertura em três lados** — mapa ↔ baseline ↔ disco, com contagens iguais; `format_version` de cada bioma **igual ao da referência**; componentes preservados **idênticos ao baseline**; **regra de cubemap explícita** (Overworld deve ter, Nether/End nunca); comparação opcional com a referência oficial viva |
| `[D]` Versões | `format_version` por tipo de arquivo contra o conjunto aceito; distribuição por bioma; `min_engine_version` ≥ maior formato usado |
| `[E]` Schemas | alcance da névoa em blocos por perfil; **saturação mínima da cor do sol por horário** (piso 150 no pôr do sol, 90 na hora dourada); **violeta do crepúsculo** (spread ≥ 60 e azul dominante em `0.361464`/`0.654508`); 4 parâmetros não interpoláveis; `waves.enabled == false`; `operator == aces`; ranges de `ambient`, `sky`, `caustics`, partículas, `biome_water_color_contribution`, `temperature`, `contrast`/`gain`/`gamma`/`offset`/`saturation`, `shadowsMax < highlightsMin`, `fog_start < fog_end`, `max_density`, `zero_density_height ≥ max_density_height`, `henyey_greenstein_g`; ciclos de keyframe |
| `[F]` Procedência | Ausência de pastas de textura/modelo/som/material; única mídia = `pack_icon.png`; nenhum som; nenhum script; baseline declara repositorio, tag e licença |

`tools\verify-package.ps1` — **autônomo**, não depende do `validate.ps1`:
`manifest.json` na raiz, separadores `/`, diretórios e extensões proibidas,
whitelist estrita de caminhos, CRC de todas as entradas, contagem de entradas.

`tools\test-negative.ps1` prova que o verificador **reprova** o que deve
reprovar: 12 diretórios proibidos, 10 extensões proibidas, 7 casos de whitelist,
1 contagem errada, 1 pacote vazio, e 1 controle positivo.

### 4.2 Empacotamento — ✅ EXECUTADO

130 entradas, `manifest.json` na raiz, separadores `/`, CRC íntegro,
`verify-package.ps1` APROVADO, SHA-256 registrado por `build.ps1`.

### 4.3 Dependência de rede

| Comando | Rede |
|---|---|
| `validate.ps1` | **Não** (padrão) |
| `validate.ps1 -CheckOfficial` | **Sim** — opcional; sem rede emite **aviso** e não falha (verificado) |
| `test-negative.ps1` | Não |
| `verify-package.ps1` | Não |
| `build.ps1` | Não |
| `generate-biomes.ps1` | Não (usa `tools\vanilla-baseline.json`) |
| `generate-biomes.ps1 -SyncBaseline` | **Sim** — única operação que baixa a referência |

O caminho padrão é totalmente offline e reproduzível.

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
| C1 | Dripstone cave natural (Y ≈ 10–40) | Densidade **uniforme** (não cresce com a profundidade — `zero_density_height` = `max_density_height` = 320); `distance.air` encurta; ainda legível |
| C2 | Lush cave | Mesma densidade uniforme, com o verde do bioma vindo do `fog_color` |
| C3 | Sulfur cave (Y ≈ −20 a 40) | **O verde vem do `fog_color`, não do `absorption`** — confirmar que sobrevive |
| C4 | Deep dark / sculk | Escuridão máxima; `ambient` no piso; tocha com halo contido |
| C5 | **Túnel sob planícies (Y ≈ 12)** | Usa o perfil de superfície: bruma modesta + tom frio; confirmar que **não** é tão densa quanto C1 (limitação documentada) |
| C6 | Túnel sob planícies: Y ≈ 10 vs Y ≈ 100 | **Aqui sim há gradiente** (`zero_density_height` 128 → `max_density_height` 48). Esperado: mais bruma em Y=10 |
| C7 | **Regressão de superfície**: vale de planícies a Y ≈ 40 | Névoa **subtil** (0.014, ~28% do vanilla), paisagem **não** encoberta — teste de regressão do piso universal |
| C8 | Teto do Nether (Y ≈ 120) e do End (Y ≈ 240) | Densidade coerente com os perfis por dimensão |
| C9 | Render distance 4 vs 16 chunks | As cavernas usam `fixed`, então não devem mudar |
| C10 | Uma caverna a Y=10 vs outra a Y=200, mesmo bioma | **Idênticas** — confirma que o perfil é uniforme na altura e não uma camada no chão |

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
