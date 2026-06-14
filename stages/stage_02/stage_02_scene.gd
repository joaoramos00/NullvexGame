extends Node2D

var _door_tex: Texture2D = null
var _tileset_z1: Texture2D = null
var _tileset_z2: Texture2D = null
var _tileset_z3: Texture2D = null
var _tileset_z4: Texture2D = null
var _glass_tex: Texture2D = null
var _zael_scene: PackedScene = null
var _zara_scene: PackedScene = null
var _grunt_scene: PackedScene = null
var _flyer_scene: PackedScene = null
var _mb02_scene: PackedScene = null
var _archer_scene: PackedScene = null
var _turret_scene: PackedScene = null
var _bomber_scene: PackedScene = null
var _shield_scene: PackedScene = null
var _wisp_scene: PackedScene = null

const _TS := 64
const _SRC_TS := 32

const Z1_GRUNTS := [Vector2(700, 856), Vector2(1280, 792), Vector2(1840, 728), Vector2(2380, 856)]
const Z1_FLYERS := [Vector2(1050, 650), Vector2(2100, 610)]
const Z1_ARCHERS := [Vector2(1600, 856), Vector2(2520, 856)]
const Z2_GRUNTS := [Vector2(3180, 856), Vector2(3650, 792), Vector2(4200, 720), Vector2(4720, 856)]
const Z2_FLYERS := [Vector2(3450, 610), Vector2(4550, 560)]
const Z2_ARCHERS := [Vector2(2920, 856), Vector2(5050, 856)]
const Z2_SHIELDS := [Vector2(3980, 792)]
const Z3_GRUNTS := [Vector2(7300, 856), Vector2(7900, 760), Vector2(8500, 650), Vector2(9100, 760), Vector2(9700, 856)]
const Z3_FLYERS := [Vector2(8100, 560), Vector2(9000, 500), Vector2(10050, 610)]
const Z3_TURRETS := [Vector2(7720, 700), Vector2(9480, 820)]
const Z3_WISPS := [Vector2(8500, 500), Vector2(10000, 540)]
const Z4_GRUNTS := [Vector2(10800, 856), Vector2(11350, 760), Vector2(11900, 650), Vector2(12600, 760)]
const Z4_FLYERS := [Vector2(11100, 540), Vector2(12150, 500), Vector2(12900, 580)]
const Z4_TURRETS := [Vector2(11280, 820), Vector2(12520, 820)]
const Z4_BOMBERS := [Vector2(11600, 760), Vector2(12880, 856)]
const Z4_SHIELDS := [Vector2(12050, 760)]
const Z4_WISPS := [Vector2(11050, 500), Vector2(12350, 500)]

# Superfície de piso única (zonas E corredores) — corrige o desalinhamento de 88px.
const FLOOR_Y := 800.0          # topo do piso (player origin fica ~40px acima)
const _CORR_INTERIOR := 192.0   # vão interno do corredor (piso↔teto)

const _CP1_ENTRY_X := 10600.0
const _CP1_EXIT_X := 11400.0
const _MB_LEFT := 11500.0
const _MB_RIGHT := 12300.0
const _CP2_ENTRY_X := 12400.0
const _CP2_EXIT_X := 13200.0
const _CP3_ENTRY_X := 23600.0
const _CP3_EXIT_X := 24400.0
const _BOSS_ENTRY_X := 24550.0

