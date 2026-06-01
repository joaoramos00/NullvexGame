extends Node2D

const _PLAYER_PATH := "res://characters/ranged/zael.tscn"
const _ENEMY_PATHS := [
    "res://characters/enemies/enemy_base.tscn",
    "res://characters/enemies/enemy_flyer.tscn",
    "res://characters/bosses/ignarath.tscn",
    "res://characters/bosses/cryovex.tscn",
    "res://characters/bosses/voltrix.tscn",
    "res://characters/bosses/gravitus.tscn",
    "res://characters/bosses/galerix.tscn",
    "res://characters/bosses/umbraex.tscn",
    "res://characters/bosses/luxar.tscn",
    "res://characters/bosses/terragor.tscn",
]
const _ENEMY_NAMES := [
    "Grunt", "Flyer",
    "Ignarath", "Cryovex", "Voltrix", "Gravitus", "Galerix", "Umbraex", "Luxar", "Terragor",
]
const _GROUND_Y := 600.0
const _PLAYER_X := 280.0
const _ENEMY_X  := 680.0
const _ENEMY_Y  := [560.0, 380.0, 536.0, 536.0, 536.0, 536.0, 536.0, 536.0, 536.0, 536.0]

const _TILE_TEX  := preload("res://stages/stage_00/Stage_00T.png")
const _GLASS_TEX := preload("res://stages/stage_00/stage_00_glass.png")
const _TS  := 32.0   # source tile size
const _TW  := 64.0   # display tile size
const _WL  := 100.0  # left  wall x
const _WR  := 1400.0 # right wall x
const _GWL := 480.0  # left  glass wall x
const _GWR := 920.0  # right glass wall x
const _GLASS_ROWS := 8  # glass wall height in tiles

var _enemy_index: int = 0
var _current_enemy: EnemyBase = null
var _current_boss: BossBase   = null
var _player: CharacterBase = null
var _label_enemy: Label
var _lbl_state: Label

func _ready() -> void:
    _setup_game_manager()
    _build_physics()
    _build_ui()
    _spawn_player()
    _spawn_enemy()
    $Camera2D.global_position = Vector2(_PLAYER_X, _GROUND_Y - 24.0 + 120.0)

func _process(_delta: float) -> void:
    if is_instance_valid(_player):
        var cam_y: float = clamp(_player.global_position.y + 120.0, _GROUND_Y - 400.0, _GROUND_Y + 200.0)
        $Camera2D.global_position = Vector2(_player.global_position.x, cam_y)
        queue_redraw()
        _update_state_label()

func _draw() -> void:
    # Fundo
    draw_rect(Rect2(-32000.0, -32000.0, 64000.0, 64000.0), Color(0.07, 0.08, 0.16))

    # Tiles do Stage_00T
    _draw_tiles()

    # Pose do player
    if not is_instance_valid(_player):
        return
    var pos     := _player.global_position + Vector2(0.0, -90.0)
    var on_floor := _player.is_on_floor()
    var on_wall  := _player._is_wall_sliding
    if on_wall:
        _draw_wall_pose(pos, _player.get_wall_normal())
    else:
        _draw_pose(pos, on_floor)

func _draw_tiles() -> void:
    var top  := Rect2(3.0 * _TS, 0.0,        _TS, _TS)  # (3,0) TOP
    var fill := Rect2(2.0 * _TS, 1.0 * _TS,  _TS, _TS)  # (2,1) FILL
    var left := Rect2(3.0 * _TS, 2.0 * _TS,  _TS, _TS)  # (3,2) LEFT
    var rght := Rect2(1.0 * _TS, 0.0,        _TS, _TS)  # (1,0) RIGHT

    # Chão
    var tx := _WL
    while tx <= _WR:
        draw_texture_rect_region(_TILE_TEX, Rect2(tx, _GROUND_Y,         _TW, _TW), top)
        draw_texture_rect_region(_TILE_TEX, Rect2(tx, _GROUND_Y + _TW,   _TW, _TW), fill)
        tx += _TW

    # Paredes normais
    for i: int in 10:
        var ty := _GROUND_Y - float(i + 1) * _TW
        draw_texture_rect_region(_TILE_TEX, Rect2(_WL - _TW, ty, _TW, _TW), left)
        draw_texture_rect_region(_TILE_TEX, Rect2(_WR,        ty, _TW, _TW), rght)

    _draw_glass_walls()

