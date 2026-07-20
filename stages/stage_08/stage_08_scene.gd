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
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_boss_arena()
	_build_zone_ceilings08()
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

# Parede de entulho (rubble_wall.gd, Task 2): bloco sólido no caminho
# principal, largura 64, altura passada por `h` (bottom sempre flush com o
# piso — `center_y` é o CENTRO da CollisionShape2D, não o topo: bottom =
# center_y + h/2 deve dar FLOOR_Y). Quebra em `hits` hits de qualquer ataque
# do jogador (HitDetector collision_mask=8 = layer "player_attack", GAME_
# CONTEXT.md, confirmado independentemente pela Task 2 contra zael_bullet.tscn/
# zara_hitbox.tscn — mesmo valor de cracked_wall.gd/ice_gate.gd).
# rubble_wall.gd NÃO declara `class_name` (só `extends StaticBody2D`), então o
# retorno/var local usam o tipo base StaticBody2D e as propriedades exportadas
# custom (hits_required) são setadas via .set(), mesmo padrão de crusher.gd em
# _build_zone2 (c1.set("wait_time", ...)) — tipar como "RubbleWall" (sem
# class_name) não compilaria.
# tileset_override (NÃO lava_override): corpo pequeno (<7 tiles de altura) —
# lava_override força mínimo 7 linhas de tile e transborda abaixo da colisão
# (reference_lava_mode_min7 na memória do projeto; mesmo bug já mordeu
# cracked_wall.gd/segredo e os footholds/espinhos do shaft Z4, ambos
# resolvidos trocando para tileset_override/skip_base_draw).
func _rubble_wall(n: String, zone: String, cx: float, center_y: float, h: float, hits: int = 3) -> StaticBody2D:
	var b: StaticBody2D = _RUBBLE.new()
	b.name = n
	b.set("hits_required", hits)
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = Vector2(cx, center_y)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(64.0, h)
	cs.shape = sh
	b.add_child(cs)
	var det := Area2D.new()
	det.name = "HitDetector"
	det.collision_layer = 0
	det.collision_mask = 8
	var dcs := CollisionShape2D.new()
	dcs.shape = sh
	det.add_child(dcs)
	b.add_child(det)
	b.set_meta("tileset_override", _zone_tile_path(zone))
	add_child(b)
	return b

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

# ── Zona 2 — Desabamentos ─────────────────────────────────────────────────────
# Piso contínuo (_CP1_EXIT_X=4096 → 7296, sem gap, ver Task 9 que retoma o
# piso em 7296) com 2 crushers (crusher.gd, script genérico de stage_04)
# embutidos no teto da zona. Convenção de teto do projeto: superfície nominal
# = FLOOR_Y-500 = 300 (mesmo valor usado em todas as fases anteriores).
# Bloco 128×96 em repouso com o topo flush nessa superfície → centro de
# repouso = 300 + 48 (metade da altura) = 348. Travel calculado p/ a base do
# bloco alcançar o piso real (FLOOR_Y=800) na extensão máxima: centro na
# extensão máxima = FLOOR_Y - 48 = 752 → travel = 752 - 348 = 404. O script
# crusher.gd default travel=260 NÃO é suficiente (pararia em y=608, 144px
# acima do piso) — setado explicitamente abaixo.
# Clearance de teto p/ Task 11: colisão do teto sobe 32px acima do nominal
# (FLOOR_Y-500-32 = 268, convenção _CEIL_FACE_GAP do projeto); topo do
# crusher em repouso fica em 348-48=300, ou seja 32px abaixo da linha de
# colisão do teto (300 > 268) — sem overlap, margem real de 32px.
# Timing escalonado (wait_time 1.2/0.9) igual ao padrão de stage_04.
func _build_zone2() -> void:
	var rest_y := (FLOOR_Y - 500.0) + 48.0   # 348.0
	var travel := (FLOOR_Y - 48.0) - rest_y  # 404.0
	_floor_seg("z2", _CP1_EXIT_X, 4700.0, FLOOR_Y)
	var c1: AnimatableBody2D = _CRUSHER.new()
	c1.name = "Z2_Crusher1"
	c1.set("wait_time", 1.2)
	c1.set("travel", travel)
	c1.collision_layer = 1
	c1.collision_mask = 0
	c1.position = Vector2(5000.0, rest_y)
	var cs1 := CollisionShape2D.new()
	var sh1 := RectangleShape2D.new()
	sh1.size = Vector2(128.0, 96.0)
	cs1.shape = sh1
	c1.add_child(cs1)
	add_child(c1)
	_floor_seg("z2", 4700.0, 6000.0, FLOOR_Y)
	var c2: AnimatableBody2D = _CRUSHER.new()
	c2.name = "Z2_Crusher2"
	c2.set("wait_time", 0.9)
	c2.set("travel", travel)
	c2.collision_layer = 1
	c2.collision_mask = 0
	c2.position = Vector2(6200.0, rest_y)
	var cs2 := CollisionShape2D.new()
	var sh2 := RectangleShape2D.new()
	sh2.size = Vector2(128.0, 96.0)
	cs2.shape = sh2
	c2.add_child(cs2)
	add_child(c2)
	_floor_seg("z2", 6000.0, 7296.0, FLOOR_Y)
	# Armadura de Zara (Pernas, cf. tabela do CLAUDE.md p/ Fase 08) num desvio
	# elevado logo após o segundo crusher — mesma altura/offset usados nas
	# stages 06/07 (FLOOR_Y-98 = 98px acima do piso, dentro do alcance de
	# pulo real de ~117.5px [JUMP_VELOCITY=-480/GRAVITY=980 em
	# character_base.gd → v²/2g ≈ 117.55px]; colecionável 40px acima do topo
	# da plataforma). Ledge (x=6520-6680) fica bem afastada do crusher 2
	# (x=6136-6264), sem overlap horizontal.
	_fixed_plat("Z2_ArmorLedge", "z2", 6600.0, FLOOR_Y - 98.0, 160.0)
	var armor := preload("res://stages/collectible.tscn").instantiate()
	armor.set("collectible_type", Collectible.Type.ARMOR_ZARA)
	armor.set("armor_piece", "legs")
	armor.global_position = Vector2(6600.0, FLOOR_Y - 138.0)
	add_child(armor)

