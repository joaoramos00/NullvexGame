# Spec — Sala de Teste de Batalha (ImgDebug › BATALHA)

**Data:** 2026-06-14
**Arquivo único afetado:** `ui/img_debug.gd` (+ web export ao final)

## Objetivo

Adicionar ao `ImgDebug` uma nova seção **BATALHA**: uma sala de treino, com as
dimensões reais da sala do boss do Stage 00, onde o jogador escolhe qual dos 11
bosses enfrentar e luta com o Zael. É um **modo treino** — boss e player são
invencíveis (HP altíssimo); a luta nunca termina por morte de nenhum dos dois.

Reaproveita o padrão já existente da seção MOVIMENTOS (`_MovView` + `_MovWorld`):
um `SubViewport` com um mundo jogável embutido no overlay do ImgDebug.

## Decisões (definidas no brainstorm)

| Tema | Decisão |
|------|---------|
| Tipo de luta | **Treino / dummy** — boss e player invencíveis (HP 99999) |
| Roster | **Todos os 11 bosses** (8 elementais + IntroBoss + Nullvex + Nullvex True) |
| Player | **Só Zael**, tiro padrão Single |
| Seleção de boss | **Grade de botões** com o nome de cada boss |
| Tamanho da sala | **Tamanho real** da sala do boss do Stage 00 |
| Sair da sala | **ESC** e **Enter** voltam à tela de seleção |
| Entrada da seção | **Tela de seleção primeiro** (escolhe e entra) |
| Botão "Sair" | Fica na tela de seleção; fecha a seção BATALHA e volta ao ImgDebug normal |

## Fluxo (máquina de 2 estados)

```
Abrir seção BATALHA
   └─> [SELEÇÃO]  grade dos 11 bosses  +  botão "Sair"
          • clicar num boss ──> [BATALHA]
          • "Sair" ──────────> fecha a seção, volta ao ImgDebug normal
   [BATALHA]  sala real + Zael + boss (treino, ambos invencíveis)
          • ESC  ──> volta a [SELEÇÃO]
          • Enter ─> volta a [SELEÇÃO]
```

A **tela de seleção é o hub central**: tanto ESC quanto Enter, dentro da sala,
retornam a ela. O botão "Sair" só existe na tela de seleção.

## Dimensões reais da sala (extraídas de `stages/stage_00/stage_00.tscn`)

| Nó | Centro | Tamanho |
|----|--------|---------|
| `Boss_Floor` | (17570, 312) | (896, 64) → superfície (topo) em **y = 280** |
| `Boss_Ceil`  | (17570, -136) | (896, 64) → face de baixo em **y = -104** |
| `Boss_LWall` | (17122, 88) | (64, 512) → face interna em **x = 17154** |
| `Boss_RWall` | (18018, 88) | (64, 512) → face interna em **x = 17986** |

- **Grade de tiles (outer):** 15 colunas × 8 linhas de 64px (960 × 512 px).
  - left = 17090, right = 18050, top = -168, bottom = 344.
- **Interior jogável:** 832 × 384 px.
- **Câmera:** centro (17570, 88), zoom **2.0** (igual `_BOSS_CAM_CENTER`/`_BOSS_CAM_ZOOM`).
- As coordenadas podem ser deslocadas para uma origem local conveniente no
  `SubViewport`, desde que a proporção/escala (15×8 tiles, zoom 2.0) seja mantida.
- Caixa **totalmente fechada** — sem abertura de porta (diferente do
  `_draw_boss_room` original, que abre o vão do corredor na parede esquerda).

## Componentes

### 1. `_build_ui()` — registrar a seção
- Adicionar botão `BATALHA` na `section_row` (ao lado de MOVIMENTOS/HITBOXES),
  com o mesmo estilo (`font_size` 28, `pressed.connect(_show_section.bind("BATALHA"))`).
- Criar `_battle_box: VBoxContainer` e adicioná-lo ao `main`.
- Registrar `"BATALHA"` em `_show_section` (mostra `_battle_box`, esconde os demais).
- Instanciar `_BossBattleView` dentro de `_battle_box` (lazy build no primeiro
  `_show_section("BATALHA")`, como as outras seções fazem com `_build_*`).

### 2. `_BossBattleView extends Control` (nova classe interna)
Espelha a estrutura de `_MovView`.

- **Estado SELEÇÃO:**
  - Grade (`GridContainer`/`HBoxContainer`) com 11 botões nomeados via `BOSS_NAMES`.
    Clicar no botão `i` → `_enter_battle(i)`.
  - Botão **"Sair"** → fecha a seção BATALHA (volta à última seção do ImgDebug,
    ex.: `_show_section("SPRITES")`, ou esconde `_battle_box`).
