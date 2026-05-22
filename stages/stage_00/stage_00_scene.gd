# stages/stage_00/stage_00_scene.gd
extends Node2D

const ZAEL_SCENE := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE := preload("res://characters/melee/zara.tscn")
const _TILESET   := preload("res://stages/stage_00/Stage_00T.png")
const _TS        := 32

const ZONE1_GRUNTS := [
	Vector2(400, 520), Vector2(700, 520), Vector2(1700, 452),
	Vector2(1900, 520), Vector2(2200, 440), Vector2(2700, 520)
]
const ZONE1_FLYERS := [Vector2(1050, 380), Vector2(2450, 400)]

const ZONE2_GRUNTS := [
	Vector2(3500, 204), Vector2(3900, 204), Vector2(4650, 140),
	Vector2(4980, 200), Vector2(5900, 360)
]
const ZONE2_FLYERS := [Vector2(3700, 160), Vector2(4250, 180), Vector2(5600, 380)]

const ZONE3_GRUNTS := [
	Vector2(6100, 520), Vector2(6800, 460), Vector2(7100, 520), Vector2(7600, 520)
]
const ZONE3_FLYERS := [Vector2(6600, 400), Vector2(7300, 380)]

const BOSS_SPAWN := Vector2(9100, 400)
const CP1_ENTRY_X := 2900.0
const CP1_EXIT_X  := 3200.0
const CP2_ENTRY_X := 8000.0
const CP2_EXIT_X  := 8300.0

var _player: CharacterBase = null
var _zone1_enemies: Array[Node] = []
var _zone2_enemies: Array[Node] = []
var _zone3_enemies: Array[Node] = []
var _zone1_entered := false
var _zone2_entered := false
var _zone3_entered := false
var _boss: Node = null
var _boss_spawned := false

var _grunt_scene: PackedScene
var _flyer_scene: PackedScene
var _boss_scene: PackedScene
var _door_scene: PackedScene

# ─── Lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Load enemy / boss / door scenes
	_grunt_scene = load("res://characters/enemies/enemy_base.tscn")
	_flyer_scene = load("res://characters/enemies/enemy_flyer.tscn")
	_boss_scene  = load("res://characters/bosses/intro_boss.tscn")
	_door_scene  = load("res://stages/checkpoint_door.tscn")

	# Boss_LWall collision starts disabled — only re-enabled once boss door opens
	var lwall := $Boss_LWall
	lwall.get_node("CollisionShape2D").disabled = true

	# Guard against running without GameManager/StageManager (e.g. test opens scene directly)
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")

	StageManager.spawn_position = $PlayerSpawn.global_position
	_spawn_player()
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)

	# Disconnect GoalZone — stage completion is handled via boss defeat
	# (BossBase calls GameManager.complete_stage(stage_id) automatically)

	AudioManager.play_bgm(AudioLibrary.bgm_intro)

	_setup_doors()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	_spawn_zone_enemies(2)
	_spawn_zone_enemies(3)

	# Default respawn at stage start (index 0 means spawn_position)
	# Checkpoint 1 will be saved when player passes through CP1 entry door

	queue_redraw()

func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		$Camera2D.global_position = _player.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		$PauseMenu.toggle_pause()

# ─── Player Spawn ────────────────────────────────────────────────────────────

func _spawn_player() -> void:
	var scene := ZARA_SCENE if GameManager.active_character == "zara" else ZAEL_SCENE
	_player = scene.instantiate() as CharacterBase
	_player.add_to_group("player")
	_player.global_position = StageManager.get_respawn_position()
	# Fall back to PlayerSpawn if no checkpoint has been set yet
	if _player.global_position == Vector2.ZERO:
		_player.global_position = $PlayerSpawn.global_position
	add_child(_player)

# ─── Checkpoint Doors ────────────────────────────────────────────────────────

func _setup_doors() -> void:
	# CP1 entry — at CP1_ENTRY_X (left side of corridor 1)
	var cp1_entry: Node2D = _door_scene.instantiate()
	cp1_entry.position = Vector2(CP1_ENTRY_X, 496)
	add_child(cp1_entry)
	cp1_entry.connect("door_opened", _on_cp1_entry_opened.bind(cp1_entry))

	# CP1 exit — at CP1_EXIT_X (right side of corridor 1)
	var cp1_exit: Node2D = _door_scene.instantiate()
	cp1_exit.position = Vector2(CP1_EXIT_X, 496)
	add_child(cp1_exit)

	# CP2 entry — at CP2_ENTRY_X (left side of corridor 2)
	var cp2_entry: Node2D = _door_scene.instantiate()
	cp2_entry.position = Vector2(CP2_ENTRY_X, 496)
	add_child(cp2_entry)
	cp2_entry.connect("door_opened", _on_cp2_entry_opened.bind(cp2_entry))

	# CP2 exit / boss door — at CP2_EXIT_X (right side of corridor 2)
	var boss_door: Node2D = _door_scene.instantiate()
	boss_door.position = Vector2(CP2_EXIT_X, 496)
	add_child(boss_door)
	boss_door.connect("door_opened", _on_boss_door_opened.bind(boss_door))

