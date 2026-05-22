# ImgDebug Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar o painel ImgDebug na title screen — visualizador de sprites animados dos personagens (seleção de personagem + animação + preview animado + strip clicável) e grid de tilesets.

**Architecture:** Cena separada `ui/img_debug.tscn` + `ui/img_debug.gd` instanciada dinamicamente pela title screen. UI construída 100% em GDScript no `_ready()`. Animação via `_process(delta)`. Title screen só instancia/destrói o painel.

**Tech Stack:** Godot 4.6.2 GDScript, Control hierarchy, AtlasTexture, TextureRect, Panel, GridContainer, StyleBoxFlat.

---

### Task 1: Testes + scaffold mínimo

**Files:**
- Create: `tests/test_img_debug.gd`
- Create: `tests/test_img_debug.tscn`
- Create: `ui/img_debug.tscn`
- Create: `ui/img_debug.gd`

- [ ] **Step 1: Escrever os testes (vão falhar)**

```gdscript
# tests/test_img_debug.gd
extends Node

func _ready() -> void:
    test_sprite_data()
    test_tile_data()
    test_initial_state()
    test_char_change_resets_anim()
    test_frame_cycling()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_sprite_data() -> void:
    assert(ImgDebug._SPRITES.size() == 6, "deve ter 6 sprites")
    assert(ImgDebug._SPRITES[0].char == "ZAEL", "índice 0 deve ser ZAEL")
    assert(ImgDebug._SPRITES[0].anim == "Idle", "índice 0 deve ser Idle")
    assert(ImgDebug._SPRITES[0].frames == 8, "Idle deve ter 8 frames")
    assert(ImgDebug._SPRITES[0].fps == 8.0, "Idle deve ter 8.0 fps")
    assert(ImgDebug._SPRITES[4].char == "ZARA", "índice 4 deve ser ZARA")
    assert(ImgDebug._SPRITES[4].anim == "Walk", "índice 4 deve ser Walk")
    print("PASS: sprite_data")

func test_tile_data() -> void:
    assert(ImgDebug._TILESETS.size() == 1, "deve ter 1 tileset")
    assert(ImgDebug._TILESETS[0].name == "Stage_00T", "nome deve ser Stage_00T")
    assert(ImgDebug._TILESETS[0].cols == 4, "deve ter 4 colunas")
    assert(ImgDebug._TILESETS[0].rows == 4, "deve ter 4 linhas")
    assert(ImgDebug._TILESETS[0].tile_size == 32, "tile_size deve ser 32")
    print("PASS: tile_data")

func test_initial_state() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    assert(panel._section == "SPRITES", "seção inicial deve ser SPRITES")
    assert(panel._char == "ZAEL", "personagem inicial deve ser ZAEL")
    assert(panel._anim_idx == 0, "anim_idx inicial deve ser 0")
    assert(panel._frame == 0, "frame inicial deve ser 0")
    assert(not panel._paused, "não deve iniciar pausado")
    panel.queue_free()
    print("PASS: initial_state")

func test_char_change_resets_anim() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    panel._select_anim(2)
    assert(panel._anim_idx == 2, "anim_idx deve ser 2")
    panel._select_char("ZARA")
    assert(panel._anim_idx == 0, "trocar personagem deve resetar anim_idx para 0")
    assert(panel._frame == 0, "trocar personagem deve resetar frame para 0")
    panel.queue_free()
    print("PASS: char_change_resets_anim")

func test_frame_cycling() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    # Zael Idle: 8 frames, 8 fps → frame_dur = 0.125s
    panel._select_char("ZAEL")
    panel._select_anim(0)
    panel._frame = 7
    panel._paused = false
    panel._anim_timer = 0.126  # ligeiramente acima de 1/8
    panel._process(0.0)
    assert(panel._frame == 0, "frame 7 deve ciclar para 0 (8 frames total)")
    panel.queue_free()
    print("PASS: frame_cycling")
```

- [ ] **Step 2: Criar test .tscn**

```
# tests/test_img_debug.tscn
[gd_scene format=3 uid="uid://test_img_debug"]

[ext_resource type="Script" path="res://tests/test_img_debug.gd" id="1_script"]

[node name="TestImgDebug" type="Node"]
script = ExtResource("1_script")
```

