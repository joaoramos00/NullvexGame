# stages/stage_00/stage_00_scene.gd
extends Node2D

const ZAEL_SCENE   := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE   := preload("res://characters/melee/zara.tscn")
const _TILESET     := preload("res://stages/stage_00/Stage_00T.png")
const _TS          := 64  # tamanho de destino no mundo
const _SRC_TS      := 32  # tamanho real do tile no PNG
const _DOOR_TEX    := preload("res://stages/door_pixellab.png")
const _GRUNT_SCENE := preload("res://characters/enemies/enemy_base.tscn")
const _FLYER_SCENE := preload("res://characters/enemies/enemy_flyer.tscn")
const _BOSS_SCENE  := preload("res://characters/bosses/intro_boss.tscn")
const _DOOR_SCENE  := preload("res://stages/checkpoint_door.tscn")
const _MINIBOSS_SCENE := preload("res://characters/enemies/enemy_miniboss.tscn")

const ZONE1_GRUNTS := [
	Vector2(800, 1024), Vector2(1400, 1024), Vector2(3400, 888),
	Vector2(3800, 1024), Vector2(4400, 864)
]
const ZONE1_FLYERS := [Vector2(2100, 906), Vector2(4900, 906)]

const ZONE2_GRUNTS := [
	Vector2(7000, 392), Vector2(7800, 392), Vector2(9300, 264),
	Vector2(9960, 384), Vector2(11800, 704)
]
const ZONE2_FLYERS := [Vector2(7400, 274), Vector2(8500, 274), Vector2(11200, 586)]

const ZONE3_GRUNTS := [
	Vector2(12200, 1024), Vector2(13600, 904), Vector2(14200, 1024), Vector2(15200, 1024)
]
const ZONE3_FLYERS := [Vector2(13200, 906), Vector2(14600, 906)]

const BOSS_SPAWN := Vector2(18200, 784)
const CP1_ENTRY_X := 5802.0   # centro visual Corr1_Wall_L (tile X 5770–5834)
const CP1_EXIT_X  := 6398.0   # centro visual Corr1_Wall_R (tile X 6366–6430)
const CP2_ENTRY_X := 16002.0  # centro visual Corr2_Wall_L (tile X 15970–16034)
const CP2_EXIT_X  := 16598.0  # centro visual Corr2_Wall_R (tile X 16566–16630)

const _CORR_CEIL_Y  := 960.0    # face interna Corr_Ceil
const _CORR_FLOOR_Y := 1088.0   # face interna Corr_Floor
const _DOOR_H       := 200.0    # altura da porta
const _DOOR_V       := _DOOR_H / 3.0  # largura da porta (1/3 da altura ≈ 67px)
const _DOOR_CY      := 1024.0   # centro da porta: 1 tile abaixo do original (960→1024)
const _DOOR_OPEN_Y  := (_CORR_CEIL_Y - _DOOR_CY) - _DOOR_H - 2.0

var _player: CharacterBase = null
var _zone1_enemies: Array[Node] = []
var _zone2_enemies: Array[Node] = []
var _zone3_enemies: Array[Node] = []
var _zone1_entered := false
var _zone2_entered := false
var _zone3_entered := false
var _boss: Node = null
var _boss_spawned := false
var _miniboss: Node = null
var _miniboss_spawned := false
var _doors: Array[CheckpointDoor] = []


# ─── Lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Boss_LWall collision starts disabled — only re-enabled once boss door opens
	var lwall := $Boss_LWall
	lwall.get_node("CollisionShape2D").disabled = true

	# Paredes de corredor são visuais — as portas de checkpoint fazem a barreira
	for _cwall_name in ["Corr1_Wall_L", "Corr1_Wall_R", "Corr2_Wall_L", "Corr2_Wall_R"]:
		var _cwall := get_node_or_null(_cwall_name)
		if _cwall:
			(_cwall as Node).get_node("CollisionShape2D").set("disabled", true)

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
	_setup_miniboss_trigger()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	_spawn_zone_enemies(2)
	_spawn_zone_enemies(3)

	# Default respawn at stage start (index 0 means spawn_position)
	# Checkpoint 1 will be saved when player passes through CP1 entry door

	_add_debug_platform()
	queue_redraw()

func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		$Camera2D.global_position = _player.global_position
	queue_redraw()

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

