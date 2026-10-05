# Decisões de escopo

Registro das decisões **não óbvias** que o pack tomou, com o que cada alternativa
custaria. Serve para que uma mudança de direção no futuro seja informada, e não
um salto no escuro.

Data da revisão: 2026-10-05 · Referência: `Mojang/bedrock-samples@v1.26.50.4`

---

## 1. Cor de grama e folhagem — **em aberto, aguardando decisão**

### O que está em jogo

`minecraft:grass_appearance` (13 biomas), `minecraft:foliage_appearance`
(11 biomas) e `minecraft:dry_foliage_color` (7 biomas) define a cor da grama e
das folhas. **Nenhum desses 31 biomas foi tocado** — todos preservam o valor do
vanilla, verificado por check.

### Por que estão intocados

O escopo declarado do projeto é: **só iluminação, atmosfera, névoa volumétrica e
color grading**. Cor de grama e de folha não é nenhum dos quatro. Alterar isso
mudaria a identidade visual do próprio bioma — o mesmo vale que trocar uma
textura, que é exatamente o que o pack promete não fazer.

### O que se perde

Muito. A grama e a folha ocupam a maior parte da tela numa paisagem aberta, e é
por isso que a identidade de um bioma é lida em boa parte pela vegetação. Um
pack que muda a luz mas deixa a grama intacta tem um alcance estético menor do
que poderia ter.

### As três opções

| Opção | Ganho | Custo |
|---|---|---|
| **A. Manter o escopo** | A promessa "não toca em nada que não seja luz, atmosfera, névoa ou grading" continua literalmente verdadeira. O pack é mais fácil de defender e de comparar. | A vegetação é o maior elemento visual da tela e fica com a paleta do jogo. O resultado é menos "diretor de arte", mais "iluminação de cinema sobre o jogo original". |
| **B. Ampliar o escopo** | Controle sobre a paleta de vegetação; o bioma passa a ler como uma unidade dirigida, não como uma Illuminação sobre um cenário emprestado. | É uma **quebra consciente da premissa do projeto**, e precisa ser dita como tal — não como detalhe. Também aumenta muito o espaço de erro: uma cor de grama errada é mais visível que um erro de fog. |
| **C. Abordagem seletiva** | Só os biomas com vegetação mais carregada e mais característica ganham ajuste de matiz, sem tocar na estrutura. | Exige um critério de seleção explícito e defensável, ou vira arbitrário. É o meio-caminho e o mais difícil de sustentar. |

### Recomendação técnica

**Manter o escopo por ora (A).** A ordem de decisão que faz sentido é: primeiro
confirmar dentro do jogo que a parte de luz está boa (é o que o pack controla e
o que a v1.1.0 acabou de corrigir), e só depois decidir se vale mexer na
vegetação. Inverter a ordem seria calibrar uma camada que se apoia em outra
ainda não validada.

Se a opção B for escolhida, o caminho limpo é: uma release separada, com
`docs/art-direction.md` gains a nova paleta de vegetação, e os 31 biomas
alinhados a uma regra única e reprodutível — não 31 valores escolhidos à mão.

### Como reverter / aplicar

Nada foi alterado, então não há o que reverter. Para aplicar a opção B, o
caminho é editar `resource_pack/biomes/*.client_biome.json` e remover o
`water_appearance`-style check de preservação verbatim correspondente no
`tools/validate.ps1` e `tools/vanilla-baseline.json` — que hoje **reprovaria**
qualquer mudança nesses três componentes, por design.

---

## 2. `local_lighting/` — **não usado, e o motivo mudou**

Este caminho foi validado em versões anteriores deste projeto como "caminho
confirmado". Isso estava **fraco demais**.

Verificação em 2026-10-05: o termo `local_lighting` **não aparece** em nenhum dos
6 documentos oficiais em `Mojang/bedrock-samples@v1.26.50.4/documentation/` —
nem em `Lighting.html`, `Atmospherics.html`, `Fogs.html`, `Water.html`,
`Schemas.html` nem `Client Biomes.html`.

Ou seja: **o caminho não está documentado pelo Mojang.** Sem documentação e sem
teste dentro do jogo, incluir um diretório inteiro cujo comportamento só se
descobre ao executar seria trocar controle por esperança. Fica de fora.

---

## 3. `biomes_client.json` — fora, benefício estreito

Serviria para dar um padrão a biomas customizados criados por *outros* behavior
packs. Nenhum bioma customizado é distribuído junto deste pack, e a semântica de
merge entre `biomes_client.json` e `biomes/*.client_biome.json` não está
documentada. Risco de comportamento inesperado sem ganho para o usuário-alvo.

---

## 4. `shadows/` — fora, caminho nunca verificado

Nunca houve confirmação de que o jogo carregue esse diretório de resource pack.
Mesma razão do item 2.

---

## 5. `waves` desativado — decisão deliberada e aprovada

`waves.enabled: false` nos 6 perfis de água. `waves` é um efeito baseado em
imagem que não move os vértices da superfície — é sobreposição, não geometria.
Desligado como decisão de direção de arte, e o vanilla também entrega
desligado. Um check garante que continue desligado.

---

## 6. Split-tone por `offset` — **removido por estar fora do spec**

O split-tone (highlights quentes, shadows frios) foi implementado com `gain`
**e** com `offset`. Os offsets eram valores negativos de 0,002 a 0,016.

A documentação oficial define `offset` como **0.0 a 4.0** e o descreve como "an
exponential factor" — um fator exponencial negativo não tem significado
matemático. O vanilla nunca usa `offset` em nenhum contexto
(`midtones.offset: [0,0,0,0,0,0]`).

Decisão: os 21 offsets foram zerados. **Nada se perde** — o split-tone continua
inteiro por meio do `gain`, que está em faixa válida e é o mecanismo que
efetivamente carrega o efeito:

| Perfil | `highlights.gain` (quente) | `shadows.gain` (frio) |
|---|---|---|
| overworld | `1,02, 1,00, 0,97` | `0,97, 0,99, 1,04` |
| cold | `1,00, 1,00, 1,01` | `0,96, 0,99, 1,05` |
| hot | `1,02, 1,00, 0,96` | `0,98, 0,99, 1,02` |
| cave | `0,99, 0,99, 1,00` | `0,93, 0,96, 1,04` |
| end | `1,00, 0,99, 1,02` | `0,95, 0,94, 1,03` |
| nether | `0,98, 0,97, 0,96` | `0,96, 0,95, 0,95` |
| swamp | `1,01, 1,00, 0,98` | `0,96, 1,00, 0,98` |

Vermelho > azul nas highlights, azul > vermelho nas shadows. É o padrão
teal-and-orange, em faixa válida, sem nenhum valor fora do spec.

---

## 7. A noite empilha reduções — risco aberto, sem ajuste

Quatro parâmetros abaixo do vanilla ao mesmo tempo:

| Parâmetro | Vanilla | Pack | % |
|---|---:|---:|---:|
| `rayleigh_strength` noturno | 5,0 | 2,2 | 44% |
| `ambient.illuminance` noturno | 0,02 | 0,010 | 50% |
| `ambient.color` noturno | `#FFFFFF` | `#46557A` | muito mais escuro |
| `moon.illuminance` | 0,4 | 0,34 | 85% |

Isso pode deixar a noite **escura demais para navegar**, o que seria regressão
de jogabilidade e não uma escolha estética. **Não foi ajustado** justamente por
isso: corrigir às cegas poderia torná-la pior. Precisa de olhar no jogo.