func _draw_glass_walls() -> void:
    var src      := _TS
    var fill_src := Rect2(2.0 * src, 1.0 * src, src, src)  # tile (2,1) fill
    var lat_r    := Rect2(1.0 * src, 0.0,        src, src)  # tile (1,0) borda p/ dir
    var lat_l    := Rect2(3.0 * src, 2.0 * src,  src, src)  # tile (3,2) borda p/ esq
    var font     := ThemeDB.fallback_font
    var lc       := Color(0.5, 0.9, 1.0, 0.9)
    var nc       := Color(0.9, 0.85, 0.4, 0.8)
    var ty0      := _GROUND_Y - float(_GLASS_ROWS) * _TW
    var rows     := _GLASS_ROWS - 1  # 1 tile de gap no fundo → player passa andando

    # Parede de vidro esquerda (colisão em _GWL)
    # borda (1,0) à esquerda + fills à direita
    for i in rows:
        var ty := _GROUND_Y - float(i + 1) * _TW
        draw_texture_rect_region(_GLASS_TEX, Rect2(_GWL - _TW, ty, _TW, _TW), lat_r)
        draw_texture_rect_region(_GLASS_TEX, Rect2(_GWL,        ty, _TW, _TW), fill_src)

    # Parede de vidro direita (colisão em _GWR)
    # fills à esquerda + borda (3,2) à direita
    for i in rows:
        var ty := _GROUND_Y - float(i + 1) * _TW
        draw_texture_rect_region(_GLASS_TEX, Rect2(_GWR - _TW, ty, _TW, _TW), fill_src)
        draw_texture_rect_region(_GLASS_TEX, Rect2(_GWR,        ty, _TW, _TW), lat_l)

    # Labels
    draw_string(font, Vector2(_GWL - _TW, ty0 - 14.0),
        "VIDRO — sem grab", HORIZONTAL_ALIGNMENT_LEFT, 136.0, 17, lc)
    draw_string(font, Vector2(_GWR - _TW, ty0 - 14.0),
        "VIDRO — sem grab", HORIZONTAL_ALIGNMENT_LEFT, 136.0, 17, lc)
    draw_string(font, Vector2(_WL + 8.0, ty0 - 14.0),
        "NORMAL — grab OK", HORIZONTAL_ALIGNMENT_LEFT, 130.0, 17, nc)
    draw_string(font, Vector2(_WR - 138.0, ty0 - 14.0),
        "NORMAL — grab OK", HORIZONTAL_ALIGNMENT_LEFT, 130.0, 17, nc)

func _draw_wall_pose(pos: Vector2, wall_normal: Vector2) -> void:
    var c  := Color(0.92, 0.92, 1.0, 0.85)
    var tw := 2.5
    var kd: float = -sign(wall_normal.x)
    draw_circle(pos + Vector2(0.0, 6.0), 36.0, Color(0.0, 0.0, 0.0, 0.38))
    draw_line(pos + Vector2(kd * 35.0, -30.0), pos + Vector2(kd * 35.0, 30.0), Color(0.55, 0.55, 0.75, 0.7), 3.0)
    draw_circle(pos + Vector2(-kd * 4.0, -16.0), 7.0, c)
    draw_line(pos + Vector2(-kd * 3.0, -9.0), pos + Vector2(0.0, 8.0), c, tw)
    draw_line(pos + Vector2(-kd * 12.0, -3.0), pos + Vector2(0.0, 1.0), c, 2.0)
    draw_line(pos + Vector2(0.0, 1.0), pos + Vector2(kd * 11.0, -7.0), c, 2.0)
    draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(kd * 22.0, 3.0), c, tw)
    draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(-kd * 9.0, 21.0), c, tw)

