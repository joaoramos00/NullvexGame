# stages/stage_02/stage_02_scene.gd — Cryovex (gelo)
# Estende a base stage_scene.gd: spawn/câmera/pause/kill-plane/desenho herdados.
# Os pisos usam lava_override com o tileset EXPLÍCITO da zona (mapeamento por
# nome exato, como o _texture_for_node antigo — sem adivinhação posicional);
# vidro dos abismos usa tileset_override (fill = rect exato).
extends "res://stages/stage_scene.gd"

var _door_tex: Texture2D = null
var _tileset_z2: Texture2D = null
var _tileset_z3: Texture2D = null
var _tileset_z4: Texture2D = null
var _glass_tex: Texture2D = null
var _grunt_scene: PackedScene = null
var _flyer_scene: PackedScene = null
var _mb02_scene: PackedScene = null
var _archer_scene: PackedScene = null
var _turret_scene: PackedScene = null
var _bomber_scene: PackedScene = null
var _shield_scene: PackedScene = null
var _wisp_scene: PackedScene = null

const _SPIKES_TEX := preload("res://stages/stage_01/spikes.png")   # mesmo PNG; tingido de azul
const _ICE_TINT := Color(0.62, 0.85, 1.0)
const _CRUMBLE := preload("res://stages/stage_01/crumbling_ledge.gd")   # script genérico

# Posições ajustadas ao relevo novo: inimigos sobre plataformas elevadas ficam
# no topo delas (y700 = topo 736 - spawn), não dentro da massa sólida.
const Z1_GRUNTS := [Vector2(700, 700), Vector2(1500, 700), Vector2(2700, 760), Vector2(3700, 760), Vector2(4800, 760)]
const Z1_FLYERS := [Vector2(1100, 600), Vector2(2900, 560), Vector2(4400, 600)]
const Z1_ARCHERS := [Vector2(1700, 760), Vector2(5100, 700)]
const Z2_GRUNTS := [Vector2(5900, 760), Vector2(6900, 760), Vector2(8000, 700), Vector2(9000, 760), Vector2(10200, 760)]
const Z2_FLYERS := [Vector2(6300, 560), Vector2(8600, 540), Vector2(10000, 580)]
const Z2_ARCHERS := [Vector2(6100, 760), Vector2(10300, 760)]
const Z2_SHIELDS := [Vector2(8350, 760)]   # guarda a entrada do campo de espinhos A
const Z3_GRUNTS := [Vector2(13600, 700), Vector2(14600, 760), Vector2(15800, 700), Vector2(16900, 760), Vector2(17700, 760)]
const Z3_FLYERS := [Vector2(14000, 560), Vector2(16000, 520), Vector2(17400, 580)]
const Z3_TURRETS := [Vector2(13750, 700), Vector2(17200, 740)]
const Z3_WISPS := [Vector2(15200, 520), Vector2(16600, 540)]
const Z4_GRUNTS := [Vector2(18400, 760), Vector2(20500, 760), Vector2(22300, 760)]
const Z4_FLYERS := [Vector2(19600, 560), Vector2(21500, 520), Vector2(23200, 580)]
const Z4_TURRETS := [Vector2(18600, 740), Vector2(22750, 740)]
const Z4_BOMBERS := [Vector2(20400, 700), Vector2(23540, 760)]
const Z4_SHIELDS := [Vector2(20600, 760)]
const Z4_WISPS := [Vector2(19500, 520), Vector2(21400, 520)]

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
const _BOSS_L := 24400.0
const _BOSS_R := 25800.0

var _camera_locked := false
var _camera_target := Vector2.ZERO
var _camera_zoom_tgt := 2.0
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
	if StageManager.current_stage_id < 0:
		StageManager.current_stage_id = 2
	super._ready()
	_load_resources()
	# Corpos do .tscn sem zona no nome: tileset explícito p/ o desenho da base.
	for pair: Array in [["MB02_Floor", "z3"], ["Z2_IgnarathGate", "z2"], ["Z4_LuxarGate", "z4"]]:
		var nd := get_node_or_null(pair[0] as String)
		if nd:
			nd.set_meta("lava_override", _zone_tile_path(pair[1] as String))
	_relocate_gated_secrets()
	_setup_blizzards()
	# O campo de espinhos do .tscn (invisível) foi substituído pelos campos com
	# visual construídos em _build_zone2().
	var old_spikes := get_node_or_null("Z2_Spikes")
	if old_spikes:
		old_spikes.queue_free()
	_setup_corridors()
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_boss_arena()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	_build_zone_ceilings02()
	_setup_secret_covers()
	queue_redraw()

