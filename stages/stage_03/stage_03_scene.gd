# stages/stage_03/stage_03_scene.gd — Voltrix (raio)
# Rebuild completo no molde do stage 02: estende a base stage_scene.gd, zonas
# temáticas construídas em código, 3 corredores com checkpoint e arena de boss
# no final. Identidade elétrica:
#   Z1 condutores — trilhos eletrificados pulsantes (atravessa na janela OFF)
#   Z2 trilhos    — plataformas móveis sobre abismos mortais com vidro
#   Z3 tempestade — raios com aviso caindo do teto; poços = refúgios
#   Z4 capacitores — abismos com plataforma eletrificada + trilhos rápidos
extends "res://stages/stage_scene.gd"

const _SHOCK_RAIL := preload("res://stages/stage_03/shock_rail.gd")
const _BOLT := preload("res://stages/stage_03/bolt_strike.gd")
const _MOVPLAT := preload("res://stages/stage_01/moving_platform.gd")
const _ARC := {
	"guard":   preload("res://characters/enemies/stage_03/enemy_volt_guard.tscn"),
	"runner":  preload("res://characters/enemies/stage_03/enemy_rail_runner.tscn"),
	"jumper":  preload("res://characters/enemies/stage_03/enemy_static_interceptor.tscn"),
	"coil":    preload("res://characters/enemies/stage_03/enemy_tesla_coil.tscn"),
	"turret":  preload("res://characters/enemies/stage_03/enemy_arc_turret.tscn"),
	"kite":    preload("res://characters/enemies/stage_03/enemy_storm_kite.tscn"),
	"hawk":    preload("res://characters/enemies/stage_03/enemy_thunder_hawklet.tscn"),
	"orbiter": preload("res://characters/enemies/stage_03/enemy_arc_orbiter.tscn"),
	"relay":   preload("res://characters/enemies/stage_03/enemy_storm_relay.tscn"),
}

const FLOOR_Y := 800.0
const _CORR_INTERIOR := 192.0

const _CP1_ENTRY_X := 9600.0
const _CP1_EXIT_X := 10400.0
const _CP2_ENTRY_X := 15200.0
const _CP2_EXIT_X := 16000.0
const _CP3_ENTRY_X := 19200.0
const _CP3_EXIT_X := 20000.0
const _BOSS_L := 20000.0
const _BOSS_R := 21400.0

# Roster elétrico por zona: kind (chave de _ARC) → posições. Progressão:
# Z1 ensina guard/kite/jumper e apresenta a coil no fim; Z2 = runners e
# torres sobre os vãos; Z3 = relays negando o ar sob os raios; Z4 = tudo junto.
const Z1_ENEMIES := {
	"guard":  [Vector2(600, 760), Vector2(2200, 760)],
	"jumper": [Vector2(3600, 760)],
	"kite":   [Vector2(1000, 600), Vector2(2500, 560)],
	"coil":   [Vector2(4300, 760)],
}
const Z2_ENEMIES := {
	"guard":   [Vector2(5000, 760)],
	"runner":  [Vector2(8500, 760), Vector2(9300, 760)],
	"orbiter": [Vector2(5900, 560), Vector2(7900, 540)],
	"hawk":    [Vector2(9000, 580)],
	"turret":  [Vector2(7050, 700)],   # sobre a ilha, cobrindo o 2º vão (face -1 default)
}
const Z3_ENEMIES := {
	"guard":  [Vector2(10600, 760), Vector2(13450, 760)],
	"relay":  [Vector2(11200, 560), Vector2(12700, 540)],
	"kite":   [Vector2(14800, 560)],
	"jumper": [Vector2(12500, 760)],
	"coil":   [Vector2(14500, 760)],
}
const Z4_ENEMIES := {
	"guard":  [Vector2(16100, 760)],
	"runner": [Vector2(17900, 760)],
	"turret": [Vector2(16450, 700)],   # sobre a ilha do Glaive
	"hawk":   [Vector2(17100, 540), Vector2(18600, 560)],
	"relay":  [Vector2(18950, 560)],
	"coil":   [Vector2(17700, 760)],
}