var _player: CharacterBase = null
var _camera_locked := false
var _camera_target := Vector2.ZERO
var _camera_zoom_tgt := 2.2
var _corr1: CorridorSection = null
var _corr2: CorridorSection = null
var _corr3: CorridorSection = null
var _mb02: Node2D = null
var _mb02_spawned := false
var _zone1_enemies: Array[Node] = []
var _zone2_enemies: Array[Node] = []
var _zone3_enemies: Array[Node] = []
var _zone4_enemies: Array[Node] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_resources()
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")
	StageManager.spawn_position = $PlayerSpawn.global_position
	_spawn_player()
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)
	$Camera2D.zoom = Vector2(2.2, 2.2)
	AudioManager.play_bgm(AudioLibrary.get_stage_bgm(2))
	_setup_corridors()
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _load_resources() -> void:
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_tileset_z1 = load("res://stages/stage_02/Stage_02T_z1.png") as Texture2D
	_tileset_z2 = load("res://stages/stage_02/Stage_02T_z2.png") as Texture2D
	_tileset_z3 = load("res://stages/stage_02/Stage_02T_z3.png") as Texture2D
	_tileset_z4 = load("res://stages/stage_02/Stage_02T_z4.png") as Texture2D
	_glass_tex = load("res://stages/stage_02/stage_02_glass.png") as Texture2D
	_zael_scene = load("res://characters/ranged/zael.tscn") as PackedScene
	_zara_scene = load("res://characters/melee/zara.tscn") as PackedScene
	_grunt_scene = load("res://characters/enemies/stage_02/enemy_ice_grunt.tscn") as PackedScene
	_flyer_scene = load("res://characters/enemies/stage_02/enemy_ice_flyer.tscn") as PackedScene
	_mb02_scene = load("res://characters/enemies/stage_02/enemy_ice_miniboss.tscn") as PackedScene
	_archer_scene = load("res://characters/enemies/stage_02/enemy_ice_archer.tscn") as PackedScene
	_turret_scene = load("res://characters/enemies/stage_02/enemy_frost_turret.tscn") as PackedScene
	_bomber_scene = load("res://characters/enemies/stage_02/enemy_cryo_bomber.tscn") as PackedScene
	_shield_scene = load("res://characters/enemies/stage_02/enemy_glacier_shield.tscn") as PackedScene
	_wisp_scene = load("res://characters/enemies/stage_02/enemy_ice_wisp.tscn") as PackedScene

func _process(_delta: float) -> void:
	var cam := $Camera2D as Camera2D
	if not is_instance_valid(_player):
		return
	if _camera_locked:
		cam.global_position = cam.global_position.lerp(_camera_target, 0.12)
		cam.zoom = cam.zoom.lerp(Vector2(_camera_zoom_tgt, _camera_zoom_tgt), 0.12)
	else:
		cam.zoom = cam.zoom.lerp(Vector2(2.2, 2.2), 0.12)
		cam.global_position = cam.global_position.lerp(_player.global_position - Vector2(0, 70), 0.12)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		$PauseMenu.toggle_pause()

func _spawn_player() -> void:
	var scene := _zara_scene if GameManager.active_character == "zara" else _zael_scene
	if scene == null:
		return
	_player = scene.instantiate() as CharacterBase
	_player.add_to_group("player")
	_player.global_position = StageManager.get_respawn_position()
	if _player.global_position == Vector2.ZERO:
		_player.global_position = $PlayerSpawn.global_position
	add_child(_player)

func _setup_corridors() -> void:
	_corr1 = _make_corridor("CP1", _CP1_ENTRY_X, _CP1_EXIT_X, 1, false, false)
	_corr2 = _make_corridor("CP2", _CP2_ENTRY_X, _CP2_EXIT_X, 2, true, false)
	_corr3 = _make_corridor("CP3", _CP3_ENTRY_X, _CP3_EXIT_X, 3, false, false)

