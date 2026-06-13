# stages/stage_00/stage_00_scene.gd
extends Node2D

const ZAEL_SCENE   := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE   := preload("res://characters/melee/zara.tscn")
const _TILESET     := preload("res://stages/stage_00/Stage_00T.png")
const _GLASS_TEX   := preload("res://stages/stage_00/stage_00_glass.png")
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
	# (removidos os 2 grunts da entrada — logo após o miniboss)
	Vector2(9090, 592),                           # Seção 2 — Degrau 2
	Vector2(9892, 296), Vector2(10292, 232), Vector2(10692, 296),  # Seção 3 — Flutuantes
	Vector2(10960, 216), Vector2(11260, 152),
	Vector2(11460, 152), Vector2(11760, 152),    # Seção 4 — Patamar
]
const ZONE2_FLYERS := [
	Vector2(8860, 608), Vector2(9250, 408),      # acima do topo de Step_Z2_2(y656) e Step_Z2_3(y464)
	Vector2(9892, 182), Vector2(10400, 118),     # pico de pulo de Float_A e Float_B
	Vector2(11260, 38),  Vector2(11860, 38),     # pico de pulo de SubPlat_Z2_1 e Z2_2
]

const ZONE3_GRUNTS := [
	Vector2(13080, 216), Vector2(13260, 216),   # Entrada
	Vector2(13560, 132),                          # Sala A — sub-plat
	Vector2(14000, 116), Vector2(14200, 116),   # Sala B — sub-plat
	Vector2(14620, 132), Vector2(14820, 132),   # Sala C — sub-plat
	Vector2(15340, 216), Vector2(15800, 216),   # Continuação
]
const ZONE3_FLYERS := [
	Vector2(13620, 180),  # Sala A — teto limita pulo; mínimo seguro c/ bob (y=144+24+12)
	Vector2(14100, 180),  # Sala B
]

const BOSS_SPAWN := Vector2(17750, 200)
const CP2_ENTRY_X := 16524.0  # centro visual Corr2_Wall_L (tile X 16492–16556)
const CP2_EXIT_X  := 17120.0  # centro visual Corr2_Wall_R (tile X 17088–17152)

const _CORR_CEIL_Y  := 960.0    # face interna Corr_Ceil
const _CORR_FLOOR_Y := 1088.0   # face interna Corr_Floor
const _DOOR_H       := 200.0    # altura da porta
const _DOOR_V       := _DOOR_H / 3.0  # largura da porta (1/3 da altura ≈ 67px)
const _DOOR_CY      := 1024.0   # centro da porta: 1 tile abaixo do original (960→1024)
const _DOOR_OPEN_Y  := (_CORR_CEIL_Y - _DOOR_CY) - _DOOR_H - 2.0
const _CORR3_DOOR_CY := 212.0   # centro do Corr3 elevado: (80+344)/2

const _MINIBOSS_CAM_CENTER := Vector2(6878.0, 896.0)
const _MINIBOSS_CAM_ZOOM   := 2.0                      # sala 960px total, zoom 2x
const _BOSS_CAM_CENTER     := Vector2(17570.0, 88.0)   # centro da sala (igual miniboss)
const _BOSS_CAM_ZOOM       := 2.0                       # mesma da miniboss

var _player: CharacterBase = null
var _corr1: CorridorSection = null
var _corr2: CorridorSection = null
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
var _camera_locked   := false
var _camera_target   := Vector2.ZERO
var _camera_zoom_tgt := 2.2

# Zona 3 — plataforma móvel do gauntlet "Exame Final"
const _Z3_MOVPLAT_DIST  := 360.0
const _Z3_MOVPLAT_SPEED := 90.0
var _z3_movplat: AnimatableBody2D = null
var _z3_movplat_start_x: float = 0.0
var _z3_movplat_dir: float = 1.0


