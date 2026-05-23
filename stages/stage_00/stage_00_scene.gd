# stages/stage_00/stage_00_scene.gd
extends Node2D

const ZAEL_SCENE   := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE   := preload("res://characters/melee/zara.tscn")
const _TILESET     := preload("res://stages/stage_00/Stage_00T.png")
const _TS          := 64  # tamanho de destino no mundo
const _SRC_TS      := 32  # tamanho real do tile no PNG
const _GRUNT_SCENE := preload("res://characters/enemies/enemy_base.tscn")
const _FLYER_SCENE := preload("res://characters/enemies/enemy_flyer.tscn")
const _BOSS_SCENE  := preload("res://characters/bosses/intro_boss.tscn")
const _DOOR_SCENE  := preload("res://stages/checkpoint_door.tscn")

const ZONE1_GRUNTS := [
	Vector2(800, 1040), Vector2(1400, 1040), Vector2(3400, 904),
	Vector2(3800, 1040), Vector2(4400, 880), Vector2(5400, 1040)
]
const ZONE1_FLYERS := [Vector2(2100, 760), Vector2(4900, 800)]

const ZONE2_GRUNTS := [
	Vector2(7000, 408), Vector2(7800, 408), Vector2(9300, 280),
	Vector2(9960, 400), Vector2(11800, 720)
]
const ZONE2_FLYERS := [Vector2(7400, 320), Vector2(8500, 360), Vector2(11200, 760)]

const ZONE3_GRUNTS := [
	Vector2(12200, 1040), Vector2(13600, 920), Vector2(14200, 1040), Vector2(15200, 1040)
]
const ZONE3_FLYERS := [Vector2(13200, 800), Vector2(14600, 760)]

const BOSS_SPAWN := Vector2(18200, 800)
const CP1_ENTRY_X := 5800.0
const CP1_EXIT_X  := 6400.0
const CP2_ENTRY_X := 16000.0
const CP2_EXIT_X  := 16600.0

var _player: CharacterBase = null
var _zone1_enemies: Array[Node] = []
var _zone2_enemies: Array[Node] = []
var _zone3_enemies: Array[Node] = []
var _zone1_entered := false
var _zone2_entered := false
var _zone3_entered := false
var _boss: Node = null
var _boss_spawned := false


# ─── Lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

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

	$Camera2D.zoom = Vector2(2.2, 2.2)
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
	var cp1_entry: Node2D = _DOOR_SCENE.instantiate()
	cp1_entry.position = Vector2(CP1_ENTRY_X, 992)
	add_child(cp1_entry)
	cp1_entry.connect("door_opened", _on_cp1_entry_opened.bind(cp1_entry))

	# CP1 exit — at CP1_EXIT_X (right side of corridor 1)
	var cp1_exit: Node2D = _DOOR_SCENE.instantiate()
	cp1_exit.position = Vector2(CP1_EXIT_X, 992)
	add_child(cp1_exit)

	# CP2 entry — at CP2_ENTRY_X (left side of corridor 2)
	var cp2_entry: Node2D = _DOOR_SCENE.instantiate()
	cp2_entry.position = Vector2(CP2_ENTRY_X, 992)
	add_child(cp2_entry)
	cp2_entry.connect("door_opened", _on_cp2_entry_opened.bind(cp2_entry))

	# CP2 exit / boss door — at CP2_EXIT_X (right side of corridor 2)
	var boss_door: Node2D = _DOOR_SCENE.instantiate()
	boss_door.position = Vector2(CP2_EXIT_X, 992)
	add_child(boss_door)
	boss_door.connect("door_opened", _on_boss_door_opened.bind(boss_door))

func _on_cp1_entry_opened(door: Node2D) -> void:
	# Save checkpoint so player respawns at CP1 exit if they die
	StageManager.save_checkpoint(Vector2(CP1_EXIT_X + 128, 992), 1)
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
	StageManager.save_checkpoint(Vector2(CP2_EXIT_X + 128, 992), 2)
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
	_boss = _BOSS_SCENE.instantiate()
	_boss.global_position = BOSS_SPAWN
	_boss.player = _player
	# Arena bounds for the boss room (x: 8301–9301, floor: ~560)
	_boss.arena_left  = 16680.0
	_boss.arena_right = 18520.0
	_boss.arena_floor = 1080.0
	add_child(_boss)
	_boss.boss_defeated.connect(_on_boss_defeated)

func _on_boss_defeated(_ability_id: String) -> void:
	# BossBase already called GameManager.complete_stage(0) in _run_death_sequence
	GameManager.save_game()

# ─── Zone Triggers ───────────────────────────────────────────────────────────