func _on_cp1_entry_opened(door: Node2D) -> void:
	# Save checkpoint so player respawns at CP1 exit if they die
	StageManager.save_checkpoint(Vector2(CP1_EXIT_X + 64, 496), 1)
	# Heal player fully
	if is_instance_valid(_player):
		_player.heal(_player.max_hp)
	# After player passes, close the door behind them
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(door) and is_instance_valid(_player):
		if _player.global_position.x > door.position.x:
			door.call("close")

func _on_cp2_entry_opened(door: Node2D) -> void:
	# Save checkpoint so player respawns at CP2 exit if they die (before boss)
	StageManager.save_checkpoint(Vector2(CP2_EXIT_X + 64, 496), 2)
	# Heal player fully
	if is_instance_valid(_player):
		_player.heal(_player.max_hp)
	# After player passes, close the door behind them
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(door) and is_instance_valid(_player):
		if _player.global_position.x > door.position.x:
			door.call("close")

func _on_boss_door_opened(_door: Node2D) -> void:
	_spawn_boss()
	# After a short delay, seal the boss room by re-enabling Boss_LWall collision
	await get_tree().create_timer(1.0).timeout
	var lwall := $Boss_LWall
	if is_instance_valid(lwall):
		lwall.get_node("CollisionShape2D").disabled = false

# ─── Boss ─────────────────────────────────────────────────────────────────────

func _spawn_boss() -> void:
	if _boss_spawned:
		return
	_boss_spawned = true
	_boss = _boss_scene.instantiate()
	_boss.global_position = BOSS_SPAWN
	_boss.player = _player
	# Arena bounds for the boss room (x: 8301–9301, floor: ~560)
	_boss.arena_left  = 8340.0
	_boss.arena_right = 9260.0
	_boss.arena_floor = 540.0
	add_child(_boss)
	_boss.boss_defeated.connect(_on_boss_defeated)

func _on_boss_defeated(_ability_id: String) -> void:
	# BossBase already called GameManager.complete_stage(0) in _run_death_sequence
	GameManager.save_game()

# ─── Zone Triggers ───────────────────────────────────────────────────────────

func _setup_zone_triggers() -> void:
	# Zone 1: x 0–2900
	var z1 := _make_zone_trigger(1450, 400, 2900, 600)
	z1.body_entered.connect(_on_zone1_entered)
	z1.body_exited.connect(_on_zone1_exited)
	add_child(z1)

	# Zone 2: x 3200–5700
	var z2 := _make_zone_trigger(4450, 300, 2500, 600)
	z2.body_entered.connect(_on_zone2_entered)
	z2.body_exited.connect(_on_zone2_exited)
	add_child(z2)

	# Zone 3: x 5700–8000
	var z3 := _make_zone_trigger(6850, 400, 2300, 600)
	z3.body_entered.connect(_on_zone3_entered)
	z3.body_exited.connect(_on_zone3_exited)
	add_child(z3)

func _make_zone_trigger(cx: float, cy: float, w: float, h: float) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2  # player layer
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	shape.shape = rect
	area.add_child(shape)
	area.position = Vector2(cx, cy)
	return area

func _on_zone1_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _zone1_entered:
		_respawn_zone(1)
	_zone1_entered = true

func _on_zone1_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_zone1_entered = false

func _on_zone2_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _zone2_entered:
		_respawn_zone(2)
	_zone2_entered = true

func _on_zone2_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_zone2_entered = false

func _on_zone3_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _zone3_entered:
		_respawn_zone(3)
	_zone3_entered = true

func _on_zone3_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_zone3_entered = false

# ─── Enemy Spawning ──────────────────────────────────────────────────────────

func _respawn_zone(zone: int) -> void:
	_clear_zone_enemies(zone)
	_spawn_zone_enemies(zone)

func _clear_zone_enemies(zone: int) -> void:
	var arr := _get_zone_array(zone)
	for enemy in arr:
		if is_instance_valid(enemy):
			enemy.queue_free()
	arr.clear()

func _spawn_zone_enemies(zone: int) -> void:
	var grunt_positions: Array
	var flyer_positions: Array
	match zone:
		1:
			grunt_positions = ZONE1_GRUNTS
			flyer_positions = ZONE1_FLYERS
		2:
			grunt_positions = ZONE2_GRUNTS
			flyer_positions = ZONE2_FLYERS
		3:
			grunt_positions = ZONE3_GRUNTS
			flyer_positions = ZONE3_FLYERS
		_:
			return

	var arr := _get_zone_array(zone)
	for pos in grunt_positions:
		if _grunt_scene != null:
			var e: Node2D = _grunt_scene.instantiate()
			e.global_position = pos
			add_child(e)
			arr.append(e)

	for pos in flyer_positions:
		if _flyer_scene != null:
			var e: Node2D = _flyer_scene.instantiate()
			e.global_position = pos
			add_child(e)
			arr.append(e)