# ─── Lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Boss_LWall é a abertura da sala — colisão começa desabilitada (parede selada ao spawnar o boss)
	var boss_lwall := get_node_or_null("Boss_LWall")
	if boss_lwall:
		boss_lwall.get_node("CollisionShape2D").disabled = true

	# Paredes de corredor são visuais — as portas de checkpoint fazem a barreira
	for _cwall_name in ["Corr2_Wall_L", "Corr2_Wall_R"]:
		var _cwall := get_node_or_null(_cwall_name)
		if _cwall:
			(_cwall as Node).get_node("CollisionShape2D").set("disabled", true)

	# Guard against running without GameManager/StageManager (e.g. test opens scene directly)
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")

	StageManager.spawn_position = $PlayerSpawn.global_position
	_spawn_player()
	_apply_debug_zone_spawn()
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)

	# Disconnect GoalZone — stage completion is handled via boss defeat
	# (BossBase calls GameManager.complete_stage(stage_id) automatically)

	$Camera2D.zoom = Vector2(2.2, 2.2)
	AudioManager.play_bgm(AudioLibrary.bgm_intro)

	_setup_corr1()
	_setup_doors()
	_setup_corr2_section()
	if not DebugBoot.no_enemies:
		_setup_miniboss_trigger()
	else:
		_open_miniboss_gate_for_debug()
	_maybe_spawn_bot()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	_spawn_zone_enemies(2)
	_spawn_zone_enemies(3)

	# Default respawn at stage start (index 0 means spawn_position)
	# Checkpoint 1 will be saved when player passes through CP1 entry door

	_setup_floor_platform()
	_build_zone3()
	queue_redraw()

func _process(_delta: float) -> void:
	var cam := $Camera2D as Camera2D
	if is_instance_valid(_player):
		if _camera_locked:
			cam.global_position = cam.global_position.lerp(_camera_target, 0.1)
			cam.zoom = cam.zoom.lerp(Vector2(_camera_zoom_tgt, _camera_zoom_tgt), 0.1)
		else:
			cam.zoom = cam.zoom.lerp(Vector2(2.2, 2.2), 0.1)
			if absf(cam.zoom.x - 2.2) < 0.05:
				cam.zoom = Vector2(2.2, 2.2)
				cam.global_position = _player.global_position
			else:
				cam.global_position = cam.global_position.lerp(_player.global_position, 0.12)
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

func _make_door(x: float, cy: float = _DOOR_CY) -> CheckpointDoor:
	var door := _DOOR_SCENE.instantiate() as CheckpointDoor
	door.position    = Vector2(x, cy)
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
	var cp2_entry := _make_door(CP2_ENTRY_X, _CORR3_DOOR_CY)
	cp2_entry.connect("door_opening", _on_door_opening)
	cp2_entry.connect("door_opened",  _on_cp2_entry_opened.bind(cp2_entry))
	_doors.append(cp2_entry)

	var boss_door := _make_door(CP2_EXIT_X, _CORR3_DOOR_CY)
	boss_door.connect("door_opened",  _on_boss_door_opened.bind(boss_door))
	_doors.append(boss_door)

# ─── Corredor 1 (CP1) ────────────────────────────────────────────────────────

func _setup_corr1() -> void:
	_corr1 = CorridorSection.new()
	_corr1.tileset   = _TILESET
	_corr1.glass_tex = _GLASS_TEX
	_corr1.door_tex  = _DOOR_TEX
	# Teto 128px mais curto que o corredor: borda direita em x=6302 (128px antes
	# da porta em x=6430). Evita que o player bata a cabeça ao entrar na sala.
	_corr1.ceil_center     = Vector2(5918.0, 928.0)
	_corr1.ceil_size       = Vector2(768.0, 64.0)
	_corr1.save_checkpoint = false
	_corr1.camera_lock_requested.connect(_on_corr1_cam_lock)
	add_child(_corr1)
	_corr1.setup(_player)
	# Libera os nós estáticos do .tscn — CorridorSection cria os próprios
	for cname: String in ["Corr1_Floor", "Corr1_Ceil", "Corr1_Wall_L", "Corr1_Wall_R"]:
		var n := get_node_or_null(cname)
		if n:
			n.queue_free()

func _on_corr1_cam_lock(center: Vector2, zoom: float) -> void:
	_camera_locked   = true
	_camera_target   = center
	_camera_zoom_tgt = zoom

func _on_door_opening() -> void:
	if is_instance_valid(_player):
		_player.door_locked = true

func _on_cp2_entry_opened(door: Node2D) -> void:
	StageManager.save_checkpoint(Vector2(CP2_EXIT_X + 128, 184), 2)
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
	_camera_locked   = true
	_camera_target   = _BOSS_CAM_CENTER
	_camera_zoom_tgt = _BOSS_CAM_ZOOM
	_spawn_boss()
	# After a short delay, seal the boss room by re-enabling Boss_LWall collision
	await get_tree().create_timer(1.0).timeout
	var boss_lwall := get_node_or_null("Boss_LWall")
	if is_instance_valid(boss_lwall):
		boss_lwall.get_node("CollisionShape2D").set_deferred("disabled", false)