var _door_tex: Texture2D = null
var _glass_tex: Texture2D = null
var _camera_locked := false
var _camera_target := Vector2.ZERO
var _camera_zoom_tgt := 2.0
var _zone1_enemies: Array[Node] = []
var _zone2_enemies: Array[Node] = []
var _zone3_enemies: Array[Node] = []
var _zone4_enemies: Array[Node] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if StageManager.current_stage_id < 0:
		StageManager.current_stage_id = 3
	super._ready()
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_glass_tex = load("res://stages/stage_03/stage_03_glass.png") as Texture2D
	_setup_corridors()
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_boss_arena()
	_build_zone_ceilings03()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _zone_tile_path(zone: String) -> String:
	# Case EXATO do arquivo (PCK web é case-sensitive). Arena do boss usa z4.
	var z := zone.to_lower()
	if z == "boss":
		z = "z4"
	return "res://stages/stage_03/Stage_03T_%s.png" % z

# Câmera: trava de corredor tem prioridade; fora dela, segue o player via base.
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

# ── Corredores (checkpoints) ─────────────────────────────────────────────────

func _setup_corridors() -> void:
	_make_corridor("CP1", _CP1_ENTRY_X, _CP1_EXIT_X, 1)
	_make_corridor("CP2", _CP2_ENTRY_X, _CP2_EXIT_X, 2)
	_make_corridor("CP3", _CP3_ENTRY_X, _CP3_EXIT_X, 3)

func _make_corridor(name_prefix: String, entry_x: float, exit_x: float, checkpoint_index: int) -> CorridorSection:
	var width := exit_x - entry_x
	var corr := CorridorSection.new()
	corr.name = name_prefix
	var zone := "z2" if checkpoint_index == 1 else ("z3" if checkpoint_index == 2 else "z4")
	corr.tileset = _cached_override_tex(_zone_tile_path(zone))
	corr.glass_tex = _glass_tex
	corr.door_tex = _door_tex
	var floor_cy := FLOOR_Y + 32.0
	var ceil_cy := FLOOR_Y - _CORR_INTERIOR - 32.0
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
	corr.save_checkpoint = true
	corr.heal_on_entry = false
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

# ── Spawn de inimigos por zona ───────────────────────────────────────────────

func _setup_zone_triggers() -> void:
	_make_zone_trigger("Z2Trigger", Rect2(4800, 300, 4800, 900), 2)
	_make_zone_trigger("Z3Trigger", Rect2(_CP1_EXIT_X, 300, 4800, 900), 3)
	_make_zone_trigger("Z4Trigger", Rect2(_CP2_EXIT_X, 300, 3200, 900), 4)

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
			_spawn_zone_enemies(zone))
	add_child(area)

func _spawn_zone_enemies(zone: int) -> void:
	if DebugBoot.no_enemies:
		return
	var target: Array[Node]
	var table: Dictionary
	match zone:
		1:
			target = _zone1_enemies
			table = Z1_ENEMIES
		2:
			target = _zone2_enemies
			table = Z2_ENEMIES
		3:
			target = _zone3_enemies
			table = Z3_ENEMIES
		4:
			target = _zone4_enemies
			table = Z4_ENEMIES
		_:
			return
	if not target.is_empty():
		return
	for kind: String in table:
		var scene: PackedScene = _ARC[kind]
		for pos in table[kind]:
			var e := scene.instantiate()
			(e as Node2D).global_position = pos
			add_child(e)
			target.append(e)

# ── Helpers de terreno (mesmo vocabulário do stage 02) ───────────────────────

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

func _glass_wall(x_center: float, top_y: float, height: float) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = "Z_Glass_%d" % int(x_center)
	b.collision_layer = 1
	b.collision_mask = 0
	b.add_to_group("no_wall_grab")
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64.0, height)
	cs.shape = shape
	cs.position = Vector2(x_center, top_y + height * 0.5)
	b.add_child(cs)
	b.set_meta("tileset_override", "res://stages/stage_03/stage_03_glass.png")
	add_child(b)
	return b

func _recoverable_pit(zone: String, left_x: float, right_x: float, gap_x0: float, gap_x1: float, depth: float = 96.0) -> void:
	_floor_seg(zone, left_x, gap_x0, FLOOR_Y)
	_floor_seg(zone, gap_x1, right_x, FLOOR_Y)
	_floor_seg(zone, gap_x0, gap_x1, FLOOR_Y + depth)

func _deadly_gap(zone: String, left_x: float, right_x: float, gap_x0: float, gap_x1: float) -> void:
	_floor_seg(zone, left_x, gap_x0, FLOOR_Y)
	_floor_seg(zone, gap_x1, right_x, FLOOR_Y)
	_glass_wall(gap_x0 + 32.0, FLOOR_Y, 320.0)
	_glass_wall(gap_x1 - 32.0, FLOOR_Y, 320.0)

