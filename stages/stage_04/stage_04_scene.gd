# stages/stage_04/stage_04_scene.gd — Gravitus (gravidade)
# Rebuild completo no molde dos stages 02/03: estende a base stage_scene.gd,
# zonas construídas em código, 3 corredores com checkpoint e arena de boss.
# Identidade gravitacional:
#   Z1 poços de gravidade — sucção radial perto de poços/abismos + alcova secreta
#   Z2 câmaras de empuxo  — baixa gravidade: flutua sobre abismos e sobe a torre
#   Z3 esmagadores        — blocos que caem do teto em ciclos; poços = refúgios
#   Z4 singularidade      — sucção sobre abismo com pouso central + esmagador
extends "res://stages/stage_scene.gd"

const _WELL := preload("res://stages/stage_04/grav_well_zone.gd")
const _LIFT := preload("res://stages/stage_04/lift_zone.gd")
const _CRUSHER := preload("res://stages/stage_04/crusher.gd")
const _GATE := preload("res://stages/stage_02/ice_gate.gd")       # gate genérico (required_ability)
const _COVER := preload("res://stages/secret_cover.gd")
const _GRAV := {
	"guard":   preload("res://characters/enemies/stage_04/enemy_grav_guard.tscn"),
	"brute":   preload("res://characters/enemies/stage_04/enemy_mass_brute.tscn"),
	"mine":    preload("res://characters/enemies/stage_04/enemy_gravity_mine.tscn"),
	"pylon":   preload("res://characters/enemies/stage_04/enemy_crush_pylon.tscn"),
	"turret":  preload("res://characters/enemies/stage_04/enemy_singularity_turret.tscn"),
	"well":    preload("res://characters/enemies/stage_04/enemy_grav_well.tscn"),
	"drone":   preload("res://characters/enemies/stage_04/enemy_void_drone.tscn"),
	"orbiter": preload("res://characters/enemies/stage_04/enemy_debris_orbiter.tscn"),
	"mauler":  preload("res://characters/enemies/stage_04/enemy_orbit_mauler.tscn"),
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

# Roster gravitacional por zona: kind (chave de _GRAV) → posições.
const Z1_ENEMIES := {
	"guard": [Vector2(700, 760), Vector2(2200, 760)],
	"mine":  [Vector2(1500, 600)],
	"drone": [Vector2(3800, 560)],
	"well":  [Vector2(3250, 760)],   # sobre o teto da alcova — guarda o segredo
}
const Z2_ENEMIES := {
	"guard":   [Vector2(6400, 760)],
	"mauler":  [Vector2(5900, 500), Vector2(8100, 500)],   # interceptam a flutuação nos vãos
	"orbiter": [Vector2(6800, 560)],
	"pylon":   [Vector2(8700, 760)],
	"mine":    [Vector2(9300, 600)],
}
const Z3_ENEMIES := {
	"guard":   [Vector2(10600, 760), Vector2(14500, 760)],
	"brute":   [Vector2(12400, 760)],
	"drone":   [Vector2(11200, 560)],
	"orbiter": [Vector2(13500, 540)],
	"mine":    [Vector2(14000, 620)],   # paira sobre o poço-refúgio
}
const Z4_ENEMIES := {
	"brute":  [Vector2(16300, 760)],
	"well":   [Vector2(16600, 760)],    # soma sucção com o poço do abismo
	"mauler": [Vector2(17400, 520)],
	"drone":  [Vector2(16950, 540)],
	"turret": [Vector2(18900, 740)],
	"pylon":  [Vector2(18700, 760)],
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
		StageManager.current_stage_id = 4
	super._ready()
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_glass_tex = load("res://stages/stage_04/stage_04_glass.png") as Texture2D
	_setup_corridors()
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_boss_arena()
	_build_zone_ceilings04()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _zone_tile_path(zone: String) -> String:
	# Case EXATO do arquivo (PCK web é case-sensitive). Arena do boss usa z4.
	var z := zone.to_lower()
	if z == "boss":
		z = "z4"
	return "res://stages/stage_04/Stage_04T_%s.png" % z

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
		var scene: PackedScene = _GRAV[kind]
		for pos in table[kind]:
			var e := scene.instantiate()
			(e as Node2D).global_position = pos
			add_child(e)
			target.append(e)

# ── Helpers de terreno (mesmo vocabulário dos stages 02/03) ──────────────────

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
	b.set_meta("tileset_override", "res://stages/stage_04/stage_04_glass.png")
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

func _well_zone(n: String, pos: Vector2, pull: float = 220.0, radius: float = 240.0) -> void:
	var w: Area2D = _WELL.new()
	w.name = n
	w.set("pull_strength", pull)
	w.set("radius", radius)
	w.position = pos
	add_child(w)

func _lift(n: String, pos: Vector2, size: Vector2, force: float = 700.0) -> void:
	var l: Area2D = _LIFT.new()
	l.name = n
	l.set("lift_force", force)
	l.set("size", size)
	l.position = pos
	add_child(l)

func _crusher(n: String, cx: float, wait_t: float = 1.2) -> void:
	# Bloco 128×96 em repouso embutido no teto (surface 448): centro y 496;
	# desce 260 → base a ~804 (esmaga até o chão).
	var c: AnimatableBody2D = _CRUSHER.new()
	c.name = n
	c.set("wait_time", wait_t)
	c.collision_layer = 1
	c.collision_mask = 0
	c.position = Vector2(cx, 496.0)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(128.0, 96.0)
	cs.shape = sh
	c.add_child(cs)
	c.set_meta("tileset_override", _zone_tile_path("z3"))
	add_child(c)

# ALCOVA SECRETA sob o piso (padrão do stage 02), selada por gate de habilidade
# construído em código (ice_gate genérico) e coberta por SecretCover.
func _secret_alcove(zone: String, x_in: float, x_end: float, gate_name: String, required: String) -> void:
	_floor_seg(zone, x_in, x_end, FLOOR_Y, 1)                        # teto da alcova (800..864)
	_floor_seg(zone, x_in, x_end, FLOOR_Y + 256.0)                   # chão (top 1056)
	_floor_seg(zone, x_end - 64.0, x_end, FLOOR_Y + 64.0, 3)         # selo direito
	_floor_seg(zone, x_in + 64.0, x_in + 128.0, FLOOR_Y + 160.0, 1)  # degrau de escape (top 960)
	var gate := StaticBody2D.new()
	gate.name = gate_name
	gate.set_script(_GATE)
	gate.set("required_ability", required)
	gate.collision_layer = 1
	gate.collision_mask = 0
	gate.position = Vector2(x_in + 32.0, FLOOR_Y + 160.0)
	var gcs := CollisionShape2D.new()
	var gsh := RectangleShape2D.new()
	gsh.size = Vector2(64.0, 192.0)
	gcs.shape = gsh
	gate.add_child(gcs)
	var det := Area2D.new()
	det.name = "HitDetector"
	det.collision_layer = 0
	det.collision_mask = 8
	var dcs := CollisionShape2D.new()
	var dsh := RectangleShape2D.new()
	dsh.size = Vector2(192.0, 192.0)
	dcs.shape = dsh
	det.add_child(dcs)
	gate.add_child(det)
	gate.set_meta("lava_override", _zone_tile_path(zone))
	add_child(gate)
	var cover: Node2D = _COVER.new()
	cover.name = gate_name + "Cover"
	cover.set("tex", _cached_override_tex(_zone_tile_path(zone)))
	cover.z_index = 7
	cover.set("rects", [Rect2(x_in + 64.0, FLOOR_Y + 64.0, x_end - x_in - 128.0, 192.0)])
	add_child(cover)
	gate.connect("gate_destroyed", func():
		if is_instance_valid(cover):
			cover.queue_free())

# ── Zonas ─────────────────────────────────────────────────────────────────────

# Z1 — poços de gravidade: sucção radial perto do abismo + alcova secreta do
# Rapid (gate exige a habilidade do Voltrix — revisita).
func _build_zone1() -> void:
	_floor_seg("Z1", 0.0, 1200.0, FLOOR_Y)
	_fp("Z1_FP1", "z1", 1200.0, 3, 5, 3)          # 1200–1904, plat 1392–1712 topo 736
	_floor_seg("Z1", 1904.0, 2600.0, FLOOR_Y)
	_floor_seg("Z1", 2600.0, 2900.0, FLOOR_Y)
	_floor_seg("Z1", 2900.0, 3100.0, FLOOR_Y + 96.0)     # catch do poço (entrada da alcova)
	_secret_alcove("z1", 3100.0, 3400.0, "Z1_VoltrixGate", "voltrix")
	_deadly_gap("Z1", 3400.0, 4800.0, 4200.0, 4380.0)    # vão pulável, mas com sucção
	_well_zone("Z1_Well1", Vector2(4290.0, 620.0), 200.0, 240.0)

# Z2 — câmaras de empuxo: flutua sobre dois abismos largos e sobe a torre do
# SubTank pela lateral, tudo dentro das lift zones.
func _build_zone2() -> void:
	_floor_seg("Z2", 4800.0, 5600.0, FLOOR_Y)
	# vão mortal 5600–6160 (560): só atravessa flutuando no empuxo
	_floor_seg("Z2", 6160.0, 7800.0, FLOOR_Y)
	_glass_wall(5632.0, FLOOR_Y, 320.0)
	_glass_wall(6128.0, FLOOR_Y, 320.0)
	_lift("Z2_Lift1", Vector2(5880.0, 550.0), Vector2(760.0, 500.0))
	_solid_block("z2", "Z2_Tower", 7164.0, 640.0, 128.0, 320.0)   # torre: topo 480
	_lift("Z2_Lift2", Vector2(7000.0, 540.0), Vector2(200.0, 520.0))
	# vão mortal 7800–8360 (560), segunda flutuação
	_floor_seg("Z2", 8360.0, 9600.0, FLOOR_Y)
	_glass_wall(7832.0, FLOOR_Y, 320.0)
	_glass_wall(8328.0, FLOOR_Y, 320.0)
	_lift("Z2_Lift3", Vector2(8080.0, 550.0), Vector2(760.0, 500.0))
	_well_zone("Z2_Well1", Vector2(8900.0, 600.0), 180.0, 220.0)

# Z3 — esmagadores: quatro crushers em ciclos defasados; o Coração fica sob o
# terceiro; poços recuperáveis são os refúgios.
func _build_zone3() -> void:
	_floor_seg("Z3", 10400.0, 11400.0, FLOOR_Y)
	_crusher("Z3_Crusher1", 10900.0, 1.2)
	_recoverable_pit("Z3", 11400.0, 12200.0, 11700.0, 11900.0)
	_floor_seg("Z3", 12200.0, 13600.0, FLOOR_Y)
	_crusher("Z3_Crusher2", 12700.0, 0.9)
	_crusher("Z3_Crusher3", 13050.0, 1.7)   # Coração embaixo
	_recoverable_pit("Z3", 13600.0, 14400.0, 13900.0, 14100.0)
	_floor_seg("Z3", 14400.0, 15200.0, FLOOR_Y)
	_crusher("Z3_Crusher4", 14800.0, 1.4)

# Z4 — singularidade: abismo com sucção e pouso central, ilha do Torso,
# esmagador e vão final limpo.
func _build_zone4() -> void:
	_floor_seg("Z4", 16000.0, 16800.0, FLOOR_Y)
	# vão mortal 16800–17160 (360) com POUSO central e sucção por cima
	_glass_wall(16832.0, FLOOR_Y, 320.0)
	_glass_wall(17128.0, FLOOR_Y, 320.0)
	_fixed_plat("Z4_MidPlat", "z4", 16980.0, FLOOR_Y)
	_well_zone("Z4_Well1", Vector2(16980.0, 560.0), 220.0, 260.0)
	_fp("Z4_FP1", "z4", 17160.0, 2, 4, 2)         # 17160–17672, plat 17288–17544 topo 736
	_floor_seg("Z4", 17672.0, 18400.0, FLOOR_Y)
	_crusher("Z4_Crusher1", 18100.0, 1.1)
	_deadly_gap("Z4", 18400.0, 19200.0, 18400.0 + 110.0, 18400.0 + 290.0)
	# nota: _deadly_gap cria os pisos 18400–18510 e 18690–19200

# Arena do Gravitus (após o CP3): sala fechada; luta começa pelo gatilho de
# ENTRADA (auto_aggro off — regra do projeto).
func _build_boss_arena() -> void:
	_floor_seg("Boss", _BOSS_L, _BOSS_R, FLOOR_Y)
	_solid_block("boss", "Boss_WallR", _BOSS_R + 32.0, 560.0, 64.0, 480.0)
	_solid_block("boss", "Boss_WallL_Top", _BOSS_L + 32.0, 448.0, 64.0, 256.0)
	var grav := get_node_or_null("Gravitus")
	if grav:
		grav.set("auto_aggro", false)
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
				grav.call("aggro"))

# ── Tetos estilo stage 00 ────────────────────────────────────────────────────
const _CEIL04_SEGS := {
	"Z1": [
		[   0.0, 1344.0, 448.0],
		[1344.0, 1760.0, 384.0],   # ilha Z1_FP1
		[1760.0, 4800.0, 448.0],
	],
	"Z2": [
		[4800.0, 7040.0, 448.0],
		[7040.0, 7296.0, 320.0],   # torre do SubTank (topo 480 + folga 160)
		[7296.0, 9600.0, 448.0],
	],
	"Z3": [
		[10400.0, 15200.0, 448.0],  # reto: crushers repousam embutidos no teto
	],
	"Z4": [
		[16000.0, 17216.0, 448.0],
		[17216.0, 17600.0, 384.0],  # ilha Z4_FP1
		[17600.0, 19200.0, 448.0],
	],
	"Boss": [
		[20000.0, 21400.0, 384.0],
	],
}
const _CEIL04_TEX := { "Z1": "z1", "Z2": "z2", "Z3": "z3", "Z4": "z4", "Boss": "z4" }
const _CEIL04_TOP := 128.0

func _build_zone_ceilings04() -> void:
	for zk: String in _CEIL04_SEGS:
		var body := StaticBody2D.new()
		body.name = "%sCeilSegs" % zk
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		for s: Array in _CEIL04_SEGS[zk]:
			var cs := CollisionShape2D.new()
			var sh := SegmentShape2D.new()
			sh.a = Vector2(s[0], s[2])
			sh.b = Vector2(s[1], s[2])
			cs.shape = sh
			body.add_child(cs)

func _ceil04_surface_at(zk: String, wx: float) -> float:
	for s: Array in _CEIL04_SEGS[zk]:
		if wx >= (s[0] as float) and wx < (s[1] as float):
			return s[2]
	return -1.0

func _ceil04_solid(zk: String, wx: float, y: float) -> bool:
	var yb := _ceil04_surface_at(zk, wx)
	return yb > 0.0 and y < yb

func _draw() -> void:
	super._draw()
	_draw_zone_ceilings04()

func _draw_zone_ceilings04() -> void:
	var ts := float(_TS)
	var sts := float(_SRC_TS)
	for zk: String in _CEIL04_SEGS:
		var segs: Array = _CEIL04_SEGS[zk]
		var tex := _cached_override_tex(_zone_tile_path(_CEIL04_TEX[zk] as String))
		if tex == null:
			continue
		var x0f: float = segs[0][0]
		var x1f: float = segs[segs.size() - 1][1]
		var x := x0f
		while x < x1f:
			var yb := _ceil04_surface_at(zk, x)
			var y := _CEIL04_TOP
			while y < yb:
				var ed := not _ceil04_solid(zk, x, y + ts)
				var el := not _ceil04_solid(zk, x - ts, y)
				var er := not _ceil04_solid(zk, x + ts, y)
				var tile: Vector2i
				if   ed and el: tile = Vector2i(0, 2)
				elif ed and er: tile = Vector2i(3, 3)
				elif ed:        tile = Vector2i(1, 2)
				elif el:        tile = Vector2i(1, 0)
				elif er:        tile = Vector2i(3, 2)
				elif not _ceil04_solid(zk, x - ts, y + ts): tile = Vector2i(2, 2)
				elif not _ceil04_solid(zk, x + ts, y + ts): tile = Vector2i(3, 1)
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