# ─── Boss ─────────────────────────────────────────────────────────────────────

func _spawn_boss() -> void:
	if DebugBoot.no_enemies:
		return
	if _boss_spawned:
		return
	_boss_spawned = true
	_boss = _BOSS_SCENE.instantiate()
	_boss.global_position = BOSS_SPAWN
	_boss.player = _player
	# Arena bounds for the boss room (interior x: 17154–17986, floor top y: 280)
	_boss.arena_left  = 17200.0
	_boss.arena_right = 17940.0
	_boss.arena_floor = 280.0
	add_child(_boss)
	_boss.boss_defeated.connect(_on_boss_defeated)

func _on_boss_defeated(_ability_id: String) -> void:
	_camera_locked = false
	# BossBase already called GameManager.complete_stage(0) in _run_death_sequence
	GameManager.save_game()

# ─── Corredor 2 (Corr2) ──────────────────────────────────────────────────────

func _setup_corr2_section() -> void:
	_corr2 = CorridorSection.new()
	_corr2.tileset          = _TILESET
	_corr2.glass_tex        = _GLASS_TEX
	_corr2.door_tex         = _DOOR_TEX
	_corr2.glass_mirror     = true
	_corr2.floor_center     = Vector2(7774.0, 1120.0)
	_corr2.floor_size       = Vector2(896.0, 64.0)
	_corr2.ceil_center      = Vector2(7774.0, 928.0)
	_corr2.entry_x          = 7326.0
	_corr2.exit_x           = 8222.0
	_corr2.entry_manual     = not DebugBoot.no_enemies  # debug: corredor auto-abre (sem miniboss pra derrotar)
	_corr2.save_checkpoint        = true
	_corr2.checkpoint_index       = 2
	_corr2.checkpoint_respawn_x   = 8350.0
	_corr2.heal_on_entry          = false
	_corr2.cam_center       = Vector2(7774.0, 1024.0)
	_corr2.cam_zoom         = 2.0
	_corr2.glass_fill_x     = 7326.0
	_corr2.glass_fill_cols  = 14
	_corr2.glass_lateral_x  = 8222.0
	_corr2.camera_lock_requested.connect(_on_corr2_cam_lock)
	_corr2.player_traversed.connect(_on_corr2_traversed)
	add_child(_corr2)
	_corr2.setup(_player)

func _on_corr2_cam_lock(center: Vector2, zoom: float) -> void:
	_camera_locked   = true
	_camera_target   = center
	_camera_zoom_tgt = zoom

func _on_corr2_traversed() -> void:
	_camera_locked = false

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
	area.position = Vector2(6470.0, 1024.0)
	area.body_entered.connect(_on_miniboss_room_entered)
	add_child(area)

func _on_miniboss_room_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	# Guard antes da criação: após a morte o GDScript auto-nulifica _miniboss,
	# fazendo o `== null` retornar true numa re-entrada — o que causaria respawn.
	if _miniboss_spawned:
		return
	if _miniboss == null:
		_miniboss = _MINIBOSS_SCENE.instantiate()
		_miniboss.global_position = Vector2(7000.0, 1024.0)
		_miniboss.died.connect(_on_miniboss_defeated)
		call_deferred("add_child", _miniboss)
	# Aguarda player sair completamente da LWall — só ENTÃO sela e troca câmera
	while is_instance_valid(body) and body.global_position.x < 6490.0:
		await get_tree().process_frame
	if _miniboss_spawned:
		return  # coroutine paralela já processou
	_miniboss_spawned = true
	var lwall := get_node_or_null("MiniBoss_LWall")
	if lwall:
		lwall.get_node("CollisionShape2D").set_deferred("disabled", false)
	_camera_locked   = true
	_camera_target   = _MINIBOSS_CAM_CENTER
	_camera_zoom_tgt = _MINIBOSS_CAM_ZOOM

func _apply_debug_zone_spawn() -> void:
	# Param ?zone=N: spawna direto numa zona pra testar (debug). Atualiza o respawn também.
	if DebugBoot.zone <= 0 or not is_instance_valid(_player):
		return
	var pos := Vector2.ZERO
	match DebugBoot.zone:
		2: pos = Vector2(8400, 1000)    # entrada da zona 2 (pós-miniboss)
		3: pos = Vector2(13100, 220)    # zona 3 (gauntlet)
		4: pos = Vector2(17570, 200)    # sala do boss (debug)
		5: pos = Vector2(5800, 1040)    # interior do Corr1 (debug teto/porta)
		_: return                        # zona 1 = início normal
	_player.global_position = pos
	StageManager.spawn_position = pos
	if DebugBoot.zone == 4:  # debug: trava a câmera na sala do boss (visão real da luta)
		_camera_locked   = true
		_camera_target   = _BOSS_CAM_CENTER
		_camera_zoom_tgt = _BOSS_CAM_ZOOM