func _make_corridor(name_prefix: String, entry_x: float, exit_x: float, checkpoint_index: int, manual: bool, heal: bool) -> CorridorSection:
	var width := exit_x - entry_x
	var corr := CorridorSection.new()
	corr.name = name_prefix
	corr.tileset = _tileset_z2 if checkpoint_index == 1 else (_tileset_z3 if checkpoint_index == 2 else _tileset_z4)
	corr.glass_tex = _glass_tex
	corr.door_tex = _door_tex
	var floor_cy := FLOOR_Y + 32.0                      # topo do piso = FLOOR_Y (800) → centro 832
	var ceil_cy := FLOOR_Y - _CORR_INTERIOR - 32.0      # fundo do teto = FLOOR_Y - 192 → centro
	var mid_y := (floor_cy + ceil_cy) * 0.5
	corr.floor_center = Vector2(entry_x + width * 0.5, floor_cy)
	corr.floor_size = Vector2(width, 64.0)
	corr.ceil_center = Vector2(entry_x + width * 0.5, ceil_cy)
	corr.ceil_size = Vector2(width, 64.0)
	corr.wall_l_center = Vector2(entry_x, mid_y)
	corr.wall_l_size = Vector2(64.0, _CORR_INTERIOR + 64.0)
	corr.wall_r_center = Vector2(exit_x, mid_y)
	corr.wall_r_size = Vector2(64.0, _CORR_INTERIOR + 64.0)
	corr.entry_x = entry_x
	corr.exit_x = exit_x
	corr.entry_manual = manual
	corr.save_checkpoint = true
	corr.heal_on_entry = heal
	corr.checkpoint_index = checkpoint_index
	corr.checkpoint_respawn_x = exit_x + 128.0
	corr.cam_center = Vector2(entry_x + width * 0.5, mid_y)
	corr.cam_zoom = 2.0
	corr.glass_lateral_x = entry_x - 64.0
	corr.glass_fill_x = entry_x
	corr.glass_fill_cols = int(width / 64.0)
	corr.camera_lock_requested.connect(_on_corridor_cam_lock)
	corr.player_traversed.connect(_on_corridor_traversed)
	add_child(corr)
	corr.setup(_player)
	return corr

func _on_corridor_cam_lock(center: Vector2, zoom: float) -> void:
	_camera_locked = true
	_camera_target = center
	_camera_zoom_tgt = zoom

func _on_corridor_traversed() -> void:
	_camera_locked = false

func _setup_zone_triggers() -> void:
	_make_zone_trigger("Z2Trigger", Rect2(2800, 400, 2400, 800), 2)
	_make_zone_trigger("MB02Trigger", Rect2(_CP1_EXIT_X, 400, 900, 800), 5)
	_make_zone_trigger("Z3Trigger", Rect2(_CP2_EXIT_X, 300, 2600, 900), 3)
	_make_zone_trigger("Z4Trigger", Rect2(10400, 300, 2600, 900), 4)

func _make_zone_trigger(node_name: String, rect: Rect2, zone: int) -> void:
	var area := Area2D.new()
	area.name = node_name
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	area.add_child(cs)
	area.position = rect.position + rect.size * 0.5
	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			if zone == 5:
				_spawn_mb02()
			else:
				_spawn_zone_enemies(zone)
	)
	add_child(area)

func _spawn_zone_enemies(zone: int) -> void:
	var target: Array[Node]
	var grunts: Array
	var flyers: Array
	var archers: Array
	var turrets: Array
	var bombers: Array
	var shields: Array
	var wisps: Array
	match zone:
		1:
			target = _zone1_enemies
			grunts = Z1_GRUNTS
			flyers = Z1_FLYERS
			archers = Z1_ARCHERS
		2:
			target = _zone2_enemies
			grunts = Z2_GRUNTS
			flyers = Z2_FLYERS
			archers = Z2_ARCHERS
			shields = Z2_SHIELDS
		3:
			target = _zone3_enemies
			grunts = Z3_GRUNTS
			flyers = Z3_FLYERS
			turrets = Z3_TURRETS
			wisps = Z3_WISPS
		4:
			target = _zone4_enemies
			grunts = Z4_GRUNTS
			flyers = Z4_FLYERS
			turrets = Z4_TURRETS
			bombers = Z4_BOMBERS
			shields = Z4_SHIELDS
			wisps = Z4_WISPS
		_:
			return
	if not target.is_empty():
		return
	_spawn_enemy_list(_grunt_scene, grunts, target)
	_spawn_enemy_list(_flyer_scene, flyers, target)
	_spawn_enemy_list(_archer_scene, archers, target)
	_spawn_enemy_list(_turret_scene, turrets, target)
	_spawn_enemy_list(_bomber_scene, bombers, target)
	_spawn_enemy_list(_shield_scene, shields, target)
	_spawn_enemy_list(_wisp_scene, wisps, target)