func _step_up(zone: String, x0: float, x1: float, rise: float = 64.0) -> void:
	_floor_seg(zone, x0, x1, FLOOR_Y - rise)

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

# Plataforma fixa (pouso sólido no meio de um vão).
func _fixed_plat(n: String, zone: String, cx: float, top_y: float, w: float = 128.0) -> StaticBody2D:
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
	return b

# Plataforma móvel horizontal (AnimatableBody2D carrega o player — regra do
# projeto: StaticBody2D movido não carrega o rider).
func _mov_plat(n: String, zone: String, cx: float, top_y: float, dist: float, speed: float, w: float = 160.0) -> void:
	var p: AnimatableBody2D = _MOVPLAT.new()
	p.name = n
	p.set("move_distance", dist)
	p.set("speed", speed)
	p.collision_layer = 1
	p.collision_mask = 0
	p.position = Vector2(cx, top_y + 16.0)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, 32.0)
	cs.shape = sh
	p.add_child(cs)
	p.set_meta("platform_override", _zone_tile_path(zone))
	add_child(p)

func _shock_rail(n: String, cx: float, surface_y: float, width: float, phase: float = 0.0,
		on_t: float = 1.2, off_t: float = 1.6) -> void:
	var r: Area2D = _SHOCK_RAIL.new()
	r.name = n
	r.set("width", width)
	r.set("phase_offset", phase)
	r.set("on_time", on_t)
	r.set("off_time", off_t)
	r.position = Vector2(cx, surface_y - 16.0)
	add_child(r)

func _bolt(n: String, x: float, surface_y: float, phase: float = 0.0, height: float = 340.0) -> void:
	var bolt: Area2D = _BOLT.new()
	bolt.name = n
	bolt.set("column_height", height)
	bolt.set("phase_offset", phase)
	bolt.position = Vector2(x, surface_y)
	add_child(bolt)

# ── Zonas ─────────────────────────────────────────────────────────────────────

# Z1 — condutores: trilhos eletrificados pulsantes no piso (ensino: 1 isolado,
# depois 2 alternados) + ilha elevada.
func _build_zone1() -> void:
	_floor_seg("Z1", 0.0, 1200.0, FLOOR_Y)
	_fp("Z1_FP1", "z1", 1200.0, 3, 5, 3)         # 1200–1904, plat 1392–1712 topo 736
	_floor_seg("Z1", 1904.0, 2600.0, FLOOR_Y)
	_shock_rail("Z1_Rail1", 2260.0, FLOOR_Y, 320.0)
	_recoverable_pit("Z1", 2600.0, 3400.0, 2900.0, 3100.0)
	_floor_seg("Z1", 3400.0, 4800.0, FLOOR_Y)
	_shock_rail("Z1_Rail2", 3760.0, FLOOR_Y, 320.0, 0.0)
	_shock_rail("Z1_Rail3", 4360.0, FLOOR_Y, 320.0, 1.65)   # alternado com o Rail2

# Z2 — trilhos: plataformas móveis sobre abismos mortais (vidro nas faces) +
# ilha com o Torso do Zael suspenso no ápice do pulo.
func _build_zone2() -> void:
	_floor_seg("Z2", 4800.0, 5800.0, FLOOR_Y)
	# vão mortal 5800–6600 (800px): travessia pelas duas plataformas móveis
	_floor_seg("Z2", 6600.0, 6800.0, FLOOR_Y)
	_glass_wall(5832.0, FLOOR_Y, 320.0)
	_glass_wall(6568.0, FLOOR_Y, 320.0)
	_mov_plat("Z2_Mov1", "z2", 6050.0, 752.0, 260.0, 90.0)
	_mov_plat("Z2_Mov2", "z2", 6350.0, 752.0, 260.0, 70.0)
	_fp("Z2_FP1", "z2", 6800.0, 2, 4, 2)         # 6800–7312, plat 6928–7184 topo 736
	_floor_seg("Z2", 7312.0, 7400.0, FLOOR_Y)
	_glass_wall(7432.0, FLOOR_Y, 320.0)
	_glass_wall(8368.0, FLOOR_Y, 320.0)
	_mov_plat("Z2_Mov3", "z2", 7900.0, 752.0, 560.0, 110.0)
	_floor_seg("Z2", 8400.0, 9600.0, FLOOR_Y)
	_shock_rail("Z2_Rail1", 8760.0, FLOOR_Y, 320.0)