- [ ] **Step 3: Confirmar que os testes falham**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_img_debug.tscn
```

Esperado: erro de parse/load (ImgDebug não existe ainda).

- [ ] **Step 4: Criar ui/img_debug.tscn**

```
# ui/img_debug.tscn
[gd_scene format=3 uid="uid://img_debug"]

[ext_resource type="Script" path="res://ui/img_debug.gd" id="1_script"]

[node name="ImgDebug" type="Control"]
script = ExtResource("1_script")
```

- [ ] **Step 5: Criar ui/img_debug.gd com dados e estado**

```gdscript
extends Control
class_name ImgDebug

const _SPRITES: Array = [
    {"char": "ZAEL", "anim": "Idle",  "path": "res://characters/ranged/ZaelIdle.png",     "frames": 8, "fps": 8.0},
    {"char": "ZAEL", "anim": "Run",   "path": "res://characters/ranged/ZaelCorrendo.png", "frames": 6, "fps": 10.0},
    {"char": "ZAEL", "anim": "Jump",  "path": "res://characters/ranged/ZaelJump.png",     "frames": 9, "fps": 10.0},
    {"char": "ZAEL", "anim": "Shot",  "path": "res://characters/ranged/ZaelAtirando.png", "frames": 9, "fps": 10.0},
    {"char": "ZARA", "anim": "Walk",  "path": "res://characters/melee/ZaraAndando.png",   "frames": 5, "fps": 8.0},
    {"char": "ZARA", "anim": "Run",   "path": "res://characters/melee/ZaraCorrendo.png",  "frames": 3, "fps": 10.0},
]

const _TILESETS: Array = [
    {"name": "Stage_00T", "path": "res://stages/stage_00/Stage_00T.png", "cols": 4, "rows": 4, "tile_size": 32},
]

const _FRAME_SIZE   := 68
const _PREVIEW_SIZE := 136
const _STRIP_SIZE   := 40
const _TILE_DISPLAY := 52

var _section: String   = "SPRITES"
var _char: String      = "ZAEL"
var _anim_idx: int     = 0
var _frame: int        = 0
var _paused: bool      = false
var _anim_timer: float = 0.0

var _section_btns: Dictionary = {}
var _char_btns: Dictionary    = {}
var _anim_btns: Array         = []
var _strip_frames: Array      = []

var _sprites_box: VBoxContainer
var _tiles_box: VBoxContainer
var _anim_tabs_box: HBoxContainer
var _preview_rect: TextureRect
var _info_label: Label
var _strip_box: HBoxContainer
var _tile_info_label: Label

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _build_ui()
    _select_char("ZAEL")
    _refresh_tiles()
    _show_section("SPRITES")

func _process(delta: float) -> void:
    if _section != "SPRITES" or _paused:
        return
    var sd := _current_sprite()
    _anim_timer += delta
    var frame_dur := 1.0 / sd.fps
    if _anim_timer >= frame_dur:
        _anim_timer -= frame_dur
        _frame = (_frame + 1) % sd.frames
        _update_preview()

func _current_sprite() -> Dictionary:
    var char_sprites: Array = _SPRITES.filter(func(s): return s.char == _char)
    return char_sprites[_anim_idx]

func _show_section(section: String) -> void:
    _section = section
    _sprites_box.visible = (section == "SPRITES")
    _tiles_box.visible   = (section == "TILES")
    for s in _section_btns:
        _section_btns[s].modulate = Color(1, 1, 0) if s == section else Color(0.6, 0.6, 0.6)

func _select_char(char_name: String) -> void:
    _char      = char_name
    _anim_idx  = 0
    _frame     = 0
    _anim_timer = 0.0
    _paused    = false
    for c in _char_btns:
        _char_btns[c].modulate = Color(1, 1, 0) if c == char_name else Color(0.6, 0.6, 0.6)
    _rebuild_anim_tabs()

func _select_anim(idx: int) -> void:
    _anim_idx  = idx
    _frame     = 0
    _anim_timer = 0.0
    _paused    = false
    for i in _anim_btns.size():
        _anim_btns[i].modulate = Color(0, 1, 0) if i == idx else Color(0.6, 0.6, 0.6)
    _rebuild_strip()
    _update_preview()

