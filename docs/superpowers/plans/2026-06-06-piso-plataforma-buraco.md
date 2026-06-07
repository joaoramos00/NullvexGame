# Modo "Piso + Plataforma + Buraco" — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar à aba "Plataformas" do painel imgdebug um modo `floor_platform_hole` que monta piso + plataforma elevada + buraco (abismo), com botão "Espelhar" para inverter o lado do buraco.

**Architecture:** Reaproveita o heightfield + marching-squares já existentes na classe `_PlatformView` (`ui/img_debug.gd`). A única mudança de lógica é tornar as colunas de um lado "vazias" em `_fp_solid`; o penhasco e seus cantos saem automaticamente do `_fp_tile` sem código novo. O modo `floor_platform` clássico fica intocado (helper retorna 0 quando o modo não é o de buraco).

**Tech Stack:** Godot 4.6.2 / GDScript. Testes headless via `res://tests/test_img_debug.tscn`.

**Spec:** `docs/superpowers/specs/2026-06-06-piso-plataforma-buraco-design.md`

---

## File Structure

- **Modify** `ui/img_debug.gd`:
  - `_PlatformView`: novo campo `mirror_hole`, helper `_fp_hole_dir()`, ajuste em `_fp_solid`, dispatch em `_draw`/`set_dims`, linha amarela condicional em `_draw_floor_platform`.
  - UI da aba "Plataformas": novo botão de modo + botão "Espelhar".
- **Modify** `tests/test_img_debug.gd`: nova função `test_floor_platform_hole_tiles()` + chamada em `_ready()`.

Comando de teste (rodar de `C:\Users\Usuário\SnesGame`):
```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_img_debug.tscn
```
Saída esperada de sucesso: termina com `ALL TESTS PASSED`.

---

## Task 1: Lógica do vazio (heightfield) — TDD

**Files:**
- Test: `tests/test_img_debug.gd` (nova função + chamada no `_ready`)
- Modify: `ui/img_debug.gd` (campo `mirror_hole`, helper `_fp_hole_dir`, ajuste `_fp_solid`)

- [ ] **Step 1: Escrever o teste que falha**

Em `tests/test_img_debug.gd`, adicionar a chamada na lista de `_ready()` logo após `test_floor_platform_tiles()` (linha 12):

```gdscript
    test_floor_platform_tiles()
    test_floor_platform_hole_tiles()
```

E adicionar a função nova logo após `test_floor_platform_tiles()` (antes de `_find_button`):

```gdscript
# Modo "Piso+Buraco": um lado vira abismo (vazio total); o penhasco da plataforma
# sai do marching-squares. mirror_hole alterna o lado. Grid igual ao floor_platform (9x4).
func test_floor_platform_hole_tiles() -> void:
    var pv = ImgDebug._PlatformView.new()
    pv.mode = "floor_platform_hole"
    pv.cols = 3   # largura da plataforma
    pv.rows = 2   # elevação acima do piso

    assert(pv._fp_grid() == Vector2i(9, 4), "grid deve ser 9x4 (igual floor_platform)")

    # ── Buraco à direita (padrão: mirror_hole = false) ──
    pv.mirror_hole = false
    assert(pv._fp_hole_dir() == 1, "hole_dir deve ser +1 (buraco à direita)")
    assert(not pv._fp_solid(6, 2), "coluna 6 (lado direito) deve ser vazia")
    assert(not pv._fp_solid(8, 0), "coluna 8 deve ser vazia")
    assert(pv._fp_tile(5, 0) == Vector2i(0, 0), "topo do penhasco direito = (0,0)")
    assert(pv._fp_tile(5, 1) == Vector2i(3, 2), "lateral do penhasco direito = (3,2)")
    assert(pv._fp_solid(0, 2), "piso esquerdo deve continuar sólido")
    assert(pv._fp_tile(1, 2) == Vector2i(3, 0), "superfície do piso esquerdo (TOP)")

    # ── Buraco à esquerda (mirror_hole = true) ──
    pv.mirror_hole = true
    assert(pv._fp_hole_dir() == -1, "hole_dir deve ser -1 (buraco à esquerda)")
    assert(not pv._fp_solid(2, 2), "coluna 2 (lado esquerdo) deve ser vazia")
    assert(not pv._fp_solid(0, 0), "coluna 0 deve ser vazia")
    assert(pv._fp_tile(3, 0) == Vector2i(1, 3), "topo do penhasco esquerdo = (1,3)")
    assert(pv._fp_tile(3, 1) == Vector2i(1, 0), "lateral do penhasco esquerdo = (1,0)")
    assert(pv._fp_solid(8, 2), "piso direito deve continuar sólido")
    assert(pv._fp_tile(7, 2) == Vector2i(3, 0), "superfície do piso direito (TOP)")

    # ── Modo clássico não afetado ──
    pv.mode = "floor_platform"
    assert(pv._fp_hole_dir() == 0, "floor_platform clássico → hole_dir 0")
    assert(pv._fp_solid(6, 2), "no modo clássico, lado direito volta a ser piso")

    pv.free()
    print("PASS: floor_platform_hole_tiles")
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run:
```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_img_debug.tscn
```
Esperado: FALHA (erro/parse ou assert) porque `mirror_hole` e `_fp_hole_dir()` ainda não existem.

- [ ] **Step 3: Implementar o campo, o helper e o ajuste no `_fp_solid`**

Em `ui/img_debug.gd`, no topo da classe `_PlatformView`, trocar a linha do `mode` (atual linha 695) por:

```gdscript
    var mode: String = "platform"   # "platform" | "room" | "floor_platform" | "floor_platform_hole"
    var mirror_hole: bool = false    # floor_platform_hole: false = buraco à direita, true = à esquerda
