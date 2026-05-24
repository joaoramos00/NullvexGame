extends Node2D

const _PLAYER_PATH := "res://characters/ranged/zael.tscn"
const _ENEMY_PATHS := [
    "res://characters/enemies/enemy_base.tscn",
    "res://characters/enemies/enemy_flyer.tscn",
]
const _ENEMY_NAMES := ["Grunt", "Flyer"]
const _GROUND_Y    := 600.0
const _PLAYER_X    := 280.0
const _ENEMY_X     := 680.0
# EnemyBase: capsule radius=20, height=40 → bottom at origin+40 → GROUND_Y-40
# EnemyFlyer: flutua, posição arbitrária
const _ENEMY_Y := [560.0, 380.0]

var _enemy_index: int = 0
var _current_enemy: EnemyBase = null
var _player: CharacterBase = null
var _label_enemy: Label

func _ready() -> void:
    _setup_game_manager()
    _build_ground()
    _build_walls()
    _build_ui()
    _spawn_player()
    _spawn_enemy()
    $Camera2D.global_position = Vector2(_PLAYER_X, _GROUND_Y - 24.0 + 120.0)

func _process(_delta: float) -> void:
    if is_instance_valid(_player):
        var cam_y := clamp(_player.global_position.y + 120.0, _GROUND_Y - 400.0, _GROUND_Y + 200.0)
        $Camera2D.global_position = Vector2(_player.global_position.x, cam_y)
        queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-32000.0, -32000.0, 64000.0, 64000.0), Color(0.07, 0.08, 0.16))
    if not is_instance_valid(_player):
        return
    var pos      := _player.global_position + Vector2(0.0, -90.0)
    var on_floor := _player.is_on_floor()
    var on_wall  := _player.is_on_wall() and not on_floor
    if on_wall:
        _draw_wall_pose(pos, _player.get_wall_normal())
    else:
        _draw_pose(pos, on_floor)

func _draw_wall_pose(pos: Vector2, wall_normal: Vector2) -> void:
    var c  := Color(0.92, 0.92, 1.0, 0.85)
    var tw := 2.5
    var kd := -sign(wall_normal.x)  # direção do chute (em direção à parede)

    draw_circle(pos + Vector2(0.0, 6.0), 36.0, Color(0.0, 0.0, 0.0, 0.38))

    # Linha indicando a parede
    var wx := kd * 35.0
    draw_line(pos + Vector2(wx, -30.0), pos + Vector2(wx, 30.0), Color(0.55, 0.55, 0.75, 0.7), 3.0)

    # Cabeça afastada da parede
    draw_circle(pos + Vector2(-kd * 4.0, -16.0), 7.0, c)
    # Tronco ligeiramente inclinado
    draw_line(pos + Vector2(-kd * 3.0, -9.0), pos + Vector2(0.0, 8.0), c, tw)
    # Braço em direção à parede (apoio / impulso)
    draw_line(pos + Vector2(-kd * 12.0, -3.0), pos + Vector2(0.0, 1.0), c, 2.0)
    draw_line(pos + Vector2(0.0, 1.0),          pos + Vector2(kd * 11.0, -7.0), c, 2.0)
    # Perna de chute — estendida horizontalmente contra a parede
    draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(kd * 22.0, 3.0), c, tw)
    # Perna traseira — dobrada para trás e levemente abaixo
    draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(-kd * 9.0, 21.0), c, tw)

func _draw_pose(pos: Vector2, on_floor: bool) -> void:
    var c    := Color(0.92, 0.92, 1.0, 0.85)
    var tw   := 2.5

    # Fundo semi-transparente para contraste
    draw_circle(pos + Vector2(0.0, 6.0), 34.0, Color(0.0, 0.0, 0.0, 0.38))

    # Cabeça
    draw_circle(pos + Vector2(0.0, -16.0), 7.0, c)
    # Tronco
    draw_line(pos + Vector2(0.0, -9.0), pos + Vector2(0.0, 8.0), c, tw)

    if on_floor:
        # Braços horizontais
        draw_line(pos + Vector2(-12.0, 0.0), pos + Vector2(12.0, 0.0), c, 2.0)
        # Pernas simétricas (no chão)
        draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(-9.0, 23.0), c, tw)
        draw_line(pos + Vector2(0.0, 8.0), pos + Vector2( 9.0, 23.0), c, tw)
    else:
        # Braços em movimento (assimétricos)
        draw_line(pos + Vector2(-13.0, -7.0), pos + Vector2(0.0,  1.0), c, 2.0)
        draw_line(pos + Vector2(  0.0,  1.0), pos + Vector2(13.0, 6.0), c, 2.0)
        # Perna traseira (baixa) e dianteira (elevada) — "pé mais para cima que o outro"
        draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(-13.0, 21.0), c, tw)
        draw_line(pos + Vector2(0.0, 8.0), pos + Vector2( 13.0,  3.0), c, tw)