func _open_miniboss_gate_for_debug() -> void:
	# no_enemies: sem miniboss pra derrotar, a parede de saída fica aberta (senão tranca a sala).
	var rwall := get_node_or_null("MiniBoss_RWall")
	if rwall:
		rwall.get_node("CollisionShape2D").set_deferred("disabled", true)

func _on_miniboss_defeated() -> void:
	var rwall := get_node_or_null("MiniBoss_RWall")
	if rwall:
		rwall.get_node("CollisionShape2D").set_deferred("disabled", true)
		queue_redraw()
	if _corr2 != null:
		_corr2.open_entry()

# ─── Zone Triggers ───────────────────────────────────────────────────────────

func _setup_zone_triggers() -> void:
	# Zone 1: x 0–5800
	var z1 := _make_zone_trigger(2900, 800, 5800, 1200)
	z1.body_entered.connect(_on_zone1_entered)
	z1.body_exited.connect(_on_zone1_exited)
	add_child(z1)

	# Zone 2: x 8222–12922 (redesenhada — player pode estar em y=280)
	var z2 := _make_zone_trigger(10572, 600, 4700, 1400)
	z2.body_entered.connect(_on_zone2_entered)
	z2.body_exited.connect(_on_zone2_exited)
	add_child(z2)

	# Zone 3: x 12922–16492 (interior elevado — player em y=280)
	var z3 := _make_zone_trigger(14707, 300, 3570, 800)
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
	if DebugBoot.no_enemies:
		return
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

# ─── Piso + plataforma (heightfield) ─────────────────────────────────────────
# Funde a antiga "Debug_Plat" ao Floor_Z1A como UMA peça piso+plataforma (modo
# "Piso+Plat" do ImgDebug): piso reto + plataforma elevada + piso reto, com paredes
# e junções côncavas via marching-squares. Floor_Z1A vira nó fp (desenho próprio via
# _draw_fp_node) e ganha uma 2ª colisão (a plataforma elevada).
const _FP_PLAT_COLS := 4    # 256px (4 tiles)
const _FP_LEFT_COLS := 7    # plataforma começa em x=448 (~posição da antiga Debug_Plat)
const _FP_ELEV_ROWS := 1    # sobe 1 tile (64px) — saltável
const _FP_DEPTH_ROWS := 2   # piso desenhado 2 tiles (junção côncava renderiza)

func _setup_floor_platform() -> void:
	var floor_node := get_node_or_null("Floor_Z1A") as StaticBody2D
	if floor_node == null:
		return
	var fcs := floor_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if fcs == null or not (fcs.shape is RectangleShape2D):
		return
	var fsize: Vector2 = (fcs.shape as RectangleShape2D).size
	var ftop_world: float = floor_node.position.y + fcs.position.y - fsize.y * 0.5  # superfície
	var fleft_world: float = floor_node.position.x + fcs.position.x - fsize.x * 0.5
	var total_cols: int = ceili(fsize.x / float(_TS))
	var right_cols: int = total_cols - _FP_LEFT_COLS - _FP_PLAT_COLS

	# Colisão da plataforma elevada (degrau sólido do topo até a superfície do piso).
	# Inset de 16px em cada lateral para alinhar a colisão com a face opaca do tile.
	const _SIDE_INSET := 34.0
	var plat_left: float = fleft_world + _FP_LEFT_COLS * _TS + _SIDE_INSET
	var plat_top: float = ftop_world - _FP_ELEV_ROWS * _TS
	var plat_w: float = _FP_PLAT_COLS * _TS - _SIDE_INSET * 2.0
	var plat_h: float = _FP_ELEV_ROWS * _TS
	var pcs := CollisionShape2D.new()
	var pshape := RectangleShape2D.new()
	pshape.size = Vector2(plat_w, plat_h)
	pcs.shape = pshape
	var plat_center := Vector2(plat_left + plat_w * 0.5, plat_top + plat_h * 0.5)
	pcs.position = plat_center - floor_node.position   # local ao Floor_Z1A
	floor_node.add_child(pcs)

	floor_node.set_meta("fp_params", {
		"left_cols": _FP_LEFT_COLS, "plat_cols": _FP_PLAT_COLS, "right_cols": right_cols,
		"elev_rows": _FP_ELEV_ROWS, "depth_rows": _FP_DEPTH_ROWS,
		"left_x": fleft_world, "surface_y": ftop_world, "surface_w": fsize.x,
	})

