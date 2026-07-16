# stages/stage_05/stage_05_scene.gd — Galerix (vento)
# Rebuild completo no molde dos stages 02/03/04: estende a base stage_scene.gd,
# zonas construídas em código, 2 corredores com checkpoint e arena de boss.
# Identidade de vento:
#   Z1 corrente horizontal — rajadas empurram o jogador ao longo do piso
#   Z2 coluna de updraft   — shaft vertical erguido por câmaras de empuxo
#   Z3 plataformas soltas  — deslizam quando pisadas, sobre abismo
#   Z4 corredor final      — canhões de vento até a sala do Galerix
extends "res://stages/stage_scene.gd"

const _BLIZZARD := preload("res://stages/stage_02/blizzard_zone.gd")
const _LIFT := preload("res://stages/stage_04/lift_zone.gd")
const _SLIDER := preload("res://stages/stage_05/sliding_platform.gd")
const _GALE := {
	"runner":   preload("res://characters/enemies/stage_05/enemy_gale_runner.tscn"),
	"glider":   preload("res://characters/enemies/stage_05/enemy_claw_glider.tscn"),
	"lancer":   preload("res://characters/enemies/stage_05/enemy_airfoil_lancer.tscn"),
	"harrier":  preload("res://characters/enemies/stage_05/enemy_sky_harrier.tscn"),
	"wisp":     preload("res://characters/enemies/stage_05/enemy_turbine_wisp.tscn"),
	"swarm":    preload("res://characters/enemies/stage_05/enemy_feather_swarm.tscn"),
	"grappler": preload("res://characters/enemies/stage_05/enemy_gale_grappler.tscn"),
	"turret":   preload("res://characters/enemies/stage_05/enemy_gale_turret.tscn"),
	"fan":      preload("res://characters/enemies/stage_05/enemy_updraft_fan.tscn"),
}

const FLOOR_Y := 800.0     # piso de Z1 e do shaft (base)
const FLOOR_Y2 := -800.0   # piso elevado de Z2(topo)/Z3/Z4/boss
const _CORR_INTERIOR := 192.0

const _CP1_ENTRY_X := 3136.0
const _CP1_EXIT_X := 4032.0
const _CP2_ENTRY_X := 8000.0
const _CP2_EXIT_X := 8896.0
const _BOSS_L := 10240.0
const _BOSS_R := 11648.0

# Roster de vento por zona: kind (chave de _GALE) → posições.
const Z1_ENEMIES := {
	"runner": [Vector2(700.0, 760.0), Vector2(2100.0, 760.0)],
	"glider": [Vector2(1400.0, 760.0)],
	"lancer": [Vector2(2700.0, 760.0)],
}
const Z2_ENEMIES := {
	"harrier": [Vector2(4200.0, 400.0), Vector2(4300.0, -300.0)],
	"wisp":    [Vector2(4100.0, 0.0), Vector2(4350.0, -500.0)],
}
const Z3_ENEMIES := {
	"swarm":    [Vector2(5600.0, -850.0), Vector2(7200.0, -850.0)],
	"grappler": [Vector2(6400.0, -900.0)],
}
const Z4_ENEMIES := {
	"turret": [Vector2(9200.0, 736.0), Vector2(9900.0, 736.0)],
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
		StageManager.current_stage_id = 5
	super._ready()
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_glass_tex = load("res://stages/stage_05/stage_05_glass.png") as Texture2D
	_setup_corridors()
	_build_zone1()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _zone_tile_path(zone: String) -> String:
	# Case EXATO do arquivo (PCK web é case-sensitive). Arena do boss usa z4.
	var z := zone.to_lower()
	if z == "boss":
		z = "z4"
	return "res://stages/stage_05/Stage_05T_%s.png" % z

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
	_make_corridor("CP1", _CP1_ENTRY_X, _CP1_EXIT_X, "z1", FLOOR_Y, 1)
	_make_corridor("CP2", _CP2_ENTRY_X, _CP2_EXIT_X, "z3", FLOOR_Y2, 2)

func _make_corridor(name_prefix: String, entry_x: float, exit_x: float, zone: String, floor_y: float, checkpoint_index: int) -> CorridorSection:
	var width := exit_x - entry_x
	var corr := CorridorSection.new()
	corr.name = name_prefix
	corr.tileset = _cached_override_tex(_zone_tile_path(zone))
	corr.glass_tex = _glass_tex
	corr.door_tex = _door_tex
	var floor_cy := floor_y + 32.0
	var ceil_cy := floor_y - _CORR_INTERIOR - 32.0
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
	_make_zone_trigger("Z2Trigger", Rect2(_CP1_EXIT_X, -1600.0, 3200.0, 2500.0), 2)
	_make_zone_trigger("Z3Trigger", Rect2(4800.0, -1600.0, 3200.0, 900.0), 3)
	_make_zone_trigger("Z4Trigger", Rect2(_CP2_EXIT_X, -1600.0, 2200.0, 900.0), 4)

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
		1: target = _zone1_enemies; table = Z1_ENEMIES
		2: target = _zone2_enemies; table = Z2_ENEMIES
		3: target = _zone3_enemies; table = Z3_ENEMIES
		4: target = _zone4_enemies; table = Z4_ENEMIES
		_: return
	if not target.is_empty():
		return
	for kind: String in table:
		var scene: PackedScene = _GALE[kind]
		for pos in table[kind]:
			var e := scene.instantiate()
			(e as Node2D).global_position = pos
			add_child(e)
			target.append(e)

# ── Helpers de terreno (mesmo vocabulário dos stages 02/03/04) ───────────────

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
	b.set_meta("tileset_override", "res://stages/stage_05/stage_05_glass.png")
	add_child(b)
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

func _wind_current(n: String, pos: Vector2, size: Vector2, force: Vector2) -> void:
	var w: Area2D = _BLIZZARD.new()
	w.name = n
	w.set("force", force)
	w.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	w.add_child(cs)
	add_child(w)

func _updraft_column(n: String, pos: Vector2, size: Vector2, force: float = 700.0) -> void:
	var l: Area2D = _LIFT.new()
	l.name = n
	l.set("lift_force", force)
	l.set("size", size)
	l.position = pos
	add_child(l)

func _sliding_plat(n: String, zone: String, pos: Vector2, dir: float = 1.0, dist: float = 220.0) -> void:
	var p: AnimatableBody2D = _SLIDER.new()
	p.name = n
	p.set("slide_dir", dir)
	p.set("slide_distance", dist)
	p.collision_layer = 1
	p.collision_mask = 0
	p.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(96.0, 32.0)
	cs.shape = sh
	p.add_child(cs)
	p.set_meta("platform_override", _zone_tile_path(zone))
	add_child(p)

# ── Zona 1 — Entrada / corrente de vento horizontal ──────────────────────────

func _build_zone1() -> void:
	_floor_seg("z1", 0.0, _CP1_ENTRY_X, FLOOR_Y)
	# Trechos de corrente: empurra a favor (ajuda travessia) e contra
	# (obriga cronometrar pulo) alternados ao longo da zona.
	_wind_current("Z1Wind_A", Vector2(900.0, 700.0), Vector2(700.0, 200.0), Vector2(140.0, 0.0))
	_wind_current("Z1Wind_B", Vector2(2400.0, 700.0), Vector2(700.0, 200.0), Vector2(-160.0, 0.0))