func _spawn_enemy_list(scene: PackedScene, positions: Array, target: Array[Node]) -> void:
	if scene == null:
		return
	for pos in positions:
		var enemy := scene.instantiate()
		enemy.global_position = pos
		add_child(enemy)
		target.append(enemy)

func _spawn_mb02() -> void:
	if _mb02_spawned:
		return
	_mb02_spawned = true
	_camera_locked = true
	_camera_target = Vector2((_MB_LEFT + _MB_RIGHT) * 0.5, 760)
	_camera_zoom_tgt = 2.0
	if _mb02_scene == null:
		return
	_mb02 = _mb02_scene.instantiate() as Node2D
	_mb02.global_position = Vector2((_MB_LEFT + _MB_RIGHT) * 0.5, 820)
	_mb02.set("arena_left", _MB_LEFT + 64.0)
	_mb02.set("arena_right", _MB_RIGHT - 64.0)
	add_child(_mb02)
	_mb02.connect("died", Callable(self, "_on_mb02_defeated"))

func _on_mb02_defeated() -> void:
	_camera_locked = false
	if _corr2 != null:
		_corr2.open_entry()

func _draw() -> void:
	for child in get_children():
		if child is StaticBody2D:
			_draw_static_terrain(child as StaticBody2D)

func _draw_static_terrain(body: StaticBody2D) -> void:
	var tex := _texture_for_node(body)
	for shape_child in body.get_children():
		if not shape_child is CollisionShape2D:
			continue
		var cs := shape_child as CollisionShape2D
		if not cs.shape is RectangleShape2D:
			continue
		var size := (cs.shape as RectangleShape2D).size
		var center := body.position + cs.position
		var rect := Rect2(center - size * 0.5, size)
		_draw_terrain_block(rect, tex)

func _texture_for_node(node: Node) -> Texture2D:
	if node.name.begins_with("Z1"):
		return _tileset_z1
	if node.name.begins_with("Z2"):
		return _tileset_z2
	if node.name.begins_with("Z3"):
		return _tileset_z3
	if node.name.begins_with("Z4_Glass"):
		return _glass_tex
	if node.name.begins_with("Z4"):
		return _tileset_z4
	return _tileset_z1

func _draw_terrain_block(rect: Rect2, tex: Texture2D) -> void:
	if tex == null:
		draw_rect(rect, Color(0.35, 0.7, 0.9, 1.0))
		return
	var cols := ceili(rect.size.x / _TS)
	var rows := ceili(rect.size.y / _TS)
	for row in rows:
		for col in cols:
			var tile := _tile_at(col, cols, row, rows)
			var dx := rect.position.x + col * _TS
			var dy := rect.position.y + row * _TS - _SRC_TS
			var dw := minf(_TS, rect.position.x + rect.size.x - dx)
			var dh := minf(_TS, rect.position.y + rect.size.y - dy)
			draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh), Rect2(tile.x * _SRC_TS, tile.y * _SRC_TS, _SRC_TS * dw / _TS, _SRC_TS * dh / _TS))

func _tile_at(col: int, cols: int, row: int, rows: int) -> Vector2i:
	var is_left := col == cols - 1
	var is_right := col == 0
	var is_top := row == rows - 1
	var is_bottom := row == 0
	if is_top:
		if is_left:
			return Vector2i(3, 3)
		if is_right:
			return Vector2i(0, 2)
		return Vector2i(1, 2)
	if is_bottom:
		if is_left:
			return Vector2i(0, 0)
		if is_right:
			return Vector2i(1, 3)
		return Vector2i(3, 0)
	if is_left:
		return Vector2i(3, 2)
	if is_right:
		return Vector2i(1, 0)
	return Vector2i(2, 1)

# ── Helpers de terreno procedural (piso baseado no chão; sem flutuantes) ──────
# Segmento de piso sólido: topo em surface_y, profundidade dr tiles. zone = "Z1".."Z4".
func _floor_seg(zone: String, x0: float, x1: float, surface_y: float, dr: int = 3) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = "%s_Floor_%d" % [zone, int(x0)]
	b.collision_layer = 1
	b.collision_mask = 0
	var w := x1 - x0
	var h := dr * float(_TS)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	cs.shape = shape
	cs.position = Vector2(x0 + w * 0.5, surface_y + h * 0.5)
	b.add_child(cs)
	add_child(b)
	return b