# Z3 — tempestade: raios com aviso ao longo dos trechos abertos; os poços
# recuperáveis são os refúgios (o raio não alcança dentro deles).
func _build_zone3() -> void:
	_floor_seg("Z3", 10400.0, 11600.0, FLOOR_Y)
	_bolt("Z3_Bolt1", 11000.0, FLOOR_Y, 0.0)
	_bolt("Z3_Bolt2", 11350.0, FLOOR_Y, 1.1)
	_recoverable_pit("Z3", 11600.0, 12400.0, 11900.0, 12100.0)
	_floor_seg("Z3", 12400.0, 12800.0, FLOOR_Y)
	_step_up("Z3", 12800.0, 13300.0)
	_floor_seg("Z3", 13300.0, 13600.0, FLOOR_Y)
	_bolt("Z3_Bolt3", 12600.0, FLOOR_Y, 0.4)
	_bolt("Z3_Bolt4", 13050.0, FLOOR_Y - 64.0, 1.6, 300.0)   # sobre o degrau (Coração)
	_bolt("Z3_Bolt5", 13500.0, FLOOR_Y, 0.9)
	_recoverable_pit("Z3", 13600.0, 14400.0, 13900.0, 14100.0)
	_floor_seg("Z3", 14400.0, 15200.0, FLOOR_Y)
	_bolt("Z3_Bolt6", 14750.0, FLOOR_Y, 0.2)

# Z4 — capacitores: abismo com plataforma ELETRIFICADA no meio (cruza na janela
# desligada), trilho rápido e vão pulável limpo no fim.
func _build_zone4() -> void:
	_floor_seg("Z4", 16000.0, 16200.0, FLOOR_Y)
	_fp("Z4_FP1", "z4", 16200.0, 2, 4, 2)        # 16200–16712, plat 16328–16584 topo 736
	_floor_seg("Z4", 16712.0, 17000.0, FLOOR_Y)
	_glass_wall(17032.0, FLOOR_Y, 320.0)
	_glass_wall(17248.0, FLOOR_Y, 320.0)
	_fixed_plat("Z4_ShockPlat", "z4", 17140.0, FLOOR_Y)          # pouso no meio do vão
	_shock_rail("Z4_PlatRail", 17140.0, FLOOR_Y, 128.0, 0.6, 0.9, 1.3)   # a plataforma pulsa
	_floor_seg("Z4", 17280.0, 18400.0, FLOOR_Y)
	_shock_rail("Z4_Rail1", 18160.0, FLOOR_Y, 320.0, 0.0, 1.4, 1.2)
	_deadly_gap("Z4", 18400.0, 19200.0, 18510.0, 18690.0)
	# nota: _deadly_gap acima já cria os pisos 18400–18510 e 18690–19200

# Arena do Voltrix no final (após o CP3): sala fechada; a luta começa pelo
# gatilho de ENTRADA (auto_aggro off — regra do projeto: boss não acorda por
# distância através da parede).
func _build_boss_arena() -> void:
	_floor_seg("Boss", _BOSS_L, _BOSS_R, FLOOR_Y)
	_solid_block("boss", "Boss_WallR", _BOSS_R + 32.0, 560.0, 64.0, 480.0)    # y320–800
	_solid_block("boss", "Boss_WallL_Top", _BOSS_L + 32.0, 448.0, 64.0, 256.0) # acima do corredor
	var volt := get_node_or_null("Voltrix")
	if volt:
		volt.set("auto_aggro", false)
		var trig := Area2D.new()
		trig.name = "BossRoomTrigger"
		trig.collision_layer = 0
		trig.collision_mask = 2
		trig.position = Vector2((_BOSS_L + _BOSS_R) * 0.5, 650.0)
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(_BOSS_R - _BOSS_L - 200.0, 300.0)
		cs.shape = sh
		trig.add_child(cs)
		add_child(trig)
		trig.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBase:
				volt.call("aggro"))

