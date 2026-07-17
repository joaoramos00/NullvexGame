# stages/stage_06/stage_06_scene.gd — Umbraex (sombra)
# Rebuild completo no molde dos stages 02-05: estende a base stage_scene.gd,
# zonas construídas em código, 2 corredores com checkpoint e arena de boss.
# Identidade de sombra:
#   Z1 fasing simples     — plataformas alternando sólido/vazio, ciclo único
#   Z2 fasing dessincronizado + emboscada — múltiplas plataformas fora de fase
#   Z3 portais de sombra  — pares de portal cruzando abismos impossíveis de pular
#   Z4 corredor final     — canhões de sombra até a sala do Umbraex
extends "res://stages/stage_scene.gd"

const _PHASE := preload("res://stages/stage_06/phase_platform.gd")
const _PORTAL := preload("res://stages/stage_06/shadow_portal.gd")
const _UMBRA := {
	"stalker":  preload("res://characters/enemies/stage_06/enemy_shadow_stalker.tscn"),
	"duelist":  preload("res://characters/enemies/stage_06/enemy_eclipse_duelist.tscn"),
	"pouncer":  preload("res://characters/enemies/stage_06/enemy_night_pouncer.tscn"),
	"bat":      preload("res://characters/enemies/stage_06/enemy_umbra_bat.tscn"),
	"orbiter":  preload("res://characters/enemies/stage_06/enemy_void_orbiter.tscn"),
	"snare":    preload("res://characters/enemies/stage_06/enemy_shadow_snare.tscn"),
	"mine":     preload("res://characters/enemies/stage_06/enemy_phase_mine.tscn"),
	"lantern":  preload("res://characters/enemies/stage_06/enemy_dark_lantern.tscn"),
	"turret":   preload("res://characters/enemies/stage_06/enemy_eclipse_turret.tscn"),
}

const FLOOR_Y := 800.0
const _CORR_INTERIOR := 192.0

const _CP1_ENTRY_X := 3136.0
const _CP1_EXIT_X := 4032.0
const _CP2_ENTRY_X := 10432.0
const _CP2_EXIT_X := 11328.0
const _BOSS_L := 12672.0
const _BOSS_R := 14080.0