# ─── Zona 3 — gauntlet "Exame Final" (dash → wall-jump → plataforma móvel) ──────

func _build_zone3() -> void:
	# Remove a zona 3 antiga (divisores intransponíveis — vão de 58px < player 80px).
	for n in ["Div_Z3_1_Top","Div_Z3_1_Bot","Div_Z3_2_Top","Div_Z3_2_Bot","Div_Z3_3_Top","Div_Z3_3_Bot","SubPlat_Z3_A","SubPlat_Z3_B","SubPlat_Z3_C","SubPlat_Z3_D","CorrZ3_Rooms_Floor","CorrZ3_Rooms_Ceil","CorrZ3_Entry_Ceil","CorrZ3_Cont_Ceil"]:
		var node := get_node_or_null(n)
		if node:
			node.queue_free()
	# 1) DASH: vão de 260px depois do entry floor (12922–13400) → Floor A
	# 2) WALL-JUMP: parede alta sobre o Floor A
	_add_z3_static("Z3_FloorA", Vector2(14205, 344), Vector2(1090, 128))  # x 13660–14750, topo y280
	_add_z3_static("Z3_Wall",   Vector2(14250, 200), Vector2(300, 160))   # x 14100–14400, topo y120
	# 3) PLATAFORMA MÓVEL sobre o fosso (x 14750–15200) → CorrZ3_Cont_Floor (15200–16492)
	var mp := AnimatableBody2D.new()
	mp.name = "Z3MovingPlat"
	mp.sync_to_physics = true
	mp.collision_layer = 1
	mp.collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(192, 32)
	cs.shape = shape
	mp.add_child(cs)
	mp.position = Vector2(14975, 296)  # topo y280
	add_child(mp)
	_z3_movplat = mp
	_z3_movplat_start_x = mp.position.x
	# Teto com COLISÃO (player bate a cabeça se chegar) — alinhado ao fundo do glass (y=-192).
	# Prefixo "Glass_" → não desenha tile por cima (o painel de glass já é o visual).
	_add_z3_static("Glass_Z3_Ceil", Vector2(14707, -256), Vector2(3570, 128))  # x 12922–16492, face de baixo y=-192

