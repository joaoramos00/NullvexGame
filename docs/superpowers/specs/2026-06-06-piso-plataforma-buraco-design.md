# Design — Modo "Piso + Plataforma + Buraco" no painel imgdebug

**Data:** 2026-06-06
**Arquivo afetado:** `ui/img_debug.gd` (classe `_PlatformView` + UI da aba "Plataformas")
**Tipo:** Feature de debug/visualização (sem impacto em gameplay)

## Objetivo

Adicionar à aba "Plataformas" do painel imgdebug um novo modo de visualização que monta um
heightfield **piso + plataforma elevada + buraco (abismo)**, com botão para **espelhar** o lado
do buraco (direita ↔ esquerda).

Hoje o modo `floor_platform` desenha **piso + plataforma elevada + piso** (piso contínuo dos dois
lados). O novo modo substitui um dos lados por um vazio vertical total (abismo sem chão), criando
um penhasco na face da plataforma virada para o buraco.

## Geometria

`▲` = plataforma elevada · `▓` = sólido · vazio = abismo

```
Normal (buraco à direita):        Espelhado (buraco à esquerda):
      ▲▲▲                                    ▲▲▲
      ▲▲▲                                    ▲▲▲
▓▓▓▓▓▓▓▓▓                                ▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓                                ▓▓▓▓▓▓▓▓▓
 piso    └penhasco→abismo        abismo┘    piso
```

- A plataforma permanece **elevada** `rows` tiles acima do piso, idêntica ao `floor_platform`.
- O "buraco" é um **vazio vertical total** naquele lado: nenhuma coluna sólida, em todas as rows.
- A face da plataforma virada ao buraco vira um **penhasco** do topo até a base da grade.

## Mapeamento de tiles (validado)

O penhasco sai automaticamente do marching-squares existente (`_fp_tile`), sem código especial:

| Lado do buraco | Topo (canto convexo) | Lateral (face) |
|----------------|----------------------|----------------|
| Direita        | `(0,0)` (`eu and er`) | `(3,2)` (`er`) |
| Esquerda       | `(1,3)` (`eu and el`) | `(1,0)` (`el`) |

A base do penhasco usa o canto convexo inferior já existente (`(3,3)` à direita / `(0,2)` à esquerda).

## Implementação

Todas as mudanças em `ui/img_debug.gd`. O modo `floor_platform` clássico fica **intocado**.

### 1. Estado novo em `_PlatformView`
- Novo valor de `mode`: `"floor_platform_hole"`.
- Novo campo: `var mirror_hole: bool = false` (`false` = buraco à direita; `true` = à esquerda).
- Helper `_fp_hole_dir() -> int`:
  - `mode != "floor_platform_hole"` → `0` (sem buraco; comportamento clássico).
  - senão → `+1` (buraco à direita) ou `-1` (buraco à esquerda) conforme `mirror_hole`.

### 2. `_fp_solid` — colunas do lado do buraco viram vazio
Nas colunas laterais (fora da região da plataforma), antes de `return r >= rows`:
- se a coluna pertence ao lado indicado por `_fp_hole_dir()`, retorna `false` (vazio em todas as rows).
- caso contrário, mantém `r >= rows` (piso).

A região da plataforma (`in_plat`) e o lado oposto ficam idênticos a hoje.

### 3. `_fp_tile` — sem mudanças
O penhasco e seus cantos saem do marching-squares a partir dos vizinhos vazios.

### 4. `_draw_floor_platform` — linha amarela do caminho condicional ao `_fp_hole_dir()`
- `0` (clássico): caminho completo atual, inalterado (piso → sobe → topo → desce → piso).
- `+1` (buraco à direita): piso esq → sobe → topo da plataforma e **para na borda direita** (penhasco; sem descer, sem piso direito).
- `-1` (buraco à esquerda): espelhado — começa na borda esquerda do topo → topo → desce → piso dir.

### 5. UI da aba "Plataformas"
- Adicionar `["Piso+Buraco", "floor_platform_hole"]` ao array de modos (linha ~2388).
- Adicionar botão **"Espelhar"** que faz `pview.mirror_hole = !pview.mirror_hole; pview.queue_redraw()`.
  (Visualmente só afeta o modo de buraco; inofensivo nos demais.)

### Não muda
- `_fp_grid()` e `set_dims`: a grade mantém a largura total; o lado do buraco apenas não desenha
  tiles (o espaço vazio mostra o abismo — desejável para debug).

## Critérios de aceitação
1. Novo botão de modo "Piso+Buraco" na aba Plataformas seleciona `floor_platform_hole`.
2. No modo de buraco, um lado mostra piso + plataforma elevada e o outro lado fica vazio (abismo).
3. O topo do penhasco usa `(0,0)`/`(1,3)` e a lateral `(3,2)`/`(1,0)` conforme o lado.
4. Botão "Espelhar" inverte o lado do buraco e redesenha.
5. O modo `floor_platform` (Piso+Plat) continua idêntico ao anterior — sem regressão visual.
6. Controles Cols/Rows continuam funcionando no novo modo.

## Fora de escopo
- Generalização para perfis de terreno arbitrários (Abordagem B descartada — YAGNI).
- Uso do layout em fases reais (este é só o visualizador de debug).