func _make_door(x: float) -> CheckpointDoor:
	var door := _DOOR_SCENE.instantiate() as CheckpointDoor
	door.position    = Vector2(x, _DOOR_CY)
	door.open_offset = _DOOR_OPEN_Y
	# Redimensiona collision body antes de _ready()
	var col := door.get_node("CollisionShape2D") as CollisionShape2D
	var body_shape := (col.shape as RectangleShape2D).duplicate() as RectangleShape2D
	body_shape.size = Vector2(_DOOR_V, _DOOR_H)
	col.shape = body_shape
	# Redimensiona trigger
	var trig := door.get_node("TriggerArea/CollisionShape2D") as CollisionShape2D
	var trig_shape := (trig.shape as RectangleShape2D).duplicate() as RectangleShape2D
	trig_shape.size = Vector2(_DOOR_V + 32.0, _DOOR_H + 32.0)
	trig.shape = trig_shape
	add_child(door)
	# Transparente — desenhada em _draw_door_underlays() antes dos tiles
	var sprite := door.get_node("ColorRect") as ColorRect
	sprite.color = Color(0, 0, 0, 0)
	return door

func _setup_doors() -> void:
	var cp1_entry := _make_door(CP1_ENTRY_X)
	cp1_entry.connect("door_opening", _on_door_opening)
	cp1_entry.connect("door_opened",  _on_cp1_entry_opened.bind(cp1_entry))
	_doors.append(cp1_entry)

	var cp1_exit := _make_door(CP1_EXIT_X)
	cp1_exit.connect("door_opening", _on_door_opening)
	cp1_exit.connect("door_opened",  _on_cp1_exit_opened.bind(cp1_exit))
	_doors.append(cp1_exit)

	var cp2_entry := _make_door(CP2_ENTRY_X)
	cp2_entry.connect("door_opening", _on_door_opening)
	cp2_entry.connect("door_opened",  _on_cp2_entry_opened.bind(cp2_entry))
	_doors.append(cp2_entry)

	var boss_door := _make_door(CP2_EXIT_X)
	boss_door.connect("door_opened",  _on_boss_door_opened.bind(boss_door))
	_doors.append(boss_door)

func _on_door_opening() -> void:
	if is_instance_valid(_player):
		_player.door_locked = true

func _on_cp1_entry_opened(door: Node2D) -> void:
	StageManager.save_checkpoint(Vector2(CP1_EXIT_X + 128, 1024), 1)
	if is_instance_valid(_player):
		_player.heal(_player.max_hp)
		_player.door_locked = false
		_player.door_walk_speed = CharacterBase.SPEED
	var target_x := door.position.x + 96.0
	while is_instance_valid(_player) and _player.global_position.x < target_x:
		await get_tree().process_frame
	if is_instance_valid(_player):
		_player.door_walk_speed = 0.0
	if is_instance_valid(door):
		door.call("close")
		var trig := door.get_node_or_null("TriggerArea") as Area2D
		if trig:
			trig.monitoring = false

func _on_cp1_exit_opened(door: Node2D) -> void:
	if is_instance_valid(_player):
		_player.door_locked = false
		_player.door_walk_speed = CharacterBase.SPEED
	var target_x := door.position.x + 96.0
	while is_instance_valid(_player) and _player.global_position.x < target_x:
		await get_tree().process_frame
	if is_instance_valid(_player):
		_player.door_walk_speed = 0.0
	if is_instance_valid(door):
		door.call("close")
		var trig := door.get_node_or_null("TriggerArea") as Area2D
		if trig:
			trig.monitoring = false

func _on_cp2_entry_opened(door: Node2D) -> void:
	StageManager.save_checkpoint(Vector2(CP2_EXIT_X + 128, 992), 2)
	if is_instance_valid(_player):
		_player.heal(_player.max_hp)
		_player.door_locked = false
		_player.door_walk_speed = CharacterBase.SPEED
	var target_x := door.position.x + 96.0
	while is_instance_valid(_player) and _player.global_position.x < target_x:
		await get_tree().process_frame
	if is_instance_valid(_player):
		_player.door_walk_speed = 0.0
	if is_instance_valid(door):
		door.call("close")

func _on_boss_door_opened(_door: Node2D) -> void:
	if is_instance_valid(_player):
		_player.door_locked = false
	_spawn_boss()
	# After a short delay, seal the boss room by re-enabling Boss_LWall collision
	await get_tree().create_timer(1.0).timeout
	var lwall := $Boss_LWall
	if is_instance_valid(lwall):
		lwall.get_node("CollisionShape2D").set_deferred("disabled", false)

# ─── Boss ─────────────────────────────────────────────────────────────────────

func _spawn_boss() -> void:
	if _boss_spawned:
		return
	_boss_spawned = true
	_boss = _BOSS_SCENE.instantiate()
	_boss.global_position = BOSS_SPAWN
	_boss.player = _player
	# Arena bounds for the boss room (x: 16680–18520, floor: 1080)
	_boss.arena_left  = 16680.0
	_boss.arena_right = 18520.0
	_boss.arena_floor = 1080.0
	add_child(_boss)
	_boss.boss_defeated.connect(_on_boss_defeated)