func _add_z3_static(node_name: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	add_child(body)

func _physics_process(delta: float) -> void:
	if _z3_movplat and is_instance_valid(_z3_movplat):
		var half := _Z3_MOVPLAT_DIST * 0.5
		_z3_movplat.position.x += _z3_movplat_dir * _Z3_MOVPLAT_SPEED * delta
		if _z3_movplat.position.x >= _z3_movplat_start_x + half:
			_z3_movplat.position.x = _z3_movplat_start_x + half
			_z3_movplat_dir = -1.0
		elif _z3_movplat.position.x <= _z3_movplat_start_x - half:
			_z3_movplat.position.x = _z3_movplat_start_x - half
			_z3_movplat_dir = 1.0

# ─── Drawing ─────────────────────────────────────────────────────────────────

func _draw() -> void:
	_draw_background()
	_draw_glass_panels()
	_draw_platforms()
	_draw_boss_room()
	_draw_door_underlays()

func _draw_glass_panels() -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	var lat_src  := Rect2(1 * src_ts, 0 * src_ts, src_ts, src_ts)  # tile (1,0) — lateral
	var fill_src := Rect2(2 * src_ts, 1 * src_ts, src_ts, src_ts)  # tile (2,1) — centro

	# Teto elevado Z3/Corr3 em y=80 — 20 tiles × 64px (y=-1152 até y=128)
	var col_rows := 20
	var col_top  := -1152.0

	# ── Zona 3 — glass com TETO MAIS ALTO (headroom pro gauntlet) ────────────
	# Antes: 20 linhas → fundo em y=128 (vão de só 152px, player entrava no teto).
	# Agora: 15 linhas → fundo em y=-192 (vão de ~472px sobre o chão y280).
	var z3_rows := 15
	var z3_fill_cols := 56  # 12922 + 56×64 = 16506 ≈ entrada do Corr3
	for row in z3_rows:
		var dy := col_top + row * ts
		draw_texture_rect_region(_GLASS_TEX, Rect2(12858.0, dy, ts, ts), lat_src)
		for col in z3_fill_cols:
			draw_texture_rect_region(_GLASS_TEX, Rect2(12922.0 + col * ts, dy, ts, ts), fill_src)

	# ── Corredor 3 → sala do chefe (x 16428–17132) ───────────────────────────
	var c2_fill_cols := 10  # x=16492→17132, para na porta (sem invadir a sala)
	for row in col_rows:
		var dy := col_top + row * ts
		draw_texture_rect_region(_GLASS_TEX, Rect2(16428.0, dy, ts, ts), lat_src)
		for col in c2_fill_cols:
			draw_texture_rect_region(_GLASS_TEX, Rect2(16492.0 + col * ts, dy, ts, ts), fill_src)

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
	# Fundo branco SÓ em debug (?whitebg=1) — para visualizar os tiles isolados.
	if DebugBoot.white_bg:
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
		if not (child is StaticBody2D or child is AnimatableBody2D):  # AnimatableBody2D = plataforma móvel
			continue
		if child is CheckpointDoor:
			continue
		if (child as Node).name.begins_with("Glass_"):
			continue
		if child.has_meta("fp_params"):   # peça piso+plataforma (heightfield) — desenho próprio
			_draw_fp_node(child)
			continue
		for shape_child in child.get_children():
			if not shape_child is CollisionShape2D:
				continue
			if not shape_child.shape is RectangleShape2D:
				continue
			var cs := shape_child as CollisionShape2D
			var n_check: String = (child as Node).name
			# Sala do boss é desenhada como grid unificado em _draw_boss_room()
			if n_check.begins_with("Boss_"):
				continue
			if cs.disabled and not n_check.begins_with("MiniBoss_"):
				continue
			var size: Vector2 = (cs.shape as RectangleShape2D).size
			var center: Vector2 = (child as Node2D).position + (cs as Node2D).position
			var rect := Rect2(center - size * 0.5, size)
			var n: String = child.name
			if n == "MiniBoss_LWall" or n == "MiniBoss_RWall":
				# Desenha só os tiles acima da abertura da porta (igual nos dois lados)
				var door_top   := _DOOR_CY - _DOOR_H * 0.5
				var above_rows := ceili((door_top - rect.position.y) / _TS)  # 5 tiles
				var top_rect   := Rect2(rect.position.x, rect.position.y, rect.size.x, above_rows * _TS)
				_draw_room_tiles(top_rect, n, true)
			elif n.begins_with("Corr") or n.begins_with("MiniBoss_"):
				_draw_room_tiles(rect, n)
			else:
				_draw_platform_tiles(rect, _TILESET)

func _draw_boss_room() -> void:
	# Sala do boss desenhada como grid unificado N×M (mesmo padrão do img_debug _room_at):
	# cantos côncavos corretos em uma única passada, com a abertura da porta na parede esquerda.
	# Mapeamento canônico (screen-space): TL=(3,1) TR=(2,2) BL=(2,0) BR=(1,1)
	#   teto=(1,2) chão=(3,0) parede_esq=(3,2) parede_dir=(1,0)
	var lwall  := get_node_or_null("Boss_LWall")  as Node2D
	var rwall  := get_node_or_null("Boss_RWall")  as Node2D
	var ceil_n := get_node_or_null("Boss_Ceil")   as Node2D
	var floor_n := get_node_or_null("Boss_Floor") as Node2D
	if not (lwall and rwall and ceil_n and floor_n):
		return
	var ts     := _TS
	var src_ts := _SRC_TS
	var left   := lwall.position.x - ts * 0.5
	var right  := rwall.position.x + ts * 0.5
	var top    := ceil_n.position.y - ts * 0.5
	var bottom := floor_n.position.y + ts * 0.5
	var cols := int(round((right - left) / ts))
	var rows := int(round((bottom - top) / ts))
	# Abertura da porta na parede esquerda: linhas que cobrem o vão do corredor (Corr2)
	var corr_ceil  := get_node_or_null("Corr2_Ceil")  as Node2D
	var corr_floor := get_node_or_null("Corr2_Floor") as Node2D
	var pass_top: float  = (corr_ceil.position.y  + ts * 0.5) if corr_ceil  else 144.0
	var pass_bot: float  = (corr_floor.position.y - ts * 0.5) if corr_floor else 280.0
	var door_lo := int(ceil((pass_top - top) / ts))
	var door_hi := int(floor((pass_bot - top) / ts)) - 1
	for row in rows:
		for col in cols:
			var is_l := col == 0
			var is_r := col == cols - 1
			var is_t := row == 0
			var is_b := row == rows - 1
			if not (is_l or is_r or is_t or is_b):
				continue  # interior vazio
			if is_l and not is_t and not is_b and row >= door_lo and row <= door_hi:
				continue  # abertura da porta
			# Porta encosta no chão? Então o piso atravessa reto (rente ao corredor),
			# sem canto na base da parede da porta.
			var door_to_floor := door_hi >= rows - 2
			var bl_is_floor := is_b and is_l and door_to_floor
			var tile: Vector2i
			# Shifts de meia-célula p/ a face sólida coincidir com a colisão (igual
			# _draw_room_tiles): chão sobe, teto desce, paredes entram. Sem isso o piso
			# do boss fica meio tile abaixo do corredor e o personagem parece flutuar.
			var tx := 0
			var ty := 0
			if   is_t and is_l:     tile = Vector2i(3, 1); tx =  src_ts; ty =  src_ts   # canto sup-esq
			elif is_t and is_r:     tile = Vector2i(2, 2); tx = -src_ts; ty =  src_ts   # canto sup-dir
			elif bl_is_floor:       tile = Vector2i(3, 0);              ty = -src_ts    # chão rente à porta (sem canto)
			elif is_b and is_l:     tile = Vector2i(2, 0); tx =  src_ts; ty = -src_ts   # canto inf-esq
			elif is_b and is_r:     tile = Vector2i(1, 1); tx = -src_ts; ty = -src_ts   # canto inf-dir
			elif is_t:              tile = Vector2i(1, 2);              ty =  src_ts    # teto
			elif is_b:              tile = Vector2i(3, 0);              ty = -src_ts    # chão
			elif is_l:              tile = Vector2i(3, 2); tx =  src_ts                 # parede esquerda
			else:                   tile = Vector2i(1, 0); tx = -src_ts                 # parede direita
			var dx := left + col * ts + tx
			var dy := top + row * ts + ty
			draw_texture_rect_region(_TILESET,
				Rect2(dx, dy, ts, ts),
				Rect2(tile.x * src_ts, tile.y * src_ts, src_ts, src_ts))

func _draw_platform_tiles(rect: Rect2, tex: Texture2D) -> void:
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
			# Preenche as bordas com meia-tile sólida. NÃO REMOVER para piso reto:
			# os tiles de canto (0,0)/(1,3) têm ~metade transparente (chanfro); sem este
			# preenchimento a borda sólida fica recuada da colisão → vão horizontal entre
			# o personagem (que colide na borda real) e o piso visível.
			if cols > 1:
				var fill := _gap_fill_tile(row, rows)
				if col == 0:
					dx -= src_ts
					draw_texture_rect_region(tex,
						Rect2(rect.position.x + ts / 2.0, dy, ts / 2.0, dh),
						Rect2(fill.x * src_ts, fill.y * src_ts, src_ts / 2, src_ts))
				elif col == cols - 1:
					dx += src_ts
					draw_texture_rect_region(tex,
						Rect2(rect.position.x + (cols - 1) * ts, dy, ts / 2.0, dh),
						Rect2(fill.x * src_ts + src_ts / 2, fill.y * src_ts, src_ts / 2, src_ts))
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var src := Rect2(tile.x * src_ts, tile.y * src_ts, src_ts * dw / ts, src_ts * dh / ts)
			draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh), src)