func _load_resources() -> void:
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_tileset_z2 = load("res://stages/stage_02/Stage_02T_z2.png") as Texture2D
	_tileset_z3 = load("res://stages/stage_02/Stage_02T_z3.png") as Texture2D
	_tileset_z4 = load("res://stages/stage_02/Stage_02T_z4.png") as Texture2D
	_glass_tex = load("res://stages/stage_02/stage_02_glass.png") as Texture2D
	_grunt_scene = load("res://characters/enemies/stage_02/enemy_ice_grunt.tscn") as PackedScene
	_flyer_scene = load("res://characters/enemies/stage_02/enemy_ice_flyer.tscn") as PackedScene
	_mb02_scene = load("res://characters/enemies/stage_02/enemy_ice_miniboss.tscn") as PackedScene
	_archer_scene = load("res://characters/enemies/stage_02/enemy_ice_archer.tscn") as PackedScene
	_turret_scene = load("res://characters/enemies/stage_02/enemy_frost_turret.tscn") as PackedScene
	_bomber_scene = load("res://characters/enemies/stage_02/enemy_cryo_bomber.tscn") as PackedScene
	_shield_scene = load("res://characters/enemies/stage_02/enemy_glacier_shield.tscn") as PackedScene
	_wisp_scene = load("res://characters/enemies/stage_02/enemy_ice_wisp.tscn") as PackedScene

func _zone_tile_path(zone: String) -> String:
	# Case EXATO do arquivo (PCK web é case-sensitive): Stage_02T_z1.png etc.
	return "res://stages/stage_02/Stage_02T_%s.png" % zone.to_lower()

# Câmera: trava de corredor/miniboss tem prioridade; fora dela, segue o player
# via CameraController da base.
func _process(delta: float) -> void:
	var cam := $Camera2D as Camera2D
	if _camera_locked:
		cam.global_position = cam.global_position.lerp(_camera_target, 0.12)
		cam.zoom = cam.zoom.lerp(Vector2(_camera_zoom_tgt, _camera_zoom_tgt), 0.12)
		queue_redraw()
		return
	if not DebugBoot.bot_enabled:
		cam.zoom = cam.zoom.lerp(Vector2(2.0, 2.0), 0.12)
	super._process(delta)

func _setup_corridors() -> void:
	_corr1 = _make_corridor("CP1", _CP1_ENTRY_X, _CP1_EXIT_X, 1, false, false)
	_corr2 = _make_corridor("CP2", _CP2_ENTRY_X, _CP2_EXIT_X, 2, not (DebugBoot.bot_enabled or DebugBoot.no_enemies), false)
	# CP3 usa índice 4: o checkpoint 3 é o da base do Poço de Gelo (índices
	# crescem com a progressão — checkpoint só salva se o índice for maior).
	_corr3 = _make_corridor("CP3", _CP3_ENTRY_X, _CP3_EXIT_X, 4, false, false)

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
	_make_zone_trigger("Z2Trigger", Rect2(5600, 300, 4000, 900), 2)
	_make_zone_trigger("MB02Trigger", Rect2(_CP1_EXIT_X, 300, 900, 900), 5)
	_make_zone_trigger("Z3Trigger", Rect2(_CP2_EXIT_X, 300, 4000, 900), 3)
	_make_zone_trigger("Z4Trigger", Rect2(18000, 300, 4000, 900), 4)

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
	if DebugBoot.no_enemies:
		return
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
	if DebugBoot.no_enemies:
		return
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

# ── Helpers de terreno procedural (piso baseado no chão; sem flutuantes) ──────
# Segmento de piso sólido: topo em surface_y, profundidade dr tiles. zone = "Z1".."Z4".
# lava_override com o tileset da zona: o desenho da base faz crosta (3,0) + miolo
# (2,1) — mesmo visual do bloco antigo, sem o pipeline duplicado.
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
	b.set_meta("lava_override", _zone_tile_path(zone))
	add_child(b)
	return b

func _solid_block(zone: String, n: String, cx: float, cy: float, w: float, h: float) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = n
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = Vector2(cx, cy)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	b.add_child(cs)
	b.set_meta("lava_override", _zone_tile_path(zone))
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
	# fill = rect exato (vidro não pode transbordar como o modo lava min-7)
	b.set_meta("tileset_override", "res://stages/stage_02/stage_02_glass.png")
	add_child(b)
	return b

# POÇO RECUPERÁVEL (Z1–Z3): piso à esquerda, vão, piso à direita, e um piso de
# fundo (catch) ~`depth` abaixo cobrindo o vão → cai e volta pulando (depth ≤ ~96).
func _recoverable_pit(zone: String, left_x: float, right_x: float, gap_x0: float, gap_x1: float, depth: float = 96.0) -> void:
	_floor_seg(zone, left_x, gap_x0, FLOOR_Y)
	_floor_seg(zone, gap_x1, right_x, FLOOR_Y)
	_floor_seg(zone, gap_x0, gap_x1, FLOOR_Y + depth)   # fundo do poço (catch)

# ABISMO MORTAL (Z4): piso à esquerda, vão ABERTO (sem fundo → morte), piso à
# direita, com VIDRO nas faces internas. O kill plane (da base) mata na queda.
func _deadly_pit(left_x: float, right_x: float, gap_x0: float, gap_x1: float) -> void:
	_floor_seg("Z4", left_x, gap_x0, FLOOR_Y)
	_floor_seg("Z4", gap_x1, right_x, FLOOR_Y)
	_glass_wall(gap_x0 + 32.0, FLOOR_Y, 320.0)   # face de vidro à esquerda do vão
	_glass_wall(gap_x1 - 32.0, FLOOR_Y, 320.0)   # face de vidro à direita do vão

