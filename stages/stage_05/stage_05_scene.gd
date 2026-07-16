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
	# y=-840 = FLOOR_Y2(-800) - 40, mesmo offset "40px acima da superfície" que
	# Z1_ENEMIES usa sobre FLOOR_Y(800) (y=760). O valor anterior (736.0) era
	# resto do scaffold da Task 6 (calibrado pro piso baixo FLOOR_Y, não pro
	# piso elevado FLOOR_Y2 de Z4) — o turret (tem gravidade, ver
	# enemy_gale_turret.gd::_physics_process) caía 1536px no vazio até o
	# kill-plane, nunca ficando de pé no corredor.
	"turret": [Vector2(9200.0, -840.0), Vector2(9900.0, -840.0)],
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
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_boss_arena()
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

# ── Zona 2 — Coluna de updraft vertical ──────────────────────────────────────
# Shaft estreito (448px, 7 tiles) subindo de FLOOR_Y (piso) até FLOOR_Y2 (topo,
# 1600px acima) — câmara de empuxo cobre quase toda a altura, erguendo o
# jogador. Alcova lateral no meio do shaft guarda a armadura de Braços do Zael.

const _Z2_SHAFT_L := 4032.0
const _Z2_SHAFT_R := 4480.0
const _Z2_SHAFT_TOP := FLOOR_Y2
const _Z2_SHAFT_BOTTOM := FLOOR_Y
const _Z2_ARMOR_ALCOVE_Y := 0.0

func _build_zone2() -> void:
	# Paredes do shaft (chão até o topo, 32px de folga acima do topo pra fechar com a Z3).
	var shaft_h := _Z2_SHAFT_BOTTOM - _Z2_SHAFT_TOP + 64.0
	var shaft_cy := (_Z2_SHAFT_BOTTOM + _Z2_SHAFT_TOP) * 0.5
	_solid_block("z2", "Z2_WallL", _Z2_SHAFT_L, shaft_cy, 64.0, shaft_h)
	# Z2_WallR fica mais curta que Z2_WallL: ela só precisa conter o jogador
	# durante a subida (do fundo do shaft até perto do topo), mas NÃO pode
	# tampar a saída pra Z3, que sai pela direita bem na altura do piso de
	# aterrissagem (y = FLOOR_Y2 = -800, ver _floor_seg abaixo). Topo da
	# parede em y = -672 deixa 128px de folga livre acima do piso pra o
	# jogador atravessar sem prender na borda.
	var wallr_bottom := _Z2_SHAFT_BOTTOM + 32.0
	var wallr_top := -672.0
	var wallr_h := wallr_bottom - wallr_top
	var wallr_cy := (wallr_bottom + wallr_top) * 0.5
	_solid_block("z2", "Z2_WallR", _Z2_SHAFT_R, wallr_cy, 64.0, wallr_h)
	# Câmara de empuxo cobrindo quase toda a coluna (deixa uma folga no topo
	# pra desacelerar antes de aterrissar na plataforma de Z2->Z3).
	_updraft_column("Z2_Updraft", Vector2((_Z2_SHAFT_L + _Z2_SHAFT_R) * 0.5, _Z2_SHAFT_BOTTOM - 200.0),
		Vector2(_Z2_SHAFT_R - _Z2_SHAFT_L - 32.0, _Z2_SHAFT_BOTTOM - _Z2_SHAFT_TOP - 100.0), 700.0)
	# Alcova lateral pro colectável (armadura Braços do Zael), acessível saindo
	# um pouco do fluxo principal do updraft no meio do shaft.
	_fixed_plat("Z2_ArmorLedge", "z2", _Z2_SHAFT_R + 96.0, _Z2_ARMOR_ALCOVE_Y, 128.0)
	var armor := preload("res://stages/collectible.tscn").instantiate()
	armor.set("collectible_type", "armor_zael_arms")
	armor.global_position = Vector2(_Z2_SHAFT_R + 96.0, _Z2_ARMOR_ALCOVE_Y - 40.0)
	add_child(armor)
	# Aterrissagem no topo do shaft — plataforma plana levando pra Z3.
	_floor_seg("z2", _Z2_SHAFT_L, 4800.0, FLOOR_Y2)