func _gap_fill_tile(row: int, rows: int) -> Vector2i:
	if row == 0:        return Vector2i(3, 0)  # TOP — linha visual superior
	if row == rows - 1: return Vector2i(1, 2)  # BOTTOM — linha visual inferior
	return Vector2i(2, 1)                       # FILL — interior

# ─── Peça "piso + plataforma" (heightfield) ──────────────────────────────────
# Espelha _fp_solid/_fp_tile de ui/img_debug.gd (modo "Piso+Plat") e stage_scene.gd.
# Piso reto + plataforma elevada (sem vão embaixo) + piso reto, como UM bloco só.
func _fp_solid(c: int, r: int, lc: int, pc: int, er: int, total_c: int, total_r: int, hole: int) -> bool:
	if c < 0 or r < 0 or c >= total_c or r >= total_r:
		return false
	var in_plat: bool = c >= lc and c < lc + pc
	if in_plat:
		return true
	if hole > 0 and c >= lc + pc:
		return false
	if hole < 0 and c < lc:
		return false
	return r >= er

func _fp_tile(c: int, r: int, lc: int, pc: int, er: int, total_c: int, total_r: int, hole: int) -> Vector2i:
	var eu := not _fp_solid(c, r - 1, lc, pc, er, total_c, total_r, hole)
	var ed := not _fp_solid(c, r + 1, lc, pc, er, total_c, total_r, hole)
	var el := not _fp_solid(c - 1, r, lc, pc, er, total_c, total_r, hole)
	var er_x := not _fp_solid(c + 1, r, lc, pc, er, total_c, total_r, hole)
	if eu and el: return Vector2i(1, 3)   # canto sup-esq
	if eu and er_x: return Vector2i(0, 0)  # canto sup-dir
	if ed and el: return Vector2i(0, 2)   # canto inf-esq
	if ed and er_x: return Vector2i(3, 3)  # canto inf-dir
	if eu: return Vector2i(3, 0)          # TOP (superfície)
	if ed: return Vector2i(1, 2)          # BOTTOM
	if el: return Vector2i(1, 0)          # parede esquerda visual
	if er_x: return Vector2i(3, 2)        # parede direita visual
	if not _fp_solid(c - 1, r - 1, lc, pc, er, total_c, total_r, hole): return Vector2i(1, 1)  # entalhe sup-esq
	if not _fp_solid(c + 1, r - 1, lc, pc, er, total_c, total_r, hole): return Vector2i(2, 0)  # entalhe sup-dir
	return Vector2i(2, 1)                  # FILL