func _draw_pose(pos: Vector2, on_floor: bool) -> void:
    var c  := Color(0.92, 0.92, 1.0, 0.85)
    var tw := 2.5
    draw_circle(pos + Vector2(0.0, 6.0), 34.0, Color(0.0, 0.0, 0.0, 0.38))
    draw_circle(pos + Vector2(0.0, -16.0), 7.0, c)
    draw_line(pos + Vector2(0.0, -9.0), pos + Vector2(0.0, 8.0), c, tw)
    if on_floor:
        draw_line(pos + Vector2(-12.0, 0.0), pos + Vector2(12.0, 0.0), c, 2.0)
        draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(-9.0, 23.0), c, tw)
        draw_line(pos + Vector2(0.0, 8.0), pos + Vector2( 9.0, 23.0), c, tw)
    else:
        draw_line(pos + Vector2(-13.0, -7.0), pos + Vector2(0.0,  1.0), c, 2.0)
        draw_line(pos + Vector2(  0.0,  1.0), pos + Vector2(13.0, 6.0), c, 2.0)
        draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(-13.0, 21.0), c, tw)
        draw_line(pos + Vector2(0.0, 8.0), pos + Vector2( 13.0,  3.0), c, tw)

func _setup_game_manager() -> void:
    GameManager.active_character = "zael"
    GameManager.max_hp = 8
    GameManager.zael_selected_shot = "single"

func _build_physics() -> void:
    # Chão
    var ground := StaticBody2D.new()
    ground.collision_layer = 1
    add_child(ground)
    var gcs := CollisionShape2D.new()
    var gseg := SegmentShape2D.new()
    gseg.a = Vector2(-8000.0, _GROUND_Y)
    gseg.b = Vector2( 8000.0, _GROUND_Y)
    gcs.shape = gseg
    ground.add_child(gcs)

    # Paredes normais (wall grab OK)
    for wx: float in [_WL, _WR]:
        var wall := StaticBody2D.new()
        wall.collision_layer = 1
        add_child(wall)
        var wcs := CollisionShape2D.new()
        var wseg := SegmentShape2D.new()
        wseg.a = Vector2(wx, _GROUND_Y - 400.0)
        wseg.b = Vector2(wx, _GROUND_Y)
        wcs.shape = wseg
        wall.add_child(wcs)

    # Paredes de vidro (no_wall_grab) — gap de 1 tile no fundo, player passa andando
    for gx: float in [_GWL, _GWR]:
        var gwall := StaticBody2D.new()
        gwall.collision_layer = 1
        gwall.add_to_group("no_wall_grab")
        add_child(gwall)
        var gwcs := CollisionShape2D.new()
        var gwseg := SegmentShape2D.new()
        gwseg.a = Vector2(gx, _GROUND_Y - float(_GLASS_ROWS) * _TW)
        gwseg.b = Vector2(gx, _GROUND_Y - _TW)
        gwcs.shape = gwseg
        gwall.add_child(gwcs)