func _get_zone_array(zone: int) -> Array[Node]:
	match zone:
		1: return _zone1_enemies
		2: return _zone2_enemies
		3: return _zone3_enemies
	return _zone1_enemies  # fallback (never reached)

# ─── Drawing ─────────────────────────────────────────────────────────────────

func _draw() -> void:
	_draw_background()
	_draw_platforms()

func _draw_background() -> void:
	# Sky — dark night with orange/red tones (destroyed city at dusk)
	draw_rect(Rect2(0, -600, 10000, 1300), Color(0.08, 0.05, 0.06))

	# Distant city silhouette — large ruined buildings
	var buildings := [
		Rect2(0,    240, 220, 320),
		Rect2(260,  160, 160, 400),
		Rect2(500,  200, 120, 360),
		Rect2(700,  100, 200, 460),
		Rect2(980,  180, 180, 380),
		Rect2(1240, 220, 140, 340),
		Rect2(1450, 140, 260, 420),
		Rect2(1800, 200, 180, 360),
		Rect2(2100, 160, 200, 400),
		Rect2(2400, 220, 160, 340),
		Rect2(2650, 100, 220, 460),
		Rect2(3000, 180, 180, 380),
		Rect2(3300, 150, 200, 410),
		Rect2(3600, 200, 160, 360),
		Rect2(3850, 120, 240, 440),
		Rect2(4200, 180, 180, 380),
		Rect2(4500, 200, 200, 360),
		Rect2(4800, 140, 220, 420),
		Rect2(5100, 200, 160, 360),
		Rect2(5400, 160, 200, 400),
		Rect2(5700, 200, 180, 360),
		Rect2(6000, 140, 240, 420),
		Rect2(6300, 180, 180, 380),
		Rect2(6600, 200, 200, 360),
		Rect2(6900, 160, 220, 400),
		Rect2(7200, 200, 180, 360),
		Rect2(7500, 140, 260, 420),
		Rect2(7800, 200, 200, 360),
	]
	var building_color := Color(0.12, 0.08, 0.09)
	for b: Rect2 in buildings:
		draw_rect(b, building_color)
		# Orange windows
		var win_cols: int = max(1, int(b.size.x / 40))
		var win_rows: int = max(1, int(b.size.y / 48))
		for wr: int in win_rows:
			for wc: int in win_cols:
				if (wr + wc) % 3 == 0:
					continue  # skip some for ruined look
				var wx: float = b.position.x + 8.0 + wc * 40.0
				var wy: float = b.position.y + 8.0 + wr * 48.0
				draw_rect(Rect2(wx, wy, 14, 18), Color(0.9, 0.4, 0.05, 0.7))

	# Boss room background — tech panels in dark blue tones
	var boss_room := Rect2(8301, -600, 1000, 1300)
	draw_rect(boss_room, Color(0.05, 0.05, 0.12))
	for i in 8:
		var panel_y := -600 + i * 140
		draw_rect(Rect2(8320, panel_y, 960, 128), Color(0.07, 0.07, 0.18))
		# Alternating accent stripe
		var stripe_color := Color(0.1, 0.1, 0.25) if i % 2 == 0 else Color(0.08, 0.08, 0.20)
		draw_rect(Rect2(8320, panel_y + 124, 960, 4), stripe_color)

func _draw_platforms() -> void:
	for child in get_children():
		if not child is StaticBody2D:
			continue
		for shape_child in child.get_children():
			if not shape_child is CollisionShape2D:
				continue
			if not shape_child.shape is RectangleShape2D:
				continue
			var size: Vector2 = (shape_child.shape as RectangleShape2D).size
			var center: Vector2 = (child as Node2D).position + (shape_child as Node2D).position
			_draw_platform_tiles(Rect2(center - size * 0.5, size))

func _draw_platform_tiles(rect: Rect2) -> void:
	var ts := _TS
	var cols := ceili(rect.size.x / ts)
	var rows := ceili(rect.size.y / ts)
	for row in rows:
		for col in cols:
			var tile := _tile_at(col, cols, row, rows)
			var src := Rect2(tile.x * ts, tile.y * ts, ts, ts)
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var dh := minf(ts, rect.position.y + rect.size.y - dy)
			src.size.x = src.size.x * dw / ts
			src.size.y = src.size.y * dh / ts
			draw_texture_rect_region(_TILESET, Rect2(dx, dy, dw, dh), src)

func _tile_at(col: int, cols: int, row: int, rows: int) -> Vector2i:
	var is_left   := col == 0
	var is_right  := col == cols - 1
	var is_top    := row == 0
	var is_bottom := row == rows - 1

	if rows == 1:
		return Vector2i(3, 0)  # flat platform

	if is_top:
		if is_left:  return Vector2i(3, 3)
		if is_right: return Vector2i(0, 2)
		return Vector2i(3, 0)

	if is_bottom:
		if is_left:  return Vector2i(0, 0)
		if is_right: return Vector2i(1, 3)
		return Vector2i(1, 2)

	if is_left:  return Vector2i(3, 2)
	if is_right: return Vector2i(1, 0)
	return Vector2i(2, 1)