func _draw_fp_node(node: Node) -> void:
	var p: Dictionary = node.get_meta("fp_params")
	var tex := _TILESET
	if tex == null:
		return
	var lc: int = p["left_cols"]
	var pc: int = p["plat_cols"]
	var rc: int = p["right_cols"]
	var er: int = p["elev_rows"]
	var dr: int = p["depth_rows"]
	var hole: int = p.get("hole_dir", 0)
	var total_c: int = lc + pc + rc
	var total_r: int = er + dr
	var ts := _TS
	var src := _SRC_TS
	var gx: float = p["left_x"]
	var gy: float = float(p["surface_y"]) - er * ts   # topo da grade (topo da plataforma)
	var surface_right: float = gx + float(p.get("surface_w", total_c * ts))
	for r in total_r:
		for c in total_c:
			if not _fp_solid(c, r, lc, pc, er, total_c, total_r, hole):
				continue
			var t := _fp_tile(c, r, lc, pc, er, total_c, total_r, hole)
			var dx := gx + c * ts
			var dy := gy + r * ts - src   # alinha face sólida superior com a colisão
			var dw: float = minf(float(ts), surface_right - dx)   # clamp à largura real do piso
			if dw <= 0.0:
				continue
			# Gap-fill lateral: tiles de canto (1,3)/(0,0) têm ~metade transparente na face
			# exposta. Preenche a área transparente com meia-tile de parede ANTES do tile
			# principal, para eliminar o vão invisível entre colisão e visual.
			draw_texture_rect_region(tex,
				Rect2(dx, dy, dw, float(ts)),
				Rect2(t.x * src, t.y * src, src * dw / ts, src))

func _draw_room_tiles(rect: Rect2, piece_name: String, skip_bottom_corner: bool = false) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	# Shifts base por peça (face de contato → expõe metade transparente ao jogador)
	var base_xs := 0
	var base_ys := 0
	if   piece_name.ends_with("_Floor"):                                      base_ys = -src_ts
	elif piece_name.ends_with("_Ceil"):                                       base_ys =  src_ts
	elif piece_name.ends_with("_Wall_L"):                                     base_xs =  src_ts
	elif piece_name.ends_with("LWall"):                                       base_xs =  0
	elif piece_name.ends_with("_Wall_R"):                                     base_xs = -src_ts
	elif piece_name.ends_with("RWall"):                                       base_xs =  0
	var cols := ceili(rect.size.x / ts)
	var rows := ceili(rect.size.y / ts)
	for row in rows:
		for col in cols:
			var is_left   := col == cols - 1
			var is_right  := col == 0
			var is_top    := row == rows - 1 and not skip_bottom_corner
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

func _maybe_spawn_bot() -> void:
	if not DebugBoot.bot_enabled:
		return
	var bot := preload("res://tests/bot/stage_bot.gd").new()
	bot.name = "StageBot"
	add_child(bot)