```

Adicionar o helper logo antes de `_fp_grid()` (atual linha 811):

```gdscript
    # Direção do buraco no modo floor_platform_hole: +1 = direita vazia, -1 = esquerda vazia.
    # 0 nos demais modos → floor_platform clássico fica intocado.
    func _fp_hole_dir() -> int:
        if mode != "floor_platform_hole":
            return 0
        return -1 if mirror_hole else 1
```

Substituir o corpo de `_fp_solid` (atual linhas 816-823) por:

```gdscript
    func _fp_solid(c: int, r: int) -> bool:
        var g := _fp_grid()
        if c < 0 or r < 0 or c >= g.x or r >= g.y:
            return false
        var in_plat: bool = c >= _FP_SIDE and c < _FP_SIDE + cols
        if in_plat:
            return true              # plataforma: sólida do topo (row 0) até a base
        var hole := _fp_hole_dir()
        if hole > 0 and c >= _FP_SIDE + cols:
            return false             # buraco à direita: lado direito é abismo (vazio total)
        if hole < 0 and c < _FP_SIDE:
            return false             # buraco à esquerda: lado esquerdo é abismo
        return r >= rows             # piso lateral: sólido a partir da superfície
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run:
```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_img_debug.tscn
```
Esperado: `PASS: floor_platform_hole_tiles` e termina com `ALL TESTS PASSED`.

- [ ] **Step 5: Commit**

```bash
git add ui/img_debug.gd tests/test_img_debug.gd
git commit -m "feat(imgdebug): logica de vazio do modo piso+plataforma+buraco"
```

---

## Task 2: Renderização (dispatch + linha do caminho)

**Files:**
- Modify: `ui/img_debug.gd` (`set_dims`, `_draw`, `_draw_floor_platform`)

Sem teste unitário novo (desenho); a verificação é o conjunto existente continuar passando (sem regressão no `floor_platform`).

- [ ] **Step 1: Dispatch do novo modo em `set_dims` e `_draw`**

Em `set_dims` (atual linha 708), trocar:

```gdscript
        var gd := _fp_grid() if mode == "floor_platform" else Vector2i(c, r)
```
por:

```gdscript
        var _is_fp := mode == "floor_platform" or mode == "floor_platform_hole"
        var gd := _fp_grid() if _is_fp else Vector2i(c, r)
```

Em `_draw` (atual linhas 716-718), trocar:

```gdscript
        if mode == "floor_platform":
            _draw_floor_platform()
            return
```
por:

```gdscript
        if mode == "floor_platform" or mode == "floor_platform_hole":
            _draw_floor_platform()
            return
```

- [ ] **Step 2: Linha amarela condicional ao lado do buraco**

Em `_draw_floor_platform`, substituir o bloco da linha amarela (atual linhas 857-868) por:

```gdscript
        # Linha amarela na superfície que o player percorre. Com buraco, o caminho
        # para no penhasco do lado vazio (não desce nem segue como piso).
        var yellow := Color(1.0, 0.9, 0.0, 0.9)
        var floor_y := rows * _TD
        var plat_y  := 0.0
        var lx := _FP_SIDE * _TD
        var rx := (_FP_SIDE + cols) * _TD
        var w  := g.x * _TD
        var hole := _fp_hole_dir()
        if hole >= 0:
            draw_line(Vector2(0.0, floor_y), Vector2(lx, floor_y), yellow, 1.5)   # piso esq
            draw_line(Vector2(lx, floor_y), Vector2(lx, plat_y), yellow, 1.5)     # sobe (esq)
        draw_line(Vector2(lx, plat_y), Vector2(rx, plat_y), yellow, 1.5)          # topo plat
        if hole <= 0:
            draw_line(Vector2(rx, plat_y), Vector2(rx, floor_y), yellow, 1.5)     # desce (dir)
            draw_line(Vector2(rx, floor_y), Vector2(w, floor_y), yellow, 1.5)     # piso dir
```

(Para `hole == 0`, os dois `if` disparam → caminho completo idêntico ao atual; sem regressão.)

- [ ] **Step 3: Rodar a suíte e confirmar sem regressão**

Run:
```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_img_debug.tscn
```
Esperado: termina com `ALL TESTS PASSED` (inclui `PASS: floor_platform_tiles` e `PASS: floor_platform_hole_tiles`).

- [ ] **Step 4: Commit**

```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): render do modo piso+plataforma+buraco"
```

---

## Task 3: UI — botão de modo + botão "Espelhar"

**Files:**
- Modify: `ui/img_debug.gd` (array de modos + botão Espelhar na aba Plataformas)

- [ ] **Step 1: Adicionar o modo à barra de botões**

Em `_build_platform_section` (a função que monta a aba), no array de modos (atual linha 2388), trocar:

```gdscript
    for me: Array in [["Plataforma", "platform"], ["Sala", "room"], ["Piso+Plat", "floor_platform"]]:
```
por:

```gdscript
    for me: Array in [["Plataforma", "platform"], ["Sala", "room"], ["Piso+Plat", "floor_platform"], ["Piso+Buraco", "floor_platform_hole"]]:
```

- [ ] **Step 2: Adicionar o botão "Espelhar" ao `ctrl_row`**

Logo após `ctrl_row.add_child(rows_hb)` (atual linha 2449), inserir:

```gdscript
    var mirror_btn := Button.new()
    mirror_btn.text = "Espelhar"
    mirror_btn.add_theme_font_size_override("font_size", 18)
    mirror_btn.pressed.connect(func():
        pview.mirror_hole = not pview.mirror_hole
        pview.queue_redraw())
    ctrl_row.add_child(mirror_btn)
```

- [ ] **Step 3: Rodar a suíte (regressão da aba Plataformas)**

Run:
```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_img_debug.tscn
```
Esperado: `PASS: platform_tab_shows_panel` e `ALL TESTS PASSED`.

- [ ] **Step 4: Commit**

```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): botoes de modo Piso+Buraco e Espelhar"
```

---

## Task 4: Verificação final + web export

**Files:** nenhum código novo.

- [ ] **Step 1: Suíte completa verde**

Run:
```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_img_debug.tscn
```
Esperado: `ALL TESTS PASSED`.

- [ ] **Step 2: Web export + restart do localhost**

Invocar a skill `web-export` (preferência do usuário: sempre exportar web e reiniciar o localhost após mudança de código). Confirmar que o `.pck` foi regenerado e o servidor na porta 8080 reiniciado.

- [ ] **Step 3: Commit do build (se a skill gerar artefatos versionados)**

```bash
git add -A
git commit -m "chore(imgdebug): web export com modo piso+plataforma+buraco"
```

---

## Self-Review

**Spec coverage:**
- Estado novo (`floor_platform_hole`, `mirror_hole`, `_fp_hole_dir`) → Task 1.
- `_fp_solid` vazio no lado do buraco → Task 1.
- `_fp_tile` sem mudanças (penhasco automático) → validado pelos asserts da Task 1.
- Linha amarela condicional → Task 2.
- Dispatch `_draw`/`set_dims` → Task 2.
- UI: botão de modo + "Espelhar" → Task 3.
- Critérios de aceitação 1-6 → cobertos por Tasks 1-3 (tiles, espelhar, sem regressão, Cols/Rows intactos via grid 9x4).

**Placeholder scan:** nenhum TBD/TODO; todo código mostrado por extenso.

**Type consistency:** `_fp_hole_dir()` (int), `mirror_hole` (bool), `mode` string `"floor_platform_hole"` usados consistentemente entre tasks e teste. Tiles batem com a tabela do spec: direita (0,0)/(3,2), esquerda (1,3)/(1,0).