func _setup_zone_triggers() -> void:
	# Zone 1: x 0–5800
	var z1 := _make_zone_trigger(2900, 800, 5800, 1200)
	z1.body_entered.connect(_on_zone1_entered)
	z1.body_exited.connect(_on_zone1_exited)
	add_child(z1)

	# Zone 2: x 6400–11400
	var z2 := _make_zone_trigger(8900, 600, 5000, 1200)
	z2.body_entered.connect(_on_zone2_entered)
	z2.body_exited.connect(_on_zone2_exited)
	add_child(z2)

	# Zone 3: x 11400–16000
	var z3 := _make_zone_trigger(13700, 800, 4600, 1200)
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
		if _GRUNT_SCENE != null:
			var e: Node2D = _GRUNT_SCENE.instantiate()
			e.global_position = pos
			add_child(e)
			arr.append(e)

	for pos in flyer_positions:
		if _FLYER_SCENE != null:
			var e: Node2D = _FLYER_SCENE.instantiate()
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
	draw_rect(Rect2(0, -1200, 20000, 2600), Color(0.08, 0.05, 0.06))

	# Distant city silhouette — large ruined buildings
	var buildings := [
		Rect2(0,     480, 440, 640),
		Rect2(520,   320, 320, 800),
		Rect2(1000,  400, 240, 720),
		Rect2(1400,  200, 400, 920),
		Rect2(1960,  360, 360, 760),
		Rect2(2480,  440, 280, 680),
		Rect2(2900,  280, 520, 840),
		Rect2(3600,  400, 360, 720),
		Rect2(4200,  320, 400, 800),
		Rect2(4800,  440, 320, 680),
		Rect2(5300,  200, 440, 920),
		Rect2(6000,  360, 360, 760),
		Rect2(6600,  300, 400, 820),
		Rect2(7200,  400, 320, 720),
		Rect2(7700,  240, 480, 880),
		Rect2(8400,  360, 360, 760),
		Rect2(9000,  400, 400, 720),
		Rect2(9600,  280, 440, 840),
		Rect2(10200, 400, 320, 720),
		Rect2(10800, 320, 400, 800),
		Rect2(11400, 400, 360, 720),
		Rect2(12000, 280, 480, 840),
		Rect2(12600, 360, 360, 760),
		Rect2(13200, 400, 400, 720),
		Rect2(13800, 320, 440, 800),
		Rect2(14400, 400, 360, 720),
		Rect2(15000, 280, 520, 840),
		Rect2(15600, 400, 400, 720),
	]
	var building_color := Color(0.12, 0.08, 0.09)
	for b: Rect2 in buildings:
		draw_rect(b, building_color)
		# Orange windows
		var win_cols: int = max(1, int(b.size.x / 80))
		var win_rows: int = max(1, int(b.size.y / 96))
		for wr: int in win_rows:
			for wc: int in win_cols:
				if (wr + wc) % 3 == 0:
					continue  # skip some for ruined look
				var wx: float = b.position.x + 16.0 + wc * 80.0
				var wy: float = b.position.y + 16.0 + wr * 96.0
				draw_rect(Rect2(wx, wy, 28, 36), Color(0.9, 0.4, 0.05, 0.7))

	# Boss room background — tech panels in dark blue tones
	var boss_room := Rect2(16602, -1200, 2000, 2600)
	draw_rect(boss_room, Color(0.05, 0.05, 0.12))
	for i in 8:
		var panel_y := -1200 + i * 280
		draw_rect(Rect2(16640, panel_y, 1920, 256), Color(0.07, 0.07, 0.18))
		# Alternating accent stripe
		var stripe_color := Color(0.1, 0.1, 0.25) if i % 2 == 0 else Color(0.08, 0.08, 0.20)
		draw_rect(Rect2(16640, panel_y + 248, 1920, 8), stripe_color)

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
	var ts     := _TS
	var src_ts := _SRC_TS
	var cols := ceili(rect.size.x / ts)
	var rows := ceili(rect.size.y / ts)
	for row in rows:
		for col in cols:
			var tile := _tile_at(col, cols, row, rows)
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var dh := minf(ts, rect.position.y + rect.size.y - dy)
			var src := Rect2(tile.x * src_ts, tile.y * src_ts, src_ts * dw / ts, src_ts * dh / ts)
			draw_texture_rect_region(_TILESET, Rect2(dx, dy, dw, dh), src)

func _tile_at(col: int, cols: int, row: int, rows: int) -> Vector2i:
	var is_left   := col == cols - 1
	var is_right  := col == 0
	var is_top    := row == rows - 1
	var is_bottom := row == 0

	# Coluna única (parede/pilar): tampa com TOP/BOT, miolo com FILL
	if cols == 1:
		if is_top:    return Vector2i(3, 0)   # TOP
		if is_bottom: return Vector2i(1, 2)   # BOTTOM
		return Vector2i(2, 1)                 # FILL

	# Linha única (plataforma fina): cantos + topo reto
	if rows == 1:
		if is_left:  return Vector2i(3, 3)    # TOP+LEFT
		if is_right: return Vector2i(0, 2)    # TOP+RIGHT
		return Vector2i(3, 0)                 # TOP

	if is_top:
		if is_left:  return Vector2i(3, 3)    # TOP+LEFT
		if is_right: return Vector2i(0, 2)    # TOP+RIGHT
		return Vector2i(3, 0)                 # TOP

	if is_bottom:
		if is_left:  return Vector2i(0, 0)    # BOT+LEFT
		if is_right: return Vector2i(1, 3)    # BOT+RIGHT
		return Vector2i(1, 2)                 # BOTTOM

	if is_left:  return Vector2i(3, 2)        # LEFT
	if is_right: return Vector2i(1, 0)        # RIGHT
	return Vector2i(2, 1)                     # FILL
