# ImgDebug Glass Colisões — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar seção "Vidro" no tab Tiles > Colisões do ImgDebug com 5 modos: Lateral, Cantos, Gap, Comparação, Painel.

**Architecture:** 5 novas classes internas em `ui/img_debug.gd` (inseridas após `_CornerView`, antes de `_PlatformView`) + código de setup adicionado ao final da seção Colisões em `_refresh_tiles()`. Cada classe segue o mesmo padrão das existentes: `extends Control` com `_draw()` puro, sem estado mutável além de props declaradas.

**Tech Stack:** GDScript / Godot 4.6.2 — apenas `ui/img_debug.gd`

---

## Arquivos Modificados

| Arquivo | Mudança |
|---|---|
| `ui/img_debug.gd` | 5 novas classes + setup em `_refresh_tiles()` |

**Ponto de inserção das classes:** após a linha `draw_rect(cap, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)` do `_CornerView` e antes do comentário `# Visualização de plataformas e salas`.

**Ponto de inserção do setup:** após `col_mode_btns[0].modulate = Color(1.0, 1.0, 0.0)` (linha final da seção Colisões existente).

---

## Task 1: _GlassLateralView

**Files:**
- Modify: `ui/img_debug.gd` — inserir classe após `_CornerView`

- [ ] **Step 1: Inserir classe `_GlassLateralView` antes do comentário `# Visualização de plataformas e salas`**

```gdscript
# Colisão lateral do vidro: dois Zaels contra as faces do painel glass
class _GlassLateralView extends Control:
    var glass_tex:  Texture2D
    var sprite_tex: Texture2D

    const _SRC  := 32.0
    const _TW   := 64.0
    const _CR   := 10.0
    const _CHH  := 24.0
    const _CH   := 48.0
    const _SPR  := 68.0
    const _SCL  := 2.0
    const _SOFY := -4.0
    const _ML   := 20.0
    const _MT   := 44.0
    const _X2   := 196.0

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        var cy  := _MT + _TW
        var cyn := Color(0.5, 0.9, 1.0, 0.9)
        var font := ThemeDB.fallback_font

        if glass_tex:
            var src_l := Rect2(3.0 * _SRC, 2.0 * _SRC, _SRC, _SRC)  # (3,2) face esq
            var src_r := Rect2(1.0 * _SRC, 0.0,         _SRC, _SRC)  # (1,0) face dir
            for i in 2:
                draw_texture_rect_region(glass_tex, Rect2(_ML, _MT + i * _TW, _TW, _TW), src_l)
                draw_texture_rect_region(glass_tex, Rect2(_X2, _MT + i * _TW, _TW, _TW), src_r)

        var sd := _SPR * _SCL

        # Zael 1: encostando no vidro esquerdo (vindo da direita)
        var cx1 := _ML + _TW - _CR
        if sprite_tex:
            draw_texture_rect_region(sprite_tex,
                Rect2(cx1 - sd * 0.5, cy + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
        var cap1 := Rect2(cx1 - _CR, cy - _CHH, _CR * 2.0, _CH)
        draw_rect(cap1, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap1, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)
        draw_line(Vector2(_ML + _TW - 32.0, _MT - 8.0),
            Vector2(_ML + _TW - 32.0, _MT + _TW * 2.0 + 8.0), cyn, 2.0)
        draw_string(font, Vector2(cx1 - 34.0, _MT - 20.0),
            "SEM GRAB", HORIZONTAL_ALIGNMENT_LEFT, 80.0, 15, cyn)

        # Zael 2: encostando no vidro direito (espelhado)
        var cx2 := _X2 + _CR
        if sprite_tex:
            draw_set_transform(Vector2(cx2 * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
            draw_texture_rect_region(sprite_tex,
                Rect2(cx2 - sd * 0.5, cy + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
            draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        var cap2 := Rect2(cx2 - _CR, cy - _CHH, _CR * 2.0, _CH)
        draw_rect(cap2, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap2, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)
        draw_line(Vector2(_X2 + 32.0, _MT - 8.0),
            Vector2(_X2 + 32.0, _MT + _TW * 2.0 + 8.0), cyn, 2.0)
        draw_string(font, Vector2(cx2 - 34.0, _MT - 20.0),
            "SEM GRAB", HORIZONTAL_ALIGNMENT_LEFT, 80.0, 15, cyn)
```