# ── Tetos estilo stage 00 ────────────────────────────────────────────────────
# Folga ~352px (superfície 448), abrindo p/ 384 sobre ilhas/degraus. Sem teto
# nos corredores (têm o próprio). Arena do boss fechada em 384.
const _CEIL03_SEGS := {
	"Z1": [
		[   0.0, 1344.0, 448.0],
		[1344.0, 1760.0, 384.0],   # ilha Z1_FP1
		[1760.0, 4800.0, 448.0],
	],
	"Z2": [
		[4800.0, 6880.0, 448.0],
		[6880.0, 7232.0, 384.0],   # ilha Z2_FP1
		[7232.0, 9600.0, 448.0],
	],
	"Z3": [
		[10400.0, 12736.0, 448.0],
		[12736.0, 13376.0, 384.0],  # degrau do Coração
		[13376.0, 15200.0, 448.0],
	],
	"Z4": [
		[16000.0, 16256.0, 448.0],
		[16256.0, 16640.0, 384.0],  # ilha Z4_FP1
		[16640.0, 19200.0, 448.0],
	],
	"Boss": [
		[20000.0, 21400.0, 384.0],
	],
}
const _CEIL03_TEX := { "Z1": "z1", "Z2": "z2", "Z3": "z3", "Z4": "z4", "Boss": "z4" }
const _CEIL03_TOP := 128.0
# Ver stage_02_scene.gd::_CEIL02_FACE_GAP / memória reference_ceiling_collision_gap.
const _CEIL03_FACE_GAP := 32.0

func _build_zone_ceilings03() -> void:
	for zk: String in _CEIL03_SEGS:
		var body := StaticBody2D.new()
		body.name = "%sCeilSegs" % zk
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		for s: Array in _CEIL03_SEGS[zk]:
			var cs := CollisionShape2D.new()
			var sh := SegmentShape2D.new()
			sh.a = Vector2(s[0], (s[2] as float) - _CEIL03_FACE_GAP)
			sh.b = Vector2(s[1], (s[2] as float) - _CEIL03_FACE_GAP)
			cs.shape = sh
			body.add_child(cs)

func _ceil03_surface_at(zk: String, wx: float) -> float:
	for s: Array in _CEIL03_SEGS[zk]:
		if wx >= (s[0] as float) and wx < (s[1] as float):
			return s[2]
	# Ver memória reference_ceiling_zone_boundary.
	for zk2: String in _CEIL03_SEGS:
		if zk2 == zk:
			continue
		for s: Array in _CEIL03_SEGS[zk2]:
			if wx >= (s[0] as float) and wx < (s[1] as float):
				return s[2]
	return -1.0

func _ceil03_solid(zk: String, wx: float, y: float) -> bool:
	var yb := _ceil03_surface_at(zk, wx)
	return yb > 0.0 and y < yb

func _draw() -> void:
	super._draw()
	_draw_zone_ceilings03()

func _draw_zone_ceilings03() -> void:
	var ts := float(_TS)
	var sts := float(_SRC_TS)
	for zk: String in _CEIL03_SEGS:
		var segs: Array = _CEIL03_SEGS[zk]
		var tex := _cached_override_tex(_zone_tile_path(_CEIL03_TEX[zk] as String))
		if tex == null:
			continue
		var x0f: float = segs[0][0]
		var x1f: float = segs[segs.size() - 1][1]
		var x := x0f
		while x < x1f:
			var yb := _ceil03_surface_at(zk, x)
			var y := _CEIL03_TOP
			while y < yb:
				var ed := not _ceil03_solid(zk, x, y + ts)
				var el := not _ceil03_solid(zk, x - ts, y)
				var er := not _ceil03_solid(zk, x + ts, y)
				var tile: Vector2i
				if   ed and el: tile = Vector2i(0, 2)
				elif ed and er: tile = Vector2i(3, 3)
				elif ed:        tile = Vector2i(1, 2)
				elif el:        tile = Vector2i(1, 0)
				elif er:        tile = Vector2i(3, 2)
				elif not _ceil03_solid(zk, x - ts, y + ts): tile = Vector2i(2, 2)
				elif not _ceil03_solid(zk, x + ts, y + ts): tile = Vector2i(3, 1)
				else:           tile = Vector2i(2, 1)
				draw_texture_rect_region(tex, Rect2(x, y, ts, ts),
					Rect2(tile.x * sts, tile.y * sts, sts, sts))
				y += ts
			x += ts

# Debug ?zone=N: spawna o player no início de uma zona.
func _zone_spawn(zone: int) -> Vector2:
	match zone:
		1: return Vector2(200.0, 720.0)
		2: return Vector2(4900.0, 720.0)
		3: return Vector2(10500.0, 720.0)
		4: return Vector2(16100.0, 720.0)
		5: return Vector2(20100.0, 720.0)   # arena do boss
		_: return Vector2.ZERO
	return Vector2.ZERO