# Degrau elevado saltável (≤64px) sobre o piso base — seção de chão mais alta.
func _step_up(zone: String, x0: float, x1: float, rise: float = 64.0) -> void:
	_floor_seg(zone, x0, x1, FLOOR_Y - rise)

# ── Elementos temáticos ───────────────────────────────────────────────────────

# Peça PISO+PLATAFORMA (heightfield fp_params — desenho da base): piso reto +
# plataforma elevada SEM vão (massa sólida) + piso reto. Medidas em tiles;
# elevação er ≤ 1 é pulável do chão (64px < pulo de 118).
func _fp(n: String, zone: String, left_x: float, lc: int, pc: int, rc: int, er: int = 1) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = n
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = Vector2.ZERO
	var tile := 64.0
	var total_c := lc + pc + rc
	var floor_cs := CollisionShape2D.new()
	var fsh := RectangleShape2D.new()
	fsh.size = Vector2(total_c * tile, 2.0 * tile)
	floor_cs.shape = fsh
	floor_cs.position = Vector2(left_x + total_c * 0.5 * tile, FLOOR_Y + tile)
	b.add_child(floor_cs)
	var plat_cs := CollisionShape2D.new()
	var psh := RectangleShape2D.new()
	psh.size = Vector2(pc * tile, er * tile)
	plat_cs.shape = psh
	plat_cs.position = Vector2(left_x + (lc + pc * 0.5) * tile, FLOOR_Y - er * tile * 0.5)
	b.add_child(plat_cs)
	add_child(b)
	b.set_meta("fp_params", {
		"left_cols": lc, "plat_cols": pc, "right_cols": rc,
		"elev_rows": er, "depth_rows": 2, "hole_dir": 0,
		"left_x": left_x, "surface_y": FLOOR_Y, "tex_path": _zone_tile_path(zone),
	})
	return b

# Campo de espinhos de gelo no chão: Area2D INSTANT KILL (ice_spikes.gd, padrão
# espinho-mata do projeto) + tira visual do spikes.png tingida de azul, tips pra
# cima, base ~8px embutida no piso. Largura em clusters INTEIROS de 32px
# (escala nativa 1x — cluster antigo de 64px cortado ao meio, o dobro aparece
# sozinho via texture_repeat na mesma largura x0-x1).
# SEM margem de perdão: a faixa de kill cobre o visual inteiro (tip a tip) —
# tocar a ponta já mata, não só pisar.
func _ice_spike_field(n: String, x0: float, x1: float) -> void:
	var area := Area2D.new()
	area.name = n
	area.set_script(load("res://stages/stage_02/ice_spikes.gd"))
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = Vector2((x0 + x1) * 0.5, FLOOR_Y - 8.0)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(x1 - x0, 32.0)
	cs.shape = sh
	area.add_child(cs)
	add_child(area)
	var spr := Sprite2D.new()
	spr.name = n + "Vis"
	spr.texture = _SPIKES_TEX
	spr.centered = true
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0.0, 0.0, x1 - x0, 32.0)
	spr.scale = Vector2(1.0, 1.0)
	spr.modulate = _ICE_TINT
	spr.position = Vector2((x0 + x1) * 0.5, FLOOR_Y - 8.0)
	spr.z_index = 5
	add_child(spr)

# Plataforma de gelo flutuante (rota segura sobre espinhos): 160×32 com pontas.
func _ice_plat(n: String, zone: String, cx: float, top_y: float, w: float = 160.0) -> void:
	var b := StaticBody2D.new()
	b.name = n
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = Vector2(cx, top_y + 16.0)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, 32.0)
	cs.shape = sh
	b.add_child(cs)
	b.set_meta("platform_override", _zone_tile_path(zone))
	add_child(b)

# Plataforma de gelo que DESMORONA (0.5s após o pouso, respawn 1.2s) — pousos
# intermediários dos abismos largos da Z4. Script genérico do stage 01.
func _ice_crumble(n: String, cx: float, top_y: float, w: float = 128.0) -> void:
	var body := StaticBody2D.new()
	body.name = n
	body.set_script(_CRUMBLE)
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(cx, top_y + 16.0)
	body.set_meta("platform_override", _zone_tile_path("z4"))
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, 32.0)
	cs.shape = sh
	body.add_child(cs)
	var det := Area2D.new()
	det.name = "LandDetector"
	det.collision_layer = 0
	det.collision_mask = 2
	var dcs := CollisionShape2D.new()
	var dsh := RectangleShape2D.new()
	dsh.size = Vector2(w, 16.0)
	dcs.shape = dsh
	dcs.position = Vector2(0.0, -24.0)
	det.add_child(dcs)
	det.body_entered.connect(func(b2: Node) -> void:
		if b2 is CharacterBase:
			body.call("touched"))
	body.add_child(det)
	add_child(body)