func _on_boss_defeated(_ability_id: String) -> void:
	# BossBase already called GameManager.complete_stage(0) in _run_death_sequence
	GameManager.save_game()

# ─── MiniBoss Room ────────────────────────────────────────────────────────────

func _setup_miniboss_trigger() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(80.0, 256.0)
	shape.shape = rect
	area.add_child(shape)
	area.position = Vector2(6470.0, 960.0)
	area.body_entered.connect(_on_miniboss_room_entered)
	add_child(area)

func _on_miniboss_room_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	# Sela a entrada com a parede esquerda da sala (tiles voltados para dentro)
	var lwall := get_node_or_null("MiniBoss_LWall")
	if lwall:
		lwall.get_node("CollisionShape2D").set_deferred("disabled", false)
	if _miniboss_spawned:
		return
	_miniboss_spawned = true
	_miniboss = _MINIBOSS_SCENE.instantiate()
	_miniboss.global_position = Vector2(6900.0, 1024.0)
	_miniboss.died.connect(_on_miniboss_defeated)
	call_deferred("add_child", _miniboss)

func _on_miniboss_defeated() -> void:
	var rwall := get_node_or_null("MiniBoss_RWall")
	if rwall:
		rwall.get_node("CollisionShape2D").set_deferred("disabled", true)

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

# ─── Debug ───────────────────────────────────────────────────────────────────

func _add_debug_platform() -> void:
	var plat := StaticBody2D.new()
	plat.name = "Debug_Plat"
	plat.collision_layer = 1
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(256, 192)
	cs.shape = shape
	plat.add_child(cs)
	plat.position = Vector2(550, 1096)  # top face y=1000, 3 linhas de tile
	add_child(plat)

# ─── Drawing ─────────────────────────────────────────────────────────────────

func _draw() -> void:
	_draw_background()
	_draw_platforms()
	_draw_door_underlays()

func _draw_door_underlays() -> void:
	for door in _doors:
		if not is_instance_valid(door):
			continue
		var anim_y: float = door.anim_offset
		var cx: float = door.position.x
		var cy: float = door.position.y + anim_y
		var dst := Rect2(cx - _DOOR_V * 0.5, cy - _DOOR_H * 0.5, _DOOR_V, _DOOR_H)
		draw_texture_rect(_DOOR_TEX, dst, false)

func _draw_background() -> void:
	# DEBUG: fundo branco para visualizar tiles
	draw_rect(Rect2(-500, -1200, 22000, 4000), Color.WHITE)
	return
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
		if child is CheckpointDoor:
			continue
		for shape_child in child.get_children():
			if not shape_child is CollisionShape2D:
				continue
			if not shape_child.shape is RectangleShape2D:
				continue
			var cs := shape_child as CollisionShape2D
			if cs.disabled:
				continue
			var size: Vector2 = (cs.shape as RectangleShape2D).size
			var center: Vector2 = (child as Node2D).position + (cs as Node2D).position
			var rect := Rect2(center - size * 0.5, size)
			var n: String = child.name
			if n.begins_with("Corr") or n.begins_with("Boss_") or n.begins_with("MiniBoss_"):
				# Esconde Corr1 visualmente após selar, mas mantém o Floor (evita borda abrupta)
				if _miniboss_spawned and n.begins_with("Corr1") and not n.ends_with("_Floor"):
					continue
				_draw_room_tiles(rect, n)
			else:
				_draw_platform_tiles(rect)

func _draw_platform_tiles(rect: Rect2) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	var cols := ceili(rect.size.x / ts)
	var rows := ceili(rect.size.y / ts)
	for row in rows:
		for col in cols:
			var tile := _tile_at(col, cols, row, rows)
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts - src_ts  # alinha face sólida com física
			var dh := minf(ts, rect.position.y + rect.size.y - dy)
			# Todos os tiles de borda lateral têm conteúdo sólido em apenas metade da
			# largura. Shift de ±src_ts alinha essa metade com a borda física e um
			# half-tile de preenchimento cobre o gap criado (16 src px → ts/2 = 2× escala).
			if cols > 1:
				var fill := _gap_fill_tile(row, rows)
				if col == 0:
					dx -= src_ts
					draw_texture_rect_region(_TILESET,
						Rect2(rect.position.x + ts / 2.0, dy, ts / 2.0, dh),
						Rect2(fill.x * src_ts, fill.y * src_ts, src_ts / 2, src_ts))
				elif col == cols - 1:
					dx += src_ts
					draw_texture_rect_region(_TILESET,
						Rect2(rect.position.x + (cols - 1) * ts, dy, ts / 2.0, dh),
						Rect2(fill.x * src_ts + src_ts / 2, fill.y * src_ts, src_ts / 2, src_ts))
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var src := Rect2(tile.x * src_ts, tile.y * src_ts, src_ts * dw / ts, src_ts * dh / ts)
			draw_texture_rect_region(_TILESET, Rect2(dx, dy, dw, dh), src)