func _setup_game_manager() -> void:
    GameManager.active_character = "zael"
    GameManager.max_hp = 8
    GameManager.zael_selected_shot = "single"

func _build_ground() -> void:
    var body := StaticBody2D.new()
    body.collision_layer = 1
    add_child(body)
    var cs := CollisionShape2D.new()
    var seg := SegmentShape2D.new()
    seg.a = Vector2(-8000.0, _GROUND_Y)
    seg.b = Vector2( 8000.0, _GROUND_Y)
    cs.shape = seg
    body.add_child(cs)

    var line := Line2D.new()
    line.add_point(Vector2(-8000.0, _GROUND_Y))
    line.add_point(Vector2( 8000.0, _GROUND_Y))
    line.width = 3.0
    line.default_color = Color(0.4, 0.42, 0.55)
    add_child(line)

func _build_walls() -> void:
    for wx in [100.0, 1400.0]:
        var body := StaticBody2D.new()
        body.collision_layer = 1
        add_child(body)
        var cs := CollisionShape2D.new()
        var seg := SegmentShape2D.new()
        seg.a = Vector2(wx, _GROUND_Y - 400.0)
        seg.b = Vector2(wx, _GROUND_Y)
        cs.shape = seg
        body.add_child(cs)
        var line := Line2D.new()
        line.add_point(Vector2(wx, _GROUND_Y - 400.0))
        line.add_point(Vector2(wx, _GROUND_Y))
        line.width = 3.0
        line.default_color = Color(0.4, 0.42, 0.55)
        add_child(line)

func _build_ui() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)

    # Barra superior
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

    # Dicas no rodapé
    var hint := Label.new()
    hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    hint.offset_top = -32.0
    hint.text = "A/D: mover  ·  Z: pular  ·  X: dash  ·  J: atirar (segurar → L2/L3)"
    hint.add_theme_font_size_override("font_size", 14)
    hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ui.add_child(hint)

func _spawn_player() -> void:
    if is_instance_valid(_player):
        _player.queue_free()
    var scene := load(_PLAYER_PATH) as PackedScene
    if scene == null:
        return
    _player = scene.instantiate() as CharacterBase
    add_child(_player)
    # Zael: capsule radius=10, height=28 → bottom at origin+24
    _player.global_position = Vector2(_PLAYER_X, _GROUND_Y - 24.0)
    _player.died.connect(func(): call_deferred("_spawn_player"))

func _spawn_enemy() -> void:
    if is_instance_valid(_current_enemy):
        _current_enemy.queue_free()
    var scene := load(_ENEMY_PATHS[_enemy_index]) as PackedScene
    if scene == null:
        return
    _current_enemy = scene.instantiate() as EnemyBase
    add_child(_current_enemy)
    _current_enemy.global_position = Vector2(_ENEMY_X, _ENEMY_Y[_enemy_index])
    _current_enemy.set_physics_process(false)
    _current_enemy.show_hitbox = true
    _current_enemy.max_hp     = 99999
    _current_enemy.current_hp = 99999
    var spr := _current_enemy.get_node_or_null("Sprite2D") as Sprite2D
    if spr:
        spr.flip_h = true
    _label_enemy.text = _ENEMY_NAMES[_enemy_index]

func _on_prev() -> void:
    _enemy_index = (_enemy_index - 1 + _ENEMY_PATHS.size()) % _ENEMY_PATHS.size()
    _spawn_enemy()

func _on_next() -> void:
    _enemy_index = (_enemy_index + 1) % _ENEMY_PATHS.size()
    _spawn_enemy()