# ALCOVA SECRETA sob o piso, entrada pelo catch de um poço recuperável à
# esquerda: gate vertical (64×192) sela o vão; dentro, degrau de escape (@960;
# chão @1056 → degrau 96 → catch 896 → piso 800, tudo ≤ pulo de 118) e o
# colecionável. Teto = piso fino (64px) no nível do corredor; selo à direita.
func _secret_alcove(zone: String, x_in: float, x_end: float, gate_name: String) -> void:
	_floor_seg(zone, x_in, x_end, FLOOR_Y, 1)                        # teto da alcova (800..864)
	_floor_seg(zone, x_in, x_end, FLOOR_Y + 256.0)                   # chão (top 1056)
	_floor_seg(zone, x_end - 64.0, x_end, FLOOR_Y + 64.0, 3)         # selo direito (864..1056)
	_floor_seg(zone, x_in + 64.0, x_in + 128.0, FLOOR_Y + 160.0, 1)  # degrau de escape (top 960)
	var gate := get_node_or_null(gate_name) as Node2D
	if gate:
		gate.position = Vector2(x_in + 32.0, FLOOR_Y + 160.0)        # sela x_in..x_in+64, y864..1056
		var gcs := gate.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if gcs:
			var gsh := RectangleShape2D.new()   # shape próprio (GateShape do tscn é compartilhado)
			gsh.size = Vector2(64.0, 192.0)
			gcs.shape = gsh
		var det := gate.get_node_or_null("HitDetector/CollisionShape2D") as CollisionShape2D
		if det:
			var dsh := RectangleShape2D.new()
			dsh.size = Vector2(192.0, 192.0)    # pega tiros dos dois lados do vão
			det.shape = dsh
			det.position = Vector2.ZERO

# Gates saem do MEIO do caminho (bloqueavam a progressão de quem não tinha a
# habilidade — a fase precisa ser completável em qualquer ordem) e passam a
# selar as alcovas secretas; os colecionáveis gated vão pra dentro delas.
func _relocate_gated_secrets() -> void:
	var helm := get_node_or_null("ArmorZaraHelmet") as Node2D
	if helm:
		helm.position = Vector2(7550.0, 1010.0)
	var spread := get_node_or_null("SpreadZael") as Node2D
	if spread:
		spread.position = Vector2(22770.0, 1010.0)

# Nevasca da Z3 em DOIS ventos alternados (a favor até x15500; CONTRA a partir
# de x15700), cobrindo só o ar acima do piso (y440..800): dentro dos poços não
# venta — são os refúgios da zona.
func _setup_blizzards() -> void:
	var bz := get_node_or_null("Z3_Blizzard") as Node2D
	if bz:
		bz.position = Vector2(14350.0, 620.0)
		bz.set("force", Vector2(180.0, 0.0))
		var cs := bz.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if cs:
			var sh := RectangleShape2D.new()
			sh.size = Vector2(2300.0, 360.0)
			cs.shape = sh
	var bz2 := Area2D.new()
	bz2.name = "Z3_Blizzard2"
	bz2.set_script(load("res://stages/stage_02/blizzard_zone.gd"))
	bz2.collision_layer = 0
	bz2.collision_mask = 2
	bz2.set("force", Vector2(-220.0, 0.0))
	bz2.position = Vector2(16800.0, 620.0)
	var cs2 := CollisionShape2D.new()
	var sh2 := RectangleShape2D.new()
	sh2.size = Vector2(2200.0, 360.0)
	cs2.shape = sh2
	bz2.add_child(cs2)
	add_child(bz2)

# ── Tetos estilo stage 00 (mesma abordagem aplicada no stage 01) ─────────────
# Teto que segue o terreno com folga ~352px (superfícies múltiplas de 64 = fim
# das fileiras bate exato na colisão), abrindo sobre as ilhas/degraus (384) e
# sobre as plataformas de gelo dos espinhos (352). Colisão = SegmentShape2D por
# segmento (sem paredes invisíveis nos degraus); visual = massa de rocha por
# marching-squares até acima do alcance da câmera. Sem teto nos corredores
# CP1-3 (têm o próprio); "MB" = arena do miniboss (fechada, tileset z3).
const _CEIL02_SEGS := {
	"Z1": [
		[   0.0,  512.0, 448.0],
		[ 512.0, 1024.0, 384.0],   # abertura sobre a ilha Z1_FP1
		[1024.0, 1344.0, 448.0],
		[1344.0, 1984.0, 384.0],   # degrau x1400-1900
		[1984.0, 4160.0, 448.0],
		[4160.0, 5312.0, 384.0],   # degrau x4200-4700 + ilha Z1_FP2
		[5312.0, 5600.0, 448.0],
	],
	"Z2": [
		[ 5600.0,  7744.0, 448.0],
		[ 7744.0,  8384.0, 384.0],   # degrau x7800-8300
		[ 8384.0,  8896.0, 352.0],   # plataformas de gelo sobre o campo A (topo 704)
		[ 8896.0, 10600.0, 448.0],
	],
	"MB": [
		[11400.0, 12400.0, 448.0],
	],
	"Z3": [
		[13200.0, 13440.0, 448.0],
		[13440.0, 13888.0, 384.0],   # ilha Z3_FP1
		[13888.0, 15552.0, 448.0],
		[15552.0, 16192.0, 384.0],   # degrau x15600-16100 (Coração)
		[16192.0, 18000.0, 448.0],
	],
	"Z4": [
		[18000.0, 23600.0, 448.0],
	],
	"Boss": [
		[_BOSS_L, _BOSS_R, 448.0],
	],
}
const _CEIL02_TEX := { "Z1": "z1", "Z2": "z2", "MB": "z3", "Z3": "z3", "Z4": "z4", "Boss": "z4" }
const _CEIL02_TOP := 128.0
# Tile de face do teto (1,2) só é opaca na metade de CIMA — a colisão nominal
# (s[2]) fica na borda do tile, onde a arte já é transparente. Sobe só a
# COLISÃO em meio tile; o visual continua no valor nominal (_ceil02_surface_at
# sem essa constante). Ver memória reference_ceiling_collision_gap.
const _CEIL02_FACE_GAP := 32.0