func _gap_fill_tile(row: int, rows: int) -> Vector2i:
	if row == 0:        return Vector2i(3, 0)  # TOP — linha visual superior
	if row == rows - 1: return Vector2i(1, 2)  # BOTTOM — linha visual inferior
	return Vector2i(2, 1)                       # FILL — interior

func _draw_room_tiles(rect: Rect2, piece_name: String) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	# Shifts base por peça (face de contato → expõe metade transparente ao jogador)
	var base_xs := 0
	var base_ys := 0
	if   piece_name.ends_with("_Floor"):                                      base_ys = -src_ts
	elif piece_name.ends_with("_Ceil"):                                       base_ys =  src_ts
	elif piece_name.ends_with("_Wall_L") or piece_name.ends_with("LWall"):   base_xs =  src_ts
	elif piece_name.ends_with("_Wall_R") or piece_name.ends_with("RWall"):   base_xs = -src_ts
	var cols := ceili(rect.size.x / ts)
	var rows := ceili(rect.size.y / ts)
	for row in rows:
		for col in cols:
			var is_left   := col == cols - 1
			var is_right  := col == 0
			var is_top    := row == rows - 1
			var is_bottom := row == 0
			var tile: Vector2i
			if piece_name.ends_with("_Ceil"):
				if is_left:        tile = Vector2i(2, 2)   # Inner-BL
				elif is_right:     tile = Vector2i(3, 1)   # Inner-BR
				else:              tile = Vector2i(1, 2)   # BOTTOM — teto
			elif piece_name.ends_with("_Wall_L") or piece_name.ends_with("LWall"):
				if is_bottom:      tile = Vector2i(2, 2)   # Inner-BL — topo da parede
				elif is_top:       tile = Vector2i(1, 1)   # Inner-TL — base da parede
				else:              tile = Vector2i(1, 0)   # RIGHT — face interna
			elif piece_name.ends_with("_Wall_R") or piece_name.ends_with("RWall"):
				if is_bottom:      tile = Vector2i(3, 1)   # Inner-BR — topo da parede
				elif is_top:       tile = Vector2i(2, 0)   # Inner-TR — base da parede
				else:              tile = Vector2i(3, 2)   # LEFT — face interna
			else:  # _Floor
				# Paredes já fornecem os cantos de junção — floor usa flat TOP em toda a extensão
				tile = Vector2i(3, 0)  # TOP
			# Cantos: aplicar shift da peça adjacente no eixo perpendicular
			var tx := base_xs
			var ty := base_ys
			# is_bottom=row==0=topo na tela; is_top=row==rows-1=base na tela
			# is_right=col==0=esquerda na tela; is_left=col==cols-1=direita na tela
			if piece_name.ends_with("_Wall_L") or piece_name.ends_with("LWall"):
				if is_bottom:   ty =  src_ts   # topo da parede → junção com Ceil
				elif is_top:    ty = -src_ts   # base da parede → junção com Floor
			elif piece_name.ends_with("_Wall_R") or piece_name.ends_with("RWall"):
				if is_bottom:   ty =  src_ts
				elif is_top:    ty = -src_ts
			# _Ceil e _Floor: sem shift horizontal — paredes cobrem os cantos por cima
			var dx := rect.position.x + col * ts + tx
			var dy := rect.position.y + row * ts + ty
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
		if is_top:    return Vector2i(1, 2)   # BOTTOM (is_top = row visual inferior)
		if is_bottom: return Vector2i(3, 0)   # TOP    (is_bottom = row visual superior)
		return Vector2i(2, 1)                 # FILL

	# Linha única (plataforma fina): cantos + topo reto
	if rows == 1:
		if is_left:  return Vector2i(0, 0)    # BOT+LEFT  (canto visual direito)
		if is_right: return Vector2i(1, 3)    # BOT+RIGHT (canto visual esquerdo)
		return Vector2i(3, 0)                 # TOP

	if is_top:
		if is_left:  return Vector2i(3, 3)    # TOP+LEFT  (cantos corretos — não mudar)
		if is_right: return Vector2i(0, 2)    # TOP+RIGHT
		return Vector2i(1, 2)                 # BOTTOM (is_top = linha visual inferior)

	if is_bottom:
		if is_left:  return Vector2i(0, 0)    # BOT+LEFT  (cantos corretos — não mudar)
		if is_right: return Vector2i(1, 3)    # BOT+RIGHT
		return Vector2i(3, 0)                 # TOP    (is_bottom = linha visual superior)

	if is_left:  return Vector2i(3, 2)        # LEFT
	if is_right: return Vector2i(1, 0)        # RIGHT
	return Vector2i(2, 1)                     # FILL