# Parede de vidro lisa (no_wall_grab) — face vertical de um abismo mortal (Z4).
func _glass_wall(x_center: float, top_y: float, height: float) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = "Z4_Glass_%d" % int(x_center)
	b.collision_layer = 1
	b.collision_mask = 0
	b.add_to_group("no_wall_grab")
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64.0, height)
	cs.shape = shape
	cs.position = Vector2(x_center, top_y + height * 0.5)
	b.add_child(cs)
	add_child(b)
	return b

# POÇO RECUPERÁVEL (Z1–Z3): piso à esquerda, vão, piso à direita, e um piso de
# fundo (catch) ~`depth` abaixo cobrindo o vão → cai e volta pulando (depth ≤ ~96).
func _recoverable_pit(zone: String, left_x: float, right_x: float, gap_x0: float, gap_x1: float, depth: float = 96.0) -> void:
	_floor_seg(zone, left_x, gap_x0, FLOOR_Y)
	_floor_seg(zone, gap_x1, right_x, FLOOR_Y)
	_floor_seg(zone, gap_x0, gap_x1, FLOOR_Y + depth)   # fundo do poço (catch)

# ABISMO MORTAL (Z4): piso à esquerda, vão ABERTO (sem fundo → morte), piso à
# direita, com VIDRO nas faces internas. O kill plane (abaixo) mata na queda.
func _deadly_pit(left_x: float, right_x: float, gap_x0: float, gap_x1: float) -> void:
	_floor_seg("Z4", left_x, gap_x0, FLOOR_Y)
	_floor_seg("Z4", gap_x1, right_x, FLOOR_Y)
	_glass_wall(gap_x0 + 32.0, FLOOR_Y, 320.0)   # face de vidro à esquerda do vão
	_glass_wall(gap_x1 - 32.0, FLOOR_Y, 320.0)   # face de vidro à direita do vão

# Degrau elevado saltável (≤64px) sobre o piso base — seção de chão mais alta.
func _step_up(zone: String, x0: float, x1: float, rise: float = 64.0) -> void:
	_floor_seg(zone, x0, x1, FLOOR_Y - rise)

# Z1 — gelo escorregadio. Piso base contínuo com poços recuperáveis e degraus.
func _build_zone1() -> void:
	_floor_seg("Z1", 0.0, 1400.0, FLOOR_Y)
	_step_up("Z1", 1400.0, 1900.0)
	_recoverable_pit("Z1", 1900.0, 3000.0, 2300.0, 2560.0)
	_recoverable_pit("Z1", 3000.0, 4200.0, 3450.0, 3650.0)
	_step_up("Z1", 4200.0, 4700.0)
	_floor_seg("Z1", 4700.0, 5600.0, FLOOR_Y)

# Z2 — espinhos de gelo. Piso com campos de espinhos e poços recuperáveis.
func _build_zone2() -> void:
	_floor_seg("Z2", 5600.0, 6600.0, FLOOR_Y)
	_recoverable_pit("Z2", 6600.0, 7800.0, 7050.0, 7300.0)
	_step_up("Z2", 7800.0, 8300.0)
	_floor_seg("Z2", 8300.0, 9400.0, FLOOR_Y)
	_recoverable_pit("Z2", 9400.0, 10600.0, 9850.0, 10100.0)

# Z3 — nevasca que empurra. Piso com poços recuperáveis sob vento lateral.
func _build_zone3() -> void:
	_floor_seg("Z3", 13200.0, 14400.0, FLOOR_Y)
	_recoverable_pit("Z3", 14400.0, 15600.0, 14900.0, 15150.0)
	_step_up("Z3", 15600.0, 16100.0)
	_recoverable_pit("Z3", 16100.0, 17300.0, 16550.0, 16800.0)
	_floor_seg("Z3", 17300.0, 18000.0, FLOOR_Y)

func _build_zone4() -> void:
	pass