func _build_zone_ceilings02() -> void:
	for zk: String in _CEIL02_SEGS:
		var body := StaticBody2D.new()
		body.name = "%sCeilSegs" % zk
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		for s: Array in _CEIL02_SEGS[zk]:
			var cs := CollisionShape2D.new()
			var sh := SegmentShape2D.new()
			sh.a = Vector2(s[0], (s[2] as float) - _CEIL02_FACE_GAP)
			sh.b = Vector2(s[1], (s[2] as float) - _CEIL02_FACE_GAP)
			cs.shape = sh
			body.add_child(cs)

func _ceil02_surface_at(zk: String, wx: float) -> float:
	for s: Array in _CEIL02_SEGS[zk]:
		if wx >= (s[0] as float) and wx < (s[1] as float):
			return s[2]
	# Fronteira entre zonas: sem isso, o el/er da coluna de borda acha que a
	# zona vizinha "não tem teto ali" e desenha face semi-transparente em vez
	# de preenchimento sólido (ver memória reference_ceiling_zone_boundary).
	for zk2: String in _CEIL02_SEGS:
		if zk2 == zk:
			continue
		for s: Array in _CEIL02_SEGS[zk2]:
			if wx >= (s[0] as float) and wx < (s[1] as float):
				return s[2]
	return -1.0

func _ceil02_solid(zk: String, wx: float, y: float) -> bool:
	var yb := _ceil02_surface_at(zk, wx)
	return yb > 0.0 and y < yb

func _draw() -> void:
	super._draw()
	_draw_zone_ceilings02()

func _draw_zone_ceilings02() -> void:
	var ts := float(_TS)
	var sts := float(_SRC_TS)
	for zk: String in _CEIL02_SEGS:
		var segs: Array = _CEIL02_SEGS[zk]
		var tex := _cached_override_tex(_zone_tile_path(_CEIL02_TEX[zk] as String))
		if tex == null:
			continue
		var x0f: float = segs[0][0]
		var x1f: float = segs[segs.size() - 1][1]
		var x := x0f
		while x < x1f:
			var yb := _ceil02_surface_at(zk, x)
			var y := _CEIL02_TOP
			while y < yb:
				var ed := not _ceil02_solid(zk, x, y + ts)
				var el := not _ceil02_solid(zk, x - ts, y)
				var er := not _ceil02_solid(zk, x + ts, y)
				var tile: Vector2i
				if   ed and el: tile = Vector2i(0, 2)
				elif ed and er: tile = Vector2i(3, 3)
				elif ed:        tile = Vector2i(1, 2)
				elif el:        tile = Vector2i(1, 0)
				elif er:        tile = Vector2i(3, 2)
				elif not _ceil02_solid(zk, x - ts, y + ts): tile = Vector2i(2, 2)
				elif not _ceil02_solid(zk, x + ts, y + ts): tile = Vector2i(3, 1)
				else:           tile = Vector2i(2, 1)
				draw_texture_rect_region(tex, Rect2(x, y, ts, ts),
					Rect2(tile.x * sts, tile.y * sts, sts, sts))
				y += ts
			x += ts

# ── Coberturas dos segredos ───────────────────────────────────────────────────
# As alcovas ficam cobertas de rocha até o gate correspondente quebrar
# (sinal gate_destroyed do ice_gate). Mesmo padrão dos segredos do stage 01.
func _setup_secret_covers() -> void:
	for cfg: Array in [
		["Z2SecretCover", "Z2_IgnarathGate", "z2", Rect2(7364.0, 864.0, 372.0, 192.0)],
		["Z4SecretCover", "Z4_LuxarGate", "z4", Rect2(22664.0, 864.0, 172.0, 192.0)],
	]:
		var cover: Node2D = preload("res://stages/secret_cover.gd").new()
		cover.name = cfg[0]
		cover.tex = _cached_override_tex(_zone_tile_path(cfg[2] as String))
		cover.z_index = 7
		cover.rects = [cfg[3]]
		add_child(cover)
		var gate := get_node_or_null(cfg[1] as String)
		if gate:
			gate.connect("gate_destroyed", func():
				if is_instance_valid(cover):
					cover.queue_free())

