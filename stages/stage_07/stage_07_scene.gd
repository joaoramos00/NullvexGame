# stages/stage_07/stage_07_scene.gd — Luxar (luz)
# Rebuild completo no molde dos stages 02-06: estende a base stage_scene.gd,
# zonas construídas em código, 2 corredores com checkpoint e arena de boss.
# Identidade de luz:
#   Z1 feixes retos          — hazards de luz fixos, timing/posicionamento
#   Z2 feixes espelhados     — feixes com dobra + interruptores permanentes
#   Z3 visão limitada        — escurecimento de tela + portões por interruptor
#   Z4 corredor final        — canhões de luz até a sala do Luxar
extends "res://stages/stage_scene.gd"

const _BEAM := preload("res://stages/stage_07/light_beam.gd")
const _SWITCH := preload("res://stages/stage_07/light_switch.gd")
const _VISION := preload("res://stages/stage_07/vision_limit_zone.gd")
const _LUXAR_ROSTER := {
	"cub":     preload("res://characters/enemies/stage_07/enemy_lion_cub_runner.tscn"),
	"guard":   preload("res://characters/enemies/stage_07/enemy_solar_guard.tscn"),
	"ram":     preload("res://characters/enemies/stage_07/enemy_mirror_ram.tscn"),
	"drone":   preload("res://characters/enemies/stage_07/enemy_glasswing_drone.tscn"),
	"orbiter": preload("res://characters/enemies/stage_07/enemy_prism_orbiter.tscn"),
	"moth":    preload("res://characters/enemies/stage_07/enemy_mirror_moth.tscn"),
	"grabber": preload("res://characters/enemies/stage_07/enemy_sun_grabber.tscn"),
	"pylon":   preload("res://characters/enemies/stage_07/enemy_radiant_pylon.tscn"),
	"turret":  preload("res://characters/enemies/stage_07/enemy_beam_turret.tscn"),
}

const FLOOR_Y := 800.0
const _CORR_INTERIOR := 192.0

const _CP1_ENTRY_X := 3136.0
const _CP1_EXIT_X := 4032.0
const _CP2_ENTRY_X := 10432.0
const _CP2_EXIT_X := 11328.0
const _BOSS_L := 12672.0
const _BOSS_R := 14080.0