# ── Zona 3 — Túnel de mineração ───────────────────────────────────────────────
# Piso contínuo de 7296 (fim real da Zona 2, Task 8) até _CP2_ENTRY_X=10496
# (início do corredor CP2, Task 7 — sem gap/overlap, mesmo padrão de CP1/Z1).
# Parede de entulho (rubble_wall.gd) trava o caminho ÚNICO em x=8700 — quebra
# em 3 hits de qualquer ataque do jogador (sem checagem de habilidade, ver
# comentário no topo de rubble_wall.gd: fase pode ser a primeira jogada).
#
# ALTURA (desvio do valor de exemplo do plano, 192px → 320px): o pulo normal
# alcança só ~117.5px, mas a Zona 3 é ar livre (sem teto físico até o
# corredor CP2, bem depois do gap) e o wall-slide/wall-jump deste projeto
# permite AGARRAR a parede ainda subindo (WALL_GRAB_MAX_RISE=160,
# character_base.gd) e então dar um wall-jump (WALL_JUMP_V=-500) a partir daí
# — encadeando os dois, o pico teórico é ~117.5 + 500²/(2·980) ≈ 245px acima
# do piso (bem mais que um pulo só). Um corpo de 192px (top a 192px do piso)
# ficaria abaixo desse pico teórico e correria risco real de ser saltado por
# cima via wall-jump (mesmo com o kick inicial jogando o player pra TRÁS —
# ele recupera controle horizontal já acima do topo da parede, dentro da
# janela de ~0.66s em que fica acima de 192px, e tem margem de sobra pra
# atravessar os 64px de largura). 320px (top a 320px do piso) fica ~75px
# acima desse pico teórico, então nem o wall-jump encadeado ultrapassa.
# Sem piso/parede oposta próxima pra encadear parede→parede (nada entre
# 7296 e 10496 além desta própria parede), então não há como ganhar altura
# além desse teto único de wall-jump.
# Largura 64 = cobre 100% da passagem (não há desvio elevado nem buraco no
# piso ao redor — piso contínuo dos dois lados, corpo cravado nele).
func _build_zone3() -> void:
	var wall_h := 320.0
	var wall_cy: float = FLOOR_Y - wall_h * 0.5  # 640.0 — bottom flush no piso (800)
	_floor_seg("z3", 7296.0, 8700.0, FLOOR_Y)
	_rubble_wall("Z3_RubbleWall", "z3", 8700.0, wall_cy, wall_h, 3)
	_floor_seg("z3", 8700.0, _CP2_ENTRY_X, FLOOR_Y)
	# Saliência com os 3 colecionáveis, só alcançável depois de quebrar a
	# parede (nenhum desvio/pulo alternativo — piso plano dos dois lados,
	# única rota é através de x=8700). Ledge x=8800-9000 (200px), início 68px
	# depois da face direita da parede (8700+32=8732) — sem overlap. Mesmo
	# offset de altura/alcance de Z2_ArmorLedge (FLOOR_Y-98 = 98px acima do
	# piso, dentro do alcance de pulo ~117.5px; colecionáveis 40px acima do
	# topo). Extra do Zael (Cannon, cf. tabela CLAUDE.md Fase 08) + coração +
	# sub-tank, 50px de espaçamento entre si (colisão raio=12 cada — sem
	# overlap, mesmo padrão de espaçamento usado em stage_06).
	_fixed_plat("Z3_ExtraLedge", "z3", 8900.0, FLOOR_Y - 98.0, 200.0)
	var cannon := preload("res://stages/collectible.tscn").instantiate()
	cannon.set("collectible_type", Collectible.Type.SHOT_ZAEL)
	cannon.set("ability_id", "cannon")
	cannon.global_position = Vector2(8850.0, FLOOR_Y - 138.0)
	add_child(cannon)
	var heart := preload("res://stages/collectible.tscn").instantiate()
	heart.set("collectible_type", Collectible.Type.HEART)
	heart.set("stage_id", 8)
	heart.global_position = Vector2(8900.0, FLOOR_Y - 138.0)
	add_child(heart)
	var subtank := preload("res://stages/collectible.tscn").instantiate()
	subtank.set("collectible_type", Collectible.Type.SUBTANK)
	# subtank_index=3: grep em stages/**/*.tscn + *.gd (todo o projeto) —
	# stage_02.tscn usa 0, stage_04.tscn usa 1, stage_06_scene.gd usa 2
	# (comentário lá mesmo já documenta 0/1/2 e reserva 3 pro antigo
	# stage_08.tscn pré-rework). O stage_08.tscn atual (branch desta rework)
	# não tem mais collectibles hardcoded — é gerado 100% em código — então 3
	# está livre e é o valor correto pra fechar a sequência 0/1/2/3 das 4
	# fases com sub-tank (02/04/06/08 por CLAUDE.md). NÃO usar 4 (placeholder
	# do plano, não confirmado contra o grep real).
	subtank.set("subtank_index", 3)
	subtank.global_position = Vector2(8950.0, FLOOR_Y - 138.0)
	add_child(subtank)

