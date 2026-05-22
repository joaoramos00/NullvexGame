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

const _TILE_DESCS: Dictionary = {
    "0,0": "Superfície superior — canto esquerdo da plataforma",
    "1,0": "Superfície superior — centro A (colunas pares)",
    "2,0": "Superfície superior — centro B (colunas ímpares, alternado com A)",
    "3,0": "Superfície superior — canto direito da plataforma",
    "0,1": "Interior da plataforma — lateral esquerda (plataformas com 2+ linhas)",
    "1,1": "Interior da plataforma — centro A (colunas pares)",
    "2,1": "Interior da plataforma — centro B (colunas ímpares, alternado com A)",
    "3,1": "Interior da plataforma — lateral direita (plataformas com 2+ linhas)",
    "0,2": "Base inferior — canto esquerdo da plataforma",
    "1,2": "Base inferior — centro A (colunas pares)",
    "2,2": "Base inferior — centro B (colunas ímpares, alternado com A)",
    "3,2": "Base inferior — canto direito da plataforma",
    "0,3": "Transparente — tile vazio (alpha = 0), não utilizado",
    "1,3": "Reservado — não utilizado pelo engine atual",
    "2,3": "Reservado — não utilizado pelo engine atual",
    "3,3": "Reservado — não utilizado pelo engine atual",
}

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
var _current_tex: Texture2D = null

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
var _tile_preview_rect: TextureRect
var _tile_desc_label: Label

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
    var frame_dur: float = 1.0 / float(sd.fps)
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
    var sd := _current_sprite()
    _current_tex = load(sd.path) as Texture2D
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
    if _current_tex == null:
        return
    var sd  := _current_sprite()
    var tex := _current_tex
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
        var idx: int = i
        panel.gui_input.connect(func(ev): _on_strip_input(ev, idx))
        _strip_box.add_child(panel)
        _strip_frames.append(panel)

func _update_preview() -> void:
    if _current_tex == null:
        return
    var sd  := _current_sprite()
    var tex := _current_tex
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

    # SPRITES BOX
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

    # TILES BOX
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
        _tile_info_label.text = "clique num tile para zoom"
        _tile_info_label.add_theme_font_size_override("font_size", 13)
        _tile_info_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
        _tiles_box.add_child(_tile_info_label)

        var content_row := HBoxContainer.new()
        content_row.add_theme_constant_override("separation", 16)
        _tiles_box.add_child(content_row)

        var grid := GridContainer.new()
        grid.columns = ts_data.cols
        grid.add_theme_constant_override("h_separation", 4)
        grid.add_theme_constant_override("v_separation", 4)
        content_row.add_child(grid)

        var zoom_panel := Panel.new()
        zoom_panel.custom_minimum_size = Vector2(160, 160)
        var zoom_style := StyleBoxFlat.new()
        zoom_style.bg_color = Color(0.05, 0.05, 0.12)
        zoom_style.border_color = Color(1.0, 0.9, 0.2)
        zoom_style.set_border_width_all(1)
        zoom_panel.add_theme_stylebox_override("panel", zoom_style)
        content_row.add_child(zoom_panel)

        _tile_preview_rect = TextureRect.new()
        _tile_preview_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        _tile_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        _tile_preview_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        _tile_preview_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        zoom_panel.add_child(_tile_preview_rect)

        _tile_desc_label = Label.new()
        _tile_desc_label.text = ""
        _tile_desc_label.add_theme_font_size_override("font_size", 80)
        _tile_desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.6))
        _tile_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _tile_desc_label.custom_minimum_size = Vector2(160, 0)
        content_row.add_child(_tile_desc_label)

        var tex    := load(ts_data.path) as Texture2D
        var ts_px: int = ts_data.tile_size

        for row in ts_data.rows:
            for col in ts_data.cols:
                var cell := VBoxContainer.new()
                cell.add_theme_constant_override("separation", 2)
                grid.add_child(cell)

                var at := AtlasTexture.new()
                at.atlas = tex
                at.filter_clip = true
                at.region = Rect2(col * ts_px, row * ts_px, ts_px, ts_px)

                var tile_panel := Panel.new()
                tile_panel.custom_minimum_size = Vector2(_TILE_DISPLAY, _TILE_DISPLAY)
                tile_panel.mouse_filter = Control.MOUSE_FILTER_STOP
                var tile_style := StyleBoxFlat.new()
                tile_style.bg_color = Color(0.08, 0.08, 0.18)
                tile_style.border_color = Color(1.0, 0.9, 0.2)
                tile_style.set_border_width_all(1)
                tile_panel.add_theme_stylebox_override("panel", tile_style)
                var c: int = col
                var r: int = row
                tile_panel.gui_input.connect(func(ev): _on_tile_input(ev, c, r))
                cell.add_child(tile_panel)

                var tile_rect := TextureRect.new()
                tile_rect.texture = at
                tile_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
                tile_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                tile_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
                tile_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
                tile_panel.add_child(tile_rect)

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
        if is_instance_valid(_tile_preview_rect):
            var ts_data: Dictionary = _TILESETS[0]
            var ts_px: int = ts_data.tile_size
            var at := AtlasTexture.new()
            at.atlas = load(ts_data.path) as Texture2D
            at.filter_clip = true
            at.region = Rect2(col * ts_px, row * ts_px, ts_px, ts_px)
            _tile_preview_rect.texture = at
        if is_instance_valid(_tile_desc_label):
            _tile_desc_label.text = _TILE_DESCS.get("%d,%d" % [col, row], "")
