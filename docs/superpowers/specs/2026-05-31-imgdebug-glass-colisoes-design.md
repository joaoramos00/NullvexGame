# ImgDebug — Glass Colisões Design

**Data:** 2026-05-31
**Contexto:** A aba TILES > Colisões do ImgDebug já exibe colisões do Stage_00T (modos Lateral e Cantos). Este spec adiciona uma segunda seção "Vidro" no mesmo tab, com 5 modos específicos para o glass tile (`stage_00_glass.png`).

---

## Objetivo

Adicionar visualização de debug para todas as propriedades de colisão do vidro: face de contato, cantos, gap inferior, contraste com parede normal, e estrutura do painel completo.

---

## Estrutura na UI

O `col_panel` (VBoxContainer do tab Colisões) ganha uma segunda seção abaixo da existente:

```
Colisões
├─ [Modo: Lateral | Cantos]           ← já existe (Stage_00T)
│
└─ [Vidro: Lateral | Cantos | Gap | Comparação | Painel]   ← novo
```

- Separador visual + label "Vidro:" antes dos botões de modo
- Toggle entre os 5 modos glass segue o mesmo padrão `_col_sw` (mostra um box, esconde os outros)
- Seção sempre visível quando o tab Colisões está ativo

---

## Arquivo modificado

`ui/img_debug.gd` — 5 novas classes internas + código de setup em `_refresh_tiles()`

---

## Classes

### `_GlassLateralView extends Control`

Espelha `_LateralView` mas para vidro.

**`_draw()`:**
- Fundo escuro
- Tile lateral (1,0) de `glass_tex` na parede esquerda (2 tiles de altura)
- Tile lateral (3,2) de `glass_tex` na parede direita (2 tiles de altura)
- Zael 1 encostado na face direita do tile (1,0) — cápsula ciano, anotação "SEM GRAB"
- Zael 2 espelhado encostado na face esquerda do tile (3,2) — cápsula ciano, anotação "SEM GRAB"
- Linha **ciano** (não amarela) na face de contato de cada parede

**Constantes:** mesmas de `_LateralView` (`_TILE_SRC=32`, `_TILE_W=64`, `_CAP_R=10`, etc.)

---

### `_GlassCornerView extends Control`

Idêntico a `_CornerView` em lógica e posições, mas tile da parede vem de `glass_tex`.

**Vars:**
- `var tile_tex: Texture2D` — Stage_00T (chão/teto)
- `var glass_tex: Texture2D` — glass (tile lateral da parede)
- `var corner: int = 0` — 0=topo-dir, 1=topo-esq, 2=base-dir, 3=base-esq

**`_draw()`:**
- Mesmo layout de `_CornerView` (tile chão, tile teto, canto, fill)
- Substitui o tile da parede lateral (`t_side`) por tile de `glass_tex`:
  - Cantos com parede à esquerda: tile (3,2) de glass_tex
  - Cantos com parede à direita: tile (1,0) de glass_tex
- Linha de contato: **ciano** (não amarela) na face do vidro; amarela nas superfícies de Stage_00T

---

### `_GlassGapView extends Control`

Mostra a física do gap inferior do vidro.

**`_draw()`:**
- Fundo escuro
- Coluna de 3 tiles de fill (2,1) de `glass_tex` terminando 1 tile acima do chão
- Chão com tile (3,0) de `tile_tex`
- Linha amarela no `ground_y` (chão)
- Linha ciano no `gap_y = ground_y - _TW` (limite inferior da colisão do vidro)
- Zael A: no chão, cápsula abaixo de `gap_y` → label "passa" (verde)
- Zael B: levitando, cápsula cruzando `gap_y` → label "bloqueado" (vermelho)

---

### `_GlassCompareView extends Control`

Metade esquerda vs metade direita.

**`_draw()`:**
- Linha divisória vertical no centro
- **Esquerda:** tile lateral Stage_00T + Zael encostado + linha amarela + label "NORMAL — grab"
- **Direita:** tile lateral glass_tex + Zael encostado + linha ciano + label "VIDRO — sem grab"
- Mesmo Y, mesma distância à face de contato em ambos os lados

---

### `_GlassPanelView extends Control`

Painel completo de vidro sem Zael.

**Vars:**
- `var mirror: bool = false`
- `var fill_cols: int = 5`

**`_draw()`:**
- Normal (`mirror=false`): tile (1,0) à esquerda + 5 fills (2,1) + tile (3,2) à direita
- Espelho (`mirror=true`): inverte posição de (1,0) e (3,2)
- Anotações abaixo de cada coluna: "(1,0)", "(2,1)×N", "(3,2)"

**Botão:** "Normal / Espelho" fora do canvas, chama `queue_redraw()` ao trocar `mirror`

---

## Setup em `_refresh_tiles()`

Após o bloco dos botões Lateral/Cantos existentes (linha ~1237), adicionar:

```gdscript
# Separador + seção Vidro
var glass_sep := HSeparator.new()
col_panel.add_child(glass_sep)

var glass_mode_row := HBoxContainer.new()
# label "Vidro:" + 5 botões de modo

# 5 boxes, um por modo (visível/oculto pelo toggle)
var glass_lateral_box  # _GlassLateralView
var glass_corners_box  # _GlassCornerView + seletor de canto
var glass_gap_box      # _GlassGapView
var glass_compare_box  # _GlassCompareView
var glass_panel_box    # _GlassPanelView + botão Normal/Espelho
```

---

## Self-Review

- Sem placeholders ✓
- Classes independentes, uma por modo ✓
- Reutiliza `tile_tex` (Stage_00T) e introduz `glass_tex` (stage_00_glass.png) ✓
- Scope focado: apenas `img_debug.gd` ✓
- Nenhuma mudança em gameplay ou física ✓