# Roster de luz por zona: kind (chave de _LUXAR_ROSTER) → posições.
const Z1_ENEMIES := {
	"cub":   [Vector2(700.0, 760.0), Vector2(2100.0, 760.0)],
	"guard": [Vector2(1400.0, 760.0)],
	"ram":   [Vector2(2700.0, 760.0)],
}
const Z2_ENEMIES := {
	"drone":   [Vector2(4700.0, 500.0), Vector2(6200.0, 450.0)],
	"orbiter": [Vector2(5400.0, 600.0)],
	"pylon":   [Vector2(6800.0, 760.0)],
}
const Z3_ENEMIES := {
	"grabber": [Vector2(8600.0, 700.0)],
	"moth":    [Vector2(9400.0, 650.0), Vector2(10000.0, 650.0)],
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
		StageManager.current_stage_id = 7
	super._ready()
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_glass_tex = load("res://stages/stage_07/stage_07_glass.png") as Texture2D
	_setup_corridors()
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _zone_tile_path(zone: String) -> String:
	var z := zone.to_lower()
	if z == "boss":
		z = "z4"
	return "res://stages/stage_07/Stage_07T_%s.png" % z

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
		var scene: PackedScene = _LUXAR_ROSTER[kind]
		for pos in table[kind]:
			var e := scene.instantiate()
			(e as Node2D).global_position = pos
			add_child(e)
			target.append(e)

# ── Helpers de terreno (mesmo vocabulário dos stages 02-06) ──────────────────

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
	b.set_meta("tileset_override", "res://stages/stage_07/stage_07_glass.png")
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

# ── Helpers de luz ────────────────────────────────────────────────────────────

func _light_beam(n: String, pos: Vector2, local_points: Array, damage_val: int = 10) -> LightBeam:
	var beam: LightBeam = _BEAM.new()
	beam.name = n
	var pts: Array[Vector2] = []
	for p in local_points:
		pts.append(p as Vector2)
	beam.points = pts
	beam.damage = damage_val
	beam.position = pos
	add_child(beam)
	return beam

func _light_switch(n: String, pos: Vector2, size: Vector2, target: Node, target_active: bool) -> void:
	var sw: Area2D = _SWITCH.new()
	sw.name = n
	sw.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	sw.add_child(cs)
	add_child(sw)
	sw.set("target_path", sw.get_path_to(target))
	sw.set("target_active_value", target_active)

func _vision_zone(n: String, pos: Vector2, size: Vector2) -> void:
	var vz: Area2D = _VISION.new()
	vz.name = n
	vz.collision_layer = 0
	vz.collision_mask = 2
	vz.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	vz.add_child(cs)
	add_child(vz)

func _light_gate(n: String, zone: String, cx: float, top_y: float, w: float = 128.0, h: float = 192.0) -> StaticBody2D:
	# Portão que começa TRANCADO (invisível/sem colisão) até um light_switch
	# ligar. Mesma técnica de crumbling_ledge (skip_base_draw + disabled).
	var b := StaticBody2D.new()
	b.name = n
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = Vector2(cx, top_y)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	cs.disabled = true
	b.add_child(cs)
	b.set_meta("lava_override", _zone_tile_path(zone))
	b.set_meta("skip_base_draw", true)
	add_child(b)
	return b

# ── Zona 1 — Entrada / feixes retos ───────────────────────────────────────────

func _build_zone1() -> void:
	_floor_seg("z1", 0.0, _CP1_ENTRY_X, FLOOR_Y)
	# 2 feixes verticais fixos, rentes ao chão (base em FLOOR_Y, 96px de
	# altura) — não bloqueiam a passagem, o jogador precisa pular por cima
	# no timing/posicionamento certo (altura máx. de pulo ≈117.5px, então
	# 96px deixa margem de segurança sem raspar o teto do pulo).
	_light_beam("Z1_Beam1", Vector2(1100.0, FLOOR_Y),
		[Vector2(0.0, 0.0), Vector2(0.0, -96.0)])
	_light_beam("Z1_Beam2", Vector2(2400.0, FLOOR_Y),
		[Vector2(0.0, 0.0), Vector2(0.0, -96.0)])

# ── Zona 2 — Feixes espelhados + interruptores ────────────────────────────────
# Feixe com 1 dobra (vertical do teto até o chão + diagonal até o receptor).
# A perna vertical tem 260px de altura — bem além do alcance de pulo
# (~117.5px, JUMP_VELOCITY²/(2×GRAVITY) = 480²/1960, ver character_base.gd),
# então NÃO é esquivável pulando. Por isso o interruptor Z2_Switch1 fica
# 144px ANTES do feixe (x=4850 vs início do feixe em x≈4994), sobre piso
# sólido contínuo desde a saída do corredor CP1 — o jogador sempre alcança e
# aciona o interruptor sem nunca precisar tocar o feixe primeiro. Desligar o
# feixe abre a passagem e o desvio elevado com a armadura de Zael (Pernas).
func _build_zone2() -> void:
	_floor_seg("z2", _CP1_EXIT_X, 4700.0, FLOOR_Y)
	var beam1 := _light_beam("Z2_Beam1", Vector2(5000.0, FLOOR_Y),
		[Vector2(0.0, -260.0), Vector2(0.0, 0.0), Vector2(260.0, -180.0)])
	_light_switch("Z2_Switch1", Vector2(4850.0, FLOOR_Y - 40.0), Vector2(64.0, 80.0), beam1, false)
	_floor_seg("z2", 4700.0, 7000.0, FLOOR_Y)
	# Armadura de Zael (Pernas, cf. tabela do CLAUDE.md p/ Fase 07) num desvio
	# elevado logo depois da dobra do feixe — mesma altura/offset usados em
	# stage_06 Z2_ArmorLedge (FLOOR_Y-98 = 98px acima do piso, dentro do
	# alcance de pulo de ~117.5px; colecionável 40px acima do topo da
	# plataforma).
	_fixed_plat("Z2_ArmorLedge", "z2", 5100.0, FLOOR_Y - 98.0, 160.0)
	var armor := preload("res://stages/collectible.tscn").instantiate()
	armor.set("collectible_type", Collectible.Type.ARMOR_ZAEL)
	armor.set("armor_piece", "legs")
	armor.global_position = Vector2(5100.0, FLOOR_Y - 138.0)
	add_child(armor)
	# Termina em x=8000 (não em _CP2_ENTRY_X=10432): a partir daí o piso passa
	# a ser responsabilidade da Zona 3 (_build_zone3, tileset "z3"). Encurtado
	# nesta task (10) porque a versão original ia até _CP2_ENTRY_X e duplicava
	# fisicamente o piso da Zona 3 inteira (8000-10432): dois StaticBody2D
	# sobrepostos no mesmo retângulo, cada um com override de textura de zona
	# diferente (z2 vs z3) — mesma classe de bug de piso invadindo território
	# da zona seguinte já visto na Stage 06 (Zona 2→3).
	_floor_seg("z2", 7000.0, 8000.0, FLOOR_Y)

# ── Zona 3 — Visão limitada + portões ─────────────────────────────────────────
# Trecho com CanvasModulate escurecido (vision_limit_zone) cobrindo o piso
# inteiro da zona (8000-10400, vs. piso 8000-10432); um interruptor (dentro
# da zona escura, mas alcançado ANDANDO no piso — não precisa de visão) abre
# um portão logo depois, guardando o extra de Zara + coração.
#
# IMPORTANTE — polaridade do portão (achado nesta task, não no brief
# original): _light_gate() sempre cria o portão DESTRANCADO por padrão
# (disabled=true, invisível) para SÓ o interruptor travá-lo/destravá-lo.
# Se o portão começasse destrancado e o interruptor o ATIVASSE (trancasse)
# depois — como o rascunho original desta task escrevia
# (`_light_switch(..., gate, true)`) — o resultado seria um portão sólido de
# 192px de altura (> pulo máx. ~117.5px) se fechando NO CAMINHO à frente do
# jogador assim que ele pisasse no interruptor (que fica ANTES do portão, no
# único caminho possível): softlock permanente e incondicional, já que o
# interruptor é toggle único (não rearma). Por isso aqui o portão é montado
# manualmente para começar TRANCADO/sólido (mesmo padrão de Z1_Beam/Z2_Beam1,
# que também começam ativos por padrão) e o interruptor o DESTRANCA
# (`target_active_value = false`, mesma semântica usada em Z2_Switch1 pra
# desligar o feixe) — abrindo a passagem depois de encontrado.
func _build_zone3() -> void:
	_floor_seg("z3", 8000.0, _CP2_ENTRY_X, FLOOR_Y)
	_vision_zone("Z3_Dark", Vector2(9200.0, FLOOR_Y - 200.0), Vector2(2400.0, 700.0))
	var gate := _light_gate("Z3_Gate", "z3", 9700.0, FLOOR_Y - 96.0, 64.0, 192.0)
	var gate_cs := gate.get_child(0) as CollisionShape2D
	gate_cs.disabled = false          # começa TRANCADO/sólido (ver nota acima)
	gate.remove_meta("skip_base_draw")  # e visível, desenhado com o tile "z3"
	_light_switch("Z3_Switch1", Vector2(9300.0, FLOOR_Y - 40.0), Vector2(64.0, 80.0), gate, false)
	# Extra de Zara (Machado de Guerra) + coração num desvio depois do portão.
	_fixed_plat("Z3_ExtraLedge", "z3", 9900.0, FLOOR_Y - 98.0, 160.0)
	var axe := preload("res://stages/collectible.tscn").instantiate()
	axe.set("collectible_type", Collectible.Type.WEAPON_ZARA)
	axe.set("ability_id", "war_axe")
	axe.global_position = Vector2(9900.0, FLOOR_Y - 138.0)
	add_child(axe)
	var heart := preload("res://stages/collectible.tscn").instantiate()
	heart.set("collectible_type", Collectible.Type.HEART)
	heart.set("stage_id", 7)
	heart.global_position = Vector2(9970.0, FLOOR_Y - 138.0)
	add_child(heart)