# ── Zona 3 — Plataformas deslizantes sobre abismo ────────────────────────────
# Piso fixo nas pontas (chegada de Z2 e chegada no corredor CP2), 3
# plataformas deslizantes no meio cobrindo o abismo — cada uma desliza numa
# direção diferente pra exigir timing, não só posição estática. Posições
# recalculadas a partir dos spans de mundo reais de _floor_seg/_sliding_plat
# (não os valores "de prosa"): o salto plano do jogador alcança ~196px
# (SPEED=200 × tempo de voo do JUMP_VELOCITY/GRAVITY) e ~118px de altura —
# ver docs/.../reference_jump_height.md. Cada trecho abaixo fica com folga
# (134-154px, margem sob o teto de 196px) medida ponta-a-ponta das
# collision shapes reais, não dos centros.
func _build_zone3() -> void:
	_floor_seg("z3", 4800.0, 5400.0, FLOOR_Y2)
	# Z3_Slide1: repouso [5552,5648]; desliza +1 até 220 → estende [5772,5868].
	# Piso1→repouso: 5552-5400=152px. Precisa esperar deslizar pra reduzir o
	# vão até a Slide2 (152→134px), por isso desliza NA DIREÇÃO da próxima.
	_sliding_plat("Z3_Slide1", "z3", Vector2(5600.0, FLOOR_Y2 - 16.0), 1.0, 220.0)
	# Z3_Slide2: repouso [6002,6098]; desliza -1 (PRA LONGE da Slide3) até 220
	# → mínimo [5782,5878]. Slide1(estendida, 5868)→repouso: 134px — pulo
	# direto funciona; mas o jogador precisa saltar pra Slide3 sem demorar
	# (senão ela deriva pra esquerda e o vão cresce) — aqui mora o "timing".
	_sliding_plat("Z3_Slide2", "z3", Vector2(6050.0, FLOOR_Y2 - 16.0), -1.0, 220.0)
	# Z3_Slide3: repouso [6252,6348]; desliza +1 até 260 → estende [6512,6608].
	# Slide2(repouso, 6098)→repouso: 154px. Espera deslizar pra alcançar o
	# piso2 (152px se saltar da extensão máxima).
	_sliding_plat("Z3_Slide3", "z3", Vector2(6300.0, FLOOR_Y2 - 16.0), 1.0, 260.0)
	_floor_seg("z3", 6760.0, _CP2_ENTRY_X, FLOOR_Y2)
	# Extra de Zara (Garras) + coração num desvio elevado, acessível ficando na
	# Z3_Slide1 até ela deslizar pra extensão máxima (dir +1, ~1.57s parado
	# nela) — nesse ponto seu span [5772,5868] fica embaixo da saliência
	# [5770,5930]: é só pular reto pra cima, 98px de ganho vertical (dentro do
	# teto de ~118px de altura de pulo). Pra continuar, desce de volta pra
	# Z3_Slide2 (ainda perto do repouso [6002,6098], já que a extensão da
	# Slide1 é rápida) e segue a sequência normal Slide2→Slide3.
	_fixed_plat("Z3_ExtraLedge", "z3", 5850.0, FLOOR_Y2 - 130.0, 160.0)
	var claws := preload("res://stages/collectible.tscn").instantiate()
	claws.set("collectible_type", "extra_zara_claws")
	claws.global_position = Vector2(5810.0, FLOOR_Y2 - 170.0)
	add_child(claws)
	var heart := preload("res://stages/collectible.tscn").instantiate()
	heart.set("collectible_type", "heart")
	heart.global_position = Vector2(5890.0, FLOOR_Y2 - 170.0)
	add_child(heart)

# ── Zona 4 — Corredor final com canhões de vento ─────────────────────────────

func _build_zone4() -> void:
	_floor_seg("z4", _CP2_EXIT_X, _BOSS_L, FLOOR_Y2)

# ── Sala do boss (Galerix) ────────────────────────────────────────────────────
# Padrão B (porta aberta + trigger, skill new-boss-room): arena aberta,
# aggro por Area2D de entrada — não por distância.

func _build_boss_arena() -> void:
	_floor_seg("boss", _BOSS_L, _BOSS_R, FLOOR_Y2)
	# Parede direita (fim de arena, sem porta): altura 512 (8 tiles, múltiplo
	# de 64 — regra de ouro da skill new-boss-room) em vez dos 480 "de prosa"
	# do plano original (7.5 tiles, deixaria a última linha do tileset de lava
	# cortada ao meio).
	_solid_block("boss", "Boss_WallR", _BOSS_R + 32.0, FLOOR_Y2 - 256.0, 64.0, 512.0)
	_solid_block("boss", "Boss_WallL_Top", _BOSS_L + 32.0, FLOOR_Y2 - 352.0, 64.0, 256.0)
	var galerix := get_node_or_null("Galerix")
	if galerix:
		galerix.visible = true
		galerix.global_position = Vector2((_BOSS_L + _BOSS_R) * 0.5, FLOOR_Y2 - 64.0)
		galerix.set("auto_aggro", false)
		var trig := Area2D.new()
		trig.name = "BossRoomTrigger"
		trig.collision_layer = 0
		trig.collision_mask = 2
		trig.position = Vector2((_BOSS_L + _BOSS_R) * 0.5, FLOOR_Y2 - 150.0)
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(_BOSS_R - _BOSS_L - 200.0, 300.0)
		cs.shape = sh
		trig.add_child(cs)
		add_child(trig)
		trig.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBase:
				galerix.call("aggro"))
		# NÃO chamar $HUD.connect_to_boss(galerix) aqui: Galerix já existe como
		# filho direto da cena (.tscn, Task 6, visible=false) ANTES de
		# super._ready() rodar — o loop genérico de stage_scene.gd::_ready()
		# (`for child in get_children(): if child is BossBase: ...`) já pega
		# esse nó e faz esse wiring (player, HUD, boss_aggro/boss_intro_ended)
		# de graça. Diferente do padrão "boss tardio" do stage_00/stage_01
		# (Ignarath/IntroBoss só nascem via add_child() em runtime, depois de
		# super._ready(), por isso PRECISAM de wiring manual — ver memória
		# reference_late_boss_spawn_hud.md). Repetir connect_to_boss aqui
		# conectaria hp_changed/boss_aggro/boss_defeated da HUD DUAS vezes no
		# mesmo callable (erro "already connected" em runtime).
		if galerix.has_signal("boss_defeated"):
			galerix.connect("boss_defeated", _on_boss_defeated)

func _on_boss_defeated(_ability_id: String) -> void:
	GameManager.save_game()