# Roster de sombra por zona: kind (chave de _UMBRA) → posições.
const Z1_ENEMIES := {
	"stalker": [Vector2(700.0, 760.0), Vector2(2100.0, 760.0)],
	"pouncer": [Vector2(1400.0, 760.0)],
	"duelist": [Vector2(2700.0, 760.0)],
}
const Z2_ENEMIES := {
	"bat":     [Vector2(4700.0, 500.0), Vector2(6200.0, 450.0)],
	"orbiter": [Vector2(5400.0, 600.0)],
	"lantern": [Vector2(6800.0, 760.0)],
}
const Z3_ENEMIES := {
	"snare": [Vector2(8600.0, 700.0)],
	"mine":  [Vector2(9400.0, 750.0), Vector2(10000.0, 750.0)],
}
const Z4_ENEMIES := {
	"turret": [Vector2(11600.0, 736.0), Vector2(12300.0, 736.0)],
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
		StageManager.current_stage_id = 6
	super._ready()
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_glass_tex = load("res://stages/stage_06/stage_06_glass.png") as Texture2D
	_setup_corridors()
	_build_zone1()
	_build_zone2()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _zone_tile_path(zone: String) -> String:
	var z := zone.to_lower()
	if z == "boss":
		z = "z4"
	return "res://stages/stage_06/Stage_06T_%s.png" % z

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
	_make_corridor("CP2", _CP2_ENTRY_X, _CP2_EXIT_X, "z3", FLOOR_Y, 2)

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
	_make_zone_trigger("Z2Trigger", Rect2(_CP1_EXIT_X, 300.0, 5600.0, 900.0), 2)
	_make_zone_trigger("Z3Trigger", Rect2(8000.0, 300.0, 3200.0, 900.0), 3)
	_make_zone_trigger("Z4Trigger", Rect2(_CP2_EXIT_X, 300.0, 2200.0, 900.0), 4)

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
		var scene: PackedScene = _UMBRA[kind]
		for pos in table[kind]:
			var e := scene.instantiate()
			(e as Node2D).global_position = pos
			add_child(e)
			target.append(e)

# ── Helpers de terreno (mesmo vocabulário dos stages 02-05) ──────────────────

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
	b.set_meta("tileset_override", "res://stages/stage_06/stage_06_glass.png")
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

func _phase_plat(n: String, zone: String, cx: float, top_y: float, solid_t: float, phase_t: float, offset: float = 0.0, w: float = 128.0) -> void:
	var p: StaticBody2D = _PHASE.new()
	p.name = n
	p.set("solid_time", solid_t)
	p.set("phase_time", phase_t)
	p.set("phase_offset", offset)
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

func _shadow_portal_pair(name_a: String, pos_a: Vector2, name_b: String, pos_b: Vector2, size: Vector2 = Vector2(64.0, 96.0)) -> void:
	var a: Area2D = _PORTAL.new()
	a.name = name_a
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = pos_a
	var cs_a := CollisionShape2D.new()
	var sh_a := RectangleShape2D.new()
	sh_a.size = size
	cs_a.shape = sh_a
	a.add_child(cs_a)
	add_child(a)

	var b: Area2D = _PORTAL.new()
	b.name = name_b
	b.collision_layer = 0
	b.collision_mask = 2
	b.position = pos_b
	var cs_b := CollisionShape2D.new()
	var sh_b := RectangleShape2D.new()
	sh_b.size = size
	cs_b.shape = sh_b
	b.add_child(cs_b)
	add_child(b)

	a.call("link_partner", b)
	b.call("link_partner", a)

# ── Zona 1 — Entrada / fasing simples ─────────────────────────────────────────

func _build_zone1() -> void:
	_floor_seg("z1", 0.0, 1400.0, FLOOR_Y)
	_phase_plat("Z1_Phase1", "z1", 1600.0, FLOOR_Y - 16.0, 2.0, 1.0)
	_phase_plat("Z1_Phase2", "z1", 1900.0, FLOOR_Y - 16.0, 2.0, 1.0)
	_floor_seg("z1", 2100.0, _CP1_ENTRY_X, FLOOR_Y)

# ── Zona 2 — Fasing dessincronizado + emboscada ──────────────────────────────
# 4 plataformas fora de sincronia (offsets diferentes) sobre um vão — o
# jogador precisa ler o padrão, não só decorar 1 timing. Períodos mais longos
# que a Z1 (mais tempo sólida, mais tempo vazia) pra dar tempo de observar.
#
# offsets 0.0/0.6/1.2/1.8 (não os 0.0/1.2/2.4/0.8 do plano original — ver
# task-8-report.md: com os offsets originais, Phase2 nunca fica sólida ao
# mesmo tempo em que Phase3 está alcançável a partir dela, criando uma
# travessia impossível. A progressão 0.0/0.6/1.2/1.8, com solid_time=2.4 e
# phase_time=1.6 (período 4.0s), garante overlap solid-solid de 1.8s entre
# cada par de plataformas vizinhas — dá folga generosa pro jogador ler o
# padrão sem ficar preso no meio do vão.
func _build_zone2() -> void:
	_floor_seg("z2", _CP1_EXIT_X, 4500.0, FLOOR_Y)
	_phase_plat("Z2_Phase1", "z2", 4700.0, FLOOR_Y - 16.0, 2.4, 1.6, 0.0)
	_phase_plat("Z2_Phase2", "z2", 4980.0, FLOOR_Y - 16.0, 2.4, 1.6, 0.6)
	_phase_plat("Z2_Phase3", "z2", 5260.0, FLOOR_Y - 16.0, 2.4, 1.6, 1.2)
	_phase_plat("Z2_Phase4", "z2", 5540.0, FLOOR_Y - 16.0, 2.4, 1.6, 1.8)
	_floor_seg("z2", 5720.0, 7000.0, FLOOR_Y)
	# Armadura de Zara (Braços) num desvio elevado guardado pelo dark_lantern
	# (já posicionado em Z2_ENEMIES, x=6800).
	# Altura ajustada: o plano original punha o topo em FLOOR_Y-180 (180px
	# acima do piso) — acima do alcance vertical máximo de pulo (JUMP_VELOCITY²
	# /(2×GRAVITY) = 480²/1960 ≈ 117.5px, ver characters/base/character_base.gd
	# e reference_jump_height.md). FLOOR_Y-98 fica 98px acima do piso, ~20px
	# de margem sob o teto de 117.5px (mesma margem de segurança usada na
	# correção análoga de stage_05 Z3_ExtraLedge).
	_fixed_plat("Z2_ArmorLedge", "z2", 6800.0, FLOOR_Y - 98.0, 160.0)
	var armor := preload("res://stages/collectible.tscn").instantiate()
	# NOTA: o plano original usava armor.set("collectible_type", "armor_zara_arms")
	# (uma String) — Collectible.collectible_type é um enum/int tipado, e esse
	# set() silenciosamente vira Type.HEART (0) com armor_piece="" (confirmado
	# via probe headless). Usando o padrão correto (igual a stage_01_scene.gd
	# linha ~1664: Collectible.Type.* + armor_piece).
	armor.set("collectible_type", Collectible.Type.ARMOR_ZARA)
	armor.set("armor_piece", "arms")
	armor.global_position = Vector2(6800.0, FLOOR_Y - 138.0)
	add_child(armor)
	_floor_seg("z2", 7000.0, _CP2_ENTRY_X, FLOOR_Y)