# ── Zona 4 — Corredor final com canhões de pedra ──────────────────────────────
# Piso contínuo de _CP2_EXIT_X=11392 (saída do corredor CP2, Task 9) até
# _BOSS_L=12544 (início da sala do boss) — sem gap/overlap, mesmo padrão de
# Z1/CP1. Roster de 2 enemy_boulder_turret já posicionado por Z4_ENEMIES
# (Task 7: x=11700/12200, ambos dentro do span 11392-12544).

func _build_zone4() -> void:
	_floor_seg("z4", _CP2_EXIT_X, _BOSS_L, FLOOR_Y)

# ── Sala do boss (Terragor) ────────────────────────────────────────────────────
# Padrão B (porta aberta + trigger, skill new-boss-room): arena aberta, aggro
# por Area2D de entrada — não por distância (mesmo padrão de stage_01/05/06/07).
#
# Boss room 64px check (skill new-boss-room): Boss_WallR altura 512 = 8×64 ✓,
# Boss_WallL_Top altura 256 = 4×64 ✓, largura da sala _BOSS_R-_BOSS_L =
# 13952-12544 = 1408 = 22×64 ✓. Terragor spawna no centro da sala em
# (13248, 736) = ((_BOSS_L+_BOSS_R)*0.5, FLOOR_Y-64) — bate exatamente com o
# offset de _fixed_plat/roster (personagem em pé sobre o piso, base 64px
# acima da superfície).
#
# arena_left/right: inset de 64px = espessura dos blocos Boss_WallR/
# Boss_WallL_Top acima (_BOSS_L+64=12608, _BOSS_R-64=13888) — o spawn em
# x=13248 cai dentro desse intervalo com folga (~640px de cada lado).
#
# arena_floor: Terragor é walker terrestre (gravity padrão, não voa) — mas
# verificado em boss_base.gd::_clamp_to_arena() e terragor.gd inteiro (_do_
# combat/_do_attack/_do_rock_attack/_do_quake_attack) que NENHUM código lê
# `arena_floor` (só arena_left/arena_right são usados, via _clamp_to_arena,
# que só restringe velocity.x). O grep global confirma: apenas voltrix.gd e
# ignarath.gd de fato leem arena_floor (pra posicionar telégrafos/feixes
# verticais) — terragor.gd não. Mesmo achado da Stage 07 (Luxar, que voa,
# também não lê). Setado mesmo assim por convenção do projeto (Global
# Constraints do plano — bug real da Stage 06 foi omitir os 3 campos por
# completo, não usar um valor "errado" de arena_floor).
func _build_boss_arena() -> void:
	_floor_seg("boss", _BOSS_L, _BOSS_R, FLOOR_Y)
	_solid_block("boss", "Boss_WallR", _BOSS_R + 32.0, FLOOR_Y - 256.0, 64.0, 512.0)
	_solid_block("boss", "Boss_WallL_Top", _BOSS_L + 32.0, FLOOR_Y - 448.0, 64.0, 256.0)
	var terragor := get_node_or_null("Terragor")
	if terragor:
		terragor.visible = true
		terragor.global_position = Vector2((_BOSS_L + _BOSS_R) * 0.5, FLOOR_Y - 64.0)
		terragor.set("auto_aggro", false)
		# Sem estes três, BossBase mantém os defaults de arena_left/right/floor
		# (arena_right=1820 default) — bug crítico da Stage 06 (Global Constraints).
		terragor.set("arena_left", _BOSS_L + 64.0)
		terragor.set("arena_right", _BOSS_R - 64.0)
		terragor.set("arena_floor", FLOOR_Y)
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
				terragor.call("aggro"))
		# $HUD.connect_to_boss já é chamado pelo loop genérico de stage_scene.gd::
		# _ready() (roda ANTES de _build_boss_arena, pra qualquer BossBase filho
		# já presente na .tscn) — não duplicar aqui (mesmo caso já resolvido nas
		# Stages 06/07, ver reference_late_boss_spawn_hud na memória do projeto:
		# só se aplica a boss criado DEPOIS do super._ready(), não é o caso aqui
		# porque Terragor já existe na .tscn desde a Task 7).
		if terragor.has_signal("boss_defeated"):
			terragor.connect("boss_defeated", _on_boss_defeated)
		if terragor.has_signal("ground_smash"):
			terragor.connect("ground_smash", _on_terragor_ground_smash)