- **Estado BATALHA:**
  - `SubViewportContainer` (stretch) → `SubViewport`
    (`handle_input_locally = false`) → `_BossBattleWorld`.
  - `_enter_battle(i)`: mostra o viewport, esconde a grade, chama
    `world.load_boss(i)`.
- **Input:** `_unhandled_key_input` captura `KEY_ESCAPE` e `KEY_ENTER` →
  `_show_selection()` (volta ao estado SELEÇÃO). Marcar como handled. O movimento
  do Zael continua chegando ao player (o SubViewport não consome essas teclas).

### 3. `_BossBattleWorld extends Node2D` (nova classe interna)
Espelha `_MovWorld`.

- `_ready()`: `GameManager.active_character = "zael"`, define `GameManager.max_hp`,
  `GameManager.zael_selected_shot = "single"`; `texture_filter = NEAREST`; `_build()`.
- **`_build()`:** monta a sala fechada (física + câmera), spawna o player.
  Não spawna boss até `load_boss` ser chamado.
- **Sala (física):** 4 `StaticBody2D` (`collision_layer = 1`) com `RectangleShape2D`
  formando a caixa fechada: chão (superfície y=280), teto, parede esquerda, parede
  direita — nas dimensões reais acima. Paredes sólidas normais (wall-grab permitido,
  irrelevante por ser caixa com teto).
- **Sala (visual):** `_draw()` portando a lógica de `_draw_boss_room`
  (`stage_00_scene.gd`): grid 15×8 com `Stage_00T.png`, cantos côncavos via o
  mapeamento canônico (TL=(3,1) TR=(2,2) BL=(2,0) BR=(1,1), teto=(1,2), chão=(3,0),
  parede_esq=(3,2), parede_dir=(1,0)), com os shifts de meia-célula. **Remover** o
  trecho da abertura da porta (a caixa é fechada). Fundo opcional simples (painéis
  escuros, como o `boss_room` background do stage).
- **Câmera:** `Camera2D` central na sala, zoom 2.0.
- **Player Zael:**
  - `_spawn_player()`: instancia `res://characters/ranged/zael.tscn`, posiciona no
    chão (esquerda da sala), `add_to_group` conforme necessário.
  - **Invencível:** `max_hp`/`current_hp` altíssimos (treino). `died` reconecta
    `_spawn_player` por segurança.
- **`load_boss(i)`:**
  - `queue_free` do boss anterior se válido.
  - Instancia `BOSS_PATHS[i]` (todos extendem `BossBase`).
  - Seta `player`, `arena_left`/`arena_right` (interior com margem),
    `arena_floor = 280`, `max_hp = current_hp = 99999`, `state = State.COMBAT`.
  - **Não** conecta `boss_defeated` (treino não termina).
  - Bosses voadores funcionam normalmente (`gravity_scale` próprio no `_ready`).

### 4. Constantes (na `_BossBattleView` ou no escopo do ImgDebug)
```gdscript
const BOSS_PATHS := [
    "res://characters/bosses/ignarath.tscn",
    "res://characters/bosses/cryovex.tscn",
    "res://characters/bosses/voltrix.tscn",
    "res://characters/bosses/gravitus.tscn",
    "res://characters/bosses/galerix.tscn",
    "res://characters/bosses/umbraex.tscn",
    "res://characters/bosses/luxar.tscn",
    "res://characters/bosses/terragor.tscn",
    "res://characters/bosses/intro_boss.tscn",
    "res://characters/bosses/nullvex.tscn",
    "res://characters/bosses/nullvex_true.tscn",
]
const BOSS_NAMES := [
    "Ignarath", "Cryovex", "Voltrix", "Gravitus", "Galerix", "Umbraex",
    "Luxar", "Terragor", "IntroBoss", "Nullvex", "Nullvex True",
]
```

## Escopo / fora de escopo

- **No escopo:** tudo dentro de `ui/img_debug.gd`. Zero alterações em scripts de
  boss, stages, ou autoloads.
- **Fora de escopo:** luta real com derrota/vitória; seleção de Zara; seleção de
  arma/tiro; HUD de boss; salvar progresso.

## Validação

- Rodar headless: a cena do ImgDebug deve carregar sem erro de parse.
- Abrir cada boss pela grade não deve gerar erro (todos extendem `BossBase`).
- **Web export** ao final (convenção do projeto: sempre exportar web e reiniciar
  o localhost após qualquer mudança de código). Verificação preferencialmente por
  análise estática, sem rodar no browser sem pedir.