func _build_ui() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)

    var panel := Panel.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    panel.offset_bottom = 58.0
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.04, 0.04, 0.1, 0.9)
    panel.add_theme_stylebox_override("panel", style)
    ui.add_child(panel)

    var row := HBoxContainer.new()
    row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    row.add_theme_constant_override("separation", 10)
    row.offset_left  = 14.0
    row.offset_right = -14.0
    panel.add_child(row)

    var btn_back := Button.new()
    btn_back.text = "◄ ImgDebug"
    btn_back.add_theme_font_size_override("font_size", 18)
    btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://ui/img_debug.tscn"))
    row.add_child(btn_back)

    var spacer_l := Control.new()
    spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(spacer_l)

    var lbl_title := Label.new()
    lbl_title.text = "Teste de Movimentos"
    lbl_title.add_theme_font_size_override("font_size", 20)
    lbl_title.add_theme_color_override("font_color", Color(0.8, 0.75, 1.0))
    lbl_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(lbl_title)

    var spacer_r := Control.new()
    spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(spacer_r)

    var lbl_prefix := Label.new()
    lbl_prefix.text = "Inimigo: "
    lbl_prefix.add_theme_font_size_override("font_size", 18)
    lbl_prefix.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(lbl_prefix)

    var btn_prev := Button.new()
    btn_prev.text = "◄"
    btn_prev.add_theme_font_size_override("font_size", 18)
    btn_prev.pressed.connect(_on_prev)
    row.add_child(btn_prev)

    _label_enemy = Label.new()
    _label_enemy.custom_minimum_size.x = 80.0
    _label_enemy.add_theme_font_size_override("font_size", 18)
    _label_enemy.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
    _label_enemy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label_enemy.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    row.add_child(_label_enemy)

    var btn_next := Button.new()
    btn_next.text = "►"
    btn_next.add_theme_font_size_override("font_size", 18)
    btn_next.pressed.connect(_on_next)
    row.add_child(btn_next)

    var hint := Label.new()
    hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    hint.offset_top = -32.0
    hint.text = "A/D: mover  ·  Z: pular  ·  X: dash  ·  J: atirar (segurar → L2/L3)"
    hint.add_theme_font_size_override("font_size", 14)
    hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ui.add_child(hint)

    _lbl_state = Label.new()
    _lbl_state.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    _lbl_state.offset_top    = 62.0
    _lbl_state.offset_left   = 14.0
    _lbl_state.offset_right  = 700.0
    _lbl_state.offset_bottom = 86.0
    _lbl_state.add_theme_font_size_override("font_size", 16)
    ui.add_child(_lbl_state)

func _update_state_label() -> void:
    if not is_instance_valid(_lbl_state) or not is_instance_valid(_player):
        return
    var ws := _player._is_wall_sliding
    var ow := _player.is_on_wall() and not _player.is_on_floor()
    if ws:
        _lbl_state.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
        _lbl_state.text = "Parede NORMAL — agarrado  (wall jump: Z)"
    elif ow:
        _lbl_state.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
        _lbl_state.text = "Parede VIDRO — sem grab  (cai com gravidade normal)"
    elif _player.is_on_floor():
        _lbl_state.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
        _lbl_state.text = "No chão"
    else:
        _lbl_state.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
        _lbl_state.text = "No ar"

func _spawn_player() -> void:
    if is_instance_valid(_player):
        _player.queue_free()
    var scene := load(_PLAYER_PATH) as PackedScene
    if scene == null:
        return
    _player = scene.instantiate() as CharacterBase
    add_child(_player)
    _player.global_position = Vector2(_PLAYER_X, _GROUND_Y - 24.0)
    _player.died.connect(func(): call_deferred("_spawn_player"))

func _spawn_enemy() -> void:
    if is_instance_valid(_current_enemy):
        _current_enemy.queue_free()
    if is_instance_valid(_current_boss):
        _current_boss.queue_free()
    _current_enemy = null
    _current_boss  = null

    var scene := load(_ENEMY_PATHS[_enemy_index]) as PackedScene
    if scene == null:
        return
    var inst := scene.instantiate()
    add_child(inst)
    (inst as Node2D).global_position = Vector2(_ENEMY_X, _ENEMY_Y[_enemy_index])

    if inst is EnemyBase:
        _current_enemy = inst as EnemyBase
        _current_enemy.set_physics_process(false)
        _current_enemy.show_hitbox = true
        _current_enemy.max_hp      = 99999
        _current_enemy.current_hp  = 99999
        var spr := _current_enemy.get_node_or_null("Sprite2D") as Sprite2D
        if spr:
            spr.flip_h = true
    elif inst is BossBase:
        _current_boss = inst as BossBase
        _current_boss.player     = _player
        _current_boss.max_hp     = 99999
        _current_boss.current_hp = 99999
        _current_boss.stage_id   = -1
        _current_boss.ability_id = ""

    _label_enemy.text = _ENEMY_NAMES[_enemy_index]

func _on_prev() -> void:
    _enemy_index = (_enemy_index - 1 + _ENEMY_PATHS.size()) % _ENEMY_PATHS.size()
    _spawn_enemy()

func _on_next() -> void:
    _enemy_index = (_enemy_index + 1) % _ENEMY_PATHS.size()
    _spawn_enemy()