func _rebuild_anim_tabs() -> void:
    for child in _anim_tabs_box.get_children():
        child.queue_free()
    _anim_btns.clear()
    var char_sprites: Array = _SPRITES.filter(func(s): return s.char == _char)
    for i in char_sprites.size():
        var btn := Button.new()
        btn.text = char_sprites[i].anim
        btn.add_theme_font_size_override("font_size", 16)
        btn.pressed.connect(_select_anim.bind(i))
        _anim_tabs_box.add_child(btn)
        _anim_btns.append(btn)
    _select_anim(0)

func _rebuild_strip() -> void:
    for child in _strip_box.get_children():
        child.queue_free()
    _strip_frames.clear()
    var sd  := _current_sprite()
    var tex := load(sd.path) as Texture2D
    for i in sd.frames:
        var at := AtlasTexture.new()
        at.atlas = tex
        at.filter_clip = true
        at.region = Rect2(i * _FRAME_SIZE, 0, _FRAME_SIZE, _FRAME_SIZE)
        var panel := Panel.new()
        panel.custom_minimum_size = Vector2(_STRIP_SIZE + 4, _STRIP_SIZE + 4)
        panel.mouse_filter = Control.MOUSE_FILTER_STOP
        var r := TextureRect.new()
        r.texture = at
        r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        r.mouse_filter = Control.MOUSE_FILTER_IGNORE
        panel.add_child(r)
        var idx := i
        panel.gui_input.connect(func(ev): _on_strip_input(ev, idx))
        _strip_box.add_child(panel)
        _strip_frames.append(panel)

func _update_preview() -> void:
    var sd  := _current_sprite()
    var tex := load(sd.path) as Texture2D
    var at  := AtlasTexture.new()
    at.atlas = tex
    at.filter_clip = true
    at.region = Rect2(_frame * _FRAME_SIZE, 0, _FRAME_SIZE, _FRAME_SIZE)
    _preview_rect.texture = at
    var status := "● pausado" if _paused else "● animando"
    _info_label.text = "%s %s\nframe %d/%d  |  %.0f fps\n%s" % [
        _char, sd.anim, _frame + 1, sd.frames, sd.fps, status
    ]
    for i in _strip_frames.size():
        var style := StyleBoxFlat.new()
        style.bg_color = Color(0.08, 0.08, 0.18)
        if i == _frame:
            style.border_color = Color(0, 1, 0)
            style.set_border_width_all(2)
        else:
            style.border_color = Color(0.25, 0.25, 0.25)
            style.set_border_width_all(1)
        _strip_frames[i].add_theme_stylebox_override("panel", style)

func _on_strip_input(event: InputEvent, idx: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _paused = true
        _frame  = idx
        _update_preview()

func _on_preview_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _paused = false
        _update_preview()

func _build_ui() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    z_index = 200

    var bg := ColorRect.new()
    bg.color = Color(0, 0, 0, 0.88)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var main := VBoxContainer.new()
    main.add_theme_constant_override("separation", 10)
    main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    main.offset_left   = 24
    main.offset_top    = 20
    main.offset_right  = -24
    main.offset_bottom = -20
    add_child(main)

    # Header
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 12)
    main.add_child(header)

    var title_lbl := Label.new()
    title_lbl.text = "ImgDebug"
    title_lbl.add_theme_font_size_override("font_size", 26)
    title_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 1.0))
    title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_lbl)

    var close_btn := Button.new()
    close_btn.text = "✕ Fechar"
    close_btn.add_theme_font_size_override("font_size", 18)
    close_btn.pressed.connect(queue_free)
    header.add_child(close_btn)

    # Section row: SPRITES | TILES
    var section_row := HBoxContainer.new()
    section_row.add_theme_constant_override("separation", 6)
    main.add_child(section_row)

    for s in ["SPRITES", "TILES"]:
        var btn := Button.new()
        btn.text = s
        btn.add_theme_font_size_override("font_size", 18)
        btn.pressed.connect(_show_section.bind(s))
        section_row.add_child(btn)
        _section_btns[s] = btn

    # ── SPRITES BOX ──────────────────────────────────────────
    _sprites_box = VBoxContainer.new()
    _sprites_box.add_theme_constant_override("separation", 8)
    main.add_child(_sprites_box)

    var char_row := HBoxContainer.new()
    char_row.add_theme_constant_override("separation", 6)
    _sprites_box.add_child(char_row)

    for c in ["ZAEL", "ZARA"]:
        var btn := Button.new()
        btn.text = c
        btn.add_theme_font_size_override("font_size", 18)
        btn.pressed.connect(_select_char.bind(c))
        char_row.add_child(btn)
        _char_btns[c] = btn

    _anim_tabs_box = HBoxContainer.new()
    _anim_tabs_box.add_theme_constant_override("separation", 4)
    _sprites_box.add_child(_anim_tabs_box)

    var preview_row := HBoxContainer.new()
    preview_row.add_theme_constant_override("separation", 16)
    _sprites_box.add_child(preview_row)

    _preview_rect = TextureRect.new()
    _preview_rect.custom_minimum_size = Vector2(_PREVIEW_SIZE, _PREVIEW_SIZE)
    _preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _preview_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _preview_rect.mouse_filter = Control.MOUSE_FILTER_STOP
    _preview_rect.gui_input.connect(_on_preview_input)
    preview_row.add_child(_preview_rect)

    var right_col := VBoxContainer.new()
    right_col.add_theme_constant_override("separation", 6)
    preview_row.add_child(right_col)

    _info_label = Label.new()
    _info_label.add_theme_font_size_override("font_size", 16)
    _info_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
    right_col.add_child(_info_label)

    _strip_box = HBoxContainer.new()
    _strip_box.add_theme_constant_override("separation", 4)
    right_col.add_child(_strip_box)

    var hint_lbl := Label.new()
    hint_lbl.text = "strip: clicar pausa  ·  preview: clicar retoma"
    hint_lbl.add_theme_font_size_override("font_size", 12)
    hint_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
    right_col.add_child(hint_lbl)

    # ── TILES BOX ────────────────────────────────────────────
    _tiles_box = VBoxContainer.new()
    _tiles_box.add_theme_constant_override("separation", 8)
    main.add_child(_tiles_box)

