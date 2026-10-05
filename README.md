# Cinematic Atmosphere — Bedrock

Resource pack de iluminação, atmosfera, névoa volumétrica e color grading para
**Minecraft: Bedrock Edition**. Não substitui nenhuma textura, modelo, som ou
elemento de jogabilidade — apenas reconfigura como o mundo é iluminado e
atmosphericamente colorido.

- **Alvo:** Minecraft Bedrock **1.26.50.x** (release estável `v1.26.50.4` da Mojang)
- **Mínimo:** **1.26.50** (`min_engine_version`)
- **Mecanismo:** **Vibrant Visuals** (capability `"pbr"`)
- **Itens no pack:** 130 arquivos — 129 `.json` + `pack_icon.png`
- **Namespace:** `cba`

### Baixar

| | |
|---|---|
| Release pronta para instalar | [`dist/Cinematic_Atmosphere_Bedrock.mcpack`](https://github.com/Gui8092/cinematic-atmosphere-bedrock/releases/latest) |
| Código-fonte | `git clone https://github.com/Gui8092/cinematic-atmosphere-bedrock.git` |
| Recompilar | `.\tools\build.ps1` — PowerShell, sem dependências |

---

## 1. Requisitos

| Item | Valor |
|---|---|
| Versão mínima do jogo | **1.26.50** (`min_engine_version`) |
| Versão de desenvolvimento | 1.26.50.x |
| SO principal | Windows 10 / 11 |
| Modo gráfico | **Vibrant Visuals** ativado |
| GPU | Suporte a DirectX 12 |

> **Por que 1.26.50 e não 1.26.0?** O arquivo de bioma de `dappled_forest` usa
> `format_version` `1.26.50` na referência oficial, e este pack **preserva o
> formato original de cada bioma** em vez de rebaixá-lo. Rebaixar poderia mudar a
> interpretação do schema ou fazer o motor rejeitar propriedades. Logo, o mínimo
> coerente é a maior versão de formato efetivamente usada.

> **Importante:** a partir da versão **1.26.0** o Minecraft passou a numerar
> releases por ano (`26.x`). Nos arquivos JSON e no `min_engine_version` o
> vetor continua sendo `1.26.x`. É isso que o `manifest.json` deste pack usa.

---

## 2. Instalação

1. **Ative o Vibrant Visuals primeiro** (senão o pack não tem efeito):
   *Minecraft → Settings → Video settings → Graphics Mode* → marque
   **Vibrant Visuals**.
   > A opção só aparece numa versão compatível. Se não aparecer, atualize o jogo.
2. Feche o Minecraft.
3. **Clique duas vezes** em `dist\Cinematic_Atmosphere_Bedrock.mcpack`.
   O Bedrock importa o pack e abre a tela de Add-Ons.
4. Em *Settings → Global Resources* (ou por mundo, em
   *Create New World → Settings → Add-Ons → Resource Packs*), **ative o pack**.
   Se outro pack de iluminação estiver ativo, coloque o Cinematic Atmosphere
   **acima** dele na lista — a ordem importa.
5. Crie/entre em um mundo. Os biomas só mudam de aparência com o mundo já
   carregado; chunks antigos podem precisar de um minuto para aplicar.

### Alternativa para desenvolvimento

Copie a pasta `resource_pack\` para:

```
%appdata%\Minecraft Bedrock\users\shared\games\com.mojang\development_resource_packs\Cinematic_Atmosphere\
```

Reinicie o jogo. Use `/reload all` para recarregar após edições.

---

## 3. Compatibilidade por modo gráfico

| Efeito | Vibrant Visuals | Modo clássico (sem VV) |
|---|:--:|:--:|
| Névoa de distância (alcance e cor por bioma) | ✅ | ✅ |
| Cor do céu / água por bioma | ✅ | ✅ |
| Iluminação solar/lunar por hora | ✅ | ❌ |
| Céu Rayleigh / Mie, amanhecer e pôr do sol | ✅ | ❌ |
| Névoa volumétrica e feixes de luz | ✅ | ❌ |
| Tone mapping (ACES) e color grading | ✅ | ❌ |
| Caustics e propagação de partículas na água | ✅ | ❌ |
| Nuvens reagindo ao espalhamento atmosférico | ✅ | ❌ |

**Não existe uma segunda variante do pack para o modo clássico.** As mesmas
`fogs\*.json` (bloco `distance`) e os componentes `sky_color` /
`water_appearance` funcionam nos dois pipelines — por isso o mesmo `.mcpack`
serve para os dois casos. No modo clássico você recebe névoa de distância e
cores de céu/água por bioma; nada mais.

---

## 4. O que o pack faz, por ambiente

| Ambiente | Identificadores | Resumo |
|---|---|---|
| Temperado (planícies, florestas leves, rios) | `cba:lighting_overworld` · `cba:atmos_overworld` · `cba:cg_overworld` · `cba:fog_default` · `cba:water_fresh` | Céu com Rayleigh alto de dia, gradiente dourado no crepúsculo, névoa que começa tarde |
| Floresta densa (jungle, dark forest, taiga, grove) | `cba:lighting_forest` · `cba:fog_forest` | `sky.intensity` 0.62, névoa mais densa, HG 0.80 para **feixes de luz** entre as árvores |
| Taiga e neve | `cba:lighting_cold` · `cba:atmos_cold` · `cba:cg_cold` | Temperatura 8200 K, azul frio, névoa difusa mais presente |
| Montanhas e picos | `cba:lighting_mountain` · `cba:fog_mountain` | Contraste maior, névoa alta (`zero_density_height` 190) que **separa planos** sem encobrir picos |
| Deserto e Badlands | `cba:lighting_hot` · `cba:atmos_hot` · `cba:cg_hot` | Céu lavado de zênite turquesa, horizonte quente, quase sem névoa |
| Savana | `cba:lighting_hot` · `cba:atmos_hot` · `cba:cg_hot` | Idêntico ao deserto, Via `cba:fog_hot` |
| Oceanos | `cba:lighting_ocean` · `cba:fog_ocean` + 4 águas | Mar funde com o horizonte; água por concentração de partículas |
| Pântano | `cba:lighting_swamp` · `cba:cg_swamp` · `cba:fog_swamp` | Névoa **rasteira** (`zero_density_height` 96), verdes-oliva |
| Cavernas | `cba:lighting_cave` · `cba:cg_cave` · `cba:fog_cave` | Escuro frio com **personalidade**, bruma uniforme, tochas com halo contido |
| Pale Garden | `cba:lighting_cold` · `cba:cg_cave` · `cba:fog_cold` | Superfície fria com grade de caverna |
| Nether | `cba:lighting_nether` · `cba:atmos_nether` · `cba:cg_nether` | 3400 K, névoa densa e curta, **sem fluorescência** |
| End | `cba:lighting_end` · `cba:atmos_end` · `cba:cg_end` | Violeta profundo, flash sutil, sensação de isolamento |



---

## 5. Ajustes rápidos (receitas)

Todos os valores são planos e reversíveis. Reinicie o mundo ou use
`/reload all` após salvar.

| Quer… | Arquivo | Mudança |
|---|---|---|
| Mais drama nas sombras | `color_grading\*.json` | `shadows.offset` de `±0.01` para `±0.02` |
| Menos névoa em floresta | `fogs\forest.json` | `volumetric.density.air.max_density` de `0.026` para `0.018` |
| Mais separação de planos nas montanhas | `fogs\mountain.json` | `distance.air.fog_start` de `0.62` para `0.52` |
| Céu mais azul ao meio-dia | `atmospherics\atmospherics.json` | `sky_zenith_color["0.000000"]` → mais azul, ex. `[84,118,172]` |
| Pôr do sol mais dramático | `atmospherics\atmospherics.json` | `sun_mie_strength` de `1.1` para `1.4` |
| Noite mais clara | `lighting\global.json` | `ambient.illuminance["0.500000"]` de `0.010` para `0.018` |
| Cavernas mais escuras | `fogs\cave.json` | `max_density` de `0.055` para `0.075` |
| **Ligar ondas na água** | `water\*.json` (todos, igual) | `waves.enabled` → `true` |
| Voltar ao visual mais parecido com o vanilla | `color_grading\*.json` (todos, igual) | `tone_mapping.operator` → `"generic"` |

### Receita: cor de luz de tochas e lanternas

Não é incluído no pack (mudaria a direção artística aprovada). O caminho é
documentado pelo Mojang (Learn, "Light Sources"), mas **nunca foi testado dentro
do jogo neste projeto** — use por sua conta e risco. Crie
`resource_pack\local_lighting\local_lighting.json`:

```json
{
  "format_version": "1.21.120",
  "minecraft:local_light_settings": {
    "minecraft:torch":        { "light_type": "point_light", "light_color": "#FFD9A8" },
    "minecraft:lantern":      { "light_type": "point_light", "light_color": "#FFB870" },
    "minecraft:candle":       { "light_type": "point_light", "light_color": "#FFD9A8" },
    "minecraft:end_rod":      { "light_type": "point_light", "light_color": "#FFFFFF" },
    "minecraft:soul_torch":   { "light_type": "point_light", "light_color": "#7FD8FF" },
    "minecraft:soul_lantern": { "light_type": "point_light", "light_color": "#7FD8FF" }
  }
}
```

> ⚠️ `light_type` é **obrigatório** no schema. Os valores acima reproduzem a
> classificação que o jogo já usa, então só a cor muda. Point lights são
> custosas — o jogo limita a quantidade por hardware.

> ⚠️ `tone_mapping.operator`, `orbital_offset_degrees`, `caustics` e `waves` **não
> são interpoláveis** entre biomas. Se mudar, mude em **todos** os arquivos do
> mesmo tipo, senão `validate.ps1` acusa.

Detalhes e justificativas de cada decisão: [`docs/art-direction.md`](docs/art-direction.md).
O que **não** foi decidido, com o custo de cada alternativa — incluindo a cor de
grama e folhagem, que está em aberto: [`docs/scope-decisions.md`](docs/scope-decisions.md).

### Se preferir zero conteúdo transcrito

Os 89 arquivos de bioma reproduzem componentes vanilla para preservar som,
música e cores. Se você preferir um pack **sem nenhum valor transcrito** da
referência da Mojang:

```powershell
.\tools\generate-biomes.ps1 -Minimal
.\tools\build.ps1
```

**Leia o tradeoff antes:** o modo `-Minimal` escreve só os 6 identificadores
Vibrant Visuals. Se o motor **substituir** o `client_biome` vanilla em vez de
mesclar por componente — algo que a documentação **não esclarece** — os biomas
perderiam `ambient_sounds` (88 de 89), `biome_music` (56 de 89),
`water_appearance` (89 de 89), cores de grama/folhagem e `sky_color`. O modo
padrão é seguro nas duas hipóteses.

Para voltar ao padrão: `.\tools\generate-biomes.ps1` (sem `-Minimal`).

---

## 6. Ferramentas

Todas em PowerShell, **sem dependências externas**. O caminho padrão é
**100% offline** — a única operação que acessa a rede é o `-SyncBaseline`.

```powershell
.\tools\validate.ps1                        # 115 verificações estáticas (offline)
.\tools\validate.ps1 -CheckOfficial         # + 2: compara com a referência oficial (requer internet)
.\tools\validate.ps1 -SkipArtifact         # usado por build.ps1 antes de empacotar
.\tools\fog-report.ps1                    # densidade de fog por altura vs vanilla
.\tools\test-negative.ps1                   # 29 testes negativos do verificador de pacote
.\tools\verify-package.ps1 -Package <arquivo> # verificação autônoma de um .mcpack
.\tools\build.ps1                            # valida, empacota e verifica dist\*.mcpack
.\tools\generate-biomes.ps1                  # regenera os 89 biomas (usa o baseline local)
.\tools\generate-biomes.ps1 -SyncBaseline    # reimporta a referência fixada (requer internet)
```

| Script | Função |
|---|---|
| `biome-map.ps1` | Fonte única de verdade: identificadores, 16 famílias, versão por tipo, regra de cubemap |
| `vanilla-baseline.json` | Baseline transcrito da referência oficial (procedência declarada) |
| `generate-biomes.ps1` | Gera os 89 arquivos a partir do mapa + baseline |
| `validate.ps1` | Blocos `[A]`–`[F]`: sintaxe, manifesto, referências, versões, schemas, procedência |
| `verify-package.ps1` | Verificação de segurança do `.mcpack` — **autônoma**, não divide lógica com o `validate.ps1` |
| `test-negative.ps1` | Prova que `verify-package.ps1` **reprova** o que deve reprovar |
| `fog-report.ps1` | Densidade do fog por altura **e alcance em blocos** vs vanilla — auditável sem o jogo |
| `water-report.ps1` | Física dos 6 perfis de água + tabela perfil × `surface_color` (luminância, spread, calor) + o acoplamento com o spread do sol |
| `build.ps1` | Orquestra em 4 etapas: valida → empacota → verifica o pacote → revalida incluindo o artefato |

Detalhe do inventário: [`docs/inventory.md`](docs/inventory.md).

---

## 7. Procedência e licença

O `LICENSE` aplica a **MIT** ao código, às ferramentas, à documentação e às
configurações escritas originalmente para este pack (tudo em `lighting/`,
`atmospherics/`, `color_grading/`, `water/`, `fogs/`, `cubemaps/`).

Os **89 arquivos de `biomes/`** incorporam um punhado de **valores factuais**
transcritos do pack oficial da Mojang: identificadores de bioma, de evento de
som e de faixa de música, e cores hexadecimais. Nenhum arquivo foi copiado e
**nenhum asset oficial** (textura, modelo, som, geometria, partícula) está no
repositório.

A licença declarada pela Mojang para o material de referência é
*"(c) Mojang AB. All rights reserved — sujeito ao Minecraft EULA"*. A análise
completa, com as categorias de conteúdo e as citações do EULA, está em
[`NOTICE`](NOTICE) e em [`docs/research.md`](docs/research.md) §11.

> Isto é uma leitura técnica das licenças, **não um parecer jurídico**.

---

## 8. Estado dos testes

| Categoria | Estado |
|---|---|
| Testes estáticos (sintaxe, manifesto, referências, versões, schemas, procedência, BOM, alcance do fog, água, artefato) | ✅ **Executados — 115 verificações, 0 falhas, 0 avisos** |
| Testes negativos do verificador de pacote | ✅ **Executados — 29 casos, 0 falhas** |
| Comparação com a referência oficial (com rede) | ✅ **Executado — 117 verificações, inventário idêntico aos 89 biomas** |
| Empacotamento e estrutura do `.mcpack` | ✅ **Executado** — 130 entradas, `manifest.json` na raiz, SHA256 registrado |
| **Testes visuais dentro do Minecraft** | ⏳ **NÃO executados** — exige acesso ao jogo e a hardware |
| **Medição de desempenho / FPS** | ⏳ **NÃO executada** — nenhum número de FPS é alegado |

> Este projeto foi desenvolvido e validado apenas por análise estática. **Nenhuma
> captura de tela, nenhum teste in-game e nenhuma medição de desempenho foram
> realizados.** Os valores são pontos de partida fundamentados nos arquivos do pack
> vanilla oficial (`Mojang/bedrock-samples@v1.26.50.4`) e na documentação, e
> precisam de calibração visual com você dentro do jogo.
> Checklist de testes visuais: [`docs/compatibility.md`](docs/compatibility.md).

---

## 9. Solução de problemas

| Sintoma | Causa provável | O que fazer |
|---|---|---|
| O pack ativa mas **nada muda** | Vibrant Visuals desligado | Settings → Video settings → Graphics Mode → marque Vibrant Visuals; reinicie o mundo |
| Só alguns biomas mudaram | Outro pack de iluminação ativo acima | Desative o outro pack ou coloque o Cinematic Atmosphere no topo da lista |
| Erros no content log | JSON com problema | Rode `.\tools\validate.ps1`; se acusar algo, o `.mcpack` não foi gerado |
| O pack não aparece na lista | Versão do jogo abaixo de 1.26.0 | Atualize o jogo; `min_engine_version` bloqueia versões antigas de propósito |
| Névoa atrapalhando a visão | `max_density` alto demais | Reduza `volumetric.density.air.max_density` no `fogs\` do bioma |
| Céu com cara de "horizonte cortado" | `horizon_blend_stops` alterado | Restaure `start: 0.8` no meio-dia e `max: 0.25` |
| Sombreamento estranho ao passar de bioma | `orbital_offset_degrees` divergente | Use o mesmo valor em todos os `lighting\*.json` (o validador checa isso) |

Content log (diagnóstico oficial): o jogo grava erros de conteúdo quando
`content-log-file-enabled` está ativo; os arquivos ficam na pasta de dados do
Minecraft. Se encontrar `CONTENT_ERROR` relacionado a este pack, reporte com o
JSON em questão.

---

## 10. Escopo e limitações declaradas

Este pack **não** faz, e não promete fazer:

- **Iluminação global (GI) controlável.** Não existe GI por pack. A aproximação
  usa `sky.intensity`, `ambient` e color grading de sombras.
- **Sombras suaves suaves.** Só existem dois estilos: `blocky_shadows` e
  `soft_shadows`. O padrão do jogo já é soft; por isso **nenhum arquivo de
  sombras é incluído** (ver `docs/inventory.md`).
- **Névoa colorida por bioma.** Com Vibrant Visuals a absorção usa só
  luminância (`0.2126R + 0.7152G + 0.0722B`); a cor vem do `fog_color`, da
  atmosfera e do color grading.
- **Detecção de "estou subterrâneo".** `zero_density_height` e
  `max_density_height` são um **perfil vertical em Y absoluto**, não um detector.
  Ver `docs/art-direction.md` § Cavernas.
- **Feixes de luz garantidos em qualquer hardware.** O efeito depende do
  pipeline e do GPU; a configuração só cria as condições (HG alto, densidade
  calibrada).

Detalhamento completo e fontes: [`docs/research.md`](docs/research.md) e
[`docs/compatibility.md`](docs/compatibility.md).

---

## 11. Estrutura

```
.
├── README.md
├── CHANGELOG.md
├── LICENSE                    MIT (com escopo delimitado)
├── NOTICE                     procedência e licenciamento dos valores transcritos
├── .gitignore
├── docs\
│   ├── research.md          pesquisa, fontes, licenciamento, decisões técnicas
│   ├── compatibility.md     matriz de compatibilidade, riscos, checklist visual
│   ├── art-direction.md     direção artística por ambiente e o caso das cavernas
│   └── inventory.md         inventário definitivo de arquivos
├── resource_pack\           ← esta pasta é o que entra no .mcpack
│   ├── manifest.json
│   ├── pack_icon.png
│   ├── lighting\        10 arquivos
│   ├── atmospherics\     5 arquivos
│   ├── color_grading\    7 arquivos
│   ├── water\            6 arquivos
│   ├── fogs\            10 arquivos
│   ├── cubemaps\         1 arquivo
│   └── biomes\          89 arquivos
├── tools\                   biome-map, vanilla-baseline, generate-biomes,
│                             validate, verify-package, test-negative, build
└── dist\                    Cinematic_Atmosphere_Bedrock.mcpack
```

**152 arquivos** no total (130 no pack + 22 de projeto).

---

## Licença

MIT — veja [`LICENSE`](LICENSE).

Este projeto é um add-on **não oficial**, sem afiliação com a Mojang Studios ou
a Microsoft. Não contém nenhuma textura, modelo, som ou recurso oficial do
Minecraft; todos os arquivos de configuração são originais.