- [ ] **Step 2: Verificar parse sem erros**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
```

Esperado: `=== All GameManager tests passed ===` sem erros de parse.

- [ ] **Step 3: Commit**

```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): _GlassLateralView — colisão lateral do vidro"
```

---

## Task 2: _GlassCornerView

**Files:**
- Modify: `ui/img_debug.gd` — inserir classe após `_GlassLateralView`

- [ ] **Step 1: Inserir classe `_GlassCornerView`**

```gdscript
# Cantos do vidro: idêntico a _CornerView mas tile da parede vem de glass_tex
class _GlassCornerView extends Control:
    var tile_tex:   Texture2D   # Stage_00T (chão/teto)
    var glass_tex:  Texture2D   # glass (tile lateral da parede)
    var sprite_tex: Texture2D
    var corner: int = 0         # 0=topo-dir  1=topo-esq  2=base-dir  3=base-esq

    const _TW   := 64.0
    const _SRC  := 32.0
    const _CR   := 10.0
    const _CH   := 48.0
    const _CHH  := 24.0
    const _OFS  := 10.0
    const _SPR  := 68.0
    const _SCL  := 2.0
    const _SOFY := -4.0

    func _blit_tex(tex: Texture2D, src: Vector2i, dst: Rect2) -> void:
        if not tex:
            return
        draw_texture_rect_region(tex, dst,
            Rect2(src.x * _SRC, src.y * _SRC, _SRC, _SRC))

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        var W := size.x
        var H := size.y
        var wx := W * 0.54
        var fy := H * 0.55
        var wx_in := wx + (32.0 if corner == 1 or corner == 3 else -32.0)
        var fy_in := fy + (32.0 if corner == 0 or corner == 1 else -32.0)

        var t_corner: Vector2i
        var t_surf:   Vector2i
        var t_side:   Vector2i
        var t_fill := Vector2i(2, 1)
        var rc: Rect2; var rs: Rect2; var rw: Rect2; var rf: Rect2
        var px: float; var py: float; var flip := false

        match corner:
            0:
                t_corner = Vector2i(0, 0); t_surf = Vector2i(3, 0); t_side = Vector2i(3, 2)
                rc = Rect2(wx - _TW,       fy,        _TW, _TW)
                rs = Rect2(wx - _TW * 2.0, fy,        _TW, _TW)
                rw = Rect2(wx - _TW,       fy + _TW,  _TW, _TW)
                rf = Rect2(wx - _TW * 2.0, fy + _TW,  _TW, _TW)
                px = wx_in + _OFS;  py = fy_in - _CHH;  flip = true
            1:
                t_corner = Vector2i(1, 3); t_surf = Vector2i(3, 0); t_side = Vector2i(1, 0)
                rc = Rect2(wx,       fy,        _TW, _TW)
                rs = Rect2(wx + _TW, fy,        _TW, _TW)
                rw = Rect2(wx,       fy + _TW,  _TW, _TW)
                rf = Rect2(wx + _TW, fy + _TW,  _TW, _TW)
                px = wx_in - _OFS;  py = fy_in - _CHH;  flip = false
            2:
                t_corner = Vector2i(3, 3); t_surf = Vector2i(1, 2); t_side = Vector2i(3, 2)
                rc = Rect2(wx - _TW,       fy - _TW,        _TW, _TW)
                rs = Rect2(wx - _TW * 2.0, fy - _TW,        _TW, _TW)
                rw = Rect2(wx - _TW,       fy - _TW * 2.0,  _TW, _TW)
                rf = Rect2(wx - _TW * 2.0, fy - _TW * 2.0,  _TW, _TW)
                px = wx_in + _OFS;  py = fy_in + _CHH;  flip = true
            3:
                t_corner = Vector2i(0, 2); t_surf = Vector2i(1, 2); t_side = Vector2i(1, 0)
                rc = Rect2(wx,       fy - _TW,        _TW, _TW)
                rs = Rect2(wx + _TW, fy - _TW,        _TW, _TW)
                rw = Rect2(wx,       fy - _TW * 2.0,  _TW, _TW)
                rf = Rect2(wx + _TW, fy - _TW * 2.0,  _TW, _TW)
                px = wx_in - _OFS;  py = fy_in + _CHH;  flip = false
            _:
                return

        # fill, surf, corner de tile_tex; side de glass_tex
        _blit_tex(tile_tex,  t_fill,   rf)
        _blit_tex(tile_tex,  t_surf,   rs)
        _blit_tex(tile_tex,  t_corner, rc)
        _blit_tex(glass_tex, t_side,   rw)

        # Linha ciano para parede de vidro, amarela para chão/teto
        var yel := Color(1.0, 0.9, 0.0, 0.85)
        var cyn := Color(0.5, 0.9, 1.0, 0.9)
        draw_line(Vector2(wx_in, 0.0), Vector2(wx_in, H), cyn, 2.0)
        draw_line(Vector2(0.0, fy_in), Vector2(W, fy_in), yel, 2.0)

        var grn := Color(0.0, 1.0, 0.5, 0.85)
        draw_line(Vector2(px - 9.0, fy_in), Vector2(px + 9.0, fy_in), grn, 2.0)
        draw_line(Vector2(wx_in, py - 9.0), Vector2(wx_in, py + 9.0), grn, 2.0)
        draw_line(Vector2(px - 5.0, py - 5.0), Vector2(px + 5.0, py + 5.0), grn, 1.5)
        draw_line(Vector2(px + 5.0, py - 5.0), Vector2(px - 5.0, py + 5.0), grn, 1.5)

        if sprite_tex:
            var sd := _SPR * _SCL
            if flip:
                draw_set_transform(Vector2(px * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
            draw_texture_rect_region(sprite_tex,
                Rect2(px - sd * 0.5, py + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
            if flip:
                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

        var cap := Rect2(px - _CR, py - _CHH, _CR * 2.0, _CH)
        draw_rect(cap, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)
```

- [ ] **Step 2: Verificar parse sem erros**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
```

Esperado: sem erros de parse.

- [ ] **Step 3: Commit**

```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): _GlassCornerView — cantos do vidro (4 variantes)"
```

---

## Task 3: _GlassGapView

**Files:**
- Modify: `ui/img_debug.gd` — inserir após `_GlassCornerView`

- [ ] **Step 1: Inserir classe `_GlassGapView`**

```gdscript
# Gap inferior do vidro: mostra onde a colisão termina e o player passa andando
class _GlassGapView extends Control:
    var glass_tex:  Texture2D
    var tile_tex:   Texture2D
    var sprite_tex: Texture2D

    const _SRC  := 32.0
    const _TW   := 64.0
    const _CR   := 10.0
    const _CH   := 48.0
    const _CHH  := 24.0
    const _SPR  := 68.0
    const _SCL  := 2.0
    const _SOFY := -4.0

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        var W   := size.x
        var gy  := size.y - 40.0      # floor y
        var gpy := gy - _TW           # gap y = bottom of glass collision
        var gx  := 18.0               # left edge of glass column
        var yel := Color(1.0, 0.9, 0.0, 0.85)
        var cyn := Color(0.5, 0.9, 1.0, 0.9)
        var font := ThemeDB.fallback_font

        # Zonas coloridas: vermelho = colisão do vidro, verde = gap (player passa)
        draw_rect(Rect2(gx + _TW * 2.0 + 4.0, gpy - _TW, _TW * 1.5, _TW),
            Color(1.0, 0.2, 0.2, 0.15))
        draw_rect(Rect2(gx + _TW * 2.0 + 4.0, gpy,       _TW * 1.5, _TW),
            Color(0.2, 1.0, 0.3, 0.15))

        # Floor tiles
        if tile_tex:
            var src_top := Rect2(3.0 * _SRC, 0.0, _SRC, _SRC)
            var tx := 0.0
            while tx <= W:
                draw_texture_rect_region(tile_tex,
                    Rect2(tx, gy - _TW * 0.5, _TW, _TW), src_top)
                tx += _TW

        # Coluna de vidro: lateral (3,2) + fill (2,1), 2 tiles altos, terminando em gpy
        if glass_tex:
            var src_lat  := Rect2(3.0 * _SRC, 2.0 * _SRC, _SRC, _SRC)
            var src_fill := Rect2(2.0 * _SRC, 1.0 * _SRC, _SRC, _SRC)
            for i in 2:
                var ty := gpy - float(i + 1) * _TW
                draw_texture_rect_region(glass_tex, Rect2(gx,        ty, _TW, _TW), src_lat)
                draw_texture_rect_region(glass_tex, Rect2(gx + _TW,  ty, _TW, _TW), src_fill)

        # Linhas
        draw_line(Vector2(0.0, gy), Vector2(W, gy), yel, 2.0)
        draw_line(Vector2(gx - 4.0, gpy),
            Vector2(gx + _TW * 2.0 + 4.0, gpy), cyn, 2.0)

        # Zael no chão (capsule top abaixo de gpy → passa)
        var axc := gx + _TW * 2.0 + _CR + 14.0
        var ayc := gy - _CHH
        if sprite_tex:
            var sd := _SPR * _SCL
            draw_texture_rect_region(sprite_tex,
                Rect2(axc - sd * 0.5, ayc + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
        var cap := Rect2(axc - _CR, ayc - _CHH, _CR * 2.0, _CH)
        draw_rect(cap, Color(0.2, 1.0, 0.3, 0.25))
        draw_rect(cap, Color(0.2, 1.0, 0.3, 1.0), false, 2.0)

        # Labels
        var zx := gx + _TW * 2.0 + 6.0
        draw_string(font, Vector2(zx, gpy - _TW * 0.5 + 8.0),
            "bloqueado", HORIZONTAL_ALIGNMENT_LEFT, 80.0, 14, Color(1.0, 0.4, 0.4))
        draw_string(font, Vector2(zx, gpy + _TW * 0.5 + 8.0),
            "passa", HORIZONTAL_ALIGNMENT_LEFT, 60.0, 14, Color(0.2, 1.0, 0.3))
        draw_string(font, Vector2(gx, gpy + 6.0),
            "gap\n64px", HORIZONTAL_ALIGNMENT_LEFT, 42.0, 13, cyn)
```

- [ ] **Step 2: Verificar parse sem erros**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
```

Esperado: sem erros de parse.

- [ ] **Step 3: Commit**

```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): _GlassGapView — gap inferior do vidro"
```

---

## Task 4: _GlassCompareView

**Files:**
- Modify: `ui/img_debug.gd` — inserir após `_GlassGapView`

- [ ] **Step 1: Inserir classe `_GlassCompareView`**

```gdscript
# Comparação lado a lado: parede normal (grab) vs vidro (sem grab)
class _GlassCompareView extends Control:
    var glass_tex:  Texture2D
    var tile_tex:   Texture2D
    var sprite_tex: Texture2D

    const _SRC  := 32.0
    const _TW   := 64.0
    const _CR   := 10.0
    const _CH   := 48.0
    const _CHH  := 24.0
    const _SPR  := 68.0
    const _SCL  := 2.0
    const _SOFY := -4.0
    const _ML   := 20.0
    const _MT   := 44.0

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        var W   := size.x
        var mid := W * 0.5
        var cy  := _MT + _TW
        var yel := Color(1.0, 0.9, 0.0, 0.85)
        var cyn := Color(0.5, 0.9, 1.0, 0.9)
        var font := ThemeDB.fallback_font
        var src_wall := Rect2(3.0 * _SRC, 2.0 * _SRC, _SRC, _SRC)  # (3,2)
        var sd := _SPR * _SCL

        # Divisória central
        draw_line(Vector2(mid, 0.0), Vector2(mid, size.y),
            Color(0.3, 0.3, 0.3, 0.8), 1.0)

        # ── ESQUERDA: parede normal ──────────────────────────
        if tile_tex:
            for i in 2:
                draw_texture_rect_region(tile_tex,
                    Rect2(_ML, _MT + i * _TW, _TW, _TW), src_wall)
        var cx1 := _ML + _TW - _CR
        if sprite_tex:
            draw_texture_rect_region(sprite_tex,
                Rect2(cx1 - sd * 0.5, cy + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
        var cap1 := Rect2(cx1 - _CR, cy - _CHH, _CR * 2.0, _CH)
        draw_rect(cap1, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap1, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)
        draw_line(Vector2(_ML + _TW - 32.0, _MT - 8.0),
            Vector2(_ML + _TW - 32.0, _MT + _TW * 2.0 + 8.0), yel, 2.0)
        draw_string(font, Vector2(_ML, size.y - 34.0),
            "NORMAL — grab", HORIZONTAL_ALIGNMENT_LEFT, mid - _ML, 16, yel)

        # ── DIREITA: vidro ────────────────────────────────────
        var rx := mid + _ML
        if glass_tex:
            for i in 2:
                draw_texture_rect_region(glass_tex,
                    Rect2(rx, _MT + i * _TW, _TW, _TW), src_wall)
        var cx2 := rx + _TW - _CR
        if sprite_tex:
            draw_texture_rect_region(sprite_tex,
                Rect2(cx2 - sd * 0.5, cy + _SOFY - sd * 0.5, sd, sd),
                Rect2(0.0, 0.0, _SPR, _SPR))
        var cap2 := Rect2(cx2 - _CR, cy - _CHH, _CR * 2.0, _CH)
        draw_rect(cap2, Color(0.0, 1.0, 1.0, 0.25))
        draw_rect(cap2, Color(0.0, 1.0, 1.0, 1.0), false, 2.0)
        draw_line(Vector2(rx + _TW - 32.0, _MT - 8.0),
            Vector2(rx + _TW - 32.0, _MT + _TW * 2.0 + 8.0), cyn, 2.0)
        draw_string(font, Vector2(rx, size.y - 34.0),
            "VIDRO — sem grab", HORIZONTAL_ALIGNMENT_LEFT, W - rx, 16, cyn)
```

- [ ] **Step 2: Verificar parse sem erros**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
```

Esperado: sem erros de parse.

- [ ] **Step 3: Commit**

```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): _GlassCompareView — comparação normal vs vidro"
```

---

## Task 5: _GlassPanelView

**Files:**
- Modify: `ui/img_debug.gd` — inserir após `_GlassCompareView`

- [ ] **Step 1: Inserir classe `_GlassPanelView`**

```gdscript
# Painel completo de vidro: lateral + fills + lateral, modo Normal ou Espelho
class _GlassPanelView extends Control:
    var glass_tex: Texture2D
    var mirror:    bool = false

    const _FILL_COLS := 5
    const _SRC  := 32.0
    const _TW   := 64.0
    const _ROWS := 2

    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14))
        if not glass_tex:
            return
        var total_cols := _FILL_COLS + 2
        var panel_w    := float(total_cols) * _TW
        var sx         := (size.x - panel_w) * 0.5
        var sy         := (size.y - float(_ROWS) * _TW - 28.0) * 0.5

        var src_lat_l  := Rect2(1.0 * _SRC, 0.0,         _SRC, _SRC)  # (1,0)
        var src_lat_r  := Rect2(3.0 * _SRC, 2.0 * _SRC,  _SRC, _SRC)  # (3,2)
        var src_fill   := Rect2(2.0 * _SRC, 1.0 * _SRC,  _SRC, _SRC)  # (2,1)
        var font       := ThemeDB.fallback_font
        var lc         := Color(0.5, 0.9, 1.0, 0.9)

        for row in _ROWS:
            var ty := sy + row * _TW
            for col in total_cols:
                var dx  := sx + col * _TW
                var src: Rect2
                if col == 0:
                    src = src_lat_r if mirror else src_lat_l
                elif col == total_cols - 1:
                    src = src_lat_l if mirror else src_lat_r
                else:
                    src = src_fill
                draw_texture_rect_region(glass_tex, Rect2(dx, ty, _TW, _TW), src)

        # Labels abaixo de cada coluna
        var label_y := sy + float(_ROWS) * _TW + 4.0
        for col in total_cols:
            var dx := sx + col * _TW
            var lbl: String
            if col == 0:
                lbl = "(3,2)" if mirror else "(1,0)"
            elif col == total_cols - 1:
                lbl = "(1,0)" if mirror else "(3,2)"
            else:
                lbl = "(2,1)"
            draw_string(font, Vector2(dx + 2.0, label_y),
                lbl, HORIZONTAL_ALIGNMENT_LEFT, _TW, 14, lc)
```

- [ ] **Step 2: Verificar parse sem erros**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
```

Esperado: sem erros de parse.

- [ ] **Step 3: Commit**

```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): _GlassPanelView — painel completo com tiles anotados"
```

---

## Task 6: Setup em _refresh_tiles() + Web Export

**Files:**
- Modify: `ui/img_debug.gd` — adicionar seção Vidro após `col_mode_btns[0].modulate = Color(1.0, 1.0, 0.0)`

- [ ] **Step 1: Inserir setup da seção Vidro logo após `col_mode_btns[0].modulate = Color(1.0, 1.0, 0.0)`**

```gdscript
    # ── Seção Vidro ──────────────────────────────────────────────────────────
    var glass_sep := HSeparator.new()
    col_panel.add_child(glass_sep)

    var glass_hdr := Label.new()
    glass_hdr.text = "Vidro (stage_00_glass.png)"
    glass_hdr.add_theme_font_size_override("font_size", 20)
    glass_hdr.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
    col_panel.add_child(glass_hdr)

    var glass_mode_row := HBoxContainer.new()
    glass_mode_row.add_theme_constant_override("separation", 6)
    col_panel.add_child(glass_mode_row)
    var glass_mode_lbl := Label.new()
    glass_mode_lbl.text = "Modo:"
    glass_mode_lbl.add_theme_font_size_override("font_size", 18)
    glass_mode_row.add_child(glass_mode_lbl)

    var gl_tex  := load("res://stages/stage_00/stage_00_glass.png") as Texture2D
    var tile_t  := load("res://stages/stage_00/Stage_00T.png")      as Texture2D
    var spr_t   := load("res://characters/ranged/ZaelIdle.png")     as Texture2D

    # ── Boxes por modo ───────────────────────────────────────────────────────
    var gbox_lat := VBoxContainer.new()
    var gbox_cor := VBoxContainer.new()
    var gbox_gap := VBoxContainer.new()
    var gbox_cmp := VBoxContainer.new()
    var gbox_pan := VBoxContainer.new()

    # Lateral
    var glat := _GlassLateralView.new()
    glat.glass_tex  = gl_tex
    glat.sprite_tex = spr_t
    glat.custom_minimum_size = Vector2(280, 220)
    glat.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    gbox_lat.add_child(glat)

    # Cantos
    var gcor := _GlassCornerView.new()
    gcor.tile_tex   = tile_t
    gcor.glass_tex  = gl_tex
    gcor.sprite_tex = spr_t
    gcor.custom_minimum_size = Vector2(320, 260)
    gcor.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    gcor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    gbox_cor.add_child(gcor)

    var gcor_btn_row := HBoxContainer.new()
    gcor_btn_row.add_theme_constant_override("separation", 6)
    var gcor_lbl := Label.new()
    gcor_lbl.text = "Canto:"
    gcor_lbl.add_theme_font_size_override("font_size", 18)
    gcor_btn_row.add_child(gcor_lbl)
    for gci: Array in [["↗ topo-dir", 0], ["↖ topo-esq", 1], ["↘ base-dir", 2], ["↙ base-esq", 3]]:
        var gcbtn := Button.new()
        gcbtn.text = gci[0]
        gcbtn.add_theme_font_size_override("font_size", 24)
        var gcidx: int = gci[1]
        gcbtn.pressed.connect(func(): gcor.corner = gcidx; gcor.queue_redraw())
        gcor_btn_row.add_child(gcbtn)
    gbox_cor.add_child(gcor_btn_row)

    # Gap
    var ggap := _GlassGapView.new()
    ggap.glass_tex  = gl_tex
    ggap.tile_tex   = tile_t
    ggap.sprite_tex = spr_t
    ggap.custom_minimum_size = Vector2(300, 260)
    ggap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    gbox_gap.add_child(ggap)

    # Comparação
    var gcmp := _GlassCompareView.new()
    gcmp.glass_tex  = gl_tex
    gcmp.tile_tex   = tile_t
    gcmp.sprite_tex = spr_t
    gcmp.custom_minimum_size = Vector2(380, 220)
    gcmp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    gbox_cmp.add_child(gcmp)

    # Painel
    var gpan := _GlassPanelView.new()
    gpan.glass_tex = gl_tex
    gpan.custom_minimum_size = Vector2(540, 180)
    gpan.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    gbox_pan.add_child(gpan)

    var gpan_row := HBoxContainer.new()
    gpan_row.add_theme_constant_override("separation", 6)
    var gpan_norm_btn := Button.new()
    gpan_norm_btn.text = "Normal"
    gpan_norm_btn.add_theme_font_size_override("font_size", 22)
    gpan_norm_btn.modulate = Color(1.0, 1.0, 0.0)
    var gpan_mirr_btn := Button.new()
    gpan_mirr_btn.text = "Espelho"
    gpan_mirr_btn.add_theme_font_size_override("font_size", 22)
    gpan_mirr_btn.modulate = Color(0.6, 0.6, 0.6)
    gpan_norm_btn.pressed.connect(func():
        gpan.mirror = false; gpan.queue_redraw()
        gpan_norm_btn.modulate = Color(1.0, 1.0, 0.0)
        gpan_mirr_btn.modulate = Color(0.6, 0.6, 0.6))
    gpan_mirr_btn.pressed.connect(func():
        gpan.mirror = true; gpan.queue_redraw()
        gpan_mirr_btn.modulate = Color(1.0, 1.0, 0.0)
        gpan_norm_btn.modulate = Color(0.6, 0.6, 0.6))
    gpan_row.add_child(gpan_norm_btn)
    gpan_row.add_child(gpan_mirr_btn)
    gbox_pan.add_child(gpan_row)

    # Adicionar boxes ao col_panel (lateral visível por padrão)
    var glass_boxes: Array = [gbox_lat, gbox_cor, gbox_gap, gbox_cmp, gbox_pan]
    for gb: VBoxContainer in glass_boxes:
        gb.visible = false
        col_panel.add_child(gb)
    gbox_lat.visible = true

    # Toggle de modos
    var glass_mode_btns: Array = []
    var _glass_sw := func(idx: int) -> void:
        for i in glass_boxes.size():
            glass_boxes[i].visible = (i == idx)
        for i in glass_mode_btns.size():
            glass_mode_btns[i].modulate = \
                Color(1.0, 1.0, 0.0) if i == idx else Color(0.6, 0.6, 0.6)
    for gml: Array in [["Lateral", 0], ["Cantos", 1], ["Gap", 2], ["Comparação", 3], ["Painel", 4]]:
        var gmbtn := Button.new()
        gmbtn.text = gml[0]
        gmbtn.add_theme_font_size_override("font_size", 24)
        var gidx: int = gml[1]
        gmbtn.pressed.connect(func(): _glass_sw.call(gidx))
        glass_mode_row.add_child(gmbtn)
        glass_mode_btns.append(gmbtn)
    glass_mode_btns[0].modulate = Color(1.0, 1.0, 0.0)
```

- [ ] **Step 2: Verificar parse sem erros**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
```

Esperado: sem erros de parse, testes passam.

- [ ] **Step 3: Web export**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\Usuário\SnesGame" --export-release "Web" "C:\Users\Usuário\SnesGame\export\web\index.html" 2>&1 | tail -4
```

Verificar PCK atualizado:

```powershell
powershell -Command "Get-Item 'C:\Users\Usuário\SnesGame\export\web\index.pck' | Select-Object LastWriteTime, Length"
```

- [ ] **Step 4: Commit e push**

```bash
git add -f export/web/ ui/img_debug.gd
git commit -m "feat(imgdebug): seção Vidro — 5 modos (Lateral/Cantos/Gap/Comparação/Painel)"
git push
```

- [ ] **Step 5: Reiniciar servidor e verificar no browser**

```powershell
powershell -Command "Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }; Start-Process python -ArgumentList 'C:\Users\Usuário\SnesGame\serve_web.py' -WindowStyle Hidden; Start-Sleep 2; (Invoke-WebRequest http://localhost:8080 -UseBasicParsing).StatusCode"
```

Esperado: `200`

Abrir `http://localhost:8080` → ImgDebug → TILES → Colisões → rolar para baixo até a seção "Vidro". Verificar:
- [ ] Label "Vidro (stage_00_glass.png)" aparece em ciano
- [ ] 5 botões de modo: Lateral | Cantos | Gap | Comparação | Painel
- [ ] Modo Lateral: dois Zaels com tiles de vidro e linha ciano
- [ ] Modo Cantos: 4 variantes com botões ↗↖↘↙, vidro no tile lateral
- [ ] Modo Gap: coluna de vidro com gap visível, label "passa/bloqueado"
- [ ] Modo Comparação: parede normal (esq, amarelo) vs vidro (dir, ciano)
- [ ] Modo Painel: 7 tiles com labels (1,0)/(2,1)/(3,2), botão Normal/Espelho