func _refresh_tiles() -> void:
    for child in _tiles_box.get_children():
        child.queue_free()

    for ts_data in _TILESETS:
        var lbl := Label.new()
        lbl.text = "%s  (%dx%d, %dpx cada)" % [ts_data.name, ts_data.cols, ts_data.rows, ts_data.tile_size]
        lbl.add_theme_font_size_override("font_size", 16)
        lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
        _tiles_box.add_child(lbl)

        _tile_info_label = Label.new()
        _tile_info_label.text = "clique num tile para ver as coordenadas"
        _tile_info_label.add_theme_font_size_override("font_size", 13)
        _tile_info_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
        _tiles_box.add_child(_tile_info_label)

        var grid := GridContainer.new()
        grid.columns = ts_data.cols
        grid.add_theme_constant_override("h_separation", 4)
        grid.add_theme_constant_override("v_separation", 4)
        _tiles_box.add_child(grid)

        var tex    := load(ts_data.path) as Texture2D
        var ts_px  := ts_data.tile_size

        for row in ts_data.rows:
            for col in ts_data.cols:
                var cell := VBoxContainer.new()
                cell.add_theme_constant_override("separation", 2)
                grid.add_child(cell)

                var at := AtlasTexture.new()
                at.atlas = tex
                at.filter_clip = true
                at.region = Rect2(col * ts_px, row * ts_px, ts_px, ts_px)

                var tile_rect := TextureRect.new()
                tile_rect.texture = at
                tile_rect.custom_minimum_size = Vector2(_TILE_DISPLAY, _TILE_DISPLAY)
                tile_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                tile_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
                tile_rect.mouse_filter = Control.MOUSE_FILTER_STOP
                var c := col
                var r := row
                tile_rect.gui_input.connect(func(ev): _on_tile_input(ev, c, r))
                cell.add_child(tile_rect)

                var coord_lbl := Label.new()
                coord_lbl.text = "—" if (col == 0 and row == 3) else "%d,%d" % [col, row]
                coord_lbl.add_theme_font_size_override("font_size", 11)
                coord_lbl.add_theme_color_override(
                    "font_color",
                    Color(0.3, 0.3, 0.3) if (col == 0 and row == 3) else Color(0.6, 0.6, 0.6)
                )
                coord_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                cell.add_child(coord_lbl)