# ── Zonas ─────────────────────────────────────────────────────────────────────

# Z1 — gelo escorregadio: ilhas elevadas (fp) onde a derrapagem importa, poços
# recuperáveis e degraus. SubTank livre sobre o degrau (x1500).
func _build_zone1() -> void:
	_floor_seg("Z1", 0.0, 400.0, FLOOR_Y)
	_fp("Z1_FP1", "z1", 400.0, 3, 6, 3)          # 400–1168, plat 592–976 topo 736
	_floor_seg("Z1", 1168.0, 1400.0, FLOOR_Y)
	_step_up("Z1", 1400.0, 1900.0)
	_recoverable_pit("Z1", 1900.0, 3000.0, 2300.0, 2560.0)
	_recoverable_pit("Z1", 3000.0, 4200.0, 3450.0, 3650.0)
	_step_up("Z1", 4200.0, 4700.0)
	_fp("Z1_FP2", "z1", 4700.0, 2, 6, 2)         # 4700–5340, plat 4828–5212 topo 736
	_floor_seg("Z1", 5340.0, 5600.0, FLOOR_Y)

# Z2 — espinhos de gelo (INSTANT KILL, padrão do projeto): dois campos com rota
# segura por plataformas flutuantes — A com duas (folgado), B com uma só no
# meio (preciso) + alcova secreta do Capacete da Zara (Z2_IgnarathGate).
func _build_zone2() -> void:
	_floor_seg("Z2", 5600.0, 6600.0, FLOOR_Y)
	_floor_seg("Z2", 6600.0, 7050.0, FLOOR_Y)
	_floor_seg("Z2", 7050.0, 7300.0, FLOOR_Y + 96.0)     # catch do poço (entrada da alcova)
	_secret_alcove("z2", 7300.0, 7800.0, "Z2_IgnarathGate")
	_step_up("Z2", 7800.0, 8300.0)
	_floor_seg("Z2", 8300.0, 9400.0, FLOOR_Y)
	_ice_spike_field("Z2_SpikesA", 8416.0, 8864.0)       # 14 clusters; 2 plataformas
	_ice_plat("Z2_IcePlat1", "z2", 8540.0, 704.0)
	_ice_plat("Z2_IcePlat2", "z2", 8760.0, 704.0)
	_ice_spike_field("Z2_SpikesB", 9024.0, 9344.0)       # 10 clusters; 1 plataforma central
	_ice_plat("Z2_IcePlat3", "z2", 9184.0, 704.0, 128.0)
	_recoverable_pit("Z2", 9400.0, 10600.0, 9850.0, 10100.0)

# Z3 — nevasca alternada (ver _setup_blizzards; poços = refúgios sem vento) +
# ilha elevada. Coração sobre o degrau, no meio do vento contrário.
func _build_zone3() -> void:
	_floor_seg("Z3", 13200.0, 13376.0, FLOOR_Y)
	_fp("Z3_FP1", "z3", 13376.0, 2, 5, 2)        # 13376–13952, plat 13504–13824 topo 736
	_floor_seg("Z3", 13952.0, 14400.0, FLOOR_Y)
	_recoverable_pit("Z3", 14400.0, 15600.0, 14900.0, 15150.0)
	_step_up("Z3", 15600.0, 16100.0)
	_recoverable_pit("Z3", 16100.0, 17300.0, 16550.0, 16800.0)
	_floor_seg("Z3", 17300.0, 17400.0, FLOOR_Y)   # borda da boca do Poço de Gelo

# Z4 — abismos mortais em PROGRESSÃO: 160 (pulável limpo) → 340 (1 crumble) →
# 400 (2 crumbles encadeados), vidro liso nas faces; BORDAS ÁSPERAS (128px sem
# derrapagem) na aproximação de cada abismo; alcova secreta do Spread sob o
# piso (Z4_LuxarGate). Kill plane da base mata na queda.
func _build_zone4() -> void:
	_build_ice_well()
	_floor_seg("Z4", 18664.0, 19000.0, FLOOR_Y)   # chegada do poço → aproximação do 1º abismo
	_deadly_pit(19000.0, 20200.0, 19190.0, 19350.0)      # vão 160
	_rough_patch("Z4_Rough1a", 19126.0)
	_rough_patch("Z4_Rough1b", 19414.0)
	_floor_seg("Z4", 20200.0, 20900.0, FLOOR_Y)
	_deadly_pit(20900.0, 22200.0, 21080.0, 21420.0)
	_ice_crumble("Z4_Crumble1", 21250.0, FLOOR_Y)
	_rough_patch("Z4_Rough2a", 21016.0)
	_rough_patch("Z4_Rough2b", 21484.0)
	_floor_seg("Z4", 22200.0, 22400.0, FLOOR_Y)
	_floor_seg("Z4", 22400.0, 22600.0, FLOOR_Y + 96.0)   # catch (entrada da alcova)
	_secret_alcove("z4", 22600.0, 22900.0, "Z4_LuxarGate")
	_deadly_pit(22900.0, 23600.0, 23080.0, 23480.0)
	_ice_crumble("Z4_Crumble2", 23180.0, FLOOR_Y)
	_ice_crumble("Z4_Crumble3", 23380.0, FLOOR_Y)
	_rough_patch("Z4_Rough3a", 23016.0)
	_rough_patch("Z4_Rough3b", 23544.0)
	_floor_seg("Z4", 23600.0, _CP3_EXIT_X, FLOOR_Y)      # sob o corredor CP3
	# Termina exatamente em _BOSS_L (24400.0, = _CP3_EXIT_X): a partir daí o
	# piso passa a ser responsabilidade de _build_boss_arena(), sem gap/overlap.

