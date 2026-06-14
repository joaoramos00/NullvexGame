# Spec — Expansão do Stage 2 (Cryovex / Gelo)

**Data:** 2026-06-14
**Arquivos afetados:** `stages/stage_02/stage_02_scene.gd`, `stages/stage_02/stage_02.tscn`

## Objetivo

O Stage 2 é curto (~14.000px de extensão, vs ~18k do Stage 00 e ~24k do Stage 01).
A ideia/tema (gelo) é boa; o problema é o **comprimento**. Dobrar a fase para
**~24.000px**, esticando cada uma das 4 zonas ~2x, mantendo estrutura, miniboss,
boss e checkpoints.

## Decisões (do brainstorm)

| Tema | Decisão |
|------|---------|
| Problema | Fase muito **curta** (não rasa) |
| Como estender | **Esticar as 4 zonas atuais** (~2x cada), não adicionar zonas |
| Alvo | **~Dobrar**: ~14k → ~24k |
| Conteúdo do espaço novo | **Os três**: plataforma de verdade + mais chão/inimigos + perigo de gelo característico por zona |
| Estilo de plataforma | **Baseado no chão** — piso com elevações + **abismos (piso+abismo)**. **SEM plataformas flutuantes no ar.** |
| Abismo Z1–Z3 | **Recuperável** (cai e volta — não mata) |
| Abismo Z4 | **Mortal, sem volta** (kill plane), com **vidro (glass) nas laterais** |

## Estrutura (mantida, deslocada para a direita)

Ordem preservada: `PlayerSpawn → Z1 → Z2 → CP1 → MiniBoss(MB02) → CP2 → Z3 → Z4 → CP3 → Boss(Cryovex)`.
Como cada zona cresce ~2x, **tudo a jusante desloca para a direita** (corredores,
miniboss, gates de fraqueza, colectáveis, boss entry). Layout-alvo aproximado
(x; ajuste fino no plano respeitando o pulo do jogo: máx ~118px / alcance ~196px):

| Elemento | Atual (x) | Novo (x, aprox) |
|----------|-----------|-----------------|
| Z1 | 180–2900 | 180–5600 |
| Z2 | 2900–5400 | 5600–10600 |
| CP1 | 5400–6200 | 10600–11400 |
| MiniBoss | 6300–7100 | 11500–12300 |
| CP2 | 7200–8000 | 12400–13200 |
| Z3 | 8000–10400 | 13200–18000 |
| Z4 | 10400–13200 | 18000–23600 |
| CP3 | 13200–14000 | 23600–24400 |
| Boss entry | 14150 | 24550 |

## Plataforma — regra geral (Z1–Z3)

**Baseado no chão, nunca flutuante.** Reusar o vocabulário de terreno que o projeto
já tem:
- **Piso + plataforma elevada** (modo `floor_platform` / helpers `_fp_*` do imgdebug e
  do `stage_00_scene`): seções de piso mais altas (≤1 tile = 64px, saltáveis) sobre o
  piso base, com junções côncavas.
- **Piso + abismo recuperável** (modo `floor_platform_hole` / `floor_holes`): o "abismo"
  é um **poço com fundo** (nível de piso mais baixo) OU um vão entre seções de piso onde,
  ao cair, o player **pousa no piso base contínuo e consegue voltar** (subir por degrau/
  parede curta ≤ pulo, ou seguir pelo piso de baixo). **Não é kill plane.**
- A profundidade dos poços recuperáveis respeita o pulo (≤ ~118px para sair pulando, ou
  com degrau/parede de retorno).

## Perigo de gelo característico por zona

- **Z1 — Chão escorregadio:** reusar `StageIceFloor` (Area2D já existente) cobrindo o
  piso da Z1 → momentum/derrapagem; abismos recuperáveis tornam a derrapagem perigosa
  (mas sem morte).
- **Z2 — Espinhos de gelo:** reusar `Z2_Spikes` (Area2D) — campos de espinhos no piso,
  com seções de piso seguro entre eles; abismos recuperáveis ao redor.
- **Z3 — Nevasca que empurra:** reusar `Z3_Blizzard` (Area2D) — vento lateral que
  dificulta os pulos sobre os abismos recuperáveis.
- **Z4 — Abismos congelados MORTAIS:** vãos **sem fundo** (abertos abaixo do kill plane →
  morte) sobre plataformas de travessia (piso). As **laterais dos abismos são de vidro**
  (textura glass + grupo `no_wall_grab`, como nos corredores) — sem wall-grab, queda
  limpa. Travessia por pulos precisos entre seções de piso.

## Inimigos

Expandir os arrays de posição por zona em `stage_02_scene.gd` (`Z1_*`..`Z4_*`) para
cobrir o novo comprimento — mais grunts/flyers/archers/turrets/bombers/shields/wisps
distribuídos ao longo de cada zona esticada (densidade similar à atual, só que ao longo
do dobro do espaço). Reaproveitar o roster e o spawn por zona já existente
(`_spawn_zone_enemies`).

## Componentes / Arquitetura

- **`stage_02_scene.gd`** (segue o padrão procedural do `stage_01_scene.gd`, que tem
  `_build_zone2/3/4`):
  - Novas funções `_build_zone1()`..`_build_zone4()` que **removem os blocos antigos**
    (`Z*_Block*` do `.tscn`) e montam a zona esticada via código: piso base, seções
    elevadas, poços (recuperáveis em Z1–3; mortais+glass em Z4), e posicionam/escalam o
    perigo de gelo da zona.
  - Recalcular as constantes de layout (`_CP1_ENTRY_X`/`_EXIT_X`, `_MB_LEFT/RIGHT`,
    `_CP2_*`, `_CP3_*`, e o boss entry) para o novo layout deslocado.
  - Expandir os arrays `Z1_*`..`Z4_*` de inimigos.
  - Ajustar `_setup_zone_triggers` (Rects das zonas) para as novas faixas X.
  - Reusar helpers de desenho de terreno (`_draw_terrain_block`, `_tile_at`,
    `_texture_for_node`) e, para poços cortados, o padrão `floor_holes`/`_pit_tile_at`
    do Stage 1.
- **`stage_02.tscn`**:
  - Remover os `Z*_Block*` antigos (substituídos pelos builders).
  - Reposicionar markers, colectáveis (SubTank/Armadura/Coração), gates de fraqueza
    (`Z2_IgnarathGate`, `Z4_LuxarGate`), e `BossEntryMarker` para o layout novo.
  - Manter/reposicionar os perigos `StageIceFloor`, `Z2_Spikes`, `Z3_Blizzard` (ou
    recriá-los nos builders, conforme ficar mais limpo).

## Mantido (não muda)
- Roster de inimigos, miniboss (MB02), boss (Cryovex), 3 checkpoints/corredores,
  gates de fraqueza, colectáveis, tilesets por zona (z1–z4), kill plane por fase.

## Validação
- Carregar `res://stages/stage_02/stage_02.tscn` headless sem `SCRIPT ERROR`.
- Conferir (debug `?zone=N` ou bot) que cada zona é transponível: pulos respeitam
  ~118px/196px; poços recuperáveis Z1–3 permitem voltar; abismos Z4 matam (kill plane)
  e têm glass lateral.
- Inimigos spawnam ao longo de toda a extensão nova.
- **Web export** ao final + reiniciar localhost (convenção do projeto).