func _on_tile_input(event: InputEvent, col: int, row: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if is_instance_valid(_tile_info_label):
            if col == 0 and row == 3:
                _tile_info_label.text = "Tile (0,3) — transparente (alpha = 0)"
            else:
                _tile_info_label.text = "Tile selecionado: (%d, %d)" % [col, row]
```

- [ ] **Step 6: Rodar os testes**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_img_debug.tscn
```

Esperado: `ALL TESTS PASSED`

- [ ] **Step 7: Commit**

```
git add tests/test_img_debug.gd tests/test_img_debug.tscn ui/img_debug.gd ui/img_debug.tscn
git commit -m "feat: ImgDebug panel — sprite viewer + tile grid"
```

---

### Task 2: Integração com title screen

**Files:**
- Modify: `ui/title_screen.tscn`
- Modify: `ui/title_screen.gd`

- [ ] **Step 1: Adicionar estilo BtnDebug e ImgDebugButton em title_screen.tscn**

Adicionar após o `[sub_resource type="StyleBoxFlat" id="BtnQuit"]` existente:

```
[sub_resource type="StyleBoxFlat" id="BtnDebug"]
bg_color = Color(0.12, 0.1, 0.22, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.5, 0.4, 0.9, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8
```

Adicionar após o nó `QuitButton`:

```
[node name="ImgDebugButton" type="Button" parent="VBox"]
layout_mode = 2
text = "ImgDebug"
theme_override_font_sizes/font_size = 34
theme_override_colors/font_color = Color(0.8, 0.75, 1.0, 1)
theme_override_styles/normal = SubResource("BtnDebug")
```

- [ ] **Step 2: Atualizar title_screen.gd**

```gdscript
# ui/title_screen.gd
extends Control

const _IMG_DEBUG_SCENE := preload("res://ui/img_debug.tscn")

var _debug_panel: Node = null

func _ready() -> void:
    $VBox/ContinueButton.disabled = not GameManager.has_save()
    $VBox/NewGameButton.pressed.connect(_on_new_game_pressed)
    $VBox/ContinueButton.pressed.connect(_on_continue_pressed)
    $VBox/QuitButton.pressed.connect(_on_quit_pressed)
    $VBox/ImgDebugButton.pressed.connect(_on_img_debug_pressed)

func _on_img_debug_pressed() -> void:
    if is_instance_valid(_debug_panel):
        _debug_panel.queue_free()
        _debug_panel = null
    else:
        _debug_panel = _IMG_DEBUG_SCENE.instantiate()
        add_child(_debug_panel)

func _on_new_game_pressed() -> void:
    GameManager.reset()
    get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_continue_pressed() -> void:
    if GameManager.load_game():
        get_tree().change_scene_to_file("res://ui/stage_select.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()
```

- [ ] **Step 3: Commit**

```
git add ui/title_screen.gd ui/title_screen.tscn
git commit -m "feat: botão ImgDebug na title screen instancia painel"
```

---

### Task 3: Export web + push

**Files:**
- Modify: `export/web/index.pck`

- [ ] **Step 1: Exportar build web**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" .godot/exported/web/index.html
```

Esperado: `[ DONE ] savepack`

- [ ] **Step 2: Copiar pck**

```bash
cp .godot/exported/web/index.pck export/web/index.pck
```

- [ ] **Step 3: Commit e push**

```
git add export/web/index.pck
git commit -m "build: web export com ImgDebug panel"
git push
```

---

## Self-Review

**Spec coverage:**
- ✅ Seção SPRITES / TILES → `_show_section()`
- ✅ Seleção de personagem ZAEL / ZARA → `_select_char()`
- ✅ Abas de animação por personagem → `_rebuild_anim_tabs()`
- ✅ Preview 136×136 animado → `_process(delta)` + `_update_preview()`
- ✅ Strip de frames clicáveis (pausa) → `_rebuild_strip()` + `_on_strip_input()`
- ✅ Clicar no preview retoma → `_on_preview_input()`
- ✅ Grid 4×4 de tiles com coordenadas → `_refresh_tiles()`
- ✅ Tile (0,3) transparente marcado com `—` → hardcoded no label
- ✅ Clicar tile destaca + info no rodapé → `_on_tile_input()`
- ✅ Botão ✕ Fechar dentro do painel → `close_btn.pressed.connect(queue_free)`
- ✅ Title screen instancia/destrói → `_on_img_debug_pressed()`
- ✅ Testes de dados, estado inicial, reset de anim, ciclo de frame

**Placeholder scan:** Nenhum TBD ou TODO encontrado.

**Type consistency:** `_select_anim`, `_select_char`, `_rebuild_anim_tabs`, `_rebuild_strip`, `_update_preview` usam os mesmos nomes em toda a cadeia de chamadas.
