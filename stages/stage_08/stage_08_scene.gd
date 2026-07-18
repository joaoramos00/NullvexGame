# stages/stage_08/stage_08_scene.gd — Terragor (terra)
# Rebuild completo no molde dos stages 02-07: estende a base stage_scene.gd,
# zonas construídas em código, 2 corredores com checkpoint e arena de boss.
# Identidade de terra/mina:
#   Z1 piso instável   — saliências que desmoronam (crumbling_ledge.gd, reuso direto)
#   Z2 desabamentos    — blocos que esmagam em ciclo (crusher.gd, reuso direto)
#   Z3 túnel de mina    — parede de entulho quebrável por ataque (rubble_wall.gd, NOVO)
#   Z4 corredor final   — canhões de pedra até a sala do Terragor
extends "res://stages/stage_scene.gd"

const _CRUMBLE := preload("res://stages/stage_01/crumbling_ledge.gd")   # script genérico
const _CRUSHER := preload("res://stages/stage_04/crusher.gd")           # script genérico (Task 8)
const _RUBBLE := preload("res://stages/stage_08/rubble_wall.gd")        # (Task 9)
const _TERRAGOR_ROSTER := {
	"grunt":   preload("res://characters/enemies/stage_08/enemy_terra_grunt.tscn"),
	"brute":   preload("res://characters/enemies/stage_08/enemy_mossback_brute.tscn"),
	"mole":    preload("res://characters/enemies/stage_08/enemy_drill_mole.tscn"),
	"wasp":    preload("res://characters/enemies/stage_08/enemy_gem_wasp.tscn"),
	"glider":  preload("res://characters/enemies/stage_08/enemy_stone_glider.tscn"),
	"orbiter": preload("res://characters/enemies/stage_08/enemy_ore_orbiter.tscn"),
	"snare":   preload("res://characters/enemies/stage_08/enemy_root_snare.tscn"),
	"turret":  preload("res://characters/enemies/stage_08/enemy_boulder_turret.tscn"),
	"totem":   preload("res://characters/enemies/stage_08/enemy_fossil_totem.tscn"),
}

const FLOOR_Y := 800.0
const _CORR_INTERIOR := 192.0

const _CP1_ENTRY_X := 3200.0
const _CP1_EXIT_X := 4096.0
const _CP2_ENTRY_X := 10496.0
const _CP2_EXIT_X := 11392.0
const _BOSS_L := 12544.0
const _BOSS_R := 13952.0

# Roster de terra por zona: kind (chave de _TERRAGOR_ROSTER) → posições.
const Z1_ENEMIES := {
	"grunt": [Vector2(500.0, 760.0), Vector2(2900.0, 760.0)],
	"brute": [Vector2(1100.0, 760.0)],
	"mole":  [Vector2(2400.0, 760.0)],
}
const Z2_ENEMIES := {
	"wasp":   [Vector2(4700.0, 500.0), Vector2(6800.0, 450.0)],
	"glider": [Vector2(5600.0, 600.0)],
}
const Z3_ENEMIES := {
	"snare":   [Vector2(9200.0, 760.0)],
	"totem":   [Vector2(9800.0, 760.0)],
	"orbiter": [Vector2(10200.0, 650.0)],
}
const Z4_ENEMIES := {
	"turret": [Vector2(11700.0, 736.0), Vector2(12200.0, 736.0)],
}

var _door_tex: Texture2D = null
var _zone1_enemies: Array[Node] = []
var _zone2_enemies: Array[Node] = []
var _zone3_enemies: Array[Node] = []
var _zone4_enemies: Array[Node] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if StageManager.current_stage_id < 0:
		StageManager.current_stage_id = 8
	super._ready()
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_setup_corridors()
	_build_zone1()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _zone_tile_path(zone: String) -> String:
	var z := zone.to_lower()
	if z == "boss":
		z = "z4"
	return "res://stages/stage_08/Stage_08T_%s.png" % z

# ── Corredores (checkpoints) ─────────────────────────────────────────────────

func _setup_corridors() -> void:
	_make_corridor("CP1", _CP1_ENTRY_X, _CP1_EXIT_X, "z1", FLOOR_Y, 1)
	_make_corridor("CP2", _CP2_ENTRY_X, _CP2_EXIT_X, "z3", FLOOR_Y, 2)

func _make_corridor(name_prefix: String, entry_x: float, exit_x: float, zone: String, floor_y: float, checkpoint_index: int) -> CorridorSection:
	var width := exit_x - entry_x
	var corr := CorridorSection.new()
	corr.name = name_prefix
	corr.tileset = _cached_override_tex(_zone_tile_path(zone))
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
	add_child(corr)
	corr.setup(_player)
	return corr

# ── Spawn de inimigos por zona ───────────────────────────────────────────────

func _setup_zone_triggers() -> void:
	_make_zone_trigger("Z2Trigger", Rect2(_CP1_EXIT_X, 300.0, _CP2_ENTRY_X - _CP1_EXIT_X, 900.0), 2)
	_make_zone_trigger("Z3Trigger", Rect2(7296.0, 300.0, _CP2_ENTRY_X - 7296.0, 900.0), 3)
	_make_zone_trigger("Z4Trigger", Rect2(_CP2_EXIT_X, 300.0, _BOSS_L - _CP2_EXIT_X, 900.0), 4)

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
		var scene: PackedScene = _TERRAGOR_ROSTER[kind]
		for pos in table[kind]:
			var e := scene.instantiate()
			(e as Node2D).global_position = pos
			add_child(e)
			target.append(e)

# ── Helpers de terreno (mesmo vocabulário dos stages 02-07) ──────────────────

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

# Saliência que desmorona (script genérico de stage_01, reuso cross-stage —
# mesmo padrão de stage_02::_ice_crumble). LandDetector Area2D chama
# touched() quando o player pousa em cima.
func _crumble_ledge(n: String, zone: String, cx: float, top_y: float, w: float = 160.0) -> void:
	var body := StaticBody2D.new()
	body.name = n
	body.set_script(_CRUMBLE)
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(cx, top_y + 16.0)
	body.set_meta("platform_override", _zone_tile_path(zone))
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

# ── Zona 1 — Piso instável ────────────────────────────────────────────────────
# Pequeno abismo (1600→2080, 480px) atravessado por 3 saliências que
# desmoronam ~0.5s após o pouso e respawnam em 1.2s (crumbling_ledge.gd) —
# flush com o piso normal (top_y=FLOOR_Y, mesma superfície de _floor_seg).
# Geometria verificada (largura 160 cada, cx=1680/1840/2000 → spans
# [1600,1760]/[1760,1920]/[1920,2080]): cobre o vão 1600-2080 inteiro sem
# gap nem overlap. Sem piso embaixo do abismo: kill plane por-fase cobre a
# queda (herdado, sem código novo, ver reference_kill_plane na memória do
# projeto).

func _build_zone1() -> void:
	_floor_seg("z1", 0.0, 1600.0, FLOOR_Y)
	_crumble_ledge("Z1_Crumble1", "z1", 1680.0, FLOOR_Y, 160.0)
	_crumble_ledge("Z1_Crumble2", "z1", 1840.0, FLOOR_Y, 160.0)
	_crumble_ledge("Z1_Crumble3", "z1", 2000.0, FLOOR_Y, 160.0)
	_floor_seg("z1", 2080.0, _CP1_ENTRY_X, FLOOR_Y)