# ── Sala do boss (Cryovex) ────────────────────────────────────────────────────
# Padrão B (porta aberta + trigger, skill new-boss-room): arena aberta,
# aggro por Area2D de entrada — não por distância. Substitui o antigo
# "FINAL PROVISÓRIO" (Z4_EndWall + ProvisionalGoal → GameManager.complete_stage
# direto, sem luta) do spec original de 2026-06-10, que deixou "criar/alterar
# Cryovex" deliberadamente fora de escopo — achado numa auditoria posterior
# (o boss nunca era de fato lutado, quebrando a cadeia de fraquezas do jogo,
# já que a habilidade do Cryovex nunca podia ser desbloqueada).

func _build_boss_arena() -> void:
	_floor_seg("Z4", _BOSS_L, _BOSS_R, FLOOR_Y)
	_solid_block("Z4", "Boss_WallR", _BOSS_R + 32.0, FLOOR_Y - 256.0, 64.0, 512.0)
	_solid_block("Z4", "Boss_WallL_Top", _BOSS_L + 32.0, FLOOR_Y - 448.0, 64.0, 256.0)
	var cryovex := get_node_or_null("Cryovex")
	if cryovex:
		cryovex.visible = true
		cryovex.global_position = Vector2((_BOSS_L + _BOSS_R) * 0.5, FLOOR_Y - 64.0)
		cryovex.set("auto_aggro", false)
		# Sem estes três, BossBase mantém os defaults de arena_left/right/floor
		# (100/1820/500 — coordenadas de outra parte do mapa, ver boss_base.gd:35-37),
		# o que quebraria _clamp_to_arena()/o dash de _do_attack() (bug crítico já
		# visto na Stage 06, ver memória project_stage06_rework).
		cryovex.set("arena_left", _BOSS_L + 64.0)
		cryovex.set("arena_right", _BOSS_R - 64.0)
		cryovex.set("arena_floor", FLOOR_Y)
		var trig := Area2D.new()
		trig.name = "BossRoomTrigger"
		trig.collision_layer = 0
		trig.collision_mask = 2
		trig.position = Vector2((_BOSS_L + _BOSS_R) * 0.5, FLOOR_Y - 150.0)
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(_BOSS_R - _BOSS_L - 200.0, 300.0)
		cs.shape = sh
		trig.add_child(cs)
		add_child(trig)
		trig.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBase:
				cryovex.call("aggro"))
		# NÃO chamar $HUD.connect_to_boss(cryovex) aqui: Cryovex já existe como
		# filho direto da cena (.tscn, visible=false) ANTES de super._ready()
		# rodar — o loop genérico de stage_scene.gd::_ready() já pega esse nó e
		# faz esse wiring (player, HUD, boss_aggro/boss_intro_ended) de graça.
		# Repetir connect_to_boss aqui conectaria os sinais da HUD duas vezes no
		# mesmo callable (erro "already connected" em runtime).
		if cryovex.has_signal("boss_defeated"):
			cryovex.connect("boss_defeated", _on_boss_defeated)

func _on_boss_defeated(_ability_id: String) -> void:
	GameManager.save_game()