func _on_boss_defeated(_ability_id: String) -> void:
	GameManager.save_game()

func _on_terragor_ground_smash() -> void:
	if _cam_ctrl != null:
		_cam_ctrl.shake(12.0, 0.35)

# ── Teto por zona ─────────────────────────────────────────────────────────────
# Cobertura de Z2+Z3 (desabamentos+armadura / túnel de mineração+entulho): a
# entrada "Z2" abaixo cobre [_CP1_EXIT_X, _CP2_ENTRY_X] = [4096, 10496].
# Confirmado contra os _floor_seg REAIS escritos nas Tasks 8/9 (não os números
# de exemplo do plano):
#   Z2 (_build_zone2): 4096→4700, 4700→6000, 6000→7296 → piso real 4096→7296.
#   Z3 (_build_zone3): 7296→8700, 8700→10496          → piso real 7296→10496.
#   Combinado: 4096→10496 — bate exatamente com [_CP1_EXIT_X, _CP2_ENTRY_X],
#   sem gap nem overlap. Mesmo padrão de stage_06/07 (sem entrada "Z3" própria).
const _CEIL08_SEGS := {
	"Z1":   [[0.0, _CP1_ENTRY_X, FLOOR_Y - 500.0]],
	"Z2":   [[_CP1_EXIT_X, _CP2_ENTRY_X, FLOOR_Y - 500.0]],
	"Z4":   [[_CP2_EXIT_X, _BOSS_L, FLOOR_Y - 500.0]],
	"Boss": [[_BOSS_L, _BOSS_R, FLOOR_Y - 448.0 - 256.0]],
}
const _CEIL08_TEX := { "Z1": "z1", "Z2": "z2", "Z4": "z4", "Boss": "z4" }
const _CEIL08_TOP := 128.0
const _CEIL08_FACE_GAP := 32.0

# Clearance vs. Z2_Crusher1/2 (_build_zone2, Task 8): superfície nominal do
# teto de Z2 = FLOOR_Y-500 = 300; linha de colisão sobe FACE_GAP=32px acima =
# 268. Crusher em repouso: centro rest_y=348.0, altura 96 → topo em repouso =
# 348-48=300, ou seja 32px ABAIXO (y maior = mais perto do chão) da linha de
# colisão do teto (268 < 300) — sem overlap, folga real de 32px, confirmado
# contra os números reais escritos em _build_zone2 (rest_y/travel), não os do
# plano.
#
# Clearance vs. Z3_RubbleWall (_build_zone3, Task 9): parede em x=8700, cai no
# span da entrada "Z2" acima (7296→10496 faz parte de [4096,10496], sem
# entrada "Z3" própria — mesmo fallback cross-zone documentado no comentário
# acima). Topo da parede: wall_cy=640.0, wall_h=320.0 → topo=640-160=480.
# Linha de colisão do teto nesse trecho = 268 (mesma superfície de Z2, ver
# acima). 480 > 268 com folga de 212px — bem abaixo da linha de colisão, sem
# risco de clipar mesmo com a altura não-padrão (320px em vez de 192px) da
# parede, exigida pela análise de wall-jump encadeado no comentário de
# _build_zone3.
func _build_zone_ceilings08() -> void:
	for zk: String in _CEIL08_SEGS:
		var body := StaticBody2D.new()
		body.name = "%sCeilSegs" % zk
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		for s: Array in _CEIL08_SEGS[zk]:
			var cs := CollisionShape2D.new()
			var sh := SegmentShape2D.new()
			sh.a = Vector2(s[0], (s[2] as float) - _CEIL08_FACE_GAP)
			sh.b = Vector2(s[1], (s[2] as float) - _CEIL08_FACE_GAP)
			cs.shape = sh
			body.add_child(cs)

func _ceil08_surface_at(zk: String, wx: float) -> float:
	for s: Array in _CEIL08_SEGS[zk]:
		if wx >= (s[0] as float) and wx < (s[1] as float):
			return s[2]
	for zk2: String in _CEIL08_SEGS:
		if zk2 == zk:
			continue
		for s: Array in _CEIL08_SEGS[zk2]:
			if wx >= (s[0] as float) and wx < (s[1] as float):
				return s[2]
	return -1.0

func _ceil08_solid(zk: String, wx: float, y: float) -> bool:
	var yb := _ceil08_surface_at(zk, wx)
	return yb > 0.0 and y < yb

func _draw() -> void:
	super._draw()
	_draw_zone_ceilings08()

func _draw_zone_ceilings08() -> void:
	var ts := float(_TS)
	var sts := float(_SRC_TS)
	for zk: String in _CEIL08_SEGS:
		var segs: Array = _CEIL08_SEGS[zk]
		var tex := _cached_override_tex(_zone_tile_path(_CEIL08_TEX[zk] as String))
		if tex == null:
			continue
		var x0f: float = segs[0][0]
		var x1f: float = segs[segs.size() - 1][1]
		var x := x0f
		while x < x1f:
			var yb := _ceil08_surface_at(zk, x)
			var y := _CEIL08_TOP
			while y < yb:
				var ed := not _ceil08_solid(zk, x, y + ts)
				var el := not _ceil08_solid(zk, x - ts, y)
				var er := not _ceil08_solid(zk, x + ts, y)
				var tile: Vector2i
				if   ed and el: tile = Vector2i(0, 2)
				elif ed and er: tile = Vector2i(3, 3)
				elif ed:        tile = Vector2i(1, 2)
				elif el:        tile = Vector2i(1, 0)
				elif er:        tile = Vector2i(3, 2)
				elif not _ceil08_solid(zk, x - ts, y + ts): tile = Vector2i(2, 2)
				elif not _ceil08_solid(zk, x + ts, y + ts): tile = Vector2i(3, 1)
				else:           tile = Vector2i(2, 1)
				draw_texture_rect_region(tex, Rect2(x, y, ts, ts),
					Rect2(float(tile.x) * sts, float(tile.y) * sts, sts, sts))
				y += ts
			x += ts