# ── POÇO DE GELO (set-piece vertical entre Z3 e Z4) ──────────────────────────
# "U" de 1280px de profundidade (x17400–18728): DESCE pelo shaft esquerdo
# derrapando entre 4 plataformas geladas alternadas nas paredes (a 2ª tem
# espinhos embaixo — instant kill), CHECKPOINT (índice 3) na base, e SOBE pelo
# shaft direito num UPDRAFT de nevasca (vento vertical; one-way — cair contra o
# updraft é impossível). Paredes lisas (no_wall_grab: gelo). Resolve o buraco
# de 11k px sem checkpoint entre o CP2 e o fim, e dá verticalidade à fase.
#
#   Z3 ─┐17400      17720┌────18344┐      18664┌─ Z4
#        │  DESCIDA  │ bloco central │ UPDRAFT │
#        │ p1▄       │   (sólido)    │    ▲    │
#        │       ▄p2*│               │    ▲    │
#        │ p3▄       │               │    ▲    │
#        │       ▄p4 └──────1888     │    ▲    │
#        │        BASE + CHECKPOINT (2080)     │
#        └──────────────────────────────────────┘
func _build_ice_well() -> void:
	const W_TOP := 800.0        # nível do corredor
	const W_BASE := 2080.0      # piso da base
	const W_MID_BOT := 1888.0   # fundo do bloco central (pé-direito 192 na base)
	# Paredes externas (gelo liso) + bloco central + piso da base
	for w: Array in [
		["Z4_WellWallL", 17368.0, (W_TOP + W_BASE) * 0.5, 64.0, W_BASE - W_TOP],
		["Z4_WellWallR", 18696.0, (W_TOP + W_BASE) * 0.5, 64.0, W_BASE - W_TOP],
		["Z4_WellCore", 18032.0, (W_TOP + W_MID_BOT) * 0.5, 624.0, W_MID_BOT - W_TOP],
	]:
		var b := StaticBody2D.new()
		b.name = w[0]
		b.collision_layer = 1
		b.collision_mask = 0
		b.position = Vector2(w[1], w[2])
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(w[3], w[4])
		cs.shape = sh
		b.add_child(cs)
		b.add_to_group("no_wall_grab")   # gelo liso: sem wall-grab no poço
		b.set_meta("lava_override", _zone_tile_path("z4"))
		add_child(b)
	_floor_seg("Z4", 17336.0, 18728.0, W_BASE)               # piso da base
	# Plataformas geladas da descida (alternadas; quedas de 256px)
	_ice_plat("Z4_WellPlat1", "z4", 17480.0, 1056.0)         # esquerda
	_ice_plat("Z4_WellPlat2", "z4", 17640.0, 1312.0)         # direita (face do bloco)
	_ice_plat("Z4_WellPlat3", "z4", 17480.0, 1568.0)         # esquerda
	_ice_plat("Z4_WellPlat4", "z4", 17640.0, 1824.0)         # direita
	# Espinhos SOB a WellPlat2 (instant kill): punem raspar por baixo dela na
	# queda — 1 cluster de 32px (escala nativa) perto da face do bloco. Tips
	# pra baixo via rotação (nunca Rect2 negativo — regra do web).
	var wsp: Area2D = load("res://stages/stage_02/ice_spikes.gd").new()
	wsp.name = "Z4_WellSpikes"
	wsp.collision_layer = 0
	wsp.collision_mask = 2
	wsp.position = Vector2(17592.0, 1360.0)
	var wsp_cs := CollisionShape2D.new()
	var wsp_sh := RectangleShape2D.new()
	wsp_sh.size = Vector2(32.0, 32.0)
	wsp_cs.shape = wsp_sh
	wsp.add_child(wsp_cs)
	add_child(wsp)
	var wsp_vis := Sprite2D.new()
	wsp_vis.name = "Z4_WellSpikesVis"
	wsp_vis.texture = _SPIKES_TEX
	wsp_vis.centered = true
	wsp_vis.region_enabled = true
	wsp_vis.region_rect = Rect2(0.0, 0.0, 32.0, 32.0)
	wsp_vis.scale = Vector2(1.0, 1.0)
	wsp_vis.rotation = PI
	wsp_vis.modulate = _ICE_TINT
	wsp_vis.position = Vector2(17592.0, 1360.0)
	wsp_vis.z_index = 5
	add_child(wsp_vis)
	# Checkpoint da base (índice 3; o corredor CP3 passa a 4)
	var cp: Area2D = preload("res://stages/checkpoint.tscn").instantiate()
	cp.name = "WellCheckpoint"
	cp.set("checkpoint_index", 3)
	cp.position = Vector2(18032.0, 1952.0)
	var cp_cs := cp.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cp_cs:
		var cp_rect := RectangleShape2D.new()
		cp_rect.size = Vector2(64.0, 256.0)
		cp_cs.shape = cp_rect
	add_child(cp)
	# Updraft de nevasca no shaft direito (sobe de volta ao corredor)
	var up: Area2D = preload("res://stages/stage_02/blizzard_zone.gd").new()
	up.name = "Z4_WellUpdraft"
	up.set("force", Vector2(0.0, -1300.0))
	up.collision_layer = 0
	up.collision_mask = 2
	up.position = Vector2(18504.0, 1470.0)
	var ucs := CollisionShape2D.new()
	var ush := RectangleShape2D.new()
	ush.size = Vector2(288.0, 1220.0)
	ucs.shape = ush
	up.add_child(ucs)
	add_child(up)

# Borda áspera: faixa de 128px de cascalho que desativa a derrapagem — colada
# na beirada dos abismos mortais (aproximação do pulo com tração normal).
func _rough_patch(n: String, cx: float) -> void:
	var p: Area2D = preload("res://stages/stage_02/rough_patch.gd").new()
	p.name = n
	p.collision_layer = 0
	p.collision_mask = 2
	p.position = Vector2(cx, FLOOR_Y - 24.0)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(128.0, 48.0)
	cs.shape = sh
	p.add_child(cs)
	add_child(p)

# Debug ?zone=N: spawna o player no início de uma zona (calibrar trechos isolados).
func _zone_spawn(zone: int) -> Vector2:
	match zone:
		1: return Vector2(200.0, 720.0)
		2: return Vector2(5700.0, 720.0)
		3: return Vector2(13300.0, 720.0)
		4: return Vector2(18100.0, 720.0)
		5: return Vector2(12500.0, 720.0)
		_: return Vector2.ZERO
	return Vector2.ZERO
